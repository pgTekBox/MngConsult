/* =====================================================================
   PortailMaster - Script 44 : controles EFT exiges par une IF parraine
   ---------------------------------------------------------------------
   Trois des quatre ecarts du dossier EFT_005_APPROBATION.md :

     1) DOUBLE CONTROLE (maker-checker) : un lot ne peut plus etre transmis
        a la banque sans avoir ete approuve par un administrateur DIFFERENT
        de celui qui l'a genere. Nouveau statut 'Approved' entre 'Generated'
        et 'Submitted'.  (s0120)

     2) PLAFONDS : montant unitaire, total du fichier et total quotidien
        (globaux, T052EftOriginator) + plafond quotidien par abonne
        (T010Abonne.MaxDailyEftCents). Verifies au seul point d'entree :
        s0044CreateEftBatch, qui refuse le lot et annule la transaction.

     3) CALENDRIER DE JOURS OUVRABLES : table T059BankHoliday (jours non
        compensables ACSS + feries bancaires du Quebec), lue par
        clsBusinessCalendar pour dater le fichier en heure de l'Est et
        reporter les echeances tombant un jour non ouvrable.  (s0122)

   Le 4e ecart (chiffrement des comptes bancaires) est dans le script 45.

   A executer APRES 43. Procs s0120+.
   Requiert SQL Server 2016+ (AT TIME ZONE, CREATE OR ALTER).
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =====================================================================
   1) COLONNES
   ===================================================================== */

/* --- Double controle sur le lot --- */
IF COL_LENGTH('dbo.T050EftBatch', 'ApprovedByAdminId') IS NULL
    ALTER TABLE dbo.T050EftBatch ADD ApprovedByAdminId INT NULL;
GO
IF COL_LENGTH('dbo.T050EftBatch', 'ApprovedUtc') IS NULL
    ALTER TABLE dbo.T050EftBatch ADD ApprovedUtc DATETIME2(0) NULL;
GO

/* --- Plafonds globaux (NULL = aucun plafond) --- */
IF COL_LENGTH('dbo.T052EftOriginator', 'MaxItemCents') IS NULL
    ALTER TABLE dbo.T052EftOriginator ADD MaxItemCents BIGINT NULL;
GO
IF COL_LENGTH('dbo.T052EftOriginator', 'MaxFileCents') IS NULL
    ALTER TABLE dbo.T052EftOriginator ADD MaxFileCents BIGINT NULL;
GO
IF COL_LENGTH('dbo.T052EftOriginator', 'MaxDailyCents') IS NULL
    ALTER TABLE dbo.T052EftOriginator ADD MaxDailyCents BIGINT NULL;
GO

/* --- Plafond quotidien par abonne (NULL = aucun plafond) --- */
IF COL_LENGTH('dbo.T010Abonne', 'MaxDailyEftCents') IS NULL
    ALTER TABLE dbo.T010Abonne ADD MaxDailyEftCents BIGINT NULL;
GO

/* =====================================================================
   2) CALENDRIER BANCAIRE
   ---------------------------------------------------------------------
   Scope 'CA' = jour non compensable ACSS (ferie federal).
   Scope 'QC' = ferie bancaire du Quebec en sus (Fete nationale).
   A CONFIRMER avec le calendrier officiel de l'IF parraine : la table est
   editable et fait autorite pour l'application.
   ===================================================================== */
