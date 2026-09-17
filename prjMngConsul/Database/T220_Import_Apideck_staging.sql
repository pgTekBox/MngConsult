-- =============================================================================
-- T220 — Importation par connecteur (Apideck → QuickBooks)
--
-- Jusqu'ici, toute reprise passait par un fichier que le client exportait
-- lui-même. Ce script ouvre l'autre voie : lire la comptabilité source en
-- direct, par l'API unifiée d'Apideck, sans que personne n'exporte quoi que ce
-- soit.
--
-- Ce qui arrive ne va PAS en comptabilité. Tout se dépose en préparation :
--
--   staging.ConnecteurRun      une extraction : qui, quand, quel connecteur
--   staging.ConnecteurDonnee   un enregistrement tel qu'Apideck l'a rendu,
--                              en JSON, sans interprétation
--
-- Garder le JSON brut plutôt que des colonnes nommées est délibéré. Apideck
-- couvre vingt-neuf ressources, dont la plupart n'ont pas encore d'écran ; leur
-- inventer des tables aujourd'hui, ce serait figer des choix qu'on ne sait pas
-- encore faire. Le JSON se relit avec OPENJSON le jour où l'écran existe, et
-- rien n'est perdu entre-temps.
--
-- Les quatre ressources déjà traitées par l'application — comptes, clients,
-- fournisseurs, produits — sont ensuite versées dans les tables de préparation
-- existantes par le code appelant, qui réutilise s0751/s0752 pour le plan
-- comptable et s0600/s0602/s0604 pour les listes. Les écrans d'import actuels
-- les affichent alors sans une ligne de changement.
--
-- Sage viendra par le même chemin : c'est un autre connecteur d'Apideck, donc
-- une autre valeur de [Service]. Rien ici ne suppose QuickBooks.
--
-- Procédures : s0776 à s0780.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) staging.ConnecteurRun — une extraction
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.ConnecteurRun', 'U') IS NULL
BEGIN
    CREATE TABLE staging.ConnecteurRun
    (
        [Id]                INT IDENTITY(1,1) NOT NULL,
        [CompanyGUID]       UNIQUEIDENTIFIER  NOT NULL,

        -- « APIDECK » aujourd'hui ; le jour où une autre passerelle s'ajoute,
        -- les extractions passées restent lisibles pour ce qu'elles sont.
        [Connecteur]        VARCHAR(20)       NOT NULL,

        -- Le logiciel source chez Apideck : « quickbooks », plus tard « sage… ».
        [Service]           VARCHAR(40)       NOT NULL,

        -- Le consommateur Apideck : la compagnie, telle qu'elle a relié son
        -- QuickBooks dans Vault.
        [ConsumerId]        NVARCHAR(100)     NULL,

        [Statut]            VARCHAR(20)       NOT NULL CONSTRAINT DF_ConnecteurRun_Statut DEFAULT ('EN_COURS'),
        [NbRessources]      INT               NOT NULL CONSTRAINT DF_ConnecteurRun_NbRes DEFAULT (0),
        [NbEnregistrements] INT               NOT NULL CONSTRAINT DF_ConnecteurRun_NbEnr DEFAULT (0),

        [Debut]             DATETIME          NOT NULL CONSTRAINT DF_ConnecteurRun_Debut DEFAULT (GETDATE()),
        [Fin]               DATETIME          NULL,
        [Note]              NVARCHAR(2000)    NULL,
        [CreatedBy]         INT               NULL,

        CONSTRAINT PK_ConnecteurRun PRIMARY KEY CLUSTERED ([Id])
    );

    CREATE INDEX IX_ConnecteurRun_Company ON staging.ConnecteurRun ([CompanyGUID], [Debut] DESC);
END
GO

-- -----------------------------------------------------------------------------
-- 2) staging.ConnecteurDonnee — ce qu'Apideck a rendu, tel quel
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.ConnecteurDonnee', 'U') IS NULL
BEGIN
    CREATE TABLE staging.ConnecteurDonnee
    (
        [Id]          BIGINT IDENTITY(1,1) NOT NULL,
        [RunId]       INT               NOT NULL,
        [CompanyGUID] UNIQUEIDENTIFIER  NOT NULL,

        -- La ressource Apideck : « customers », « ledger-accounts »…
        [Ressource]   VARCHAR(60)       NOT NULL,

        [Rang]        INT               NOT NULL,

        -- L'identifiant chez la source, quand il existe : c'est lui qui
        -- permettra de reconnaître un enregistrement d'une extraction à l'autre.
        [ExterneId]   NVARCHAR(100)     NULL,

        [Json]        NVARCHAR(MAX)     NOT NULL,
        [Created]     DATETIME          NOT NULL CONSTRAINT DF_ConnecteurDonnee_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_ConnecteurDonnee PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_ConnecteurDonnee_Run FOREIGN KEY ([RunId])
            REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );

    CREATE INDEX IX_ConnecteurDonnee_Run ON staging.ConnecteurDonnee ([RunId], [Ressource], [Rang]);
    CREATE INDEX IX_ConnecteurDonnee_Externe ON staging.ConnecteurDonnee ([CompanyGUID], [Ressource], [ExterneId]);
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0776OuvrirConnecteurRun
--    Ouvre une extraction. Le RunId qui revient accompagne tous les
--    chargements qui suivent.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0776OuvrirConnecteurRun]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Connecteur  VARCHAR(20),
    @Service     VARCHAR(40),
    @ConsumerId  NVARCHAR(100) = NULL,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @CompanyGUID IS NULL
        THROW 50361, 'Aucune compagnie : impossible d''ouvrir une extraction.', 1;

    INSERT INTO staging.ConnecteurRun ([CompanyGUID], [Connecteur], [Service], [ConsumerId], [CreatedBy])
    VALUES (@CompanyGUID, @Connecteur, @Service, @ConsumerId, @UserId);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS RunId;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0777ChargerConnecteurDonnees
