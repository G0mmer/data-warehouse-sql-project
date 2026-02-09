/*
================================================================================
Product Report
================================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
        - total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last sale)
        - average order revenue (AOR)
        - average monthly revenue
*/
-- Create Report: gold.report_products

if object_id('gold.report_products', 'v') is not null
    drop view gold.report_products;
go

create view gold.report_products as
-- Base Query: Retrieves core columns from fact_sales and dim_products
with base_query as (
select     
    p.product_key,
    p.product_name,
    p.category_name,
    p.subcategory,
    p.production_cost,
    p.production_date_start,
    s.order_number,
    s.customer_key,
    s.price,
    s.quantity,
    s.order_date,
    s.sales_amount
from gold.fact_sales s
left join gold.dim_products p
on s.product_key=p.product_key
where s.order_date is not null
),
--Product Aggregations: Summarizes key metrics at the product level
agr_query as (
select  
    product_key,
    product_name,
    category_name,
    subcategory,
    production_cost,
    production_date_start,
    count(*) as total_orders,
    count(distinct customer_key) as distinct_clients_that_bought,
    sum(quantity) as total_copies_sold,
    min(order_date) as first_order_date,
    max(order_date)as last_order_date,
    sum(sales_amount) as total_sales,
    datediff(month,min(order_date),max(order_date)) as lifespan,
    avg(price) as avg_price
from base_query
group by  
    product_key,
    product_name,
    category_name,
    subcategory,
    production_cost,
    production_date_start
  ),
  --Final Query: Combines all product results into one output
 final_query as(
  select *,
    datediff(month, last_order_date, getdate()) as recancy_in_months,
    case    
        when total_sales-total_copies_sold*production_cost> 10000 then 'High performence'
        when total_sales-total_copies_sold*production_cost>=5000 then 'Mid performence'
        else 'Low performence' end as product_segment,
    case 
        when total_orders=0 then 0
        else total_sales/total_orders 
    end as avg_order_revenue,
        case when lifespan = 0 then total_sales
        else total_sales/lifespan 
    end as avg_monthly_revenue
  from agr_query
  )
  select*
  from final_query
