-- Week 6: Data model checks
-- 1. Orders: row count and unique order IDs


SELECT 
	COUNT(*) AS row_count,
	COUNT(DISTINCT order_id) AS unique_orders
FROM orders;
-- 2. Compare item rows and unique orders
SELECT 
	COUNT(*) AS row_count,
	COUNT(DISTINCT order_id) AS unique_orders
FROM order_items;

-- 3. Check composite key duplicates

SELECT
	oi.order_id,
	oi.order_item_id,
	COUNT(*) AS row_count
FROM order_items AS oi
GROUP BY oi.order_id, oi.order_item_id 
HAVING COUNT(*) > 1
ORDER BY order_id;
-- Result: 0 duplicate pairs of (order_id, order_item_id)

-- 4. Check customers and products key uniqueness

SELECT 
	COUNT(*) AS row_count,
	COUNT(DISTINCT customer_id) AS unique_keys
FROM customers AS c; 
-- Result: 99441 rows, 99441 unique customer IDs
-- customer_id is unique and has no NULLs
SELECT 
	COUNT(*) AS row_count,
	COUNT(DISTINCT product_id) AS unique_keys
FROM products AS p; 
-- Result: 32951 rows, 32951 unique product IDs
-- product_id is unique and has no NULLs

-- 5. Check row multiplication after joining orders to items

SELECT 
	COUNT(*) AS joined_rows,
	COUNT(DISTINCT o.order_id) AS unique_orders,
	COUNT(oi.order_item_id) AS matched_items
FROM orders AS o 
LEFT JOIN order_items AS oi 
ON o.order_id = oi.order_id;
-- Result: 113425 joined rows, 99441 unique orders, 112650 matched items
-- 775 orders have no items
-- COUNT(*) after this join overcounts orders


-- 6. Compare item price totals before and after joining orders
SELECT 
	SUM(oi.price) AS total_price
FROM order_items AS oi;

SELECT 
	SUM(oi.price) AS total_price
FROM orders AS o
LEFT JOIN order_items AS oi -- Total price before and after join: 13591643.70 
ON o.order_id = oi.order_id; -- Item prices are not duplicated by this join


-- 7. Check double counting of order totals after joining items

WITH order_totals AS (
	SELECT 
		oi.order_id,
		SUM(price) AS order_total
	FROM order_items AS oi
	GROUP BY order_id
)
SELECT 
	(SELECT SUM(price) FROM order_items) AS correct_total,
	SUM(ot.order_total) AS duplicated_total
FROM order_totals AS ot
LEFT JOIN order_items AS oi
ON ot.order_id = oi.order_id;
-- Correct total: 13591643.70
-- Duplicated total: 17230898.37
-- Order totals repeat once per item after the join

-- 8. Preserve order grain by joining aggregated item totals

WITH order_totals AS (
	SELECT 
		oi.order_id,
		SUM(price) AS order_total
	FROM order_items AS oi
	GROUP BY order_id
) 
SELECT 
	COUNT(*) AS row_count,
	COUNT(DISTINCT o.order_id) AS unique_orders,
	SUM(ot.order_total) AS total_price
FROM orders AS o
LEFT JOIN order_totals AS ot
ON ot.order_id = o.order_id;

-- 99441 rows, 99441 unique orders, total price 13591643.70
-- Aggregating items before the join preserves one row per order
-- Orders without items are retained


-- Validate total orders for 2018 against Power BI

SELECT 
	COUNT(DISTINCT order_id) AS total_orders_2018
FROM orders
WHERE order_purchase_timestamp >= '2018-01-01'
	AND order_purchase_timestamp < '2019-01-01';

-- Validate total item revenue for 2018 against Power BI

SELECT 
	SUM(oi.price) AS total_revenue_2018 
FROM orders AS o
LEFT JOIN order_items AS oi 
ON o.order_id = oi.order_id 
WHERE order_purchase_timestamp >= '2018-01-01'
	AND order_purchase_timestamp < '2019-01-01';

-- Calculate monthly item revenue for 2018

SELECT 
	DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        ) AS month,
	SUM(oi.price) AS monthly_revenue
FROM orders AS o
LEFT JOIN order_items AS oi
ON o.order_id = oi.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
	AND o.order_purchase_timestamp < '2019-01-01'
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;

-- Calculate monthly order counts for January to August 2018

