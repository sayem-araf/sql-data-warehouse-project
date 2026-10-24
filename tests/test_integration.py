"""Runs only against the dedicated portfolio-warehouse-test SQL Server container."""
import csv
import json
import os
from pathlib import Path
import shutil
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from prepare_sources import prepare
from run_pipeline import sql,deploy,ROOT

CONTAINER='portfolio-warehouse-test'
SOURCE=ROOT/'dataset/_integration_source'
STAGED=ROOT/'dataset/_integration'

@unittest.skipUnless(os.getenv('DW_INTEGRATION')=='1','Set DW_INTEGRATION=1 for isolated SQL Server checks')
class WarehouseIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):deploy(CONTAINER)

    def setUp(self):
        if SOURCE.exists():shutil.rmtree(SOURCE)
        shutil.copytree(ROOT/'tests/fixtures',SOURCE)
        self.refresh()

    def refresh(self):
        prepare(SOURCE,STAGED)
        return sql(CONTAINER,"USE PortfolioWarehouse; EXEC audit.run_pipeline @source_root=N'/var/opt/mssql/datasets/_integration', @as_of_date='2026-10-24';\nGO\n")

    def query(self,query):
        value=sql(CONTAINER,'SET NOCOUNT ON; '+query+' FOR JSON PATH, INCLUDE_NULL_VALUES;\nGO\n',raw=True)
        return json.loads(''.join(value.splitlines()))

    def test_expected_totals_and_exclusion_reconciliation(self):
        rows=self.query('SELECT COUNT(*) lines,SUM(sales_amount) sales,SUM(estimated_gross_profit) profit FROM gold.fact_sales')
        self.assertEqual(rows,[{'lines':5,'sales':790.00,'profit':290.00}])
        rejects=self.query("SELECT COUNT(*) n FROM audit.quality_issue WHERE entity='sales' AND run_id=(SELECT MAX(run_id) FROM audit.etl_run)")
        self.assertEqual(rejects[0]['n'],5)
        self.assertEqual(self.query('SELECT COUNT(*) n FROM gold.report_customers')[0]['n'],2)
        self.assertEqual(self.query('SELECT COUNT(*) n FROM gold.report_products')[0]['n'],2)

    def test_rerun_does_not_duplicate_or_change_business_rows(self):
        before=self.query('SELECT * FROM gold.fact_sales ORDER BY order_number,product_number')
        self.refresh()
        self.assertEqual(before,self.query('SELECT * FROM gold.fact_sales ORDER BY order_number,product_number'))

    def test_missing_file_rolls_back_every_layer_and_logs_failure(self):
        before=self.query('SELECT * FROM gold.fact_sales ORDER BY order_number,product_number')
        (STAGED/'source_erp/loc_a101.csv').rename(STAGED/'source_erp/loc_a101.missing')
        with self.assertRaises(RuntimeError):
            sql(CONTAINER,"USE PortfolioWarehouse; EXEC audit.run_pipeline @source_root=N'/var/opt/mssql/datasets/_integration',@as_of_date='2026-10-24';\nGO\n")
        self.assertEqual(before,self.query('SELECT * FROM gold.fact_sales ORDER BY order_number,product_number'))
        self.assertEqual(self.query('SELECT TOP (1) status FROM audit.etl_run ORDER BY run_id DESC')[0]['status'],'FAILED')

    def test_duplicate_sales_are_explicitly_excluded(self):
        p=SOURCE/'source_crm/sales_details.csv'
        with p.open(newline='') as stream:rows=list(csv.reader(stream))
        with p.open('a',newline='') as stream:csv.writer(stream).writerow(rows[1])
        self.refresh()
        self.assertEqual(self.query('SELECT COUNT(*) n FROM gold.fact_sales')[0]['n'],4)
        r=self.query("SELECT COUNT(*) n FROM audit.quality_issue WHERE run_id=(SELECT MAX(run_id) FROM audit.etl_run) AND reason='DUPLICATE_ORDER_PRODUCT'")
        self.assertEqual(r[0]['n'],2)

    def test_conflicting_order_customer_aborts_publication(self):
        p=SOURCE/'source_crm/sales_details.csv'
        with p.open(newline='') as stream:rows=list(csv.reader(stream))
        rows[5][2]='1'
        with p.open('w',newline='') as stream:csv.writer(stream).writerows(rows)
        with self.assertRaises(RuntimeError):self.refresh()
        self.assertEqual(self.query('SELECT COUNT(*) n FROM gold.fact_sales')[0]['n'],5)

    def test_missing_cost_is_not_treated_as_zero(self):
        p=SOURCE/'source_crm/prd_info.csv'
        with p.open(newline='') as stream:rows=list(csv.reader(stream))
        rows[1][3]='';rows[2][3]=''
        with p.open('w',newline='') as stream:csv.writer(stream).writerows(rows)
        self.refresh()
        r=self.query('SELECT SUM(CASE WHEN unit_cost IS NULL THEN 1 ELSE 0 END) missing,SUM(estimated_gross_profit) known_profit FROM gold.fact_sales')[0]
        self.assertEqual(r,{'missing':3,'known_profit':180.00})

    def test_unicode_survives_sql_server_bulk_ingestion(self):
        p=SOURCE/'source_crm/cust_info.csv'
        with p.open(newline='') as stream:rows=list(csv.reader(stream))
        rows[2][2]='Åsa, "Demo"'
        with p.open('w',encoding='utf-8',newline='') as stream:csv.writer(stream).writerows(rows)
        self.refresh()
        self.assertEqual(self.query('SELECT first_name FROM gold.dim_customers WHERE customer_key=1')[0]['first_name'],'Åsa, "Demo"')
