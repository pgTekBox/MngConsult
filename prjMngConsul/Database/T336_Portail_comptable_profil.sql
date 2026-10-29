-- =============================================================================
-- T336_Portail_comptable_profil.sql
-- Phase 3 du Portail comptable :
--   * Profil du cabinet : colonnes de profil sur T331Cabinet + s0935/s0936.
--     « Fiche visible dans l'annuaire » publie/retire une ligne T319CabinetCertifie
--     (lien T331.CabinetCertifieId) lue par CabinetsCertifies.aspx.
--   * Fiche client : s0937GetDossierDetail (en-tête + affectation + compteurs QFQ).
-- Clients non associés et Activités à attribuer réutilisent l'existant
-- (s0920 / s0930AssignDossier ; s0150 / s0151) : aucune proc neuve.
-- Numéros réellement libres : s0935+. Dernier script : T336.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ---------------------------------------------------------------------------
-- Colonnes de profil sur T331Cabinet (gardes IF COL_LENGTH)
-- ---------------------------------------------------------------------------
IF COL_LENGTH('dbo.T331Cabinet', 'Responsable') IS NULL ALTER TABLE dbo.T331Cabinet ADD Responsable NVARCHAR(150) NULL;
IF COL_LENGTH('dbo.T331Cabinet', 'Ville') IS NULL ALTER TABLE dbo.T331Cabinet ADD Ville NVARCHAR(100) NULL;
IF COL_LENGTH('dbo.T331Cabinet', 'Province') IS NULL ALTER TABLE dbo.T331Cabinet ADD Province NVARCHAR(50) NULL;
IF COL_LENGTH('dbo.T331Cabinet', 'Courriel') IS NULL ALTER TABLE dbo.T331Cabinet ADD Courriel NVARCHAR(200) NULL;
IF COL_LENGTH('dbo.T331Cabinet', 'Telephone') IS NULL ALTER TABLE dbo.T331Cabinet ADD Telephone NVARCHAR(40) NULL;
IF COL_LENGTH('dbo.T331Cabinet', 'SiteWeb') IS NULL ALTER TABLE dbo.T331Cabinet ADD SiteWeb NVARCHAR(250) NULL;
IF COL_LENGTH('dbo.T331Cabinet', 'Langues') IS NULL ALTER TABLE dbo.T331Cabinet ADD Langues NVARCHAR(50) NULL;
IF COL_LENGTH('dbo.T331Cabinet', 'Specialites') IS NULL ALTER TABLE dbo.T331Cabinet ADD Specialites NVARCHAR(200) NULL;
IF COL_LENGTH('dbo.T331Cabinet', 'Description') IS NULL ALTER TABLE dbo.T331Cabinet ADD [Description] NVARCHAR(500) NULL;
IF COL_LENGTH('dbo.T331Cabinet', 'AccepteNouveauxClients') IS NULL ALTER TABLE dbo.T331Cabinet ADD AccepteNouveauxClients BIT NOT NULL CONSTRAINT DF_T331_Accepte DEFAULT 0;
IF COL_LENGTH('dbo.T331Cabinet', 'FichePublique') IS NULL ALTER TABLE dbo.T331Cabinet ADD FichePublique BIT NOT NULL CONSTRAINT DF_T331_Publique DEFAULT 0;
GO

-- ---------------------------------------------------------------------------
-- s0935GetCabinetProfil : le profil du cabinet de l'appelant.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0935GetCabinetProfil
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @cabId int;
    SELECT TOP 1 @cabId = m.CabinetId
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    SELECT
        c.Id, c.Nom, c.Responsable, c.[Description], c.Ville, c.Province,
        c.Courriel, c.Telephone, c.SiteWeb, c.Langues, c.Specialites,
        c.AccepteNouveauxClients, c.FichePublique, c.CabinetCertifieId,
        CAST(CASE WHEN EXISTS (SELECT 1 FROM dbo.T319CabinetCertifie a
                               WHERE a.Id = c.CabinetCertifieId AND a.IsActive = 1)
                  THEN 1 ELSE 0 END AS bit) AS EstDansAnnuaire
    FROM dbo.T331Cabinet c
    WHERE c.Id = @cabId;
END
GO

