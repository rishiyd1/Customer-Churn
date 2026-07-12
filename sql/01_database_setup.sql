-- ============================================================
--  Script   : 01_database_setup.sql
--  Purpose  : Create database, raw staging table, import CSV,
--             and verify data integrity
--  Database : MySQL 8.0+
--  Dataset  : Customer_Data.csv  (6,419 records | 32 columns)
--  Author   : [Your Name]
--  Project  : Customer Churn Analysis  (SQL + Python + Power BI)
--  Version  : 1.0
--  Notes    : Run each section sequentially.
--             This script performs NO data cleaning — raw import only.
-- ============================================================


-- ============================================================
-- SECTION 1 — DATABASE CREATION
-- ============================================================

-- Drop and recreate for a clean setup (safe for dev; remove DROP in prod)
DROP DATABASE IF EXISTS customer_churn_db;

CREATE DATABASE customer_churn_db
    CHARACTER SET  utf8mb4        -- full Unicode (handles ₹, special chars)
    COLLATE        utf8mb4_unicode_ci;  -- case-insensitive, accent-insensitive

USE customer_churn_db;

-- ============================================================
-- SECTION 2 — TABLE CREATION  (Raw / Staging Layer)
-- ============================================================
-- Naming convention : tbl_churn_raw  (raw = unmodified source data)
-- Every column mirrors the CSV exactly — no transformations.
-- NULL is allowed on all optional/conditional columns.
-- ============================================================

DROP TABLE IF EXISTS tbl_churn_raw;

CREATE TABLE tbl_churn_raw (

    -- ── Identity ─────────────────────────────────────────────
    Customer_ID                 VARCHAR(20)        NOT NULL,   -- e.g. '19877-DEL'

    -- ── Demographics ─────────────────────────────────────────
    Gender                      VARCHAR(10)        NULL,       -- 'Male' | 'Female'
    Age                         TINYINT UNSIGNED   NULL,       -- 0–120; TINYINT fits perfectly
    Married                     VARCHAR(5)         NULL,       -- 'Yes' | 'No'
    State                       VARCHAR(60)        NULL,       -- Indian state name

    -- ── Engagement ───────────────────────────────────────────
    Number_of_Referrals         TINYINT UNSIGNED   NULL,       -- 0–15 observed in data
    Tenure_in_Months            SMALLINT UNSIGNED  NULL,       -- 0–72+ months
    Value_Deal                  VARCHAR(15)        NULL,       -- 'Deal 1'…'Deal 5' or blank

    -- ── Phone Services ───────────────────────────────────────
    Phone_Service               VARCHAR(5)         NULL,       -- 'Yes' | 'No'
    Multiple_Lines              VARCHAR(25)        NULL,       -- 'Yes' | 'No' | blank (no phone)

    -- ── Internet Services ────────────────────────────────────
    Internet_Service            VARCHAR(5)         NULL,       -- 'Yes' | 'No'
    Internet_Type               VARCHAR(20)        NULL,       -- 'Fiber Optic' | 'Cable' | 'DSL' | blank

    -- ── Internet Add-Ons (blank when Internet_Service = 'No') ─
    Online_Security             VARCHAR(25)        NULL,
    Online_Backup               VARCHAR(25)        NULL,
    Device_Protection_Plan      VARCHAR(25)        NULL,
    Premium_Support             VARCHAR(25)        NULL,
    Streaming_TV                VARCHAR(25)        NULL,
    Streaming_Movies            VARCHAR(25)        NULL,
    Streaming_Music             VARCHAR(25)        NULL,
    Unlimited_Data              VARCHAR(25)        NULL,

    -- ── Contract & Billing ───────────────────────────────────
    Contract                    VARCHAR(20)        NULL,       -- 'Month-to-Month' | 'One Year' | 'Two Year'
    Paperless_Billing           VARCHAR(5)         NULL,       -- 'Yes' | 'No'
    Payment_Method              VARCHAR(25)        NULL,       -- 'Credit Card' | 'Bank Withdrawal' | 'Mailed Check'

    -- ── Financials ───────────────────────────────────────────
    -- DECIMAL(p, s): p = total digits, s = decimal places
    -- Negative Monthly_Charge exists in raw data — keep as-is (no cleaning yet)
    Monthly_Charge              DECIMAL(8,  2)     NULL,       -- e.g.  65.60  | -4.00
    Total_Charges               DECIMAL(12, 2)     NULL,       -- cumulative billing
    Total_Refunds               DECIMAL(10, 2)     NULL,       -- cumulative refunds
    Total_Extra_Data_Charges    DECIMAL(8,  2)     NULL,       -- overage charges
    Total_Long_Distance_Charges DECIMAL(10, 2)     NULL,       -- long-distance spend
    Total_Revenue               DECIMAL(12, 2)     NULL,       -- lifetime revenue

    -- ── Target / Outcome Columns ─────────────────────────────
    Customer_Status             VARCHAR(15)        NULL,       -- 'Churned' | 'Stayed' | 'Joined'
    Churn_Category              VARCHAR(30)        NULL,       -- 'Competitor' | 'Dissatisfaction' | ... | blank
    Churn_Reason                VARCHAR(100)       NULL,       -- granular reason text | blank

    -- ── Primary Key ──────────────────────────────────────────
    CONSTRAINT pk_churn_raw PRIMARY KEY (Customer_ID)

) ENGINE = InnoDB
  DEFAULT CHARSET  = utf8mb4
  COLLATE          = utf8mb4_unicode_ci
  COMMENT          = 'Raw staging table — Customer Churn dataset, unmodified source import';


