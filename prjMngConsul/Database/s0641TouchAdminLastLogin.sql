SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0641TouchAdminLastLogin
-- Met à jour la date de dernière connexion d'un administrateur.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0641TouchAdminLastLogin
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T900AdminUser
    SET LastLoginOn = GETDATE()
    WHERE Id = @Id;
END
