DROP TABLE IF EXISTS customers;
CREATE TABLE customers(
	customer_id VARCHAR PRIMARY KEY,
	customer_name VARCHAR,
	segment VARCHAR,
	country VARCHAR,
	city VARCHAR,
	state VARCHAR,
	postal_code VARCHAR,
	region VARCHAR
);

COPY customers(customer_id, customer_name, segment, country, city, state, postal_code, region)
FROM 'D:\DO_NOT_ENTER\Data analysis excel+sql+power bi\SQL Phase\customers.csv'
DELIMITER ','
CSV HEADER
ENCODING 'LATIN1';

SELECT * FROM customers;

DROP TABLE IF EXISTS products;
CREATE TABLE products(
	product_id VARCHAR PRIMARY KEY,
	category VARCHAR,
	sub_category VARCHAR,
	product_name VARCHAR
);

COPY products(product_id, category,	sub_category, product_name)
FROM 'D:\DO_NOT_ENTER\Data analysis excel+sql+power bi\SQL Phase\products.csv'
DELIMITER ','
CSV HEADER
ENCODING 'LATIN1';

SELECT * FROM products;

DROP TABLE IF EXISTS orders;
CREATE TABLE orders(
	order_id VARCHAR PRIMARY KEY,
	order_date DATE,
	ship_date DATE,
	ship_mode VARCHAR,
	customer_id VARCHAR,
	FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

COPY orders(order_id, order_date, ship_date, ship_mode, customer_id)
FROM 'D:\DO_NOT_ENTER\Data analysis excel+sql+power bi\SQL Phase\orders.csv'
DELIMITER ','
CSV HEADER
ENCODING 'LATIN1';

SELECT * FROM orders;

DROP TABLE IF EXISTS order_details;
CREATE TABLE order_details(
	order_id VARCHAR,
	product_id VARCHAR,
	sales NUMERIC,
	quantity INTEGER,
	discount NUMERIC,
	profit NUMERIC,
	PRIMARY KEY (order_id, product_id),
	FOREIGN KEY (order_id) REFERENCES orders(order_id),
	FOREIGN KEY (product_id) REFERENCES products(product_id)
);

COPY order_details(order_id, product_id, sales, quantity, discount, profit)
FROM 'D:\DO_NOT_ENTER\Data analysis excel+sql+power bi\SQL Phase\order_details.csv'
DELIMITER ','
CSV HEADER
ENCODING 'LATIN1';

SELECT * FROM order_details;

-- TOTAL SALES AND PROFIT BY CUSTOMER

SELECT c.customer_id, c.customer_name,
	   SUM(od.sales) AS total_sales,
	   SUM(od.profit) AS total_profit
FROM
customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON od.order_id = o.order_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_sales DESC;

-- TOTAL SALES BY REGION AND SEGMENT

SELECT c.region, c.segment,
	   SUM(od.sales) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON od.order_id = o.order_id
GROUP BY c.region, c.segment
ORDER BY c.region, total_sales DESC;

-- TOP 10 PRODUCTS BY TOTAL PROFIT

SELECT p.product_id,
 	   p.product_name,
	   SUM(od.profit) AS total_profit
FROM products p
JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_profit DESC
LIMIT 10;

-- Monthly Sales Trend

SELECT EXTRACT(YEAR FROM o.order_date) AS year,
	   TO_CHAR(o.order_date, 'FMMonth') AS month_name,
	   SUM(od.sales) AS total_sales
FROM orders o
JOIN order_details od ON od.order_id = o.order_id
GROUP BY year, EXTRACT(MONTH FROM o.order_date), month_name
ORDER BY year, EXTRACT(MONTH FROM o.order_date);

-- YEAR OVER YEAR SALES GROWTH

WITH yearly_growth AS (
	SELECT EXTRACT(YEAR FROM o.order_date) AS sales_year,
	SUM(od.sales) AS total_sales
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY sales_year
ORDER BY sales_year
)
SELECT *,
	   ROUND(((total_sales - LAG(total_sales) OVER(ORDER BY sales_year))/
	   LAG(total_sales) OVER(ORDER BY sales_year))*100, 2) AS YOY_GROWTH
FROM yearly_growth;

-- PRODUCTS WITH OVERALL NEGATIVE PROFIT

SELECT p.product_id,
	   p.product_name,
	   SUM(od.profit) AS total_profit
FROM products p
JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name
HAVING SUM(od.profit) < 0
ORDER BY total_profit;
