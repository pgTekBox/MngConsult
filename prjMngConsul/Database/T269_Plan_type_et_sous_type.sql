-- =============================================================================
-- T269 — Le plan comptable importé garde le type et le sous-type de la source
--
-- QuickBooks, par Apideck, dit de chaque compte trois choses : sa
-- classification (asset, liability, equity, revenue, expense), son type
-- (bank, accounts_receivable, fixed_asset, credit_card, costs_of_sales,
-- other_income…) et son sous-type (Checking, CreditCard, RetainedEarnings,
-- CostOfLaborCos, TravelMeals…). L'import ne gardait que la classification,
-- rangée dans TypeSource, et laissait TypeNormalise vide.
--
-- Désormais :
--   · TypeSource      = le type QuickBooks (bank, fixed_asset…) ;
--   · SousTypeSource  = le sous-type (colonne nouvelle) ;
--   · TypeNormalise   = ACTIF / PASSIF / CAPITAUX / PRODUIT / CHARGE, posé
--                       par le moteur d'après la classification.
--
-- Et une garde qui manquait : la reconnaissance « déjà au plan » par le nom
-- exige désormais que la nature concorde. « Tools » (charge) ne se rattache
-- plus à « 1580 Outillage » (actif) parce que les mots se ressemblent : la
-- ligne reste à décider, avec l'explication.
--   ACTIF → A · PASSIF → P · CAPITAUX → CP · PRODUIT → R · CHARGE → C
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('staging.ImportPlanComptable', 'SousTypeSource') IS NULL
    ALTER TABLE staging.ImportPlanComptable ADD [SousTypeSource] NVARCHAR(100) NULL;
GO

-- La nature du plan d'ici qui correspond à une nature normalisée de la source.
CREATE OR ALTER FUNCTION dbo.fTypeBilanDeNature(@nature VARCHAR(20))
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CASE @nature
        WHEN 'ACTIF'    THEN 'A'
        WHEN 'PASSIF'   THEN 'P'
        WHEN 'CAPITAUX' THEN 'CP'
        WHEN 'PRODUIT'  THEN 'R'
        WHEN 'CHARGE'   THEN 'C'
    END;
