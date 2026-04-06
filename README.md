# sql-data-warehouse-project
Building a modern data warehouse with SQL server, ETL process, data modeling and analytics


Complete SQL Server + Docker + macOS Setup Guide

1. Install Docker Desktop

Download: https://docs.docker.com/desktop/
Choose Mac (Apple or Intel chip)
Open and let it start (1-2 minutes)
2. Start SQL Server Container (First Time)

docker run -d \
  --name sqlserver \
  -e ACCEPT_EULA=Y \
  -e SA_PASSWORD=Economix22 \
  -p 1433:1433 \
  -v sqlserver_data:/var/opt/mssql \
  -v ~/Desktop/sql-data-warehouse-project/datasets:/var/opt/mssql/datasets \
  mcr.microsoft.com/mssql/server:latest
Why each flag:

-d = run in background
--name sqlserver = give container a name
-e ACCEPT_EULA=Y = accept license
-e SA_PASSWORD=Economix22 = set admin password
-p 1433:1433 = map port from Mac to container
-v sqlserver_data:/var/opt/mssql = persistent data storage (won't lose data on restart)
-v ~/Desktop/...:/var/opt/mssql/datasets = mount your Mac folder so SQL Server can read CSV files
3. Install mssql Extension in VS Code

Open VS Code
Extensions (Cmd + Shift + X)
Search mssql
Install "SQL Server (mssql)" by Microsoft
4. Connect in VS Code

Press Cmd + Shift + P
Type MS SQL: Add Connection
Fill in:
Server: localhost,1433
Authentication: SQL Login
User: sa
Password: Economix22
Trust certificate: checked
Click Connect
5. Create Database & Tables Right-click connection → New Query, then run:

CREATE DATABASE Datawarehouse;
GO
USE Datawarehouse;
GO
CREATE TABLE bronze.crm_cust_info (
    -- your columns here
);
GO
6. Load Data from CSV

USE Datawarehouse;
GO
BULK INSERT bronze.crm_cust_info
FROM '/var/opt/mssql/datasets/source_crm/cust_info.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);
GO
Important:

Use /var/opt/mssql/datasets/... (container path), NOT /Users/... (Mac path)
Docker's volume mount translates the container path to your actual Mac folder
7. Verify Data

SELECT COUNT(*) FROM bronze.crm_cust_info;
GO
SELECT * FROM bronze.crm_cust_info;
GO
8. Manage Container

# Check if running
docker ps

# Stop
docker stop sqlserver

# Start (data persists)
docker start sqlserver

# View logs
docker logs sqlserver

# Check volume storage
docker volume inspect sqlserver_data
Key Concepts:

Container = isolated SQL Server environment on your Mac
Volume mounts (-v) = bridges between Mac files and container
Persistent storage = data saved on Mac, not lost on restart
localhost:1433 = how your Mac connects to container
What Went Wrong Before:

First container had no -v sqlserver_data → data was lost on restart
No dataset volume mount → couldn't read CSV files
Solution: Use both -v flags as shown above
