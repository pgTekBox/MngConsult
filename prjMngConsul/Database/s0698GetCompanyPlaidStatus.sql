SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================================
-- s0698GetCompanyPlaidStatus : état de connexion Plaid d'une compagnie.
--   BankCount    : nombre de banques (items) actives
--   AccountCount : nombre de comptes actifs
--   Banks        : noms des banques (distincts), séparés par des virgules
-- =============================================================
CREATE OR ALTER PROCEDURE [dbo].[s0698GetCompanyPlaidStatus]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        (SELECT COUNT(DISTINCT ItemId)
           FROM dbo.T143PlaidAccount
          WHERE CompanyGUID = @CompanyGUID AND Active = 1)                       AS BankCount,
        (SELECT COUNT(*)
           FROM dbo.T143PlaidAccount
          WHERE CompanyGUID = @CompanyGUID AND Active = 1)                       AS AccountCount,
        (SELECT STRING_AGG(x.BankName, ', ')
           FROM (SELECT DISTINCT BankName
                   FROM dbo.T143PlaidAccount
                  WHERE CompanyGUID = @CompanyGUID AND Active = 1
                    AND BankName IS NOT NULL) x)                                 AS Banks;
END
GO
