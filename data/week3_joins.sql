SELECT 
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp
FROM orders AS o 
INNER JOIN customers as c 
	on o.customer_id = c.customer_id 
LIMIT  20;


SELECT 
	COUNT(*) AS joined_rows,
	COUNT(DISTINCT o.order_id) AS unique_orders,
	COUNT(DISTINCT o.customer_id) AS unique_customer_ids,
	COUNT(DISTINCT c.customer_unique_id) AS real_customers
FROM orders AS o
INNER JOIN customers AS c
ON o.customer_id = c.customer_id;
	


SELECT 
	c.customer_state,
	COUNT(DISTINCT o.order_id ) AS delivered_orders,
	COUNT(DISTINCT  c.customer_unique_id) AS real_customers
FROM orders AS o
INNER JOIN customers AS c
ON o.customer_id = c.customer_id 
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY delivered_orders DESC 
LIMIT 10;


SELECT 
	o.order_id,
	o.order_status,
	o.order_purchase_timestamp,
	oi.order_item_id,
	oi.product_id,
	oi.price,
	oi.freight_value
FROM orders AS o
INNER JOIN order_items AS oi
	ON o.order_id = oi.order_id
	LIMIT 40;


SELECT 
	COUNT(*) AS joined_rows,
	COUNT(DISTINCT o.order_id ) AS unique_orders, 
	COUNT(DISTINCT oi.product_id) AS unique_products,
	ROUND(COUNT(*)::NUMERIC / COUNT(DISTINCT o.order_id), 2) AS avg_items_per_order
FROM orders AS o 
INNER JOIN order_items AS oi 
	ON o.order_id=oi.order_id


	
SELECT 
	o.order_id,
	oi.order_item_id,
	oi.product_id,
	p.product_category_name,
	oi.price,
	oi.freight_value,
	p.product_weight_g,
	p.product_photos_qty
FROM orders AS o 
INNER JOIN order_items AS oi 
	ON o.order_id=oi.order_id
INNER JOIN products AS p 
ON oi.product_id = p.product_id
LIMIT 20;




SELECT 
	COUNT(*) AS joined_rows,
	COUNT(DISTINCT o.order_id ) AS unique_orders, 
	COUNT(DISTINCT oi.product_id) AS unique_products,
	SUM(oi.price ) AS total_product_value,
	SUM(oi.freight_value ) AS total_freight_value
FROM orders AS o 
INNER JOIN order_items AS oi 
	ON o.order_id=oi.order_id
INNER JOIN products AS p 
ON oi.product_id = p.product_id




SELECT
	o.order_id,
	o.order_status, 
	o.order_purchase_timestamp
FROM orders AS o
LEFT JOIN order_items AS oi
ON o.order_id=oi.order_id
WHERE oi.order_id IS NULL
LIMIT 20;


SELECT
    COUNT(*) AS empty_orders_count
FROM orders AS o
LEFT JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;




SELECT
	o.order_status,
	COUNT(o.order_id) AS empty_orders_count
FROM orders AS o
LEFT JOIN order_items AS oi
ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
GROUP BY o.order_status 
ORDER BY empty_orders_count DESC;



SELECT 
	COUNT(*) AS unsold_products
FROM products AS p
LEFT JOIN order_items AS oi
ON p.product_id = oi.product_id 
WHERE oi.product_id IS NULL





SELECT 
	o.order_id,
	c.customer_unique_id,
	c.customer_state,
	o.order_status,
	o.order_purchase_timestamp,
	oi.order_item_id,
	oi.product_id,
	p.product_category_name,
	ct.product_category_name_english,
	oi.price,
	oi.freight_value
FROM order_items AS oi
INNER JOIN orders AS o
ON oi.order_id  = o.order_id
INNER JOIN customers AS c
ON o.customer_id = c.customer_id 
INNER JOIN products AS p
ON oi.product_id = p.product_id 
LEFT JOIN category_translation AS ct 
ON p.product_category_name =ct.product_category_name
LIMIT 20;





SELECT 
	COUNT(*) AS joined_rows,
	COUNT(DISTINCT o.order_id) AS unique_orders,
	COUNT(DISTINCT c.customer_unique_id ) AS real_customers,
	SUM(oi.price) AS total_product_value,
	SUM(oi.freight_value) AS total_freight_value		
FROM order_items AS oi
INNER JOIN orders AS o
ON oi.order_id  = o.order_id
INNER JOIN customers AS c
ON o.customer_id = c.customer_id 
INNER JOIN products AS p
ON oi.product_id = p.product_id 
LEFT JOIN category_translation AS ct 
ON p.product_category_name =ct.product_category_name;







-- 1.2.1 Group orders by status
SELECT
    order_id,
    order_status,
    CASE
        WHEN order_status = 'delivered' THEN 'successful'
        WHEN order_status IN ('canceled', 'unavailable') THEN 'problem'
        ELSE 'in_progress'
    END AS status_group
