-- Business would like to extract data on all active customers from North America. Only customers that have either ordered no less than 2500 in total amount (with Tax) or ordered 5 + times should be presented
WITH LatestAddress AS (
    SELECT 
        custaddress.CustomerID, 
        address.AddressID, 
        address.AddressLine1, 
        address.AddressLine2, 
        address.City, 
        statep.Name AS State, 
        countryr.Name AS Country, 
    FROM 
        `tc-da-1.adwentureworks_db.customeraddress` custaddress
    JOIN `tc-da-1.adwentureworks_db.address` address ON custaddress.AddressID = address.AddressID
    JOIN `tc-da-1.adwentureworks_db.stateprovince` statep ON address.StateProvinceID = statep.StateProvinceID
    JOIN `tc-da-1.adwentureworks_db.countryregion` countryr ON statep.CountryRegionCode = countryr.CountryRegionCode
),
CustomerOrders AS (
  SELECT
    so.CustomerID,
    COUNT(so.SalesOrderID) AS NumberOfOrders,
    SUM(so.TotalDue) AS TotalAmountWithTax,
    MAX(so.OrderDate) AS LastOrderDate,
    (SELECT MAX(OrderDate) FROM tc-da-1.adwentureworks_db.salesorderheader) AS Currentdate
  FROM
    tc-da-1.adwentureworks_db.salesorderheader so
  GROUP BY
    so.CustomerID
)
SELECT
  i.CustomerID,
  c.FirstName,
  c.LastName,
  CONCAT(c.FirstName, ' ', c.LastName) AS FullName,
  CASE
    WHEN c.Title IS NOT NULL THEN CONCAT(c.Title, ' ', c.LastName)
    ELSE CONCAT('Dear ', c.LastName)
  END AS AddressingTitle,
  c.EmailAddress,
  c.Phone,
  cust.AccountNumber,
  cust.CustomerType,
  la.City,
  la.State,
  la.Country,
  la.AddressLine1,
  la.AddressLine2,
  co.NumberOfOrders,
  ROUND(co.TotalAmountWithTax, 2) AS TotalAmountTax,
  co.LastOrderDate,
  co.Currentdate,
  CASE
    WHEN DATETIME_DIFF(co.Currentdate, co.LastOrderDate, DAY) >= 365 THEN 'Inactive'
    ELSE 'Active'
  END AS CustomerStatus
FROM
  tc-da-1.adwentureworks_db.individual i
JOIN tc-da-1.adwentureworks_db.contact c ON i.ContactID = c.ContactID
JOIN tc-da-1.adwentureworks_db.customer cust ON i.CustomerID = cust.CustomerID
LEFT JOIN LatestAddress la ON i.CustomerID = la.CustomerID
LEFT JOIN CustomerOrders co ON i.CustomerID = co.CustomerID

-- Ensured customers are from North America.
-- Active Customers Only by Adding co.CustomerStatus = 'Active'.
-- Filtering on Total Amount or Number of Orders: Added conditions for customers who have ordered at least 2500 in total amount or have made 5 or more orders.
-- Ordered the output by Country, State, and LastOrderDate.

WHERE
  cust.CustomerType = 'I'
  AND (co.TotalAmountWithTax >= 2500 OR co.NumberOfOrders >= 5)
  AND CASE
    WHEN DATETIME_DIFF(co.Currentdate, co.LastOrderDate, DAY) >= 365 THEN 'Inactive'
    ELSE 'Active'
  END = 'Active'
  AND la.Country = 'North America'
ORDER BY
  la.Country, la.State, co.LastOrderDate 
;
