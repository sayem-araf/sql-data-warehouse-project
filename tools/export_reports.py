"""Export the verified Gold model to local CSVs for BI tools; outputs are gitignored."""
import argparse
import csv
import json
from pathlib import Path
from run_pipeline import ROOT,sql

VIEWS=['dim_customers','dim_products','fact_sales','report_customers','report_products','sales_trends']


def rows(container,query):
    result=sql(container,'SET NOCOUNT ON; '+query+' FOR JSON PATH, INCLUDE_NULL_VALUES;\nGO\n',raw=True)
    return json.loads(''.join(result.splitlines()))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--container',default='portfolio-warehouse-test')
    parser.add_argument('--output',type=Path,default=ROOT/'output'/'gold')
    args=parser.parse_args();args.output.mkdir(parents=True,exist_ok=True)
    for name in VIEWS:
        records=rows(args.container,'SELECT * FROM gold.'+name)
        target=args.output/(name+'.csv')
        with target.open('w',encoding='utf-8',newline='') as stream:
            if records:
                writer=csv.DictWriter(stream,fieldnames=list(records[0]));writer.writeheader();writer.writerows(records)
        print(f'{name}: {len(records)} rows -> {target.name}')
