-- =============================================================================
-- s0712AssignMailbox (révisé)
--   Attribue l'adresse @60sec.ca d'une compagnie à partir du slug de son
--   nom commercial (TRADE_NAME).
--   NOUVEAU : @AllowFallback (défaut 0). Si la compagnie n'a PAS de nom
--   commercial, on NE crée PLUS l'adresse générique « abonne@… » ; on renvoie
--   simplement l'adresse actuelle (NULL). Ainsi les appels automatiques
--   (inscription, ouverture de la page Courriel) n'engendrent plus de
--   « abonne-N » : la boîte sera créée dès qu'un vrai nom commercial existe.
--   Le bouton « Attribuer » de la console Admin passe @AllowFallback=1 pour
--   forcer la création (repli « abonne » toléré car action explicite).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0712AssignMailbox
    @CompanyGUID   UNIQUEIDENTIFIER,
    @AllowFallback BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cur VARCHAR(150) = (SELECT Sec60Email FROM dbo.T010Company WHERE CompanyGUID = @CompanyGUID);
    IF @cur IS NOT NULL AND @cur <> ''
    BEGIN
        -- s'assurer que l'adresse locale est bien enregistree
        IF NOT EXISTS (SELECT 1 FROM MailService.dbo.SmtpLocalRecipient WHERE LTRIM(RTRIM(Email)) = @cur)
            INSERT INTO MailService.dbo.SmtpLocalRecipient(Email, IsActive, CreatedAtUtc) VALUES(@cur, 1, SYSUTCDATETIME());
        SELECT @cur AS Email;
        RETURN;
    END

    DECLARE @trade NVARCHAR(200) =
        (SELECT TOP 1 v.sVal FROM dbo.T101ParamValues v
         JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
         WHERE v.CompanyGUID = @CompanyGUID AND p.ShortName = 'TRADE_NAME');

    -- Pas de nom commercial ET pas de repli explicite -> ne rien créer.
    IF (@trade IS NULL OR LTRIM(RTRIM(@trade)) = '') AND @AllowFallback = 0
    BEGIN
        SELECT @cur AS Email;   -- NULL : aucune boîte attribuée pour l'instant
        RETURN;
    END

    DECLARE @base VARCHAR(100) = dbo.fnSlugify(@trade);   -- 'abonne' si @trade vide (repli explicite)
    DECLARE @cand VARCHAR(120) = @base, @email VARCHAR(150), @n INT = 1;

    WHILE 1 = 1
    BEGIN
        SET @email = @cand + '@60sec.ca';
        IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE Sec60Email = @email)
           AND NOT EXISTS (SELECT 1 FROM MailService.dbo.SmtpLocalRecipient WHERE LTRIM(RTRIM(Email)) = @email)
            BREAK;
        SET @n = @n + 1;
        SET @cand = @base + '-' + CAST(@n AS VARCHAR(10));
    END

    UPDATE dbo.T010Company SET Sec60Email = @email WHERE CompanyGUID = @CompanyGUID;
    INSERT INTO MailService.dbo.SmtpLocalRecipient(Email, IsActive, CreatedAtUtc) VALUES(@email, 1, SYSUTCDATETIME());

    SELECT @email AS Email;
END
GO
