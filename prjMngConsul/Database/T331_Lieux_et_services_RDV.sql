-- =============================================================================
-- T331 — Les lieux des services et les services offerts en rendez-vous
--
-- Produits et services › Lieux (wbfLieux.aspx) gère les lieux de la compagnie :
-- chez le client, à la place d'affaires, à distance, ou un autre lieu nommé.
-- Chaque service choisit ses lieux dans sa fiche (wbfProductEdit.aspx) ; la
-- fenêtre « Nouveau RDV » (wbfAppointmentEdit.aspx) offre les services offerts
-- en rendez-vous, puis les lieux du service choisi.
--
--   T331Lieu           un lieu : nom (unique par compagnie), type, adresse, actif
--   T331ServiceLieu    les lieux d'un service (T075Products) : seuls les lieux
--                      cochés sont offerts dans le rendez-vous (aucun = aucun lieu)
--
-- Un produit est offert en rendez-vous quand T075Products.Appointment = 1, ou
-- quand Appointment est NULL et que c'est un service (TypeArticle = 'service',
-- les services importés). Appointment = 0 le retire. DurationMinutes donne la
-- durée du rendez-vous (60 min si elle manque).
--
--   s0918GetLieux               les lieux (pose les trois lieux de base la première fois)
--   s0919GetLieuById            la fiche d'un lieu
--   s0920SaveLieu               crée ou met à jour un lieu
--   s0921DeleteLieu             supprime un lieu (et ses liens aux services)
--   s0922GetServiceRdv          le rendez-vous d'un service : offert, durée, puis ses lieux
--   s0923SaveServiceRdv         enregistre l'offre, la durée et les lieux d'un service
--   s0924GetServicesRdv         (Nouveau RDV) les services offerts, puis les lieux actifs
--   s0925PoserLieuxDeBase       les trois lieux de base d'une compagnie qui n'en a aucun
--
-- vwAppointmentTypes ne filtre plus sur Appointment : l'agenda garde le nom du
-- service d'un RDV même si le service n'est plus offert en rendez-vous.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T331Lieu', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T331Lieu (
        Id          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T331Lieu PRIMARY KEY,
        CompanyGUID UNIQUEIDENTIFIER  NOT NULL,
        Nom         NVARCHAR(150)     NOT NULL,
        TypeLieu    NVARCHAR(20)      NOT NULL CONSTRAINT DF_T331Lieu_TypeLieu DEFAULT (N'autre'),
        Adresse     NVARCHAR(300)     NULL,
        Actif       BIT               NOT NULL CONSTRAINT DF_T331Lieu_Actif DEFAULT (1),
        Ordre       INT               NOT NULL CONSTRAINT DF_T331Lieu_Ordre DEFAULT (0),
        CreatedOn   DATETIME          NOT NULL CONSTRAINT DF_T331Lieu_CreatedOn DEFAULT (GETDATE()),
        ModifiedOn  DATETIME          NULL,
        CONSTRAINT UQ_T331Lieu_Nom UNIQUE (CompanyGUID, Nom),
        CONSTRAINT CK_T331Lieu_TypeLieu CHECK (TypeLieu IN (N'client', N'affaires', N'distance', N'autre'))
    );
END
GO

IF OBJECT_ID('dbo.T331ServiceLieu', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T331ServiceLieu (
        ProductId  INT NOT NULL,
        LieuId     INT NOT NULL,
        CONSTRAINT PK_T331ServiceLieu PRIMARY KEY (ProductId, LieuId),
        CONSTRAINT FK_T331ServiceLieu_Lieu FOREIGN KEY (LieuId) REFERENCES dbo.T331Lieu (Id) ON DELETE CASCADE
    );
END
GO

-- -----------------------------------------------------------------------------
-- Le nom du service d'un RDV, qu'il soit encore offert en rendez-vous ou non.
-- -----------------------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vwAppointmentTypes
AS
SELECT Id, Name AS TypeName, Appointment, CompanyGUID, ColorHex, DurationMinutes, Actif AS isActive
FROM dbo.T075Products
GO

-- -----------------------------------------------------------------------------
-- Les trois lieux de base d'une compagnie qui n'a encore aucun lieu.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0925PoserLieuxDeBase
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.T331Lieu WHERE CompanyGUID = @CompanyGUID)
        INSERT INTO dbo.T331Lieu (CompanyGUID, Nom, TypeLieu, Ordre)
        VALUES (@CompanyGUID, N'Chez le client', N'client', 1),
               (@CompanyGUID, N'À votre place d''affaires', N'affaires', 2),
               (@CompanyGUID, N'À distance', N'distance', 3);
