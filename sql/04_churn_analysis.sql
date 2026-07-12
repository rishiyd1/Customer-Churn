-- ============================================================
--  Script   : 04_churn_analysis.sql
--  Purpose  : 35 business-focused SQL queries for Customer Churn Analysis
--  Source   : customer_churn_clean
--  Database : MySQL 8.0+
--  Author   : [Your Name]
--  Project  : Customer Churn Analysis  (SQL + Python + Power BI)
--  Version  : 1.0
--
--  Analysis Sections:
--    A  — Overall Churn Metrics       (Q01–Q03)
--    B  — Tenure & Lifecycle          (Q04–Q06)
--    C  — Demographics                (Q07–Q09)
--    D  — Contract & Billing          (Q10–Q13)
--    E  — Internet & Services         (Q14–Q17)
--    F  — Revenue & Financial Impact  (Q18–Q21)
--    G  — Geographic Analysis         (Q22–Q24)
--    H  — Churn Root Cause            (Q25–Q28)
--    I  — High-Value & At-Risk        (Q29–Q31)
--    J  — Customer Segmentation       (Q32–Q35)
-- ============================================================

USE customer_churn_db;


-- ============================================================
-- SECTION A — OVERALL CHURN METRICS
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- Q01: What is the overall churn rate of the business?
-- Business Question: Of all active customers (Stayed + Churned),
--                    what percentage have left the company?
-- ──────────────────────────────────────────────────────────────
SELECT
    COUNT(*)                                                           AS total_customers,
    SUM(CASE WHEN Customer_Status = 'Stayed'  THEN 1 ELSE 0 END)      AS stayed,
    SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END)      AS churned,
    SUM(CASE WHEN Customer_Status = 'Joined'  THEN 1 ELSE 0 END)      AS new_joiners,
    ROUND(
        SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END)
        * 100.0
        / NULLIF(SUM(CASE WHEN Customer_Status IN ('Churned','Stayed') THEN 1 ELSE 0 END), 0),
    2)                                                                 AS churn_rate_pct
FROM customer_churn_clean;
-- INSIGHT: Establishes the baseline churn KPI. Industry benchmark for
--          telecom is ~15-25%. Values above this signal urgent retention action.


-- ──────────────────────────────────────────────────────────────
-- Q02: What is the revenue impact of churn?
-- Business Question: How much total and average revenue is being
--                    lost each period due to churned customers?
-- ──────────────────────────────────────────────────────────────
SELECT
    Customer_Status,
    COUNT(*)                                   AS customers,
    ROUND(SUM(Total_Revenue),        2)        AS total_revenue,
    ROUND(AVG(Total_Revenue),        2)        AS avg_revenue_per_customer,
    ROUND(AVG(Monthly_Charge),       2)        AS avg_monthly_charge,
    ROUND(SUM(Monthly_Charge),       2)        AS total_monthly_revenue
FROM customer_churn_clean
GROUP BY Customer_Status
ORDER BY total_revenue DESC;
-- INSIGHT: Quantifies the exact revenue at risk. Average revenue of churned
--          customers vs. stayed shows whether high-value customers are leaving.


-- ──────────────────────────────────────────────────────────────
-- Q03: What is the monthly revenue being lost due to churn?
-- Business Question: How much recurring monthly revenue is walking
--                    out the door every billing cycle?
-- ──────────────────────────────────────────────────────────────
SELECT
    ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN Monthly_Charge ELSE 0 END), 2)  AS monthly_revenue_lost,
    ROUND(SUM(CASE WHEN Customer_Status = 'Stayed'  THEN Monthly_Charge ELSE 0 END), 2)  AS monthly_revenue_retained,
    ROUND(
        SUM(CASE WHEN Customer_Status = 'Churned' THEN Monthly_Charge ELSE 0 END)
        * 100.0
        / NULLIF(SUM(Monthly_Charge), 0),
    2)                                                                                    AS pct_monthly_revenue_lost
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed');
-- INSIGHT: Monthly revenue loss is the most actionable financial metric —
--          it directly impacts the P&L and justifies retention investment.


-- ============================================================
-- SECTION B — TENURE & LIFECYCLE ANALYSIS
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- Q04: Which tenure group has the highest churn rate?
-- Business Question: At what point in the customer lifecycle
--                    is churn most likely to occur?
-- ──────────────────────────────────────────────────────────────
SELECT
    Tenure_Group,
    COUNT(*)                                                            AS total_customers,
    SUM(Churn_Flag)                                                     AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)                       AS churn_rate_pct,
    ROUND(AVG(Monthly_Charge), 2)                                       AS avg_monthly_charge
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Tenure_Group
ORDER BY
    CASE Tenure_Group
        WHEN '0-6 Months'   THEN 1
        WHEN '7-12 Months'  THEN 2
        WHEN '13-24 Months' THEN 3
        WHEN '25-36 Months' THEN 4
        ELSE 5
    END;
-- INSIGHT: New customers (0-6 months) almost always have the highest churn.
--          This identifies the "critical retention window" for onboarding campaigns.


