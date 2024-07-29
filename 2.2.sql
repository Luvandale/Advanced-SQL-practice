  -- Enrich 2.1 query with the cumulative_sum of the total amount with tax earned per country & region.
  -- CTE (OrderSummary): calculates the total amount and other metrics for each month, country, and region
WITH
  OrderSummary AS (
  SELECT
    LAST_DAY(DATE(TIMESTAMP_TRUNC(SalesOrderHeader.OrderDate, MONTH))) AS order_month,
    SalesTerritory.CountryRegionCode AS CountryRegionCode,
    SalesTerritory.Name AS Region,
    COUNT(DISTINCT SalesOrderHeader.SalesOrderID) AS NumberOfOrders,
    COUNT(DISTINCT SalesOrderHeader.CustomerID) AS NumberOfCustomers,
    COUNT(DISTINCT SalesOrderHeader.SalesPersonID) AS NumberOfSalesPersons,
    ROUND(CAST(SUM(SalesOrderHeader.TotalDue)AS DECIMAL),0) AS TotalAmount
  FROM
    `tc-da-1.adwentureworks_db.salesorderheader` SalesOrderHeader
  JOIN
    `tc-da-1.adwentureworks_db.customer` Customer
  ON
    SalesOrderHeader.CustomerID = Customer.CustomerID
  JOIN
    `tc-da-1.adwentureworks_db.salesterritory` SalesTerritory
  ON
    SalesOrderHeader.TerritoryID = SalesTerritory.TerritoryID
  GROUP BY
    order_month,
    SalesTerritory.CountryRegionCode,
    SalesTerritory.Name )
SELECT
  order_month,
  CountryRegionCode,
  Region,
  NumberOfOrders,
  NumberOfCustomers,
  NumberOfSalesPersons,
  TotalAmount,
  -- Cumulative Total Amount Calculation:
  SUM(TotalAmount) OVER (PARTITION BY CountryRegionCode, Region ORDER BY order_month) AS CumulativeTotalAmount
FROM
  OrderSummary
ORDER BY
  CountryRegionCode,
  Region,
  order_month;
