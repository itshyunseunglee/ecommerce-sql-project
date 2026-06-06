-- ============================================================
-- 02. Sales Analysis
-- ============================================================
USE ecommerce;


-- ------------------------------------------------------------
-- 2-1. Total revenue summary (excluding cancellations & returns)
-- ------------------------------------------------------------
SELECT
    COUNT(DISTINCT i.invoice_no)          AS total_invoices,
    COUNT(DISTINCT i.customer_id)         AS total_customers,
    SUM(ii.quantity)                      AS total_units_sold,
    ROUND(SUM(ii.line_total), 2)          AS gross_revenue,
    ROUND(AVG(ii.line_total), 2)          AS avg_line_value
FROM invoices      AS i
JOIN invoice_items AS ii ON i.invoice_no = ii.invoice_no
WHERE i.is_cancelled = 0
  AND ii.quantity    > 0
  AND ii.unit_price  > 0;


-- ------------------------------------------------------------
-- 2-2. Monthly revenue & average order value (AOV)
-- ------------------------------------------------------------
SELECT
    DATE_FORMAT(i.invoice_date, '%Y-%m')              AS month,
    COUNT(DISTINCT i.invoice_no)                      AS invoices,
    ROUND(SUM(ii.line_total), 2)                      AS revenue,
    ROUND(SUM(ii.line_total)
          / COUNT(DISTINCT i.invoice_no), 2)          AS aov
FROM invoices      AS i
JOIN invoice_items AS ii ON i.invoice_no = ii.invoice_no
WHERE i.is_cancelled = 0
  AND ii.quantity    > 0
  AND ii.unit_price  > 0
GROUP BY month
ORDER BY month;


-- ------------------------------------------------------------
-- 2-3. Month-over-month revenue growth rate
-- ------------------------------------------------------------
WITH monthly AS (
    SELECT
        DATE_FORMAT(i.invoice_date, '%Y-%m') AS month,
        ROUND(SUM(ii.line_total), 2)         AS revenue
    FROM invoices      AS i
    JOIN invoice_items AS ii ON i.invoice_no = ii.invoice_no
    WHERE i.is_cancelled = 0
      AND ii.quantity    > 0
      AND ii.unit_price  > 0
    GROUP BY month
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month)                AS prev_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month) * 100, 2
    )                                                  AS mom_growth_pct
FROM monthly
ORDER BY month;


-- ------------------------------------------------------------
-- 2-4. Revenue by country (top 15)
-- ------------------------------------------------------------
SELECT
    c.name                                                   AS country,
    COUNT(DISTINCT i.invoice_no)                             AS invoices,
    ROUND(SUM(ii.line_total), 2)                             AS revenue,
    ROUND(SUM(ii.line_total) * 100.0
          / SUM(SUM(ii.line_total)) OVER(), 2)               AS revenue_pct
FROM invoices      AS i
JOIN invoice_items AS ii ON i.invoice_no = ii.invoice_no
JOIN countries     AS c  ON i.country_id = c.country_id
WHERE i.is_cancelled = 0
  AND ii.quantity    > 0
  AND ii.unit_price  > 0
GROUP BY c.name
ORDER BY revenue DESC
LIMIT 15;


-- ------------------------------------------------------------
-- 2-5. Revenue by day of week
-- ------------------------------------------------------------
SELECT
    DAYNAME(i.invoice_date)              AS day_of_week,
    DAYOFWEEK(i.invoice_date)            AS dow_num,
    COUNT(DISTINCT i.invoice_no)         AS invoices,
    ROUND(SUM(ii.line_total), 2)         AS revenue
FROM invoices      AS i
JOIN invoice_items AS ii ON i.invoice_no = ii.invoice_no
WHERE i.is_cancelled = 0
  AND ii.quantity    > 0
  AND ii.unit_price  > 0
GROUP BY day_of_week, dow_num
ORDER BY dow_num;


-- ------------------------------------------------------------
-- 2-6. Revenue by hour of day
-- ------------------------------------------------------------
SELECT
    HOUR(i.invoice_date)                 AS hour_of_day,
    COUNT(DISTINCT i.invoice_no)         AS invoices,
    ROUND(SUM(ii.line_total), 2)         AS revenue
FROM invoices      AS i
JOIN invoice_items AS ii ON i.invoice_no = ii.invoice_no
WHERE i.is_cancelled = 0
  AND ii.quantity    > 0
  AND ii.unit_price  > 0
GROUP BY hour_of_day
ORDER BY hour_of_day;


-- ------------------------------------------------------------
-- 2-7. Cancellation rate by country (top 15 by invoice volume)
-- ------------------------------------------------------------
SELECT
    c.name                                                        AS country,
    COUNT(DISTINCT i.invoice_no)                                  AS total_invoices,
    COUNT(DISTINCT CASE WHEN i.is_cancelled = 1
                   THEN i.invoice_no END)                         AS cancelled,
    ROUND(COUNT(DISTINCT CASE WHEN i.is_cancelled = 1
                         THEN i.invoice_no END) * 100.0
          / COUNT(DISTINCT i.invoice_no), 2)                      AS cancel_rate_pct
FROM invoices  AS i
JOIN countries AS c ON i.country_id = c.country_id
GROUP BY c.name
ORDER BY total_invoices DESC
LIMIT 15;


-- ------------------------------------------------------------
-- 2-8. Quarterly revenue (year-over-year)
-- ------------------------------------------------------------
SELECT
    YEAR(i.invoice_date)             AS yr,
    QUARTER(i.invoice_date)          AS qtr,
    ROUND(SUM(ii.line_total), 2)     AS revenue
FROM invoices      AS i
JOIN invoice_items AS ii ON i.invoice_no = ii.invoice_no
WHERE i.is_cancelled = 0
  AND ii.quantity    > 0
  AND ii.unit_price  > 0
GROUP BY yr, qtr
ORDER BY yr, qtr;
