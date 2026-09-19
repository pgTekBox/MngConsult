-- =============================================================================
-- T243 — Le lot d'importation disparaît : la compagnie suffit
--
-- Le plan comptable importé passait par une table d'entête, staging.ImportLot,
-- et chaque extraction en ouvrait une nouvelle. Résultat visible après cinq
-- extractions Apideck : cinq lots de cinquante-huit comptes identiques, et un
-- écran qui demandait lequel regarder.
--
-- Le lot n'apportait rien. La preuve est dans la transformation : TOUTES les
-- procédures prenaient déjà @CompanyGUID à côté de @LotId. Le lot n'était qu'un
-- niveau de plus à traverser pour arriver au même endroit.
--
-- CE QUI REMPLACE QUOI
--   le numéro de lot          -> la compagnie ; il n'y a qu'un import de plan
--                                comptable en préparation à la fois, et le
--                                suivant remplace le précédent
--   ImportLot.SystemeSource   -> ImportPlanComptable.SystemeSource (par ligne :
--                                même valeur partout, mais plus de table)
--   ImportLot.NomFichier      -> staging.ImportFiles, le registre de TOUS les
--                                imports, par ImportPlanComptable.ImportFileId
--   les compteurs Nb*         -> calculés à la lecture, plus stockés : un
--                                compteur qu'on met à jour finit par mentir
--   ImportLot.Statut          -> déduit : une ligne est appliquée quand elle
--                                porte un PlanComptableId
--   ImportLot.AppliqueLe/Par  -> sur la ligne, au moment où elle est appliquée
--
-- s0751OuvrirImportLot et s0754GetImportLots disparaissent : il n'y a plus de
-- lot à ouvrir ni de liste à parcourir. s0752 fait tout en un appel.
--
-- Vérifié avant d'écrire : TypeDonnees valait toujours 'PLAN_COMPTABLE'. Ce
-- rail ne servait que le plan comptable, sa suppression n'atteint rien d'autre.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) La table des lignes reçoit ce que l'entête portait
-- -----------------------------------------------------------------------------
IF COL_LENGTH('staging.ImportPlanComptable', 'SystemeSource') IS NULL
    ALTER TABLE staging.ImportPlanComptable ADD [SystemeSource] VARCHAR(20) NULL;
GO
IF COL_LENGTH('staging.ImportPlanComptable', 'ImportFileId') IS NULL
    ALTER TABLE staging.ImportPlanComptable ADD [ImportFileId] INT NULL;
GO
IF COL_LENGTH('staging.ImportPlanComptable', 'AppliqueLe') IS NULL
    ALTER TABLE staging.ImportPlanComptable ADD [AppliqueLe] DATETIME NULL;
GO
IF COL_LENGTH('staging.ImportPlanComptable', 'AppliquePar') IS NULL
    ALTER TABLE staging.ImportPlanComptable ADD [AppliquePar] INT NULL;
GO

-- Ce qui est déjà en préparation garde son origine : on la recopie depuis
-- l'entête avant de la supprimer.
UPDATE p
   SET p.[SystemeSource] = l.[SystemeSource],
       p.[ImportFileId]  = l.[ImportFileId]
  FROM staging.ImportPlanComptable p
  JOIN staging.ImportLot l ON l.[Id] = p.[LotId]
 WHERE p.[SystemeSource] IS NULL;
GO

-- Un seul import de plan comptable par compagnie : si des extractions
-- successives en ont laissé plusieurs, on ne conserve que le dernier.
;WITH doublons AS (
    SELECT p.[Id],
           DENSE_RANK() OVER (PARTITION BY p.[CompanyGUID] ORDER BY p.[LotId] DESC) AS rang
      FROM staging.ImportPlanComptable p
)
DELETE FROM staging.ImportPlanComptable
 WHERE [Id] IN (SELECT [Id] FROM doublons WHERE rang > 1);
GO
-- -----------------------------------------------------------------------------
-- 4) s0753GetPlanComptableStaging — la cle apparait dans la liste
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0753GetPlanComptableStaging]
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
    WHERE p.[CompanyGUID] = @CompanyGUID
      AND p.[CompanyGUID] = @CompanyGUID
      AND (@Statut IS NULL OR p.[Statut] = @Statut)
    ORDER BY p.[LigneNo];
END
GO

-- -----------------------------------------------------------------------------
-- 7) s0756GetCorrespondances — la proposition de l'IA vient s'ajouter
--
--    L'ordre de preference reste : ce qui est decide, puis ce que le
--    chargement a reconnu, puis le nom, puis l'IA. L'IA ne passe jamais
--    devant une correspondance etablie sur le numero ou le nom.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0756GetCorrespondances]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Filtre      VARCHAR(20) = NULL,
    @Top         INT = 1000
