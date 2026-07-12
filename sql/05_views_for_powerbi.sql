-- ============================================================
-- Script  : 05_views_for_powerbi.sql
-- Purpose : Create views optimized for Power BI dashboard consumption
-- Author  : [Your Name]
-- Project : Customer Churn Analysis
-- ============================================================

USE customer_churn_db;

-- View 1: Summary metrics for KPI cards
CREATE OR REPLACE VIEW vw_churn_summary AS
SELECT
    COUNT(*)                                                        AS total_customers,
    SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END)   AS total_churned,
    SUM(CASE WHEN Customer_Status = 'Stayed'  THEN 1 ELSE 0 END)   AS total_stayed,
    SUM(CASE WHEN Customer_Status = 'Joined'  THEN 1 ELSE 0 END)   AS total_joined,
    ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0
          / NULLIF(SUM(CASE WHEN Customer_Status != 'Joined' THEN 1 ELSE 0 END), 0), 2) AS churn_rate_pct,
    ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN Total_Revenue ELSE 0 END), 2) AS revenue_lost
FROM customer_clean;

-- View 2: Customer-level data for drill-through in Power BI
CREATE OR REPLACE VIEW vw_customer_detail AS
SELECT
    Customer_ID, Gender, Age, Married, State,
    Tenure_in_Months, Contract, Internet_Type, Monthly_Charge,
    Total_Revenue, Customer_Status, Churn_Category, Churn_Reason, Churn_Flag
FROM customer_clean;

-- View 3: Churn by category and reason (for treemap / bar charts)
CREATE OR REPLACE VIEW vw_churn_reasons AS
SELECT
    Churn_Category,
    Churn_Reason,
    COUNT(*) AS count,
    ROUND(SUM(Total_Revenue), 2) AS revenue_at_risk
FROM customer_clean
WHERE Customer_Status = 'Churned'
GROUP BY Churn_Category, Churn_Reason
ORDER BY count DESC;
