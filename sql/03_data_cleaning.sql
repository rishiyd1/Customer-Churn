-- ============================================================
--  Script   : 03_data_cleaning.sql
--  Purpose  : Audit, clean, enrich, and produce the final
--             production-ready table: customer_churn_clean
--  Source   : tbl_churn_raw  (imported in 01_database_setup.sql)
--  Database : MySQL 8.0+
--  Author   : [Your Name]
--  Project  : Customer Churn Analysis  (SQL + Python + Power BI)
--  Version  : 1.0
--
--  Cleaning Stages:
--    STAGE 1  — Duplicate Detection & Removal
--    STAGE 2  — NULL & Blank Value Audit
--    STAGE 3  — NULL & Blank Value Treatment
--    STAGE 4  — Inconsistent & Anomalous Value Correction
--    STAGE 5  — Datatype Validation & Conversion
--    STAGE 6  — Derived / Engineered Columns
--    STAGE 7  — Final Cleaned Table Creation
--    STAGE 8  — Post-Clean Validation
-- ============================================================

USE customer_churn_db;


-- ============================================================
-- STAGE 1 — DUPLICATE DETECTION & REMOVAL
-- ============================================================

-- ── 1.1  Detect duplicate Customer_IDs ───────────────────────
-- Customer_ID is the primary key; zero rows = clean
SELECT
    Customer_ID,
    COUNT(*) AS occurrences
FROM tbl_churn_raw
GROUP BY Customer_ID
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- ── 1.2  Inspect the actual duplicate rows ───────────────────
-- Shows the full records for any duplicated IDs
SELECT r.*
FROM tbl_churn_raw r
INNER JOIN (
    SELECT Customer_ID
    FROM   tbl_churn_raw
    GROUP  BY Customer_ID
    HAVING COUNT(*) > 1
) dups ON r.Customer_ID = dups.Customer_ID
ORDER BY r.Customer_ID;


-- ── 1.3  Remove duplicates, keep one row per Customer_ID ─────
-- Strategy: keep the row with the lowest internal rowid using a CTE.
-- Note: MySQL does not expose rowid; we use a staging approach.
-- If NO duplicates found in 1.1, this step can be skipped safely.

-- Step A: Create deduplicated staging table
CREATE TABLE IF NOT EXISTS tbl_churn_deduped AS
SELECT *
FROM tbl_churn_raw
WHERE Customer_ID IN (
    SELECT Customer_ID FROM tbl_churn_raw GROUP BY Customer_ID
);

-- Step B: For true duplicates, keep only the first occurrence
-- (Uses ROW_NUMBER window function — MySQL 8.0+)
DELETE r1
FROM tbl_churn_raw r1
INNER JOIN (
    SELECT
        Customer_ID,
        ROW_NUMBER() OVER (
            PARTITION BY Customer_ID
            ORDER BY Customer_ID         -- deterministic tie-breaking
        ) AS row_num
    FROM tbl_churn_raw
) ranked ON r1.Customer_ID = ranked.Customer_ID
WHERE ranked.row_num > 1;

-- ── 1.4  Confirm deduplication result ────────────────────────
SELECT
    COUNT(*)                   AS total_rows_after_dedup,
    COUNT(DISTINCT Customer_ID) AS unique_customer_ids
FROM tbl_churn_raw;
-- total_rows_after_dedup should equal unique_customer_ids


-- ============================================================
-- STAGE 2 — NULL & BLANK VALUE AUDIT
-- ============================================================
-- Audit all 32 columns. Results classify blanks as:
--   [STRUCTURAL] → blank by design (e.g. add-ons when no internet)
--   [EXPECTED]   → blank for non-churned customers
--   [INVESTIGATE]→ unexpected missing data
-- ============================================================

-- ── 2.1  Full NULL / Blank count for all columns ─────────────
SELECT
    column_name,
    null_or_blank_count,
    ROUND(null_or_blank_count * 100.0 / (SELECT COUNT(*) FROM tbl_churn_raw), 2) AS pct_missing,
    CASE
        WHEN column_name IN ('Multiple_Lines')                           THEN '[STRUCTURAL] Blank when Phone_Service = No'
        WHEN column_name IN ('Internet_Type','Online_Security',
                             'Online_Backup','Device_Protection_Plan',
                             'Premium_Support','Streaming_TV',
                             'Streaming_Movies','Streaming_Music',
                             'Unlimited_Data')                           THEN '[STRUCTURAL] Blank when Internet_Service = No'
        WHEN column_name IN ('Value_Deal')                              THEN '[STRUCTURAL] Blank = customer has no promotional deal'
        WHEN column_name IN ('Churn_Category','Churn_Reason')           THEN '[EXPECTED]   Blank for Stayed / Joined customers'
        ELSE '[INVESTIGATE] Unexpected missing data'
    END AS classification
