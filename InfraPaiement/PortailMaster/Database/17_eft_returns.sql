/* =====================================================================
   PortailMaster - Script 17 : Retours / NSF (fichiers CPA-005 entrants)
   ---------------------------------------------------------------------
   La banque renvoie un fichier 005 de retour (enregistrements E = retour
   de credit, F = retour de debit) avec un code de motif. On rapproche
   chaque retour de la transaction d'origine (PaymentId embarque dans la
   reference croisee 'P'+id du fichier sortant) et on contre-passe.

   s0049ProcessReturn gere les 4 cas (Entrant/Sortant x Initie/Regle) :
     Entrant Initie  : DR SUBBAL(net)+DR FEES(fee) / CR EFT_IN(brut)
     Entrant Regle   : DR SUBBAL(net)+DR FEES(fee) / CR TRUST(brut)
     Sortant Initie  : DR EFT_OUT(mnt)+DR FEES(fee) / CR SUBBAL(mnt+fee)
     Sortant Regle   : DR TRUST(mnt)+DR FEES(fee)   / CR SUBBAL(mnt+fee)
   Invariant preserve dans les 4 cas. Le trigger T030 emet le webhook
   payment.returned / payout.returned.

   A executer APRES 16. Procs s0049+.
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---- Reference croisee = 'P'+PaymentId dans le fichier sortant (pour
        rapprocher les retours). Mise a jour de s0044CreateEftBatch. ---- */
CREATE OR ALTER PROCEDURE dbo.s0044CreateEftBatch
    @AdminId  INT = NULL,
    @BatchId  INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.T030Payment WHERE Status=N'Initie' AND BatchId IS NULL)
    BEGIN RAISERROR(N'Aucune transaction initiee a mettre en lot.', 16, 1); RETURN; END

    DECLARE @fcn INT = (SELECT NextFileCreationNumber FROM dbo.T052EftOriginator);
    IF @fcn IS NULL BEGIN RAISERROR(N'Config emetteur (T052EftOriginator) absente.', 16, 1); RETURN; END

    BEGIN TRAN;
    INSERT INTO dbo.T050EftBatch (FileCreationNumber, Status, CreatedByAdminId) VALUES (@fcn, N'Open', @AdminId);
    SET @BatchId = CAST(SCOPE_IDENTITY() AS INT);
    UPDATE dbo.T052EftOriginator SET NextFileCreationNumber = NextFileCreationNumber + 1;

    INSERT INTO dbo.T051EftBatchItem (BatchId, PaymentId, RecordType, AmountCents, CounterpartyName, BankInstitution, BankTransit, BankAccount, DueDate, CrossReference)
    SELECT @BatchId, p.Id, 'D', p.AmountCents, LEFT(c.Nom,30), c.BankInstitution, c.BankTransit, c.BankAccount, p.ExpectedSettlementDate, 'P' + RIGHT('0000000000' + CAST(p.Id AS VARCHAR(10)), 10)
    FROM dbo.T030Payment p JOIN dbo.T020Client c ON c.Id = p.ClientId
    WHERE p.Status=N'Initie' AND p.Direction=N'Entrant' AND p.BatchId IS NULL;

    INSERT INTO dbo.T051EftBatchItem (BatchId, PaymentId, RecordType, AmountCents, CounterpartyName, BankInstitution, BankTransit, BankAccount, DueDate, CrossReference)
    SELECT @BatchId, p.Id, 'C', p.AmountCents, LEFT(f.Nom,30), f.BankInstitution, f.BankTransit, f.BankAccount, p.ExpectedSettlementDate, 'P' + RIGHT('0000000000' + CAST(p.Id AS VARCHAR(10)), 10)
    FROM dbo.T030Payment p JOIN dbo.T021Fournisseur f ON f.Id = p.FournisseurId
    WHERE p.Status=N'Initie' AND p.Direction=N'Sortant' AND p.BatchId IS NULL;

    UPDATE p SET p.BatchId = @BatchId
    FROM dbo.T030Payment p JOIN dbo.T051EftBatchItem i ON i.PaymentId = p.Id WHERE i.BatchId = @BatchId;

    UPDATE b SET
        TotalDebitCents  = ISNULL((SELECT SUM(AmountCents) FROM dbo.T051EftBatchItem WHERE BatchId=@BatchId AND RecordType='D'),0),
        TotalCreditCents = ISNULL((SELECT SUM(AmountCents) FROM dbo.T051EftBatchItem WHERE BatchId=@BatchId AND RecordType='C'),0),
        CountDebit  = (SELECT COUNT(*) FROM dbo.T051EftBatchItem WHERE BatchId=@BatchId AND RecordType='D'),
        CountCredit = (SELECT COUNT(*) FROM dbo.T051EftBatchItem WHERE BatchId=@BatchId AND RecordType='C')
    FROM dbo.T050EftBatch b WHERE b.Id=@BatchId;

    COMMIT;
    SELECT @BatchId AS BatchId;
END
GO

