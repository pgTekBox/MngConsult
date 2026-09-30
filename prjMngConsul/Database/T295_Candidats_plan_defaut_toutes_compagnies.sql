-- =============================================================================
-- T295 — Sec60Admin › Ajouter depuis un import QuickBooks : toutes les compagnies
--
-- Le menu ne montrait que les compagnies ayant des comptes décidés « Créer » ;
-- après un rechargement du plan (décisions remises à zéro) il était vide, sans
-- dire pourquoi. s0875 (@CompanyGUID NULL) liste désormais TOUTES les compagnies
-- qui ont un plan QuickBooks en préparation, avec le nombre de candidats (0
-- compris), le nombre de comptes en préparation, encore à décider, et la date
-- du dernier chargement. Les parties 2 et 3 (candidats d'une compagnie,
-- sous-classes du modèle) sont celles de T293.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0875GetCandidatsPlanDefaut]
    @CompanyGUID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    -- 1) Sans compagnie : toutes celles qui ont un plan en préparation.
    IF @CompanyGUID IS NULL
    BEGIN
        SELECT s.[CompanyGUID],
               COUNT(*) AS [NbEnPreparation],
               SUM(CASE WHEN c.[Action] = 'CREER' THEN 1 ELSE 0 END) AS [NbCandidats],
               SUM(CASE WHEN c.[Id] IS NULL THEN 1 ELSE 0 END) AS [NbADecider],
               SUM(CASE WHEN c.[Action] = 'LIER' THEN 1 ELSE 0 END) AS [NbLies],
               MAX(s.[Created]) AS [DernierChargement],
               MAX(c.[Created]) AS [DerniereDecision]
          FROM staging.ImportPlanComptable s
          LEFT JOIN staging.CorrespondanceCompte c
            ON c.[CompanyGUID] = s.[CompanyGUID] AND c.[SystemeSource] = s.[SystemeSource] AND c.[CleSource] = s.[CleSource]
         WHERE s.[CompanyGUID] <> @Model
           AND s.[Statut] IN ('OK', 'EXISTE')
         GROUP BY s.[CompanyGUID]
         ORDER BY SUM(CASE WHEN c.[Action] = 'CREER' THEN 1 ELSE 0 END) DESC, MAX(s.[Created]) DESC;
        RETURN;
    END

    -- 2) Les candidats de la compagnie.
    SELECT s.[Id] AS [StagingId],
           s.[CleSource],
           s.[NomSource],
           ISNULL(NULLIF(c.[NomCible], ''), s.[Nom]) AS [NomCible],
           s.[TypeSource], s.[SousTypeSource], s.[TypeNormalise],
           dbo.fTypeBilanDeNature(s.[TypeNormalise]) AS [TypeBilan],
           s.[Origine],
           s.[DescriptionSource],
           c.[CompteCible],
           c.[PlanComptableId] AS [CreeChezClientId],
           cli.[Compte]        AS [CreeChezClientCompte],
           cls.[Code]          AS [ClasseCodeClient],
           mcl.[Id]            AS [ModelClasseIdSuggere],
           dbo.fLangueNomQBO(s.[NomSource]) AS [Langue],
           dm.[Compte] AS [DejaModeleCompte],
           dm.[Nom]    AS [DejaModeleNom],
           dm.[Motif]  AS [DejaModeleMotif]
      FROM staging.CorrespondanceCompte c
      JOIN staging.ImportPlanComptable s
        ON s.[CompanyGUID] = c.[CompanyGUID] AND s.[SystemeSource] = c.[SystemeSource] AND s.[CleSource] = c.[CleSource]
      LEFT JOIN dbo.T121PlanComptable cli ON cli.[Id] = c.[PlanComptableId]
      LEFT JOIN dbo.T120PlanComptable_Classe cls ON cls.[Id] = cli.[ClasseId]
      LEFT JOIN dbo.T120PlanComptable_Classe mcl ON mcl.[CompanyGUID] = @Model AND mcl.[Code] = cls.[Code] AND mcl.[ParentId] IS NOT NULL
     OUTER APPLY (
        SELECT TOP 1 m.[Compte], m.[Nom],
               CASE WHEN UPPER(LTRIM(RTRIM(m.[Nom]))) = UPPER(LTRIM(RTRIM(s.[NomSource]))) THEN N'même nom'
                    WHEN UPPER(LTRIM(RTRIM(ISNULL(m.[QBOCompteFR], '')))) = UPPER(LTRIM(RTRIM(s.[NomSource])))
                      OR UPPER(LTRIM(RTRIM(ISNULL(m.[QBOCompteEN], '')))) = UPPER(LTRIM(RTRIM(s.[NomSource]))) THEN N'alias QuickBooks'
                    ELSE N'même numéro' END AS [Motif]
          FROM dbo.T121PlanComptable m
         WHERE m.[CompanyGUID] = @Model
           AND (UPPER(LTRIM(RTRIM(m.[Nom]))) = UPPER(LTRIM(RTRIM(s.[NomSource])))
                OR UPPER(LTRIM(RTRIM(ISNULL(m.[QBOCompteFR], '')))) = UPPER(LTRIM(RTRIM(s.[NomSource])))
                OR UPPER(LTRIM(RTRIM(ISNULL(m.[QBOCompteEN], '')))) = UPPER(LTRIM(RTRIM(s.[NomSource])))
                OR (NULLIF(c.[CompteCible], '') IS NOT NULL AND m.[Compte] = c.[CompteCible]))
         ORDER BY CASE WHEN UPPER(LTRIM(RTRIM(m.[Nom]))) = UPPER(LTRIM(RTRIM(s.[NomSource]))) THEN 0 ELSE 1 END, m.[Compte]
     ) dm
     WHERE c.[CompanyGUID] = @CompanyGUID
       AND c.[Action] = 'CREER'
       AND s.[Statut] IN ('OK', 'EXISTE')
     ORDER BY CASE WHEN s.[Origine] = 'DEFAUT' THEN 0 ELSE 1 END, s.[TypeNormalise], s.[NomSource];

    -- 3) Les sous-classes du modèle, pour le choix par ligne.
    SELECT sc.[Id], sc.[Code], sc.[Description], sc.[TypeBilan], sc.[Sens],
           sc.[NumeroDebut], sc.[NumeroFin],
           p.[Code] AS [ParentCode], p.[Description] AS [ParentDescription]
      FROM dbo.T120PlanComptable_Classe sc
      JOIN dbo.T120PlanComptable_Classe p ON p.[Id] = sc.[ParentId]
     WHERE sc.[CompanyGUID] = @Model
       AND ISNULL(sc.[Actif], 1) = 1
     ORDER BY sc.[NumeroDebut], sc.[Code];
END
GO

PRINT N'T295_Candidats_plan_defaut_toutes_compagnies.sql : terminé.';
