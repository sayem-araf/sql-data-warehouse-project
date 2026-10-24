# CRM / ERP Sales Warehouse

A SQL Server learning project that turns six CRM/ERP CSV extracts into a cleaned sales model and reusable customer, product and monthly reporting views. The pipeline includes source validation, full-refresh transactions, run auditing, explicit row exclusions and executable regression checks.

**Tutorial-based portfolio work.** The original project and requirements are based on materials by Baraa Khatib Salkini. See [attribution](NOTICE.md). This is not a client deployment or evidence of production data-engineering experience.

## What runs

```text
CRM + ERP CSVs → contract validation → Bronze raw values → Silver cleaning
              → Gold dimensions + sales fact → customer / product / sales reports
```

- One current customer and product model, joined to order/product sales lines.
- Consistent source IDs, dates and numeric types; customer deduplication and ERP enrichment.
- Excluded sales are logged by reason and reconciled to raw source counts.
- A failed load rolls back all layers, retains the prior successful result and records the error.
- Repeat loads replace the snapshot without accumulating duplicate sales.
- Report CSV exports can be imported into Power BI. A new PBIX file is not included.

## Run the public fixture demo

Prerequisites: Python 3.10+, Docker, SQL Server 2025 with `sqlcmd` at `/opt/mssql-tools18/bin/sqlcmd`. Python scripts use the standard library only.

1. Read [Microsoft's SQL Server container setup and licensing guidance](https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker). On an x86-64 machine:

   ```sh
   python3 tools/start_sqlserver.py --accept-eula
   ```

   On Apple Silicon, add `--allow-emulation` only for a local experiment. Microsoft does not support SQL Server container emulation on ARM. A successful local test is not a supported deployment. The container is bound to `127.0.0.1:14330`, has a generated password and uses a separate `PortfolioWarehouse` database. It does not reuse or delete an existing warehouse.

2. Wait until SQL Server reports it is ready in `docker logs portfolio-warehouse-test`. Then stage the committed **fictional** fixtures:

   ```sh
   python3 tools/prepare_sources.py tests/fixtures
   python3 tools/run_pipeline.py --as-of 2026-10-24
   python3 tools/export_reports.py
   ```

   Expected fixture result: 10 raw sales lines, 5 accepted, 5 excluded; accepted sales 790 source monetary units. Original extracts are not bundled with these fixtures.

3. Inspect `gold.report_customers`, `gold.report_products`, `gold.sales_trends`, `audit.etl_run` and `audit.quality_issue`. Exported files appear in `output/gold/` and remain local.

To stop and resume the dedicated container, use `docker stop portfolio-warehouse-test` and `docker start portfolio-warehouse-test`. Removing it deletes its database; source CSVs remain in the host staging folder and can rebuild it. Do not remove containers belonging to other projects.

## Use original course extracts

```sh
python3 tools/prepare_sources.py /absolute/path/to/01_datasets
python3 tools/run_pipeline.py --as-of 2026-10-24
python3 tools/export_reports.py
```

Source preparation validates all six contracts before writing normalized, Unicode-safe bulk files under `dataset/`. It handles uppercase ERP filenames. The original folder is unchanged. Original extracts, local staging, exports and credentials are excluded from Git.

The load is deliberately a **full snapshot refresh**, not an incremental or streaming pipeline. Previous successful business rows remain readable if a refresh fails. Re-running initialization is non-destructive; do not run the old tutorial database-drop script against an existing database.

## Model and business questions

[Model, cleaning rules and metric definitions](docs/model-and-rules.md) explains the star model, fact grain, keys, source precedence, excluded records and limitations. [Business queries](scripts/gold/business_questions.sql) cover:

- Which product categories contribute most to sales and known-cost profit?
- How do one-order and repeat customers differ in sales contribution?
- How do sales change across adjacent observed months?
- Which records were excluded, and why?

Cost-based profit uses the latest product cost, not historical realised cost. It excludes operating expenses and has no FX or accounting-revenue treatment. Recency uses the last observed order date, and partial first/last months require care. Findings must disclose exclusions and dataset boundaries.

## Reproducible checks

```sh
python3 -m unittest discover -s tests -p 'test_sources.py' -v
DW_INTEGRATION=1 python3 -m unittest discover -s tests -p 'test_integration.py' -v
```

Source tests cover header/duplicate-file rejection and Unicode/quoted fields. SQL Server integration tests cover expected totals and exclusions, rerun stability, missing-file rollback, conflicting order ownership, duplicate sales, missing costs and Unicode ingestion. Integration tests deliberately replace the dedicated test database's snapshot with fixtures; **run the original-source pipeline again afterward** to restore the full dataset.

CI runs source checks only; SQL Server tests are an explicit local step. No cloud scheduling, live ERP connector, incremental merge, production access model or operational SLA is claimed.

## Repository guide

| Path | Purpose |
| --- | --- |
| `scripts/init_database.sql` | Create the separate database and audit objects safely |
| `scripts/bronze/` | Raw tables and CSV ingestion |
| `scripts/silver/` | Cleaning, enrichment and exclusion recording |
| `scripts/gold/` | Star views, reports and business queries |
| `scripts/quality/checks.sql` | Publication assertions and transactional orchestration |
| `tools/` | Setup, source preparation, execution and BI export |
| `tests/fixtures/` | Small fictional source files, including known data errors |
| `docs/` | Model documentation, validation results and upstream licence |

[Validation results](docs/validation.md) records what was actually run and the remaining boundaries.
