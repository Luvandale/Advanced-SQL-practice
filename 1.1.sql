-- You’ve been tasked to create a detailed overview of all individual customers (these are defined by customerType = ‘I’ and/or stored in an individual table). Write a query that provides:
-- Identity information : CustomerId, Firstname, Last Name, FullName (First Name & Last Name).
-- An Extra column called addressing_title i.e. (Mr. Achong), if the title is missing - Dear Achong.
-- Contact information : Email, phone, account number, CustomerType.
-- Location information : City, State & Country, address.
-- Sales: number of orders, total amount (with Tax), date of the last order.
-- Copy only the top 200 rows from your written select ordered by total amount (with tax).

-- LatestAddress CTE: Identifies the latest address for each customer.
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
-- CustomerOrders: This CTE calculates the number of orders, total amount (with tax), and date of the last order for each customer.
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
-- Main Query:
-- Joins the Individual table with Contact, Customer, LatestAddress, and CustomerOrders.
-- Selects the required identity, contact, location, and sales information.
-- Orders the results by the total amount (with tax) in descending order.
-- Limits the output to the top 200 rows.
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
ORDER BY 
    custorders.TotalAmountWithTax DESC
-- LIMIT 200;
