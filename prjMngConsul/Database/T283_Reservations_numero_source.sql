-- =============================================================================
-- T283 — Réservations : numéro d'inscription, source et « avant le lancement »
--
-- La page d'accueil (version 128) confirme chaque inscription avec un numéro
-- (60S-2026-XXXXX), distingue la fenêtre « Le grand départ » de la section
-- Inscription (Source), et dit si l'inscription précède le lancement du
-- 1er janvier 2027. s0868 génère le numéro et rend ces trois valeurs ;
-- s0869 les liste.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('dbo.T025LandingReservation', 'Numero') IS NULL
    ALTER TABLE dbo.T025LandingReservation ADD Numero varchar(20) NULL;
IF COL_LENGTH('dbo.T025LandingReservation', 'Source') IS NULL
    ALTER TABLE dbo.T025LandingReservation ADD Source varchar(20) NULL;
IF COL_LENGTH('dbo.T025LandingReservation', 'AvantLancement') IS NULL
    ALTER TABLE dbo.T025LandingReservation ADD AvantLancement bit NOT NULL CONSTRAINT DF_T025_Avant DEFAULT (1);
IF COL_LENGTH('dbo.T025LandingReservation', 'LanguePage') IS NULL
    ALTER TABLE dbo.T025LandingReservation ADD LanguePage varchar(10) NULL;
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
    @Brut          nvarchar(max) = NULL,
    @Source        varchar(20) = NULL,
    @LanguePage    varchar(10) = NULL
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

    -- Numéro lisible, sans lettres ambiguës (I, L, O, 0, 1), unique.
    DECLARE @alphabet varchar(40) = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789', @numero varchar(20), @i int, @essai int = 0;
    WHILE 1 = 1
    BEGIN
        SET @numero = '60S-' + CAST(YEAR(SYSDATETIME()) AS varchar(4)) + '-';
        SET @i = 0;
        WHILE @i < 5
        BEGIN
            SET @numero = @numero + SUBSTRING(@alphabet, 1 + ABS(CHECKSUM(NEWID())) % LEN(@alphabet), 1);
            SET @i = @i + 1;
        END
        IF NOT EXISTS (SELECT 1 FROM dbo.T025LandingReservation WHERE Numero = @numero) BREAK;
        SET @essai = @essai + 1;
        IF @essai > 20 BREAK;
    END
    DECLARE @avant bit = CASE WHEN SYSDATETIME() < '2027-01-01' THEN 1 ELSE 0 END;

    INSERT INTO dbo.T025LandingReservation
        (Profil, ProfilLibelle, Nom, Courriel, Secteur, SousCategorie, ActiviteAutre, Taxes, SocieteNom, FinExercice, NbEmployes,
         FrequencePaie, CabinetNom, NbDossiers, Logiciel, Pilote, Langue, Estimation, Fondateur, Consentement, AvisLancement,
         Destinataire, Page, Ip, UserAgent, Brut, Numero, Source, AvantLancement, LanguePage)
    VALUES
        (@Profil, @ProfilLibelle, @Nom, @Courriel, @Secteur, @SousCategorie, @ActiviteAutre, @Taxes, @SocieteNom, @FinExercice, @NbEmployes,
         @FrequencePaie, @CabinetNom, @NbDossiers, @Logiciel, @Pilote, @Langue, @Estimation, @Fondateur, ISNULL(@Consentement, 0), ISNULL(@AvisLancement, 0),
         @Destinataire, @Page, @Ip, @UserAgent, @Brut, @numero, @Source, @avant, @LanguePage);
    SELECT CAST(SCOPE_IDENTITY() AS int) AS Id, @numero AS Numero, @avant AS AvantLancement;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0869GetLandingReservations
    @Top int = 500
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top) Id, Numero, Created, Profil, ProfilLibelle, Nom, Courriel, Secteur, SousCategorie, ActiviteAutre, Taxes, SocieteNom,
           FinExercice, NbEmployes, FrequencePaie, CabinetNom, NbDossiers, Logiciel, Pilote, Langue, Estimation, Fondateur,
           Consentement, AvisLancement, Destinataire, Source, AvantLancement, LanguePage, Statut, Note, Ip
      FROM dbo.T025LandingReservation
     ORDER BY Created DESC, Id DESC;
END
GO

PRINT N'T283_Reservations_numero_source.sql : terminé.';
