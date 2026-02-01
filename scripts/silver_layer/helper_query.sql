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
