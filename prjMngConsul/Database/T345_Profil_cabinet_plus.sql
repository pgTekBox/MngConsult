-- ===========================================================================
-- T345 — Profil du cabinet enrichi (onglets de la maquette).
--
-- Ajoute à T331Cabinet trois champs sauvegardés par les nouveaux onglets du
-- profil, en plus des champs existants (gérés par s0935/s0936) :
--   * MfaObligatoire  — onglet « Sécurité » (double vérification).
--   * CertifEtapes     — onglet « Certification » (indices des étapes faites, CSV).
--   * OffreActivites   — onglet « Offre de services » (état JSON : offert /
--                        responsabilité / attribution par activité).
--
-- Procs s0958GetCabinetProfilPlus (lecture) / s0959SaveCabinetProfilPlus
-- (écriture, réservée admin/solo). Idempotent.
-- ===========================================================================
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.T331Cabinet', 'MfaObligatoire') IS NULL
    ALTER TABLE dbo.T331Cabinet ADD MfaObligatoire BIT NOT NULL CONSTRAINT DF_T331_Mfa DEFAULT 0;
GO
IF COL_LENGTH('dbo.T331Cabinet', 'CertifEtapes') IS NULL
    ALTER TABLE dbo.T331Cabinet ADD CertifEtapes NVARCHAR(100) NULL;
GO
IF COL_LENGTH('dbo.T331Cabinet', 'OffreActivites') IS NULL
    ALTER TABLE dbo.T331Cabinet ADD OffreActivites NVARCHAR(MAX) NULL;
GO

-- Démo : les 2 premières étapes de certification déjà faites (comme la maquette).
UPDATE dbo.T331Cabinet SET CertifEtapes = '0,1' WHERE Id = 1 AND CertifEtapes IS NULL;
GO

CREATE OR ALTER PROCEDURE dbo.s0958GetCabinetProfilPlus
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
    IF @cabId IS NULL RETURN;

    SELECT CAST(ISNULL(MfaObligatoire, 0) AS int) AS MfaObligatoire,
           ISNULL(CertifEtapes, '')               AS CertifEtapes,
           ISNULL(OffreActivites, '')             AS OffreActivites
    FROM dbo.T331Cabinet WHERE Id = @cabId;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0959SaveCabinetProfilPlus
    @UserId         varchar(200),
    @Mfa            bit,
    @CertifEtapes   nvarchar(100),
    @OffreActivites nvarchar(max),
    @ErrorCode      int OUTPUT
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

    UPDATE dbo.T331Cabinet
    SET MfaObligatoire = @Mfa,
        CertifEtapes   = @CertifEtapes,
        OffreActivites = @OffreActivites
    WHERE Id = @cabId;
END
GO
