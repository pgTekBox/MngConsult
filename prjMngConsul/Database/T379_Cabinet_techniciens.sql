-- =============================================================================
-- T379 — Portail comptable : les techniciens du cabinet
--
-- Nouveau rôle de membre « technicien » (technicien comptable), à côté
-- d'admin / employé / solo :
--   - il ne voit et n'entre que dans les dossiers qui lui sont confiés
--     (T334CabinetDossier.AssignedUserGUID), comme un employé ;
--   - il travaille sous un SUPERVISEUR (un employé ou un administrateur du
--     cabinet) : T332CabinetMembre.SuperviseurUserGUID. Un employé superviseur
--     voit aussi les dossiers confiés à ses techniciens (fCabinetDossiers).
--
--   fCabinetDossiers    : + dossiers des techniciens supervisés (rôle employé)
--   s0922ListCabinetMembres : + superviseur
--   s0923 / s0924       : acceptent le rôle « technicien »
--   s0997ListTechniciens : les techniciens (admin/solo : tous ; employé : les
--                          siens) avec superviseur, dossiers, tâches ouvertes
--                          et en retard, dernière connexion
--   s0998SetSuperviseur  : change le superviseur d'un technicien (admin/solo)
--   s0999ListDossiersTechnicien : les dossiers du cabinet, cochés quand ils
--                          sont confiés au technicien (pour « Gérer les dossiers »)
-- La page wbfCabTechniciens confie/retire les dossiers par s0930AssignDossier.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ── Le rôle et le superviseur ──────────────────────────────────────────────
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_T332_Role')
    ALTER TABLE dbo.T332CabinetMembre DROP CONSTRAINT CK_T332_Role;
ALTER TABLE dbo.T332CabinetMembre WITH CHECK ADD CONSTRAINT CK_T332_Role
    CHECK ([Role] IN ('solo', 'employe', 'responsable', 'admin', 'technicien'));
GO

IF COL_LENGTH('dbo.T332CabinetMembre', 'SuperviseurUserGUID') IS NULL
    ALTER TABLE dbo.T332CabinetMembre ADD SuperviseurUserGUID UNIQUEIDENTIFIER NULL;
GO

-- ── Le périmètre des dossiers ──────────────────────────────────────────────
CREATE OR ALTER FUNCTION dbo.fCabinetDossiers(@UserGUID uniqueidentifier)
RETURNS @r TABLE (CompanyGUID uniqueidentifier PRIMARY KEY)
AS
BEGIN
    DECLARE @cabId int, @role nvarchar(20), @equipeId int;
    SELECT TOP 1 @cabId = m.CabinetId, @role = m.Role, @equipeId = m.EquipeId
    FROM dbo.T332CabinetMembre m
    JOIN dbo.T331Cabinet cab ON cab.Id = m.CabinetId AND cab.IsActive = 1
    WHERE m.UserGUID = @UserGUID AND m.IsActive = 1
    ORDER BY m.Id;

    IF @cabId IS NULL
        RETURN;

    IF @role IN ('admin', 'solo')
        INSERT INTO @r (CompanyGUID)
        SELECT c.CompanyGUID
        FROM dbo.T010Company c
        WHERE c.ComptableGUID IN (
            SELECT UserGUID FROM dbo.T332CabinetMembre WHERE CabinetId = @cabId AND IsActive = 1
        );
    ELSE IF @role = 'responsable'
        INSERT INTO @r (CompanyGUID)
        SELECT DISTINCT d.CompanyGUID
        FROM dbo.T334CabinetDossier d
        WHERE d.CabinetId = @cabId AND d.EquipeId = @equipeId;
    ELSE
        -- employé / technicien : ses dossiers ; un employé voit aussi ceux de ses techniciens
        INSERT INTO @r (CompanyGUID)
        SELECT DISTINCT d.CompanyGUID
        FROM dbo.T334CabinetDossier d
        WHERE d.CabinetId = @cabId
          AND (d.AssignedUserGUID = @UserGUID
               OR (@role = 'employe' AND d.AssignedUserGUID IN (
                       SELECT t.UserGUID FROM dbo.T332CabinetMembre t
                       WHERE t.CabinetId = @cabId AND t.IsActive = 1
                         AND t.Role = 'technicien' AND t.SuperviseurUserGUID = @UserGUID)));

    RETURN;
END
GO

-- ── Les membres, avec leur superviseur ─────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0922ListCabinetMembres
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @uid uniqueidentifier, @cabId int;
    SELECT TOP 1 @uid = u.UserGUID, @cabId = m.CabinetId
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    SELECT
        m.Id            AS MembreId,
        m.UserGUID,
        u.Email,
        u.FirstName,
        u.LastName,
        m.Role,
        m.EquipeId,
        eq.Nom          AS EquipeNom,
        u.IsActive,
        CAST(CASE WHEN u.IsActive = 0 THEN 1 ELSE 0 END AS bit) AS Pending,
        CAST(CASE WHEN u.UserGUID = @uid THEN 1 ELSE 0 END AS bit) AS IsMe,
        m.SuperviseurUserGUID,
        LTRIM(ISNULL(su.FirstName, '') + ' ' + ISNULL(su.LastName, '')) AS SuperviseurNom
    FROM dbo.T332CabinetMembre m
    JOIN dbo.T015User u      ON u.UserGUID = m.UserGUID AND u.IsDeleted = 0
    LEFT JOIN dbo.T333Equipe eq ON eq.Id = m.EquipeId
    LEFT JOIN dbo.T015User su ON su.UserGUID = m.SuperviseurUserGUID
    WHERE m.CabinetId = @cabId AND m.IsActive = 1
    ORDER BY u.FirstName, u.LastName, u.Email;
END
GO

