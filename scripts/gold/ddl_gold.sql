USE PortfolioWarehouse;
GO
CREATE OR ALTER VIEW gold.dim_customers AS
SELECT customer_id customer_key,customer_code customer_number,first_name,last_name,
    marital_status,gender,birth_date,country,created_date FROM silver.customers;
GO
CREATE OR ALTER VIEW gold.dim_products AS
SELECT CONCAT(product_code,'|',CONVERT(CHAR(8),valid_from,112)) product_key,
    product_code product_number,product_name,category_id,category,subcategory,maintenance,
    product_line,unit_cost,valid_from,valid_to FROM silver.products WHERE valid_to IS NULL;
GO
CREATE OR ALTER VIEW gold.fact_sales AS
SELECT s.order_number,s.product_code product_number,s.customer_id customer_key,
    p.product_key,s.order_date,s.ship_date,s.due_date,s.sales_amount,s.quantity,s.unit_price,
    p.unit_cost,
    CAST(s.quantity*p.unit_cost AS DECIMAL(28,2)) estimated_product_cost,
    CAST(s.sales_amount-s.quantity*p.unit_cost AS DECIMAL(28,2)) estimated_gross_profit
FROM silver.sales s JOIN gold.dim_products p ON s.product_code=p.product_number;
GO
CREATE OR ALTER VIEW gold.monthly_sales AS
SELECT DATEFROMPARTS(YEAR(order_date),MONTH(order_date),1) sales_month,
    COUNT(DISTINCT order_number) orders,COUNT_BIG(*) order_lines,SUM(quantity) units,
    SUM(sales_amount) sales_amount,
    SUM(estimated_gross_profit) known_cost_gross_profit,
    SUM(CASE WHEN unit_cost IS NULL THEN 1 ELSE 0 END) lines_missing_cost
FROM gold.fact_sales GROUP BY DATEFROMPARTS(YEAR(order_date),MONTH(order_date),1);
GO
