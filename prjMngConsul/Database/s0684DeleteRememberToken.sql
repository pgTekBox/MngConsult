SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0684DeleteRememberToken
-- Supprime un jeton « Se souvenir de moi » par son Selector.
-- Utilisé à la déconnexion, à la rotation, et si un cookie forgé est détecté.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0684DeleteRememberToken
    @Selector VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.T016UserRememberToken WHERE Selector = @Selector;
END
