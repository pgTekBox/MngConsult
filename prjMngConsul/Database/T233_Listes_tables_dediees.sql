-- =============================================================================
-- T233 — Une table par liste, staging.ReferenceImport supprimée
--
-- T232 rangeait six listes dans une seule table, distinguées par un [Genre].
-- L'économie était réelle mais le prix aussi : aucune des six ne pouvait avoir
-- ses propres colonnes. Un compte bancaire a un solde, une devise, une
-- institution et un compte du grand livre ; un département a un parent et rien
-- d'autre. Les loger ensemble, c'est soit une table pleine de colonnes vides,
-- soit six listes appauvries au plus petit dénominateur.
--
-- Six tables, donc, chacune avec ce que sa notion demande :
--
--   staging.ModePaiementImport        code, nom, type
--   staging.CategorieSuiviImport      code, nom, parent
--   staging.DepartementImport         code, nom, parent
--   staging.EmplacementImport         code, nom, parent, adresse
--   staging.JournalImport             symbole, nom, type, devise
--   staging.CompteBancaireImport      numéro masqué, type, devise, soldes,
--                                     institution, compte du grand livre
--
-- Ce qu'elles gardent en commun — le rattachement au registre, le rang, le
-- verdict, l'élément d'origine — reste nommé pareil partout : une requête écrite
-- pour l'une se lit sur les autres.
--
-- 🔒 Le numéro de compte bancaire n'est TOUJOURS pas stocké en clair : seuls les
--    quatre derniers chiffres descendent en base. Une table de préparation n'est
--    pas l'endroit d'un numéro de compte complet.
--
-- Procédures : s0797 à s0803.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) La table générique s'en va — et ses procédures avec elle.
--    Chaque DROP dans son propre lot : un lot qui mélange DROP et référence à
--    l'objet supprimé échoue à la compilation du plan (erreur 8624).
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.s0795ChargerReferenceImport', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[s0795ChargerReferenceImport];
GO

IF OBJECT_ID('dbo.s0796GetReferenceImport', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[s0796GetReferenceImport];
GO

IF OBJECT_ID('staging.ReferenceImport', 'U') IS NOT NULL
    DROP TABLE staging.ReferenceImport;
GO

-- -----------------------------------------------------------------------------
-- 2) Les six tables
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.ModePaiementImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.ModePaiementImport
    (
        [Id]            INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]  INT               NULL,
        [RunId]         INT               NULL,
        [CompanyGUID]   UNIQUEIDENTIFIER  NOT NULL,
        [Rang]          INT               NOT NULL CONSTRAINT DF_ModePaiementImport_Rang DEFAULT (0),

        [ExterneId]     NVARCHAR(100)     NULL,
        [Code]          NVARCHAR(100)     NULL,
        [Nom]           NVARCHAR(300)     NULL,
        -- cash · cheque · credit_card · bank_transfer · other
        [TypeSource]    NVARCHAR(60)      NULL,
        [StatutSource]  NVARCHAR(40)      NULL,

        [Extra]         NVARCHAR(MAX)     NULL,
        [Statut]        VARCHAR(20)       NOT NULL CONSTRAINT DF_ModePaiementImport_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]      NVARCHAR(400)     NULL,
        [Created]       DATETIME          NOT NULL CONSTRAINT DF_ModePaiementImport_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_ModePaiementImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_ModePaiementImport_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_ModePaiementImport_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_ModePaiementImport_Company ON staging.ModePaiementImport ([CompanyGUID]);
    CREATE INDEX IX_ModePaiementImport_File ON staging.ModePaiementImport ([ImportFileId]);
END
GO

IF OBJECT_ID('staging.CategorieSuiviImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.CategorieSuiviImport
    (
        [Id]               INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]     INT               NULL,
        [RunId]            INT               NULL,
        [CompanyGUID]      UNIQUEIDENTIFIER  NOT NULL,
        [Rang]             INT               NOT NULL CONSTRAINT DF_CategorieSuiviImport_Rang DEFAULT (0),

        [ExterneId]        NVARCHAR(100)     NULL,
        [Code]             NVARCHAR(100)     NULL,
        [Nom]              NVARCHAR(300)     NULL,
        -- Les catégories de suivi s'emboîtent : « Région » puis « Région/Est ».
        [ParentExterneId]  NVARCHAR(100)     NULL,
        [StatutSource]     NVARCHAR(40)      NULL,

        [Extra]            NVARCHAR(MAX)     NULL,
        [Statut]           VARCHAR(20)       NOT NULL CONSTRAINT DF_CategorieSuiviImport_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]         NVARCHAR(400)     NULL,
        [Created]          DATETIME          NOT NULL CONSTRAINT DF_CategorieSuiviImport_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_CategorieSuiviImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_CategorieSuiviImport_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_CategorieSuiviImport_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_CategorieSuiviImport_Company ON staging.CategorieSuiviImport ([CompanyGUID]);
    CREATE INDEX IX_CategorieSuiviImport_File ON staging.CategorieSuiviImport ([ImportFileId]);
