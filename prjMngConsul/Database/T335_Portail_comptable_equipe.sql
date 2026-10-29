-- =============================================================================
-- T335_Portail_comptable_equipe.sql
-- Phase 2 du Portail comptable : UI de gestion d'equipe.
--   * fCabinetDossiers(@UserGUID) : les compagnies accessibles a un membre de
--     cabinet selon son role (admin/solo = toutes celles des membres ;
--     responsable = son equipe ; employe = ses affectations T334).
--   * s0210GetUserCompanies / s0211ValidateCompanyAccess ETENDUES : un comptable
--     membre d'un cabinet est scope par le perimetre du cabinet (sinon logique
--     ComptableGUID actuelle). Sans ca, un employe ne verrait pas / ne pourrait
--     pas entrer dans un dossier qu'on lui affecte.
--   * s0922-s0930 : membres (invitation par courriel), equipes, affectation.
-- Procs libres ensuite : s0931+. Dernier script : T335.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ---------------------------------------------------------------------------
-- fCabinetDossiers : CompanyGUID des dossiers accessibles a un membre, par role.
-- Vide si l'utilisateur n'est membre d'aucun cabinet actif.
-- ---------------------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fCabinetDossiers(@UserGUID uniqueidentifier)
RETURNS @r TABLE (CompanyGUID uniqueidentifier PRIMARY KEY)
AS
BEGIN
    DECLARE @cabId int, @role nvarchar(20), @equipeId int;
    SELECT TOP 1 @cabId = m.CabinetId, @role = m.Role, @equipeId = m.EquipeId
    FROM dbo.T332CabinetMembre m
    JOIN dbo.T331Cabinet cab ON cab.Id = m.CabinetId AND cab.IsActive = 1
    WHERE m.UserGUID = @UserGUID AND m.IsActive = 1
    ORDER BY m.Id;

    IF @cabId IS NULL
        RETURN;

    IF @role IN ('admin', 'solo')
        INSERT INTO @r (CompanyGUID)
        SELECT c.CompanyGUID
        FROM dbo.T010Company c
        WHERE c.ComptableGUID IN (
            SELECT UserGUID FROM dbo.T332CabinetMembre WHERE CabinetId = @cabId AND IsActive = 1
        );
    ELSE IF @role = 'responsable'
        INSERT INTO @r (CompanyGUID)
        SELECT DISTINCT d.CompanyGUID
        FROM dbo.T334CabinetDossier d
        WHERE d.CabinetId = @cabId AND d.EquipeId = @equipeId;
    ELSE
        INSERT INTO @r (CompanyGUID)
        SELECT DISTINCT d.CompanyGUID
        FROM dbo.T334CabinetDossier d
        WHERE d.CabinetId = @cabId AND d.AssignedUserGUID = @UserGUID;

    RETURN;
END
GO

-- ---------------------------------------------------------------------------
-- s0210GetUserCompanies (ETENDUE) : un comptable membre d'un cabinet est scope
-- par le perimetre du cabinet ; un comptable hors cabinet garde la logique
-- ComptableGUID ; un utilisateur normal garde sa compagnie maison.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0210GetUserCompanies]
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IsAccountant BIT = 0;
    DECLARE @UserCompanyGUID UNIQUEIDENTIFIER;
    DECLARE @UserGUID UNIQUEIDENTIFIER;
    SELECT
        @IsAccountant = IsAccountant,
        @UserCompanyGUID = CompanyGUID,
        @UserGUID  = UserGUID
    FROM dbo.T015User
    WHERE email = @UserId
      AND IsDeleted = 0;

    IF @IsAccountant = 1
       AND EXISTS (SELECT 1 FROM dbo.T332CabinetMembre m
                   JOIN dbo.T331Cabinet cab ON cab.Id = m.CabinetId AND cab.IsActive = 1
                   WHERE m.UserGUID = @UserGUID AND m.IsActive = 1)
    BEGIN
        -- Comptable membre d'un cabinet : perimetre du cabinet selon son role
        SELECT
            c.CompanyGUID,
            dbo.fCompanyName(c.CompanyGUID) AS Name,
            dbo.fParamS(c.CompanyGUID, 'LEGAL_NAME') AS LegalName,
            c.CompanyCode
        FROM dbo.T010Company c
        JOIN dbo.fCabinetDossiers(@UserGUID) d ON d.CompanyGUID = c.CompanyGUID
        ORDER BY Name;
    END
    ELSE IF @IsAccountant = 1
    BEGIN
        -- Comptable hors cabinet : ses compagnies (ComptableGUID)
        SELECT
            c.CompanyGUID,
            dbo.fCompanyName(c.CompanyGUID) AS Name,
            dbo.fParamS(c.CompanyGUID, 'LEGAL_NAME') AS LegalName,
            c.CompanyCode
        FROM dbo.T010Company c
        WHERE c.[ComptableGUID] = @UserGUID
        ORDER BY Name;
    END
    ELSE
    BEGIN
        -- Utilisateur normal : uniquement sa compagnie
        SELECT
            c.CompanyGUID,
            dbo.fCompanyName(c.CompanyGUID) AS Name,
            dbo.fParamS(c.CompanyGUID, 'LEGAL_NAME') AS LegalName,
            c.CompanyCode
        FROM dbo.T010Company c
        WHERE c.CompanyGUID = @UserCompanyGUID;
    END
