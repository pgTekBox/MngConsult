SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0703GetPlaidStats
-- Statistiques agregees sur les connexions bancaires Plaid (console Admin).
-- Comptes = lignes T143PlaidAccount ; Connexions/Items = ItemId distincts ;
-- Erreurs = lignes T144PlaidSyncLog dans la periode @SinceHours.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0703GetPlaidStats
    @SinceHours INT = 168    -- fenetre pour le compte d'erreurs (7 jours par defaut)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SinceDate DATETIME = DATEADD(HOUR, -@SinceHours, GETDATE());

    SELECT
        (SELECT COUNT(*)                    FROM dbo.T143PlaidAccount)                                   AS TotalAccounts,
        (SELECT COUNT(*)                    FROM dbo.T143PlaidAccount WHERE Active = 1)                  AS ActiveAccounts,
        (SELECT COUNT(*)                    FROM dbo.T143PlaidAccount WHERE Active = 0)                  AS InactiveAccounts,
        (SELECT COUNT(DISTINCT ItemId)      FROM dbo.T143PlaidAccount WHERE Active = 1)                  AS DistinctItems,
        (SELECT COUNT(DISTINCT CompanyGUID) FROM dbo.T143PlaidAccount WHERE Active = 1)                  AS DistinctCompanies,
        (SELECT COUNT(DISTINCT BankName)    FROM dbo.T143PlaidAccount WHERE Active = 1
                                                  AND BankName IS NOT NULL)                              AS DistinctBanks,
        (SELECT MAX(BalanceUpdated)         FROM dbo.T143PlaidAccount)                                   AS LastBalanceUpdate,
        (SELECT COUNT(*)                    FROM dbo.T144PlaidSyncLog WHERE Created >= @SinceDate)       AS ErrorCount,
        (SELECT MAX(Created)                FROM dbo.T144PlaidSyncLog)                                   AS LastErrorOn;
END
GO
