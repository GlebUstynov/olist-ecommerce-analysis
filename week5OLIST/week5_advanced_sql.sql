-- WEEK 5 — ADVANCED SQL (Olist / PostgreSQL)
-- Reconstructed from the SQL exercises in our conversation, 12 October 2026.
-- These are corrected working versions of the exercises, not an exact recovery
-- of the unsaved DBeaver editor buffer. Run individual statements in DBeaver.


-- 01. CTE: order-level aggregation and filtering

WITH order_summary AS (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS total_price,
        SUM(freight_value) AS freight_total
    FROM order_items
    GROUP BY order_id
)
SELECT
    order_id,
    item_count,
    total_price,
    freight_total
FROM order_summary
WHERE total_price > 500
ORDER BY total_price DESC
LIMIT 20;


-- 02. Multiple CTEs: delivered orders with at least two items

WITH order_metrics AS (
    SELECT
        order_id,
        SUM(price) AS total_price,
        COUNT(*) AS item_count
    FROM order_items
    GROUP BY order_id
),
delivered_orders AS (
    SELECT
        om.order_id,
        om.total_price,
        om.item_count
    FROM order_metrics AS om
    INNER JOIN orders AS o
        ON om.order_id = o.order_id
    WHERE o.order_status = 'delivered'
)
SELECT
    order_id,
    total_price,
    item_count
FROM delivered_orders
WHERE item_count >= 2
ORDER BY total_price DESC
LIMIT 10;


-- 03. Scalar subquery: items priced above the item average

SELECT
    order_id,
    product_id,
    price
FROM order_items
WHERE price > (
    SELECT AVG(price)
    FROM order_items
)
ORDER BY price DESC
LIMIT 15;


-- 04. IN subquery: expensive items belonging to delivered orders

SELECT
    oi.order_id,
    oi.product_id,
    oi.price
FROM order_items AS oi
WHERE oi.price > 100
  AND oi.order_id IN (
      SELECT o.order_id
      FROM orders AS o
      WHERE o.order_status = 'delivered'
  )
ORDER BY oi.price DESC
LIMIT 20;


-- 05. Derived table: orders with > 300 in goods and >= 2 items

SELECT
    order_id,
    total_price,
    item_count
FROM (
    SELECT
        order_id,
        SUM(price) AS total_price,
        COUNT(*) AS item_count
    FROM order_items
    GROUP BY order_id
) AS order_totals
WHERE total_price > 300
  AND item_count >= 2
ORDER BY total_price DESC
LIMIT 20;


-- 06. Nested subqueries: orders above the mean order revenue

SELECT
    order_id,
    SUM(price) AS total_revenue
FROM order_items
GROUP BY order_id
HAVING SUM(price) > (
    SELECT AVG(total_revenue)
    FROM (
        SELECT
            order_id,
            SUM(price) AS total_revenue
        FROM order_items
        GROUP BY order_id
    ) AS order_average
)
ORDER BY total_revenue DESC
LIMIT 20;


-- 07. EXISTS: delivered orders with at least one item > 300

SELECT
    o.order_id,
    o.order_status
FROM orders AS o
WHERE o.order_status = 'delivered'
  AND EXISTS (
      SELECT 1
      FROM order_items AS oi
      WHERE oi.order_id = o.order_id
        AND oi.price > 300
  )
ORDER BY o.order_id
LIMIT 20;


-- 08. NOT EXISTS: delivered orders without any item > 300

SELECT
    o.order_id,
    o.order_status
FROM orders AS o
WHERE o.order_status = 'delivered'
  AND NOT EXISTS (
      SELECT 1
      FROM order_items AS oi
      WHERE oi.order_id = o.order_id
        AND oi.price > 300
  )
ORDER BY o.order_id
LIMIT 20;


-- 09. NOT IN: orders without any items; exclude NULL in subquery

SELECT
    o.order_id,
    o.order_status
FROM orders AS o
WHERE o.order_id NOT IN (
    SELECT oi.order_id
    FROM order_items AS oi
    WHERE oi.order_id IS NOT NULL
)
LIMIT 20;


