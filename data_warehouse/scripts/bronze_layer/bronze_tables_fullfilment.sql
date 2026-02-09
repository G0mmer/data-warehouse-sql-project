/* 
Script purpose:
	This script creates the procedure to generate the bronze layer within the db. It drops the tables if
	they exist and create new one from the source files.

Parameters:
	path configuration
	   before running this querry mkae sure to change the variable for the path
	   where you store the cloned repository; aslo set query->sqlcmd mode to make the line 6 work

Example Usage:
	exec bronze.load_bronze
*/

create or alter procedure bronze.load_bronze as 
begin
declare @start_time datetime, @end_time datetime, @total_time_start datetime, @total_time_end datetime;
	begin try
		set @total_time_start= getdate();
		print'>>No errors encounterd proceidng to the loading...'
		print'>>The path to cloned repository is correct; loading the bronze layer';


		print 'loading crm tables';

		:setvar ProjectPath "C:\Users\Cezary\Desktop\data-warehouse-sql-project"

		set @start_time = getdate();
		print '>>Truncate the cust_info table'
		truncate table bronze.crm_cust_info;

		print '>>Performing a bulk insert of cust_info table'
		bulk insert bronze.crm_cust_info
		from '$(ProjectPath)\datasets\source_crm\cust_info.csv'
		with(
			firstrow=2,
			fieldterminator=',',
			tablock
		);
		set @end_time = getdate();
		print '>>Loading time: '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+ ' seconds';
		print' ';

		set @start_time = getdate();
		print '>>Truncate the prd_info table'
		truncate table bronze.crm_prd_info;

		print '>>Performing a bulk insert of prd_info table'
		bulk insert bronze.crm_prd_info
		from '$(ProjectPath)\datasets\source_crm\prd_info.csv'
		with(
			firstrow=2,
			fieldterminator=',',
			tablock
		);
		set @end_time = getdate();
		print '>>Loading time: '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+ ' seconds';
		print' ';


		set @start_time = getdate();
		print '>>Truncate the sales_details table'
		truncate table bronze.crm_sales_details;

		print '>>Performing a bulk insert of sales_details table'
		bulk insert bronze.crm_sales_details
		from '$(ProjectPath)\datasets\source_crm\sales_details.csv'
		with(
			firstrow=2,
			fieldterminator=',',
			tablock
		);
		set @end_time = getdate();
		print '>>Loading time: '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+ ' seconds';
		print' ';
		print 'loading erp tables';

		set @start_time = getdate();
		print '>>Truncate the cust_az12 table'
		truncate table bronze.erp_cust_az12;

		print '>>Performing a bulk insert of cust_az12 table'
		bulk insert bronze.erp_cust_az12
		from '$(ProjectPath)\datasets\source_erp\CUST_AZ12.csv'
		with(
			firstrow=2,
			fieldterminator=',',
			tablock
		);
		set @end_time = getdate();
		print '>>Loading time: '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+ ' seconds';
		print' ';

		set @start_time = getdate();
		print '>>Truncate the loc_a101 table'
		truncate table bronze.erp_loc_a101;

		print '>>Performing a bulk insert of loc_a101 table'
		bulk insert bronze.erp_loc_a101
		from '$(ProjectPath)\datasets\source_erp\LOC_A101.csv'
		with(
			firstrow=2,
			fieldterminator=',',
			tablock
		);
		set @end_time = getdate();
		print '>>Loading time: '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+ ' seconds';
		print' ';

		set @start_time = getdate();
		print '>>Truncate the PX_CAT_G1V2 table'
		truncate table bronze.erp_px_cat_g1v2;

		print '>>Performing a bulk insert of PX_CAT_G1V2 table'
		bulk insert bronze.erp_px_cat_g1v2
		from '$(ProjectPath)\datasets\source_erp\PX_CAT_G1V2.csv'
		with(
			firstrow=2,
			fieldterminator=',',
			tablock
		);
		set @end_time = getdate();
		print '>>Loading time: '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+ ' seconds';
		print' ';
		print '>>Completed loading the Bronze Layer'
		set @total_time_end = getdate()
		print '>>Total loading time: '+ cast(datediff(second,@total_time_start,@total_time_end) as nvarchar(50))+ ' seconds';
	
	end try
	begin catch 
		print'>>An erro has occured, check if the path to the cloned repositoy is correct, 
				or data types matches the one chosen in table_creation file'
		print '>>Error message' + error_message();
		print '>>Error Number' + cast(error_number() as nvarchar(50))
	end catch
end