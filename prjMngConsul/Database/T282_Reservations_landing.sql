-- =============================================================================
-- T282 — Réservations d'accès anticipé faites sur la page d'accueil (60secondes)
--
-- La nouvelle page d'accueil (LandingPage.aspx, septembre 2026) propose
-- « Réserver ma place » : un formulaire par profil (travailleur autonome,
-- société sans employé, société avec employés, cabinet comptable). Chaque
-- demande est enregistrée ici par LandingReservation.ashx, puis consultée
-- dans Sec60Admin › Réservations. Les champs bruts sont aussi gardés en JSON.
--   s0868InsertLandingReservation : une demande.
--   s0869GetLandingReservations   : la liste (les plus récentes d'abord).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'dbo.T025LandingReservation') IS NULL
BEGIN
    CREATE TABLE dbo.T025LandingReservation (
        Id             int IDENTITY(1,1) NOT NULL CONSTRAINT PK_T025LandingReservation PRIMARY KEY,
        Created        datetime2(0) NOT NULL CONSTRAINT DF_T025_Created DEFAULT (sysdatetime()),
        Profil         varchar(10) NOT NULL,          -- ta | c0 | c4 | cab
        ProfilLibelle  nvarchar(60) NULL,
        Nom            nvarchar(200) NULL,
        Courriel       nvarchar(320) NOT NULL,
        Secteur        nvarchar(200) NULL,
        SousCategorie  nvarchar(200) NULL,
        ActiviteAutre  nvarchar(200) NULL,
        Taxes          nvarchar(60) NULL,
        SocieteNom     nvarchar(200) NULL,
        FinExercice    nvarchar(60) NULL,
        NbEmployes     int NULL,
        FrequencePaie  nvarchar(60) NULL,
        CabinetNom     nvarchar(200) NULL,
        NbDossiers     nvarchar(60) NULL,
        Logiciel       nvarchar(60) NULL,
        Pilote         bit NULL,
        Langue         nvarchar(60) NULL,
        Estimation     nvarchar(60) NULL,
        Fondateur      bit NULL,
        Consentement   bit NOT NULL CONSTRAINT DF_T025_Consent DEFAULT (0),
        AvisLancement  bit NOT NULL CONSTRAINT DF_T025_Avis DEFAULT (0),
        Destinataire   nvarchar(320) NULL,           -- boîte 60secondes visée (info@ / certifies@)
        Page           nvarchar(500) NULL,
        Ip             varchar(64) NULL,
        UserAgent      nvarchar(400) NULL,
        Brut           nvarchar(max) NULL,           -- le JSON reçu, tel quel
        Statut         varchar(20) NOT NULL CONSTRAINT DF_T025_Statut DEFAULT ('NOUVELLE'),
        Note           nvarchar(1000) NULL
    );
    CREATE INDEX IX_T025_Created ON dbo.T025LandingReservation (Created DESC);
    CREATE INDEX IX_T025_Courriel ON dbo.T025LandingReservation (Courriel);
END
GO

CREATE OR ALTER PROCEDURE dbo.s0868InsertLandingReservation
    @Profil        varchar(10),
    @ProfilLibelle nvarchar(60) = NULL,
    @Nom           nvarchar(200) = NULL,
    @Courriel      nvarchar(320),
    @Secteur       nvarchar(200) = NULL,
    @SousCategorie nvarchar(200) = NULL,
    @ActiviteAutre nvarchar(200) = NULL,
    @Taxes         nvarchar(60) = NULL,
    @SocieteNom    nvarchar(200) = NULL,
    @FinExercice   nvarchar(60) = NULL,
    @NbEmployes    int = NULL,
    @FrequencePaie nvarchar(60) = NULL,
    @CabinetNom    nvarchar(200) = NULL,
    @NbDossiers    nvarchar(60) = NULL,
    @Logiciel      nvarchar(60) = NULL,
    @Pilote        bit = NULL,
    @Langue        nvarchar(60) = NULL,
    @Estimation    nvarchar(60) = NULL,
    @Fondateur     bit = NULL,
    @Consentement  bit = 0,
    @AvisLancement bit = 0,
    @Destinataire  nvarchar(320) = NULL,
    @Page          nvarchar(500) = NULL,
    @Ip            varchar(64) = NULL,
    @UserAgent     nvarchar(400) = NULL,
    @Brut          nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Courriel IS NULL OR @Courriel NOT LIKE '%_@_%.__%'
    BEGIN
        RAISERROR('Courriel invalide.', 16, 1);
        RETURN;
    END
    IF ISNULL(@Consentement, 0) = 0
    BEGIN
        RAISERROR('Consentement requis.', 16, 1);
        RETURN;
    END
    -- Anti-rafale : la même adresse ne dépose pas plus de 5 demandes en 10 minutes.
    IF (SELECT COUNT(*) FROM dbo.T025LandingReservation WHERE Courriel = @Courriel AND Created > DATEADD(minute, -10, SYSDATETIME())) >= 5
    BEGIN
        RAISERROR('Trop de demandes pour ce courriel : réessayez dans quelques minutes.', 16, 1);
        RETURN;
    END
    INSERT INTO dbo.T025LandingReservation
        (Profil, ProfilLibelle, Nom, Courriel, Secteur, SousCategorie, ActiviteAutre, Taxes, SocieteNom, FinExercice, NbEmployes,
         FrequencePaie, CabinetNom, NbDossiers, Logiciel, Pilote, Langue, Estimation, Fondateur, Consentement, AvisLancement,
         Destinataire, Page, Ip, UserAgent, Brut)
    VALUES
        (@Profil, @ProfilLibelle, @Nom, @Courriel, @Secteur, @SousCategorie, @ActiviteAutre, @Taxes, @SocieteNom, @FinExercice, @NbEmployes,
         @FrequencePaie, @CabinetNom, @NbDossiers, @Logiciel, @Pilote, @Langue, @Estimation, @Fondateur, ISNULL(@Consentement, 0), ISNULL(@AvisLancement, 0),
         @Destinataire, @Page, @Ip, @UserAgent, @Brut);
    SELECT CAST(SCOPE_IDENTITY() AS int) AS Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0869GetLandingReservations
    @Top int = 500
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top) Id, Created, Profil, ProfilLibelle, Nom, Courriel, Secteur, SousCategorie, ActiviteAutre, Taxes, SocieteNom,
           FinExercice, NbEmployes, FrequencePaie, CabinetNom, NbDossiers, Logiciel, Pilote, Langue, Estimation, Fondateur,
           Consentement, AvisLancement, Destinataire, Statut, Note, Ip
      FROM dbo.T025LandingReservation
     ORDER BY Created DESC, Id DESC;
END
GO

PRINT N'T282_Reservations_landing.sql : terminé.';