END
GO

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

    IF @ImportFileId IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM staging.ImportFiles
                        WHERE [Id] = @ImportFileId
                          AND ([CompanyGUID] IS NULL OR [CompanyGUID] = @CompanyGUID))
        THROW 50367, 'Le fichier d''importation n''appartient pas à cette compagnie.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.ImportPlanComptable WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.ImportPlanComptable
        ([CompanyGUID], [SystemeSource], [ImportFileId], [LigneNo],
         [CompteSource], [NomSource], [TypeSource], [SousTypeSource], [SoldeSource], [SensSource],
         [Compte], [Nom], [TypeNormalise], [Solde], [Sens],
         [CleSource], [TypeCle])
    SELECT
        @CompanyGUID, @SystemeSource, @ImportFileId, j.LigneNo,
        j.CompteSource, j.NomSource, j.TypeSource, NULLIF(j.SousTypeSource, ''), j.SoldeSource, j.SensSource,
        NULLIF(LEFT(LTRIM(RTRIM(ISNULL(j.Compte, ''))), 20), ''),
        NULLIF(LTRIM(RTRIM(ISNULL(j.Nom, ''))), ''),
        NULLIF(j.TypeNormalise, ''),
        j.Solde,
        j.Sens,
        COALESCE(
            NULLIF(LEFT(LTRIM(RTRIM(ISNULL(j.Compte, ''))), 20), ''),
            NULLIF(UPPER(LTRIM(RTRIM(ISNULL(j.Nom, '')))), '')),
        CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(j.Compte, ''))), '') IS NOT NULL
             THEN 'NUMERO' ELSE 'NOM' END
    FROM OPENJSON(@Lignes)
         WITH (
            LigneNo        INT            '$.LigneNo',
            CompteSource   NVARCHAR(50)   '$.CompteSource',
            NomSource      NVARCHAR(200)  '$.NomSource',
            TypeSource     NVARCHAR(100)  '$.TypeSource',
            SousTypeSource NVARCHAR(100)  '$.SousTypeSource',
            SoldeSource    NVARCHAR(50)   '$.SoldeSource',
            SensSource     NVARCHAR(20)   '$.SensSource',
            Compte         NVARCHAR(50)   '$.Compte',
            Nom            NVARCHAR(200)  '$.Nom',
            TypeNormalise  VARCHAR(20)    '$.TypeNormalise',
            Solde          DECIMAL(18,2)  '$.Solde',
            Sens           VARCHAR(10)    '$.Sens'
         ) j;

    -- ── Verdicts ──────────────────────────────────────────────────────────
    UPDATE staging.ImportPlanComptable
       SET [Statut]   = 'INVALIDE',
           [Anomalie] = N'Ligne sans numéro ni nom de compte : rien ne permet de l''identifier.'
     WHERE [CompanyGUID] = @CompanyGUID
       AND [CleSource] IS NULL;

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

    -- Déjà au plan : par le numéro quand il y en a un...
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

    -- ...par le nom quand il n'y en a pas — et seulement si la nature concorde.
    -- Le plan est trilingue : les quatre libellés sont confrontés.
    UPDATE p
       SET p.[PlanComptableId] = n.[Id],
           p.[Statut]          = 'EXISTE',
           p.[Anomalie]        = N'Déjà au plan comptable : ' + n.[Compte] + N' - ' + n.[Nom]
      FROM staging.ImportPlanComptable p
     CROSS APPLY (
        SELECT TOP 1 pc.[Id], pc.[Compte], pc.[Nom]
          FROM dbo.T121PlanComptable pc
         CROSS APPLY (VALUES (pc.[Nom]), (pc.[NomFr]), (pc.[NomEn]), (pc.[NomEs])) AS l([Libelle])
         WHERE pc.[CompanyGUID] = p.[CompanyGUID]
           AND ISNULL(pc.[Actif], 1) = 1
           AND UPPER(LTRIM(RTRIM(l.[Libelle]))) = p.[CleSource]
           AND (p.[TypeNormalise] IS NULL
                OR dbo.fTypeBilanDeNature(p.[TypeNormalise]) IS NULL
                OR pc.[TypeBilan] = dbo.fTypeBilanDeNature(p.[TypeNormalise]))
         ORDER BY pc.[Compte]
     ) n
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] = 'OK'
       AND p.[TypeCle] = 'NOM';

    -- Même nom, autre nature : on ne rattache pas, mais on le dit.
    UPDATE p
       SET p.[Anomalie] = N'Même nom que ' + n.[Compte] + N' - ' + n.[Nom]
                        + N', mais d''une autre nature (' + ISNULL(p.[TypeNormalise], N'?')
                        + N' ici, ' + n.[TypeBilan] + N' au plan) : à décider.'
      FROM staging.ImportPlanComptable p
     CROSS APPLY (
        SELECT TOP 1 pc.[Compte], pc.[Nom], pc.[TypeBilan]
          FROM dbo.T121PlanComptable pc
         CROSS APPLY (VALUES (pc.[Nom]), (pc.[NomFr]), (pc.[NomEn]), (pc.[NomEs])) AS l([Libelle])
         WHERE pc.[CompanyGUID] = p.[CompanyGUID]
           AND ISNULL(pc.[Actif], 1) = 1
           AND UPPER(LTRIM(RTRIM(l.[Libelle]))) = p.[CleSource]
         ORDER BY pc.[Compte]
     ) n
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] = 'OK'
       AND p.[TypeCle] = 'NOM'
       AND p.[PlanComptableId] IS NULL
       AND p.[Anomalie] IS NULL;

    COMMIT TRANSACTION;

    SELECT COUNT(*)                                                                    AS [NbLignesLues],
           SUM(CASE WHEN [Statut] IN ('OK', 'EXISTE') THEN 1 ELSE 0 END)                AS [NbLignesRetenues],
           SUM(CASE WHEN [Statut] IN ('INVALIDE', 'DOUBLON_FICHIER') THEN 1 ELSE 0 END) AS [NbAnomalies],
           'CHARGE'                                                                     AS [Statut]
      FROM staging.ImportPlanComptable
     WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0753GetPlanComptableStaging]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Statut      VARCHAR(20) = NULL,
    @Top         INT = 500
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
        p.[Id], p.[LigneNo],
        p.[CompteSource], p.[NomSource], p.[TypeSource], p.[SousTypeSource], p.[SoldeSource], p.[SensSource],
        p.[Compte], p.[Nom], p.[TypeNormalise], p.[Solde], p.[Sens],
        p.[CleSource], p.[TypeCle],
        p.[Statut], p.[Anomalie],
        p.[PlanComptableId],
        pc.[Nom] AS NomAuPlan
    FROM staging.ImportPlanComptable p
    LEFT JOIN dbo.T121PlanComptable pc ON pc.[Id] = p.[PlanComptableId]
    WHERE p.[CompanyGUID] = @CompanyGUID
      AND (@Statut IS NULL OR p.[Statut] = @Statut)
    ORDER BY p.[LigneNo];
END
GO