AS
BEGIN
    SET NOCOUNT ON;

        -- Le système d'origine vit désormais sur les lignes : c'est la même valeur
    -- pour toutes celles d'un même import, et cela évite une table d'entête
    -- dont c'était le seul contenu utile.
    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);

    ;WITH src AS (
        SELECT p.[Id] AS StagingId, p.[LigneNo],
               p.[CleSource], p.[TypeCle],
               p.[Compte], p.[Nom], p.[TypeNormalise], p.[Solde],
               p.[Statut] AS StatutChargement,
               p.[PlanComptableId] AS ProposeAuChargement,
               p.[ProposeIAId], p.[ProposeIAConfiance], p.[ProposeIARaison]
          FROM staging.ImportPlanComptable p
         WHERE p.[CompanyGUID] = @CompanyGUID
           AND p.[CompanyGUID] = @CompanyGUID
           AND p.[Statut] IN ('OK', 'EXISTE')
    )
    SELECT TOP (@Top)
        s.StagingId, s.LigneNo, s.CleSource, s.TypeCle,
        s.Compte, s.Nom, s.TypeNormalise, s.Solde, s.StatutChargement,

        c.[Id]              AS CorrespondanceId,
        c.[Action],
        c.[PlanComptableId] AS DecidePlanComptableId,
        c.[CompteCible],
        c.[NomCible],
        c.[Note],

        COALESCE(c.[PlanComptableId], s.ProposeAuChargement, n.[Id], s.[ProposeIAId]) AS ProposeId,
        CASE
            WHEN c.[Id] IS NOT NULL                THEN 'DECIDE'
            WHEN s.ProposeAuChargement IS NOT NULL AND s.TypeCle = 'NUMERO' THEN 'PROPOSE_NUMERO'
            WHEN s.ProposeAuChargement IS NOT NULL THEN 'PROPOSE_NOM'
            WHEN n.[Id] IS NOT NULL                THEN 'PROPOSE_NOM'
            WHEN s.[ProposeIAId] IS NOT NULL       THEN 'PROPOSE_IA'
            ELSE 'AUCUN'
        END AS Origine,

        pc.[Compte] AS ProposeCompte,
        pc.[Nom]    AS ProposeNom,

        -- La classe du compte propose : deux comptes peuvent porter des noms
        -- voisins et ne pas vivre au meme endroit des etats financiers.
        pcl.[Id]          AS ProposeClasseId,
        pcl.[Code]        AS ProposeClasse,
        pcl.[Description] AS ProposeClasseNom,

        s.[ProposeIAConfiance] AS IAConfiance,
        s.[ProposeIARaison]    AS IARaison,
        ia.[Compte]            AS IACompte,
        ia.[Nom]               AS IANom,
        icl.[Code]             AS IAClasse,
        icl.[Description]      AS IAClasseNom
    FROM src s
    LEFT JOIN staging.CorrespondanceCompte c
           ON c.[CompanyGUID] = @CompanyGUID
          AND c.[SystemeSource] = @Systeme
          AND c.[CleSource] = s.CleSource
    -- Meme regle qu'au chargement : les quatre libelles du plan sont
    -- confrontes au nom d'origine, quelle que soit la langue du fichier.
    OUTER APPLY (
        SELECT TOP 1 p2.[Id]
          FROM dbo.T121PlanComptable p2
         CROSS APPLY (VALUES (p2.[Nom]), (p2.[NomFr]), (p2.[NomEn]), (p2.[NomEs])) AS l([Libelle])
         WHERE s.ProposeAuChargement IS NULL
           AND p2.[CompanyGUID] = @CompanyGUID
           AND ISNULL(p2.[Actif], 1) = 1
           AND UPPER(LTRIM(RTRIM(l.[Libelle]))) = UPPER(LTRIM(RTRIM(s.Nom)))
         ORDER BY p2.[Compte]
    ) n
    LEFT JOIN dbo.T121PlanComptable pc
           ON pc.[Id] = COALESCE(c.[PlanComptableId], s.ProposeAuChargement, n.[Id], s.[ProposeIAId])
    LEFT JOIN dbo.T120PlanComptable_Classe pcl ON pcl.[Id] = pc.[ClasseId]
    LEFT JOIN dbo.T121PlanComptable ia
           ON ia.[Id] = s.[ProposeIAId]
    LEFT JOIN dbo.T120PlanComptable_Classe icl ON icl.[Id] = ia.[ClasseId]
    WHERE (@Filtre IS NULL
           OR (@Filtre = 'DECIDE'    AND c.[Id] IS NOT NULL)
           OR (@Filtre = 'A_DECIDER' AND c.[Id] IS NULL))
    ORDER BY s.LigneNo;
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
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = NULL,
    @Decisions   NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

        -- Le système d'origine vit désormais sur les lignes : c'est la même valeur
    -- pour toutes celles d'un même import, et cela évite une table d'entête
    -- dont c'était le seul contenu utile.
    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);

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

    EXEC dbo.s0758StatsCorrespondance @CompanyGUID = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 7) s0758StatsCorrespondance — sur la cle
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0758StatsCorrespondance]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

        -- Le système d'origine vit désormais sur les lignes : c'est la même valeur
    -- pour toutes celles d'un même import, et cela évite une table d'entête
    -- dont c'était le seul contenu utile.
    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);;WITH src AS (
        SELECT p.[CleSource]
          FROM staging.ImportPlanComptable p
         WHERE p.[CompanyGUID] = @CompanyGUID
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
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

        -- Le système d'origine vit désormais sur les lignes : c'est la même valeur
    -- pour toutes celles d'un même import, et cela évite une table d'entête
    -- dont c'était le seul contenu utile.
    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);

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
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] IN ('OK', 'EXISTE')
       AND p.[PlanComptableId] IS NOT NULL
       AND NOT EXISTS (
            SELECT 1 FROM staging.CorrespondanceCompte c
             WHERE c.[CompanyGUID] = @CompanyGUID
               AND c.[SystemeSource] = @Systeme
               AND c.[CleSource] = p.[CleSource]);

    EXEC dbo.s0758StatsCorrespondance @CompanyGUID = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0761EnregistrerPropositionsIA
