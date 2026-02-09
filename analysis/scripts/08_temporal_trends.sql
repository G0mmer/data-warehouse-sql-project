/*
--------------------------------------------------------------------------------
temporal_trends
purpose:
    - analyzes sales trends over time
    - aggregates revenue, customer count, and avg bill by year
    - aggregates the same metrics by month
    - creates a custom quarter analysis (2011-2013)
--------------------------------------------------------------------------------
*/

--yearly analysis
select 
    year(order_date) as order_year,
    sum(sales_amount) as rev,
    count(distinct customer_key) as customers_number,
    sum(quantity) as product_sold,
    sum(sales_amount)/count(distinct customer_key) as avg_cust_bill
from gold.fact_sales
where order_date is not null
group by year(order_date)
order by year(order_date);

--monthly analysis
select 
    month(order_date) as month,
    sum(sales_amount) as rev,
    count(distinct customer_key) as customers_number,
    sum(quantity) as product_sold,
    sum(sales_amount)/count(distinct customer_key) as avg_cust_bill
from gold.fact_sales
where order_date is not null
group by month(order_date)
order by month(order_date);

--quarterly analysis (custom logic for 2011-2013)
with cte as (
select*, cast(year(order_date) as int)*10 + floor(1.00*(cast(month(order_date) as int)-1)/3)+1 as quarter_code
from gold.fact_sales
where order_date>'2010-12-31' and order_date<'2014-01-01'
)
select 
    substring(cast(quarter_code as nvarchar(50)),5,len(cast(quarter_code as nvarchar(50))))+'_quarter of '+substring(cast(quarter_code as nvarchar(50)),1,4) as quarte,
    sum(sales_amount) as rev,
    count(distinct customer_key) as customers_number,
    sum(quantity) as product_sold,
    sum(sales_amount)/count(distinct customer_key) as avg_cust_bill
from cte
group by quarter_code
order by quarter_code;