USE PortfolioWarehouse;
GO
-- Reference date is the dataset's last order date, not the viewer's current date.
CREATE OR ALTER VIEW gold.report_customers AS
WITH base AS (
 SELECT customer_key,COUNT(DISTINCT order_number) total_orders,SUM(sales_amount) total_sales,
   SUM(quantity) total_units,COUNT(DISTINCT product_number) distinct_products,
   MIN(order_date) first_order_date,MAX(order_date) last_order_date
 FROM gold.fact_sales GROUP BY customer_key
), snapshot AS (SELECT MAX(order_date) as_of_date FROM gold.fact_sales)
SELECT c.customer_key,c.customer_number,c.country,b.total_orders,b.total_sales,b.total_units,
 b.distinct_products,b.first_order_date,b.last_order_date,s.as_of_date,
 DATEDIFF(DAY,b.last_order_date,s.as_of_date) days_since_last_order,
 CAST(b.total_sales/NULLIF(b.total_orders,0) AS DECIMAL(18,2)) average_order_value,
 CASE WHEN b.total_orders>1 THEN 'Repeat' ELSE 'One order' END purchase_frequency
FROM base b JOIN gold.dim_customers c ON c.customer_key=b.customer_key CROSS JOIN snapshot s;
GO
CREATE OR ALTER VIEW gold.report_products AS
SELECT p.product_key,p.product_number,p.product_name,p.category,p.subcategory,
 COUNT(DISTINCT f.order_number) total_orders,COUNT_BIG(*) order_lines,
 SUM(f.quantity) total_units,SUM(f.sales_amount) total_sales,
 SUM(f.estimated_gross_profit) known_cost_gross_profit,
 CAST(100.0*SUM(f.estimated_gross_profit)/NULLIF(SUM(CASE WHEN f.unit_cost IS NOT NULL THEN f.sales_amount END),0) AS DECIMAL(18,2)) known_cost_margin_pct,
 SUM(CASE WHEN f.unit_cost IS NULL THEN 1 ELSE 0 END) lines_missing_cost
FROM gold.fact_sales f JOIN gold.dim_products p ON p.product_key=f.product_key
GROUP BY p.product_key,p.product_number,p.product_name,p.category,p.subcategory;
GO
CREATE OR ALTER VIEW gold.sales_trends AS
SELECT sales_month,orders,order_lines,units,sales_amount,known_cost_gross_profit,lines_missing_cost,
 LAG(sales_amount) OVER(ORDER BY sales_month) previous_observed_month_sales,
 DATEDIFF(MONTH,LAG(sales_month) OVER(ORDER BY sales_month),sales_month) gap_months,
 SUM(sales_amount) OVER(PARTITION BY YEAR(sales_month) ORDER BY sales_month ROWS UNBOUNDED PRECEDING) year_to_date_sales
FROM gold.monthly_sales;
GO
