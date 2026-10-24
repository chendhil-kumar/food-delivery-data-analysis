-- ============================================================
-- Food Delivery Analytics - SQL analysis queries (MySQL 8.0+)
-- Run 01_create_tables_and_load.sql first.  Database: food_delivery
-- BUSINESS RULES:  Sales / AOV / completed orders use order_status = 'Delivered' only.
--                  Cancellation rate = cancelled / ALL orders.
-- Each query: business question, then SQL.  Sample output is in docs/02_SQL_Analysis_Guide.md
-- ============================================================
USE food_delivery;

-- ------------------------------------------------------------
-- Q1 [Basic] SELECT, WHERE, ORDER BY, LIMIT
-- Business question: Show me the 5 biggest delivered orders from Mumbai. Are there any suspiciously large ones?
-- ------------------------------------------------------------
SELECT order_id, order_date, restaurant_name, quantity, unit_price, discount_amount, net_amount
FROM orders
WHERE city = 'Mumbai'
  AND order_status = 'Delivered'
ORDER BY net_amount DESC
LIMIT 5;

-- ------------------------------------------------------------
-- Q2 [Basic] DISTINCT, COUNT(DISTINCT)
-- Business question: How big is our business? How many cities, restaurants, cuisines and customers are in the data?
-- ------------------------------------------------------------
SELECT COUNT(*)                         AS total_rows,
       COUNT(DISTINCT order_id)         AS unique_orders,
       COUNT(DISTINCT city)             AS cities,
       COUNT(DISTINCT restaurant_name)  AS restaurants,
       COUNT(DISTINCT cuisine)          AS cuisines,
       COUNT(DISTINCT customer_id)      AS customers
FROM orders;

-- ------------------------------------------------------------
-- Q3 [Basic] COUNT, WHERE
-- Business question: How many orders were completed (delivered)?
-- ------------------------------------------------------------
SELECT COUNT(*) AS completed_orders
FROM orders
WHERE order_status = 'Delivered';

-- ------------------------------------------------------------
-- Q4 [Basic] SUM, WHERE
-- Business question: What is our total sales (revenue from food)? How much discount did we give?
-- ------------------------------------------------------------
SELECT SUM(quantity * unit_price)  AS gross_sales,
       SUM(discount_amount)         AS total_discount,
       SUM(net_amount)              AS total_sales
FROM orders
WHERE order_status = 'Delivered';

-- ------------------------------------------------------------
-- Q5 [Basic] AVG, ROUND
-- Business question: What is the Average Order Value (AOV)? (AOV = how much a customer spends per order)
-- ------------------------------------------------------------
SELECT ROUND(AVG(net_amount), 2)              AS avg_order_value,
       ROUND(SUM(net_amount) / COUNT(*), 2)    AS aov_check
FROM orders
WHERE order_status = 'Delivered';

-- ------------------------------------------------------------
-- Q6 [Intermediate] GROUP BY, ORDER BY, LIMIT
-- Business question: Which 10 restaurants earn the most sales?
-- ------------------------------------------------------------
SELECT restaurant_name,
       city,
       COUNT(*)        AS delivered_orders,
       SUM(net_amount) AS total_sales
FROM orders
WHERE order_status = 'Delivered'
GROUP BY restaurant_name, city
ORDER BY total_sales DESC
LIMIT 10;

-- ------------------------------------------------------------
-- Q7 [Intermediate] GROUP BY + subquery for % share
-- Business question: Which city generates the highest sales, and what share of total sales is it?
-- ------------------------------------------------------------
SELECT city,
       COUNT(*)                                   AS delivered_orders,
       SUM(net_amount)                            AS total_sales,
       ROUND(100 * SUM(net_amount) /
            (SELECT SUM(net_amount) FROM orders WHERE order_status = 'Delivered'), 1) AS pct_of_total_sales
FROM orders
WHERE order_status = 'Delivered'
GROUP BY city
ORDER BY total_sales DESC;

-- ------------------------------------------------------------
-- Q8 [Intermediate] GROUP BY, multiple measures
-- Business question: Which cuisines are most popular (by orders), and which earn the most?
-- ------------------------------------------------------------
SELECT cuisine,
       COUNT(*)                    AS delivered_orders,
       SUM(net_amount)             AS total_sales,
       ROUND(AVG(net_amount), 0)   AS avg_order_value
FROM orders
WHERE order_status = 'Delivered'
GROUP BY cuisine
ORDER BY delivered_orders DESC;

-- ------------------------------------------------------------
-- Q9 [Intermediate] Date functions (DATE_FORMAT), GROUP BY
-- Business question: What is the monthly sales trend? Which month is highest?
-- ------------------------------------------------------------
SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_month,
       COUNT(*)                          AS delivered_orders,
       SUM(net_amount)                   AS total_sales
FROM orders
WHERE order_status = 'Delivered'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;

