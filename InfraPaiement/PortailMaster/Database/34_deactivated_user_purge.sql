/* =====================================================================
   PortailMaster - Script 34 : purge des utilisateurs abonnés DÉSACTIVÉS
   ---------------------------------------------------------------------
   Les comptes utilisateurs abonnés désactivés (T011AbonneUser.IsActive=0)
   qui ne sont plus utilisés depuis longtemps peuvent être supprimés :
   c'est de la MINIMISATION DES DONNÉES (RGPD/vie privée) — on retire les
   données personnelles (courriel, nom, hash) d'un compte hors service.

   Sûreté :
     - Seule dépendance entrante : T012AbonneRememberToken (FK **ON DELETE
       CASCADE**) → les jetons « Se souvenir de moi » du compte partent
       automatiquement avec lui.
     - T011AbonneUser n'est référencé nulle part comme AUTEUR d'un
       enregistrement (les procs d'action utilisent AdminId→T001PortalAdmin,
       ou aucune attribution) : aucune référence pendante après suppression.
     - On ne touche QUE les comptes IsActive=0 ; les comptes actifs (et donc
       les admins en fonction) ne sont jamais concernés.

   Âge de référence : COALESCE(ModifiedUtc, CreatedUtc) — la désactivation
   passe par s0070SaveAbonneUser (UPDATE) qui pose ModifiedUtc.

   Rétention par défaut 365 j après désactivation.

   s0086PurgeDeactivatedAbonneUsers + maj s0079.
   A executer APRES 22 (T011) / 26 (T012) et 33 (s0079). Procs numerotees s0086+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   s0086PurgeDeactivatedAbonneUsers : supprime les comptes désactivés
   inactifs depuis plus longtemps que la rétention (défaut 365 j).
   Les jetons remember-me suivent par CASCADE. Renvoie le nb supprimé.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0086PurgeDeactivatedAbonneUsers
    @RetentionDays INT = 365
AS
BEGIN
    SET NOCOUNT ON;
    IF @RetentionDays IS NULL OR @RetentionDays < 0 SET @RetentionDays = 365;
    DECLARE @cutoff DATETIME2(0) = DATEADD(DAY, -@RetentionDays, SYSUTCDATETIME());

    DELETE FROM dbo.T011AbonneUser
    WHERE IsActive = 0
      AND COALESCE(ModifiedUtc, CreatedUtc) < @cutoff;

    SELECT @@ROWCOUNT AS Purged;
END
GO

/* ---------------------------------------------------------------------
   s0079RunDailyMaintenance : + purge des utilisateurs abonnés désactivés.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0079RunDailyMaintenance
    @WebhookRetentionDays          INT = 30,
    @BankLineRetentionDays         INT = 365,
    @EftBatchRetentionDays         INT = 365,
    @ExchangeLogRetentionDays      INT = 180,
    @EftReturnRetentionDays        INT = 365,
    @WebhookAbandonedRetentionDays INT = 90,
    @ReturnedPaymentRetentionDays  INT = 2555,
    @DeactivatedUserRetentionDays  INT = 365
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
    DECLARE @duRes  TABLE (Purged INT);

    INSERT INTO @tokRes EXEC dbo.s0077PurgeExpiredRememberTokens;
    INSERT INTO @whRes  EXEC dbo.s0078PurgeDeliveredWebhooks       @RetentionDays = @WebhookRetentionDays;
    INSERT INTO @blRes  EXEC dbo.s0080PurgeReconciledBankLines     @RetentionDays = @BankLineRetentionDays;
    INSERT INTO @ebRes  EXEC dbo.s0081PurgeSettledEftBatches       @RetentionDays = @EftBatchRetentionDays;
    INSERT INTO @elRes  EXEC dbo.s0082PurgeExchangeLog             @RetentionDays = @ExchangeLogRetentionDays;
    INSERT INTO @erRes  EXEC dbo.s0083PurgeProcessedEftReturns     @RetentionDays = @EftReturnRetentionDays;
    INSERT INTO @waRes  EXEC dbo.s0084PurgeAbandonedWebhooks       @RetentionDays = @WebhookAbandonedRetentionDays;
    INSERT INTO @rpRes  EXEC dbo.s0085PurgeReturnedPayments        @RetentionDays = @ReturnedPaymentRetentionDays;
    INSERT INTO @duRes  EXEC dbo.s0086PurgeDeactivatedAbonneUsers  @RetentionDays = @DeactivatedUserRetentionDays;

    SELECT
        ISNULL((SELECT TOP 1 Purged FROM @tokRes), 0) AS PurgedTokens,
        ISNULL((SELECT TOP 1 Purged FROM @whRes),  0) AS PurgedWebhooks,
        ISNULL((SELECT TOP 1 Purged FROM @blRes),  0) AS PurgedBankLines,
        ISNULL((SELECT TOP 1 Purged FROM @ebRes),  0) AS PurgedEftBatches,
        ISNULL((SELECT TOP 1 Purged FROM @elRes),  0) AS PurgedExchangeLogs,
        ISNULL((SELECT TOP 1 Purged FROM @erRes),  0) AS PurgedEftReturns,
        ISNULL((SELECT TOP 1 Purged FROM @waRes),  0) AS PurgedAbandonedWebhooks,
        ISNULL((SELECT TOP 1 Purged FROM @rpRes),  0) AS PurgedReturnedPayments,
        ISNULL((SELECT TOP 1 Purged FROM @duRes),  0) AS PurgedDeactivatedUsers;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'34_deactivated_user_purge.sql : termine.';
GO
