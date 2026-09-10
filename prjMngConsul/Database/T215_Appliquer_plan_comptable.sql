-- =============================================================================
-- T215 — Etape 3 : creer les comptes dans le plan comptable
--
-- C'est le premier ecran de la reprise qui ecrit dans la comptabilite. Tout
-- ce qui precede vivait en preparation ; ici les comptes marques « Creer »
-- entrent pour de bon dans T121PlanComptable.
--
-- Ce qu'il faut pour creer un compte, et d'ou cela vient :
--
--   Compte          le numero -- fourni, ou attribue dans la plage de la classe
--   Nom             le libelle -- repris de l'origine, modifiable
--   ClasseId        la sous-classe choisie par l'utilisateur
--   ClasseParentId  \
--   TypeBilan        > deduits de la sous-classe : ils y sont deja
--   Sens            /
--   Ordre           le numero, en entier
--
-- Le choix de la sous-classe revient a l'utilisateur : c'est une decision
-- comptable. Le reste se deduit, il n'y a pas a le lui demander.
--
-- L'operation est rejouable : un compte deja cree porte son PlanComptableId
-- dans staging.CorrespondanceCompte et n'est pas recree.
--
-- T121PlanComptable.Id n'est PAS une colonne identite -- comme
-- T200JobDefinition. Le numero suivant se calcule sous verrou.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
GO
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) s0765GetSousClasses — les sous-classes de la compagnie, par nature
--
--    La nature filtre : on ne propose pas de ranger une charge dans l'actif.
--    @Nature nul rend tout, pour les cas ou l'origine ne dit rien.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0765GetSousClasses]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Nature      VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT sc.[Id], sc.[Code], sc.[Description], sc.[NumeroDebut], sc.[NumeroFin],
           p.[Code] AS ParentCode, p.[Description] AS ParentDescription,
           dbo.fn_NatureCompte(p.[Code]) AS Nature
      FROM dbo.T120PlanComptable_Classe sc
      JOIN dbo.T120PlanComptable_Classe p ON p.[Id] = sc.[ParentId]
     WHERE sc.[CompanyGUID] = @CompanyGUID
       AND sc.[Niveau] = 2
       AND ISNULL(sc.[Actif], 1) = 1
       AND (@Nature IS NULL
            OR dbo.fn_NatureCompte(p.[Code]) IS NULL
            OR dbo.fn_NatureCompte(p.[Code]) = @Nature)
     ORDER BY sc.[NumeroDebut];
END
GO

-- -----------------------------------------------------------------------------
-- 2) s0766GetAAppliquer — l'etat du lot avant d'appliquer
--
--    Un jeu de resultats par question : ce qui reste a faire, et le compte
--    rendu de ce qui est deja regle.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0766GetAAppliquer]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT [SystemeSource] FROM staging.ImportLot
          WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID);

    IF @Systeme IS NULL
        THROW 50330, 'Lot d''importation introuvable pour cette compagnie.', 1;

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
     WHERE p.[LotId] = @LotId
       AND p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] IN ('OK', 'EXISTE');

    -- 1er jeu : les comptes a creer qui ne le sont pas encore
    SELECT [LigneNo], [CleSource], [Nom], [TypeNormalise],
           ISNULL(NULLIF([NomCible], ''), [Nom]) AS NomPropose,
           [CompteCible]
      FROM @src
     WHERE [Action] = 'CREER'
       AND [PlanComptableId] IS NULL
     ORDER BY [LigneNo];

    -- 2e jeu : le decompte
    SELECT
        SUM(CASE WHEN [Action] = 'CREER'   AND [PlanComptableId] IS NULL     THEN 1 ELSE 0 END) AS ACreer,
        SUM(CASE WHEN [Action] = 'CREER'   AND [PlanComptableId] IS NOT NULL THEN 1 ELSE 0 END) AS DejaCrees,
        SUM(CASE WHEN [Action] = 'LIER'                                       THEN 1 ELSE 0 END) AS Lies,
        SUM(CASE WHEN [Action] = 'IGNORER'                                    THEN 1 ELSE 0 END) AS Ignores,
        SUM(CASE WHEN [Action] IS NULL                                        THEN 1 ELSE 0 END) AS ADecider,
        COUNT(*)                                                                                AS Total
      FROM @src;

    -- 3e jeu : le lot lui-meme
    SELECT [Id], [NomFichier], [SystemeSource], [Statut], [AppliqueLe]
      FROM staging.ImportLot
     WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0767AppliquerPlanComptable — la creation
