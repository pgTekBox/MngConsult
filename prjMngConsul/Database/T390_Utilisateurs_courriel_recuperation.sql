-- =============================================================================
-- T390 — Page Utilisateurs de l'ERP : courriel de récupération (suite de T389)
--   s0202GetUsersList / s0203GetUserById : renvoient RecoveryEmail et
--       EstMembreCabinet (le courriel de récupération est obligatoire pour un
--       membre actif d'un cabinet comptable).
--   s0204SaveUser : @RecoveryEmail (NULL = conserver, '' = effacer). Les règles
--       sont vérifiées dans la page (format, pas @60sec.ca, différent du
--       courriel de connexion) et ici : THROW 51170 si invalide.
--   Reprend s0204 de T388 (garde du dernier administrateur, IsAccountant
--   conservé, boîte @60sec.ca qui suit le mot de passe).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0203GetUserById
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Email, FirstName, LastName, IsAdmin, IsAccountant, IsActive, RecoveryEmail,
           CAST(CASE WHEN EXISTS (SELECT 1 FROM dbo.T332CabinetMembre m
                                  WHERE m.UserGUID = u.UserGUID AND m.IsActive = 1) THEN 1 ELSE 0 END AS bit) AS EstMembreCabinet
    FROM dbo.T015User u
    WHERE CompanyGUID = @CompanyGUID
      AND Id = @Id
      AND IsDeleted = 0;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0202GetUsersList
    @CompanyGUID UNIQUEIDENTIFIER,
    @Search      NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Email,
        FirstName,
        LastName,
        ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '') AS FullName,
        IsAdmin,
        CAST(ISNULL(isAccountant, 0) AS BIT) AS IsAccountant,
        IsActive,
        LastLoginOn,
        CreatedOn,
        RecoveryEmail,
        CAST(CASE WHEN EXISTS (SELECT 1 FROM dbo.T332CabinetMembre m
                               WHERE m.UserGUID = u.UserGUID AND m.IsActive = 1) THEN 1 ELSE 0 END AS bit) AS EstMembreCabinet
    FROM dbo.T015User u
    WHERE CompanyGUID = @CompanyGUID
      AND IsDeleted = 0
      AND (@Search IS NULL OR @Search = ''
           OR Email LIKE '%' + @Search + '%'
           OR FirstName LIKE '%' + @Search + '%'
           OR LastName LIKE '%' + @Search + '%'
           OR RecoveryEmail LIKE '%' + @Search + '%')
    ORDER BY IsActive DESC, LastName, FirstName;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0204SaveUser
    @Id              INT,
    @CompanyGUID     UNIQUEIDENTIFIER,
    @Email           NVARCHAR(200),
    @PasswordHash    NVARCHAR(500) = NULL,
    @FirstName       NVARCHAR(100) = NULL,
    @LastName        NVARCHAR(100) = NULL,
    @IsAdmin         BIT = 0,
    @IsAccountant    BIT = NULL,          -- NULL = conserver la valeur actuelle (T384)
    @IsActive        BIT = 1,
    @ModifiedBy      NVARCHAR(200) = NULL,
    @RecoveryEmail   NVARCHAR(200) = NULL,  -- T390 : NULL = conserver, '' = effacer
    @NewId           INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- T390 : courriel de récupération — externe, valide, différent du courriel de connexion
    IF @RecoveryEmail IS NOT NULL
    BEGIN
        SET @RecoveryEmail = LOWER(LTRIM(RTRIM(@RecoveryEmail)));
        IF @RecoveryEmail <> ''
           AND (CHARINDEX('@', @RecoveryEmail) < 2 OR CHARINDEX('.', @RecoveryEmail, CHARINDEX('@', @RecoveryEmail)) = 0
                OR CHARINDEX(' ', @RecoveryEmail) > 0 OR @RecoveryEmail LIKE '%@60sec.ca'
                OR @RecoveryEmail = LOWER(LTRIM(RTRIM(@Email))))
            THROW 51170, N'COURRIEL_RECUPERATION_INVALIDE', 1;
    END

    IF ISNULL(@Id, 0) = 0
    BEGIN
        IF @PasswordHash IS NULL
        BEGIN
            RAISERROR('Le mot de passe est obligatoire à la création.', 16, 1);
            RETURN;
        END

        INSERT INTO dbo.T015User
            (CompanyGUID, Email, PasswordHash, FirstName, LastName,
             IsAdmin, IsAccountant, IsActive, CreatedBy, RecoveryEmail)
        VALUES
            (@CompanyGUID, @Email, @PasswordHash, @FirstName, @LastName,
             @IsAdmin, ISNULL(@IsAccountant, 0), @IsActive, @ModifiedBy, NULLIF(@RecoveryEmail, ''));

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        -- Le dernier administrateur actif d'un cabinet ne peut pas être désactivé
        IF @IsActive = 0
        BEGIN
            DECLARE @g uniqueidentifier = (SELECT UserGUID FROM dbo.T015User
                                           WHERE Id = @Id AND CompanyGUID = @CompanyGUID AND IsActive = 1);
            IF @g IS NOT NULL AND dbo.fDernierAdminCabinet(@g) = 1
                THROW 51140, N'DERNIER_ADMIN_CABINET', 1;
        END

        UPDATE dbo.T015User
        SET Email        = @Email,
            FirstName    = @FirstName,
            LastName     = @LastName,
            IsAdmin      = @IsAdmin,
            IsAccountant = ISNULL(@IsAccountant, IsAccountant),
            IsActive     = @IsActive,
            RecoveryEmail = CASE WHEN @RecoveryEmail IS NULL THEN RecoveryEmail ELSE NULLIF(@RecoveryEmail, '') END,
            PasswordHash = COALESCE(@PasswordHash, PasswordHash),
            ModifiedOn   = GETDATE(),
            ModifiedBy   = @ModifiedBy
        WHERE Id = @Id
          AND CompanyGUID = @CompanyGUID;

        SET @NewId = @Id;

        -- T388 : la boîte @60sec.ca d'un membre de cabinet suit le nouveau mot de passe
        IF @PasswordHash IS NOT NULL
        BEGIN
            DECLARE @mail nvarchar(200), @ug uniqueidentifier;
            SELECT @mail = LTRIM(RTRIM(Email)), @ug = UserGUID
            FROM dbo.T015User WHERE Id = @Id AND CompanyGUID = @CompanyGUID AND IsDeleted = 0;
            IF @mail LIKE '%@60sec.ca'
               AND EXISTS (SELECT 1 FROM dbo.T332CabinetMembre WHERE UserGUID = @ug AND IsActive = 1)
                UPDATE MailService.dbo.SmtpLocalRecipient
                SET PasswordHash = @PasswordHash, PasswordSetOn = SYSUTCDATETIME()
                WHERE LTRIM(RTRIM(Email)) = @mail;
        END
    END
END
GO
