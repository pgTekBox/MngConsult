-- =============================================================================
-- T302 — Les refus de l'étape 2 nomment les deux logiciels
--
-- « Le compte 5060 est déjà lié à « COÛT DES PRODUITS VENDUS ». Un compte
-- chez vous ne reçoit qu'un seul compte de l'ancien logiciel. » : on ne sait
-- plus qui est qui. Désormais : « Le compte 5060 de 60sec est déjà lié à
-- « COÛT DES PRODUITS VENDUS » de QuickBooks. Un compte de 60sec ne reçoit
-- qu'un seul compte de QuickBooks. »
--
-- Le nom du logiciel source vient du lot : QBO, SAGE50, ACOMBA pour un fichier
-- exporté ; pour un lot APIDECK, du service relié dans la dernière extraction
-- (« quickbooks » → QuickBooks). Faute de mieux : « l'ancien logiciel ».
--
--   dbo.fNomLogicielSource(@CompanyGUID, @Systeme)  — le nom à afficher
--   s0757SaveCorrespondances                        — T277 + messages nommés
--   s0884GetNomLogicielSource                       — le même nom pour la page
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER FUNCTION [dbo].[fNomLogicielSource]
    (@CompanyGUID UNIQUEIDENTIFIER, @Systeme VARCHAR(20))
RETURNS NVARCHAR(60)
AS
BEGIN
    DECLARE @s VARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@Systeme, ''))));

    IF @s = ''
        SELECT TOP 1 @s = UPPER([SystemeSource])
          FROM staging.ImportPlanComptable
         WHERE [CompanyGUID] = @CompanyGUID
         ORDER BY [Id] DESC;

    DECLARE @svc VARCHAR(40) = NULL;
    IF @s = 'APIDECK'
        SELECT TOP 1 @svc = LOWER([Service])
          FROM staging.ConnecteurRun
         WHERE [CompanyGUID] = @CompanyGUID
         ORDER BY [Id] DESC;

    RETURN CASE
        WHEN @s = 'QBO'    OR @svc LIKE 'quickbooks%' THEN N'QuickBooks'
        WHEN @s = 'SAGE50'                            THEN N'Sage 50'
        WHEN @svc LIKE 'sage%'                        THEN N'Sage'
        WHEN @s = 'ACOMBA'                            THEN N'Acomba'
        WHEN @svc LIKE 'xero%'                        THEN N'Xero'
        WHEN @svc LIKE 'freshbooks%'                  THEN N'FreshBooks'
        WHEN @svc LIKE 'wave%'                        THEN N'Wave'
        WHEN ISNULL(@svc, '') <> ''                   THEN UPPER(LEFT(@svc, 1)) + SUBSTRING(@svc, 2, 39)
        ELSE N'l''ancien logiciel'
    END;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0884GetNomLogicielSource]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT dbo.fNomLogicielSource(@CompanyGUID, NULL) AS NomLogiciel;
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

PRINT 'T302_Correspondance_messages_nommer_les_logiciels.sql : terminé.';