IF OBJECT_ID(N'dbo.T059BankHoliday', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T059BankHoliday
    (
        HolidayDate DATE          NOT NULL,
        Scope       CHAR(2)       NOT NULL CONSTRAINT DF_T059_Scope DEFAULT ('CA'),
        Name        NVARCHAR(80)  NOT NULL,
        CONSTRAINT PK_T059BankHoliday PRIMARY KEY CLUSTERED (HolidayDate, Scope)
    );
END
GO

MERGE dbo.T059BankHoliday AS t
USING (VALUES
    /* ---- 2026 ---- */
    ('2026-01-01','CA',N'Jour de l an'),
    ('2026-04-03','CA',N'Vendredi saint'),
    ('2026-05-18','CA',N'Journee nationale des patriotes / Victoria'),
    ('2026-06-24','QC',N'Fete nationale du Quebec'),
    ('2026-07-01','CA',N'Fete du Canada'),
    ('2026-09-07','CA',N'Fete du Travail'),
    ('2026-09-30','CA',N'Journee de la verite et de la reconciliation'),
    ('2026-10-12','CA',N'Action de graces'),
    ('2026-12-25','CA',N'Noel'),
    ('2026-12-28','CA',N'Lendemain de Noel (reporte)'),
    /* ---- 2027 ---- */
    ('2027-01-01','CA',N'Jour de l an'),
    ('2027-03-26','CA',N'Vendredi saint'),
    ('2027-05-24','CA',N'Journee nationale des patriotes / Victoria'),
    ('2027-06-24','QC',N'Fete nationale du Quebec'),
    ('2027-07-01','CA',N'Fete du Canada'),
    ('2027-09-06','CA',N'Fete du Travail'),
    ('2027-09-30','CA',N'Journee de la verite et de la reconciliation'),
    ('2027-10-11','CA',N'Action de graces'),
    ('2027-12-27','CA',N'Noel (reporte)'),
    ('2027-12-28','CA',N'Lendemain de Noel (reporte)'),
    /* ---- 2028 ---- */
    ('2028-01-03','CA',N'Jour de l an (reporte)'),
    ('2028-04-14','CA',N'Vendredi saint'),
    ('2028-05-22','CA',N'Journee nationale des patriotes / Victoria'),
    ('2028-06-24','QC',N'Fete nationale du Quebec'),
    ('2028-07-03','CA',N'Fete du Canada (reporte)'),
    ('2028-09-04','CA',N'Fete du Travail'),
    ('2028-09-30','CA',N'Journee de la verite et de la reconciliation'),
    ('2028-10-09','CA',N'Action de graces'),
    ('2028-12-25','CA',N'Noel'),
    ('2028-12-26','CA',N'Lendemain de Noel')
) AS s (HolidayDate, Scope, Name)
    ON t.HolidayDate = s.HolidayDate AND t.Scope = s.Scope
WHEN NOT MATCHED BY TARGET THEN
    INSERT (HolidayDate, Scope, Name) VALUES (s.HolidayDate, s.Scope, s.Name);
GO

/* =====================================================================
   3) PROCEDURES
   ===================================================================== */

/* --- s0043SaveOriginator : + plafonds globaux --- */
CREATE OR ALTER PROCEDURE dbo.s0043SaveOriginator
    @ClientNumber NVARCHAR(10), @ShortName NVARCHAR(15), @LongName NVARCHAR(30), @DataCentre CHAR(5),
    @ReturnInstitution CHAR(3) = NULL, @ReturnTransit CHAR(5) = NULL, @ReturnAccount NVARCHAR(12) = NULL,
    @CpaCodeDebit CHAR(3) = '430', @CpaCodeCredit CHAR(3) = '230',
    @MaxItemCents BIGINT = NULL, @MaxFileCents BIGINT = NULL, @MaxDailyCents BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id INT = (SELECT TOP 1 Id FROM dbo.T052EftOriginator ORDER BY Id);
    IF @id IS NULL
        INSERT INTO dbo.T052EftOriginator (ClientNumber, ShortName, LongName, DataCentre, ReturnInstitution,
            ReturnTransit, ReturnAccount, CpaCodeDebit, CpaCodeCredit, MaxItemCents, MaxFileCents, MaxDailyCents)
        VALUES (@ClientNumber, @ShortName, @LongName, @DataCentre, @ReturnInstitution, @ReturnTransit,
            @ReturnAccount, @CpaCodeDebit, @CpaCodeCredit, @MaxItemCents, @MaxFileCents, @MaxDailyCents);
    ELSE
        UPDATE dbo.T052EftOriginator SET ClientNumber=@ClientNumber, ShortName=@ShortName, LongName=@LongName,
            DataCentre=@DataCentre, ReturnInstitution=@ReturnInstitution, ReturnTransit=@ReturnTransit,
            ReturnAccount=@ReturnAccount, CpaCodeDebit=@CpaCodeDebit, CpaCodeCredit=@CpaCodeCredit,
            MaxItemCents=@MaxItemCents, MaxFileCents=@MaxFileCents, MaxDailyCents=@MaxDailyCents
        WHERE Id=@id;
END
GO

/* --- s0005GetAbonne : + plafond quotidien EFT --- */
CREATE OR ALTER PROCEDURE dbo.s0005GetAbonne
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  Id, TenantGUID, RaisonSociale, NomAffichage, NumeroEntreprise,
            CourrielContact, Telephone, Adresse1, Adresse2, Ville, Province,
            CodePostal, Pays, Devise, Statut, StatutKYB, Notes, MaxDailyEftCents,
            CreatedUtc, CreatedByAdminId, ModifiedUtc, ModifiedByAdminId
    FROM    dbo.T010Abonne
    WHERE   Id = @Id;
END
GO

/* --- s0121SetAbonneEftLimit : plafond quotidien EFT d'un abonne.
       Proc dediee pour ne pas alterer la semantique de s0006SaveAbonne. --- */
CREATE OR ALTER PROCEDURE dbo.s0121SetAbonneEftLimit
    @AbonneId INT,
    @MaxDailyEftCents BIGINT = NULL,   -- NULL = aucun plafond
    @AdminId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.T010Abonne WHERE Id = @AbonneId)
    BEGIN RAISERROR(N'Abonne introuvable.', 16, 1); RETURN; END

    IF @MaxDailyEftCents IS NOT NULL AND @MaxDailyEftCents < 0
    BEGIN RAISERROR(N'Le plafond doit etre positif.', 16, 1); RETURN; END

    UPDATE dbo.T010Abonne
    SET MaxDailyEftCents = @MaxDailyEftCents,
        ModifiedUtc = SYSUTCDATETIME(),
        ModifiedByAdminId = @AdminId
    WHERE Id = @AbonneId;