END
GO

IF OBJECT_ID('staging.DepartementImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.DepartementImport
    (
        [Id]               INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]     INT               NULL,
        [RunId]            INT               NULL,
        [CompanyGUID]      UNIQUEIDENTIFIER  NOT NULL,
        [Rang]             INT               NOT NULL CONSTRAINT DF_DepartementImport_Rang DEFAULT (0),

        [ExterneId]        NVARCHAR(100)     NULL,
        [Code]             NVARCHAR(100)     NULL,
        [Nom]              NVARCHAR(300)     NULL,
        [ParentExterneId]  NVARCHAR(100)     NULL,
        [StatutSource]     NVARCHAR(40)      NULL,

        [Extra]            NVARCHAR(MAX)     NULL,
        [Statut]           VARCHAR(20)       NOT NULL CONSTRAINT DF_DepartementImport_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]         NVARCHAR(400)     NULL,
        [Created]          DATETIME          NOT NULL CONSTRAINT DF_DepartementImport_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_DepartementImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_DepartementImport_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_DepartementImport_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_DepartementImport_Company ON staging.DepartementImport ([CompanyGUID]);
    CREATE INDEX IX_DepartementImport_File ON staging.DepartementImport ([ImportFileId]);
END
GO

IF OBJECT_ID('staging.EmplacementImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.EmplacementImport
    (
        [Id]               INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]     INT               NULL,
        [RunId]            INT               NULL,
        [CompanyGUID]      UNIQUEIDENTIFIER  NOT NULL,
        [Rang]             INT               NOT NULL CONSTRAINT DF_EmplacementImport_Rang DEFAULT (0),

        [ExterneId]        NVARCHAR(100)     NULL,
        [Code]             NVARCHAR(100)     NULL,
        [Nom]              NVARCHAR(300)     NULL,
        [ParentExterneId]  NVARCHAR(100)     NULL,
        -- Un emplacement a souvent une adresse, contrairement à un département.
        [Adresse]          NVARCHAR(400)     NULL,
        [Ville]            NVARCHAR(150)     NULL,
        [Province]         NVARCHAR(100)     NULL,
        [CodePostal]       NVARCHAR(30)      NULL,
        [Pays]             NVARCHAR(100)     NULL,
        [StatutSource]     NVARCHAR(40)      NULL,

        [Extra]            NVARCHAR(MAX)     NULL,
        [Statut]           VARCHAR(20)       NOT NULL CONSTRAINT DF_EmplacementImport_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]         NVARCHAR(400)     NULL,
        [Created]          DATETIME          NOT NULL CONSTRAINT DF_EmplacementImport_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_EmplacementImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_EmplacementImport_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_EmplacementImport_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_EmplacementImport_Company ON staging.EmplacementImport ([CompanyGUID]);
    CREATE INDEX IX_EmplacementImport_File ON staging.EmplacementImport ([ImportFileId]);
END
GO

IF OBJECT_ID('staging.JournalImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.JournalImport
    (
        [Id]            INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]  INT               NULL,
        [RunId]         INT               NULL,
        [CompanyGUID]   UNIQUEIDENTIFIER  NOT NULL,
        [Rang]          INT               NOT NULL CONSTRAINT DF_JournalImport_Rang DEFAULT (0),

        [ExterneId]     NVARCHAR(100)     NULL,
        -- Le « symbole » d'un journal : VTE, ACH, BQ, OD…
        [Symbole]       NVARCHAR(40)      NULL,
        [Nom]           NVARCHAR(300)     NULL,
        [Description]   NVARCHAR(500)     NULL,
        -- sale · purchase · cash · general
        [TypeSource]    NVARCHAR(60)      NULL,
        [Devise]        VARCHAR(10)       NULL,
        [StatutSource]  NVARCHAR(40)      NULL,

        [Extra]         NVARCHAR(MAX)     NULL,
        [Statut]        VARCHAR(20)       NOT NULL CONSTRAINT DF_JournalImport_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]      NVARCHAR(400)     NULL,
        [Created]       DATETIME          NOT NULL CONSTRAINT DF_JournalImport_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_JournalImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_JournalImport_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_JournalImport_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_JournalImport_Company ON staging.JournalImport ([CompanyGUID]);
    CREATE INDEX IX_JournalImport_File ON staging.JournalImport ([ImportFileId]);
