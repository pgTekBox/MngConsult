/* =====================================================================
   PortailMaster - Script 40 : Interac e-Transfer (rail parallèle, simulé)
   ---------------------------------------------------------------------
   Interac e-Transfer = virement quasi-instantané par courriel, distinct de
   l'EFT (lot T+2). Ici en mode SIMULÉ (le vrai Interac est gaté par le
   partenaire/banque). Réutilise TOUTE la machinerie de paiement (même flux
   au grand livre, clearing EFT_IN/EFT_OUT générique) via Method='Interac' ;
   la différence : règlement INDIVIDUEL (pas de lot 005) déclenché par une
   notification de dépôt (simulée), et une contrepartie identifiée par
   courriel Interac (stocké sur le paiement, saisi à l'initiation).

   Cycle : Initie (créé/envoyé) -> Regle (déposé/encaissé) -> Retourne
   (refusé/expiré, contre-passé via s0049).

   - T030Payment.InteracEmail (colonne)
   - s0020/s0038 : + @Method, @InteracEmail
   - s0097SettleInteracPayment (règlement individuel)
   - T056InteracEvent + s0098SaveInteracEvent / s0099ListInteracEvents
   - s0100ListInteracPayments
   A executer APRES 08/11. Procs numerotees s0097+.
   ===================================================================== */

USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.T030Payment', 'InteracEmail') IS NULL
    ALTER TABLE dbo.T030Payment ADD InteracEmail NVARCHAR(256) NULL;
GO

/* ---- s0020InitiateClientPayment : + @Method / @InteracEmail ---- */
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
    @Method         NVARCHAR(20)  = N'EFT',
    @InteracEmail   NVARCHAR(256) = NULL,
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
    IF @Method IS NULL SET @Method = N'EFT';

    IF @IdempotencyKey IS NOT NULL
    BEGIN
        SELECT @PaymentId = Id FROM dbo.T030Payment WHERE IdempotencyKey = @IdempotencyKey;
        IF @PaymentId IS NOT NULL BEGIN SELECT @PaymentId AS PaymentId; RETURN; END
    END

    IF @ClientId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.T020Client WHERE Id = @ClientId AND AbonneId = @AbonneId)
    BEGIN RAISERROR(N'Client invalide pour cet abonne.',16,1); RETURN; END

    EXEC dbo.s0014EnsureAbonneAccounts @AbonneId;
    DECLARE @eftIn  INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'EFT_IN');
    DECLARE @subbal INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'SUBBAL');
    DECLARE @fees   INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId IS NULL AND AccountCode = 'FEES');
    DECLARE @net BIGINT = @AmountCents - @FeeCents;

    BEGIN TRAN;
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
                                 ExpectedSettlementDate, InitiationTxnId, CreatedByAdminId, InteracEmail)
    VALUES (@AbonneId, @ClientId, N'Entrant', @Method, @AmountCents, @FeeCents,
            N'Initie', @Description, @Reference, @IdempotencyKey,
            DATEADD(DAY, @SettlementDays, CAST(SYSUTCDATETIME() AS DATE)), @txn, @AdminId, @InteracEmail);
    SET @PaymentId = CAST(SCOPE_IDENTITY() AS BIGINT);

    COMMIT;
    SELECT @PaymentId AS PaymentId;
END
GO

/* ---- s0038InitiatePayout : + @Method / @InteracEmail ---- */
CREATE OR ALTER PROCEDURE dbo.s0038InitiatePayout
    @AbonneId       INT,
    @FournisseurId  INT,
    @AmountCents    BIGINT,
    @FeeCents       BIGINT        = 0,
    @Description    NVARCHAR(300) = NULL,
    @Reference      NVARCHAR(100) = NULL,
    @SettlementDays INT           = 2,
    @IdempotencyKey NVARCHAR(100) = NULL,
    @AdminId        INT           = NULL,
    @Method         NVARCHAR(20)  = N'EFT',
    @InteracEmail   NVARCHAR(256) = NULL,
    @PaymentId      BIGINT        = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @PaymentId = NULL;

    IF @AbonneId IS NULL BEGIN RAISERROR(N'AbonneId est requis.',16,1); RETURN; END
    IF @AmountCents IS NULL OR @AmountCents <= 0 BEGIN RAISERROR(N'Le montant doit etre superieur a zero.',16,1); RETURN; END
    IF @FeeCents IS NULL SET @FeeCents = 0;
    IF @FeeCents < 0 BEGIN RAISERROR(N'Frais invalides.',16,1); RETURN; END
    IF @Method IS NULL SET @Method = N'EFT';

    IF @IdempotencyKey IS NOT NULL
    BEGIN
        SELECT @PaymentId = Id FROM dbo.T030Payment WHERE IdempotencyKey = @IdempotencyKey;
        IF @PaymentId IS NOT NULL BEGIN SELECT @PaymentId AS PaymentId; RETURN; END
    END

    IF @FournisseurId IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.T021Fournisseur WHERE Id = @FournisseurId AND AbonneId = @AbonneId)
    BEGIN RAISERROR(N'Fournisseur invalide pour cet abonne.',16,1); RETURN; END

    EXEC dbo.s0014EnsureAbonneAccounts @AbonneId;
    DECLARE @eftOut INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'EFT_OUT');
    DECLARE @subbal INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'SUBBAL');
    DECLARE @fees   INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId IS NULL AND AccountCode = 'FEES');

    DECLARE @total BIGINT = @AmountCents + @FeeCents;
    DECLARE @avail BIGINT = (SELECT ISNULL(SUM(CreditCents - DebitCents),0) FROM dbo.T102LedgerPosting WHERE AccountId = @subbal);
    IF @avail < @total BEGIN RAISERROR(N'Solde insuffisant pour ce decaissement.',16,1); RETURN; END

    BEGIN TRAN;
    DECLARE @txn BIGINT;
    INSERT INTO dbo.T101LedgerTransaction (AbonneId, TxnType, Description, CreatedByAdminId)
    VALUES (@AbonneId, N'DecaissementInitie', @Description, @AdminId);
    SET @txn = CAST(SCOPE_IDENTITY() AS BIGINT);

    INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
    VALUES (@txn, @subbal, @total, 0),
           (@txn, @eftOut, 0, @AmountCents);
    IF @FeeCents > 0
        INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
        VALUES (@txn, @fees, 0, @FeeCents);

    IF (SELECT SUM(DebitCents) - SUM(CreditCents) FROM dbo.T102LedgerPosting WHERE TransactionId = @txn) <> 0
    BEGIN RAISERROR(N'Ecriture desequilibree.',16,1); RETURN; END

    INSERT INTO dbo.T030Payment (AbonneId, ClientId, FournisseurId, Direction, Method, AmountCents, FeeCents,
                                 Status, Description, Reference, IdempotencyKey,
                                 ExpectedSettlementDate, InitiationTxnId, CreatedByAdminId, InteracEmail)
    VALUES (@AbonneId, NULL, @FournisseurId, N'Sortant', @Method, @AmountCents, @FeeCents,
            N'Initie', @Description, @Reference, @IdempotencyKey,
            DATEADD(DAY, @SettlementDays, CAST(SYSUTCDATETIME() AS DATE)), @txn, @AdminId, @InteracEmail);
    SET @PaymentId = CAST(SCOPE_IDENTITY() AS BIGINT);

    COMMIT;
    SELECT @PaymentId AS PaymentId;
