-- =============================================================================
-- T260 — Huit entités que seule la passerelle rend : employés, classes,
--        agences de taxes, devises et taux de change, dépôts et virements
--        bancaires, transactions récurrentes, budgets, feuilles de temps
--
-- L'API unifiée d'Apideck s'arrête aux vingt-huit ressources du catalogue.
-- QuickBooks en tient d'autres, lisibles par son API native — celle que la
-- passerelle transmet. Ce script prépare l'atterrissage de chacune :
--
--   1) Employés            → staging.PaieEmployeImport (la table de la paie,
--                            qui attendait un fichier : on la remplit par la
--                            source) — s0842 ne touche que les employés.
--   2) Classes, agences de taxes, devises, taux de change → quatre listes de
--                            structure, sur le modèle des départements, et
--                            s0803 les réunit à l'écran des listes.
--   3) Dépôts et virements → staging.MouvementBancaireImport (+ lignes).
--   4) Transactions récurrentes → staging.TransactionRecurrenteImport.
--   5) Budgets             → staging.BudgetImport (+ lignes).
--   6) Feuilles de temps   → staging.FeuilleTempsImport.
--   7) Le registre (staging.ImportFiles) accepte les neuf types nouveaux.
--
-- Ce qui n'y est pas : les UTILISATEURS. L'API v3 de QuickBooks n'expose pas
-- la liste des utilisateurs d'une société — seul l'utilisateur connecté, par
-- OpenID. Il n'y a rien à lire, donc rien à préparer.
--
-- Tout est contrôle et préparation : rien ne s'applique à la comptabilité.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 0) Le registre : neuf types de plus. Liste fermée, à dessein.
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_staging_ImportFiles_TypeImport')
    ALTER TABLE staging.ImportFiles DROP CONSTRAINT CK_staging_ImportFiles_TypeImport;
GO
ALTER TABLE staging.ImportFiles WITH CHECK
    ADD CONSTRAINT CK_staging_ImportFiles_TypeImport CHECK ([TypeImport] IN (
        'PlanComptable', 'Societe', 'Taxe', 'ModePaiement', 'ConditionPaiement', 'CategorieSuivi',
        'Departement', 'Emplacement', 'CompteBancaire', 'Client', 'Fournisseur', 'Produit',
        'Inventaire', 'FactureClient', 'FactureFournisseur', 'AvoirClient', 'AvoirFournisseur',
        'Depense', 'RecuVente', 'Soumission', 'BonCommande', 'Encaissement', 'Decaissement',
        'Remboursement', 'Paie', 'RemiseDas', 'EcritureJournal', 'PieceJointe', 'GrandLivre',
        'Rapprochement', 'BalanceVerification', 'BalanceAgeeClient', 'BalanceAgeeFournisseur',
        'RapportBilan', 'RapportResultats', 'RapportTaxes', 'BalanceAgee', 'Rapport',
        'Employe', 'Classe', 'AgenceTaxe', 'Devise', 'TauxChange', 'MouvementBancaire',
        'TransactionRecurrente', 'Budget', 'FeuilleTemps'));
GO

-- -----------------------------------------------------------------------------
-- 1) Employés → staging.PaieEmployeImport
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0842ChargerEmployesImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50396, 'Aucune compagnie : impossible de déposer les employés.', 1;

    BEGIN TRANSACTION;

    -- Seuls les employés : les lots et les paies déposés par fichier restent.
    DELETE FROM staging.PaieEmployeImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[externe_id], '') ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Elements)
               WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                     [code] NVARCHAR(50) '$.code', [prenom] NVARCHAR(200) '$.prenom',
                     [nom] NVARCHAR(200) '$.nom', [courriel] NVARCHAR(320) '$.courriel',
                     [telephone] NVARCHAR(50) '$.telephone', [adresse1] NVARCHAR(300) '$.adresse1',
                     [ville] NVARCHAR(200) '$.ville', [province] NVARCHAR(10) '$.province',
                     [code_postal] NVARCHAR(20) '$.code_postal',
                     [date_naissance] NVARCHAR(40) '$.date_naissance', [nas_fourni] NVARCHAR(10) '$.nas_fourni',
                     [poste] NVARCHAR(200) '$.poste', [date_embauche] NVARCHAR(40) '$.date_embauche',
                     [date_fin] NVARCHAR(40) '$.date_fin', [actif] NVARCHAR(10) '$.actif',
                     [taux_horaire] NVARCHAR(40) '$.taux_horaire') AS j
    )
    INSERT INTO staging.PaieEmployeImport
        ([RunId], [ImportFileId], [CompanyGUID], [Rang], [ExterneId], [Code],
         [Prenom], [Nom], [Courriel], [Telephone], [Adresse1], [Ville], [Province], [CodePostal],
         [DateNaissance], [NASFourni], [Poste], [DateEmbauche], [DateFinEmploi], [Actif],
         [TauxHoraire], [Statut], [Anomalie])
    SELECT @RunId, @ImportFileId, @CompanyGUID, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[code], ''),
           NULLIF(l.[prenom], ''), NULLIF(l.[nom], ''), NULLIF(l.[courriel], ''), NULLIF(l.[telephone], ''),
           NULLIF(l.[adresse1], ''), NULLIF(l.[ville], ''), NULLIF(l.[province], ''), NULLIF(l.[code_postal], ''),
           TRY_CONVERT(DATE, NULLIF(l.[date_naissance], '')),
           CASE WHEN LOWER(l.[nas_fourni]) = 'true' THEN 1 ELSE 0 END,
           NULLIF(l.[poste], ''),
           TRY_CONVERT(DATE, NULLIF(l.[date_embauche], '')),
           TRY_CONVERT(DATE, NULLIF(l.[date_fin], '')),
           CASE WHEN LOWER(l.[actif]) = 'false' THEN 0 ELSE 1 END,
           TRY_CONVERT(DECIMAL(18,4), NULLIF(REPLACE(l.[taux_horaire], ',', '.'), '')),
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[code], '') IS NULL THEN 'ANOMALIE'
                WHEN l.[Occ] > 1 THEN 'ANOMALIE' ELSE 'OK' END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[code], '') IS NULL
                     THEN N'Ni nom ni code : impossible de reconnaître cet employé.'
                WHEN l.[Occ] > 1 THEN N'Cet identifiant apparaît plusieurs fois dans la même extraction.'
                ELSE NULL END
      FROM Lu l;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'OK' THEN 1 ELSE 0 END) AS [NbNouveaux],
           0 AS [NbDoublons],
           SUM(CASE WHEN [Statut] <> 'OK' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.PaieEmployeImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 2) Quatre listes de structure
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.ClasseImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.ClasseImport
    (
        [Id]               INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]     INT               NULL,
        [RunId]            INT               NULL,
        [CompanyGUID]      UNIQUEIDENTIFIER  NOT NULL,
        [Rang]             INT               NOT NULL CONSTRAINT DF_ClasseImport_Rang DEFAULT (0),
        [ExterneId]        NVARCHAR(100)     NULL,
        [Code]             NVARCHAR(100)     NULL,
        [Nom]              NVARCHAR(300)     NULL,
        [NomComplet]       NVARCHAR(400)     NULL,   -- « Parent:Enfant », tel que QuickBooks l'écrit
        [ParentExterneId]  NVARCHAR(100)     NULL,
        [StatutSource]     NVARCHAR(40)      NULL,
        [Extra]            NVARCHAR(MAX)     NULL,
        [Statut]           VARCHAR(20)       NOT NULL CONSTRAINT DF_ClasseImport_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]         NVARCHAR(400)     NULL,
        [Created]          DATETIME          NOT NULL CONSTRAINT DF_ClasseImport_Created DEFAULT (GETDATE()),
        CONSTRAINT PK_ClasseImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_ClasseImport_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_ClasseImport_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_ClasseImport_Company ON staging.ClasseImport ([CompanyGUID]);
