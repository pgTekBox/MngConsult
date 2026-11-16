-- =============================================================================
-- T393 — Actions permises à un employé dans un dossier
-- Dans « Gérer les dossiers », l'administrateur choisit, pour chaque dossier
-- confié à un employé, les actions qu'il peut y faire (les zones de l'ERP du
-- client) :
--   revenus, paiements, processeurs, rapports, comptabilite, taxes,
--   agenda, employes, produits, parametres
-- Aucune ligne pour (employé, dossier) = toutes les actions (comportement
-- d'avant). Les administrateurs du cabinet (admin / solo) ne sont jamais
-- restreints. Appliqué dans l'ERP : menu (entrées masquées) et pages (accès
-- refusé) — cf. App_Code/clsActionsDossier.vb.
--   T336DossierAction
--   s1014ListActionsMembre    : (CompanyGUID, Action) d'un membre (admin / solo)
--   s1015SetActionsDossier    : remplace les actions d'un membre dans un dossier
--                               (@Actions = liste « a,b,c » ; '*' = toutes)
--                               ErrorCode : 0 OK, 2 non autorisé, 5 introuvable
--   s1016GetActionsPermises   : pour l'utilisateur connecté dans une compagnie :
--                               Restreint = 1 + les actions, ou Restreint = 0
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T336DossierAction') IS NULL
BEGIN
    CREATE TABLE dbo.T336DossierAction (
        Id          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T336DossierAction PRIMARY KEY,
        CabinetId   INT NOT NULL,
        CompanyGUID UNIQUEIDENTIFIER NOT NULL,
        UserGUID    UNIQUEIDENTIFIER NOT NULL,
        Action      NVARCHAR(30) NOT NULL,
        CreatedUtc  DATETIME2 NOT NULL CONSTRAINT DF_T336_Created DEFAULT (SYSUTCDATETIME())
    );
    CREATE UNIQUE INDEX UX_T336_Dossier_User_Action ON dbo.T336DossierAction (CompanyGUID, UserGUID, Action);
    CREATE INDEX IX_T336_User ON dbo.T336DossierAction (UserGUID, CompanyGUID);
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
    SELECT a.CompanyGUID, a.Action
    FROM dbo.T336DossierAction a
    WHERE a.CabinetId = @cabId AND a.UserGUID = @membre
    ORDER BY a.CompanyGUID, a.Action;
END
GO

CREATE OR ALTER PROCEDURE dbo.s1015SetActionsDossier
    @UserId      varchar(200),
    @MembreId    int,
    @CompanyGUID uniqueidentifier,
    @Actions     nvarchar(500),
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
    -- Le dossier doit être dans le périmètre du cabinet
    IF @CompanyGUID IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.fCabinetDossiers((SELECT TOP 1 u.UserGUID FROM dbo.T015User u WHERE u.email = @UserId AND u.IsDeleted = 0)) f
                                            WHERE f.CompanyGUID = @CompanyGUID)
    BEGIN SET @ErrorCode = 5; RETURN; END

    DECLARE @connues TABLE (Action nvarchar(30) PRIMARY KEY);
    INSERT INTO @connues VALUES ('revenus'), ('paiements'), ('processeurs'), ('rapports'), ('comptabilite'),
                                ('taxes'), ('agenda'), ('employes'), ('produits'), ('parametres');

    DECLARE @voulues TABLE (Action nvarchar(30) PRIMARY KEY);
    INSERT INTO @voulues
    SELECT DISTINCT LOWER(LTRIM(RTRIM(s.value)))
    FROM STRING_SPLIT(ISNULL(@Actions, ''), ',') s
    WHERE LOWER(LTRIM(RTRIM(s.value))) IN (SELECT Action FROM @connues);

    BEGIN TRAN;
    DELETE FROM dbo.T336DossierAction WHERE CabinetId = @cabId AND CompanyGUID = @CompanyGUID AND UserGUID = @membre;
    -- '*' ou toutes les actions cochées = aucune restriction (pas de lignes)
    IF LTRIM(RTRIM(ISNULL(@Actions, ''))) <> '*'
       AND (SELECT COUNT(*) FROM @voulues) < (SELECT COUNT(*) FROM @connues)
    BEGIN
        INSERT INTO dbo.T336DossierAction (CabinetId, CompanyGUID, UserGUID, Action)
        SELECT @cabId, @CompanyGUID, @membre, Action FROM @voulues;
        -- Aucune action cochée : une ligne « aucune » garde la restriction totale
        IF NOT EXISTS (SELECT 1 FROM @voulues)
            INSERT INTO dbo.T336DossierAction (CabinetId, CompanyGUID, UserGUID, Action)
            VALUES (@cabId, @CompanyGUID, @membre, 'aucune');
    END
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
        SELECT CAST(0 AS bit) AS Restreint, CAST(NULL AS nvarchar(30)) AS Action;
        RETURN;
    END

    SELECT CAST(1 AS bit) AS Restreint, Action
    FROM dbo.T336DossierAction
    WHERE UserGUID = @uid AND CompanyGUID = @CompanyGUID;
END
GO
