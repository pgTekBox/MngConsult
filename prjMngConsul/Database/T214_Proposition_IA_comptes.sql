-- =============================================================================
-- T214 — Proposition de correspondance assistee par l'IA
--
-- Le modele recoit deux listes -- les comptes de l'ancien logiciel et le plan
-- de la compagnie -- et rend une correspondance. Ce qu'il rend est une
-- PROPOSITION : elle se range a cote de la ligne importee, jamais dans
-- staging.CorrespondanceCompte, qui ne contient que des decisions prises.
--
-- Rien de ce que le modele repond n'est cru sur parole :
--
--   1. le compte doit exister au plan de CETTE compagnie et etre actif ;
--   2. sa nature doit s'accorder avec celle du compte d'origine. Sans cette
--      regle, « Tools » -- une depense chez QuickBooks -- se rattache au
--      compte 1580 Outillage, qui est une immobilisation : la depense se
--      trouverait capitalisee sans que rien ne le signale.
--
-- La classe « Impots et elements extraordinaires » echappe au controle de
-- nature : elle porte a la fois des gains et des pertes.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
GO
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) Les colonnes de la proposition
-- -----------------------------------------------------------------------------
IF COL_LENGTH('staging.ImportPlanComptable', 'ProposeIAId') IS NULL
    ALTER TABLE staging.ImportPlanComptable ADD [ProposeIAId] INT NULL;
GO
IF COL_LENGTH('staging.ImportPlanComptable', 'ProposeIAConfiance') IS NULL
    ALTER TABLE staging.ImportPlanComptable ADD [ProposeIAConfiance] TINYINT NULL;
GO
IF COL_LENGTH('staging.ImportPlanComptable', 'ProposeIARaison') IS NULL
    ALTER TABLE staging.ImportPlanComptable ADD [ProposeIARaison] NVARCHAR(300) NULL;
GO
IF COL_LENGTH('staging.ImportPlanComptable', 'ProposeIALe') IS NULL
    ALTER TABLE staging.ImportPlanComptable ADD [ProposeIALe] DATETIME NULL;
GO

-- -----------------------------------------------------------------------------
-- 2) fn_NatureCompte — la nature d'un compte du plan, tiree de sa classe mere
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION [dbo].[fn_NatureCompte] (@ParentCode VARCHAR(20))
RETURNS VARCHAR(20)
AS
BEGIN
    RETURN CASE
        WHEN @ParentCode LIKE 'ACT-%'  THEN 'ACTIF'
        WHEN @ParentCode LIKE 'PAS-%'  THEN 'PASSIF'
        WHEN @ParentCode =    'CP'     THEN 'CAPITAUX'
        WHEN @ParentCode =    'REV'    THEN 'PRODUIT'
        WHEN @ParentCode =    'CDV'    THEN 'CHARGE'
        WHEN @ParentCode LIKE 'CHG-%'  THEN 'CHARGE'
        ELSE NULL                      -- IMP-EXT : gains et pertes melanges
    END;
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
    @LotId        INT,
    @CompanyGUID  UNIQUEIDENTIFIER,
    @Propositions NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM staging.ImportLot
                    WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID)
        THROW 50320, 'Lot d''importation introuvable pour cette compagnie.', 1;

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
         WHERE p.[LotId] = @LotId
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
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE staging.ImportPlanComptable
       SET [ProposeIAId] = NULL, [ProposeIAConfiance] = NULL,
           [ProposeIARaison] = NULL, [ProposeIALe] = NULL
     WHERE [LotId] = @LotId AND [CompanyGUID] = @CompanyGUID;

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
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT [SystemeSource] FROM staging.ImportLot
          WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID);

    IF @Systeme IS NULL
        THROW 50321, 'Lot d''importation introuvable pour cette compagnie.', 1;

    SELECT p.[CleSource], p.[Compte], p.[Nom], p.[TypeNormalise], p.[TypeSource]
      FROM staging.ImportPlanComptable p
     WHERE p.[LotId] = @LotId
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
-- 6) s0764GetPlanPourIA — le plan de la compagnie, en version compacte
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0764GetPlanPourIA]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT pc.[Compte], pc.[Nom], ISNULL(pc.[NomEn], '') AS NomEn,
           dbo.fn_NatureCompte(cl.[Code]) AS Nature,
           sc.[Description] AS Classe
      FROM dbo.T121PlanComptable pc
      JOIN dbo.T120PlanComptable_Classe cl ON cl.[Id] = pc.[ClasseParentId]
      JOIN dbo.T120PlanComptable_Classe sc ON sc.[Id] = pc.[ClasseId]
     WHERE pc.[CompanyGUID] = @CompanyGUID
       AND ISNULL(pc.[Actif], 1) = 1
     ORDER BY pc.[Compte];
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
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @Filtre      VARCHAR(20) = NULL,
    @Top         INT = 1000
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT [SystemeSource] FROM staging.ImportLot
          WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID);

    IF @Systeme IS NULL
        THROW 50310, 'Lot d''importation introuvable pour cette compagnie.', 1;

    ;WITH src AS (
        SELECT p.[Id] AS StagingId, p.[LigneNo],
               p.[CleSource], p.[TypeCle],
               p.[Compte], p.[Nom], p.[TypeNormalise], p.[Solde],
               p.[Statut] AS StatutChargement,
               p.[PlanComptableId] AS ProposeAuChargement,
               p.[ProposeIAId], p.[ProposeIAConfiance], p.[ProposeIARaison]
          FROM staging.ImportPlanComptable p
         WHERE p.[LotId] = @LotId
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
-- 8) Le prompt, range ou vivent les autres : modifiable sans redeployer
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.T0000Parameters WHERE [ParamName] = 'PROMPT_MAPPING_COMPTES')
    INSERT INTO dbo.T0000Parameters ([ParamName], [Value])
    VALUES ('PROMPT_MAPPING_COMPTES', N'');
GO

UPDATE dbo.T0000Parameters
   SET [Value] = N'Tu es comptable et tu prépares la reprise d''un plan comptable vers un autre logiciel.

On te donne deux listes :
  A. les comptes de l''ancien logiciel (nom, nature, type d''origine) ;
  B. le plan comptable de destination (numéro, nom français, nom anglais, nature, classe).

Pour chaque compte de la liste A, indique le compte de la liste B qui lui correspond.

Règles :
- La nature doit concorder. Un compte de charge ne se rattache jamais à un actif, même si les noms se ressemblent. Exemple : « Tools » est une dépense, pas l''immobilisation « Outillage ».
- N''utilise que des numéros présents dans la liste B. N''en invente aucun.
- Si aucun compte de B ne convient vraiment, n''en propose pas : omets la ligne. Une correspondance fausse coûte plus cher qu''une absence de correspondance.
- Les comptes techniques de l''ancien logiciel (Uncategorized, Non classé, Ask My Accountant) n''ont pas de contrepartie : omets-les.
- Confiance : 90-100 le même compte sous un autre nom ; 70-89 un compte clairement équivalent ; 50-69 plausible mais discutable. En dessous de 50, omets la ligne.
- Raison : une phrase courte en français, qui dit pourquoi. Si le choix est discutable, dis-le.

Réponds UNIQUEMENT par un tableau JSON, sans texte autour, sans bloc de code :
[{"CleSource":"<la clé exacte de la liste A>","Compte":"<numéro de la liste B>","Confiance":<0-100>,"Raison":"<une phrase>"}]'
 WHERE [ParamName] = 'PROMPT_MAPPING_COMPTES';
GO

PRINT 'T214_Proposition_IA_comptes.sql : termine.';
GO