-- ──────────────────────────────────────────────────────────────
-- Q05: How do new joiners compare to established customers?
-- Business Question: Are newly acquired customers churning before
--                    they generate meaningful revenue?
-- ──────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN Customer_Status = 'Joined'              THEN 'New Joiner'
        WHEN Tenure_in_Months <= 12                  THEN 'Early Stage (≤12M)'
        WHEN Tenure_in_Months BETWEEN 13 AND 36      THEN 'Established (13-36M)'
        ELSE                                              'Loyal (36M+)'
    END                                                                AS customer_lifecycle,
    COUNT(*)                                                           AS customers,
    ROUND(AVG(Monthly_Charge), 2)                                      AS avg_monthly_charge,
    ROUND(AVG(Total_Revenue),  2)                                      AS avg_total_revenue,
    SUM(Churn_Flag)                                                    AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / NULLIF(COUNT(*), 0), 2)           AS churn_rate_pct
FROM customer_churn_clean
GROUP BY customer_lifecycle
ORDER BY churn_rate_pct DESC;
-- INSIGHT: If new joiners have a high churn rate before Month 12,
--          the business needs a stronger onboarding & early-engagement strategy.


-- ──────────────────────────────────────────────────────────────
-- Q06: What is the average tenure of churned vs. stayed customers?
-- Business Question: How long does a typical customer stay before
--                    deciding to leave?
-- ──────────────────────────────────────────────────────────────
SELECT
    Customer_Status,
    ROUND(AVG(Tenure_in_Months),   1)   AS avg_tenure_months,
    MIN(Tenure_in_Months)               AS min_tenure,
    MAX(Tenure_in_Months)               AS max_tenure,
    ROUND(STDDEV(Tenure_in_Months), 1)  AS stddev_tenure,
    COUNT(*)                            AS customers
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Customer_Status;
-- INSIGHT: A large gap in avg tenure between churned and stayed customers
--          confirms tenure is a leading indicator — prioritize early intervention.


-- ============================================================
-- SECTION C — DEMOGRAPHIC ANALYSIS
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- Q07: Does gender influence customer churn?
-- Business Question: Are male or female customers more likely to churn?
-- ──────────────────────────────────────────────────────────────
SELECT
    Gender,
    COUNT(*)                                                   AS total_customers,
    SUM(Churn_Flag)                                            AS churned,
    SUM(CASE WHEN Customer_Status = 'Stayed' THEN 1 ELSE 0 END) AS stayed,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)               AS churn_rate_pct,
    ROUND(AVG(Monthly_Charge), 2)                              AS avg_monthly_charge
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Gender
ORDER BY churn_rate_pct DESC;
-- INSIGHT: If churn rates are similar across genders, gender is a weak predictor.
--          Use this for demographic marketing segmentation rather than risk scoring.


-- ──────────────────────────────────────────────────────────────
-- Q08: Which age group churns the most?
-- Business Question: Are younger customers more likely to switch
--                    providers compared to older demographics?
-- ──────────────────────────────────────────────────────────────
SELECT
    Age_Group,
    COUNT(*)                                            AS total_customers,
    SUM(Churn_Flag)                                     AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(AVG(Monthly_Charge), 2)                       AS avg_monthly_charge,
    ROUND(AVG(Tenure_in_Months), 1)                     AS avg_tenure_months
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Age_Group
ORDER BY
    CASE Age_Group
        WHEN '18-30' THEN 1
        WHEN '31-45' THEN 2
        WHEN '46-60' THEN 3
        ELSE 4
    END;
-- INSIGHT: Younger customers (18-30) typically churn more due to higher
--          price sensitivity and lower brand loyalty. Seniors (60+) may
--          churn due to service complexity or competitor pricing.


-- ──────────────────────────────────────────────────────────────
-- Q09: Does marital status affect churn behaviour?
-- Business Question: Are single customers more likely to churn
--                    than married customers?
-- ──────────────────────────────────────────────────────────────
SELECT
    Married,
    COUNT(*)                                            AS total_customers,
    SUM(Churn_Flag)                                     AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(AVG(Tenure_in_Months), 1)                     AS avg_tenure_months,
    ROUND(AVG(Number_of_Referrals), 2)                  AS avg_referrals
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Married
ORDER BY churn_rate_pct DESC;
-- INSIGHT: Married customers often have bundled family plans — higher switching
--          cost. Single customers may churn more when a better individual deal appears.


-- ============================================================
-- SECTION D — CONTRACT & BILLING ANALYSIS
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- Q10: How does contract type drive churn rate?
-- Business Question: Which contract type is the strongest
--                    predictor of customer churn?
-- ──────────────────────────────────────────────────────────────
SELECT
    Contract,
    Contract_Risk,
    COUNT(*)                                                   AS total_customers,
    SUM(Churn_Flag)                                            AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)               AS churn_rate_pct,
    ROUND(AVG(Monthly_Charge),  2)                             AS avg_monthly_charge,
    ROUND(AVG(Tenure_in_Months),1)                             AS avg_tenure_months
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Contract, Contract_Risk
ORDER BY churn_rate_pct DESC;
-- INSIGHT: Month-to-Month customers will have dramatically higher churn (often 40-50%)
--          vs Two-Year customers (<5%). The top business lever is converting
--          Month-to-Month customers to longer contract terms.


