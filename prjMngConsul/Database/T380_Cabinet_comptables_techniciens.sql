-- =============================================================================
-- T380 — Portail comptable : gestion des comptables ET des techniciens
-- La page « Comptables et techniciens » (wbfCabTechniciens) gère tous les
-- membres du cabinet :
--   s1000ListEquipeCabinet  : les membres actifs (admin / solo / employé /
--                             responsable / technicien) avec rôle, superviseur,
--                             dossiers, tâches ouvertes et en retard, techniciens
--                             supervisés ; admin/solo : tous ; employé : lui-même
--                             et les techniciens qu'il supervise.
--                             2e jeu : les superviseurs possibles.
--   s1001ListDossiersMembre : les dossiers du cabinet, cochés quand ils sont
--                             confiés au membre (comptable ou technicien).
-- Les écritures restent : s0923 (invitation), s0924 (rôle / retrait),
-- s0998 (superviseur d'un technicien), s0930 (dossier).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s1000ListEquipeCabinet
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @uid uniqueidentifier, @cabId int, @role nvarchar(20);
    SELECT TOP 1 @uid = u.UserGUID, @cabId = m.CabinetId, @role = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    IF @cabId IS NULL OR @role NOT IN ('admin', 'solo', 'employe') RETURN;

    DECLARE @Auj DATE = CAST(GETDATE() AS DATE);

    SELECT
        m.Id AS MembreId,
        m.UserGUID,
        m.Role,
        u.Email, u.FirstName, u.LastName,
        CAST(CASE WHEN u.IsActive = 0 THEN 1 ELSE 0 END AS bit) AS Pending,
        CAST(CASE WHEN m.UserGUID = @uid THEN 1 ELSE 0 END AS bit) AS IsMe,
        u.LastLoginOn,
        m.SuperviseurUserGUID,
        LTRIM(ISNULL(su.FirstName, '') + ' ' + ISNULL(su.LastName, '')) AS SuperviseurNom,
        (SELECT COUNT(*) FROM dbo.T334CabinetDossier d WHERE d.CabinetId = @cabId AND d.AssignedUserGUID = m.UserGUID) AS NbDossiers,
        STUFF((SELECT ', ' + dbo.fCompanyName(d.CompanyGUID)
               FROM dbo.T334CabinetDossier d WHERE d.CabinetId = @cabId AND d.AssignedUserGUID = m.UserGUID
               ORDER BY dbo.fCompanyName(d.CompanyGUID)
               FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Dossiers,
        (SELECT COUNT(*) FROM dbo.T339DossierTache t
         WHERE t.CabinetId = @cabId AND t.AssignedUserGUID = m.UserGUID AND t.Statut <> 'fait') AS NbTaches,
        (SELECT COUNT(*) FROM dbo.T339DossierTache t
         WHERE t.CabinetId = @cabId AND t.AssignedUserGUID = m.UserGUID AND t.Statut <> 'fait'
           AND t.Echeance IS NOT NULL AND CAST(t.Echeance AS DATE) < @Auj) AS NbRetard,
        (SELECT COUNT(*) FROM dbo.T332CabinetMembre s
         WHERE s.CabinetId = @cabId AND s.IsActive = 1 AND s.Role = 'technicien'
           AND s.SuperviseurUserGUID = m.UserGUID) AS NbTechniciens
    FROM dbo.T332CabinetMembre m
    JOIN dbo.T015User u ON u.UserGUID = m.UserGUID AND u.IsDeleted = 0
    LEFT JOIN dbo.T015User su ON su.UserGUID = m.SuperviseurUserGUID
    WHERE m.CabinetId = @cabId AND m.IsActive = 1
      AND (@role IN ('admin', 'solo')
           OR m.UserGUID = @uid
           OR (m.Role = 'technicien' AND m.SuperviseurUserGUID = @uid))
    ORDER BY CASE WHEN m.Role = 'technicien' THEN 1 ELSE 0 END, u.FirstName, u.LastName, u.Email;

    -- Les superviseurs possibles : comptables (employés) et administrateurs actifs
    SELECT m.UserGUID, LTRIM(ISNULL(u.FirstName, '') + ' ' + ISNULL(u.LastName, '')) AS Nom, u.Email, m.Role
    FROM dbo.T332CabinetMembre m
    JOIN dbo.T015User u ON u.UserGUID = m.UserGUID AND u.IsDeleted = 0
    WHERE m.CabinetId = @cabId AND m.IsActive = 1 AND m.Role IN ('admin', 'solo', 'employe')
    ORDER BY u.FirstName, u.LastName;
END
GO

CREATE OR ALTER PROCEDURE dbo.s1001ListDossiersMembre
    @UserId varchar(200),
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
    IF @cabId IS NULL OR @role NOT IN ('admin', 'solo') RETURN;

    DECLARE @membre uniqueidentifier = (SELECT UserGUID FROM dbo.T332CabinetMembre
                                        WHERE Id = @MembreId AND CabinetId = @cabId AND IsActive = 1);
    IF @membre IS NULL RETURN;

    SELECT f.CompanyGUID, dbo.fCompanyName(f.CompanyGUID) AS Nom,
           CAST(CASE WHEN d.AssignedUserGUID = @membre THEN 1 ELSE 0 END AS bit) AS Confie,
           LTRIM(ISNULL(a.FirstName, '') + ' ' + ISNULL(a.LastName, '')) AS AssigneA
    FROM dbo.fCabinetDossiers(@uid) f
    LEFT JOIN dbo.T334CabinetDossier d ON d.CabinetId = @cabId AND d.CompanyGUID = f.CompanyGUID
    LEFT JOIN dbo.T015User a ON a.UserGUID = d.AssignedUserGUID
    ORDER BY dbo.fCompanyName(f.CompanyGUID);
END
GO
