"""Create a dedicated local SQL Server Developer container after explicit EULA acceptance."""
import argparse
import os
import platform
import secrets
import subprocess
from run_pipeline import DOCKER,ROOT

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--accept-eula',action='store_true',help='Accept Microsoft SQL Server container EULA')
    parser.add_argument('--allow-emulation',action='store_true',help='Allow unsupported x86 emulation on ARM for local testing')
    args=parser.parse_args()
    if not args.accept_eula:parser.error('Review Microsoft terms and supply --accept-eula before creating the container.')
    if platform.machine().lower() in ('arm64','aarch64') and not args.allow_emulation:
        parser.error('SQL Server requires x86-64. For a local ARM experiment only, also supply --allow-emulation.')
    (ROOT/'dataset').mkdir(exist_ok=True)
    env=os.environ.copy();env.setdefault('MSSQL_SA_PASSWORD','Wh!'+secrets.token_urlsafe(24))
    subprocess.run([DOCKER,'run','-d','--name','portfolio-warehouse-test','--platform','linux/amd64',
        '--memory','3g','--cpus','2','-p','127.0.0.1:14330:1433','-e','ACCEPT_EULA=Y',
        '-e','MSSQL_PID=Developer','-e','MSSQL_SA_PASSWORD','--mount',
        f'type=bind,source={ROOT}/dataset,target=/var/opt/mssql/datasets,readonly',
        'mcr.microsoft.com/mssql/server:2025-latest'],env=env,check=True)
    print('Created portfolio-warehouse-test. Wait for SQL Server readiness before running the pipeline.')
