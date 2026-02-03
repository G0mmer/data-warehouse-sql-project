create or alter view gold.dim_customers as (
select
	row_number() over (order by cst_id) as customer_key,
	cst_id as customer_id,
	cst_key as customer_number,
	cst_first_name as first_name,
	cst_last_name as last_name,
	lc.cntry as country,
	cst_marital_status as marital_status,
	case
		when cst_gndr != 'n/a' then cst_gndr --supose the crm is the main source
		else coalesce(bt.gen,'n/a') end as gender,
	bt.bdate as birthday,
	cast(year(getdate()) as int)-cast(year(bt.bdate) as int) as age,
	cst_create_date as create_date
from silver.crm_cust_info ci
left join silver.erp_cust_az12 bt
	on ci.cst_key=bt.cid
left join silver.erp_loc_a101 lc
	on ci.cst_key=lc.cid
);

create or alter view gold.dim_products as (
select 
	row_number() over (order by i.prd_start_dt ,i.prd_key) as product_key,
	i.prd_id as product_id,
	i.prd_key as product_number,
	i.prd_nm as product_name,
	i.cat_id as category_id,
	c.cat as category_name,
	c.subcat as subcategory,
	c.maintenance as maintenance,
	i.prd_cost as production_cost,
	i.prd_line as production_line, 
	i.prd_start_dt as production_date_start
from silver.crm_prd_info i
left join silver.erp_px_cat_g1v2 c
on i.cat_id=c.id
where prd_end_dt is null  --filter out all historical data
);

create or alter view gold.fact_sales as( 
select
s.sls_ord_num as order_number,
c.customer_key,
p.product_key,
s.sls_order_dt as order_date,
s.sls_ship_dt as ship_date,
s.sls_due_dt as due_date,
s.sls_sales as sales_amount,
s.sls_quantity as quantity,
s.sls_price as price
from silver.crm_sales_details s
left join gold.dim_customers c
on s.sls_cust_id=c.customer_id
left join gold.dim_products p
on s.sls_prd_key=p.product_number
);