--
--    @Propositions : [{ "CleSource": "...", "Compte": "6400",
--                       "Confiance": 85, "Raison": "..." }]
--
--    Retourne ce qui a ete retenu et ce qui a ete ecarte, avec le motif.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0761EnregistrerPropositionsIA]
    @CompanyGUID  UNIQUEIDENTIFIER,
    @Propositions NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @d TABLE (
        CleSource NVARCHAR(200),
        Compte    VARCHAR(20),
        Confiance TINYINT,
        Raison    NVARCHAR(300)
    );

    INSERT INTO @d (CleSource, Compte, Confiance, Raison)
    SELECT LTRIM(RTRIM(j.CleSource)),
           LTRIM(RTRIM(j.Compte)),
           CASE WHEN j.Confiance IS NULL THEN NULL
                WHEN j.Confiance < 0   THEN 0
                WHEN j.Confiance > 100 THEN 100
                ELSE j.Confiance END,
           LEFT(LTRIM(RTRIM(ISNULL(j.Raison, ''))), 300)
      FROM OPENJSON(@Propositions)
           WITH (
              CleSource NVARCHAR(200) '$.CleSource',
              Compte    VARCHAR(20)   '$.Compte',
              Confiance INT           '$.Confiance',
              Raison    NVARCHAR(300) '$.Raison'
           ) j
     WHERE ISNULL(LTRIM(RTRIM(j.CleSource)), '') <> ''
       AND ISNULL(LTRIM(RTRIM(j.Compte)), '')    <> '';

    -- Le compte propose, avec sa nature, pour cette compagnie seulement.
    ;WITH cible AS (
        SELECT pc.[Id], pc.[Compte],
               dbo.fn_NatureCompte(cl.[Code]) AS Nature
          FROM dbo.T121PlanComptable pc
          JOIN dbo.T120PlanComptable_Classe cl ON cl.[Id] = pc.[ClasseParentId]
         WHERE pc.[CompanyGUID] = @CompanyGUID
           AND ISNULL(pc.[Actif], 1) = 1
    ),
    retenu AS (
        SELECT p.[Id] AS StagingId, c.[Id] AS PlanId,
               d.Confiance, d.Raison
          FROM staging.ImportPlanComptable p
          JOIN @d d  ON d.CleSource = p.[CleSource]
          JOIN cible c ON c.[Compte] = d.Compte
         WHERE p.[CompanyGUID] = @CompanyGUID
           AND p.[CompanyGUID] = @CompanyGUID
           -- La nature doit s'accorder. Inconnue d'un cote ou de l'autre,
           -- on laisse passer plutot que d'ecarter a tort.
           AND (c.Nature IS NULL
                OR p.[TypeNormalise] IS NULL
                OR c.Nature = p.[TypeNormalise])
    )
    UPDATE p
       SET p.[ProposeIAId]        = r.PlanId,
           p.[ProposeIAConfiance] = r.Confiance,
           p.[ProposeIARaison]    = r.Raison,
           p.[ProposeIALe]        = GETDATE()
      FROM staging.ImportPlanComptable p
     INNER JOIN retenu r ON r.StagingId = p.[Id];

    DECLARE @retenues INT = @@ROWCOUNT;
    DECLARE @recues   INT = (SELECT COUNT(*) FROM @d);

    SELECT @recues                AS Recues,
           @retenues              AS Retenues,
           @recues - @retenues    AS Ecartees;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0762EffacerPropositionsIA — repartir a zero sur un lot
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0762EffacerPropositionsIA]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE staging.ImportPlanComptable
       SET [ProposeIAId] = NULL, [ProposeIAConfiance] = NULL,
           [ProposeIARaison] = NULL, [ProposeIALe] = NULL
     WHERE [CompanyGUID] = @CompanyGUID AND [CompanyGUID] = @CompanyGUID;

    SELECT @@ROWCOUNT AS Effacees;
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0763GetComptesAProposer — ce qu'on soumet au modele
--
--    Seulement ce qui reste a decider : inutile de payer pour ce qui est
--    deja tranche ou deja reconnu par le numero.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0763GetComptesAProposer]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

        -- Le système d'origine vit désormais sur les lignes : c'est la même valeur
    -- pour toutes celles d'un même import, et cela évite une table d'entête
    -- dont c'était le seul contenu utile.
    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);

    SELECT p.[CleSource], p.[Compte], p.[Nom], p.[TypeNormalise], p.[TypeSource]
      FROM staging.ImportPlanComptable p
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] IN ('OK', 'EXISTE')
       AND p.[PlanComptableId] IS NULL          -- pas deja reconnu au chargement
       AND NOT EXISTS (
            SELECT 1 FROM staging.CorrespondanceCompte c
             WHERE c.[CompanyGUID] = @CompanyGUID
               AND c.[SystemeSource] = @Systeme
               AND c.[CleSource] = p.[CleSource])
     ORDER BY p.[LigneNo];
END
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
    @CompanyGUID   UNIQUEIDENTIFIER,
    @SystemeSource VARCHAR(20),
    @ImportFileId  INT = NULL,
    @Lignes        NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50302, 'Aucune compagnie : impossible de déposer un plan comptable.', 1;

    -- Un fichier d'une autre compagnie n'a rien à faire ici : le lien doit
    -- rester vérifiable, sinon il ne vaut rien.
    IF @ImportFileId IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM staging.ImportFiles
                        WHERE [Id] = @ImportFileId
                          AND ([CompanyGUID] IS NULL OR [CompanyGUID] = @CompanyGUID))
        THROW 50367, 'Le fichier d''importation n''appartient pas à cette compagnie.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.ImportPlanComptable WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.ImportPlanComptable
        ([CompanyGUID], [SystemeSource], [ImportFileId], [LigneNo],
         [CompteSource], [NomSource], [TypeSource], [SoldeSource], [SensSource],
         [Compte], [Nom], [TypeNormalise], [Solde], [Sens],
         [CleSource], [TypeCle])
    SELECT
        @CompanyGUID, @SystemeSource, @ImportFileId, j.LigneNo,
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
     WHERE [CompanyGUID] = @CompanyGUID
       AND [CleSource] IS NULL;

    -- Le message nomme la cle et la ligne d'origine : sans cela un doublon
    -- annonce reste indemontrable pour celui qui relit son fichier.
    ;WITH d AS (
        SELECT [Id],
               ROW_NUMBER() OVER (PARTITION BY [CleSource] ORDER BY [LigneNo]) AS rn,
               MIN([LigneNo])  OVER (PARTITION BY [CleSource])                 AS PremiereLigne
          FROM staging.ImportPlanComptable
         WHERE [CompanyGUID] = @CompanyGUID AND [Statut] = 'OK'
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
     WHERE p.[CompanyGUID] = @CompanyGUID
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
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] = 'OK'
       AND p.[TypeCle] = 'NOM';

    COMMIT TRANSACTION;

    -- Le compte rendu se calcule à la lecture. Rien à tenir à jour, donc rien
    -- qui puisse diverger de ce que la table contient vraiment.
    SELECT COUNT(*)                                                                    AS [NbLignesLues],
           SUM(CASE WHEN [Statut] IN ('OK', 'EXISTE') THEN 1 ELSE 0 END)                AS [NbLignesRetenues],
           SUM(CASE WHEN [Statut] IN ('INVALIDE', 'DOUBLON_FICHIER') THEN 1 ELSE 0 END) AS [NbAnomalies],
           'CHARGE'                                                                     AS [Statut]
      FROM staging.ImportPlanComptable
     WHERE [CompanyGUID] = @CompanyGUID;
END

GO
GO

