/*
==========================================
A SQL Server-based data warehouse built on the medallion architecture (bronze, silver, gold schemas). 
This project provides a structured approach to data ingestion, transformation, and analytics-ready data layers.

WARNING:
  Running this will drop the entire 'DataWarehouse' database if it exists.
  All data in the database will be permanently deleted. Proceed with caution and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN 
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

  -- Create Database 'DataWarehouse
  
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

-- Creating Tables

IF OBJECT_ID ('bronze.crm_cust_info' , 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
    cst_id NVARCHAR(50),
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_latname NVARCHAR(50),
    cst_material_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_craete_date DATE
);
  
IF OBJECT_ID ('bronze.crm_prd_info' , 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info (
    prd_id INT,
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost INT,
    prd_line NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt DATETIME     
);
IF OBJECT_ID ('bronze.crm_sales_details' , 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id NVARCHAR(50),
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT
);
IF OBJECT_ID ('bronze.erp_cust_az12' , 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
CREATE TABLE bronze.erp_cust_az12 (
    cid NVARCHAR(50),
    bdate DATETIME,
    gen NVARCHAR(50),
);
IF OBJECT_ID ('bronze.erp_loc_a101' , 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
CREATE TABLE bronze.erp_loc_a101 (
    cid NVARCHAR(50),
    cntry NVARCHAR(50),
);
IF OBJECT_ID ('bronze.erp_px_cat_g1v2' , 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id NVARCHAR(50),
    cat NVARCHAR(50),
    subcat NVARCHAR(50),
    maintenance NVARCHAR(50)
);

-- Uploading Data
-- creating stored procedure


 CREATE OR ALTER PROCEDURE bronze.load_bronze AS
 BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '==============================================================='
        PRINT 'Loading data into Bronze layer...'
        PRINT '==============================================================='

        PRINT '---------------------------------------------------------------'
        PRINT 'Loading CRM data...'
        PRINT '---------------------------------------------------------------'

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_cust_info'
        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '>> Loading data'
        BULK INSERT bronze.crm_cust_info
        FROM '/var/opt/mssql/datasets/source_crm/cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time =GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------------------'

        SET @start_time = GETDATE();
        PRINT'>> Truncating Table: bronze.crm_loc_info'
        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '>> Loading data'
        BULK INSERT bronze.crm_prd_info
        FROM '/var/opt/mssql/datasets/source_crm/prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time =GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------------------'

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_sales_details'
        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '>> Loading data'
        BULK INSERT bronze.crm_sales_details
        FROM '/var/opt/mssql/datasets/source_crm/sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time =GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------------------'   

        PRINT '---------------------------------------------------------------'
        PRINT 'Loading ERP data...'
        PRINT '---------------------------------------------------------------'

        SET @start_time = GETDATE();
        PRINT '>>  Truncating Table: bronze.erp_cust_az12'
        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT '>> Loading data'
        BULK INSERT bronze.erp_cust_az12
        FROM '/var/opt/mssql/datasets/source_erp/cust_az12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time =GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------------------'   

        SET @start_time = GETDATE();    
        PRINT '>> Truncating Table: bronze.erp_prd_b56'
        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '>> Loading data'
        BULK INSERT bronze.erp_loc_a101
        FROM '/var/opt/mssql/datasets/source_erp/loc_a101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time =GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------------------'
        
        SET @start_time = GETDATE();    
        PRINT '>> TRUNCATING Table: bronze.erp_sales_f34'
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT '>> Loading data'
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM '/var/opt/mssql/datasets/source_erp/px_cat_g1v2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time =GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------------------'

        SET @batch_end_time = GETDATE();
        PRINT '==============================================================='
        PRINT 'Loading Bronze Layer completed successfully.'    
        PRINT 'Total Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
    END TRY
    BEGIN CATCH
        PRINT '==============================================================='
        PRINT 'Error occurred while loading data into Bronze layer:'
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'ERROR State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==============================================================='
    END CATCH
END 
