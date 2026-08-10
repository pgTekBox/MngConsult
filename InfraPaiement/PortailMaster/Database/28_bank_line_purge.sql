/* =====================================================================
   PortailMaster - Script 28 : purge des lignes de relevé RAPPROCHÉES
   ---------------------------------------------------------------------
   Les lignes de relevé bancaire (T061BankStatementLine) une fois
   RAPPROCHÉES (Status=Matched) ont joué leur rôle et peuvent être purgées
   au-delà d'une rétention. Les lignes Unmatched (à traiter) et Ignored
   (écartées manuellement) sont CONSERVÉES.

   ⚠️ Interaction : s0060/s0062 déduisent « quel mouvement du grand livre est
   rapproché » via T061.MatchedTxnId. Supprimer une ligne Matched ferait donc
   RÉAPPARAÎTRE son mouvement comme non rapproché. Pour l'éviter, la
   réconciliation est bornée à un HORIZON récent (@HorizonDays) et la purge ne
   supprime que les lignes dont le mouvement est DÉJÀ hors de cet horizon.
   Règle : rétention de purge >= horizon de réconciliation (défaut 365 j pour
   les deux). Plateforme récente => aucun impact visible actuellement.

   s0080PurgeReconciledBankLines + maj s0060/s0062 (horizon) + maj s0079.
   A executer APRES 20 (T061) et 27 (s0079). Procs numerotees s0080+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   s0060ListUnmatchedTrustMovements : + borne d'horizon (défaut 365 j).
   Ne considère que les mouvements TRUST récents (les plus anciens sont
   réputés archivés et ne réapparaissent pas après purge des lignes).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0060ListUnmatchedTrustMovements
    @Top         INT = 100,
    @HorizonDays INT = 365
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @minDate DATE = DATEADD(DAY, -@HorizonDays, CAST(SYSUTCDATETIME() AS DATE));

    SELECT TOP (@Top) t.Id, t.EffectiveDate, t.TxnType, t.Description,
           SUM(p.DebitCents - p.CreditCents) AS NetCents
    FROM dbo.T101LedgerTransaction t
    JOIN dbo.T102LedgerPosting p ON p.TransactionId = t.Id
    JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId AND a.AbonneId IS NULL AND a.AccountCode = 'TRUST'
    WHERE t.Id NOT IN (SELECT MatchedTxnId FROM dbo.T061BankStatementLine WHERE MatchedTxnId IS NOT NULL)
      AND t.EffectiveDate >= @minDate
    GROUP BY t.Id, t.EffectiveDate, t.TxnType, t.Description
    HAVING SUM(p.DebitCents - p.CreditCents) <> 0
    ORDER BY t.EffectiveDate, t.Id;
END
GO

/* ---------------------------------------------------------------------
   s0062GetReconSummary : + borne d'horizon sur le COMPTEUR de mouvements
   non rapprochés (les soldes cumulés ledger/relevé restent complets).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0062GetReconSummary
    @HorizonDays INT = 365
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @minDate DATE = DATEADD(DAY, -@HorizonDays, CAST(SYSUTCDATETIME() AS DATE));

    DECLARE @ledger BIGINT = (SELECT ISNULL(SUM(p.DebitCents - p.CreditCents),0)
        FROM dbo.T102LedgerPosting p JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId
        WHERE a.AbonneId IS NULL AND a.AccountCode = 'TRUST');
    DECLARE @stmt BIGINT = (SELECT ISNULL(SUM(AmountCents),0) FROM dbo.T061BankStatementLine WHERE Status <> N'Ignored');
    DECLARE @unmMov INT = (SELECT COUNT(*) FROM (
        SELECT t.Id FROM dbo.T101LedgerTransaction t
        JOIN dbo.T102LedgerPosting p ON p.TransactionId = t.Id
        JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId AND a.AbonneId IS NULL AND a.AccountCode = 'TRUST'
        WHERE t.Id NOT IN (SELECT MatchedTxnId FROM dbo.T061BankStatementLine WHERE MatchedTxnId IS NOT NULL)
          AND t.EffectiveDate >= @minDate
        GROUP BY t.Id HAVING SUM(p.DebitCents - p.CreditCents) <> 0) x);
    SELECT
        @ledger AS LedgerTrustCents,
        @stmt AS StatementTotalCents,
        (@ledger - @stmt) AS DiffCents,
        (SELECT COUNT(*) FROM dbo.T061BankStatementLine WHERE Status = N'Unmatched') AS UnmatchedLines,
        (SELECT COUNT(*) FROM dbo.T061BankStatementLine WHERE Status = N'Matched') AS MatchedLines,
        @unmMov AS UnmatchedMovements;
END
GO

/* ---------------------------------------------------------------------
   s0080PurgeReconciledBankLines : supprime les lignes RAPPROCHÉES anciennes
   dont le mouvement du grand livre est lui aussi hors de l'horizon (donc
   déjà exclu de la réconciliation) — aucune réapparition possible.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0080PurgeReconciledBankLines
    @RetentionDays INT = 365
AS
BEGIN
    SET NOCOUNT ON;
    IF @RetentionDays IS NULL OR @RetentionDays < 0 SET @RetentionDays = 365;
    DECLARE @cutoffUtc DATETIME2(0) = DATEADD(DAY, -@RetentionDays, SYSUTCDATETIME());
    DECLARE @cutoffDate DATE        = CAST(@cutoffUtc AS DATE);

    DELETE bl
    FROM dbo.T061BankStatementLine bl
    LEFT JOIN dbo.T101LedgerTransaction t ON t.Id = bl.MatchedTxnId
    WHERE bl.Status = N'Matched'
      AND bl.ImportedUtc < @cutoffUtc
      AND (t.Id IS NULL OR t.EffectiveDate < @cutoffDate);

    SELECT @@ROWCOUNT AS Purged;
END
GO

/* ---------------------------------------------------------------------
   s0079RunDailyMaintenance : + purge des lignes de relevé rapprochées.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0079RunDailyMaintenance
    @WebhookRetentionDays  INT = 30,
    @BankLineRetentionDays INT = 365
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tokRes  TABLE (Purged INT);
    DECLARE @whRes   TABLE (Purged INT);
    DECLARE @blRes   TABLE (Purged INT);

    INSERT INTO @tokRes EXEC dbo.s0077PurgeExpiredRememberTokens;
    INSERT INTO @whRes  EXEC dbo.s0078PurgeDeliveredWebhooks     @RetentionDays = @WebhookRetentionDays;
    INSERT INTO @blRes  EXEC dbo.s0080PurgeReconciledBankLines   @RetentionDays = @BankLineRetentionDays;

    SELECT
        ISNULL((SELECT TOP 1 Purged FROM @tokRes), 0) AS PurgedTokens,
        ISNULL((SELECT TOP 1 Purged FROM @whRes),  0) AS PurgedWebhooks,
        ISNULL((SELECT TOP 1 Purged FROM @blRes),  0) AS PurgedBankLines;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'28_bank_line_purge.sql : termine.';
GO
