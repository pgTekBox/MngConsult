-- =============================================================================
-- s0693GetCompanyMailStatus
-- Etat de verification du courriel d'entreprise, pour l'affichage du badge
-- dans wbfSetting.aspx (onglet Email, parametre MAIL_FROM_EMAIL).
--
-- IsVerified n'est vrai que si l'adresse confirmee correspond TOUJOURS a la
-- valeur courante du parametre MAIL_FROM_EMAIL (T101) : changer le courriel
-- invalide donc la verification sans traitement supplementaire.
-- =============================================================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.s0693GetCompanyMailStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0693GetCompanyMailStatus;
GO

CREATE PROCEDURE dbo.s0693GetCompanyMailStatus
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentEmail VARCHAR(300) = dbo.fParamS(@CompanyGUID, 'MAIL_FROM_EMAIL');

    SELECT
        @CurrentEmail              AS CurrentEmail,
        c.MailVerifiedAddress      AS VerifiedAddress,
        c.MailVerifiedOn           AS VerifiedOn,
        c.MailVerifySentTo         AS PendingAddress,
        c.MailVerifyTokenExpires   AS PendingExpires,
        CAST(CASE WHEN c.MailVerifiedOn IS NOT NULL
                   AND @CurrentEmail IS NOT NULL
                   AND c.MailVerifiedAddress = @CurrentEmail
             THEN 1 ELSE 0 END AS BIT) AS IsVerified,
        CAST(CASE WHEN c.MailVerifyToken IS NOT NULL
                   AND c.MailVerifyTokenExpires > GETDATE()
                   AND c.MailVerifySentTo = @CurrentEmail
                   AND (c.MailVerifiedAddress IS NULL OR c.MailVerifiedAddress <> @CurrentEmail)
             THEN 1 ELSE 0 END AS BIT) AS IsPending
    FROM dbo.T010Company c
    WHERE c.CompanyGUID = @CompanyGUID;
END
GO