END
GO

-- ---------------------------------------------------------------------------
-- s0211ValidateCompanyAccess (ETENDUE) : meme regle de perimetre que s0210.
-- (Re-definit la version du script T306.)
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0211ValidateCompanyAccess]
    @UserId       varchar(200),
    @CompanyGUID  UNIQUEIDENTIFIER,
    @HasAccess    BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @HasAccess = 0;
    DECLARE @IsAccountant BIT = 0;
    DECLARE @UserCompanyGUID UNIQUEIDENTIFIER;
    DECLARE @UserGUID UNIQUEIDENTIFIER;
    SELECT
        @IsAccountant = IsAccountant,
        @UserCompanyGUID = CompanyGUID,
        @UserGUID = UserGUID
    FROM dbo.T015User
    WHERE email = @UserId
      AND IsDeleted = 0
      AND IsActive = 1;

    IF @IsAccountant = 1
       AND EXISTS (SELECT 1 FROM dbo.T332CabinetMembre m
                   JOIN dbo.T331Cabinet cab ON cab.Id = m.CabinetId AND cab.IsActive = 1
                   WHERE m.UserGUID = @UserGUID AND m.IsActive = 1)
    BEGIN
        -- Comptable membre d'un cabinet : acces borne au perimetre du cabinet
        IF EXISTS (SELECT 1 FROM dbo.fCabinetDossiers(@UserGUID) WHERE CompanyGUID = @CompanyGUID)
            SET @HasAccess = 1;
    END
    ELSE IF @IsAccountant = 1
    BEGIN
        IF @UserCompanyGUID = @CompanyGUID
           OR EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @CompanyGUID AND ComptableGUID = @UserGUID)
            SET @HasAccess = 1;
    END
    ELSE
    BEGIN
        IF @UserCompanyGUID = @CompanyGUID
            SET @HasAccess = 1;
    END
END
GO

-- ---------------------------------------------------------------------------
-- s0922ListCabinetMembres : les membres du cabinet de l'appelant.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0922ListCabinetMembres
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @uid uniqueidentifier, @cabId int;
    SELECT TOP 1 @uid = u.UserGUID, @cabId = m.CabinetId
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    SELECT
        m.Id            AS MembreId,
        m.UserGUID,
        u.Email,
        u.FirstName,
        u.LastName,
        m.Role,
        m.EquipeId,
        eq.Nom          AS EquipeNom,
        u.IsActive,
        CAST(CASE WHEN u.IsActive = 0 THEN 1 ELSE 0 END AS bit) AS Pending,
        CAST(CASE WHEN u.UserGUID = @uid THEN 1 ELSE 0 END AS bit) AS IsMe
    FROM dbo.T332CabinetMembre m
    JOIN dbo.T015User u      ON u.UserGUID = m.UserGUID AND u.IsDeleted = 0
    LEFT JOIN dbo.T333Equipe eq ON eq.Id = m.EquipeId
    WHERE m.CabinetId = @cabId AND m.IsActive = 1
    ORDER BY u.FirstName, u.LastName, u.Email;
END
GO

