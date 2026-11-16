-- =============================================================================
-- T389 — Courriel de récupération des utilisateurs du cabinet
-- Chaque membre d'un cabinet a un courriel de récupération (adresse externe,
-- p. ex. personnelle) : c'est là que partent les liens de mot de passe, puisque
-- la boîte @60sec.ca partage le mot de passe du compte et n'est donc pas
-- lisible quand on l'a oublié.
--   T015User.RecoveryEmail
--   s1013SetCourrielRecuperation : pose le courriel de récupération d'un membre
--       (admin / solo). ErrorCode : 0 OK, 2 non autorisé, 5 introuvable,
--       6 invalide, 8 identique au courriel de connexion, 9 adresse @60sec.ca.
--   s1000ListEquipeCabinet : renvoie RecoveryEmail.
--   s0679CreateUserResetToken : renvoie RecoveryEmail (« Mot de passe oublié »
--       envoie le lien à cette adresse quand elle existe).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('dbo.T015User', 'RecoveryEmail') IS NULL
    ALTER TABLE dbo.T015User ADD RecoveryEmail NVARCHAR(200) NULL;
GO

CREATE OR ALTER PROCEDURE dbo.s1013SetCourrielRecuperation
    @UserId    varchar(200),
    @MembreId  int,
    @Email     nvarchar(200),
    @ErrorCode int OUTPUT
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

    DECLARE @cible uniqueidentifier = (SELECT UserGUID FROM dbo.T332CabinetMembre
                                       WHERE Id = @MembreId AND CabinetId = @cabId AND IsActive = 1);
    IF @cible IS NULL BEGIN SET @ErrorCode = 5; RETURN; END

    SET @Email = LOWER(LTRIM(RTRIM(ISNULL(@Email, ''))));
    IF @Email = '' OR CHARINDEX('@', @Email) < 2 OR CHARINDEX('.', @Email, CHARINDEX('@', @Email)) = 0
       OR CHARINDEX(' ', @Email) > 0
    BEGIN SET @ErrorCode = 6; RETURN; END
    IF @Email LIKE '%@60sec.ca' BEGIN SET @ErrorCode = 9; RETURN; END
    IF EXISTS (SELECT 1 FROM dbo.T015User WHERE UserGUID = @cible AND LOWER(LTRIM(RTRIM(Email))) = @Email)
    BEGIN SET @ErrorCode = 8; RETURN; END

    UPDATE dbo.T015User SET RecoveryEmail = @Email, ModifiedOn = GETDATE(), ModifiedBy = @UserId
    WHERE UserGUID = @cible AND IsDeleted = 0;
END
GO

-- ── s1000 : le courriel de récupération ────────────────────────────────────
DECLARE @def nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID('dbo.s1000ListEquipeCabinet')), @p int;
IF CHARINDEX(N'RecoveryEmail', @def) = 0
BEGIN
    DECLARE @a nvarchar(200) = N'u.Email, u.FirstName, u.LastName,';
    IF CHARINDEX(@a, @def) = 0 THROW 51160, N's1000 : ancre introuvable.', 1;
    SET @def = STUFF(@def, CHARINDEX(@a, @def), LEN(@a), N'u.Email, u.FirstName, u.LastName, u.RecoveryEmail,');
    SET @p = CHARINDEX(N'CREATE', @def); SET @def = STUFF(@def, @p, 6, N'ALTER');
    EXEC sys.sp_executesql @def;
END
GO

-- ── s0679 : renvoie aussi le courriel de récupération ──────────────────────
CREATE OR ALTER PROCEDURE dbo.s0679CreateUserResetToken
    @Email          NVARCHAR(200),
    @ExpiresMinutes INT = 60
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Id INT, @Token UNIQUEIDENTIFIER = NEWID();

    SELECT @Id = Id
    FROM dbo.T015User
    WHERE Email = @Email
      AND IsActive = 1
      AND IsDeleted = 0;

    IF @Id IS NULL
        RETURN;  -- aucun compte actif : aucun résultat

    UPDATE dbo.T015User
    SET ResetToken        = @Token,
        ResetTokenExpires = DATEADD(MINUTE, @ExpiresMinutes, GETDATE())
    WHERE Id = @Id;

    SELECT
        ResetToken AS Token,
        Email,
        FirstName,
        RecoveryEmail      -- T389 : destinataire du lien quand il existe
    FROM dbo.T015User
    WHERE Id = @Id;
END
GO
