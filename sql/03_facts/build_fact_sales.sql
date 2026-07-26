-- ============================================================================
-- Fact build: fact_sales
-- Joins cleaned staging data to dimension tables to resolve surrogate keys
-- and compute derived measures. This is the classic "fact table load" step
-- in a star-schema ETL/ELT pipeline.
-- ============================================================================

CREATE OR REPLACE TABLE `your_project.sales_dw.fact_sales` AS
SELECT
  o.order_id,
  CAST(FORMAT_DATE('%Y%m%d', o.order_date) AS INT64)   AS date_key,
  o.customer_key,
  o.product_key,
  o.sales_rep_key,
  c.region_key,
  o.quantity,
  o.unit_price,
  ROUND(o.quantity * o.unit_price, 2)                   AS gross_amount,
  ROUND((o.quantity * o.unit_price) - o.net_amount, 2)  AS discount_amount,
  o.net_amount,
  ROUND(o.net_amount * 0.45, 2)                          AS cost_amount  -- placeholder COGS ratio
FROM `your_project.sales_dw.stg_orders_clean` AS o
INNER JOIN `your_project.sales_dw.dim_customer` AS c
  ON o.customer_key = c.customer_key
INNER JOIN `your_project.sales_dw.dim_product` AS p
  ON o.product_key = p.product_key
WHERE o.order_id IS NOT NULL           -- referential-integrity guard
  AND o.order_date IS NOT NULL;

-- Referential integrity check (governance control — run post-load)
SELECT 'orphaned_customer_key' AS issue, COUNT(*) AS row_count
FROM `your_project.sales_dw.fact_sales` f
LEFT JOIN `your_project.sales_dw.dim_customer` d USING (customer_key)
WHERE d.customer_key IS NULL
UNION ALL
SELECT 'orphaned_product_key', COUNT(*)
FROM `your_project.sales_dw.fact_sales` f
LEFT JOIN `your_project.sales_dw.dim_product` d USING (product_key)
WHERE d.product_key IS NULL;
