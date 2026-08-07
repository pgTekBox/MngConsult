/* =====================================================================
   PortailMaster - Script 08 : Flux de paiement EFT (clearing simule)
   ---------------------------------------------------------------------
   Encaissement d'un client par EFT (debit du compte bancaire du client).
   Cycle de vie :
     Initie   : DR EFT_IN (brut) / CR SUBBAL (net) + CR FEES (frais)
     Regle    : DR TRUST (brut)  / CR EFT_IN (brut)      [reglement T+2]
     Retourne : DR SUBBAL (net) + DR FEES (frais) / CR EFT_IN (brut)  [NSF]
   Le connecteur bancaire est SIMULE (regle par lot les paiements echus ;
   les retours NSF sont declenches manuellement).

   A executer APRES 01-07. Procs numerotees s0020+.
   ===================================================================== */

USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   Table des paiements (objet metier a etats ; le grand livre reste, lui,
   immuable : chaque transition y ecrit une ecriture).
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.T030Payment', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T030Payment
    (
        Id                     BIGINT           IDENTITY(1,1) NOT NULL,
        PaymentGUID            UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_T030_Guid DEFAULT (NEWID()),
        AbonneId               INT              NOT NULL,
        ClientId               INT              NULL,               -- payeur (T020Client)
        Direction              NVARCHAR(10)     NOT NULL CONSTRAINT DF_T030_Dir DEFAULT (N'Entrant'), -- Entrant / Sortant
        Method                 NVARCHAR(20)     NOT NULL CONSTRAINT DF_T030_Method DEFAULT (N'EFT'),
        AmountCents            BIGINT           NOT NULL,           -- brut
        FeeCents               BIGINT           NOT NULL CONSTRAINT DF_T030_Fee DEFAULT (0),
        NetCents               AS (AmountCents - FeeCents) PERSISTED,
        Devise                 CHAR(3)          NOT NULL CONSTRAINT DF_T030_Devise DEFAULT ('CAD'),
        Status                 NVARCHAR(20)     NOT NULL CONSTRAINT DF_T030_Status DEFAULT (N'Initie'), -- Initie/Regle/Retourne
        Description            NVARCHAR(300)    NULL,
        Reference              NVARCHAR(100)    NULL,
        IdempotencyKey         NVARCHAR(100)    NULL,
        ExpectedSettlementDate DATE             NULL,
        InitiationTxnId        BIGINT           NULL,
        SettlementTxnId        BIGINT           NULL,
        ReturnTxnId            BIGINT           NULL,
        ReturnReason           NVARCHAR(100)    NULL,
        InitiatedUtc           DATETIME2(0)     NOT NULL CONSTRAINT DF_T030_Init DEFAULT (SYSUTCDATETIME()),
        SettledUtc             DATETIME2(0)     NULL,
        ReturnedUtc            DATETIME2(0)     NULL,
        CreatedByAdminId       INT              NULL,
        CONSTRAINT PK_T030Payment PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UX_T030_Guid UNIQUE (PaymentGUID),
        CONSTRAINT CK_T030_Amount CHECK (AmountCents > 0 AND FeeCents >= 0 AND FeeCents <= AmountCents),
        CONSTRAINT FK_T030_Abonne FOREIGN KEY (AbonneId) REFERENCES dbo.T010Abonne(Id),
        CONSTRAINT FK_T030_Client FOREIGN KEY (ClientId) REFERENCES dbo.T020Client(Id),
        CONSTRAINT FK_T030_Admin  FOREIGN KEY (CreatedByAdminId) REFERENCES dbo.T001PortalAdmin(Id),
        CONSTRAINT FK_T030_InitTxn FOREIGN KEY (InitiationTxnId) REFERENCES dbo.T101LedgerTransaction(Id),
        CONSTRAINT FK_T030_SetlTxn FOREIGN KEY (SettlementTxnId) REFERENCES dbo.T101LedgerTransaction(Id),
        CONSTRAINT FK_T030_RetTxn  FOREIGN KEY (ReturnTxnId)     REFERENCES dbo.T101LedgerTransaction(Id)
    );
    CREATE UNIQUE INDEX UX_T030_Idempotency ON dbo.T030Payment (IdempotencyKey) WHERE IdempotencyKey IS NOT NULL;
    CREATE INDEX IX_T030_Abonne ON dbo.T030Payment (AbonneId, Id);
    CREATE INDEX IX_T030_Due    ON dbo.T030Payment (Status, ExpectedSettlementDate);
END
GO

/* =====================================================================
   PROCEDURES
   ===================================================================== */

/* --- s0020InitiateClientPayment : cree un paiement + ecriture d'initiation.
       Idempotent via @IdempotencyKey. Renvoie l'Id du paiement.          */
