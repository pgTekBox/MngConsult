-- =============================================================================
-- s0094GetAutoPayHistory
-- Historique des tentatives d'auto-paiement pour affichage UI
-- (wbfAutoPayHistory.aspx).
--
-- Filtres optionnels :
--   @PartyId        : restreindre a un fournisseur
--   @DocumentId     : restreindre a une facture
--   @Result         : restreindre par resultat (SUCCESS/FAILED/etc.)
--   @FromDate       : date debut
--   @ToDate         : date fin
--
-- Retourne au maximum @MaxRows lignes (defaut 200), tri descendant.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0094GetAutoPayHistory', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0094GetAutoPayHistory;
GO

CREATE PROCEDURE dbo.s0094GetAutoPayHistory
    @CompanyGUID    UNIQUEIDENTIFIER,
    @PartyId        INT = NULL,
    @DocumentId     INT = NULL,
    @Result         VARCHAR(30) = NULL,
    @FromDate       DATE = NULL,
    @ToDate         DATE = NULL,
    @MaxRows        INT = 200
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@MaxRows)
        AT.Id AS AttemptId,
        AT.AttemptDate,
        AT.AttemptNumber,
        AT.Amount,
        AT.AmountGross,
        AT.FeeAmount,
        AT.Currency,
        AT.PaymentMethodType,
        AT.Result,
        AT.StripePaymentIntentId,
        AT.StripeChargeId,
        AT.FailureCode,
        AT.FailureMessage,
        AT.Requires3DSUrl,
        AT.ReglementId,

        AT.DocumentId,
        D.DocumentNumber,
        D.DocumentDate,
        D.DueDate,
        D.Total AS DocumentTotal,

        AT.PartyId,
        P.DisplayName AS PartyName,

        AT.AuthorizationId,
        A.CardBrand,
        A.CardLast4,
        A.BankAccountLast4
    FROM dbo.T145AutoPayAttempt AT
        INNER JOIN dbo.T060Document D ON D.Id = AT.DocumentId
        INNER JOIN dbo.T050Party P ON P.Id = AT.PartyId
        LEFT JOIN dbo.T144AuthorizationAutoPay A ON A.Id = AT.AuthorizationId
    WHERE AT.CompanyGUID = @CompanyGUID
      AND (@PartyId IS NULL OR AT.PartyId = @PartyId)
      AND (@DocumentId IS NULL OR AT.DocumentId = @DocumentId)
      AND (@Result IS NULL OR AT.Result = @Result)
      AND (@FromDate IS NULL OR CAST(AT.AttemptDate AS DATE) >= @FromDate)
      AND (@ToDate IS NULL OR CAST(AT.AttemptDate AS DATE) <= @ToDate)
    ORDER BY AT.AttemptDate DESC;
END
GO
