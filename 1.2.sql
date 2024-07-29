-- Business finds the original query valuable to analyze customers and now want to get the data from the first query for the top 200 customers with the highest total amount (with tax) who have not ordered for the last 365 days. How would you identify this segment?

-- LatestAddress CTE: Retrieves the most recent address for each customer.
WITH LatestAddress AS (
    SELECT 
        custaddress.CustomerID, 
        address.AddressID, 
        address.AddressLine1, 
        address.AddressLine2, 
        address.City, 
        statep.Name AS State, 
        countryr.Name AS Country, 
        -- ROW_NUMBER() OVER (PARTITION BY ca.CustomerID ORDER BY a.AddressID DESC) AS rn
    FROM 
        `tc-da-1.adwentureworks_db.customeraddress` custaddress
    JOIN `tc-da-1.adwentureworks_db.address` address ON custaddress.AddressID = address.AddressID
    JOIN `tc-da-1.adwentureworks_db.stateprovince` statep ON address.StateProvinceID = statep.StateProvinceID
    JOIN `tc-da-1.adwentureworks_db.countryregion` countryr ON statep.CountryRegionCode = countryr.CountryRegionCode
)
-- CustomerOrders CTE: Aggregates orders for each customer, including the total amount with tax and the date of the last order
, CustomerOrders AS (
    SELECT
        salesorderheader.CustomerID,
        COUNT(salesorderheader.SalesOrderID) AS NumberOfOrders,
        SUM(salesorderheader.TotalDue) AS TotalAmountWithTax,
        MAX(salesorderheader.OrderDate) AS LastOrderDate
    FROM
       `tc-da-1.adwentureworks_db.salesorderheader`salesorderheader
    GROUP BY
        salesorderheader.CustomerID
)
-- FilteredCustomers CTE: Joins the individual and customer data with the latest address and order details, filtering out customers who have placed orders within the last 365 days.
, FilteredCustomers AS (
    SELECT 
   individual.CustomerID,
   contact.FirstName,
    contact.LastName,
    CONCAT(contact.Firstname, ' ',contact.LastName) AS FullName,
    CASE 
        WHEN contact.Title IS NOT NULL THEN CONCAT(contact.Title , ' ' , contact.LastName)
        ELSE CONCAT('Dear ' , contact.LastName)
    END AS AddressingTitle,
    contact.EmailAddress,
    contact.Phone,
    cust.AccountNumber,
    cust.CustomerType,
    latesta.City,
    latesta.State,
    latesta.Country,
    latesta.AddressLine1,
    latesta.AddressLine2,
    custorders.NumberOfOrders,
    ROUND(custorders.TotalAmountWithTax,3) AS TotalAmountTax,
    custorders.LastOrderDate
FROM 
    `tc-da-1.adwentureworks_db.individual` individual
JOIN `tc-da-1.adwentureworks_db.contact` contact ON individual.ContactID = contact.ContactID
JOIN `tc-da-1.adwentureworks_db.customer` cust ON individual.CustomerID = cust.CustomerID
LEFT JOIN LatestAddress latesta ON individual.CustomerID = latesta.CustomerID 
LEFT JOIN CustomerOrders custorders ON individual.CustomerID = custorders.CustomerID
WHERE 
    cust.CustomerType = 'I'
        AND custorders.LastOrderDate <= DATE_SUB((SELECT MAX(OrderDate) FROM tc-da-1.adwentureworks_db.salesorderheader), INTERVAL 365 DAY)
)
-- Main Query: Selects the top 200 customers with the highest total amount (with tax) from the FilteredCustomers
SELECT * FROM FilteredCustomers
ORDER BY TotalAmountTax DESC
LIMIT 200;
