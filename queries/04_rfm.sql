-- ============================================================
-- 04. RFM Analysis (Recency · Frequency · Monetary)
-- ============================================================
-- Reference date: 2011-12-10 (day after last transaction in dataset)
-- ============================================================
USE ecommerce;


-- ------------------------------------------------------------
-- 4-1. Raw RFM values per customer
-- ------------------------------------------------------------
WITH rfm_raw AS (
    SELECT
        i.customer_id,
        DATEDIFF('2011-12-10', MAX(i.invoice_date)) AS recency,
        COUNT(DISTINCT i.invoice_no)                AS frequency,
        ROUND(SUM(ii.line_total), 2)                AS monetary
    FROM invoices      AS i
    JOIN invoice_items AS ii ON i.invoice_no = ii.invoice_no
    WHERE i.is_cancelled = 0
      AND ii.quantity    > 0
      AND ii.unit_price  > 0
      AND i.customer_id  IS NOT NULL
    GROUP BY i.customer_id
)
SELECT *
FROM rfm_raw
ORDER BY monetary DESC
LIMIT 20;


-- ------------------------------------------------------------
-- 4-2. RFM scores (1–5 per dimension, higher = better)
-- ------------------------------------------------------------
WITH rfm_raw AS (
    SELECT
        i.customer_id,
        DATEDIFF('2011-12-10', MAX(i.invoice_date)) AS recency,
        COUNT(DISTINCT i.invoice_no)                AS frequency,
        ROUND(SUM(ii.line_total), 2)                AS monetary
    FROM invoices      AS i
    JOIN invoice_items AS ii ON i.invoice_no = ii.invoice_no
    WHERE i.is_cancelled = 0
      AND ii.quantity    > 0
      AND ii.unit_price  > 0
      AND i.customer_id  IS NOT NULL
    GROUP BY i.customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,  -- lower days = better
        NTILE(5) OVER (ORDER BY frequency)    AS f_score,  -- higher = better
        NTILE(5) OVER (ORDER BY monetary)     AS m_score   -- higher = better
    FROM rfm_raw
)
SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score)            AS rfm_cell,
    ROUND((r_score + f_score + m_score) / 3, 2) AS rfm_avg
FROM rfm_scored
ORDER BY rfm_avg DESC;


-- ------------------------------------------------------------
-- 4-3. Customer segments based on RFM scores
-- ------------------------------------------------------------
WITH rfm_raw AS (
    SELECT
        i.customer_id,
        DATEDIFF('2011-12-10', MAX(i.invoice_date)) AS recency,
        COUNT(DISTINCT i.invoice_no)                AS frequency,
        ROUND(SUM(ii.line_total), 2)                AS monetary
    FROM invoices      AS i
    JOIN invoice_items AS ii ON i.invoice_no = ii.invoice_no
    WHERE i.is_cancelled = 0
      AND ii.quantity    > 0
      AND ii.unit_price  > 0
      AND i.customer_id  IS NOT NULL
    GROUP BY i.customer_id
),
rfm_scored AS (
    SELECT
        customer_id, recency, frequency, monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency)    AS f_score,
        NTILE(5) OVER (ORDER BY monetary)     AS m_score
    FROM rfm_raw
),
rfm_segmented AS (
    SELECT
        customer_id, recency, frequency, monetary,
        r_score, f_score, m_score,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3                   THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2                   THEN 'Recent Customers'
            WHEN r_score >= 3 AND f_score <= 2 AND m_score >= 3  THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4  THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 3                   THEN 'Cant Lose Them'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2  THEN 'Lost'
            ELSE 'Need Attention'
        END AS segment
    FROM rfm_scored
)
SELECT *
FROM rfm_segmented
ORDER BY monetary DESC;


-- ------------------------------------------------------------
-- 4-4. Segment summary (customer count & revenue per segment)
-- ------------------------------------------------------------
WITH rfm_raw AS (
    SELECT
        i.customer_id,
        DATEDIFF('2011-12-10', MAX(i.invoice_date)) AS recency,
        COUNT(DISTINCT i.invoice_no)                AS frequency,
        ROUND(SUM(ii.line_total), 2)                AS monetary
    FROM invoices      AS i
    JOIN invoice_items AS ii ON i.invoice_no = ii.invoice_no
    WHERE i.is_cancelled = 0
      AND ii.quantity    > 0
      AND ii.unit_price  > 0
      AND i.customer_id  IS NOT NULL
    GROUP BY i.customer_id
),
rfm_scored AS (
    SELECT
        customer_id, recency, frequency, monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency)    AS f_score,
        NTILE(5) OVER (ORDER BY monetary)     AS m_score
    FROM rfm_raw
),
rfm_segmented AS (
    SELECT
        customer_id, monetary,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3                   THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2                   THEN 'Recent Customers'
            WHEN r_score >= 3 AND f_score <= 2 AND m_score >= 3  THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4  THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 3                   THEN 'Cant Lose Them'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2  THEN 'Lost'
            ELSE 'Need Attention'
        END AS segment
    FROM rfm_scored
)
SELECT
    segment,
    COUNT(*)                                               AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)    AS customer_pct,
    ROUND(SUM(monetary), 2)                               AS total_revenue,
    ROUND(AVG(monetary), 2)                               AS avg_ltv
FROM rfm_segmented
GROUP BY segment
ORDER BY total_revenue DESC;