-- 10. Conditional aggregation: order counts by status

SELECT
    SUM(CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered_count,
    SUM(CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END) AS canceled_count,
    SUM(CASE WHEN o.order_status NOT IN ('delivered', 'canceled') THEN 1 ELSE 0 END) AS other_count
FROM orders AS o;
-- Note: NULL order_status would not count as 'other' with NOT IN.


-- 11. Derived table + LEFT JOIN + COALESCE: all orders, even empty

SELECT
    o.order_status,
    o.order_id,
    COALESCE(ot.item_count, 0) AS item_count,
    COALESCE(ot.total_price, 0) AS total_price
FROM orders AS o
LEFT JOIN (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS total_price
    FROM order_items
    GROUP BY order_id
) AS ot
    ON o.order_id = ot.order_id
ORDER BY total_price DESC
LIMIT 20;


-- 12. CASE + COALESCE: categorize each order by goods value

SELECT
    o.order_status,
    o.order_id,
    CASE
        WHEN COALESCE(ot.total_price, 0) >= 500 THEN 'high'
        WHEN COALESCE(ot.total_price, 0) >= 200 THEN 'medium'
        ELSE 'low'
    END AS order_category,
    COALESCE(ot.item_count, 0) AS item_count,
    COALESCE(ot.total_price, 0) AS total_price
FROM orders AS o
LEFT JOIN (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS total_price
    FROM order_items
    GROUP BY order_id
) AS ot
    ON o.order_id = ot.order_id
ORDER BY total_price DESC
LIMIT 20;

-- 13. Window functions: order-level metrics

SELECT 
	oi.order_id,
	oi.product_id,
	oi.price,
	SUM(price) OVER (
	PARTITION BY oi.order_id) AS order_total,
	COUNT(*) OVER (
	PARTITION BY oi.order_id) AS item_count,
	AVG(price) OVER (PARTITION BY oi.order_id ) AS avg_item_price 
FROM order_items AS oi
ORDER BY oi.order_id, oi.price DESC
LIMIT 20;


-- 14. Compare each item price with its order average


SELECT 
	oi.order_id,
	oi.product_id,
	oi.price,
	AVG(price) OVER (PARTITION BY oi.order_id) AS avg_order_price,
	price - AVG(price) OVER (PARTITION BY oi.order_id) AS difference
FROM order_items AS oi
ORDER BY oi.order_id, oi.price DESC
LIMIT 20;


-- 15. Rank order items by price

SELECT 
	oi.order_id,
	oi.product_id,
	oi.price,
	row_number() OVER (
	ORDER BY price DESC 
	) AS row_num,
	rank() OVER (
	ORDER BY price DESC 
	) AS price_rank,
	dense_rank() OVER (
	ORDER BY price DESC 
	) AS dense_price_rank
FROM order_items AS oi
ORDER BY oi.price DESC
LIMIT 20;

-- 16. Rank items by price within each order

SELECT 
	oi.order_id,
	oi.product_id,
	oi.price,
	row_number() OVER (
	PARTITION BY oi.order_id
	ORDER BY oi.price DESC
	) AS row_num,
	rank() OVER (
	PARTITION BY oi.order_id
	ORDER BY oi.price DESC
	) AS price_rank,
	dense_rank() OVER (
	PARTITION BY oi.order_id
	ORDER BY oi.price DESC
	) AS dense_price_rank
FROM order_items AS oi 
ORDER BY oi.order_id, oi.price DESC
LIMIT 30;



-- 17. Calculate each item's share of order value



SELECT 
	oi.order_id,
	oi.product_id,
	oi.price,
	SUM(oi.price) OVER (
	PARTITION BY order_id) AS order_total,
	ROUND(
	oi.price * 100.0 / 
	NULLIF (
		SUM(oi.price) OVER (PARTITION BY oi.order_id),
		0
		),
		2
	) AS item_share_pct
FROM order_items AS oi
ORDER BY order_id, oi.price DESC 
LIMIT 30;
	
-- 18. Calculate each item's share of total revenue
	

SELECT 
	oi.order_id,
	oi.product_id,
	oi.price,
	SUM(oi.price) OVER () AS total_revenue,
	ROUND(
	oi.price * 100.0 / 
	NULLIF (
		SUM(oi.price) OVER (),
		0
		),
		4
	) AS revenue_share_pct
FROM order_items AS oi
ORDER BY oi.price DESC
LIMIT 20;

-- 19. Compare each item price with the previous item in its order

SELECT 
	order_id,
	order_item_id,
	price,
	LAG(price) OVER (
		PARTITION BY order_id
		ORDER BY order_item_id
	) AS previous_price,
	price - LAG(price) OVER (
    	PARTITION BY order_id
    	ORDER BY order_item_id
	) AS price_difference
FROM order_items 
ORDER BY order_id, order_item_id
LIMIT 30;

-- 20. Compare each item price with the next item in its order

SELECT  
	order_id,
	order_item_id,
	price, 
	LEAD(price) OVER (
		PARTITION BY order_id
		ORDER BY order_item_id
	) AS next_price,
	LEAD(price) OVER (
		PARTITION BY order_id
		ORDER BY order_item_id) - price AS difference_to_next
FROM order_items 
ORDER BY order_id, order_item_id
LIMIT 30;


WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        ) AS month,
        SUM(oi.price) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    month,
    revenue
