"""Deterministic fictional test data. Not a replacement for the original dataset."""
import csv
from pathlib import Path
from prepare_sources import CONTRACTS

ROOT = Path(__file__).resolve().parents[1] / 'tests' / 'fixtures'
ROWS = {
'source_crm/cust_info.csv': [
 ['1','AW001','  Alex  ',' Demo ','S','M','2025-01-01'],
 ['1','AW001','Alex','Demo','M','M','2026-01-01'],
 ['2','AW002','Sam','Example','S','','2025-01-01'],
 ['3','AW003','Jo','Sample','','F','2025-01-01'],
 ['bad','INVALID','Bad','Key','','','2025-01-01']],
'source_crm/prd_info.csv': [
 ['10','CO-RF-P100','Demo component','40','R','2025-01-01','2025-12-31'],
 ['11','CO-RF-P100','Demo component','50','R','2026-01-01',''],
 ['20','BI-RD-P200','Demo assembly','100','M','2025-01-01','']],
'source_erp/cust_az12.csv': [['NASAW001','1990-01-01','Male'],['NASAW002','1992-06-12','Female'],['NASAW003','2999-01-01','Female']],
'source_erp/loc_a101.csv': [['AW-001','DE'],['AW-002','Finland'],['AW-003','US']],
'source_erp/px_cat_g1v2.csv': [['CO_RF','Components','Frames','Yes'],['BI_RD','Bikes','Road','Yes']],
'source_crm/sales_details.csv': [
 ['A001','P100','1','20250110','20250112','20250115','140','2','70'],
 ['A002','P100','1','20260210','20260212','20260215','80','1','80'],
 ['A003','P200','2','20260212','20260213','20260216','160','1','160'],
 ['A004','P200','2','20260302','20260305','20260306','320','2','160'],
 ['A004','P100','2','20260302','20260305','20260306','90','1','90'],
 ['BAD_DATE','P100','1','20260230','20260302','20260305','80','1','80'],
 ['BAD_QTY','P100','1','20260210','20260212','20260215','0','0','80'],
 ['BAD_MATH','P100','1','20260210','20260212','20260215','999','1','80'],
 ['BAD_CUSTOMER','P100','999','20260210','20260212','20260215','80','1','80'],
 ['BAD_PRODUCT','NOPE','1','20260210','20260212','20260215','80','1','80']],
}

if __name__ == '__main__':
    for relative, rows in ROWS.items():
        target = ROOT / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open('w', newline='', encoding='utf-8') as stream:
            writer = csv.writer(stream, lineterminator='\n')
            writer.writerow(CONTRACTS[relative]); writer.writerows(rows)
    print('Created six fictional fixture files.')
