-- =============================================================================
-- T276 — « Créer » avec un numéro que le plan connaît déjà est refusé ici,
--        pas trois écrans plus loin
--
-- Le plan n'admet pas deux comptes du même numéro (index unique
-- T121PlanComptable(Compte, CompanyGUID)) et l'étape 3 (s0767) le refuse en
-- bloc : « Le numéro 2050 est déjà utilisé dans votre plan », tout l'envoi
-- rejeté. Mais la page de correspondance, elle, acceptait un « Créer » sur
-- 2050 sans rien dire, et on ne découvrait le refus qu'à l'étape suivante.
--
-- Désormais s0757 tranche à l'enregistrement :
--   · « Créer » avec un numéro choisi à la main qui existe déjà au plan :
--     refus, en nommant le compte — c'est « Lier » qu'il faut, ou un autre
--     numéro ;
--   · « Créer » dont le numéro vient de l'ancien logiciel (le même que
--     CompteSource) et qui existe déjà chez nous : on ne refuse pas — le
--     numéro est simplement laissé vide, et l'étape 3 en attribue un dans
--     la plage de la classe choisie, ou en demande un ;
--   · deux « Créer » sur le même numéro, dans l'envoi ou contre une ligne
--     déjà enregistrée : refus.
-- Le reste de s0757 est celui de T275.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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

    DECLARE @faute NVARCHAR(1000);

    -- ── « Créer » : le numéro ne doit pas exister déjà ────────────────────
    -- Numéro repris de l'ancien logiciel et déjà pris chez nous : on le
    -- laisse vide, l'étape 3 s'en charge. Ce n'est pas une erreur de saisie.
    UPDATE d
       SET d.CompteCible = NULL
      FROM @d d
     WHERE d.Action = 'CREER'
       AND d.CompteCible IS NOT NULL
       AND d.CompteCible = d.CompteSource
       AND EXISTS (SELECT 1 FROM dbo.T121PlanComptable pc
                    WHERE pc.[CompanyGUID] = @CompanyGUID AND pc.[Compte] = d.CompteCible);

    -- Numéro choisi à la main et déjà pris : là, c'est une erreur.
    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » : le numéro ' + d.CompteCible
                        + N' existe déjà dans votre plan (' + pc.[Nom] + N'). '
                        + N'Pour le rattacher à ce compte, choisissez « Lier » ; pour en créer un nouveau, '
                        + N'laissez le compte vide, le numéro sera attribué à l''étape suivante.'
      FROM @d d
      JOIN dbo.T121PlanComptable pc
        ON pc.[CompanyGUID] = @CompanyGUID AND pc.[Compte] = d.CompteCible
     WHERE d.Action = 'CREER';
    IF @faute IS NOT NULL THROW 50343, @faute, 1;

    -- Deux « Créer » sur le même numéro dans l'envoi.
    SELECT TOP 1 @faute = N'Le numéro ' + x.CompteCible + N' serait créé '
                        + CAST(x.n AS NVARCHAR(10)) + N' fois (« ' + x.liste + N' »). '
                        + N'Un numéro ne se crée qu''une fois.'
      FROM (SELECT d.CompteCible, COUNT(*) AS n,
                   STRING_AGG(CAST(d.CleSource AS NVARCHAR(MAX)), N' », « ') AS liste
              FROM @d d
             WHERE d.Action = 'CREER' AND d.CompteCible IS NOT NULL
             GROUP BY d.CompteCible
            HAVING COUNT(*) > 1) x;
    IF @faute IS NOT NULL THROW 50344, @faute, 1;

    -- ...ou contre un « Créer » déjà enregistré par une ligne hors de l'envoi.
    SELECT TOP 1 @faute = N'Le numéro ' + d.CompteCible + N' est déjà réservé par « ' + c.[CleSource]
                        + N' » (à créer). Un numéro ne se crée qu''une fois.'
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
    SELECT TOP 1 @faute = N'Le compte ' + x.CompteCible + N' recevrait '
                        + CAST(x.n AS NVARCHAR(10)) + N' comptes de l''ancien logiciel (« '
                        + x.liste + N' »). Un compte chez vous ne reçoit qu''un seul compte : '
                        + N'liez les autres ailleurs, ou créez-les.'
      FROM (SELECT d.CompteCible, COUNT(*) AS n,
                   STRING_AGG(CAST(d.CleSource AS NVARCHAR(MAX)), N' », « ') AS liste
              FROM @d d
             WHERE d.Action = 'LIER' AND d.CompteCible IS NOT NULL
             GROUP BY d.CompteCible
            HAVING COUNT(*) > 1) x;
    IF @faute IS NOT NULL THROW 50341, @faute, 1;

    SELECT TOP 1 @faute = N'Le compte ' + d.CompteCible + N' est déjà lié à « ' + c.CleSource
                        + N' ». Un compte chez vous ne reçoit qu''un seul compte de l''ancien logiciel.'
      FROM @d d
      JOIN dbo.T121PlanComptable pc
        ON pc.[CompanyGUID] = @CompanyGUID AND pc.[Compte] = d.CompteCible
      JOIN staging.CorrespondanceCompte c
        ON c.[CompanyGUID] = @CompanyGUID
       AND c.[SystemeSource] = @Systeme
       AND c.[Action] = 'LIER'
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

PRINT 'T276_Correspondance_creer_numero_deja_pris.sql : terminé.';
