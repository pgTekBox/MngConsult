-- =============================================================================
-- T275 — Un compte du plan ne reçoit qu'un seul compte de l'ancien logiciel
--
-- Deux comptes QuickBooks liés au même compte chez nous fusionneraient leurs
-- soldes et leurs écritures sans que rien ne le dise. C'est refusé, à trois
-- niveaux :
--   1) s0757 vérifie l'envoi avant d'écrire — deux « Lier » vers le même
--      compte dans la page, ou un « Lier » vers un compte qu'une ligne hors
--      de la page (filtrée) occupe déjà — et refuse tout l'envoi en nommant
--      les comptes ;
--   2) s0760 (accepter les propositions par numéro/nom) ne retient qu'une
--      proposition par compte cible, la première, et laisse les autres à
--      décider ;
--   3) un index unique filtré sur (compagnie, système, compte cible) pour les
--      « Lier » ferme la porte à tout autre chemin.
-- Le navigateur prévient avant l'envoi, mais c'est la base qui tranche.
--
-- Index filtré : tous les écrivains de la table (s0755, s0757, s0760, s0767,
-- s0790) sont compilés avec QUOTED_IDENTIFIER ON — vérifié avant d'écrire
-- ceci ; sans quoi leurs écritures échoueraient (Msg 1934).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ── 1) s0757 : le refus en clair ──────────────────────────────────────────
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

    -- ── Un compte cible, un seul compte source ────────────────────────────
    DECLARE @faute NVARCHAR(1000);

    -- Dans l'envoi lui-même : deux « Lier » vers le même compte.
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

    -- Avec ce qui est déjà enregistré et que la page n'a pas renvoyé (lignes
    -- hors du filtre affiché). Une ligne renvoyée remplace son ancienne
    -- version : elle ne compte pas contre elle-même.
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

    -- Les lignes renvoyées d'abord effacées : sinon l'index unique refuserait
    -- un échange de cibles entre deux lignes (A prend le compte de B, B celui
    -- de A) au milieu du MERGE.
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

    -- Un « lier » qui ne pointe nulle part n'est pas une décision.
    DELETE FROM staging.CorrespondanceCompte
     WHERE [CompanyGUID] = @CompanyGUID
       AND [SystemeSource] = @Systeme
       AND [Action] = 'LIER'
       AND [PlanComptableId] IS NULL;

    COMMIT TRANSACTION;

    EXEC dbo.s0758StatsCorrespondance @CompanyGUID = @CompanyGUID;
END
GO

-- ── 2) s0760 : une proposition par compte cible ───────────────────────────
CREATE OR ALTER PROCEDURE [dbo].[s0760AccepterPropositions]
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);

    ;WITH candidats AS (
        SELECT p.[CleSource], p.[TypeCle], p.[Compte], p.[Nom], p.[PlanComptableId],
               ROW_NUMBER() OVER (PARTITION BY p.[PlanComptableId] ORDER BY p.[LigneNo]) AS rn
          FROM staging.ImportPlanComptable p
         WHERE p.[CompanyGUID] = @CompanyGUID
           AND p.[Statut] IN ('OK', 'EXISTE')
           AND p.[PlanComptableId] IS NOT NULL
           AND NOT EXISTS (
                SELECT 1 FROM staging.CorrespondanceCompte c
                 WHERE c.[CompanyGUID] = @CompanyGUID
                   AND c.[SystemeSource] = @Systeme
                   AND c.[CleSource] = p.[CleSource])
           -- le compte cible n'est pas déjà pris par une autre liaison
           AND NOT EXISTS (
                SELECT 1 FROM staging.CorrespondanceCompte c
                 WHERE c.[CompanyGUID] = @CompanyGUID
                   AND c.[SystemeSource] = @Systeme
                   AND c.[Action] = 'LIER'
                   AND c.[PlanComptableId] = p.[PlanComptableId])
    )
    INSERT INTO staging.CorrespondanceCompte
        ([CompanyGUID], [SystemeSource], [CleSource], [TypeCle],
         [CompteSource], [NomSource], [Action], [PlanComptableId], [Note], [CreatedBy])
    SELECT @CompanyGUID, @Systeme, c.[CleSource], c.[TypeCle],
           c.[Compte], c.[Nom], 'LIER', c.[PlanComptableId],
           CASE WHEN c.[TypeCle] = 'NUMERO'
                THEN N'Proposition acceptée : même numéro de compte.'
                ELSE N'Proposition acceptée : même nom de compte.' END,
           @UserId
      FROM candidats c
     WHERE c.rn = 1;   -- deux sources vers le même compte : la première seulement

    EXEC dbo.s0758StatsCorrespondance @CompanyGUID = @CompanyGUID;
END
GO

-- ── 3) L'index unique, dernier rempart ────────────────────────────────────
-- Il ne se crée que si rien ne le contredit déjà ; sinon le script le dit
-- et laisse les procédures faire seules, le temps de nettoyer.
IF EXISTS (SELECT 1 FROM staging.CorrespondanceCompte
            WHERE [Action] = 'LIER' AND [PlanComptableId] IS NOT NULL
            GROUP BY [CompanyGUID], [SystemeSource], [PlanComptableId]
           HAVING COUNT(*) > 1)
    PRINT 'T275 : des liaisons en double existent déjà — index UX_Corresp_Cible non créé, à reprendre après nettoyage.';
ELSE IF NOT EXISTS (SELECT 1 FROM sys.indexes
                     WHERE object_id = OBJECT_ID('staging.CorrespondanceCompte')
                       AND name = 'UX_Corresp_Cible')
    CREATE UNIQUE NONCLUSTERED INDEX UX_Corresp_Cible
        ON staging.CorrespondanceCompte ([CompanyGUID], [SystemeSource], [PlanComptableId])
     WHERE [Action] = 'LIER' AND [PlanComptableId] IS NOT NULL;
GO

PRINT 'T275_Correspondance_un_seul_compte_source_par_cible.sql : terminé.';
