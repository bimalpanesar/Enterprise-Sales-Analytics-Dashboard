# Star Schema — Entity Relationship Diagram

GitHub renders Mermaid diagrams natively in markdown, so this shows up as a
diagram directly on the repo page — no image export needed.

```mermaid
erDiagram
    FACT_SALES }o--|| DIM_DATE : date_key
    FACT_SALES }o--|| DIM_CUSTOMER : customer_key
    FACT_SALES }o--|| DIM_PRODUCT : product_key
    FACT_SALES }o--|| DIM_SALES_REP : sales_rep_key
    FACT_SALES }o--|| DIM_REGION : region_key
    DIM_CUSTOMER }o--|| DIM_REGION : region_key
    DIM_SALES_REP }o--|| DIM_REGION : region_key

    FACT_SALES {
        int order_id PK
        int date_key FK
        int customer_key FK
        int product_key FK
        int sales_rep_key FK
        int region_key FK
        int quantity
        numeric unit_price
        numeric gross_amount
        numeric discount_amount
        numeric net_amount
        numeric cost_amount
    }
    DIM_DATE {
        int date_key PK
        date full_date
        string month_name
        string quarter
        string fiscal_year
        bool is_weekend
    }
    DIM_CUSTOMER {
        int customer_key PK
        string customer_name
        string industry
        string segment
        int region_key FK
    }
    DIM_PRODUCT {
        int product_key PK
        string product_name
        string category
        string subcategory
        numeric unit_list_price
    }
    DIM_SALES_REP {
        int sales_rep_key PK
        string rep_name
        string title
        int region_key FK
    }
    DIM_REGION {
        int region_key PK
        string continent
        string country
        string state_or_province
    }
```

## Why a star schema (not a normalized OLTP model)

- **One join hop** from fact to any dimension → fast, predictable Power BI
  query plans and simple DAX (no bidirectional filtering hacks).
- **Conformed dimensions** (`dim_region` shared by both customer and rep)
  let you slice revenue-by-region and rep-performance-by-region with the
  same filter context.
- **Grain is explicit**: one row in `fact_sales` = one order line. Every
  measure in the DAX library is built assuming that grain — documented so
  nobody double-counts by accident.
