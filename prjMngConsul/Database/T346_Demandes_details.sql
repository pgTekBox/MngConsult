-- ===========================================================================
-- T346 — « Clients non associés » (ex « Demandes de clients ») calqué sur la
-- maquette : enrichit la demande entrante des attributs affichés par la fiche.
--
--  1) Colonnes d'affichage sur T337DemandeCabinet (toutes NULL — en vrai
--     remplies à l'inscription du client ; ici seedées en démonstration) :
--     NomEntreprise, Metier, Profil, Ville, ServicesCsv (séparateur |),
--     ContactNom/Mail/Tel, Taille, Logiciel, FinExercice.
--  2) s0939ListDemandesCabinet étendue : renvoie ces colonnes + Jours d'attente.
--  3) s0960RestoreDemandeCabinet : remet une demande traitée « EnAttente »
--     (bouton « Annuler » de la maquette).
--  4) Seed de 3 demandes en attente pour le cabinet de démo (CabinetCertifieId 7).
--
-- Idempotent (le seed est marqué Canal='Seed').
-- ===========================================================================
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.T337DemandeCabinet', 'NomEntreprise') IS NULL ALTER TABLE dbo.T337DemandeCabinet ADD NomEntreprise NVARCHAR(200) NULL;
GO
IF COL_LENGTH('dbo.T337DemandeCabinet', 'Metier') IS NULL ALTER TABLE dbo.T337DemandeCabinet ADD Metier NVARCHAR(80) NULL;
GO
IF COL_LENGTH('dbo.T337DemandeCabinet', 'Profil') IS NULL ALTER TABLE dbo.T337DemandeCabinet ADD Profil NVARCHAR(60) NULL;
GO
IF COL_LENGTH('dbo.T337DemandeCabinet', 'Ville') IS NULL ALTER TABLE dbo.T337DemandeCabinet ADD Ville NVARCHAR(80) NULL;
GO
IF COL_LENGTH('dbo.T337DemandeCabinet', 'ServicesCsv') IS NULL ALTER TABLE dbo.T337DemandeCabinet ADD ServicesCsv NVARCHAR(400) NULL;
GO
IF COL_LENGTH('dbo.T337DemandeCabinet', 'ContactNom') IS NULL ALTER TABLE dbo.T337DemandeCabinet ADD ContactNom NVARCHAR(120) NULL;
GO
IF COL_LENGTH('dbo.T337DemandeCabinet', 'ContactMail') IS NULL ALTER TABLE dbo.T337DemandeCabinet ADD ContactMail NVARCHAR(200) NULL;
GO
IF COL_LENGTH('dbo.T337DemandeCabinet', 'ContactTel') IS NULL ALTER TABLE dbo.T337DemandeCabinet ADD ContactTel NVARCHAR(40) NULL;
GO
IF COL_LENGTH('dbo.T337DemandeCabinet', 'Taille') IS NULL ALTER TABLE dbo.T337DemandeCabinet ADD Taille NVARCHAR(60) NULL;
GO
IF COL_LENGTH('dbo.T337DemandeCabinet', 'Logiciel') IS NULL ALTER TABLE dbo.T337DemandeCabinet ADD Logiciel NVARCHAR(80) NULL;
GO
IF COL_LENGTH('dbo.T337DemandeCabinet', 'FinExercice') IS NULL ALTER TABLE dbo.T337DemandeCabinet ADD FinExercice NVARCHAR(40) NULL;
GO

CREATE OR ALTER PROCEDURE dbo.s0939ListDemandesCabinet
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @certId INT;
    SELECT TOP 1 @certId = cab.CabinetCertifieId
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    JOIN dbo.T331Cabinet cab     ON cab.Id = m.CabinetId AND cab.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;
    IF @certId IS NULL RETURN;

    SELECT d.Id,
           CONVERT(varchar(40), d.CompanyGUID) AS CompanyGUID,
           COALESCE(NULLIF(dbo.fCompanyName(d.CompanyGUID), N''), d.NomEntreprise, N'Entreprise') AS Name,
           d.Message, d.RecueLe,
           DATEDIFF(DAY, d.RecueLe, SYSUTCDATETIME()) AS Jours,
           d.Metier, d.Profil, d.Ville, d.ServicesCsv,
           d.ContactNom, d.ContactMail, d.ContactTel,
           d.Taille, d.Logiciel, d.FinExercice
    FROM dbo.T337DemandeCabinet d
    WHERE d.CabinetCertifieId = @certId AND d.Statut = 'EnAttente'
    ORDER BY d.RecueLe;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0960RestoreDemandeCabinet
    @UserId    varchar(200),
    @Id        INT,
    @ErrorCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;
    DECLARE @certId INT, @role NVARCHAR(20);
    SELECT TOP 1 @certId = cab.CabinetCertifieId, @role = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    JOIN dbo.T331Cabinet cab     ON cab.Id = m.CabinetId AND cab.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;
    IF @certId IS NULL OR @role NOT IN ('admin','solo') BEGIN SET @ErrorCode = 2; RETURN; END

    UPDATE dbo.T337DemandeCabinet
    SET Statut = 'EnAttente', TraiteeLe = NULL, TraiteePar = NULL
    WHERE Id = @Id AND CabinetCertifieId = @certId AND Statut IN ('Acceptee','Refusee');
END
GO

-- ---- Seed de 3 demandes en attente (cabinet de démo, CabinetCertifieId 7) ----
DECLARE @cert INT = 7;
DELETE FROM dbo.T337DemandeCabinet WHERE CabinetCertifieId = @cert AND Canal = 'Seed';

INSERT INTO dbo.T337DemandeCabinet
    (CompanyGUID, CabinetCertifieId, Message, Canal, Statut, RecueLe,
     NomEntreprise, Metier, Profil, Ville, ServicesCsv, ContactNom, ContactMail, ContactTel, Taille, Logiciel, FinExercice)
VALUES
    ('A1A1A1A1-0000-4000-8000-000000000001', @cert, N'Nous embauchons en janvier : il faut mettre la paie en place.', 'Seed', 'EnAttente', DATEADD(DAY, -2, SYSUTCDATETIME()),
     N'Émilie Brault', N'coiffeuse', N'compagnie avec employés', N'Cowansville',
     N'la tenue de livres|les remises gouvernementales|l''impôt du propriétaire',
     N'Sophie Thibault', N'sophie@emiliebraultcoiffeuse.ca', N'450 202-2650', N'3 employés', N'QuickBooks Online', N'31 décembre'),
    ('A2A2A2A2-0000-4000-8000-000000000002', @cert, NULL, 'Seed', 'EnAttente', DATEADD(DAY, -4, SYSUTCDATETIME()),
     N'Simon Paquette', N'peintre', N'travailleur autonome', N'Sutton',
     N'la tenue de livres|les remises gouvernementales|l''impôt du propriétaire',
     N'Sophie Gauthier', N'sophie@simonpaquettepeintre.ca', N'450 406-5940', N'Seul', N'Aucun (papier)', N'31 mars'),
    ('A3A3A3A3-0000-4000-8000-000000000003', @cert, N'Nous embauchons en janvier : il faut mettre la paie en place.', 'Seed', 'EnAttente', DATEADD(DAY, -6, SYSUTCDATETIME()),
     N'Nathalie Bisson', N'nutritionniste', N'compagnie avec employés', N'Lac-Brome',
     N'la paie et les remises|la tenue de livres|du conseil fiscal',
     N'Mathieu Gauthier', N'mathieu@nathaliebissonnutritionniste.ca', N'450 377-9514', N'2 employés', N'Sage 50', N'31 mars');
GO
