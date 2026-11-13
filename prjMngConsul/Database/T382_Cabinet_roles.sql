-- =============================================================================
-- T382 — Portail comptable : gestion des rôles du cabinet
-- Chaque cabinet a ses rôles (table T335CabinetRole). Un rôle porte un nom,
-- une description et un NIVEAU D'ACCÈS (Acces) qui décide de ce que voit le
-- membre — ce niveau est recopié dans T332CabinetMembre.Role, si bien que
-- toute la logique existante (fCabinetDossiers, menus, droits) reste inchangée :
--   admin      : tous les dossiers du cabinet, gère le cabinet
--   employe    : ses dossiers + ceux des techniciens qu'il supervise
--   technicien : seulement les dossiers qui lui sont confiés
-- Trois rôles de base par cabinet (IsSysteme = 1, non supprimables, niveau
-- fixe) : Administrateur, Comptable, Technicien. Un rôle utilisé par au moins
-- un membre ne peut pas être supprimé.
--   s1003ListRolesCabinet  : les rôles + nombre de membres (provisionne les rôles de base)
--   s1004SaveRoleCabinet   : ajoute / modifie un rôle
--   s1005DeleteRoleCabinet : supprime un rôle inutilisé
--   s1006SetRoleMembre     : donne un rôle à un membre
--   s1000ListEquipeCabinet : renvoie RoleId / RoleNom
-- ErrorCode : 0 OK, 1 nom déjà pris, 2 non autorisé, 3 dernier administrateur,
--             5 introuvable, 8 rôle utilisé, 9 rôle de base, 11 nom requis.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T335CabinetRole') IS NULL
BEGIN
    CREATE TABLE dbo.T335CabinetRole (
        Id          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T335CabinetRole PRIMARY KEY,
        CabinetId   INT NOT NULL,
        Nom         NVARCHAR(80) NOT NULL,
        Description NVARCHAR(400) NULL,
        Acces       NVARCHAR(20) NOT NULL,
        IsSysteme   BIT NOT NULL CONSTRAINT DF_T335_IsSysteme DEFAULT (0),
        CreatedUtc  DATETIME2 NOT NULL CONSTRAINT DF_T335_Created DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT CK_T335_Acces CHECK (Acces IN ('admin', 'employe', 'technicien'))
    );
    CREATE UNIQUE INDEX UX_T335_Cabinet_Nom ON dbo.T335CabinetRole (CabinetId, Nom);
END
GO

IF COL_LENGTH('dbo.T332CabinetMembre', 'RoleId') IS NULL
    ALTER TABLE dbo.T332CabinetMembre ADD RoleId INT NULL;
GO

-- ── Les rôles de base d'un cabinet ─────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s1007ProvisionRolesCabinet
    @CabinetId int
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.T335CabinetRole WHERE CabinetId = @CabinetId AND IsSysteme = 1 AND Acces = 'admin')
        INSERT INTO dbo.T335CabinetRole (CabinetId, Nom, Description, Acces, IsSysteme)
        VALUES (@CabinetId, N'Administrateur', N'Gère le cabinet et voit tous les dossiers.', 'admin', 1);
    IF NOT EXISTS (SELECT 1 FROM dbo.T335CabinetRole WHERE CabinetId = @CabinetId AND IsSysteme = 1 AND Acces = 'employe')
        INSERT INTO dbo.T335CabinetRole (CabinetId, Nom, Description, Acces, IsSysteme)
        VALUES (@CabinetId, N'Comptable', N'Suit ses dossiers et ceux des techniciens qu''il supervise.', 'employe', 1);
    IF NOT EXISTS (SELECT 1 FROM dbo.T335CabinetRole WHERE CabinetId = @CabinetId AND IsSysteme = 1 AND Acces = 'technicien')
        INSERT INTO dbo.T335CabinetRole (CabinetId, Nom, Description, Acces, IsSysteme)
        VALUES (@CabinetId, N'Technicien', N'Ne voit que les dossiers qui lui sont confiés, sous un superviseur.', 'technicien', 1);

    -- Les membres sans rôle (ou dont le rôle ne correspond plus) reprennent le rôle de base de leur niveau
    UPDATE m SET RoleId = r.Id
    FROM dbo.T332CabinetMembre m
    JOIN dbo.T335CabinetRole r ON r.CabinetId = m.CabinetId AND r.IsSysteme = 1
         AND r.Acces = CASE WHEN m.Role IN ('admin', 'technicien') THEN m.Role ELSE 'employe' END
    WHERE m.CabinetId = @CabinetId AND m.Role <> 'solo'
      AND NOT EXISTS (SELECT 1 FROM dbo.T335CabinetRole x WHERE x.Id = m.RoleId AND x.CabinetId = m.CabinetId
                      AND x.Acces = CASE WHEN m.Role IN ('admin', 'technicien') THEN m.Role ELSE 'employe' END);
