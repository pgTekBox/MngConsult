/* =====================================================================
   PortailMaster / webAPI - Script 11 : Fournisseurs & decaissement sortant
   ---------------------------------------------------------------------
   L'abonne paie un FOURNISSEUR (beneficiaire) par EFT credit (money-out),
   via le compte de clearing EFT_OUT. Cycle (miroir de l'encaissement) :
     Initie   : DR SUBBAL (montant+frais) / CR EFT_OUT (montant) + CR FEES (frais)
     Regle    : DR EFT_OUT (montant) / CR TRUST (montant)      [reglement T+2]
     Retourne : DR EFT_OUT (montant) + DR FEES (frais) / CR SUBBAL (montant+frais)  [remboursement]

   Reutilise T030Payment (Direction='Sortant' + FournisseurId). Le trigger
   webhook devient direction-aware (payout.* vs payment.*). Le batch de
   reglement entrant (s0024) est restreint a Direction='Entrant'.

   A executer APRES 01-10. Procs s0035+.
   ===================================================================== */

USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   1) Fournisseurs (beneficiaires) — miroir des clients, scope par abonne
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.T021Fournisseur', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T021Fournisseur
    (
        Id                 INT              IDENTITY(1,1) NOT NULL,
        FournisseurGUID    UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_T021_Guid    DEFAULT (NEWID()),
        AbonneId           INT              NOT NULL,
        TypeFournisseur    NVARCHAR(20)     NOT NULL CONSTRAINT DF_T021_Type     DEFAULT (N'Entreprise'),
        Nom                NVARCHAR(200)    NOT NULL,
        ReferenceExterne   NVARCHAR(100)    NULL,
        CourrielContact    NVARCHAR(256)    NULL,
        Telephone          NVARCHAR(40)     NULL,
        Adresse1           NVARCHAR(200)    NULL,
        Adresse2           NVARCHAR(200)    NULL,
        Ville              NVARCHAR(120)    NULL,
        Province           NVARCHAR(60)     NULL,
        CodePostal         NVARCHAR(20)     NULL,
        Pays               NVARCHAR(60)     NOT NULL CONSTRAINT DF_T021_Pays     DEFAULT (N'Canada'),
        Statut             NVARCHAR(20)     NOT NULL CONSTRAINT DF_T021_Statut   DEFAULT (N'Actif'),
        Notes              NVARCHAR(MAX)    NULL,
        CreatedUtc         DATETIME2(0)     NOT NULL CONSTRAINT DF_T021_Created  DEFAULT (SYSUTCDATETIME()),
        CreatedByAdminId   INT              NULL,
        ModifiedUtc        DATETIME2(0)     NULL,
        ModifiedByAdminId  INT              NULL,
        CONSTRAINT PK_T021Fournisseur PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UX_T021_Guid UNIQUE (FournisseurGUID),
        CONSTRAINT FK_T021_Abonne     FOREIGN KEY (AbonneId)          REFERENCES dbo.T010Abonne(Id),
        CONSTRAINT FK_T021_CreatedBy  FOREIGN KEY (CreatedByAdminId)  REFERENCES dbo.T001PortalAdmin(Id),
        CONSTRAINT FK_T021_ModifiedBy FOREIGN KEY (ModifiedByAdminId) REFERENCES dbo.T001PortalAdmin(Id)
    );
    CREATE INDEX IX_T021_AbonneNom ON dbo.T021Fournisseur (AbonneId, Nom);
    CREATE UNIQUE INDEX UX_T021_AbonneRef ON dbo.T021Fournisseur (AbonneId, ReferenceExterne) WHERE ReferenceExterne IS NOT NULL;
END
GO

/* ---------------------------------------------------------------------
   2) T030Payment : ajouter le beneficiaire (fournisseur) pour les sorties
   --------------------------------------------------------------------- */
IF COL_LENGTH('dbo.T030Payment', 'FournisseurId') IS NULL
BEGIN
    ALTER TABLE dbo.T030Payment ADD FournisseurId INT NULL
        CONSTRAINT FK_T030_Fournisseur REFERENCES dbo.T021Fournisseur(Id);
END
GO

