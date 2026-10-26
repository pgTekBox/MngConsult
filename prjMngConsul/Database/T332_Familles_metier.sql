-- =============================================================================
-- T332 — Les familles de métiers (gérées dans la console d'administration)
--
-- La famille d'un métier (T330Metier.Famille) était un texte libre. Les familles
-- ont maintenant leur table, gérée dans prjSec60Admin (Abonnements › Familles de
-- métiers), remplie à partir des familles déjà utilisées par les métiers. La fiche
-- d'un métier choisit sa famille dans cette liste.
--
--   T332FamilleMetier   une famille : nom (unique)
--
-- T330Metier.Famille garde le NOM de la famille (lu tel quel par s0912 et par
-- « Qui fait quoi ») ; une clé étrangère sur ce nom, ON UPDATE CASCADE :
--   - renommer une famille renomme aussi la famille de ses métiers ;
--   - une famille encore portée par un métier ne peut pas être supprimée.
--
--   s0917GetFamillesMetier          (admin) les familles, maintenant lues ici
--                                   (aussi celles sans métier)
--   s0926GetFamillesMetierAdminList (admin) liste avec recherche, nombre de métiers
--   s0927GetFamilleMetierById       (admin) la fiche
--   s0928SaveFamilleMetier          (admin) crée ou renomme (@NbMetiers : métiers suivis)
--   s0929DeleteFamilleMetier        (admin) supprime une famille qu'aucun métier ne porte
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T332FamilleMetier', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T332FamilleMetier (
        Id          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T332FamilleMetier PRIMARY KEY,
        Nom         NVARCHAR(100) NOT NULL,
        CreatedOn   DATETIME      NOT NULL CONSTRAINT DF_T332FamilleMetier_CreatedOn DEFAULT (GETDATE()),
        ModifiedOn  DATETIME      NULL,
        CONSTRAINT UQ_T332FamilleMetier_Nom UNIQUE (Nom)
    );
END
GO

-- Les familles déjà utilisées par les métiers (sans espaces autour, pour la clé étrangère).
UPDATE dbo.T330Metier SET Famille = LTRIM(RTRIM(Famille))
WHERE DATALENGTH(Famille) <> DATALENGTH(LTRIM(RTRIM(Famille)));

INSERT INTO dbo.T332FamilleMetier (Nom)
SELECT DISTINCT m.Famille
FROM dbo.T330Metier m
WHERE NOT EXISTS (SELECT 1 FROM dbo.T332FamilleMetier f WHERE f.Nom = m.Famille);
GO

-- Le métier porte le nom d'une famille existante ; renommer la famille le suit.
IF OBJECT_ID('dbo.FK_T330Metier_Famille', 'F') IS NULL
    ALTER TABLE dbo.T330Metier WITH CHECK
        ADD CONSTRAINT FK_T330Metier_Famille FOREIGN KEY (Famille)
            REFERENCES dbo.T332FamilleMetier (Nom) ON UPDATE CASCADE;
GO

-- -----------------------------------------------------------------------------
-- (admin) Les familles, par nom, pour la liste de la fiche Métier.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0917GetFamillesMetier
AS
BEGIN
    SET NOCOUNT ON;
    SELECT f.Nom AS Famille,
           (SELECT COUNT(*) FROM dbo.T330Metier m WHERE m.Famille = f.Nom) AS NbMetiers
    FROM dbo.T332FamilleMetier f
    ORDER BY f.Nom;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) Toutes les familles, par nom ; recherche sur le nom.
-- NbMetiers : les métiers de la famille ; NbActifs : ceux qui sont actifs.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0926GetFamillesMetierAdminList
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), N'');
    SELECT
        f.Id, f.Nom,
        (SELECT COUNT(*) FROM dbo.T330Metier m WHERE m.Famille = f.Nom) AS NbMetiers,
        (SELECT COUNT(*) FROM dbo.T330Metier m WHERE m.Famille = f.Nom AND m.IsActive = 1) AS NbActifs
    FROM dbo.T332FamilleMetier f
    WHERE @Search IS NULL OR f.Nom LIKE N'%' + @Search + N'%'
    ORDER BY f.Nom;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) La fiche d'une famille.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0927GetFamilleMetierById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT f.Id, f.Nom,
           (SELECT COUNT(*) FROM dbo.T330Metier m WHERE m.Famille = f.Nom) AS NbMetiers
    FROM dbo.T332FamilleMetier f
    WHERE f.Id = @Id;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) Crée (@Id = 0) ou renomme une famille.
--   Refuse un nom vide ou déjà pris.
--   Renommer met aussi à jour les métiers de la famille (FK ON UPDATE CASCADE) ;
--   @NbMetiers : le nombre de métiers renommés.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0928SaveFamilleMetier
    @Id        INT,
    @Nom       NVARCHAR(100),
    @NewId     INT OUTPUT,
    @NbMetiers INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Nom = LTRIM(RTRIM(ISNULL(@Nom, N'')));
    SET @NbMetiers = 0;

    IF @Nom = N'' BEGIN RAISERROR(N'Le nom de la famille est obligatoire.', 16, 1); RETURN; END
    IF EXISTS (SELECT 1 FROM dbo.T332FamilleMetier WHERE Nom = @Nom AND Id <> ISNULL(@Id, 0))
        BEGIN RAISERROR(N'Une autre famille porte déjà ce nom.', 16, 1); RETURN; END

    IF ISNULL(@Id, 0) = 0
    BEGIN
        INSERT INTO dbo.T332FamilleMetier (Nom) VALUES (@Nom);
        SET @NewId = SCOPE_IDENTITY();
        RETURN;
    END

    DECLARE @Ancien NVARCHAR(100) = (SELECT Nom FROM dbo.T332FamilleMetier WHERE Id = @Id);
    IF @Ancien IS NULL BEGIN RAISERROR(N'Famille introuvable.', 16, 1); RETURN; END

    IF @Ancien <> @Nom COLLATE Latin1_General_BIN
        SET @NbMetiers = (SELECT COUNT(*) FROM dbo.T330Metier WHERE Famille = @Ancien);
    -- Les métiers suivent par la clé étrangère (ON UPDATE CASCADE).
    UPDATE dbo.T332FamilleMetier SET Nom = @Nom, ModifiedOn = GETDATE() WHERE Id = @Id;
    SET @NewId = @Id;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) Supprime une famille, si aucun métier ne la porte (sinon : changer
-- d'abord la famille de ces métiers).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0929DeleteFamilleMetier
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Nom NVARCHAR(100) = (SELECT Nom FROM dbo.T332FamilleMetier WHERE Id = @Id);
    IF @Nom IS NULL RETURN;
    DECLARE @Nb INT = (SELECT COUNT(*) FROM dbo.T330Metier WHERE Famille = @Nom);
    IF @Nb > 0
    BEGIN
        RAISERROR(N'%d métier(s) portent encore cette famille : changez d''abord leur famille.', 16, 1, @Nb);
        RETURN;
    END
    DELETE FROM dbo.T332FamilleMetier WHERE Id = @Id;
END
GO
