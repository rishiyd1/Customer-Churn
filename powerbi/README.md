# Power BI Dashboard

This folder contains the Power BI report file for the Customer Churn Analysis project.

## File
- `Customer_Churn_Dashboard.pbix` — Main Power BI dashboard (add after building)

## Dashboard Pages (Planned)
1. **Executive Summary** — KPI cards: total customers, churn rate, revenue lost
2. **Churn Overview** — Charts by contract type, tenure, internet type
3. **Geographic Analysis** — State-wise churn heatmap across India
4. **Root Cause Analysis** — Churn category & reason breakdown (treemap + bar)
5. **Customer Segments** — High-value at-risk customers (scatter, table)
6. **Churn Playbook** — Actionable retention recommendations

## Data Source
Connects to the cleaned SQL view `vw_customer_detail` and aggregated views from `sql/05_views_for_powerbi.sql`.
