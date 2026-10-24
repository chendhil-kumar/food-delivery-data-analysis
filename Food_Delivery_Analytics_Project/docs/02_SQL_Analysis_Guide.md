# SQL Analysis Guide (MySQL)

All outputs below were produced by actually running the queries on the cleaned dataset (2,937 orders). Your numbers will match if you load the same CSV.

## Setup (do this once)
1. Install **MySQL Server + MySQL Workbench** (free Community edition).
2. Open `sql/01_create_tables_and_load.sql` in Workbench. Replace every `DATA_PATH` with the folder holding your CSV files (use forward slashes `/`, e.g. `C:/food_delivery/data`).
3. If `LOAD DATA LOCAL INFILE` is blocked, run `SET GLOBAL local_infile = 1;` and enable *OPT_LOCAL_INFILE=1* in Workbench connection > Advanced. **Easier alternative:** right-click the table > *Table Data Import Wizard* > pick the CSV.
4. Run the last three `SELECT COUNT(*)` lines. Expect **2937, 32, 8**.

**Why three tables?** `orders` is the main (fact) table. `dim_restaurants` and `dim_city` are small lookup (dimension) tables used for JOINs. Power BI uses the same structure (star schema).

## Read this first - three rules used in every query
- **Order ID is unique**, so `COUNT(*)` never double-counts an order.
- **Sales = SUM(net_amount) for Delivered orders only.** Cancelled orders are not revenue.
- **NULL is not zero.** Missing delivery time/rating stay NULL so `AVG()` ignores them.

**SQL execution order (helps you debug):** FROM > JOIN > WHERE > GROUP BY > HAVING > SELECT > ORDER BY > LIMIT.

## Query 1 - SELECT, WHERE, ORDER BY, LIMIT  _(Basic)_
**Business question:** Show me the 5 biggest delivered orders from Mumbai. Are there any suspiciously large ones?

```sql
SELECT order_id, order_date, restaurant_name, quantity, unit_price, discount_amount, net_amount
FROM orders
WHERE city = 'Mumbai'
  AND order_status = 'Delivered'
ORDER BY net_amount DESC
LIMIT 5;
```
**Explanation:** SELECT chooses the columns. FROM names the table. WHERE keeps only rows that match BOTH conditions (AND). ORDER BY ... DESC sorts biggest first. LIMIT 5 stops after 5 rows. Always add LIMIT when you explore a big table.

**Output:**
```
+----------+------------+-----------------+----------+------------+-----------------+------------+
| order_id | order_date | restaurant_name | quantity | unit_price | discount_amount | net_amount |
+----------+------------+-----------------+----------+------------+-----------------+------------+
| ORD10819 | 2025-04-14 | Mumbai Pizza Co |        5 |        415 |               0 |       2075 |
| ORD11607 | 2025-07-29 | Mumbai Pizza Co |        4 |        425 |               0 |       1700 |
| ORD11159 | 2025-05-27 | Mumbai Pizza Co |        5 |        335 |               0 |       1675 |
| ORD10182 | 2025-01-24 | Mumbai Pizza Co |        4 |        395 |               0 |       1580 |
| ORD12057 | 2025-09-23 | Mumbai Pizza Co |        4 |        390 |               0 |       1560 |
+----------+------------+-----------------+----------+------------+-----------------+------------+
```

## Query 2 - DISTINCT, COUNT(DISTINCT)  _(Basic)_
**Business question:** How big is our business? How many cities, restaurants, cuisines and customers are in the data?

```sql
SELECT COUNT(*)                         AS total_rows,
       COUNT(DISTINCT order_id)         AS unique_orders,
       COUNT(DISTINCT city)             AS cities,
       COUNT(DISTINCT restaurant_name)  AS restaurants,
       COUNT(DISTINCT cuisine)          AS cuisines,
       COUNT(DISTINCT customer_id)      AS customers
FROM orders;
```
**Explanation:** COUNT(*) counts rows. COUNT(DISTINCT x) counts each different value only once. total_rows must equal unique_orders - that proves there are no duplicate Order IDs. To just LIST the unique values use SELECT DISTINCT cuisine FROM orders;

