-- =============================================================================
-- s0691StartCompanyMailVerification
-- Genere un token de verification (valide 24 h) pour l'adresse courriel de
-- l'entreprise (parametre MAIL_FROM_EMAIL) et retourne ce token a l'appelant,
-- qui construit le lien et depose le courriel dans T400Mails (BD MailService).
--
-- Appelee par wbfSetting.aspx (bouton « Verifier »).
-- Result : 1 = token genere, 0 = compagnie introuvable.
-- =============================================================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.s0691StartCompanyMailVerification', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0691StartCompanyMailVerification;
GO

CREATE PROCEDURE dbo.s0691StartCompanyMailVerification
    @CompanyGUID UNIQUEIDENTIFIER,
    @Email       VARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Token UNIQUEIDENTIFIER = NEWID();

    UPDATE dbo.T010Company
    SET MailVerifySentTo       = @Email,
        MailVerifyToken        = @Token,
        MailVerifyTokenExpires = DATEADD(HOUR, 24, GETDATE()),
        ModifiedOn             = GETDATE()
    WHERE CompanyGUID = @CompanyGUID;

    IF @@ROWCOUNT = 0
        SELECT 0 AS [Result], CAST(NULL AS UNIQUEIDENTIFIER) AS Token;
    ELSE
        SELECT 1 AS [Result], @Token AS Token;
END
GO