/* ---------------------------------------------------------------------
   3) Trigger webhook : direction-aware (payment.* / payout.*)
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.TR_T030_Webhook', N'TR') IS NOT NULL DROP TRIGGER dbo.TR_T030_Webhook;
GO
CREATE TRIGGER dbo.TR_T030_Webhook ON dbo.T030Payment
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Initiation
    INSERT INTO dbo.T042WebhookDelivery (AbonneId, EndpointId, EventType, PaymentId)
    SELECT i.AbonneId, e.Id,
           CASE WHEN i.Direction = N'Sortant' THEN N'payout.initiated' ELSE N'payment.initiated' END,
           i.Id
    FROM inserted i
    JOIN dbo.T041WebhookEndpoint e ON e.AbonneId = i.AbonneId AND e.IsActive = 1
    WHERE NOT EXISTS (SELECT 1 FROM deleted);

    -- Transitions
    INSERT INTO dbo.T042WebhookDelivery (AbonneId, EndpointId, EventType, PaymentId)
    SELECT i.AbonneId, e.Id,
           CASE WHEN i.Direction = N'Sortant' THEN
                    CASE i.Status WHEN N'Regle' THEN N'payout.settled' WHEN N'Retourne' THEN N'payout.returned' END
                ELSE
                    CASE i.Status WHEN N'Regle' THEN N'payment.settled' WHEN N'Retourne' THEN N'payment.returned' END
           END,
           i.Id
    FROM inserted i
    JOIN deleted d ON d.Id = i.Id
    JOIN dbo.T041WebhookEndpoint e ON e.AbonneId = i.AbonneId AND e.IsActive = 1
    WHERE i.Status <> d.Status AND i.Status IN (N'Regle', N'Retourne');
END
GO

/* ---------------------------------------------------------------------
   4) Restreindre le batch de reglement ENTRANT a Direction='Entrant'
   --------------------------------------------------------------------- */
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
        WHERE Status = N'Initie' AND Direction = N'Entrant'
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

/* =====================================================================
   5) FOURNISSEURS - procedures (miroir des clients)
   ===================================================================== */

CREATE OR ALTER PROCEDURE dbo.s0035ListFournisseurs
    @AbonneId INT,
    @Search   NVARCHAR(200) = NULL,
    @Statut   NVARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  Id, FournisseurGUID, AbonneId, TypeFournisseur, Nom, ReferenceExterne,
            CourrielContact, Telephone, Ville, Province, Statut, CreatedUtc
    FROM    dbo.T021Fournisseur
    WHERE   AbonneId = @AbonneId
      AND   (@Search IS NULL OR @Search = N''
             OR Nom LIKE N'%' + @Search + N'%'
             OR CourrielContact LIKE N'%' + @Search + N'%'
             OR ReferenceExterne LIKE N'%' + @Search + N'%')
      AND   (@Statut IS NULL OR @Statut = N'' OR Statut = @Statut)
    ORDER BY Nom;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0036GetFournisseur
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  Id, FournisseurGUID, AbonneId, TypeFournisseur, Nom, ReferenceExterne,
            CourrielContact, Telephone, Adresse1, Adresse2, Ville, Province,
            CodePostal, Pays, Statut, Notes,
            CreatedUtc, CreatedByAdminId, ModifiedUtc, ModifiedByAdminId
    FROM    dbo.T021Fournisseur
    WHERE   Id = @Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0037SaveFournisseur
    @Id                INT OUTPUT,
    @AbonneId          INT,
    @TypeFournisseur   NVARCHAR(20)  = N'Entreprise',
    @Nom               NVARCHAR(200),
    @ReferenceExterne  NVARCHAR(100) = NULL,
    @CourrielContact   NVARCHAR(256) = NULL,
    @Telephone         NVARCHAR(40)  = NULL,
    @Adresse1          NVARCHAR(200) = NULL,
    @Adresse2          NVARCHAR(200) = NULL,
    @Ville             NVARCHAR(120) = NULL,
    @Province          NVARCHAR(60)  = NULL,
    @CodePostal        NVARCHAR(20)  = NULL,
    @Pays              NVARCHAR(60)  = N'Canada',
    @Statut            NVARCHAR(20)  = N'Actif',
    @Notes             NVARCHAR(MAX) = NULL,
    @AdminId           INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Id IS NULL OR @Id = 0
    BEGIN
        INSERT INTO dbo.T021Fournisseur
            (AbonneId, TypeFournisseur, Nom, ReferenceExterne, CourrielContact, Telephone,
             Adresse1, Adresse2, Ville, Province, CodePostal, Pays, Statut, Notes, CreatedByAdminId)
        VALUES
            (@AbonneId, @TypeFournisseur, @Nom, @ReferenceExterne, @CourrielContact, @Telephone,
             @Adresse1, @Adresse2, @Ville, @Province, @CodePostal, @Pays, @Statut, @Notes, @AdminId);
        SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    END
    ELSE
    BEGIN
        UPDATE dbo.T021Fournisseur
        SET TypeFournisseur = @TypeFournisseur, Nom = @Nom, ReferenceExterne = @ReferenceExterne,
            CourrielContact = @CourrielContact, Telephone = @Telephone,
            Adresse1 = @Adresse1, Adresse2 = @Adresse2, Ville = @Ville, Province = @Province,
            CodePostal = @CodePostal, Pays = @Pays, Statut = @Statut, Notes = @Notes,
            ModifiedUtc = SYSUTCDATETIME(), ModifiedByAdminId = @AdminId
        WHERE Id = @Id;
    END
    SELECT @Id AS Id;
