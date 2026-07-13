SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0685GetOnboardingProfile
-- Charge les champs de wbfNewUser :
--   IDENTITÉ  → T015User (FirstName, LastName, Email, Phone)
--   ENTREPRISE → paramètres T100/T101 (SOURCE UNIQUE, par ShortName) :
--     LEGAL_NAME, NEQ, INCORP_DATE, FED_BN, FISCAL_YEAR_END, GST_NO, QST_NO, HST_NO
--   (les DATE sont lues dans dVal, les chaînes dans sVal.)
-- Ne lit plus T010Company pour les infos entreprise.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0685GetOnboardingProfile
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.CompanyGUID,
        u.FirstName,
        u.LastName,
        u.Email,
        u.Phone,
        (SELECT v.sVal FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE p.CompanyGUID = u.CompanyGUID AND p.ShortName = 'LEGAL_NAME')      AS LegalName,
        (SELECT v.sVal FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE p.CompanyGUID = u.CompanyGUID AND p.ShortName = 'NEQ')             AS NEQ,
        (SELECT v.dVal FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE p.CompanyGUID = u.CompanyGUID AND p.ShortName = 'INCORP_DATE')     AS IncorporationDate,
        (SELECT v.sVal FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE p.CompanyGUID = u.CompanyGUID AND p.ShortName = 'FED_BN')          AS BusinessNumber,
        (SELECT v.dVal FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE p.CompanyGUID = u.CompanyGUID AND p.ShortName = 'FISCAL_YEAR_END') AS FiscalYearEnd,
        (SELECT v.sVal FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE p.CompanyGUID = u.CompanyGUID AND p.ShortName = 'GST_NO')          AS TpsNumber,
        (SELECT v.sVal FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE p.CompanyGUID = u.CompanyGUID AND p.ShortName = 'QST_NO')          AS TvqNumber,
        (SELECT v.sVal FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE p.CompanyGUID = u.CompanyGUID AND p.ShortName = 'HST_NO')          AS HstNumber
    FROM dbo.T015User u
    WHERE u.Id = @UserId;
END
GO