END
GO

IF OBJECT_ID('staging.CompteBancaireImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.CompteBancaireImport
    (
        [Id]                 INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]       INT               NULL,
        [RunId]              INT               NULL,
        [CompanyGUID]        UNIQUEIDENTIFIER  NOT NULL,
        [Rang]               INT               NOT NULL CONSTRAINT DF_CompteBancaireImport_Rang DEFAULT (0),

        [ExterneId]          NVARCHAR(100)     NULL,
        [Nom]                NVARCHAR(300)     NULL,

        -- 🔒 Les quatre derniers chiffres, jamais le numéro entier. Assez pour
        --    reconnaître un compte à l'écran, pas assez pour s'en servir.
        [NumeroMasque]       VARCHAR(20)       NULL,
        [InstitutionNom]     NVARCHAR(200)     NULL,
        -- checking · savings · credit_card · loan
        [TypeCompte]         NVARCHAR(60)      NULL,
        [Devise]             VARCHAR(10)       NULL,

        [Solde]              DECIMAL(18,2)     NULL,
        [SoldeDisponible]    DECIMAL(18,2)     NULL,
        [DateSolde]          DATE              NULL,

        -- Le compte du grand livre auquel la banque est rattachée chez la
        -- source : c'est par lui que le rapprochement se fera un jour.
        [CompteGLExterneId]  NVARCHAR(100)     NULL,
        [CompteGLNom]        NVARCHAR(300)     NULL,

        [StatutSource]       NVARCHAR(40)      NULL,

        [Extra]              NVARCHAR(MAX)     NULL,
        [Statut]             VARCHAR(20)       NOT NULL CONSTRAINT DF_CompteBancaireImport_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]           NVARCHAR(400)     NULL,
        [Created]            DATETIME          NOT NULL CONSTRAINT DF_CompteBancaireImport_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_CompteBancaireImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_CompteBancaireImport_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_CompteBancaireImport_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_CompteBancaireImport_Company ON staging.CompteBancaireImport ([CompanyGUID]);
    CREATE INDEX IX_CompteBancaireImport_File ON staging.CompteBancaireImport ([ImportFileId]);
END
GO

