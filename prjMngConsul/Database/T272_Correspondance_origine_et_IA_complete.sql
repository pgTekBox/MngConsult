-- =============================================================================
-- T272 — La grille de correspondance filtre sur l'origine, et l'IA reçoit tout
--
-- 1) s0756 accepte @Origine (DEFAUT | AJOUTE, cf. T271) : on peut ne regarder
--    que les comptes ajoutés après l'ouverture de la société — ce sont ceux
--    qui demandent une vraie décision, les comptes par défaut ayant presque
--    tous un jumeau évident au plan.
--
-- 2) « Proposer avec l'IA » ne lui donnait que « clé | nom | nature | type »
--    d'un côté et « numéro | nom | nom anglais | nature | classe » de l'autre.
--    Le modèle jugeait sur les noms. Il reçoit désormais :
--      A. de chaque compte QuickBooks : la clé, le nom complet « Parent:Enfant »,
--         la nature, le type et le sous-type QuickBooks, l'origine (par défaut
--         ou ajouté, et quand), le solde, la description ;
--      B. de chaque compte du plan : le numéro, le nom, le nom anglais, la
--         nature, la classe de niveau 1, la sous-classe, le sens normal,
--         la description.
--    Le prompt est réécrit pour dire ce que chaque colonne apporte.
--    Le contrôle d'après (s0761 : compte existant, nature concordante) ne
--    change pas.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0756GetCorrespondances]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Filtre      VARCHAR(20) = NULL,   -- DECIDE | A_DECIDER
    @Top         INT = 1000,
    @Origine     VARCHAR(20) = NULL    -- DEFAUT | AJOUTE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);

    ;WITH src AS (
        SELECT p.[Id] AS StagingId, p.[LigneNo],
               p.[CleSource], p.[TypeCle],
               p.[Compte], p.[Nom], p.[TypeNormalise], p.[Solde],
               p.[CompteSource], p.[NomSource], p.[TypeSource], p.[SousTypeSource],
               p.[SoldeSource], p.[SensSource], p.[SystemeSource],
               p.[CreeLe], p.[ModifieLe], p.[Origine], p.[DescriptionSource], p.[SousCompte], p.[NomComplet],
               p.[Anomalie] AS AnomalieChargement,
               p.[Statut] AS StatutChargement,
               p.[PlanComptableId] AS ProposeAuChargement,
               p.[ProposeIAId], p.[ProposeIAConfiance], p.[ProposeIARaison]
          FROM staging.ImportPlanComptable p
         WHERE p.[CompanyGUID] = @CompanyGUID
           AND p.[Statut] IN ('OK', 'EXISTE')
           AND (@Origine IS NULL OR p.[Origine] = @Origine)
    )
    SELECT TOP (@Top)
        s.StagingId, s.LigneNo, s.CleSource, s.TypeCle,
        s.Compte, s.Nom, s.TypeNormalise, s.Solde, s.StatutChargement,
        s.CompteSource, s.NomSource, s.TypeSource, s.SousTypeSource,
        s.SoldeSource, s.SensSource, s.SystemeSource, s.AnomalieChargement,
        s.CreeLe, s.ModifieLe, s.Origine, s.DescriptionSource, s.SousCompte, s.NomComplet,
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
    OUTER APPLY (
        SELECT TOP 1 p2.[Id]
          FROM dbo.T121PlanComptable p2
         CROSS APPLY (VALUES (p2.[Nom]), (p2.[NomFr]), (p2.[NomEn]), (p2.[NomEs])) AS l([Libelle])
         WHERE s.ProposeAuChargement IS NULL
           AND p2.[CompanyGUID] = @CompanyGUID
           AND ISNULL(p2.[Actif], 1) = 1
           AND UPPER(LTRIM(RTRIM(l.[Libelle]))) = UPPER(LTRIM(RTRIM(s.Nom)))
           AND (s.TypeNormalise IS NULL
                OR dbo.fTypeBilanDeNature(s.TypeNormalise) IS NULL
                OR p2.[TypeBilan] = dbo.fTypeBilanDeNature(s.TypeNormalise))
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
-- Ce qu'on soumet au modèle : les comptes encore à décider, avec tout ce que
-- la source en dit. Pas de doublons dans le nom complet : quand QuickBooks
-- n'en donne pas, c'est le nom simple.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0763GetComptesAProposer]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);

    SELECT p.[CleSource], p.[Compte], p.[Nom],
           ISNULL(NULLIF(p.[NomComplet], ''), p.[Nom]) AS NomComplet,
           p.[TypeNormalise], p.[TypeSource], p.[SousTypeSource],
           p.[Origine], p.[CreeLe],
           p.[Solde], p.[SensSource],
           p.[DescriptionSource], p.[SousCompte]
      FROM staging.ImportPlanComptable p
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] IN ('OK', 'EXISTE')
       AND p.[PlanComptableId] IS NULL          -- pas déjà reconnu au chargement
       AND NOT EXISTS (
            SELECT 1 FROM staging.CorrespondanceCompte c
             WHERE c.[CompanyGUID] = @CompanyGUID
               AND c.[SystemeSource] = @Systeme
               AND c.[CleSource] = p.[CleSource])
     ORDER BY p.[LigneNo];
END
GO

