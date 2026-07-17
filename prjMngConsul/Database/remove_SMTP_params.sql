-- =============================================================================
-- Retrait des parametres SMTP par compagnie :
--   MAIL_FROM_NAME, SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS
--
-- Devenus inutiles : l'application n'envoie plus rien en SMTP direct. Les
-- courriels sont deposes dans T400Mails (BD MailService) via
-- s0610InsertOutboundMail, qui fixe lui-meme l'expediteur (noreply@60sec.ca),
-- et le service Windows SrvAI les envoie. Aucun lecteur de ces 5 parametres
-- ne subsiste (verifie : ni code VB, ni proc/vue SQL).
--
-- L'onglet Email de wbfSetting ne garde donc que MAIL_FROM_EMAIL (+ son bouton
-- de verification, cf. s0691-s0693) et MAIL_SIGNATURE.
--
-- Suppression dans T101 (valeurs), T100 (definitions, toutes compagnies +
-- modele) et T102 (libelles), comme remove_PAYMENT_REGIME_param.sql.
-- Les valeurs sont sauvegardees dans dbo.T101ParamValues_bak_smtp au cas ou.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. Backup des valeurs existantes (avec la compagnie et le ShortName)
IF OBJECT_ID('dbo.T101ParamValues_bak_smtp', 'U') IS NOT NULL
    DROP TABLE dbo.T101ParamValues_bak_smtp;

SELECT
    p.CompanyGUID,
    p.ShortName,
    v.Id AS T101Id,
    v.sVal,
    v.iVal,
    v.dVal,
    v.fVal,
    GETDATE() AS BackedUpOn
INTO dbo.T101ParamValues_bak_smtp
FROM dbo.T101ParamValues v
INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
WHERE p.ShortName IN ('MAIL_FROM_NAME', 'SMTP_HOST', 'SMTP_PORT', 'SMTP_USER', 'SMTP_PASS');
GO

-- 2. Valeurs
DELETE FROM dbo.T101ParamValues
WHERE T100Id IN (
    SELECT Id FROM dbo.T100ParamComptable
    WHERE ShortName IN ('MAIL_FROM_NAME', 'SMTP_HOST', 'SMTP_PORT', 'SMTP_USER', 'SMTP_PASS')
);

-- 3. Definitions (toutes les compagnies, y compris la compagnie modele)
DELETE FROM dbo.T100ParamComptable
WHERE ShortName IN ('MAIL_FROM_NAME', 'SMTP_HOST', 'SMTP_PORT', 'SMTP_USER', 'SMTP_PASS');

-- 4. Libelles multilingues
DELETE FROM dbo.T102ParamI18n
WHERE ShortName IN ('MAIL_FROM_NAME', 'SMTP_HOST', 'SMTP_PORT', 'SMTP_USER', 'SMTP_PASS');
GO
