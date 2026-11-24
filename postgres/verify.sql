-- Run at any time from psql or pgAdmin, using database superstore_data.
SELECT count(*) AS lines, count(DISTINCT order_id) AS orders,
       count(DISTINCT customer_id) AS purchasing_customers,
       count(DISTINCT product_id) AS product_ids,
       count(DISTINCT product_key) AS product_variants,
       sum(quantity) AS units, sum(sales) AS sales, sum(profit) AS profit,
       round(sum(profit) / nullif(sum(sales), 0) * 100, 4) AS margin_pct,
       round(sum(sales) / nullif(count(DISTINCT order_id), 0), 2) AS avg_order_value
FROM superstore_v2.order_details;

SELECT o.region, sum(f.sales) AS sales, sum(f.profit) AS profit
FROM superstore_v2.order_details f JOIN superstore_v2.orders o USING (order_id)
GROUP BY o.region ORDER BY sales DESC;

SELECT p.category, count(DISTINCT f.order_id) AS qualifying_orders,
       count(DISTINCT f.customer_id) AS purchasing_customers, sum(f.sales) AS sales,
       round(sum(f.sales) / nullif(count(DISTINCT f.order_id), 0), 2) AS avg_order_value
FROM superstore_v2.order_details f JOIN superstore_v2.products p USING (product_key)
GROUP BY p.category ORDER BY sales DESC;

SELECT min(order_date) AS earliest_order, max(order_date) AS latest_order,
       min(ship_date - order_date) AS shortest_shipment_days,
       max(ship_date - order_date) AS longest_shipment_days
FROM superstore_v2.orders;
