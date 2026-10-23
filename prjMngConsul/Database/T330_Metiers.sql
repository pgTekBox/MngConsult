-- =============================================================================
-- T330 — Les métiers dans la base (gérés dans la console d'administration)
--
-- La liste des métiers (Paramètres › Entreprise › Métier, et la page « Qui fait
-- quoi ») venait de js/qui-fait-quoi-data.js (DATA.M). Elle est maintenant ici,
-- gérée dans prjSec60Admin (Abonnements › Métiers) ; seed_T330_metiers.sql la
-- remplit à partir de l'inventaire v5.2 (201 métiers, 560 lignes métier × profil).
--
--   T330Metier         un métier : nom (unique), famille, actif
--   T330MetierProfil   les profils où le métier existe (TA, Cie 0, Cie 1-4),
--                      avec son groupe (« — », « Sociétés ») et ses taxes
--                      (Taxable, Exonéré, Détaxé, Mixte, À valider)
--
--   s0912GetMetiers            (ERP) les métiers actifs, une ligne par profil,
--                              comme DATA.M : Nom (m), Profil (p), Famille (f),
--                              Groupe (g), Taxes (t)
--   s0913GetMetiersAdminList   (admin) liste avec recherche, profils, compagnies
--   s0914GetMetierById         (admin) la fiche, puis ses profils
--   s0915SaveMetier            (admin) crée ou met à jour ; renommer met aussi à
--                              jour le paramètre METIER des compagnies concernées
--   s0916DeleteMetier          (admin) supprime un métier qu'aucune compagnie n'a choisi
--   s0917GetFamillesMetier     (admin) les familles existantes
--
-- Le paramètre METIER de chaque compagnie (T101ParamValues.sVal) garde le NOM du
-- métier : c'est le lien avec cette table et avec les actions « Qui fait quoi »
-- propres à un métier (js/qui-fait-quoi-data.js, DATA.A, champ m).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T330Metier', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T330Metier (
        Id          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T330Metier PRIMARY KEY,
        Nom         NVARCHAR(150) NOT NULL,
        Famille     NVARCHAR(100) NOT NULL,
        IsActive    BIT           NOT NULL CONSTRAINT DF_T330Metier_IsActive DEFAULT (1),
        CreatedOn   DATETIME      NOT NULL CONSTRAINT DF_T330Metier_CreatedOn DEFAULT (GETDATE()),
        ModifiedOn  DATETIME      NULL,
        CONSTRAINT UQ_T330Metier_Nom UNIQUE (Nom)
    );
END
GO

IF OBJECT_ID('dbo.T330MetierProfil', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T330MetierProfil (
        MetierId  INT          NOT NULL,
        Profil    NVARCHAR(10) NOT NULL,
        Groupe    NVARCHAR(50) NOT NULL CONSTRAINT DF_T330MetierProfil_Groupe DEFAULT (N'—'),
        Taxes     NVARCHAR(30) NOT NULL CONSTRAINT DF_T330MetierProfil_Taxes DEFAULT (N'Taxable'),
        CONSTRAINT PK_T330MetierProfil PRIMARY KEY (MetierId, Profil),
        CONSTRAINT FK_T330MetierProfil_Metier FOREIGN KEY (MetierId) REFERENCES dbo.T330Metier (Id) ON DELETE CASCADE,
        CONSTRAINT CK_T330MetierProfil_Profil CHECK (Profil IN (N'TA', N'Cie 0', N'Cie 1-4'))
    );
END
GO

-- -----------------------------------------------------------------------------
-- (ERP) Les métiers actifs, une ligne par profil, triés par nom.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0912GetMetiers
AS
BEGIN
    SET NOCOUNT ON;
    SELECT m.Nom, p.Profil, m.Famille, p.Groupe, p.Taxes
    FROM dbo.T330Metier m
    JOIN dbo.T330MetierProfil p ON p.MetierId = m.Id
    WHERE m.IsActive = 1
    ORDER BY m.Nom,
             CASE p.Profil WHEN N'TA' THEN 1 WHEN N'Cie 0' THEN 2 ELSE 3 END;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) Tous les métiers, par nom ; recherche sur le nom et la famille.
-- Profils : « TA, Cie 0, Cie 1-4 » ; NbCompagnies : compagnies qui l'ont choisi.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0913GetMetiersAdminList
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), N'');
    SELECT
        m.Id, m.Nom, m.Famille, m.IsActive,
        STUFF((SELECT N', ' + p.Profil FROM dbo.T330MetierProfil p WHERE p.MetierId = m.Id
               ORDER BY CASE p.Profil WHEN N'TA' THEN 1 WHEN N'Cie 0' THEN 2 ELSE 3 END
               FOR XML PATH(''), TYPE).value('.', 'nvarchar(100)'), 1, 2, N'') AS Profils,
        (SELECT COUNT(DISTINCT v.CompanyGUID)
           FROM dbo.T101ParamValues v
           JOIN dbo.T100ParamComptable t ON t.Id = v.T100Id AND t.ShortName = 'METIER'
          WHERE v.sVal = m.Nom) AS NbCompagnies
    FROM dbo.T330Metier m
    WHERE @Search IS NULL OR m.Nom LIKE N'%' + @Search + N'%' OR m.Famille LIKE N'%' + @Search + N'%'
    ORDER BY m.Nom;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) La fiche d'un métier, puis ses profils.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0914GetMetierById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Nom, Famille, IsActive FROM dbo.T330Metier WHERE Id = @Id;
    SELECT Profil, Groupe, Taxes FROM dbo.T330MetierProfil WHERE MetierId = @Id;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) Crée (@Id = 0) ou met à jour un métier et ses profils.
