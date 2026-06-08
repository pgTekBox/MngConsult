-- =============================================================================
-- s0092GetUpcomingPadPreavis3Days
-- Retourne les factures dont le debit PAD (ACSS Debit) est prevu dans 3 jours
-- et pour lesquelles le preavis legal PAD n'a pas encore ete envoye.
--
-- Conformite Regle H1 de Paiements Canada :
--   - Preavis legal 10 jours pour debits Personnel
--   - Preavis legal 3 jours pour debits Affaires (avec mention dans la convention)
--
-- MngConsul opere en mode Affaires (B2B), donc 3 jours OK si la convention
-- PAD initiale (presentee lors de l'autorisation) le mentionne explicitement.
--
-- Le preavis doit contenir :
--   - Montant exact a debiter
--   - Date du debit
--   - Nom du beneficiaire (fournisseur)
--   - Numero de mandat Stripe (StripeMandateId)
--   - Coordonnees pour annulation
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0092GetUpcomingPadPreavis3Days', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0092GetUpcomingPadPreavis3Days;
GO

CREATE PROCEDURE dbo.s0092GetUpcomingPadPreavis3Days
    @DaysAhead      INT = 3
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TargetDate DATE = DATEADD(DAY, @DaysAhead, CAST(GETDATE() AS DATE));

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
        A.BankInstitutionNumber,
        A.BankTransitNumber,
        A.BankAccountLast4,
        A.StripeMandateId,
        A.PadAgreementUrl,
        A.AuthorizedByUserGUID,
        A.AuthorizationLanguage,

        U.FirstName AS PayerFirstName,
        U.LastName AS PayerLastName,
        U.Email AS PayerEmail
    FROM dbo.T060Document D
        INNER JOIN dbo.T144AuthorizationAutoPay A ON A.Id = D.AutoPayAuthorizationId
        INNER JOIN dbo.T050Party P ON P.PartyGUID = D.PartyGUID AND P.CompanyGUID = D.CompanyGUID
        LEFT JOIN dbo.T015User U ON U.UserGUID = A.AuthorizedByUserGUID
    WHERE D.AutoPay = 1
      AND D.AutoPayStatus = 'PLANIFIE'
      AND D.AutoPayDate = @TargetDate
      AND D.AutoPayPadPreavisSentDate IS NULL
      AND A.PaymentMethodType = 'acss_debit'
      AND A.RevokedDate IS NULL
    ORDER BY D.CompanyGUID, D.AutoPayDate;
END
GO

-- =============================================================================
-- s0092bMarkPadPreavisSent
-- Marque le preavis PAD comme envoye pour une facture.
-- =============================================================================

IF OBJECT_ID('dbo.s0092bMarkPadPreavisSent', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0092bMarkPadPreavisSent;
GO

CREATE PROCEDURE dbo.s0092bMarkPadPreavisSent
    @CompanyGUID    UNIQUEIDENTIFIER,
    @DocumentId     INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T060Document
    SET AutoPayPadPreavisSentDate = GETDATE()
    WHERE Id = @DocumentId
      AND CompanyGUID = @CompanyGUID
      AND AutoPayPadPreavisSentDate IS NULL;

    SELECT @@ROWCOUNT AS RowsUpdated;
END
GO
