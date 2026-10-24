USE PortfolioWarehouse;
GO
CREATE OR ALTER PROCEDURE silver.load_silver @run_id BIGINT, @as_of_date DATE AS
BEGIN
 SET NOCOUNT ON;
 DELETE FROM silver.sales;
 DELETE FROM silver.products;
 DELETE FROM silver.customers;

 -- Latest valid CRM record per customer ID. Text tie-breakers are deterministic.
 SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY created_date DESC,
     customer_code, first_name, last_name, marital_status, gender) AS id_rank
 INTO #customer_candidates
 FROM (
   SELECT TRY_CONVERT(INT,cst_id) customer_id,
     NULLIF(UPPER(TRIM(cst_key)),'') customer_code,
     NULLIF(TRIM(cst_firstname),'') first_name, NULLIF(TRIM(cst_lastname),'') last_name,
     CASE UPPER(TRIM(cst_marital_status)) WHEN 'M' THEN 'Married' WHEN 'S' THEN 'Single' ELSE 'Unknown' END marital_status,
     CASE UPPER(TRIM(cst_gndr)) WHEN 'M' THEN 'Male' WHEN 'F' THEN 'Female' ELSE 'Unknown' END gender,
     TRY_CONVERT(DATE,cst_create_date,23) created_date
   FROM bronze.crm_cust_info
 ) c;
 INSERT audit.quality_issue
 SELECT @run_id,'customers',CONVERT(NVARCHAR(200),customer_id),
   CASE WHEN customer_id IS NULL OR customer_code IS NULL THEN 'INVALID_CUSTOMER_KEY' ELSE 'DUPLICATE_CUSTOMER_ID' END,
   'Excluded from customer dimension.'
 FROM #customer_candidates WHERE customer_id IS NULL OR customer_code IS NULL OR id_rank>1;
 SELECT *,ROW_NUMBER() OVER(PARTITION BY customer_code ORDER BY created_date DESC,customer_id DESC) code_rank
 INTO #customers FROM #customer_candidates WHERE customer_id IS NOT NULL AND customer_code IS NOT NULL AND id_rank=1;
 INSERT audit.quality_issue
 SELECT @run_id,'customers',customer_code,'DUPLICATE_CUSTOMER_CODE','Excluded duplicate code with a different ID.'
 FROM #customers WHERE code_rank>1;

 ;WITH erp AS (
   SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_code ORDER BY bdate DESC,gen DESC) rn
   FROM (SELECT CASE WHEN LEFT(UPPER(TRIM(cid)),3)='NAS' THEN SUBSTRING(UPPER(TRIM(cid)),4,252) ELSE UPPER(TRIM(cid)) END customer_code,
      bdate, gen FROM bronze.erp_cust_az12) x
 ), locations AS (
   SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_code ORDER BY cntry) rn
   FROM (SELECT REPLACE(UPPER(TRIM(cid)),'-','') customer_code, TRIM(cntry) cntry FROM bronze.erp_loc_a101) x
 )
 INSERT silver.customers
 SELECT c.customer_id,c.customer_code,c.first_name,c.last_name,c.marital_status,
   CASE WHEN c.gender<>'Unknown' THEN c.gender
        WHEN UPPER(TRIM(e.gen)) IN ('M','MALE') THEN 'Male'
        WHEN UPPER(TRIM(e.gen)) IN ('F','FEMALE') THEN 'Female' ELSE 'Unknown' END,
   CASE WHEN TRY_CONVERT(DATE,e.bdate,23)<=@as_of_date THEN TRY_CONVERT(DATE,e.bdate,23) END,
   CASE UPPER(l.cntry) WHEN 'DE' THEN 'Germany' WHEN 'US' THEN 'United States' WHEN 'USA' THEN 'United States'
     WHEN '' THEN 'Unknown' ELSE COALESCE(l.cntry,'Unknown') END,
   c.created_date
 FROM #customers c LEFT JOIN erp e ON c.customer_code=e.customer_code AND e.rn=1
 LEFT JOIN locations l ON c.customer_code=l.customer_code AND l.rn=1 WHERE c.code_rank=1;

 -- Source product revisions become non-overlapping [valid_from, valid_to) intervals.
 SELECT *,ROW_NUMBER() OVER(PARTITION BY product_code,valid_from ORDER BY source_product_id DESC,product_name,unit_cost DESC) rn
 INTO #products
 FROM (SELECT SUBSTRING(TRIM(prd_key),7,249) product_code,
   REPLACE(LEFT(TRIM(prd_key),5),'-','_') category_id,
   NULLIF(TRIM(prd_nm),'') product_name, TRY_CONVERT(INT,prd_id) source_product_id,
   TRY_CONVERT(DATE,prd_start_dt,23) valid_from,
   CASE WHEN TRY_CONVERT(DECIMAL(18,2),prd_cost)>=0 THEN TRY_CONVERT(DECIMAL(18,2),prd_cost) END unit_cost,
   CASE UPPER(TRIM(prd_line)) WHEN 'M' THEN 'Mountain' WHEN 'R' THEN 'Road' WHEN 'S' THEN 'Other Sales'
     WHEN 'T' THEN 'Touring' ELSE 'Unknown' END product_line
 FROM bronze.crm_prd_info) p;
 INSERT audit.quality_issue
 SELECT @run_id,'products',product_code,
   CASE WHEN product_code IS NULL OR product_code='' OR valid_from IS NULL THEN 'INVALID_PRODUCT_KEY_OR_DATE'
     WHEN rn>1 THEN 'DUPLICATE_PRODUCT_VERSION' ELSE 'UNKNOWN_COST' END,
   'Invalid versions excluded; invalid cost retained as NULL, never zero.'
 FROM #products WHERE product_code IS NULL OR product_code='' OR valid_from IS NULL OR rn>1 OR unit_cost IS NULL;
 ;WITH valid_products AS (
   SELECT *,LEAD(valid_from) OVER(PARTITION BY product_code ORDER BY valid_from) valid_to
   FROM #products WHERE product_code IS NOT NULL AND product_code<>'' AND valid_from IS NOT NULL AND rn=1
 ), categories AS (
   SELECT *,ROW_NUMBER() OVER(PARTITION BY id ORDER BY cat,subcat,maintenance) rn FROM bronze.erp_px_cat_g1v2
 )
 INSERT silver.products
 SELECT p.product_code,p.valid_from,p.valid_to,p.source_product_id,p.product_name,p.category_id,
   COALESCE(NULLIF(TRIM(c.cat),''),'Unknown'),COALESCE(NULLIF(TRIM(c.subcat),''),'Unknown'),
   COALESCE(NULLIF(TRIM(c.maintenance),''),'Unknown'),p.product_line,p.unit_cost
 FROM valid_products p LEFT JOIN categories c ON p.category_id=TRIM(c.id) AND c.rn=1;

 SELECT *,COUNT(*) OVER(PARTITION BY order_number,product_code) key_count
 INTO #sales
 FROM (SELECT NULLIF(TRIM(sls_ord_num),'') order_number,NULLIF(TRIM(sls_prd_key),'') product_code,
   TRY_CONVERT(INT,sls_cust_id) customer_id,
   CASE WHEN LEN(TRIM(sls_order_dt))=8 THEN TRY_CONVERT(DATE,sls_order_dt,112) END order_date,
   CASE WHEN LEN(TRIM(sls_ship_dt))=8 THEN TRY_CONVERT(DATE,sls_ship_dt,112) END ship_date,
   CASE WHEN LEN(TRIM(sls_due_dt))=8 THEN TRY_CONVERT(DATE,sls_due_dt,112) END due_date,
   TRY_CONVERT(DECIMAL(18,2),sls_sales) sales_amount,TRY_CONVERT(INT,sls_quantity) quantity,
   TRY_CONVERT(DECIMAL(18,2),sls_price) unit_price
 FROM bronze.crm_sales_details) s;
 SELECT s.*,CASE
   WHEN order_number IS NULL OR product_code IS NULL OR customer_id IS NULL THEN 'INVALID_SALES_KEY'
   WHEN key_count>1 THEN 'DUPLICATE_ORDER_PRODUCT'
   WHEN order_date IS NULL OR order_date>@as_of_date OR ship_date IS NULL OR due_date IS NULL
        OR ship_date<order_date OR due_date<order_date THEN 'INVALID_SALES_DATE'
   WHEN quantity IS NULL OR quantity<=0 OR sales_amount IS NULL OR sales_amount<0 OR unit_price IS NULL OR unit_price<0 THEN 'INVALID_SALES_AMOUNT'
   WHEN ABS(CONVERT(DECIMAL(28,2),sales_amount)-CONVERT(DECIMAL(28,2),quantity)*unit_price)>0.01 THEN 'SALES_ARITHMETIC_MISMATCH'
   WHEN NOT EXISTS(SELECT 1 FROM silver.customers c WHERE c.customer_id=s.customer_id) THEN 'UNMATCHED_CUSTOMER'
   WHEN NOT EXISTS(SELECT 1 FROM silver.products p WHERE p.product_code=s.product_code AND p.valid_to IS NULL) THEN 'UNMATCHED_PRODUCT'
 END rejection_reason
 INTO #classified FROM #sales s;
 INSERT audit.quality_issue
 SELECT @run_id,'sales',CONCAT(order_number,'|',product_code),rejection_reason,
   'Raw source row retained in Bronze; excluded from analytical sales.' FROM #classified WHERE rejection_reason IS NOT NULL;
 INSERT silver.sales
 SELECT order_number,product_code,customer_id,order_date,ship_date,due_date,sales_amount,quantity,unit_price
 FROM #classified WHERE rejection_reason IS NULL;
 INSERT audit.load_metric SELECT @run_id,'silver','customers',COUNT_BIG(*) FROM silver.customers;
 INSERT audit.load_metric SELECT @run_id,'silver','products',COUNT_BIG(*) FROM silver.products;
 INSERT audit.load_metric SELECT @run_id,'silver','sales',COUNT_BIG(*) FROM silver.sales;
END;
GO
