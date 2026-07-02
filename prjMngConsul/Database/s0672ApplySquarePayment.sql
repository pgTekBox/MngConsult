-- =============================================================================
-- s0672ApplySquarePayment
-- Rapproche un PAIEMENT Square (Payments API) avec une Facture Client existante
-- via SquareOrderId : pose SquarePaymentId et met a jour le statut.
-- Sens ENTRANT (Square -> app).
--
-- Ne touche PAS aux lignes : c'est un simple tampon de paiement. Si aucune
-- facture ne correspond (vente TPV/Terminal sans facture Square preexistante),
-- renvoie @NeedsInvoice = 1 pour que le webhook cree la facture via
-- s0671UpsertInvoiceFromSquare (avec les lignes de l'Order) puis re-applique.
--
-- Statut paiement -> StatusId :
--   COMPLETED / APPROVED            -> 3 (Paid)
--   CANCELED / FAILED               -> statut inchange (echec : la facture reste due)
--   autres                          -> inchange
-- =============================================================================

USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.s0672ApplySquarePayment', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0672ApplySquarePayment;
GO

CREATE PROCEDURE dbo.s0672ApplySquarePayment
    @CompanyGUID     UNIQUEIDENTIFIER,
    @SquareOrderId   VARCHAR(100) = NULL,
    @SquarePaymentId VARCHAR(100),
    @SquareStatus    VARCHAR(40)  = NULL,
    @AmountCents     BIGINT       = NULL,
    @NeedsInvoice    BIT          = NULL OUTPUT,
    @DocumentId      INT          = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @NeedsInvoice = 0;
    SET @DocumentId = NULL;

    -- Rapprochement par order (puis par paiement deja stampe, pour l'idempotence)
    IF @SquareOrderId IS NOT NULL
        SELECT TOP 1 @DocumentId = Id FROM dbo.T060Document
        WHERE SquareOrderId = @SquareOrderId AND CompanyGUID = @CompanyGUID ORDER BY Id;
    IF @DocumentId IS NULL
        SELECT TOP 1 @DocumentId = Id FROM dbo.T060Document
        WHERE SquarePaymentId = @SquarePaymentId AND CompanyGUID = @CompanyGUID ORDER BY Id;

    IF @DocumentId IS NULL
    BEGIN
        SET @NeedsInvoice = 1;
        SELECT @DocumentId AS DocumentId, @NeedsInvoice AS NeedsInvoice;
        RETURN;
    END

    DECLARE @NewStatusId INT = NULL;
    IF @SquareStatus IN ('COMPLETED','APPROVED') SET @NewStatusId = 3;

    UPDATE dbo.T060Document
    SET SquarePaymentId  = @SquarePaymentId,
        StatusId         = COALESCE(@NewStatusId, StatusId),
        SquareSyncStatus = 'IMPORT',
        SquareSyncDate   = GETDATE()
    WHERE Id = @DocumentId AND CompanyGUID = @CompanyGUID;

    SELECT @DocumentId AS DocumentId, @NeedsInvoice AS NeedsInvoice;
END
GO