-- ------------------------------------------------------------
-- Q10 [Intermediate] Window function LAG (bonus)
-- Business question: By what percentage did sales grow or fall each month compared to the previous month?
-- ------------------------------------------------------------
SELECT order_month, total_sales,
       LAG(total_sales) OVER (ORDER BY order_month)                                  AS prev_month_sales,
       ROUND(100 * (total_sales - LAG(total_sales) OVER (ORDER BY order_month))
             / LAG(total_sales) OVER (ORDER BY order_month), 1)                      AS mom_growth_pct
FROM (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_month,
           SUM(net_amount)                  AS total_sales
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
) AS monthly
ORDER BY order_month;

-- ------------------------------------------------------------
-- Q11 [Intermediate] GROUP BY, subquery for %
-- Business question: How are customers paying? Show orders and share by payment method.
-- ------------------------------------------------------------
SELECT payment_method,
       COUNT(*) AS orders,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM orders), 1) AS pct_of_orders
FROM orders
GROUP BY payment_method
ORDER BY orders DESC;

-- ------------------------------------------------------------
-- Q12 [Intermediate] CASE WHEN, conditional counting
-- Business question: How many orders were cancelled, and what is the overall cancellation rate?
-- ------------------------------------------------------------
SELECT COUNT(*)                                                    AS total_orders,
       SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_orders,
       SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
       ROUND(100 * SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END)
             / COUNT(*), 2)                                         AS cancellation_rate_pct
FROM orders;