-- ──────────────────────────────────────────────────────────────
-- Q11: Which payment method is associated with the highest churn?
-- Business Question: Does the payment method signal financial
--                    engagement or risk of involuntary churn?
-- ──────────────────────────────────────────────────────────────
SELECT
    Payment_Method,
    COUNT(*)                                            AS total_customers,
    SUM(Churn_Flag)                                     AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(AVG(Monthly_Charge), 2)                       AS avg_monthly_charge,
    ROUND(AVG(Total_Revenue),  2)                       AS avg_lifetime_revenue
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Payment_Method
ORDER BY churn_rate_pct DESC;
-- INSIGHT: Mailed Check customers have manual payment friction — higher involuntary
--          churn risk. Auto-pay customers (Credit Card, Bank Withdrawal) show lower
--          churn. Nudging customers to auto-pay is a low-cost retention tactic.


-- ──────────────────────────────────────────────────────────────
-- Q12: Does paperless billing correlate with churn?
-- Business Question: Are digitally-engaged customers (paperless)
--                    more or less likely to churn?
-- ──────────────────────────────────────────────────────────────
SELECT
    Paperless_Billing,
    COUNT(*)                                            AS total_customers,
    SUM(Churn_Flag)                                     AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(AVG(Monthly_Charge), 2)                       AS avg_monthly_charge
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Paperless_Billing
ORDER BY churn_rate_pct DESC;
-- INSIGHT: Paperless customers see their bills digitally and may notice
--          price changes faster — potentially triggering price-driven churn.
--          This finding is context-dependent and must be cross-tabbed with Contract.


-- ──────────────────────────────────────────────────────────────
-- Q13: How does the value deal (promotional offer) impact churn?
-- Business Question: Are customers on promotional deals more loyal,
--                    or do they churn when the deal expires?
-- ──────────────────────────────────────────────────────────────
SELECT
    Value_Deal,
    COUNT(*)                                            AS total_customers,
    SUM(Churn_Flag)                                     AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(AVG(Monthly_Charge), 2)                       AS avg_monthly_charge,
    ROUND(AVG(Tenure_in_Months), 1)                     AS avg_tenure_months
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Value_Deal
ORDER BY churn_rate_pct DESC;
-- INSIGHT: Customers with 'No Deal' have no pricing incentive to stay.
--          If deal customers churn at high rates too, deals may be attracting
--          price-sensitive customers who leave when the deal ends.


-- ============================================================
-- SECTION E — INTERNET & SERVICE ANALYSIS
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- Q14: Which internet type has the highest churn rate?
-- Business Question: Are customers on Fiber Optic dissatisfied
--                    with value-for-money vs. Cable or DSL?
-- ──────────────────────────────────────────────────────────────
SELECT
    Internet_Type,
    COUNT(*)                                            AS total_customers,
    SUM(Churn_Flag)                                     AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(AVG(Monthly_Charge), 2)                       AS avg_monthly_charge,
    ROUND(AVG(Addon_Count),    2)                       AS avg_addons_subscribed
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Internet_Type
ORDER BY churn_rate_pct DESC;
-- INSIGHT: Fiber Optic typically has the highest churn because it carries the
--          highest price. When competitors offer faster speeds at lower prices,
--          these customers are the first to leave.


-- ──────────────────────────────────────────────────────────────
-- Q15: Does the number of add-on services reduce churn?
-- Business Question: Do customers with more services have more
--                    switching cost and therefore stay longer?
-- ──────────────────────────────────────────────────────────────
SELECT
    Addon_Count,
    COUNT(*)                                            AS total_customers,
    SUM(Churn_Flag)                                     AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(AVG(Monthly_Charge),  2)                      AS avg_monthly_charge,
    ROUND(AVG(Tenure_in_Months),1)                      AS avg_tenure_months
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Addon_Count
ORDER BY Addon_Count;
-- INSIGHT: As Addon_Count increases, churn rate should decrease — this is the
--          "stickiness" hypothesis. Each add-on raises the switching cost.
--          Use this to justify aggressive add-on upsell programs.


