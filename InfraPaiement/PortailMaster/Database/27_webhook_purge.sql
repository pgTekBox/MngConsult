/* =====================================================================
   PortailMaster - Script 27 : purge des livraisons de webhooks livrees
                                + orchestrateur de maintenance quotidienne
   ---------------------------------------------------------------------
   Les livraisons de webhooks (T042WebhookDelivery) s'accumulent : une fois
   LIVREES (Status=Delivered) elles n'ont plus d'utilite operationnelle et
   peuvent etre purgees au-dela d'une periode de retention. Les livraisons
   Pending (a renvoyer) et Abandoned (echecs, valeur diagnostique + visibles
   dans la Supervision) sont CONSERVEES.

   s0078PurgeDeliveredWebhooks : purge (retention parametrable).
   s0079RunDailyMaintenance    : orchestrateur (jetons remember-me + webhooks),
                                 appele par le planificateur.

   A executer APRES 10 (T042) et 26 (s0077). Procs numerotees s0078+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   s0078PurgeDeliveredWebhooks : supprime les livraisons LIVREES dont la
   date de livraison depasse la retention (defaut 30 jours). Renvoie le
   nombre de lignes supprimees.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0078PurgeDeliveredWebhooks
    @RetentionDays INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    IF @RetentionDays IS NULL OR @RetentionDays < 0 SET @RetentionDays = 30;

    DELETE FROM dbo.T042WebhookDelivery
    WHERE Status = N'Delivered'
      AND DeliveredUtc IS NOT NULL
      AND DeliveredUtc < DATEADD(DAY, -@RetentionDays, SYSUTCDATETIME());

    SELECT @@ROWCOUNT AS Purged;
END
GO

/* ---------------------------------------------------------------------
   s0079RunDailyMaintenance : regroupe les taches d'hygiene quotidiennes.
   Reutilise les procs de purge (source unique de la logique) et renvoie
   une ligne de synthese. Point d'extension pour de futures purges.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0079RunDailyMaintenance
    @WebhookRetentionDays INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tokRes TABLE (Purged INT);
    DECLARE @whRes  TABLE (Purged INT);

    INSERT INTO @tokRes EXEC dbo.s0077PurgeExpiredRememberTokens;
    INSERT INTO @whRes  EXEC dbo.s0078PurgeDeliveredWebhooks @RetentionDays = @WebhookRetentionDays;

    SELECT
        ISNULL((SELECT TOP 1 Purged FROM @tokRes), 0) AS PurgedTokens,
        ISNULL((SELECT TOP 1 Purged FROM @whRes),  0) AS PurgedWebhooks;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'27_webhook_purge.sql : termine.';
GO