END
GO

/* =====================================================================
   6) DECAISSEMENT - cycle de vie du paiement sortant
   ===================================================================== */

/* --- s0038InitiatePayout : reserve les fonds + ecriture d'initiation. --- */
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

    -- DR SUBBAL (montant+frais) ; CR EFT_OUT (montant) ; CR FEES (frais)
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
                                 ExpectedSettlementDate, InitiationTxnId, CreatedByAdminId)
    VALUES (@AbonneId, NULL, @FournisseurId, N'Sortant', N'EFT', @AmountCents, @FeeCents,
            N'Initie', @Description, @Reference, @IdempotencyKey,
            DATEADD(DAY, @SettlementDays, CAST(SYSUTCDATETIME() AS DATE)), @txn, @AdminId);
    SET @PaymentId = CAST(SCOPE_IDENTITY() AS BIGINT);

    COMMIT;
    SELECT @PaymentId AS PaymentId;
END
GO

/* --- s0039SettlePayout : DR EFT_OUT / CR TRUST (les fonds quittent la banque). --- */
CREATE OR ALTER PROCEDURE dbo.s0039SettlePayout
    @PaymentId BIGINT,
    @AdminId   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AbonneId INT, @Amount BIGINT, @Status NVARCHAR(20), @Dir NVARCHAR(10);
    SELECT @AbonneId = AbonneId, @Amount = AmountCents, @Status = Status, @Dir = Direction
    FROM dbo.T030Payment WHERE Id = @PaymentId;

    IF @AbonneId IS NULL BEGIN RAISERROR(N'Paiement introuvable.',16,1); RETURN; END
    IF @Dir <> N'Sortant' BEGIN RAISERROR(N'Ce paiement n''est pas un decaissement.',16,1); RETURN; END
    IF @Status = N'Regle' RETURN;
    IF @Status <> N'Initie' BEGIN RAISERROR(N'Seul un decaissement initie peut etre regle.',16,1); RETURN; END

    DECLARE @trust  INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId IS NULL AND AccountCode = 'TRUST');
    DECLARE @eftOut INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'EFT_OUT');

    BEGIN TRAN;
    DECLARE @txn BIGINT;
    INSERT INTO dbo.T101LedgerTransaction (AbonneId, TxnType, Description, CreatedByAdminId)
    VALUES (@AbonneId, N'DecaissementRegle', N'Reglement EFT sortant', @AdminId);
    SET @txn = CAST(SCOPE_IDENTITY() AS BIGINT);

    INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
    VALUES (@txn, @eftOut, @Amount, 0),
           (@txn, @trust,  0, @Amount);

    UPDATE dbo.T030Payment
    SET Status = N'Regle', SettlementTxnId = @txn, SettledUtc = SYSUTCDATETIME()
    WHERE Id = @PaymentId;

    COMMIT;
END
GO

