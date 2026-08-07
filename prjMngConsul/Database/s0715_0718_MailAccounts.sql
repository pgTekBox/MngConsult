-- =============================================================================
-- Gestion des comptes de courriel (console Admin)
--   s0715MailAccountsList        : compagnies + leur boîte @60sec.ca + état + nb logins
--   s0716LocalRecipientsList     : adresses locales système (non rattachées à une compagnie)
--   s0717MailAccountRename        : renomme/attribue l'adresse @60sec.ca d'une compagnie (unicité)
--   s0718MailRecipientSetActive   : active/désactive une adresse locale (SmtpLocalRecipient)
-- L'attribution initiale reste s0712AssignMailbox.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0715MailAccountsList
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        c.CompanyGUID,
        c.CompanyCode,
        COALESCE(dbo.fParamS(c.CompanyGUID, 'TRADE_NAME'), dbo.fCompanyName(c.CompanyGUID)) AS Name,
        c.Sec60Email,
        CASE WHEN c.Sec60Email IS NOT NULL AND c.Sec60Email <> '' THEN 1 ELSE 0 END AS HasMailbox,
        CAST(ISNULL(r.IsActive, 0) AS BIT) AS IsActive,
        CAST(CASE WHEN r.PasswordHash IS NOT NULL AND r.PasswordHash <> '' THEN 1 ELSE 0 END AS BIT) AS HasPassword,
        (SELECT COUNT(*) FROM dbo.T015User u
           WHERE u.CompanyGUID = c.CompanyGUID
             AND u.IsActive = 1 AND ISNULL(u.IsDeleted, 0) = 0
             AND u.Email IS NOT NULL AND u.Email <> '') AS UserCount
    FROM dbo.T010Company c
    LEFT JOIN MailService.dbo.SmtpLocalRecipient r ON r.Email = c.Sec60Email
    WHERE (@Search IS NULL OR @Search = ''
           OR dbo.fParamS(c.CompanyGUID, 'TRADE_NAME') LIKE '%' + @Search + '%'
           OR c.CompanyCode LIKE '%' + @Search + '%'
           OR c.Sec60Email LIKE '%' + @Search + '%')
    ORDER BY Name;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0716LocalRecipientsList
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.Id, r.Email, r.IsActive, r.CreatedAtUtc,
           CAST(CASE WHEN r.PasswordHash IS NOT NULL AND r.PasswordHash <> '' THEN 1 ELSE 0 END AS BIT) AS HasPassword
    FROM MailService.dbo.SmtpLocalRecipient r
    WHERE NOT EXISTS (SELECT 1 FROM dbo.T010Company c WHERE c.Sec60Email = r.Email)
    ORDER BY r.Email;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0717MailAccountRename
    @CompanyGUID UNIQUEIDENTIFIER,
    @LocalPart   NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    -- normaliser : retirer un éventuel domaine puis slugifier la partie locale
    DECLARE @lp NVARCHAR(200) = LTRIM(RTRIM(ISNULL(@LocalPart, '')));
    IF CHARINDEX('@', @lp) > 0 SET @lp = LEFT(@lp, CHARINDEX('@', @lp) - 1);

    DECLARE @slug VARCHAR(120) = dbo.fnSlugify(@lp);
    IF @slug IS NULL OR @slug = ''
    BEGIN
        SELECT CAST(0 AS BIT) AS Ok, CAST(NULL AS VARCHAR(150)) AS Email, N'Adresse invalide.' AS Msg;
        RETURN;
    END

    DECLARE @email VARCHAR(150) = @slug + '@60sec.ca';
    DECLARE @cur   VARCHAR(150) = (SELECT Sec60Email FROM dbo.T010Company WHERE CompanyGUID = @CompanyGUID);

    IF @email = @cur
    BEGIN
        SELECT CAST(1 AS BIT) AS Ok, @email AS Email, N'Aucun changement.' AS Msg;
        RETURN;
    END

    -- unicité (autres compagnies + autres destinataires locaux)
    IF EXISTS (SELECT 1 FROM dbo.T010Company WHERE Sec60Email = @email AND CompanyGUID <> @CompanyGUID)
       OR EXISTS (SELECT 1 FROM MailService.dbo.SmtpLocalRecipient
                  WHERE Email = @email AND Email <> ISNULL(@cur, ''))
    BEGIN
        SELECT CAST(0 AS BIT) AS Ok, @email AS Email, N'Cette adresse est déjà utilisée.' AS Msg;
        RETURN;
    END

    BEGIN TRAN;
        UPDATE dbo.T010Company SET Sec60Email = @email WHERE CompanyGUID = @CompanyGUID;

        IF @cur IS NOT NULL AND EXISTS (SELECT 1 FROM MailService.dbo.SmtpLocalRecipient WHERE Email = @cur)
            UPDATE MailService.dbo.SmtpLocalRecipient SET Email = @email WHERE Email = @cur;
        ELSE IF NOT EXISTS (SELECT 1 FROM MailService.dbo.SmtpLocalRecipient WHERE Email = @email)
            INSERT INTO MailService.dbo.SmtpLocalRecipient(Email, IsActive, CreatedAtUtc)
            VALUES(@email, 1, SYSUTCDATETIME());
    COMMIT;

    SELECT CAST(1 AS BIT) AS Ok, @email AS Email, N'Adresse mise à jour.' AS Msg;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0718MailRecipientSetActive
    @Email  NVARCHAR(320),
    @Active BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM MailService.dbo.SmtpLocalRecipient WHERE Email = @Email)
        UPDATE MailService.dbo.SmtpLocalRecipient SET IsActive = @Active WHERE Email = @Email;
    ELSE IF @Active = 1
        INSERT INTO MailService.dbo.SmtpLocalRecipient(Email, IsActive, CreatedAtUtc)
        VALUES(@Email, 1, SYSUTCDATETIME());
END
GO
