/*
 * Enterprise Sales Data Warehouse
 * Project #31 - Multi-branch Sales Analytics
 * SQL Server 2008, Star Schema, SSIS
 * Created: 2012
 */

USE master;
GO
CREATE DATABASE SalesDW;
GO
USE SalesDW;
GO

-- Dimension: Date
CREATE TABLE dbo.DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    DayOfWeek INT,
    DayName VARCHAR(10),
    DayOfMonth INT,
    DayOfYear INT,
    WeekOfYear INT,
    MonthNumber INT,
    MonthName VARCHAR(10),
    Quarter INT,
    QuarterName VARCHAR(2),
    Year INT,
    IsWeekend BIT,
    IsHoliday BIT DEFAULT 0
);

-- Dimension: Product
CREATE TABLE dbo.DimProduct (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    ProductCode VARCHAR(30) NOT NULL,
    ProductName VARCHAR(200) NOT NULL,
    CategoryName VARCHAR(100),
    SubCategoryName VARCHAR(100),
    UnitPrice DECIMAL(18,2),
    CostPrice DECIMAL(18,2),
    EffectiveDate DATE NOT NULL,
    ExpiryDate DATE NULL,
    IsCurrent BIT DEFAULT 1
);

-- Dimension: Customer
CREATE TABLE dbo.DimCustomer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    CustomerCode VARCHAR(20) NOT NULL,
    CustomerName VARCHAR(200) NOT NULL,
    CustomerType VARCHAR(20),
    City VARCHAR(50),
    State VARCHAR(50),
    Country VARCHAR(50),
    EffectiveDate DATE NOT NULL,
    ExpiryDate DATE NULL,
    IsCurrent BIT DEFAULT 1
);

-- Dimension: Branch
CREATE TABLE dbo.DimBranch (
    BranchKey INT IDENTITY(1,1) PRIMARY KEY,
    BranchID INT NOT NULL,
    BranchCode VARCHAR(10) NOT NULL,
    BranchName VARCHAR(100) NOT NULL,
    City VARCHAR(50),
    State VARCHAR(50),
    Region VARCHAR(50),
    ManagerName VARCHAR(100),
    EffectiveDate DATE NOT NULL,
    ExpiryDate DATE NULL,
    IsCurrent BIT DEFAULT 1
);

-- Dimension: Sales Representative
CREATE TABLE dbo.DimSalesRep (
    SalesRepKey INT IDENTITY(1,1) PRIMARY KEY,
    SalesRepID INT NOT NULL,
    EmployeeCode VARCHAR(20) NOT NULL,
    SalesRepName VARCHAR(100) NOT NULL,
    BranchName VARCHAR(100),
    Territory VARCHAR(100),
    EffectiveDate DATE NOT NULL,
    ExpiryDate DATE NULL,
    IsCurrent BIT DEFAULT 1
);

-- Fact: Sales Transactions
CREATE TABLE dbo.FactSales (
    SalesKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL,
    ProductKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    BranchKey INT NOT NULL,
    SalesRepKey INT NOT NULL,
    TransactionNumber VARCHAR(30) NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    DiscountAmount DECIMAL(18,2) DEFAULT 0,
    TaxAmount DECIMAL(18,2) DEFAULT 0,
    SalesAmount DECIMAL(18,2) NOT NULL,
    CostAmount DECIMAL(18,2) NOT NULL,
    ProfitAmount AS (SalesAmount - CostAmount),
    FOREIGN KEY (DateKey) REFERENCES dbo.DimDate(DateKey),
    FOREIGN KEY (ProductKey) REFERENCES dbo.DimProduct(ProductKey),
    FOREIGN KEY (CustomerKey) REFERENCES dbo.DimCustomer(CustomerKey),
    FOREIGN KEY (BranchKey) REFERENCES dbo.DimBranch(BranchKey),
    FOREIGN KEY (SalesRepKey) REFERENCES dbo.DimSalesRep(SalesRepKey)
);

-- Fact: Daily Sales Summary
CREATE TABLE dbo.FactDailySales (
    DailySalesKey INT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL,
    BranchKey INT NOT NULL,
    TransactionCount INT DEFAULT 0,
    TotalQuantity INT DEFAULT 0,
    TotalSalesAmount DECIMAL(18,2) DEFAULT 0,
    TotalCostAmount DECIMAL(18,2) DEFAULT 0,
    TotalProfitAmount DECIMAL(18,2) DEFAULT 0,
    FOREIGN KEY (DateKey) REFERENCES dbo.DimDate(DateKey),
    FOREIGN KEY (BranchKey) REFERENCES dbo.DimBranch(BranchKey),
    UNIQUE (DateKey, BranchKey)
);

-- Create Indexes for Performance
CREATE INDEX IX_FactSales_Date ON dbo.FactSales(DateKey);
CREATE INDEX IX_FactSales_Product ON dbo.FactSales(ProductKey);
CREATE INDEX IX_FactSales_Customer ON dbo.FactSales(CustomerKey);
CREATE INDEX IX_FactSales_Branch ON dbo.FactSales(BranchKey);
CREATE INDEX IX_FactSales_SalesRep ON dbo.FactSales(SalesRepKey);

-- Populate Date Dimension (2011-2015)
DECLARE @StartDate DATE = '2011-01-01';
DECLARE @EndDate DATE = '2015-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO dbo.DimDate (
        DateKey, FullDate, DayOfWeek, DayName, DayOfMonth, DayOfYear,
        WeekOfYear, MonthNumber, MonthName, Quarter, QuarterName, Year, IsWeekend
    )
    VALUES (
        CONVERT(INT, CONVERT(VARCHAR(8), @StartDate, 112)),
        @StartDate,
        DATEPART(WEEKDAY, @StartDate),
        DATENAME(WEEKDAY, @StartDate),
        DAY(@StartDate),
        DATEPART(DAYOFYEAR, @StartDate),
        DATEPART(WEEK, @StartDate),
        MONTH(@StartDate),
        DATENAME(MONTH, @StartDate),
        DATEPART(QUARTER, @StartDate),
        'Q' + CAST(DATEPART(QUARTER, @StartDate) AS VARCHAR(1)),
        YEAR(@StartDate),
        CASE WHEN DATEPART(WEEKDAY, @StartDate) IN (1, 7) THEN 1 ELSE 0 END
    );
    
    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END

PRINT 'Sales Data Warehouse created successfully';
GO
