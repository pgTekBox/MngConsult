-- =============================================================================
-- T331_Portail_comptable.sql
-- Socle du « Portail comptable » : un cabinet (firme) regroupe des membres
-- (comptables T015User) avec un role interne (admin / responsable / employe /
-- solo), des equipes, et l'affectation des dossiers (compagnies clientes) a un
-- membre/equipe. Les 2 ecrans du 1er jet (Tableau de bord, Mes dossiers) lisent
-- ces tables ; la gestion des equipes (UI) viendra ensuite.
--
-- L'appartenance brute d'une compagnie au cabinet reste portee par
-- T010Company.ComptableGUID (= UserGUID d'un membre). T334 ne sert qu'a
-- l'affectation fine (quel membre/equipe suit le dossier).
--
-- Procs : s0919 GetUserCabinet, s0920 ListCabinetDossiers, s0921 GetCabinetKpis.
-- Seed demo : cabinet « Cabinet 60sec (demo) » + comptable@60sec.ca (solo) + ses
-- compagnies (ComptableGUID) comme dossiers.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ---------------------------------------------------------------------------
-- 1) Le cabinet
-- ---------------------------------------------------------------------------
IF OBJECT_ID('dbo.T331Cabinet', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T331Cabinet (
        Id                INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CabinetGUID       UNIQUEIDENTIFIER  NOT NULL CONSTRAINT DF_T331_Guid DEFAULT NEWID(),
        Nom               NVARCHAR(150)     NOT NULL,
        CabinetCertifieId INT               NULL,   -- lien optionnel vers T319CabinetCertifie.Id
        IsActive          BIT               NOT NULL CONSTRAINT DF_T331_Active DEFAULT 1,
        CreatedUtc        DATETIME2(0)      NOT NULL CONSTRAINT DF_T331_Created DEFAULT SYSUTCDATETIME()
    );
    CREATE UNIQUE INDEX UX_T331_Guid ON dbo.T331Cabinet(CabinetGUID);
END
GO

-- ---------------------------------------------------------------------------
-- 2) Les equipes internes (cree avant T332 car T332.EquipeId -> T333.Id)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('dbo.T333Equipe', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T333Equipe (
        Id                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CabinetId           INT               NOT NULL,
        Nom                 NVARCHAR(100)     NOT NULL,
        ResponsableUserGUID UNIQUEIDENTIFIER  NULL,
        IsActive            BIT               NOT NULL CONSTRAINT DF_T333_Active DEFAULT 1,
        CreatedUtc          DATETIME2(0)      NOT NULL CONSTRAINT DF_T333_Created DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_T333_Cabinet FOREIGN KEY (CabinetId) REFERENCES dbo.T331Cabinet(Id)
    );
    CREATE INDEX IX_T333_Cabinet ON dbo.T333Equipe(CabinetId);
END
GO

-- ---------------------------------------------------------------------------
-- 3) Les membres (comptables) du cabinet et leur role
-- ---------------------------------------------------------------------------
IF OBJECT_ID('dbo.T332CabinetMembre', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T332CabinetMembre (
        Id         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CabinetId  INT               NOT NULL,
        UserGUID   UNIQUEIDENTIFIER  NOT NULL,   -- -> T015User.UserGUID
        Role       NVARCHAR(20)      NOT NULL CONSTRAINT DF_T332_Role DEFAULT 'employe',
        EquipeId   INT               NULL,
        IsActive   BIT               NOT NULL CONSTRAINT DF_T332_Active DEFAULT 1,
        CreatedUtc DATETIME2(0)      NOT NULL CONSTRAINT DF_T332_Created DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_T332_Cabinet FOREIGN KEY (CabinetId) REFERENCES dbo.T331Cabinet(Id),
        CONSTRAINT FK_T332_Equipe  FOREIGN KEY (EquipeId)  REFERENCES dbo.T333Equipe(Id),
        CONSTRAINT CK_T332_Role CHECK (Role IN ('admin', 'responsable', 'employe', 'solo'))
    );
    CREATE UNIQUE INDEX UX_T332_CabinetUser ON dbo.T332CabinetMembre(CabinetId, UserGUID);
END
GO

-- ---------------------------------------------------------------------------
-- 4) L'affectation des dossiers (compagnies clientes) a un membre/equipe
-- ---------------------------------------------------------------------------
IF OBJECT_ID('dbo.T334CabinetDossier', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T334CabinetDossier (
        Id               INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CabinetId        INT               NOT NULL,
        CompanyGUID      UNIQUEIDENTIFIER  NOT NULL,   -- compagnie cliente (T010Company)
        AssignedUserGUID UNIQUEIDENTIFIER  NULL,
        EquipeId         INT               NULL,
        CreatedUtc       DATETIME2(0)      NOT NULL CONSTRAINT DF_T334_Created DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_T334_Cabinet FOREIGN KEY (CabinetId) REFERENCES dbo.T331Cabinet(Id),
        CONSTRAINT FK_T334_Equipe  FOREIGN KEY (EquipeId)  REFERENCES dbo.T333Equipe(Id)
    );
    CREATE UNIQUE INDEX UX_T334_CabinetCompany ON dbo.T334CabinetDossier(CabinetId, CompanyGUID);
END
GO

-- ---------------------------------------------------------------------------
-- s0919GetUserCabinet : le cabinet + role du comptable connecte (par email).
-- 0 ligne si l'utilisateur n'est membre d'aucun cabinet.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0919GetUserCabinet
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1
        cab.Id       AS CabinetId,
        cab.Nom      AS CabinetNom,
        m.Role       AS Role,
        m.EquipeId   AS EquipeId,
        eq.Nom       AS EquipeNom
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    JOIN dbo.T331Cabinet cab     ON cab.Id = m.CabinetId AND cab.IsActive = 1
    LEFT JOIN dbo.T333Equipe eq  ON eq.Id = m.EquipeId
    WHERE u.email = @UserId
      AND u.IsDeleted = 0
    ORDER BY m.Id;
END
GO

-- ---------------------------------------------------------------------------
-- s0920ListCabinetDossiers : les dossiers (compagnies) du cabinet, scopes par
-- role du comptable connecte :
--   admin / solo  -> toutes les compagnies dont ComptableGUID est un membre
--   responsable   -> compagnies affectees a son equipe (T334.EquipeId)
--   employe       -> compagnies qui lui sont affectees (T334.AssignedUserGUID)
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0920ListCabinetDossiers
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @uid UNIQUEIDENTIFIER, @cabId INT, @role NVARCHAR(20), @equipeId INT;
    SELECT TOP 1
        @uid = u.UserGUID, @cabId = m.CabinetId, @role = m.Role, @equipeId = m.EquipeId
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    JOIN dbo.T331Cabinet cab     ON cab.Id = m.CabinetId AND cab.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    IF @cabId IS NULL
    BEGIN
        -- Aucun cabinet : jeu de resultats vide avec les bonnes colonnes
        SELECT CAST(NULL AS UNIQUEIDENTIFIER) AS CompanyGUID,
               CAST(NULL AS NVARCHAR(200))    AS Name,
               CAST(NULL AS NVARCHAR(50))     AS CompanyCode,
               CAST(NULL AS UNIQUEIDENTIFIER) AS AssignedUserGUID,
               CAST(NULL AS INT)              AS EquipeId,
               CAST(NULL AS NVARCHAR(100))    AS EquipeNom
        WHERE 1 = 0;
        RETURN;
    END

    IF @role IN ('admin', 'solo')
    BEGIN
        SELECT
            c.CompanyGUID,
            dbo.fCompanyName(c.CompanyGUID) AS Name,
            c.CompanyCode,
            d.AssignedUserGUID,
            d.EquipeId,
            eq.Nom AS EquipeNom
        FROM dbo.T010Company c
        LEFT JOIN dbo.T334CabinetDossier d ON d.CabinetId = @cabId AND d.CompanyGUID = c.CompanyGUID
        LEFT JOIN dbo.T333Equipe eq        ON eq.Id = d.EquipeId
        WHERE c.ComptableGUID IN (
            SELECT UserGUID FROM dbo.T332CabinetMembre WHERE CabinetId = @cabId AND IsActive = 1
        )
        ORDER BY Name;
    END
    ELSE IF @role = 'responsable'
    BEGIN
        SELECT
            c.CompanyGUID,
            dbo.fCompanyName(c.CompanyGUID) AS Name,
            c.CompanyCode,
            d.AssignedUserGUID,
            d.EquipeId,
            eq.Nom AS EquipeNom
        FROM dbo.T334CabinetDossier d
        JOIN dbo.T010Company c      ON c.CompanyGUID = d.CompanyGUID
        LEFT JOIN dbo.T333Equipe eq ON eq.Id = d.EquipeId
        WHERE d.CabinetId = @cabId AND d.EquipeId = @equipeId
        ORDER BY Name;
    END
    ELSE
    BEGIN
        -- employe
        SELECT
            c.CompanyGUID,
            dbo.fCompanyName(c.CompanyGUID) AS Name,
            c.CompanyCode,
            d.AssignedUserGUID,
            d.EquipeId,
            eq.Nom AS EquipeNom
        FROM dbo.T334CabinetDossier d
        JOIN dbo.T010Company c      ON c.CompanyGUID = d.CompanyGUID
        LEFT JOIN dbo.T333Equipe eq ON eq.Id = d.EquipeId
        WHERE d.CabinetId = @cabId AND d.AssignedUserGUID = @uid
        ORDER BY Name;
    END
END
GO

-- ---------------------------------------------------------------------------
-- s0921GetCabinetKpis : compteurs du tableau de bord du cabinet.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0921GetCabinetKpis
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @uid UNIQUEIDENTIFIER, @cabId INT, @role NVARCHAR(20), @equipeId INT;
    SELECT TOP 1
        @uid = u.UserGUID, @cabId = m.CabinetId, @role = m.Role, @equipeId = m.EquipeId
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    JOIN dbo.T331Cabinet cab     ON cab.Id = m.CabinetId AND cab.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    DECLARE @nbDossiers INT = 0, @nbAMoi INT = 0, @nbMembres INT = 0, @nbEquipes INT = 0;

    IF @cabId IS NOT NULL
    BEGIN
        SELECT @nbMembres = COUNT(*) FROM dbo.T332CabinetMembre WHERE CabinetId = @cabId AND IsActive = 1;
        SELECT @nbEquipes = COUNT(*) FROM dbo.T333Equipe WHERE CabinetId = @cabId AND IsActive = 1;

        -- Total des dossiers du cabinet (compagnies rattachees a un membre)
        SELECT @nbDossiers = COUNT(*)
        FROM dbo.T010Company c
        WHERE c.ComptableGUID IN (
            SELECT UserGUID FROM dbo.T332CabinetMembre WHERE CabinetId = @cabId AND IsActive = 1
        );

        -- Dossiers « a moi » selon le role
        IF @role IN ('admin', 'solo')
            SET @nbAMoi = @nbDossiers;
        ELSE IF @role = 'responsable'
            SELECT @nbAMoi = COUNT(*) FROM dbo.T334CabinetDossier WHERE CabinetId = @cabId AND EquipeId = @equipeId;
        ELSE
            SELECT @nbAMoi = COUNT(*) FROM dbo.T334CabinetDossier WHERE CabinetId = @cabId AND AssignedUserGUID = @uid;
    END

    SELECT
        ISNULL(@role, '')   AS Role,
        @nbDossiers         AS NbDossiers,
        @nbAMoi             AS NbDossiersAMoi,
        @nbMembres          AS NbMembres,
        @nbEquipes          AS NbEquipes;
END
GO

-- ---------------------------------------------------------------------------
-- Seed demo (idempotent) : cabinet « Cabinet 60sec (demo) » + comptable@60sec.ca
-- en solo + ses compagnies (ComptableGUID) comme dossiers.
-- ---------------------------------------------------------------------------
DECLARE @compUid UNIQUEIDENTIFIER;
SELECT @compUid = UserGUID FROM dbo.T015User WHERE email = 'comptable@60sec.ca' AND IsDeleted = 0;

IF @compUid IS NOT NULL
BEGIN
    -- 1) Le cabinet (par Nom)
    DECLARE @cabId INT;
    SELECT @cabId = Id FROM dbo.T331Cabinet WHERE Nom = N'Cabinet 60sec (démo)';
    IF @cabId IS NULL
    BEGIN
        INSERT INTO dbo.T331Cabinet (Nom) VALUES (N'Cabinet 60sec (démo)');
        SET @cabId = SCOPE_IDENTITY();
    END

    -- 2) Le membre (solo)
    IF NOT EXISTS (SELECT 1 FROM dbo.T332CabinetMembre WHERE CabinetId = @cabId AND UserGUID = @compUid)
        INSERT INTO dbo.T332CabinetMembre (CabinetId, UserGUID, Role) VALUES (@cabId, @compUid, 'solo');

    -- 3) Les dossiers = compagnies dont il est le comptable, non deja presentes
    INSERT INTO dbo.T334CabinetDossier (CabinetId, CompanyGUID, AssignedUserGUID)
    SELECT @cabId, c.CompanyGUID, @compUid
    FROM dbo.T010Company c
    WHERE c.ComptableGUID = @compUid
      AND NOT EXISTS (
          SELECT 1 FROM dbo.T334CabinetDossier d
          WHERE d.CabinetId = @cabId AND d.CompanyGUID = c.CompanyGUID
      );
END
GO
