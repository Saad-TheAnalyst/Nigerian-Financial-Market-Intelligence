-- ==============================================================================
-- NIGERIAN FINANCIAL MARKET INTELLIGENCE SYSTEM
-- Database: nse_db | Table: nse_analysis
-- Author: Data Science Team
-- Date: 2026-10-01
-- ==============================================================================

-- 1. Initialize Database
CREATE DATABASE IF NOT EXISTS nse_db;
USE nse_db;

-- 2. Table Schema Definition (nse_analysis)
CREATE TABLE IF NOT EXISTS nse_analysis (
    Date DATE NOT NULL,
    Price DOUBLE,
    Open DOUBLE,
    High DOUBLE,
    Low DOUBLE,
    Volume DOUBLE,
    Year INT,
    Month INT,
    Day INT,
    DayOfWeek INT,
    Daily_Return DOUBLE,
    MA7 DOUBLE,
    MA30 DOUBLE,
    MA90 DOUBLE,
    Volatility DOUBLE,
    Price_Range DOUBLE,
    Volume_Change DOUBLE,
    Target INT,
    PRIMARY KEY (Date)
);

-- ==============================================================================
-- STEP 9: ADVANCED SQL ANALYTICAL QUERIES
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 1: Average Yearly Return using GROUP BY
-- Business Objective: Determine historical performance, annual daily average returns,
-- cumulative annual returns, and yearly price ranges across the 12-year window.
-- ------------------------------------------------------------------------------
SELECT 
    Year, 
    COUNT(*) AS Trading_Days,
    ROUND(AVG(Daily_Return), 4) AS Avg_Daily_Return_Pct,
    ROUND(SUM(Daily_Return), 2) AS Cumulative_Daily_Return_Pct,
    ROUND(MIN(Price), 2) AS Lowest_Price,
    ROUND(MAX(Price), 2) AS Highest_Price
FROM nse_analysis
GROUP BY Year
ORDER BY Year ASC;

-- ------------------------------------------------------------------------------
-- Query 2: Best and Worst Performing Months using GROUP BY
-- Business Objective: Identify calendar seasonality effects to detect optimal entry
-- and exit months for quantitative equity asset allocation in Nigeria.
-- ------------------------------------------------------------------------------
SELECT 
    Month,
    ROUND(AVG(Daily_Return), 4) AS Avg_Daily_Return_Pct,
    ROUND(SUM(Daily_Return), 2) AS Total_Monthly_Return_Pct,
    COUNT(*) AS Total_Trading_Sessions
FROM nse_analysis
GROUP BY Month
ORDER BY Avg_Daily_Return_Pct DESC;

-- ------------------------------------------------------------------------------
-- Query 3: Bull and Bear Market Classification using CASE WHEN
-- Business Objective: Segment calendar years into Strong Bull, Mild Bull, Mild Bear,
-- and Severe Bear market regimes based on net annual index performance.
-- ------------------------------------------------------------------------------
WITH YearBounds AS (
    SELECT 
        Year,
        SUBSTRING_INDEX(GROUP_CONCAT(Price ORDER BY Date ASC), ',', 1) AS Open_Price,
        SUBSTRING_INDEX(GROUP_CONCAT(Price ORDER BY Date DESC), ',', 1) AS Close_Price
    FROM nse_analysis
    GROUP BY Year
)
SELECT 
    Year,
    ROUND(Open_Price, 2) AS Year_Open,
    ROUND(Close_Price, 2) AS Year_Close,
    ROUND(((Close_Price - Open_Price) / Open_Price) * 100, 2) AS Annual_Gain_Pct,
    CASE 
        WHEN ((Close_Price - Open_Price) / Open_Price) * 100 >= 20 THEN 'Strong Bull Market'
        WHEN ((Close_Price - Open_Price) / Open_Price) * 100 > 0 THEN 'Mild Bull Market'
        WHEN ((Close_Price - Open_Price) / Open_Price) * 100 <= -20 THEN 'Severe Bear Market'
        ELSE 'Mild Bear Market'
    END AS Market_Regime
FROM YearBounds
ORDER BY Year ASC;

-- ------------------------------------------------------------------------------
-- Query 4: Rolling 3-Year Performance using SQL Window Functions
-- Business Objective: Smooth short-term market noise and observe structural multi-year
-- capital growth trends across Nigerian economic cycles.
-- ------------------------------------------------------------------------------
WITH AnnualStats AS (
    SELECT 
        Year,
        ROUND(AVG(Daily_Return), 4) AS Yearly_Avg_Daily_Return,
        ROUND(SUM(Daily_Return), 2) AS Yearly_Total_Return
    FROM nse_analysis
    GROUP BY Year
)
SELECT 
    Year,
    Yearly_Avg_Daily_Return,
    Yearly_Total_Return,
    ROUND(AVG(Yearly_Total_Return) OVER (
        ORDER BY Year 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS Rolling_3Yr_Avg_Return,
    ROUND(SUM(Yearly_Total_Return) OVER (
        ORDER BY Year 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS Rolling_3Yr_Cumulative_Return
FROM AnnualStats
ORDER BY Year ASC;

-- ------------------------------------------------------------------------------
-- Query 5: Top 10 Highest Single-Day Gains using ORDER BY and LIMIT
-- Business Objective: Identify extreme single-day market rallies to examine catalyst
-- events (presidential election announcements, currency devaluations, bank recapitalizations).
-- ------------------------------------------------------------------------------
SELECT 
    Date,
    Price,
    Open,
    High,
    Low,
    ROUND(Daily_Return, 2) AS Daily_Gain_Pct,
    FORMAT(Volume, 0) AS Volume
FROM nse_analysis
ORDER BY Daily_Return DESC
LIMIT 10;
