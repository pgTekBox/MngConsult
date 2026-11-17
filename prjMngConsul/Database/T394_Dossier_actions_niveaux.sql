-- =============================================================================
-- T394 — Un niveau d'accès par action dans un dossier
-- Suite de T393 : au lieu d'une case (permis / pas permis), chaque action d'un
-- dossier reçoit un NIVEAU choisi dans une liste déroulante. Les niveaux sont
-- un catalogue (T338NiveauAcces) pour pouvoir en ajouter plus tard :
--   aucun     : Aucun accès      — la zone est masquée et ses pages refusées
--   restreint : Accès restreint  — la zone est ouverte ; les pages pourront
--                                  limiter ce qu'on y fait (NiveauDe)
--   complet   : Accès complet
-- Toutes les actions en « complet » = aucune restriction (aucune ligne).
--   T338NiveauAcces (Code, NomFr/En/Es, Ordre, PermetPage)
--   T336DossierAction.Niveau
--   s1014ListActionsMembre : (CompanyGUID, Action, Niveau) + 2e jeu = le catalogue
--   s1015SetActionsDossier : @Actions = « action:niveau,… » ; '*' = tout complet
--   s1016GetActionsPermises : Restreint, Action, Niveau, PermetPage
--   s1017ListNiveauxAcces  : le catalogue des niveaux
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T338NiveauAcces') IS NULL
BEGIN
    CREATE TABLE dbo.T338NiveauAcces (
        Code       NVARCHAR(20) NOT NULL CONSTRAINT PK_T338NiveauAcces PRIMARY KEY,
        NomFr      NVARCHAR(60) NOT NULL,
        NomEn      NVARCHAR(60) NOT NULL,
        NomEs      NVARCHAR(60) NOT NULL,
        Ordre      INT NOT NULL,
        PermetPage BIT NOT NULL      -- 0 = la zone est fermée (menu masqué, pages refusées)
    );
END
GO
MERGE dbo.T338NiveauAcces AS t
USING (VALUES ('aucun',     N'Aucun accès',     N'No access',         N'Sin acceso',        1, 0),
              ('restreint', N'Accès restreint', N'Restricted access', N'Acceso restringido', 2, 1),
              ('complet',   N'Accès complet',   N'Full access',       N'Acceso completo',    3, 1)) AS s (Code, NomFr, NomEn, NomEs, Ordre, PermetPage)
ON t.Code = s.Code
WHEN MATCHED THEN UPDATE SET NomFr = s.NomFr, NomEn = s.NomEn, NomEs = s.NomEs, Ordre = s.Ordre, PermetPage = s.PermetPage
WHEN NOT MATCHED THEN INSERT (Code, NomFr, NomEn, NomEs, Ordre, PermetPage) VALUES (s.Code, s.NomFr, s.NomEn, s.NomEs, s.Ordre, s.PermetPage);
GO

IF COL_LENGTH('dbo.T336DossierAction', 'Niveau') IS NULL
    ALTER TABLE dbo.T336DossierAction ADD Niveau NVARCHAR(20) NOT NULL CONSTRAINT DF_T336_Niveau DEFAULT ('complet');
GO
-- Ancienne ligne sentinelle « aucune » (T393) : les actions de ce dossier passent à « aucun »
DELETE FROM dbo.T336DossierAction WHERE Action = 'aucune';
GO

CREATE OR ALTER PROCEDURE dbo.s1017ListNiveauxAcces
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Code, NomFr, NomEn, NomEs, Ordre, PermetPage FROM dbo.T338NiveauAcces ORDER BY Ordre;
END
GO

CREATE OR ALTER PROCEDURE dbo.s1014ListActionsMembre
    @UserId   varchar(200),
    @MembreId int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @cabId int, @role nvarchar(20);
    SELECT TOP 1 @cabId = m.CabinetId, @role = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;
    IF @cabId IS NULL OR @role NOT IN ('admin', 'solo') RETURN;

    DECLARE @membre uniqueidentifier = (SELECT UserGUID FROM dbo.T332CabinetMembre
                                        WHERE Id = @MembreId AND CabinetId = @cabId AND IsActive = 1);
    SELECT a.CompanyGUID, a.Action, a.Niveau
    FROM dbo.T336DossierAction a
    WHERE a.CabinetId = @cabId AND a.UserGUID = @membre
    ORDER BY a.CompanyGUID, a.Action;

    SELECT Code, NomFr, NomEn, NomEs, Ordre, PermetPage FROM dbo.T338NiveauAcces ORDER BY Ordre;
