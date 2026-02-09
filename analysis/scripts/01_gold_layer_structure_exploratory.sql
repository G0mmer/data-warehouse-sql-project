/*
--------------------------------------------------------------------------------
gold_layer_structure
purpose:
    - quick overview of the database schema (tables and columns)
    - explores distinct categories available in the product dimension
--------------------------------------------------------------------------------
*/

--check the tables
select * from information_schema.tables;

--check the columns form gold layer
select * from information_schema.columns
where table_schema='gold';

--explore categories
select distinct 
    category_name,
    subcategory,
    product_name
from gold.dim_products
order by 1,2,3;