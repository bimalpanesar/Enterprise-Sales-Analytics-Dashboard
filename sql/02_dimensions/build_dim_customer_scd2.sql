-- ============================================================================
-- Dimension build: dim_customer with Slowly Changing Dimension (Type 2)
-- Demonstrates dimensional-modelling technique for tracking history when a
-- customer's segment or region changes over time (e.g. SMB -> Mid-Market
-- after a renewal). This is the pattern a hiring manager will look for
-- beyond a flat dimension table.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `your_project.sales_dw.dim_customer_scd2` (
  customer_sk     INT64,      -- surrogate key, one row per version
  customer_key    INT64,      -- natural/business key, stable across versions
  customer_name   STRING,
  industry        STRING,
  segment         STRING,
  region_key      INT64,
  valid_from      DATE,
  valid_to        DATE,
  is_current      BOOL
);

-- Incoming batch of customer attribute changes (in practice this would be
-- the latest extract from the CRM landed in a staging table)
CREATE OR REPLACE TEMP TABLE incoming_customers AS
SELECT customer_key, customer_name, industry, segment, region_key
FROM `your_project.sales_dw.dim_customer`;

-- Step 1: close out changed records
UPDATE `your_project.sales_dw.dim_customer_scd2` AS tgt
SET valid_to = CURRENT_DATE(), is_current = FALSE
FROM incoming_customers AS src
WHERE tgt.customer_key = src.customer_key
  AND tgt.is_current = TRUE
  AND (tgt.segment != src.segment OR tgt.region_key != src.region_key);

-- Step 2: insert new versions for changed records + brand-new customers
INSERT INTO `your_project.sales_dw.dim_customer_scd2`
SELECT
  (SELECT IFNULL(MAX(customer_sk), 0) FROM `your_project.sales_dw.dim_customer_scd2`)
    + ROW_NUMBER() OVER () AS customer_sk,
  src.customer_key,
  src.customer_name,
  src.industry,
  src.segment,
  src.region_key,
  CURRENT_DATE()  AS valid_from,
  DATE('9999-12-31') AS valid_to,
  TRUE AS is_current
FROM incoming_customers AS src
LEFT JOIN `your_project.sales_dw.dim_customer_scd2` AS tgt
  ON tgt.customer_key = src.customer_key AND tgt.is_current = TRUE
WHERE tgt.customer_key IS NULL;
