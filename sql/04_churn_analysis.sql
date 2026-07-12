-- ============================================================
-- Script  : 04_churn_analysis.sql
-- Purpose : Core analytical queries for churn insights
-- Author  : [Your Name]
-- Project : Customer Churn Analysis
-- ============================================================

USE customer_churn_db;

-- 1. Overall Churn Rate
SELECT
    SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS churned,
    COUNT(*) AS total,
    ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customer_clean
WHERE Customer_Status != 'Joined';

-- 2. Revenue Lost to Churn
SELECT
    Customer_Status,
    COUNT(*) AS customers,
    ROUND(SUM(Total_Revenue), 2) AS total_revenue,
    ROUND(AVG(Total_Revenue), 2) AS avg_revenue_per_customer
FROM customer_clean
GROUP BY Customer_Status;

-- 3. Churn Rate by Contract Type
SELECT
    Contract,
    COUNT(*) AS total,
    SUM(Churn_Flag) AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customer_clean
WHERE Customer_Status != 'Joined'
GROUP BY Contract
ORDER BY churn_rate_pct DESC;

-- 4. Churn Rate by Tenure Bucket
SELECT
    CASE
        WHEN Tenure_in_Months <= 6  THEN '0-6 Months'
        WHEN Tenure_in_Months <= 12 THEN '7-12 Months'
        WHEN Tenure_in_Months <= 24 THEN '13-24 Months'
        ELSE '24+ Months'
    END AS tenure_bucket,
    COUNT(*) AS total,
    SUM(Churn_Flag) AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customer_clean
WHERE Customer_Status != 'Joined'
GROUP BY tenure_bucket;

-- 5. Top 10 Churn Reasons
SELECT Churn_Reason, COUNT(*) AS count
FROM customer_clean
WHERE Customer_Status = 'Churned'
GROUP BY Churn_Reason
ORDER BY count DESC
LIMIT 10;

-- 6. Churn Rate by Internet Type
SELECT
    Internet_Type,
    COUNT(*) AS total,
    SUM(Churn_Flag) AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customer_clean
WHERE Customer_Status != 'Joined'
GROUP BY Internet_Type
ORDER BY churn_rate_pct DESC;

-- 7. State-wise Churn Ranking
SELECT
    State,
    COUNT(*) AS total_customers,
    SUM(Churn_Flag) AS churned_customers,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customer_clean
WHERE Customer_Status != 'Joined'
GROUP BY State
ORDER BY churn_rate_pct DESC;
