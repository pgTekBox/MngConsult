-- =============================================================================
-- s0091GetUpcomingPreavis24h
-- Retourne les factures dont le debit automatique est prevu demain
-- et pour lesquelles le preavis 24h n'a pas encore ete envoye.
--
-- Concerne UNIQUEMENT les paiements par CARTE (les ACSS ont leur propre
-- preavis a 3 jours via s0092).
--
-- Appele par le job SQL Agent quotidien (6h00).
-- Le scheduler envoie ensuite l'email via T400Mails (s0610) et appelle
-- s0091bMarkPreavisSent pour flaguer.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0091GetUpcomingPreavis24h', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0091GetUpcomingPreavis24h;
GO

CREATE PROCEDURE dbo.s0091GetUpcomingPreavis24h
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Tomorrow DATE = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));

    SELECT
        D.Id AS DocumentId,
        D.CompanyGUID,
        D.DocumentNumber,
        D.DocumentDate,
        D.DueDate,
        D.Total,
        D.AutoPayDate,
        D.AutoPayAuthorizationId,

        P.Id AS PartyId,
        P.DisplayName AS PartyName,
        D.Email AS PartyEmail,

        A.StripeAccountId,
        A.PaymentMethodType,
        A.CardBrand,
        A.CardLast4,
        A.AuthorizedByUserGUID,

        U.FirstName AS PayerFirstName,
        U.LastName AS PayerLastName,
        U.Email AS PayerEmail
    FROM dbo.T060Document D
        INNER JOIN dbo.T144AuthorizationAutoPay A ON A.Id = D.AutoPayAuthorizationId
        INNER JOIN dbo.T050Party P ON P.PartyGUID = D.PartyGUID AND P.CompanyGUID = D.CompanyGUID
        LEFT JOIN dbo.T015User U ON U.UserGUID = A.AuthorizedByUserGUID
    WHERE D.AutoPay = 1
      AND D.AutoPayStatus = 'PLANIFIE'
      AND D.AutoPayDate = @Tomorrow
      AND D.AutoPayPreavisSentDate IS NULL
      AND A.PaymentMethodType = 'card'
      AND A.RevokedDate IS NULL
    ORDER BY D.CompanyGUID, D.AutoPayDate;
END
GO

-- =============================================================================
-- s0091bMarkPreavisSent
-- Marque le preavis 24h comme envoye pour une facture.
-- =============================================================================

IF OBJECT_ID('dbo.s0091bMarkPreavisSent', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0091bMarkPreavisSent;
GO

CREATE PROCEDURE dbo.s0091bMarkPreavisSent
    @CompanyGUID    UNIQUEIDENTIFIER,
    @DocumentId     INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T060Document
    SET AutoPayPreavisSentDate = GETDATE()
    WHERE Id = @DocumentId
      AND CompanyGUID = @CompanyGUID
      AND AutoPayPreavisSentDate IS NULL;

    SELECT @@ROWCOUNT AS RowsUpdated;
END
GO
