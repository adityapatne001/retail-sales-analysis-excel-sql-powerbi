# Open the corrected seven-page Power BI report

**Open `powerbi/Superstore_Executive.pbip` in a current Power BI Desktop for Windows after loading PostgreSQL.** This is a separate editable project derived from the uploaded Superstore report. Its report and model use relative paths. Keep the `.pbip`, its sibling `.Report` folder and its sibling `.SemanticModel` folder together.

## Connect and refresh

1. Extract the complete delivery ZIP to a short local path, for example `C:\Superstore`. Follow **README-data.md** to install the four supplied tables in schema `superstore_v2` of database `superstore_data`. For example, from the extracted folder run `psql -X -h localhost -p 5432 -U postgres -d superstore_data -W -f ".\postgres\load_superstore_v2.sql"`. Run the supplied verification script from the same folder.
2. Open **powerbi → Superstore_Executive.pbip**. Use **Home → Refresh**. On the first database prompt choose database authentication and enter the PostgreSQL login authorized to read the corrected schema. Server and database default to `localhost` and `superstore_data`. The distribution omits the previous report's local data cache, so empty visuals before the first successful refresh are expected.
3. For a different host or port, use **Home → Transform data**. Select each of **customers, products, orders and order_details**, open **Advanced Editor**, and update the first two arguments of `PostgreSQL.Database`. For a nondefault port, use a server such as `localhost:5433`. Choose **Close & Apply**, then refresh. If prompted for an old login, change credentials under **File → Options and settings → Data source settings**.
4. Open **DAX query view**. Paste and run the contents of **powerbi/Validation.dax**. The first three comparison populations below are independent calculations from the normalized CSVs. Depending on the grid's display formatting, use an export or select a value to inspect its exact decimals.

   | Slice | Lines | Sales in USD | Profit in USD | Orders | Active buyers |
   |---|---:|---:|---:|---:|---:|
   | All | 9,994 | 2,297,200.8603 | 286,397.0217 | 5,009 | 793 |
   | Technology | 1,847 | 836,154.0330 | 145,454.9481 | 1,544 | 687 |
   | West | 3,203 | 725,457.8245 | 108,418.4489 | 1,611 | 686 |

   December 2017 sales should be **$83,829.3188**. The unfiltered Product Analysis cards should show **1,862 source IDs** and **1,894 ID/name variants**.

5. On Overview select **Technology** and confirm **1,544 orders** and **$541.55 sales per order**. Open **Customers** and confirm **687 purchasing customers**. Clear the category selection, select **West** and check the sales and profit totals. A navigation button in Desktop authoring mode may require Ctrl-click. Use the slicer's clear selection control to restore all values.
6. Confirm the monthly chart shows numerical Y ticks at fit-to-page and normal viewing size. Hover a month for full-dollar detail. Test all seven page tabs and check the **Mobile layout** preview. Save the project after refresh. To produce a PBIX in Desktop, choose **File → Save As** and select the Power BI report file type if available in your version.

## What changed

- The active report opens on a question about the gap between sales and profit. Five KPI cards and a filter-responsive takeaway lead into four analytical charts. They cover monthly trend, category comparison, lowest-profit subcategories and regional margin. The headline recomputes the leading category and lowest margin in the current context.
- The seven existing page IDs and destinations are preserved. Their new layouts share one title band, navigation row and synchronized year, destination and category filters. Positive and negative profit bars have distinct colors and signed values. Exact-value KPI bodies use larger type. Compact ranked tables use wrapped product labels and fewer borders.
- The native Overview trend expands from about 455 to **914 design pixels**. Its two new numeric measures divide sales/profit by 1,000, and the title states **USD thousands**. The chart uses unscaled numeric tick labels, full-dollar tooltip measures, standard-weight type, and fixed plot behavior. The old forced category spacing and 5% margin are removed. A tick of **80** means **$80,000**. A full-width phone position is authored separately.
- Region and state now filter **orders** and flow from order headers to individual lines. Product relationships use integer **product_key**. Display names that occur with several product IDs receive an ID suffix in product rankings. Counts of orders, purchasing customers and product IDs use qualifying **order_details** rows. Profit margin uses signed aggregate profit divided by sales. Sales per order uses qualifying-order count.
- The model retains cents and sub-cent precision using fixed decimal currency for source values. Counts and IDs have whole-number or text types as appropriate. The marked date table covers complete order years. MTD and YTD use the latest qualifying order in context. The Time page includes a cumulative monthly series that restarts each January.
- Seven phone page arrangements put filters and cards above single-column charts. Use the Power BI mobile app's page selector to move between pages.

## Updating another copy of the original report

The supplied PBIP already includes every change. Replacing only the SQL data source in the original PBIX will leave its original chart bindings, product relationship and KPI measures in place. For another copy that must retain later edits:

1. Save it as a **separate PBIP** and close Power BI Desktop. Open the supplied corrected PBIP separately for reference.
2. For a complete report/model replacement, use the supplied **Superstore_Executive.pbip** and its two sibling folders as the new project entry point. Bring any unrelated custom visuals from the old report over in Desktop after both are open.
3. For a selective merge, find the M queries in **powerbi/PowerQuery/** and the DAX/column definitions under **powerbi/Superstore_Executive.SemanticModel/definition/tables/**. Preserve the model display names **Customer_Name** and **Product_Name** by mapping them to the lowercase SQL source columns. M is already embedded in the four business-table TMDL files. **KPI_Measures.tmdl** contains the exact DAX for each measure.
4. In **Model view**, use one-to-many, single-direction relationships from **customers.customer_id → orders.customer_id**, **orders.order_id → order_details.order_id**, **products.product_key → order_details.product_key** and **Date_Table.Date → orders.order_date**. The original separate automatic ship-date hierarchy remains available. Bind every geographic slicer, chart, sort and Top N filter to **orders.region/state**, and bind product ranking labels and filters to **products[Product label]**.
5. Use **Validation.dax** and the filter checks above after every merge. Working from the complete supplied project is the quickest way to retain all 49 navigation links, 21 synchronized slicers and 28 analytical chart/table bindings.

## Verification boundary

The project paths, all JSON files, normalized source columns, primary and foreign keys, five relationship endpoints, chart and filter bindings, Top N field references, page destinations, and all 21 slicer memberships were statically checked. Each of the 28 analytical chart/table containers fits its desktop canvas. Desktop foreground elements and authored phone positions were checked for rectangle overlaps. The two copies of the original attached report were left intact.

The Power BI Desktop renderer, local PostgreSQL credentials and Power BI service were unavailable here. Native DAX execution, refresh, rendered axis labels, conditional visual appearance and phone rendering need the Windows checks above. The supplied file is a PBIP project. The original PBIX was not edited or run.

Microsoft documents report-definition files and local model caches in [the Power BI project report reference](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-report) and [the semantic model project reference](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-dataset).
