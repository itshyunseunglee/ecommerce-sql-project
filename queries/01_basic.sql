-- ============================================================
-- 01. Basic Queries
-- ============================================================
USE ecommerce;


-- ------------------------------------------------------------
-- 1-1. Row counts per table
-- ------------------------------------------------------------
SELECT 'countries'    AS tbl, COUNT(*) AS cnt FROM countries
UNION ALL
SELECT 'customers'    AS tbl, COUNT(*) AS cnt FROM customers
UNION ALL
SELECT 'products'     AS tbl, COUNT(*) AS cnt FROM products
UNION ALL
SELECT 'invoices'     AS tbl, COUNT(*) AS cnt FROM invoices
UNION ALL
SELECT 'invoice_items' AS tbl, COUNT(*) AS cnt FROM invoice_items;


-- ------------------------------------------------------------
-- 1-2. Date range of the dataset
-- ------------------------------------------------------------
SELECT
    MIN(invoice_date)                              AS first_order,
    MAX(invoice_date)                              AS last_order,
    DATEDIFF(MAX(invoice_date), MIN(invoice_date)) AS days_span
FROM invoices;


-- ------------------------------------------------------------
-- 1-3. Cancelled vs normal invoices
-- ------------------------------------------------------------
SELECT
    is_cancelled,
    COUNT(*)                                              AS invoice_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)    AS pct
FROM invoices
GROUP BY is_cancelled;


-- ------------------------------------------------------------
-- 1-4. Guest vs registered customer orders
-- ------------------------------------------------------------
SELECT
    CASE WHEN customer_id IS NULL THEN 'Guest' ELSE 'Registered' END AS customer_type,
    COUNT(*)                                                          AS invoice_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)                AS pct
FROM invoices
GROUP BY customer_type;


-- ------------------------------------------------------------
-- 1-5. Top 10 countries by number of invoices
-- ------------------------------------------------------------
SELECT
    c.name               AS country,
    COUNT(i.invoice_no)  AS invoice_count
FROM invoices  AS i
JOIN countries AS c ON i.country_id = c.country_id
WHERE i.is_cancelled = 0
GROUP BY c.name
ORDER BY invoice_count DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 1-6. Top 10 best-selling products (by quantity sold)
-- ------------------------------------------------------------
SELECT
    ii.stock_code,
    ii.description,
    SUM(ii.quantity)             AS total_qty,
    ROUND(SUM(ii.line_total), 2) AS total_revenue
FROM invoice_items AS ii
JOIN invoices      AS i ON ii.invoice_no = i.invoice_no
JOIN products      AS p ON ii.stock_code = p.stock_code
WHERE i.is_cancelled = 0
  AND ii.quantity    > 0
  AND p.is_product   = 1
GROUP BY ii.stock_code, ii.description
ORDER BY total_qty DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 1-7. Top 10 products by revenue
-- ------------------------------------------------------------
SELECT
    ii.stock_code,
    ii.description,
    ROUND(SUM(ii.line_total), 2) AS total_revenue,
    SUM(ii.quantity)             AS total_qty
FROM invoice_items AS ii
JOIN invoices      AS i ON ii.invoice_no = i.invoice_no
JOIN products      AS p ON ii.stock_code = p.stock_code
WHERE i.is_cancelled = 0
  AND ii.quantity    > 0
  AND p.is_product   = 1
GROUP BY ii.stock_code, ii.description
ORDER BY total_revenue DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 1-8. Monthly order count trend
-- ------------------------------------------------------------
SELECT
    DATE_FORMAT(invoice_date, '%Y-%m') AS month,
    COUNT(DISTINCT invoice_no)         AS invoice_count,
    COUNT(DISTINCT customer_id)        AS active_customers
FROM invoices
WHERE is_cancelled = 0
GROUP BY month
ORDER BY month;


-- ------------------------------------------------------------
-- 1-9. Products priced above average
-- ------------------------------------------------------------
SELECT
    ii.stock_code,
    ii.description,
    ROUND(AVG(ii.unit_price), 2) AS avg_price
FROM invoice_items AS ii
JOIN products      AS p ON ii.stock_code = p.stock_code
WHERE ii.unit_price > 0
  AND p.is_product  = 1
GROUP BY ii.stock_code, ii.description
HAVING avg_price > (
    SELECT AVG(unit_price)
    FROM invoice_items
    WHERE unit_price > 0
)
ORDER BY avg_price DESC
LIMIT 20;


-- ------------------------------------------------------------
-- 1-10. Customers who placed more than 20 orders
-- ------------------------------------------------------------
SELECT
    i.customer_id,
    COUNT(DISTINCT i.invoice_no) AS order_count,
    ROUND(SUM(ii.line_total), 2) AS total_spent
FROM invoices      AS i
JOIN invoice_items AS ii ON i.invoice_no = ii.invoice_no
WHERE i.is_cancelled = 0
  AND i.customer_id  IS NOT NULL
GROUP BY i.customer_id
HAVING order_count > 20
ORDER BY order_count DESC;
