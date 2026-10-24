USE PortfolioWarehouse;
GO
IF OBJECT_ID(N'silver.customers',N'U') IS NULL
CREATE TABLE silver.customers (
    customer_id INT PRIMARY KEY,
    customer_code NVARCHAR(50) NOT NULL UNIQUE,
    first_name NVARCHAR(100), last_name NVARCHAR(100),
    marital_status NVARCHAR(20), gender NVARCHAR(20),
    birth_date DATE, country NVARCHAR(100), created_date DATE
);
IF OBJECT_ID(N'silver.products',N'U') IS NULL
CREATE TABLE silver.products (
    product_code NVARCHAR(50) NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE,
    source_product_id INT,
    product_name NVARCHAR(255), category_id NVARCHAR(50),
    category NVARCHAR(100), subcategory NVARCHAR(100),
    maintenance NVARCHAR(50), product_line NVARCHAR(50),
    unit_cost DECIMAL(18,2),
    PRIMARY KEY(product_code,valid_from),
    CHECK(valid_to IS NULL OR valid_to > valid_from),
    CHECK(unit_cost IS NULL OR unit_cost >= 0)
);
IF OBJECT_ID(N'silver.sales',N'U') IS NULL
CREATE TABLE silver.sales (
    order_number NVARCHAR(50) NOT NULL,
    product_code NVARCHAR(50) NOT NULL,
    customer_id INT NOT NULL REFERENCES silver.customers(customer_id),
    order_date DATE NOT NULL, ship_date DATE, due_date DATE,
    sales_amount DECIMAL(18,2) NOT NULL,
    quantity INT NOT NULL CHECK(quantity > 0),
    unit_price DECIMAL(18,2) NOT NULL CHECK(unit_price >= 0),
    PRIMARY KEY(order_number,product_code),
    CHECK(sales_amount >= 0)
);
GO