-- -----------------------------------------------------------------------------
-- 3) Les chargements, un par liste
--
--    Toutes suivent le même patron, et c'est voulu : une relecture remplace la
--    liste précédente de la compagnie, les nombres passent par TRY_CONVERT
--    (cf. T231 — un champ vide chez la source ne doit pas faire échouer l'import),
--    et trois verdicts suffisent :
--
--      NOUVEAU   lu sans réserve
--      DOUBLON   le même identifiant revient dans la même extraction
--      INVALIDE  ni nom ni code — rien pour le désigner
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0797ChargerModesPaiementImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50376, 'Aucune compagnie : impossible de déposer les modes de paiement.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.ModePaiementImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[externe_id], '') ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Elements)
               WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                     [code] NVARCHAR(100) '$.code', [nom] NVARCHAR(300) '$.nom',
                     [type] NVARCHAR(60) '$.type', [statut] NVARCHAR(40) '$.statut',
                     [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j
    )
    INSERT INTO staging.ModePaiementImport
        ([ImportFileId], [RunId], [CompanyGUID], [Rang], [ExterneId], [Code], [Nom],
         [TypeSource], [StatutSource], [Extra], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[code], ''), NULLIF(l.[nom], ''),
           NULLIF(l.[type], ''), NULLIF(l.[statut], ''), l.[extra],
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[code], '') IS NULL THEN 'INVALIDE'
                WHEN l.[Occ] > 1 THEN 'DOUBLON' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[code], '') IS NULL
                     THEN N'Ni nom ni code : rien pour identifier ce mode de paiement.'
                WHEN l.[Occ] > 1
                     THEN N'Cet identifiant apparaît plusieurs fois dans la même extraction.'
                ELSE NULL END
      FROM Lu l;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'DOUBLON' THEN 1 ELSE 0 END)  AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.ModePaiementImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0798ChargerCategoriesSuiviImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50377, 'Aucune compagnie : impossible de déposer les catégories de suivi.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.CategorieSuiviImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[externe_id], '') ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Elements)
               WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                     [code] NVARCHAR(100) '$.code', [nom] NVARCHAR(300) '$.nom',
                     [parent_id] NVARCHAR(100) '$.parent_id', [statut] NVARCHAR(40) '$.statut',
                     [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j
    )
    INSERT INTO staging.CategorieSuiviImport
        ([ImportFileId], [RunId], [CompanyGUID], [Rang], [ExterneId], [Code], [Nom],
         [ParentExterneId], [StatutSource], [Extra], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[code], ''), NULLIF(l.[nom], ''),
           NULLIF(l.[parent_id], ''), NULLIF(l.[statut], ''), l.[extra],
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[code], '') IS NULL THEN 'INVALIDE'
                WHEN l.[Occ] > 1 THEN 'DOUBLON' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[code], '') IS NULL
                     THEN N'Ni nom ni code : rien pour identifier cette catégorie.'
                WHEN l.[Occ] > 1
                     THEN N'Cet identifiant apparaît plusieurs fois dans la même extraction.'
                ELSE NULL END
      FROM Lu l;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'DOUBLON' THEN 1 ELSE 0 END)  AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.CategorieSuiviImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0799ChargerDepartementsImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50378, 'Aucune compagnie : impossible de déposer les départements.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.DepartementImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[externe_id], '') ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Elements)
               WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                     [code] NVARCHAR(100) '$.code', [nom] NVARCHAR(300) '$.nom',
                     [parent_id] NVARCHAR(100) '$.parent_id', [statut] NVARCHAR(40) '$.statut',
                     [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j
    )
    INSERT INTO staging.DepartementImport
        ([ImportFileId], [RunId], [CompanyGUID], [Rang], [ExterneId], [Code], [Nom],
         [ParentExterneId], [StatutSource], [Extra], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[code], ''), NULLIF(l.[nom], ''),
           NULLIF(l.[parent_id], ''), NULLIF(l.[statut], ''), l.[extra],
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[code], '') IS NULL THEN 'INVALIDE'
                WHEN l.[Occ] > 1 THEN 'DOUBLON' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[code], '') IS NULL
                     THEN N'Ni nom ni code : rien pour identifier ce département.'
                WHEN l.[Occ] > 1
                     THEN N'Cet identifiant apparaît plusieurs fois dans la même extraction.'
                ELSE NULL END
      FROM Lu l;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'DOUBLON' THEN 1 ELSE 0 END)  AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.DepartementImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0800ChargerEmplacementsImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50379, 'Aucune compagnie : impossible de déposer les emplacements.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.EmplacementImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[externe_id], '') ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Elements)
               WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                     [code] NVARCHAR(100) '$.code', [nom] NVARCHAR(300) '$.nom',
                     [parent_id] NVARCHAR(100) '$.parent_id',
                     [adresse] NVARCHAR(400) '$.adresse', [ville] NVARCHAR(150) '$.ville',
                     [province] NVARCHAR(100) '$.province', [code_postal] NVARCHAR(30) '$.code_postal',
                     [pays] NVARCHAR(100) '$.pays', [statut] NVARCHAR(40) '$.statut',
                     [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j
    )
    INSERT INTO staging.EmplacementImport
        ([ImportFileId], [RunId], [CompanyGUID], [Rang], [ExterneId], [Code], [Nom],
         [ParentExterneId], [Adresse], [Ville], [Province], [CodePostal], [Pays],
         [StatutSource], [Extra], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[code], ''), NULLIF(l.[nom], ''),
           NULLIF(l.[parent_id], ''), NULLIF(l.[adresse], ''), NULLIF(l.[ville], ''),
           NULLIF(l.[province], ''), NULLIF(l.[code_postal], ''), NULLIF(l.[pays], ''),
           NULLIF(l.[statut], ''), l.[extra],
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[code], '') IS NULL THEN 'INVALIDE'
                WHEN l.[Occ] > 1 THEN 'DOUBLON' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[code], '') IS NULL
                     THEN N'Ni nom ni code : rien pour identifier cet emplacement.'
                WHEN l.[Occ] > 1
                     THEN N'Cet identifiant apparaît plusieurs fois dans la même extraction.'
                ELSE NULL END
      FROM Lu l;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'DOUBLON' THEN 1 ELSE 0 END)  AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.EmplacementImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0801ChargerJournauxImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50380, 'Aucune compagnie : impossible de déposer les journaux.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.JournalImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[externe_id], '') ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Elements)
               WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                     [symbole] NVARCHAR(40) '$.symbole', [nom] NVARCHAR(300) '$.nom',
                     [description] NVARCHAR(500) '$.description', [type] NVARCHAR(60) '$.type',
                     [devise] VARCHAR(10) '$.devise', [statut] NVARCHAR(40) '$.statut',
                     [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j
    )
    INSERT INTO staging.JournalImport
        ([ImportFileId], [RunId], [CompanyGUID], [Rang], [ExterneId], [Symbole], [Nom],
         [Description], [TypeSource], [Devise], [StatutSource], [Extra], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[symbole], ''), NULLIF(l.[nom], ''),
           NULLIF(l.[description], ''), NULLIF(l.[type], ''), NULLIF(l.[devise], ''),
           NULLIF(l.[statut], ''), l.[extra],
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[symbole], '') IS NULL THEN 'INVALIDE'
                WHEN l.[Occ] > 1 THEN 'DOUBLON' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[symbole], '') IS NULL
                     THEN N'Ni nom ni symbole : rien pour identifier ce journal.'
                WHEN l.[Occ] > 1
                     THEN N'Cet identifiant apparaît plusieurs fois dans la même extraction.'
                ELSE NULL END
      FROM Lu l;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'DOUBLON' THEN 1 ELSE 0 END)  AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.JournalImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0802ChargerComptesBancairesImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50381, 'Aucune compagnie : impossible de déposer les comptes bancaires.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.CompteBancaireImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[externe_id], '') ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Elements)
               WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                     [nom] NVARCHAR(300) '$.nom', [numero] NVARCHAR(60) '$.numero',
                     [institution] NVARCHAR(200) '$.institution', [type] NVARCHAR(60) '$.type',
                     [devise] VARCHAR(10) '$.devise',
                     [solde] NVARCHAR(40) '$.solde', [solde_dispo] NVARCHAR(40) '$.solde_dispo',
                     [date_solde] NVARCHAR(40) '$.date_solde',
                     [compte_gl_id] NVARCHAR(100) '$.compte_gl_id',
                     [compte_gl_nom] NVARCHAR(300) '$.compte_gl_nom',
                     [statut] NVARCHAR(40) '$.statut',
                     [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j
    )
    INSERT INTO staging.CompteBancaireImport
        ([ImportFileId], [RunId], [CompanyGUID], [Rang], [ExterneId], [Nom], [NumeroMasque],
         [InstitutionNom], [TypeCompte], [Devise], [Solde], [SoldeDisponible], [DateSolde],
         [CompteGLExterneId], [CompteGLNom], [StatutSource], [Extra], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[nom], ''),
           -- 🔒 Le masquage se fait ICI, avant l'écriture : le numéro complet
           --    ne se trouve à aucun moment dans la table.
           CASE WHEN LEN(ISNULL(l.[numero], '')) > 4
                THEN N'••••' + RIGHT(l.[numero], 4)
                ELSE NULLIF(l.[numero], '') END,
           NULLIF(l.[institution], ''), NULLIF(l.[type], ''), NULLIF(l.[devise], ''),
           TRY_CONVERT(DECIMAL(18,2), l.[solde]),
           TRY_CONVERT(DECIMAL(18,2), l.[solde_dispo]),
           TRY_CONVERT(DATE, l.[date_solde]),
           NULLIF(l.[compte_gl_id], ''), NULLIF(l.[compte_gl_nom], ''),
           NULLIF(l.[statut], ''), l.[extra],
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[numero], '') IS NULL THEN 'INVALIDE'
                WHEN l.[Occ] > 1 THEN 'DOUBLON' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[numero], '') IS NULL
                     THEN N'Ni nom ni numéro : rien pour identifier ce compte.'
                WHEN l.[Occ] > 1
                     THEN N'Cet identifiant apparaît plusieurs fois dans la même extraction.'
                ELSE NULL END
      FROM Lu l;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'DOUBLON' THEN 1 ELSE 0 END)  AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.CompteBancaireImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0803GetListesImport