END
GO

IF OBJECT_ID('staging.AgenceTaxeImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.AgenceTaxeImport
    (
        [Id]                  INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]        INT               NULL,
        [RunId]               INT               NULL,
        [CompanyGUID]         UNIQUEIDENTIFIER  NOT NULL,
        [Rang]                INT               NOT NULL CONSTRAINT DF_AgenceTaxeImport_Rang DEFAULT (0),
        [ExterneId]           NVARCHAR(100)     NULL,
        [Nom]                 NVARCHAR(300)     NULL,
        [NumeroInscription]   NVARCHAR(50)      NULL,   -- le numéro de TPS/TVQ de la compagnie auprès d'elle
        [SuiviVentes]         BIT               NULL,
        [SuiviAchats]         BIT               NULL,
        [DerniereDeclaration] DATE              NULL,
        [StatutSource]        NVARCHAR(40)      NULL,
        [Extra]               NVARCHAR(MAX)     NULL,
        [Statut]              VARCHAR(20)       NOT NULL CONSTRAINT DF_AgenceTaxeImport_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]            NVARCHAR(400)     NULL,
        [Created]             DATETIME          NOT NULL CONSTRAINT DF_AgenceTaxeImport_Created DEFAULT (GETDATE()),
        CONSTRAINT PK_AgenceTaxeImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_AgenceTaxeImport_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_AgenceTaxeImport_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_AgenceTaxeImport_Company ON staging.AgenceTaxeImport ([CompanyGUID]);
END
GO

