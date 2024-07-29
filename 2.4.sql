  -- Enrich 2.3 query by adding taxes on a country level:
  -- As taxes can vary in country based on province, the needed column is ‘mean_tax_rate’ -> average tax rate in a country.
  -- Also, as not all regions have data on taxes, you also want to be transparent and show the ‘perc_provinces_w_tax’ -> a column representing the percentage of provinces with available tax rates for each country (i.e. If US has 53 provinces, and 10 of them have tax rates, then for US it should show 0,19)
  -- Calculates monthly order summaries.
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
    SalesTerritory.Name ),

  TaxSummary AS (
  SELECT
    StateProvince.CountryRegionCode,
    StateProvince.StateProvinceID,
    MAX(SalestaxRate.TaxRate) AS Max_tax_rate,
  FROM
    tc-da-1.adwentureworks_db.stateprovince StateProvince
  LEFT JOIN
    tc-da-1.adwentureworks_db.salestaxrate SalestaxRate
  ON
    SalestaxRate.StateProvinceID = StateProvince.StateProvinceID
  GROUP BY
    StateProvince.CountryRegionCode,
    StateProvince.StateProvinceID ),
  --  - Calculates the average tax rate (mean_tax_rate) per country.
  --  - Calculates the percentage of provinces with available tax rates (perc_provinces_w_tax) per country
  Countrytax AS(
  SELECT
    CountryRegionCode,
    ROUND(AVG(Max_tax_rate),2) AS mean_tax_rate,
    ROUND(COUNTIF(Max_tax_rate IS NOT NULL) / COUNT(*), 2) AS perc_provinces_w_tax
  FROM
    TaxSummary
  GROUP BY
    CountryRegionCode )
SELECT
  OrderSummary.order_month,
  OrderSummary.CountryRegionCode,
  OrderSummary.Region,
  OrderSummary.NumberOfOrders,
  OrderSummary.NumberOfCustomers,
  OrderSummary.NumberOfSalesPersons,
  OrderSummary.TotalAmount,
  RANK() OVER (PARTITION BY OrderSummary.CountryRegionCode, OrderSummary.Region ORDER BY OrderSummary.TotalAmount DESC) AS sales_rank,
  SUM(OrderSummary.TotalAmount) OVER (PARTITION BY OrderSummary.CountryRegionCode, OrderSummary.Region ORDER BY OrderSummary.order_month) AS CumulativeTotalAmount,
  Countrytax.mean_tax_rate,
  Countrytax.perc_provinces_w_tax
FROM
  OrderSummary OrderSummary
JOIN
  Countrytax Countrytax
ON
  OrderSummary.CountryRegionCode = Countrytax.CountryRegionCode ;
