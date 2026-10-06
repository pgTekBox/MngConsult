-- =============================================================================
-- T312 — L'étape 3 montre la même fiche du compte d'origine que l'étape 2
--
-- La grille « Créer les comptes au plan » ne disait du compte de l'ancien
-- logiciel que son nom et sa nature. L'étape 2, elle, montre toute la fiche :
-- numéro, type et sous-type QuickBooks, solde, origine (par défaut ou ajouté),
-- sous-compte de qui, description. Pour choisir la classe et la sous-classe
-- où ranger le compte, ces renseignements comptent autant qu'à l'étape 2.
--
-- s0766GetAAppliquer rend donc, dans son premier jeu, les colonnes de la fiche
-- telles que s0756 les rend — mêmes noms, pour partager le même rendu.
-- Recréée à l'identique de T243, à ce jeu près.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

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

    -- 1er jeu : les comptes à créer qui ne le sont pas encore, avec la fiche
    -- du compte d'origine (T312) — les mêmes colonnes que s0756.
    SELECT s.[LigneNo], s.[CleSource], s.[Nom], s.[TypeNormalise],
           ISNULL(NULLIF(s.[NomCible], ''), s.[Nom]) AS NomPropose,
           s.[CompteCible], s.[Solde],
           p.[Id] AS StagingId, p.[TypeCle], p.[Compte],
           p.[CompteSource], p.[NomSource], p.[TypeSource], p.[SousTypeSource],
           p.[SoldeSource], p.[SensSource], p.[SystemeSource],
           p.[CreeLe], p.[Origine] AS OrigineSource,
           p.[DescriptionSource], p.[SousCompte], p.[NomComplet],
           p.[Anomalie] AS AnomalieChargement, p.[Statut] AS StatutChargement
      FROM @src s
      JOIN staging.ImportPlanComptable p
        ON p.[CompanyGUID] = @CompanyGUID
       AND p.[CleSource]   = s.[CleSource]
       AND p.[Statut] IN ('OK', 'EXISTE')
     WHERE s.[Action] = 'CREER'
       AND s.[PlanComptableId] IS NULL
     ORDER BY s.[LigneNo];

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