-- ──────────────────────────────────────────────────────────────
-- Q16: Which specific add-on service is most protective against churn?
-- Business Question: If we can sell only one add-on to an at-risk
--                    customer, which one reduces churn the most?
-- ──────────────────────────────────────────────────────────────
SELECT
    'Online_Security'      AS addon_service,
    SUM(CASE WHEN Online_Security = 'Yes' AND Churn_Flag = 1 THEN 1 ELSE 0 END)       AS churned_with_addon,
    SUM(CASE WHEN Online_Security = 'Yes' THEN 1 ELSE 0 END)                          AS total_with_addon,
    ROUND(SUM(CASE WHEN Online_Security = 'Yes' AND Churn_Flag = 1 THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(SUM(CASE WHEN Online_Security = 'Yes' THEN 1 ELSE 0 END), 0), 2) AS churn_rate_with,
    ROUND(SUM(CASE WHEN Online_Security = 'No'  AND Churn_Flag = 1 THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(SUM(CASE WHEN Online_Security = 'No'  THEN 1 ELSE 0 END), 0), 2) AS churn_rate_without
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed') UNION ALL
SELECT 'Online_Backup',
    SUM(CASE WHEN Online_Backup = 'Yes' AND Churn_Flag = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN Online_Backup = 'Yes' THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN Online_Backup = 'Yes' AND Churn_Flag = 1 THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(SUM(CASE WHEN Online_Backup = 'Yes' THEN 1 ELSE 0 END), 0), 2),
    ROUND(SUM(CASE WHEN Online_Backup = 'No'  AND Churn_Flag = 1 THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(SUM(CASE WHEN Online_Backup = 'No'  THEN 1 ELSE 0 END), 0), 2)
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed') UNION ALL
SELECT 'Device_Protection_Plan',
    SUM(CASE WHEN Device_Protection_Plan = 'Yes' AND Churn_Flag = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN Device_Protection_Plan = 'Yes' THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN Device_Protection_Plan = 'Yes' AND Churn_Flag = 1 THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(SUM(CASE WHEN Device_Protection_Plan = 'Yes' THEN 1 ELSE 0 END), 0), 2),
    ROUND(SUM(CASE WHEN Device_Protection_Plan = 'No'  AND Churn_Flag = 1 THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(SUM(CASE WHEN Device_Protection_Plan = 'No'  THEN 1 ELSE 0 END), 0), 2)
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed') UNION ALL
SELECT 'Premium_Support',
    SUM(CASE WHEN Premium_Support = 'Yes' AND Churn_Flag = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN Premium_Support = 'Yes' THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN Premium_Support = 'Yes' AND Churn_Flag = 1 THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(SUM(CASE WHEN Premium_Support = 'Yes' THEN 1 ELSE 0 END), 0), 2),
    ROUND(SUM(CASE WHEN Premium_Support = 'No'  AND Churn_Flag = 1 THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(SUM(CASE WHEN Premium_Support = 'No'  THEN 1 ELSE 0 END), 0), 2)
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed') UNION ALL
SELECT 'Unlimited_Data',
    SUM(CASE WHEN Unlimited_Data = 'Yes' AND Churn_Flag = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN Unlimited_Data = 'Yes' THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN Unlimited_Data = 'Yes' AND Churn_Flag = 1 THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(SUM(CASE WHEN Unlimited_Data = 'Yes' THEN 1 ELSE 0 END), 0), 2),
    ROUND(SUM(CASE WHEN Unlimited_Data = 'No'  AND Churn_Flag = 1 THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(SUM(CASE WHEN Unlimited_Data = 'No'  THEN 1 ELSE 0 END), 0), 2)
FROM customer_churn_clean WHERE Customer_Status IN ('Churned','Stayed')
ORDER BY churn_rate_without DESC;
-- INSIGHT: The addon with the LARGEST gap between churn_rate_without and churn_rate_with
--          is the highest-ROI upsell for retention teams.


-- ──────────────────────────────────────────────────────────────
-- Q17: Do extra data charges drive customers to churn?
-- Business Question: Are overage fees a meaningful churn trigger?
-- ──────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN Total_Extra_Data_Charges = 0         THEN 'No Overage'
        WHEN Total_Extra_Data_Charges BETWEEN 1 AND 50  THEN 'Low Overage (1-50)'
        WHEN Total_Extra_Data_Charges BETWEEN 51 AND 150 THEN 'Medium (51-150)'
        ELSE                                           'High Overage (150+)'
    END                                                            AS overage_tier,
    COUNT(*)                                                       AS customers,
    SUM(Churn_Flag)                                                AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)                   AS churn_rate_pct,
    ROUND(AVG(Total_Extra_Data_Charges), 2)                        AS avg_overage_charge
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY overage_tier
ORDER BY avg_overage_charge;
-- INSIGHT: Customers with overage fees have an explicit financial grievance.
--          A targeted offer of Unlimited Data to this segment is a direct retention move.


-- ============================================================
-- SECTION F — REVENUE & FINANCIAL IMPACT
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- Q18: What is the revenue distribution across churn segments?
-- Business Question: Are we losing high-spending customers or
--                    mostly low-value customers?
-- ──────────────────────────────────────────────────────────────
SELECT
    Monthly_Charge_Tier,
    COUNT(*)                                            AS total_customers,
    SUM(Churn_Flag)                                     AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(SUM(CASE WHEN Churn_Flag = 1 THEN Total_Revenue ELSE 0 END), 2) AS revenue_lost,
    ROUND(AVG(Tenure_in_Months), 1)                     AS avg_tenure_months
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Monthly_Charge_Tier
ORDER BY
    CASE Monthly_Charge_Tier
        WHEN 'Low (<30)'       THEN 1
        WHEN 'Medium (30-60)'  THEN 2
        WHEN 'High (61-90)'    THEN 3
        ELSE 4
    END;
-- INSIGHT: If Premium (>90) customers have a high churn rate, the business
--          is losing its most valuable segment — this demands immediate VIP
--          retention intervention.


-- ──────────────────────────────────────────────────────────────
-- Q19: How do refunds relate to churn behaviour?
-- Business Question: Do customers who received refunds churn at
--                    higher rates, signalling ongoing dissatisfaction?
-- ──────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN Total_Refunds = 0                   THEN 'No Refunds'
        WHEN Total_Refunds BETWEEN 0.01 AND 30   THEN 'Small Refund (≤30)'
        WHEN Total_Refunds BETWEEN 30.01 AND 100 THEN 'Medium Refund (30-100)'
        ELSE                                          'Large Refund (100+)'
    END                                                            AS refund_tier,
    COUNT(*)                                                       AS customers,
    SUM(Churn_Flag)                                                AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)                   AS churn_rate_pct,
    ROUND(AVG(Total_Refunds), 2)                                   AS avg_refund_amount,
    ROUND(AVG(Total_Revenue), 2)                                   AS avg_lifetime_revenue
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY refund_tier
ORDER BY avg_refund_amount;
-- INSIGHT: Customers with large refunds likely experienced a service failure.
--          Refunds alone don't fix the relationship — they need a follow-up
--          retention call or upgrade offer.


-- ──────────────────────────────────────────────────────────────
-- Q20: What is the cumulative revenue lost to churn by contract?
-- Business Question: Which contract segment represents the largest
--                    revenue loss from churn?
-- ──────────────────────────────────────────────────────────────
SELECT
    Contract,
    COUNT(*)                                                                           AS total_customers,
    SUM(Churn_Flag)                                                                    AS churned_count,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)                                       AS churn_rate_pct,
    ROUND(SUM(CASE WHEN Churn_Flag = 1 THEN Total_Revenue    ELSE 0 END), 2)           AS lifetime_revenue_lost,
    ROUND(SUM(CASE WHEN Churn_Flag = 1 THEN Monthly_Charge   ELSE 0 END), 2)           AS monthly_revenue_lost,
    ROUND(AVG(CASE WHEN Churn_Flag = 1 THEN Total_Revenue    ELSE NULL END), 2)        AS avg_revenue_per_churner
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Contract
ORDER BY lifetime_revenue_lost DESC;
-- INSIGHT: Even though Month-to-Month has the highest churn RATE,
--          the total revenue lost may be dominated by customers who stayed
--          long and then left. This guides where to invest retention budget.


-- ──────────────────────────────────────────────────────────────
-- Q21: What is the long-distance charge burden on churned customers?
-- Business Question: Are high long-distance charges pushing customers
--                    to switch to VoIP or competitor plans?
-- ──────────────────────────────────────────────────────────────
SELECT
    Customer_Status,
    COUNT(*)                                                   AS customers,
    ROUND(AVG(Total_Long_Distance_Charges), 2)                 AS avg_long_distance,
    ROUND(SUM(Total_Long_Distance_Charges), 2)                 AS total_long_distance,
    ROUND(AVG(Monthly_Charge),             2)                  AS avg_monthly_charge,
    ROUND(
        AVG(Total_Long_Distance_Charges)
        / NULLIF(AVG(Monthly_Charge), 0) * 100,
    2)                                                         AS long_dist_as_pct_of_bill
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
  AND Phone_Service = 'Yes'
GROUP BY Customer_Status;
-- INSIGHT: If churned customers have significantly higher long-distance charges
--          as a % of bill, the company should introduce a long-distance bundle
--          offer before these customers compare prices with competitors.


-- ============================================================
-- SECTION G — GEOGRAPHIC ANALYSIS
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- Q22: Which Indian states have the highest churn rate?
-- Business Question: Are there specific regions where service quality,
--                    competition, or pricing is causing elevated churn?
-- ──────────────────────────────────────────────────────────────
SELECT
    State,
    COUNT(*)                                            AS total_customers,
    SUM(Churn_Flag)                                     AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(SUM(CASE WHEN Churn_Flag=1 THEN Total_Revenue ELSE 0 END), 2) AS revenue_lost,
    ROUND(AVG(Monthly_Charge), 2)                       AS avg_monthly_charge
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY State
ORDER BY churn_rate_pct DESC
LIMIT 15;
-- INSIGHT: States with high churn may have new competitor entrants or poor network
--          infrastructure. This drives region-specific retention campaigns and
--          infrastructure investment decisions.


-- ──────────────────────────────────────────────────────────────
-- Q23: Which states generate the most revenue from retained customers?
-- Business Question: Where should we double down on retention efforts
--                    to protect the highest-value markets?
-- ──────────────────────────────────────────────────────────────
SELECT
    State,
    COUNT(*)                                                            AS total_customers,
    ROUND(SUM(Total_Revenue), 2)                                        AS total_revenue,
    ROUND(SUM(CASE WHEN Customer_Status='Stayed'  THEN Total_Revenue ELSE 0 END), 2) AS revenue_retained,
    ROUND(SUM(CASE WHEN Customer_Status='Churned' THEN Total_Revenue ELSE 0 END), 2) AS revenue_lost,
    ROUND(
        SUM(CASE WHEN Customer_Status='Churned' THEN Total_Revenue ELSE 0 END)
        * 100.0 / NULLIF(SUM(Total_Revenue), 0),
    2)                                                                  AS pct_revenue_lost
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY State
ORDER BY total_revenue DESC
LIMIT 15;
-- INSIGHT: A state with high total revenue but moderate churn still represents
--          a massive retention opportunity compared to a small state with high churn.


-- ──────────────────────────────────────────────────────────────
-- Q24: Which states have both high churn AND high average revenue?
-- Business Question: Where is the combination of risk and financial
--                    impact most alarming for the business?
-- ──────────────────────────────────────────────────────────────
SELECT
    State,
    COUNT(*)                                            AS total_customers,
    ROUND(AVG(Monthly_Charge), 2)                       AS avg_monthly_charge,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(SUM(CASE WHEN Churn_Flag=1 THEN Monthly_Charge ELSE 0 END), 2) AS monthly_revenue_at_risk,
    CASE
        WHEN SUM(Churn_Flag)*100.0/COUNT(*) > 30
         AND AVG(Monthly_Charge) > 70              THEN '🔴 Critical Priority'
        WHEN SUM(Churn_Flag)*100.0/COUNT(*) > 20
         AND AVG(Monthly_Charge) > 50              THEN '🟠 High Priority'
        ELSE                                            '🟢 Monitor'
    END                                                AS priority_flag
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY State
HAVING COUNT(*) >= 50          -- filter states with enough data to be statistically meaningful
ORDER BY monthly_revenue_at_risk DESC;
-- INSIGHT: 🔴 Critical Priority states need immediate on-ground retention programs,
--          competitive pricing review, and proactive customer calls.


-- ============================================================
-- SECTION H — CHURN ROOT CAUSE ANALYSIS
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- Q25: What are the top churn categories driving customer loss?
-- Business Question: Is churn driven primarily by competition,
--                    dissatisfaction, price, attitude, or other reasons?
-- ──────────────────────────────────────────────────────────────
SELECT
    Churn_Category,
    COUNT(*)                                                           AS churned_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)                AS pct_of_total_churn,
    ROUND(AVG(Monthly_Charge),  2)                                     AS avg_monthly_charge,
    ROUND(AVG(Tenure_in_Months),1)                                     AS avg_tenure_months,
    ROUND(SUM(Total_Revenue),   2)                                     AS total_revenue_lost
FROM customer_churn_clean
WHERE Customer_Status = 'Churned'
GROUP BY Churn_Category
ORDER BY churned_customers DESC;
-- INSIGHT: If 'Competitor' is the top category, the business has a competitive
--          positioning problem. If 'Dissatisfaction' dominates, it is a service
--          quality problem. Each category demands a completely different response.


-- ──────────────────────────────────────────────────────────────
-- Q26: What are the top 15 specific churn reasons?
-- Business Question: What precise complaints are causing customers
--                    to leave, and which can be operationally fixed?
-- ──────────────────────────────────────────────────────────────
SELECT
    Churn_Category,
    Churn_Reason,
    COUNT(*)                                                           AS churned_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)                AS pct_of_total_churn,
    ROUND(AVG(Monthly_Charge),  2)                                     AS avg_monthly_charge,
    ROUND(SUM(Total_Revenue),   2)                                     AS revenue_lost
FROM customer_churn_clean
WHERE Customer_Status = 'Churned'
GROUP BY Churn_Category, Churn_Reason
ORDER BY churned_customers DESC
LIMIT 15;
-- INSIGHT: The top 3 specific reasons often account for 40-50% of all churn.
--          Fixing just those 3 issues can have an outsized impact on retention.


-- ──────────────────────────────────────────────────────────────
-- Q27: What is the revenue lost per churn reason?
-- Business Question: Should the business prioritize fixing reasons
--                    that affect the most customers, or the ones
--                    where each lost customer is most valuable?
-- ──────────────────────────────────────────────────────────────
SELECT
    Churn_Reason,
    COUNT(*)                                                           AS customers_lost,
    ROUND(AVG(Total_Revenue),   2)                                     AS avg_revenue_per_churner,
    ROUND(SUM(Total_Revenue),   2)                                     AS total_revenue_lost,
    ROUND(AVG(Monthly_Charge),  2)                                     AS avg_monthly_charge,
    ROUND(AVG(Tenure_in_Months),1)                                     AS avg_tenure_months
FROM customer_churn_clean
WHERE Customer_Status = 'Churned'
GROUP BY Churn_Reason
ORDER BY total_revenue_lost DESC
LIMIT 15;
-- INSIGHT: A reason with low frequency but very high avg revenue per churner
--          may be worth fixing first. A reason with high frequency but low avg
--          revenue is a volume problem — both matter but in different ways.


-- ──────────────────────────────────────────────────────────────
-- Q28: How does churn reason distribute across contract types?
-- Business Question: Do Month-to-Month customers churn for different
--                    reasons than longer-contract customers?
-- ──────────────────────────────────────────────────────────────
SELECT
    Contract,
    Churn_Category,
    COUNT(*)                                                           AS churned_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY Contract), 2) AS pct_within_contract
