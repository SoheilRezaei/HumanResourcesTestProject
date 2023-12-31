--/*
USE MASTER;
GO
--*/

CREATE DATABASE HumanResources;
GO

USE HumanResources
GO

CREATE TABLE dbo.Departments(
	DepartmentID INT IDENTITY CONSTRAINT PK_Department PRIMARY KEY,
	DepartmentName NVARCHAR(150) NOT NULL, --UNIQUE | ADD CONSTRAINT | OPTIMIZE
	StreetAddress NVARCHAR(100) NOT NULL,
	City NVARCHAR(60) NOT NULL,
	Province NVARCHAR(50) NOT NULL,
	PostalCode CHAR(6) NOT NULL,
	MaxWorkstations INT NOT NULL -- DEFAULT 1  | ADD CONSTRAINT
);

CREATE TABLE dbo.PhoneTypes(
	PhoneTypeID INT IDENTITY CONSTRAINT PK_PhoneTypes PRIMARY KEY,
	PhoneType NVARCHAR(50) NOT NULL,
);
  
CREATE TABLE dbo.Employees(
	EmployeeID INT IDENTITY CONSTRAINT PK_Employee PRIMARY KEY,
	FirstName NVARCHAR(50) NOT NULL,
	MiddleName NVARCHAR(50) NULL,
	LastName NVARCHAR(50) NOT NULL,
	DateofBirth DATE NOT NULL, -- <= GETDATE() | ADD CONSTRAINT 
	SIN char(9) NOT NULL, -- UNIQUE | ADD CONSTRAINT | OPTIMIZE
	DefaultDepartmentID  INT NOT NULL CONSTRAINT FK_Employee_Department_Default REFERENCES dbo.Departments ( DepartmentID ),
	CurrentDepartmentID  INT NOT NULL CONSTRAINT FK_Employee_Department_Current REFERENCES dbo.Departments ( DepartmentID ),
	ReportsToEmployeeID INT NULL CONSTRAINT FK_Employee_ReportsTo REFERENCES dbo.Employees ( EmployeeID ),
	StreetAddress NVARCHAR(100) NULL,
	City NVARCHAR(60) NULL,
	Province NVARCHAR(50) NULL,
	PostalCode CHAR(6) NULL,
	StartDate  DATE NOT NULL,  -- <= GETDATE() | ADD CONSTRAINT
	BaseSalary decimal(18, 2) NOT NULL -- DEFAULT 0 | ADD CONSTRAINT
-- 	BonusPercent decimal(3, 2) NOT NULL -- Best not to Store, as this Can be calculated from Employee data
);

CREATE TABLE dbo.EmployeePhoneNumbers(
	EmployeePhoneNumberID INT IDENTITY CONSTRAINT PK_EmployeePhoneNumbers PRIMARY KEY,
	EmployeeID INT NOT NULL CONSTRAINT FK_EmployeePhoneNumbers_Employee REFERENCES dbo.Employees ( EmployeeID ),
	PhoneTypeID INT NOT NULL CONSTRAINT FK_EmployeePhoneNumbers_PhoneTypes REFERENCES dbo.PhoneTypes (PhoneTypeID ),
	PhoneNumber NVARCHAR(14) NULL
); 

CREATE TABLE dbo.BenefitType(
	BenefitTypeID INT IDENTITY CONSTRAINT PK_BenefitType PRIMARY KEY, 
	BenefitType NVARCHAR(100) NOT NULL,
	BenefitCompanyName NVARCHAR(100) NOT NULL,
    PolicyNumber INT NULL -- UNIQUE | ADD CONSTRAINT | OPTIMIZE
);

CREATE TABLE dbo.EmployeeBenefits(
	EmployeeBenefitID INT IDENTITY CONSTRAINT PK_EmployeeBenefits PRIMARY KEY, 
	EmployeeId INT NOT NULL CONSTRAINT FK_Employee REFERENCES dbo.Employees ( EmployeeID ),
	BenefitTypeID INT NOT NULL CONSTRAINT FK_BenefitType REFERENCES dbo.BenefitType ( BenefitTypeID  ),
    StartDate DATE NULL -- <= GETDATE() | ADD CONSTRAINT
);

CREATE TABLE dbo.Providers (
	ProviderID INT IDENTITY CONSTRAINT PK_Providers PRIMARY KEY, 
	ProviderName  NVARCHAR(50) NOT NULL,
	ProviderAddress NVARCHAR(60) NOT NULL,
	ProviderCity NVARCHAR(50) NOT NULL,
);

CREATE TABLE dbo.Claims(
	ClaimsID INT IDENTITY CONSTRAINT PK_Claims PRIMARY KEY, 
	ProviderID INT NOT NULL CONSTRAINT FK_Provider REFERENCES dbo.Providers ( ProviderID ),
	ClaimAmount decimal(18, 2) NOT NULL, -- DEFAULT 0 | ADD CONSTRAINT
	ServiceDate DATE NOT NULL, -- DEFAULT GETDATE(), CHECK <= GETDATE() | ADD CONSTRAINTS 
	EmployeeBenefitID INT NULL CONSTRAINT FK_Claims_EmployeeBenefits REFERENCES dbo.EmployeeBenefits ( EmployeeBenefitID ),
	ClaimDate DATE NOT NULL -- DEFAULT GETDATE(), CHECK <= GETDATE() | ADD CONSTRAINT
);

