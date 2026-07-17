-- =============================================================================
-- s0694GetCompanyReplyTo
-- Adresse de la compagnie utilisable en Reply-To sur les courriels envoyes
-- EN SON NOM (invitation fournisseur, avis de prelevement automatique).
-- Retourne NULL si le courriel n'est pas configure ou pas verifie.
--
-- Pourquoi Reply-To et pas From : SrvAI envoie en direct-to-MX depuis notre
-- propre IP et utilise la colonne T400Mails.Sender comme From (enveloppe +
-- en-tete). Mettre le domaine d'un client dans Sender ferait echouer son SPF
-- (notre IP n'y est pas autorisee) et DMARC ensuite -> spam/rejet. Le From
-- reste donc noreply@60sec.ca (aligne SPF) et c'est le Reply-To qui porte
-- l'adresse de la compagnie : les reponses lui arrivent, sans rien casser.
--
-- La verification (s0691-s0693) prouve la propriete de la BOITE, pas que le
-- DNS du client autorise notre serveur : elle ne dispense pas du Reply-To.
--
-- Regle unique : l'adresse doit etre verifiee ET correspondre encore a la
-- valeur courante de MAIL_FROM_EMAIL (meme derivation que s0693).
-- =============================================================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.s0694GetCompanyReplyTo', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0694GetCompanyReplyTo;
GO

CREATE PROCEDURE dbo.s0694GetCompanyReplyTo
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentEmail VARCHAR(300) = dbo.fParamS(@CompanyGUID, 'MAIL_FROM_EMAIL');

    SELECT
        CASE WHEN c.MailVerifiedOn IS NOT NULL
              AND @CurrentEmail IS NOT NULL
              AND LTRIM(RTRIM(@CurrentEmail)) <> ''
              AND c.MailVerifiedAddress = @CurrentEmail
             THEN @CurrentEmail
        END AS ReplyTo
    FROM dbo.T010Company c
    WHERE c.CompanyGUID = @CompanyGUID;
END
GO
