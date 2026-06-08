-- =============================================================================
-- s0087ScheduleAutoPay
-- Programme une facture pour paiement automatique a une date donnee.
--
-- Pre-conditions verifiees :
--   - La facture existe et appartient a la Company
--   - Elle est ComptabilisationStatus = 'COMPTABILISE'
--   - Une autorisation active existe pour ce fournisseur
--   - La facture n'est pas deja entierement payee
--   - AutoPayDate >= aujourd'hui
--
-- En cas d'erreur, retourne RetCode <> 0 avec ErrorMessage.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0087ScheduleAutoPay', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0087ScheduleAutoPay;
GO

CREATE PROCEDURE dbo.s0087ScheduleAutoPay
    @CompanyGUID        UNIQUEIDENTIFIER,
    @DocumentId         INT,
    @AutoPayDate        DATE,
    @AuthorizationId    INT,
    @ScheduledByUserGUID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validation Document
    DECLARE @ComptaStatus    VARCHAR(20);
    DECLARE @PartyGUID       UNIQUEIDENTIFIER;
    DECLARE @Total           DECIMAL(15,2);
    DECLARE @AlreadyScheduled BIT;

    SELECT
        @ComptaStatus     = ComptabilisationStatus,
        @PartyGUID        = PartyGUID,
        @Total            = Total,
        @AlreadyScheduled = AutoPay
    FROM dbo.T060Document
    WHERE Id = @DocumentId
      AND CompanyGUID = @CompanyGUID;

    IF @ComptaStatus IS NULL
    BEGIN
        SELECT 1 AS RetCode, 'Facture introuvable' AS ErrorMessage;
        RETURN;
    END

    IF @ComptaStatus <> 'COMPTABILISE'
    BEGIN
        SELECT 2 AS RetCode, 'Facture doit etre comptabilisee avant programmation' AS ErrorMessage;
        RETURN;
    END

    IF @AutoPayDate < CAST(GETDATE() AS DATE)
    BEGIN
        SELECT 3 AS RetCode, 'La date d''auto-paiement doit etre aujourd''hui ou ulterieure' AS ErrorMessage;
        RETURN;
    END

    -- Verifier que l'autorisation est active et appartient au bon fournisseur
    DECLARE @AuthPartyGUID UNIQUEIDENTIFIER;
    DECLARE @AuthRevoked   DATETIME;
    SELECT @AuthPartyGUID = PartyGUID, @AuthRevoked = RevokedDate
    FROM dbo.T144AuthorizationAutoPay
    WHERE Id = @AuthorizationId
      AND CompanyGUID = @CompanyGUID;

    IF @AuthPartyGUID IS NULL
    BEGIN
        SELECT 4 AS RetCode, 'Autorisation introuvable' AS ErrorMessage;
        RETURN;
    END

    IF @AuthRevoked IS NOT NULL
    BEGIN
        SELECT 5 AS RetCode, 'Autorisation revoked - reconfigurer auto-paiement' AS ErrorMessage;
        RETURN;
    END

    IF @AuthPartyGUID <> @PartyGUID
    BEGIN
        SELECT 6 AS RetCode, 'Autorisation ne correspond pas au fournisseur de la facture' AS ErrorMessage;
        RETURN;
    END

    -- Verifier que la facture n'est pas deja payee
    DECLARE @TotalPaye DECIMAL(15,2) = 0;
    SELECT @TotalPaye = ISNULL(SUM(RD.MontantImpute), 0)
    FROM dbo.T141ReglementDocument RD
        INNER JOIN dbo.T140Reglement R ON R.Id = RD.ReglementId
    WHERE RD.DocumentId = @DocumentId
      AND R.Statut IN ('COMPTABILISE','RAPPROCHE');

    IF @TotalPaye >= @Total
    BEGIN
        SELECT 7 AS RetCode, 'Facture deja entierement payee' AS ErrorMessage;
        RETURN;
    END

    -- Programmer
    UPDATE dbo.T060Document
    SET AutoPay = 1,
        AutoPayDate = @AutoPayDate,
        AutoPayStatus = 'PLANIFIE',
        AutoPayAttempts = 0,
        AutoPayAuthorizationId = @AuthorizationId,
        AutoPayPreavisSentDate = NULL,
        AutoPayPadPreavisSentDate = NULL
    WHERE Id = @DocumentId
      AND CompanyGUID = @CompanyGUID;

    SELECT 0 AS RetCode,
           '' AS ErrorMessage,
           @DocumentId AS DocumentId,
           @AutoPayDate AS AutoPayDate,
           @Total - @TotalPaye AS RestantAPayer;
END
GO
