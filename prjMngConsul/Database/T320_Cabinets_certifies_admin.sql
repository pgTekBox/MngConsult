-- =============================================================================
-- T320 — Cabinets certifiés : la gestion de l'annuaire dans la console
--        d'administration (prjSec60Admin, Abonnements › Cabinets certifiés)
--
-- T319 a créé l'annuaire (T319CabinetCertifie) et sa lecture pour l'ERP
-- (s0900, les cabinets actifs). La console le gère maintenant : liste avec
-- recherche (actifs et inactifs), fiche, enregistrement, suppression.
--
--   s0901GetCabinetsAdminList (@Search) → tous les cabinets, par nom ;
--       recherche sur le nom, le responsable, la ville.
--   s0902GetCabinetById (@Id) → la fiche.
--   s0903SaveCabinet (@Id = 0 pour créer, …, @NewId OUT) → crée ou met à jour ;
--       refuse un nom vide ou déjà pris par un autre cabinet.
--   s0904DeleteCabinet (@Id) → supprime (l'annuaire n'est référencé nulle
--       part ; un cabinet qu'on veut seulement cacher passe Inactif).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0901GetCabinetsAdminList]
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.[Id], c.[Nom], c.[Responsable], c.[Ville], c.[Province], c.[Courriel],
           c.[Telephone], c.[SiteWeb], c.[Langues], c.[Specialites], c.[Description],
           c.[CertifieDepuis], c.[IsActive], c.[CreatedUtc]
      FROM dbo.T319CabinetCertifie c
     WHERE (@Search IS NULL OR @Search = ''
            OR c.[Nom] LIKE '%' + @Search + '%'
            OR c.[Responsable] LIKE '%' + @Search + '%'
            OR c.[Ville] LIKE '%' + @Search + '%')
     ORDER BY c.[Nom];
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0902GetCabinetById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.[Id], c.[Nom], c.[Responsable], c.[Ville], c.[Province], c.[Courriel],
           c.[Telephone], c.[SiteWeb], c.[Langues], c.[Specialites], c.[Description],
           c.[CertifieDepuis], c.[IsActive], c.[CreatedUtc]
      FROM dbo.T319CabinetCertifie c
     WHERE c.[Id] = @Id;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0903SaveCabinet]
    @Id             INT,
    @Nom            NVARCHAR(150),
    @Responsable    NVARCHAR(150) = NULL,
    @Ville          NVARCHAR(100) = NULL,
    @Province       NVARCHAR(50)  = NULL,
    @Courriel       NVARCHAR(200) = NULL,
    @Telephone      NVARCHAR(40)  = NULL,
    @SiteWeb        NVARCHAR(250) = NULL,
    @Langues        NVARCHAR(50)  = NULL,
    @Specialites    NVARCHAR(200) = NULL,
    @Description    NVARCHAR(500) = NULL,
    @CertifieDepuis DATE          = NULL,
    @IsActive       BIT           = 1,
    @NewId          INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Nom = NULLIF(LTRIM(RTRIM(@Nom)), '');
    IF @Nom IS NULL
    BEGIN
        RAISERROR(N'Le nom du cabinet est obligatoire.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.T319CabinetCertifie WHERE [Nom] = @Nom AND [Id] <> ISNULL(@Id, 0))
    BEGIN
        RAISERROR(N'Un autre cabinet porte déjà ce nom.', 16, 1);
        RETURN;
    END

    SET @Province = ISNULL(NULLIF(LTRIM(RTRIM(@Province)), ''), N'QC');
    SET @Langues  = ISNULL(NULLIF(LTRIM(RTRIM(@Langues)), ''), N'FR');

    IF ISNULL(@Id, 0) > 0 AND EXISTS (SELECT 1 FROM dbo.T319CabinetCertifie WHERE [Id] = @Id)
    BEGIN
        UPDATE dbo.T319CabinetCertifie
           SET [Nom] = @Nom, [Responsable] = @Responsable, [Ville] = @Ville, [Province] = @Province,
               [Courriel] = @Courriel, [Telephone] = @Telephone, [SiteWeb] = @SiteWeb,
               [Langues] = @Langues, [Specialites] = @Specialites, [Description] = @Description,
               [CertifieDepuis] = @CertifieDepuis, [IsActive] = ISNULL(@IsActive, 1)
         WHERE [Id] = @Id;
        SET @NewId = @Id;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.T319CabinetCertifie
            ([Nom], [Responsable], [Ville], [Province], [Courriel], [Telephone], [SiteWeb],
             [Langues], [Specialites], [Description], [CertifieDepuis], [IsActive])
        VALUES
            (@Nom, @Responsable, @Ville, @Province, @Courriel, @Telephone, @SiteWeb,
             @Langues, @Specialites, @Description, @CertifieDepuis, ISNULL(@IsActive, 1));
        SET @NewId = SCOPE_IDENTITY();
    END
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0904DeleteCabinet]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.T319CabinetCertifie WHERE [Id] = @Id;
END
GO