FROM monthly_revenue
ORDER BY month;


-- 21. Compare monthly revenue with the previous month
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        ) AS month,
        SUM(oi.price) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
	month,
    revenue,
	lag(revenue) OVER (
			ORDER BY month  
		) previous_month_revenue,
	revenue - LAG(revenue) OVER (
    ORDER BY month
	) AS revenue_change
FROM monthly_revenue
ORDER BY month;


-- 22. Calculate cumulative monthly revenue and revenue share

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        ) AS month,
        SUM(oi.price) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT 
	month,
	revenue,
	SUM(revenue) OVER (
		ORDER BY month 
		ROWS BETWEEN UNBOUNDED PRECEDING 
			AND CURRENT ROW 
		) AS running_revenue,
	ROUND(
		revenue * 100.0 /
		NULLIF (
		SUM(revenue) OVER (), 
		0
		),
		2
	) AS revenue_share_pct
FROM monthly_revenue 
ORDER BY month;




SELECT 
	COUNT(DISTINCT order_id) AS order_count,
	COUNT(order_item_id) AS item_count,
	SUM(price) AS total_price
FROM order_items;


EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE order_status = 'delivered';

CREATE INDEX idx_orders_status
ON orders (order_status);

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE order_status = 'delivered';

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE order_status = 'created';


-- WEEK 5 GATE
-- G1: CTE and average order value
WITH order_totals AS (
	SELECT 
		oi.order_id,
		SUM(oi.price) AS total_price
	FROM order_items AS oi
	GROUP BY oi.order_id
)
SELECT
	order_id,
	total_price
FROM order_totals AS ot
WHERE ot.total_price > (SELECT AVG(total_price) FROM order_totals)
ORDER BY ot.total_price DESC;

-- G2: NOT EXISTS
SELECT 
	o.order_id,
	o.order_status
FROM orders AS o
WHERE NOT EXISTS (
	SELECT 1
	FROM order_items AS oi
	WHERE o.order_id = oi.order_id
)
ORDER BY order_id ASC;


-- G3: DENSE_RANK by order
SELECT 
	order_id,
	order_item_id,
	price,
	dense_rank() OVER (
		PARTITION BY order_id
		ORDER BY price DESC
	) AS price_rank 
FROM order_items 
ORDER BY order_id, price_rank;

-- G4: Index performance analysis

EXPLAIN ANALYZE 
SELECT *
FROM orders 
WHERE order_status = 'unavalaible';

-- G5: LAG - Previous item price within each order

SELECT 
	order_id,
	order_item_id,
	price, 
	lag(price) OVER (
		PARTITION BY order_id
		ORDER BY order_item_id
	) AS previous_price 
FROM order_items 
ORDER BY order_id, order_item_id;

SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(SUM(price)::numeric, 2) AS total_price
FROM order_items;