SELECT 
	date_trunc(
		'month',
		o.order_purchase_timestamp
	)	AS month,
	COUNT(*) AS monthly_orders
FROM orders AS o
WHERE o.order_purchase_timestamp >= '2018-01-01'
	AND o.order_purchase_timestamp < '2018-09-01'
GROUP BY date_trunc('month', o.order_purchase_timestamp)
ORDER BY month;

-- Check row multiplication after joining orders with order items

SELECT 
	COUNT(DISTINCT o.order_id) AS unique_orders,
	COUNT(*) AS row_count,
	COUNT(*) - COUNT(DISTINCT o.order_id)  AS extra_rows
FROM orders AS o
LEFT JOIN order_items AS oi
ON o.order_id=oi.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
	AND o.order_purchase_timestamp < '2018-09-01';

-- Preserve one row per order by aggregating items before joining

WITH order_totals AS (
	SELECT
		oi.order_id,
		SUM(oi.price) AS order_total
	FROM order_items AS oi
	GROUP BY oi.order_id
)
SELECT 
	COUNT(*) AS row_count,
	COUNT(DISTINCT o.order_id) AS unique_orders,
	SUM(ot.order_total) AS total_revenue
FROM orders AS o
LEFT JOIN order_totals AS ot
ON o.order_id = ot.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp < '2018-09-01';

-- Calculate previous and cumulative monthly revenue

WITH monthly_revenue AS (
	SELECT 
		date_trunc('month', o.order_purchase_timestamp) AS month,
		sum(oi.price) AS revenue
	FROM orders AS o
	LEFT JOIN order_items AS oi
		ON o.order_id = oi.order_id 
	WHERE o.order_purchase_timestamp >= '2018-01-01'
		AND o.order_purchase_timestamp < '2018-09-01'
	GROUP BY date_trunc('month', o.order_purchase_timestamp )
)
SELECT 
	mr.revenue,
	mr.month,
	LAG(mr.revenue) OVER (ORDER BY mr.month) AS previous_revenue,
    SUM(mr.revenue) OVER (ORDER BY mr.month) AS cumulative_revenue
FROM monthly_revenue AS mr
ORDER BY mr.month;
	
-- Reconcile January to August 2018 orders and revenue with Pandas
-- Orders: 53991 in SQL and Pandas
-- Revenue: 7385905.80 in SQL and Pandas
	
	

-- Week 6 SQL Gate

-- Task 1: Monthly delivered orders, revenue and AOV


SELECT 
	date_trunc('month', o.order_purchase_timestamp) AS MONTH, 
	COUNT(DISTINCT o.order_id) AS delivered_orders,
	SUM(oi.price) AS total_revenue,
	ROUND(SUM(oi.price)/ nullif(count(DISTINCT o.order_id), 0),
	2 
	) AS aov
FROM orders AS o
LEFT JOIN order_items AS oi
	ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
	AND o.order_purchase_timestamp >= '2018-01-01'
	AND o.order_purchase_timestamp < '2018-09-01'
GROUP BY date_trunc('month', o.order_purchase_timestamp)
ORDER BY month;

-- Task 2: Revenue share by customer state

WITH state_revenue_data AS (
	SELECT
		c.customer_state,
		SUM(oi.price) AS state_revenue
	FROM orders AS o
	LEFT JOIN order_items AS oi
		ON o.order_id = oi.order_id
	LEFT JOIN customers AS c
		ON o.customer_id = c.customer_id
	WHERE o.order_status = 'delivered'
		AND o.order_purchase_timestamp >= '2018-01-01'
		AND o.order_purchase_timestamp < '2018-09-01'
	GROUP BY c.customer_state
)
SELECT 
	srd.customer_state,
	srd.state_revenue,
	ROUND(
    srd.state_revenue / NULLIF(SUM(srd.state_revenue) OVER (), 0) * 100,
    2
	) AS revenue_share_pct
FROM state_revenue_data AS srd 
ORDER BY state_revenue DESC;
	
-- Task 3: Orders without items

SELECT 
	count(o.order_id) AS orders_without_items	
FROM orders AS o
LEFT JOIN order_items AS oi
	ON o.order_id = oi.order_id
WHERE oi.order_id is NULL 
	AND o.order_purchase_timestamp >= '2018-01-01'
  	AND o.order_purchase_timestamp < '2018-09-01'





	