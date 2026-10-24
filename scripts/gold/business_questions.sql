USE PortfolioWarehouse;
GO
-- 1. Which product categories contribute most to sales and known-cost profit?
SELECT category,SUM(total_sales) sales_amount,SUM(known_cost_gross_profit) known_cost_gross_profit,
 SUM(lines_missing_cost) lines_missing_cost
FROM gold.report_products GROUP BY category ORDER BY sales_amount DESC;
-- 2. How do one-order and repeat customers differ in sales contribution?
SELECT purchase_frequency,COUNT(*) customers,SUM(total_sales) sales_amount,
 CAST(SUM(total_sales)/NULLIF(SUM(total_orders),0) AS DECIMAL(18,2)) average_order_value
FROM gold.report_customers GROUP BY purchase_frequency;
-- 3. Which months have comparable changes? A gap is not a normal month-on-month change.
SELECT sales_month,sales_amount,previous_observed_month_sales,gap_months,
 CASE WHEN gap_months=1 THEN CAST(100.0*(sales_amount-previous_observed_month_sales)
   /NULLIF(previous_observed_month_sales,0) AS DECIMAL(18,2)) END month_on_month_pct
FROM gold.sales_trends ORDER BY sales_month;
-- 4. Which records were excluded, and why? Always disclose exclusions with findings.
SELECT r.run_id,q.entity,q.reason,COUNT(*) records
FROM audit.quality_issue q JOIN audit.etl_run r ON r.run_id=q.run_id
WHERE r.run_id=(SELECT MAX(run_id) FROM audit.etl_run WHERE status='SUCCEEDED')
GROUP BY r.run_id,q.entity,q.reason ORDER BY q.entity,records DESC;
GO
