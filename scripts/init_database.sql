/* Safe setup: never drops an existing database or user tables. */
USE master;
GO
IF DB_ID(N'PortfolioWarehouse') IS NULL
    CREATE DATABASE PortfolioWarehouse;
GO
USE PortfolioWarehouse;
GO
IF SCHEMA_ID(N'bronze') IS NULL EXEC(N'CREATE SCHEMA bronze');
IF SCHEMA_ID(N'silver') IS NULL EXEC(N'CREATE SCHEMA silver');
IF SCHEMA_ID(N'gold') IS NULL EXEC(N'CREATE SCHEMA gold');
IF SCHEMA_ID(N'audit') IS NULL EXEC(N'CREATE SCHEMA audit');
GO
IF OBJECT_ID(N'audit.etl_run',N'U') IS NULL
CREATE TABLE audit.etl_run (
    run_id BIGINT IDENTITY PRIMARY KEY,
    started_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    finished_at DATETIME2(3),
    status VARCHAR(12) NOT NULL,
    source_root NVARCHAR(1000) NOT NULL,
    as_of_date DATE NOT NULL,
    error_message NVARCHAR(4000)
);
IF OBJECT_ID(N'audit.quality_issue',N'U') IS NULL
CREATE TABLE audit.quality_issue (
    run_id BIGINT NOT NULL REFERENCES audit.etl_run(run_id),
    entity VARCHAR(40) NOT NULL,
    business_key NVARCHAR(200),
    reason VARCHAR(80) NOT NULL,
    detail NVARCHAR(1000)
);
IF OBJECT_ID(N'audit.load_metric',N'U') IS NULL
CREATE TABLE audit.load_metric (
    run_id BIGINT NOT NULL REFERENCES audit.etl_run(run_id),
    layer VARCHAR(10) NOT NULL,
    table_name SYSNAME NOT NULL,
    row_count BIGINT NOT NULL,
    PRIMARY KEY(run_id, layer, table_name)
);
GO
