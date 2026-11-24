# SQL analysis — corrected edition

Both analytical scripts were revised in November 2026 to work with the same corrected sample used by the Power BI, Excel and web dashboards. All values are USD. Original CSVs and historical SQL scripts should be retained separately as historical material, not used as the final data model.

## Prerequisites

- PostgreSQL and its psql client; a database named `superstore_data`.
- Run from the project root (the folder that contains `data`, `SQL`, and `postgres`).
- Install the corrected schema with `postgres/load_superstore_v2.sql` and verify with `postgres/verify.sql` if not already installed. If your existing `superstore_v2` schema passed verification, skip the installation step.

## Files

| Script | Purpose | Side effects |
|---|---|---|
| `postgres/load_superstore_v2.sql` | Install and verify the four corrected relational tables | Creates a separate schema on first installation; re-runs compare existing data without rewriting it |
| `postgres/verify.sql` | Validate installed totals, geography, category counts and date ranges | Read-only |
| `SQL/superstore_flat_analysis.sql` | Import `data/transactions.csv` into a temporary table and analyze it | Temporary table only; transaction rolled back at the end |
| `SQL/superstore_relational_analysis.sql` | Analyze `superstore_v2` via joins and window functions | Read-only transaction |

## Run in PowerShell (from project root)

```powershell
psql -X -v ON_ERROR_STOP=1 -h localhost -p 5432 -U postgres -d superstore_data -W -f ".\postgres\verify.sql"
psql -X -v ON_ERROR_STOP=1 -h localhost -p 5432 -U postgres -d superstore_data -W -f ".\SQL\superstore_flat_analysis.sql"
psql -X -v ON_ERROR_STOP=1 -h localhost -p 5432 -U postgres -d superstore_data -W -f ".\SQL\superstore_relational_analysis.sql"
```

If psql is not on PATH, invoke your installed executable using `& "D:\PostgreSQL\bin\psql.exe"` (or the actual installation location). Passwords are entered interactively and are not stored in the scripts.

The flat script uses psql's `\copy` and `\set`, so use **psql**, not the pgAdmin Query Tool. The relational script also runs in pgAdmin Query Tool (connect to `superstore_data`; select individual query blocks to see each result). For the flat script, the corrected ISO dates must be imported directly, not repaired a second time.

## Expected results

| Metric | Expected |
|---|---:|
| Transaction lines | 9,994 |
| Orders | 5,009 |
| Purchasing customers | 793 |
| Product IDs | 1,862 |
| Product variants | 1,894 |
| Units | 37,873 |
| Sales (exact) | 2297200.8603 |
| Profit (exact) | 286397.0217 |
| Profit margin | 12.47% |
| Average order value | 458.61 |
| Technology orders / customers | 1,544 / 687 |
| West sales / profit | 725457.8245 / 108418.4489 |
| Final relational join check | `join_reconciled = true` |

The original analytical queries have been retained or expanded, but their source, key definitions, date handling, precision and order counts have been corrected. Rankings use product variants, not names or nonunique source IDs alone. Annual growth uses unrounded aggregates and guards against missing/zero prior-year denominators. Discount-level counts distinguish transaction lines from distinct orders. Orders and customers can belong to multiple product categories or discount levels; those distinct counts must not be added across groups.

## Verification status

The supplied flat file was independently compared, field for field, against the four normalized CSV tables. All 9,994 lines and exact financial benchmarks above match. The revised query definitions were reviewed against the actual PostgreSQL loader schema. PostgreSQL itself was not available in the environment used to prepare these scripts; execute the commands locally to confirm runtime results.
