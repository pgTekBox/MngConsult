-- =============================================================================
-- s0096ListAllAuthorizations
-- Liste toutes les autorisations T144 (actives + revoked) d'une Company.
-- Pour la page wbfAutoPayAuthorizations.aspx.
--
-- Filtres optionnels :
--   @OnlyActive : 1 = uniquement RevokedDate IS NULL (defaut), 0 = tout
--   @PartyId    : filtrer par fournisseur (NULL = tout)
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0096ListAllAuthorizations', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0096ListAllAuthorizations;
GO

CREATE PROCEDURE dbo.s0096ListAllAuthorizations
    @CompanyGUID    UNIQUEIDENTIFIER,
    @OnlyActive     BIT = 1,
    @PartyId        INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        A.Id,
        A.AuthorizationGUID,
        A.PartyId,
        P.DisplayName AS PartyName,
        A.StripeAccountId,
        A.PaymentMethodType,
        A.CardBrand,
        A.CardLast4,
        A.CardExpMonth,
        A.CardExpYear,
        A.BankAccountLast4,
        A.MaxAmountPerCharge,
        A.MaxAmountPerMonth,
        A.AuthorizedDate,
        A.AuthorizedByUserGUID,
        U.FirstName + ' ' + ISNULL(U.LastName, '') AS AuthorizedByName,
        U.Email AS AuthorizedByEmail,
        A.RevokedDate,
        A.RevokedReason,
        CASE WHEN A.RevokedDate IS NULL THEN 1 ELSE 0 END AS IsActive,

        -- Compteurs : combien de factures programmees ?
        (SELECT COUNT(*) FROM dbo.T060Document D
            WHERE D.CompanyGUID = A.CompanyGUID
              AND D.AutoPayAuthorizationId = A.Id
              AND D.AutoPayStatus = 'PLANIFIE') AS ScheduledCount,

        -- Combien de succes a vie ?
        (SELECT COUNT(*) FROM dbo.T145AutoPayAttempt AT
            WHERE AT.AuthorizationId = A.Id
              AND AT.Result = 'SUCCESS') AS SuccessCount,

        -- Total cumule SUCCESS ce mois
        (SELECT ISNULL(SUM(AT.Amount), 0) FROM dbo.T145AutoPayAttempt AT
            WHERE AT.AuthorizationId = A.Id
              AND AT.Result = 'SUCCESS'
              AND AT.AttemptDate >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) AS MonthToDateAmount

    FROM dbo.T144AuthorizationAutoPay A
        LEFT JOIN dbo.T050Party P ON P.Id = A.PartyId AND P.CompanyGUID = A.CompanyGUID
        LEFT JOIN dbo.T015User U ON U.UserGUID = A.AuthorizedByUserGUID
    WHERE A.CompanyGUID = @CompanyGUID
      AND (@OnlyActive = 0 OR A.RevokedDate IS NULL)
      AND (@PartyId IS NULL OR A.PartyId = @PartyId)
    ORDER BY
        CASE WHEN A.RevokedDate IS NULL THEN 0 ELSE 1 END,
        A.AuthorizedDate DESC;
END
GO