IF OBJECT_ID('staging.DeviseImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.DeviseImport
    (
        [Id]           INT IDENTITY(1,1) NOT NULL,
        [ImportFileId] INT               NULL,
        [RunId]        INT               NULL,
        [CompanyGUID]  UNIQUEIDENTIFIER  NOT NULL,
        [Rang]         INT               NOT NULL CONSTRAINT DF_DeviseImport_Rang DEFAULT (0),
        [ExterneId]    NVARCHAR(100)     NULL,
        [Code]         NVARCHAR(10)      NULL,   -- ISO 4217
        [Nom]          NVARCHAR(300)     NULL,
        [Actif]        BIT               NULL,
        [StatutSource] NVARCHAR(40)      NULL,
        [Extra]        NVARCHAR(MAX)     NULL,
        [Statut]       VARCHAR(20)       NOT NULL CONSTRAINT DF_DeviseImport_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]     NVARCHAR(400)     NULL,
        [Created]      DATETIME          NOT NULL CONSTRAINT DF_DeviseImport_Created DEFAULT (GETDATE()),
        CONSTRAINT PK_DeviseImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_DeviseImport_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_DeviseImport_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_DeviseImport_Company ON staging.DeviseImport ([CompanyGUID]);
END
GO

IF OBJECT_ID('staging.TauxChangeImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.TauxChangeImport
    (
        [Id]           INT IDENTITY(1,1) NOT NULL,
        [ImportFileId] INT               NULL,
        [RunId]        INT               NULL,
        [CompanyGUID]  UNIQUEIDENTIFIER  NOT NULL,
        [Rang]         INT               NOT NULL CONSTRAINT DF_TauxChangeImport_Rang DEFAULT (0),
        [DeviseSource] NVARCHAR(10)      NULL,
        [DeviseCible]  NVARCHAR(10)      NULL,   -- la devise de la compagnie
        [Taux]         DECIMAL(18,8)     NULL,
        [DateTaux]     DATE              NULL,
        [Extra]        NVARCHAR(MAX)     NULL,
        [Statut]       VARCHAR(20)       NOT NULL CONSTRAINT DF_TauxChangeImport_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]     NVARCHAR(400)     NULL,
        [Created]      DATETIME          NOT NULL CONSTRAINT DF_TauxChangeImport_Created DEFAULT (GETDATE()),
        CONSTRAINT PK_TauxChangeImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_TauxChangeImport_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_TauxChangeImport_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_TauxChangeImport_Company ON staging.TauxChangeImport ([CompanyGUID]);
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0843ChargerClassesImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50397, 'Aucune compagnie : impossible de déposer les classes.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.ClasseImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[externe_id], '') ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Elements)
               WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                     [code] NVARCHAR(100) '$.code', [nom] NVARCHAR(300) '$.nom',
                     [nom_complet] NVARCHAR(400) '$.nom_complet',
                     [parent_id] NVARCHAR(100) '$.parent_id', [statut] NVARCHAR(40) '$.statut',
                     [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j
    )
    INSERT INTO staging.ClasseImport
        ([ImportFileId], [RunId], [CompanyGUID], [Rang], [ExterneId], [Code], [Nom], [NomComplet],
         [ParentExterneId], [StatutSource], [Extra], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[code], ''), NULLIF(l.[nom], ''), NULLIF(l.[nom_complet], ''),
           NULLIF(l.[parent_id], ''), NULLIF(l.[statut], ''), l.[extra],
           CASE WHEN NULLIF(l.[nom], '') IS NULL THEN 'INVALIDE' WHEN l.[Occ] > 1 THEN 'DOUBLON' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL THEN N'Pas de nom : rien pour identifier cette classe.'
                WHEN l.[Occ] > 1 THEN N'Cet identifiant apparaît plusieurs fois dans la même extraction.' END
      FROM Lu l;
    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'DOUBLON' THEN 1 ELSE 0 END)  AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.ClasseImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0844ChargerAgencesTaxeImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50398, 'Aucune compagnie : impossible de déposer les agences de taxes.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.AgenceTaxeImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[externe_id], '') ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Elements)
               WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                     [nom] NVARCHAR(300) '$.nom', [numero] NVARCHAR(50) '$.numero',
                     [suivi_ventes] NVARCHAR(10) '$.suivi_ventes', [suivi_achats] NVARCHAR(10) '$.suivi_achats',
                     [derniere_declaration] NVARCHAR(40) '$.derniere_declaration',
                     [statut] NVARCHAR(40) '$.statut', [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j
    )
    INSERT INTO staging.AgenceTaxeImport
        ([ImportFileId], [RunId], [CompanyGUID], [Rang], [ExterneId], [Nom], [NumeroInscription],
         [SuiviVentes], [SuiviAchats], [DerniereDeclaration], [StatutSource], [Extra], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[nom], ''), NULLIF(l.[numero], ''),
           dbo.fImportBit(l.[suivi_ventes]), dbo.fImportBit(l.[suivi_achats]),
           TRY_CONVERT(DATE, NULLIF(l.[derniere_declaration], '')),
           NULLIF(l.[statut], ''), l.[extra],
           CASE WHEN NULLIF(l.[nom], '') IS NULL THEN 'INVALIDE' WHEN l.[Occ] > 1 THEN 'DOUBLON' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL THEN N'Pas de nom : rien pour identifier cette agence.'
                WHEN l.[Occ] > 1 THEN N'Cet identifiant apparaît plusieurs fois dans la même extraction.' END
      FROM Lu l;
    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'DOUBLON' THEN 1 ELSE 0 END)  AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.AgenceTaxeImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0845ChargerDevisesImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50399, 'Aucune compagnie : impossible de déposer les devises.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.DeviseImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[code], '') ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Elements)
               WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                     [code] NVARCHAR(10) '$.code', [nom] NVARCHAR(300) '$.nom',
                     [actif] NVARCHAR(10) '$.actif', [statut] NVARCHAR(40) '$.statut',
                     [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j
    )
    INSERT INTO staging.DeviseImport
        ([ImportFileId], [RunId], [CompanyGUID], [Rang], [ExterneId], [Code], [Nom], [Actif],
         [StatutSource], [Extra], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[code], ''), NULLIF(l.[nom], ''), dbo.fImportBit(l.[actif]),
           NULLIF(l.[statut], ''), l.[extra],
           CASE WHEN NULLIF(l.[code], '') IS NULL THEN 'INVALIDE' WHEN l.[Occ] > 1 THEN 'DOUBLON' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(l.[code], '') IS NULL THEN N'Pas de code ISO : rien pour identifier cette devise.'
                WHEN l.[Occ] > 1 THEN N'Ce code apparaît plusieurs fois dans la même extraction.' END
      FROM Lu l;
    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'DOUBLON' THEN 1 ELSE 0 END)  AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.DeviseImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0846ChargerTauxChangeImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50400, 'Aucune compagnie : impossible de déposer les taux de change.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.TauxChangeImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY j.[source], j.[cible], j.[date] ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Elements)
               WITH ([rang] INT '$.rang', [source] NVARCHAR(10) '$.source', [cible] NVARCHAR(10) '$.cible',
                     [taux] NVARCHAR(40) '$.taux', [date] NVARCHAR(40) '$.date',
                     [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j
    )
    INSERT INTO staging.TauxChangeImport
        ([ImportFileId], [RunId], [CompanyGUID], [Rang], [DeviseSource], [DeviseCible], [Taux], [DateTaux],
         [Extra], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, l.[rang],
           NULLIF(l.[source], ''), NULLIF(l.[cible], ''),
           TRY_CONVERT(DECIMAL(18,8), NULLIF(REPLACE(l.[taux], ',', '.'), '')),
           TRY_CONVERT(DATE, NULLIF(l.[date], '')),
           l.[extra],
           CASE WHEN NULLIF(l.[source], '') IS NULL OR TRY_CONVERT(DECIMAL(18,8), NULLIF(REPLACE(l.[taux], ',', '.'), '')) IS NULL THEN 'INVALIDE'
                WHEN l.[Occ] > 1 THEN 'DOUBLON' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(l.[source], '') IS NULL OR TRY_CONVERT(DECIMAL(18,8), NULLIF(REPLACE(l.[taux], ',', '.'), '')) IS NULL
                     THEN N'Devise ou taux illisible.'
                WHEN l.[Occ] > 1 THEN N'Le même couple de devises à la même date apparaît plusieurs fois.' END
      FROM Lu l;
    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'DOUBLON' THEN 1 ELSE 0 END)  AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.TauxChangeImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

-- s0803 réunit désormais huit listes. Même forme qu'en T235, quatre unions de plus.
CREATE OR ALTER PROCEDURE [dbo].[s0803GetListesImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Genre       VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Tout AS (
        SELECT 'ModePaiement' AS [Genre], [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], NULL AS [ParentExterneId],
               [TypeSource], NULL AS [Detail1], NULL AS [Detail2],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.ModePaiementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'CategorieSuivi', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId], NULL, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.CategorieSuiviImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Departement', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId], NULL, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.DepartementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Emplacement', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId], NULL, [Adresse], [Ville],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.EmplacementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Classe', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId], NULL, [NomComplet], NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.ClasseImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'AgenceTaxe', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [NumeroInscription], [Nom], NULL,
               CASE WHEN [SuiviVentes] = 1 AND [SuiviAchats] = 1 THEN N'ventes et achats'
                    WHEN [SuiviVentes] = 1 THEN N'ventes' WHEN [SuiviAchats] = 1 THEN N'achats' END,
               CASE WHEN [DerniereDeclaration] IS NULL THEN NULL
                    ELSE N'dernière déclaration ' + CONVERT(NVARCHAR(10), [DerniereDeclaration], 120) END,
               NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.AgenceTaxeImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Devise', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], NULL,
               CASE WHEN [Actif] = 0 THEN N'inactive' END, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.DeviseImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'TauxChange', [Id], [ImportFileId], [RunId], [Rang],
               NULL, [DeviseSource] + N' → ' + ISNULL([DeviseCible], ''), CONVERT(NVARCHAR(30), [Taux]), NULL,
               NULL, CASE WHEN [DateTaux] IS NULL THEN NULL ELSE N'au ' + CONVERT(NVARCHAR(10), [DateTaux], 120) END, NULL,
               NULL, [Statut], [Anomalie], [Created]
          FROM staging.TauxChangeImport WHERE [CompanyGUID] = @CompanyGUID
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
               [TypeSource], NULL AS [Detail1], NULL AS [Detail2],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.ModePaiementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'CategorieSuivi', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId], NULL, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.CategorieSuiviImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Departement', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId], NULL, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.DepartementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Emplacement', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId], NULL, [Adresse], [Ville],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.EmplacementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Classe', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId], NULL, [NomComplet], NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.ClasseImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'AgenceTaxe', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [NumeroInscription], [Nom], NULL,
               CASE WHEN [SuiviVentes] = 1 AND [SuiviAchats] = 1 THEN N'ventes et achats'
                    WHEN [SuiviVentes] = 1 THEN N'ventes' WHEN [SuiviAchats] = 1 THEN N'achats' END,
               CASE WHEN [DerniereDeclaration] IS NULL THEN NULL
                    ELSE N'dernière déclaration ' + CONVERT(NVARCHAR(10), [DerniereDeclaration], 120) END,
               NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.AgenceTaxeImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Devise', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], NULL,
               CASE WHEN [Actif] = 0 THEN N'inactive' END, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.DeviseImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'TauxChange', [Id], [ImportFileId], [RunId], [Rang],
               NULL, [DeviseSource] + N' → ' + ISNULL([DeviseCible], ''), CONVERT(NVARCHAR(30), [Taux]), NULL,
               NULL, CASE WHEN [DateTaux] IS NULL THEN NULL ELSE N'au ' + CONVERT(NVARCHAR(10), [DateTaux], 120) END, NULL,
               NULL, [Statut], [Anomalie], [Created]
          FROM staging.TauxChangeImport WHERE [CompanyGUID] = @CompanyGUID
    )
    SELECT * FROM Tout
     WHERE (@Genre IS NULL OR @Genre = '' OR [Genre] = @Genre)
     ORDER BY [Genre],
              CASE WHEN [Statut] <> 'NOUVEAU' THEN 0 ELSE 1 END,
              [Rang], [Id];
