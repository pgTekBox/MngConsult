-- =============================================================================
-- T304 — Un compte utilisé par une facture ou un produit en préparation ne s'ignore pas
--
-- Un solde à 0 ne dit pas qu'un compte est inutilisé : QuickBooks ne donne un
-- solde courant qu'aux comptes de bilan, les revenus et les dépenses reviennent
-- toujours à 0. Ignorer un tel compte laisserait des lignes de factures et des
-- produits sans compte où pointer.
--
--   dbo.fComptesSourceUtilises(@CompanyGUID) — par compte source : lignes de
--       factures et produits en préparation (pas encore créés) qui le visent
--   s0885GetComptesSourceUtilises           — les comptes utilisés, pour la page
--   s0757SaveCorrespondances                — T303 + refus 50347 nommé
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER FUNCTION [dbo].[fComptesSourceUtilises] (@CompanyGUID UNIQUEIDENTIFIER)
RETURNS TABLE
AS
RETURN
    SELECT p.[CleSource],
           (SELECT COUNT(*)
              FROM staging.DocumentImportLigne l
              JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
             WHERE d.[CompanyGUID] = @CompanyGUID
               AND d.[DocumentId] IS NULL
               AND l.[CompteImportId] = p.[Id]) AS NbLignesFactures,
           (SELECT COUNT(*)
              FROM staging.ProductImport pi
              JOIN staging.ImportFiles f ON f.[Id] = pi.[ImportFileId]
             WHERE f.[CompanyGUID] = @CompanyGUID
               AND pi.[Status] <> 'Error'
               AND pi.[MigratedToProductId] IS NULL
               AND (   (ISNULL(p.[Nom], N'') <> N''
                        AND p.[Nom] IN (pi.[IncomeAccountName], pi.[ExpenseAccountName], pi.[AssetAccountName]))
                    OR (ISNULL(p.[Compte], '') <> ''
                        AND p.[Compte] IN (pi.[IncomeAccountCode], pi.[ExpenseAccountCode], pi.[AssetAccountCode])))) AS NbProduits
      FROM staging.ImportPlanComptable p
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[CleSource] IS NOT NULL;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0885GetComptesSourceUtilises]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.[CleSource], u.NbLignesFactures, u.NbProduits
      FROM dbo.fComptesSourceUtilises(@CompanyGUID) u
     WHERE u.NbLignesFactures > 0 OR u.NbProduits > 0;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0757SaveCorrespondances]
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = NULL,
    @Decisions   NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);

    -- Les messages nomment les deux côtés : « 60sec » et le logiciel d'où
    -- vient le lot (T302).
    DECLARE @Logiciel NVARCHAR(60) = dbo.fNomLogicielSource(@CompanyGUID, @Systeme);

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

    -- ── Les comptes déjà créés au plan ne se rediscutent pas (T277) ────────
    DELETE d
      FROM @d d
      JOIN staging.CorrespondanceCompte c
        ON c.[CompanyGUID] = @CompanyGUID
       AND c.[SystemeSource] = @Systeme
       AND c.[CleSource] = d.CleSource
     WHERE c.[Action] = 'CREER'
       AND c.[PlanComptableId] IS NOT NULL;

    DECLARE @faute NVARCHAR(1000);

    -- ── « Créer » : le numéro ne doit pas exister déjà (T276) ─────────────
    UPDATE d
       SET d.CompteCible = NULL
      FROM @d d
     WHERE d.Action = 'CREER'
       AND d.CompteCible IS NOT NULL
       AND d.CompteCible = d.CompteSource
       AND EXISTS (SELECT 1 FROM dbo.T121PlanComptable pc
                    WHERE pc.[CompanyGUID] = @CompanyGUID AND pc.[Compte] = d.CompteCible);

    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » de ' + @Logiciel + N' : le numéro ' + d.CompteCible
                        + N' existe déjà dans votre plan 60sec (' + pc.[Nom] + N'). '
                        + N'Pour le rattacher à ce compte, choisissez « Lier » ; pour en créer un nouveau, '
                        + N'laissez le compte vide, le numéro sera attribué à l''étape suivante.'
      FROM @d d
      JOIN dbo.T121PlanComptable pc
        ON pc.[CompanyGUID] = @CompanyGUID AND pc.[Compte] = d.CompteCible
     WHERE d.Action = 'CREER';
    IF @faute IS NOT NULL THROW 50343, @faute, 1;

    SELECT TOP 1 @faute = N'Le numéro ' + x.CompteCible + N' serait créé '
                        + CAST(x.n AS NVARCHAR(10)) + N' fois dans 60sec (« ' + x.liste + N' » de ' + @Logiciel + N'). '
                        + N'Un numéro ne se crée qu''une fois.'
      FROM (SELECT d.CompteCible, COUNT(*) AS n,
                   STRING_AGG(CAST(d.CleSource AS NVARCHAR(MAX)), N' », « ') AS liste
              FROM @d d
             WHERE d.Action = 'CREER' AND d.CompteCible IS NOT NULL
             GROUP BY d.CompteCible
            HAVING COUNT(*) > 1) x;
    IF @faute IS NOT NULL THROW 50344, @faute, 1;

    SELECT TOP 1 @faute = N'Le numéro ' + d.CompteCible + N' est déjà réservé par « ' + c.[CleSource]
                        + N' » de ' + @Logiciel + N' (à créer). Un numéro ne se crée qu''une fois.'
      FROM @d d
      JOIN staging.CorrespondanceCompte c
        ON c.[CompanyGUID] = @CompanyGUID
       AND c.[SystemeSource] = @Systeme
       AND c.[Action] = 'CREER'
       AND c.[CompteCible] = d.CompteCible
       AND c.[CleSource] <> d.CleSource
     WHERE d.Action = 'CREER'
       AND d.CompteCible IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM @d d2 WHERE d2.CleSource = c.[CleSource]);
    IF @faute IS NOT NULL THROW 50345, @faute, 1;

    -- ── « Lier » : un compte cible, un seul compte source (T275) ──────────
    SELECT TOP 1 @faute = N'Le compte ' + x.CompteCible + N' de 60sec recevrait '
                        + CAST(x.n AS NVARCHAR(10)) + N' comptes de ' + @Logiciel + N' (« '
                        + x.liste + N' »). Un compte de 60sec ne reçoit qu''un seul compte de ' + @Logiciel + N' : '
                        + N'liez les autres ailleurs, ou créez-les.'
      FROM (SELECT d.CompteCible, COUNT(*) AS n,
                   STRING_AGG(CAST(d.CleSource AS NVARCHAR(MAX)), N' », « ') AS liste
              FROM @d d
             WHERE d.Action = 'LIER' AND d.CompteCible IS NOT NULL
             GROUP BY d.CompteCible
            HAVING COUNT(*) > 1) x;
    IF @faute IS NOT NULL THROW 50341, @faute, 1;

    -- ...contre une liaison existante, ou contre un compte que cette reprise
    -- a elle-même créé pour une autre ligne.
    SELECT TOP 1 @faute = N'Le compte ' + d.CompteCible + N' de 60sec est déjà '
                        + CASE WHEN c.[Action] = 'CREER' THEN N'celui créé pour « ' ELSE N'lié à « ' END
                        + c.CleSource + N' » de ' + @Logiciel
                        + N'. Un compte de 60sec ne reçoit qu''un seul compte de ' + @Logiciel + N'.'
      FROM @d d
      JOIN dbo.T121PlanComptable pc
        ON pc.[CompanyGUID] = @CompanyGUID AND pc.[Compte] = d.CompteCible
      JOIN staging.CorrespondanceCompte c
        ON c.[CompanyGUID] = @CompanyGUID
       AND c.[SystemeSource] = @Systeme
       AND c.[PlanComptableId] = pc.[Id]
       AND c.[CleSource] <> d.CleSource
     WHERE d.Action = 'LIER'
       AND NOT EXISTS (SELECT 1 FROM @d d2 WHERE d2.CleSource = c.[CleSource]);
    IF @faute IS NOT NULL THROW 50342, @faute, 1;

    -- ── « Ignorer » : pas sur un compte qui porte un solde (T303) ────────
    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » de ' + @Logiciel + N' porte un solde de '
                        + FORMAT(ABS(p.[Solde]), 'N2', 'fr-CA') + N' $ : il ne peut pas être ignoré. '
                        + N'Liez-le à un compte de 60sec ou créez-le, sinon ce montant disparaîtrait de la reprise.'
      FROM @d d
      JOIN staging.ImportPlanComptable p
        ON p.[CompanyGUID] = @CompanyGUID
       AND p.[CleSource] = d.CleSource
     WHERE d.Action = 'IGNORER'
       AND ISNULL(p.[Solde], 0) <> 0;
    IF @faute IS NOT NULL THROW 50346, @faute, 1;

    -- ── « Ignorer » : pas sur un compte que la reprise utilise (T304) ─────
    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » de ' + @Logiciel + N' est utilisé par '
                        + CASE WHEN u.NbLignesFactures > 0
                               THEN CAST(u.NbLignesFactures AS NVARCHAR(10)) + N' ligne(s) de facture' ELSE N'' END
                        + CASE WHEN u.NbLignesFactures > 0 AND u.NbProduits > 0 THEN N' et ' ELSE N'' END
                        + CASE WHEN u.NbProduits > 0
                               THEN CAST(u.NbProduits AS NVARCHAR(10)) + N' produit(s)' ELSE N'' END
                        + N' en préparation : il ne peut pas être ignoré. '
                        + N'Liez-le à un compte de 60sec ou créez-le, sinon ces éléments n''auraient aucun compte.'
      FROM @d d
      JOIN dbo.fComptesSourceUtilises(@CompanyGUID) u ON u.[CleSource] = d.CleSource
     WHERE d.Action = 'IGNORER'
       AND (u.NbLignesFactures > 0 OR u.NbProduits > 0);
    IF @faute IS NOT NULL THROW 50347, @faute, 1;

    BEGIN TRANSACTION;

    DELETE c
      FROM staging.CorrespondanceCompte c
     INNER JOIN @d d ON d.CleSource = c.CleSource
     WHERE c.[CompanyGUID] = @CompanyGUID
       AND c.[SystemeSource] = @Systeme
       AND d.Action IS NULL;

    DELETE c
      FROM staging.CorrespondanceCompte c
     INNER JOIN @d d ON d.CleSource = c.CleSource
     WHERE c.[CompanyGUID] = @CompanyGUID
       AND c.[SystemeSource] = @Systeme
       AND d.Action IS NOT NULL
       AND c.[Action] = 'LIER';

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

    DELETE FROM staging.CorrespondanceCompte
     WHERE [CompanyGUID] = @CompanyGUID
       AND [SystemeSource] = @Systeme
       AND [Action] = 'LIER'
       AND [PlanComptableId] IS NULL;

    COMMIT TRANSACTION;

    EXEC dbo.s0758StatsCorrespondance @CompanyGUID = @CompanyGUID;
END
GO

PRINT 'T304_Correspondance_ignorer_refuse_si_utilise.sql : terminé.';
