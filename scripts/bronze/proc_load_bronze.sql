USE PortfolioWarehouse;
GO
CREATE OR ALTER PROCEDURE bronze.load_bronze @source_root NVARCHAR(1000), @run_id BIGINT AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @sql NVARCHAR(MAX), @path NVARCHAR(1500), @rows BIGINT;
 TRUNCATE TABLE bronze.crm_cust_info;
 SET @path = @source_root + N'/source_crm/cust_info.csv';
 SET @sql = N'BULK INSERT bronze.crm_cust_info FROM ''' + REPLACE(@path, '''', '''''') + ''' WITH (FORMAT=''CSV'', FIRSTROW=2, ROWTERMINATOR=''0x0a00'', DATAFILETYPE=''widechar'', TABLOCK, KEEPNULLS, MAXERRORS=0);';
 EXEC sys.sp_executesql @sql;
 SELECT @rows=COUNT_BIG(*) FROM bronze.crm_cust_info;
 INSERT audit.load_metric VALUES(@run_id,'bronze','crm_cust_info',@rows);
 TRUNCATE TABLE bronze.crm_prd_info;
 SET @path = @source_root + N'/source_crm/prd_info.csv';
 SET @sql = N'BULK INSERT bronze.crm_prd_info FROM ''' + REPLACE(@path, '''', '''''') + ''' WITH (FORMAT=''CSV'', FIRSTROW=2, ROWTERMINATOR=''0x0a00'', DATAFILETYPE=''widechar'', TABLOCK, KEEPNULLS, MAXERRORS=0);';
 EXEC sys.sp_executesql @sql;
 SELECT @rows=COUNT_BIG(*) FROM bronze.crm_prd_info;
 INSERT audit.load_metric VALUES(@run_id,'bronze','crm_prd_info',@rows);
 TRUNCATE TABLE bronze.crm_sales_details;
 SET @path = @source_root + N'/source_crm/sales_details.csv';
 SET @sql = N'BULK INSERT bronze.crm_sales_details FROM ''' + REPLACE(@path, '''', '''''') + ''' WITH (FORMAT=''CSV'', FIRSTROW=2, ROWTERMINATOR=''0x0a00'', DATAFILETYPE=''widechar'', TABLOCK, KEEPNULLS, MAXERRORS=0);';
 EXEC sys.sp_executesql @sql;
 SELECT @rows=COUNT_BIG(*) FROM bronze.crm_sales_details;
 INSERT audit.load_metric VALUES(@run_id,'bronze','crm_sales_details',@rows);
 TRUNCATE TABLE bronze.erp_cust_az12;
 SET @path = @source_root + N'/source_erp/cust_az12.csv';
 SET @sql = N'BULK INSERT bronze.erp_cust_az12 FROM ''' + REPLACE(@path, '''', '''''') + ''' WITH (FORMAT=''CSV'', FIRSTROW=2, ROWTERMINATOR=''0x0a00'', DATAFILETYPE=''widechar'', TABLOCK, KEEPNULLS, MAXERRORS=0);';
 EXEC sys.sp_executesql @sql;
 SELECT @rows=COUNT_BIG(*) FROM bronze.erp_cust_az12;
 INSERT audit.load_metric VALUES(@run_id,'bronze','erp_cust_az12',@rows);
 TRUNCATE TABLE bronze.erp_loc_a101;
 SET @path = @source_root + N'/source_erp/loc_a101.csv';
 SET @sql = N'BULK INSERT bronze.erp_loc_a101 FROM ''' + REPLACE(@path, '''', '''''') + ''' WITH (FORMAT=''CSV'', FIRSTROW=2, ROWTERMINATOR=''0x0a00'', DATAFILETYPE=''widechar'', TABLOCK, KEEPNULLS, MAXERRORS=0);';
 EXEC sys.sp_executesql @sql;
 SELECT @rows=COUNT_BIG(*) FROM bronze.erp_loc_a101;
 INSERT audit.load_metric VALUES(@run_id,'bronze','erp_loc_a101',@rows);
 TRUNCATE TABLE bronze.erp_px_cat_g1v2;
 SET @path = @source_root + N'/source_erp/px_cat_g1v2.csv';
 SET @sql = N'BULK INSERT bronze.erp_px_cat_g1v2 FROM ''' + REPLACE(@path, '''', '''''') + ''' WITH (FORMAT=''CSV'', FIRSTROW=2, ROWTERMINATOR=''0x0a00'', DATAFILETYPE=''widechar'', TABLOCK, KEEPNULLS, MAXERRORS=0);';
 EXEC sys.sp_executesql @sql;
 SELECT @rows=COUNT_BIG(*) FROM bronze.erp_px_cat_g1v2;
 INSERT audit.load_metric VALUES(@run_id,'bronze','erp_px_cat_g1v2',@rows);
END;
GO
