-- ============================================================
--  Script   : 05_views_for_powerbi.sql
--  Purpose  : Production-ready views for Power BI data model
--  Source   : customer_churn_clean
--  Database : MySQL 8.0+
--  Author   : [Your Name]
--  Project  : Customer Churn Analysis  (SQL + Python + Power BI)
--  Version  : 2.0
--
--  Views Created:
--    vw_executive_summary      → Page 1 KPI cards
--    vw_customer_detail        → Row-level drill-through
--    vw_churn_by_dimension     → Churn rate across all dimensions
--    vw_revenue_analysis       → Revenue & financial breakdown
--    vw_churn_reasons          → Root cause treemap & bar charts
--    vw_segment_risk           → Segment risk scorecard
--    vw_addon_stickiness       → Add-on stickiness analysis
--    vw_state_summary          → Geographic map visual
--    vw_high_risk_customers    → At-risk customer table
--    vw_recommendations        → Playbook action table
-- ============================================================

USE customer_churn_db;


-- ============================================================
-- VIEW 1: Executive Summary KPIs (Card visuals on Page 1)
-- ============================================================
CREATE OR REPLACE VIEW vw_executive_summary AS
SELECT
    -- Volume
    COUNT(*)                                                                AS Total_Customers,
    SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END)           AS Total_Churned,
    SUM(CASE WHEN Customer_Status = 'Stayed'  THEN 1 ELSE 0 END)           AS Total_Stayed,
    SUM(CASE WHEN Customer_Status = 'Joined'  THEN 1 ELSE 0 END)           AS Total_New_Joiners,

    -- Churn Rate (exclude Joined from denominator)
    ROUND(
        SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN Customer_Status IN ('Churned','Stayed') THEN 1 ELSE 0 END), 0),
    2)                                                                      AS Churn_Rate_Pct,

    -- Revenue
    ROUND(SUM(Total_Revenue), 2)                                            AS Total_Lifetime_Revenue,
    ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN Total_Revenue  ELSE 0 END), 2) AS Revenue_Lost,
    ROUND(SUM(CASE WHEN Customer_Status = 'Stayed'  THEN Total_Revenue  ELSE 0 END), 2) AS Revenue_Retained,
    ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN Monthly_Charge ELSE 0 END), 2) AS Monthly_Revenue_Lost,

    -- At-Risk (active MTM customers = biggest exposure)
    SUM(CASE WHEN Customer_Status = 'Stayed' AND Contract = 'Month-to-Month' THEN 1 ELSE 0 END) AS At_Risk_Customers,
    ROUND(SUM(CASE WHEN Customer_Status = 'Stayed' AND Contract = 'Month-to-Month' THEN Monthly_Charge ELSE 0 END), 2) AS At_Risk_Monthly_Revenue,

    -- Averages
    ROUND(AVG(Monthly_Charge),    2)   AS Avg_Monthly_Charge,
    ROUND(AVG(Tenure_in_Months),  1)   AS Avg_Tenure_Months,
    ROUND(AVG(CASE WHEN Customer_Status = 'Churned' THEN Tenure_in_Months ELSE NULL END), 1) AS Avg_Churner_Tenure,
    ROUND(AVG(CASE WHEN Customer_Status = 'Stayed'  THEN Tenure_in_Months ELSE NULL END), 1) AS Avg_Stayer_Tenure,
    ROUND(AVG(Addon_Count), 2)         AS Avg_Addon_Count,
    ROUND(AVG(Number_of_Referrals), 2) AS Avg_Referrals

FROM customer_churn_clean;


-- ============================================================
-- VIEW 2: Customer Detail (Row-level — for drill-through)
-- ============================================================
CREATE OR REPLACE VIEW vw_customer_detail AS
SELECT
    Customer_ID,
    Gender,
    Age,
    Age_Group,
    Married,
    State,
    Number_of_Referrals,
    Tenure_in_Months,
    Tenure_Group,
    Value_Deal,
    Phone_Service,
    Multiple_Lines,
    Internet_Service,
    Internet_Type,
    Online_Security,
    Online_Backup,
    Device_Protection_Plan,
    Premium_Support,
    Streaming_TV,
    Streaming_Movies,
    Streaming_Music,
    Unlimited_Data,
    Addon_Count,
    Contract,
    Contract_Risk,
    Paperless_Billing,
    Payment_Method,
    Monthly_Charge,
    Monthly_Charge_Tier,
    Total_Charges,
    Total_Refunds,
    Total_Extra_Data_Charges,
    Total_Long_Distance_Charges,
    Total_Revenue,
    Customer_Status,
    Churn_Flag,
    Churn_Category,
    Churn_Reason
FROM customer_churn_clean;


-- ============================================================
-- VIEW 3: Churn Rate by Every Key Dimension
-- (Powers Page 3 — Churn Dashboard charts)
-- ============================================================
CREATE OR REPLACE VIEW vw_churn_by_dimension AS

