/* =====================================================================
   PortailMaster - Script 33 : purge des paiements RETOURNÉS
   ---------------------------------------------------------------------
   ⚠️ SENSIBILITÉ PARTICULIÈRE. Contrairement aux journaux/files purgés
   jusqu'ici, T030Payment est un ENREGISTREMENT FINANCIER (cycle du
   paiement). À traiter avec prudence :

     - Rétention par défaut TRÈS LONGUE (2555 j ≈ 7 ans) : les registres de
       paiement sont soumis à des obligations réglementaires de conservation
       (FINTRAC/PCMLTFA, fiscalité, etc.). ⚠️ AJUSTER selon votre politique
       de rétention / conseil juridique avant de raccourcir.
     - Le GRAND LIVRE IMMUABLE (T101/T102) n'a AUCUNE FK vers T030 : il
       CONSERVE l'écriture réelle (initiation/règlement/contre-passation) et
       l'invariant. Supprimer un T030 ne touche donc pas la piste d'audit
       comptable ; T030 n'est que l'objet OPÉRATIONNEL du cycle.
     - Dépendances entrantes : T042WebhookDelivery.PaymentId et
       T051EftBatchItem.PaymentId (FK). Pour ne rien casser ni cascader, on
       ne purge QUE les paiements retournés qui ne sont PLUS référencés (leurs
       livraisons/lignes de lot ont déjà été purgées par s0078/s0084/s0081).
       Un paiement encore référencé attend simplement un prochain passage.
     - T053EftReturn.PaymentId est une simple valeur (pas de FK) : peut
       rester en référence informative (ou est purgé par s0083).

   s0085PurgeReturnedPayments + maj s0079.
   A executer APRES 08 (T030) et 32 (s0079). Procs numerotees s0085+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   s0085PurgeReturnedPayments : supprime les paiements RETOURNÉS anciens
   (via ReturnedUtc) qui ne sont plus référencés par une livraison de
   webhook ni une ligne de lot EFT. Renvoie le nombre supprimé.
   Défaut 2555 j (≈ 7 ans).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0085PurgeReturnedPayments
    @RetentionDays INT = 2555
AS
BEGIN
    SET NOCOUNT ON;
    IF @RetentionDays IS NULL OR @RetentionDays < 0 SET @RetentionDays = 2555;
    DECLARE @cutoff DATETIME2(0) = DATEADD(DAY, -@RetentionDays, SYSUTCDATETIME());

    DELETE p
    FROM dbo.T030Payment p
    WHERE p.Status = N'Retourne'
      AND p.ReturnedUtc IS NOT NULL
      AND p.ReturnedUtc < @cutoff
      AND NOT EXISTS (SELECT 1 FROM dbo.T042WebhookDelivery d WHERE d.PaymentId = p.Id)
      AND NOT EXISTS (SELECT 1 FROM dbo.T051EftBatchItem   it WHERE it.PaymentId = p.Id);

    SELECT @@ROWCOUNT AS Purged;
END
GO

/* ---------------------------------------------------------------------
   s0079RunDailyMaintenance : + purge des paiements retournés.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0079RunDailyMaintenance
    @WebhookRetentionDays          INT = 30,
    @BankLineRetentionDays         INT = 365,
    @EftBatchRetentionDays         INT = 365,
    @ExchangeLogRetentionDays      INT = 180,
    @EftReturnRetentionDays        INT = 365,
    @WebhookAbandonedRetentionDays INT = 90,
    @ReturnedPaymentRetentionDays  INT = 2555
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tokRes TABLE (Purged INT);
    DECLARE @whRes  TABLE (Purged INT);
    DECLARE @blRes  TABLE (Purged INT);
    DECLARE @ebRes  TABLE (Purged INT);
    DECLARE @elRes  TABLE (Purged INT);
    DECLARE @erRes  TABLE (Purged INT);
    DECLARE @waRes  TABLE (Purged INT);
    DECLARE @rpRes  TABLE (Purged INT);

    INSERT INTO @tokRes EXEC dbo.s0077PurgeExpiredRememberTokens;
    INSERT INTO @whRes  EXEC dbo.s0078PurgeDeliveredWebhooks     @RetentionDays = @WebhookRetentionDays;
    INSERT INTO @blRes  EXEC dbo.s0080PurgeReconciledBankLines   @RetentionDays = @BankLineRetentionDays;
    INSERT INTO @ebRes  EXEC dbo.s0081PurgeSettledEftBatches     @RetentionDays = @EftBatchRetentionDays;
    INSERT INTO @elRes  EXEC dbo.s0082PurgeExchangeLog           @RetentionDays = @ExchangeLogRetentionDays;
    INSERT INTO @erRes  EXEC dbo.s0083PurgeProcessedEftReturns   @RetentionDays = @EftReturnRetentionDays;
    INSERT INTO @waRes  EXEC dbo.s0084PurgeAbandonedWebhooks     @RetentionDays = @WebhookAbandonedRetentionDays;
    INSERT INTO @rpRes  EXEC dbo.s0085PurgeReturnedPayments      @RetentionDays = @ReturnedPaymentRetentionDays;

    SELECT
        ISNULL((SELECT TOP 1 Purged FROM @tokRes), 0) AS PurgedTokens,
        ISNULL((SELECT TOP 1 Purged FROM @whRes),  0) AS PurgedWebhooks,
        ISNULL((SELECT TOP 1 Purged FROM @blRes),  0) AS PurgedBankLines,
        ISNULL((SELECT TOP 1 Purged FROM @ebRes),  0) AS PurgedEftBatches,
        ISNULL((SELECT TOP 1 Purged FROM @elRes),  0) AS PurgedExchangeLogs,
        ISNULL((SELECT TOP 1 Purged FROM @erRes),  0) AS PurgedEftReturns,
        ISNULL((SELECT TOP 1 Purged FROM @waRes),  0) AS PurgedAbandonedWebhooks,
        ISNULL((SELECT TOP 1 Purged FROM @rpRes),  0) AS PurgedReturnedPayments;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'33_returned_payment_purge.sql : termine.';
GO
