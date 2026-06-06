-- ============================================================
-- 03. Customer Analysis
-- ============================================================
USE ecommerce;


-- ------------------------------------------------------------
-- 3-1. New customers acquired per month
-- ------------------------------------------------------------
SELECT
    DATE_FORMAT(first_seen_at, '%Y-%m') AS cohort_month,
    COUNT(*)                            AS new_customers
FROM customers
GROUP BY cohort_month
ORDER BY cohort_month;


-- ------------------------------------------------------------
-- 3-2. One-time vs repeat buyers
-- ------------------------------------------------------------
WITH order_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS order_count
    FROM invoices
    WHERE is_cancelled = 0
      AND customer_id  IS NOT NULL
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN order_count = 1              THEN '1 order (one-time)'
        WHEN order_count BETWEEN 2 AND 5  THEN '2-5 orders'
        WHEN order_count BETWEEN 6 AND 10 THEN '6-10 orders'
        ELSE '11+ orders'
    END                                                        AS segment,
    COUNT(*)                                                   AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)         AS pct
FROM order_counts
GROUP BY segment
ORDER BY MIN(order_count);


-- ------------------------------------------------------------
-- 3-3. Top 20 customers by lifetime value (LTV)
-- ------------------------------------------------------------
SELECT
    i.customer_id,
    c.name                                AS country,
    COUNT(DISTINCT i.invoice_no)          AS total_orders,
    SUM(ii.quantity)                      AS total_units,
    ROUND(SUM(ii.line_total), 2)          AS ltv,
    ROUND(SUM(ii.line_total)
          / COUNT(DISTINCT i.invoice_no), 2) AS avg_order_value
FROM invoices      AS i
JOIN invoice_items AS ii ON i.invoice_no  = ii.invoice_no
JOIN customers     AS cu ON i.customer_id = cu.customer_id
JOIN countries     AS c  ON cu.country_id = c.country_id
WHERE i.is_cancelled = 0
  AND ii.quantity    > 0
  AND ii.unit_price  > 0
GROUP BY i.customer_id, c.name
ORDER BY ltv DESC
LIMIT 20;


-- ------------------------------------------------------------
-- 3-4. Average days between orders (purchase frequency)
-- ------------------------------------------------------------
WITH order_dates AS (
    SELECT
        customer_id,
        invoice_date,
        LAG(invoice_date) OVER (PARTITION BY customer_id ORDER BY invoice_date) AS prev_date
    FROM invoices
    WHERE is_cancelled = 0
      AND customer_id  IS NOT NULL
),
gaps AS (
    SELECT
        customer_id,
        DATEDIFF(invoice_date, prev_date) AS days_between
    FROM order_dates
    WHERE prev_date IS NOT NULL
)
SELECT
    ROUND(AVG(days_between), 1)  AS avg_days_between_orders,
    ROUND(MIN(days_between), 1)  AS min_days,
    ROUND(MAX(days_between), 1)  AS max_days,
    COUNT(DISTINCT customer_id)  AS customers_with_repeat
FROM gaps;


-- ------------------------------------------------------------
-- 3-5. Monthly cohort retention (M0 ~ M3)
-- ------------------------------------------------------------
WITH cohort_base AS (
    SELECT
        customer_id,
        DATE_FORMAT(MIN(invoice_date), '%Y-%m') AS cohort_month
    FROM invoices
    WHERE is_cancelled = 0
      AND customer_id  IS NOT NULL
    GROUP BY customer_id
),
activity AS (
    SELECT
        i.customer_id,
        DATE_FORMAT(i.invoice_date, '%Y-%m') AS active_month
    FROM invoices AS i
    WHERE i.is_cancelled = 0
      AND i.customer_id  IS NOT NULL
    GROUP BY i.customer_id, active_month
)
SELECT
    cb.cohort_month,
    COUNT(DISTINCT cb.customer_id)                                AS cohort_size,
    COUNT(DISTINCT CASE WHEN a.active_month = cb.cohort_month
                   THEN a.customer_id END)                        AS month_0,
    COUNT(DISTINCT CASE
        WHEN PERIOD_DIFF(REPLACE(a.active_month, '-', ''),
                         REPLACE(cb.cohort_month, '-', '')) = 1
        THEN a.customer_id END)                                   AS month_1,
    COUNT(DISTINCT CASE
        WHEN PERIOD_DIFF(REPLACE(a.active_month, '-', ''),
                         REPLACE(cb.cohort_month, '-', '')) = 2
        THEN a.customer_id END)                                   AS month_2,
    COUNT(DISTINCT CASE
        WHEN PERIOD_DIFF(REPLACE(a.active_month, '-', ''),
                         REPLACE(cb.cohort_month, '-', '')) = 3
        THEN a.customer_id END)                                   AS month_3
FROM cohort_base AS cb
LEFT JOIN activity AS a ON cb.customer_id = a.customer_id
GROUP BY cb.cohort_month
ORDER BY cb.cohort_month;


-- ------------------------------------------------------------
-- 3-6. Revenue distribution: top 10% vs bottom 90% of customers
-- ------------------------------------------------------------
WITH customer_ltv AS (
    SELECT
        i.customer_id,
        ROUND(SUM(ii.line_total), 2) AS ltv
    FROM invoices      AS i
    JOIN invoice_items AS ii ON i.invoice_no = ii.invoice_no
    WHERE i.is_cancelled = 0
      AND ii.quantity    > 0
      AND ii.unit_price  > 0
      AND i.customer_id  IS NOT NULL
    GROUP BY i.customer_id
),
ranked AS (
    SELECT
        customer_id,
        ltv,
        NTILE(10) OVER (ORDER BY ltv DESC) AS decile
    FROM customer_ltv
)
SELECT
    CASE WHEN decile = 1 THEN 'Top 10%' ELSE 'Bottom 90%' END    AS segment,
    COUNT(*)                                                       AS customers,
    ROUND(SUM(ltv), 2)                                            AS total_revenue,
    ROUND(SUM(ltv) * 100.0 / SUM(SUM(ltv)) OVER(), 2)            AS revenue_pct
FROM ranked
GROUP BY segment;