END
GO

/* --- s0122ListBankHolidays : calendrier lu par clsBusinessCalendar. --- */
CREATE OR ALTER PROCEDURE dbo.s0122ListBankHolidays
    @FromDate DATE = NULL,
    @Scopes   NVARCHAR(20) = N'CA,QC'   -- liste separee par des virgules
AS
BEGIN
    SET NOCOUNT ON;
    IF @FromDate IS NULL SET @FromDate = DATEADD(YEAR, -1, CAST(SYSUTCDATETIME() AS DATE));

    SELECT HolidayDate, Scope, Name
    FROM   dbo.T059BankHoliday
    WHERE  HolidayDate >= @FromDate
      AND  (@Scopes IS NULL OR N',' + @Scopes + N',' LIKE N'%,' + Scope + N',%')
    ORDER BY HolidayDate;
END
GO

/* --- s0044CreateEftBatch : idem script 17 + VERIFICATION DES PLAFONDS.
       Tout depassement annule la creation du lot (rien n'est mis en lot). --- */
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

    DECLARE @maxItem BIGINT, @maxFile BIGINT, @maxDaily BIGINT;
    SELECT TOP 1 @maxItem = MaxItemCents, @maxFile = MaxFileCents, @maxDaily = MaxDailyCents
    FROM dbo.T052EftOriginator ORDER BY Id;

    DECLARE @msg NVARCHAR(400), @today DATE =
        CAST(SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE);

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

    /* ---------- PLAFOND 1 : montant unitaire ---------- */
    IF @maxItem IS NOT NULL
    BEGIN
        DECLARE @worst BIGINT = (SELECT MAX(AmountCents) FROM dbo.T051EftBatchItem WHERE BatchId=@BatchId);
        IF @worst > @maxItem
        BEGIN
            SET @msg = N'Plafond unitaire depasse : une transaction de ' +
                       FORMAT(@worst / 100.0, N'N2') + N' $ excede le plafond de ' +
                       FORMAT(@maxItem / 100.0, N'N2') + N' $. Lot annule.';
            ROLLBACK TRAN; RAISERROR(@msg, 16, 1); RETURN;
        END
    END

    /* ---------- PLAFOND 2 : total du fichier ---------- */
    DECLARE @fileTotal BIGINT = (SELECT TotalDebitCents + TotalCreditCents FROM dbo.T050EftBatch WHERE Id=@BatchId);
    IF @maxFile IS NOT NULL AND @fileTotal > @maxFile
    BEGIN
        SET @msg = N'Plafond par fichier depasse : ' + FORMAT(@fileTotal / 100.0, N'N2') +
                   N' $ pour un plafond de ' + FORMAT(@maxFile / 100.0, N'N2') +
                   N' $. Lot annule ; scindez les transactions sur plusieurs lots.';
        ROLLBACK TRAN; RAISERROR(@msg, 16, 1); RETURN;
    END

    /* ---------- PLAFOND 3 : total quotidien (heure de l'Est) ---------- */
    IF @maxDaily IS NOT NULL
    BEGIN
        DECLARE @dayTotal BIGINT = ISNULL((
            SELECT SUM(b.TotalDebitCents + b.TotalCreditCents)
            FROM dbo.T050EftBatch b
            WHERE b.Status <> N'Rejected'
              AND CAST(b.CreatedUtc AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE) = @today), 0);
        IF @dayTotal > @maxDaily
        BEGIN
            SET @msg = N'Plafond quotidien depasse : ' + FORMAT(@dayTotal / 100.0, N'N2') +
                       N' $ mis en lot aujourd hui pour un plafond de ' + FORMAT(@maxDaily / 100.0, N'N2') +
                       N' $. Lot annule.';
            ROLLBACK TRAN; RAISERROR(@msg, 16, 1); RETURN;
        END
    END

    /* ---------- PLAFOND 4 : quotidien par abonne ---------- */
    DECLARE @badAbonne NVARCHAR(200), @badCents BIGINT, @badMax BIGINT;
    SELECT TOP 1 @badAbonne = a.RaisonSociale, @badCents = x.Cents, @badMax = a.MaxDailyEftCents
    FROM (
        SELECT p.AbonneId, SUM(i.AmountCents) AS Cents
        FROM dbo.T051EftBatchItem i
        JOIN dbo.T030Payment p  ON p.Id = i.PaymentId
        JOIN dbo.T050EftBatch b ON b.Id = i.BatchId
        WHERE b.Status <> N'Rejected'
          AND CAST(b.CreatedUtc AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE) = @today
        GROUP BY p.AbonneId
    ) x
    JOIN dbo.T010Abonne a ON a.Id = x.AbonneId
    WHERE a.MaxDailyEftCents IS NOT NULL AND x.Cents > a.MaxDailyEftCents
    ORDER BY x.Cents DESC;

    IF @badAbonne IS NOT NULL
    BEGIN
        SET @msg = N'Plafond quotidien de l abonne depasse : ' + @badAbonne + N' totalise ' +
                   FORMAT(@badCents / 100.0, N'N2') + N' $ aujourd hui pour un plafond de ' +
                   FORMAT(@badMax / 100.0, N'N2') + N' $. Lot annule.';
        ROLLBACK TRAN; RAISERROR(@msg, 16, 1); RETURN;
    END

    COMMIT;
    SELECT @BatchId AS BatchId;
