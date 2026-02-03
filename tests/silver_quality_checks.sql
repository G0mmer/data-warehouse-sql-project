/*
	Helper querry that helps identify errors in tables and later validate the improvments
*/
-----------------------------
-- check bronze.crm_cust_info
-----------------------------

	--check for nulls or duplciates in primary key 
	select cst_id,count(*)
	from bronze.crm_cust_info
	group by cst_id
	having count(*)>1 or cst_id is null
		
	--check for unwanted spaces
	select cst_first_name
	from bronze.crm_cust_info
	where cst_first_name!= trim(cst_first_name)

	union 

	select cst_last_name
	from bronze.crm_cust_info
	where cst_last_name!= trim(cst_last_name)

	--consistency in gander and matial status
	select distinct(cst_gndr)
	from bronze.crm_cust_info

	select distinct(cst_marital_status)
	from bronze.crm_cust_info
-----------------------------------
--validate the silver.crm_cust_info
-----------------------------------

	--check for nulls or duplciates in primary key 
	select cst_id,count(*)
	from silver.crm_cust_info
	group by cst_id
	having count(*)>1 or cst_id is null
		
	--check for unwanted spaces
	select cst_first_name
	from silver.crm_cust_info
	where cst_first_name!= trim(cst_first_name)

	union 

	select cst_last_name
	from silver.crm_cust_info
	where cst_last_name!= trim(cst_last_name)

	--consistency in gander and matial status
	select distinct(cst_gndr)
	from silver.crm_cust_info

	select distinct(cst_marital_status)
	from silver.crm_cust_info

---------------------------
--check bronze.crm_prd_info
---------------------------
	select * from bronze.crm_prd_info

	--check the prm key
	select prd_id,count(*)
	from bronze.crm_prd_info
	group by prd_id
	having count(*)>1 or prd_id is null
	
	--check the product names
	select prd_nm
	from bronze.crm_prd_info
	where prd_nm!= trim(prd_nm)

	--check for nulls or negative numbers 
	select prd_cost
	from bronze.crm_prd_info
	where prd_cost<0 or prd_cost is null

	--line check 
	select distinct prd_line
	from bronze.crm_prd_info

	--date order
	select *
	from bronze.crm_prd_info
	where prd_end_dt < prd_start_dt
	
	--fix: we take the start_date form the next entry if exists and substracr one
	select *,
	Lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 as prd_end_dt 
	from (select *
	from bronze.crm_prd_info
	where prd_end_dt < prd_start_dt
	)t

	--quality checks in silver layer
	--check the prm key
	select prd_id,count(*)
	from silver.crm_prd_info
	group by prd_id
	having count(*)>1 or prd_id is null
	
	--check the product names
	select prd_nm
	from silver.crm_prd_info
	where prd_nm!= trim(prd_nm)

	--check for nulls or negative numbers 
	select prd_cost
	from silver.crm_prd_info
	where prd_cost<0 or prd_cost is null

	--line check 
	select distinct prd_line
	from silver.crm_prd_info

	--date order
	select *
	from silver.crm_prd_info
	where prd_end_dt < prd_start_dt

