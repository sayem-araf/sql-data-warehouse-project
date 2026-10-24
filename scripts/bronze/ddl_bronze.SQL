USE PortfolioWarehouse;
GO
-- Preserve raw values, including malformed dates and numeric strings.
IF OBJECT_ID(N'bronze.crm_cust_info',N'U') IS NULL
CREATE TABLE bronze.crm_cust_info (
    cst_id NVARCHAR(255),
    cst_key NVARCHAR(255),
    cst_firstname NVARCHAR(255),
    cst_lastname NVARCHAR(255),
    cst_marital_status NVARCHAR(255),
    cst_gndr NVARCHAR(255),
    cst_create_date NVARCHAR(255)
);
GO
IF OBJECT_ID(N'bronze.crm_prd_info',N'U') IS NULL
CREATE TABLE bronze.crm_prd_info (
    prd_id NVARCHAR(255),
    prd_key NVARCHAR(255),
    prd_nm NVARCHAR(255),
    prd_cost NVARCHAR(255),
    prd_line NVARCHAR(255),
    prd_start_dt NVARCHAR(255),
    prd_end_dt NVARCHAR(255)
);
GO
IF OBJECT_ID(N'bronze.crm_sales_details',N'U') IS NULL
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num NVARCHAR(255),
    sls_prd_key NVARCHAR(255),
    sls_cust_id NVARCHAR(255),
    sls_order_dt NVARCHAR(255),
    sls_ship_dt NVARCHAR(255),
    sls_due_dt NVARCHAR(255),
    sls_sales NVARCHAR(255),
    sls_quantity NVARCHAR(255),
    sls_price NVARCHAR(255)
);
GO
IF OBJECT_ID(N'bronze.erp_cust_az12',N'U') IS NULL
CREATE TABLE bronze.erp_cust_az12 (
    cid NVARCHAR(255),
    bdate NVARCHAR(255),
    gen NVARCHAR(255)
);
GO
IF OBJECT_ID(N'bronze.erp_loc_a101',N'U') IS NULL
CREATE TABLE bronze.erp_loc_a101 (
    cid NVARCHAR(255),
    cntry NVARCHAR(255)
);
GO
IF OBJECT_ID(N'bronze.erp_px_cat_g1v2',N'U') IS NULL
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id NVARCHAR(255),
    cat NVARCHAR(255),
    subcat NVARCHAR(255),
    maintenance NVARCHAR(255)
);
GO
