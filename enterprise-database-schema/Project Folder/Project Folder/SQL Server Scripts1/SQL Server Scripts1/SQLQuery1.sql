USE AdventureWorks2022
Go

--/* STORED PROCEDURES*/
--Stored Procedure 1 to add a new customer to the database
CREATE OR ALTER PROCEDURE spAddIndividualCustomer
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(100),
    @TerritoryID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Add to Person.BusinessEntity
    INSERT INTO Person.BusinessEntity (rowguid, ModifiedDate)
    VALUES (NEWID(), GETDATE());

    DECLARE @BusinessEntityID INT = SCOPE_IDENTITY();

    -- 2. Add to Person.Person
    INSERT INTO Person.Person (
        BusinessEntityID, FirstName, LastName, PersonType, EmailPromotion, rowguid, ModifiedDate
    )
    VALUES (
        @BusinessEntityID, @FirstName, @LastName, 'IN', 0, NEWID(), GETDATE()
    );

    -- 3. Add Email
    INSERT INTO Person.EmailAddress (
        BusinessEntityID, EmailAddress, rowguid, ModifiedDate
    )
    VALUES (
        @BusinessEntityID, @Email, NEWID(), GETDATE()
    );

    -- 4. Add to Sales.Customer (no AccountNumber input — it's computed)
    INSERT INTO Sales.Customer (
        PersonID, TerritoryID, rowguid, ModifiedDate
    )
    VALUES (
        @BusinessEntityID, @TerritoryID, NEWID(), GETDATE()
    );
END;

EXEC spAddIndividualCustomer
    @FirstName = 'Lebo',
    @LastName = 'Mokoena',
    @Email = 'LeboM@gmail.com',
    @TerritoryID = 1;

SELECT TOP 1 * 
FROM Sales.Customer
ORDER BY CustomerID DESC;


EXEC spAddIndividualCustomer
    @FirstName = 'Mufunwa',
    @LastName = 'Muofhe',
    @Email = 'Me32M@gmail.com',
    @TerritoryID = 2;

SELECT TOP 3 * 
FROM Sales.Customer
ORDER BY CustomerID DESC;

SELECT TOP 1 * 
FROM Person.Person
ORDER BY BusinessEntityID DESC;


--Stored Procedure 2 to look at different employee sales summaries by the year

CREATE PROCEDURE spEmployeeSalesSummary
    @EmployeeID INT,
    @Year INT
AS
BEGIN
    SELECT soh.SalesOrderID, CAST(soh.OrderDate AS DATE) AS 'Order Date', soh.TotalDue
    FROM Sales.SalesOrderHeader soh
    WHERE YEAR(soh.OrderDate) = @Year
      AND soh.SalesPersonID = @EmployeeID
    ORDER BY soh.OrderDate;
END;

EXEC spEmployeeSalesSummary
    @EmployeeID = 279,  --  SalesPersonID
    @Year = 2014;

EXEC spEmployeeSalesSummary
    @EmployeeID = 290,  -- Another SalesPersonID
    @Year = 2013;

GO

--Stored Procedure 3 to manage inventory levels
CREATE PROCEDURE spUpdateProductInventory
    @ProductID INT,
    @QuantityAdjustment INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE Production.ProductInventory
        SET Quantity = Quantity + @QuantityAdjustment
        WHERE ProductID = @ProductID;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO


/*TRIGGERS*/

-- A trigger to log new sales added to the salesorderheader table
--This table created records all audits made
CREATE TABLE SalesOrderAuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderID INT,
    InsertedBy NVARCHAR(100),
    InsertedAt DATETIME
)


CREATE TRIGGER trLogSalesOrderInsert
ON Sales.SalesOrderHeader
AFTER INSERT
AS
BEGIN
    INSERT INTO SalesOrderAuditLog (SalesOrderID, InsertedBy, InsertedAt)
    SELECT 
        i.SalesOrderID,
        SYSTEM_USER,
        GETDATE()
    FROM inserted i;
END;