END
GO

-- -----------------------------------------------------------------------------
-- Les lieux de la compagnie, par ordre puis par nom ; NbServices : les services
-- qui l'ont choisi. La première fois, pose les trois lieux de base.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0918GetLieux
    @CompanyGUID UNIQUEIDENTIFIER,
    @Search      NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.s0925PoserLieuxDeBase @CompanyGUID = @CompanyGUID;

    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), N'');
    SELECT
        l.Id, l.Nom, l.TypeLieu, ISNULL(l.Adresse, N'') AS Adresse, l.Actif, l.Ordre,
        (SELECT COUNT(*) FROM dbo.T331ServiceLieu sl WHERE sl.LieuId = l.Id) AS NbServices
    FROM dbo.T331Lieu l
    WHERE l.CompanyGUID = @CompanyGUID
      AND (@Search IS NULL OR l.Nom LIKE N'%' + @Search + N'%' OR l.Adresse LIKE N'%' + @Search + N'%')
    ORDER BY l.Ordre, l.Nom;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0919GetLieuById
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Nom, TypeLieu, ISNULL(Adresse, N'') AS Adresse, Actif, Ordre
    FROM dbo.T331Lieu
    WHERE CompanyGUID = @CompanyGUID AND Id = @Id;
END
GO

-- -----------------------------------------------------------------------------
-- Crée (@Id = 0) ou met à jour un lieu. Refuse un nom vide ou déjà pris.
-- Un nouveau lieu se place après les autres.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0920SaveLieu
    @Id          INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @Nom         NVARCHAR(150),
    @TypeLieu    NVARCHAR(20),
    @Adresse     NVARCHAR(300) = NULL,
    @Actif       BIT = 1,
    @NewId       INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Nom = LTRIM(RTRIM(ISNULL(@Nom, N'')));
    SET @Adresse = NULLIF(LTRIM(RTRIM(@Adresse)), N'');
    IF @TypeLieu NOT IN (N'client', N'affaires', N'distance', N'autre') SET @TypeLieu = N'autre';

    IF @Nom = N'' BEGIN RAISERROR(N'Le nom du lieu est obligatoire.', 16, 1); RETURN; END
    IF EXISTS (SELECT 1 FROM dbo.T331Lieu WHERE CompanyGUID = @CompanyGUID AND Nom = @Nom AND Id <> ISNULL(@Id, 0))
        BEGIN RAISERROR(N'Un autre lieu porte déjà ce nom.', 16, 1); RETURN; END

    IF ISNULL(@Id, 0) = 0
    BEGIN
        INSERT INTO dbo.T331Lieu (CompanyGUID, Nom, TypeLieu, Adresse, Actif, Ordre)
        VALUES (@CompanyGUID, @Nom, @TypeLieu, @Adresse, @Actif,
                ISNULL((SELECT MAX(Ordre) FROM dbo.T331Lieu WHERE CompanyGUID = @CompanyGUID), 0) + 1);
        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.T331Lieu
           SET Nom = @Nom, TypeLieu = @TypeLieu, Adresse = @Adresse, Actif = @Actif, ModifiedOn = GETDATE()
         WHERE CompanyGUID = @CompanyGUID AND Id = @Id;
        SET @NewId = @Id;
    END
END
GO

CREATE OR ALTER PROCEDURE dbo.s0921DeleteLieu
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.T331Lieu WHERE CompanyGUID = @CompanyGUID AND Id = @Id;
END
GO