**Output:**
```
+------------+---------------+--------+-------------+----------+-----------+
| total_rows | unique_orders | cities | restaurants | cuisines | customers |
+------------+---------------+--------+-------------+----------+-----------+
|       2937 |          2937 |      8 |          32 |        9 |      1258 |
+------------+---------------+--------+-------------+----------+-----------+
```

## Query 3 - COUNT, WHERE  _(Basic)_
**Business question:** How many orders were completed (delivered)?

```sql
SELECT COUNT(*) AS completed_orders
FROM orders
WHERE order_status = 'Delivered';
```
**Explanation:** Business rule: a 'completed order' = Order_Status Delivered. Cancelled orders are excluded. Because order_id is the primary key, COUNT(*) never double-counts an order.

**Output:**
```
+------------------+
| completed_orders |
+------------------+
|             2759 |
+------------------+
```

## Query 4 - SUM, WHERE  _(Basic)_
**Business question:** What is our total sales (revenue from food)? How much discount did we give?

```sql
SELECT SUM(quantity * unit_price)  AS gross_sales,
       SUM(discount_amount)         AS total_discount,
       SUM(net_amount)              AS total_sales
FROM orders
WHERE order_status = 'Delivered';
```
**Explanation:** Sales rule: only DELIVERED orders count. net_amount = quantity x unit_price - discount_amount, so gross_sales - total_discount = total_sales. Cancelled orders are not money earned, so they are filtered out with WHERE.

**Output:**
```
+-------------+----------------+-------------+
| gross_sales | total_discount | total_sales |
+-------------+----------------+-------------+
|     1291530 |          91834 |     1199696 |
+-------------+----------------+-------------+
```

## Query 5 - AVG, ROUND  _(Basic)_
**Business question:** What is the Average Order Value (AOV)? (AOV = how much a customer spends per order)

```sql
SELECT ROUND(AVG(net_amount), 2)              AS avg_order_value,
       ROUND(SUM(net_amount) / COUNT(*), 2)    AS aov_check
FROM orders
WHERE order_status = 'Delivered';
```
**Explanation:** AVG(net_amount) = total sales / number of orders. The second column proves it by dividing manually. In interviews, always say AOV uses delivered orders only.

**Output:**
```
+-----------------+-----------+
| avg_order_value | aov_check |
+-----------------+-----------+
|          434.83 |    434.83 |
+-----------------+-----------+
```

## Query 6 - GROUP BY, ORDER BY, LIMIT  _(Intermediate)_
**Business question:** Which 10 restaurants earn the most sales?

```sql
SELECT restaurant_name,
       city,
       COUNT(*)        AS delivered_orders,
       SUM(net_amount) AS total_sales
FROM orders
WHERE order_status = 'Delivered'
GROUP BY restaurant_name, city
ORDER BY total_sales DESC
LIMIT 10;
```
**Explanation:** GROUP BY makes one row per restaurant, then COUNT and SUM work inside each group. Every non-aggregated column in SELECT (restaurant_name, city) must also appear in GROUP BY.

**Output:**
```
+-----------------------+-----------+------------------+-------------+
| restaurant_name       | city      | delivered_orders | total_sales |
+-----------------------+-----------+------------------+-------------+
| Mumbai Pizza Co       | Mumbai    |              132 |       97665 |
| Tandoor Tales         | Delhi     |              175 |       93205 |
| Curry Leaf Kitchen    | Mumbai    |              180 |       88581 |
| Nawabi Biryani House  | Bengaluru |              142 |       74648 |
| Burger Barn           | Delhi     |              181 |       73295 |
| Spice Junction        | Bengaluru |              148 |       70693 |
| Dragon Express        | Mumbai    |              139 |       65741 |
| Hyderabad Dum Biryani | Hyderabad |               98 |       57786 |
| Cheesy Slice          | Ahmedabad |               81 |       54822 |
| Wok & Roll            | Bengaluru |              125 |       52319 |
+-----------------------+-----------+------------------+-------------+
```

## Query 7 - GROUP BY + subquery for % share  _(Intermediate)_
**Business question:** Which city generates the highest sales, and what share of total sales is it?

