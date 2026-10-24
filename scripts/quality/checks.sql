USE PortfolioWarehouse;
GO
CREATE OR ALTER PROCEDURE audit.assert_quality @run_id BIGINT AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM gold.fact_sales) THROW 51001,'No valid analytical sales were loaded.',1;
 IF (SELECT COUNT_BIG(*) FROM silver.sales)<>(SELECT COUNT_BIG(*) FROM gold.fact_sales)
    THROW 51002,'Gold join lost or multiplied sales lines.',1;
 IF (SELECT COUNT_BIG(*) FROM bronze.crm_sales_details)<>(SELECT COUNT_BIG(*) FROM silver.sales)
      +(SELECT COUNT_BIG(*) FROM audit.quality_issue WHERE run_id=@run_id AND entity='sales')
    THROW 51003,'Source sales do not reconcile to accepted plus rejected rows.',1;
 IF EXISTS(SELECT order_number FROM silver.sales GROUP BY order_number HAVING COUNT(DISTINCT customer_id)>1)
    THROW 51004,'An order belongs to multiple customers.',1;
 IF EXISTS(SELECT 1 FROM silver.products p JOIN silver.products q ON p.product_code=q.product_code
    AND p.valid_from<q.valid_from AND (p.valid_to IS NULL OR p.valid_to>q.valid_from))
    THROW 51005,'Product validity intervals overlap.',1;
 IF (SELECT COALESCE(SUM(sales_amount),0) FROM silver.sales)<>(SELECT COALESCE(SUM(sales_amount),0) FROM gold.fact_sales)
    THROW 51006,'Silver and Gold sales totals differ.',1;
END;
GO
CREATE OR ALTER PROCEDURE audit.run_pipeline
 @source_root NVARCHAR(1000)=N'/var/opt/mssql/datasets', @as_of_date DATE=NULL AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @as_of_date IS NULL SET @as_of_date=CONVERT(DATE,SYSUTCDATETIME());
 DECLARE @run_id BIGINT;
 INSERT audit.etl_run(status,source_root,as_of_date) VALUES('RUNNING',@source_root,@as_of_date);
 SET @run_id=SCOPE_IDENTITY();
 BEGIN TRY
   BEGIN TRANSACTION;
   DECLARE @lock_result INT;
   EXEC @lock_result=sys.sp_getapplock @Resource='portfolio-warehouse-full-refresh',
     @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=0;
   IF @lock_result<0 THROW 51007,'Another warehouse refresh is already running.',1;
   EXEC bronze.load_bronze @source_root,@run_id;
   EXEC silver.load_silver @run_id,@as_of_date;
   EXEC audit.assert_quality @run_id;
   UPDATE audit.etl_run SET status='SUCCEEDED',finished_at=SYSUTCDATETIME() WHERE run_id=@run_id;
   COMMIT TRANSACTION;
   SELECT @run_id run_id,'SUCCEEDED' status;
 END TRY
 BEGIN CATCH
   IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
   UPDATE audit.etl_run SET status='FAILED',finished_at=SYSUTCDATETIME(),error_message=ERROR_MESSAGE() WHERE run_id=@run_id;
   THROW;
 END CATCH;
END;
GO