-- -----------------------------------------------------------------------------
-- Le rendez-vous d'un service : offert (selon la règle de l'en-tête), durée ;
-- puis tous les lieux de la compagnie, Choisi = 1 pour ceux du service.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0922GetServiceRdv
    @CompanyGUID UNIQUEIDENTIFIER,
    @ProductId   INT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.s0925PoserLieuxDeBase @CompanyGUID = @CompanyGUID;

    SELECT
        CAST(CASE WHEN p.Appointment = 1 OR (p.Appointment IS NULL AND p.TypeArticle = 'service') THEN 1 ELSE 0 END AS BIT) AS Offert,
        ISNULL(p.DurationMinutes, 0) AS DurationMinutes
    FROM dbo.T075Products p
    WHERE p.CompanyGUID = @CompanyGUID AND p.Id = @ProductId;

    SELECT l.Id, l.Nom, l.TypeLieu, l.Actif,
           CAST(CASE WHEN sl.LieuId IS NULL THEN 0 ELSE 1 END AS BIT) AS Choisi
    FROM dbo.T331Lieu l
    LEFT JOIN dbo.T331ServiceLieu sl ON sl.LieuId = l.Id AND sl.ProductId = @ProductId
    WHERE l.CompanyGUID = @CompanyGUID
    ORDER BY l.Ordre, l.Nom;
END
GO

-- -----------------------------------------------------------------------------
-- Enregistre l'offre en rendez-vous, la durée et les lieux d'un service.
--   @LieuIds : « 1,4,7 » ; vide = aucun lieu offert.
--   Seuls les lieux de la compagnie sont retenus.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0923SaveServiceRdv
    @CompanyGUID     UNIQUEIDENTIFIER,
    @ProductId       INT,
    @Offert          BIT,
    @DurationMinutes INT = NULL,
    @LieuIds         NVARCHAR(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.T075Products WHERE CompanyGUID = @CompanyGUID AND Id = @ProductId) RETURN;

    BEGIN TRAN;
        UPDATE dbo.T075Products
           SET Appointment = CASE WHEN @Offert = 1 THEN 1 ELSE 0 END,
               DurationMinutes = NULLIF(@DurationMinutes, 0)
         WHERE CompanyGUID = @CompanyGUID AND Id = @ProductId;

        DELETE FROM dbo.T331ServiceLieu WHERE ProductId = @ProductId;

        INSERT INTO dbo.T331ServiceLieu (ProductId, LieuId)
        SELECT DISTINCT @ProductId, l.Id
        FROM STRING_SPLIT(ISNULL(@LieuIds, N''), N',') x
        JOIN dbo.T331Lieu l ON l.Id = TRY_CAST(LTRIM(RTRIM(x.value)) AS INT) AND l.CompanyGUID = @CompanyGUID;
    COMMIT;
END
GO

-- -----------------------------------------------------------------------------
-- (Nouveau RDV) Les services actifs offerts en rendez-vous, par nom :
--   Duree (60 min si elle manque), Prix, LieuIds « 1,4 » (vide = aucun lieu) ;
-- puis les lieux actifs de la compagnie.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0924GetServicesRdv
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.s0925PoserLieuxDeBase @CompanyGUID = @CompanyGUID;

    SELECT
        p.Id,
        p.Name AS Nom,
        ISNULL(NULLIF(p.DurationMinutes, 0), 60) AS Duree,
        ISNULL(p.Prix, 0) AS Prix,
        ISNULL(STUFF((SELECT N',' + CAST(sl.LieuId AS NVARCHAR(10))
                      FROM dbo.T331ServiceLieu sl
                      JOIN dbo.T331Lieu l ON l.Id = sl.LieuId AND l.Actif = 1
                      WHERE sl.ProductId = p.Id
                      ORDER BY l.Ordre, l.Nom
                      FOR XML PATH(''), TYPE).value('.', 'nvarchar(2000)'), 1, 1, N''), N'') AS LieuIds
    FROM dbo.T075Products p
    WHERE p.CompanyGUID = @CompanyGUID
      AND ISNULL(p.Actif, 1) = 1
      AND (p.Appointment = 1 OR (p.Appointment IS NULL AND p.TypeArticle = 'service'))
    ORDER BY p.Name;

    SELECT Id, Nom, TypeLieu, ISNULL(Adresse, N'') AS Adresse
    FROM dbo.T331Lieu
    WHERE CompanyGUID = @CompanyGUID AND Actif = 1
    ORDER BY Ordre, Nom;
END
GO
