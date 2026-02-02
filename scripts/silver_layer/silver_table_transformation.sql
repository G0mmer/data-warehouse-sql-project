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
insert into silver.crm_prd_info(
prd_id ,
cat_id ,
prd_key ,
prd_nm ,
prd_cost ,
prd_line ,
prd_start_dt,
prd_end_dt 
)
	select 
		prd_id,
		--divide the prd_key into two distinct columns as first five letters stay for category id
		replace(substring(prd_key,1,5),'-','_')  as cat_id,
		substring(prd_key,7,len(prd_key)) as prd_key,
		prd_nm,
		--null handling (0 makes further calculations easier)
		isnull(prd_cost,0) as prd_cost,
		--sticking to convention the mapping to full prodcution lines
		case upper(trim(prd_line))
			when 'M' then 'Mountain'
			when 'R' then 'Road'
			when 'S' then 'Other Sales'
			when 'T' then 'Touring'
			else 'n/a' 
		end as prd_line,
		--as time is alwasys 00:00:00 switch dtype to date in both columns
		cast(prd_start_dt as date) as prd_start_dt,
		--to avoid scenarios where end date is smaller then starting date we make it the start date of next update and substract 1
		cast (Lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 as date ) as prd_end_dt
	from bronze.crm_prd_info

---------------
--sales_details
---------------
insert into silver.crm_sales_details(
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
)

select 
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	--for dates, if there is 0 change it to null; then rest change the dtype to date
	case 
		when 
			len(sls_order_dt)!=8 
			or sls_order_dt not between 19000000 and 20270000
		then null
		else cast(cast(sls_order_dt as varchar(50)) as date)	
		end as sls_order_dt,
	case 
		when 
			len(sls_ship_dt)!=8 
			or sls_ship_dt not between 19000000 and 20270000
		then null
		else cast(cast(sls_ship_dt as varchar(50)) as date)	
		end as sls_ship_dt,
	case 
		when 
			len(sls_due_dt)!=8 
			or sls_due_dt not between 19000000 and 20270000
		then null
		else cast(cast(sls_due_dt as varchar(50)) as date)	
		end as sls_due_dt,
	--to handle the errors in sales, when it is null or id doesn't corespond to its products, recalcluate it 
	case 
		when sls_sales is null or (sls_quantity>0 and sls_price>0 and sls_sales!=sls_price*sls_quantity) then sls_price*sls_quantity
		else sls_sales end as sls_sales, 
	--as there is no error in quantities we keep it like this
	sls_quantity,
	--when negative remove the minus, if 0 or null and quantity is positive (true for evry item in this table) calulat it form sales
	case 
		when sls_price<0 then abs(sls_price)
		when (sls_price=0 or sls_price is null) and sls_quantity>0 then sls_sales/sls_quantity
		else sls_price end as sls_price
from bronze.crm_sales_details

-----------
--cust_az12
-----------
insert into silver.erp_cust_az12(
cid,
bdate,
gen
)
select
--trim cid if needed
case 
	when cid like 'NAS%' then substring(cid,4,len(cid))
	else cid end as cid,
--if bdate higher then current date cut it off
case 
	when bdate> getdate() then null
	else bdate end as bdate,
--clean the gender column
case 
	when trim(upper(gen)) in ('M','MALE') then 'Male'
	when trim(upper(gen)) in ('F','FEMALE') then 'Female'
	else 'n/a' end as gen 
from bronze.erp_cust_az12