-- ============================================================
-- SECTION 3 — CSV IMPORT  (LOAD DATA INFILE)
-- ============================================================
-- IMPORTANT: Before running this section:
--   1. Place Customer_Data.csv inside MySQL's secure_file_priv directory,
--      OR set secure_file_priv = '' in my.ini / my.cnf and restart MySQL.
--
--   To find your secure_file_priv path, run:
--      SHOW VARIABLES LIKE 'secure_file_priv';
--
--   Typical Windows path (MySQL 8):
--      C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/
--
--   UPDATE THE PATH BELOW to match your system.
-- ============================================================

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Customer_Data.csv'

INTO TABLE tbl_churn_raw

    FIELDS
        TERMINATED BY   ','          -- comma-separated
        OPTIONALLY ENCLOSED BY '"'   -- handles commas inside quoted fields (e.g. Churn_Reason)
        ESCAPED BY      '\\'

    LINES
        TERMINATED BY   '\r\n'       -- Windows CRLF line endings

    IGNORE 1 ROWS                    -- skip the header row

    -- Map all 32 CSV columns to table columns in exact CSV order:
    (
        Customer_ID,
        Gender,
        Age,
        Married,
        State,
        Number_of_Referrals,
        Tenure_in_Months,
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
        Contract,
        Paperless_Billing,
        Payment_Method,
        Monthly_Charge,
        Total_Charges,
        Total_Refunds,
        Total_Extra_Data_Charges,
        Total_Long_Distance_Charges,
        Total_Revenue,
        Customer_Status,
        Churn_Category,
        Churn_Reason
    );


-- ============================================================
-- SECTION 4 — IMPORT VERIFICATION
-- ============================================================
-- Goal: Confirm data was loaded correctly, completely, and without
--       silent truncation or type conversion errors.
-- ============================================================

-- ── 4.1  Total Row Count ─────────────────────────────────────
-- Expected : 6,419 rows (6,420 lines in CSV minus 1 header)
SELECT COUNT(*) AS total_rows_imported
FROM tbl_churn_raw;


-- ── 4.2  Peek at First 10 Rows ───────────────────────────────
-- Visually confirm data looks correct after import
SELECT *
FROM tbl_churn_raw
LIMIT 10;


-- ── 4.3  Customer_Status Distribution ────────────────────────
-- Validates the three status values are intact and complete
SELECT
    Customer_Status,
    COUNT(*)                                                    AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)         AS pct_of_total
FROM tbl_churn_raw
GROUP BY Customer_Status
ORDER BY count DESC;


-- ── 4.4  Check for Duplicate Customer_IDs ────────────────────
-- Primary key should have zero duplicates; any result here = data issue
SELECT
    Customer_ID,
    COUNT(*) AS occurrences
FROM tbl_churn_raw
GROUP BY Customer_ID
HAVING COUNT(*) > 1;


