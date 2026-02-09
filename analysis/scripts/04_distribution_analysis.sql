/*
--------------------------------------------------------------------------------
distribution_analysis
purpose:
    - breaks down customer counts by country and gender
    - analyzes inventory depth (product counts) within categories and subcategories
--------------------------------------------------------------------------------
*/

--customers by country 
select country, count(*) as customers_number
from gold.dim_customers
group by country
order by count(*) desc;

--customers by gender
select gender, count(*) as customers_number
from gold.dim_customers
group by gender
order by count(*) desc;

--product distribiution within each category 
select 
    category_name,
    count(distinct product_key) as products_in_category
from gold.dim_products
group by category_name
order by count(distinct product_key) desc;

--product distribiution within each subcategory 
select 
    category_name,
    subcategory,
    count(distinct product_key) as products_in_subcategory
from gold.dim_products
group by category_name,subcategory
order by count(distinct product_key) desc;