FROM orders;



-- 1.2.2 Classify orders by delivery timeliness

SELECT
    o.order_id,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    CASE
        WHEN order_delivered_customer_date IS NULL  THEN 'unknown'
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'on_time'
        ELSE 'late'
    END AS delivery_status
FROM orders AS o;



-- Check the number of orders in each delivery group

SELECT
    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN 'unknown'
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
            THEN 'on_time'
        ELSE 'late'
    END AS delivery_status,
    COUNT(*) AS order_count
FROM orders AS o
GROUP BY delivery_status
ORDER BY order_count DESC;

-- 1.2.3 Count orders by status group using conditional aggregation

SELECT 
	COUNT(*) AS total_orders,
	SUM(CASE
		WHEN o.order_status = 'delivered' THEN 1
		ELSE 0
	END
	) AS delivered_orders,
	SUM(CASE
		WHEN o.order_status IN ('canceled', 'unavailable') THEN 1
		ELSE 0
	END
	) AS problem_orders,
	SUM(CASE 
		WHEN o.order_status  NOT IN ('canceled', 'unavailable', 'delivered') THEN 1
		ELSE 0
	END
	) AS other_orders
	
FROM orders AS o;
	

-- 1.2.4 Replace missing product categories with COALESCE

SELECT
	p.product_id,
	p.product_category_name,
	COALESCE( p.product_category_name, 'unknown') AS category_clean
FROM products AS p


-- 2.2.1 Aggregate order items to the order level


WITH item_totals AS (
	SELECT 
	COUNT(*) AS item_count,
	oi.order_id,
	SUM(oi.price) AS item_total, 
	
	SUM(oi.freight_value) AS freight_total
	FROM order_items AS oi
	GROUP BY oi.order_id
)

SELECT 
	*
FROM item_totals 
LIMIT 10;

-- 2.2.2 Join order-level item totals to orders

WITH item_totals AS (
    SELECT
        COUNT(*) AS item_count,
        oi.order_id,
        SUM(oi.price) AS item_total,
        SUM(oi.freight_value) AS freight_total
    FROM order_items AS oi
    GROUP BY oi.order_id
)
SELECT
    o.order_id,
    o.order_status,
    it.item_count,
    it.item_total,
    it.freight_total
FROM orders AS o
LEFT JOIN item_totals AS it
    ON o.order_id = it.order_id
LIMIT 10;

-- 2.2.3 Validate row counts and totals after the join

WITH item_totals AS (
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
    SUM(
        CASE
            WHEN it.order_id IS NULL THEN 1
            ELSE 0
        END
    ) AS orders_without_items,
    SUM(it.total_price) AS total_item_value,
    SUM(it.freight_total) AS total_freight_value
FROM orders AS o
LEFT JOIN item_totals AS it
    ON o.order_id = it.order_id;


-- 2.2.4 Calculate order metrics by customer state

WITH item_totals AS (
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
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(DISTINCT c.customer_unique_id) AS customer_count,
    SUM(it.total_price ) AS total_item_value,
    SUM(it.freight_total ) AS total_freight_value,
    AVG(it.total_price) AS avg_order_value
FROM orders AS o
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN item_totals AS it
    ON o.order_id = it.order_id
GROUP BY c.customer_state
ORDER BY total_item_value DESC;

-- 2.2.5 Compare row counts without pre-aggregation

SELECT 
	COUNT(*) AS row_count,
	COUNT(DISTINCT o.order_id) AS unique_orders, 
	SUM(oi.price) AS total_item_value,
	SUM(oi.freight_value) AS total_freight_value
FROM orders AS o
LEFT JOIN order_items AS oi 
	ON o.order_id = oi.order_id;
	
	
	
	

-- 1.1 Count orders without order-item records by status


SELECT
	o.order_status,
	COUNT(*) AS order_count
FROM orders AS o
LEFT JOIN order_items AS oi
	ON o.order_id = oi.order_id 
WHERE oi.order_id IS NULL
GROUP BY o.order_status
ORDER BY order_count DESC;


-- 1.2 Count order-item records without matching products

SELECT
	COUNT(*) AS items_without_products
FROM order_items AS io
LEFT JOIN products AS p
	ON io.product_id = p.product_id 
WHERE p.product_id IS NULL;

-- 1.3 Count orders without matching customers

SELECT
	COUNT(*) AS orders_without_customers
FROM orders AS o
LEFT JOIN customers AS c
	ON o.customer_id = c.customer_id 
WHERE c.customer_id  IS NULL

-- 2.1 Count orders without order-item records by customer state

SELECT
    c.customer_state,
    COUNT(*) AS order_count
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
GROUP BY c.customer_state
ORDER BY order_count DESC;






















