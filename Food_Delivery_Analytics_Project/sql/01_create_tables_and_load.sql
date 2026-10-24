-- ============================================================
-- Food Delivery Analytics Project - MySQL setup
-- Step 1: create database & tables   Step 2: load the CSV files
-- ============================================================
DROP DATABASE IF EXISTS food_delivery;
CREATE DATABASE food_delivery CHARACTER SET utf8mb4;
USE food_delivery;

CREATE TABLE orders (
    order_id          VARCHAR(10)  PRIMARY KEY,   -- unique: one row = one order
    order_date        DATE         NOT NULL,
    order_time        TIME         NOT NULL,
    customer_id       VARCHAR(10)  NOT NULL,
    restaurant_name   VARCHAR(60)  NOT NULL,
    city              VARCHAR(30)  NOT NULL,
    cuisine           VARCHAR(30)  NOT NULL,
    quantity          INT          NOT NULL,
    unit_price        INT          NOT NULL,      -- Rs per item
    discount_amount   INT          NOT NULL,      -- Rs off the whole order
    net_amount        INT          NOT NULL,      -- quantity*unit_price - discount_amount
    payment_method    VARCHAR(30)  NOT NULL,
    order_status      VARCHAR(15)  NOT NULL,      -- Delivered / Cancelled
    delivery_time_min INT          NULL,          -- NULL = not available
    customer_rating   INT          NULL           -- NULL = not rated
);

CREATE TABLE dim_restaurants (
    restaurant_id    VARCHAR(5) PRIMARY KEY,
    restaurant_name  VARCHAR(60) NOT NULL,
    city             VARCHAR(30) NOT NULL,
    cuisine          VARCHAR(30) NOT NULL,
    restaurant_type  VARCHAR(20) NOT NULL,
    partner_since    DATE
);

CREATE TABLE dim_city (
    city       VARCHAR(30) PRIMARY KEY,
    state      VARCHAR(30) NOT NULL,
    city_tier  VARCHAR(10) NOT NULL,
    region     VARCHAR(10) NOT NULL
);

-- Change the path to where you saved the CSV files.
-- Windows example: 'C:/food_delivery/data/cleaned_food_delivery_orders.csv'
-- (If LOAD DATA is blocked, run:  SET GLOBAL local_infile = 1;  and connect with local-infile enabled.
--  Or use MySQL Workbench: right-click table > Table Data Import Wizard.)
LOAD DATA LOCAL INFILE 'DATA_PATH/cleaned_food_delivery_orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, order_date, order_time, customer_id, restaurant_name, city, cuisine,
 quantity, unit_price, discount_amount, net_amount, payment_method, order_status,
 @delivery_time, @rating)
SET delivery_time_min = NULLIF(TRIM(@delivery_time), ''),   -- empty text -> NULL
    customer_rating   = NULLIF(TRIM(@rating), '');

LOAD DATA LOCAL INFILE 'DATA_PATH/dim_restaurants.csv'
INTO TABLE dim_restaurants
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'DATA_PATH/dim_city.csv'
INTO TABLE dim_city
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Verify the load
SELECT COUNT(*) AS rows_loaded FROM orders;                 -- expect 2937
SELECT COUNT(*) AS restaurants FROM dim_restaurants;        -- expect 32
SELECT COUNT(*) AS cities FROM dim_city;                    -- expect 8