-- ---------------------------------------------------------------------------
-- s0936SaveCabinetProfil : enregistre le profil (admin/solo) et publie/retire
-- la fiche publique dans l'annuaire T319CabinetCertifie.
-- ErrorCode : 0=OK, 2=non autorisé.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0936SaveCabinetProfil
    @UserId                 varchar(200),
    @Nom                    nvarchar(150),
    @Responsable            nvarchar(150) = NULL,
    @Description            nvarchar(500) = NULL,
    @Ville                  nvarchar(100) = NULL,
    @Province               nvarchar(50)  = NULL,
    @Courriel               nvarchar(200) = NULL,
    @Telephone              nvarchar(40)  = NULL,
    @SiteWeb                nvarchar(250) = NULL,
    @Langues                nvarchar(50)  = NULL,
    @Specialites            nvarchar(200) = NULL,
    @AccepteNouveauxClients bit = 0,
    @FichePublique          bit = 0,
    @ErrorCode              int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;

    DECLARE @cabId int, @callerRole nvarchar(20), @certId int;
    SELECT TOP 1 @cabId = m.CabinetId, @callerRole = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    JOIN dbo.T331Cabinet cab     ON cab.Id = m.CabinetId AND cab.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    IF @cabId IS NULL OR @callerRole NOT IN ('admin', 'solo') BEGIN SET @ErrorCode = 2; RETURN; END
    IF @Nom IS NULL OR LTRIM(RTRIM(@Nom)) = N'' BEGIN SET @ErrorCode = 7; RETURN; END

    UPDATE dbo.T331Cabinet
    SET Nom = @Nom, Responsable = @Responsable, [Description] = @Description,
        Ville = @Ville, Province = @Province, Courriel = @Courriel,
        Telephone = @Telephone, SiteWeb = @SiteWeb, Langues = @Langues,
        Specialites = @Specialites, AccepteNouveauxClients = @AccepteNouveauxClients,
        FichePublique = @FichePublique
    WHERE Id = @cabId;

    SELECT @certId = CabinetCertifieId FROM dbo.T331Cabinet WHERE Id = @cabId;

    IF @FichePublique = 1
    BEGIN
        -- Publier / mettre à jour la fiche d'annuaire
        IF @certId IS NULL
        BEGIN
            INSERT INTO dbo.T319CabinetCertifie
                (Nom, Responsable, Ville, Province, Courriel, Telephone, SiteWeb, Langues, Specialites, [Description], IsActive)
            VALUES
                (@Nom, @Responsable, @Ville, ISNULL(NULLIF(@Province, N''), N'QC'), @Courriel, @Telephone, @SiteWeb,
                 ISNULL(NULLIF(@Langues, N''), N'FR'), @Specialites, @Description, 1);
            SET @certId = SCOPE_IDENTITY();
            UPDATE dbo.T331Cabinet SET CabinetCertifieId = @certId WHERE Id = @cabId;
        END
        ELSE
        BEGIN
            UPDATE dbo.T319CabinetCertifie
            SET Nom = @Nom, Responsable = @Responsable, Ville = @Ville,
                Province = ISNULL(NULLIF(@Province, N''), N'QC'), Courriel = @Courriel,
                Telephone = @Telephone, SiteWeb = @SiteWeb,
                Langues = ISNULL(NULLIF(@Langues, N''), N'FR'), Specialites = @Specialites,
                [Description] = @Description, IsActive = 1
            WHERE Id = @certId;
        END
    END
    ELSE IF @certId IS NOT NULL
    BEGIN
        -- Retirer de l'annuaire (sans supprimer la ligne)
        UPDATE dbo.T319CabinetCertifie SET IsActive = 0 WHERE Id = @certId;
    END
END
GO

-- ---------------------------------------------------------------------------
-- s0937GetDossierDetail : détail d'un dossier (compagnie) pour la fiche client.
-- Valide que la compagnie est dans le périmètre du cabinet de l'appelant.
-- Renvoie 0 ligne si hors périmètre.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0937GetDossierDetail
    @UserId      varchar(200),
    @CompanyGUID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @uid uniqueidentifier, @cabId int;
    SELECT TOP 1 @uid = u.UserGUID, @cabId = m.CabinetId
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    -- Hors périmètre → rien
    IF @cabId IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.fCabinetDossiers(@uid) WHERE CompanyGUID = @CompanyGUID)
        RETURN;

    SELECT
        @CompanyGUID AS CompanyGUID,
        dbo.fCompanyName(@CompanyGUID) AS Name,
        dbo.fParamS(@CompanyGUID, 'LEGAL_NAME') AS LegalName,
        c.CompanyCode,
        d.AssignedUserGUID,
        LTRIM(RTRIM(ISNULL(mu.FirstName, N'') + N' ' + ISNULL(mu.LastName, N''))) AS MembreNom,
        eq.Nom AS EquipeNom,
        (SELECT COUNT(*) FROM dbo.T101ParamValues v JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE p.CompanyGUID = @CompanyGUID AND p.Categorie = 'QUIFAITQUOI' AND v.sVal = 'moi') AS NbClient,
        (SELECT COUNT(*) FROM dbo.T101ParamValues v JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE p.CompanyGUID = @CompanyGUID AND p.Categorie = 'QUIFAITQUOI' AND v.sVal = 'cabinet') AS NbCabinet,
        (SELECT COUNT(*) FROM dbo.T101ParamValues v JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE p.CompanyGUID = @CompanyGUID AND p.Categorie = 'QUIFAITQUOI' AND v.sVal = 'moi+cabinet') AS NbPartage
    FROM dbo.T010Company c
    LEFT JOIN dbo.T334CabinetDossier d ON d.CabinetId = @cabId AND d.CompanyGUID = @CompanyGUID
    LEFT JOIN dbo.T015User mu          ON mu.UserGUID = d.AssignedUserGUID
    LEFT JOIN dbo.T333Equipe eq        ON eq.Id = d.EquipeId
    WHERE c.CompanyGUID = @CompanyGUID;
END
GO
