-- =============================================================================
-- s0097GetScheduledAutoPays
-- Liste les factures programmees pour auto-paiement (calendrier).
--
-- Pour la page wbfAutoPaySchedule.aspx.
-- Filtres optionnels :
--   @FromDate / @ToDate : plage de dates (defaut : aujourd'hui -> +30 jours)
--   @PartyId            : filtrer par fournisseur
--   @Status             : filtrer par status (PLANIFIE / EN_COURS / REQUIRES_3DS / etc.)
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0097GetScheduledAutoPays', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0097GetScheduledAutoPays;
GO

CREATE PROCEDURE dbo.s0097GetScheduledAutoPays
    @CompanyGUID    UNIQUEIDENTIFIER,
    @FromDate       DATE = NULL,
    @ToDate         DATE = NULL,
    @PartyId        INT = NULL,
    @Status         VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @From DATE = ISNULL(@FromDate, CAST(GETDATE() AS DATE));
    DECLARE @To   DATE = ISNULL(@ToDate, DATEADD(DAY, 30, CAST(GETDATE() AS DATE)));

    SELECT
        D.Id AS DocumentId,
        D.DocumentNumber,
        D.DocumentDate,
        D.DueDate,
        D.Total,
        D.AutoPayDate,
        D.AutoPayStatus,
        D.AutoPayAttempts,
        D.AutoPayAuthorizationId,
        D.AutoPayPreavisSentDate,
        D.AutoPayPadPreavisSentDate,

        P.Id AS PartyId,
        P.DisplayName AS PartyName,

        A.PaymentMethodType,
        A.CardBrand,
        A.CardLast4,
        A.BankAccountLast4,

        -- Reste a payer
        D.Total - ISNULL((
            SELECT SUM(RD.MontantImpute)
            FROM dbo.T141ReglementDocument RD
                INNER JOIN dbo.T140Reglement R ON R.Id = RD.ReglementId
            WHERE RD.DocumentId = D.Id
              AND R.Statut IN ('COMPTABILISE','RAPPROCHE')
        ), 0) AS RestantAPayer

    FROM dbo.T060Document D
        LEFT JOIN dbo.T050Party P ON P.PartyGUID = D.PartyGUID AND P.CompanyGUID = D.CompanyGUID
        LEFT JOIN dbo.T144AuthorizationAutoPay A ON A.Id = D.AutoPayAuthorizationId
    WHERE D.CompanyGUID = @CompanyGUID
      AND D.AutoPay = 1
      AND D.AutoPayDate BETWEEN @From AND @To
      AND (@PartyId IS NULL OR P.Id = @PartyId)
      AND (@Status IS NULL OR D.AutoPayStatus = @Status)
    ORDER BY D.AutoPayDate, D.Id;
END
GO
