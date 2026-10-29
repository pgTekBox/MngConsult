-- =============================================================================
-- T339_Portail_droits.sql — Portail comptable Phase 4, Part E
-- Droits par domaine, par membre : qui, dans le cabinet, prend en charge quels
-- domaines d'activités. Déclaratif/organisationnel (l'accès reste par dossier).
-- Procs libres : s0947+. Table : T342MembreDroit.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.T342MembreDroit', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T342MembreDroit (
        Id         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CabinetId  INT               NOT NULL,
        UserGUID   UNIQUEIDENTIFIER  NOT NULL,
        Domaine    NVARCHAR(30)      NOT NULL,
        CreatedUtc DATETIME2(0)      NOT NULL CONSTRAINT DF_T342_Created DEFAULT SYSUTCDATETIME()
    );
    CREATE UNIQUE INDEX UX_T342 ON dbo.T342MembreDroit(CabinetId, UserGUID, Domaine);
END
GO

-- ---------------------------------------------------------------------------
-- s0947GetDroits : les (UserGUID, Domaine) accordés dans le cabinet de l'appelant.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0947GetDroits
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @cabId int;
    SELECT TOP 1 @cabId = m.CabinetId FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0 ORDER BY m.Id;

    SELECT d.UserGUID, d.Domaine
    FROM dbo.T342MembreDroit d
    WHERE d.CabinetId = @cabId;
END
GO

-- ---------------------------------------------------------------------------
-- s0948SetDroit : accorde (@Accorde=1) ou retire un domaine à un membre. admin/solo.
-- ErrorCode : 0=OK, 2=non autorisé, 5=membre hors cabinet.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0948SetDroit
    @UserId          varchar(200),
    @MembreUserGUID  uniqueidentifier,
    @Domaine         nvarchar(30),
    @Accorde         bit,
    @ErrorCode       int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;

    DECLARE @cabId int, @role nvarchar(20);
    SELECT TOP 1 @cabId = m.CabinetId, @role = m.Role FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0 ORDER BY m.Id;

    IF @cabId IS NULL OR @role NOT IN ('admin','solo') BEGIN SET @ErrorCode = 2; RETURN; END
    IF NOT EXISTS (SELECT 1 FROM dbo.T332CabinetMembre WHERE CabinetId = @cabId AND UserGUID = @MembreUserGUID AND IsActive = 1)
    BEGIN SET @ErrorCode = 5; RETURN; END

    IF @Accorde = 1
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.T342MembreDroit WHERE CabinetId = @cabId AND UserGUID = @MembreUserGUID AND Domaine = @Domaine)
            INSERT INTO dbo.T342MembreDroit (CabinetId, UserGUID, Domaine) VALUES (@cabId, @MembreUserGUID, @Domaine);
    END
    ELSE
    BEGIN
        DELETE FROM dbo.T342MembreDroit WHERE CabinetId = @cabId AND UserGUID = @MembreUserGUID AND Domaine = @Domaine;
    END
END
GO