FROM customer_churn_clean
WHERE Customer_Status = 'Churned'
GROUP BY Contract, Churn_Category
ORDER BY Contract, churned_customers DESC;
-- INSIGHT: Month-to-Month churners may leave for price/competitor reasons
--          (easy to switch), while long-contract churners who break their
--          contract must have deep dissatisfaction — different playbooks required.


-- ============================================================
-- SECTION I — HIGH-VALUE & AT-RISK CUSTOMERS
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- Q29: Who are the top 20 highest-value customers still active?
-- Business Question: Which retained customers represent the biggest
--                    revenue that must be protected at all costs?
-- ──────────────────────────────────────────────────────────────
SELECT
    Customer_ID,
    State,
    Age,
    Contract,
    Internet_Type,
    Tenure_in_Months,
    Monthly_Charge,
    Total_Revenue,
    Addon_Count,
    Contract_Risk
FROM customer_churn_clean
WHERE Customer_Status = 'Stayed'
ORDER BY Monthly_Charge DESC
LIMIT 20;
-- INSIGHT: These customers should be placed in a VIP retention program with
--          proactive annual check-ins, loyalty rewards, and contract renewal offers.


-- ──────────────────────────────────────────────────────────────
-- Q30: Which high-value customers are on risky Month-to-Month contracts?
-- Business Question: Who are the most financially dangerous at-risk
--                    customers — high spend + no contract lock-in?
-- ──────────────────────────────────────────────────────────────
SELECT
    Customer_ID,
    State,
    Age,
    Gender,
    Internet_Type,
    Tenure_in_Months,
    Monthly_Charge,
    Total_Revenue,
    Addon_Count,
    Number_of_Referrals