-- -----------------------------------------------------------------------------
-- s0755ViderImportPlan — remplace s0755SupprimerImportLot
--
-- On ne supprime plus « un lot » : on vide le plan comptable en préparation de
-- la compagnie. Le refus, lui, ne change pas de raison — ce qui est déjà passé
-- au plan ne se reprend pas en effaçant sa trace.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0755ViderImportPlan]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50304, 'Aucune compagnie : refus de vider le plan comptable en préparation.', 1;

    IF EXISTS (SELECT 1 FROM staging.ImportPlanComptable
                WHERE [CompanyGUID] = @CompanyGUID AND [AppliqueLe] IS NOT NULL)
        THROW 50303, 'Cet import a été appliqué au plan comptable : il ne peut plus être supprimé.', 1;

    DELETE FROM staging.ImportPlanComptable WHERE [CompanyGUID] = @CompanyGUID;

    SELECT @@ROWCOUNT AS [NbSupprimees];
END
GO

-- -----------------------------------------------------------------------------
-- 2) s0766GetAAppliquer — l'etat du lot avant d'appliquer
--
--    Un jeu de resultats par question : ce qui reste a faire, et le compte
--    rendu de ce qui est deja regle.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0766GetAAppliquer]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

        DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);

    -- Une table, pas une CTE : trois SELECT suivent, et une CTE ne vit que
    -- le temps de la requete qui la suit immediatement.
    DECLARE @src TABLE (
        LigneNo         INT,
        CleSource       NVARCHAR(400),
        Nom             NVARCHAR(400),
        TypeNormalise   VARCHAR(20),
        Solde           DECIMAL(18,2),
        [Action]        VARCHAR(10),
        PlanComptableId INT,
        CompteCible     VARCHAR(20),
        NomCible        NVARCHAR(400)
    );

    INSERT INTO @src
    SELECT p.[LigneNo], p.[CleSource], p.[Nom], p.[TypeNormalise], p.[Solde],
           c.[Action], c.[PlanComptableId], c.[CompteCible], c.[NomCible]
      FROM staging.ImportPlanComptable p
      LEFT JOIN staging.CorrespondanceCompte c
             ON c.[CompanyGUID] = @CompanyGUID
            AND c.[SystemeSource] = @Systeme
            AND c.[CleSource] = p.[CleSource]
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] IN ('OK', 'EXISTE');

    -- 1er jeu : les comptes a creer qui ne le sont pas encore
    SELECT [LigneNo], [CleSource], [Nom], [TypeNormalise],
           ISNULL(NULLIF([NomCible], ''), [Nom]) AS NomPropose,
           [CompteCible]
      FROM @src
     WHERE [Action] = 'CREER'
       AND [PlanComptableId] IS NULL
     ORDER BY [LigneNo];

    -- 2e jeu : le decompte
    SELECT
        SUM(CASE WHEN [Action] = 'CREER'   AND [PlanComptableId] IS NULL     THEN 1 ELSE 0 END) AS ACreer,
        SUM(CASE WHEN [Action] = 'CREER'   AND [PlanComptableId] IS NOT NULL THEN 1 ELSE 0 END) AS DejaCrees,
        SUM(CASE WHEN [Action] = 'LIER'                                       THEN 1 ELSE 0 END) AS Lies,
        SUM(CASE WHEN [Action] = 'IGNORER'                                    THEN 1 ELSE 0 END) AS Ignores,
        SUM(CASE WHEN [Action] IS NULL                                        THEN 1 ELSE 0 END) AS ADecider,
        COUNT(*)                                                                                AS Total
      FROM @src;

    -- 3e jeu : l'import lui-même. Plus d'entête à lire, alors on le
    -- reconstitue — le nom du fichier vient du registre, le statut se déduit de
    -- ce qui reste à appliquer.
    SELECT TOP 1
           p.[ImportFileId]                      AS [Id],
           ISNULL(f.[OriginalName], N'—')        AS [NomFichier],
           p.[SystemeSource],
           CASE WHEN EXISTS (SELECT 1 FROM staging.ImportPlanComptable x
                              WHERE x.[CompanyGUID] = @CompanyGUID
                                AND x.[Statut] IN ('OK', 'EXISTE')
                                AND x.[AppliqueLe] IS NULL)
                THEN 'CHARGE' ELSE 'APPLIQUE' END AS [Statut],
           (SELECT MAX([AppliqueLe]) FROM staging.ImportPlanComptable
             WHERE [CompanyGUID] = @CompanyGUID)  AS [AppliqueLe]
      FROM staging.ImportPlanComptable p
      LEFT JOIN staging.ImportFiles f ON f.[Id] = p.[ImportFileId]
     WHERE p.[CompanyGUID] = @CompanyGUID
     ORDER BY p.[Id];
END

GO
GO

