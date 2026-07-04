-- =============================================================
-- T015User : colonnes de réinitialisation de mot de passe utilisateur.
-- Même patron que T900AdminUser (ResetToken / ResetTokenExpires).
-- Idempotent : ne fait rien si les colonnes existent déjà.
-- =============================================================
IF COL_LENGTH('dbo.T015User', 'ResetToken') IS NULL
    ALTER TABLE dbo.T015User ADD ResetToken UNIQUEIDENTIFIER NULL;
GO
IF COL_LENGTH('dbo.T015User', 'ResetTokenExpires') IS NULL
    ALTER TABLE dbo.T015User ADD ResetTokenExpires DATETIME NULL;
GO
