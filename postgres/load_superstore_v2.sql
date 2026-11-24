-- Run using psql from the extracted folder containing data/ and postgres/.
-- This is an atomic installation in a separate schema. Re-running compares
-- an existing installation to the delivered files without modifying its rows.
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL DateStyle = 'ISO, YMD';
SELECT pg_advisory_xact_lock(hashtext(current_database()), hashtext('superstore_v2'));

DO $$
BEGIN
    IF current_database() <> 'superstore_data' THEN
        RAISE EXCEPTION 'Connect to the database named superstore_data before running this loader.';
    END IF;
END $$;

CREATE TEMP TABLE customers (
    customer_id text PRIMARY KEY,
    customer_name text NOT NULL,
    segment text NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE products (
    product_key integer PRIMARY KEY,
    product_id text NOT NULL,
    category text NOT NULL,
    sub_category text NOT NULL,
    product_name text NOT NULL,
    UNIQUE (product_id, product_name),
    UNIQUE (product_key, product_id)
) ON COMMIT DROP;

CREATE TEMP TABLE orders (
    order_id text PRIMARY KEY,
    order_date date NOT NULL,
    ship_date date NOT NULL CHECK (ship_date >= order_date),
    ship_mode text NOT NULL,
    customer_id text NOT NULL,
    country text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    postal_code text NOT NULL CHECK (postal_code ~ '^[0-9]{5}$'),
    region text NOT NULL,
    UNIQUE (order_id, customer_id)
) ON COMMIT DROP;

CREATE TEMP TABLE order_details (
    line_item_id integer PRIMARY KEY,
    order_id text NOT NULL,
    customer_id text NOT NULL,
    product_key integer NOT NULL,
    product_id text NOT NULL,
    sales numeric(19,4) NOT NULL,
    quantity integer NOT NULL CHECK (quantity > 0),
    discount numeric(9,4) NOT NULL CHECK (discount BETWEEN 0 AND 1),
    profit numeric(19,4) NOT NULL
) ON COMMIT DROP;

\copy pg_temp.customers FROM 'data/customers.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy pg_temp.products FROM 'data/products.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy pg_temp.orders FROM 'data/orders.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy pg_temp.order_details FROM 'data/order_details.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DO $$
BEGIN
    IF (SELECT count(*) FROM pg_temp.customers) <> 793
       OR (SELECT count(*) FROM pg_temp.orders) <> 5009
       OR (SELECT count(*) FROM pg_temp.products) <> 1894
       OR NOT (SELECT count(*) = 9994 AND count(DISTINCT product_id) = 1862
               AND count(DISTINCT order_id) = 5009 AND count(DISTINCT customer_id) = 793
               AND sum(sales) = 2297200.8603 AND sum(profit) = 286397.0217
               AND sum(quantity) = 37873 FROM pg_temp.order_details) THEN
        RAISE EXCEPTION 'Dataset population or exact financial reconciliation failed.';
    END IF;
    IF NOT (SELECT count(DISTINCT f.order_id) = 1544 AND count(DISTINCT f.customer_id) = 687
            FROM pg_temp.order_details f JOIN pg_temp.products p USING (product_key)
            WHERE p.category = 'Technology') THEN
        RAISE EXCEPTION 'Technology customer or order reconciliation failed.';
    END IF;
    IF NOT (SELECT sum(f.sales) IS NOT DISTINCT FROM 725457.8245 AND
                   sum(f.profit) IS NOT DISTINCT FROM 108418.4489
            FROM pg_temp.order_details f JOIN pg_temp.orders o USING (order_id)
            WHERE o.region = 'West') THEN
        RAISE EXCEPTION 'West transaction geography reconciliation failed.';
    END IF;
    IF (SELECT max(ship_date - order_date) FROM pg_temp.orders) > 7 THEN
        RAISE EXCEPTION 'Shipping interval is outside the validated sample.';
    END IF;
END $$;

SELECT EXISTS (SELECT FROM pg_namespace WHERE nspname = 'superstore_v2') AS already_present \gset
\if :already_present
    LOCK TABLE superstore_v2.customers, superstore_v2.products, superstore_v2.orders,
               superstore_v2.order_details IN SHARE MODE;
    DO $$
    DECLARE
        table_name text;
        differs boolean;
    BEGIN
        FOREACH table_name IN ARRAY ARRAY['customers', 'products', 'orders', 'order_details'] LOOP
            EXECUTE format(
                'SELECT EXISTS (
                    (SELECT * FROM pg_temp.%1$I EXCEPT ALL SELECT * FROM superstore_v2.%1$I)
                    UNION ALL
                    (SELECT * FROM superstore_v2.%1$I EXCEPT ALL SELECT * FROM pg_temp.%1$I)
                )', table_name
            ) INTO differs;
            IF differs THEN
                RAISE EXCEPTION 'Existing superstore_v2.% differs from the supplied dataset. No changes applied.', table_name;
            END IF;
        END LOOP;
    END $$;
    \echo Existing superstore_v2 population matches the supplied files.
\else
    CREATE SCHEMA superstore_v2;
    CREATE TABLE superstore_v2.customers (LIKE pg_temp.customers INCLUDING ALL);
    CREATE TABLE superstore_v2.products (LIKE pg_temp.products INCLUDING ALL);
    CREATE TABLE superstore_v2.orders (LIKE pg_temp.orders INCLUDING ALL);
    CREATE TABLE superstore_v2.order_details (LIKE pg_temp.order_details INCLUDING ALL);
    ALTER TABLE superstore_v2.orders
        ADD FOREIGN KEY (customer_id) REFERENCES superstore_v2.customers(customer_id);
    ALTER TABLE superstore_v2.order_details
        ADD FOREIGN KEY (order_id, customer_id)
            REFERENCES superstore_v2.orders(order_id, customer_id),
        ADD FOREIGN KEY (product_key, product_id)
            REFERENCES superstore_v2.products(product_key, product_id);

    INSERT INTO superstore_v2.customers SELECT * FROM pg_temp.customers;
    INSERT INTO superstore_v2.products SELECT * FROM pg_temp.products;
    INSERT INTO superstore_v2.orders SELECT * FROM pg_temp.orders;
    INSERT INTO superstore_v2.order_details SELECT * FROM pg_temp.order_details;
    CREATE INDEX ON superstore_v2.orders (order_date);
    CREATE INDEX ON superstore_v2.order_details (order_id);
    CREATE INDEX ON superstore_v2.order_details (product_key);
\endif

COMMIT;
\echo Verified superstore_v2 in superstore_data.