END
GO

DECLARE @c int;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT Id FROM dbo.T331Cabinet;
OPEN cur; FETCH NEXT FROM cur INTO @c;
WHILE @@FETCH_STATUS = 0 BEGIN EXEC dbo.s1007ProvisionRolesCabinet @c; FETCH NEXT FROM cur INTO @c; END
CLOSE cur; DEALLOCATE cur;
GO

-- ── Liste des rôles ────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s1003ListRolesCabinet
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @cabId int, @role nvarchar(20);
    SELECT TOP 1 @cabId = m.CabinetId, @role = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;
    IF @cabId IS NULL OR @role NOT IN ('admin', 'solo', 'employe') RETURN;

    EXEC dbo.s1007ProvisionRolesCabinet @cabId;

    SELECT r.Id, r.Nom, r.Description, r.Acces, r.IsSysteme,
           (SELECT COUNT(*) FROM dbo.T332CabinetMembre m
            JOIN dbo.T015User u ON u.UserGUID = m.UserGUID AND u.IsDeleted = 0
            WHERE m.RoleId = r.Id AND m.CabinetId = @cabId AND m.IsActive = 1) AS NbMembres,
           STUFF((SELECT ', ' + LTRIM(ISNULL(u.FirstName, '') + ' ' + ISNULL(u.LastName, ''))
                  FROM dbo.T332CabinetMembre m
                  JOIN dbo.T015User u ON u.UserGUID = m.UserGUID AND u.IsDeleted = 0
                  WHERE m.RoleId = r.Id AND m.CabinetId = @cabId AND m.IsActive = 1
                  ORDER BY u.FirstName, u.LastName
                  FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Membres,
           CAST(CASE WHEN @role IN ('admin', 'solo') THEN 1 ELSE 0 END AS bit) AS PeutGerer
    FROM dbo.T335CabinetRole r
    WHERE r.CabinetId = @cabId
    ORDER BY r.IsSysteme DESC, CASE r.Acces WHEN 'admin' THEN 0 WHEN 'employe' THEN 1 ELSE 2 END, r.Nom;
END
GO

-- ── Ajouter / modifier un rôle ─────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s1004SaveRoleCabinet
    @UserId      varchar(200),
    @RoleId      int,
    @Nom         nvarchar(80),
    @Description nvarchar(400),
    @Acces       nvarchar(20),
    @NewId       int OUTPUT,
    @ErrorCode   int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0; SET @NewId = NULL;
    DECLARE @cabId int, @role nvarchar(20);
    SELECT TOP 1 @cabId = m.CabinetId, @role = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;
    IF @cabId IS NULL OR @role NOT IN ('admin', 'solo') BEGIN SET @ErrorCode = 2; RETURN; END

    SET @Nom = LTRIM(RTRIM(ISNULL(@Nom, '')));
    IF @Nom = '' BEGIN SET @ErrorCode = 11; RETURN; END
    IF @Acces NOT IN ('admin', 'employe', 'technicien') SET @Acces = 'employe';
    IF EXISTS (SELECT 1 FROM dbo.T335CabinetRole WHERE CabinetId = @cabId AND Nom = @Nom AND Id <> ISNULL(@RoleId, 0))
    BEGIN SET @ErrorCode = 1; RETURN; END

    IF ISNULL(@RoleId, 0) = 0
    BEGIN
        INSERT INTO dbo.T335CabinetRole (CabinetId, Nom, Description, Acces, IsSysteme)
        VALUES (@cabId, @Nom, NULLIF(LTRIM(RTRIM(@Description)), ''), @Acces, 0);
        SET @NewId = SCOPE_IDENTITY();
        RETURN;
    END

    DECLARE @sys bit, @ancien nvarchar(20);
    SELECT @sys = IsSysteme, @ancien = Acces FROM dbo.T335CabinetRole WHERE Id = @RoleId AND CabinetId = @cabId;
    IF @ancien IS NULL BEGIN SET @ErrorCode = 5; RETURN; END
    IF @sys = 1 SET @Acces = @ancien;   -- le niveau d'un rôle de base ne change pas

    -- Changer le niveau d'un rôle utilisé : le cabinet doit garder un administrateur
    IF @Acces <> @ancien AND @ancien = 'admin'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.T332CabinetMembre m
                       JOIN dbo.T015User u ON u.UserGUID = m.UserGUID AND u.IsDeleted = 0 AND u.IsActive = 1
                       WHERE m.CabinetId = @cabId AND m.IsActive = 1 AND m.Role IN ('admin', 'solo')
                         AND ISNULL(m.RoleId, 0) <> @RoleId)
        BEGIN SET @ErrorCode = 3; RETURN; END
    END

    UPDATE dbo.T335CabinetRole
    SET Nom = @Nom, Description = NULLIF(LTRIM(RTRIM(@Description)), ''), Acces = @Acces
    WHERE Id = @RoleId AND CabinetId = @cabId;

    IF @Acces <> @ancien
        UPDATE dbo.T332CabinetMembre SET Role = @Acces
        WHERE RoleId = @RoleId AND CabinetId = @cabId AND Role <> 'solo';
    SET @NewId = @RoleId;
END
GO

-- ── Supprimer un rôle inutilisé ────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s1005DeleteRoleCabinet
    @UserId    varchar(200),
    @RoleId    int,
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

    DECLARE @sys bit = (SELECT IsSysteme FROM dbo.T335CabinetRole WHERE Id = @RoleId AND CabinetId = @cabId);
    IF @sys IS NULL BEGIN SET @ErrorCode = 5; RETURN; END
    IF @sys = 1 BEGIN SET @ErrorCode = 9; RETURN; END
    -- Utilisé par un membre (même désactivé ou en attente) : on ne supprime pas
    IF EXISTS (SELECT 1 FROM dbo.T332CabinetMembre WHERE RoleId = @RoleId AND CabinetId = @cabId AND IsActive = 1)
    BEGIN SET @ErrorCode = 8; RETURN; END

    DELETE FROM dbo.T335CabinetRole WHERE Id = @RoleId AND CabinetId = @cabId;
END
GO

-- ── Donner un rôle à un membre ─────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s1006SetRoleMembre
    @UserId    varchar(200),
    @MembreId  int,
    @RoleId    int,
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

    DECLARE @tRole nvarchar(20), @tRoleId int;
    SELECT @tRole = Role, @tRoleId = RoleId FROM dbo.T332CabinetMembre
    WHERE Id = @MembreId AND CabinetId = @cabId AND IsActive = 1;
    IF @tRole IS NULL OR @tRole = 'solo' BEGIN SET @ErrorCode = 5; RETURN; END

    DECLARE @acces nvarchar(20) = (SELECT Acces FROM dbo.T335CabinetRole WHERE Id = @RoleId AND CabinetId = @cabId);
    IF @acces IS NULL BEGIN SET @ErrorCode = 5; RETURN; END

    -- Dernier administrateur
    IF @tRole = 'admin' AND @acces <> 'admin'
       AND NOT EXISTS (SELECT 1 FROM dbo.T332CabinetMembre m
                       JOIN dbo.T015User u ON u.UserGUID = m.UserGUID AND u.IsDeleted = 0 AND u.IsActive = 1
                       WHERE m.CabinetId = @cabId AND m.IsActive = 1 AND m.Role IN ('admin', 'solo') AND m.Id <> @MembreId)
    BEGIN SET @ErrorCode = 3; RETURN; END

    UPDATE dbo.T332CabinetMembre
    SET RoleId = @RoleId, Role = @acces,
        SuperviseurUserGUID = CASE WHEN @acces = 'technicien' THEN SuperviseurUserGUID ELSE NULL END
    WHERE Id = @MembreId AND CabinetId = @cabId;
END
GO

-- ── L'équipe : le nom du rôle ──────────────────────────────────────────────
DECLARE @def NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.s1000ListEquipeCabinet')), @p INT;
IF CHARINDEX(N'RoleNom', @def) = 0
BEGIN
    SET @def = REPLACE(@def, N'        m.Role,
        u.Email, u.FirstName, u.LastName,',
        N'        m.Role,
        m.RoleId,
        COALESCE(CASE WHEN rr.Acces = m.Role THEN rr.Nom END,
                 (SELECT TOP 1 rs.Nom FROM dbo.T335CabinetRole rs WHERE rs.CabinetId = m.CabinetId AND rs.IsSysteme = 1
                  AND rs.Acces = CASE WHEN m.Role IN (''admin'', ''technicien'') THEN m.Role ELSE ''employe'' END)) AS RoleNom,
        u.Email, u.FirstName, u.LastName,');
    SET @def = REPLACE(@def, N'    LEFT JOIN dbo.T015User su ON su.UserGUID = m.SuperviseurUserGUID
    WHERE m.CabinetId = @cabId AND m.IsActive = 1
      AND (@role IN',
        N'    LEFT JOIN dbo.T015User su ON su.UserGUID = m.SuperviseurUserGUID
    LEFT JOIN dbo.T335CabinetRole rr ON rr.Id = m.RoleId AND rr.CabinetId = m.CabinetId
    WHERE m.CabinetId = @cabId AND m.IsActive = 1
      AND (@role IN');
    IF CHARINDEX(N'RoleNom', @def) = 0 OR CHARINDEX(N'rr.Id = m.RoleId', @def) = 0
        THROW 51130, 's1000 : points d''ancrage introuvables.', 1;
    SET @p = CHARINDEX(N'CREATE', @def); SET @def = STUFF(@def, @p, 6, N'ALTER');
    EXEC sys.sp_executesql @def;
END
GO