FROM customer_churn_clean
WHERE Customer_Status  = 'Stayed'
  AND Contract         = 'Month-to-Month'
  AND Monthly_Charge   > 70                  -- above-average spender
  AND Tenure_in_Months < 24                  -- relatively new, no deep loyalty yet
ORDER BY Monthly_Charge DESC
LIMIT 20;
-- INSIGHT: This is the single highest-priority retention list. These customers
--          spend above average, have no contract lock-in, and are early enough
--          in their lifecycle that they haven't built strong loyalty. A targeted
--          contract upgrade offer with an incentive should go to these customers first.


-- ──────────────────────────────────────────────────────────────
-- Q31: Who are the high-value customers we already lost?
-- Business Question: What profile of high-value customer did we
--                    fail to retain, and what was the financial damage?
-- ──────────────────────────────────────────────────────────────
SELECT
    Customer_ID,
    State,
    Age,
    Contract,
    Internet_Type,
    Tenure_in_Months,
    Monthly_Charge,
    Total_Revenue,
    Churn_Category,
    Churn_Reason
FROM customer_churn_clean
WHERE Customer_Status = 'Churned'
  AND Monthly_Charge  > 70
ORDER BY Total_Revenue DESC
LIMIT 20;
-- INSIGHT: Understanding the profile of high-value churners informs predictive
--          modeling — these attributes become the early warning signals in
--          a proactive churn prevention system.


