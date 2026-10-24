# Local source staging

Run `python3 tools/prepare_sources.py /absolute/path/to/original/datasets`.

The six CRM/ERP source CSVs are validated for header order and field counts, then written here as UTF-16 CSVs with LF line endings for SQL Server Linux bulk ingestion. Original extracts are never changed. Dataset files are ignored by Git; do not commit original extracts or exported customer-level records.

Small fictional, UTF-8 regression fixtures are committed under `tests/fixtures/`. Stage those explicitly with `python3 tools/prepare_sources.py tests/fixtures` when running the public demo.
