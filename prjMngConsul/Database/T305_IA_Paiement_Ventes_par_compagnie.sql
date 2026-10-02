-- =============================================================================
-- T305 — IA Paiement et IA Ventes : chaque compagnie ne voit que ses données
--
-- Les écrans « IA Paiement » et « IA Ventes » lisaient les vues vwAiPaiement et
-- vwAISales en SQL posé dans la page, sans aucun filtre de compagnie : les vues
-- n'exposaient même pas la colonne. Tout abonné connecté voyait donc les
-- paiements et les ventes planifiés de toutes les compagnies.
--
--   vwAiPaiement, vwAISales        — exposent désormais [CompanyGUID]
--                                    (celui de la tâche planifiée T204)
--   s0886GetAiPaiementKpis         — compteurs par période et catégorie
--   s0887GetAiPaiementListe        — paiements de la période choisie
--   s0888GetAiVentesKpis           — les 4 × 3 sous-totaux des ventes
--   s0889GetAiVentesListe          — ventes de la période et de l'onglet
--   s0890GetAiVentesCompteurs      — compteurs des trois onglets
--
-- Toutes les procédures exigent @CompanyGUID. Une compagnie absente ou vide ne
-- reçoit rien : jamais « tout ».
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER VIEW [dbo].[vwAiPaiement]
AS
SELECT c.[Name]          AS Category,
       p.[Id],
       p.[Beneficiaire],
       p.[Montant],
       d.[Nom]           AS Description,
       p.[DateExecutionPrevue],
       d.[Description]   AS Nom,
       d.[Id]            AS JobId,
       p.[Created],
       p.[CompanyGUID]
  FROM dbo.T204JobPlanned p
 INNER JOIN dbo.T200JobDefinition d ON p.[JobDefinitionId] = d.[Id]
 INNER JOIN dbo.T205JobCategories c ON d.[CategotyId] = c.[Id]
 WHERE c.[Id] IN (1, 2, 3);
GO

CREATE OR ALTER VIEW [dbo].[vwAISales]
AS
SELECT c.[Name]          AS Category,
       p.[Id],
       p.[Beneficiaire],
       p.[Montant],
       d.[Nom]           AS Description,
       p.[DateExecutionPrevue],
       d.[Description]   AS Nom,
       d.[Id]            AS JobId,
       p.[Created],
       p.[DueDate],
       p.[StatutPaiement],
       p.[DejaRecu],
       p.[CompanyGUID]
  FROM dbo.T204JobPlanned p
 INNER JOIN dbo.T200JobDefinition d ON p.[JobDefinitionId] = d.[Id]
 INNER JOIN dbo.T205JobCategories c ON d.[CategotyId] = c.[Id]
 WHERE c.[Id] IN (4);
GO

-- ── IA Paiement : compteurs par période et par catégorie ────────────────────
CREATE OR ALTER PROCEDURE [dbo].[s0886GetAiPaiementKpis]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @T DATE = CAST(GETDATE() AS DATE);

    SELECT x.[Period],
           x.[Category]                AS CategorieNom,
           COUNT(*)                    AS NbPaiements,
           SUM(ISNULL(x.[Montant], 0)) AS Total
      FROM (SELECT v.[Category], v.[Montant],
                   CASE WHEN v.[DateExecutionPrevue] < DATEADD(DAY, 1, @T)   THEN 'TODAY'
                        WHEN v.[DateExecutionPrevue] < DATEADD(DAY, 7, @T)   THEN 'WEEK'
                        WHEN v.[DateExecutionPrevue] < DATEADD(MONTH, 1, @T) THEN 'MONTH'
                        WHEN v.[DateExecutionPrevue] < DATEADD(MONTH, 3, @T) THEN '3MONTHS'
                        ELSE 'OTHER' END AS [Period]
              FROM dbo.vwAiPaiement v
             WHERE v.[CompanyGUID] = @CompanyGUID
               AND v.[DateExecutionPrevue] >= @T) x
     GROUP BY x.[Period], x.[Category];
END
GO

-- ── IA Paiement : les paiements de la période choisie ───────────────────────
CREATE OR ALTER PROCEDURE [dbo].[s0887GetAiPaiementListe]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Periode     VARCHAR(10)            -- TODAY, WEEK, MONTH, sinon 3 mois
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @T DATE = CAST(GETDATE() AS DATE);
    DECLARE @Fin DATE = CASE @Periode WHEN 'TODAY' THEN DATEADD(DAY, 1, @T)
                                      WHEN 'WEEK'  THEN DATEADD(DAY, 7, @T)
                                      WHEN 'MONTH' THEN DATEADD(MONTH, 1, @T)
                                      ELSE DATEADD(MONTH, 3, @T) END;

    SELECT v.[Category] AS CategorieNom,
           v.[Id], v.[Beneficiaire], v.[Montant], v.[Nom], v.[Description],
           v.[DateExecutionPrevue]
      FROM dbo.vwAiPaiement v
     WHERE v.[CompanyGUID] = @CompanyGUID
       AND v.[DateExecutionPrevue] >= @T
       AND v.[DateExecutionPrevue] <  @Fin
     ORDER BY v.[Category], v.[DateExecutionPrevue];
END
GO