END
GO

-- -----------------------------------------------------------------------------
-- 3) Dépôts et virements bancaires
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.MouvementBancaireImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.MouvementBancaireImport
    (
        [Id]                    INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]          INT               NULL,
        [RunId]                 INT               NULL,
        [CompanyGUID]           UNIQUEIDENTIFIER  NOT NULL,
        [Rang]                  INT               NOT NULL CONSTRAINT DF_MouvBanc_Rang DEFAULT (0),
        [Genre]                 VARCHAR(20)       NOT NULL,   -- Depot | Virement
        [ExterneId]             NVARCHAR(100)     NULL,
        [DateMouvement]         DATE              NULL,
        [Montant]               DECIMAL(18,2)     NULL,
        [CompteVersNom]         NVARCHAR(300)     NULL,   -- où l'argent arrive
        [CompteVersExterneId]   NVARCHAR(100)     NULL,
        [CompteDepuisNom]       NVARCHAR(300)     NULL,   -- d'où il part (virement)
        [CompteDepuisExterneId] NVARCHAR(100)     NULL,
        [Devise]                NVARCHAR(10)      NULL,
        [Note]                  NVARCHAR(1000)    NULL,
        [NbLignes]              INT               NOT NULL CONSTRAINT DF_MouvBanc_NbLignes DEFAULT (0),
        [Extra]                 NVARCHAR(MAX)     NULL,
        [Statut]                VARCHAR(20)       NOT NULL CONSTRAINT DF_MouvBanc_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]              NVARCHAR(400)     NULL,
        [Created]               DATETIME          NOT NULL CONSTRAINT DF_MouvBanc_Created DEFAULT (GETDATE()),
        CONSTRAINT PK_MouvementBancaireImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_MouvBanc_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_MouvBanc_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_MouvBanc_Company ON staging.MouvementBancaireImport ([CompanyGUID], [Genre]);
END
GO

