-- =============================================================================
-- T383 — Portail comptable : création d'un membre avec sa boîte @60sec.ca
--   s1008SuggererCourriel60Sec : adresse libre « prenom.nom@60sec.ca » (sans
--                                accents ; suffixe -2, -3… si déjà prise)
--   s1009CreerBoite60Sec       : crée la boîte dans MailService.SmtpLocalRecipient
--                                (admin / solo du cabinet). ErrorCode : 0 OK,
--                                1 adresse déjà prise, 2 non autorisé, 6 adresse invalide.
--   s1010Courriel60SecPris     : 1 si l'adresse est déjà utilisée (compte, compagnie, employé, boîte).
-- Le mot de passe de la boîte est posé à l'activation de l'invitation
-- (wbfCabInvitation → MailService.s0629SetLocalRecipientPassword).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Une adresse @60sec.ca est-elle déjà utilisée quelque part ?
CREATE OR ALTER FUNCTION dbo.fCourriel60SecPris(@Email nvarchar(200))
RETURNS bit
AS
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.T015User WHERE Email = @Email AND IsDeleted = 0)
       OR EXISTS (SELECT 1 FROM dbo.T010Company WHERE Sec60Email = @Email)
       OR EXISTS (SELECT 1 FROM dbo.T300Employees WHERE Sec60Email = @Email)
       OR EXISTS (SELECT 1 FROM MailService.dbo.SmtpLocalRecipient WHERE LTRIM(RTRIM(Email)) = @Email)
        RETURN 1;
    RETURN 0;
END
GO

CREATE OR ALTER PROCEDURE dbo.s1008SuggererCourriel60Sec
    @Prenom nvarchar(100),
    @Nom    nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @p varchar(100) = dbo.fnSlugify(ISNULL(@Prenom, '')),
            @n varchar(100) = dbo.fnSlugify(ISNULL(@Nom, ''));
    DECLARE @base varchar(160) =
        CASE WHEN ISNULL(@p, '') <> '' AND ISNULL(@n, '') <> '' THEN @p + '.' + @n
             ELSE COALESCE(NULLIF(@p, ''), NULLIF(@n, ''), 'membre') END;

    DECLARE @cand varchar(170) = @base, @email varchar(200), @i int = 1;
    WHILE 1 = 1
    BEGIN
        SET @email = @cand + '@60sec.ca';
        IF dbo.fCourriel60SecPris(@email) = 0 BREAK;
        SET @i = @i + 1;
        SET @cand = @base + '-' + CAST(@i AS varchar(10));
    END
    SELECT @email AS Email;
END
GO

CREATE OR ALTER PROCEDURE dbo.s1009CreerBoite60Sec
    @UserId    varchar(200),
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

    SET @Email = LOWER(LTRIM(RTRIM(ISNULL(@Email, ''))));
    IF RIGHT(@Email, 10) <> '@60sec.ca' OR LEN(@Email) < 11 OR CHARINDEX(' ', @Email) > 0
       OR @Email LIKE '%[^a-z0-9.@_-]%'
    BEGIN SET @ErrorCode = 6; RETURN; END

    IF EXISTS (SELECT 1 FROM MailService.dbo.SmtpLocalRecipient WHERE LTRIM(RTRIM(Email)) = @Email)
       OR EXISTS (SELECT 1 FROM dbo.T010Company WHERE Sec60Email = @Email)
       OR EXISTS (SELECT 1 FROM dbo.T300Employees WHERE Sec60Email = @Email)
    BEGIN SET @ErrorCode = 1; RETURN; END

    INSERT INTO MailService.dbo.SmtpLocalRecipient (Email, IsActive, CreatedAtUtc)
    VALUES (@Email, 1, SYSUTCDATETIME());
END
GO

CREATE OR ALTER PROCEDURE dbo.s1010Courriel60SecPris
    @Email nvarchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT dbo.fCourriel60SecPris(LOWER(LTRIM(RTRIM(ISNULL(@Email, ''))))) AS Pris;
END
GO
