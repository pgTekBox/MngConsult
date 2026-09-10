-- =============================================================================
-- Reprise comptable — la cle d'un compte source n'est pas toujours son numero
-- -----------------------------------------------------------------------------
-- Le premier modele exigeait un numero de compte. C'etait une erreur : dans
-- QuickBooks en ligne les numeros sont facultatifs et desactives par defaut.
-- Beaucoup de compagnies n'en ont jamais eu, et leurs comptes s'identifient par
-- leur nom, qui est unique chez eux. Leurs autres rapports — le grand livre au
-- premier chef — designent d'ailleurs les comptes par ce nom.
--
-- Exiger le numero rendait donc l'importation impossible pour ces compagnies,
-- et la cle ne tenait pas davantage pour les etapes suivantes.
--
-- Desormais chaque ligne porte une CleSource : le numero s'il existe, le nom
-- normalise sinon. C'est elle qui identifie le compte d'origine, et c'est sur
-- elle que porte la correspondance.
--
-- Une ligne n'est refusee que si elle n'a NI numero NI nom.
--
-- Le numero redevient obligatoire a un seul endroit : dans NOTRE plan, ou
-- T121PlanComptable.Compte est NOT NULL. Un compte a creer doit donc recevoir
-- un numero, et c'est une decision comptable, pas une deduction.
--
-- Re-executable. Les tables de preparation etaient vides a l'application.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1) La cle source, en preparation
-- -----------------------------------------------------------------------------
IF COL_LENGTH('staging.ImportPlanComptable', 'CleSource') IS NULL
    ALTER TABLE staging.ImportPlanComptable ADD [CleSource] NVARCHAR(200) NULL;
GO
IF COL_LENGTH('staging.ImportPlanComptable', 'TypeCle') IS NULL
    ALTER TABLE staging.ImportPlanComptable ADD [TypeCle] VARCHAR(10) NULL;   -- NUMERO | NOM
GO

-- Le numero peut manquer : il n'est plus la cle.
IF EXISTS (SELECT 1 FROM sys.columns
            WHERE object_id = OBJECT_ID('staging.ImportPlanComptable')
              AND name = 'Compte' AND is_nullable = 0)
    ALTER TABLE staging.ImportPlanComptable ALTER COLUMN [Compte] VARCHAR(20) NULL;
GO

-- -----------------------------------------------------------------------------
-- 2) La cle source, dans la correspondance
-- -----------------------------------------------------------------------------
IF COL_LENGTH('staging.CorrespondanceCompte', 'CleSource') IS NULL
    ALTER TABLE staging.CorrespondanceCompte ADD [CleSource] NVARCHAR(200) NULL;
GO
IF COL_LENGTH('staging.CorrespondanceCompte', 'TypeCle') IS NULL
    ALTER TABLE staging.CorrespondanceCompte ADD [TypeCle] VARCHAR(10) NULL;
GO

-- Reprise des lignes existantes avant de changer la cle.
UPDATE staging.CorrespondanceCompte
   SET [CleSource] = COALESCE(NULLIF(LTRIM(RTRIM([CompteSource])), ''), UPPER(LTRIM(RTRIM([NomSource])))),
       [TypeCle]   = CASE WHEN NULLIF(LTRIM(RTRIM([CompteSource])), '') IS NOT NULL THEN 'NUMERO' ELSE 'NOM' END
 WHERE [CleSource] IS NULL;
GO

IF EXISTS (SELECT 1 FROM sys.indexes
            WHERE object_id = OBJECT_ID('staging.CorrespondanceCompte') AND name = 'UX_Corresp_Source')
    DROP INDEX UX_Corresp_Source ON staging.CorrespondanceCompte;
GO

IF EXISTS (SELECT 1 FROM sys.columns
            WHERE object_id = OBJECT_ID('staging.CorrespondanceCompte')
              AND name = 'CompteSource' AND is_nullable = 0)
    ALTER TABLE staging.CorrespondanceCompte ALTER COLUMN [CompteSource] VARCHAR(20) NULL;
GO

ALTER TABLE staging.CorrespondanceCompte ALTER COLUMN [CleSource] NVARCHAR(200) NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
                WHERE object_id = OBJECT_ID('staging.CorrespondanceCompte') AND name = 'UX_Corresp_Cle')
    CREATE UNIQUE INDEX UX_Corresp_Cle
        ON staging.CorrespondanceCompte ([CompanyGUID], [SystemeSource], [CleSource]);
