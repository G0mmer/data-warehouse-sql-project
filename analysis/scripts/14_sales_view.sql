/*
================================================================================
Sales view
================================================================================
Purpose:
    - This viwe stores the record of orders with customer and product keys, 
      it allows the dynamic date filters in power BI.
*/
if object_id('gold.report_dates', 'v') is not null
    drop view gold.report_dates;
go

create view gold.report_dates as
select 
    s.customer_key,
    s.product_key,
    s.order_date,
    s.order_number,    
    s.sales_amount,    
    s.quantity,        
    p.production_cost
from gold.fact_sales s
left join gold.dim_products p
on s.product_key=p.product_key