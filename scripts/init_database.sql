/*-- Create Database 'Datawarehouse'
==========================================
A SQL Server-based data warehouse built on the medallion architecture (bronze, silver, gold schemas). 
This project provides a structured approach to data ingestion, transformation, and analytics-ready data layers.

WARNING:
  Running this will drop the entire 'DataWarehouse' database if it exists.
  All data in the database will be permanently deleted. Proceed with caution and ensure you have proper backups before running this script.
*/

USE master;
GO

CREATE DATABASE Datawarehouse;
GO

USE Datawarehouse;
GO

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