IF OBJECT_ID('staging.MouvementBancaireLigneImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.MouvementBancaireLigneImport
    (
        [Id]                  INT IDENTITY(1,1) NOT NULL,
        [EnteteId]            INT               NOT NULL,
        [CompanyGUID]         UNIQUEIDENTIFIER  NOT NULL,
        [Rang]                INT               NOT NULL CONSTRAINT DF_MouvBancL_Rang DEFAULT (0),
        [Montant]             DECIMAL(18,2)     NULL,
        [CompteNom]           NVARCHAR(300)     NULL,   -- la contrepartie
        [CompteExterneId]     NVARCHAR(100)     NULL,
        [TiersNom]            NVARCHAR(500)     NULL,
        [TiersExterneId]      NVARCHAR(100)     NULL,
        [ModePaiement]        NVARCHAR(100)     NULL,
        [NumeroCheque]        NVARCHAR(50)      NULL,
        [PaiementLieExterneId] NVARCHAR(100)    NULL,   -- l'encaissement déposé, quand c'en est un
        [Description]         NVARCHAR(1000)    NULL,
        CONSTRAINT PK_MouvementBancaireLigneImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_MouvBancL_Entete FOREIGN KEY ([EnteteId]) REFERENCES staging.MouvementBancaireImport ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_MouvBancL_Entete ON staging.MouvementBancaireLigneImport ([EnteteId]);
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0847ChargerMouvementsBancaires]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL,
    @Entetes NVARCHAR(MAX), @Lignes NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50401, 'Aucune compagnie : impossible de déposer les mouvements bancaires.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.MouvementBancaireImport WHERE [CompanyGUID] = @CompanyGUID;

    -- Les entêtes, en gardant le rang pour retrouver les lignes.
    DECLARE @map TABLE ([Rang] INT, [Id] INT);

    MERGE staging.MouvementBancaireImport AS cible
    USING (SELECT j.* FROM OPENJSON(@Entetes)
             WITH ([rang] INT '$.rang', [genre] VARCHAR(20) '$.genre', [externe_id] NVARCHAR(100) '$.externe_id',
                   [date] NVARCHAR(40) '$.date', [montant] NVARCHAR(40) '$.montant',
                   [compte_vers] NVARCHAR(300) '$.compte_vers', [compte_vers_id] NVARCHAR(100) '$.compte_vers_id',
                   [compte_depuis] NVARCHAR(300) '$.compte_depuis', [compte_depuis_id] NVARCHAR(100) '$.compte_depuis_id',
                   [devise] NVARCHAR(10) '$.devise', [note] NVARCHAR(1000) '$.note',
                   [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j) AS src
       ON 1 = 0
    WHEN NOT MATCHED THEN
        INSERT ([ImportFileId], [RunId], [CompanyGUID], [Rang], [Genre], [ExterneId], [DateMouvement], [Montant],
                [CompteVersNom], [CompteVersExterneId], [CompteDepuisNom], [CompteDepuisExterneId],
                [Devise], [Note], [Extra], [Statut], [Anomalie])
        VALUES (@ImportFileId, @RunId, @CompanyGUID, src.[rang], ISNULL(NULLIF(src.[genre], ''), 'Depot'),
                NULLIF(src.[externe_id], ''), TRY_CONVERT(DATE, NULLIF(src.[date], '')),
                TRY_CONVERT(DECIMAL(18,2), NULLIF(REPLACE(src.[montant], ',', '.'), '')),
                NULLIF(src.[compte_vers], ''), NULLIF(src.[compte_vers_id], ''),
                NULLIF(src.[compte_depuis], ''), NULLIF(src.[compte_depuis_id], ''),
                NULLIF(src.[devise], ''), NULLIF(src.[note], ''), src.[extra],
                CASE WHEN TRY_CONVERT(DECIMAL(18,2), NULLIF(REPLACE(src.[montant], ',', '.'), '')) IS NULL THEN 'INVALIDE' ELSE 'NOUVEAU' END,
                CASE WHEN TRY_CONVERT(DECIMAL(18,2), NULLIF(REPLACE(src.[montant], ',', '.'), '')) IS NULL THEN N'Montant illisible.' END)
    OUTPUT inserted.[Rang], inserted.[Id] INTO @map;

    INSERT INTO staging.MouvementBancaireLigneImport
        ([EnteteId], [CompanyGUID], [Rang], [Montant], [CompteNom], [CompteExterneId], [TiersNom], [TiersExterneId],
         [ModePaiement], [NumeroCheque], [PaiementLieExterneId], [Description])
    SELECT m.[Id], @CompanyGUID, j.[rang], TRY_CONVERT(DECIMAL(18,2), NULLIF(REPLACE(j.[montant], ',', '.'), '')),
           NULLIF(j.[compte], ''), NULLIF(j.[compte_id], ''), NULLIF(j.[tiers], ''), NULLIF(j.[tiers_id], ''),
           NULLIF(j.[mode], ''), NULLIF(j.[cheque], ''), NULLIF(j.[paiement_id], ''), NULLIF(j.[description], '')
      FROM OPENJSON(@Lignes)
           WITH ([entete_rang] INT '$.entete_rang', [rang] INT '$.rang', [montant] NVARCHAR(40) '$.montant',
                 [compte] NVARCHAR(300) '$.compte', [compte_id] NVARCHAR(100) '$.compte_id',
                 [tiers] NVARCHAR(500) '$.tiers', [tiers_id] NVARCHAR(100) '$.tiers_id',
                 [mode] NVARCHAR(100) '$.mode', [cheque] NVARCHAR(50) '$.cheque',
                 [paiement_id] NVARCHAR(100) '$.paiement_id', [description] NVARCHAR(1000) '$.description') AS j
      JOIN @map m ON m.[Rang] = j.[entete_rang];

    UPDATE e SET [NbLignes] = (SELECT COUNT(*) FROM staging.MouvementBancaireLigneImport l WHERE l.[EnteteId] = e.[Id])
      FROM staging.MouvementBancaireImport e WHERE e.[CompanyGUID] = @CompanyGUID;

    COMMIT TRANSACTION;

    SELECT SUM(CASE WHEN [Genre] = 'Depot' THEN 1 ELSE 0 END) AS [NbDepots],
           SUM(CASE WHEN [Genre] = 'Virement' THEN 1 ELSE 0 END) AS [NbVirements],
           SUM([NbLignes]) AS [NbLignes],
           SUM(ISNULL([Montant], 0)) AS [Total],
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.MouvementBancaireImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0848GetMouvementsBancaires]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Genre       VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Genre], COUNT(*) AS [Nb], SUM(ISNULL([Montant], 0)) AS [Total],
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END) AS [NbSoucis],
           MIN([DateMouvement]) AS [Du], MAX([DateMouvement]) AS [Au]
      FROM staging.MouvementBancaireImport
     WHERE [CompanyGUID] = @CompanyGUID
     GROUP BY [Genre] ORDER BY [Genre];

    SELECT [Id], [Rang], [Genre], [ExterneId], [DateMouvement], [Montant], [CompteVersNom], [CompteDepuisNom],
           [Devise], [Note], [NbLignes], [Statut], [Anomalie]
      FROM staging.MouvementBancaireImport
     WHERE [CompanyGUID] = @CompanyGUID AND (@Genre IS NULL OR @Genre = '' OR [Genre] = @Genre)
     ORDER BY [DateMouvement] DESC, [Rang];

    SELECT l.[EnteteId], l.[Rang], l.[Montant], l.[CompteNom], l.[TiersNom], l.[ModePaiement], l.[NumeroCheque],
           l.[PaiementLieExterneId], l.[Description]
      FROM staging.MouvementBancaireLigneImport l
      JOIN staging.MouvementBancaireImport e ON e.[Id] = l.[EnteteId]
     WHERE e.[CompanyGUID] = @CompanyGUID AND (@Genre IS NULL OR @Genre = '' OR e.[Genre] = @Genre)
     ORDER BY l.[EnteteId], l.[Rang];
END
GO