-- ── 4.5  NULL / Blank Count per Column ───────────────────────
-- Quantify how many rows have empty or null values in each column.
-- Structural blanks (add-ons, Churn columns) are expected — document them.
SELECT
    'Customer_ID'                  AS column_name, SUM(Customer_ID                  IS NULL OR Customer_ID                  = '') AS null_or_blank FROM tbl_churn_raw UNION ALL
    SELECT 'Gender',                               SUM(Gender                        IS NULL OR Gender                        = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Age',                                  SUM(Age                           IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Married',                              SUM(Married                       IS NULL OR Married                       = '') FROM tbl_churn_raw UNION ALL
    SELECT 'State',                                SUM(State                         IS NULL OR State                         = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Number_of_Referrals',                  SUM(Number_of_Referrals           IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Tenure_in_Months',                     SUM(Tenure_in_Months              IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Value_Deal',                           SUM(Value_Deal                    IS NULL OR Value_Deal                    = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Phone_Service',                        SUM(Phone_Service                 IS NULL OR Phone_Service                 = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Multiple_Lines',                       SUM(Multiple_Lines                IS NULL OR Multiple_Lines                = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Internet_Service',                     SUM(Internet_Service              IS NULL OR Internet_Service              = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Internet_Type',                        SUM(Internet_Type                 IS NULL OR Internet_Type                 = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Online_Security',                      SUM(Online_Security               IS NULL OR Online_Security               = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Online_Backup',                        SUM(Online_Backup                 IS NULL OR Online_Backup                 = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Device_Protection_Plan',               SUM(Device_Protection_Plan        IS NULL OR Device_Protection_Plan        = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Premium_Support',                      SUM(Premium_Support               IS NULL OR Premium_Support               = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Streaming_TV',                         SUM(Streaming_TV                  IS NULL OR Streaming_TV                  = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Streaming_Movies',                     SUM(Streaming_Movies              IS NULL OR Streaming_Movies              = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Streaming_Music',                      SUM(Streaming_Music               IS NULL OR Streaming_Music               = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Unlimited_Data',                       SUM(Unlimited_Data                IS NULL OR Unlimited_Data                = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Contract',                             SUM(Contract                      IS NULL OR Contract                      = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Paperless_Billing',                    SUM(Paperless_Billing             IS NULL OR Paperless_Billing             = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Payment_Method',                       SUM(Payment_Method                IS NULL OR Payment_Method                = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Monthly_Charge',                       SUM(Monthly_Charge                IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Total_Charges',                        SUM(Total_Charges                 IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Total_Refunds',                        SUM(Total_Refunds                 IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Total_Extra_Data_Charges',             SUM(Total_Extra_Data_Charges      IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Total_Long_Distance_Charges',          SUM(Total_Long_Distance_Charges   IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Total_Revenue',                        SUM(Total_Revenue                 IS NULL)                                       FROM tbl_churn_raw UNION ALL
    SELECT 'Customer_Status',                      SUM(Customer_Status               IS NULL OR Customer_Status               = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Churn_Category',                       SUM(Churn_Category                IS NULL OR Churn_Category                = '') FROM tbl_churn_raw UNION ALL
    SELECT 'Churn_Reason',                         SUM(Churn_Reason                  IS NULL OR Churn_Reason                  = '') FROM tbl_churn_raw;


-- ── 4.6  Validate Distinct Values in Categorical Columns ─────
-- Confirms no unexpected or misspelled category values made it in

SELECT DISTINCT Gender           FROM tbl_churn_raw ORDER BY 1;
SELECT DISTINCT Married          FROM tbl_churn_raw ORDER BY 1;
SELECT DISTINCT Phone_Service    FROM tbl_churn_raw ORDER BY 1;
SELECT DISTINCT Multiple_Lines   FROM tbl_churn_raw ORDER BY 1;
SELECT DISTINCT Internet_Service FROM tbl_churn_raw ORDER BY 1;
SELECT DISTINCT Internet_Type    FROM tbl_churn_raw ORDER BY 1;
SELECT DISTINCT Contract         FROM tbl_churn_raw ORDER BY 1;
SELECT DISTINCT Paperless_Billing FROM tbl_churn_raw ORDER BY 1;
SELECT DISTINCT Payment_Method   FROM tbl_churn_raw ORDER BY 1;
SELECT DISTINCT Customer_Status  FROM tbl_churn_raw ORDER BY 1;
SELECT DISTINCT Churn_Category   FROM tbl_churn_raw ORDER BY 1;
SELECT DISTINCT Value_Deal       FROM tbl_churn_raw ORDER BY 1;


-- ── 4.7  Numeric Range Sanity Check ──────────────────────────
-- Confirms values fall within expected business ranges
SELECT
    MIN(Age)                          AS age_min,
    MAX(Age)                          AS age_max,
    MIN(Tenure_in_Months)             AS tenure_min,
    MAX(Tenure_in_Months)             AS tenure_max,
    MIN(Number_of_Referrals)          AS referrals_min,
    MAX(Number_of_Referrals)          AS referrals_max,
    MIN(Monthly_Charge)               AS monthly_charge_min,    -- expect negatives here
    MAX(Monthly_Charge)               AS monthly_charge_max,
    MIN(Total_Charges)                AS total_charges_min,
    MAX(Total_Charges)                AS total_charges_max,
    MIN(Total_Revenue)                AS total_revenue_min,
    MAX(Total_Revenue)                AS total_revenue_max,
    MIN(Total_Refunds)                AS refunds_min,
    MAX(Total_Refunds)                AS refunds_max,
    MIN(Total_Extra_Data_Charges)     AS extra_data_min,
    MAX(Total_Extra_Data_Charges)     AS extra_data_max,
    MIN(Total_Long_Distance_Charges)  AS long_dist_min,
    MAX(Total_Long_Distance_Charges)  AS long_dist_max
FROM tbl_churn_raw;


-- ── 4.8  Flag Known Data Anomalies (not cleaning — just surfacing) ──
-- Negative Monthly Charges: data quality issue identified in analysis
SELECT
    Customer_ID,
    Monthly_Charge,
    Total_Charges,
    Total_Revenue,
    Customer_Status
FROM tbl_churn_raw
WHERE Monthly_Charge < 0
ORDER BY Monthly_Charge ASC;


-- ── 4.9  Verify Churn Columns Are Blank Only for Non-Churned Rows ─
-- Churned rows must have a Churn_Category; non-churned rows must not
SELECT
    Customer_Status,
    SUM(CASE WHEN Churn_Category = '' OR Churn_Category IS NULL THEN 1 ELSE 0 END) AS blank_churn_category,
    SUM(CASE WHEN Churn_Reason   = '' OR Churn_Reason   IS NULL THEN 1 ELSE 0 END) AS blank_churn_reason,
    COUNT(*)                                                                         AS total
FROM tbl_churn_raw
GROUP BY Customer_Status;


-- ── 4.10  Spot-Check: Specific Known Records ─────────────────
-- Validate 3 specific rows against the source CSV manually
SELECT Customer_ID, Gender, Age, Contract, Monthly_Charge, Customer_Status, Churn_Reason
FROM tbl_churn_raw
WHERE Customer_ID IN ('19877-DEL', '25063-WES', '58353-MAH');


-- ── 4.11  Count of Internet Add-On Blanks vs. Internet_Service ─
-- Structural validation: add-on blanks should equal non-internet rows
SELECT
    Internet_Service,
    COUNT(*)                                           AS customers,
    SUM(CASE WHEN Online_Security = '' OR Online_Security IS NULL THEN 1 ELSE 0 END) AS blank_online_security
FROM tbl_churn_raw
GROUP BY Internet_Service;


-- ── 4.12  Import Summary Report ──────────────────────────────
-- Single-query sanity dashboard for import sign-off
SELECT
    (SELECT COUNT(*)           FROM tbl_churn_raw)                                                         AS total_rows,
    (SELECT COUNT(DISTINCT Customer_ID) FROM tbl_churn_raw)                                                AS unique_customers,
    (SELECT COUNT(*) FROM tbl_churn_raw WHERE Customer_Status = 'Churned')                                 AS churned,
    (SELECT COUNT(*) FROM tbl_churn_raw WHERE Customer_Status = 'Stayed')                                  AS stayed,
    (SELECT COUNT(*) FROM tbl_churn_raw WHERE Customer_Status = 'Joined')                                  AS joined,
    (SELECT COUNT(*) FROM tbl_churn_raw WHERE Monthly_Charge < 0)                                          AS negative_charge_rows,
    (SELECT COUNT(*) FROM tbl_churn_raw WHERE Customer_Status = 'Churned' AND (Churn_Category = '' OR Churn_Category IS NULL)) AS churned_missing_category,
    (SELECT COUNT(*) FROM tbl_churn_raw gr1
     JOIN (SELECT Customer_ID FROM tbl_churn_raw GROUP BY Customer_ID HAVING COUNT(*) > 1) dups
     ON gr1.Customer_ID = dups.Customer_ID)                                                                AS duplicate_id_rows;
