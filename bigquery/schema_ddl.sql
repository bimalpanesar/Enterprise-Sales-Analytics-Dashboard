-- ============================================================================
-- Enterprise Sales BI Analytics Solution
-- BigQuery DDL — dataset + star schema table definitions
-- ============================================================================
-- Run these in order in the BigQuery console or via `bq query` / `bq load`.
-- Replace `your_project.sales_dw` with your actual project.dataset.

CREATE SCHEMA IF NOT EXISTS `your_project.sales_dw`
OPTIONS (
  description = "Enterprise Sales data warehouse — star schema for Power BI reporting",
  location = "US"
);

-- Staging layer: raw load target, 1:1 with source CSV, all STRING to avoid
-- load failures on dirty data. This is intentionally "dumb" — cleansing
-- happens in the staging SQL scripts (sql/01_staging).
CREATE OR REPLACE TABLE `your_project.sales_dw.stg_orders_raw` (
  order_id        STRING,
  order_date      STRING,
  customer_key    STRING,
  product_key     STRING,
  sales_rep_key   STRING,
  quantity        STRING,
  unit_price      STRING,
  net_amount      STRING
);

-- ---------------------------------------------------------------------------
-- Dimension tables
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE `your_project.sales_dw.dim_date` (
  date_key         INT64 NOT NULL,
  full_date        DATE  NOT NULL,
  day_of_week      STRING,
  day_num_in_week  INT64,
  day_num_in_month INT64,
  week_of_year     INT64,
  month_num        INT64,
  month_name       STRING,
  quarter          STRING,
  year             INT64,
  fiscal_year      STRING,
  is_weekend       BOOL
)
CLUSTER BY date_key;

CREATE OR REPLACE TABLE `your_project.sales_dw.dim_region` (
  region_key        INT64 NOT NULL,
  continent         STRING,
  country           STRING,
  state_or_province  STRING
);

CREATE OR REPLACE TABLE `your_project.sales_dw.dim_sales_rep` (
  sales_rep_key INT64 NOT NULL,
  rep_name      STRING,
  title         STRING,
  region_key    INT64,
  hire_year     INT64
);

CREATE OR REPLACE TABLE `your_project.sales_dw.dim_customer` (
  customer_key   INT64 NOT NULL,
  customer_name  STRING,
  industry       STRING,
  segment        STRING,
  region_key     INT64,
  signup_year    INT64
);

CREATE OR REPLACE TABLE `your_project.sales_dw.dim_product` (
  product_key      INT64 NOT NULL,
  product_name     STRING,
  category         STRING,
  subcategory      STRING,
  unit_list_price  NUMERIC
);

-- ---------------------------------------------------------------------------
-- Fact table — grain: one row per order line
-- Partitioned by date and clustered by the dimensions most filtered in
-- Power BI (customer, product) to control BigQuery scan cost.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE `your_project.sales_dw.fact_sales` (
  order_id         INT64 NOT NULL,
  date_key         INT64 NOT NULL,
  customer_key     INT64 NOT NULL,
  product_key      INT64 NOT NULL,
  sales_rep_key    INT64 NOT NULL,
  region_key       INT64 NOT NULL,
  quantity         INT64,
  unit_price       NUMERIC,
  gross_amount     NUMERIC,
  discount_amount  NUMERIC,
  net_amount       NUMERIC,
  cost_amount      NUMERIC
)
PARTITION BY RANGE_BUCKET(date_key, GENERATE_ARRAY(20230101, 20260101, 1))
CLUSTER BY customer_key, product_key;

-- ---------------------------------------------------------------------------
-- Loading data (after `bq load`-ing the CSVs from data/star_schema/ into
-- temp tables, or uploading directly via the console "Create Table from
-- upload" wizard):
--   bq load --source_format=CSV --skip_leading_rows=1 \
--     your_project:sales_dw.dim_date data/star_schema/dim_date.csv
--   (repeat for each dim_*.csv and fact_sales.csv)
-- ---------------------------------------------------------------------------