END
GO

/* --- s0120ApproveEftBatch : DOUBLE CONTROLE.
       Refus si : lot inconnu, deja approuve, statut incompatible,
       createur inconnu, ou approbateur = createur. --- */
CREATE OR ALTER PROCEDURE dbo.s0120ApproveEftBatch
    @BatchId INT,
    @AdminId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @st NVARCHAR(20), @creator INT, @fcn INT;
    SELECT @st = Status, @creator = CreatedByAdminId, @fcn = FileCreationNumber
    FROM dbo.T050EftBatch WHERE Id = @BatchId;

    IF @st IS NULL BEGIN RAISERROR(N'Lot introuvable.', 16, 1); RETURN; END
    IF @AdminId IS NULL OR @AdminId = 0
    BEGIN RAISERROR(N'Approbation impossible : administrateur non identifie.', 16, 1); RETURN; END

    IF @st = N'Approved' BEGIN RAISERROR(N'Ce lot est deja approuve.', 16, 1); RETURN; END

    IF @st NOT IN (N'Open', N'Generated')
    BEGIN
        DECLARE @m1 NVARCHAR(200) = N'Seul un lot non encore transmis peut etre approuve (statut actuel : ' + @st + N').';
        RAISERROR(@m1, 16, 1); RETURN;
    END

    IF @creator IS NULL
    BEGIN RAISERROR(N'Createur du lot inconnu : double controle impossible, approbation refusee.', 16, 1); RETURN; END

    IF @creator = @AdminId
    BEGIN RAISERROR(N'Double controle : le lot doit etre approuve par une personne differente de celle qui l a genere.', 16, 1); RETURN; END

    UPDATE dbo.T050EftBatch
    SET Status = N'Approved', ApprovedByAdminId = @AdminId, ApprovedUtc = SYSUTCDATETIME()
    WHERE Id = @BatchId AND Status IN (N'Open', N'Generated');

    SELECT @fcn AS FileCreationNumber;