-- By Contract
SELECT 'Contract' AS Dimension, Contract AS Category, COUNT(*) AS Total,
       SUM(Churn_Flag) AS Churned,
       ROUND(SUM(Churn_Flag)*100.0/COUNT(*),2) AS Churn_Rate_Pct,
       ROUND(AVG(Monthly_Charge),2) AS Avg_Monthly_Charge
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned','Stayed')
GROUP BY Contract

UNION ALL

-- By Internet Type
SELECT 'Internet Type', Internet_Type, COUNT(*), SUM(Churn_Flag),
       ROUND(SUM(Churn_Flag)*100.0/COUNT(*),2), ROUND(AVG(Monthly_Charge),2)
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed')
GROUP BY Internet_Type

UNION ALL

-- By Payment Method
SELECT 'Payment Method', Payment_Method, COUNT(*), SUM(Churn_Flag),
       ROUND(SUM(Churn_Flag)*100.0/COUNT(*),2), ROUND(AVG(Monthly_Charge),2)
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed')
GROUP BY Payment_Method

UNION ALL

-- By Tenure Group
SELECT 'Tenure Group', Tenure_Group, COUNT(*), SUM(Churn_Flag),
       ROUND(SUM(Churn_Flag)*100.0/COUNT(*),2), ROUND(AVG(Monthly_Charge),2)
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed')
GROUP BY Tenure_Group

UNION ALL

-- By Age Group
SELECT 'Age Group', Age_Group, COUNT(*), SUM(Churn_Flag),
       ROUND(SUM(Churn_Flag)*100.0/COUNT(*),2), ROUND(AVG(Monthly_Charge),2)
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed')
GROUP BY Age_Group

UNION ALL

-- By Monthly Charge Tier
SELECT 'Monthly Charge Tier', Monthly_Charge_Tier, COUNT(*), SUM(Churn_Flag),
       ROUND(SUM(Churn_Flag)*100.0/COUNT(*),2), ROUND(AVG(Monthly_Charge),2)
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed')
GROUP BY Monthly_Charge_Tier

UNION ALL

-- By Gender
SELECT 'Gender', Gender, COUNT(*), SUM(Churn_Flag),
       ROUND(SUM(Churn_Flag)*100.0/COUNT(*),2), ROUND(AVG(Monthly_Charge),2)
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed')
GROUP BY Gender

UNION ALL

-- By Married
SELECT 'Married', Married, COUNT(*), SUM(Churn_Flag),
       ROUND(SUM(Churn_Flag)*100.0/COUNT(*),2), ROUND(AVG(Monthly_Charge),2)
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed')
GROUP BY Married

UNION ALL

-- By Paperless Billing
SELECT 'Paperless Billing', Paperless_Billing, COUNT(*), SUM(Churn_Flag),
       ROUND(SUM(Churn_Flag)*100.0/COUNT(*),2), ROUND(AVG(Monthly_Charge),2)
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed')
GROUP BY Paperless_Billing

UNION ALL

-- By Value Deal
SELECT 'Value Deal', Value_Deal, COUNT(*), SUM(Churn_Flag),
       ROUND(SUM(Churn_Flag)*100.0/COUNT(*),2), ROUND(AVG(Monthly_Charge),2)
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed')
GROUP BY Value_Deal;


-- ============================================================
-- VIEW 4: Revenue Analysis (Page 4 — Revenue Dashboard)
-- ============================================================
CREATE OR REPLACE VIEW vw_revenue_analysis AS
SELECT
    Customer_Status,
    Contract,
    Internet_Type,
    Monthly_Charge_Tier,
    State,
    Tenure_Group,
    COUNT(*)                                                  AS Customers,
    ROUND(SUM(Total_Revenue),              2)                 AS Total_Revenue,
    ROUND(AVG(Total_Revenue),              2)                 AS Avg_Revenue_Per_Customer,
    ROUND(SUM(Monthly_Charge),             2)                 AS Total_Monthly_Revenue,
    ROUND(AVG(Monthly_Charge),             2)                 AS Avg_Monthly_Charge,
    ROUND(SUM(Total_Refunds),              2)                 AS Total_Refunds,
    ROUND(SUM(Total_Extra_Data_Charges),   2)                 AS Total_Overage_Charges,
    ROUND(SUM(Total_Long_Distance_Charges),2)                 AS Total_LongDistance_Charges,
    SUM(Churn_Flag)                                           AS Churned_Count,
    ROUND(SUM(CASE WHEN Churn_Flag=1 THEN Total_Revenue  ELSE 0 END),2) AS Revenue_Lost,
    ROUND(SUM(CASE WHEN Churn_Flag=1 THEN Monthly_Charge ELSE 0 END),2) AS Monthly_Revenue_Lost
