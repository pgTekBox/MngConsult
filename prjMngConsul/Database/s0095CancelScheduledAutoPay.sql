-- =============================================================================
-- s0095CancelScheduledAutoPay
-- Annule une auto-paiement programmee (sans revoquer l'autorisation).
-- L'utilisateur garde la PaymentMethod sauvegardee pour de futures factures.
--
-- Seules les factures en status PLANIFIE ou REQUIRES_3DS peuvent etre annulees.
-- Une facture EN_COURS (debit en train d'etre execute) ne peut pas etre annulee
-- via cette proc (il faudrait appeler Stripe pour annuler le PaymentIntent).
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0095CancelScheduledAutoPay', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0095CancelScheduledAutoPay;
GO

CREATE PROCEDURE dbo.s0095CancelScheduledAutoPay
    @CompanyGUID        UNIQUEIDENTIFIER,
    @DocumentId         INT,
    @CancelledByUserGUID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentStatus VARCHAR(20);

    SELECT @CurrentStatus = AutoPayStatus
    FROM dbo.T060Document
    WHERE Id = @DocumentId
      AND CompanyGUID = @CompanyGUID
      AND AutoPay = 1;

    IF @CurrentStatus IS NULL
    BEGIN
        SELECT 1 AS RetCode, 'Facture introuvable ou non programmee' AS ErrorMessage;
        RETURN;
    END

    IF @CurrentStatus NOT IN ('PLANIFIE','REQUIRES_3DS')
    BEGIN
        SELECT 2 AS RetCode,
               CONCAT('Annulation impossible (status = ', @CurrentStatus, ')') AS ErrorMessage;
        RETURN;
    END

    UPDATE dbo.T060Document
    SET AutoPayStatus = 'ANNULE',
        AutoPay = 0
    WHERE Id = @DocumentId
      AND CompanyGUID = @CompanyGUID;

    SELECT 0 AS RetCode, '' AS ErrorMessage;
END
GO