-- -----------------------------------------------------------------------------
-- 4) Transactions récurrentes
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.TransactionRecurrenteImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.TransactionRecurrenteImport
    (
        [Id]             INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]   INT               NULL,
        [RunId]          INT               NULL,
        [CompanyGUID]    UNIQUEIDENTIFIER  NOT NULL,
        [Rang]           INT               NOT NULL CONSTRAINT DF_TxnRec_Rang DEFAULT (0),
        [ExterneId]      NVARCHAR(100)     NULL,
        [Nom]            NVARCHAR(300)     NULL,
        [TypeTxn]        NVARCHAR(40)      NULL,   -- Invoice, Bill, JournalEntry…
        [TypeRecurrence] NVARCHAR(40)      NULL,   -- Automated, Reminded, Unscheduled
        [Actif]          BIT               NULL,
        [IntervalleType] NVARCHAR(30)      NULL,   -- Daily, Weekly, Monthly, Yearly
        [NumIntervalle]  INT               NULL,
        [JourDuMois]     INT               NULL,
        [JourSemaine]    NVARCHAR(20)      NULL,
        [DateDebut]      DATE              NULL,
        [DateProchaine]  DATE              NULL,
        [DateFin]        DATE              NULL,
        [TiersNom]       NVARCHAR(500)     NULL,
        [Montant]        DECIMAL(18,2)     NULL,
        [Devise]         NVARCHAR(10)      NULL,
        [Extra]          NVARCHAR(MAX)     NULL,   -- le modèle de transaction, tel quel
        [Statut]         VARCHAR(20)       NOT NULL CONSTRAINT DF_TxnRec_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]       NVARCHAR(400)     NULL,
        [Created]        DATETIME          NOT NULL CONSTRAINT DF_TxnRec_Created DEFAULT (GETDATE()),
        CONSTRAINT PK_TransactionRecurrenteImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_TxnRec_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_TxnRec_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_TxnRec_Company ON staging.TransactionRecurrenteImport ([CompanyGUID]);
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0849ChargerTransactionsRecurrentes]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50402, 'Aucune compagnie : impossible de déposer les transactions récurrentes.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.TransactionRecurrenteImport WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.TransactionRecurrenteImport
        ([ImportFileId], [RunId], [CompanyGUID], [Rang], [ExterneId], [Nom], [TypeTxn], [TypeRecurrence], [Actif],
         [IntervalleType], [NumIntervalle], [JourDuMois], [JourSemaine], [DateDebut], [DateProchaine], [DateFin],
         [TiersNom], [Montant], [Devise], [Extra], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, j.[rang], NULLIF(j.[externe_id], ''), NULLIF(j.[nom], ''),
           NULLIF(j.[type_txn], ''), NULLIF(j.[type_rec], ''), dbo.fImportBit(j.[actif]),
           NULLIF(j.[intervalle], ''), TRY_CONVERT(INT, NULLIF(j.[num_intervalle], '')),
           TRY_CONVERT(INT, NULLIF(j.[jour_mois], '')), NULLIF(j.[jour_semaine], ''),
           TRY_CONVERT(DATE, NULLIF(j.[debut], '')), TRY_CONVERT(DATE, NULLIF(j.[prochaine], '')), TRY_CONVERT(DATE, NULLIF(j.[fin], '')),
           NULLIF(j.[tiers], ''), TRY_CONVERT(DECIMAL(18,2), NULLIF(REPLACE(j.[montant], ',', '.'), '')), NULLIF(j.[devise], ''),
           j.[extra],
           CASE WHEN NULLIF(j.[nom], '') IS NULL THEN 'INVALIDE' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(j.[nom], '') IS NULL THEN N'Pas de nom : rien pour identifier ce modèle.' END
      FROM OPENJSON(@Elements)
           WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id', [nom] NVARCHAR(300) '$.nom',
                 [type_txn] NVARCHAR(40) '$.type_txn', [type_rec] NVARCHAR(40) '$.type_rec', [actif] NVARCHAR(10) '$.actif',
                 [intervalle] NVARCHAR(30) '$.intervalle', [num_intervalle] NVARCHAR(10) '$.num_intervalle',
                 [jour_mois] NVARCHAR(10) '$.jour_mois', [jour_semaine] NVARCHAR(20) '$.jour_semaine',
                 [debut] NVARCHAR(40) '$.debut', [prochaine] NVARCHAR(40) '$.prochaine', [fin] NVARCHAR(40) '$.fin',
                 [tiers] NVARCHAR(500) '$.tiers', [montant] NVARCHAR(40) '$.montant', [devise] NVARCHAR(10) '$.devise',
                 [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j;
    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END) AS [NbNouveaux],
           0 AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.TransactionRecurrenteImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0850GetTransactionsRecurrentes]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(*) AS [Nb],
           SUM(CASE WHEN [Actif] = 1 THEN 1 ELSE 0 END) AS [NbActives],
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END) AS [NbSoucis],
           MIN([DateProchaine]) AS [Prochaine]
      FROM staging.TransactionRecurrenteImport WHERE [CompanyGUID] = @CompanyGUID;

    SELECT [Id], [Rang], [ExterneId], [Nom], [TypeTxn], [TypeRecurrence], [Actif], [IntervalleType], [NumIntervalle],
           [JourDuMois], [JourSemaine], [DateDebut], [DateProchaine], [DateFin], [TiersNom], [Montant], [Devise],
           [Statut], [Anomalie]
      FROM staging.TransactionRecurrenteImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY CASE WHEN [Actif] = 1 THEN 0 ELSE 1 END, [DateProchaine], [Nom];
END
GO

-- -----------------------------------------------------------------------------
-- 5) Budgets
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.BudgetImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.BudgetImport
    (
        [Id]           INT IDENTITY(1,1) NOT NULL,
        [ImportFileId] INT               NULL,
        [RunId]        INT               NULL,
        [CompanyGUID]  UNIQUEIDENTIFIER  NOT NULL,
        [Rang]         INT               NOT NULL CONSTRAINT DF_Budget_Rang DEFAULT (0),
        [ExterneId]    NVARCHAR(100)     NULL,
        [Nom]          NVARCHAR(300)     NULL,
        [TypeBudget]   NVARCHAR(40)      NULL,   -- ProfitAndLoss, BalanceSheet
        [TypeSaisie]   NVARCHAR(40)      NULL,   -- Monthly, Quarterly, Yearly
        [DateDebut]    DATE              NULL,
        [DateFin]      DATE              NULL,
        [Actif]        BIT               NULL,
        [NbLignes]     INT               NOT NULL CONSTRAINT DF_Budget_NbLignes DEFAULT (0),
        [Total]        DECIMAL(18,2)     NULL,
        [Extra]        NVARCHAR(MAX)     NULL,
        [Statut]       VARCHAR(20)       NOT NULL CONSTRAINT DF_Budget_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]     NVARCHAR(400)     NULL,
        [Created]      DATETIME          NOT NULL CONSTRAINT DF_Budget_Created DEFAULT (GETDATE()),
        CONSTRAINT PK_BudgetImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_Budget_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_Budget_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_Budget_Company ON staging.BudgetImport ([CompanyGUID]);