END
GO

/* ---- s0097SettleInteracPayment : règlement individuel (dépôt/encaissement) ---- */
CREATE OR ALTER PROCEDURE dbo.s0097SettleInteracPayment
    @PaymentId BIGINT,
    @AdminId   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @dir NVARCHAR(10), @st NVARCHAR(20), @method NVARCHAR(20);
    SELECT @dir = Direction, @st = Status, @method = Method FROM dbo.T030Payment WHERE Id = @PaymentId;
    IF @dir IS NULL BEGIN RAISERROR(N'Paiement introuvable.',16,1); RETURN; END
    IF @method <> N'Interac' BEGIN RAISERROR(N'Ce paiement n''est pas un transfert Interac.',16,1); RETURN; END
    IF @st <> N'Initie' BEGIN RAISERROR(N'Seul un transfert initie peut etre depose/regle.',16,1); RETURN; END

    IF @dir = N'Entrant' EXEC dbo.s0021SettlePayment @PaymentId = @PaymentId, @AdminId = @AdminId;
    ELSE                 EXEC dbo.s0039SettlePayout  @PaymentId = @PaymentId, @AdminId = @AdminId;
    SELECT 1 AS Settled;
END
GO

/* ---- Journal d'évènements Interac ---- */
IF OBJECT_ID(N'dbo.T056InteracEvent', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T056InteracEvent
    (
        Id        BIGINT       IDENTITY(1,1) NOT NULL,
        PaymentId BIGINT       NULL,
        EventType NVARCHAR(20) NOT NULL,     -- Requested / Sent / Deposited / Declined / Expired
        Message   NVARCHAR(300) NULL,
        Utc       DATETIME2(0) NOT NULL CONSTRAINT DF_T056_Utc DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_T056InteracEvent PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_T056_Payment FOREIGN KEY (PaymentId) REFERENCES dbo.T030Payment(Id)
    );
    CREATE INDEX IX_T056_Payment ON dbo.T056InteracEvent (PaymentId, Id DESC);
END
GO

CREATE OR ALTER PROCEDURE dbo.s0098SaveInteracEvent
    @PaymentId BIGINT,
    @EventType NVARCHAR(20),
    @Message   NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.T056InteracEvent (PaymentId, EventType, Message)
    VALUES (@PaymentId, @EventType, @Message);
END
GO

CREATE OR ALTER PROCEDURE dbo.s0099ListInteracEvents
    @AbonneId INT = NULL,
    @Top      INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top) e.Id, e.PaymentId, e.EventType, e.Message, e.Utc
    FROM dbo.T056InteracEvent e
    LEFT JOIN dbo.T030Payment p ON p.Id = e.PaymentId
    WHERE (@AbonneId IS NULL OR p.AbonneId = @AbonneId)
    ORDER BY e.Id DESC;
END
GO

/* ---- s0100ListInteracPayments ---- */
CREATE OR ALTER PROCEDURE dbo.s0100ListInteracPayments
    @AbonneId INT = NULL,
    @Top      INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
        p.Id, p.AbonneId, p.Direction, p.AmountCents, p.FeeCents, p.NetCents, p.Status,
        p.Description, p.Reference, p.InteracEmail, p.InitiatedUtc, p.SettledUtc, p.ReturnedUtc,
        c.Nom AS ClientNom, f.Nom AS FournisseurNom
    FROM dbo.T030Payment p
    LEFT JOIN dbo.T020Client c      ON c.Id = p.ClientId
    LEFT JOIN dbo.T021Fournisseur f ON f.Id = p.FournisseurId
    WHERE p.Method = N'Interac'
      AND (@AbonneId IS NULL OR p.AbonneId = @AbonneId)
    ORDER BY p.Id DESC;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO
PRINT N'40_interac.sql : termine.';
GO