CREATE OR ALTER PROCEDURE dbo.s0020InitiateClientPayment
    @AbonneId       INT,
    @ClientId       INT,
    @AmountCents    BIGINT,
    @FeeCents       BIGINT        = 0,
    @Description    NVARCHAR(300) = NULL,
    @Reference      NVARCHAR(100) = NULL,
    @SettlementDays INT           = 2,
    @IdempotencyKey NVARCHAR(100) = NULL,
    @AdminId        INT           = NULL,
    @PaymentId      BIGINT        = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @PaymentId = NULL;

    IF @AbonneId IS NULL BEGIN RAISERROR(N'AbonneId est requis.',16,1); RETURN; END
    IF @AmountCents IS NULL OR @AmountCents <= 0 BEGIN RAISERROR(N'Le montant doit etre superieur a zero.',16,1); RETURN; END
    IF @FeeCents IS NULL SET @FeeCents = 0;
    IF @FeeCents < 0 OR @FeeCents > @AmountCents BEGIN RAISERROR(N'Frais invalides.',16,1); RETURN; END

    -- Idempotence
    IF @IdempotencyKey IS NOT NULL
    BEGIN
        SELECT @PaymentId = Id FROM dbo.T030Payment WHERE IdempotencyKey = @IdempotencyKey;
        IF @PaymentId IS NOT NULL BEGIN SELECT @PaymentId AS PaymentId; RETURN; END
    END

    -- Le client doit appartenir a l'abonne (isolation).
    IF @ClientId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.T020Client WHERE Id = @ClientId AND AbonneId = @AbonneId)
    BEGIN RAISERROR(N'Client invalide pour cet abonne.',16,1); RETURN; END

    EXEC dbo.s0014EnsureAbonneAccounts @AbonneId;
    DECLARE @eftIn  INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'EFT_IN');
    DECLARE @subbal INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'SUBBAL');
    DECLARE @fees   INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId IS NULL AND AccountCode = 'FEES');

    DECLARE @net BIGINT = @AmountCents - @FeeCents;

    BEGIN TRAN;

    -- Ecriture d'initiation : DR EFT_IN (brut) / CR SUBBAL (net) + CR FEES (frais)
    DECLARE @txn BIGINT;
    INSERT INTO dbo.T101LedgerTransaction (AbonneId, TxnType, Description, CreatedByAdminId)
    VALUES (@AbonneId, N'PaiementInitie', @Description, @AdminId);
    SET @txn = CAST(SCOPE_IDENTITY() AS BIGINT);

    INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
    VALUES (@txn, @eftIn,  @AmountCents, 0),
           (@txn, @subbal, 0, @net);
    IF @FeeCents > 0
        INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
        VALUES (@txn, @fees, 0, @FeeCents);

    IF (SELECT SUM(DebitCents) - SUM(CreditCents) FROM dbo.T102LedgerPosting WHERE TransactionId = @txn) <> 0
    BEGIN RAISERROR(N'Ecriture desequilibree.',16,1); RETURN; END

    INSERT INTO dbo.T030Payment (AbonneId, ClientId, Direction, Method, AmountCents, FeeCents,
                                 Status, Description, Reference, IdempotencyKey,
                                 ExpectedSettlementDate, InitiationTxnId, CreatedByAdminId)
    VALUES (@AbonneId, @ClientId, N'Entrant', N'EFT', @AmountCents, @FeeCents,
            N'Initie', @Description, @Reference, @IdempotencyKey,
            DATEADD(DAY, @SettlementDays, CAST(SYSUTCDATETIME() AS DATE)), @txn, @AdminId);
    SET @PaymentId = CAST(SCOPE_IDENTITY() AS BIGINT);

    COMMIT;
    SELECT @PaymentId AS PaymentId;
END
GO

/* --- s0021SettlePayment : reglement (connecteur simule).
       DR TRUST / CR EFT_IN. Idempotent (deja Regle => noop).             */
CREATE OR ALTER PROCEDURE dbo.s0021SettlePayment
    @PaymentId BIGINT,
    @AdminId   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AbonneId INT, @Amount BIGINT, @Status NVARCHAR(20);
    SELECT @AbonneId = AbonneId, @Amount = AmountCents, @Status = Status
    FROM dbo.T030Payment WHERE Id = @PaymentId;

    IF @AbonneId IS NULL BEGIN RAISERROR(N'Paiement introuvable.',16,1); RETURN; END
    IF @Status = N'Regle' RETURN;                       -- idempotent
    IF @Status <> N'Initie' BEGIN RAISERROR(N'Seul un paiement initie peut etre regle.',16,1); RETURN; END

    DECLARE @trust INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId IS NULL AND AccountCode = 'TRUST');
    DECLARE @eftIn INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'EFT_IN');

    BEGIN TRAN;
    DECLARE @txn BIGINT;
    INSERT INTO dbo.T101LedgerTransaction (AbonneId, TxnType, Description, CreatedByAdminId)
    VALUES (@AbonneId, N'PaiementRegle', N'Reglement EFT', @AdminId);
    SET @txn = CAST(SCOPE_IDENTITY() AS BIGINT);

    INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
    VALUES (@txn, @trust, @Amount, 0),
           (@txn, @eftIn, 0, @Amount);

    UPDATE dbo.T030Payment
    SET Status = N'Regle', SettlementTxnId = @txn, SettledUtc = SYSUTCDATETIME()
    WHERE Id = @PaymentId;

    COMMIT;
