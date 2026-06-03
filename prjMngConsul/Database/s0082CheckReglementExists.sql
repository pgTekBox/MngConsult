-- =============================================================================
-- s0082CheckReglementExists
-- Verifie si un T140Reglement existe deja pour un StripeSessionId donne.
-- Utilise par wbfSupplierPaymentSync pour savoir quels paiements Stripe
-- sont deja synchronises et lesquels manquent.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0082CheckReglementExists', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0082CheckReglementExists;
GO

CREATE PROCEDURE dbo.s0082CheckReglementExists
    @StripeSessionId VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        Id          AS ReglementId,
        DateReglement,
        Montant,
        Statut
    FROM dbo.T140Reglement
    WHERE Reference = @StripeSessionId
      AND TypeReglement = 'STRIPE';
END
GO
