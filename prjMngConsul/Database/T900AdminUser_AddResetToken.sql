-- =============================================================
-- T900AdminUser : ajout des colonnes de réinitialisation de mot de passe.
-- ResetToken         : jeton (GUID) envoyé par courriel.
-- ResetTokenExpires  : date d'expiration du jeton.
-- Idempotent.
-- =============================================================
IF COL_LENGTH('dbo.T900AdminUser', 'ResetToken') IS NULL
    ALTER TABLE dbo.T900AdminUser ADD ResetToken UNIQUEIDENTIFIER NULL;
GO

IF COL_LENGTH('dbo.T900AdminUser', 'ResetTokenExpires') IS NULL
    ALTER TABLE dbo.T900AdminUser ADD ResetTokenExpires DATETIME NULL;
GO