-- ============================================================
-- SECTION J — CUSTOMER SEGMENTATION & COMBINED ANALYSIS
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- Q32: What is the churn rate for the highest-risk combined segment?
-- Business Question: What profile of customer is simultaneously
--                    the most likely to churn AND the most costly?
-- ──────────────────────────────────────────────────────────────
SELECT
    Contract,
    Internet_Type,
    Payment_Method,
    COUNT(*)                                            AS total_customers,
    SUM(Churn_Flag)                                     AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(AVG(Monthly_Charge),  2)                      AS avg_monthly_charge,
    ROUND(SUM(CASE WHEN Churn_Flag=1 THEN Total_Revenue ELSE 0 END), 2) AS revenue_lost
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Contract, Internet_Type, Payment_Method
HAVING COUNT(*) >= 20          -- minimum sample for reliability
ORDER BY churn_rate_pct DESC
LIMIT 15;
-- INSIGHT: The segment with the highest churn_rate_pct AND highest revenue_lost
--          is the "burning platform" — the precise profile to target in the
--          next churn prevention campaign.


-- ──────────────────────────────────────────────────────────────
-- Q33: How does referral activity correlate with loyalty?
-- Business Question: Are customers who refer others significantly
--                    less likely to churn?
-- ──────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN Number_of_Referrals = 0             THEN '0 Referrals'
        WHEN Number_of_Referrals BETWEEN 1 AND 3 THEN '1-3 Referrals'
        WHEN Number_of_Referrals BETWEEN 4 AND 7 THEN '4-7 Referrals'
        ELSE                                          '8+ Referrals'
    END                                                            AS referral_bucket,
    COUNT(*)                                                       AS total_customers,
    SUM(Churn_Flag)                                                AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)                   AS churn_rate_pct,
    ROUND(AVG(Tenure_in_Months),  1)                               AS avg_tenure_months,
    ROUND(AVG(Monthly_Charge),    2)                               AS avg_monthly_charge
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY referral_bucket
ORDER BY
    CASE referral_bucket
        WHEN '0 Referrals'   THEN 1
        WHEN '1-3 Referrals' THEN 2
        WHEN '4-7 Referrals' THEN 3
        ELSE 4
    END;