GO

-- -----------------------------------------------------------------------------
-- 3) s0752ChargerPlanComptableStaging — la cle, et la validite revue
--
--    Une ligne est invalide seulement si elle n'a ni numero ni nom.
--    Le doublon se juge sur la cle, pas sur le numero.
--    « Deja au plan » se reconnait par le numero quand il existe, par le nom
--    sinon — c'est le seul rattachement possible pour un plan sans numeros.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0752ChargerPlanComptableStaging]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @Lignes      NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM staging.ImportLot
                    WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID)
        THROW 50302, 'Lot d''importation introuvable pour cette compagnie.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.ImportPlanComptable WHERE [LotId] = @LotId;

    INSERT INTO staging.ImportPlanComptable
        ([LotId], [CompanyGUID], [LigneNo],
         [CompteSource], [NomSource], [TypeSource], [SoldeSource], [SensSource],
         [Compte], [Nom], [TypeNormalise], [Solde], [Sens],
         [CleSource], [TypeCle])
    SELECT
        @LotId, @CompanyGUID, j.LigneNo,
        j.CompteSource, j.NomSource, j.TypeSource, j.SoldeSource, j.SensSource,
        NULLIF(LEFT(LTRIM(RTRIM(ISNULL(j.Compte, ''))), 20), ''),
        NULLIF(LTRIM(RTRIM(ISNULL(j.Nom, ''))), ''),
        j.TypeNormalise,
        j.Solde,
        j.Sens,
        -- la cle : le numero s'il existe, le nom normalise sinon
        COALESCE(
            NULLIF(LEFT(LTRIM(RTRIM(ISNULL(j.Compte, ''))), 20), ''),
            NULLIF(UPPER(LTRIM(RTRIM(ISNULL(j.Nom, '')))), '')),
        CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(j.Compte, ''))), '') IS NOT NULL
             THEN 'NUMERO' ELSE 'NOM' END
    FROM OPENJSON(@Lignes)
         WITH (
            LigneNo       INT            '$.LigneNo',
            CompteSource  NVARCHAR(50)   '$.CompteSource',
            NomSource     NVARCHAR(200)  '$.NomSource',
            TypeSource    NVARCHAR(100)  '$.TypeSource',
            SoldeSource   NVARCHAR(50)   '$.SoldeSource',
            SensSource    NVARCHAR(20)   '$.SensSource',
            Compte        NVARCHAR(50)   '$.Compte',
            Nom           NVARCHAR(200)  '$.Nom',
            TypeNormalise VARCHAR(20)    '$.TypeNormalise',
            Solde         DECIMAL(18,2)  '$.Solde',
            Sens          VARCHAR(10)    '$.Sens'
         ) j;

    -- ── Verdicts ─────────────────────────────────────────────────────────
    UPDATE staging.ImportPlanComptable
       SET [Statut]   = 'INVALIDE',
           [Anomalie] = N'Ligne sans numéro ni nom de compte : rien ne permet de l''identifier.'
     WHERE [LotId] = @LotId
       AND [CleSource] IS NULL;

    -- Le message nomme la cle et la ligne d'origine : sans cela un doublon
    -- annonce reste indemontrable pour celui qui relit son fichier.
    ;WITH d AS (
        SELECT [Id],
               ROW_NUMBER() OVER (PARTITION BY [CleSource] ORDER BY [LigneNo]) AS rn,
               MIN([LigneNo])  OVER (PARTITION BY [CleSource])                 AS PremiereLigne
          FROM staging.ImportPlanComptable
         WHERE [LotId] = @LotId AND [Statut] = 'OK'
    )
    UPDATE p
       SET p.[Statut]   = 'DOUBLON_FICHIER',
           p.[Anomalie] = N'Même clé (« ' + p.[CleSource] + N' ») que la ligne '
                        + CAST(d.PremiereLigne AS NVARCHAR(20)) + N' du fichier.'
      FROM staging.ImportPlanComptable p
     INNER JOIN d ON d.[Id] = p.[Id]
     WHERE d.rn > 1;

    -- Deja au plan : par le numero quand il y en a un...
    UPDATE p
       SET p.[PlanComptableId] = pc.[Id],
           p.[Statut]          = 'EXISTE',
           p.[Anomalie]        = N'Déjà au plan comptable : ' + pc.[Nom]
      FROM staging.ImportPlanComptable p
     INNER JOIN dbo.T121PlanComptable pc
             ON pc.[CompanyGUID] = p.[CompanyGUID]
            AND pc.[Compte] = p.[Compte]
     WHERE p.[LotId] = @LotId
       AND p.[Statut] = 'OK'
       AND p.[TypeCle] = 'NUMERO';

    -- ...par le nom quand il n'y en a pas. Le plan est trilingue : un export
    -- QuickBooks anglais dit « Accounts receivable » la ou notre plan francais
    -- dit « Comptes clients ». On confronte donc les quatre libelles, sinon
    -- rien ne se reconnait des qu'on change de langue.
    UPDATE p
       SET p.[PlanComptableId] = n.[Id],
           p.[Statut]          = 'EXISTE',
           p.[Anomalie]        = N'Déjà au plan comptable : ' + n.[Compte] + N' — ' + n.[Nom]
      FROM staging.ImportPlanComptable p
     CROSS APPLY (
        SELECT TOP 1 pc.[Id], pc.[Compte], pc.[Nom]
          FROM dbo.T121PlanComptable pc
         CROSS APPLY (VALUES (pc.[Nom]), (pc.[NomFr]), (pc.[NomEn]), (pc.[NomEs])) AS l([Libelle])
         WHERE pc.[CompanyGUID] = p.[CompanyGUID]
           AND ISNULL(pc.[Actif], 1) = 1
           AND UPPER(LTRIM(RTRIM(l.[Libelle]))) = p.[CleSource]
         ORDER BY pc.[Compte]
     ) n
     WHERE p.[LotId] = @LotId
       AND p.[Statut] = 'OK'
       AND p.[TypeCle] = 'NOM';

    UPDATE l
       SET l.[NbLignesLues]     = x.Total,
           l.[NbLignesRetenues] = x.Retenues,
           l.[NbAnomalies]      = x.Anomalies,
           l.[Statut]           = 'CHARGE'
      FROM staging.ImportLot l
     CROSS APPLY (
        SELECT COUNT(*) AS Total,
               SUM(CASE WHEN [Statut] IN ('OK', 'EXISTE') THEN 1 ELSE 0 END) AS Retenues,
               SUM(CASE WHEN [Statut] IN ('INVALIDE', 'DOUBLON_FICHIER') THEN 1 ELSE 0 END) AS Anomalies
          FROM staging.ImportPlanComptable WHERE [LotId] = @LotId
     ) x
     WHERE l.[Id] = @LotId;

    COMMIT TRANSACTION;

    SELECT [NbLignesLues], [NbLignesRetenues], [NbAnomalies], [Statut]
      FROM staging.ImportLot WHERE [Id] = @LotId;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0753GetPlanComptableStaging — la cle apparait dans la liste
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0753GetPlanComptableStaging]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @Statut      VARCHAR(20) = NULL,
    @Top         INT = 500
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        p.[Id], p.[LigneNo],
        p.[CompteSource], p.[NomSource], p.[TypeSource], p.[SoldeSource], p.[SensSource],
        p.[Compte], p.[Nom], p.[TypeNormalise], p.[Solde], p.[Sens],
        p.[CleSource], p.[TypeCle],
        p.[Statut], p.[Anomalie],
        p.[PlanComptableId],
        pc.[Nom] AS NomAuPlan
    FROM staging.ImportPlanComptable p
    LEFT JOIN dbo.T121PlanComptable pc ON pc.[Id] = p.[PlanComptableId]
    WHERE p.[LotId] = @LotId
      AND p.[CompanyGUID] = @CompanyGUID
      AND (@Statut IS NULL OR p.[Statut] = @Statut)
    ORDER BY p.[LigneNo];
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0756GetCorrespondances — sa definition vit dans T214
--
--    T214 l'a etendue pour porter la proposition de l'IA. En garder une copie
--    ici faisait qu'un simple rejeu de T212 effacait ces colonnes et cassait
--    la page de correspondance. Une procedure, un fichier.
-- -----------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
-- 6) s0757SaveCorrespondances — cle, et le numero exige a la creation
--
--    « Creer » sans numero cible n'est plus enregistrable : notre plan exige
--    un numero (T121PlanComptable.Compte est NOT NULL) et on ne peut pas le
--    reprendre de l'origine quand celle-ci n'en a pas. C'est une decision
--    comptable, elle revient a l'utilisateur.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0757SaveCorrespondances]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = NULL,
    @Decisions   NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT [SystemeSource] FROM staging.ImportLot
          WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID);

    IF @Systeme IS NULL
        THROW 50310, 'Lot d''importation introuvable pour cette compagnie.', 1;

    DECLARE @d TABLE (
        CleSource    NVARCHAR(200),
        CompteSource VARCHAR(20),
        NomSource    NVARCHAR(200),
        TypeCle      VARCHAR(10),
        Action       VARCHAR(10),
        CompteCible  VARCHAR(20),
        NomCible     NVARCHAR(200),
        TypeCible    VARCHAR(20),
        Note         NVARCHAR(500)
    );

    INSERT INTO @d
    SELECT LTRIM(RTRIM(j.CleSource)),
           NULLIF(LEFT(LTRIM(RTRIM(ISNULL(j.CompteSource, ''))), 20), ''),
           j.NomSource,
           j.TypeCle,
           NULLIF(LTRIM(RTRIM(j.Action)), ''),
           NULLIF(LEFT(LTRIM(RTRIM(ISNULL(j.CompteCible, ''))), 20), ''),
           j.NomCible, j.TypeCible, j.Note
      FROM OPENJSON(@Decisions)
           WITH (
              CleSource    NVARCHAR(200) '$.CleSource',
              CompteSource NVARCHAR(50)  '$.CompteSource',
              NomSource    NVARCHAR(200) '$.NomSource',
              TypeCle      VARCHAR(10)   '$.TypeCle',
              Action       VARCHAR(10)   '$.Action',
              CompteCible  NVARCHAR(50)  '$.CompteCible',
              NomCible     NVARCHAR(200) '$.NomCible',
              TypeCible    VARCHAR(20)   '$.TypeCible',
              Note         NVARCHAR(500) '$.Note'
           ) j
     WHERE ISNULL(LTRIM(RTRIM(j.CleSource)), '') <> '';

    BEGIN TRANSACTION;

    DELETE c
      FROM staging.CorrespondanceCompte c
     INNER JOIN @d d ON d.CleSource = c.CleSource
     WHERE c.[CompanyGUID] = @CompanyGUID
       AND c.[SystemeSource] = @Systeme
       AND d.Action IS NULL;

    MERGE staging.CorrespondanceCompte AS cible
    USING (
        SELECT d.CleSource, d.CompteSource, d.NomSource, d.TypeCle, d.Action,
               d.CompteCible, d.NomCible, d.TypeCible, d.Note,
               pc.[Id] AS PlanComptableId
          FROM @d d
          LEFT JOIN dbo.T121PlanComptable pc
                 ON pc.[CompanyGUID] = @CompanyGUID
                AND pc.[Compte] = d.CompteCible
         WHERE d.Action IS NOT NULL
    ) AS src
       ON  cible.[CompanyGUID] = @CompanyGUID
       AND cible.[SystemeSource] = @Systeme
       AND cible.[CleSource] = src.CleSource
    WHEN MATCHED THEN UPDATE SET
        cible.[Action]          = src.Action,
        cible.[PlanComptableId] = CASE WHEN src.Action = 'LIER' THEN src.PlanComptableId END,
        cible.[CompteCible]     = CASE WHEN src.Action = 'CREER' THEN src.CompteCible END,
        cible.[NomCible]        = CASE WHEN src.Action = 'CREER' THEN src.NomCible END,
        cible.[TypeCible]       = CASE WHEN src.Action = 'CREER' THEN src.TypeCible END,
        cible.[CompteSource]    = src.CompteSource,
        cible.[NomSource]       = src.NomSource,
        cible.[TypeCle]         = src.TypeCle,
        cible.[Note]            = src.Note,
        cible.[Modified]        = GETDATE(),
        cible.[ModifiedBy]      = @UserId
    WHEN NOT MATCHED THEN INSERT
        ([CompanyGUID], [SystemeSource], [CleSource], [TypeCle], [CompteSource], [NomSource],
         [Action], [PlanComptableId], [CompteCible], [NomCible], [TypeCible], [Note], [CreatedBy])
        VALUES
        (@CompanyGUID, @Systeme, src.CleSource, src.TypeCle, src.CompteSource, src.NomSource,
         src.Action,
         CASE WHEN src.Action = 'LIER'  THEN src.PlanComptableId END,
         CASE WHEN src.Action = 'CREER' THEN src.CompteCible END,
         CASE WHEN src.Action = 'CREER' THEN src.NomCible END,
         CASE WHEN src.Action = 'CREER' THEN src.TypeCible END,
         src.Note, @UserId);

    -- Un « lier » qui ne pointe nulle part n'est pas une decision.
    DELETE FROM staging.CorrespondanceCompte
     WHERE [CompanyGUID] = @CompanyGUID
       AND [SystemeSource] = @Systeme
       AND [Action] = 'LIER'
       AND [PlanComptableId] IS NULL;

    -- Un « creer » sans numero reste recevable : l'etape 3 (T215) attribue le
    -- numero dans la plage de la classe choisie. L'exiger ici obligeait a
    -- l'inventer avant meme de savoir ou le compte serait range.

    COMMIT TRANSACTION;

    EXEC dbo.s0758StatsCorrespondance @LotId = @LotId, @CompanyGUID = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 7) s0758StatsCorrespondance — sur la cle
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0758StatsCorrespondance]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT [SystemeSource] FROM staging.ImportLot
          WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID);

    ;WITH src AS (
        SELECT p.[CleSource]
          FROM staging.ImportPlanComptable p
         WHERE p.[LotId] = @LotId
           AND p.[CompanyGUID] = @CompanyGUID
           AND p.[Statut] IN ('OK', 'EXISTE')
    )
    SELECT
        COUNT(*)                                                    AS Total,
        SUM(CASE WHEN c.[Id] IS NOT NULL THEN 1 ELSE 0 END)         AS Decides,
        SUM(CASE WHEN c.[Id] IS NULL THEN 1 ELSE 0 END)             AS ADecider,
        SUM(CASE WHEN c.[Action] = 'LIER' THEN 1 ELSE 0 END)        AS Lies,
        SUM(CASE WHEN c.[Action] = 'CREER' THEN 1 ELSE 0 END)       AS ACreer,
        SUM(CASE WHEN c.[Action] = 'IGNORER' THEN 1 ELSE 0 END)     AS Ignores
    FROM src s
    LEFT JOIN staging.CorrespondanceCompte c
           ON c.[CompanyGUID] = @CompanyGUID
          AND c.[SystemeSource] = @Systeme
          AND c.[CleSource] = s.[CleSource];
