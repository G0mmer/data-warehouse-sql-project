/*
--------------------------------------------------------------------------------
ranking_products_categories
purpose:
    - identifies top 5 best-performing products by sales
    - identifies bottom 5 worst-performing products by sales
    - performs the same top/bottom analysis for subcategories
--------------------------------------------------------------------------------
*/

--what are the 5 best-performing products in term of sales
select top 5 p.product_name, sum(s.sales_amount) as rev
from gold.fact_sales s
left join gold.dim_products p
on p.product_key=s.product_key
group by p.product_name
order by rev desc;

--what are the 5 worst-performing products in term of sales
select top 5 p.product_name, sum(s.sales_amount) as rev
from gold.fact_sales s
left join gold.dim_products p
on p.product_key=s.product_key
group by p.product_name
order by rev;
    
--what are the 5 best-performing categories in term of sales
select top 5 p.subcategory, sum(s.sales_amount) as rev
from gold.fact_sales s
left join gold.dim_products p
on p.product_key=s.product_key
group by p.subcategory
order by rev desc;

--what are the 5 worst-performing products in term of sales
select top 5 p.subcategory, sum(s.sales_amount) as rev
from gold.fact_sales s
left join gold.dim_products p
on p.product_key=s.product_key
group by p.subcategory
order by rev;