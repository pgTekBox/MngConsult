/* =====================================================================
   PortailMaster - Script 07 : Grand livre (partie double) & solde abonné
   ---------------------------------------------------------------------
   Coeur comptable de la plateforme (Phase 1).
     - Partie double, APPEND-ONLY (immuable : triggers bloquant UPD/DEL).
     - Montants en CENTS ENTIERS (BIGINT), jamais de flottant. Devise CAD.
     - Comptes plateforme (mutualises) + comptes par abonne (tenant).

   Comptes plateforme (AbonneId NULL) :
     TRUST    Fiducie / banque        (Actif,   normal Debit)
     FEES     Frais percus            (Produit, normal Credit)
     SUSPENSE Suspens                 (Actif,   normal Debit)
   Comptes par abonne (AbonneId = Id) :
     SUBBAL   Solde de l'abonne       (Passif,  normal Credit)
     RESERVE  Reserve                 (Passif,  normal Credit)
     EFT_IN   EFT en cours entrant    (Clearing,normal Debit)   [phases futures]
     EFT_OUT  EFT en cours sortant    (Clearing,normal Credit)  [phases futures]

   Invariant : TRUST = SUM(SUBBAL) + SUM(RESERVE) + FEES (+ clearing).

   A executer APRES 01-06. Procs numerotees s0014+.
   ===================================================================== */

USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =====================================================================
   1) TABLES
   ===================================================================== */

