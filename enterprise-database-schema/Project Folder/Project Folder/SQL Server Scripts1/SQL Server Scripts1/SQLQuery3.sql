Use AdventureWorks2022
go
----//VIEWS//----

---- Creating a view to display the full contact details of Persons

--CREATE VIEW vw_FullPersonContactDetails AS
--SELECT 
--    p.BusinessEntityID,  -- Unique identifier for each person
--    p.FirstName + ' ' + p.LastName AS FullName,  -- Combine first and last name
--    ea.EmailAddress,  
--    ph.PhoneNumber,  
--    at.Name AS AddressType,  
--    a.AddressLine1 + ', ' + a.City + ', ' + sp.Name AS FullAddress  -- Full formatted address
--FROM Person.Person p
--LEFT JOIN Person.EmailAddress ea ON p.BusinessEntityID = ea.BusinessEntityID  -- Join email
--LEFT JOIN Person.PersonPhone ph ON p.BusinessEntityID = ph.BusinessEntityID 
--LEFT JOIN Person.BusinessEntityAddress bea ON p.BusinessEntityID = bea.BusinessEntityID  -- Join address link table
--LEFT JOIN Person.Address a ON bea.AddressID = a.AddressID  -- Get actual address
--LEFT JOIN Person.AddressType at ON bea.AddressTypeID = at.AddressTypeID  -- Get address type
--LEFT JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID;  

-- SELECT *
-- FROM vw_FullPersonContactDetails

--Creating a view to see the inventory of products per location available

--CREATE VIEW vw_InventoryByLocation AS
--SELECT 
--    p.Name AS ProductName,  -- Product name
--    l.Name AS LocationName,  -- Location where stored
--    pi.Shelf,  -- Shelf in warehouse
--    pi.Bin,  -- Bin in warehouse
--    pi.Quantity  -- Quantity available
--FROM Production.Product p
--JOIN Production.ProductInventory pi ON p.ProductID = pi.ProductID  -- Inventory table
--JOIN Production.Location l ON pi.LocationID = l.LocationID;  -- Get location name

-- SELECT *
-- FROM vw_InventoryByLocation

-- Creating a View to display a Detailed bill of materials

--CREATE VIEW vw_BillOfMaterialsDetails AS
--SELECT 
--    b.ProductAssemblyID,  -- ID of the assembled product
--    p1.Name AS ParentProduct,  -- Name of the parent (assembled) product
--    p2.Name AS ComponentProduct,  -- Name of the component product
--    b.PerAssemblyQty,  -- Quantity of component per assembly
--    b.BOMLevel,  -- Level of bill (hierarchical)
--    b.ModifiedDate  -- Last modified date
--FROM Production.BillOfMaterials b
--JOIN Production.Product p1 ON b.ProductAssemblyID = p1.ProductID
--JOIN Production.Product p2 ON b.ComponentID = p2.ProductID;

--SELECT *
--FROM vw_BillOfMaterialsDetails

---- Create or update the view for the top 10 best-selling products
--CREATE OR ALTER VIEW Top10BestSoldProducts AS
--SELECT TOP 10
--    p.Name AS ProductName,  -- Display the product name from the Product table
--    SUM(sode.OrderQty) AS TotalQuantitySold,  -- Sum total quantity sold for each product
--    COUNT(DISTINCT sode.SalesOrderID) AS NumberOfOrders  -- Count how many distinct orders included the product
--FROM
--    Sales.SalesOrderDetail sode  -- Sales order line items
--JOIN
--    Production.Product p ON sode.ProductID = p.ProductID  -- Join with Product table to get product names
--GROUP BY
--    p.Name  -- Group the results by product name to aggregate totals per product
--ORDER BY
--    TotalQuantitySold DESC;  -- Sort products by quantity sold, highest first

--//Queries//--

----Creating a query to view the TOP 5 most reviewed products
--SELECT TOP 5 
--    p.Name AS ProductName,  -- Product name
--    COUNT(pr.ProductReviewID) AS TotalReviews,  -- Count of reviews
--    AVG(pr.Rating) AS AvgRating  -- Average rating
--FROM Production.Product p
--JOIN Production.ProductReview pr ON p.ProductID = pr.ProductID  -- Join reviews
--GROUP BY p.Name  -- Group by product
--ORDER BY TotalReviews DESC, AvgRating DESC;  -- Order by most reviewed and best rated

-- This query calculates the average product rating per subcategory, only including products that have at least 3 reviews.

--SELECT 
--    psc.Name AS SubcategoryName,  -- Name of the product subcategory
--    COUNT(pr.ProductReviewID) AS TotalReviews,  -- Number of reviews
--    AVG(CAST(pr.Rating AS FLOAT)) AS AvgRating  -- Average rating (cast to float for precision)
--FROM 
--    Production.Product p
--JOIN 
--    Production.ProductReview pr ON p.ProductID = pr.ProductID
--JOIN 
--    Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
--GROUP BY 
--    psc.Name
--HAVING 
--    COUNT(pr.ProductReviewID) >= 3  -- Only include subcategories with 3+ reviews
--ORDER BY 
--    AvgRating DESC;  -- Show highest-rated subcategories first

-- This query finds the top 5 products with the highest inventory value (quantity × standard cost) across all warehouse locations.

--SELECT TOP 5
--    p.Name AS ProductName,  -- Product name
--    SUM(pi.Quantity) AS TotalQuantity,  -- Total stock quantity across locations
--    p.StandardCost,  -- Cost per unit
--    SUM(pi.Quantity * p.StandardCost) AS InventoryValue  -- Total inventory value
--FROM 
--    Production.Product p
--JOIN 
--    Production.ProductInventory pi ON p.ProductID = pi.ProductID
--GROUP BY 
--    p.Name, p.StandardCost
--ORDER BY 
--    InventoryValue DESC;  -- Show the most valuable products first