-- ---------------------------------------------------------------------------
-- s0923InviteCabinetMembre : cree un compte comptable (IsAccountant=1,
-- IsActive=0 + jeton) rattache au cabinet de l'appelant (admin/solo).
-- ErrorCode : 0=OK, 1=courriel deja utilise, 2=appelant non autorise, >=10000 exception.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0923InviteCabinetMembre
    @UserId          varchar(200),
    @Email           nvarchar(200),
    @FirstName       nvarchar(100) = NULL,
    @LastName        nvarchar(100) = NULL,
    @Role            nvarchar(20),
    @EquipeId        int = NULL,
    @HomeCompanyGUID uniqueidentifier,
    @PlaceholderHash nvarchar(500),
    @Token           uniqueidentifier OUTPUT,
    @NewUserId       int OUTPUT,
    @ErrorCode       int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0; SET @Token = NULL; SET @NewUserId = NULL;

    DECLARE @cabId int, @callerRole nvarchar(20), @callerMembreId int;
    SELECT TOP 1 @cabId = m.CabinetId, @callerRole = m.Role, @callerMembreId = m.Id
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    JOIN dbo.T331Cabinet cab     ON cab.Id = m.CabinetId AND cab.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    IF @cabId IS NULL OR @callerRole NOT IN ('admin', 'solo') BEGIN SET @ErrorCode = 2; RETURN; END
    IF EXISTS (SELECT 1 FROM dbo.T015User WHERE email = @Email AND IsDeleted = 0) BEGIN SET @ErrorCode = 1; RETURN; END

    IF @Role NOT IN ('admin', 'responsable', 'employe') SET @Role = 'employe';
    SET @Token = NEWID();

    BEGIN TRY
        BEGIN TRAN;
        INSERT INTO dbo.T015User
            (CompanyGUID, Email, PasswordHash, FirstName, LastName,
             IsAdmin, IsAccountant, IsActive, IsEmailVerified,
             ActivationToken, ActivationExpires, CreatedBy)
        VALUES
            (@HomeCompanyGUID, @Email, @PlaceholderHash, @FirstName, @LastName,
             0, 1, 0, 0,
             @Token, DATEADD(DAY, 7, GETDATE()), N'cabinet-invite');
        SET @NewUserId = SCOPE_IDENTITY();

        DECLARE @uid uniqueidentifier;
        SELECT @uid = UserGUID FROM dbo.T015User WHERE Id = @NewUserId;

        INSERT INTO dbo.T332CabinetMembre (CabinetId, UserGUID, Role, EquipeId)
        VALUES (@cabId, @uid, @Role, @EquipeId);

        -- un cabinet solo qui recrute devient administre
        IF @callerRole = 'solo'
            UPDATE dbo.T332CabinetMembre SET Role = 'admin' WHERE Id = @callerMembreId;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        IF ERROR_NUMBER() IN (2601, 2627) SET @ErrorCode = 1; ELSE SET @ErrorCode = 10000 + ERROR_NUMBER();
        SET @Token = NULL; SET @NewUserId = NULL;
    END CATCH
END
GO

-- ---------------------------------------------------------------------------
-- s0924UpdateCabinetMembre : role / equipe / actif d'un membre.
-- ErrorCode : 0=OK, 2=non autorise, 3=dernier admin, 4=soi-meme desactive, 5=introuvable.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0924UpdateCabinetMembre
    @UserId    varchar(200),
    @MembreId  int,
    @Role      nvarchar(20),
    @EquipeId  int = NULL,
    @IsActive  bit,
    @ErrorCode int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;

    DECLARE @uid uniqueidentifier, @cabId int, @callerRole nvarchar(20);
    SELECT TOP 1 @uid = u.UserGUID, @cabId = m.CabinetId, @callerRole = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    IF @cabId IS NULL OR @callerRole NOT IN ('admin', 'solo') BEGIN SET @ErrorCode = 2; RETURN; END
    IF @Role NOT IN ('admin', 'responsable', 'employe', 'solo') SET @Role = 'employe';

    DECLARE @tUser uniqueidentifier, @tRole nvarchar(20), @tCab int;
    SELECT @tUser = UserGUID, @tRole = Role, @tCab = CabinetId
    FROM dbo.T332CabinetMembre WHERE Id = @MembreId AND IsActive = 1;

    IF @tUser IS NULL OR @tCab <> @cabId BEGIN SET @ErrorCode = 5; RETURN; END

    -- soi-meme : interdit de se desactiver
    IF @tUser = @uid AND @IsActive = 0 BEGIN SET @ErrorCode = 4; RETURN; END

    -- dernier admin : interdit de retirer admin / desactiver
    IF @tRole = 'admin' AND (@Role <> 'admin' OR @IsActive = 0)
    BEGIN
        DECLARE @nbAdmin int;
        SELECT @nbAdmin = COUNT(*)
        FROM dbo.T332CabinetMembre m2
        JOIN dbo.T015User u2 ON u2.UserGUID = m2.UserGUID AND u2.IsDeleted = 0 AND u2.IsActive = 1
        WHERE m2.CabinetId = @cabId AND m2.IsActive = 1 AND m2.Role IN ('admin', 'solo');
        IF @nbAdmin <= 1 BEGIN SET @ErrorCode = 3; RETURN; END
    END

    UPDATE dbo.T332CabinetMembre SET Role = @Role, EquipeId = @EquipeId WHERE Id = @MembreId;
    UPDATE dbo.T015User SET IsActive = @IsActive WHERE UserGUID = @tUser;
