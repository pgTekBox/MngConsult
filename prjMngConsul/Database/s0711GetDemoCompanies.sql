-- =============================================================================
-- s0711GetDemoCompanies
-- Liste les compagnies de demonstration (liste blanche fnDemoCompanies) qui
-- existent, avec leur nom commercial (param TRADE_NAME) pour le selecteur Admin.
-- Lecture seule.
-- =============================================================================
USE [MngConsul];
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0711GetDemoCompanies
AS
BEGIN
    SET NOCOUNT ON;
    SELECT dc.CompanyGUID,
           ISNULL(
               (SELECT TOP 1 v.sVal
                FROM dbo.T101ParamValues v
                JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
                WHERE v.CompanyGUID = dc.CompanyGUID AND p.ShortName = 'TRADE_NAME'),
               CAST(dc.CompanyGUID AS VARCHAR(50))) AS Name
    FROM dbo.fnDemoCompanies() dc
    JOIN dbo.T010Company c ON c.CompanyGUID = dc.CompanyGUID
    ORDER BY Name;
END
GO
