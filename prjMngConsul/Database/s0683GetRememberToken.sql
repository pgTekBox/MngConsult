SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0683GetRememberToken
-- Récupère un jeton « Se souvenir de moi » par son Selector, seulement s'il
-- est non expiré et que le compte est actif. Retourne le hash du validator
-- (comparé côté app en temps constant) + UserId + CompanyGUID pour restaurer
-- la session. Retourne rien si invalide/expiré/compte inactif.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0683GetRememberToken
    @Selector VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.UserId,
        t.ValidatorHash,
        t.ExpiresOn,
        u.CompanyGUID
    FROM dbo.T016UserRememberToken t
    INNER JOIN dbo.T015User u ON u.Id = t.UserId
    WHERE t.Selector = @Selector
      AND t.ExpiresOn > GETDATE()
      AND u.IsActive = 1
      AND u.IsDeleted = 0;
END
