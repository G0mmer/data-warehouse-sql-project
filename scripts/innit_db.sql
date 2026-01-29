/*
Script purpose:
	create the database 'DataWarehouse', if there already exist one 
	it drop it and create the new one. It also creates schemas for  bronze,
	silver and gold layer

Warning:
	running the quey will delete the entire database and its data, make sure there exist
	a valid backup
*/
--escape the current db
use master;
go
--drop the db if exists
if exists (select 1 from sys.databases where name='DataWarehouse')
begin 
	alter database DataWarehouse set single_user with rollback immediate;
	drop database DataWarehouse 
end;
go

--create the db 
create database DataWarehouse;
go
--set the db as active
use DataWarehouse;

--create schemas
create schema bronze;
go
create schema silver;

create schema gold;

