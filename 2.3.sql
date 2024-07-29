-- Enrich 2.2 query by adding ‘sales_rank’ column that ranks rows from best to worst for each country based on total amount with tax earned each month. I.e. the month where the (US, Southwest) region made the highest total amount with tax earned will be ranked 1 for that region and vice versa.
WITH OrderSummary AS (
    SELECT 
    LAST_DAY(DATE(TIMESTAMP_TRUNC(SalesOrderHeader.OrderDate, MONTH))) AS order_month,
    SalesTerritory.CountryRegionCode AS CountryRegionCode,
    SalesTerritory.Name AS Region,
    COUNT(DISTINCT SalesOrderHeader.SalesOrderID) AS NumberOfOrders,
    COUNT(DISTINCT SalesOrderHeader.CustomerID) AS NumberOfCustomers,
    COUNT(DISTINCT SalesOrderHeader.SalesPersonID) AS NumberOfSalesPersons,
    ROUND((SUM(SalesOrderHeader.TotalDue)),0) AS TotalAmount
FROM 
   `tc-da-1.adwentureworks_db.salesorderheader` SalesOrderHeader
JOIN 
    `tc-da-1.adwentureworks_db.customer` Customer ON SalesOrderHeader.CustomerID = Customer.CustomerID
JOIN 
    `tc-da-1.adwentureworks_db.salesterritory` SalesTerritory ON SalesOrderHeader.TerritoryID = SalesTerritory.TerritoryID
GROUP BY 
    order_month, 
    SalesTerritory.CountryRegionCode, 
    SalesTerritory.Name
)
SELECT 
    order_month,
    CountryRegionCode,
    Region,
    NumberOfOrders,
    NumberOfCustomers,
    NumberOfSalesPersons,
    TotalAmount,
-- The RANK() function assigns a rank based on the TotalAmount for each CountryRegionCode and Region, ordering from highest to lowest (DESC).
-- The PARTITION BY clause ensures that the ranking is done separately for each CountryRegionCode and Region.
    RANK() OVER (PARTITION BY CountryRegionCode, Region ORDER BY TotalAmount DESC) AS sales_rank,
    SUM(TotalAmount) OVER (PARTITION BY CountryRegionCode, Region ORDER BY order_month) AS CumulativeTotalAmount,
  
FROM 
    OrderSummary
ORDER BY 
    CountryRegionCode, Region, order_month;
