/* Test query for gold layer
	Purpose of this query is to validate the silver layer sources and new objects in gold layer.
	Make sure all silver and gold objects are already created
*/
--------------------
--csutomer dimension
--------------------
--check the sources uniqunes

	select 
		cst_id,
		count(*) 
	from (select
		cst_id,
		cst_key,
		cst_first_name,
		cst_last_name,
		cst_marital_status,
		cst_gndr,
		cst_create_date,
		bt.bdate,
		bt.gen,
		lc.cntry
	from silver.crm_cust_info ci
	left join silver.erp_cust_az12 bt
		on ci.cst_key=bt.cid
	left join silver.erp_loc_a101 lc
		on ci.cst_key=lc.cid)a
	group by a.cst_id 
	having count(*)>1

--gender - data inegity check between sources

	select distinct
		cst_gndr,
		bt.gen,
		case
			when cst_gndr != 'n/a' then cst_gndr --supose the crm is the main source
			else coalesce(bt.gen,'n/a') end as gender
	from silver.crm_cust_info ci
	left join silver.erp_cust_az12 bt
		on ci.cst_key=bt.cid
	left join silver.erp_loc_a101 lc
		on ci.cst_key=lc.cid
	order by 1,2

----------------------------------------
--validation on gold layer (view object)
----------------------------------------

--key uniqunes
	select 
		customer_key,
		count(*) 
	from gold.dim_customers
	group by customer_key
	having count(*)>1

--gender column
	select distinct
		gender 
	from gold.dim_customers

---------------
--products view
---------------

--check for uniqunes
select a.prd_key, count(*)
from (
select 
	prd_id,
	prd_key,
	cat_id,
	prd_cost,
	prd_nm,
	prd_line,
	prd_start_dt,
	prd_end_dt,
	c.cat,
	c.maintenance
from silver.crm_prd_info i
left join silver.erp_px_cat_g1v2 c
on i.cat_id=c.id
where prd_end_dt is null --filter out all historical data
)a
group by a.prd_key
having count(*)>1 

--validate 
select* from gold.dim_products

--for sales details, only switch keys 

--validate + foreign key integrity
select* from gold.fact_sales s
left join gold.dim_products p
on p.product_key=s.product_key
left join gold.dim_customers c
on c.customer_key=s.customer_key
where c.customer_key is null 

select* from gold.fact_sales s
left join gold.dim_products p
on p.product_key=s.product_key
left join gold.dim_customers c
on c.customer_key=s.customer_key
where p.product_key is null
