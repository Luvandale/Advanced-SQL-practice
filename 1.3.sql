-- Enrich your original 1.1 SELECT by creating a new column in the view that marks active & inactive customers based on whether they have ordered anything during the last 365 days.
-- Copy only the top 500 rows from your written select ordered by CustomerId desc.
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
    (
    SELECT
    MAX(OrderDate) AS Currentdate
  FROM
    `tc-da-1.adwentureworks_db.salesorderheader`) Currentdate,
  FROM
    `tc-da-1.adwentureworks_db.salesorderheader` so
  GROUP BY
    so.CustomerID ) 
SELECT
  i.CustomerID,
  c.FirstName,
  c.LastName,
  CONCAT(c.Firstname, ' ', c.LastName) AS FullName,
  CASE
    WHEN c.Title IS NOT NULL THEN CONCAT(c.Title, ' ', c.LastName)
    ELSE CONCAT('Dear ', c.LastName)
END
  AS AddressingTitle,
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
  ROUND(co.TotalAmountWithTax, 3) AS TotalAmountTax,
  co.LastOrderDate,
  co.Currentdate,
  -- A new column CustomerStatus is created which checks if the customer's last order date is within the last 365 days. If it is, the customer is marked as 'Active', otherwise 'Inactive'.
  CASE
    WHEN DATETIME_DIFF( co.Currentdate, co.LastOrderDate, DAY) >= 365 THEN 'Inactive' ELSE 'Active'
END
  AS CutomerStatus
FROM
  `tc-da-1.adwentureworks_db.individual` i
JOIN `tc-da-1.adwentureworks_db.contact` c ON i.ContactID = c.ContactID
JOIN `tc-da-1.adwentureworks_db.customer` cust ON i.CustomerID = cust.CustomerID
LEFT JOIN LatestAddress la ON i.CustomerID = la.CustomerID
LEFT JOIN CustomerOrders co ON i.CustomerID = co.CustomerID
WHERE
  cust.CustomerType = 'I'
  -- The query is limited to the top 500 rows, ordered by CustomerID in descending order.
ORDER BY
  i.CustomerID DESC
LIMIT
  500;
