-- =============================================================================
-- Reprise comptable — la mise en correspondance des comptes
-- -----------------------------------------------------------------------------
-- Etape 2 : dire, pour chaque compte de l'ancien logiciel, a quel compte de
-- notre plan il correspond. C'est le seul travail de la migration qu'un
-- programme ne peut pas decider seul : il se fait avec le comptable.
--
-- La decision ne vit pas dans le lot d'importation mais dans une table a part,
-- et pour une bonne raison : les etapes suivantes en ont besoin. Quand on
-- chargera les factures et les ecritures, chacune desingera un compte de
-- l'ancien logiciel — c'est ici qu'on saura vers quoi le tourner. Le lot, lui,
-- peut etre abandonne et recharge ; la correspondance reste.
--
-- Re-executable.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1) La correspondance
--    Une ligne par compte de l'ancien logiciel, pour une compagnie donnee.
--    Elle survit aux lots : c'est la piece que le comptable signe.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.CorrespondanceCompte', 'U') IS NULL
BEGIN
    CREATE TABLE staging.CorrespondanceCompte (
        [Id]              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CorrespondanceCompte PRIMARY KEY,
        [CompanyGUID]     UNIQUEIDENTIFIER NOT NULL,
        [SystemeSource]   VARCHAR(20) NOT NULL,

        -- le compte tel qu'il est dans l'ancien logiciel
        [CompteSource]    VARCHAR(20) NOT NULL,
        [NomSource]       NVARCHAR(200) NULL,

        -- ce qu'on en fait : LIER a un compte existant, CREER un compte, ou
        -- IGNORER (compte technique, compte vide, doublon du plan d'origine)
        [Action]          VARCHAR(10) NOT NULL CONSTRAINT DF_Corresp_Action DEFAULT ('LIER'),

        -- si LIER : le compte de notre plan
        [PlanComptableId] INT NULL,
        -- si CREER : ce qu'il faudra creer
        [CompteCible]     VARCHAR(20) NULL,
        [NomCible]        NVARCHAR(200) NULL,
        [TypeCible]       VARCHAR(20) NULL,

        [Note]            NVARCHAR(500) NULL,

        [Created]         DATETIME NOT NULL CONSTRAINT DF_Corresp_Created DEFAULT (GETDATE()),
        [CreatedBy]       INT NULL,
        [Modified]        DATETIME NULL,
        [ModifiedBy]      INT NULL,

        CONSTRAINT CK_Corresp_Action CHECK ([Action] IN ('LIER', 'CREER', 'IGNORER'))
    );

    -- Un compte d'origine n'a qu'une correspondance par compagnie et par
    -- logiciel : c'est ce qui rend la table interrogeable par les etapes
    -- suivantes sans ambiguite.
    CREATE UNIQUE INDEX UX_Corresp_Source
        ON staging.CorrespondanceCompte ([CompanyGUID], [SystemeSource], [CompteSource]);
END
GO

-- -----------------------------------------------------------------------------
-- 2) s0756GetCorrespondances
--    Les lignes du lot, avec la decision deja prise s'il y en a une, et une
--    proposition sinon.
--
--    Deux propositions, de la plus sure a la moins sure :
--      1. meme numero de compte — c'est deja repere au chargement ;
--      2. meme nom, aux accents et a la casse pres.
--    Au-dela, on ne devine pas : une correspondance fausse deplace des montants
--    sans rien signaler.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0756GetCorrespondances]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @Filtre      VARCHAR(20) = NULL,   -- NULL=tout | A_DECIDER | DECIDE
    @Top         INT = 1000
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT [SystemeSource] FROM staging.ImportLot
          WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID);

    IF @Systeme IS NULL
        THROW 50310, 'Lot d''importation introuvable pour cette compagnie.', 1;

    ;WITH src AS (
        SELECT p.[Id]        AS StagingId,
               p.[LigneNo],
               p.[Compte],
               p.[Nom],
               p.[TypeNormalise],
               p.[Solde],
               p.[Statut]    AS StatutChargement,
               p.[PlanComptableId] AS ProposeParNumero
          FROM staging.ImportPlanComptable p
         WHERE p.[LotId] = @LotId
           AND p.[CompanyGUID] = @CompanyGUID
           -- une ligne sans numero ou en doublon n'a pas de correspondance a
           -- decider : elle a deja ete ecartee au chargement
           AND p.[Statut] IN ('OK', 'EXISTE')
    )
    SELECT TOP (@Top)
        s.StagingId, s.LigneNo, s.Compte, s.Nom, s.TypeNormalise, s.Solde,
        s.StatutChargement,

        -- la decision enregistree, s'il y en a une
        c.[Id]              AS CorrespondanceId,
        c.[Action],
        c.[PlanComptableId] AS DecidePlanComptableId,
        c.[CompteCible],
        c.[NomCible],
        c.[Note],

        -- ce que nous proposons a defaut de decision
        COALESCE(c.[PlanComptableId], s.ProposeParNumero, n.[Id]) AS ProposeId,
        CASE
            WHEN c.[Id] IS NOT NULL              THEN 'DECIDE'
            WHEN s.ProposeParNumero IS NOT NULL  THEN 'PROPOSE_NUMERO'
            WHEN n.[Id] IS NOT NULL              THEN 'PROPOSE_NOM'
            ELSE 'AUCUN'
        END AS Origine,

        pc.[Compte] AS ProposeCompte,
        pc.[Nom]    AS ProposeNom
    FROM src s
    LEFT JOIN staging.CorrespondanceCompte c
           ON c.[CompanyGUID] = @CompanyGUID
          AND c.[SystemeSource] = @Systeme
          AND c.[CompteSource] = s.Compte
    -- proposition par le nom, quand le numero n'a rien donne
    OUTER APPLY (
        SELECT TOP 1 p2.[Id]
          FROM dbo.T121PlanComptable p2
         WHERE s.ProposeParNumero IS NULL
           AND p2.[CompanyGUID] = @CompanyGUID
           AND ISNULL(p2.[Actif], 1) = 1
           AND LOWER(LTRIM(RTRIM(p2.[Nom]))) = LOWER(LTRIM(RTRIM(s.Nom)))
         ORDER BY p2.[Compte]
    ) n
    LEFT JOIN dbo.T121PlanComptable pc
           ON pc.[Id] = COALESCE(c.[PlanComptableId], s.ProposeParNumero, n.[Id])
    WHERE (@Filtre IS NULL
           OR (@Filtre = 'DECIDE'    AND c.[Id] IS NOT NULL)
           OR (@Filtre = 'A_DECIDER' AND c.[Id] IS NULL))
    ORDER BY s.LigneNo;
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0757SaveCorrespondances
--    Enregistre les decisions d'un coup. Le JSON porte, par ligne :
--      CompteSource, NomSource, Action, CompteCible, NomCible, TypeCible, Note
--
--    Une ligne sans action est effacee de la correspondance : c'est ainsi que
--    l'utilisateur revient sur une decision.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0757SaveCorrespondances]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = NULL,
    @Decisions   NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT [SystemeSource] FROM staging.ImportLot
          WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID);

    IF @Systeme IS NULL
        THROW 50310, 'Lot d''importation introuvable pour cette compagnie.', 1;

    DECLARE @d TABLE (
        CompteSource VARCHAR(20),
        NomSource    NVARCHAR(200),
        Action       VARCHAR(10),
        CompteCible  VARCHAR(20),
        NomCible     NVARCHAR(200),
        TypeCible    VARCHAR(20),
        Note         NVARCHAR(500)
    );

    INSERT INTO @d
    SELECT LEFT(LTRIM(RTRIM(j.CompteSource)), 20), j.NomSource,
           NULLIF(LTRIM(RTRIM(j.Action)), ''),
           NULLIF(LEFT(LTRIM(RTRIM(ISNULL(j.CompteCible, ''))), 20), ''),
           j.NomCible, j.TypeCible, j.Note
      FROM OPENJSON(@Decisions)
           WITH (
              CompteSource NVARCHAR(50)  '$.CompteSource',
              NomSource    NVARCHAR(200) '$.NomSource',
              Action       VARCHAR(10)   '$.Action',
              CompteCible  NVARCHAR(50)  '$.CompteCible',
              NomCible     NVARCHAR(200) '$.NomCible',
              TypeCible    VARCHAR(20)   '$.TypeCible',
              Note         NVARCHAR(500) '$.Note'
           ) j
     WHERE ISNULL(LTRIM(RTRIM(j.CompteSource)), '') <> '';

    BEGIN TRANSACTION;

    -- Revenir sur une decision : la ligne repasse « a decider »
    DELETE c
      FROM staging.CorrespondanceCompte c
     INNER JOIN @d d ON d.CompteSource = c.CompteSource
     WHERE c.[CompanyGUID] = @CompanyGUID
       AND c.[SystemeSource] = @Systeme
       AND d.Action IS NULL;

    -- LIER : le compte cible doit exister au plan de la compagnie. On le
    -- resout ici plutot que de faire confiance a un identifiant venu du
    -- navigateur.
    MERGE staging.CorrespondanceCompte AS cible
    USING (
        SELECT d.CompteSource, d.NomSource, d.Action, d.CompteCible,
               d.NomCible, d.TypeCible, d.Note,
               pc.[Id] AS PlanComptableId
          FROM @d d
          LEFT JOIN dbo.T121PlanComptable pc
                 ON pc.[CompanyGUID] = @CompanyGUID
                AND pc.[Compte] = d.CompteCible
         WHERE d.Action IS NOT NULL
    ) AS src
       ON  cible.[CompanyGUID] = @CompanyGUID
       AND cible.[SystemeSource] = @Systeme
       AND cible.[CompteSource] = src.CompteSource
    WHEN MATCHED THEN UPDATE SET
        cible.[Action]          = src.Action,
        cible.[PlanComptableId] = CASE WHEN src.Action = 'LIER' THEN src.PlanComptableId END,
        cible.[CompteCible]     = CASE WHEN src.Action = 'CREER' THEN src.CompteCible END,
        cible.[NomCible]        = CASE WHEN src.Action = 'CREER' THEN src.NomCible END,
        cible.[TypeCible]       = CASE WHEN src.Action = 'CREER' THEN src.TypeCible END,
        cible.[NomSource]       = src.NomSource,
        cible.[Note]            = src.Note,
        cible.[Modified]        = GETDATE(),
        cible.[ModifiedBy]      = @UserId
    WHEN NOT MATCHED THEN INSERT
        ([CompanyGUID], [SystemeSource], [CompteSource], [NomSource], [Action],
         [PlanComptableId], [CompteCible], [NomCible], [TypeCible], [Note], [CreatedBy])
        VALUES
        (@CompanyGUID, @Systeme, src.CompteSource, src.NomSource, src.Action,
         CASE WHEN src.Action = 'LIER'  THEN src.PlanComptableId END,
         CASE WHEN src.Action = 'CREER' THEN src.CompteCible END,
         CASE WHEN src.Action = 'CREER' THEN src.NomCible END,
         CASE WHEN src.Action = 'CREER' THEN src.TypeCible END,
         src.Note, @UserId);

    -- Un LIER dont le compte n'a pas ete trouve n'est pas une decision : on ne
    -- laisse pas passer une correspondance qui ne pointe nulle part.
    DELETE FROM staging.CorrespondanceCompte
     WHERE [CompanyGUID] = @CompanyGUID
       AND [SystemeSource] = @Systeme
       AND [Action] = 'LIER'
       AND [PlanComptableId] IS NULL;

    COMMIT TRANSACTION;

    EXEC dbo.s0758StatsCorrespondance @LotId = @LotId, @CompanyGUID = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0758StatsCorrespondance — ou en est-on
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0758StatsCorrespondance]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT [SystemeSource] FROM staging.ImportLot
          WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID);

    ;WITH src AS (
        SELECT p.[Compte]
          FROM staging.ImportPlanComptable p
         WHERE p.[LotId] = @LotId
           AND p.[CompanyGUID] = @CompanyGUID
           AND p.[Statut] IN ('OK', 'EXISTE')
    )
    SELECT
        COUNT(*)                                                             AS Total,
        SUM(CASE WHEN c.[Id] IS NOT NULL THEN 1 ELSE 0 END)                  AS Decides,
        SUM(CASE WHEN c.[Id] IS NULL THEN 1 ELSE 0 END)                      AS ADecider,
        SUM(CASE WHEN c.[Action] = 'LIER' THEN 1 ELSE 0 END)                 AS Lies,
        SUM(CASE WHEN c.[Action] = 'CREER' THEN 1 ELSE 0 END)                AS ACreer,
        SUM(CASE WHEN c.[Action] = 'IGNORER' THEN 1 ELSE 0 END)              AS Ignores
    FROM src s
    LEFT JOIN staging.CorrespondanceCompte c
           ON c.[CompanyGUID] = @CompanyGUID
          AND c.[SystemeSource] = @Systeme
          AND c.[CompteSource] = s.[Compte];
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0759GetPlanCompagnie
--    Le plan de la compagnie, pour la liste de saisie assistee de la page.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0759GetPlanCompagnie]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [Compte], [Nom], [TypeBilan], [Sens]
      FROM dbo.T121PlanComptable
     WHERE [CompanyGUID] = @CompanyGUID
       AND ISNULL([Actif], 1) = 1
     ORDER BY [Compte];