--
--    @Lignes : [{ "CleSource": "...", "ClasseId": 980,
--                 "Compte": "1060" | "", "Nom": "..." }]
--
--    Le numero est facultatif : laisse vide, il est attribue dans la plage
--    de la sous-classe, de preference sur une dizaine ronde.
--
--    Tout ou rien : une seule ligne fautive et rien n'est cree. On ne veut
--    pas d'un plan comptable a moitie repris.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0767AppliquerPlanComptable]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = NULL,
    @Lignes      NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT [SystemeSource] FROM staging.ImportLot
          WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID);

    IF @Systeme IS NULL
        THROW 50331, 'Lot d''importation introuvable pour cette compagnie.', 1;

    DECLARE @d TABLE (
        Rang      INT IDENTITY(1,1),
        CleSource NVARCHAR(400),
        ClasseId  INT,
        Compte    VARCHAR(20),
        Nom       NVARCHAR(400)
    );

    INSERT INTO @d (CleSource, ClasseId, Compte, Nom)
    SELECT LTRIM(RTRIM(j.CleSource)), j.ClasseId,
           NULLIF(LTRIM(RTRIM(ISNULL(j.Compte, ''))), ''),
           NULLIF(LTRIM(RTRIM(ISNULL(j.Nom, ''))), '')
      FROM OPENJSON(@Lignes)
           WITH (
              CleSource NVARCHAR(400) '$.CleSource',
              ClasseId  INT           '$.ClasseId',
              Compte    VARCHAR(20)   '$.Compte',
              Nom       NVARCHAR(400) '$.Nom'
           ) j
     WHERE ISNULL(LTRIM(RTRIM(j.CleSource)), '') <> '';

    IF NOT EXISTS (SELECT 1 FROM @d)
        THROW 50332, 'Aucun compte à créer.', 1;

    -- ── Controles prealables, avant d'ecrire quoi que ce soit ────────────────
    DECLARE @faute NVARCHAR(400);

    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » : aucune classe choisie.'
      FROM @d d WHERE d.ClasseId IS NULL;
    IF @faute IS NOT NULL THROW 50333, @faute, 1;

    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » : cette classe n''appartient pas à votre plan.'
      FROM @d d
     WHERE NOT EXISTS (SELECT 1 FROM dbo.T120PlanComptable_Classe sc
                        WHERE sc.[Id] = d.ClasseId
                          AND sc.[CompanyGUID] = @CompanyGUID
                          AND sc.[Niveau] = 2);
    IF @faute IS NOT NULL THROW 50334, @faute, 1;

    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » : le nom du compte est vide.'
      FROM @d d WHERE d.Nom IS NULL;
    IF @faute IS NOT NULL THROW 50335, @faute, 1;

    -- Un numero fourni doit etre un nombre, tomber dans la plage de sa classe
    -- et etre libre. Le plan se lit par ses numeros : un numero hors plage
    -- range le compte au mauvais endroit dans tous les etats financiers.
    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » : « ' + d.Compte +
                          N' » n''est pas un numéro.'
      FROM @d d WHERE d.Compte IS NOT NULL AND TRY_CAST(d.Compte AS INT) IS NULL;
    IF @faute IS NOT NULL THROW 50336, @faute, 1;

    SELECT TOP 1 @faute = N'« ' + d.CleSource + N' » : le numéro ' + d.Compte +
                          N' est hors de la plage ' + CAST(sc.[NumeroDebut] AS NVARCHAR(10)) +
                          N'-' + CAST(sc.[NumeroFin] AS NVARCHAR(10)) + N' de la classe ' + sc.[Code] + N'.'
      FROM @d d
      JOIN dbo.T120PlanComptable_Classe sc ON sc.[Id] = d.ClasseId
     WHERE d.Compte IS NOT NULL
       AND TRY_CAST(d.Compte AS INT) NOT BETWEEN sc.[NumeroDebut] AND sc.[NumeroFin];
    IF @faute IS NOT NULL THROW 50337, @faute, 1;

    SELECT TOP 1 @faute = N'Le numéro ' + d.Compte + N' est déjà utilisé dans votre plan.'
      FROM @d d
     WHERE d.Compte IS NOT NULL
       AND EXISTS (SELECT 1 FROM dbo.T121PlanComptable pc
                    WHERE pc.[CompanyGUID] = @CompanyGUID AND pc.[Compte] = d.Compte);
    IF @faute IS NOT NULL THROW 50338, @faute, 1;

    SELECT TOP 1 @faute = N'Le numéro ' + d.Compte + N' est demandé deux fois.'
      FROM @d d
     WHERE d.Compte IS NOT NULL
     GROUP BY d.Compte HAVING COUNT(*) > 1;
    IF @faute IS NOT NULL THROW 50339, @faute, 1;

    -- ── La creation ─────────────────────────────────────────────────────────
    DECLARE @crees TABLE (CleSource NVARCHAR(400), Compte VARCHAR(20), Nom NVARCHAR(400), PlanId INT);

    BEGIN TRANSACTION;

    DECLARE @rang INT = 1, @max INT = (SELECT MAX(Rang) FROM @d);

    WHILE @rang <= @max
    BEGIN
        DECLARE @cle NVARCHAR(400), @classe INT, @num VARCHAR(20), @nom NVARCHAR(400);

        SET @cle = NULL; SET @classe = NULL; SET @num = NULL; SET @nom = NULL;

        SELECT @cle = CleSource, @classe = ClasseId, @num = Compte, @nom = Nom
          FROM @d WHERE Rang = @rang;

        IF @cle IS NULL BEGIN SET @rang += 1; CONTINUE; END

        -- Deja cree lors d'un passage precedent : on passe.
        IF EXISTS (SELECT 1 FROM staging.CorrespondanceCompte c
                    WHERE c.[CompanyGUID] = @CompanyGUID
                      AND c.[SystemeSource] = @Systeme
                      AND c.[CleSource] = @cle
                      AND c.[PlanComptableId] IS NOT NULL)
        BEGIN
            SET @rang += 1;
            CONTINUE;
        END

        DECLARE @debut INT, @fin INT, @parent INT, @typeBilan VARCHAR(10), @sens VARCHAR(10);
        SELECT @debut = sc.[NumeroDebut], @fin = sc.[NumeroFin], @parent = sc.[ParentId],
               @typeBilan = sc.[TypeBilan], @sens = sc.[Sens]
          FROM dbo.T120PlanComptable_Classe sc WITH (UPDLOCK, HOLDLOCK)
         WHERE sc.[Id] = @classe;

        -- Numero non fourni : le premier libre de la plage, dizaines rondes
        -- d'abord -- un plan comptable se lit mieux en 1060 qu'en 1051.
        IF @num IS NULL
        BEGIN
            ;WITH n AS (
                SELECT TOP (@fin - @debut + 1)
                       @debut + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS INT) - 1 AS v
                  FROM sys.all_objects
            )
            SELECT TOP 1 @num = CAST(n.v AS VARCHAR(20))
              FROM n
             WHERE NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable pc WITH (UPDLOCK, HOLDLOCK)
                                WHERE pc.[CompanyGUID] = @CompanyGUID
                                  AND TRY_CAST(pc.[Compte] AS INT) = n.v)
               -- ...ni un numero qu'une autre ligne du meme envoi reclame :
               -- l'attribution automatique ne doit pas prendre la place d'un
               -- numero impose plus bas dans la liste.
               AND NOT EXISTS (SELECT 1 FROM @d d2
                                WHERE TRY_CAST(d2.Compte AS INT) = n.v)
             ORDER BY CASE WHEN n.v % 10 = 0 THEN 0 ELSE 1 END, n.v;

            IF @num IS NULL
            BEGIN
                SET @faute = N'« ' + @cle + N' » : la plage de numéros de cette classe est pleine.';
                THROW 50340, @faute, 1;
            END
        END

        -- T121PlanComptable.Id n'est pas une identite.
        DECLARE @newId INT;
        SELECT @newId = ISNULL(MAX([Id]), 0) + 1
          FROM dbo.T121PlanComptable WITH (UPDLOCK, HOLDLOCK);

        INSERT INTO dbo.T121PlanComptable
            ([Id], [Compte], [Nom], [ClasseId], [ClasseParentId], [TypeBilan], [Sens],
             [Ordre], [Actif], [Systeme], [CompanyGUID], [NomFr])
        VALUES
            (@newId, @num, @nom, @classe, @parent, @typeBilan, @sens,
             CAST(@num AS INT), 1, 0, @CompanyGUID, @nom);

        UPDATE staging.CorrespondanceCompte
           SET [PlanComptableId] = @newId,
               [CompteCible]     = @num,
               [NomCible]        = @nom,
               [Modified]        = GETDATE(),
               [ModifiedBy]      = @UserId
         WHERE [CompanyGUID] = @CompanyGUID
           AND [SystemeSource] = @Systeme
           AND [CleSource] = @cle;

        INSERT INTO @crees (CleSource, Compte, Nom, PlanId)
        VALUES (@cle, @num, @nom, @newId);

        SET @rang += 1;
    END

    -- Le lot est applique quand plus rien n'attend : ni decision, ni creation.
    IF NOT EXISTS (
        SELECT 1
          FROM staging.ImportPlanComptable p
          LEFT JOIN staging.CorrespondanceCompte c
                 ON c.[CompanyGUID] = @CompanyGUID
                AND c.[SystemeSource] = @Systeme
                AND c.[CleSource] = p.[CleSource]
         WHERE p.[LotId] = @LotId
           AND p.[CompanyGUID] = @CompanyGUID
           AND p.[Statut] IN ('OK', 'EXISTE')
           AND (c.[Id] IS NULL
                OR (c.[Action] = 'CREER' AND c.[PlanComptableId] IS NULL)))
    BEGIN
        UPDATE staging.ImportLot
           SET [Statut] = 'APPLIQUE', [AppliqueLe] = GETDATE(), [AppliquePar] = @UserId
         WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID;
    END

    COMMIT TRANSACTION;

    SELECT CleSource, Compte, Nom, PlanId FROM @crees ORDER BY Compte;
END
GO

-- -----------------------------------------------------------------------------
-- 4) Note : la regle « un creer sans numero n'est pas enregistrable » a ete
--    retiree de T212 en meme temps que cette etape est apparue. Elle datait
--    d'avant : sans etape 3, un compte a creer restait sans numero pour
--    toujours. Maintenant que s0767 attribue le numero dans la plage de la
--    classe, l'exiger a l'etape 2 revient a le faire inventer avant de
--    savoir ou le compte sera range. Rejouer T212 apres T215.
-- -----------------------------------------------------------------------------

PRINT 'T215_Appliquer_plan_comptable.sql : termine.';
GO
