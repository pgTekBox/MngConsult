-- =============================================================================
-- T333 — Les secteurs d'activité des métiers (gérés dans la console d'administration)
--
-- Un métier peut appartenir à un secteur d'activité (Construction, Éducation,
-- Santé et services sociaux…), facultatif. Les secteurs sont gérés dans
-- prjSec60Admin (Abonnements › Secteurs d'activité) ; la fiche d'un métier choisit
-- le sien dans cette liste, ou aucun. seed_T333_secteurs.sql propose une première
-- liste de secteurs et un secteur pour chaque métier.
--
--   T333SecteurActivite   un secteur : nom (unique)
--   T330Metier.SecteurId  le secteur du métier (NULL : aucun)
--
--   s0913GetMetiersAdminList           (admin) la liste des métiers, avec leur secteur
--                                      (recherche aussi sur le secteur)
--   s0914GetMetierById                 (admin) la fiche, avec SecteurId, puis ses profils
--   s0930GetSecteursActiviteAdminList  (admin) liste avec recherche, nombre de métiers
--   s0931GetSecteurActiviteById        (admin) la fiche
--   s0932SaveSecteurActivite           (admin) crée ou renomme
--   s0933DeleteSecteurActivite         (admin) supprime un secteur qu'aucun métier ne porte
--   s0934SetMetierSecteur              (admin) le secteur d'un métier (après s0915)
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T333SecteurActivite', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T333SecteurActivite (
        Id          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T333SecteurActivite PRIMARY KEY,
        Nom         NVARCHAR(100) NOT NULL,
        CreatedOn   DATETIME      NOT NULL CONSTRAINT DF_T333SecteurActivite_CreatedOn DEFAULT (GETDATE()),
        ModifiedOn  DATETIME      NULL,
        CONSTRAINT UQ_T333SecteurActivite_Nom UNIQUE (Nom)
    );
END
GO

IF COL_LENGTH('dbo.T330Metier', 'SecteurId') IS NULL
    ALTER TABLE dbo.T330Metier ADD SecteurId INT NULL;
GO

IF OBJECT_ID('dbo.FK_T330Metier_Secteur', 'F') IS NULL
    ALTER TABLE dbo.T330Metier WITH CHECK
        ADD CONSTRAINT FK_T330Metier_Secteur FOREIGN KEY (SecteurId)
            REFERENCES dbo.T333SecteurActivite (Id);
GO

-- -----------------------------------------------------------------------------
-- (admin) Tous les métiers, par nom ; recherche sur le nom, la famille et le secteur.
-- Profils : « TA, Cie 0, Cie 1-4 » ; NbCompagnies : compagnies qui l'ont choisi.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0913GetMetiersAdminList
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), N'');
    SELECT
        m.Id, m.Nom, m.Famille, s.Nom AS Secteur, m.IsActive,
        STUFF((SELECT N', ' + p.Profil FROM dbo.T330MetierProfil p WHERE p.MetierId = m.Id
               ORDER BY CASE p.Profil WHEN N'TA' THEN 1 WHEN N'Cie 0' THEN 2 ELSE 3 END
               FOR XML PATH(''), TYPE).value('.', 'nvarchar(100)'), 1, 2, N'') AS Profils,
        (SELECT COUNT(DISTINCT v.CompanyGUID)
           FROM dbo.T101ParamValues v
           JOIN dbo.T100ParamComptable t ON t.Id = v.T100Id AND t.ShortName = 'METIER'
          WHERE v.sVal = m.Nom) AS NbCompagnies
    FROM dbo.T330Metier m
    LEFT JOIN dbo.T333SecteurActivite s ON s.Id = m.SecteurId
    WHERE @Search IS NULL OR m.Nom LIKE N'%' + @Search + N'%' OR m.Famille LIKE N'%' + @Search + N'%'
       OR s.Nom LIKE N'%' + @Search + N'%'
    ORDER BY m.Nom;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) La fiche d'un métier (avec son secteur), puis ses profils.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0914GetMetierById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Nom, Famille, SecteurId, IsActive FROM dbo.T330Metier WHERE Id = @Id;
    SELECT Profil, Groupe, Taxes FROM dbo.T330MetierProfil WHERE MetierId = @Id;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) Tous les secteurs, par nom ; recherche sur le nom.
