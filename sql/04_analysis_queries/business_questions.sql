-- ============================================================================
-- Analysis queries — the kind of business questions this warehouse answers.
-- Useful both as a sanity check on the model and as Power BI "reasonableness"
-- benchmarks to compare your DAX measures against.
-- ============================================================================

-- 1. Revenue and margin by region, current fiscal year
SELECT
  r.continent,
  r.country,
  ROUND(SUM(f.net_amount), 2)                                    AS net_revenue,
  ROUND(SUM(f.net_amount - f.cost_amount), 2)                    AS gross_margin,
  ROUND(SAFE_DIVIDE(SUM(f.net_amount - f.cost_amount), SUM(f.net_amount)) * 100, 1) AS margin_pct
FROM `your_project.sales_dw.fact_sales` f
JOIN `your_project.sales_dw.dim_region` r  ON f.region_key = r.region_key
JOIN `your_project.sales_dw.dim_date` d    ON f.date_key   = d.date_key
WHERE d.fiscal_year = 'FY2025'
GROUP BY r.continent, r.country
ORDER BY net_revenue DESC;

-- 2. Top 10 sales reps by net revenue, with rank
SELECT
  s.rep_name,
  s.title,
  ROUND(SUM(f.net_amount), 2) AS net_revenue,
  RANK() OVER (ORDER BY SUM(f.net_amount) DESC) AS revenue_rank
FROM `your_project.sales_dw.fact_sales` f
JOIN `your_project.sales_dw.dim_sales_rep` s ON f.sales_rep_key = s.sales_rep_key
GROUP BY s.rep_name, s.title
ORDER BY net_revenue DESC
LIMIT 10;

-- 3. Month-over-month revenue trend with running total (window function)
SELECT
  d.year,
  d.month_num,
  d.month_name,
  ROUND(SUM(f.net_amount), 2) AS monthly_revenue,
  ROUND(SUM(SUM(f.net_amount)) OVER (ORDER BY d.year, d.month_num), 2) AS running_total
FROM `your_project.sales_dw.fact_sales` f
JOIN `your_project.sales_dw.dim_date` d ON f.date_key = d.date_key
GROUP BY d.year, d.month_num, d.month_name
ORDER BY d.year, d.month_num;

-- 4. Customer segment performance with product category cross-tab
SELECT
  c.segment,
  p.category,
  COUNT(DISTINCT f.order_id)  AS order_count,
  ROUND(SUM(f.net_amount), 2) AS net_revenue,
  ROUND(AVG(f.net_amount), 2) AS avg_order_value
FROM `your_project.sales_dw.fact_sales` f
JOIN `your_project.sales_dw.dim_customer` c ON f.customer_key = c.customer_key
JOIN `your_project.sales_dw.dim_product` p  ON f.product_key = p.product_key
GROUP BY c.segment, p.category
ORDER BY c.segment, net_revenue DESC;

-- 5. Discount leakage — orders with above-average discount, by rep
WITH avg_discount AS (
  SELECT AVG(SAFE_DIVIDE(discount_amount, gross_amount)) AS overall_avg_disc_pct
  FROM `your_project.sales_dw.fact_sales`
  WHERE gross_amount > 0
)
SELECT
  s.rep_name,
  COUNT(*) AS above_avg_discount_orders,
  ROUND(SUM(f.discount_amount), 2) AS total_discount_given
FROM `your_project.sales_dw.fact_sales` f
JOIN `your_project.sales_dw.dim_sales_rep` s ON f.sales_rep_key = s.sales_rep_key
CROSS JOIN avg_discount
WHERE SAFE_DIVIDE(f.discount_amount, f.gross_amount) > avg_discount.overall_avg_disc_pct
GROUP BY s.rep_name
ORDER BY total_discount_given DESC;