END
GO

/* --- s0045ListEftBatches : + colonnes d'approbation --- */
CREATE OR ALTER PROCEDURE dbo.s0045ListEftBatches
    @Top INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
           b.Id, b.FileCreationNumber, b.Status, b.FileName,
           b.TotalDebitCents, b.TotalCreditCents, b.CountDebit, b.CountCredit,
           b.CreatedUtc, b.GeneratedUtc, b.SubmittedUtc, b.SettledUtc,
           b.CreatedByAdminId, b.ApprovedByAdminId, b.ApprovedUtc,
           LTRIM(RTRIM(ISNULL(cr.FirstName, N'') + N' ' + ISNULL(cr.LastName, N''))) AS CreatedBy,
           LTRIM(RTRIM(ISNULL(ap.FirstName, N'') + N' ' + ISNULL(ap.LastName, N''))) AS ApprovedBy
    FROM dbo.T050EftBatch b
    LEFT JOIN dbo.T001PortalAdmin cr ON cr.Id = b.CreatedByAdminId
    LEFT JOIN dbo.T001PortalAdmin ap ON ap.Id = b.ApprovedByAdminId
    ORDER BY b.Id DESC;
END
GO

/* --- s0064ListBatchesToSend : SEULS les lots approuves partent. --- */
CREATE OR ALTER PROCEDURE dbo.s0064ListBatchesToSend
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, FileCreationNumber, Status, CountDebit, CountCredit, TotalDebitCents, TotalCreditCents
    FROM dbo.T050EftBatch
    WHERE Status = N'Approved'
    ORDER BY Id;
END
GO

/* --- s0063MarkBatchSubmitted : ne marque que depuis 'Approved'. --- */
CREATE OR ALTER PROCEDURE dbo.s0063MarkBatchSubmitted
    @BatchId INT, @FileName NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T050EftBatch
    SET Status = N'Submitted',
        FileName = ISNULL(@FileName, FileName),
        GeneratedUtc = ISNULL(GeneratedUtc, SYSUTCDATETIME()),
        SubmittedUtc = SYSUTCDATETIME()
    WHERE Id = @BatchId AND Status = N'Approved';
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'44_eft_controls.sql : termine.';
GO
