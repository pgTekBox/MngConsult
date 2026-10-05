-- =============================================================================
-- T311 — Le décompte de s0874 ne sort plus en tête du résultat de s0752
--
-- s0752ChargerPlanComptableStaging appelle s0874ProposerParAliasQBO, qui
-- rend son propre décompte (NbParNom, NbParSousType). Depuis T292, ce
-- décompte arrivait en PREMIER jeu de résultats de s0752 : le code qui lit le
-- bilan du chargement dans le premier jeu — l'extraction QuickBooks — tombait
-- sur « La colonne 'NbLignesRetenues' n'appartient pas à la table », et le
-- plan comptable n'était jamais versé par le connecteur.
--
-- s0874 reçoit @Silencieux : appelée depuis s0752, elle se tait. Appelée
-- seule, elle rend son décompte comme avant. s0752 est recréée à l'identique,
-- à cet appel près.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0874ProposerParAliasQBO]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Silencieux  BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    -- 1) Par nom, quelle que soit la langue.
    UPDATE p
       SET p.[PlanComptableId] = x.[Id],
           p.[Statut]          = 'EXISTE',
           p.[ProposeParAlias] = 1,
           p.[Anomalie]        = N'Déjà au plan comptable (nom QuickBooks connu) : ' + x.[Compte] + N' - ' + x.[Nom]
      FROM staging.ImportPlanComptable p
     CROSS APPLY (
        SELECT TOP 1 pc.[Id], pc.[Compte], pc.[Nom]
          FROM dbo.T122PlanComptableAlias a
          JOIN dbo.T121PlanComptable pc
            ON pc.[CompanyGUID] = p.[CompanyGUID] AND pc.[Compte] = a.[Compte] AND ISNULL(pc.[Actif], 1) = 1
         WHERE a.[CompanyGUID] = @Model AND a.[SystemeSource] = 'QBO'
           AND UPPER(LTRIM(RTRIM(a.[NomSource]))) = UPPER(LTRIM(RTRIM(p.[Nom])))
           AND (p.[TypeNormalise] IS NULL
                OR dbo.fTypeBilanDeNature(p.[TypeNormalise]) IS NULL
                OR pc.[TypeBilan] = dbo.fTypeBilanDeNature(p.[TypeNormalise]))
         ORDER BY pc.[Compte]
     ) x
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] = 'OK'
       AND p.[PlanComptableId] IS NULL
       AND NULLIF(LTRIM(RTRIM(p.[Nom])), '') IS NOT NULL;

    DECLARE @ParNom INT = @@ROWCOUNT;

    -- 2) Par sous-type, seulement quand il ne désigne qu'un seul compte d'ici,
    --    et que ce compte n'est pas déjà proposé à une autre ligne.
    UPDATE p
       SET p.[PlanComptableId] = x.[Id],
           p.[Statut]          = 'EXISTE',
           p.[ProposeParAlias] = 1,
           p.[Anomalie]        = N'Déjà au plan comptable (sous-type QuickBooks connu) : ' + x.[Compte] + N' - ' + x.[Nom]
      FROM staging.ImportPlanComptable p
     CROSS APPLY (
        SELECT TOP 1 pc.[Id], pc.[Compte], pc.[Nom]
          FROM (SELECT DISTINCT a.[Compte]
                  FROM dbo.T122PlanComptableAlias a
                 WHERE a.[CompanyGUID] = @Model AND a.[SystemeSource] = 'QBO'
                   AND a.[SousType] = LTRIM(RTRIM(p.[SousTypeSource]))) u
          JOIN dbo.T121PlanComptable pc
            ON pc.[CompanyGUID] = p.[CompanyGUID] AND pc.[Compte] = u.[Compte] AND ISNULL(pc.[Actif], 1) = 1
         WHERE (SELECT COUNT(DISTINCT a2.[Compte]) FROM dbo.T122PlanComptableAlias a2
                 WHERE a2.[CompanyGUID] = @Model AND a2.[SystemeSource] = 'QBO'
                   AND a2.[SousType] = LTRIM(RTRIM(p.[SousTypeSource]))) = 1
           AND (p.[TypeNormalise] IS NULL
                OR dbo.fTypeBilanDeNature(p.[TypeNormalise]) IS NULL
                OR pc.[TypeBilan] = dbo.fTypeBilanDeNature(p.[TypeNormalise]))
         ORDER BY pc.[Compte]
     ) x
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] = 'OK'
       AND p.[PlanComptableId] IS NULL
       AND NULLIF(LTRIM(RTRIM(p.[SousTypeSource])), '') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM staging.ImportPlanComptable q
                        WHERE q.[CompanyGUID] = @CompanyGUID AND q.[PlanComptableId] = x.[Id]);

    DECLARE @ParSousType INT = @@ROWCOUNT;

    -- 3) La liaison d'office (T301).
    DECLARE @lies TABLE ([NbLies] INT);
    INSERT INTO @lies EXEC dbo.s0883LierParAliasQBO @CompanyGUID = @CompanyGUID;

    IF @Silencieux = 0
        SELECT @ParNom AS [NbParNom], @ParSousType AS [NbParSousType], (SELECT TOP 1 [NbLies] FROM @lies) AS [NbLiesDOffice];
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
         [CleSource], [TypeCle],
         [CreeLe], [ModifieLe], [DescriptionSource], [SousCompte], [NomComplet])
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
             THEN 'NUMERO' ELSE 'NOM' END,
        TRY_CONVERT(DATETIME, TRY_CONVERT(DATETIMEOFFSET, NULLIF(j.CreeLe, ''))),
        TRY_CONVERT(DATETIME, TRY_CONVERT(DATETIMEOFFSET, NULLIF(j.ModifieLe, ''))),
        NULLIF(j.DescriptionSource, ''),
        dbo.fImportBit(j.SousCompte),
        NULLIF(j.NomComplet, '')
    FROM OPENJSON(@Lignes)
         WITH (
            LigneNo           INT            '$.LigneNo',
            CompteSource      NVARCHAR(50)   '$.CompteSource',
            NomSource         NVARCHAR(200)  '$.NomSource',
            TypeSource        NVARCHAR(100)  '$.TypeSource',
            SousTypeSource    NVARCHAR(100)  '$.SousTypeSource',
            SoldeSource       NVARCHAR(50)   '$.SoldeSource',
            SensSource        NVARCHAR(20)   '$.SensSource',
            Compte            NVARCHAR(50)   '$.Compte',
            Nom               NVARCHAR(200)  '$.Nom',
            TypeNormalise     VARCHAR(20)    '$.TypeNormalise',
            Solde             DECIMAL(18,2)  '$.Solde',
            Sens              VARCHAR(10)    '$.Sens',
            CreeLe            NVARCHAR(40)   '$.CreeLe',
            ModifieLe         NVARCHAR(40)   '$.ModifieLe',
            DescriptionSource NVARCHAR(500)  '$.DescriptionSource',
            SousCompte        NVARCHAR(10)   '$.SousCompte',
            NomComplet        NVARCHAR(300)  '$.NomComplet'
         ) j;

    -- ── L'origine : par défaut ou ajouté ──────────────────────────────────
    DECLARE @Naissance DATETIME =
        (SELECT MIN([CreeLe]) FROM staging.ImportPlanComptable WHERE [CompanyGUID] = @CompanyGUID);

    UPDATE staging.ImportPlanComptable
       SET [Origine] = CASE WHEN [CreeLe] IS NULL THEN NULL
                            WHEN [CreeLe] <= DATEADD(MINUTE, 10, @Naissance) THEN 'DEFAUT'
                            ELSE 'AJOUTE' END
     WHERE [CompanyGUID] = @CompanyGUID;

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

    -- ── Les alias QuickBooks du plan par défaut (T292) ─────────────────────
    -- Un compte QBO dont le nom (FR ou EN) ou le sous-type est connu du plan
    -- modèle est lié d'office au compte de même numéro chez la compagnie.
    EXEC dbo.s0874ProposerParAliasQBO @CompanyGUID = @CompanyGUID, @Silencieux = 1;

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
           SUM(CASE WHEN [Origine] = 'AJOUTE' THEN 1 ELSE 0 END)                        AS [NbAjoutes],
           'CHARGE'                                                                     AS [Statut]
      FROM staging.ImportPlanComptable
     WHERE [CompanyGUID] = @CompanyGUID;
END

GO