--sales details table

	--check if there is a macth beetwen the sales table and both prodcuts and customer ones
	select *
	from bronze.crm_sales_details
	where sls_prd_key not in (
								select prd_key
								from silver.crm_prd_info)
	
	select *
	from bronze.crm_sales_details
	where sls_cust_id not in (
								select cst_id
								from silver.crm_cust_info)

	--date handling, check range and len 
	select nullif(sls_order_dt,0)
	from bronze.crm_sales_details
	where sls_order_dt<=0 or
	len(sls_order_dt)!=8
	or sls_order_dt >20270000
	or sls_order_dt <19000000
	
	select nullif(sls_ship_dt,0)
	from bronze.crm_sales_details
	where len(sls_ship_dt)!=8
	or sls_ship_dt >20270000
	or sls_ship_dt <19000000
	
	--check if alwys order date is less then shiping one
	select *
	from bronze.crm_sales_details
	where sls_order_dt>sls_ship_dt or sls_order_dt>sls_due_dt

	--checks for sals_sales, sls_quantity and sls_price
	select sls_price,sls_quantity,sls_sales ,
		case 
		when sls_quantity>0 and sls_price>0 and sls_sales!=sls_price*sls_quantity then sls_price*sls_quantity
		else sls_sales end as new_sls_sales, 
	case 
		when sls_price<0 then -sls_price
		when sls_price=0 or sls_price is null then sls_sales/sls_quantity
		else sls_price end as new_sls_price
	from bronze.crm_sales_details
	where 
		sls_sales != sls_quantity*sls_price
		or sls_quantity<=0
		or sls_quantity is null
		or sls_price<=0
		or sls_price is null

	--validate
	--check if there is a macth beetwen the sales table and both prodcuts and customer ones
	select *
	from silver.crm_sales_details
	where sls_prd_key not in (
								select prd_key
								from silver.crm_prd_info)
	
	select *
	from silver.crm_sales_details
	where sls_cust_id not in (
								select cst_id
								from silver.crm_cust_info)

	
	--check if alwys order date is less then shiping one
	select *
	from silver.crm_sales_details
	where sls_order_dt>sls_ship_dt or sls_order_dt>sls_due_dt

	--checks for sals_sales, sls_quantity and sls_price
	select sls_price,sls_quantity,sls_sales ,
		case 
		when sls_quantity>0 and sls_price>0 and sls_sales!=sls_price*sls_quantity then sls_price*sls_quantity
		else sls_sales end as new_sls_sales, 
	case 
		when sls_price<0 then -sls_price
		when sls_price=0 or sls_price is null then sls_sales/sls_quantity
		else sls_price end as new_sls_price
	from silver.crm_sales_details
	where 
		sls_sales != sls_quantity*sls_price
		or sls_quantity<=0
		or sls_quantity is null
		or sls_price<=0
		or sls_price is null

--------------------------------
--check the bronze.erp_cust_az12
--------------------------------

	select*
	from bronze.erp_cust_az12 e
	left join bronze.crm_cust_info c
	on e.cid=c.cst_key 
	where c.cst_key is null and e.cid not like 'NAS%'

	select *
	from bronze.erp_cust_az12
	where bdate not between '1924-01-01' and getdate()

	select distinct(gen)
	from bronze.erp_cust_az12

	select *
	from bronze.erp_cust_az12
	where gen = ''
	----------
	--validate
	----------
	select*
	from silver.erp_cust_az12 e
	left join silver.crm_cust_info c
	on e.cid=c.cst_key 
	where c.cst_key is null and e.cid not like 'NAS%'

	select *
	from silver.erp_cust_az12
	where bdate > getdate()

	select distinct(gen)
	from silver.erp_cust_az12

-------------------------------
--check the bronze.erp_loc_a101
-------------------------------	

	select *
	from bronze.erp_loc_a101 
	where cid not in (select distinct (cst_key) from silver.crm_cust_info)

	select distinct cntry
	from bronze.erp_loc_a101

	----------
	--validate
	----------

	select replace(cid,'-','') as cid_
	from silver.erp_loc_a101 
	where replace(cid,'-','') not in (select distinct (cst_key) from silver.crm_cust_info)

	select distinct cntry
	from silver.erp_loc_a101

------------------------------
--check bronze.erp_px_cat_g1v2
------------------------------

select
	id,
	cat,
	subcat,
	maintenance
from bronze.erp_px_cat_g1v2
where id not in (select distinct cat_id from silver.crm_prd_info)

select
	id,
	cat,
	subcat,
	maintenance
from bronze.erp_px_cat_g1v2
where id not in (select distinct cat_id from silver.crm_prd_info
)

select distinct cat_id from silver.crm_prd_info
where cat_id not in (select
	id
from bronze.erp_px_cat_g1v2
)
SELECT  distinct
      [cat_id]
  FROM [DataWarehouse].[silver].[crm_prd_info]
  where cat_id like 'CO%'