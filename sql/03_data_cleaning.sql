-- ============================================================
-- Script  : 03_data_cleaning.sql
-- Purpose : Clean and standardize the raw data; create a clean view/table
-- Author  : [Your Name]
-- Project : Customer Churn Analysis
-- ============================================================

USE customer_churn_db;

-- Create the cleaned production table
CREATE TABLE IF NOT EXISTS customer_clean AS
SELECT
    Customer_ID,
    Gender,
    Age,
    Married,
    State,
    Number_of_Referrals,
    Tenure_in_Months,

    -- Fix blank Value_Deal
    CASE WHEN Value_Deal IS NULL OR Value_Deal = '' THEN 'No Deal' ELSE Value_Deal END AS Value_Deal,

    Phone_Service,

    -- Fix blank Multiple_Lines (when no phone)
    CASE WHEN Multiple_Lines IS NULL OR Multiple_Lines = '' THEN 'No Phone Service' ELSE Multiple_Lines END AS Multiple_Lines,

    Internet_Service,

    -- Fix blank Internet_Type (when no internet)
    CASE WHEN Internet_Type IS NULL OR Internet_Type = '' THEN 'No Internet Service' ELSE Internet_Type END AS Internet_Type,

    -- Fix all internet add-on columns
    CASE WHEN Online_Security            IS NULL OR Online_Security            = '' THEN 'No Internet Service' ELSE Online_Security            END AS Online_Security,
    CASE WHEN Online_Backup              IS NULL OR Online_Backup              = '' THEN 'No Internet Service' ELSE Online_Backup              END AS Online_Backup,
    CASE WHEN Device_Protection_Plan     IS NULL OR Device_Protection_Plan     = '' THEN 'No Internet Service' ELSE Device_Protection_Plan     END AS Device_Protection_Plan,
    CASE WHEN Premium_Support            IS NULL OR Premium_Support            = '' THEN 'No Internet Service' ELSE Premium_Support            END AS Premium_Support,
    CASE WHEN Streaming_TV               IS NULL OR Streaming_TV               = '' THEN 'No Internet Service' ELSE Streaming_TV               END AS Streaming_TV,
    CASE WHEN Streaming_Movies           IS NULL OR Streaming_Movies           = '' THEN 'No Internet Service' ELSE Streaming_Movies           END AS Streaming_Movies,
    CASE WHEN Streaming_Music            IS NULL OR Streaming_Music            = '' THEN 'No Internet Service' ELSE Streaming_Music            END AS Streaming_Music,
    CASE WHEN Unlimited_Data             IS NULL OR Unlimited_Data             = '' THEN 'No Internet Service' ELSE Unlimited_Data             END AS Unlimited_Data,

    Contract,
    Paperless_Billing,
    Payment_Method,

    -- Correct negative Monthly Charges
    CASE WHEN Monthly_Charge < 0 THEN ABS(Monthly_Charge) ELSE Monthly_Charge END AS Monthly_Charge,

    Total_Charges,
    Total_Refunds,
    Total_Extra_Data_Charges,
    Total_Long_Distance_Charges,
    Total_Revenue,

    Customer_Status,

    -- Fix blank Churn_Category and Churn_Reason for non-churned customers
    CASE WHEN Churn_Category IS NULL OR Churn_Category = '' THEN 'Not Applicable' ELSE Churn_Category END AS Churn_Category,
    CASE WHEN Churn_Reason   IS NULL OR Churn_Reason   = '' THEN 'Not Applicable' ELSE Churn_Reason   END AS Churn_Reason,

    -- Derived: Binary churn flag (for modeling)
    CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END AS Churn_Flag

FROM customer_raw;
