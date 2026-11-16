-- =============================================================================
-- T392 — Dans le cabinet, tout le monde peut être superviseur
-- Avant : seuls les membres de niveau admin / solo / employe (« Superviseur »)
-- pouvaient superviser un employé au niveau Restreint (technicien).
-- Maintenant : n'importe quel membre actif du cabinet (sauf l'employé lui-même).
--   fCabinetDossiers : un employé (niveau employe ou technicien) voit ses
--       dossiers + ceux des membres qu'il supervise.
--   s0998SetSuperviseur : superviseur = tout membre actif du cabinet ≠ l'employé.
--   s1000ListEquipeCabinet : ouverte aux employés de niveau Restreint (lecture :
--       eux-mêmes + ceux qu'ils supervisent) ; superviseurs possibles = tous.
--   s1003ListRolesCabinet : lecture ouverte au niveau Restreint aussi.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

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
        -- employé (tout niveau) : ses dossiers + ceux des membres qu'il supervise (T392)
        INSERT INTO @r (CompanyGUID)
        SELECT DISTINCT d.CompanyGUID
        FROM dbo.T334CabinetDossier d
        WHERE d.CabinetId = @cabId
          AND (d.AssignedUserGUID = @UserGUID
               OR d.AssignedUserGUID IN (
                       SELECT t.UserGUID FROM dbo.T332CabinetMembre t
                       WHERE t.CabinetId = @cabId AND t.IsActive = 1
                         AND t.SuperviseurUserGUID = @UserGUID));

    RETURN;
END
GO

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
    DECLARE @cible uniqueidentifier = (SELECT UserGUID FROM dbo.T332CabinetMembre
                                       WHERE Id = @MembreId AND CabinetId = @cabId AND IsActive = 1 AND Role = 'technicien');
    IF @cible IS NULL BEGIN SET @ErrorCode = 3; RETURN; END
    -- T392 : tout membre actif du cabinet peut superviser, sauf l'employé lui-même
    IF @SuperviseurUserGUID IS NOT NULL AND (@SuperviseurUserGUID = @cible OR NOT EXISTS (
        SELECT 1 FROM dbo.T332CabinetMembre WHERE CabinetId = @cabId AND IsActive = 1
          AND UserGUID = @SuperviseurUserGUID))
    BEGIN SET @ErrorCode = 4; RETURN; END

    UPDATE dbo.T332CabinetMembre SET SuperviseurUserGUID = @SuperviseurUserGUID
    WHERE Id = @MembreId AND CabinetId = @cabId;
END
GO

-- ── s1000 / s1003 : ouvertes au niveau Restreint ; superviseurs possibles = tous
DECLARE @def nvarchar(max), @p int;

SET @def = OBJECT_DEFINITION(OBJECT_ID('dbo.s1000ListEquipeCabinet'));
IF CHARINDEX(N'T392', @def) = 0
BEGIN
    SET @def = REPLACE(@def, N'IF @cabId IS NULL OR @role NOT IN (''admin'', ''solo'', ''employe'') RETURN;',
                             N'IF @cabId IS NULL OR @role NOT IN (''admin'', ''solo'', ''employe'', ''technicien'') RETURN;  -- T392');
    SET @def = REPLACE(@def, N'OR (m.Role = ''technicien'' AND m.SuperviseurUserGUID = @uid))',
                             N'OR m.SuperviseurUserGUID = @uid)');
    SET @def = REPLACE(@def, N'WHERE m.CabinetId = @cabId AND m.IsActive = 1 AND m.Role IN (''admin'', ''solo'', ''employe'')',
                             N'WHERE m.CabinetId = @cabId AND m.IsActive = 1');
    IF CHARINDEX(N'T392', @def) = 0 OR CHARINDEX(N'OR m.SuperviseurUserGUID = @uid)', @def) = 0
        THROW 51180, N's1000 : ancres introuvables.', 1;
    SET @p = CHARINDEX(N'CREATE', @def); SET @def = STUFF(@def, @p, 6, N'ALTER');
    EXEC sys.sp_executesql @def;
END

SET @def = OBJECT_DEFINITION(OBJECT_ID('dbo.s1003ListRolesCabinet'));
IF CHARINDEX(N'T392', @def) = 0
BEGIN
    SET @def = REPLACE(@def, N'IF @cabId IS NULL OR @role NOT IN (''admin'', ''solo'', ''employe'') RETURN;',
                             N'IF @cabId IS NULL OR @role NOT IN (''admin'', ''solo'', ''employe'', ''technicien'') RETURN;  -- T392');
    IF CHARINDEX(N'T392', @def) = 0 THROW 51181, N's1003 : ancre introuvable.', 1;
    SET @p = CHARINDEX(N'CREATE', @def); SET @def = STUFF(@def, @p, 6, N'ALTER');
    EXEC sys.sp_executesql @def;
END
GO
