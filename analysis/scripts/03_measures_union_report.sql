/*
--------------------------------------------------------------------------------
measures_union_report
purpose:
    - generates a vertical report of all key metrics using union all
    - useful for quickly binding data to a dashboard card visual
--------------------------------------------------------------------------------
*/

select 'total_years' as measure_name , cast(datediff(year,min(order_date),max(order_date)) as int) as measure_value
from gold.fact_sales

union all

select 'total_months' as measure_name , cast(datediff(month,min(order_date),max(order_date)) as int) as measure_value
from gold.fact_sales

union all

select 'min_age' as measure_name , min(age) as measure_value
from gold.dim_customers

union all

select 'max_age' as measure_name , max(age) as measure_value
from gold.dim_customers

union all

select 'age_span' as measure_name , max(age)-min(age) as measure_value
from gold.dim_customers

union all

select 'total_number_of_customers' as measure_name , count(distinct customer_id) as measure_value
from gold.dim_customers

union all

select 'customers_that_placed_order' as measure_name , count(distinct c.customer_key) as measure_value
from gold.dim_customers c
left join gold.fact_sales s
on c.customer_key=s.customer_key
where s.customer_key is not null

union all

select 'total_products' as measure_name , count(distinct product_key) as measure_value
from gold.dim_products

union all

select 'total_revenue' as measure_name , sum(sales_amount) as measure_value
from gold.fact_sales

union all

select 'total_items_sold' as measure_name , sum(quantity) as measure_value
from gold.fact_sales

union all

select 'avg_price' as measure_name , avg(price) as measure_value
from gold.fact_sales

union all

select 'order_numbers' as measure_name , count(distinct order_number) as measure_value
from gold.fact_sales

union all

select 'avg_value_of_order' as measure_name , avg(a.avg_c) as measure_value
from (
        select 
            avg(price) over (partition by order_number order by product_key) as  avg_c
        from gold.fact_sales
        )a