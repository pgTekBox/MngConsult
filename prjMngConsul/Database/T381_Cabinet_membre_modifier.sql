-- =============================================================================
-- T381 — Portail comptable : fenêtre « Modifier le membre »
--   s1002UpdateMembreIdentite : prénom, nom et courriel d'un membre du cabinet
--                               (admin / solo). ErrorCode : 0 OK, 1 courriel déjà
--                               utilisé, 2 non autorisé, 5 introuvable,
--                               6 courriel invalide, 7 son propre courriel.
--   s1000ListEquipeCabinet    : distingue « en attente d'activation »
--                               (jeton d'invitation non utilisé) et « inactif »
--                               (compte désactivé) ; ajoute la colonne Inactif.
-- Le rôle / l'état actif passent par s0924, le superviseur par s0998.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s1002UpdateMembreIdentite
    @UserId    varchar(200),
    @MembreId  int,
    @FirstName nvarchar(100),
    @LastName  nvarchar(100),
    @Email     nvarchar(200),
    @ErrorCode int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;
    DECLARE @uid uniqueidentifier, @cabId int, @role nvarchar(20);
    SELECT TOP 1 @uid = u.UserGUID, @cabId = m.CabinetId, @role = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;
    IF @cabId IS NULL OR @role NOT IN ('admin', 'solo') BEGIN SET @ErrorCode = 2; RETURN; END

    DECLARE @cible uniqueidentifier = (SELECT UserGUID FROM dbo.T332CabinetMembre
                                       WHERE Id = @MembreId AND CabinetId = @cabId AND IsActive = 1);
    IF @cible IS NULL BEGIN SET @ErrorCode = 5; RETURN; END

    SET @Email = LTRIM(RTRIM(ISNULL(@Email, '')));
    IF @Email = '' OR CHARINDEX('@', @Email) < 2 OR CHARINDEX(' ', @Email) > 0 BEGIN SET @ErrorCode = 6; RETURN; END

    DECLARE @ancien nvarchar(200) = (SELECT TOP 1 Email FROM dbo.T015User WHERE UserGUID = @cible AND IsDeleted = 0);
    IF @cible = @uid AND @ancien <> @Email BEGIN SET @ErrorCode = 7; RETURN; END
    IF EXISTS (SELECT 1 FROM dbo.T015User WHERE Email = @Email AND IsDeleted = 0 AND UserGUID <> @cible)
    BEGIN SET @ErrorCode = 1; RETURN; END

    UPDATE dbo.T015User
    SET FirstName  = NULLIF(LTRIM(RTRIM(@FirstName)), ''),
        LastName   = NULLIF(LTRIM(RTRIM(@LastName)), ''),
        Email      = @Email,
        ModifiedOn = GETDATE(),
        ModifiedBy = @UserId
    WHERE UserGUID = @cible AND IsDeleted = 0;
END
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
        CAST(CASE WHEN u.IsActive = 0 AND u.ActivationToken IS NOT NULL THEN 1 ELSE 0 END AS bit) AS Pending,
        CAST(CASE WHEN u.IsActive = 0 AND u.ActivationToken IS NULL THEN 1 ELSE 0 END AS bit) AS Inactif,
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
