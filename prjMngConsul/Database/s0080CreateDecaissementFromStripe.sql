-- =============================================================================
-- s0080CreateDecaissementFromStripe (V2)
-- Cree un decaissement (reglement + ligne sur facture) suite a un paiement
-- Stripe Connect Direct Charge reussi.
--
-- Appele par StripeWebhook.ashx au recu de checkout.session.completed
-- avec metadata MngConsul_DocumentId present.
--
-- Cree :
--   1. T140Reglement
--      - TypeReglement : mappe selon PaymentMethod
--          card           -> CARTE
--          acss_debit     -> PRELEVEMENT
--          interac        -> VIREMENT
--          (autre)        -> AUTRE
--      - Sens          : 'DECAISSEMENT'
--      - Statut        : 'COMPTABILISE' (valide cote contrainte chk_T140_Statut)
--      - Reference     : cs_xxx Stripe Session Id (cle d'idempotence)
--
--   2. T141ReglementDocument (lien reglement <-> facture)
--
-- Idempotent : si une ligne T140 existe deja pour cette session_id,
-- on n'en cree pas une nouvelle. Cle = Reference + TypeReglement.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0080CreateDecaissementFromStripe', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0080CreateDecaissementFromStripe;
GO

CREATE PROCEDURE dbo.s0080CreateDecaissementFromStripe
    @CompanyGUID           UNIQUEIDENTIFIER,
    @PartyId               INT,
    @DocumentId            INT,
    @Amount                DECIMAL(15,2),
    @StripeSessionId       VARCHAR(100),
    @StripePaymentIntentId VARCHAR(100) = NULL,
    @PaymentMethod         VARCHAR(50)  = 'card',
    @CreatedByUserId       INT          = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Idempotence : un reglement avec cette Reference existe deja ?
    DECLARE @ExistingReglementId INT = NULL;
    SELECT TOP 1 @ExistingReglementId = Id
    FROM dbo.T140Reglement
    WHERE Reference = @StripeSessionId;

    IF @ExistingReglementId IS NOT NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS WasInserted, @ExistingReglementId AS ReglementId;
        RETURN;
    END

    -- Mapping methode de paiement Stripe -> TypeReglement comptable
    -- (les valeurs doivent respecter chk_T140_Type : AUTRE | PRELEVEMENT | ESPECES | CARTE | CHEQUE | VIREMENT)
    DECLARE @TypeReglement VARCHAR(20) =
        CASE
            WHEN @PaymentMethod = 'card'              THEN 'CARTE'
            WHEN @PaymentMethod = 'acss_debit'        THEN 'PRELEVEMENT'
            WHEN @PaymentMethod = 'interac'           THEN 'VIREMENT'
            WHEN @PaymentMethod = 'interac_present'   THEN 'VIREMENT'
            ELSE                                           'AUTRE'
        END;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NewReglementId INT;

        INSERT INTO dbo.T140Reglement (
            ReglementGUID, CompanyGUID, PartyId,
            DateReglement, Montant, Reference,
            TypeReglement, Sens, CompteBanque, Statut,
            Created, CreatedBy
        )
        VALUES (
            NEWID(), @CompanyGUID, @PartyId,
            CAST(GETDATE() AS DATE), @Amount, @StripeSessionId,
            @TypeReglement, 'DECAISSEMENT', '1020', 'COMPTABILISE',
            GETDATE(), @CreatedByUserId
        );

        SET @NewReglementId = SCOPE_IDENTITY();

        IF @NewReglementId IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('Insertion T140Reglement a echoue (SCOPE_IDENTITY NULL)', 16, 1);
            RETURN;
        END

        INSERT INTO dbo.T141ReglementDocument (
            ReglementId, DocumentId, MontantImpute, Created
        )
        VALUES (
            @NewReglementId, @DocumentId, @Amount, GETDATE()
        );

        COMMIT TRANSACTION;

        SELECT CAST(1 AS BIT) AS WasInserted, @NewReglementId AS ReglementId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
    END CATCH
END
GO