/* ---- s0049ProcessReturn : contre-passation (4 cas). ---- */
CREATE OR ALTER PROCEDURE dbo.s0049ProcessReturn
    @PaymentId    BIGINT,
    @Reason       NVARCHAR(100) = N'Retour',
    @AdminId      INT           = NULL,
    @ReturnTxnId  BIGINT        = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ReturnTxnId = NULL;

    DECLARE @AbonneId INT, @Amount BIGINT, @Fee BIGINT, @Status NVARCHAR(20), @Dir NVARCHAR(10);
    SELECT @AbonneId=AbonneId, @Amount=AmountCents, @Fee=FeeCents, @Status=Status, @Dir=Direction
    FROM dbo.T030Payment WHERE Id=@PaymentId;

    IF @AbonneId IS NULL BEGIN RAISERROR(N'Paiement introuvable.',16,1); RETURN; END
    IF @Status = N'Retourne' BEGIN RAISERROR(N'Transaction deja retournee.',16,1); RETURN; END
    IF @Status NOT IN (N'Initie', N'Regle') BEGIN RAISERROR(N'Statut non retournable.',16,1); RETURN; END

    DECLARE @trust  INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId IS NULL AND AccountCode='TRUST');
    DECLARE @fees   INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId IS NULL AND AccountCode='FEES');
    DECLARE @subbal INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId=@AbonneId AND AccountCode='SUBBAL');
    DECLARE @eftIn  INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId=@AbonneId AND AccountCode='EFT_IN');
    DECLARE @eftOut INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId=@AbonneId AND AccountCode='EFT_OUT');
    DECLARE @net BIGINT = @Amount - @Fee, @total BIGINT = @Amount + @Fee;

    BEGIN TRAN;
    INSERT INTO dbo.T101LedgerTransaction (AbonneId, TxnType, Description, CreatedByAdminId)
    VALUES (@AbonneId, CASE WHEN @Dir=N'Entrant' THEN N'PaiementRetourne' ELSE N'DecaissementRetourne' END, @Reason, @AdminId);
    SET @ReturnTxnId = CAST(SCOPE_IDENTITY() AS BIGINT);

    IF @Dir = N'Entrant'
    BEGIN
        DECLARE @src INT = CASE WHEN @Status=N'Initie' THEN @eftIn ELSE @trust END;
        INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
        VALUES (@ReturnTxnId, @subbal, @net, 0), (@ReturnTxnId, @src, 0, @Amount);
        IF @Fee > 0 INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents) VALUES (@ReturnTxnId, @fees, @Fee, 0);
    END
    ELSE
    BEGIN
        DECLARE @src2 INT = CASE WHEN @Status=N'Initie' THEN @eftOut ELSE @trust END;
        INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
        VALUES (@ReturnTxnId, @src2, @Amount, 0), (@ReturnTxnId, @subbal, 0, @total);
        IF @Fee > 0 INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents) VALUES (@ReturnTxnId, @fees, @Fee, 0);
    END

    IF (SELECT SUM(DebitCents)-SUM(CreditCents) FROM dbo.T102LedgerPosting WHERE TransactionId=@ReturnTxnId) <> 0
    BEGIN RAISERROR(N'Ecriture de retour desequilibree.',16,1); RETURN; END

    UPDATE dbo.T030Payment
    SET Status=N'Retourne', ReturnTxnId=@ReturnTxnId, ReturnReason=@Reason, ReturnedUtc=SYSUTCDATETIME()
    WHERE Id=@PaymentId;

    COMMIT;
    SELECT @ReturnTxnId AS ReturnTxnId;
END
GO

/* ---- Journal des retours importes ---- */
IF OBJECT_ID(N'dbo.T053EftReturn', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T053EftReturn
    (
        Id            INT           IDENTITY(1,1) NOT NULL,
        PaymentId     BIGINT        NULL,
        RecordType    CHAR(1)       NULL,          -- E (retour credit) / F (retour debit)
        AmountCents   BIGINT        NULL,
        ReasonCode    NVARCHAR(3)   NULL,
        CrossRef      NVARCHAR(19)  NULL,
        FileName      NVARCHAR(100) NULL,
        Status        NVARCHAR(20)  NOT NULL,      -- Processed / Unmatched / AmountMismatch / AlreadyReturned / Error
        Message       NVARCHAR(300) NULL,
        ReturnTxnId   BIGINT        NULL,
        ImportedUtc   DATETIME2(0)  NOT NULL CONSTRAINT DF_T053_Imported DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_T053EftReturn PRIMARY KEY CLUSTERED (Id)
    );
    CREATE INDEX IX_T053_Payment ON dbo.T053EftReturn (PaymentId);
END
GO

CREATE OR ALTER PROCEDURE dbo.s0050SaveEftReturn
    @PaymentId BIGINT = NULL, @RecordType CHAR(1) = NULL, @AmountCents BIGINT = NULL,
    @ReasonCode NVARCHAR(3) = NULL, @CrossRef NVARCHAR(19) = NULL, @FileName NVARCHAR(100) = NULL,
    @Status NVARCHAR(20), @Message NVARCHAR(300) = NULL, @ReturnTxnId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.T053EftReturn (PaymentId, RecordType, AmountCents, ReasonCode, CrossRef, FileName, Status, Message, ReturnTxnId)
    VALUES (@PaymentId, @RecordType, @AmountCents, @ReasonCode, @CrossRef, @FileName, @Status, @Message, @ReturnTxnId);
END
GO

CREATE OR ALTER PROCEDURE dbo.s0051ListEftReturns
    @Top INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top) Id, PaymentId, RecordType, AmountCents, ReasonCode, CrossRef, FileName, Status, Message, ReturnTxnId, ImportedUtc
    FROM dbo.T053EftReturn ORDER BY Id DESC;
END
GO

/* Retourne la transaction pour rapprochement (montant + statut). */
CREATE OR ALTER PROCEDURE dbo.s0052GetPaymentForReturn
    @PaymentId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, AbonneId, Direction, AmountCents, Status FROM dbo.T030Payment WHERE Id = @PaymentId;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'17_eft_returns.sql : termine.';
GO
