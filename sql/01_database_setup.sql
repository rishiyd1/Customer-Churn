-- ============================================================
-- Script  : 01_database_setup.sql
-- Purpose : Create the database and raw table for Customer Churn Analysis
-- Author  : [Your Name]
-- Project : Customer Churn Analysis (SQL + Python + Power BI)
-- ============================================================

CREATE DATABASE IF NOT EXISTS customer_churn_db;
USE customer_churn_db;

-- Raw staging table (to be populated via CSV import)
CREATE TABLE IF NOT EXISTS customer_raw (
    Customer_ID                 VARCHAR(20),
    Gender                      VARCHAR(10),
    Age                         INT,
    Married                     VARCHAR(5),
    State                       VARCHAR(50),
    Number_of_Referrals         INT,
    Tenure_in_Months            INT,
    Value_Deal                  VARCHAR(20),
    Phone_Service               VARCHAR(5),
    Multiple_Lines              VARCHAR(25),
    Internet_Service            VARCHAR(5),
    Internet_Type               VARCHAR(20),
    Online_Security             VARCHAR(25),
    Online_Backup               VARCHAR(25),
    Device_Protection_Plan      VARCHAR(25),
    Premium_Support             VARCHAR(25),
    Streaming_TV                VARCHAR(25),
    Streaming_Movies            VARCHAR(25),
    Streaming_Music             VARCHAR(25),
    Unlimited_Data              VARCHAR(25),
    Contract                    VARCHAR(20),
    Paperless_Billing           VARCHAR(5),
    Payment_Method              VARCHAR(25),
    Monthly_Charge              DECIMAL(10,2),
    Total_Charges               DECIMAL(10,2),
    Total_Refunds               DECIMAL(10,2),
    Total_Extra_Data_Charges    DECIMAL(10,2),
    Total_Long_Distance_Charges DECIMAL(10,2),
    Total_Revenue               DECIMAL(10,2),
    Customer_Status             VARCHAR(15),
    Churn_Category              VARCHAR(30),
    Churn_Reason                VARCHAR(100)
);
