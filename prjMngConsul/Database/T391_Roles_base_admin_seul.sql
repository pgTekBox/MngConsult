-- =============================================================================
-- T391 — Les rôles de base « Comptable » et « Technicien » n'existent plus
-- Tout le monde est un employé : le seul rôle de base (IsSysteme = 1) est
-- « Administrateur ». Les autres rôles sont ceux que le cabinet crée (Rôles),
-- chacun avec son niveau d'accès (admin / employe = superviseur / technicien
-- = restreint) — ces niveaux techniques restent inchangés dans T332.Role.
--   1) Rôles de base « Comptable » / « Technicien » : supprimés s'ils ne sont
--      portés par personne ; sinon gardés comme rôles ordinaires (IsSysteme = 0),
--      que l'administrateur pourra renommer ou supprimer une fois libérés.
--   2) s1007ProvisionRolesCabinet : ne crée plus que « Administrateur ». Un
--      membre sans rôle valide reprend le premier rôle de son niveau ; s'il
--      n'y en a aucun, un rôle ordinaire est créé (« Employé » ou « Accès restreint »).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ── 1) Les anciens rôles de base ───────────────────────────────────────────
DELETE r
FROM dbo.T335CabinetRole r
WHERE r.IsSysteme = 1 AND r.Acces IN ('employe', 'technicien')
  AND NOT EXISTS (SELECT 1 FROM dbo.T332CabinetMembre m WHERE m.RoleId = r.Id AND m.IsActive = 1);
SELECT @@ROWCOUNT AS RolesDeBaseSupprimes;

UPDATE dbo.T335CabinetRole SET IsSysteme = 0
WHERE IsSysteme = 1 AND Acces IN ('employe', 'technicien');
SELECT @@ROWCOUNT AS RolesDeBaseGardesCommeOrdinaires;
GO

-- ── 2) Provisionnement : « Administrateur » seulement ──────────────────────
CREATE OR ALTER PROCEDURE dbo.s1007ProvisionRolesCabinet
    @CabinetId int
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.T335CabinetRole WHERE CabinetId = @CabinetId AND IsSysteme = 1 AND Acces = 'admin')
        INSERT INTO dbo.T335CabinetRole (CabinetId, Nom, Description, Acces, IsSysteme)
        VALUES (@CabinetId, N'Administrateur', N'Gère le cabinet et voit tous les dossiers.', 'admin', 1);

    -- Niveau attendu de chaque membre (solo à part)
    DECLARE @niveaux TABLE (Acces nvarchar(20) PRIMARY KEY, NomDefaut nvarchar(80), Descr nvarchar(400));
    INSERT INTO @niveaux VALUES
        ('employe',    N'Employé',          N'Suit ses dossiers et ceux des employés qu''il supervise.'),
        ('technicien', N'Accès restreint',  N'Ne voit que les dossiers qui lui sont confiés, sous un superviseur.');

    -- Un niveau porté par un membre sans rôle valide, et sans aucun rôle de ce niveau : rôle ordinaire créé
    INSERT INTO dbo.T335CabinetRole (CabinetId, Nom, Description, Acces, IsSysteme)
    SELECT DISTINCT @CabinetId, n.NomDefaut, n.Descr, n.Acces, 0
    FROM dbo.T332CabinetMembre m
    JOIN @niveaux n ON n.Acces = CASE WHEN m.Role = 'technicien' THEN 'technicien' ELSE 'employe' END
    WHERE m.CabinetId = @CabinetId AND m.Role NOT IN ('solo', 'admin')
      AND NOT EXISTS (SELECT 1 FROM dbo.T335CabinetRole x WHERE x.CabinetId = @CabinetId AND x.Acces = n.Acces)
      AND NOT EXISTS (SELECT 1 FROM dbo.T335CabinetRole y WHERE y.CabinetId = @CabinetId AND y.Nom = n.NomDefaut);

    -- Les membres sans rôle (ou dont le rôle ne correspond plus) reprennent le premier rôle de leur niveau
    UPDATE m SET RoleId = (SELECT TOP 1 r.Id FROM dbo.T335CabinetRole r
                           WHERE r.CabinetId = m.CabinetId
                             AND r.Acces = CASE WHEN m.Role IN ('admin', 'technicien') THEN m.Role ELSE 'employe' END
                           ORDER BY r.IsSysteme DESC, r.Id)
    FROM dbo.T332CabinetMembre m
    WHERE m.CabinetId = @CabinetId AND m.Role <> 'solo'
      AND NOT EXISTS (SELECT 1 FROM dbo.T335CabinetRole x WHERE x.Id = m.RoleId AND x.CabinetId = m.CabinetId
                      AND x.Acces = CASE WHEN m.Role IN ('admin', 'technicien') THEN m.Role ELSE 'employe' END);
END
GO

-- ── 3) s1000 : nom de rôle de repli = premier rôle du niveau (plus seulement les rôles de base)
DECLARE @def nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID('dbo.s1000ListEquipeCabinet')), @p int;
DECLARE @a nvarchar(400) = N'(SELECT TOP 1 rs.Nom FROM dbo.T335CabinetRole rs WHERE rs.CabinetId = m.CabinetId AND rs.IsSysteme = 1';
IF CHARINDEX(@a, @def) > 0
BEGIN
    SET @def = REPLACE(@def, @a, N'(SELECT TOP 1 rs.Nom FROM dbo.T335CabinetRole rs WHERE rs.CabinetId = m.CabinetId');
    SET @def = REPLACE(@def, N'THEN m.Role ELSE ''employe'' END)) AS RoleNom', N'THEN m.Role ELSE ''employe'' END ORDER BY rs.IsSysteme DESC, rs.Id)) AS RoleNom');
    SET @p = CHARINDEX(N'CREATE', @def); SET @def = STUFF(@def, @p, 6, N'ALTER');
    EXEC sys.sp_executesql @def;
END
GO

-- Réparer tous les cabinets
DECLARE @c int;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT Id FROM dbo.T331Cabinet;
OPEN cur; FETCH NEXT FROM cur INTO @c;
WHILE @@FETCH_STATUS = 0 BEGIN EXEC dbo.s1007ProvisionRolesCabinet @c; FETCH NEXT FROM cur INTO @c; END
CLOSE cur; DEALLOCATE cur;
GO