/* --- s0040ReturnPayout : remboursement (DR EFT_OUT + DR FEES / CR SUBBAL). --- */
CREATE OR ALTER PROCEDURE dbo.s0040ReturnPayout
    @PaymentId BIGINT,
    @Reason    NVARCHAR(100) = N'Retour',
    @AdminId   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AbonneId INT, @Amount BIGINT, @Fee BIGINT, @Status NVARCHAR(20), @Dir NVARCHAR(10);
    SELECT @AbonneId = AbonneId, @Amount = AmountCents, @Fee = FeeCents, @Status = Status, @Dir = Direction
    FROM dbo.T030Payment WHERE Id = @PaymentId;

    IF @AbonneId IS NULL BEGIN RAISERROR(N'Paiement introuvable.',16,1); RETURN; END
    IF @Dir <> N'Sortant' BEGIN RAISERROR(N'Ce paiement n''est pas un decaissement.',16,1); RETURN; END
    IF @Status <> N'Initie' BEGIN RAISERROR(N'Seul un decaissement initie peut etre retourne.',16,1); RETURN; END

    DECLARE @eftOut INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'EFT_OUT');
    DECLARE @subbal INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'SUBBAL');
    DECLARE @fees   INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId IS NULL AND AccountCode = 'FEES');
    DECLARE @total BIGINT = @Amount + @Fee;

    BEGIN TRAN;
    DECLARE @txn BIGINT;
    INSERT INTO dbo.T101LedgerTransaction (AbonneId, TxnType, Description, CreatedByAdminId)
    VALUES (@AbonneId, N'DecaissementRetourne', @Reason, @AdminId);
    SET @txn = CAST(SCOPE_IDENTITY() AS BIGINT);

    INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
    VALUES (@txn, @eftOut, @Amount, 0);
    IF @Fee > 0
        INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
        VALUES (@txn, @fees, @Fee, 0);
    INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
    VALUES (@txn, @subbal, 0, @total);

    IF (SELECT SUM(DebitCents) - SUM(CreditCents) FROM dbo.T102LedgerPosting WHERE TransactionId = @txn) <> 0
    BEGIN RAISERROR(N'Ecriture desequilibree.',16,1); RETURN; END

    UPDATE dbo.T030Payment
    SET Status = N'Retourne', ReturnTxnId = @txn, ReturnReason = @Reason, ReturnedUtc = SYSUTCDATETIME()
    WHERE Id = @PaymentId;

    COMMIT;
END
GO

/* --- s0041RunPayoutSettlementBatch : connecteur simule (Direction='Sortant'). --- */
CREATE OR ALTER PROCEDURE dbo.s0041RunPayoutSettlementBatch
    @AbonneId INT = NULL,
    @AdminId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @today DATE = CAST(SYSUTCDATETIME() AS DATE);
    DECLARE @n INT = 0, @pid BIGINT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Id FROM dbo.T030Payment
        WHERE Status = N'Initie' AND Direction = N'Sortant'
          AND ExpectedSettlementDate <= @today
          AND (@AbonneId IS NULL OR AbonneId = @AbonneId)
        ORDER BY Id;
    OPEN cur; FETCH NEXT FROM cur INTO @pid;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.s0039SettlePayout @PaymentId = @pid, @AdminId = @AdminId;
        SET @n = @n + 1;
        FETCH NEXT FROM cur INTO @pid;
    END
    CLOSE cur; DEALLOCATE cur;
    SELECT @n AS NbRegles;
END
GO

/* ---------------------------------------------------------------------
   7) s0023ListPayments : ajout du filtre @Direction + nom du fournisseur
      (retro-compatible : @Direction optionnel).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0023ListPayments
    @AbonneId  INT,
    @Status    NVARCHAR(20)  = NULL,
    @Search    NVARCHAR(200) = NULL,
    @Direction NVARCHAR(10)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  p.Id, p.PaymentGUID, p.ClientId, c.Nom AS ClientNom,
            p.FournisseurId, f.Nom AS FournisseurNom,
            p.Direction, p.Method, p.AmountCents, p.FeeCents, p.NetCents,
            p.Status, p.Description, p.Reference, p.ExpectedSettlementDate,
            p.InitiatedUtc, p.SettledUtc, p.ReturnedUtc, p.ReturnReason
    FROM    dbo.T030Payment p
    LEFT JOIN dbo.T020Client c ON c.Id = p.ClientId
    LEFT JOIN dbo.T021Fournisseur f ON f.Id = p.FournisseurId
    WHERE   p.AbonneId = @AbonneId
      AND   (@Status IS NULL OR @Status = N'' OR p.Status = @Status)
      AND   (@Direction IS NULL OR @Direction = N'' OR p.Direction = @Direction)
      AND   (@Search IS NULL OR @Search = N''
             OR c.Nom LIKE N'%' + @Search + N'%'
             OR f.Nom LIKE N'%' + @Search + N'%'
             OR p.Reference LIKE N'%' + @Search + N'%'
             OR p.Description LIKE N'%' + @Search + N'%')
    ORDER BY p.Id DESC;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'11_decaissements.sql : termine.';
GO
