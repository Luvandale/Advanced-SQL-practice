-- Create a query of monthly sales numbers in each Country & region. Include in the query a number of orders, customers and sales persons in each month with a total amount with tax earned. Sales numbers from all types of customers are required.

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
    `tc-da-1.adwentureworks_db.customer` Customer ON SalesOrderHeader.CustomerID = Customer.CustomerID
JOIN 
    `tc-da-1.adwentureworks_db.salesterritory` SalesTerritory ON SalesOrderHeader.TerritoryID = SalesTerritory.TerritoryID
GROUP BY 
    order_month, 
    SalesTerritory.CountryRegionCode, 
    SalesTerritory.Name
;