--
--    Six tables, un seul écran. L'union se fait ici plutôt que dans le code :
--    l'écran demande « montre-moi les listes », pas « fais six requêtes ».
--    Les colonnes propres à une liste passent par [Detail1] et [Detail2], que
--    l'écran nomme selon le genre — c'est le seul compromis, et il ne coûte
--    rien aux tables elles-mêmes.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0803GetListesImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Genre       VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Tout AS (
        SELECT 'ModePaiement' AS [Genre], [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], NULL AS [ParentExterneId],
               [TypeSource], NULL AS [Devise], NULL AS [NumeroMasque],
               CAST(NULL AS DECIMAL(18,2)) AS [Solde],
               NULL AS [Detail1], NULL AS [Detail2],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.ModePaiementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'CategorieSuivi', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId],
               NULL, NULL, NULL, NULL, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.CategorieSuiviImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Departement', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId],
               NULL, NULL, NULL, NULL, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.DepartementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Emplacement', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId],
               NULL, NULL, NULL, NULL,
               [Adresse], [Ville],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.EmplacementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Journal', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Symbole], [Nom], NULL,
               [TypeSource], [Devise], NULL, NULL,
               [Description], NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.JournalImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'CompteBancaire', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], NULL, [Nom], NULL,
               [TypeCompte], [Devise], [NumeroMasque], [Solde],
               [InstitutionNom], [CompteGLNom],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.CompteBancaireImport WHERE [CompanyGUID] = @CompanyGUID
    )
    SELECT [Genre], COUNT(*) AS [Nb],
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END) AS [NbSoucis],
           MAX([Created]) AS [Dernier]
      FROM Tout
     GROUP BY [Genre]
     ORDER BY [Genre];

    ;WITH Tout AS (
        SELECT 'ModePaiement' AS [Genre], [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], NULL AS [ParentExterneId],
               [TypeSource], NULL AS [Devise], NULL AS [NumeroMasque],
               CAST(NULL AS DECIMAL(18,2)) AS [Solde],
               NULL AS [Detail1], NULL AS [Detail2],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.ModePaiementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'CategorieSuivi', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId],
               NULL, NULL, NULL, NULL, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.CategorieSuiviImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Departement', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId],
               NULL, NULL, NULL, NULL, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.DepartementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Emplacement', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId],
               NULL, NULL, NULL, NULL,
               [Adresse], [Ville],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.EmplacementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Journal', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Symbole], [Nom], NULL,
               [TypeSource], [Devise], NULL, NULL,
               [Description], NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.JournalImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'CompteBancaire', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], NULL, [Nom], NULL,
               [TypeCompte], [Devise], [NumeroMasque], [Solde],
               [InstitutionNom], [CompteGLNom],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.CompteBancaireImport WHERE [CompanyGUID] = @CompanyGUID
    )
    SELECT * FROM Tout
     WHERE (@Genre IS NULL OR @Genre = '' OR [Genre] = @Genre)
     ORDER BY [Genre],
              CASE WHEN [Statut] <> 'NOUVEAU' THEN 0 ELSE 1 END,
              [Rang], [Nom];
