-- =============================================================================
-- T340_Portail_prep.sql — Portail comptable Phase 4, Part F
-- Préparer la rencontre : notes par dossier (le miroir « ce que voit le client »
-- est dérivé des paramètres QFQ, sans stockage neuf).
-- Procs libres : s0949+. Table : T343DossierPrep.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.T343DossierPrep', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T343DossierPrep (
        CompanyGUID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        CabinetId   INT              NOT NULL,
        Notes       NVARCHAR(MAX)    NULL,
        MajUtc      DATETIME2(0)     NOT NULL CONSTRAINT DF_T343_Maj DEFAULT SYSUTCDATETIME(),
        MajPar      UNIQUEIDENTIFIER NULL
    );
END
GO

-- ---------------------------------------------------------------------------
-- s0949GetPrep : les notes de préparation d'un dossier (si dans le périmètre).
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0949GetPrep
    @UserId      varchar(200),
    @CompanyGUID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @uid uniqueidentifier;
    SELECT TOP 1 @uid = u.UserGUID FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0 ORDER BY m.Id;
    IF @uid IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.fCabinetDossiers(@uid) WHERE CompanyGUID = @CompanyGUID) RETURN;

    SELECT Notes, MajUtc FROM dbo.T343DossierPrep WHERE CompanyGUID = @CompanyGUID;
END
GO

-- ---------------------------------------------------------------------------
-- s0950SavePrep : enregistre les notes de préparation (membre du périmètre).
-- ErrorCode : 0=OK, 6=hors périmètre.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0950SavePrep
    @UserId      varchar(200),
    @CompanyGUID uniqueidentifier,
    @Notes       nvarchar(max),
    @ErrorCode   int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;

    DECLARE @uid uniqueidentifier, @cabId int;
    SELECT TOP 1 @uid = u.UserGUID, @cabId = m.CabinetId FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0 ORDER BY m.Id;
    IF @uid IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.fCabinetDossiers(@uid) WHERE CompanyGUID = @CompanyGUID)
    BEGIN SET @ErrorCode = 6; RETURN; END

    IF EXISTS (SELECT 1 FROM dbo.T343DossierPrep WHERE CompanyGUID = @CompanyGUID)
        UPDATE dbo.T343DossierPrep SET Notes = @Notes, MajUtc = SYSUTCDATETIME(), MajPar = @uid WHERE CompanyGUID = @CompanyGUID;
    ELSE
        INSERT INTO dbo.T343DossierPrep (CompanyGUID, CabinetId, Notes, MajPar) VALUES (@CompanyGUID, @cabId, @Notes, @uid);
END
GO
