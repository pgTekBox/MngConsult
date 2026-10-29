-- ===========================================================================
-- T344 — Écran « Tous les dossiers » (calqué sur « Tous les clients » de la
-- maquette) : données manquantes + proc de liste.
--
--  1) Ajoute à T334CabinetDossier le Secteur (groupe du client) et un bit
--     EstNouveau, utilisés par les cartes et le filtre « Secteur ».
--  2) Garantit une ligne T334 pour chaque dossier du cabinet de démo (dont
--     INFORMATIQUE MG, rattaché par ComptableGUID mais pas encore confié).
--  3) Renseigne les secteurs des 5 dossiers de démo.
--  4) Proc s0957GetJourneeClients : tous les dossiers du périmètre (scopés par
--     rôle via fCabinetDossiers) avec secteur, « nouveau » et employé assigné.
--     L'agrégation des tâches (priorité, nombre à faire, prochaine action) se
--     fait côté application à partir de s0956.
--
-- Idempotent / rejouable.
-- ===========================================================================
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.T334CabinetDossier', 'Secteur') IS NULL
    ALTER TABLE dbo.T334CabinetDossier ADD Secteur NVARCHAR(60) NULL;
GO
IF COL_LENGTH('dbo.T334CabinetDossier', 'EstNouveau') IS NULL
    ALTER TABLE dbo.T334CabinetDossier ADD EstNouveau BIT NOT NULL CONSTRAINT DF_T334_EstNouveau DEFAULT 0;
GO

-- Ligne T334 manquante pour INFORMATIQUE MG (confié à Marie Tremblay) + secteurs
DECLARE @cab int = 1;
DECLARE @marie uniqueidentifier = (SELECT UserGUID FROM dbo.T015User WHERE Email = 'marie.tremblay@60sec.ca' AND IsDeleted = 0);
DECLARE @info uniqueidentifier = 'D89EB638-6B05-443D-B1C9-01A6316443BF';

IF NOT EXISTS (SELECT 1 FROM dbo.T334CabinetDossier WHERE CabinetId = @cab AND CompanyGUID = @info)
    INSERT INTO dbo.T334CabinetDossier (CabinetId, CompanyGUID, AssignedUserGUID)
    VALUES (@cab, @info, @marie);

UPDATE dbo.T334CabinetDossier SET Secteur = N'Commerce de détail'      WHERE CabinetId = @cab AND CompanyGUID = 'D2D2D2D2-0000-4000-8000-000000000002';
UPDATE dbo.T334CabinetDossier SET Secteur = N'Santé'                   WHERE CabinetId = @cab AND CompanyGUID = 'D4D4D4D4-0000-4000-8000-000000000004';
UPDATE dbo.T334CabinetDossier SET Secteur = N'Technologie', EstNouveau = 1 WHERE CabinetId = @cab AND CompanyGUID = @info;
UPDATE dbo.T334CabinetDossier SET Secteur = N'Construction'            WHERE CabinetId = @cab AND CompanyGUID = 'D5D5D5D5-0000-4000-8000-000000000005';
UPDATE dbo.T334CabinetDossier SET Secteur = N'Services professionnels' WHERE CabinetId = @cab AND CompanyGUID = 'D3D3D3D3-0000-4000-8000-000000000003';
GO

CREATE OR ALTER PROCEDURE dbo.s0957GetJourneeClients
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @uid uniqueidentifier, @cabId int;
    SELECT TOP 1 @uid = u.UserGUID, @cabId = m.CabinetId
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;
    IF @uid IS NULL RETURN;

    SELECT
        CONVERT(varchar(40), f.CompanyGUID) AS CompanyGUID,
        dbo.fCompanyName(f.CompanyGUID)     AS Nom,
        c.CompanyCode,
        d.Secteur,
        CAST(ISNULL(d.EstNouveau, 0) AS int) AS EstNouveau,
        CONVERT(varchar(40), d.AssignedUserGUID) AS AssignedUserGUID,
        LTRIM(RTRIM(ISNULL(au.FirstName, N'') + N' ' + ISNULL(au.LastName, N''))) AS AssignedNom
    FROM dbo.fCabinetDossiers(@uid) f
    LEFT JOIN dbo.T010Company c         ON c.CompanyGUID = f.CompanyGUID
    LEFT JOIN dbo.T334CabinetDossier d  ON d.CabinetId = @cabId AND d.CompanyGUID = f.CompanyGUID
    LEFT JOIN dbo.T015User au           ON au.UserGUID = d.AssignedUserGUID
    ORDER BY Nom;
END
GO