END
GO

/* --- s0022ReturnPayment : retour / NSF sur un paiement initie.
       DR SUBBAL (net) + DR FEES (frais) / CR EFT_IN (brut).              */
CREATE OR ALTER PROCEDURE dbo.s0022ReturnPayment
    @PaymentId BIGINT,
    @Reason    NVARCHAR(100) = N'NSF',
    @AdminId   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AbonneId INT, @Amount BIGINT, @Fee BIGINT, @Status NVARCHAR(20);
    SELECT @AbonneId = AbonneId, @Amount = AmountCents, @Fee = FeeCents, @Status = Status
    FROM dbo.T030Payment WHERE Id = @PaymentId;

    IF @AbonneId IS NULL BEGIN RAISERROR(N'Paiement introuvable.',16,1); RETURN; END
    IF @Status <> N'Initie' BEGIN RAISERROR(N'Seul un paiement initie peut etre retourne.',16,1); RETURN; END

    DECLARE @eftIn  INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'EFT_IN');
    DECLARE @subbal INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'SUBBAL');
    DECLARE @fees   INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId IS NULL AND AccountCode = 'FEES');
    DECLARE @net BIGINT = @Amount - @Fee;

    BEGIN TRAN;
    DECLARE @txn BIGINT;
    INSERT INTO dbo.T101LedgerTransaction (AbonneId, TxnType, Description, CreatedByAdminId)
    VALUES (@AbonneId, N'PaiementRetourne', @Reason, @AdminId);
    SET @txn = CAST(SCOPE_IDENTITY() AS BIGINT);

    INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
    VALUES (@txn, @subbal, @net, 0);
    IF @Fee > 0
        INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
        VALUES (@txn, @fees, @Fee, 0);
    INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
    VALUES (@txn, @eftIn, 0, @Amount);

    IF (SELECT SUM(DebitCents) - SUM(CreditCents) FROM dbo.T102LedgerPosting WHERE TransactionId = @txn) <> 0
    BEGIN RAISERROR(N'Ecriture desequilibree.',16,1); RETURN; END

    UPDATE dbo.T030Payment
    SET Status = N'Retourne', ReturnTxnId = @txn, ReturnReason = @Reason, ReturnedUtc = SYSUTCDATETIME()
    WHERE Id = @PaymentId;

    COMMIT;
END
GO

/* --- s0023ListPayments : paiements d'un abonne (filtrables). */
CREATE OR ALTER PROCEDURE dbo.s0023ListPayments
    @AbonneId INT,
    @Status   NVARCHAR(20) = NULL,
    @Search   NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  p.Id, p.PaymentGUID, p.ClientId, c.Nom AS ClientNom,
            p.Direction, p.Method, p.AmountCents, p.FeeCents, p.NetCents,
            p.Status, p.Description, p.Reference, p.ExpectedSettlementDate,
            p.InitiatedUtc, p.SettledUtc, p.ReturnedUtc, p.ReturnReason
    FROM    dbo.T030Payment p
    LEFT JOIN dbo.T020Client c ON c.Id = p.ClientId
    WHERE   p.AbonneId = @AbonneId
      AND   (@Status IS NULL OR @Status = N'' OR p.Status = @Status)
      AND   (@Search IS NULL OR @Search = N''
             OR c.Nom       LIKE N'%' + @Search + N'%'
             OR p.Reference LIKE N'%' + @Search + N'%'
             OR p.Description LIKE N'%' + @Search + N'%')
    ORDER BY p.Id DESC;
END
GO

/* --- s0024RunSettlementBatch : connecteur bancaire SIMULE. Regle tous les
       paiements Initie echus (ExpectedSettlementDate <= aujourd'hui).
       @AbonneId NULL = tous les abonnes. Renvoie le nombre regle.         */
CREATE OR ALTER PROCEDURE dbo.s0024RunSettlementBatch
    @AbonneId INT = NULL,
    @AdminId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @today DATE = CAST(SYSUTCDATETIME() AS DATE);
    DECLARE @n INT = 0, @pid BIGINT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Id FROM dbo.T030Payment
        WHERE Status = N'Initie'
          AND ExpectedSettlementDate <= @today
          AND (@AbonneId IS NULL OR AbonneId = @AbonneId)
        ORDER BY Id;
    OPEN cur; FETCH NEXT FROM cur INTO @pid;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.s0021SettlePayment @PaymentId = @pid, @AdminId = @AdminId;
        SET @n = @n + 1;
        FETCH NEXT FROM cur INTO @pid;
    END
    CLOSE cur; DEALLOCATE cur;

    SELECT @n AS NbRegles;
END
GO

/* --- s0025GetPayment : detail d'un paiement (avec client + Ids d'ecritures). */
CREATE OR ALTER PROCEDURE dbo.s0025GetPayment
    @PaymentId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  p.*, c.Nom AS ClientNom
    FROM    dbo.T030Payment p
    LEFT JOIN dbo.T020Client c ON c.Id = p.ClientId
    WHERE   p.Id = @PaymentId;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'08_paiements.sql : termine.';
GO
