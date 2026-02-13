/* =========================================================
   Retail Customer Analytics & Segmentation
   Author: Annika Crozier
   Description:
   End-to-end SQL pipeline for retail analytics and RFM-based
   customer segmentation.
   ========================================================= */


/* =========================================================
   1. Create Database
   ========================================================= */

CREATE DATABASE IF NOT EXISTS ecommerce_analytics;
USE ecommerce_analytics;


/* =========================================================
   2. Create Transactions Table
   ========================================================= */

DROP TABLE IF EXISTS transactions;

CREATE TABLE transactions (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INT,
    InvoiceDate VARCHAR(50),
    UnitPrice DOUBLE,
    CustomerID VARCHAR(20),
    Country VARCHAR(100)
);


/* =========================================================
   3. Data Validation Queries
   ========================================================= */

-- Check NULL or empty CustomerID
SELECT COUNT(*) AS Null_CustomerID_Count
FROM transactions
WHERE CustomerID IS NULL OR CustomerID = '';

-- Check negative quantities (returns)
SELECT COUNT(*) AS Negative_Quantity_Count
FROM transactions
WHERE Quantity < 0;

-- Check zero or negative prices
SELECT COUNT(*) AS Invalid_Price_Count
FROM transactions
WHERE UnitPrice <= 0;


/* =========================================================
   4. Clean Transactions View
   Removes invalid and incomplete records
   ========================================================= */

CREATE OR REPLACE VIEW clean_transactions AS
SELECT *
FROM transactions
WHERE CustomerID IS NOT NULL
AND CustomerID != ''
AND Quantity > 0
AND UnitPrice > 0;


/* =========================================================
   5. Business Transactions View (Revenue Calculation)
   ========================================================= */

CREATE OR REPLACE VIEW business_transactions AS
SELECT *,
       (Quantity * UnitPrice) AS Revenue
FROM clean_transactions;


/* =========================================================
   6. Total Revenue
   ========================================================= */

SELECT 
    ROUND(SUM(Revenue), 2) AS Total_Revenue
FROM business_transactions;


/* =========================================================
   7. Monthly Revenue Trend
   ========================================================= */

SELECT 
    DATE_FORMAT(
        STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i'),
        '%Y-%m'
    ) AS Month,
    ROUND(SUM(Revenue), 2) AS Monthly_Revenue
FROM business_transactions
GROUP BY Month
ORDER BY Month;


/* =========================================================
   8. Top 10 Products by Revenue
   (Excluding non-product entries)
   ========================================================= */

SELECT 
    Description,
    ROUND(SUM(Revenue), 2) AS Product_Revenue
FROM business_transactions
WHERE Description NOT IN ('POSTAGE', 'Manual')
GROUP BY Description
ORDER BY Product_Revenue DESC
LIMIT 10;


/* =========================================================
   9. Revenue by Country
   ========================================================= */

SELECT 
    Country,
    ROUND(SUM(Revenue), 2) AS Country_Revenue
FROM business_transactions
GROUP BY Country
ORDER BY Country_Revenue DESC;


/* =========================================================
   10. Top 10 High-Value Customers
   ========================================================= */

SELECT 
    CustomerID,
    ROUND(SUM(Revenue), 2) AS Total_Spent
FROM business_transactions
GROUP BY CustomerID
ORDER BY Total_Spent DESC
LIMIT 10;


/* =========================================================
   11. RFM Analysis View
   Recency, Frequency, Monetary
   ========================================================= */

CREATE OR REPLACE VIEW rfm_analysis AS
SELECT 
    CustomerID,

    -- Recency: Days since last purchase
    DATEDIFF(
        (SELECT MAX(STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i'))
         FROM business_transactions),
        MAX(STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i'))
    ) AS Recency,

    -- Frequency: Number of distinct invoices
    COUNT(DISTINCT InvoiceNo) AS Frequency,

    -- Monetary: Total revenue per customer
    ROUND(SUM(Revenue), 2) AS Monetary

FROM business_transactions
GROUP BY CustomerID;


/* =========================================================
   12. RFM Summary Statistics
   ========================================================= */

-- Recency distribution
SELECT 
    MIN(Recency) AS Min_Recency,
    MAX(Recency) AS Max_Recency,
    ROUND(AVG(Recency), 2) AS Avg_Recency
FROM rfm_analysis;

-- Frequency distribution
SELECT 
    MIN(Frequency) AS Min_Frequency,
    MAX(Frequency) AS Max_Frequency,
    ROUND(AVG(Frequency), 2) AS Avg_Frequency
FROM rfm_analysis;

-- Monetary distribution
SELECT 
    MIN(Monetary) AS Min_Monetary,
    MAX(Monetary) AS Max_Monetary,
    ROUND(AVG(Monetary), 2) AS Avg_Monetary
FROM rfm_analysis;