/* Plan comptable ---------------------------------------------------- */
IF OBJECT_ID(N'dbo.T100LedgerAccount', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T100LedgerAccount
    (
        Id           INT           IDENTITY(1,1) NOT NULL,
        AbonneId     INT           NULL,                 -- NULL = compte plateforme mutualise
        AccountCode  NVARCHAR(30)  NOT NULL,             -- TRUST, FEES, SUBBAL, RESERVE, ...
        Name         NVARCHAR(150) NOT NULL,
        AccountType  NVARCHAR(20)  NOT NULL,             -- Actif / Passif / Produit / Charge / Clearing
        NormalSide   CHAR(1)       NOT NULL,             -- 'D' ou 'C'
        Devise       CHAR(3)       NOT NULL CONSTRAINT DF_T100_Devise DEFAULT ('CAD'),
        IsActive     BIT           NOT NULL CONSTRAINT DF_T100_Active DEFAULT (1),
        CreatedUtc   DATETIME2(0)  NOT NULL CONSTRAINT DF_T100_Created DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_T100LedgerAccount PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT CK_T100_NormalSide CHECK (NormalSide IN ('D','C')),
        CONSTRAINT FK_T100_Abonne FOREIGN KEY (AbonneId) REFERENCES dbo.T010Abonne(Id)
    );
    -- Un seul compte d'un code donne par abonne (et un seul par code cote plateforme).
    CREATE UNIQUE INDEX UX_T100_AbonneCode ON dbo.T100LedgerAccount (AbonneId, AccountCode);
END
GO

/* Ecritures (entetes) ----------------------------------------------- */
IF OBJECT_ID(N'dbo.T101LedgerTransaction', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T101LedgerTransaction
    (
        Id               BIGINT          IDENTITY(1,1) NOT NULL,
        TransactionGUID  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_T101_Guid DEFAULT (NEWID()),
        AbonneId         INT             NULL,          -- abonne concerne (NULL = purement plateforme)
        TxnType          NVARCHAR(40)    NOT NULL,      -- Encaissement / Paiement / MiseEnReserve / ...
        Description      NVARCHAR(300)   NULL,
        Devise           CHAR(3)         NOT NULL CONSTRAINT DF_T101_Devise DEFAULT ('CAD'),
        EffectiveDate    DATE            NOT NULL CONSTRAINT DF_T101_EffDate DEFAULT (CAST(SYSUTCDATETIME() AS DATE)),
        IdempotencyKey   NVARCHAR(100)   NULL,          -- anti double-comptabilisation
        CreatedUtc       DATETIME2(0)    NOT NULL CONSTRAINT DF_T101_Created DEFAULT (SYSUTCDATETIME()),
        CreatedByAdminId INT             NULL,
        CONSTRAINT PK_T101LedgerTransaction PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_T101_Abonne  FOREIGN KEY (AbonneId)         REFERENCES dbo.T010Abonne(Id),
        CONSTRAINT FK_T101_Admin   FOREIGN KEY (CreatedByAdminId) REFERENCES dbo.T001PortalAdmin(Id)
    );
    CREATE UNIQUE INDEX UX_T101_Idempotency ON dbo.T101LedgerTransaction (IdempotencyKey) WHERE IdempotencyKey IS NOT NULL;
    CREATE INDEX IX_T101_Abonne ON dbo.T101LedgerTransaction (AbonneId, Id);
END
GO

/* Lignes d'ecriture (postings) -------------------------------------- */
IF OBJECT_ID(N'dbo.T102LedgerPosting', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T102LedgerPosting
    (
        Id             BIGINT   IDENTITY(1,1) NOT NULL,
        TransactionId  BIGINT   NOT NULL,
        AccountId      INT      NOT NULL,
        DebitCents     BIGINT   NOT NULL CONSTRAINT DF_T102_Debit  DEFAULT (0),
        CreditCents    BIGINT   NOT NULL CONSTRAINT DF_T102_Credit DEFAULT (0),
        Memo           NVARCHAR(200) NULL,
        CONSTRAINT PK_T102LedgerPosting PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_T102_Txn     FOREIGN KEY (TransactionId) REFERENCES dbo.T101LedgerTransaction(Id),
        CONSTRAINT FK_T102_Account FOREIGN KEY (AccountId)     REFERENCES dbo.T100LedgerAccount(Id),
        -- Montants non negatifs et une seule colonne non nulle par ligne.
        CONSTRAINT CK_T102_NonNeg  CHECK (DebitCents >= 0 AND CreditCents >= 0),
        CONSTRAINT CK_T102_OneSide CHECK (DebitCents = 0 OR CreditCents = 0)
    );
    CREATE INDEX IX_T102_Account ON dbo.T102LedgerPosting (AccountId);
    CREATE INDEX IX_T102_Txn     ON dbo.T102LedgerPosting (TransactionId);
END
GO

/* =====================================================================
   2) IMMUTABILITE : bloquer UPDATE/DELETE (append-only).
      Les corrections se font par une ecriture de contre-passation.
   ===================================================================== */
IF OBJECT_ID(N'dbo.TR_T101_Immutable', N'TR') IS NOT NULL DROP TRIGGER dbo.TR_T101_Immutable;
GO
CREATE TRIGGER dbo.TR_T101_Immutable ON dbo.T101LedgerTransaction
INSTEAD OF UPDATE, DELETE AS
BEGIN
    RAISERROR(N'Grand livre immuable : modification/suppression d''une ecriture interdite (utiliser une contre-passation).', 16, 1);
END
GO

IF OBJECT_ID(N'dbo.TR_T102_Immutable', N'TR') IS NOT NULL DROP TRIGGER dbo.TR_T102_Immutable;
GO
CREATE TRIGGER dbo.TR_T102_Immutable ON dbo.T102LedgerPosting
INSTEAD OF UPDATE, DELETE AS
BEGIN
    RAISERROR(N'Grand livre immuable : modification/suppression d''une ligne interdite (utiliser une contre-passation).', 16, 1);
END
GO

/* =====================================================================
   3) COMPTES PLATEFORME (seed idempotent)
   ===================================================================== */
INSERT INTO dbo.T100LedgerAccount (AbonneId, AccountCode, Name, AccountType, NormalSide)
SELECT v.AbonneId, v.AccountCode, v.Name, v.AccountType, v.NormalSide
FROM (VALUES
    (CAST(NULL AS INT), N'TRUST',    N'Fiducie / banque',  N'Actif',   'D'),
    (CAST(NULL AS INT), N'FEES',     N'Frais per' + NCHAR(231) + N'us', N'Produit', 'C'),
    (CAST(NULL AS INT), N'SUSPENSE', N'Suspens',           N'Actif',   'D')
) AS v(AbonneId, AccountCode, Name, AccountType, NormalSide)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.T100LedgerAccount a
    WHERE a.AbonneId IS NULL AND a.AccountCode = v.AccountCode);
GO

/* =====================================================================
   4) PROCEDURES
   ===================================================================== */

/* --- s0014EnsureAbonneAccounts : cree les comptes standard d'un abonne */
CREATE OR ALTER PROCEDURE dbo.s0014EnsureAbonneAccounts
    @AbonneId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @AbonneId IS NULL
    BEGIN RAISERROR(N'AbonneId est requis.', 16, 1); RETURN; END

    INSERT INTO dbo.T100LedgerAccount (AbonneId, AccountCode, Name, AccountType, NormalSide)
    SELECT @AbonneId, v.AccountCode, v.Name, v.AccountType, v.NormalSide
    FROM (VALUES
        (N'SUBBAL',  N'Solde de l''abonn' + NCHAR(233),          N'Passif',   'C'),
        (N'RESERVE', N'R' + NCHAR(233) + N'serve',               N'Passif',   'C'),
        (N'EFT_IN',  N'EFT en cours entrant',                    N'Clearing', 'D'),
        (N'EFT_OUT', N'EFT en cours sortant',                    N'Clearing', 'C')
    ) AS v(AccountCode, Name, AccountType, NormalSide)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.T100LedgerAccount a
        WHERE a.AbonneId = @AbonneId AND a.AccountCode = v.AccountCode);
END
GO

/* --- s0015GetAbonneBalances : soldes (en cents) des comptes d'un abonne */
CREATE OR ALTER PROCEDURE dbo.s0015GetAbonneBalances
    @AbonneId INT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.s0014EnsureAbonneAccounts @AbonneId;

    ;WITH bal AS (
        SELECT a.AccountCode,
               -- Solde oriente selon le cote normal du compte
               CASE a.NormalSide
                    WHEN 'C' THEN ISNULL(SUM(p.CreditCents - p.DebitCents), 0)
                    ELSE          ISNULL(SUM(p.DebitCents  - p.CreditCents), 0)
               END AS SoldeCents
        FROM dbo.T100LedgerAccount a
        LEFT JOIN dbo.T102LedgerPosting p ON p.AccountId = a.Id
        WHERE a.AbonneId = @AbonneId
        GROUP BY a.AccountCode, a.NormalSide
    )
    SELECT
        MAX(CASE WHEN AccountCode = 'SUBBAL'  THEN SoldeCents END) AS SoldeCents,
        MAX(CASE WHEN AccountCode = 'RESERVE' THEN SoldeCents END) AS ReserveCents,
        MAX(CASE WHEN AccountCode = 'EFT_IN'  THEN SoldeCents END) AS EftInCents,
        MAX(CASE WHEN AccountCode = 'EFT_OUT' THEN SoldeCents END) AS EftOutCents
    FROM bal;
END
GO

/* --- s0016ListAbonneJournal : dernieres ecritures d'un abonne, avec la
       variation de Solde (SUBBAL) et de Reserve pour chaque ecriture.   */
CREATE OR ALTER PROCEDURE dbo.s0016ListAbonneJournal
    @AbonneId INT,
    @Top      INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        t.Id,
        t.EffectiveDate,
        t.TxnType,
        t.Description,
        t.CreatedUtc,
        ISNULL((SELECT SUM(p.CreditCents - p.DebitCents)
                FROM dbo.T102LedgerPosting p
                JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId
                WHERE p.TransactionId = t.Id AND a.AbonneId = @AbonneId AND a.AccountCode = 'SUBBAL'), 0) AS DeltaSoldeCents,
        ISNULL((SELECT SUM(p.CreditCents - p.DebitCents)
                FROM dbo.T102LedgerPosting p
                JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId
                WHERE p.TransactionId = t.Id AND a.AbonneId = @AbonneId AND a.AccountCode = 'RESERVE'), 0) AS DeltaReserveCents
    FROM dbo.T101LedgerTransaction t
    WHERE t.AbonneId = @AbonneId
    ORDER BY t.Id DESC;
END
GO

/* --- s0017RecordAbonneMovement : comptabilise un mouvement (partie double).
       @Operation : Encaissement | Paiement | MiseEnReserve | LiberationReserve
       Montants en cents (>0). @FeeCents utilise seulement pour Encaissement.
       Idempotent via @IdempotencyKey. Renvoie l'Id de l'ecriture.          */
CREATE OR ALTER PROCEDURE dbo.s0017RecordAbonneMovement
    @AbonneId       INT,
    @Operation      NVARCHAR(30),
    @AmountCents    BIGINT,
    @FeeCents       BIGINT        = 0,
    @Description    NVARCHAR(300) = NULL,
    @IdempotencyKey NVARCHAR(100) = NULL,
    @AdminId        INT           = NULL,
    @TransactionId  BIGINT        = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @TransactionId = NULL;   -- ne jamais heriter d'une valeur passee par l'appelant

    IF @AbonneId IS NULL
    BEGIN RAISERROR(N'AbonneId est requis.', 16, 1); RETURN; END
    IF @AmountCents IS NULL OR @AmountCents <= 0
    BEGIN RAISERROR(N'Le montant doit etre superieur a zero.', 16, 1); RETURN; END
    IF @FeeCents IS NULL SET @FeeCents = 0;

    -- Idempotence : si la cle existe deja, renvoyer l'ecriture existante.
    IF @IdempotencyKey IS NOT NULL
    BEGIN
        SELECT @TransactionId = Id FROM dbo.T101LedgerTransaction WHERE IdempotencyKey = @IdempotencyKey;
        IF @TransactionId IS NOT NULL
        BEGIN SELECT @TransactionId AS TransactionId; RETURN; END
    END

    EXEC dbo.s0014EnsureAbonneAccounts @AbonneId;

    DECLARE @trust   INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId IS NULL AND AccountCode = 'TRUST');
    DECLARE @fees    INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId IS NULL AND AccountCode = 'FEES');
    DECLARE @subbal  INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'SUBBAL');
    DECLARE @reserve INT = (SELECT Id FROM dbo.T100LedgerAccount WHERE AbonneId = @AbonneId AND AccountCode = 'RESERVE');

    DECLARE @avail  BIGINT = (SELECT ISNULL(SUM(CreditCents - DebitCents),0) FROM dbo.T102LedgerPosting WHERE AccountId = @subbal);
    DECLARE @resBal BIGINT = (SELECT ISNULL(SUM(CreditCents - DebitCents),0) FROM dbo.T102LedgerPosting WHERE AccountId = @reserve);

    BEGIN TRAN;

    INSERT INTO dbo.T101LedgerTransaction (AbonneId, TxnType, Description, IdempotencyKey, CreatedByAdminId)
    VALUES (@AbonneId, @Operation, @Description, @IdempotencyKey, @AdminId);
    SET @TransactionId = CAST(SCOPE_IDENTITY() AS BIGINT);

    IF @Operation = N'Encaissement'
    BEGIN
        IF @FeeCents < 0 OR @FeeCents > @AmountCents
        BEGIN RAISERROR(N'Frais invalides.', 16, 1); RETURN; END
        -- DR Trust (brut) ; CR Solde abonne (net) ; CR Frais
        INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
        VALUES (@TransactionId, @trust,  @AmountCents, 0),
               (@TransactionId, @subbal, 0, @AmountCents - @FeeCents);
        IF @FeeCents > 0
            INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
            VALUES (@TransactionId, @fees, 0, @FeeCents);
    END
    ELSE IF @Operation = N'Paiement'
    BEGIN
        IF @avail < @AmountCents
        BEGIN RAISERROR(N'Solde insuffisant pour ce paiement.', 16, 1); RETURN; END
        -- DR Solde abonne ; CR Trust
        INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
        VALUES (@TransactionId, @subbal, @AmountCents, 0),
               (@TransactionId, @trust,  0, @AmountCents);
    END
    ELSE IF @Operation = N'MiseEnReserve'
    BEGIN
        IF @avail < @AmountCents
        BEGIN RAISERROR(N'Solde insuffisant pour mise en reserve.', 16, 1); RETURN; END
        INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
        VALUES (@TransactionId, @subbal,  @AmountCents, 0),
               (@TransactionId, @reserve, 0, @AmountCents);
    END
    ELSE IF @Operation = N'LiberationReserve'
    BEGIN
        IF @resBal < @AmountCents
        BEGIN RAISERROR(N'Reserve insuffisante.', 16, 1); RETURN; END
        INSERT INTO dbo.T102LedgerPosting (TransactionId, AccountId, DebitCents, CreditCents)
        VALUES (@TransactionId, @reserve, @AmountCents, 0),
               (@TransactionId, @subbal,  0, @AmountCents);
    END
    ELSE
    BEGIN RAISERROR(N'Operation inconnue.', 16, 1); RETURN; END

    -- Garde-fou partie double : debits = credits.
    IF (SELECT SUM(DebitCents) - SUM(CreditCents) FROM dbo.T102LedgerPosting WHERE TransactionId = @TransactionId) <> 0
    BEGIN RAISERROR(N'Ecriture desequilibree.', 16, 1); RETURN; END

    COMMIT;
    SELECT @TransactionId AS TransactionId;
