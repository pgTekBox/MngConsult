-- =============================================================================
-- s0692VerifyCompanyMail
-- Confirme l'adresse courriel d'entreprise a partir du token du lien clique.
-- Appelee par wbfVerifyCompanyMail.aspx.
--
-- Le token n'est PAS efface a la confirmation : il reste valide jusqu'a son
-- expiration pour que reclicker le lien affiche « deja verifie » (-2) plutot
-- que « lien invalide » (0), comme s0221ActivateUser.
--
-- Result :  1 = verification OK
--          -1 = lien expire
--          -2 = adresse deja verifiee
--           0 = token inconnu
-- =============================================================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.s0692VerifyCompanyMail', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0692VerifyCompanyMail;
GO

CREATE PROCEDURE dbo.s0692VerifyCompanyMail
    @Token UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LocalCompanyGUID  UNIQUEIDENTIFIER;
    DECLARE @LocalSentTo       VARCHAR(300);
    DECLARE @LocalExpires      DATETIME;
    DECLARE @LocalVerifiedAddr VARCHAR(300);
    DECLARE @LocalVerifiedOn   DATETIME;
    DECLARE @Result            INT = 0;

    SELECT TOP 1
        @LocalCompanyGUID  = CompanyGUID,
        @LocalSentTo       = MailVerifySentTo,
        @LocalExpires      = MailVerifyTokenExpires,
        @LocalVerifiedAddr = MailVerifiedAddress,
        @LocalVerifiedOn   = MailVerifiedOn
    FROM dbo.T010Company
    WHERE MailVerifyToken = @Token;

    IF @LocalCompanyGUID IS NULL
    BEGIN
        -- Token inconnu (jamais emis, ou remplace par une demande plus recente)
        SET @Result = 0;
    END
    ELSE IF @LocalVerifiedOn IS NOT NULL AND @LocalVerifiedAddr = @LocalSentTo
    BEGIN
        -- Cette adresse a deja ete confirmee via ce lien
        SET @Result = -2;
    END
    ELSE IF @LocalExpires < GETDATE()
    BEGIN
        SET @Result = -1;
    END
    ELSE
    BEGIN
        UPDATE dbo.T010Company
        SET MailVerifiedAddress = @LocalSentTo,
            MailVerifiedOn      = GETDATE(),
            ModifiedOn          = GETDATE(),
            ModifiedBy          = N'self-mail-verification'
        WHERE CompanyGUID = @LocalCompanyGUID;

        SET @Result = 1;
    END

    -- Resultset unique pour ExecuteSQLds
    SELECT
        @Result           AS [Result],
        @LocalCompanyGUID AS CompanyGUID,
        @LocalSentTo      AS Email;
END
GO