-- INSIGHT: Customers with 8+ referrals are the most loyal brand advocates.
--          Referral programs don't just grow the customer base — they also
--          deeply embed the referring customer into the brand ecosystem.


-- ──────────────────────────────────────────────────────────────
-- Q34: Build a comprehensive churn risk scorecard by segment.
-- Business Question: Which customer segments should the retention
--                    team focus on, ranked by priority?
-- ──────────────────────────────────────────────────────────────
SELECT
    Contract,
    Tenure_Group,
    Monthly_Charge_Tier,
    Internet_Type,
    COUNT(*)                                                          AS segment_size,
    SUM(Churn_Flag)                                                   AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2)                      AS churn_rate_pct,
    ROUND(SUM(CASE WHEN Churn_Flag=1 THEN Total_Revenue ELSE 0 END), 2) AS revenue_at_risk,
    ROUND(AVG(Addon_Count), 2)                                        AS avg_addons,
    -- Risk Score: composite of churn rate + revenue at risk (normalized to 100)
    ROUND(
        (SUM(Churn_Flag) * 100.0 / COUNT(*)) * 0.6
        + (SUM(CASE WHEN Churn_Flag=1 THEN Total_Revenue ELSE 0 END)
           / NULLIF((SELECT MAX(Total_Revenue) FROM customer_churn_clean), 0)) * 0.4
    , 2)                                                              AS risk_score
FROM customer_churn_clean
WHERE Customer_Status IN ('Churned', 'Stayed')
GROUP BY Contract, Tenure_Group, Monthly_Charge_Tier, Internet_Type
HAVING COUNT(*) >= 15
ORDER BY risk_score DESC
LIMIT 20;
-- INSIGHT: The risk_score combines both likelihood to churn (rate) AND business
--          impact (revenue) — giving a single actionable priority ranking.
--          The top 5 rows of this query become the retention team's campaign targets.


-- ──────────────────────────────────────────────────────────────
-- Q35: What does a complete churn summary dashboard look like?
-- Business Question: A single-screen summary with all critical KPIs
--                    for executive reporting.
-- ──────────────────────────────────────────────────────────────
SELECT

    -- Volume KPIs
    COUNT(*)                                                                           AS total_customers,
    SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END)                      AS total_churned,
    SUM(CASE WHEN Customer_Status = 'Stayed'  THEN 1 ELSE 0 END)                      AS total_stayed,
    SUM(CASE WHEN Customer_Status = 'Joined'  THEN 1 ELSE 0 END)                      AS total_new_joiners,

    -- Churn Rate
    ROUND(
        SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN Customer_Status IN ('Churned','Stayed') THEN 1 ELSE 0 END), 0),
    2)                                                                                 AS overall_churn_rate_pct,

    -- Financial KPIs
    ROUND(SUM(Total_Revenue),                                                2)        AS total_lifetime_revenue,
    ROUND(SUM(CASE WHEN Customer_Status='Churned' THEN Total_Revenue  ELSE 0 END), 2) AS lifetime_revenue_lost,
    ROUND(SUM(CASE WHEN Customer_Status='Churned' THEN Monthly_Charge ELSE 0 END), 2) AS monthly_revenue_lost,
    ROUND(AVG(Monthly_Charge),                                               2)        AS avg_monthly_charge,
    ROUND(AVG(CASE WHEN Customer_Status='Churned' THEN Monthly_Charge ELSE NULL END),2) AS avg_churner_monthly_charge,

    -- Customer Profile KPIs
    ROUND(AVG(Tenure_in_Months),                                             1)        AS avg_tenure_all,
    ROUND(AVG(CASE WHEN Customer_Status='Churned' THEN Tenure_in_Months ELSE NULL END),1) AS avg_churner_tenure,
    ROUND(AVG(CASE WHEN Customer_Status='Stayed'  THEN Tenure_in_Months ELSE NULL END),1) AS avg_stayer_tenure,

    -- Risk KPIs
    SUM(CASE WHEN Contract = 'Month-to-Month' AND Customer_Status='Stayed' THEN 1 ELSE 0 END) AS at_risk_mtm_customers,
    ROUND(
        SUM(CASE WHEN Contract = 'Month-to-Month' AND Customer_Status='Stayed' THEN Monthly_Charge ELSE 0 END),
    2)                                                                                 AS at_risk_monthly_revenue

FROM customer_churn_clean;
-- INSIGHT: This query powers the Executive Dashboard KPI card row.
--          at_risk_mtm_customers and at_risk_monthly_revenue show the
--          current exposure — the revenue that could still be saved.