-- Insert a new order
DECLARE @CustomerID INT = 11000; -- Customer from Person.Customer table
DECLARE @ShipMethodID INT = 1;   -- A valid shipping method
DECLARE @BillToAddressID INT = 4; -- A valid address ID
DECLARE @ShipToAddressID INT = 4; -- A valid address ID
DECLARE @SubTotal MONEY = 100.00;

INSERT INTO Sales.SalesOrderHeader (
    RevisionNumber, 
    OrderDate, 
    DueDate, 
    ShipDate,
    Status, 
    OnlineOrderFlag,
    PurchaseOrderNumber,
    AccountNumber,
    CustomerID, 
    SalesPersonID, 
    BillToAddressID, 
    ShipToAddressID,
    ShipMethodID
)
VALUES (
    0, 
    GETDATE(), 
    DATEADD(day, 7, GETDATE()), 
    DATEADD(day, 1, GETDATE()),
    1, -- In process
    1, -- Online order
    'PO18009876',
    'ADWCK00000', 
    @CustomerID,
    NULL, -- SalesPersonID can be null for online orders
    @BillToAddressID,
    @ShipToAddressID,
    @ShipMethodID
)

DECLARE @ID INT = 11001; -- Customer from Person.Customer table
DECLARE @ShipmentMethodID INT = 1;   -- A valid shipping method
DECLARE @BillingAddressID INT = 4; -- A valid address ID
DECLARE @ShippingAddressID INT = 4; -- A valid address ID
DECLARE @FullTotal MONEY = 200.00;

INSERT INTO Sales.SalesOrderHeader (
    RevisionNumber, 
    OrderDate, 
    DueDate, 
    ShipDate,
    Status, 
    OnlineOrderFlag,
    PurchaseOrderNumber,
    AccountNumber,
    CustomerID, 
    SalesPersonID, 
    BillToAddressID, 
    ShipToAddressID,
    ShipMethodID
)
VALUES (
    0, 
    GETDATE(), 
    DATEADD(day, 7, GETDATE()), 
    DATEADD(day, 1, GETDATE()),
    1, -- In process
    1, -- Online order
    'PO18009876',
    'ADWCK00000', 
    @ID,
    NULL, -- SalesPersonID can be null for online orders
    @BillingAddressID,
    @ShippingAddressID,
    @ShipmentMethodID
)

-- Check if the audit log recorded it
SELECT * FROM SalesOrderAuditLog WHERE SalesOrderID = SCOPE_IDENTITY();


--This is used to check if the trigger is properly installed.
SELECT * FROM sys.triggers WHERE name = 'trLogSalesOrderInsert';

GO

--LOGIN DETAILS
--Used to check if user server has permission to make changes to the database
SELECT SYSTEM_USER AS LoginName,
       IS_SRVROLEMEMBER('sysadmin') AS IsSysAdmin;


USE master;
GO

CREATE LOGIN NewAWUser
WITH PASSWORD = 'Str0ngP@ssword2025!', CHECK_POLICY = ON;
GO



USE AdventureWorks2022;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'NewAWUser')
    DROP USER NewAWUser;
GO

CREATE USER NewAWUser FOR LOGIN NewAWUser;
GO

ALTER ROLE db_datareader ADD MEMBER NewAWUser;
ALTER ROLE db_datawriter ADD MEMBER NewAWUser;
GRANT EXECUTE TO NewAWUser;
GO
GRANT SELECT ON Sales.Customer TO NewAWUser;
GRANT SELECT, UPDATE ON Production.Product TO NewAWUser;
GO

EXECUTE AS USER = 'NewAWUser';
SELECT USER_NAME() AS CurrentUser;

-- Permissions test
SELECT TOP 3 * FROM Sales.Customer;
SELECT TOP 3 * FROM Production.Product;

-- Expected to fail if not granted:

REVERT;
GO

--View used to select only the top selling products in the database

CREATE VIEW vTopSellingProducts AS
SELECT TOP 10 p.ProductID, p.Name, SUM(sod.OrderQty) AS TotalSold
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
GROUP BY p.ProductID, p.Name
ORDER BY TotalSold DESC;
GO

SELECT *
FROM vTopSellingProducts;


--DATABASE BACKUP
BACKUP DATABASE AdventureWorks2022
TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorks2022.bak'