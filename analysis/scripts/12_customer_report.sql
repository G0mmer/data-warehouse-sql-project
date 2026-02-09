/*
================================================================================
Customer Report
================================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors.

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

if object_id('gold.report_customers', 'v') is not null
    drop view gold.report_customers;
go

create view gold.report_customers as
with 
-- 1. Global parameters: calculate age ranges dynamically for buckets
global_params as (
    select 
        min(age) as min_age,
        max(age) as max_age,
        (max(age) - min(age) + 1.0) / 5.0 as bucket_size
    from gold.dim_customers
),

-- 2. Base Query: Join sales to customers & apply age buckets with proper grouping
base_query as (
    select
        c.customer_key,
        concat(c.first_name, ' ', c.last_name) as customer_name,
        c.age,
        c.gender,
        c.country,
        count(distinct s.order_number) as order_count,
        sum(s.sales_amount) as total_rev,
        sum(s.quantity) as total_items_purchased,
        count(distinct s.product_key) as distinct_products_count,
        max(s.order_date) as last_order_date,
        min(s.order_date) as first_order_date,
        datediff(month, min(s.order_date), max(s.order_date)) as lifespan_months,
        -- Calculate age range label
        concat(
            floor(gp.min_age + (floor((c.age - gp.min_age) / gp.bucket_size)) * gp.bucket_size),
            ' - ',
            floor(gp.min_age + (floor((c.age - gp.min_age) / gp.bucket_size) + 1) * gp.bucket_size-1)
        ) as age_range
    from gold.fact_sales s
    left join gold.dim_customers c on s.customer_key = c.customer_key
    cross join global_params gp 
    where s.order_date is not null
    group by 
        c.customer_key, 
        c.first_name, 
        c.last_name, 
        c.age, 
        c.gender, 
        c.country,
        gp.min_age, 
        gp.bucket_size
),

-- 3. Customer Aggregations: Calculate final KPIs and Segmentations
aggr_query as (
    select
        *,
        -- Recency: Months since the last purchase
        datediff(month, last_order_date, getdate()) as recency_months,
        -- Segmentation: Account level (VIP, Regular, New)
        case
            when lifespan_months >= 12 and total_rev > 5000 then 'VIP'
            when lifespan_months >= 12 and total_rev <= 5000 then 'Regular'
            else 'New' 
        end as customer_segment,
        -- Averages
        case when order_count = 0 then 0 else total_rev / order_count end as avg_order_value,
        case when lifespan_months = 0 then total_rev else total_rev / lifespan_months end as avg_monthly_spend
    from base_query
)

select *
from aggr_query;