/*
================================
CREATE DATABASE 'DATA WAREHOUSE'
================================

Script Purpose:
	This script create a new database named 'DataWareHouse' after checking if it already exists.
	If the database exists, it is dropped and recreated. Additionally, the scripts set up three schemas
	within the database: 'bronze', 'silver' and 'gold'

Warning:
	Running this script will drop the entire 'DataWareHouse' if it exists.
	All data in the database will be permanently deleted. Proceed with caution
	and ensure you have proper backups before running this script.

*/

USE master;
GO

-- CREATE DATABASE 'DATA WAREHOUSE'

USE master;
GO

-- Drop and recreate the DataWarehouse database
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'DataWareHouse')
BEGIN
	ALTER DATABASE DataWareHouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWareHouse;
END
GO

--create the 'DataWareHouse' Database
CREATE DATABASE DataWareHouse;
GO

USE DataWareHouse;
GO

--create schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
