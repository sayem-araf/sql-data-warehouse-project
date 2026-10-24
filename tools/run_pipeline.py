"""Deploy SQL definitions and execute a full-refresh warehouse load in a named container."""
import argparse
from datetime import date
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ['scripts/init_database.sql', 'scripts/bronze/ddl_bronze.SQL',
           'scripts/silver/ddl_silver.sql', 'scripts/bronze/proc_load_bronze.sql',
           'scripts/silver/proc_load_silver.sql', 'scripts/gold/ddl_gold.sql',
           'scripts/quality/checks.sql', 'scripts/gold/analytics.sql']
DOCKER = shutil.which('docker') or '/Applications/Docker.app/Contents/Resources/bin/docker'


def sql(container, query, raw=False):
    # Use the container's existing secret without printing it or writing it to disk.
    script = 'export SQLCMDPASSWORD="$MSSQL_SA_PASSWORD"; exec /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -b -r 1 -W -w 65535 -s "|"'
    if raw:
        script = script.replace('-W -w 65535 -s \"|\"', '-d PortfolioWarehouse -y 0 -w 65535')
    result = subprocess.run([DOCKER, 'exec', '-i', container, 'sh', '-c', script],
                            input=query, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr + result.stdout)
    return result.stdout


def deploy(container):
    for relative in SCRIPTS:
        print(f'Applying {relative}')
        sql(container, (ROOT / relative).read_text())


def run(container, as_of):
    date.fromisoformat(as_of)
    return sql(container, f"USE PortfolioWarehouse; EXEC audit.run_pipeline @as_of_date='{as_of}';\nGO\n")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--container', default='portfolio-warehouse-test')
    parser.add_argument('--as-of', default=date.today().isoformat())
    parser.add_argument('--skip-deploy', action='store_true')
    args = parser.parse_args()
    if not args.skip_deploy:
        deploy(args.container)
    print(run(args.container, args.as_of))
    print(sql(args.container, 'USE PortfolioWarehouse; SELECT * FROM gold.monthly_sales ORDER BY sales_month;\nGO\n'))