```sql
SELECT city,
       COUNT(*)                                   AS delivered_orders,
       SUM(net_amount)                            AS total_sales,
       ROUND(100 * SUM(net_amount) /
            (SELECT SUM(net_amount) FROM orders WHERE order_status = 'Delivered'), 1) AS pct_of_total_sales
FROM orders
WHERE order_status = 'Delivered'
GROUP BY city
ORDER BY total_sales DESC;
```
**Explanation:** The part in brackets is a SUBQUERY: a small query that calculates the grand total once. Dividing each city's sales by it gives a percentage share.

**Output:**
```
+-----------+------------------+-------------+--------------------+
| city      | delivered_orders | total_sales | pct_of_total_sales |
+-----------+------------------+-------------+--------------------+
| Mumbai    |              551 |      279810 |               23.3 |
| Bengaluru |              595 |      240590 |               20.1 |
| Delhi     |              536 |      214330 |               17.9 |
| Hyderabad |              314 |      134231 |               11.2 |
| Pune      |              263 |      104824 |                8.7 |
| Ahmedabad |              155 |       88144 |                7.3 |
| Chennai   |              194 |       85233 |                7.1 |
| Kolkata   |              151 |       52534 |                4.4 |
+-----------+------------------+-------------+--------------------+
```

## Query 8 - GROUP BY, multiple measures  _(Intermediate)_
**Business question:** Which cuisines are most popular (by orders), and which earn the most?

```sql
SELECT cuisine,
       COUNT(*)                    AS delivered_orders,
       SUM(net_amount)             AS total_sales,
       ROUND(AVG(net_amount), 0)   AS avg_order_value
FROM orders
WHERE order_status = 'Delivered'
GROUP BY cuisine
ORDER BY delivered_orders DESC;
```
**Explanation:** Popularity = number of orders. Revenue = sum of sales. Cuisines can rank differently on the two: a cheap cuisine can be popular but earn less per order (look at avg_order_value).

**Output:**
```
+--------------+------------------+-------------+-----------------+
| cuisine      | delivered_orders | total_sales | avg_order_value |
+--------------+------------------+-------------+-----------------+
| North Indian |              622 |      306832 |             493 |
| Biryani      |              369 |      201100 |             545 |
| South Indian |              364 |       97908 |             269 |
| Chinese      |              348 |      143771 |             413 |
| Street Food  |              297 |       74783 |             252 |
| Pizza        |              258 |      176099 |             683 |
| Burgers      |              237 |       97575 |             412 |
| Desserts     |              199 |       63078 |             317 |
| Healthy Food |               65 |       38550 |             593 |
+--------------+------------------+-------------+-----------------+
```

## Query 9 - Date functions (DATE_FORMAT), GROUP BY  _(Intermediate)_
**Business question:** What is the monthly sales trend? Which month is highest?

```sql
SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_month,
       COUNT(*)                          AS delivered_orders,
       SUM(net_amount)                   AS total_sales
FROM orders
WHERE order_status = 'Delivered'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;
```
**Explanation:** DATE_FORMAT turns a date into 'year-month' text so we can group by month. '%Y-%m' sorts correctly in time order. This is the data behind a monthly line chart in Power BI.

**Output:**
```
+-------------+------------------+-------------+
| order_month | delivered_orders | total_sales |
+-------------+------------------+-------------+
| 2025-01     |              212 |       89850 |
| 2025-02     |              199 |       88479 |
| 2025-03     |              250 |      100829 |
| 2025-04     |              217 |       98569 |
| 2025-05     |              221 |      101852 |
| 2025-06     |              193 |       74885 |
| 2025-07     |              212 |       95216 |
| 2025-08     |              218 |      100826 |
| 2025-09     |              242 |      102043 |
| 2025-10     |              264 |      120076 |
| 2025-11     |              278 |      121839 |
| 2025-12     |              253 |      105232 |
+-------------+------------------+-------------+
```

## Query 10 - Window function LAG (bonus)  _(Intermediate)_
**Business question:** By what percentage did sales grow or fall each month compared to the previous month?

```sql
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
```
**Explanation:** The inner query (a derived table) makes monthly sales. LAG() looks at the PREVIOUS row without a join. MoM growth = (this month - last month) / last month. January is NULL because there is no month before it. Window functions need MySQL 8.0+.

