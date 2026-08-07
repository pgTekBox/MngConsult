/* =====================================================================
   PortailMaster - Script 16 : Connecteur EFT reel (CPA Norme 005 / AFT)
   ---------------------------------------------------------------------
   Fondations de la generation de fichiers AFT (CPA-005) a soumettre a la
   banque parrain, en remplacement du connecteur simule.

     - Coordonnees bancaires sur clients (payeurs -> debits D) et
       fournisseurs (beneficiaires -> credits C).
     - Config emetteur (T052EftOriginator) : parametres fournis par la
       banque (n. client, noms, centre de donnees, compte de retour,
       codes CPA, prochain n. de creation de fichier).
     - Lots EFT (T050EftBatch) + items (T051EftBatchItem) avec etats
       Open / Generated / Submitted / Settled.
     - T030Payment.BatchId : evite qu'un paiement soit mis 2x en lot.

   NB : la mise en forme exacte des enregistrements 005 varie selon
   l'institution ; a valider avec le guide d'implantation de la banque.
   Procs s0042+.
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---- 1) Coordonnees bancaires sur clients / fournisseurs ---- */
IF COL_LENGTH('dbo.T020Client', 'BankInstitution') IS NULL
    ALTER TABLE dbo.T020Client ADD BankInstitution CHAR(3) NULL, BankTransit CHAR(5) NULL, BankAccount NVARCHAR(12) NULL;
GO
IF COL_LENGTH('dbo.T021Fournisseur', 'BankInstitution') IS NULL
    ALTER TABLE dbo.T021Fournisseur ADD BankInstitution CHAR(3) NULL, BankTransit CHAR(5) NULL, BankAccount NVARCHAR(12) NULL;
GO

/* ---- 2) T030Payment.BatchId ---- */
IF COL_LENGTH('dbo.T030Payment', 'BatchId') IS NULL
    ALTER TABLE dbo.T030Payment ADD BatchId INT NULL;
GO