-- ── IA Ventes : les 4 × 3 sous-totaux ───────────────────────────────────────
CREATE OR ALTER PROCEDURE [dbo].[s0888GetAiVentesKpis]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @T DATE = CAST(GETDATE() AS DATE);

    WITH Periodes AS (
        SELECT v.[Id], v.[Montant], v.[StatutPaiement],
               ABS(DATEDIFF(DAY, @T, ISNULL(v.[DueDate], v.[DateExecutionPrevue]))) AS DiffDays
          FROM dbo.vwAISales v
         WHERE v.[CompanyGUID] = @CompanyGUID
    )
    SELECT
        SUM(CASE WHEN DiffDays <= 1  THEN 1 ELSE 0 END) AS NbToday,
        SUM(CASE WHEN DiffDays <= 7  THEN 1 ELSE 0 END) AS NbWeek,
        SUM(CASE WHEN DiffDays <= 30 THEN 1 ELSE 0 END) AS NbMonth,
        SUM(CASE WHEN DiffDays <= 90 THEN 1 ELSE 0 END) AS Nb3M,

        SUM(CASE WHEN DiffDays <= 1 AND StatutPaiement = 'PAYEE'                                 THEN Montant ELSE 0 END) AS TodayCollecte,
        SUM(CASE WHEN DiffDays <= 1 AND StatutPaiement IN ('OUVERTE','IN_PROGRESS','PARTIELLE')  THEN Montant ELSE 0 END) AS TodayRecevoir,
        SUM(CASE WHEN DiffDays <= 1 AND StatutPaiement = 'EN_RETARD'                             THEN Montant ELSE 0 END) AS TodayRetard,

        SUM(CASE WHEN DiffDays <= 7 AND StatutPaiement = 'PAYEE'                                 THEN Montant ELSE 0 END) AS WeekCollecte,
        SUM(CASE WHEN DiffDays <= 7 AND StatutPaiement IN ('OUVERTE','IN_PROGRESS','PARTIELLE')  THEN Montant ELSE 0 END) AS WeekRecevoir,
        SUM(CASE WHEN DiffDays <= 7 AND StatutPaiement = 'EN_RETARD'                             THEN Montant ELSE 0 END) AS WeekRetard,

        SUM(CASE WHEN DiffDays <= 30 AND StatutPaiement = 'PAYEE'                                THEN Montant ELSE 0 END) AS MonthCollecte,
        SUM(CASE WHEN DiffDays <= 30 AND StatutPaiement IN ('OUVERTE','IN_PROGRESS','PARTIELLE') THEN Montant ELSE 0 END) AS MonthRecevoir,
        SUM(CASE WHEN DiffDays <= 30 AND StatutPaiement = 'EN_RETARD'                            THEN Montant ELSE 0 END) AS MonthRetard,

        SUM(CASE WHEN DiffDays <= 90 AND StatutPaiement = 'PAYEE'                                THEN Montant ELSE 0 END) AS M3Collecte,
        SUM(CASE WHEN DiffDays <= 90 AND StatutPaiement IN ('OUVERTE','IN_PROGRESS','PARTIELLE') THEN Montant ELSE 0 END) AS M3Recevoir,
        SUM(CASE WHEN DiffDays <= 90 AND StatutPaiement = 'EN_RETARD'                            THEN Montant ELSE 0 END) AS M3Retard
      FROM Periodes;
END
GO

-- ── IA Ventes : la liste de la période et de l'onglet ───────────────────────
CREATE OR ALTER PROCEDURE [dbo].[s0889GetAiVentesListe]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Jours       INT,                   -- 1, 7, 30 ou 90
    @Onglet      VARCHAR(10)            -- COLLECTE, RECEVOIR, sinon RETARD
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @T DATE = CAST(GETDATE() AS DATE);

    SELECT v.[Id]                                AS Id,
           ISNULL(v.[Beneficiaire], '')          AS Client,
           ISNULL(v.[Description], v.[Nom])      AS Description,
           v.[DueDate]                           AS DueDate,
           ISNULL(v.[Montant], 0)                AS Montant,
           ISNULL(v.[StatutPaiement], 'OUVERTE') AS StatutPaiement
      FROM dbo.vwAISales v
     WHERE v.[CompanyGUID] = @CompanyGUID
       AND ABS(DATEDIFF(DAY, @T, ISNULL(v.[DueDate], v.[DateExecutionPrevue]))) <= @Jours
       AND (   (@Onglet = 'COLLECTE' AND v.[StatutPaiement] = 'PAYEE')
            OR (@Onglet = 'RECEVOIR' AND v.[StatutPaiement] IN ('OUVERTE','IN_PROGRESS','PARTIELLE'))
            OR (@Onglet NOT IN ('COLLECTE','RECEVOIR') AND v.[StatutPaiement] = 'EN_RETARD'))
     ORDER BY ISNULL(v.[DueDate], v.[DateExecutionPrevue]) DESC;
END
GO

-- ── IA Ventes : les compteurs des trois onglets ─────────────────────────────
CREATE OR ALTER PROCEDURE [dbo].[s0890GetAiVentesCompteurs]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Jours       INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @T DATE = CAST(GETDATE() AS DATE);

    SELECT SUM(CASE WHEN v.[StatutPaiement] = 'PAYEE' THEN 1 ELSE 0 END)                                AS NbCollecte,
           SUM(CASE WHEN v.[StatutPaiement] IN ('OUVERTE','IN_PROGRESS','PARTIELLE') THEN 1 ELSE 0 END) AS NbRecevoir,
           SUM(CASE WHEN v.[StatutPaiement] = 'EN_RETARD' THEN 1 ELSE 0 END)                            AS NbRetard
      FROM dbo.vwAISales v
     WHERE v.[CompanyGUID] = @CompanyGUID
       AND ABS(DATEDIFF(DAY, @T, ISNULL(v.[DueDate], v.[DateExecutionPrevue]))) <= @Jours;
END
GO

PRINT 'T305_IA_Paiement_Ventes_par_compagnie.sql : terminé.';