-- ── s0923 / s0924 acceptent « technicien » (texte relu sur le serveur) ─────
DECLARE @def NVARCHAR(MAX), @p INT;

SET @def = OBJECT_DEFINITION(OBJECT_ID('dbo.s0923InviteCabinetMembre'));
IF CHARINDEX(N'''technicien''', @def) = 0
BEGIN
    SET @def = REPLACE(@def, N'IF @Role NOT IN (''admin'', ''responsable'', ''employe'') SET @Role = ''employe'';',
                             N'IF @Role NOT IN (''admin'', ''responsable'', ''employe'', ''technicien'') SET @Role = ''employe'';');
    IF CHARINDEX(N'''technicien''', @def) = 0 THROW 51120, 's0923 : liste des rôles introuvable.', 1;
    SET @p = CHARINDEX(N'CREATE', @def); SET @def = STUFF(@def, @p, 6, N'ALTER');
    EXEC sys.sp_executesql @def;
END

SET @def = OBJECT_DEFINITION(OBJECT_ID('dbo.s0924UpdateCabinetMembre'));
IF CHARINDEX(N'''technicien''', @def) = 0
BEGIN
    SET @def = REPLACE(@def, N'IF @Role NOT IN (''admin'', ''responsable'', ''employe'', ''solo'') SET @Role = ''employe'';',
                             N'IF @Role NOT IN (''admin'', ''responsable'', ''employe'', ''solo'', ''technicien'') SET @Role = ''employe'';');
    IF CHARINDEX(N'''technicien''', @def) = 0 THROW 51121, 's0924 : liste des rôles introuvable.', 1;
    SET @p = CHARINDEX(N'CREATE', @def); SET @def = STUFF(@def, @p, 6, N'ALTER');
    EXEC sys.sp_executesql @def;
END
GO

-- ── Les techniciens du cabinet ─────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0997ListTechniciens
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
        u.Email, u.FirstName, u.LastName,
        CAST(CASE WHEN u.IsActive = 0 THEN 1 ELSE 0 END AS bit) AS Pending,
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
        CAST(CASE WHEN @role IN ('admin', 'solo') THEN 1 ELSE 0 END AS bit) AS PeutGerer
    FROM dbo.T332CabinetMembre m
    JOIN dbo.T015User u ON u.UserGUID = m.UserGUID AND u.IsDeleted = 0
    LEFT JOIN dbo.T015User su ON su.UserGUID = m.SuperviseurUserGUID
    WHERE m.CabinetId = @cabId AND m.IsActive = 1 AND m.Role = 'technicien'
      AND (@role IN ('admin', 'solo') OR m.SuperviseurUserGUID = @uid)
    ORDER BY u.FirstName, u.LastName, u.Email;

    -- Les superviseurs possibles : employés et administrateurs actifs du cabinet
    SELECT m.UserGUID, LTRIM(ISNULL(u.FirstName, '') + ' ' + ISNULL(u.LastName, '')) AS Nom, u.Email, m.Role
    FROM dbo.T332CabinetMembre m
    JOIN dbo.T015User u ON u.UserGUID = m.UserGUID AND u.IsDeleted = 0
    WHERE m.CabinetId = @cabId AND m.IsActive = 1 AND m.Role IN ('admin', 'solo', 'employe')
    ORDER BY u.FirstName, u.LastName;
END
GO

-- ── Le superviseur d'un technicien ─────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0998SetSuperviseur
    @UserId varchar(200),
    @MembreId int,
    @SuperviseurUserGUID uniqueidentifier = NULL,
    @ErrorCode int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;
    DECLARE @cabId int, @role nvarchar(20);
    SELECT TOP 1 @cabId = m.CabinetId, @role = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    IF @cabId IS NULL OR @role NOT IN ('admin', 'solo') BEGIN SET @ErrorCode = 2; RETURN; END
    IF NOT EXISTS (SELECT 1 FROM dbo.T332CabinetMembre WHERE Id = @MembreId AND CabinetId = @cabId AND Role = 'technicien')
    BEGIN SET @ErrorCode = 3; RETURN; END
    IF @SuperviseurUserGUID IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM dbo.T332CabinetMembre WHERE CabinetId = @cabId AND IsActive = 1
          AND UserGUID = @SuperviseurUserGUID AND Role IN ('admin', 'solo', 'employe'))
    BEGIN SET @ErrorCode = 4; RETURN; END

    UPDATE dbo.T332CabinetMembre SET SuperviseurUserGUID = @SuperviseurUserGUID
    WHERE Id = @MembreId AND CabinetId = @cabId;
END
GO

-- ── Les dossiers du cabinet, cochés pour un technicien ─────────────────────
CREATE OR ALTER PROCEDURE dbo.s0999ListDossiersTechnicien
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

    DECLARE @tech uniqueidentifier = (SELECT UserGUID FROM dbo.T332CabinetMembre
                                      WHERE Id = @MembreId AND CabinetId = @cabId AND Role = 'technicien');
    IF @tech IS NULL RETURN;

    SELECT f.CompanyGUID, dbo.fCompanyName(f.CompanyGUID) AS Nom,
           CAST(CASE WHEN d.AssignedUserGUID = @tech THEN 1 ELSE 0 END AS bit) AS Confie,
           LTRIM(ISNULL(a.FirstName, '') + ' ' + ISNULL(a.LastName, '')) AS AssigneA
    FROM dbo.fCabinetDossiers(@uid) f
    LEFT JOIN dbo.T334CabinetDossier d ON d.CabinetId = @cabId AND d.CompanyGUID = f.CompanyGUID
    LEFT JOIN dbo.T015User a ON a.UserGUID = d.AssignedUserGUID
    ORDER BY dbo.fCompanyName(f.CompanyGUID);
END
GO
