



CREATE PROCEDURE [dbo].[Sp_DeparmentInformation]
    @DepartmentName VARCHAR(50),
    @DepartmentDesc VARCHAR(100)
AS
BEGIN
BEGIN TRY
    INSERT INTO dbo.Departments
    (
        DepartmentName,
        DepartmentDesc
    )
    VALUES
    (@DepartmentName, @DepartmentDesc)
	END  TRY
    BEGIN CATCH
	SELECT ERROR_MESSAGE() AS ErrorMessage

	END CATCH
END



CREATE FUNCTION [dbo].[GetDepartmentIdByName]
(
    @DepartmentName NVARCHAR(50)
)
RETURNS INT
AS
BEGIN
    DECLARE @DepartmentId INT;
    BEGIN TRY
        SELECT @DepartmentId = DepartmentID
        FROM dbo.Departments
        WHERE DepartmentName = @DepartmentName;

        IF @DepartmentId IS NULL
        BEGIN 
            RETURN NULL;
        END 

        RETURN @DepartmentId;
    END TRY
    BEGIN CATCH
        -- Handle the error here
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN NULL;
    END CATCH
END


CREATE  PROCEDURE [dbo].[Sp_EmployeeInformation]
    @DepartmentName NVARCHAR(50),
    @EmployeeFirstName NVARCHAR(50),
    @EmployeeLastName NVARCHAR(50),
    @Salary money = 45000,
    @FileFolder NVARCHAR(256),
    @ManagerFirstName NVARCHAR(50),
    @ManagerLastName NVARCHAR(50),
    @CommissionBonus money = 1500
AS
BEGIN
    SET NOCOUNT ON;
	 BEGIN TRANSACTION;
	 BEGIN TRY;
    SET XACT_ABORT ON;
	DECLARE @departmentID INT;
    SELECT @departmentID = [dbo].[GetDepartmentIdByName](@DepartmentName);


    IF @departmentID IS NULL
    BEGIN
        INSERT INTO [dbo].[Departments]
        (
            DepartmentName,
            DepartmentDesc
        )
        VALUES
        (@DepartmentName, '');
    END

    DECLARE @managerID INT;
    SELECT @managerID = [dbo].[GetEmployeeID](@ManagerFirstName, @ManagerLastName);

    IF @managerID IS NULL
    BEGIN
        INSERT INTO dbo.Employees
        (
            FirstName,
            LastName
        )
        VALUES
        (@ManagerFirstName, @ManagerLastName);
    END

    INSERT INTO dbo.Employees
    (
        [DepartmentID],
        [ManagerEmployeeID],
        [FirstName],
        [LastName],
        [Salary],
        [CommissionBonus],
        [FileFolder]
    )
    VALUES
    (@departmentID, @managerID, @EmployeeFirstName, @EmployeeLastName, @Salary, @CommissionBonus, @FileFolder);
	 COMMIT TRANSACTION
	END TRY 
	  BEGIN CATCH
	IF @@ERROR <> 0
  
        ROLLBACK TRANSACTION
        RETURN
    END catch
   
END



CREATE FUNCTION [dbo].[GetEmployeeBySalary]
(
    @Salary MONEY
)
RETURNS TABLE
AS
RETURN SELECT emp.FirstName,
              emp.LastName,
              emp.Salary,
              emp.FileFolder,
              dep.DepartmentName
       FROM dbo.Employees emp
           INNER JOIN dbo.Departments dep
               ON emp.DepartmentID = dep.DepartmentID
       WHERE emp.Salary >= @Salary
             AND @Salary >= 0;




SELECT [EmployeeID],
       [FirstName] + ' ' + LastName AS FullName,
       [DepartmentID],
       [CommissionBonus],
       [Salary],
       RANK() OVER (PARTITION BY [DepartmentID] ORDER BY CommissionBonus DESC) AS RankByDepartment,
       LAG([FirstName]) OVER (PARTITION BY [DepartmentID] ORDER BY CommissionBonus DESC) AS PerAbove,
       LAG(CommissionBonus) OVER (PARTITION BY [DepartmentID] ORDER BY CommissionBonus DESC) AS ComAbove,
       AVG(CommissionBonus) OVER (PARTITION BY [DepartmentID]) AS AvgCommission,
       SUM (CommissionBonus+Salary) OVER (PARTITION BY [EmployeeID]) AS TotalCom
FROM [dbo].[Employees];

WITH OrganizationHierarchy
AS (SELECT em.EmployeeID,
           em.FirstName,
           em.LastName,
           em.DepartmentID,
           [ManagerEmployeeID],
           em.FileFolder,
           CAST(em.[FileFolder] AS VARCHAR(MAX)) AS FilePath,
           1 AS level
    FROM Employees em
    WHERE em.ManagerEmployeeID IS NULL
    UNION ALL
    SELECT e.EmployeeID,
           e.FirstName,
           e.LastName,
           e.DepartmentID,
           e.ManagerEmployeeID,
           e.FileFolder,
           CAST(oh.FilePath + '\' + e.FileFolder AS VARCHAR(MAX)) AS FilePath,
           oh.level + 1 AS Level
    FROM Employees e
        INNER JOIN OrganizationHierarchy oh
            ON e.[ManagerEmployeeID] = oh.EmployeeID)
SELECT m.FirstName AS EmployeeFirstName,
       m.LastName AS EmployeeLastName,
       m.DepartmentID,
       m.FileFolder,
       m.FirstName AS ManagerFirstName,
       m.LastName AS ManagerLastName,
       oh.FilePath,
       oh.level
FROM OrganizationHierarchy oh
    LEFT JOIN OrganizationHierarchy m
        ON oh.[ManagerEmployeeID] = m.EmployeeID
ORDER BY oh.level;