**Output:**
```
+-------------+-------------+------------------+----------------+
| order_month | total_sales | prev_month_sales | mom_growth_pct |
+-------------+-------------+------------------+----------------+
| 2025-01     |       89850 |             NULL |           NULL |
| 2025-02     |       88479 |            89850 |           -1.5 |
| 2025-03     |      100829 |            88479 |           14.0 |
| 2025-04     |       98569 |           100829 |           -2.2 |
| 2025-05     |      101852 |            98569 |            3.3 |
| 2025-06     |       74885 |           101852 |          -26.5 |
| 2025-07     |       95216 |            74885 |           27.1 |
| 2025-08     |      100826 |            95216 |            5.9 |
| 2025-09     |      102043 |           100826 |            1.2 |
| 2025-10     |      120076 |           102043 |           17.7 |
| 2025-11     |      121839 |           120076 |            1.5 |
| 2025-12     |      105232 |           121839 |          -13.6 |
+-------------+-------------+------------------+----------------+
```

## Query 11 - GROUP BY, subquery for %  _(Intermediate)_
**Business question:** How are customers paying? Show orders and share by payment method.

```sql
SELECT payment_method,
       COUNT(*) AS orders,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM orders), 1) AS pct_of_orders
FROM orders
GROUP BY payment_method
ORDER BY orders DESC;
```
**Explanation:** Here ALL orders are counted (including cancelled) because the question is about payment behaviour, not sales. 'Unknown' are orders where the payment method was not recorded.

**Output:**
```
+------------------+--------+---------------+
| payment_method   | orders | pct_of_orders |
+------------------+--------+---------------+
| UPI              |   1306 |          44.5 |
| Cash on Delivery |    488 |          16.6 |
| Credit Card      |    422 |          14.4 |
| Debit Card       |    315 |          10.7 |
| Wallet           |    235 |           8.0 |
| Net Banking      |    146 |           5.0 |
| Unknown          |     25 |           0.9 |
+------------------+--------+---------------+
```

## Query 12 - CASE WHEN, conditional counting  _(Intermediate)_
**Business question:** How many orders were cancelled, and what is the overall cancellation rate?

```sql
SELECT COUNT(*)                                                    AS total_orders,
       SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_orders,
       SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
       ROUND(100 * SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END)
             / COUNT(*), 2)                                         AS cancellation_rate_pct
FROM orders;
```
**Explanation:** CASE WHEN works like IF in Excel: give 1 when the status matches, otherwise 0. Adding those 1s counts the matching rows. Cancellation rate = cancelled / TOTAL orders (not / delivered).

**Output:**
```
+--------------+------------------+------------------+-----------------------+
| total_orders | delivered_orders | cancelled_orders | cancellation_rate_pct |
+--------------+------------------+------------------+-----------------------+
|         2937 |             2759 |              178 |                  6.06 |
+--------------+------------------+------------------+-----------------------+
```

## Query 13 - CASE WHEN + GROUP BY + HAVING  _(Intermediate)_
**Business question:** Do some payment methods get cancelled more often? (only show methods with 50+ orders)

```sql
SELECT payment_method,
       COUNT(*) AS total_orders,
       SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
       ROUND(100 * SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancellation_rate_pct
FROM orders
GROUP BY payment_method
HAVING COUNT(*) >= 50
ORDER BY cancellation_rate_pct DESC;
```
**Explanation:** HAVING filters AFTER grouping (WHERE filters BEFORE grouping). We use it so tiny groups with unreliable percentages are hidden. Look for Cash on Delivery - COD orders are usually cancelled more because there is no prepayment.

**Output:**
```
+------------------+--------------+------------------+-----------------------+
| payment_method   | total_orders | cancelled_orders | cancellation_rate_pct |
+------------------+--------------+------------------+-----------------------+
| Cash on Delivery |          488 |               51 |                 10.45 |
| Net Banking      |          146 |               11 |                  7.53 |
| Wallet           |          235 |               15 |                  6.38 |
| UPI              |         1306 |               67 |                  5.13 |
| Credit Card      |          422 |               20 |                  4.74 |
| Debit Card       |          315 |               12 |                  3.81 |
+------------------+--------------+------------------+-----------------------+
```

## Query 14 - GROUP BY, ORDER BY  _(Intermediate)_
**Business question:** Who are our top 10 customers by number of orders?

