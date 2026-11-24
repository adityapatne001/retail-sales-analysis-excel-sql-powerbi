\set ON_ERROR_STOP on
BEGIN;
SET LOCAL DateStyle = 'ISO, YMD';
CREATE TEMP TABLE superstore_flat_analysis (
    order_id text NOT NULL,
    order_date date NOT NULL,
    ship_date date NOT NULL CHECK (ship_date >= order_date),
    ship_mode text NOT NULL,
    customer_id text NOT NULL,
    customer_name text NOT NULL,
    segment text NOT NULL,
    country text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    postal_code text NOT NULL,
    region text NOT NULL,
    product_id text NOT NULL,
    category text NOT NULL,
    sub_category text NOT NULL,
    product_name text NOT NULL,
    sales numeric(19,4) NOT NULL,
    quantity integer NOT NULL CHECK (quantity > 0),
    discount numeric(9,4) NOT NULL CHECK (discount BETWEEN 0 AND 1),
    profit numeric(19,4) NOT NULL,
    line_item_id integer PRIMARY KEY,
    product_key integer NOT NULL
) ON COMMIT DROP;
\copy pg_temp.superstore_flat_analysis (order_id, order_date, ship_date, ship_mode, customer_id, customer_name, segment, country, city, state, postal_code, region, product_id, category, sub_category, product_name, sales, quantity, discount, profit, line_item_id, product_key) FROM 'data/transactions.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Release-specific reconciliation; stop rather than analyze unexpected data.
DO $$
BEGIN
    IF NOT (SELECT count(*) = 9994 AND count(DISTINCT order_id) = 5009
        AND count(DISTINCT customer_id) = 793 AND count(DISTINCT product_id) = 1862
        AND count(DISTINCT product_key) = 1894 AND sum(quantity) = 37873
        AND sum(sales) = 2297200.8603 AND sum(profit) = 286397.0217
        AND max(ship_date - order_date) = 7 AND min(ship_date - order_date) = 0
        FROM pg_temp.superstore_flat_analysis) THEN
        RAISE EXCEPTION 'Flat-file validation failed.';
    END IF;
END $$;

-- 01. Executive KPIs. Counts are distinct within qualifying lines.
SELECT count(*) AS transaction_lines, count(DISTINCT order_id) AS total_orders,
       count(DISTINCT customer_id) AS purchasing_customers,
       count(DISTINCT product_id) AS product_ids, count(DISTINCT product_key) AS product_variants,
       sum(quantity) AS units_sold, round(sum(sales), 2) AS total_sales,
       round(sum(profit), 2) AS total_profit,
       round(100 * sum(profit) / nullif(sum(sales), 0), 2) AS profit_margin_pct,
       round(sum(sales) / nullif(count(DISTINCT order_id), 0), 2) AS avg_order_value
FROM pg_temp.superstore_flat_analysis;

-- 02. Top 10 product variants by sales (not by name alone).
SELECT product_key, product_id, product_name, round(sum(sales), 2) AS total_sales,
       round(sum(profit), 2) AS total_profit
FROM pg_temp.superstore_flat_analysis
GROUP BY product_key, product_id, product_name
ORDER BY sum(sales) DESC, product_key LIMIT 10;

-- 03. Monthly sales and profit; date ordering rather than alphabetic month names.
SELECT date_trunc('month', order_date)::date AS month_start,
       round(sum(sales), 2) AS monthly_sales, round(sum(profit), 2) AS monthly_profit
FROM pg_temp.superstore_flat_analysis
GROUP BY 1 ORDER BY 1;

-- 04. Year-month sales, using a display-friendly label.
SELECT to_char(order_date, 'YYYY-MM') AS year_month, round(sum(sales), 2) AS total_sales
FROM pg_temp.superstore_flat_analysis GROUP BY 1 ORDER BY 1;

-- 05. Category sales, profit, margin and share of total profit.
SELECT category, round(sum(sales), 2) AS total_sales, round(sum(profit), 2) AS total_profit,
       round(100 * sum(profit) / nullif(sum(sales), 0), 2) AS profit_margin_pct,
       round(100 * sum(profit) / nullif(sum(sum(profit)) OVER (), 0), 2) AS profit_share_pct,
       count(DISTINCT order_id) AS qualifying_orders,
       count(DISTINCT customer_id) AS purchasing_customers
FROM pg_temp.superstore_flat_analysis GROUP BY category ORDER BY sum(profit) DESC, category;

-- 06. Sales, profit and margin by order-destination region.
SELECT region, round(sum(sales), 2) AS total_sales, round(sum(profit), 2) AS total_profit,
       round(100 * sum(profit) / nullif(sum(sales), 0), 2) AS profit_margin_pct
FROM pg_temp.superstore_flat_analysis GROUP BY region ORDER BY sum(sales) DESC, region;

-- 07. Top 10 product variants by profit.
SELECT product_key, product_id, product_name, round(sum(profit), 2) AS total_profit
FROM pg_temp.superstore_flat_analysis GROUP BY product_key, product_id, product_name
ORDER BY sum(profit) DESC, product_key LIMIT 10;

-- 08. Category / subcategory profitability.
SELECT category, sub_category, round(sum(sales), 2) AS total_sales,
       round(sum(profit), 2) AS total_profit,
       round(100 * sum(profit) / nullif(sum(sales), 0), 2) AS profit_margin_pct
FROM pg_temp.superstore_flat_analysis GROUP BY category, sub_category
ORDER BY category, sum(profit) DESC, sub_category;

-- 09. Calendar-year growth; calculate using unrounded totals.
WITH yearly_sales AS (
    SELECT extract(year FROM order_date)::integer AS sales_year, sum(sales) AS total_sales
    FROM pg_temp.superstore_flat_analysis GROUP BY 1
), comparison AS (
    SELECT *, lag(total_sales) OVER (ORDER BY sales_year) AS prior_year_sales,
           lag(sales_year) OVER (ORDER BY sales_year) AS prior_year
    FROM yearly_sales
)
SELECT sales_year, round(total_sales, 2) AS total_sales,
       round(prior_year_sales, 2) AS prior_year_sales,
       CASE WHEN prior_year = sales_year - 1 THEN
           round(100 * (total_sales - prior_year_sales) / nullif(prior_year_sales, 0), 2)
       END AS yoy_growth_pct
FROM comparison ORDER BY sales_year;

-- 10. Discount vs profitability. Observational, not a causal estimate.
-- An order can occur in multiple discount levels; distinct counts are nonadditive.
SELECT discount AS discount_level, count(*) AS transaction_lines,
       count(DISTINCT order_id) AS qualifying_orders,
       round(sum(sales), 2) AS total_sales, round(sum(profit), 2) AS total_profit,
       round(100 * sum(profit) / nullif(sum(sales), 0), 2) AS profit_margin_pct
FROM pg_temp.superstore_flat_analysis GROUP BY discount ORDER BY discount;

-- 11. Source lines of product variants with overall negative profit (subquery).
SELECT line_item_id, order_id, order_date, product_key, product_id, product_name, sales, profit
FROM pg_temp.superstore_flat_analysis
WHERE product_key IN (
    SELECT product_key FROM pg_temp.superstore_flat_analysis
    GROUP BY product_key HAVING sum(profit) < 0
)
ORDER BY product_key, line_item_id;

-- 12. Five lowest-profit subcategories; signed amounts.
SELECT sub_category, round(sum(profit), 2) AS total_profit
FROM pg_temp.superstore_flat_analysis GROUP BY sub_category
ORDER BY sum(profit), sub_category LIMIT 5;

-- No persistent database objects are created by this script.
ROLLBACK;