END
GO

CREATE OR ALTER PROCEDURE dbo.s1015SetActionsDossier
    @UserId      varchar(200),
    @MembreId    int,
    @CompanyGUID uniqueidentifier,
    @Actions     nvarchar(1000),
    @ErrorCode   int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;
    DECLARE @cabId int, @role nvarchar(20);
    SELECT TOP 1 @cabId = m.CabinetId, @role = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;
    IF @cabId IS NULL OR @role NOT IN ('admin', 'solo') BEGIN SET @ErrorCode = 2; RETURN; END

    DECLARE @membre uniqueidentifier = (SELECT UserGUID FROM dbo.T332CabinetMembre
                                        WHERE Id = @MembreId AND CabinetId = @cabId AND IsActive = 1);
    IF @membre IS NULL BEGIN SET @ErrorCode = 5; RETURN; END
    IF @CompanyGUID IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.fCabinetDossiers((SELECT TOP 1 u.UserGUID FROM dbo.T015User u WHERE u.email = @UserId AND u.IsDeleted = 0)) f
                                            WHERE f.CompanyGUID = @CompanyGUID)
    BEGIN SET @ErrorCode = 5; RETURN; END

    DECLARE @connues TABLE (Action nvarchar(30) PRIMARY KEY);
    INSERT INTO @connues VALUES ('revenus'), ('paiements'), ('processeurs'), ('rapports'), ('comptabilite'),
                                ('taxes'), ('agenda'), ('employes'), ('produits'), ('parametres');

    -- « action:niveau » ; une action absente ou un niveau inconnu = aucun accès
    DECLARE @voulues TABLE (Action nvarchar(30) PRIMARY KEY, Niveau nvarchar(20));
    IF LTRIM(RTRIM(ISNULL(@Actions, ''))) = '*'
        INSERT INTO @voulues SELECT Action, 'complet' FROM @connues;
    ELSE
    BEGIN
        INSERT INTO @voulues (Action, Niveau)
        SELECT c.Action, ISNULL(n.Code, 'aucun')
        FROM @connues c
        OUTER APPLY (SELECT TOP 1 LOWER(LTRIM(RTRIM(SUBSTRING(s.value, CHARINDEX(':', s.value) + 1, 50)))) AS Niv
                     FROM STRING_SPLIT(ISNULL(@Actions, ''), ',') s
                     WHERE CHARINDEX(':', s.value) > 0
                       AND LOWER(LTRIM(RTRIM(LEFT(s.value, CHARINDEX(':', s.value) - 1)))) = c.Action) v
        LEFT JOIN dbo.T338NiveauAcces n ON n.Code = v.Niv;
    END

    BEGIN TRAN;
    DELETE FROM dbo.T336DossierAction WHERE CabinetId = @cabId AND CompanyGUID = @CompanyGUID AND UserGUID = @membre;
    -- Tout « complet » = aucune restriction (aucune ligne)
    IF EXISTS (SELECT 1 FROM @voulues WHERE Niveau <> 'complet')
        INSERT INTO dbo.T336DossierAction (CabinetId, CompanyGUID, UserGUID, Action, Niveau)
        SELECT @cabId, @CompanyGUID, @membre, Action, Niveau FROM @voulues;
    COMMIT;
END
GO

CREATE OR ALTER PROCEDURE dbo.s1016GetActionsPermises
    @UserId      varchar(200),
    @CompanyGUID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @uid uniqueidentifier, @role nvarchar(20);
    SELECT TOP 1 @uid = u.UserGUID, @role = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    IF @uid IS NULL OR @role IN ('admin', 'solo')
       OR NOT EXISTS (SELECT 1 FROM dbo.T336DossierAction WHERE UserGUID = @uid AND CompanyGUID = @CompanyGUID)
    BEGIN
        SELECT CAST(0 AS bit) AS Restreint, CAST(NULL AS nvarchar(30)) AS Action,
               CAST(NULL AS nvarchar(20)) AS Niveau, CAST(1 AS bit) AS PermetPage;
        RETURN;
    END

    SELECT CAST(1 AS bit) AS Restreint, a.Action, a.Niveau, ISNULL(n.PermetPage, 0) AS PermetPage
    FROM dbo.T336DossierAction a
    LEFT JOIN dbo.T338NiveauAcces n ON n.Code = a.Niveau
    WHERE a.UserGUID = @uid AND a.CompanyGUID = @CompanyGUID;
END
GO