FROM (
    SELECT 'Customer_ID'                 AS column_name, SUM(Customer_ID                  IS NULL OR Customer_ID                  = '') AS null_or_blank_count FROM tbl_churn_raw UNION ALL
    SELECT 'Gender',                                     SUM(Gender                        IS NULL OR Gender                        = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Age',                                        SUM(Age                           IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Married',                                    SUM(Married                       IS NULL OR Married                       = '') FROM tbl_churn_raw UNION ALL
    SELECT 'State',                                      SUM(State                         IS NULL OR State                         = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Number_of_Referrals',                        SUM(Number_of_Referrals           IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Tenure_in_Months',                           SUM(Tenure_in_Months              IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Value_Deal',                                 SUM(Value_Deal                    IS NULL OR Value_Deal                    = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Phone_Service',                              SUM(Phone_Service                 IS NULL OR Phone_Service                 = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Multiple_Lines',                             SUM(Multiple_Lines                IS NULL OR Multiple_Lines                = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Internet_Service',                           SUM(Internet_Service              IS NULL OR Internet_Service              = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Internet_Type',                              SUM(Internet_Type                 IS NULL OR Internet_Type                 = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Online_Security',                            SUM(Online_Security               IS NULL OR Online_Security               = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Online_Backup',                              SUM(Online_Backup                 IS NULL OR Online_Backup                 = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Device_Protection_Plan',                     SUM(Device_Protection_Plan        IS NULL OR Device_Protection_Plan        = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Premium_Support',                            SUM(Premium_Support               IS NULL OR Premium_Support               = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Streaming_TV',                               SUM(Streaming_TV                  IS NULL OR Streaming_TV                  = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Streaming_Movies',                           SUM(Streaming_Movies              IS NULL OR Streaming_Movies              = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Streaming_Music',                            SUM(Streaming_Music               IS NULL OR Streaming_Music               = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Unlimited_Data',                             SUM(Unlimited_Data                IS NULL OR Unlimited_Data                = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Contract',                                   SUM(Contract                      IS NULL OR Contract                      = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Paperless_Billing',                          SUM(Paperless_Billing             IS NULL OR Paperless_Billing             = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Payment_Method',                             SUM(Payment_Method                IS NULL OR Payment_Method                = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Monthly_Charge',                             SUM(Monthly_Charge                IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Total_Charges',                              SUM(Total_Charges                 IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Total_Refunds',                              SUM(Total_Refunds                 IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Total_Extra_Data_Charges',                   SUM(Total_Extra_Data_Charges      IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Total_Long_Distance_Charges',                SUM(Total_Long_Distance_Charges   IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Total_Revenue',                              SUM(Total_Revenue                 IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Customer_Status',                            SUM(Customer_Status               IS NULL OR Customer_Status               = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Churn_Category',                             SUM(Churn_Category                IS NULL OR Churn_Category                = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Churn_Reason',                               SUM(Churn_Reason                  IS NULL OR Churn_Reason                  = '') FROM tbl_churn_raw
) audit
ORDER BY null_or_blank_count DESC;


-- ── 2.2  Cross-validate structural blanks ────────────────────
-- Blank Multiple_Lines count must equal rows where Phone_Service = 'No'
SELECT
    'Multiple_Lines'                                                     AS column_name,
    SUM(Multiple_Lines IS NULL OR Multiple_Lines = '')                   AS blank_count,
    SUM(Phone_Service = 'No')                                            AS phone_service_no_count,
    SUM(Multiple_Lines IS NULL OR Multiple_Lines = '')
        - SUM(Phone_Service = 'No')                                      AS discrepancy
FROM tbl_churn_raw

UNION ALL

-- Blank Internet add-on columns must equal rows where Internet_Service = 'No'
SELECT
    'Online_Security (internet add-on sample)',
    SUM(Online_Security IS NULL OR Online_Security = ''),
    SUM(Internet_Service = 'No'),
    SUM(Online_Security IS NULL OR Online_Security = '') - SUM(Internet_Service = 'No')
FROM tbl_churn_raw;
-- Discrepancy = 0 confirms structural blanks only


-- ── 2.3  Verify Churn columns are blank ONLY for non-churned ──
SELECT
    Customer_Status,
    COUNT(*)                                                                                  AS total,
    SUM(Churn_Category IS NULL OR Churn_Category = '')                                        AS blank_category,
    SUM(Churn_Reason   IS NULL OR Churn_Reason   = '')                                        AS blank_reason
FROM tbl_churn_raw
GROUP BY Customer_Status;


-- ============================================================
-- STAGE 3 — NULL & BLANK VALUE TREATMENT
-- ============================================================
-- All structural blanks are replaced with meaningful labels.
-- This makes every column query-safe — no more silent NULLs.
-- ============================================================

-- ── 3.1  Value_Deal: blank → 'No Deal' ───────────────────────
-- Blank means no promotional deal; NOT a missing value.
UPDATE tbl_churn_raw
SET Value_Deal = 'No Deal'
WHERE Value_Deal IS NULL OR Value_Deal = '';

-- ── 3.2  Multiple_Lines: blank → 'No Phone Service' ──────────
-- Only applies to customers with Phone_Service = 'No'
UPDATE tbl_churn_raw
SET Multiple_Lines = 'No Phone Service'
WHERE (Multiple_Lines IS NULL OR Multiple_Lines = '')
  AND Phone_Service = 'No';

-- ── 3.3  Internet_Type: blank → 'No Internet Service' ────────
UPDATE tbl_churn_raw
SET Internet_Type = 'No Internet Service'
WHERE (Internet_Type IS NULL OR Internet_Type = '')
  AND Internet_Service = 'No';

-- ── 3.4  All 8 internet add-on columns: blank → 'No Internet Service'
UPDATE tbl_churn_raw
SET
    Online_Security        = CASE WHEN Online_Security        IS NULL OR Online_Security        = '' THEN 'No Internet Service' ELSE Online_Security        END,
    Online_Backup          = CASE WHEN Online_Backup          IS NULL OR Online_Backup          = '' THEN 'No Internet Service' ELSE Online_Backup          END,
    Device_Protection_Plan = CASE WHEN Device_Protection_Plan IS NULL OR Device_Protection_Plan = '' THEN 'No Internet Service' ELSE Device_Protection_Plan END,
    Premium_Support        = CASE WHEN Premium_Support        IS NULL OR Premium_Support        = '' THEN 'No Internet Service' ELSE Premium_Support        END,
    Streaming_TV           = CASE WHEN Streaming_TV           IS NULL OR Streaming_TV           = '' THEN 'No Internet Service' ELSE Streaming_TV           END,
    Streaming_Movies       = CASE WHEN Streaming_Movies       IS NULL OR Streaming_Movies       = '' THEN 'No Internet Service' ELSE Streaming_Movies       END,
    Streaming_Music        = CASE WHEN Streaming_Music        IS NULL OR Streaming_Music        = '' THEN 'No Internet Service' ELSE Streaming_Music        END,
    Unlimited_Data         = CASE WHEN Unlimited_Data         IS NULL OR Unlimited_Data         = '' THEN 'No Internet Service' ELSE Unlimited_Data         END
WHERE Internet_Service = 'No';

-- ── 3.5  Churn_Category & Churn_Reason: blank → 'Not Applicable'
-- These are blank for Stayed / Joined — not genuinely missing.
UPDATE tbl_churn_raw
SET Churn_Category = 'Not Applicable'
WHERE (Churn_Category IS NULL OR Churn_Category = '')
  AND Customer_Status IN ('Stayed', 'Joined');

UPDATE tbl_churn_raw
SET Churn_Reason = 'Not Applicable'
WHERE (Churn_Reason IS NULL OR Churn_Reason = '')
  AND Customer_Status IN ('Stayed', 'Joined');

-- ── 3.6  Confirm all blanks are resolved ─────────────────────
SELECT
    SUM(Value_Deal          IS NULL OR Value_Deal          = '') AS vd_blanks,
    SUM(Multiple_Lines      IS NULL OR Multiple_Lines      = '') AS ml_blanks,
    SUM(Internet_Type       IS NULL OR Internet_Type       = '') AS it_blanks,
    SUM(Online_Security     IS NULL OR Online_Security     = '') AS os_blanks,
    SUM(Churn_Category      IS NULL OR Churn_Category      = '') AS cc_blanks,
    SUM(Churn_Reason        IS NULL OR Churn_Reason        = '') AS cr_blanks
FROM tbl_churn_raw;
-- All columns should return 0


-- ============================================================
-- STAGE 4 — INCONSISTENT & ANOMALOUS VALUE CORRECTION
-- ============================================================

-- ── 4.1  Inspect all distinct categorical values ─────────────
-- Run each before and after updating to confirm correctness

SELECT 'Gender'            AS col, Gender            AS val, COUNT(*) AS n FROM tbl_churn_raw GROUP BY Gender            UNION ALL
SELECT 'Married',                  Married,                  COUNT(*)     FROM tbl_churn_raw GROUP BY Married            UNION ALL
SELECT 'Phone_Service',            Phone_Service,            COUNT(*)     FROM tbl_churn_raw GROUP BY Phone_Service       UNION ALL
SELECT 'Internet_Service',         Internet_Service,         COUNT(*)     FROM tbl_churn_raw GROUP BY Internet_Service    UNION ALL
SELECT 'Internet_Type',            Internet_Type,            COUNT(*)     FROM tbl_churn_raw GROUP BY Internet_Type       UNION ALL
SELECT 'Contract',                 Contract,                 COUNT(*)     FROM tbl_churn_raw GROUP BY Contract            UNION ALL
SELECT 'Paperless_Billing',        Paperless_Billing,        COUNT(*)     FROM tbl_churn_raw GROUP BY Paperless_Billing   UNION ALL
SELECT 'Payment_Method',           Payment_Method,           COUNT(*)     FROM tbl_churn_raw GROUP BY Payment_Method      UNION ALL
SELECT 'Customer_Status',          Customer_Status,          COUNT(*)     FROM tbl_churn_raw GROUP BY Customer_Status     UNION ALL
SELECT 'Churn_Category',           Churn_Category,           COUNT(*)     FROM tbl_churn_raw GROUP BY Churn_Category      UNION ALL
SELECT 'Value_Deal',               Value_Deal,               COUNT(*)     FROM tbl_churn_raw GROUP BY Value_Deal
ORDER BY col, n DESC;


-- ── 4.2  Standardize case/whitespace on all categorical columns ─
-- TRIM removes leading/trailing spaces; ensures consistency.
UPDATE tbl_churn_raw
SET
    Gender             = TRIM(Gender),
    Married            = TRIM(Married),
    State              = TRIM(State),
    Value_Deal         = TRIM(Value_Deal),
    Phone_Service      = TRIM(Phone_Service),
    Multiple_Lines     = TRIM(Multiple_Lines),
    Internet_Service   = TRIM(Internet_Service),
    Internet_Type      = TRIM(Internet_Type),
    Online_Security    = TRIM(Online_Security),
    Online_Backup      = TRIM(Online_Backup),
    Device_Protection_Plan = TRIM(Device_Protection_Plan),
    Premium_Support    = TRIM(Premium_Support),
    Streaming_TV       = TRIM(Streaming_TV),
    Streaming_Movies   = TRIM(Streaming_Movies),
    Streaming_Music    = TRIM(Streaming_Music),
    Unlimited_Data     = TRIM(Unlimited_Data),
    Contract           = TRIM(Contract),
    Paperless_Billing  = TRIM(Paperless_Billing),
    Payment_Method     = TRIM(Payment_Method),
    Customer_Status    = TRIM(Customer_Status),
    Churn_Category     = TRIM(Churn_Category),
    Churn_Reason       = TRIM(Churn_Reason);


-- ── 4.3  Fix negative Monthly_Charge values ──────────────────
-- Root cause: likely billing credit entries or data entry errors.
-- Fix: take absolute value to represent the correct charge amount.
-- Flag these rows before correcting for audit trail.

-- Show impacted rows first
SELECT
    Customer_ID,
    Monthly_Charge        AS monthly_charge_raw,
    ABS(Monthly_Charge)   AS monthly_charge_corrected,
    Total_Charges,
    Total_Revenue,
    Customer_Status
FROM tbl_churn_raw
WHERE Monthly_Charge < 0
ORDER BY Monthly_Charge;

-- Apply the correction
UPDATE tbl_churn_raw
SET Monthly_Charge = ABS(Monthly_Charge)
WHERE Monthly_Charge < 0;

-- Confirm no negatives remain
SELECT MIN(Monthly_Charge) AS min_monthly_charge FROM tbl_churn_raw;
-- Expected: value >= 0


-- ── 4.4  Validate Total_Revenue consistency ───────────────────
-- Total_Revenue ≈ Total_Charges + Total_Extra_Data_Charges
--               + Total_Long_Distance_Charges - Total_Refunds
-- Flag rows where the computed value differs by more than ±1.00
-- (small delta is acceptable due to floating-point rounding)
SELECT
    Customer_ID,
    Total_Charges,
    Total_Extra_Data_Charges,
    Total_Long_Distance_Charges,
    Total_Refunds,
    Total_Revenue                                                                              AS revenue_stored,
    ROUND(
        Total_Charges
        + Total_Extra_Data_Charges
        + Total_Long_Distance_Charges
        - Total_Refunds,
    2)                                                                                         AS revenue_computed,
    ROUND(
        ABS(Total_Revenue - (
            Total_Charges
            + Total_Extra_Data_Charges
            + Total_Long_Distance_Charges
            - Total_Refunds
        )),
    2)                                                                                         AS delta
FROM tbl_churn_raw
HAVING delta > 1.00
ORDER BY delta DESC
LIMIT 20;


-- ── 4.5  Check Age is within a realistic range ────────────────
-- Expected: 18–100. Flag outliers.
SELECT
    Customer_ID, Age, Customer_Status
FROM tbl_churn_raw
WHERE Age < 18 OR Age > 100
ORDER BY Age;


-- ── 4.6  Check Tenure_in_Months is non-negative ───────────────
SELECT
    Customer_ID, Tenure_in_Months
FROM tbl_churn_raw
WHERE Tenure_in_Months < 0;
-- Expected: zero rows


-- ── 4.7  Verify 'Joined' customers have short tenure ─────────
-- 'Joined' = recently acquired; tenure should logically be very low
SELECT
    Tenure_in_Months,
    COUNT(*) AS count
FROM tbl_churn_raw
WHERE Customer_Status = 'Joined'
GROUP BY Tenure_in_Months
ORDER BY Tenure_in_Months DESC;


-- ============================================================
-- STAGE 5 — DATATYPE VALIDATION & CONVERSION CHECK
-- ============================================================
-- All columns were created with correct types in tbl_churn_raw.
-- These queries verify there are no hidden type coercion issues.
-- ============================================================

-- ── 5.1  Confirm DECIMAL columns have no text stored ─────────
-- MySQL silently converts bad text to 0 during LOAD DATA INFILE.
-- These checks surface any such silent coercions.
SELECT COUNT(*) AS suspicious_zero_monthly_charge
FROM tbl_churn_raw
WHERE Monthly_Charge = 0
  AND Tenure_in_Months > 3;     -- long-tenure customers with zero charge is unusual

SELECT COUNT(*) AS zero_total_revenue_stayed
FROM tbl_churn_raw
WHERE Total_Revenue = 0
  AND Customer_Status = 'Stayed';


-- ── 5.2  Confirm integer columns contain no fractional values ─
SELECT COUNT(*) AS non_integer_age
FROM tbl_churn_raw
WHERE Age != FLOOR(Age);

SELECT COUNT(*) AS non_integer_tenure
FROM tbl_churn_raw
WHERE Tenure_in_Months != FLOOR(Tenure_in_Months);

SELECT COUNT(*) AS non_integer_referrals
FROM tbl_churn_raw
WHERE Number_of_Referrals != FLOOR(Number_of_Referrals);


-- ── 5.3  Verify all DECIMAL values are within DECIMAL(12,2) ──
SELECT
    MAX(LENGTH(CAST(Total_Charges  AS CHAR)))   AS total_charges_max_digits,
    MAX(LENGTH(CAST(Total_Revenue  AS CHAR)))   AS total_revenue_max_digits,
    MAX(LENGTH(CAST(Monthly_Charge AS CHAR)))   AS monthly_charge_max_digits
FROM tbl_churn_raw;


-- ============================================================
-- STAGE 6 — DERIVED / ENGINEERED COLUMNS (computed at select time)
-- ============================================================
-- These enrich the clean table with pre-computed business segments
-- and binary flags that are used directly in Power BI & Python.
-- ============================================================

-- Preview the derived columns before baking them into the final table:
SELECT
    Customer_ID,

    -- ── 6.1  Binary churn flag (for ML modeling) ─────────────
    CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END                             AS Churn_Flag,

    -- ── 6.2  Tenure group (for segmented analysis) ────────────
    CASE
        WHEN Tenure_in_Months BETWEEN  0 AND  6  THEN '0-6 Months'
        WHEN Tenure_in_Months BETWEEN  7 AND 12  THEN '7-12 Months'
        WHEN Tenure_in_Months BETWEEN 13 AND 24  THEN '13-24 Months'
        WHEN Tenure_in_Months BETWEEN 25 AND 36  THEN '25-36 Months'
        ELSE                                           '36+ Months'
    END                                                                                  AS Tenure_Group,

    -- ── 6.3  Monthly charge tier ──────────────────────────────
    CASE
        WHEN Monthly_Charge <  30                 THEN 'Low (<₹30)'
        WHEN Monthly_Charge BETWEEN  30 AND  60   THEN 'Medium (₹30-60)'
        WHEN Monthly_Charge BETWEEN  61 AND  90   THEN 'High (₹61-90)'
        ELSE                                           'Premium (>₹90)'
    END                                                                                  AS Monthly_Charge_Tier,

    -- ── 6.4  Age group ────────────────────────────────────────
    CASE
        WHEN Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Age BETWEEN 31 AND 45 THEN '31-45'
        WHEN Age BETWEEN 46 AND 60 THEN '46-60'
        ELSE                            '60+'
    END                                                                                  AS Age_Group,

    -- ── 6.5  Add-on service count ─────────────────────────────
    -- Measures "stickiness" — how many add-ons the customer subscribes to
    (
        (CASE WHEN Online_Security        = 'Yes' THEN 1 ELSE 0 END) +
        (CASE WHEN Online_Backup          = 'Yes' THEN 1 ELSE 0 END) +
        (CASE WHEN Device_Protection_Plan = 'Yes' THEN 1 ELSE 0 END) +
        (CASE WHEN Premium_Support        = 'Yes' THEN 1 ELSE 0 END) +
        (CASE WHEN Streaming_TV           = 'Yes' THEN 1 ELSE 0 END) +
        (CASE WHEN Streaming_Movies       = 'Yes' THEN 1 ELSE 0 END) +
        (CASE WHEN Streaming_Music        = 'Yes' THEN 1 ELSE 0 END)
    )                                                                                    AS Addon_Count,

    -- ── 6.6  High-value customer flag ─────────────────────────
    -- Customers spending above the median monthly charge
    CASE WHEN Monthly_Charge > (
        SELECT ROUND(AVG(mc), 2)
        FROM (SELECT Monthly_Charge AS mc FROM tbl_churn_raw ORDER BY Monthly_Charge
              LIMIT 2 - (SELECT COUNT(*) FROM tbl_churn_raw) % 2
              OFFSET (SELECT (COUNT(*) - 1) / 2 FROM tbl_churn_raw)) AS median_sub
    ) THEN 'High Value' ELSE 'Standard' END                                              AS Customer_Segment,

    -- ── 6.7  Contract risk label ──────────────────────────────
    CASE
        WHEN Contract = 'Month-to-Month' THEN 'High Risk'
        WHEN Contract = 'One Year'       THEN 'Medium Risk'
        ELSE                                  'Low Risk'
    END                                                                                  AS Contract_Risk

FROM tbl_churn_raw
LIMIT 5;  -- preview only; full column set used in STAGE 7


-- ============================================================
-- STAGE 7 — FINAL CLEANED TABLE: customer_churn_clean
-- ============================================================
-- This is the single source of truth for all downstream analysis:
--   • 02_data_exploration.sql  (SQL analytics)
--   • 04_churn_analysis.sql    (business queries)
--   • 05_views_for_powerbi.sql (Power BI views)
--   • Python EDA & ML notebooks
-- ============================================================

DROP TABLE IF EXISTS customer_churn_clean;

CREATE TABLE customer_churn_clean AS
SELECT

    -- ── Identity ──────────────────────────────────────────────
    Customer_ID,

    -- ── Demographics ──────────────────────────────────────────
    Gender,
    Age,
    CASE
        WHEN Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Age BETWEEN 31 AND 45 THEN '31-45'
        WHEN Age BETWEEN 46 AND 60 THEN '46-60'
        ELSE                            '60+'
    END                                                              AS Age_Group,
    Married,
    State,

    -- ── Engagement ────────────────────────────────────────────
    Number_of_Referrals,
    Tenure_in_Months,
    CASE
        WHEN Tenure_in_Months BETWEEN  0 AND  6  THEN '0-6 Months'
        WHEN Tenure_in_Months BETWEEN  7 AND 12  THEN '7-12 Months'
        WHEN Tenure_in_Months BETWEEN 13 AND 24  THEN '13-24 Months'
        WHEN Tenure_in_Months BETWEEN 25 AND 36  THEN '25-36 Months'
        ELSE                                           '36+ Months'
    END                                                              AS Tenure_Group,
    Value_Deal,

    -- ── Phone Services ────────────────────────────────────────
    Phone_Service,
    Multiple_Lines,

    -- ── Internet Services ─────────────────────────────────────
    Internet_Service,
    Internet_Type,

    -- ── Internet Add-Ons ──────────────────────────────────────
    Online_Security,
    Online_Backup,
    Device_Protection_Plan,
    Premium_Support,
    Streaming_TV,
    Streaming_Movies,
    Streaming_Music,
    Unlimited_Data,

    -- ── Add-On Count (stickiness metric) ──────────────────────
    (
        (CASE WHEN Online_Security        = 'Yes' THEN 1 ELSE 0 END) +
        (CASE WHEN Online_Backup          = 'Yes' THEN 1 ELSE 0 END) +
        (CASE WHEN Device_Protection_Plan = 'Yes' THEN 1 ELSE 0 END) +
        (CASE WHEN Premium_Support        = 'Yes' THEN 1 ELSE 0 END) +
        (CASE WHEN Streaming_TV           = 'Yes' THEN 1 ELSE 0 END) +
        (CASE WHEN Streaming_Movies       = 'Yes' THEN 1 ELSE 0 END) +
        (CASE WHEN Streaming_Music        = 'Yes' THEN 1 ELSE 0 END)
    )                                                                AS Addon_Count,

    -- ── Contract & Billing ────────────────────────────────────
    Contract,
    CASE
        WHEN Contract = 'Month-to-Month' THEN 'High Risk'
        WHEN Contract = 'One Year'       THEN 'Medium Risk'
        ELSE                                  'Low Risk'
    END                                                              AS Contract_Risk,
    Paperless_Billing,
    Payment_Method,

    -- ── Financials (cleaned) ───────────────────────────────────
    Monthly_Charge,                                                  -- negatives already corrected in Stage 4
    CASE
        WHEN Monthly_Charge <  30                THEN 'Low (<30)'
        WHEN Monthly_Charge BETWEEN  30 AND  60  THEN 'Medium (30-60)'
        WHEN Monthly_Charge BETWEEN  61 AND  90  THEN 'High (61-90)'
        ELSE                                          'Premium (>90)'
    END                                                              AS Monthly_Charge_Tier,
    Total_Charges,
    Total_Refunds,
    Total_Extra_Data_Charges,
    Total_Long_Distance_Charges,
    Total_Revenue,

    -- ── Target / Outcome ──────────────────────────────────────
    Customer_Status,
    CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END          AS Churn_Flag,
    Churn_Category,
    Churn_Reason

FROM tbl_churn_raw;


-- ── Add primary key to the clean table ───────────────────────
ALTER TABLE customer_churn_clean
    ADD CONSTRAINT pk_churn_clean PRIMARY KEY (Customer_ID);

-- ── Add an index on high-cardinality filter columns ──────────
-- These are frequently used in WHERE / GROUP BY across all reports
CREATE INDEX idx_clean_status    ON customer_churn_clean (Customer_Status);
CREATE INDEX idx_clean_contract  ON customer_churn_clean (Contract);
CREATE INDEX idx_clean_state     ON customer_churn_clean (State);
CREATE INDEX idx_clean_internet  ON customer_churn_clean (Internet_Type);
CREATE INDEX idx_clean_tenure    ON customer_churn_clean (Tenure_in_Months);


-- ============================================================
-- STAGE 8 — POST-CLEAN VALIDATION
-- ============================================================
-- Systematically confirm the clean table is correct and complete.
-- ============================================================

-- ── 8.1  Row count should match deduped source ───────────────
SELECT
    (SELECT COUNT(*) FROM tbl_churn_raw)         AS source_rows,
    (SELECT COUNT(*) FROM customer_churn_clean)   AS clean_rows,
    (SELECT COUNT(*) FROM tbl_churn_raw)
        - (SELECT COUNT(*) FROM customer_churn_clean) AS row_diff;
-- row_diff = 0 expected (no rows lost or duplicated)


-- ── 8.2  Confirm zero nulls/blanks in previously blank columns ─
SELECT
    SUM(Value_Deal          IS NULL OR Value_Deal          = '') AS vd,
    SUM(Multiple_Lines      IS NULL OR Multiple_Lines      = '') AS ml,
    SUM(Internet_Type       IS NULL OR Internet_Type       = '') AS it,
    SUM(Online_Security     IS NULL OR Online_Security     = '') AS os,
    SUM(Online_Backup       IS NULL OR Online_Backup       = '') AS ob,
    SUM(Device_Protection_Plan IS NULL OR Device_Protection_Plan = '') AS dp,
    SUM(Premium_Support     IS NULL OR Premium_Support     = '') AS ps,
    SUM(Streaming_TV        IS NULL OR Streaming_TV        = '') AS stv,
    SUM(Streaming_Movies    IS NULL OR Streaming_Movies    = '') AS smv,
    SUM(Streaming_Music     IS NULL OR Streaming_Music     = '') AS smu,
    SUM(Unlimited_Data      IS NULL OR Unlimited_Data      = '') AS ud,
    SUM(Churn_Category      IS NULL OR Churn_Category      = '') AS cc,
    SUM(Churn_Reason        IS NULL OR Churn_Reason        = '') AS cr
FROM customer_churn_clean;
-- All columns must return 0


-- ── 8.3  Confirm no negative Monthly_Charge ──────────────────
SELECT COUNT(*) AS negative_charges
FROM customer_churn_clean
WHERE Monthly_Charge < 0;
-- Expected: 0


-- ── 8.4  Confirm Churn_Flag is only 0 or 1 ───────────────────
SELECT DISTINCT Churn_Flag
FROM customer_churn_clean
ORDER BY Churn_Flag;
-- Expected: 0, 1 only


-- ── 8.5  Validate derived column: Churn_Flag matches Customer_Status ─
SELECT
    Customer_Status,
    Churn_Flag,
    COUNT(*) AS count
FROM customer_churn_clean
GROUP BY Customer_Status, Churn_Flag
ORDER BY Customer_Status;
-- 'Churned' → Churn_Flag = 1 | 'Stayed'/'Joined' → Churn_Flag = 0


-- ── 8.6  Confirm all new category labels are correct ─────────
SELECT DISTINCT Value_Deal       FROM customer_churn_clean ORDER BY 1;
SELECT DISTINCT Multiple_Lines   FROM customer_churn_clean ORDER BY 1;
SELECT DISTINCT Internet_Type    FROM customer_churn_clean ORDER BY 1;
SELECT DISTINCT Churn_Category   FROM customer_churn_clean ORDER BY 1;
SELECT DISTINCT Tenure_Group     FROM customer_churn_clean ORDER BY 1;
SELECT DISTINCT Age_Group        FROM customer_churn_clean ORDER BY 1;
SELECT DISTINCT Monthly_Charge_Tier FROM customer_churn_clean ORDER BY 1;
SELECT DISTINCT Contract_Risk    FROM customer_churn_clean ORDER BY 1;


-- ── 8.7  Addon_Count distribution check ──────────────────────
SELECT
    Addon_Count,
    COUNT(*) AS customers
FROM customer_churn_clean
GROUP BY Addon_Count
ORDER BY Addon_Count;
-- Expected values: 0 through 7


-- ── 8.8  Final summary dashboard ─────────────────────────────
SELECT
    (SELECT COUNT(*)                                                   FROM customer_churn_clean)  AS total_customers,
    (SELECT COUNT(DISTINCT Customer_ID)                                FROM customer_churn_clean)  AS unique_ids,
    (SELECT COUNT(*) FROM customer_churn_clean WHERE Customer_Status = 'Churned')                  AS total_churned,
    (SELECT COUNT(*) FROM customer_churn_clean WHERE Customer_Status = 'Stayed')                   AS total_stayed,
    (SELECT COUNT(*) FROM customer_churn_clean WHERE Customer_Status = 'Joined')                   AS total_joined,
    (SELECT ROUND(AVG(Churn_Flag) * 100, 2)
     FROM customer_churn_clean WHERE Customer_Status != 'Joined')                                  AS churn_rate_pct,
    (SELECT ROUND(AVG(Monthly_Charge), 2)                              FROM customer_churn_clean)  AS avg_monthly_charge,
    (SELECT ROUND(AVG(Tenure_in_Months), 1)                            FROM customer_churn_clean)  AS avg_tenure_months,
    (SELECT ROUND(SUM(Total_Revenue), 2)                               FROM customer_churn_clean)  AS total_revenue,
    (SELECT ROUND(SUM(CASE WHEN Customer_Status = 'Churned'
                           THEN Total_Revenue ELSE 0 END), 2)          FROM customer_churn_clean)  AS revenue_lost_to_churn,
    (SELECT COUNT(*) FROM customer_churn_clean WHERE Monthly_Charge < 0)                           AS negative_charge_rows,  -- must be 0
    (SELECT COUNT(*) FROM customer_churn_clean
     WHERE Churn_Category IS NULL OR Churn_Category = '')                                          AS null_churn_category;    -- must be 0


-- ── 8.9  Preview final clean table ───────────────────────────
SELECT *
FROM customer_churn_clean
LIMIT 15;