```sql
SELECT customer_id,
       COUNT(*)                                                    AS total_orders,
       SUM(CASE WHEN order_status = 'Delivered' THEN net_amount ELSE 0 END) AS total_spend,
       MIN(order_date)                                             AS first_order,
       MAX(order_date)                                             AS last_order
FROM orders
GROUP BY customer_id
ORDER BY total_orders DESC, total_spend DESC
LIMIT 10;
```
**Explanation:** One row per customer. total_spend only adds delivered orders (CASE WHEN inside SUM). Ordering by two columns breaks ties. These are your VIP customers - candidates for loyalty offers.

**Output:**
```
+-------------+--------------+-------------+-------------+------------+
| customer_id | total_orders | total_spend | first_order | last_order |
+-------------+--------------+-------------+-------------+------------+
| C0006       |           16 |        4595 | 2025-02-01  | 2025-12-03 |
| C0562       |           15 |        6400 | 2025-01-20  | 2025-11-11 |
| C0674       |           13 |        5188 | 2025-01-07  | 2025-11-27 |
| C0477       |           11 |        6500 | 2025-02-01  | 2025-12-19 |
| C0411       |           11 |        5350 | 2025-01-02  | 2025-12-29 |
| C1296       |           10 |        4800 | 2025-01-16  | 2025-12-13 |
| C0365       |            9 |        3825 | 2025-01-06  | 2025-12-12 |
| C1119       |            8 |        3240 | 2025-03-23  | 2025-12-06 |
| C1051       |            8 |        3193 | 2025-01-07  | 2025-12-24 |
| C0903       |            8 |        2650 | 2025-03-26  | 2025-12-25 |
+-------------+--------------+-------------+-------------+------------+
```

## Query 15 - AVG, GROUP BY, subquery  _(Intermediate)_
**Business question:** Which cities have longer delivery times than the overall average?

```sql
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
```
**Explanation:** AVG ignores NULL values automatically, so orders with a missing delivery time do not drag the average to zero (this is why we kept them as NULL, not 0). The subquery gives the overall average to compare with.

**Output:**
```
+-----------+------------------+------------------+
| city      | avg_delivery_min | orders_with_time |
+-----------+------------------+------------------+
| Mumbai    |             43.1 |              546 |
| Bengaluru |             40.4 |              590 |
| Delhi     |             39.5 |              529 |
+-----------+------------------+------------------+
```

## Query 16 - Subquery in HAVING / derived table  _(Intermediate)_
**Business question:** Which restaurants earn MORE than the average restaurant?

```sql
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
```
**Explanation:** Step 1 (inner) - sales per restaurant. Step 2 - the average of those restaurant totals. Step 3 (outer) - keep only restaurants above that average. These are your 'high sales' restaurants. Read subqueries from the inside out.

**Output:**
```
+-----------------------+-----------+-------------+
| restaurant_name       | city      | total_sales |
+-----------------------+-----------+-------------+
| Mumbai Pizza Co       | Mumbai    |       97665 |
| Tandoor Tales         | Delhi     |       93205 |
| Curry Leaf Kitchen    | Mumbai    |       88581 |
| Nawabi Biryani House  | Bengaluru |       74648 |
| Burger Barn           | Delhi     |       73295 |
| Spice Junction        | Bengaluru |       70693 |
| Dragon Express        | Mumbai    |       65741 |
| Hyderabad Dum Biryani | Hyderabad |       57786 |
| Cheesy Slice          | Ahmedabad |       54822 |
| Wok & Roll            | Bengaluru |       52319 |
| Maratha Thali House   | Pune      |       46722 |
| Madras Biryani Co     | Chennai   |       45274 |
| Dosa Darbar           | Bengaluru |       42930 |
+-----------------------+-----------+-------------+
```

## Query 17 - JOIN, GROUP BY, HAVING  _(Intermediate)_
**Business question:** Which restaurants have the best customer ratings? (min 30 rated orders for fairness) Also show restaurant type.

```sql
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
```
**Explanation:** INNER JOIN adds columns from the dim_restaurants table where restaurant names match. COUNT(customer_rating) counts only non-NULL ratings. A restaurant with one 5-star rating should not beat one with 100 ratings, so HAVING sets a minimum.