--   @Profils : « TA|—|Taxable;Cie 0|Sociétés|Taxable;… » (profil|groupe|taxes),
--              au moins un profil.
--   Refuse un nom ou une famille vides, ou un nom déjà pris.
--   Renommer met aussi à jour le paramètre METIER des compagnies qui avaient
--   choisi l'ancien nom (@NbRenommes).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0915SaveMetier
    @Id         INT,
    @Nom        NVARCHAR(150),
    @Famille    NVARCHAR(100),
    @IsActive   BIT,
    @Profils    NVARCHAR(1000),
    @NewId      INT OUTPUT,
    @NbRenommes INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Nom = LTRIM(RTRIM(ISNULL(@Nom, N'')));
    SET @Famille = LTRIM(RTRIM(ISNULL(@Famille, N'')));
    SET @NbRenommes = 0;

    IF @Nom = N''     BEGIN RAISERROR(N'Le nom du métier est obligatoire.', 16, 1); RETURN; END
    IF @Famille = N'' BEGIN RAISERROR(N'La famille est obligatoire.', 16, 1); RETURN; END
    IF EXISTS (SELECT 1 FROM dbo.T330Metier WHERE Nom = @Nom AND Id <> ISNULL(@Id, 0))
        BEGIN RAISERROR(N'Un autre métier porte déjà ce nom.', 16, 1); RETURN; END

    -- Les profils reçus
    DECLARE @p TABLE (Profil NVARCHAR(10) PRIMARY KEY, Groupe NVARCHAR(50), Taxes NVARCHAR(30));
    INSERT INTO @p (Profil, Groupe, Taxes)
    SELECT DISTINCT
        LTRIM(RTRIM(PARSENAME(REPLACE(x.value, N'|', N'.'), 3))),
        ISNULL(NULLIF(LTRIM(RTRIM(PARSENAME(REPLACE(x.value, N'|', N'.'), 2))), N''), N'—'),
        ISNULL(NULLIF(LTRIM(RTRIM(PARSENAME(REPLACE(x.value, N'|', N'.'), 1))), N''), N'Taxable')
    FROM STRING_SPLIT(ISNULL(@Profils, N''), N';') x
    WHERE LTRIM(RTRIM(x.value)) <> N'';
    IF NOT EXISTS (SELECT 1 FROM @p)
        BEGIN RAISERROR(N'Cochez au moins un profil.', 16, 1); RETURN; END
    IF EXISTS (SELECT 1 FROM @p WHERE Profil NOT IN (N'TA', N'Cie 0', N'Cie 1-4'))
        BEGIN RAISERROR(N'Profil inconnu.', 16, 1); RETURN; END

    BEGIN TRANSACTION;

    IF ISNULL(@Id, 0) = 0
    BEGIN
        INSERT INTO dbo.T330Metier (Nom, Famille, IsActive) VALUES (@Nom, @Famille, ISNULL(@IsActive, 1));
        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        DECLARE @Ancien NVARCHAR(150) = (SELECT Nom FROM dbo.T330Metier WHERE Id = @Id);
        IF @Ancien IS NULL BEGIN ROLLBACK; RAISERROR(N'Métier introuvable.', 16, 1); RETURN; END

        UPDATE dbo.T330Metier SET Nom = @Nom, Famille = @Famille, IsActive = ISNULL(@IsActive, 1), ModifiedOn = GETDATE()
        WHERE Id = @Id;
        SET @NewId = @Id;

        -- Renommé : les compagnies qui avaient choisi l'ancien nom suivent.
        IF @Ancien <> @Nom
        BEGIN
            UPDATE v SET v.sVal = @Nom
            FROM dbo.T101ParamValues v
            JOIN dbo.T100ParamComptable t ON t.Id = v.T100Id AND t.ShortName = 'METIER'
            WHERE v.sVal = @Ancien;
            SET @NbRenommes = @@ROWCOUNT;
        END
    END

    DELETE FROM dbo.T330MetierProfil WHERE MetierId = @NewId;
    INSERT INTO dbo.T330MetierProfil (MetierId, Profil, Groupe, Taxes)
    SELECT @NewId, Profil, Groupe, Taxes FROM @p;

    COMMIT;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) Supprime un métier, s'il n'est choisi par aucune compagnie (sinon :
-- le mettre Inactif, il disparaît des listes sans toucher aux compagnies).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0916DeleteMetier
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Nom NVARCHAR(150) = (SELECT Nom FROM dbo.T330Metier WHERE Id = @Id);
    IF @Nom IS NULL RETURN;
    IF EXISTS (SELECT 1 FROM dbo.T101ParamValues v
               JOIN dbo.T100ParamComptable t ON t.Id = v.T100Id AND t.ShortName = 'METIER'
               WHERE v.sVal = @Nom)
    BEGIN
        RAISERROR(N'Des compagnies ont choisi ce métier : mettez-le plutôt Inactif.', 16, 1);
        RETURN;
    END
    DELETE FROM dbo.T330Metier WHERE Id = @Id;
END
GO

-- -----------------------------------------------------------------------------
-- (admin) Les familles déjà utilisées, par nom.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0917GetFamillesMetier
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Famille, COUNT(*) AS NbMetiers FROM dbo.T330Metier GROUP BY Famille ORDER BY Famille;
END
GO
