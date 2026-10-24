# Validation record — 24 October 2026

## Executed environment

Microsoft SQL Server 2025 RTM-CU9 (17.0.5005.3), Enterprise Developer Edition, on the dedicated local Docker container `portfolio-warehouse-test`. The host is Apple Silicon and the image runs under x86 emulation. This succeeded as a local experiment; Microsoft does not support that emulation platform. SQL Server 2022 and cloud deployments were not tested.

The supplied source datasets were read from local files and normalized into gitignored staging. Neither original extracts nor row-level exports are included in the repository.

## Automated results

- 3 Python source-contract tests: passed.
- 7 SQL Server integration tests: passed.
- Included cases: totals and exclusion reconciliation, duplicate sales, conflicting order/customer ownership, missing-cost behaviour, Unicode/quoted CSV ingestion, repeat-run stability and missing-file rollback with a FAILED audit record.
- Original dataset loaded successfully after fixture tests. A second full refresh retained identical accepted line count and sales total.
- All six BI exports were generated and their JSON payloads parsed successfully; the exported fact file contains 60,345 data rows.

## Original-data reconciliation

| Measure | Observed result |
| --- | ---: |
| Raw CRM sales rows | 60,398 |
| Accepted analytical sales lines | 60,345 |
| Excluded sales rows | 53 |
| Customer dimension records | 18,484 |
| Current product dimension records | 295 |
| Distinct accepted orders | 27,656 |
| Accepted sales amount, source monetary units | 29,347,532.00 |
| Order-date range | 2010-12-29 through 2014-01-28 |
| Monthly reporting rows | 38 |

Sales exclusions: 22 invalid amount/quantity/price rows, 19 invalid date rows and 12 arithmetic mismatches. The first applicable reason is recorded per excluded row. The previous tutorial solution may repair some of these records and therefore produce different totals; the difference is intentional and must be disclosed.

Additional diagnostics: 6 duplicate CRM customer-ID rows, 4 invalid customer-key rows and 2 source product revisions with unknown cost. Product warnings do not imply the same number of unknown-cost sales lines.

## Example analytical findings

These describe accepted tutorial-dataset records, not a live business or achieved commercial results.

- Bikes account for 96.5% of accepted sales value. Category sales are 28,309,187 for Bikes, 699,279 for Accessories and 339,066 for Clothing. This is value concentration, not a complete profitability or demand forecast.
- Repeat buyers account for 77.0% of accepted sales value: 6,864 repeat buyers and 11,618 one-order buyers appear in the customer report. An appropriate next investigation is cohort/product-mix analysis; observed repeat purchases do not prove a retention intervention would cause growth.
- The 2010 period contains only 29–31 December, and 2014 ends on 28 January. Comparing either with a full year would be misleading. Monthly changes also need partial-period checks.

Reproduce using `scripts/gold/business_questions.sql` or the six local exports. Cost-derived profit is based on current product costs, not historical realised costs or accounting profit.

## Not completed or claimed

No incremental loading, CDC, live CRM/ERP integration, scheduler, alerting service, production security review, maintained historical dimension or new Power BI PBIX dashboard. SQL reports and CSV exports are working outputs. The original course material and licence are acknowledged in NOTICE.md.