-- -----------------------------------------------------------------------------
-- 3) s0767AppliquerPlanComptable — la creation
--
--    @Lignes : [{ "CleSource": "...", "ClasseId": 980,
--                 "Compte": "1060" | "", "Nom": "..." }]
--
--    Le numero est facultatif : laisse vide, il est attribue dans la plage
--    de la sous-classe, de preference sur une dizaine ronde.
--
--    Tout ou rien : une seule ligne fautive et rien n'est cree. On ne veut
--    pas d'un plan comptable a moitie repris.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0767AppliquerPlanComptable]
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = NULL,
    @Lignes      NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

        DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);

    DECLARE @d TABLE (
        Rang      INT IDENTITY(1,1),
        CleSource NVARCHAR(400),
        ClasseId  INT,
        Compte    VARCHAR(20),
        Nom       NVARCHAR(400)
    );

    INSERT INTO @d (CleSource, ClasseId, Compte, Nom)
    SELECT LTRIM(RTRIM(j.CleSource)), j.ClasseId,
           NULLIF(LTRIM(RTRIM(ISNULL(j.Compte, ''))), ''),
           NULLIF(LTRIM(RTRIM(ISNULL(j.Nom, ''))), '')
      FROM OPENJSON(@Lignes)
           WITH (
              CleSource NVARCHAR(400) '$.CleSource',
              ClasseId  INT           '$.ClasseId',
              Compte    VARCHAR(20)   '$.Compte',
              Nom       NVARCHAR(400) '$.Nom'
           ) j
     WHERE ISNULL(LTRIM(RTRIM(j.CleSource)), '') <> '';

    IF NOT EXISTS (SELECT 1 FROM @d)
        THROW 50332, 'Aucun compte à créer.', 1;

    -- ── Controles prealables, avant d'ecrire quoi que ce soit ────────────────
    DECLARE @faute NVARCHAR(400);

    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » : aucune classe choisie.'
      FROM @d d WHERE d.ClasseId IS NULL;
    IF @faute IS NOT NULL THROW 50333, @faute, 1;

    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » : cette classe n''appartient pas à votre plan.'
      FROM @d d
     WHERE NOT EXISTS (SELECT 1 FROM dbo.T120PlanComptable_Classe sc
                        WHERE sc.[Id] = d.ClasseId
                          AND sc.[CompanyGUID] = @CompanyGUID
                          AND sc.[Niveau] = 2);
    IF @faute IS NOT NULL THROW 50334, @faute, 1;

    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » : le nom du compte est vide.'
      FROM @d d WHERE d.Nom IS NULL;
    IF @faute IS NOT NULL THROW 50335, @faute, 1;

    -- Un numero fourni doit etre un nombre, tomber dans la plage de sa classe
    -- et etre libre. Le plan se lit par ses numeros : un numero hors plage
    -- range le compte au mauvais endroit dans tous les etats financiers.
    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » : « ' + d.Compte +
                          N' » n''est pas un numéro.'
      FROM @d d WHERE d.Compte IS NOT NULL AND TRY_CAST(d.Compte AS INT) IS NULL;
    IF @faute IS NOT NULL THROW 50336, @faute, 1;

    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » : le numéro ' + d.Compte +
                          N' est hors de la plage ' + CAST(sc.[NumeroDebut] AS NVARCHAR(10)) +
                          N'-' + CAST(sc.[NumeroFin] AS NVARCHAR(10)) + N' de la classe ' + sc.[Code] + N'.'
      FROM @d d
      JOIN dbo.T120PlanComptable_Classe sc ON sc.[Id] = d.ClasseId
     WHERE d.Compte IS NOT NULL
       AND TRY_CAST(d.Compte AS INT) NOT BETWEEN sc.[NumeroDebut] AND sc.[NumeroFin];
    IF @faute IS NOT NULL THROW 50337, @faute, 1;

    SELECT TOP 1 @faute = N'Le numéro ' + d.Compte + N' est déjà utilisé dans votre plan.'
      FROM @d d
     WHERE d.Compte IS NOT NULL
       AND EXISTS (SELECT 1 FROM dbo.T121PlanComptable pc
                    WHERE pc.[CompanyGUID] = @CompanyGUID AND pc.[Compte] = d.Compte);
    IF @faute IS NOT NULL THROW 50338, @faute, 1;

    SELECT TOP 1 @faute = N'Le numéro ' + d.Compte + N' est demandé deux fois.'
      FROM @d d
     WHERE d.Compte IS NOT NULL
     GROUP BY d.Compte HAVING COUNT(*) > 1;
    IF @faute IS NOT NULL THROW 50339, @faute, 1;

    -- ── La creation ─────────────────────────────────────────────────────────
    DECLARE @crees TABLE (CleSource NVARCHAR(400), Compte VARCHAR(20), Nom NVARCHAR(400), PlanId INT);

    BEGIN TRANSACTION;

    DECLARE @rang INT = 1, @max INT = (SELECT MAX(Rang) FROM @d);

    WHILE @rang <= @max
    BEGIN
        DECLARE @cle NVARCHAR(400), @classe INT, @num VARCHAR(20), @nom NVARCHAR(400);

        SET @cle = NULL; SET @classe = NULL; SET @num = NULL; SET @nom = NULL;

        SELECT @cle = CleSource, @classe = ClasseId, @num = Compte, @nom = Nom
          FROM @d WHERE Rang = @rang;

        IF @cle IS NULL BEGIN SET @rang += 1; CONTINUE; END

        -- Deja cree lors d'un passage precedent : on passe.
        IF EXISTS (SELECT 1 FROM staging.CorrespondanceCompte c
                    WHERE c.[CompanyGUID] = @CompanyGUID
                      AND c.[SystemeSource] = @Systeme
                      AND c.[CleSource] = @cle
                      AND c.[PlanComptableId] IS NOT NULL)
        BEGIN
            SET @rang += 1;
            CONTINUE;
        END

        DECLARE @debut INT, @fin INT, @parent INT, @typeBilan VARCHAR(10), @sens VARCHAR(10);
        SELECT @debut = sc.[NumeroDebut], @fin = sc.[NumeroFin], @parent = sc.[ParentId],
               @typeBilan = sc.[TypeBilan], @sens = sc.[Sens]
          FROM dbo.T120PlanComptable_Classe sc WITH (UPDLOCK, HOLDLOCK)
         WHERE sc.[Id] = @classe;

        -- Numero non fourni : le premier libre de la plage, dizaines rondes
        -- d'abord -- un plan comptable se lit mieux en 1060 qu'en 1051.
        IF @num IS NULL
        BEGIN
            ;WITH n AS (
                SELECT TOP (@fin - @debut + 1)
                       @debut + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS INT) - 1 AS v
                  FROM sys.all_objects
            )
            SELECT TOP 1 @num = CAST(n.v AS VARCHAR(20))
              FROM n
             WHERE NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable pc WITH (UPDLOCK, HOLDLOCK)
                                WHERE pc.[CompanyGUID] = @CompanyGUID
                                  AND TRY_CAST(pc.[Compte] AS INT) = n.v)
               -- ...ni un numero qu'une autre ligne du meme envoi reclame :
               -- l'attribution automatique ne doit pas prendre la place d'un
               -- numero impose plus bas dans la liste.
               AND NOT EXISTS (SELECT 1 FROM @d d2
                                WHERE TRY_CAST(d2.Compte AS INT) = n.v)
             ORDER BY CASE WHEN n.v % 10 = 0 THEN 0 ELSE 1 END, n.v;

            IF @num IS NULL
            BEGIN
                SET @faute = N'« ' + @cle + N' » : la plage de numéros de cette classe est pleine.';
                THROW 50340, @faute, 1;
            END
        END

        -- T121PlanComptable.Id n'est pas une identite.
        DECLARE @newId INT;
        SELECT @newId = ISNULL(MAX([Id]), 0) + 1
          FROM dbo.T121PlanComptable WITH (UPDLOCK, HOLDLOCK);

        INSERT INTO dbo.T121PlanComptable
            ([Id], [Compte], [Nom], [ClasseId], [ClasseParentId], [TypeBilan], [Sens],
             [Ordre], [Actif], [Systeme], [CompanyGUID], [NomFr])
        VALUES
            (@newId, @num, @nom, @classe, @parent, @typeBilan, @sens,
             CAST(@num AS INT), 1, 0, @CompanyGUID, @nom);

        UPDATE staging.CorrespondanceCompte
           SET [PlanComptableId] = @newId,
               [CompteCible]     = @num,
               [NomCible]        = @nom,
               [Modified]        = GETDATE(),
               [ModifiedBy]      = @UserId
         WHERE [CompanyGUID] = @CompanyGUID
           AND [SystemeSource] = @Systeme
           AND [CleSource] = @cle;

        INSERT INTO @crees (CleSource, Compte, Nom, PlanId)
        VALUES (@cle, @num, @nom, @newId);

        SET @rang += 1;
    END

    -- Il n'y a plus d'entête à marquer « appliqué » : on marque les LIGNES,
    -- chacune au moment où elle est réellement passée au plan. C'est plus
    -- précis que l'ancien drapeau tout-ou-rien, qui ne disait pas lesquelles.
    UPDATE p
       SET p.[AppliqueLe]  = GETDATE(),
           p.[AppliquePar] = @UserId
      FROM staging.ImportPlanComptable p
      JOIN staging.CorrespondanceCompte c
        ON c.[CompanyGUID]   = @CompanyGUID
       AND c.[SystemeSource] = @Systeme
       AND c.[CleSource]     = p.[CleSource]
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[AppliqueLe] IS NULL
       AND p.[Statut] IN ('OK', 'EXISTE')
       AND (c.[Action] <> 'CREER' OR c.[PlanComptableId] IS NOT NULL);

    COMMIT TRANSACTION;

    SELECT CleSource, Compte, Nom, PlanId FROM @crees ORDER BY Compte;