END
GO

-- ---------------------------------------------------------------------------
-- s0925GetMembreByInviteToken : infos d'invitation si jeton valide/non expire/non active.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0925GetMembreByInviteToken
    @Token uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.Email, u.FirstName, u.LastName, cab.Nom AS CabinetNom
    FROM dbo.T015User u
    LEFT JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    LEFT JOIN dbo.T331Cabinet cab     ON cab.Id = m.CabinetId
    WHERE u.ActivationToken = @Token
      AND u.IsDeleted = 0
      AND u.IsActive = 0
      AND u.ActivationExpires > GETDATE();
END
GO

-- ---------------------------------------------------------------------------
-- s0926AcceptInvitation : le membre pose son mot de passe et active son compte.
-- Result : 1=OK, -1=expire, -2=deja active, 0=jeton invalide.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0926AcceptInvitation
    @Token        uniqueidentifier,
    @PasswordHash nvarchar(500),
    @FirstName    nvarchar(100) = NULL,
    @LastName     nvarchar(100) = NULL,
    @Result       int OUTPUT,
    @UserId       int OUTPUT,
    @Email        nvarchar(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Result = 0; SET @UserId = NULL; SET @Email = NULL;

    DECLARE @id int, @active bit, @exp datetime;
    SELECT @id = Id, @active = IsActive, @exp = ActivationExpires, @Email = Email
    FROM dbo.T015User WHERE ActivationToken = @Token AND IsDeleted = 0;

    IF @id IS NULL BEGIN SET @Result = 0; RETURN; END
    IF @active = 1 BEGIN SET @Result = -2; RETURN; END
    IF @exp IS NULL OR @exp < GETDATE() BEGIN SET @Result = -1; RETURN; END

    UPDATE dbo.T015User
    SET PasswordHash = @PasswordHash,
        IsActive = 1,
        IsEmailVerified = 1,
        ActivatedOn = GETDATE(),
        ActivationToken = NULL,
        ActivationExpires = NULL,
        FirstName = ISNULL(NULLIF(@FirstName, N''), FirstName),
        LastName = ISNULL(NULLIF(@LastName, N''), LastName)
    WHERE Id = @id;

    SET @UserId = @id;
    SET @Result = 1;
END
GO

-- ---------------------------------------------------------------------------
-- s0927ResendInvite : regenere le jeton d'un membre en attente du cabinet.
-- ErrorCode : 0=OK, 2=non autorise, 5=introuvable/deja actif.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0927ResendInvite
    @UserId    varchar(200),
    @MembreId  int,
    @Token     uniqueidentifier OUTPUT,
    @Email     nvarchar(200) OUTPUT,
    @ErrorCode int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0; SET @Token = NULL; SET @Email = NULL;

    DECLARE @cabId int, @callerRole nvarchar(20);
    SELECT TOP 1 @cabId = m.CabinetId, @callerRole = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    IF @cabId IS NULL OR @callerRole NOT IN ('admin', 'solo') BEGIN SET @ErrorCode = 2; RETURN; END

    DECLARE @tUserId int, @tUser uniqueidentifier;
    SELECT @tUser = m.UserGUID FROM dbo.T332CabinetMembre m WHERE m.Id = @MembreId AND m.CabinetId = @cabId AND m.IsActive = 1;
    IF @tUser IS NULL BEGIN SET @ErrorCode = 5; RETURN; END

    SELECT @tUserId = Id, @Email = Email FROM dbo.T015User WHERE UserGUID = @tUser AND IsDeleted = 0 AND IsActive = 0;
    IF @tUserId IS NULL BEGIN SET @ErrorCode = 5; SET @Email = NULL; RETURN; END

    SET @Token = NEWID();
    UPDATE dbo.T015User SET ActivationToken = @Token, ActivationExpires = DATEADD(DAY, 7, GETDATE()) WHERE Id = @tUserId;
END
GO

-- ---------------------------------------------------------------------------
-- s0928ListEquipes : les equipes du cabinet de l'appelant.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0928ListEquipes
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @cabId int;
    SELECT TOP 1 @cabId = m.CabinetId
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    SELECT
        eq.Id,
        eq.Nom,
        eq.ResponsableUserGUID,
        ru.FirstName + ' ' + ru.LastName AS ResponsableNom,
        eq.IsActive,
        (SELECT COUNT(*) FROM dbo.T332CabinetMembre mm WHERE mm.EquipeId = eq.Id AND mm.IsActive = 1) AS NbMembres
    FROM dbo.T333Equipe eq
    LEFT JOIN dbo.T015User ru ON ru.UserGUID = eq.ResponsableUserGUID
    WHERE eq.CabinetId = @cabId AND eq.IsActive = 1
    ORDER BY eq.Nom;
END
GO

-- ---------------------------------------------------------------------------
-- s0929SaveEquipe : upsert d'une equipe dans le cabinet de l'appelant (admin/solo).
-- ErrorCode : 0=OK, 2=non autorise.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0929SaveEquipe
    @UserId              varchar(200),
    @Id                  int,
    @Nom                 nvarchar(100),
    @ResponsableUserGUID uniqueidentifier = NULL,
    @IsActive            bit = 1,
    @NewId               int OUTPUT,
    @ErrorCode           int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0; SET @NewId = @Id;

    DECLARE @cabId int, @callerRole nvarchar(20);
    SELECT TOP 1 @cabId = m.CabinetId, @callerRole = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    IF @cabId IS NULL OR @callerRole NOT IN ('admin', 'solo') BEGIN SET @ErrorCode = 2; RETURN; END

    IF @Id = 0
    BEGIN
        INSERT INTO dbo.T333Equipe (CabinetId, Nom, ResponsableUserGUID, IsActive)
        VALUES (@cabId, @Nom, @ResponsableUserGUID, @IsActive);
        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.T333Equipe
        SET Nom = @Nom, ResponsableUserGUID = @ResponsableUserGUID, IsActive = @IsActive
        WHERE Id = @Id AND CabinetId = @cabId;
    END
END
GO

-- ---------------------------------------------------------------------------
-- s0930AssignDossier : affecte un dossier (compagnie) a un membre / une equipe.
-- Valide que la compagnie appartient bien au cabinet de l'appelant.
-- ErrorCode : 0=OK, 2=non autorise, 6=compagnie hors cabinet.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0930AssignDossier
    @UserId           varchar(200),
    @CompanyGUID      uniqueidentifier,
    @AssignedUserGUID uniqueidentifier = NULL,
    @EquipeId         int = NULL,
    @ErrorCode        int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;

    DECLARE @cabId int, @callerRole nvarchar(20);
    SELECT TOP 1 @cabId = m.CabinetId, @callerRole = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    IF @cabId IS NULL OR @callerRole NOT IN ('admin', 'solo') BEGIN SET @ErrorCode = 2; RETURN; END

    -- la compagnie doit etre un dossier du cabinet (ComptableGUID d'un membre)
    IF NOT EXISTS (
        SELECT 1 FROM dbo.T010Company c
        WHERE c.CompanyGUID = @CompanyGUID
          AND c.ComptableGUID IN (SELECT UserGUID FROM dbo.T332CabinetMembre WHERE CabinetId = @cabId AND IsActive = 1)
    )
    BEGIN SET @ErrorCode = 6; RETURN; END

    IF EXISTS (SELECT 1 FROM dbo.T334CabinetDossier WHERE CabinetId = @cabId AND CompanyGUID = @CompanyGUID)
        UPDATE dbo.T334CabinetDossier
        SET AssignedUserGUID = @AssignedUserGUID, EquipeId = @EquipeId
        WHERE CabinetId = @cabId AND CompanyGUID = @CompanyGUID;
    ELSE
        INSERT INTO dbo.T334CabinetDossier (CabinetId, CompanyGUID, AssignedUserGUID, EquipeId)
        VALUES (@cabId, @CompanyGUID, @AssignedUserGUID, @EquipeId);
END
GO
