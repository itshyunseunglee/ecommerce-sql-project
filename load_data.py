import pandas as pd
import mysql.connector
from math import isnan

CSV_PATH = "data/online_retail_II.csv"
DB = dict(host="127.0.0.1", port=3306, user="root", password="", database="ecommerce")

NON_PRODUCT_CODES = {"POST", "DOT", "M", "m", "C2", "C3", "D", "S", "B", "PADS", "CRUK", "GIFT"}

def batch_insert(cursor, sql, rows, batch=5000):
    for i in range(0, len(rows), batch):
        cursor.executemany(sql, rows[i:i+batch])
        print(f"  {min(i+batch, len(rows)):,} / {len(rows):,}", end="\r")
    print()

def main():
    print("Loading CSV...")
    df = pd.read_csv(CSV_PATH, dtype=str)
    df.columns = ["invoice_no","stock_code","description","quantity","invoice_date","unit_price","customer_id","country"]

    df["quantity"]   = pd.to_numeric(df["quantity"],   errors="coerce")
    df["unit_price"] = pd.to_numeric(df["unit_price"], errors="coerce")
    df["invoice_date"] = pd.to_datetime(df["invoice_date"], errors="coerce")
    df = df.dropna(subset=["quantity","unit_price","invoice_date"])
    df["line_total"] = df["quantity"] * df["unit_price"]
    df["is_cancelled"] = df["invoice_no"].str.startswith("C").astype(int)

    # customer_id: float string "13085.0" → int, NaN → None
    def parse_cid(v):
        try:
            f = float(v)
            return None if isnan(f) else int(f)
        except:
            return None
    df["cid"] = df["customer_id"].apply(parse_cid)

    print("Connecting to MySQL...")
    conn = mysql.connector.connect(**DB)
    cur  = conn.cursor()
    cur.execute("SET FOREIGN_KEY_CHECKS=0")

    # 1. COUNTRIES
    print("Inserting countries...")
    countries = sorted(df["country"].dropna().unique())
    cur.executemany(
        "INSERT IGNORE INTO countries (name) VALUES (%s)",
        [(c,) for c in countries]
    )
    cur.execute("SELECT country_id, name FROM countries")
    country_map = {name: cid for cid, name in cur.fetchall()}

    # 2. CUSTOMERS
    print("Inserting customers...")
    cust_df = df.dropna(subset=["cid"]).copy()
    cust_df["cid"] = cust_df["cid"].astype(int)
    cust_group = cust_df.groupby("cid").agg(
        country=("country", lambda x: x.mode()[0]),
        first_seen=("invoice_date", "min")
    ).reset_index()
    cust_rows = [
        (int(r.cid), country_map.get(r.country), r.first_seen.strftime("%Y-%m-%d %H:%M:%S"))
        for r in cust_group.itertuples()
    ]
    batch_insert(cur,
        "INSERT IGNORE INTO customers (customer_id, country_id, first_seen_at) VALUES (%s,%s,%s)",
        cust_rows)

    # 3. PRODUCTS
    print("Inserting products...")
    prod_df = df.groupby("stock_code")["description"].agg(
        lambda x: x.dropna().mode()[0] if x.dropna().any() else None
    ).reset_index()
    prod_rows = [
        (r.stock_code, r.description if pd.notna(r.description) else None, 0 if r.stock_code in NON_PRODUCT_CODES else 1)
        for r in prod_df.itertuples()
    ]
    batch_insert(cur,
        "INSERT IGNORE INTO products (stock_code, description, is_product) VALUES (%s,%s,%s)",
        prod_rows)

    # 4. INVOICES
    print("Inserting invoices...")
    inv_df = df.groupby("invoice_no").agg(
        cid=("cid", "first"),
        country=("country", "first"),
        invoice_date=("invoice_date", "min"),
        is_cancelled=("is_cancelled", "first")
    ).reset_index()
    inv_rows = [
        (
            r.invoice_no,
            int(r.cid) if r.cid and not (isinstance(r.cid, float) and isnan(r.cid)) else None,
            country_map.get(r.country),
            r.invoice_date.strftime("%Y-%m-%d %H:%M:%S"),
            int(r.is_cancelled)
        )
        for r in inv_df.itertuples()
    ]
    batch_insert(cur,
        "INSERT IGNORE INTO invoices (invoice_no, customer_id, country_id, invoice_date, is_cancelled) VALUES (%s,%s,%s,%s,%s)",
        inv_rows)

    # 5. INVOICE_ITEMS
    print("Inserting invoice_items...")
    item_rows = [
        (
            r.invoice_no,
            r.stock_code,
            r.description if pd.notna(r.description) else None,
            int(r.quantity),
            float(r.unit_price),
            float(r.line_total)
        )
        for r in df.itertuples()
    ]
    batch_insert(cur,
        "INSERT INTO invoice_items (invoice_no, stock_code, description, quantity, unit_price, line_total) VALUES (%s,%s,%s,%s,%s,%s)",
        item_rows)

    cur.execute("SET FOREIGN_KEY_CHECKS=1")
    conn.commit()
    cur.close()
    conn.close()

    print("\nDone!")
    print(f"  countries   : {len(countries):,}")
    print(f"  customers   : {len(cust_rows):,}")
    print(f"  products    : {len(prod_rows):,}")
    print(f"  invoices    : {len(inv_rows):,}")
    print(f"  items       : {len(item_rows):,}")

if __name__ == "__main__":
    main()