-- -----------------------------------------------------------------------------
-- Le plan de la compagnie, tout entier : numéro, libellés, nature, classe de
-- niveau 1, sous-classe, sens normal, description.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0764GetPlanPourIA]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT pc.[Compte], pc.[Nom], ISNULL(pc.[NomEn], '') AS NomEn,
           dbo.fn_NatureCompte(cl.[Code]) AS Nature,
           cl.[Code] + ' - ' + cl.[Description] AS ClasseParent,
           sc.[Description] AS Classe,
           CASE pc.[Sens] WHEN 'D' THEN 'débit' WHEN 'C' THEN 'crédit' ELSE ISNULL(pc.[Sens], '') END AS Sens,
           ISNULL(pc.[Description], '') AS Description
      FROM dbo.T121PlanComptable pc
      JOIN dbo.T120PlanComptable_Classe cl ON cl.[Id] = pc.[ClasseParentId]
      JOIN dbo.T120PlanComptable_Classe sc ON sc.[Id] = pc.[ClasseId]
     WHERE pc.[CompanyGUID] = @CompanyGUID
       AND ISNULL(pc.[Actif], 1) = 1
     ORDER BY pc.[Compte];
END
GO

-- -----------------------------------------------------------------------------
-- Le prompt, réécrit pour les nouvelles colonnes. Il vit dans T0000Parameters :
-- modifiable sans redéployer.
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.T0000Parameters WHERE [ParamName] = 'PROMPT_MAPPING_COMPTES')
    INSERT INTO dbo.T0000Parameters ([ParamName], [Value])
    VALUES ('PROMPT_MAPPING_COMPTES', N'');
GO

UPDATE dbo.T0000Parameters
   SET [Value] = N'Tu es comptable au Québec et tu prépares la reprise d''un plan comptable QuickBooks vers un autre logiciel.
On te donne deux listes, une ligne par compte, colonnes séparées par « | » :

  A. les comptes de l''ancien logiciel (QuickBooks) :
     clé | nom complet | nature | type QuickBooks | sous-type QuickBooks | origine | solde | description
     - clé : l''identifiant exact à rendre dans la réponse ;
     - nom complet : « Parent:Enfant » quand c''est un sous-compte — le parent dit la famille ;
     - nature : ACTIF, PASSIF, CAPITAUX, PRODUIT ou CHARGE ;
     - type et sous-type : la classification QuickBooks (bank/Checking, fixed_asset/Vehicles, expense/Auto…), plus précise que le nom ;
     - origine : « défaut QuickBooks » (compte générique créé à l''ouverture de la société) ou « ajouté le <date> » (créé ensuite, en général par l''utilisateur, pour un besoin précis) ;
     - solde : le solde courant, signe compris ; vide si inconnu ;
     - description : ce que l''utilisateur a écrit, quand il l''a fait.

  B. le plan comptable de destination :
     numéro | nom | nom anglais | nature | classe | sous-classe | sens | description
     - classe : la classe de niveau 1 (ex. « ACT - Actif ») ; sous-classe : le regroupement fin (ex. « Immobilisations ») ;
     - sens : le sens normal du solde (débit ou crédit).

Pour chaque compte de la liste A, indique le compte de la liste B qui lui correspond.
Règles :
- La nature doit concorder. Un compte de charge ne se rattache jamais à un actif, même si les noms se ressemblent. Exemple : « Tools » (expense) est une dépense, pas l''immobilisation « Outillage ».
- Sers-toi du type et du sous-type QuickBooks avant du nom : un credit_card/CreditCard va à une carte de crédit (passif), un current_asset/LoansToStockholders à une avance aux actionnaires, un fixed_asset/Vehicles au matériel roulant, un bank/Savings à un compte d''épargne.
- Un sous-compte va dans la même sous-classe que son parent, ou dans le compte du plan qui en tient lieu.
- Les comptes « ajoutés » sont spécifiques à l''entreprise : lis leur nom complet et leur description avant de conclure ; n''en propose pas si rien ne convient vraiment.
- Les comptes par défaut de QuickBooks qui sont techniques (Uncategorized, Non classé, Ask My Accountant, Revenu non imputé d''un règlement comptant, Dépense non imputée d''un règlement comptant, Compte d''attente) n''ont pas de contrepartie : omets-les.
- N''utilise que des numéros présents dans la liste B. N''en invente aucun.
- Si aucun compte de B ne convient vraiment, n''en propose pas : omets la ligne. Une correspondance fausse coûte plus cher qu''une absence de correspondance.
- Confiance : 90-100 le même compte sous un autre nom ; 70-89 un compte clairement équivalent ; 50-69 plausible mais discutable. En dessous de 50, omets la ligne.
- Raison : une phrase courte en français, qui dit pourquoi — cite le type QuickBooks ou la description quand c''est ce qui a tranché. Si le choix est discutable, dis-le.

Réponds UNIQUEMENT par un tableau JSON, sans texte autour, sans bloc de code :
[{"CleSource":"<la clé exacte de la liste A>","Compte":"<numéro de la liste B>","Confiance":<0-100>,"Raison":"<une phrase>"}]'
 WHERE [ParamName] = 'PROMPT_MAPPING_COMPTES';
GO

PRINT 'T272_Correspondance_origine_et_IA_complete.sql : terminé.';
