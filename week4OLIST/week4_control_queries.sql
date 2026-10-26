-- Week 4: Olist monthly exports
-- Grain: one row per order
-- Period: January–March 2018
-- Include all order statuses
-- Monetary values: BRL

-- 1. Aggregate order items

-- 2. Build the order-level export

-- 3. Filter and export each month

-- 4. Calculate control totals

WITH total_price AS ( 
	SELECT 
		oi.order_id,
		COUNT(*) AS item_count,
		SUM(oi.price) AS total_price,
		SUM(oi.freight_value) AS freight_total
	FROM order_items AS oi 
	GROUP BY oi.order_id 
)
SELECT 
	c.customer_state,
	o.order_id,
	o.order_status,
	o.order_purchase_timestamp,
	CASE 
		WHEN tp.order_id IS NULL THEN 0
		ELSE 1
	END AS has_items,
	COALESCE(tp.item_count, 0) AS item_count,
    tp.total_price,
    tp.freight_total,
    tp.total_price + tp.freight_total AS order_total
FROM orders AS o
LEFT JOIN total_price AS tp
	ON o.order_id = tp.order_id 
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE order_purchase_timestamp >= '2018-03-01'
  AND order_purchase_timestamp < '2018-04-01'
ORDER BY o.order_purchase_timestamp, o.order_id;




WITH total_price AS ( 
	SELECT 
		oi.order_id,
		COUNT(*) AS item_count,
		SUM(oi.price) AS total_price,
		SUM(oi.freight_value) AS freight_total
	FROM order_items AS oi 
	GROUP BY oi.order_id 
)
SELECT 
    COUNT(*) AS row_count,
    COUNT(DISTINCT o.order_id) AS unique_orders,
    SUM(tp.total_price) AS goods_sum,
    SUM(tp.freight_total) AS freight_sum,
    SUM(tp.total_price + tp.freight_total) AS order_sum,
    SUM(
        CASE WHEN tp.order_id IS NULL THEN 1 ELSE 0 END
    ) AS orders_without_items
FROM orders AS o
LEFT JOIN total_price AS tp
	ON o.order_id = tp.order_id 
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE o.order_purchase_timestamp >= TIMESTAMP '2018-01-01'
  AND o.order_purchase_timestamp <  TIMESTAMP '2018-02-01';