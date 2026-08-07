/* =====================================================================
   PortailMaster - Script 20 : Rapprochement bancaire (compte fiducie)
   ---------------------------------------------------------------------
   Confronte les mouvements du compte TRUST (fiducie) du grand livre au
   relevé bancaire réel. On importe les lignes du relevé, puis on les
   rapproche des écritures du grand livre affectant TRUST (par montant
   signé + date). L'écart livre ↔ relevé doit tendre vers 0.

   Signe des montants : + = crédit/dépôt (entrée en fiducie), - = débit/
   retrait. Côté livre, net TRUST = SUM(Debit - Credit) d'une écriture.
   Procs s0058+.
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.T061BankStatementLine', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T061BankStatementLine
    (
        Id            INT           IDENTITY(1,1) NOT NULL,
        TxnDate       DATE          NOT NULL,
        Description   NVARCHAR(200) NULL,
        AmountCents   BIGINT        NOT NULL,        -- signé : + dépôt, - retrait
        Reference     NVARCHAR(100) NULL,
        Status        NVARCHAR(20)  NOT NULL CONSTRAINT DF_T061_Status DEFAULT (N'Unmatched'), -- Unmatched/Matched/Ignored
        MatchedTxnId  BIGINT        NULL,            -- écriture du grand livre rapprochée
        FileName      NVARCHAR(100) NULL,
        ImportedUtc   DATETIME2(0)  NOT NULL CONSTRAINT DF_T061_Imported DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_T061BankStatementLine PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_T061_Txn FOREIGN KEY (MatchedTxnId) REFERENCES dbo.T101LedgerTransaction(Id)
    );
    CREATE INDEX IX_T061_Status ON dbo.T061BankStatementLine (Status, TxnDate);
END
GO

/* --- s0058SaveBankLine : insère une ligne de relevé. --- */
CREATE OR ALTER PROCEDURE dbo.s0058SaveBankLine
    @TxnDate DATE, @Description NVARCHAR(200) = NULL, @AmountCents BIGINT,
    @Reference NVARCHAR(100) = NULL, @FileName NVARCHAR(100) = NULL,
    @Id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.T061BankStatementLine (TxnDate, Description, AmountCents, Reference, FileName)
    VALUES (@TxnDate, @Description, @AmountCents, @Reference, @FileName);
    SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    SELECT @Id AS Id;
END
GO

/* --- s0059ListBankLines --- */
CREATE OR ALTER PROCEDURE dbo.s0059ListBankLines
    @Top INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top) Id, TxnDate, Description, AmountCents, Reference, Status, MatchedTxnId, FileName, ImportedUtc
    FROM dbo.T061BankStatementLine ORDER BY TxnDate DESC, Id DESC;
END
GO

/* --- s0060ListUnmatchedTrustMovements : écritures TRUST non rapprochées. --- */
CREATE OR ALTER PROCEDURE dbo.s0060ListUnmatchedTrustMovements
    @Top INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top) t.Id, t.EffectiveDate, t.TxnType, t.Description,
           SUM(p.DebitCents - p.CreditCents) AS NetCents
    FROM dbo.T101LedgerTransaction t
    JOIN dbo.T102LedgerPosting p ON p.TransactionId = t.Id
    JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId AND a.AbonneId IS NULL AND a.AccountCode = 'TRUST'
    WHERE t.Id NOT IN (SELECT MatchedTxnId FROM dbo.T061BankStatementLine WHERE MatchedTxnId IS NOT NULL)
    GROUP BY t.Id, t.EffectiveDate, t.TxnType, t.Description
    HAVING SUM(p.DebitCents - p.CreditCents) <> 0
    ORDER BY t.EffectiveDate, t.Id;
END
GO

/* --- s0061RunReconciliation : rapproche les lignes non rapprochées
       aux mouvements TRUST (montant égal, date dans la fenêtre). --- */
CREATE OR ALTER PROCEDURE dbo.s0061RunReconciliation
    @WindowDays INT = 3,
    @NbMatched  INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @used TABLE (TxnId BIGINT PRIMARY KEY);
    INSERT INTO @used SELECT MatchedTxnId FROM dbo.T061BankStatementLine WHERE MatchedTxnId IS NOT NULL;
    SET @NbMatched = 0;

    DECLARE @lineId INT, @amt BIGINT, @dt DATE, @txn BIGINT;
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Id, AmountCents, TxnDate FROM dbo.T061BankStatementLine WHERE Status = N'Unmatched' ORDER BY Id;
    OPEN cur; FETCH NEXT FROM cur INTO @lineId, @amt, @dt;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @txn = NULL;
        ;WITH mov AS (
            SELECT t.Id, t.EffectiveDate, SUM(p.DebitCents - p.CreditCents) AS Net
            FROM dbo.T101LedgerTransaction t
            JOIN dbo.T102LedgerPosting p ON p.TransactionId = t.Id
            JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId AND a.AbonneId IS NULL AND a.AccountCode = 'TRUST'
            WHERE t.Id NOT IN (SELECT TxnId FROM @used)
            GROUP BY t.Id, t.EffectiveDate
        )
        SELECT TOP 1 @txn = Id FROM mov
        WHERE Net = @amt AND ABS(DATEDIFF(DAY, EffectiveDate, @dt)) <= @WindowDays
        ORDER BY ABS(DATEDIFF(DAY, EffectiveDate, @dt)), Id;

        IF @txn IS NOT NULL
        BEGIN
            UPDATE dbo.T061BankStatementLine SET Status = N'Matched', MatchedTxnId = @txn WHERE Id = @lineId;
            INSERT INTO @used VALUES (@txn);
            SET @NbMatched = @NbMatched + 1;
        END
        FETCH NEXT FROM cur INTO @lineId, @amt, @dt;
    END
    CLOSE cur; DEALLOCATE cur;
    SELECT @NbMatched AS NbMatched;
END
GO

/* --- s0062GetReconSummary : soldes et compteurs. --- */
CREATE OR ALTER PROCEDURE dbo.s0062GetReconSummary
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ledger BIGINT = (SELECT ISNULL(SUM(p.DebitCents - p.CreditCents),0)
        FROM dbo.T102LedgerPosting p JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId
        WHERE a.AbonneId IS NULL AND a.AccountCode = 'TRUST');
    DECLARE @stmt BIGINT = (SELECT ISNULL(SUM(AmountCents),0) FROM dbo.T061BankStatementLine WHERE Status <> N'Ignored');
    DECLARE @unmMov INT = (SELECT COUNT(*) FROM (
        SELECT t.Id FROM dbo.T101LedgerTransaction t
        JOIN dbo.T102LedgerPosting p ON p.TransactionId = t.Id
        JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId AND a.AbonneId IS NULL AND a.AccountCode = 'TRUST'
        WHERE t.Id NOT IN (SELECT MatchedTxnId FROM dbo.T061BankStatementLine WHERE MatchedTxnId IS NOT NULL)
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

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'20_rapprochement.sql : termine.';
GO