GO



------------------------------------------------------------------------------------------------------------------------------------------------------



-- check constraint : https://learn.microsoft.com/en-us/sql/relational-databases/tables/create-check-constraints?view=sql-server-ver15

ALTER TABLE dbo.Employees
ADD CONSTRAINT UQ_Employee_SIN UNIQUE (SIN),
    CONSTRAINT DF_Employee_BaseSalary DEFAULT 0 FOR BaseSalary,
    CONSTRAINT CK_Employee_StartDate CHECK (StartDate <= GETDATE()),
	CONSTRAINT CK_Employee_DateofBirth CHECK (DateofBirth <= GETDATE());
GO

ALTER TABLE dbo.Departments
ADD CONSTRAINT CK_Department_MaxWorkstations CHECK (MaxWorkstations >= 0),
	CONSTRAINT DF_Department_MaxWorkstations DEFAULT 1 FOR MaxWorkstations,
	CONSTRAINT UQ_Department_DepartmentName UNIQUE (DepartmentName);
GO

ALTER TABLE dbo.Claims
ADD CONSTRAINT DF_Claims_ClaimAmount DEFAULT 0 FOR ClaimAmount,
	CONSTRAINT DF_Claims_ServiceDate DEFAULT GETDATE() FOR ServiceDate,
	CONSTRAINT DF_Claims_ClaimDate DEFAULT GETDATE() FOR ClaimDate,
	CONSTRAINT CK_Claims_ServiceDate CHECK (ServiceDate <= GETDATE()),
	CONSTRAINT CK_Claims_ClaimDate CHECK (ClaimDate <= GETDATE());
GO

ALTER TABLE dbo.EmployeeBenefits
ADD CONSTRAINT CK_EmployeeBenefits_StartDate CHECK (StartDate <= GETDATE());
GO

ALTER TABLE dbo.BenefitType
ADD CONSTRAINT UQ_BenefitType_PolicyNumber UNIQUE (PolicyNumber);
GO

-- creating index : https://learn.microsoft.com/en-us/sql/relational-databases/indexes/create-indexes-with-included-columns?view=sql-server-ver16


-- CREATE NONCLUSTERED INDEX IX_Employee_SIN ON dbo.Employees (SIN);

-- CREATE NONCLUSTERED INDEX IX_Department_DepartmentName ON dbo.Departments (DepartmentName);

-- CREATE NONCLUSTERED INDEX IX_BenefitType_PolicyNumber ON dbo.BenefitType (PolicyNumber);

-- There is no need to add the indexes above as the dbms already has created them

--OPTIMIZE THE FOLLOWING 3 QUERIES :

--SELECT City, PostalCode
--FROM dbo.Departments
--ORDER BY City, PostalCode;

--SELECT *
--FROM dbo.Departments
--WHERE City = '@city';

--SELECT *
--FROM dbo.Departments
--WHERE PostalCode = '@postalCode';

-- Create the non-clustered index on the City column
-- CREATE INDEX IX_Departments_City ON dbo.Departments (City)

-- Create the non-clustered index on the PostalCode column alone
CREATE NONCLUSTERED INDEX IX_Departments_PostalCode ON dbo.Departments (PostalCode)

-- to avoid repeating indexes we only need to write the following index once
-- for the first and second queries:
CREATE NONCLUSTERED INDEX IX_Departments_City_PostalCode ON dbo.Departments (City, PostalCode)

GO



-- covering index for Employees/EmployeePhoneNumbers/PhoneTypes table
CREATE NONCLUSTERED INDEX IX_EmployeePhoneNumbers_EmployeeID_PhoneTypeID
ON dbo.EmployeePhoneNumbers (EmployeeID, PhoneTypeID)

-- covering index for PhoneTypes/EmployeePhoneNumbers/Employees table
CREATE NONCLUSTERED INDEX IX_EmployeePhoneNumbers_PhoneTypeID_EmployeeID
ON dbo.EmployeePhoneNumbers (PhoneTypeID, EmployeeID)

-- covering index for BenefitTypes/EmployeeBenefits/Employees table
CREATE NONCLUSTERED INDEX IX_EmployeeBenefits_EmployeeID_BenefitTypeID
ON dbo.EmployeeBenefits (EmployeeID, BenefitTypeID)

-- covering index for Employees/EmployeeBenefits/BenefitTypes table
CREATE NONCLUSTERED INDEX IX_EmployeeBenefits_BenefitTypeID_EmployeeID
ON dbo.EmployeeBenefits (BenefitTypeID, EmployeeID)

-- covering index for Providers/Claims/EmployeeBenefits table
CREATE NONCLUSTERED INDEX IX_Claims_ProviderID_EmployeeBenefitID
ON dbo.Claims (ProviderID, EmployeeBenefitID)

-- covering index for EmployeeBenefits/Claims/Providers table
CREATE NONCLUSTERED INDEX IX_Claims_EmployeeBenefitID_ProviderID
ON dbo.Claims (EmployeeBenefitID, ProviderID)
