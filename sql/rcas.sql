SELECT 
    MIN(Monetary) AS Min_Monetary,
    MAX(Monetary) AS Max_Monetary,
    ROUND(AVG(Monetary),2) AS Avg_Monetary
FROM rfm_analysis;