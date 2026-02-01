/* Purpose of this query:
	Transform the data form bronze layer and insert it into the silver layer
*/
---------------
--crm_cust_info
---------------
	--use cte in order not to operate on data that will be removed
	with cte as (
		select *
		from (
		select
		*,
		Row_number() over (partition by cst_id order by cst_create_date desc) as flag_last
		from bronze.crm_cust_info
		)t where flag_last =1  and cst_id is not null
		--choose only the latest updates for redudant ids and remove the null ones

	)
	/*use insert into as the table has been already created 
	(if not use first the table creation query for silver layer*/
	insert into silver.crm_cust_info(
		cst_id,
		cst_key,
		cst_first_name,
		cst_last_name,
		cst_marital_status,
		cst_gndr,
		cst_create_date
	)


	select 
		cst_id,
		cst_key,
		--trim both first and last name columns to rmove whitespaces
		trim(cst_first_name) as cst_first_name,
		trim(cst_last_name) as cst_last_name,
		/*increase the readabilty by using the full name of martial status and gender column;
		use n/a for null; apply upper() in order not to omit lowercase in further batches
		*/
		case
			when upper(trim(cst_marital_status))='S' then 'Single'
			when upper(trim(cst_marital_status))='M' then 'Married'
			else 'n/a' end as cst_marital_status,
		case 
			when upper(trim(cst_gndr))='M' then 'Male'
			when upper(trim(cst_gndr))='F' then 'Female'
			else 'n/a' end as cst_gndr,

		cst_create_date
	from cte

--------------
--crm_prd_info
--------------
select* from bronze.crm_prd_info
select* from bronze.erp_px_cat_g1v2

	select 
		prd_id,
		prd_key,
		replace(substring(prd_key,1,5),'-','_')  as cat_id,
		substring(prd_key,7,len(prd_key)) as prd_key,
		prd_nm,
		isnull(prd_cost,0) as prd_cost,
		case upper(trim(prd_line))
			when 'M' then 'Mountain'
			when 'R' then 'Road'
			when 'S' then 'Other Sales'
			when 'T' then 'Touring'
			else 'n/a' 
		end as prd_line,

		prd_end_dt,
		prd_end_dt
	from bronze.crm_prd_info