END
GO

IF OBJECT_ID('staging.BudgetLigneImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.BudgetLigneImport
    (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [EnteteId]        INT               NOT NULL,
        [CompanyGUID]     UNIQUEIDENTIFIER  NOT NULL,
        [Rang]            INT               NOT NULL CONSTRAINT DF_BudgetL_Rang DEFAULT (0),
        [DateLigne]       DATE              NULL,
        [Montant]         DECIMAL(18,2)     NULL,
        [CompteNom]       NVARCHAR(300)     NULL,
        [CompteExterneId] NVARCHAR(100)     NULL,
        [TiersNom]        NVARCHAR(500)     NULL,
        [ClasseNom]       NVARCHAR(300)     NULL,
        [DepartementNom]  NVARCHAR(300)     NULL,
        CONSTRAINT PK_BudgetLigneImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_BudgetL_Entete FOREIGN KEY ([EnteteId]) REFERENCES staging.BudgetImport ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_BudgetL_Entete ON staging.BudgetLigneImport ([EnteteId]);
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0851ChargerBudgets]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL,
    @Entetes NVARCHAR(MAX), @Lignes NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50403, 'Aucune compagnie : impossible de déposer les budgets.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.BudgetImport WHERE [CompanyGUID] = @CompanyGUID;

    DECLARE @map TABLE ([Rang] INT, [Id] INT);

    MERGE staging.BudgetImport AS cible
    USING (SELECT j.* FROM OPENJSON(@Entetes)
             WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id', [nom] NVARCHAR(300) '$.nom',
                   [type_budget] NVARCHAR(40) '$.type_budget', [type_saisie] NVARCHAR(40) '$.type_saisie',
                   [debut] NVARCHAR(40) '$.debut', [fin] NVARCHAR(40) '$.fin', [actif] NVARCHAR(10) '$.actif',
                   [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j) AS src
       ON 1 = 0
    WHEN NOT MATCHED THEN
        INSERT ([ImportFileId], [RunId], [CompanyGUID], [Rang], [ExterneId], [Nom], [TypeBudget], [TypeSaisie],
                [DateDebut], [DateFin], [Actif], [Extra], [Statut], [Anomalie])
        VALUES (@ImportFileId, @RunId, @CompanyGUID, src.[rang], NULLIF(src.[externe_id], ''), NULLIF(src.[nom], ''),
                NULLIF(src.[type_budget], ''), NULLIF(src.[type_saisie], ''),
                TRY_CONVERT(DATE, NULLIF(src.[debut], '')), TRY_CONVERT(DATE, NULLIF(src.[fin], '')),
                dbo.fImportBit(src.[actif]), src.[extra],
                CASE WHEN NULLIF(src.[nom], '') IS NULL THEN 'INVALIDE' ELSE 'NOUVEAU' END,
                CASE WHEN NULLIF(src.[nom], '') IS NULL THEN N'Pas de nom : rien pour identifier ce budget.' END)
    OUTPUT inserted.[Rang], inserted.[Id] INTO @map;

    INSERT INTO staging.BudgetLigneImport
        ([EnteteId], [CompanyGUID], [Rang], [DateLigne], [Montant], [CompteNom], [CompteExterneId], [TiersNom], [ClasseNom], [DepartementNom])
    SELECT m.[Id], @CompanyGUID, j.[rang], TRY_CONVERT(DATE, NULLIF(j.[date], '')),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(REPLACE(j.[montant], ',', '.'), '')),
           NULLIF(j.[compte], ''), NULLIF(j.[compte_id], ''), NULLIF(j.[tiers], ''), NULLIF(j.[classe], ''), NULLIF(j.[departement], '')
      FROM OPENJSON(@Lignes)
           WITH ([entete_rang] INT '$.entete_rang', [rang] INT '$.rang', [date] NVARCHAR(40) '$.date',
                 [montant] NVARCHAR(40) '$.montant', [compte] NVARCHAR(300) '$.compte', [compte_id] NVARCHAR(100) '$.compte_id',
                 [tiers] NVARCHAR(500) '$.tiers', [classe] NVARCHAR(300) '$.classe', [departement] NVARCHAR(300) '$.departement') AS j
      JOIN @map m ON m.[Rang] = j.[entete_rang];

    UPDATE e SET [NbLignes] = x.[Nb], [Total] = x.[Total]
      FROM staging.BudgetImport e
     CROSS APPLY (SELECT COUNT(*) AS [Nb], SUM(ISNULL([Montant], 0)) AS [Total]
                    FROM staging.BudgetLigneImport l WHERE l.[EnteteId] = e.[Id]) x
     WHERE e.[CompanyGUID] = @CompanyGUID;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END) AS [NbNouveaux],
           0 AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides],
           SUM([NbLignes]) AS [NbLignes]
      FROM staging.BudgetImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0852GetBudgets]
    @CompanyGUID UNIQUEIDENTIFIER,
    @BudgetId    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [Rang], [ExterneId], [Nom], [TypeBudget], [TypeSaisie], [DateDebut], [DateFin], [Actif],
           [NbLignes], [Total], [Statut], [Anomalie]
      FROM staging.BudgetImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY [DateDebut] DESC, [Nom];

    -- Les lignes du budget demandé, regroupées par compte : une colonne par
    -- mois serait plus jolie mais la période n'est pas toujours mensuelle.
    SELECT l.[EnteteId], l.[CompteNom], l.[TiersNom], l.[ClasseNom], l.[DepartementNom],
           l.[DateLigne], l.[Montant]
      FROM staging.BudgetLigneImport l
      JOIN staging.BudgetImport e ON e.[Id] = l.[EnteteId]
     WHERE e.[CompanyGUID] = @CompanyGUID AND (@BudgetId IS NULL OR e.[Id] = @BudgetId)
     ORDER BY l.[EnteteId], l.[CompteNom], l.[DateLigne];
