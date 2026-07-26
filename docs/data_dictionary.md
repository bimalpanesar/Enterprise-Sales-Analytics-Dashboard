# Data Dictionary

## fact_sales (grain: one row per order line)
| Column          | Type    | Description                                          |
|-----------------|---------|-------------------------------------------------------|
| order_id        | INT64   | Natural key of the order line                          |
| date_key        | INT64   | FK to dim_date (YYYYMMDD)                              |
| customer_key    | INT64   | FK to dim_customer                                     |
| product_key     | INT64   | FK to dim_product                                      |
| sales_rep_key   | INT64   | FK to dim_sales_rep                                    |
| region_key      | INT64   | FK to dim_region (denormalized from customer for speed)|
| quantity        | INT64   | Units sold                                             |
| unit_price      | NUMERIC | List price per unit at time of sale                    |
| gross_amount    | NUMERIC | quantity × unit_price, before discount                 |
| discount_amount | NUMERIC | Discount applied to the line                           |
| net_amount      | NUMERIC | gross_amount − discount_amount (the "revenue" figure)  |
| cost_amount     | NUMERIC | Estimated COGS for margin analysis                     |

## dim_date
| Column     | Description                                    |
|------------|-------------------------------------------------|
| date_key   | Surrogate key, YYYYMMDD integer                  |
| fiscal_year| Custom fiscal year starting April (FYyyyy)       |
| quarter    | Calendar quarter (Q1–Q4)                         |
| is_weekend | Boolean flag for weekend exclusion in DAX        |

## dim_customer
| Column        | Description                                 |
|---------------|-----------------------------------------------|
| customer_key  | Surrogate key                                 |
| segment       | Enterprise / Mid-Market / SMB                 |
| industry      | Customer's industry vertical                  |
| region_key    | FK to dim_region                              |
| signup_year   | Year the account was acquired                 |

## dim_product
| Column          | Description                              |
|-----------------|---------------------------------------------|
| product_key     | Surrogate key                                |
| category        | Top-level product line                       |
| subcategory     | Specific SKU grouping                        |
| unit_list_price | List price, pre-discount                     |

## dim_sales_rep
| Column        | Description                          |
|---------------|-----------------------------------------|
| sales_rep_key | Surrogate key                            |
| title         | Role/level of the rep                    |
| region_key    | Home region of the rep                   |

## dim_region
| Column             | Description                       |
|--------------------|------------------------------------|
| region_key         | Surrogate key                      |
| continent          | Top-level geography rollup         |
| country / state    | Drill-down geography levels        |

## Source-to-target mapping (staging)
`data/raw/orders_export_raw.csv` simulates a messy ERP export — inconsistent
column-name whitespace, string-typed numeric fields, possible duplicate
`OrderID`. `sql/01_staging/clean_orders.sql` documents exactly how each raw
column maps to its cleaned, typed equivalent before it's allowed into
`fact_sales`.
