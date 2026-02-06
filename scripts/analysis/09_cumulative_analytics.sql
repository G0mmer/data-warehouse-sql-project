/*
--------------------------------------------------------------------------------
cumulative_analytics
purpose:
    - calculates cumulative (running total) revenue and sales per month
    - calculates moving averages for price
    - performs year-over-year running total comparisons
--------------------------------------------------------------------------------
*/

--total sales per month and running total of sales over year and time 
select 
    year_and_month,
    max(rev) as cumulative_annual_revenue,
    max(total_rev) as running_total_revenue,
    max(product_sold) as cumulative_annual_product_sold_count,
    max(total_product_sold) as running_total_product_sold_count,
    max(avg_price) as moving_annual_avg_price,
    max(avg_price_total) as moving_total_avg_price
from (select
    datetrunc(month,order_date) as year_and_month,
    sum(sales_amount) over (partition by year(order_date) order by datetrunc(month,order_date)) as rev,
    sum(sales_amount) over (order by datetrunc(month,order_date)) as total_rev,
    sum(quantity) over (partition by year(order_date) order by datetrunc(month,order_date)) as product_sold,
    sum(quantity) over (order by datetrunc(month,order_date)) as total_product_sold,
    avg(price) over (partition by year(order_date) order by datetrunc(month,order_date)) as avg_price,
    avg(price) over (order by datetrunc(month,order_date)) as avg_price_total
from gold.fact_sales
where order_date is not null
)a group by year_and_month
order by year_and_month;

--years comparison of running totals
select 
    year_,
    max(total_rev) as running_total_revenue,
    max(total_product_sold) as running_total_product_sold_count,
    max(avg_price_total) as moving_total_avg_price
from (select
    datetrunc(year,order_date) as year_,
    sum(sales_amount) over (order by datetrunc(year,order_date)) as total_rev,
    sum(quantity) over (order by datetrunc(year,order_date)) as total_product_sold,
    avg(price) over (order by datetrunc(year,order_date)) as avg_price_total
from gold.fact_sales
where order_date is not null
)a group by year_
order by year_;