END
GO

-- -----------------------------------------------------------------------------
-- 6) s0760AccepterPropositions
--    Enregistre d'un coup toutes les propositions sures — celles ou le numero
--    de compte concorde. C'est le gros du travail sur un plan comptable qui a
--    ete construit sur la meme base ; ce qui reste demande un avis.
--
--    N'ecrase jamais une decision deja prise.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0760AccepterPropositions]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT [SystemeSource] FROM staging.ImportLot
          WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID);

    IF @Systeme IS NULL
        THROW 50310, 'Lot d''importation introuvable pour cette compagnie.', 1;

    INSERT INTO staging.CorrespondanceCompte
        ([CompanyGUID], [SystemeSource], [CompteSource], [NomSource],
         [Action], [PlanComptableId], [Note], [CreatedBy])
    SELECT @CompanyGUID, @Systeme, p.[Compte], p.[Nom],
           'LIER', p.[PlanComptableId],
           N'Proposition acceptée : même numéro de compte.', @UserId
      FROM staging.ImportPlanComptable p
     WHERE p.[LotId] = @LotId
       AND p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] IN ('OK', 'EXISTE')
       AND p.[PlanComptableId] IS NOT NULL
       AND NOT EXISTS (
            SELECT 1 FROM staging.CorrespondanceCompte c
             WHERE c.[CompanyGUID] = @CompanyGUID
               AND c.[SystemeSource] = @Systeme
               AND c.[CompteSource] = p.[Compte]);

    EXEC dbo.s0758StatsCorrespondance @LotId = @LotId, @CompanyGUID = @CompanyGUID;
END
GO

PRINT N'T211_Correspondance_comptes.sql : termine.';
GO
