SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0702GetPlaidAccounts
-- Liste des comptes bancaires connectes via Plaid (console Admin — diagnostic).
-- Une ligne par compte (T143PlaidAccount). Nom de compagnie derive des
-- parametres (comme s0653). NE RETOURNE PAS AccessToken/Raw/authData (sensibles).
--
-- Filtres :
--   @Status : 'all', 'active', 'inactive'
--   @Search : fragment recherche dans BankName / AccountName / ItemId (ou vide)
--   @MaxRows: limite (default 500)
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0702GetPlaidAccounts
    @Status  VARCHAR(20)   = 'all',
    @Search  NVARCHAR(200) = NULL,
    @MaxRows INT           = 500
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@MaxRows)
        a.Id,
        a.CompanyGUID,
        COALESCE(dbo.fParamS(a.CompanyGUID, 'TRADE_NAME'), dbo.fCompanyName(a.CompanyGUID)) AS CompanyName,
        c.CompanyCode,
        a.ItemId,
        a.BankName,
        a.AccountName,
        a.AccountId,
        a.AccountType,
        a.AccountSubtype,
        a.Mask,
        a.BalanceAvailable,
        a.BalanceCurrent,
        a.BalanceLimit,
        a.CurrencyCode,
        a.BalanceUpdated,
        a.Active,
        a.InstitutionNumber,
        a.BranchNumber,
        a.AccountNumber,
        a.Created,
        a.accountJson
    FROM dbo.T143PlaidAccount a
    LEFT JOIN dbo.T010Company c ON c.CompanyGUID = a.CompanyGUID
    WHERE (@Status = 'all'
           OR (@Status = 'active'   AND a.Active = 1)
           OR (@Status = 'inactive' AND a.Active = 0))
      AND (@Search IS NULL OR @Search = ''
           OR a.BankName    LIKE '%' + @Search + '%'
           OR a.AccountName LIKE '%' + @Search + '%'
           OR a.ItemId      LIKE '%' + @Search + '%')
    ORDER BY a.Active DESC, a.BankName, a.AccountName;
END
GO
