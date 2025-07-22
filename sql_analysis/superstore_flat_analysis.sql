DROP TABLE IF EXISTS superstore;
CREATE TABLE superstore(
	order_id VARCHAR(20),
	order_date DATE,
	ship_date DATE,
	ship_mode VARCHAR(50),
	customer_id VARCHAR(20),
	customer_name VARCHAR(100),
	segment VARCHAR(50),
	country VARCHAR(50),
	city VARCHAR(100),
	state VARCHAR(100),
	postal_code VARCHAR(10),
	region VARCHAR(50),
	product_id VARCHAR(50),
	category VARCHAR(50),
	sub_category VARCHAR(50),
	product_name VARCHAR(200),
	sales NUMERIC(10,2),
	quantity INT,
	discount NUMERIC(10,2),
	profit NUMERIC(10,2)
);

COPY superstore(order_id, order_date, ship_date, ship_mode, customer_id, customer_name, segment, country , city, 
	state, postal_code, region, product_id, category, sub_category, product_name, sales, quantity, discount, profit)
FROM 'D:\DO_NOT_ENTER\Data analysis excel+sql+power bi\SQL Phase\Superstore_Cleaned_For_SQL.csv'
DELIMITER ','
CSV HEADER
ENCODING 'LATIN1';

-- TOTAL SALES, TOTAL PROFIT, TOTAL QUANTITY

SELECT ROUND(SUM(sales), 2) as total_sales,
	   ROUND(SUM(profit), 2) as total_profit,
	   ROUND(SUM(quantity), 2) as total_quantity
FROM superstore;

-- TOP 10 PRODUCTS BY SALES

SELECT product_name,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore
GROUP BY product_name
ORDER BY total_sales DESC
LIMIT 10;

-- MONTHLY SALES TREND

SELECT EXTRACT(YEAR FROM order_date) AS year, 
	   TO_CHAR(order_date, 'Month') AS month_name,
	   ROUND(SUM(sales),2) AS monthly_sales
FROM superstore
GROUP BY year, EXTRACT(MONTH FROM order_date), month_name
ORDER BY year, EXTRACT(MONTH FROM order_date);

-- MONTHLY SALES TREND GROUPED BY YEAR-MONTH

SELECT TO_CHAR(order_date, 'YYYY-MM') AS year_month,
       SUM(sales) AS total_sales
FROM superstore
GROUP BY year_month
ORDER BY year_month; 

-- TOTAL PROFIT BY CATEGORY

SELECT category,
       ROUND(SUM(profit), 2) AS total_profit
FROM superstore
GROUP BY category
ORDER BY total_profit DESC;

-- SALES AND PROFIT BY REGION

SELECT region,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(SUM(profit), 2) AS total_profit
FROM superstore
GROUP BY region
ORDER BY total_sales DESC;

-- REGION WISE PROFITABILITY

SELECT  region, 
	    SUM(sales) AS total_sales,
		SUM(profit) AS total_profit,
		ROUND((SUM(profit) / NULLIF(SUM(sales), 0)) * 100, 2) AS profit_margin_pct
FROM superstore
GROUP BY region
ORDER BY total_profit DESC;

-- TOP 10 MOST PROFITABLE PRODUCTS

SELECT product_name,
       ROUND(SUM(profit), 2) AS total_profit
FROM superstore
GROUP BY product_name
ORDER BY total_profit DESC
LIMIT 10;

-- PROFIT BY CATEGORY/SUB-CATEGORY

SELECT category,
	   sub_category,
	   ROUND(SUM(profit), 2) AS total_profit
FROM superstore
GROUP BY category, sub_category
ORDER BY category, total_profit DESC;

-- YEAR-OVER-YEAR SALES COMPARISON (CTE + DATE FUNCTIONS)

with yearly_sales AS (
	SELECT EXTRACT(YEAR FROM order_date) AS sales_year,
		   ROUND(SUM(sales), 2) AS total_sales
    FROM superstore
	GROUP BY sales_year
)
SELECT *,
	   ROUND(((total_sales - LAG(total_sales) over(ORDER BY sales_year))/
	   LAG(total_sales) over(ORDER BY sales_year)) * 100, 2) AS yoy_growth_percentage
FROM yearly_sales;

-- Discount vs. Profitability Trend

SELECT
  ROUND(discount, 2) AS discount_level,
  COUNT(*) AS num_orders,
  SUM(profit) AS total_profit
FROM superstore
GROUP BY discount_level
ORDER BY discount_level;

-- Subquery Example — Products Generating Negative Profit

SELECT *
FROM superstore
WHERE product_name IN(
	SELECT product_name
	FROM superstore
	GROUP BY product_name
	HAVING SUM(profit) < 0)
ORDER BY product_name;
