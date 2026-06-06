-- ============================================================
-- E-Commerce Database Schema (MySQL)
-- Source: UCI Online Retail II Dataset (2009-12 ~ 2011-12)
-- ============================================================

CREATE DATABASE IF NOT EXISTS ecommerce;
USE ecommerce;

-- Drop tables in reverse dependency order for clean re-runs
DROP TABLE IF EXISTS invoice_items;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS countries;

-- ------------------------------------------------------------
-- 1. COUNTRIES  (normalizes 43 distinct country names)
-- ------------------------------------------------------------
CREATE TABLE countries (
    country_id   SMALLINT       UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100)   NOT NULL UNIQUE
);

-- ------------------------------------------------------------
-- 2. CUSTOMERS
--    Source Customer ID is float (e.g. 13085.0) -- cast to INT on load
--    Guest transactions are stored with customer_id = NULL in invoices
-- ------------------------------------------------------------
CREATE TABLE customers (
    customer_id   INT            UNSIGNED PRIMARY KEY,  -- integer-cast of source Customer ID
    country_id    SMALLINT       UNSIGNED,
    first_seen_at DATETIME       NOT NULL,
    CONSTRAINT fk_cust_country FOREIGN KEY (country_id)
        REFERENCES countries (country_id)
);

-- ------------------------------------------------------------
-- 3. PRODUCTS
--    Keyed by StockCode; includes non-product codes (POST, DOT, M, etc.)
-- ------------------------------------------------------------
CREATE TABLE products (
    stock_code   VARCHAR(20)    NOT NULL PRIMARY KEY,
    description  VARCHAR(500),
    is_product   TINYINT(1)     NOT NULL DEFAULT 1  -- 0: service charge / postage / fee
);

-- ------------------------------------------------------------
-- 4. INVOICES  (order header)
--    Invoices prefixed with 'C' are cancellations
-- ------------------------------------------------------------
CREATE TABLE invoices (
    invoice_no   VARCHAR(20)    NOT NULL PRIMARY KEY,
    customer_id  INT            UNSIGNED,              -- NULL for guest transactions
    country_id   SMALLINT       UNSIGNED NOT NULL,
    invoice_date DATETIME       NOT NULL,
    is_cancelled TINYINT(1)     NOT NULL DEFAULT 0,    -- 1 when invoice_no starts with 'C'
    CONSTRAINT fk_inv_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id),
    CONSTRAINT fk_inv_country FOREIGN KEY (country_id)
        REFERENCES countries (country_id)
);

-- ------------------------------------------------------------
-- 5. INVOICE_ITEMS  (order line items)
--    Negative quantity = return; zero price = free / sample
--    description is a point-in-time snapshot (may differ from products.description)
-- ------------------------------------------------------------
CREATE TABLE invoice_items (
    item_id      INT            UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    invoice_no   VARCHAR(20)    NOT NULL,
    stock_code   VARCHAR(20)    NOT NULL,
    description  VARCHAR(500),                         -- snapshot at purchase time
    quantity     INT            NOT NULL,              -- negative for returns
    unit_price   DECIMAL(10,2)  NOT NULL,              -- negative for price adjustments
    line_total   DECIMAL(10,2)  NOT NULL,              -- quantity * unit_price
    CONSTRAINT fk_item_invoice FOREIGN KEY (invoice_no)
        REFERENCES invoices (invoice_no),
    CONSTRAINT fk_item_product FOREIGN KEY (stock_code)
        REFERENCES products (stock_code)
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_invoices_customer  ON invoices (customer_id);
CREATE INDEX idx_invoices_date      ON invoices (invoice_date);
CREATE INDEX idx_invoices_country   ON invoices (country_id);
CREATE INDEX idx_invoices_cancelled ON invoices (is_cancelled);
CREATE INDEX idx_items_invoice      ON invoice_items (invoice_no);
CREATE INDEX idx_items_stock        ON invoice_items (stock_code);
CREATE INDEX idx_customers_country  ON customers (country_id);
