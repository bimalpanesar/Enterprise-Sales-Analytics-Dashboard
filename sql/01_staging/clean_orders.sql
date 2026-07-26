-- ============================================================================
-- Staging: clean the raw orders export before it enters the warehouse
-- Demonstrates: trimming column-name whitespace artifacts, type casting,
-- null handling, de-duplication — the kind of cleanup a real BigQuery
-- ELT pipeline has to do before data is trustworthy enough for dimensions.
-- ============================================================================

CREATE OR REPLACE TABLE `your_project.sales_dw.stg_orders_clean` AS
SELECT
  SAFE_CAST(TRIM(order_id) AS INT64)                         AS order_id,
  SAFE.PARSE_DATE('%Y-%m-%d', TRIM(order_date))              AS order_date,
  SAFE_CAST(TRIM(customer_key) AS INT64)                     AS customer_key,
  SAFE_CAST(TRIM(product_key) AS INT64)                      AS product_key,
  SAFE_CAST(TRIM(sales_rep_key) AS INT64)                    AS sales_rep_key,
  SAFE_CAST(TRIM(quantity) AS INT64)                         AS quantity,
  SAFE_CAST(TRIM(unit_price) AS NUMERIC)                     AS unit_price,
  SAFE_CAST(TRIM(net_amount) AS NUMERIC)                     AS net_amount
FROM `your_project.sales_dw.stg_orders_raw`
QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(order_id) ORDER BY order_date) = 1
-- drop rows that failed to cast a primary key — logged, not silently dropped
-- in a production pipeline these would route to a quarantine table
;

-- Data-quality check to run after every staging load (governance control)
SELECT
  COUNT(*)                                            AS total_rows,
  COUNTIF(order_id IS NULL)                           AS missing_order_id,
  COUNTIF(customer_key IS NULL)                       AS missing_customer_key,
  COUNTIF(net_amount IS NULL OR net_amount < 0)       AS invalid_net_amount
FROM `your_project.sales_dw.stg_orders_clean`;