END
GO

-- -----------------------------------------------------------------------------
-- 6) Feuilles de temps
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.FeuilleTempsImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.FeuilleTempsImport
    (
        [Id]                INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]      INT               NULL,
        [RunId]             INT               NULL,
        [CompanyGUID]       UNIQUEIDENTIFIER  NOT NULL,
        [Rang]              INT               NOT NULL CONSTRAINT DF_FeuilleTemps_Rang DEFAULT (0),
        [ExterneId]         NVARCHAR(100)     NULL,
        [DateActivite]      DATE              NULL,
        [PersonneType]      NVARCHAR(20)      NULL,   -- Employee | Vendor
        [PersonneNom]       NVARCHAR(500)     NULL,
        [PersonneExterneId] NVARCHAR(100)     NULL,
        [ClientNom]         NVARCHAR(500)     NULL,
        [ClientExterneId]   NVARCHAR(100)     NULL,
        [ArticleNom]        NVARCHAR(500)     NULL,
        [ClasseNom]         NVARCHAR(300)     NULL,
        [Facturable]        NVARCHAR(30)      NULL,   -- Billable, NotBillable, HasBeenBilled
        [Taxable]           BIT               NULL,
        [TauxHoraire]       DECIMAL(18,4)     NULL,
        [Heures]            INT               NULL,
        [Minutes]           INT               NULL,
        [HeureDebut]        DATETIME          NULL,
        [HeureFin]          DATETIME          NULL,
        [Description]       NVARCHAR(2000)    NULL,
        [Extra]             NVARCHAR(MAX)     NULL,
        [Statut]            VARCHAR(20)       NOT NULL CONSTRAINT DF_FeuilleTemps_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]          NVARCHAR(400)     NULL,
        [Created]           DATETIME          NOT NULL CONSTRAINT DF_FeuilleTemps_Created DEFAULT (GETDATE()),
        CONSTRAINT PK_FeuilleTempsImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_FeuilleTemps_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_FeuilleTemps_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_FeuilleTemps_Company ON staging.FeuilleTempsImport ([CompanyGUID], [DateActivite]);
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0853ChargerFeuillesTemps]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50404, 'Aucune compagnie : impossible de déposer les feuilles de temps.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.FeuilleTempsImport WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.FeuilleTempsImport
        ([ImportFileId], [RunId], [CompanyGUID], [Rang], [ExterneId], [DateActivite], [PersonneType], [PersonneNom], [PersonneExterneId],
         [ClientNom], [ClientExterneId], [ArticleNom], [ClasseNom], [Facturable], [Taxable], [TauxHoraire], [Heures], [Minutes],
         [HeureDebut], [HeureFin], [Description], [Extra], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, j.[rang], NULLIF(j.[externe_id], ''),
           TRY_CONVERT(DATE, NULLIF(j.[date], '')), NULLIF(j.[personne_type], ''), NULLIF(j.[personne], ''), NULLIF(j.[personne_id], ''),
           NULLIF(j.[client], ''), NULLIF(j.[client_id], ''), NULLIF(j.[article], ''), NULLIF(j.[classe], ''),
           NULLIF(j.[facturable], ''), dbo.fImportBit(j.[taxable]),
           TRY_CONVERT(DECIMAL(18,4), NULLIF(REPLACE(j.[taux], ',', '.'), '')),
           TRY_CONVERT(INT, NULLIF(j.[heures], '')), TRY_CONVERT(INT, NULLIF(j.[minutes], '')),
           TRY_CONVERT(DATETIME, TRY_CONVERT(DATETIMEOFFSET, NULLIF(j.[debut], ''))),
           TRY_CONVERT(DATETIME, TRY_CONVERT(DATETIMEOFFSET, NULLIF(j.[fin], ''))),
           NULLIF(j.[description], ''), j.[extra],
           CASE WHEN TRY_CONVERT(DATE, NULLIF(j.[date], '')) IS NULL THEN 'INVALIDE' ELSE 'NOUVEAU' END,
           CASE WHEN TRY_CONVERT(DATE, NULLIF(j.[date], '')) IS NULL THEN N'Pas de date : une activité sans jour ne se place nulle part.' END
      FROM OPENJSON(@Elements)
           WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id', [date] NVARCHAR(40) '$.date',
                 [personne_type] NVARCHAR(20) '$.personne_type', [personne] NVARCHAR(500) '$.personne', [personne_id] NVARCHAR(100) '$.personne_id',
                 [client] NVARCHAR(500) '$.client', [client_id] NVARCHAR(100) '$.client_id', [article] NVARCHAR(500) '$.article',
                 [classe] NVARCHAR(300) '$.classe', [facturable] NVARCHAR(30) '$.facturable', [taxable] NVARCHAR(10) '$.taxable',
                 [taux] NVARCHAR(40) '$.taux', [heures] NVARCHAR(10) '$.heures', [minutes] NVARCHAR(10) '$.minutes',
                 [debut] NVARCHAR(40) '$.debut', [fin] NVARCHAR(40) '$.fin', [description] NVARCHAR(2000) '$.description',
                 [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j;
    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END) AS [NbNouveaux],
           0 AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.FeuilleTempsImport WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0854GetFeuillesTemps]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Le repère : par personne, les heures et ce qui est facturable.
    SELECT [PersonneNom], [PersonneType], COUNT(*) AS [Nb],
           SUM(ISNULL([Heures], 0) * 60 + ISNULL([Minutes], 0)) AS [MinutesTotal],
           SUM(CASE WHEN [Facturable] = 'Billable' THEN ISNULL([Heures], 0) * 60 + ISNULL([Minutes], 0) ELSE 0 END) AS [MinutesFacturables],
           MIN([DateActivite]) AS [Du], MAX([DateActivite]) AS [Au]
      FROM staging.FeuilleTempsImport
     WHERE [CompanyGUID] = @CompanyGUID
     GROUP BY [PersonneNom], [PersonneType]
     ORDER BY [PersonneNom];

    SELECT [Id], [Rang], [ExterneId], [DateActivite], [PersonneType], [PersonneNom], [ClientNom], [ArticleNom], [ClasseNom],
           [Facturable], [Taxable], [TauxHoraire], [Heures], [Minutes], [HeureDebut], [HeureFin], [Description],
           [Statut], [Anomalie]
      FROM staging.FeuilleTempsImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY [DateActivite] DESC, [PersonneNom], [Rang];
END
GO
