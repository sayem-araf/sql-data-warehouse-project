"""Validate six CSV contracts and stage local copies; never modifies input files."""
import argparse
import csv
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACTS = {
    'source_crm/cust_info.csv': ['cst_id','cst_key','cst_firstname','cst_lastname','cst_marital_status','cst_gndr','cst_create_date'],
    'source_crm/prd_info.csv': ['prd_id','prd_key','prd_nm','prd_cost','prd_line','prd_start_dt','prd_end_dt'],
    'source_crm/sales_details.csv': ['sls_ord_num','sls_prd_key','sls_cust_id','sls_order_dt','sls_ship_dt','sls_due_dt','sls_sales','sls_quantity','sls_price'],
    'source_erp/cust_az12.csv': ['cid','bdate','gen'],
    'source_erp/loc_a101.csv': ['cid','cntry'],
    'source_erp/px_cat_g1v2.csv': ['id','cat','subcat','maintenance'],
}


def prepare(source, destination):
    source, destination = Path(source).resolve(), Path(destination).resolve()
    all_files = list(source.rglob('*.csv')) + list(source.rglob('*.CSV'))
    staged = []
    for relative, columns in CONTRACTS.items():
        matches = [p for p in all_files if p.name.lower() == Path(relative).name]
        if len(matches) != 1:
            raise ValueError(f'{relative}: expected exactly one input file; found {len(matches)}')
        path = matches[0]
        with path.open(encoding='utf-8-sig', newline='') as stream:
            reader = csv.reader(stream)
            header = next(reader, [])
            if [c.strip().lower() for c in header] != columns:
                raise ValueError(f'{relative}: column order differs from the documented contract')
            rows = list(reader)
            if not rows or any(len(row) != len(columns) for row in rows):
                raise ValueError(f'{relative}: empty file or wrong field count')
        staged.append((relative, columns, rows))
    for relative, columns, rows in staged:
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        # Normalize UTF-8 inputs into UTF-16 bulk files; preserve Unicode on SQL Server Linux.
        with target.open('w', encoding='utf-16', newline='') as stream:
            writer = csv.writer(stream, lineterminator='\n')
            writer.writerow(columns)
            writer.writerows(rows)
        print(f'{relative}: {len(rows)} source rows staged')
    return staged


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('--destination', type=Path, default=ROOT / 'dataset')
    args = parser.parse_args()
    prepare(args.source, args.destination)
