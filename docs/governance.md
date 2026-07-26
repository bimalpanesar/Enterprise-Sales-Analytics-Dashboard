# Data Governance

A BI solution isn't just a schema and a report — it needs documented rules
for who can see what, how quality is enforced, and how the model evolves.
This is what an interviewer means by "governance concepts."

## 1. Access control model
| Role                | Access level                                              |
|----------------------|-----------------------------------------------------------|
| Data Engineer         | Full read/write on staging + warehouse datasets in BigQuery|
| BI Developer          | Read-only on `sales_dw`, write access to Power BI workspace|
| Regional Sales Manager| Power BI report access filtered to their own region only  |
| Sales Rep             | Power BI report access filtered to their own records only |
| Executive             | Full read access, all regions, no row-level restriction    |

Implemented via:
- **BigQuery**: IAM roles at the dataset level (`roles/bigquery.dataViewer`
  for BI Developer; no direct warehouse access for reps/managers — they only
  ever see Power BI).
- **Power BI**: **Row-Level Security (RLS)** roles defined on `dim_region`
  and `dim_sales_rep`, e.g.:
  ```
  [region_key] = LOOKUPVALUE(dim_sales_rep[region_key], dim_sales_rep[rep_name], USERPRINCIPALNAME())
  ```

## 2. Data quality rules (enforced in SQL, not just eyeballed)
- Every staging load runs the row-count / null-count check in
  `sql/01_staging/clean_orders.sql`.
- Every fact load runs the referential-integrity check in
  `sql/03_facts/build_fact_sales.sql` — orphaned foreign keys are a hard
  fail, not a warning, in a production pipeline.
- Fact table grain is documented once (`data_dictionary.md`) and never
  silently changed — a grain change without updating every DAX measure is
  the #1 cause of silently-wrong dashboards.

## 3. Naming conventions
- `dim_*` / `fact_*` prefixes make table purpose unambiguous at a glance.
- `_key` suffix = surrogate/natural key used for joins.
- Measures live in a single dedicated `_Measures` table in the Power BI
  model, not scattered across fact/dimension tables.

## 4. Change management
- Schema changes go through `bigquery/schema_ddl.sql` — never edited ad hoc
  in the console. This file is the single source of truth for structure.
- SCD Type 2 (`sql/02_dimensions/build_dim_customer_scd2.sql`) preserves
  historical accuracy: if a customer moves from SMB to Mid-Market, past
  reporting periods still reflect what was true *then*, not today.

## 5. Data classification
| Data element      | Classification | Note                                   |
|--------------------|----------------|------------------------------------------|
| customer_name       | Internal        | Synthetic in this portfolio dataset       |
| net_amount / cost   | Confidential    | Would be masked for non-Finance roles in a real deployment |
| rep_name            | Internal        | Visible to managers, restricted for reps outside their own record via RLS |

> Note: all data in this repository is synthetically generated
> (`scripts/generate_data.py`, seeded RNG) — no real customer, employee, or
> transaction data is included anywhere in this project.
