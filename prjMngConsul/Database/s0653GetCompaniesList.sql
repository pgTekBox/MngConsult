SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0653GetCompaniesList
-- Liste des compagnies (T010Company) avec un résumé de leur
-- abonnement courant (le plus récent actif, sinon le plus récent).
-- @Search : filtre optionnel (nom, code, raison sociale).
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0653GetCompaniesList
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CompanyGUID,
        c.CompanyCode,
        c.Name,
        c.LegalName,
        c.Structure,
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
           OR c.Name LIKE '%' + @Search + '%'
           OR c.CompanyCode LIKE '%' + @Search + '%'
           OR c.LegalName LIKE '%' + @Search + '%')
    ORDER BY c.Name;
END