END

GO
GO

CREATE OR ALTER PROCEDURE [dbo].[s0771ControleBalancePlan]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Le plan comptable en préparation pour la compagnie. Il n'y en a qu'un :
    -- plus de numéro de lot à retenir.
    DECLARE @Systeme VARCHAR(20), @FichierPlan NVARCHAR(260), @DatePlan DATETIME;

    SELECT TOP 1 @Systeme     = p.[SystemeSource],
                 @FichierPlan = f.[OriginalName],
                 @DatePlan    = p.[Created]
      FROM staging.ImportPlanComptable p
      LEFT JOIN staging.ImportFiles f ON f.[Id] = p.[ImportFileId]
     WHERE p.[CompanyGUID] = @CompanyGUID
     ORDER BY p.[Id] DESC;

    DECLARE @plan TABLE (
        CleSource     NVARCHAR(400),
        Compte        VARCHAR(20),
        Nom           NVARCHAR(400),
        NomCle        NVARCHAR(400),
        TypeNormalise VARCHAR(20),
        Solde         DECIMAL(18,2)
    );

    INSERT INTO @plan
    SELECT p.[CleSource], p.[Compte], p.[Nom],
           UPPER(LTRIM(RTRIM(ISNULL(p.[Nom], '')))),
           p.[TypeNormalise], p.[Solde]
      FROM staging.ImportPlanComptable p
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] IN ('OK', 'EXISTE');

    DECLARE @bal TABLE (
        Id          INT,
        Compte      VARCHAR(20),
        Nom         NVARCHAR(400),
        NomCle      NVARCHAR(400),
        Debit       DECIMAL(18,2),
        Credit      DECIMAL(18,2)
    );

    INSERT INTO @bal
    SELECT b.[Id], b.[Compte], b.[Description],
           UPPER(LTRIM(RTRIM(ISNULL(b.[Description], '')))),
           ISNULL(b.[Debit], 0), ISNULL(b.[Credit], 0)
      FROM staging.BalanceVerification b
     WHERE b.[CompanyGUID] = @CompanyGUID;

    -- Chaque ligne de la balance et le compte du plan qui lui repond.
    DECLARE @lien TABLE (BalId INT, CleSource NVARCHAR(400));

    INSERT INTO @lien
    SELECT b.Id, m.CleSource
      FROM @bal b
     OUTER APPLY (
        SELECT TOP 1 pl.CleSource
          FROM @plan pl
         WHERE (b.Compte IS NOT NULL AND pl.Compte IS NOT NULL AND pl.Compte = b.Compte)
            OR (b.NomCle <> '' AND pl.NomCle = b.NomCle)
         ORDER BY CASE WHEN b.Compte IS NOT NULL AND pl.Compte = b.Compte THEN 0 ELSE 1 END
     ) m;

    DECLARE @a TABLE (
        Gravite VARCHAR(10),
        Ordre   INT,
        Type    VARCHAR(20),
        Compte  VARCHAR(20),
        Nom     NVARCHAR(400),
        Detail  NVARCHAR(600)
    );

    -- ── Compte de la balance absent du plan ─────────────────────────────────
    --    Erreur s'il porte un solde : ce montant n'aurait nulle part ou aller.
    --    Sans solde, rien ne se perd : simple information.
    INSERT INTO @a
    SELECT CASE WHEN b.Debit - b.Credit = 0 THEN 'INFO' ELSE 'ERREUR' END,
           CASE WHEN b.Debit - b.Credit = 0 THEN 6 ELSE 1 END,
           'ABSENT_PLAN', b.Compte, b.Nom,
           CASE WHEN b.Debit - b.Credit = 0
                THEN N'Absent du plan comptable importé, mais sans solde : rien ne se perd.'
                ELSE N'Absent du plan comptable importé : son solde de ' +
                     FORMAT(ABS(b.Debit - b.Credit), 'N2', 'fr-CA') + N' $ n''aura nulle part où aller.'
           END
      FROM @bal b
      JOIN @lien l ON l.BalId = b.Id
     WHERE l.CleSource IS NULL
       AND @Systeme IS NOT NULL;

    -- ── ERREUR : ignore a l'etape 2, mais porteur d'un solde ────────────────
    INSERT INTO @a
    SELECT 'ERREUR', 2, 'IGNORE_AVEC_SOLDE', b.Compte, b.Nom,
           N'Marqué « Ignorer » à la correspondance, mais porte un solde de ' +
           FORMAT(ABS(b.Debit - b.Credit), 'N2', 'fr-CA') + N' $ : ce montant disparaîtrait de la reprise.'
      FROM @bal b
      JOIN @lien l ON l.BalId = b.Id
      JOIN staging.CorrespondanceCompte c
        ON c.[CompanyGUID] = @CompanyGUID
       AND c.[SystemeSource] = @Systeme
       AND c.[CleSource] = l.CleSource
     WHERE c.[Action] = 'IGNORER'
       AND b.Debit - b.Credit <> 0;

    -- ── ERREUR : compte en double dans la balance ───────────────────────────
    INSERT INTO @a
    SELECT 'ERREUR', 3, 'DOUBLON_BALANCE',
           NULLIF(MAX(ISNULL(b.Compte, '')), ''), MAX(b.Nom),
           N'Apparaît ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' fois dans la balance.'
      FROM @bal b
     GROUP BY COALESCE(b.Compte, b.NomCle)
    HAVING COUNT(*) > 1;

    -- ── VERIFIER : solde de sens contraire a la nature du compte ────────────
    INSERT INTO @a
    SELECT 'VERIFIER', 4, 'SENS', b.Compte, b.Nom,
           N'Compte de nature ' + LOWER(pl.TypeNormalise) + N', mais solde au ' +
           CASE WHEN b.Debit > b.Credit THEN N'débit' ELSE N'crédit' END + N' (' +
           FORMAT(ABS(b.Debit - b.Credit), 'N2', 'fr-CA') + N' $). Normal pour un contre-compte, sinon à vérifier.'
      FROM @bal b
      JOIN @lien l ON l.BalId = b.Id
      JOIN @plan pl ON pl.CleSource = l.CleSource
     WHERE pl.TypeNormalise IS NOT NULL
       AND b.Debit <> b.Credit
       AND (CASE WHEN pl.TypeNormalise IN ('ACTIF', 'CHARGE') THEN 'DEBIT' ELSE 'CREDIT' END)
        <> (CASE WHEN b.Debit > b.Credit THEN 'DEBIT' ELSE 'CREDIT' END);

    -- ── VERIFIER : solde du plan different de celui de la balance ───────────
    INSERT INTO @a
    SELECT 'VERIFIER', 5, 'SOLDE', b.Compte, b.Nom,
           N'Le plan annonce ' + FORMAT(ABS(pl.Solde), 'N2', 'fr-CA') + N' $, la balance ' +
           FORMAT(ABS(b.Debit - b.Credit), 'N2', 'fr-CA') + N' $. Normal si les deux exports ne sont pas à la même date.'
      FROM @bal b
      JOIN @lien l ON l.BalId = b.Id
      JOIN @plan pl ON pl.CleSource = l.CleSource
     WHERE pl.Solde IS NOT NULL
       AND ABS(ABS(pl.Solde) - ABS(b.Debit - b.Credit)) > 0.01;

    -- ── INFO : compte du plan absent de la balance ──────────────────────────
    INSERT INTO @a
    SELECT 'INFO', 7, 'ABSENT_BALANCE', pl.Compte, pl.Nom,
           N'Au plan comptable, mais absent de la balance — le plus souvent un compte sans solde.'
      FROM @plan pl
     WHERE NOT EXISTS (SELECT 1 FROM @lien l WHERE l.CleSource = pl.CleSource);

    -- ── 1er jeu : le contexte de la comparaison ─────────────────────────────
    SELECT @Systeme     AS SystemePlan,
           @FichierPlan AS FichierPlan,
           @DatePlan    AS DatePlan,
           (SELECT COUNT(*) FROM @plan) AS ComptesPlan,
           (SELECT COUNT(*) FROM @bal)  AS ComptesBalance,
           (SELECT COUNT(*) FROM @lien WHERE CleSource IS NOT NULL) AS ComptesRapproches,
           (SELECT TOP 1 [NomFichier] FROM staging.BalanceVerification
             WHERE [CompanyGUID] = @CompanyGUID ORDER BY [Id] DESC) AS FichierBalance,
           (SELECT COUNT(*) FROM @a WHERE Gravite = 'ERREUR')   AS Erreurs,
           (SELECT COUNT(*) FROM @a WHERE Gravite = 'VERIFIER') AS AVerifier,
           (SELECT COUNT(*) FROM @a WHERE Gravite = 'INFO')     AS Infos;

    -- ── 2e jeu : les incoherences, les plus graves d'abord ──────────────────
    SELECT Gravite, Type, Compte, Nom, Detail
      FROM @a
     ORDER BY Ordre, Nom;