**Output:**
```
+-----------------------+-----------------+------------+--------------+
| restaurant_name       | restaurant_type | avg_rating | rated_orders |
+-----------------------+-----------------+------------+--------------+
| Nawabi Biryani House  | Cloud Kitchen   |       4.32 |          128 |
| Pizza Palace          | Cloud Kitchen   |       4.26 |           42 |
| Pune Burger Hub       | Cloud Kitchen   |       4.24 |           50 |
| Hyderabad Dum Biryani | Dine-in         |       4.22 |           91 |
| Chaat Corner          | Dine-in         |       4.20 |           86 |
| Bengal Bites          | Dine-in         |       4.20 |           45 |
| Maratha Thali House   | Dine-in         |       4.13 |           77 |
| Momo Magic            | Cloud Kitchen   |       4.13 |           75 |
| Cake Walk             | Cloud Kitchen   |       4.07 |           76 |
| Dragon Express        | Cloud Kitchen   |       4.05 |          126 |
+-----------------------+-----------------+------------+--------------+
```

## Query 18 - HOUR(), GROUP BY  _(Intermediate)_
**Business question:** What are the peak ordering hours?

```sql
SELECT HOUR(order_time)  AS hour_of_day,
       COUNT(*)           AS orders
FROM orders
GROUP BY HOUR(order_time)
ORDER BY orders DESC
LIMIT 6;
```
**Explanation:** HOUR() pulls the hour (0-23) out of a time value. Sort descending to see the busiest hours - these decide when restaurants and delivery partners must be ready.

**Output:**
```
+-------------+--------+
| hour_of_day | orders |
+-------------+--------+
|          20 |    375 |
|          19 |    360 |
|          12 |    340 |
|          11 |    276 |
|          21 |    237 |
|          18 |    213 |
+-------------+--------+
```

## Query 19 - CASE WHEN for time buckets  _(Intermediate)_
**Business question:** Group the day into meal slots - which slot brings the most orders and the slowest deliveries?

```sql
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
```
**Explanation:** CASE WHEN builds a new label column from the hour. Numbering the labels (1., 2., ...) makes them sort in clock order. The same buckets are used in Power BI for the 'Orders by Time of Day' chart.

**Output:**
```
+----------------------+--------+------------------+
| time_of_day          | orders | avg_delivery_min |
+----------------------+--------+------------------+
| 1. Breakfast (6-10)  |    265 |             36.3 |
| 2. Lunch (11-15)     |   1005 |             38.2 |
| 3. Snacks (16-18)    |    425 |             36.5 |
| 4. Dinner (19-22)    |   1120 |             40.0 |
| 5. Late Night (23-5) |    122 |             35.1 |
+----------------------+--------+------------------+
```

## Query 20 - Subquery + HAVING  _(Intermediate)_
**Business question:** How many customers are repeat customers (ordered more than once), and what is the repeat rate?

```sql
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
```
**Explanation:** The inner query counts delivered orders per customer. The outer query counts how many customers have more than 1. Repeat rate is a key retention metric: it shows loyalty.

**Output:**
```
+-----------------+------------------+-----------------+
| total_customers | repeat_customers | repeat_rate_pct |
+-----------------+------------------+-----------------+
|            1226 |              763 |            62.2 |
+-----------------+------------------+-----------------+
```

## Query 21 - INNER JOIN with dim_city  _(Intermediate)_
**Business question:** Which STATE and which type of city (tier) generate the most sales?

```sql
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
```
**Explanation:** The orders table only knows the city. JOIN dim_city to bring in state and region, then group by those. Mumbai and Pune both roll up into Maharashtra. This is how a 'dimension table' enriches data - the same idea as Power BI relationships.

**Output:**
```
+-------------+--------+------------------+-------------+
| state       | region | delivered_orders | total_sales |
+-------------+--------+------------------+-------------+
| Maharashtra | West   |              814 |      384634 |
| Karnataka   | South  |              595 |      240590 |
| Delhi       | North  |              536 |      214330 |
| Telangana   | South  |              314 |      134231 |
| Gujarat     | West   |              155 |       88144 |
| Tamil Nadu  | South  |              194 |       85233 |
| West Bengal | East   |              151 |       52534 |
+-------------+--------+------------------+-------------+
```

