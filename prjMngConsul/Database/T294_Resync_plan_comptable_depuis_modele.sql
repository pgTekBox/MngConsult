-- =============================================================================
-- T294 — Resynchroniser le plan comptable d'une compagnie avec le plan par défaut
--
-- Le plan d'une compagnie est copié du modèle à sa création et n'est jamais
-- retouché ensuite (s0500). Quand le plan par défaut s'enrichit (comptes QBO
-- ajoutés, alias), une compagnie de démonstration veut « repartir comme à la
-- création » sans perdre ce qui la référence.
--
-- s0877ResyncPlanComptableDepuisModele (@CompanyGUID, @SupprimerEnTrop = 0, @Simuler = 0)
--   1. AJOUTE à la compagnie chaque compte du modèle qu'elle n'a pas (par numéro),
--      dans la sous-classe de même code, avec ses alias QuickBooks.
--   2. MET À JOUR sur les comptes communs (même numéro) les alias QuickBooks,
--      les noms anglais/espagnol et la description, sans toucher au nom ni à
--      l'état actif que la compagnie a pu choisir.
--   3. Avec @SupprimerEnTrop = 1, RETIRE les comptes de la compagnie absents du
--      modèle, seulement s'ils ne sont ni système ni référencés (écritures
--      T136, modèles T139, correspondances de reprise) ; les autres sont listés.
--   @Simuler = 1 : tout est calculé et rendu, puis annulé (ROLLBACK).
--   Résultat : un bilan (NbAjoutes, NbMisAJour, NbSupprimes, NbGardes) et le détail.
-- Refusé sur la compagnie modèle elle-même.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0877ResyncPlanComptableDepuisModele]
    @CompanyGUID     UNIQUEIDENTIFIER,
    @SupprimerEnTrop BIT = 0,
    @Simuler         BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    IF @CompanyGUID IS NULL OR @CompanyGUID = @Model
        THROW 50380, 'Compagnie invalide : la compagnie modèle ne se resynchronise pas avec elle-même.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE [CompanyGUID] = @CompanyGUID)
        THROW 50381, 'La compagnie n''existe pas.', 1;

    DECLARE @detail TABLE ([Action] NVARCHAR(20), [Compte] VARCHAR(20), [Nom] NVARCHAR(200), [Motif] NVARCHAR(300));

    BEGIN TRANSACTION;

    -- 1) Les comptes du modèle absents de la compagnie.
    DECLARE @NextId INT;
    SELECT @NextId = ISNULL(MAX([Id]), 0) + 1 FROM dbo.T121PlanComptable WITH (UPDLOCK, HOLDLOCK);

    ;WITH manquants AS (
        SELECT m.*, csc.[Id] AS ClasseCie, cp.[Id] AS ParentCie,
               ROW_NUMBER() OVER (ORDER BY m.[Id]) AS rn
          FROM dbo.T121PlanComptable m
          JOIN dbo.T120PlanComptable_Classe msc ON msc.[Id] = m.[ClasseId]
          LEFT JOIN dbo.T120PlanComptable_Classe csc ON csc.[CompanyGUID] = @CompanyGUID AND csc.[Code] = msc.[Code] AND csc.[ParentId] IS NOT NULL
          LEFT JOIN dbo.T120PlanComptable_Classe cp  ON cp.[Id] = csc.[ParentId]
         WHERE m.[CompanyGUID] = @Model
           AND NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable d WHERE d.[CompanyGUID] = @CompanyGUID AND d.[Compte] = m.[Compte])
    )
    INSERT INTO @detail ([Action], [Compte], [Nom], [Motif])
    SELECT CASE WHEN ClasseCie IS NULL THEN N'REFUSE' ELSE N'AJOUTE' END, [Compte], [Nom],
           CASE WHEN ClasseCie IS NULL THEN N'la sous-classe « ' + ISNULL((SELECT [Code] FROM dbo.T120PlanComptable_Classe WHERE [Id] = manquants.[ClasseId]), '?') + N' » n''existe pas chez la compagnie'
                ELSE N'compte du plan par défaut absent de la compagnie' END
      FROM manquants;

    INSERT INTO dbo.T121PlanComptable
        ([Id], [Compte], [Nom], [ClasseId], [ClasseParentId], [TypeBilan], [Sens], [Ordre], [Actif], [Systeme], [Description], [CompanyGUID],
         [NomFr], [NomEn], [NomEs], [QBOCompteFR], [QBOCompteEN], [QBOSousType])
    SELECT @NextId - 1 + ROW_NUMBER() OVER (ORDER BY m.[Id]),
           m.[Compte], m.[Nom], csc.[Id], csc.[ParentId], m.[TypeBilan], m.[Sens], m.[Ordre], m.[Actif], m.[Systeme], m.[Description], @CompanyGUID,
           m.[NomFr], m.[NomEn], m.[NomEs], m.[QBOCompteFR], m.[QBOCompteEN], m.[QBOSousType]
      FROM dbo.T121PlanComptable m
      JOIN dbo.T120PlanComptable_Classe msc ON msc.[Id] = m.[ClasseId]
      JOIN dbo.T120PlanComptable_Classe csc ON csc.[CompanyGUID] = @CompanyGUID AND csc.[Code] = msc.[Code] AND csc.[ParentId] IS NOT NULL
     WHERE m.[CompanyGUID] = @Model
       AND NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable d WHERE d.[CompanyGUID] = @CompanyGUID AND d.[Compte] = m.[Compte]);
    DECLARE @NbAjoutes INT = @@ROWCOUNT;

    -- 2) Les comptes communs : alias QuickBooks, noms EN/ES et description suivent le modèle.
    INSERT INTO @detail ([Action], [Compte], [Nom], [Motif])
    SELECT N'MIS_A_JOUR', d.[Compte], d.[Nom], N'alias QuickBooks / noms EN-ES / description alignés sur le modèle'
      FROM dbo.T121PlanComptable d
      JOIN dbo.T121PlanComptable m ON m.[CompanyGUID] = @Model AND m.[Compte] = d.[Compte]
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND (ISNULL(d.[QBOCompteFR], '') <> ISNULL(m.[QBOCompteFR], '')
            OR ISNULL(d.[QBOCompteEN], '') <> ISNULL(m.[QBOCompteEN], '')
            OR ISNULL(d.[QBOSousType], '') <> ISNULL(m.[QBOSousType], '')
            OR ISNULL(d.[NomEn], '') <> ISNULL(m.[NomEn], '')
            OR ISNULL(d.[NomEs], '') <> ISNULL(m.[NomEs], '')
            OR ISNULL(d.[Description], '') <> ISNULL(m.[Description], ''));

    UPDATE d
       SET d.[QBOCompteFR] = m.[QBOCompteFR],
           d.[QBOCompteEN] = m.[QBOCompteEN],
           d.[QBOSousType] = m.[QBOSousType],
           d.[NomEn]       = m.[NomEn],
           d.[NomEs]       = m.[NomEs],
           d.[Description] = m.[Description]
      FROM dbo.T121PlanComptable d
      JOIN dbo.T121PlanComptable m ON m.[CompanyGUID] = @Model AND m.[Compte] = d.[Compte]
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND (ISNULL(d.[QBOCompteFR], '') <> ISNULL(m.[QBOCompteFR], '')
            OR ISNULL(d.[QBOCompteEN], '') <> ISNULL(m.[QBOCompteEN], '')
            OR ISNULL(d.[QBOSousType], '') <> ISNULL(m.[QBOSousType], '')
            OR ISNULL(d.[NomEn], '') <> ISNULL(m.[NomEn], '')
            OR ISNULL(d.[NomEs], '') <> ISNULL(m.[NomEs], '')
            OR ISNULL(d.[Description], '') <> ISNULL(m.[Description], ''));
    DECLARE @NbMisAJour INT = @@ROWCOUNT;

    -- 3) Les comptes de la compagnie absents du modèle.
    DECLARE @NbSupprimes INT = 0;
    ;WITH entrop AS (
        SELECT d.[Id], d.[Compte], d.[Nom], d.[Systeme],
               (SELECT COUNT(*) FROM dbo.T136LignesEcriture l WHERE l.[PlanComptableId] = d.[Id]) AS Ecritures,
               (SELECT COUNT(*) FROM dbo.T139TemplateLignes l WHERE l.[PlanComptableId] = d.[Id]) AS Modeles,
               (SELECT COUNT(*) FROM staging.CorrespondanceCompte c WHERE c.[PlanComptableId] = d.[Id]) AS Liaisons
          FROM dbo.T121PlanComptable d
         WHERE d.[CompanyGUID] = @CompanyGUID
           AND NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable m WHERE m.[CompanyGUID] = @Model AND m.[Compte] = d.[Compte])
    )
    INSERT INTO @detail ([Action], [Compte], [Nom], [Motif])
    SELECT CASE WHEN @SupprimerEnTrop = 1 AND ISNULL(Systeme, 0) = 0 AND Ecritures + Modeles + Liaisons = 0 THEN N'SUPPRIME' ELSE N'GARDE' END,
           [Compte], [Nom],
           CASE WHEN ISNULL(Systeme, 0) = 1 THEN N'absent du modèle, mais compte système'
                WHEN Ecritures + Modeles + Liaisons > 0 THEN N'absent du modèle, mais référencé (' + CAST(Ecritures AS NVARCHAR(10)) + N' écriture(s), ' + CAST(Modeles AS NVARCHAR(10)) + N' modèle(s), ' + CAST(Liaisons AS NVARCHAR(10)) + N' liaison(s) de reprise)'
                WHEN @SupprimerEnTrop = 1 THEN N'absent du modèle, non référencé : retiré'
                ELSE N'absent du modèle, non référencé : gardé (suppression non demandée)' END
      FROM entrop;

    IF @SupprimerEnTrop = 1
    BEGIN
        DELETE d
          FROM dbo.T121PlanComptable d
         WHERE d.[CompanyGUID] = @CompanyGUID
           AND ISNULL(d.[Systeme], 0) = 0
           AND NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable m WHERE m.[CompanyGUID] = @Model AND m.[Compte] = d.[Compte])
           AND NOT EXISTS (SELECT 1 FROM dbo.T136LignesEcriture l WHERE l.[PlanComptableId] = d.[Id])
           AND NOT EXISTS (SELECT 1 FROM dbo.T139TemplateLignes l WHERE l.[PlanComptableId] = d.[Id])
           AND NOT EXISTS (SELECT 1 FROM staging.CorrespondanceCompte c WHERE c.[PlanComptableId] = d.[Id]);
        SET @NbSupprimes = @@ROWCOUNT;
    END

    IF @Simuler = 1 ROLLBACK TRANSACTION ELSE COMMIT TRANSACTION;

    SELECT @NbAjoutes AS [NbAjoutes], @NbMisAJour AS [NbMisAJour], @NbSupprimes AS [NbSupprimes],
           (SELECT COUNT(*) FROM @detail WHERE [Action] = N'GARDE') AS [NbGardes],
           (SELECT COUNT(*) FROM @detail WHERE [Action] = N'REFUSE') AS [NbRefuses],
           @Simuler AS [Simule];
    SELECT [Action], [Compte], [Nom], [Motif] FROM @detail ORDER BY CASE [Action] WHEN N'REFUSE' THEN 0 WHEN N'AJOUTE' THEN 1 WHEN N'SUPPRIME' THEN 2 WHEN N'GARDE' THEN 3 ELSE 4 END, [Compte];
END
GO

PRINT N'T294_Resync_plan_comptable_depuis_modele.sql : terminé.';