END

GO
GO



-- -----------------------------------------------------------------------------
-- 3) Ce qui n'a plus d'objet
--
--    Chaque DROP dans son propre lot : un lot qui mélange un DROP et une
--    référence à l'objet supprimé échoue à la compilation du plan (erreur 8624),
--    avant même d'exécuter la première instruction.
-- -----------------------------------------------------------------------------

-- Il n'y a plus de lot à ouvrir : s0752 reçoit directement l'origine de l'import.
IF OBJECT_ID('dbo.s0751OuvrirImportLot', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[s0751OuvrirImportLot];
GO

-- Il n'y a plus de liste de lots à parcourir : il n'y en a qu'un par compagnie.
IF OBJECT_ID('dbo.s0754GetImportLots', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[s0754GetImportLots];
GO

IF OBJECT_ID('dbo.s0755SupprimerImportLot', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[s0755SupprimerImportLot];
GO

-- La colonne et sa clé étrangère.
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ImportPC_Lot')
    ALTER TABLE staging.ImportPlanComptable DROP CONSTRAINT FK_ImportPC_Lot;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ImportPC_Lot'
            AND object_id = OBJECT_ID('staging.ImportPlanComptable'))
    DROP INDEX IX_ImportPC_Lot ON staging.ImportPlanComptable;
GO

IF COL_LENGTH('staging.ImportPlanComptable', 'LotId') IS NOT NULL
    ALTER TABLE staging.ImportPlanComptable DROP COLUMN [LotId];
GO

-- L'index qui remplace celui du lot : on cherche désormais par compagnie.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ImportPC_Company'
                AND object_id = OBJECT_ID('staging.ImportPlanComptable'))
    CREATE INDEX IX_ImportPC_Company ON staging.ImportPlanComptable ([CompanyGUID], [Statut]);
GO

IF OBJECT_ID('staging.ImportLot', 'U') IS NOT NULL
    DROP TABLE staging.ImportLot;
GO

-- -----------------------------------------------------------------------------
-- 4) Le registre et le vidage oublient le lot
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0787GetImportsCompagnie]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Plus de LEFT JOIN vers le lot : le plan comptable se rattache au registre
    -- par ImportFileId, comme toutes les autres tables de préparation. C'est
    -- précisément ce que le lot empêchait.
    SELECT TOP 100
           f.[Id], f.[TypeImport], f.[OriginalName], f.[FileExtension], f.[FileSize],
           f.[UploadDate], f.[Status], f.[ProcessedRows], f.[ModelUsed],
           (SELECT COUNT(*) FROM staging.PartyImport pi WHERE pi.[ImportFileId] = f.[Id])      AS [NbTiers],
           (SELECT COUNT(*) FROM staging.ProductImport pr WHERE pr.[ImportFileId] = f.[Id])    AS [NbProduits],
           (SELECT COUNT(*) FROM staging.ImportPlanComptable pc WHERE pc.[ImportFileId] = f.[Id]) AS [NbComptes],
           (SELECT COUNT(*) FROM staging.DocumentImport di WHERE di.[ImportFileId] = f.[Id])   AS [NbDocuments],
           (SELECT COUNT(*) FROM staging.SocieteImport si WHERE si.[ImportFileId] = f.[Id])    AS [NbChampsSociete],
           (SELECT COUNT(*) FROM staging.TaxeImport ti WHERE ti.[ImportFileId] = f.[Id])       AS [NbTaux],
           ((SELECT COUNT(*) FROM staging.ModePaiementImport x WHERE x.[ImportFileId] = f.[Id])
          + (SELECT COUNT(*) FROM staging.CategorieSuiviImport x WHERE x.[ImportFileId] = f.[Id])
          + (SELECT COUNT(*) FROM staging.DepartementImport x WHERE x.[ImportFileId] = f.[Id])
          + (SELECT COUNT(*) FROM staging.EmplacementImport x WHERE x.[ImportFileId] = f.[Id])) AS [NbReferences],
           (SELECT COUNT(*) FROM staging.PieceCommercialeImport x WHERE x.[ImportFileId] = f.[Id]) AS [NbPieces],
           (SELECT COUNT(*) FROM staging.PaiementImport x WHERE x.[ImportFileId] = f.[Id])         AS [NbPaiements],
           (SELECT COUNT(*) FROM staging.EcritureImport x WHERE x.[ImportFileId] = f.[Id])         AS [NbEcritures],
           ((SELECT COUNT(*) FROM staging.RapportImport x WHERE x.[ImportFileId] = f.[Id])
          + (SELECT COUNT(*) FROM staging.BalanceAgeeImport x WHERE x.[ImportFileId] = f.[Id]))    AS [NbRapports],
           (SELECT COUNT(*) FROM staging.PieceJointeImport x WHERE x.[ImportFileId] = f.[Id])      AS [NbPiecesJointes],
           (SELECT COUNT(*) FROM staging.ConditionPaiementImport x WHERE x.[ImportFileId] = f.[Id]) AS [NbConditions]
      FROM staging.ImportFiles f
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

    DELETE l
      FROM staging.PieceCommercialeImportLigne l
      JOIN staging.PieceCommercialeImport e ON e.[Id] = l.[EnteteId]
     WHERE e.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (12, 'PieceCommercialeImportLigne', @@ROWCOUNT);

    DELETE x FROM staging.PieceCommercialeImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (13, 'PieceCommercialeImport', @@ROWCOUNT);

    DELETE a
      FROM staging.PaiementImportAffectation a
      JOIN staging.PaiementImport p ON p.[Id] = a.[PaiementId]
     WHERE p.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (14, 'PaiementImportAffectation', @@ROWCOUNT);

    DELETE x FROM staging.PaiementImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (15, 'PaiementImport', @@ROWCOUNT);

    DELETE l
      FROM staging.EcritureImportLigne l
      JOIN staging.EcritureImport e ON e.[Id] = l.[EnteteId]
     WHERE e.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (16, 'EcritureImportLigne', @@ROWCOUNT);

    DELETE x FROM staging.EcritureImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (17, 'EcritureImport', @@ROWCOUNT);

    DELETE l
      FROM staging.RapportImportLigne l
      JOIN staging.RapportImport r ON r.[Id] = l.[RapportId]
     WHERE r.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (18, 'RapportImportLigne', @@ROWCOUNT);

    DELETE x FROM staging.RapportImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (19, 'RapportImport', @@ROWCOUNT);

    DELETE x FROM staging.BalanceAgeeImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (20, 'BalanceAgeeImport', @@ROWCOUNT);

    DELETE x FROM staging.PieceJointeImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (21, 'PieceJointeImport', @@ROWCOUNT);

    DELETE x FROM staging.ConditionPaiementImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (22, 'ConditionPaiementImport', @@ROWCOUNT);

    DELETE pi
      FROM staging.PartyImport pi
      JOIN staging.ImportFiles f ON f.[Id] = pi.[ImportFileId]
     WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (23, 'PartyImport', @@ROWCOUNT);

    DELETE pr
      FROM staging.ProductImport pr
      JOIN staging.ImportFiles f ON f.[Id] = pr.[ImportFileId]
     WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (24, 'ProductImport', @@ROWCOUNT);

    DELETE cd FROM staging.ConnecteurDonnee cd WHERE cd.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (25, 'ConnecteurDonnee', @@ROWCOUNT);

    DELETE cr FROM staging.ConnecteurRun cr WHERE cr.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (26, 'ConnecteurRun', @@ROWCOUNT);

    DELETE bv FROM staging.BalanceVerification bv WHERE bv.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (27, 'BalanceVerification', @@ROWCOUNT);

    DELETE f FROM staging.ImportFiles f WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (28, 'ImportFiles', @@ROWCOUNT);

    COMMIT TRANSACTION;

    SELECT [Table], [Lignes] FROM @Compte WHERE [Lignes] > 0 ORDER BY [Ordre];
    SELECT SUM([Lignes]) AS [Total] FROM @Compte;
END
GO

