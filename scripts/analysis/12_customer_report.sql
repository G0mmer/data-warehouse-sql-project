/*
customer report (view-ready)
================================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
        
*/
if object_id('gold.report_products', 'v') is not null
    drop view gold.report_products;
go

create view gold.report_products as
with 
-- 1. global parameters: calculate totals and ranges dynamically
global_params as (
    select 
        -- age bucket logic
        min(age) as min_age,
        max(age) as max_age,
        -- calculate bucket size: (max - min + 1) / 5 buckets
        (max(age) - min(age) + 1.0) / 5.0 as bucket_size,
        
        -- totals for percentage calculations
        (select count(*) from gold.dim_customers) as total_clients,
        (select sum(sales_amount) from gold.fact_sales) as total_rev,
        (select sum(quantity) from gold.fact_sales) as total_products
    from gold.dim_customers
),

-- 2. base query: join sales to customers & apply buckets
base_query as (
    select 
        c.customer_key,
        c.customer_id,
        concat(c.first_name, ' ', c.last_name) as customer_name,
        c.age,
        c.gender,
        c.country,
        s.order_number,
        s.order_date,
        s.quantity,
        s.price,
        s.sales_amount,
        s.product_key,
        -- calculate bucket id using global params
        floor((c.age - gp.min_age) / gp.bucket_size) + 1 as bucket_id
    from gold.fact_sales s
    left join gold.dim_customers c on s.customer_key = c.customer_key
    cross join global_params gp -- brings parameters to every row
    where s.order_date is not null
),

-- 3. customer aggregations
aggr_query as (
    select
        customer_key,
        customer_name,
        age,
        gender,
        country,
        bucket_id,
        count(distinct order_number) as order_count,
        sum(sales_amount) as total_rev,
        sum(quantity) as total_items_purchased,
        count(distinct product_key) as distinct_products_count,
        max(order_date) as last_order,
        datediff(month, max(order_date), getdate()) as recency,
        avg(sales_amount) as avg_order_value,
        case 
            when datediff(month, min(order_date), max(order_date)) = 0 then 0
            else cast(1.00 * sum(sales_amount) / datediff(month, min(order_date), max(order_date)) as decimal(9,2)) 
        end as avg_monthly_spend,
        sum(sales_amount) as total_spent,    
        datediff(month, min(order_date), max(order_date)) as legacy
    from base_query
    group by 
        customer_key,
        customer_name,
        age,
        gender,
        country,
        bucket_id
),

-- 4. segmentation: account level (vip/regular/new)
account_level as (
    select
        a.label_,
        count(*) as clients_count,
        cast(100.00 * count(*) / gp.total_clients as decimal(9,2)) as clients_percentage,
        avg(a.age) as avg_age,
        avg(a.order_count) as avg_order_placed,
        avg(a.total_rev) as avg_rev,
        avg(a.total_items_purchased) as avg_items_bought,
        avg(a.legacy) as avg_legacy,
        sum(a.total_rev) as total_rev,
        cast(100.00 * sum(a.total_rev) / gp.total_rev as decimal(9,2)) as revenue_percentage,
        sum(a.total_items_purchased) as total_items_purchased,
        cast(100.00 * sum(a.total_items_purchased) / gp.total_products as decimal(9,2)) as items_percentage
    from (
        select *, 
            case 
                when legacy >= 12 and total_rev > 5000 then 'vip'
                when legacy >= 12 and total_rev <= 5000 then 'regular'
                else 'new' 
            end as label_
        from aggr_query
    ) a
    cross join global_params gp -- join again to get totals for % calculation
    group by a.label_, gp.total_clients, gp.total_rev, gp.total_products
)
select* from aggr_query