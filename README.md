# E-Commerce SQL Portfolio Project

MySQL-based analysis of the UCI Online Retail II dataset, covering two years of UK wholesale transaction data (Dec 2009 to Dec 2011).

## Dataset

Source: [Online Retail II UCI (Kaggle)](https://www.kaggle.com/datasets/mashlyn/online-retail-ii-uci)

The raw CSV contains 1.06M rows across 8 columns (Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer ID, Country). Before loading, the data was normalized into a 5-table relational schema to support more structured querying.

## Schema

```
countries       country_id, name
customers       customer_id, country_id, first_seen_at
products        stock_code, description, is_product
invoices        invoice_no, customer_id, country_id, invoice_date, is_cancelled
invoice_items   item_id, invoice_no, stock_code, description, quantity, unit_price, line_total
```

A few design decisions worth noting. Customer ID in the raw data is stored as a float (e.g. 13085.0) and cast to INT on load. About 23% of invoices have no Customer ID, which means they are guest transactions — those rows are kept with `customer_id = NULL` rather than dropped. Invoices prefixed with "C" are cancellations and flagged via `is_cancelled`. Non-product stock codes like POST, DOT, and M are included in the products table but marked with `is_product = 0` so they can be filtered out of sales queries.

## Project Structure

```
ecommerce_sql_project/
├── schema.sql
├── load_data.py
├── data/
│   └── online_retail_II.csv
├── queries/
│   ├── 01_basic.sql
│   ├── 02_sales_analysis.sql
│   ├── 03_customer_analysis.sql
│   └── 04_rfm.sql
└── insights/
    └── summary.md
```

## Query Files

**01_basic.sql** covers foundational queries: row counts, date range, cancellation rate, guest vs registered breakdown, top countries, top products by quantity and revenue, monthly trends, and high-frequency customers.

**02_sales_analysis.sql** digs into revenue: total summary, monthly AOV, month-over-month growth, country breakdown, revenue by day of week and hour, cancellation rates by country, and year-over-year quarterly comparison.

**03_customer_analysis.sql** focuses on customer behavior: new customer acquisition by month, one-time vs repeat buyer segmentation, top 20 customers by LTV, average days between purchases, monthly cohort retention (M0 to M3), and the 80/20 revenue distribution check.

**04_rfm.sql** performs RFM segmentation using NTILE(5) scoring on recency, frequency, and monetary value. Outputs raw scores, combined RFM cell codes, and final segment labels with revenue breakdown per segment.

## Key Results

**Overall (Dec 2009 to Dec 2011)**

| Metric | Value |
|--------|-------|
| Valid invoices | 40,077 |
| Registered customers | 5,878 |
| Gross revenue | $41.9M |
| Cancellation rate | 15.5% |
| Guest transaction rate | 16.3% |

**Revenue by Country (Top 5)**

| Country | Revenue | Share |
|---------|---------|-------|
| United Kingdom | $35.7M | 85.2% |
| Ireland | $1.3M | 3.2% |
| Netherlands | $1.1M | 2.6% |
| Germany | $862K | 2.1% |
| France | $714K | 1.7% |

**Top 5 Products by Revenue**

| Product | Revenue |
|---------|---------|
| REGENCY CAKESTAND 3 TIER | $689,127 |
| WHITE HANGING HEART T-LIGHT HOLDER | $533,847 |
| PAPER CRAFT, LITTLE BIRDIE | $336,939 |
| JUMBO BAG RED RETROSPOT | $301,871 |
| PARTY BUNTING | $298,374 |

**Purchase Frequency Distribution**

| Orders per Customer | Customers | Share |
|---------------------|-----------|-------|
| 1 (one-time) | 1,626 | 27.7% |
| 2 to 5 | 2,454 | 41.7% |
| 6 to 10 | 925 | 15.7% |
| 11 or more | 876 | 14.9% |

**RFM Segments**

| Segment | Customers | Share | Total Revenue | Avg LTV |
|---------|-----------|-------|---------------|---------|
| Champions | 1,345 | 22.9% | $24.4M | $18,162 |
| Loyal Customers | 1,473 | 25.1% | $5.8M | $3,918 |
| At Risk | 203 | 3.5% | $1.9M | $9,558 |
| Cant Lose Them | 505 | 8.6% | $1.2M | $2,352 |
| Need Attention | 584 | 9.9% | $938K | $1,607 |
| Lost | 1,362 | 23.2% | $719K | $528 |
| Recent Customers | 287 | 4.9% | $228K | $795 |
| Potential Loyalists | 119 | 2.0% | $275K | $2,311 |

Champions represent 23% of customers but drive 58% of total revenue. The At Risk group is small (203 customers) but has the second-highest average LTV at $9,558, making them the most valuable reactivation target.

## Setup

Requires MySQL 8.0+ and Python 3.x with `pandas` and `mysql-connector-python`.

```bash
# 1. Create schema
mysql -u root -p < schema.sql

# 2. Load data
python load_data.py

# 3. Run any query file
mysql -u root -p ecommerce < queries/04_rfm.sql
```
