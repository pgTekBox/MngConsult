SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0653GetCompaniesList (console admin — liste des compagnies)
-- Name/LegalName/Structure proviennent de T101 (Name←TRADE_NAME, repli
-- LEGAL_NAME/T010Company.Name ; LegalName←LEGAL_NAME ; Structure←STRUCTURE).
-- Le filtre @Search cherche dans TRADE_NAME, CompanyCode et LEGAL_NAME.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0653GetCompaniesList
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CompanyGUID,
        c.CompanyCode,
        COALESCE(dbo.fParamS(c.CompanyGUID, 'TRADE_NAME'), dbo.fCompanyName(c.CompanyGUID)) AS Name,
        dbo.fParamS(c.CompanyGUID, 'LEGAL_NAME') AS LegalName,
        dbo.fParamS(c.CompanyGUID, 'STRUCTURE')  AS Structure,
        s.PlanCode,
        s.PlanName,
        s.Status        AS SubStatus,
        s.Amount        AS SubAmount,
        s.Currency      AS SubCurrency,
        s.BillingCycle  AS SubCycle,
        s.IsTrial       AS SubIsTrial,
        s.NextBillingDate
    FROM dbo.T010Company c
    OUTER APPLY (
        SELECT TOP 1
            PlanCode, PlanName, Status, Amount, Currency, BillingCycle, IsTrial, NextBillingDate
        FROM dbo.T020Subscription s2
        WHERE s2.CompanyGUID = c.CompanyGUID
          AND s2.IsDeleted = 0
        ORDER BY CASE WHEN s2.Status = 'active' THEN 0 ELSE 1 END, s2.CreatedOn DESC
    ) s
    WHERE (@Search IS NULL OR @Search = ''
           OR dbo.fParamS(c.CompanyGUID, 'TRADE_NAME') LIKE '%' + @Search + '%'
           OR c.CompanyCode LIKE '%' + @Search + '%'
           OR dbo.fParamS(c.CompanyGUID, 'LEGAL_NAME') LIKE '%' + @Search + '%')
    ORDER BY Name;
END
GO