FROM customer_churn_clean
GROUP BY Customer_Status, Contract, Internet_Type, Monthly_Charge_Tier, State, Tenure_Group;


-- ============================================================
-- VIEW 5: Churn Reasons (Page 3 — Root Cause visuals)
-- ============================================================
CREATE OR REPLACE VIEW vw_churn_reasons AS
SELECT
    Churn_Category,
    Churn_Reason,
    Contract,
    Internet_Type,
    Age_Group,
    Tenure_Group,
    COUNT(*)                              AS Churned_Customers,
    ROUND(AVG(Monthly_Charge),  2)        AS Avg_Monthly_Charge,
    ROUND(SUM(Total_Revenue),   2)        AS Revenue_Lost,
    ROUND(AVG(Tenure_in_Months),1)        AS Avg_Tenure_Months
FROM customer_churn_clean
WHERE Customer_Status = 'Churned'
  AND Churn_Category != 'Not Applicable'
GROUP BY Churn_Category, Churn_Reason, Contract, Internet_Type, Age_Group, Tenure_Group;


-- ============================================================
-- VIEW 6: Segment Risk Scorecard (Recommendations Page)
-- ============================================================
CREATE OR REPLACE VIEW vw_segment_risk AS
SELECT
    Contract,
    Internet_Type,
    Tenure_Group,
    Monthly_Charge_Tier,
    COUNT(*)                                                  AS Segment_Size,
    SUM(Churn_Flag)                                           AS Churned,
    ROUND(SUM(Churn_Flag)*100.0/COUNT(*),2)                   AS Churn_Rate_Pct,
    ROUND(AVG(Monthly_Charge),2)                              AS Avg_Monthly_Charge,
    ROUND(SUM(CASE WHEN Churn_Flag=1 THEN Total_Revenue ELSE 0 END),2) AS Revenue_Lost,
    ROUND(SUM(CASE WHEN Customer_Status='Stayed' THEN Monthly_Charge ELSE 0 END),2) AS Monthly_Revenue_At_Risk,
    ROUND(AVG(Addon_Count),2)                                 AS Avg_Addon_Count,
    CASE
        WHEN SUM(Churn_Flag)*100.0/COUNT(*) >= 40 THEN 'Critical'
        WHEN SUM(Churn_Flag)*100.0/COUNT(*) >= 25 THEN 'High'
        WHEN SUM(Churn_Flag)*100.0/COUNT(*) >= 15 THEN 'Medium'
        ELSE 'Low'
    END                                                       AS Risk_Level,
    ROUND(
        (SUM(Churn_Flag)*100.0/COUNT(*)) * 0.6
        + (SUM(CASE WHEN Churn_Flag=1 THEN Monthly_Charge ELSE 0 END)
           / NULLIF((SELECT MAX(Monthly_Charge) FROM customer_churn_clean),0)) * 40
    ,2)                                                       AS Risk_Score
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned','Stayed')
GROUP BY Contract, Internet_Type, Tenure_Group, Monthly_Charge_Tier
HAVING COUNT(*) >= 15
ORDER BY Risk_Score DESC;


-- ============================================================
-- VIEW 7: Add-On Stickiness (Behaviour Page)
-- ============================================================
CREATE OR REPLACE VIEW vw_addon_stickiness AS
SELECT
    Addon_Count,
    COUNT(*)                                            AS Total_Customers,
    SUM(Churn_Flag)                                     AS Churned,
    SUM(CASE WHEN Customer_Status='Stayed' THEN 1 ELSE 0 END) AS Stayed,
    ROUND(SUM(Churn_Flag)*100.0/COUNT(*),2)             AS Churn_Rate_Pct,
    ROUND(AVG(Monthly_Charge),2)                        AS Avg_Monthly_Charge,
    ROUND(AVG(Tenure_in_Months),1)                      AS Avg_Tenure_Months,
    ROUND(AVG(Number_of_Referrals),2)                   AS Avg_Referrals
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned','Stayed')
GROUP BY Addon_Count
ORDER BY Addon_Count;


-- ============================================================
-- VIEW 8: State Summary (Geographic Map visual)
-- ============================================================
CREATE OR REPLACE VIEW vw_state_summary AS
SELECT
    State,
    COUNT(*)                                            AS Total_Customers,
    SUM(Churn_Flag)                                     AS Churned,
    SUM(CASE WHEN Customer_Status='Stayed' THEN 1 ELSE 0 END)  AS Stayed,
    SUM(CASE WHEN Customer_Status='Joined' THEN 1 ELSE 0 END)  AS New_Joiners,
    ROUND(SUM(Churn_Flag)*100.0/NULLIF(
        SUM(CASE WHEN Customer_Status IN ('Churned','Stayed') THEN 1 ELSE 0 END),0),2) AS Churn_Rate_Pct,
    ROUND(SUM(Total_Revenue),2)                         AS Total_Revenue,
    ROUND(SUM(CASE WHEN Churn_Flag=1 THEN Total_Revenue ELSE 0 END),2) AS Revenue_Lost,
    ROUND(AVG(Monthly_Charge),2)                        AS Avg_Monthly_Charge,
    ROUND(AVG(Tenure_in_Months),1)                      AS Avg_Tenure_Months
