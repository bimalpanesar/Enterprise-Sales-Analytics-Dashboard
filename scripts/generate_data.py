"""
Enterprise Sales BI Analytics Solution
Synthetic data generator — produces raw + star-schema CSVs that mimic
what you'd normally pull from a transactional ERP/CRM into BigQuery.

Run: python generate_data.py
Outputs land in ../data/raw and ../data/star_schema
"""
import csv
import os
import random
from datetime import date, timedelta

random.seed(42)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_DIR = os.path.join(BASE_DIR, "data", "raw")
STAR_DIR = os.path.join(BASE_DIR, "data", "star_schema")
os.makedirs(RAW_DIR, exist_ok=True)
os.makedirs(STAR_DIR, exist_ok=True)

# ----------------------------------------------------------------------
# 1. DIM_DATE  (3 full fiscal years so you can build YoY / QoQ DAX)
# ----------------------------------------------------------------------
start_date = date(2023, 1, 1)
end_date = date(2025, 12, 31)

dim_date_rows = []
d = start_date
date_key_map = {}
while d <= end_date:
    date_key = int(d.strftime("%Y%m%d"))
    quarter = (d.month - 1) // 3 + 1
    fiscal_year = d.year if d.month >= 4 else d.year - 1  # FY starts April
    dim_date_rows.append({
        "date_key": date_key,
        "full_date": d.isoformat(),
        "day_of_week": d.strftime("%A"),
        "day_num_in_week": d.isoweekday(),
        "day_num_in_month": d.day,
        "week_of_year": int(d.strftime("%V")),
        "month_num": d.month,
        "month_name": d.strftime("%B"),
        "quarter": f"Q{quarter}",
        "year": d.year,
        "fiscal_year": f"FY{fiscal_year}",
        "is_weekend": d.isoweekday() in (6, 7),
    })
    date_key_map[d] = date_key
    d += timedelta(days=1)

# ----------------------------------------------------------------------
# 2. DIM_REGION
# ----------------------------------------------------------------------
regions = [
    (1, "North America", "United States", "West"),
    (2, "North America", "United States", "East"),
    (3, "North America", "Canada", "Ontario"),
    (4, "Europe", "United Kingdom", "London"),
    (5, "Europe", "Germany", "Bavaria"),
    (6, "Europe", "France", "Île-de-France"),
    (7, "Asia Pacific", "India", "Maharashtra"),
    (8, "Asia Pacific", "India", "Delhi NCR"),
    (9, "Asia Pacific", "Australia", "New South Wales"),
    (10, "Middle East", "UAE", "Dubai"),
]
dim_region_rows = [
    {"region_key": r[0], "continent": r[1], "country": r[2], "state_or_province": r[3]}
    for r in regions
]

# ----------------------------------------------------------------------
# 3. DIM_SALES_REP
# ----------------------------------------------------------------------
first_names = ["Aisha", "Marcus", "Priya", "Liam", "Sofia", "Kenji", "Fatima", "Noah",
               "Elena", "Diego", "Mei", "Owen", "Zara", "Lucas", "Hana", "Ravi"]
last_names = ["Khan", "Rossi", "Nakamura", "Schmidt", "Okafor", "Dubois", "Silva",
              "Kowalski", "Patel", "Larsen", "Fischer", "Costa"]
titles = ["Account Executive", "Senior Account Executive", "Regional Sales Manager", "Sales Director"]

dim_rep_rows = []
for i in range(1, 26):
    dim_rep_rows.append({
        "sales_rep_key": i,
        "rep_name": f"{random.choice(first_names)} {random.choice(last_names)}",
        "title": random.choices(titles, weights=[50, 30, 15, 5])[0],
        "region_key": random.choice(regions)[0],
        "hire_year": random.randint(2018, 2024),
    })

# ----------------------------------------------------------------------
# 4. DIM_CUSTOMER
# ----------------------------------------------------------------------
industries = ["Manufacturing", "Retail", "Healthcare", "Financial Services", "Technology",
              "Education", "Logistics", "Energy", "Public Sector", "Hospitality"]
segments = ["Enterprise", "Mid-Market", "SMB"]
company_words = ["Global", "Prime", "Summit", "Nova", "Vertex", "Orbit", "Atlas", "Pioneer",
                  "Meridian", "Crest", "Sterling", "Horizon", "Apex", "Cobalt", "Anchor"]