-- NbMetiers : les métiers du secteur ; NbActifs : ceux qui sont actifs.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0930GetSecteursActiviteAdminList
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), N'');
    SELECT
        s.Id, s.Nom,
        (SELECT COUNT(*) FROM dbo.T330Metier m WHERE m.SecteurId = s.Id) AS NbMetiers,
        (SELECT COUNT(*) FROM dbo.T330Metier m WHERE m.SecteurId = s.Id AND m.IsActive = 1) AS NbActifs
    FROM dbo.T333SecteurActivite s
    WHERE @Search IS NULL OR s.Nom LIKE N'%' + @Search + N'%'
    ORDER BY s.Nom;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) La fiche d'un secteur.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0931GetSecteurActiviteById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.Id, s.Nom,
           (SELECT COUNT(*) FROM dbo.T330Metier m WHERE m.SecteurId = s.Id) AS NbMetiers
    FROM dbo.T333SecteurActivite s
    WHERE s.Id = @Id;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) Crée (@Id = 0) ou renomme un secteur. Refuse un nom vide ou déjà pris.
-- Les métiers suivent d'eux-mêmes : ils portent l'Id du secteur.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0932SaveSecteurActivite
    @Id    INT,
    @Nom   NVARCHAR(100),
    @NewId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Nom = LTRIM(RTRIM(ISNULL(@Nom, N'')));

    IF @Nom = N'' BEGIN RAISERROR(N'Le nom du secteur est obligatoire.', 16, 1); RETURN; END
    IF EXISTS (SELECT 1 FROM dbo.T333SecteurActivite WHERE Nom = @Nom AND Id <> ISNULL(@Id, 0))
        BEGIN RAISERROR(N'Un autre secteur porte déjà ce nom.', 16, 1); RETURN; END

    IF ISNULL(@Id, 0) = 0
    BEGIN
        INSERT INTO dbo.T333SecteurActivite (Nom) VALUES (@Nom);
        SET @NewId = SCOPE_IDENTITY();
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.T333SecteurActivite WHERE Id = @Id)
        BEGIN RAISERROR(N'Secteur introuvable.', 16, 1); RETURN; END
    UPDATE dbo.T333SecteurActivite SET Nom = @Nom, ModifiedOn = GETDATE() WHERE Id = @Id;
    SET @NewId = @Id;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) Supprime un secteur, si aucun métier ne le porte (sinon : changer
-- d'abord le secteur de ces métiers, ou le leur retirer).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0933DeleteSecteurActivite
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.T333SecteurActivite WHERE Id = @Id) RETURN;
    DECLARE @Nb INT = (SELECT COUNT(*) FROM dbo.T330Metier WHERE SecteurId = @Id);
    IF @Nb > 0
    BEGIN
        RAISERROR(N'%d métier(s) portent encore ce secteur : changez d''abord leur secteur.', 16, 1, @Nb);
        RETURN;
    END
    DELETE FROM dbo.T333SecteurActivite WHERE Id = @Id;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) Le secteur d'un métier ; @SecteurId NULL ou 0 : aucun.
-- Appelée par la fiche Métier après s0915SaveMetier.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0934SetMetierSecteur
    @MetierId  INT,
    @SecteurId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @SecteurId = NULLIF(@SecteurId, 0);
    IF @SecteurId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.T333SecteurActivite WHERE Id = @SecteurId)
        BEGIN RAISERROR(N'Secteur introuvable.', 16, 1); RETURN; END
    UPDATE dbo.T330Metier SET SecteurId = @SecteurId, ModifiedOn = GETDATE() WHERE Id = @MetierId;
END
GO
