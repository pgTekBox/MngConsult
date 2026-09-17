-- =============================================================================
-- T237 — Les rapports de contrôle
--
-- Les quatre derniers ne sont pas des listes mais des ÉTATS : ils ne servent pas
-- à créer quoi que ce soit, ils servent à vérifier. Quand la reprise sera faite,
-- la question ne sera pas « ai-je tout importé ? » mais « mon bilan donne-t-il
-- le même total que celui de la source ? ». Ces tables portent la réponse.
--
-- DEUX FORMES, DEUX TABLES — et c'est la source qui l'impose, vérifié en direct :
--
--   · Bilan et résultats sont des ARBRES de sections et de comptes :
--        ACTIFS 223 → Actifs à court terme 223 → Comptes clients 223 (compte 58)
--     staging.RapportImport (l'entête : type, période, devise) +
--     staging.RapportImportLigne (l'arbre aplati : section, niveau, ordre).
--     Aplatir plutôt que stocker un arbre : on veut pouvoir sommer, comparer et
--     afficher sans récursion.
--
--   · Les balances âgées sont des montants PAR TIERS ET PAR TRANCHE :
--        Comcap Inc · CAD · 2026-08-18 au 2026-09-16 · 0,00
--     Rien à voir avec un arbre de comptes. staging.BalanceAgeeImport, à plat.
--
-- Les mêler aurait donné une table à moitié vide dans les deux cas — la leçon
-- déjà apprise avec les listes de structure.
--
-- Procédures : s0810 à s0813.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) L'entête d'un rapport
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.RapportImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.RapportImport
    (
        [Id]            INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]  INT               NULL,
        [RunId]         INT               NULL,
        [CompanyGUID]   UNIQUEIDENTIFIER  NOT NULL,

        -- Bilan · Resultats
        [Genre]         VARCHAR(20)       NOT NULL,
        [NomSource]     NVARCHAR(100)     NULL,
        [DateDebut]     DATE              NULL,
        [DateFin]       DATE              NULL,
        [Devise]        VARCHAR(10)       NULL,

        -- Les totaux que la source annonce, gardés tels quels : c'est à eux
        -- qu'on confrontera les nôtres.
        [TotalActif]    DECIMAL(18,2)     NULL,
        [TotalPassif]   DECIMAL(18,2)     NULL,
        [TotalCapital]  DECIMAL(18,2)     NULL,
        [TotalRevenus]  DECIMAL(18,2)     NULL,
        [TotalDepenses] DECIMAL(18,2)     NULL,
        [ResultatNet]   DECIMAL(18,2)     NULL,

        [NbLignes]      INT               NOT NULL CONSTRAINT DF_Rapport_NbLignes DEFAULT (0),
        [Created]       DATETIME          NOT NULL CONSTRAINT DF_Rapport_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_RapportImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT CK_Rapport_Genre CHECK ([Genre] IN ('Bilan', 'Resultats')),
        CONSTRAINT FK_Rapport_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_Rapport_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_Rapport_Company ON staging.RapportImport ([CompanyGUID], [Genre]);
END
GO

IF OBJECT_ID('staging.RapportImportLigne', 'U') IS NULL
BEGIN
    CREATE TABLE staging.RapportImportLigne
    (
        [Id]               INT IDENTITY(1,1) NOT NULL,
        [RapportId]        INT               NOT NULL,

        -- La branche de l'arbre : ACTIF, PASSIF, CAPITAL, REVENUS, COUT_VENTES,
        -- DEPENSES, AUTRES_REVENUS, AUTRES_DEPENSES, RESULTAT
        [Section]          VARCHAR(30)       NOT NULL,
        -- 0 = le titre de section, 1 = sous-total, 2+ = le détail
        [Niveau]           INT               NOT NULL CONSTRAINT DF_RapportLigne_Niveau DEFAULT (0),
        [Ordre]            INT               NOT NULL CONSTRAINT DF_RapportLigne_Ordre DEFAULT (0),

        [Libelle]          NVARCHAR(400)     NULL,
        [CompteExterneId]  NVARCHAR(100)     NULL,
        [Montant]          DECIMAL(18,2)     NULL,

        -- Vrai pour les lignes de total : elles ne se somment pas avec le détail.
        [EstTotal]         BIT               NOT NULL CONSTRAINT DF_RapportLigne_EstTotal DEFAULT (0),
        [Created]          DATETIME          NOT NULL CONSTRAINT DF_RapportLigne_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_RapportImportLigne PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_RapportLigne_Rapport FOREIGN KEY ([RapportId])
            REFERENCES staging.RapportImport ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_RapportLigne_Rapport ON staging.RapportImportLigne ([RapportId], [Section], [Ordre]);
END
GO

-- -----------------------------------------------------------------------------
-- 2) Les balances âgées
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.BalanceAgeeImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.BalanceAgeeImport
    (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]    INT               NULL,
        [RunId]           INT               NULL,
        [CompanyGUID]     UNIQUEIDENTIFIER  NOT NULL,

        -- Client (ce qu'on nous doit) ou Fournisseur (ce qu'on doit)
        [Genre]           VARCHAR(20)       NOT NULL,
        [DateArrete]      DATE              NULL,
        [LongueurPeriode] INT               NULL,

        [TiersExterneId]  NVARCHAR(100)     NULL,
        [TiersNom]        NVARCHAR(500)     NULL,
        [PartyGUID]       UNIQUEIDENTIFIER  NULL,
        [Devise]          VARCHAR(10)       NULL,

        -- Le total du tiers, répété sur chacune de ses tranches : c'est le
        -- prix à payer pour une table plate, et il est faible.
        [TotalTiers]      DECIMAL(18,2)     NULL,

        [PeriodeOrdre]    INT               NOT NULL CONSTRAINT DF_BalanceAgee_Ordre DEFAULT (0),
        [PeriodeDebut]    DATE              NULL,
        [PeriodeFin]      DATE              NULL,
        [Montant]         DECIMAL(18,2)     NULL,

        [Created]         DATETIME          NOT NULL CONSTRAINT DF_BalanceAgee_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_BalanceAgeeImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT CK_BalanceAgee_Genre CHECK ([Genre] IN ('Client', 'Fournisseur')),
        CONSTRAINT FK_BalanceAgee_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_BalanceAgee_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_BalanceAgee_Company ON staging.BalanceAgeeImport ([CompanyGUID], [Genre]);
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0810ChargerRapportImport
--    Le VB aplatit l'arbre avant d'appeler : la récursion se fait mieux en .NET
--    qu'en T-SQL, et la procédure n'a plus qu'à ranger des lignes déjà ordonnées.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0810ChargerRapportImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @Genre VARCHAR(20),
    @ImportFileId INT = NULL,
    @Entete NVARCHAR(MAX), @Lignes NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL THROW 50388, 'Aucune compagnie : impossible de déposer ce rapport.', 1;
    IF @Genre NOT IN ('Bilan', 'Resultats') THROW 50389, 'Genre de rapport inconnu.', 1;

    BEGIN TRANSACTION;

    DELETE l
      FROM staging.RapportImportLigne l
      JOIN staging.RapportImport r ON r.[Id] = l.[RapportId]
     WHERE r.[CompanyGUID] = @CompanyGUID AND r.[Genre] = @Genre;

    DELETE FROM staging.RapportImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Genre] = @Genre;

    DECLARE @RapportId INT;

    INSERT INTO staging.RapportImport
        ([RunId], [ImportFileId], [CompanyGUID], [Genre], [NomSource],
         [DateDebut], [DateFin], [Devise],
         [TotalActif], [TotalPassif], [TotalCapital],
         [TotalRevenus], [TotalDepenses], [ResultatNet])
    SELECT @RunId, @ImportFileId, @CompanyGUID, @Genre, j.[nom],
           TRY_CONVERT(DATE, NULLIF(j.[debut], '')),
           TRY_CONVERT(DATE, NULLIF(j.[fin], '')),
           LEFT(j.[devise], 10),
           TRY_CONVERT(DECIMAL(18,2), j.[actif]),
           TRY_CONVERT(DECIMAL(18,2), j.[passif]),
           TRY_CONVERT(DECIMAL(18,2), j.[capital]),
           TRY_CONVERT(DECIMAL(18,2), j.[revenus]),
           TRY_CONVERT(DECIMAL(18,2), j.[depenses]),
           TRY_CONVERT(DECIMAL(18,2), j.[resultat])
      FROM OPENJSON(@Entete)
           WITH ([nom]      NVARCHAR(100) '$.nom',
                 [debut]    NVARCHAR(40)  '$.debut',
                 [fin]      NVARCHAR(40)  '$.fin',
                 [devise]   NVARCHAR(20)  '$.devise',
                 [actif]    NVARCHAR(40)  '$.actif',
                 [passif]   NVARCHAR(40)  '$.passif',
                 [capital]  NVARCHAR(40)  '$.capital',
                 [revenus]  NVARCHAR(40)  '$.revenus',
                 [depenses] NVARCHAR(40)  '$.depenses',
                 [resultat] NVARCHAR(40)  '$.resultat') AS j;

    SET @RapportId = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO staging.RapportImportLigne
        ([RapportId], [Section], [Niveau], [Ordre], [Libelle], [CompteExterneId],
         [Montant], [EstTotal])
    SELECT @RapportId, LEFT(j.[section], 30), j.[niveau], j.[ordre],
           j.[libelle], LEFT(j.[compte_id], 100),
           TRY_CONVERT(DECIMAL(18,2), j.[montant]),
           CASE WHEN j.[total] = 1 THEN 1 ELSE 0 END
      FROM OPENJSON(@Lignes)
           WITH ([section]   NVARCHAR(40)  '$.section',
                 [niveau]    INT           '$.niveau',
                 [ordre]     INT           '$.ordre',
                 [libelle]   NVARCHAR(400) '$.libelle',
                 [compte_id] NVARCHAR(200) '$.compte_id',
                 [montant]   NVARCHAR(40)  '$.montant',
                 [total]     INT           '$.total') AS j;

    UPDATE staging.RapportImport
       SET [NbLignes] = (SELECT COUNT(*) FROM staging.RapportImportLigne
                          WHERE [RapportId] = @RapportId)
     WHERE [Id] = @RapportId;

    COMMIT TRANSACTION;

    SELECT @RapportId AS [RapportId],
           (SELECT COUNT(*) FROM staging.RapportImportLigne WHERE [RapportId] = @RapportId) AS [NbLignes];
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0811GetRapportImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Genre       VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [Genre], [NomSource], [DateDebut], [DateFin], [Devise],
           [TotalActif], [TotalPassif], [TotalCapital],
           [TotalRevenus], [TotalDepenses], [ResultatNet], [NbLignes], [Created]
      FROM staging.RapportImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND (@Genre IS NULL OR @Genre = '' OR [Genre] = @Genre)
     ORDER BY [Genre];

    SELECT l.[RapportId], r.[Genre], l.[Section], l.[Niveau], l.[Ordre],
           l.[Libelle], l.[CompteExterneId], l.[Montant], l.[EstTotal]
      FROM staging.RapportImportLigne l
      JOIN staging.RapportImport r ON r.[Id] = l.[RapportId]
     WHERE r.[CompanyGUID] = @CompanyGUID
       AND (@Genre IS NULL OR @Genre = '' OR r.[Genre] = @Genre)
     ORDER BY r.[Genre], l.[Ordre];
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0812ChargerBalanceAgee
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0812ChargerBalanceAgee]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @Genre VARCHAR(20),
    @ImportFileId INT = NULL, @Lignes NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL THROW 50390, 'Aucune compagnie : impossible de déposer cette balance.', 1;
    IF @Genre NOT IN ('Client', 'Fournisseur') THROW 50391, 'Genre de balance âgée inconnu.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.BalanceAgeeImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Genre] = @Genre;

    INSERT INTO staging.BalanceAgeeImport
        ([RunId], [ImportFileId], [CompanyGUID], [Genre], [DateArrete], [LongueurPeriode],
         [TiersExterneId], [TiersNom], [Devise], [TotalTiers],
         [PeriodeOrdre], [PeriodeDebut], [PeriodeFin], [Montant])
    SELECT @RunId, @ImportFileId, @CompanyGUID, @Genre,
           TRY_CONVERT(DATE, NULLIF(j.[arrete], '')),
           j.[longueur],
           LEFT(j.[tiers_id], 100), j.[tiers], LEFT(j.[devise], 10),
           TRY_CONVERT(DECIMAL(18,2), j.[total_tiers]),
           j.[ordre],
           TRY_CONVERT(DATE, NULLIF(j.[debut], '')),
           TRY_CONVERT(DATE, NULLIF(j.[fin], '')),
           TRY_CONVERT(DECIMAL(18,2), j.[montant])
      FROM OPENJSON(@Lignes)
           WITH ([arrete]      NVARCHAR(40)  '$.arrete',
                 [longueur]    INT           '$.longueur',
                 [tiers_id]    NVARCHAR(200) '$.tiers_id',
                 [tiers]       NVARCHAR(500) '$.tiers',
                 [devise]      NVARCHAR(20)  '$.devise',
                 [total_tiers] NVARCHAR(40)  '$.total_tiers',
                 [ordre]       INT           '$.ordre',
                 [debut]       NVARCHAR(40)  '$.debut',
                 [fin]         NVARCHAR(40)  '$.fin',
                 [montant]     NVARCHAR(40)  '$.montant') AS j;

    -- Le tiers retrouvé par son nom, comme partout ailleurs.
    UPDATE b
       SET b.[PartyGUID] = p.[PartyGUID]
      FROM staging.BalanceAgeeImport b
      JOIN dbo.T050Party p
        ON p.[CompanyGUID] = @CompanyGUID
       AND (p.[Name] = b.[TiersNom] OR p.[DisplayName] = b.[TiersNom])
     WHERE b.[CompanyGUID] = @CompanyGUID AND b.[Genre] = @Genre
       AND b.[TiersNom] IS NOT NULL;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbLignes],
           COUNT(DISTINCT [TiersExterneId]) AS [NbTiers],
           SUM(CASE WHEN [PartyGUID] IS NULL THEN 1 ELSE 0 END) AS [NbSansTiers],
           SUM([Montant]) AS [Total]
      FROM staging.BalanceAgeeImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Genre] = @Genre;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0813GetBalanceAgee]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Genre       VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Genre], [DateArrete], [LongueurPeriode],
           COUNT(DISTINCT [TiersExterneId]) AS [NbTiers],
           SUM([Montant]) AS [Total]
      FROM staging.BalanceAgeeImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND (@Genre IS NULL OR @Genre = '' OR [Genre] = @Genre)
     GROUP BY [Genre], [DateArrete], [LongueurPeriode]
     ORDER BY [Genre];

    SELECT [Id], [Genre], [TiersExterneId], [TiersNom], [PartyGUID], [Devise],
           [TotalTiers], [PeriodeOrdre], [PeriodeDebut], [PeriodeFin], [Montant]
      FROM staging.BalanceAgeeImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND (@Genre IS NULL OR @Genre = '' OR [Genre] = @Genre)
     ORDER BY [Genre], [TiersNom], [PeriodeOrdre];
END
GO
