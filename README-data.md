# Corrected Superstore data

This edition preserves every transaction in the supplied 2014–2017 US Superstore file. Tableau describes Superstore as a fictitious company. Its published sample meets a requirement permitting publicly available sample data. It should be identified as a sample in the submission. [Tableau sample-data catalogue](https://public.tableau.com/app/resources/sample-data)

## Reconciliation

Monetary amounts below are USD. Totals use the original decimals before any display rounding.

| Population | Lines | Units | Orders | Buyers | Product IDs | Sales | Profit |
|---|---:|---:|---:|---:|---:|---:|---:|
| Original flat CSV and original details | 9,994 | 37,873 | 5,009 | 793 | 1,862 | 2,297,200.8603 | 286,397.0217 |
| Previously cleaned detail CSV | 9,986 | 37,840 | 5,009 | 793 | 1,862 | 2,295,509.5723 | 286,013.8196 |
| Corrected transactions and reconstructed model | 9,994 | 37,873 | 5,009 | 793 | 1,862 | 2,297,200.8603 | 286,397.0217 |
| Corrected, Technology only | 1,847 | 6,939 | 1,544 | 687 | 404 | 836,154.0330 | 145,454.9481 |
| Corrected, West only | 3,203 | 12,266 | 1,611 | 686 | 1,509 | 725,457.8245 | 108,418.4489 |

Restoring eight lines adds 33 units, $1,691.2880 sales and $383.2021 profit to the previous cleaned extract. Overall margin is 12.4672% and average order value is $458.61. Technology-only average order value is $541.55, computed as selected-category sales divided by orders containing that category. An order or customer can appear in more than one category. Distinct counts across categories are therefore nonadditive.

## Data files

| File in data/ | Rows | Grain and use |
|---|---:|---|
| transactions.csv | 9,994 | Standalone corrected flat file. Original 20 fields plus integer line_item_id and product_key. |
| order_details.csv | 9,994 | One record per original transaction line. Monetary and discount strings preserve the original decimals. |
| orders.csv | 5,009 | One row per order. Corrected order and ship dates and the order’s original country, city, state, postal code and region. |
| customers.csv | 793 | One customer per ID with verified name and segment. |
| products.csv | 1,894 | One record per original product ID/name combination. The same product_id can identify several documented variants. |
| date_reconciliation.csv | 5,009 | One original/corrected pair of dates and the resulting shipping interval for each order. Exclude this audit table from the report model. |

The four normalized tables reconstruct the corrected flat data exactly, field for field. Load either the four-table model or the flat file into a new analytical model. Including both as related sales facts can double-count sales.

### Corrections

- **Dates.** The uploaded ISO strings had already undergone a mixed day/month conversion. For this specific edition, reverse the day and month when the stored day is at most 12. Equal month and day values stay identical. Apply the rule independently to order and ship dates. It changes 1,836 order dates and 1,806 ship dates across 2,494 distinct orders. Independently published order and ship dates matched all 9,994 repaired rows. Each corrected order ships within zero to seven days. Dates cover January 3, 2014 through December 30, 2017 by order date and reach January 5, 2018 by ship date. The reconciliation CSV carries the input values for traceability. This is a one-time conversion for the uploaded edition. Import the corrected ISO dates directly. [Matching published edition](https://www.scribd.com/document/584053243/Sample-Superstore)
- **Transaction geography.** For each order, all source lines agree on country, city, state, ZIP and region. These fields now live on the order. Using the first location per customer instead disagrees with the source on 6,209 lines for region alone. All 449 four-character ZIP values in the US source received their missing leading zero. Read postal_code as text.
- **Repeated lines.** The original detail file matches the flat file line by line across all six detail fields. A line_item_id preserves its one-based input record position. Seven repeated order/product pairs contain distinct quantities or values. The eighth pair looks identical across the 20 uploaded fields, but the matching published edition lists separate row IDs 3406 and 3407. Both are present.
- **Products.** A product_key is assigned to each sorted pair of exact source product_id and product_name, starting at 1. Sorting uses the original Unicode strings, preserving accents and punctuation. This creates 1,894 variants for 1,862 source product IDs. Category and subcategory remain as recorded. Count source IDs for catalogue coverage and use product_key for variant drill-down or grouping. Reuse this release’s mapping when adding later data.
- **Types and precision.** Original Windows-1252 text was decoded and exported as UTF-8. CSV numbers preserve the source fractional digits. PostgreSQL uses numeric(19,4) for sales/profit and numeric(9,4) for discount. Quantity and keys are integers. A negative profit is a loss, and remains signed. Profit margin is total profit divided by total sales.
- **Source fingerprint.** The SHA-256 of the uploaded superstore(3).csv is `3ab73d2343154f181cc5dce94b1f4fa6840c01262d94843dfa934636c41ab8a5`.

## Connect PostgreSQL and Power BI on Windows

1. Extract the full ZIP. Open PowerShell in the folder containing the **data** and **postgres** directories. Start your local PostgreSQL service and use a database account with CREATE privilege in **superstore_data**. The commands assume PostgreSQL listens on localhost:5432 and the account is postgres. Substitute your local port and username if needed.
2. With psql version 10 or later on PATH, run the following from that folder. Enter your password at the prompt. If psql is unavailable on PATH, use its full executable path, for example `& "C:\Program Files\PostgreSQL\17\bin\psql.exe"`, in place of `psql`.

   ```powershell
   psql -X -h localhost -p 5432 -U postgres -d superstore_data -W -f ".\postgres\load_superstore_v2.sql"
   psql -X -h localhost -p 5432 -U postgres -d superstore_data -W -f ".\postgres\verify.sql"
   ```

3. Look for **Verified superstore_v2 in superstore_data** and compare the verification query outputs with the table above. The loader uses psql’s client-side COPY, so both the SQL client and the extracted CSVs must be accessible from this machine. All installed tables are under **superstore_v2**. Installation and checks run in one transaction. A repeated installation compares every stored row with the supplied tables and stops if the populations differ. The previous **public** schema can continue serving the original report.
4. Open the supplied updated **.pbip** in a recent Power BI Desktop for Windows. Keep the adjacent Report and SemanticModel folders in the same relative locations as supplied. Sign in to the PostgreSQL source **localhost** / **superstore_data** and refresh. If you installed PostgreSQL on another machine or port, update the server in all four business-table source queries first. A different Power BI database login needs USAGE on **superstore_v2** and SELECT on its four tables.
5. In Model view, confirm the active paths from customers to orders, the order-date calendar to orders, orders to details, and products to details via **product_key**. All geographic slicers and axes use **orders**. Distinct order and buyer measures use **order_details**. The existing binary PBIX can be kept separately. To work in PBIX format after opening and validating the updated project, use Desktop’s **Save as** and choose a new filename.
6. Test the unfiltered, Technology-only and West-only selections against the benchmarks above. A 2017-only selection must yield 693 distinct purchasing customers. The two sales/profit totals can be rounded to two decimals for display. Exporting or showing exact figures makes the reconciliation visible.

The self-contained dashboard works separately from this database installation. The SQL loader enforces its own run-time checks. Loading and refreshing your local PostgreSQL database and rendering the PBIP in Windows Desktop require those applications on your machine.