## Query 22 - JOIN, CASE WHEN  _(Intermediate)_
**Business question:** Do Dine-in restaurants or Cloud Kitchens earn more per order?

```sql
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
```
**Explanation:** Another JOIN example: restaurant_type lives only in the dimension table. After joining, we can compare the two business models on sales, order value and speed.

**Output:**
```
+-----------------+------------------+-------------+-----------------+------------------+
| restaurant_type | delivered_orders | total_sales | avg_order_value | avg_delivery_min |
+-----------------+------------------+-------------+-----------------+------------------+
| Cloud Kitchen   |             1302 |      631656 |             485 |             37.9 |
| Dine-in         |             1457 |      568040 |             390 |             38.7 |
+-----------------+------------------+-------------+-----------------+------------------+
```

## Query 23 - Date functions: DAYNAME, WEEKDAY  _(Intermediate)_
**Business question:** Which day of the week is busiest? Do weekends sell more?

```sql
SELECT DAYNAME(order_date)       AS day_name,
       WEEKDAY(order_date)       AS day_no,
       COUNT(*)                  AS delivered_orders,
       SUM(net_amount)           AS total_sales
FROM orders
WHERE order_status = 'Delivered'
GROUP BY DAYNAME(order_date), WEEKDAY(order_date)
ORDER BY day_no;
```
**Explanation:** DAYNAME gives 'Monday'..., WEEKDAY gives 0 (Monday) to 6 (Sunday) which we use to sort properly. Remember: 52 weeks in 2025 means each weekday appears about the same number of times, so totals are fairly comparable.

**Output:**
```
+-----------+--------+------------------+-------------+
| day_name  | day_no | delivered_orders | total_sales |
+-----------+--------+------------------+-------------+
| Monday    |      0 |              383 |      165999 |
| Tuesday   |      1 |              378 |      164997 |
| Wednesday |      2 |              412 |      179825 |
| Thursday  |      3 |              384 |      171986 |
| Friday    |      4 |              383 |      168691 |
| Saturday  |      5 |              409 |      172805 |
| Sunday    |      6 |              410 |      175393 |
+-----------+--------+------------------+-------------+
```

## Query 24 - Window function RANK / PARTITION BY  _(Advanced (bonus))_
**Business question:** Which is the #1 restaurant in EACH city?

```sql
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
```
**Explanation:** RANK() OVER (PARTITION BY city ...) restarts the ranking for every city. We then keep rank 1 only. Very common interview question: 'top N per group'.

**Output:**
```
+-----------+-----------------------+-------------+------------+
| city      | restaurant_name       | total_sales | sales_rank |
+-----------+-----------------------+-------------+------------+
| Mumbai    | Mumbai Pizza Co       |       97665 |          1 |
| Delhi     | Tandoor Tales         |       93205 |          1 |
| Bengaluru | Nawabi Biryani House  |       74648 |          1 |
| Hyderabad | Hyderabad Dum Biryani |       57786 |          1 |
| Ahmedabad | Cheesy Slice          |       54822 |          1 |
| Pune      | Maratha Thali House   |       46722 |          1 |
| Chennai   | Madras Biryani Co     |       45274 |          1 |
| Kolkata   | Biryani Baadshah      |       23392 |          1 |
+-----------+-----------------------+-------------+------------+
```

## Query 25 - GROUP BY + HAVING, IS NULL  _(Data quality)_
**Business question:** Final health check: any duplicate Order IDs or unexpected NULLs left after cleaning?

```sql
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
```
**Explanation:** UNION ALL stacks several checks into one result. Duplicates must be 0. NULL delivery time/rating on delivered orders are EXPECTED (we kept them as NULL on purpose); cancelled orders with ratings and non-positive amounts must be 0.

**Output:**
```
+------------------------------------------+--------------+
| check_name                               | problem_rows |
+------------------------------------------+--------------+
| duplicate order_ids                      |            0 |
| delivered orders with NULL delivery time |           28 |
| delivered orders with NULL rating        |          270 |
| cancelled orders that have a rating      |            0 |
| negative or zero net_amount              |            0 |
+------------------------------------------+--------------+
```