FROM customer_churn_clean
GROUP BY State
ORDER BY Churn_Rate_Pct DESC;


-- ============================================================
-- VIEW 9: High-Risk Active Customers (Retention Action table)
-- ============================================================
CREATE OR REPLACE VIEW vw_high_risk_customers AS
SELECT
    Customer_ID,
    State,
    Age,
    Age_Group,
    Gender,
    Contract,
    Internet_Type,
    Tenure_in_Months,
    Tenure_Group,
    Monthly_Charge,
    Total_Revenue,
    Addon_Count,
    Number_of_Referrals,
    Paperless_Billing,
    Payment_Method,
    Value_Deal,
    Total_Extra_Data_Charges,
    Total_Refunds,
    -- Risk flags
    CASE WHEN Contract = 'Month-to-Month'          THEN 1 ELSE 0 END AS Flag_MTM,
    CASE WHEN Tenure_in_Months <= 12               THEN 1 ELSE 0 END AS Flag_Short_Tenure,
    CASE WHEN Monthly_Charge > 70                  THEN 1 ELSE 0 END AS Flag_High_Charge,
    CASE WHEN Internet_Type = 'Fiber Optic'        THEN 1 ELSE 0 END AS Flag_Fiber,
    CASE WHEN Addon_Count <= 1                     THEN 1 ELSE 0 END AS Flag_Low_Addons,
    CASE WHEN Number_of_Referrals = 0             THEN 1 ELSE 0 END AS Flag_No_Referrals,
    CASE WHEN Total_Extra_Data_Charges > 0         THEN 1 ELSE 0 END AS Flag_Overage,
    CASE WHEN Total_Refunds > 0                    THEN 1 ELSE 0 END AS Flag_Has_Refunds,
    -- Composite risk score (count of red flags, max = 8)
    (
        CASE WHEN Contract = 'Month-to-Month'      THEN 1 ELSE 0 END +
        CASE WHEN Tenure_in_Months <= 12           THEN 1 ELSE 0 END +
        CASE WHEN Monthly_Charge > 70              THEN 1 ELSE 0 END +
        CASE WHEN Internet_Type = 'Fiber Optic'    THEN 1 ELSE 0 END +
        CASE WHEN Addon_Count <= 1                 THEN 1 ELSE 0 END +
        CASE WHEN Number_of_Referrals = 0         THEN 1 ELSE 0 END +
        CASE WHEN Total_Extra_Data_Charges > 0     THEN 1 ELSE 0 END +
        CASE WHEN Total_Refunds > 0               THEN 1 ELSE 0 END
    )                                                              AS Risk_Flag_Count,
    CASE
        WHEN (CASE WHEN Contract='Month-to-Month' THEN 1 ELSE 0 END +
              CASE WHEN Tenure_in_Months<=12      THEN 1 ELSE 0 END +
              CASE WHEN Monthly_Charge>70         THEN 1 ELSE 0 END +
              CASE WHEN Internet_Type='Fiber Optic' THEN 1 ELSE 0 END +
              CASE WHEN Addon_Count<=1            THEN 1 ELSE 0 END +
              CASE WHEN Number_of_Referrals=0    THEN 1 ELSE 0 END +
              CASE WHEN Total_Extra_Data_Charges>0 THEN 1 ELSE 0 END +
              CASE WHEN Total_Refunds>0           THEN 1 ELSE 0 END) >= 5 THEN 'Critical'
        WHEN (CASE WHEN Contract='Month-to-Month' THEN 1 ELSE 0 END +
              CASE WHEN Tenure_in_Months<=12      THEN 1 ELSE 0 END +
              CASE WHEN Monthly_Charge>70         THEN 1 ELSE 0 END +
              CASE WHEN Internet_Type='Fiber Optic' THEN 1 ELSE 0 END +
              CASE WHEN Addon_Count<=1            THEN 1 ELSE 0 END +
              CASE WHEN Number_of_Referrals=0    THEN 1 ELSE 0 END +
              CASE WHEN Total_Extra_Data_Charges>0 THEN 1 ELSE 0 END +
              CASE WHEN Total_Refunds>0           THEN 1 ELSE 0 END) >= 3 THEN 'High'
        ELSE 'Medium'
    END AS Risk_Level
FROM customer_churn_clean
WHERE Customer_Status = 'Stayed'
ORDER BY Risk_Flag_Count DESC, Monthly_Charge DESC;
