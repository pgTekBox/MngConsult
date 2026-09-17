/* RÉPLIQUES MINIMALES des objets de MngConsul dont 60secPaie dépend (tables T010Company, T015User, T300Employees, T053State,
   fonctions fParamS / fCompanyName, procédure s0210GetUserCompanies).
   POUR LES BASES DE TEST SEULEMENT : sur le serveur, ces objets appartiennent à MngConsul et ne doivent jamais être recréés.
   Le garde-fou ci-dessous refuse toute base dont le nom ne se termine pas par « _Test ». */
USE [$(Base)];
GO
IF DB_NAME() NOT LIKE N'%[_]Test'
BEGIN
    RAISERROR(N'00_stubs_mngconsul.sql est réservé aux bases de test (nom terminé par _Test).', 16, 1);
    SET NOEXEC ON;
END
GO

CREATE TABLE dbo.T010Company (
    Id int IDENTITY(1,1) NOT NULL,
    CompanyGUID uniqueidentifier NOT NULL PRIMARY KEY,
    CompanyCode varchar(50) NULL,
    ComptableGUID uniqueidentifier NULL
);
CREATE TABLE dbo.T015User (
    Id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CompanyGUID uniqueidentifier NULL,
    UserGUID uniqueidentifier NULL,
    Email nvarchar(200) NOT NULL,
    PasswordHash nvarchar(500) NOT NULL,
    FirstName nvarchar(100) NULL,
    LastName nvarchar(100) NULL,
    IsAdmin bit NOT NULL DEFAULT (0),
    IsActive bit NOT NULL DEFAULT (1),
    IsDeleted bit NOT NULL DEFAULT (0),
    isAccountant bit NULL
);
CREATE TABLE dbo.T053State (Id int IDENTITY(1,1) NOT NULL PRIMARY KEY, Name varchar(200) NULL);
INSERT INTO dbo.T053State (Name) VALUES ('unknown'), ('Quebec'), ('Ontario');
CREATE TABLE dbo.T300Employees (
    Id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EmployeeGUID uniqueidentifier NOT NULL DEFAULT (NEWID()),
    CompanyGUID uniqueidentifier NULL,
    EmployeeNumber varchar(50) NULL,
    FirstName varchar(150) NULL, LastName varchar(150) NULL,
    DateOfBirth date NULL, [SIN] varchar(20) NULL,
    Email varchar(200) NULL, Phone varchar(50) NULL, Mobile varchar(50) NULL,
    Address1 varchar(500) NULL, Address2 varchar(500) NULL, City varchar(100) NULL, StateId int NULL, PostalCode varchar(20) NULL,
    JobTitle varchar(150) NULL, HireDate date NULL, TerminationDate date NULL,
    HourlyRate decimal(15,2) NULL, AnnualSalary decimal(15,2) NULL, PayFrequency varchar(50) NULL,
    BankTransit varchar(20) NULL, BankInstitution varchar(20) NULL, BankAccount varchar(50) NULL,
    Active bit NULL
);
-- Dans MngConsul, le nom et l'adresse d'une compagnie sont des paramètres (T100ParamComptable / T101ParamValues).
CREATE TABLE dbo.StubParam (CompanyGUID uniqueidentifier NOT NULL, ShortName varchar(50) NOT NULL, sVal varchar(8000) NULL, PRIMARY KEY (CompanyGUID, ShortName));
GO
CREATE FUNCTION dbo.fParamS(@CompanyGUID uniqueidentifier, @ShortName varchar(50)) RETURNS varchar(8000) AS
BEGIN
    RETURN (SELECT sVal FROM dbo.StubParam WHERE CompanyGUID = @CompanyGUID AND ShortName = @ShortName);
END
GO
CREATE FUNCTION dbo.fCompanyName(@CompanyGUID uniqueidentifier) RETURNS varchar(8000) AS
BEGIN
    RETURN COALESCE(dbo.fParamS(@CompanyGUID, 'LEGAL_NAME'), dbo.fParamS(@CompanyGUID, 'TRADE_NAME'));
END
GO
-- Même règle que dans MngConsul : un comptable voit les compagnies dont il est le ComptableGUID, les autres leur seule compagnie.
CREATE PROCEDURE dbo.s0210GetUserCompanies @UserId nvarchar(200) AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IsAccountant bit, @UserCompanyGUID uniqueidentifier, @UserGUID uniqueidentifier;
    SELECT @IsAccountant = isAccountant, @UserCompanyGUID = CompanyGUID, @UserGUID = UserGUID FROM dbo.T015User WHERE Email = @UserId AND IsDeleted = 0;
    IF @IsAccountant = 1
        SELECT c.CompanyGUID, dbo.fCompanyName(c.CompanyGUID) AS Name, dbo.fParamS(c.CompanyGUID, 'LEGAL_NAME') AS LegalName, c.CompanyCode
        FROM dbo.T010Company c WHERE c.ComptableGUID = @UserGUID ORDER BY Name;
    ELSE
        SELECT c.CompanyGUID, dbo.fCompanyName(c.CompanyGUID) AS Name, dbo.fParamS(c.CompanyGUID, 'LEGAL_NAME') AS LegalName, c.CompanyCode
        FROM dbo.T010Company c WHERE c.CompanyGUID = @UserCompanyGUID;
END
GO
SET NOEXEC OFF;
GO
