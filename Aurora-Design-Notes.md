# Superstore Profit Observatory — Aurora Design Edition

This package builds on the previously supplied corrected-data/PBIP project.

## Changes in this update
- Replaced the included standalone dashboard with the richer Aurora palette.
- Applied a color-only palette transformation to all seven PBIP page and visual JSON definition files.
- Updated the shared CY24SU10 Power BI theme color palette to blue, mint, violet, amber, coral, and cyan.
- Preserved all CSV files, DAX measures, model definitions, Power Query transformations, and SQL loaders unchanged.

## Publishing
- The public `chatgpt.site` site is **not** automatically updated by this ZIP.
- The self-contained `Superstore-Overview.html` can be renamed `index.html` for static hosting.
- See the separate `Superstore-Aurora-Web-Ready.zip` for a ready-to-host index.html.

## Power BI Desktop verification still required
Open `powerbi/Superstore_Executive.pbip`, refresh your data, review every page for color contrast and label rendering, and save as PBIX if desired. Visual JSON/theme edits were checked for JSON validity, but **not rendered inside Power BI Desktop**. Make a backup before replacing any active report.

## Data provenance and limitations
The Superstore dataset is the fictitious sample associated with Tableau. This is not a real retailer's business data.