-- ------------------------------------------------------------
-- Q13 [Intermediate] CASE WHEN + GROUP BY + HAVING
-- Business question: Do some payment methods get cancelled more often? (only show methods with 50+ orders)
-- ------------------------------------------------------------
SELECT payment_method,
       COUNT(*) AS total_orders,
       SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
       ROUND(100 * SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancellation_rate_pct
FROM orders
GROUP BY payment_method
HAVING COUNT(*) >= 50
ORDER BY cancellation_rate_pct DESC;

-- ------------------------------------------------------------
-- Q14 [Intermediate] GROUP BY, ORDER BY
-- Business question: Who are our top 10 customers by number of orders?
-- ------------------------------------------------------------
SELECT customer_id,
       COUNT(*)                                                    AS total_orders,
       SUM(CASE WHEN order_status = 'Delivered' THEN net_amount ELSE 0 END) AS total_spend,
       MIN(order_date)                                             AS first_order,
       MAX(order_date)                                             AS last_order
FROM orders
GROUP BY customer_id
ORDER BY total_orders DESC, total_spend DESC
LIMIT 10;

-- ------------------------------------------------------------
-- Q15 [Intermediate] AVG, GROUP BY, subquery
-- Business question: Which cities have longer delivery times than the overall average?
-- ------------------------------------------------------------
SELECT city,
       ROUND(AVG(delivery_time_min), 1) AS avg_delivery_min,
       COUNT(delivery_time_min)         AS orders_with_time
FROM orders
WHERE order_status = 'Delivered'
GROUP BY city
HAVING AVG(delivery_time_min) > (SELECT AVG(delivery_time_min)
                                 FROM orders
                                 WHERE order_status = 'Delivered')
ORDER BY avg_delivery_min DESC;

-- ------------------------------------------------------------
-- Q16 [Intermediate] Subquery in HAVING / derived table
-- Business question: Which restaurants earn MORE than the average restaurant?
-- ------------------------------------------------------------
SELECT restaurant_name, city, total_sales
FROM (
    SELECT restaurant_name, city, SUM(net_amount) AS total_sales
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY restaurant_name, city
) AS rest_sales
WHERE total_sales > (SELECT AVG(total_sales)
                     FROM (SELECT SUM(net_amount) AS total_sales
                           FROM orders
                           WHERE order_status = 'Delivered'
                           GROUP BY restaurant_name) AS x)
ORDER BY total_sales DESC;

-- ------------------------------------------------------------
-- Q17 [Intermediate] JOIN, GROUP BY, HAVING
-- Business question: Which restaurants have the best customer ratings? (min 30 rated orders for fairness) Also show restaurant type.
-- ------------------------------------------------------------
SELECT o.restaurant_name,
       r.restaurant_type,
       ROUND(AVG(o.customer_rating), 2) AS avg_rating,
       COUNT(o.customer_rating)         AS rated_orders
FROM orders AS o
INNER JOIN dim_restaurants AS r
        ON o.restaurant_name = r.restaurant_name
WHERE o.order_status = 'Delivered'
GROUP BY o.restaurant_name, r.restaurant_type
HAVING COUNT(o.customer_rating) >= 30
ORDER BY avg_rating DESC, rated_orders DESC
LIMIT 10;

-- ------------------------------------------------------------
-- Q18 [Intermediate] HOUR(), GROUP BY
-- Business question: What are the peak ordering hours?
-- ------------------------------------------------------------
SELECT HOUR(order_time)  AS hour_of_day,
       COUNT(*)           AS orders
FROM orders
GROUP BY HOUR(order_time)
ORDER BY orders DESC
LIMIT 6;

-- ------------------------------------------------------------
-- Q19 [Intermediate] CASE WHEN for time buckets
-- Business question: Group the day into meal slots - which slot brings the most orders and the slowest deliveries?
-- ------------------------------------------------------------
SELECT CASE
           WHEN HOUR(order_time) BETWEEN 6  AND 10 THEN '1. Breakfast (6-10)'
           WHEN HOUR(order_time) BETWEEN 11 AND 15 THEN '2. Lunch (11-15)'
           WHEN HOUR(order_time) BETWEEN 16 AND 18 THEN '3. Snacks (16-18)'
           WHEN HOUR(order_time) BETWEEN 19 AND 22 THEN '4. Dinner (19-22)'
           ELSE '5. Late Night (23-5)'
       END                                  AS time_of_day,
       COUNT(*)                             AS orders,
       ROUND(AVG(delivery_time_min), 1)     AS avg_delivery_min
FROM orders
GROUP BY time_of_day
ORDER BY time_of_day;

-- ------------------------------------------------------------
-- Q20 [Intermediate] Subquery + HAVING
-- Business question: How many customers are repeat customers (ordered more than once), and what is the repeat rate?
-- ------------------------------------------------------------
SELECT COUNT(*)                                                       AS total_customers,
       SUM(CASE WHEN orders_per_customer > 1 THEN 1 ELSE 0 END)       AS repeat_customers,
       ROUND(100 * SUM(CASE WHEN orders_per_customer > 1 THEN 1 ELSE 0 END)
             / COUNT(*), 1)                                            AS repeat_rate_pct
FROM (
    SELECT customer_id, COUNT(*) AS orders_per_customer
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
) AS per_customer;

-- ------------------------------------------------------------
-- Q21 [Intermediate] INNER JOIN with dim_city
-- Business question: Which STATE and which type of city (tier) generate the most sales?
-- ------------------------------------------------------------
SELECT c.state,
       c.region,
       COUNT(*)           AS delivered_orders,
       SUM(o.net_amount)  AS total_sales
FROM orders AS o
INNER JOIN dim_city AS c
        ON o.city = c.city
WHERE o.order_status = 'Delivered'
GROUP BY c.state, c.region
ORDER BY total_sales DESC;

-- ------------------------------------------------------------
-- Q22 [Intermediate] JOIN, CASE WHEN
-- Business question: Do Dine-in restaurants or Cloud Kitchens earn more per order?
-- ------------------------------------------------------------
SELECT r.restaurant_type,
       COUNT(*)                            AS delivered_orders,
       SUM(o.net_amount)                   AS total_sales,
       ROUND(AVG(o.net_amount), 0)         AS avg_order_value,
       ROUND(AVG(o.delivery_time_min), 1)  AS avg_delivery_min
FROM orders AS o
INNER JOIN dim_restaurants AS r
        ON o.restaurant_name = r.restaurant_name
WHERE o.order_status = 'Delivered'
GROUP BY r.restaurant_type;

-- ------------------------------------------------------------
-- Q23 [Intermediate] Date functions: DAYNAME, WEEKDAY
-- Business question: Which day of the week is busiest? Do weekends sell more?
-- ------------------------------------------------------------
SELECT DAYNAME(order_date)       AS day_name,
       WEEKDAY(order_date)       AS day_no,
       COUNT(*)                  AS delivered_orders,
       SUM(net_amount)           AS total_sales
FROM orders
WHERE order_status = 'Delivered'
GROUP BY DAYNAME(order_date), WEEKDAY(order_date)
ORDER BY day_no;

-- ------------------------------------------------------------
-- Q24 [Advanced (bonus)] Window function RANK / PARTITION BY
-- Business question: Which is the #1 restaurant in EACH city?
-- ------------------------------------------------------------
SELECT city, restaurant_name, total_sales, sales_rank
FROM (
    SELECT city,
           restaurant_name,
           SUM(net_amount) AS total_sales,
           RANK() OVER (PARTITION BY city ORDER BY SUM(net_amount) DESC) AS sales_rank
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY city, restaurant_name
) AS ranked
WHERE sales_rank = 1
ORDER BY total_sales DESC;

-- ------------------------------------------------------------
-- Q25 [Data quality] GROUP BY + HAVING, IS NULL
-- Business question: Final health check: any duplicate Order IDs or unexpected NULLs left after cleaning?
-- ------------------------------------------------------------
SELECT 'duplicate order_ids'                 AS check_name,
       COUNT(*)                              AS problem_rows
FROM (SELECT order_id FROM orders GROUP BY order_id HAVING COUNT(*) > 1) AS d
UNION ALL
SELECT 'delivered orders with NULL delivery time', COUNT(*)
FROM orders WHERE order_status = 'Delivered' AND delivery_time_min IS NULL
UNION ALL
SELECT 'delivered orders with NULL rating', COUNT(*)
FROM orders WHERE order_status = 'Delivered' AND customer_rating IS NULL
UNION ALL
SELECT 'cancelled orders that have a rating', COUNT(*)
FROM orders WHERE order_status = 'Cancelled' AND customer_rating IS NOT NULL
UNION ALL
SELECT 'negative or zero net_amount', COUNT(*)
FROM orders WHERE net_amount <= 0;