/* ---- 3) Config emetteur (une seule ligne) ---- */
IF OBJECT_ID(N'dbo.T052EftOriginator', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T052EftOriginator
    (
        Id                    INT           IDENTITY(1,1) NOT NULL,
        ClientNumber          NVARCHAR(10)  NOT NULL,     -- n. client emetteur (banque)
        ShortName             NVARCHAR(15)  NOT NULL,
        LongName              NVARCHAR(30)  NOT NULL,
        DataCentre            CHAR(5)       NOT NULL CONSTRAINT DF_T052_DC DEFAULT ('00000'),
        ReturnInstitution     CHAR(3)       NULL,         -- compte de retour (fiducie)
        ReturnTransit         CHAR(5)       NULL,
        ReturnAccount         NVARCHAR(12)  NULL,
        Currency              CHAR(3)       NOT NULL CONSTRAINT DF_T052_Cur DEFAULT ('CAD'),
        CpaCodeDebit          CHAR(3)       NOT NULL CONSTRAINT DF_T052_CD DEFAULT ('430'),
        CpaCodeCredit         CHAR(3)       NOT NULL CONSTRAINT DF_T052_CC DEFAULT ('230'),
        NextFileCreationNumber INT          NOT NULL CONSTRAINT DF_T052_NFC DEFAULT (1),
        CONSTRAINT PK_T052EftOriginator PRIMARY KEY CLUSTERED (Id)
    );
    INSERT INTO dbo.T052EftOriginator (ClientNumber, ShortName, LongName, DataCentre, ReturnInstitution, ReturnTransit, ReturnAccount)
    VALUES (N'0000000000', N'60SECPAIEMENT', N'60SECPAIEMENT INC', '00000', '000', '00000', N'0000000');
END
GO

/* ---- 4) Lots EFT ---- */
IF OBJECT_ID(N'dbo.T050EftBatch', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T050EftBatch
    (
        Id                 INT              IDENTITY(1,1) NOT NULL,
        BatchGUID          UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_T050_Guid DEFAULT (NEWID()),
        FileCreationNumber INT              NOT NULL,
        Status             NVARCHAR(20)     NOT NULL CONSTRAINT DF_T050_Status DEFAULT (N'Open'), -- Open/Generated/Submitted/Settled
        FileName           NVARCHAR(100)    NULL,
        TotalDebitCents    BIGINT           NOT NULL CONSTRAINT DF_T050_TD DEFAULT (0),
        TotalCreditCents   BIGINT           NOT NULL CONSTRAINT DF_T050_TC DEFAULT (0),
        CountDebit         INT              NOT NULL CONSTRAINT DF_T050_ND DEFAULT (0),
        CountCredit        INT              NOT NULL CONSTRAINT DF_T050_NC DEFAULT (0),
        CreatedUtc         DATETIME2(0)     NOT NULL CONSTRAINT DF_T050_Created DEFAULT (SYSUTCDATETIME()),
        GeneratedUtc       DATETIME2(0)     NULL,
        SubmittedUtc       DATETIME2(0)     NULL,
        SettledUtc         DATETIME2(0)     NULL,
        CreatedByAdminId   INT              NULL,
        CONSTRAINT PK_T050EftBatch PRIMARY KEY CLUSTERED (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.T051EftBatchItem', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T051EftBatchItem
    (
        Id              INT          IDENTITY(1,1) NOT NULL,
        BatchId         INT          NOT NULL,
        PaymentId       BIGINT       NOT NULL,
        RecordType      CHAR(1)      NOT NULL,   -- 'C' credit (sortant) / 'D' debit (entrant)
        AmountCents     BIGINT       NOT NULL,
        CounterpartyName NVARCHAR(30) NULL,
        BankInstitution CHAR(3)      NULL,
        BankTransit     CHAR(5)      NULL,
        BankAccount     NVARCHAR(12) NULL,
        DueDate         DATE         NULL,
        CrossReference  NVARCHAR(19) NULL,
        CONSTRAINT PK_T051EftBatchItem PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_T051_Batch   FOREIGN KEY (BatchId)   REFERENCES dbo.T050EftBatch(Id),
        CONSTRAINT FK_T051_Payment FOREIGN KEY (PaymentId) REFERENCES dbo.T030Payment(Id)
    );
    CREATE INDEX IX_T051_Batch ON dbo.T051EftBatchItem (BatchId);
END
GO

/* =====================================================================
   PROCEDURES  (s0042+)
   ===================================================================== */

/* --- Client / Fournisseur : Save & Get incluant les coordonnees bancaires --- */
CREATE OR ALTER PROCEDURE dbo.s0012GetClient @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  Id, ClientGUID, AbonneId, TypeClient, Nom, ReferenceExterne,
            CourrielContact, Telephone, Adresse1, Adresse2, Ville, Province,
            CodePostal, Pays, Statut, Notes, BankInstitution, BankTransit, BankAccount,
            CreatedUtc, CreatedByAdminId, ModifiedUtc, ModifiedByAdminId
    FROM    dbo.T020Client WHERE Id = @Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0013SaveClient
    @Id INT OUTPUT, @AbonneId INT, @TypeClient NVARCHAR(20) = N'Entreprise', @Nom NVARCHAR(200),
    @ReferenceExterne NVARCHAR(100) = NULL, @CourrielContact NVARCHAR(256) = NULL, @Telephone NVARCHAR(40) = NULL,
    @Adresse1 NVARCHAR(200) = NULL, @Adresse2 NVARCHAR(200) = NULL, @Ville NVARCHAR(120) = NULL,
    @Province NVARCHAR(60) = NULL, @CodePostal NVARCHAR(20) = NULL, @Pays NVARCHAR(60) = N'Canada',
    @Statut NVARCHAR(20) = N'Actif', @Notes NVARCHAR(MAX) = NULL, @AdminId INT = NULL,
    @BankInstitution CHAR(3) = NULL, @BankTransit CHAR(5) = NULL, @BankAccount NVARCHAR(12) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Id IS NULL OR @Id = 0
    BEGIN
        INSERT INTO dbo.T020Client (AbonneId, TypeClient, Nom, ReferenceExterne, CourrielContact, Telephone,
            Adresse1, Adresse2, Ville, Province, CodePostal, Pays, Statut, Notes, CreatedByAdminId,
            BankInstitution, BankTransit, BankAccount)
        VALUES (@AbonneId, @TypeClient, @Nom, @ReferenceExterne, @CourrielContact, @Telephone,
            @Adresse1, @Adresse2, @Ville, @Province, @CodePostal, @Pays, @Statut, @Notes, @AdminId,
            @BankInstitution, @BankTransit, @BankAccount);
        SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    END
    ELSE
        UPDATE dbo.T020Client SET TypeClient=@TypeClient, Nom=@Nom, ReferenceExterne=@ReferenceExterne,
            CourrielContact=@CourrielContact, Telephone=@Telephone, Adresse1=@Adresse1, Adresse2=@Adresse2,
            Ville=@Ville, Province=@Province, CodePostal=@CodePostal, Pays=@Pays, Statut=@Statut, Notes=@Notes,
            BankInstitution=@BankInstitution, BankTransit=@BankTransit, BankAccount=@BankAccount,
            ModifiedUtc=SYSUTCDATETIME(), ModifiedByAdminId=@AdminId
        WHERE Id=@Id;
    SELECT @Id AS Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0036GetFournisseur @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  Id, FournisseurGUID, AbonneId, TypeFournisseur, Nom, ReferenceExterne,
            CourrielContact, Telephone, Adresse1, Adresse2, Ville, Province,
            CodePostal, Pays, Statut, Notes, BankInstitution, BankTransit, BankAccount,
            CreatedUtc, CreatedByAdminId, ModifiedUtc, ModifiedByAdminId
    FROM    dbo.T021Fournisseur WHERE Id = @Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0037SaveFournisseur
    @Id INT OUTPUT, @AbonneId INT, @TypeFournisseur NVARCHAR(20) = N'Entreprise', @Nom NVARCHAR(200),
    @ReferenceExterne NVARCHAR(100) = NULL, @CourrielContact NVARCHAR(256) = NULL, @Telephone NVARCHAR(40) = NULL,
    @Adresse1 NVARCHAR(200) = NULL, @Adresse2 NVARCHAR(200) = NULL, @Ville NVARCHAR(120) = NULL,
    @Province NVARCHAR(60) = NULL, @CodePostal NVARCHAR(20) = NULL, @Pays NVARCHAR(60) = N'Canada',
    @Statut NVARCHAR(20) = N'Actif', @Notes NVARCHAR(MAX) = NULL, @AdminId INT = NULL,
    @BankInstitution CHAR(3) = NULL, @BankTransit CHAR(5) = NULL, @BankAccount NVARCHAR(12) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Id IS NULL OR @Id = 0
    BEGIN
        INSERT INTO dbo.T021Fournisseur (AbonneId, TypeFournisseur, Nom, ReferenceExterne, CourrielContact, Telephone,
            Adresse1, Adresse2, Ville, Province, CodePostal, Pays, Statut, Notes, CreatedByAdminId,
            BankInstitution, BankTransit, BankAccount)
        VALUES (@AbonneId, @TypeFournisseur, @Nom, @ReferenceExterne, @CourrielContact, @Telephone,
            @Adresse1, @Adresse2, @Ville, @Province, @CodePostal, @Pays, @Statut, @Notes, @AdminId,
            @BankInstitution, @BankTransit, @BankAccount);
        SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    END
    ELSE
        UPDATE dbo.T021Fournisseur SET TypeFournisseur=@TypeFournisseur, Nom=@Nom, ReferenceExterne=@ReferenceExterne,
            CourrielContact=@CourrielContact, Telephone=@Telephone, Adresse1=@Adresse1, Adresse2=@Adresse2,
            Ville=@Ville, Province=@Province, CodePostal=@CodePostal, Pays=@Pays, Statut=@Statut, Notes=@Notes,
            BankInstitution=@BankInstitution, BankTransit=@BankTransit, BankAccount=@BankAccount,
            ModifiedUtc=SYSUTCDATETIME(), ModifiedByAdminId=@AdminId
        WHERE Id=@Id;
    SELECT @Id AS Id;
END
GO

/* --- s0042GetOriginator / s0043SaveOriginator --- */
CREATE OR ALTER PROCEDURE dbo.s0042GetOriginator
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 * FROM dbo.T052EftOriginator ORDER BY Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0043SaveOriginator
    @ClientNumber NVARCHAR(10), @ShortName NVARCHAR(15), @LongName NVARCHAR(30), @DataCentre CHAR(5),
    @ReturnInstitution CHAR(3) = NULL, @ReturnTransit CHAR(5) = NULL, @ReturnAccount NVARCHAR(12) = NULL,
    @CpaCodeDebit CHAR(3) = '430', @CpaCodeCredit CHAR(3) = '230'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id INT = (SELECT TOP 1 Id FROM dbo.T052EftOriginator ORDER BY Id);
    IF @id IS NULL
        INSERT INTO dbo.T052EftOriginator (ClientNumber, ShortName, LongName, DataCentre, ReturnInstitution, ReturnTransit, ReturnAccount, CpaCodeDebit, CpaCodeCredit)
        VALUES (@ClientNumber, @ShortName, @LongName, @DataCentre, @ReturnInstitution, @ReturnTransit, @ReturnAccount, @CpaCodeDebit, @CpaCodeCredit);
    ELSE
        UPDATE dbo.T052EftOriginator SET ClientNumber=@ClientNumber, ShortName=@ShortName, LongName=@LongName,
            DataCentre=@DataCentre, ReturnInstitution=@ReturnInstitution, ReturnTransit=@ReturnTransit,
            ReturnAccount=@ReturnAccount, CpaCodeDebit=@CpaCodeDebit, CpaCodeCredit=@CpaCodeCredit
        WHERE Id=@id;
END
GO

/* --- s0044CreateEftBatch : cree un lot a partir des paiements/decaissements
       INITIES non encore mis en lot. Snapshot des coordonnees bancaires. --- */
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

    INSERT INTO dbo.T050EftBatch (FileCreationNumber, Status, CreatedByAdminId)
    VALUES (@fcn, N'Open', @AdminId);
    SET @BatchId = CAST(SCOPE_IDENTITY() AS INT);

    UPDATE dbo.T052EftOriginator SET NextFileCreationNumber = NextFileCreationNumber + 1;

    -- Debits (D) : encaissements entrants (on tire du compte du client)
    INSERT INTO dbo.T051EftBatchItem (BatchId, PaymentId, RecordType, AmountCents, CounterpartyName, BankInstitution, BankTransit, BankAccount, DueDate, CrossReference)
    SELECT @BatchId, p.Id, 'D', p.AmountCents, LEFT(c.Nom,30), c.BankInstitution, c.BankTransit, c.BankAccount, p.ExpectedSettlementDate, LEFT(p.Reference,19)
    FROM dbo.T030Payment p JOIN dbo.T020Client c ON c.Id = p.ClientId
    WHERE p.Status=N'Initie' AND p.Direction=N'Entrant' AND p.BatchId IS NULL;

    -- Credits (C) : decaissements sortants (on paie le fournisseur)
    INSERT INTO dbo.T051EftBatchItem (BatchId, PaymentId, RecordType, AmountCents, CounterpartyName, BankInstitution, BankTransit, BankAccount, DueDate, CrossReference)
    SELECT @BatchId, p.Id, 'C', p.AmountCents, LEFT(f.Nom,30), f.BankInstitution, f.BankTransit, f.BankAccount, p.ExpectedSettlementDate, LEFT(p.Reference,19)
    FROM dbo.T030Payment p JOIN dbo.T021Fournisseur f ON f.Id = p.FournisseurId
    WHERE p.Status=N'Initie' AND p.Direction=N'Sortant' AND p.BatchId IS NULL;

    -- Marquer les paiements et calculer les totaux
    UPDATE p SET p.BatchId = @BatchId
    FROM dbo.T030Payment p JOIN dbo.T051EftBatchItem i ON i.PaymentId = p.Id
    WHERE i.BatchId = @BatchId;

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

/* --- s0045ListEftBatches --- */
CREATE OR ALTER PROCEDURE dbo.s0045ListEftBatches
    @Top INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top) Id, FileCreationNumber, Status, FileName,
           TotalDebitCents, TotalCreditCents, CountDebit, CountCredit,
           CreatedUtc, GeneratedUtc, SubmittedUtc, SettledUtc
    FROM dbo.T050EftBatch ORDER BY Id DESC;
END
GO

/* --- s0046GetEftBatch : entete + items (2 result sets) --- */
CREATE OR ALTER PROCEDURE dbo.s0046GetEftBatch
    @BatchId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.T050EftBatch WHERE Id = @BatchId;
    SELECT Id, PaymentId, RecordType, AmountCents, CounterpartyName,
           BankInstitution, BankTransit, BankAccount, DueDate, CrossReference
    FROM dbo.T051EftBatchItem WHERE BatchId = @BatchId ORDER BY RecordType, Id;
END
GO

/* --- s0047MarkBatchGenerated / Submitted --- */
CREATE OR ALTER PROCEDURE dbo.s0047MarkBatchGenerated
    @BatchId INT, @FileName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T050EftBatch
    SET Status = CASE WHEN Status = N'Open' THEN N'Generated' ELSE Status END,
        FileName = @FileName, GeneratedUtc = SYSUTCDATETIME()
    WHERE Id = @BatchId;
END
GO

/* --- s0048SettleEftBatch : marque Submitted->Settled et REGLE chaque
       paiement du lot (via s0021 entrant / s0039 sortant) = confirmation
       de reglement par la banque (ici declenchee manuellement). --- */
CREATE OR ALTER PROCEDURE dbo.s0048SettleEftBatch
    @BatchId INT, @AdminId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.T050EftBatch WHERE Id=@BatchId) BEGIN RAISERROR(N'Lot introuvable.',16,1); RETURN; END

    DECLARE @pid BIGINT, @dir NVARCHAR(10), @st NVARCHAR(20);
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT p.Id, p.Direction, p.Status
        FROM dbo.T030Payment p JOIN dbo.T051EftBatchItem i ON i.PaymentId = p.Id
        WHERE i.BatchId = @BatchId;
    OPEN cur; FETCH NEXT FROM cur INTO @pid, @dir, @st;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @st = N'Initie'
        BEGIN
            IF @dir = N'Entrant' EXEC dbo.s0021SettlePayment @PaymentId=@pid, @AdminId=@AdminId;
            ELSE                 EXEC dbo.s0039SettlePayout  @PaymentId=@pid, @AdminId=@AdminId;
        END
        FETCH NEXT FROM cur INTO @pid, @dir, @st;
    END
    CLOSE cur; DEALLOCATE cur;

    UPDATE dbo.T050EftBatch
    SET Status = N'Settled', SubmittedUtc = ISNULL(SubmittedUtc, SYSUTCDATETIME()), SettledUtc = SYSUTCDATETIME()
    WHERE Id = @BatchId;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'16_eft_cpa005.sql : termine.';
GO