END
GO

/* --- s0018GetPlatformSummary : totaux plateforme + verification invariant */
CREATE OR ALTER PROCEDURE dbo.s0018GetPlatformSummary
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @trust BIGINT = (
        SELECT ISNULL(SUM(p.DebitCents - p.CreditCents),0)
        FROM dbo.T102LedgerPosting p JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId
        WHERE a.AbonneId IS NULL AND a.AccountCode = 'TRUST');
    DECLARE @fees BIGINT = (
        SELECT ISNULL(SUM(p.CreditCents - p.DebitCents),0)
        FROM dbo.T102LedgerPosting p JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId
        WHERE a.AbonneId IS NULL AND a.AccountCode = 'FEES');
    DECLARE @subbal BIGINT = (
        SELECT ISNULL(SUM(p.CreditCents - p.DebitCents),0)
        FROM dbo.T102LedgerPosting p JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId
        WHERE a.AccountCode = 'SUBBAL');
    DECLARE @reserve BIGINT = (
        SELECT ISNULL(SUM(p.CreditCents - p.DebitCents),0)
        FROM dbo.T102LedgerPosting p JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId
        WHERE a.AccountCode = 'RESERVE');
    DECLARE @eftIn BIGINT = (
        SELECT ISNULL(SUM(p.DebitCents - p.CreditCents),0)
        FROM dbo.T102LedgerPosting p JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId
        WHERE a.AccountCode = 'EFT_IN');
    DECLARE @eftOut BIGINT = (
        SELECT ISNULL(SUM(p.CreditCents - p.DebitCents),0)
        FROM dbo.T102LedgerPosting p JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId
        WHERE a.AccountCode = 'EFT_OUT');

    SELECT
        @trust                                            AS TrustCents,
        @subbal                                           AS TotalSoldeCents,
        @reserve                                          AS TotalReserveCents,
        @fees                                             AS FeesCents,
        @eftIn                                            AS EftInCents,
        @eftOut                                           AS EftOutCents,
        (@subbal + @reserve + @fees + @eftOut - @eftIn)   AS PassifTotalCents,
        CASE WHEN @trust = (@subbal + @reserve + @fees + @eftOut - @eftIn)
             THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END  AS InvariantOK,
        (SELECT COUNT(*) FROM dbo.T101LedgerTransaction)  AS NbEcritures;
END
GO

/* --- s0019GetTransactionPostings : lignes d'une ecriture (pour le detail) */
CREATE OR ALTER PROCEDURE dbo.s0019GetTransactionPostings
    @TransactionId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.Id, a.AccountCode, a.Name, a.AbonneId, p.DebitCents, p.CreditCents, p.Memo
    FROM dbo.T102LedgerPosting p
    JOIN dbo.T100LedgerAccount a ON a.Id = p.AccountId
    WHERE p.TransactionId = @TransactionId
    ORDER BY p.Id;
END
GO

/* Provisionner les comptes pour les abonnes deja existants. */
DECLARE @id INT;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT Id FROM dbo.T010Abonne;
OPEN cur; FETCH NEXT FROM cur INTO @id;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC dbo.s0014EnsureAbonneAccounts @id;
    FETCH NEXT FROM cur INTO @id;
END
CLOSE cur; DEALLOCATE cur;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'07_grand_livre.sql : termine.';
GO