company_suffix = ["Corp", "Industries", "Group", "Holdings", "Systems", "Solutions", "Partners"]

dim_customer_rows = []
for i in range(1, 301):
    region = random.choice(regions)
    dim_customer_rows.append({
        "customer_key": i,
        "customer_name": f"{random.choice(company_words)} {random.choice(company_suffix)}",
        "industry": random.choice(industries),
        "segment": random.choices(segments, weights=[20, 35, 45])[0],
        "region_key": region[0],
        "signup_year": random.randint(2019, 2025),
    })

# ----------------------------------------------------------------------
# 5. DIM_PRODUCT
# ----------------------------------------------------------------------
categories = {
    "Cloud Platform": ["Core Subscription", "Enterprise Add-on", "Data Connector Pack"],
    "Analytics Suite": ["Standard Analytics", "Advanced Analytics", "AI Insights Module"],
    "Security": ["Identity Management", "Threat Monitoring", "Compliance Toolkit"],
    "Professional Services": ["Implementation Package", "Training Package", "Managed Support"],
}
dim_product_rows = []
pk = 1
for cat, subs in categories.items():
    for sub in subs:
        dim_product_rows.append({
            "product_key": pk,
            "product_name": f"{cat} - {sub}",
            "category": cat,
            "subcategory": sub,
            "unit_list_price": round(random.uniform(500, 15000), 2),
        })
        pk += 1

# ----------------------------------------------------------------------
# 6. FACT_SALES  (~12,000 transaction rows)
# ----------------------------------------------------------------------
all_dates = list(date_key_map.keys())
fact_rows = []
order_id = 100000
for _ in range(12000):
    order_id += 1
    d = random.choice(all_dates)
    cust = random.choice(dim_customer_rows)
    prod = random.choice(dim_product_rows)
    rep = random.choice(dim_rep_rows)
    qty = random.randint(1, 20)
    unit_price = prod["unit_list_price"]
    discount_pct = random.choices([0, 0.05, 0.10, 0.15, 0.20], weights=[40, 25, 20, 10, 5])[0]
    gross_amount = round(qty * unit_price, 2)
    discount_amount = round(gross_amount * discount_pct, 2)
    net_amount = round(gross_amount - discount_amount, 2)
    cost_pct = random.uniform(0.35, 0.55)  # COGS as % of net for margin analysis
    cost_amount = round(net_amount * cost_pct, 2)

    fact_rows.append({
        "order_id": order_id,
        "date_key": date_key_map[d],
        "customer_key": cust["customer_key"],
        "product_key": prod["product_key"],
        "sales_rep_key": rep["sales_rep_key"],
        "region_key": cust["region_key"],
        "quantity": qty,
        "unit_price": unit_price,
        "gross_amount": gross_amount,
        "discount_amount": discount_amount,
        "net_amount": net_amount,
        "cost_amount": cost_amount,
    })


def write_csv(path, rows):
    if not rows:
        return
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {len(rows):>6} rows -> {path}")


# Star schema (clean, load-ready) tables
write_csv(os.path.join(STAR_DIR, "dim_date.csv"), dim_date_rows)
write_csv(os.path.join(STAR_DIR, "dim_region.csv"), dim_region_rows)
write_csv(os.path.join(STAR_DIR, "dim_sales_rep.csv"), dim_rep_rows)
write_csv(os.path.join(STAR_DIR, "dim_customer.csv"), dim_customer_rows)
write_csv(os.path.join(STAR_DIR, "dim_product.csv"), dim_product_rows)
write_csv(os.path.join(STAR_DIR, "fact_sales.csv"), fact_rows)

# Also drop a "raw" messy version of orders to simulate a source export
# (this is what your staging SQL will clean up — realistic for a portfolio piece)
raw_rows = []
for r in fact_rows[:3000]:
    raw_rows.append({
        "OrderID ": r["order_id"],
        " order_date": next(dt for dt, k in date_key_map.items() if k == r["date_key"]).isoformat(),
        "Customer_Key": r["customer_key"],
        "Product_Key ": r["product_key"],
        "Rep": r["sales_rep_key"],
        "qty": r["quantity"],
        "unit_price ": r["unit_price"],
        "net_amount": r["net_amount"],
    })
write_csv(os.path.join(RAW_DIR, "orders_export_raw.csv"), raw_rows)

print("\nDone. Star schema tables are in data/star_schema/, raw export sample in data/raw/.")
