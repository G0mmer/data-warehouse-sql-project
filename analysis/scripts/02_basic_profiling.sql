/*
--------------------------------------------------------------------------------
basic_profiling
purpose:
    - establishes the time range of the sales data
    - profiles customer demographics (age range)
    - calculates high-level aggregates (total revenue, orders, distinct counts)
--------------------------------------------------------------------------------
*/

--explore the time range
select 
    min(order_date) as min_oder_date,
    max(order_date) as max_order_date,
    datediff(year,min(order_date),max(order_date)) as total_years, 
    datediff(month,min(order_date),max(order_date)) as total_months 
from gold.fact_sales;

--explore the age range 
select
    min(age) as min_age,
    max(age) as max_age,
    max(age)-min(age) as age_span
from gold.dim_customers;

--find the total sales, items sold, avg price, and order count
select 
    sum(sales_amount) as total_revenue,
    sum(quantity) as tota_items_sold,
    avg(price) as avg_price,
    count(distinct order_number) as order_numbers
from gold.fact_sales;

--find avg bill of customer
select avg(a.avg_c) as avg_value_of_order
from (
    select 
        avg(price) over (partition by order_number order by product_key) as  avg_c
    from gold.fact_sales
    )a;

--find total number of products 
select count(distinct product_key) as total_products
from gold.dim_products;

--find the total number of customers 
select count(distinct customer_id)
from gold.dim_customers;