END
GO

-- -----------------------------------------------------------------------------
-- 5) Le registre et le vidage suivent
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0787GetImportsCompagnie]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 100
           f.[Id], f.[TypeImport], f.[OriginalName], f.[FileExtension], f.[FileSize],
           f.[UploadDate], f.[Status], f.[ProcessedRows], f.[ModelUsed],
           l.[Id]            AS [LotId],
           l.[SystemeSource],
           l.[NbLignesLues], l.[NbLignesRetenues], l.[NbAnomalies],
           (SELECT COUNT(*) FROM staging.PartyImport pi WHERE pi.[ImportFileId] = f.[Id])      AS [NbTiers],
           (SELECT COUNT(*) FROM staging.ProductImport pr WHERE pr.[ImportFileId] = f.[Id])    AS [NbProduits],
           (SELECT COUNT(*) FROM staging.ImportPlanComptable pc WHERE pc.[LotId] = l.[Id])     AS [NbComptes],
           (SELECT COUNT(*) FROM staging.DocumentImport di WHERE di.[ImportFileId] = f.[Id])   AS [NbDocuments],
           (SELECT COUNT(*) FROM staging.SocieteImport si WHERE si.[ImportFileId] = f.[Id])    AS [NbChampsSociete],
           (SELECT COUNT(*) FROM staging.TaxeImport ti WHERE ti.[ImportFileId] = f.[Id])       AS [NbTaux],
           ((SELECT COUNT(*) FROM staging.ModePaiementImport x WHERE x.[ImportFileId] = f.[Id])
          + (SELECT COUNT(*) FROM staging.CategorieSuiviImport x WHERE x.[ImportFileId] = f.[Id])
          + (SELECT COUNT(*) FROM staging.DepartementImport x WHERE x.[ImportFileId] = f.[Id])
          + (SELECT COUNT(*) FROM staging.EmplacementImport x WHERE x.[ImportFileId] = f.[Id])
          + (SELECT COUNT(*) FROM staging.JournalImport x WHERE x.[ImportFileId] = f.[Id])
          + (SELECT COUNT(*) FROM staging.CompteBancaireImport x WHERE x.[ImportFileId] = f.[Id])) AS [NbReferences]
      FROM staging.ImportFiles f
      LEFT JOIN staging.ImportLot l ON l.[ImportFileId] = f.[Id]
     WHERE f.[CompanyGUID] = @CompanyGUID
     ORDER BY f.[UploadDate] DESC;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0790ViderStaging]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50370, 'Aucune compagnie : refus de vider la préparation.', 1;

    DECLARE @Compte TABLE ([Ordre] INT, [Table] VARCHAR(60), [Lignes] INT);

    BEGIN TRANSACTION;

    DELETE cc FROM staging.CorrespondanceCompte cc WHERE cc.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (1, 'CorrespondanceCompte', @@ROWCOUNT);

    DELETE pc FROM staging.ImportPlanComptable pc WHERE pc.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (2, 'ImportPlanComptable', @@ROWCOUNT);

    DELETE l FROM staging.ImportLot l WHERE l.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (3, 'ImportLot', @@ROWCOUNT);

    DELETE dl
      FROM staging.DocumentImportLigne dl
      JOIN staging.DocumentImport di ON di.[Id] = dl.[EnteteId]
     WHERE di.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (4, 'DocumentImportLigne', @@ROWCOUNT);

    DELETE di FROM staging.DocumentImport di WHERE di.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (5, 'DocumentImport', @@ROWCOUNT);

    DELETE si FROM staging.SocieteImport si WHERE si.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (6, 'SocieteImport', @@ROWCOUNT);

    DELETE ti FROM staging.TaxeImport ti WHERE ti.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (7, 'TaxeImport', @@ROWCOUNT);

    DELETE x FROM staging.ModePaiementImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (8, 'ModePaiementImport', @@ROWCOUNT);

    DELETE x FROM staging.CategorieSuiviImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (9, 'CategorieSuiviImport', @@ROWCOUNT);

    DELETE x FROM staging.DepartementImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (10, 'DepartementImport', @@ROWCOUNT);

    DELETE x FROM staging.EmplacementImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (11, 'EmplacementImport', @@ROWCOUNT);

    DELETE x FROM staging.JournalImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (12, 'JournalImport', @@ROWCOUNT);

    DELETE x FROM staging.CompteBancaireImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (13, 'CompteBancaireImport', @@ROWCOUNT);

    DELETE pi
      FROM staging.PartyImport pi
      JOIN staging.ImportFiles f ON f.[Id] = pi.[ImportFileId]
     WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (14, 'PartyImport', @@ROWCOUNT);

    DELETE pr
      FROM staging.ProductImport pr
      JOIN staging.ImportFiles f ON f.[Id] = pr.[ImportFileId]
     WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (15, 'ProductImport', @@ROWCOUNT);

    DELETE cd FROM staging.ConnecteurDonnee cd WHERE cd.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (16, 'ConnecteurDonnee', @@ROWCOUNT);

    DELETE cr FROM staging.ConnecteurRun cr WHERE cr.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (17, 'ConnecteurRun', @@ROWCOUNT);

    DELETE bv FROM staging.BalanceVerification bv WHERE bv.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (18, 'BalanceVerification', @@ROWCOUNT);

    DELETE f FROM staging.ImportFiles f WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (19, 'ImportFiles', @@ROWCOUNT);

    COMMIT TRANSACTION;

    SELECT [Table], [Lignes] FROM @Compte WHERE [Lignes] > 0 ORDER BY [Ordre];
    SELECT SUM([Lignes]) AS [Total] FROM @Compte;
END
GO