--    Dépose une ressource entière en un appel. Les enregistrements arrivent en
--    JSON : un aller-retour par ligne serait inutilement bavard sur des milliers
--    de factures.
--
--    Recharger une ressource remplace ce qu'elle contenait : on ne cumule pas
--    deux lectures de la même liste.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0777ChargerConnecteurDonnees]
    @RunId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @Ressource   VARCHAR(60),
    @Lignes      NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM staging.ConnecteurRun
                    WHERE [Id] = @RunId AND [CompanyGUID] = @CompanyGUID)
        THROW 50362, 'Extraction introuvable pour cette compagnie.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.ConnecteurDonnee
     WHERE [RunId] = @RunId AND [Ressource] = @Ressource;

    INSERT INTO staging.ConnecteurDonnee ([RunId], [CompanyGUID], [Ressource], [Rang], [ExterneId], [Json])
    SELECT @RunId, @CompanyGUID, @Ressource,
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
           LEFT(j.[ExterneId], 100),
           j.[Json]
      FROM OPENJSON(@Lignes)
           WITH ([ExterneId] NVARCHAR(200) '$.id',
                 [Json]      NVARCHAR(MAX) '$.json' AS JSON) AS j;

    -- Les compteurs du lot se recalculent à partir de ce qu'il contient
    -- réellement : deux chargements de la même ressource ne le gonflent pas.
    UPDATE r
       SET [NbEnregistrements] = x.[Enregistrements],
           [NbRessources]      = x.[Ressources]
      FROM staging.ConnecteurRun r
     CROSS APPLY (SELECT COUNT(*) AS [Enregistrements],
                         COUNT(DISTINCT d.[Ressource]) AS [Ressources]
                    FROM staging.ConnecteurDonnee d
                   WHERE d.[RunId] = r.[Id]) x
     WHERE r.[Id] = @RunId;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS NbCharges
      FROM staging.ConnecteurDonnee
     WHERE [RunId] = @RunId AND [Ressource] = @Ressource;
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0778FermerConnecteurRun
--    Clôt l'extraction. La note porte ce qui s'est mal passé, s'il y a lieu :
--    une ressource refusée par Apideck n'arrête pas les autres.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0778FermerConnecteurRun]
    @RunId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @Statut      VARCHAR(20),
    @Note        NVARCHAR(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE staging.ConnecteurRun
       SET [Statut] = @Statut,
           [Fin]    = GETDATE(),
           [Note]   = @Note
     WHERE [Id] = @RunId AND [CompanyGUID] = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 6) s0779GetConnecteurRuns
--    Les extractions récentes de la compagnie, puis le détail par ressource.
--    Deux jeux de résultats : la liste, puis le contenu.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0779GetConnecteurRuns]
    @CompanyGUID UNIQUEIDENTIFIER,
    @RunId       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 20
           r.[Id], r.[Connecteur], r.[Service], r.[ConsumerId], r.[Statut],
           r.[NbRessources], r.[NbEnregistrements], r.[Debut], r.[Fin], r.[Note]
      FROM staging.ConnecteurRun r
     WHERE r.[CompanyGUID] = @CompanyGUID
     ORDER BY r.[Debut] DESC;

    SELECT d.[Ressource], COUNT(*) AS [Nb]
      FROM staging.ConnecteurDonnee d
      JOIN staging.ConnecteurRun r ON r.[Id] = d.[RunId]
     WHERE r.[CompanyGUID] = @CompanyGUID
       AND (@RunId IS NULL OR d.[RunId] = @RunId)
     GROUP BY d.[Ressource]
     ORDER BY d.[Ressource];
END
GO

-- -----------------------------------------------------------------------------
-- 7) s0780SupprimerConnecteurRun
--    Efface une extraction et son contenu. Rien n'ayant été appliqué à la
--    comptabilité à ce stade, la suppression est sans conséquence.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0780SupprimerConnecteurRun]
    @CompanyGUID UNIQUEIDENTIFIER,
    @RunId       INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM staging.ConnecteurRun
                    WHERE [Id] = @RunId AND [CompanyGUID] = @CompanyGUID)
        THROW 50363, 'Extraction introuvable pour cette compagnie.', 1;

    DELETE FROM staging.ConnecteurRun WHERE [Id] = @RunId;
END
GO
