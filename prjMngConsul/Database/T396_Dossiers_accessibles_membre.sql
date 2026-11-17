-- =====================================================================
-- T396 — Dossiers réellement accessibles à un employé du cabinet
--
-- s1018ListDossiersAccessibles : les dossiers que l'employé @MembreId
-- peut ouvrir (fCabinetDossiers de CE membre : confiés + ceux des
-- employés qu'il supervise ; tout le cabinet pour un administrateur),
-- avec Confie = 1 si le dossier lui est confié directement.
-- Sert au rapport imprimable des employés : les réglages d'accès qui
-- restent dans T336 pour un dossier que l'employé ne voit plus (dossier
-- confié à quelqu'un d'autre) ne doivent pas y apparaître.
--
-- Appelant : un administrateur / solo du cabinet (tout membre), ou un
-- employé pour lui-même et les employés qu'il supervise.
-- =====================================================================
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s1018ListDossiersAccessibles
    @UserId   varchar(200),
    @MembreId int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @uid uniqueidentifier, @cabId int, @role nvarchar(20);
    SELECT TOP 1 @uid = u.UserGUID, @cabId = m.CabinetId, @role = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;
    IF @cabId IS NULL RETURN;

    DECLARE @membre uniqueidentifier, @sup uniqueidentifier;
    SELECT @membre = UserGUID, @sup = SuperviseurUserGUID
    FROM dbo.T332CabinetMembre
    WHERE Id = @MembreId AND CabinetId = @cabId;
    IF @membre IS NULL RETURN;

    -- Un employé : seulement lui-même et ceux qu'il supervise
    IF @role NOT IN ('admin', 'solo') AND @membre <> @uid AND ISNULL(@sup, '00000000-0000-0000-0000-000000000000') <> @uid RETURN;

    SELECT f.CompanyGUID, dbo.fCompanyName(f.CompanyGUID) AS Nom,
           CAST(CASE WHEN d.AssignedUserGUID = @membre THEN 1 ELSE 0 END AS bit) AS Confie
    FROM dbo.fCabinetDossiers(@membre) f
    LEFT JOIN dbo.T334CabinetDossier d ON d.CabinetId = @cabId AND d.CompanyGUID = f.CompanyGUID
    ORDER BY dbo.fCompanyName(f.CompanyGUID);
END
GO