END
GO

-- -----------------------------------------------------------------------------
-- 8) s0760AccepterPropositions — sur la cle
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0760AccepterPropositions]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT [SystemeSource] FROM staging.ImportLot
          WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID);

    IF @Systeme IS NULL
        THROW 50310, 'Lot d''importation introuvable pour cette compagnie.', 1;

    INSERT INTO staging.CorrespondanceCompte
        ([CompanyGUID], [SystemeSource], [CleSource], [TypeCle],
         [CompteSource], [NomSource], [Action], [PlanComptableId], [Note], [CreatedBy])
    SELECT @CompanyGUID, @Systeme, p.[CleSource], p.[TypeCle],
           p.[Compte], p.[Nom], 'LIER', p.[PlanComptableId],
           CASE WHEN p.[TypeCle] = 'NUMERO'
                THEN N'Proposition acceptée : même numéro de compte.'
                ELSE N'Proposition acceptée : même nom de compte.' END,
           @UserId
      FROM staging.ImportPlanComptable p
     WHERE p.[LotId] = @LotId
       AND p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] IN ('OK', 'EXISTE')
       AND p.[PlanComptableId] IS NOT NULL
       AND NOT EXISTS (
            SELECT 1 FROM staging.CorrespondanceCompte c
             WHERE c.[CompanyGUID] = @CompanyGUID
               AND c.[SystemeSource] = @Systeme
               AND c.[CleSource] = p.[CleSource]);

    EXEC dbo.s0758StatsCorrespondance @LotId = @LotId, @CompanyGUID = @CompanyGUID;
END
GO

PRINT N'T212_Cle_source_numero_ou_nom.sql : termine.';
GO
