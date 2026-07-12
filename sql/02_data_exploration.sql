-- ============================================================
-- Script  : 02_data_exploration.sql
-- Purpose : Explore and understand the raw customer churn data
-- Author  : [Your Name]
-- Project : Customer Churn Analysis
-- ============================================================

USE customer_churn_db;

-- 1. Total record count
SELECT COUNT(*) AS total_customers FROM customer_raw;

-- 2. Distribution of Customer Status
SELECT Customer_Status, COUNT(*) AS count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_raw), 2) AS pct
FROM customer_raw
GROUP BY Customer_Status;

-- 3. Churn by Contract Type
SELECT Contract, Customer_Status, COUNT(*) AS count
FROM customer_raw
GROUP BY Contract, Customer_Status
ORDER BY Contract, Customer_Status;

-- 4. Churn by Internet Type
SELECT Internet_Type, Customer_Status, COUNT(*) AS count
FROM customer_raw
GROUP BY Internet_Type, Customer_Status;

-- 5. Churn Category Breakdown (churned customers only)
SELECT Churn_Category, COUNT(*) AS count
FROM customer_raw
WHERE Customer_Status = 'Churned'
GROUP BY Churn_Category
ORDER BY count DESC;

-- 6. Average Monthly Charge by Status
SELECT Customer_Status, ROUND(AVG(Monthly_Charge), 2) AS avg_monthly_charge
FROM customer_raw
GROUP BY Customer_Status;

-- 7. Check for negative Monthly Charges
SELECT * FROM customer_raw WHERE Monthly_Charge < 0;

-- 8. Tenure distribution (new vs old customers)
SELECT
    CASE
        WHEN Tenure_in_Months <= 6   THEN '0-6 Months'
        WHEN Tenure_in_Months <= 12  THEN '7-12 Months'
        WHEN Tenure_in_Months <= 24  THEN '13-24 Months'
        ELSE '24+ Months'
    END AS tenure_bucket,
    COUNT(*) AS count
FROM customer_raw
GROUP BY tenure_bucket;
