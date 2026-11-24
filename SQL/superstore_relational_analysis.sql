BEGIN TRANSACTION READ ONLY;

-- 01. Executive KPIs.
SELECT count(*) AS transaction_lines, count(DISTINCT f.order_id) AS total_orders,
       count(DISTINCT f.customer_id) AS purchasing_customers,
       count(DISTINCT f.product_id) AS product_ids, count(DISTINCT f.product_key) AS product_variants,
       sum(f.quantity) AS units_sold, round(sum(f.sales), 2) AS total_sales,
       round(sum(f.profit), 2) AS total_profit,
       round(100 * sum(f.profit) / nullif(sum(f.sales), 0), 2) AS profit_margin_pct,
       round(sum(f.sales) / nullif(count(DISTINCT f.order_id), 0), 2) AS avg_order_value
FROM superstore_v2.order_details f;

-- 02. Customer sales and profit (explicit customer -> order -> line joins).
SELECT c.customer_id, c.customer_name, count(DISTINCT f.order_id) AS qualifying_orders,
       round(sum(f.sales), 2) AS total_sales, round(sum(f.profit), 2) AS total_profit
FROM superstore_v2.customers c
JOIN superstore_v2.orders o ON o.customer_id = c.customer_id
JOIN superstore_v2.order_details f ON f.order_id = o.order_id AND f.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name ORDER BY sum(f.sales) DESC, c.customer_id;

-- 03. Region and segment sales; region follows the order destination.
SELECT o.region, c.segment, round(sum(f.sales), 2) AS total_sales,
       round(sum(f.profit), 2) AS total_profit
FROM superstore_v2.customers c
JOIN superstore_v2.orders o ON o.customer_id = c.customer_id
JOIN superstore_v2.order_details f ON f.order_id = o.order_id AND f.customer_id = o.customer_id
GROUP BY o.region, c.segment ORDER BY o.region, sum(f.sales) DESC, c.segment;

-- 04. Top 10 product variants by profit; use the unique variant key.
SELECT p.product_key, p.product_id, p.product_name, round(sum(f.profit), 2) AS total_profit,
       round(sum(f.sales), 2) AS total_sales
FROM superstore_v2.products p JOIN superstore_v2.order_details f ON f.product_key = p.product_key
GROUP BY p.product_key, p.product_id, p.product_name
ORDER BY sum(f.profit) DESC, p.product_key LIMIT 10;

-- 05. Monthly sales and profit.
SELECT date_trunc('month', o.order_date)::date AS month_start,
       round(sum(f.sales), 2) AS total_sales, round(sum(f.profit), 2) AS total_profit
FROM superstore_v2.orders o JOIN superstore_v2.order_details f ON f.order_id = o.order_id
GROUP BY 1 ORDER BY 1;

-- 06. Year-over-year sales growth (CTE + LAG, with zero protection).
WITH yearly_sales AS (
    SELECT extract(year FROM o.order_date)::integer AS sales_year, sum(f.sales) AS total_sales
    FROM superstore_v2.orders o JOIN superstore_v2.order_details f ON f.order_id = o.order_id
    GROUP BY 1
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

-- 07. Product variants with overall negative profit.
SELECT p.product_key, p.product_id, p.product_name, round(sum(f.profit), 2) AS total_profit
FROM superstore_v2.products p JOIN superstore_v2.order_details f ON f.product_key = p.product_key
GROUP BY p.product_key, p.product_id, p.product_name
HAVING sum(f.profit) < 0 ORDER BY sum(f.profit), p.product_key;

-- 08. Category performance, with counts from qualifying fact rows.
-- Orders and customers may appear in more than one category.
SELECT p.category, count(DISTINCT f.order_id) AS qualifying_orders,
       count(DISTINCT f.customer_id) AS purchasing_customers,
       round(sum(f.sales), 2) AS total_sales, round(sum(f.profit), 2) AS total_profit,
       round(100 * sum(f.profit) / nullif(sum(f.sales), 0), 2) AS profit_margin_pct,
       round(sum(f.sales) / nullif(count(DISTINCT f.order_id), 0), 2) AS avg_order_value
FROM superstore_v2.order_details f JOIN superstore_v2.products p ON p.product_key = f.product_key
GROUP BY p.category ORDER BY sum(f.sales) DESC, p.category;

-- 09. Region performance including profit margin and distinct counts.
SELECT o.region, count(DISTINCT f.order_id) AS qualifying_orders,
       count(DISTINCT f.customer_id) AS purchasing_customers,
       round(sum(f.sales), 2) AS total_sales, round(sum(f.profit), 2) AS total_profit,
       round(100 * sum(f.profit) / nullif(sum(f.sales), 0), 2) AS profit_margin_pct
FROM superstore_v2.order_details f JOIN superstore_v2.orders o ON o.order_id = f.order_id
GROUP BY o.region ORDER BY sum(f.sales) DESC, o.region;

-- 10. Five lowest-profit subcategories.
SELECT p.sub_category, round(sum(f.profit), 2) AS total_profit
FROM superstore_v2.order_details f JOIN superstore_v2.products p ON p.product_key = f.product_key
GROUP BY p.sub_category ORDER BY sum(f.profit), p.sub_category LIMIT 5;

-- 11. Customer-segment performance.
SELECT c.segment, round(sum(f.sales), 2) AS total_sales, round(sum(f.profit), 2) AS total_profit,
       count(DISTINCT f.customer_id) AS purchasing_customers
FROM superstore_v2.order_details f JOIN superstore_v2.customers c ON c.customer_id = f.customer_id
GROUP BY c.segment ORDER BY sum(f.sales) DESC, c.segment;

-- 12. Reconcile the four-table join with the fact table; no dropped or multiplied lines.
WITH joined AS (
    SELECT count(*) AS lines, count(DISTINCT f.line_item_id) AS distinct_lines,
           sum(f.sales) AS sales, sum(f.profit) AS profit
    FROM superstore_v2.order_details f
    JOIN superstore_v2.orders o ON o.order_id = f.order_id AND o.customer_id = f.customer_id
    JOIN superstore_v2.customers c ON c.customer_id = o.customer_id
    JOIN superstore_v2.products p ON p.product_key = f.product_key AND p.product_id = f.product_id
), fact AS (
    SELECT count(*) AS lines, sum(sales) AS sales, sum(profit) AS profit
    FROM superstore_v2.order_details
)
SELECT joined.*, (joined.lines = fact.lines AND joined.distinct_lines = fact.lines
       AND joined.sales = fact.sales AND joined.profit = fact.profit) AS join_reconciled
FROM joined CROSS JOIN fact;
COMMIT;
