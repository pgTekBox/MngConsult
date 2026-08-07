/* =====================================================================
   PortailMaster - Script 04 : Abonnes (locataires / tenants)
   ---------------------------------------------------------------------
   Un abonne = une entreprise cliente de la plateforme 60secPaiement.
   Hierarchie : Plateforme -> Abonne (tenant) -> ses clients/fournisseurs.
   L'abonne detient un solde sur la plateforme (gere plus tard par le
   grand livre). Ici : fiche signaletique + statut + suivi KYB.

   A executer APRES 01/02. Procs numerotees s0004+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   Table des abonnes
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.T010Abonne', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T010Abonne
    (
        Id                 INT              IDENTITY(1,1) NOT NULL,
        TenantGUID         UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_T010_Guid    DEFAULT (NEWID()),
        RaisonSociale      NVARCHAR(200)    NOT NULL,
        NomAffichage       NVARCHAR(200)    NULL,
        NumeroEntreprise   NVARCHAR(50)     NULL,   -- NEQ / numero d'entreprise (BN)
        CourrielContact    NVARCHAR(256)    NULL,
        Telephone          NVARCHAR(40)     NULL,
        Adresse1           NVARCHAR(200)    NULL,
        Adresse2           NVARCHAR(200)    NULL,
        Ville              NVARCHAR(120)    NULL,
        Province           NVARCHAR(60)     NULL,
        CodePostal         NVARCHAR(20)     NULL,
        Pays               NVARCHAR(60)     NOT NULL CONSTRAINT DF_T010_Pays     DEFAULT (N'Canada'),
        Devise             CHAR(3)          NOT NULL CONSTRAINT DF_T010_Devise   DEFAULT ('CAD'),
        -- Statut commercial : Prospect / Actif / Suspendu / Ferme
        Statut             NVARCHAR(20)     NOT NULL CONSTRAINT DF_T010_Statut   DEFAULT (N'Prospect'),
        -- Statut conformite (KYB) : NonDebute / EnCours / Verifie / Rejete
        StatutKYB          NVARCHAR(20)     NOT NULL CONSTRAINT DF_T010_KYB      DEFAULT (N'NonDebute'),
        Notes              NVARCHAR(MAX)    NULL,
        CreatedUtc         DATETIME2(0)     NOT NULL CONSTRAINT DF_T010_Created  DEFAULT (SYSUTCDATETIME()),
        CreatedByAdminId   INT              NULL,
        ModifiedUtc        DATETIME2(0)     NULL,
        ModifiedByAdminId  INT              NULL,
        CONSTRAINT PK_T010Abonne PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UX_T010Abonne_Guid UNIQUE (TenantGUID),
        CONSTRAINT FK_T010_CreatedBy  FOREIGN KEY (CreatedByAdminId)  REFERENCES dbo.T001PortalAdmin(Id),
        CONSTRAINT FK_T010_ModifiedBy FOREIGN KEY (ModifiedByAdminId) REFERENCES dbo.T001PortalAdmin(Id)
    );

    CREATE INDEX IX_T010Abonne_Statut        ON dbo.T010Abonne (Statut);
    CREATE INDEX IX_T010Abonne_RaisonSociale ON dbo.T010Abonne (RaisonSociale);
END
GO

/* ---------------------------------------------------------------------
   s0004ListAbonnes : liste filtrable (recherche + statut).
   @Search : filtre sur raison sociale / nom d'affichage / courriel / NEQ.
   @Statut : filtre exact, NULL/'' = tous.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0004ListAbonnes
    @Search NVARCHAR(200) = NULL,
    @Statut NVARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  Id,
            TenantGUID,
            RaisonSociale,
            NomAffichage,
            NumeroEntreprise,
            CourrielContact,
            Telephone,
            Ville,
            Province,
            Devise,
            Statut,
            StatutKYB,
            CreatedUtc
    FROM    dbo.T010Abonne
    WHERE   (@Search IS NULL OR @Search = N''
             OR RaisonSociale    LIKE N'%' + @Search + N'%'
             OR NomAffichage     LIKE N'%' + @Search + N'%'
             OR CourrielContact  LIKE N'%' + @Search + N'%'
             OR NumeroEntreprise LIKE N'%' + @Search + N'%')
      AND   (@Statut IS NULL OR @Statut = N'' OR Statut = @Statut)
    ORDER BY RaisonSociale;
END
GO

/* ---------------------------------------------------------------------
   s0005GetAbonne : fiche complete d'un abonne.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0005GetAbonne
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  Id, TenantGUID, RaisonSociale, NomAffichage, NumeroEntreprise,
            CourrielContact, Telephone, Adresse1, Adresse2, Ville, Province,
            CodePostal, Pays, Devise, Statut, StatutKYB, Notes,
            CreatedUtc, CreatedByAdminId, ModifiedUtc, ModifiedByAdminId
    FROM    dbo.T010Abonne
    WHERE   Id = @Id;
END
GO

/* ---------------------------------------------------------------------
   s0006SaveAbonne : upsert. @Id = 0 -> insertion (retourne le nouvel Id
   dans @Id en OUTPUT) ; @Id > 0 -> mise a jour.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0006SaveAbonne
    @Id                INT OUTPUT,
    @RaisonSociale     NVARCHAR(200),
    @NomAffichage      NVARCHAR(200) = NULL,
    @NumeroEntreprise  NVARCHAR(50)  = NULL,
    @CourrielContact   NVARCHAR(256) = NULL,
    @Telephone         NVARCHAR(40)  = NULL,
    @Adresse1          NVARCHAR(200) = NULL,
    @Adresse2          NVARCHAR(200) = NULL,
    @Ville             NVARCHAR(120) = NULL,
    @Province          NVARCHAR(60)  = NULL,
    @CodePostal        NVARCHAR(20)  = NULL,
    @Pays              NVARCHAR(60)  = N'Canada',
    @Devise            CHAR(3)       = 'CAD',
    @Statut            NVARCHAR(20)  = N'Prospect',
    @StatutKYB         NVARCHAR(20)  = N'NonDebute',
    @Notes             NVARCHAR(MAX) = NULL,
    @AdminId           INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id IS NULL OR @Id = 0
    BEGIN
        INSERT INTO dbo.T010Abonne
            (RaisonSociale, NomAffichage, NumeroEntreprise, CourrielContact, Telephone,
             Adresse1, Adresse2, Ville, Province, CodePostal, Pays, Devise,
             Statut, StatutKYB, Notes, CreatedByAdminId)
        VALUES
            (@RaisonSociale, @NomAffichage, @NumeroEntreprise, @CourrielContact, @Telephone,
             @Adresse1, @Adresse2, @Ville, @Province, @CodePostal, @Pays, @Devise,
             @Statut, @StatutKYB, @Notes, @AdminId);

        SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    END
    ELSE
    BEGIN
        UPDATE dbo.T010Abonne
        SET RaisonSociale     = @RaisonSociale,
            NomAffichage      = @NomAffichage,
            NumeroEntreprise  = @NumeroEntreprise,
            CourrielContact   = @CourrielContact,
            Telephone         = @Telephone,
            Adresse1          = @Adresse1,
            Adresse2          = @Adresse2,
            Ville             = @Ville,
            Province          = @Province,
            CodePostal        = @CodePostal,
            Pays              = @Pays,
            Devise            = @Devise,
            Statut            = @Statut,
            StatutKYB         = @StatutKYB,
            Notes             = @Notes,
            ModifiedUtc       = SYSUTCDATETIME(),
            ModifiedByAdminId = @AdminId
        WHERE Id = @Id;
    END

    SELECT @Id AS Id;
END
GO

/* ---------------------------------------------------------------------
   s0007SetAbonneStatut : changement rapide de statut (activer/suspendre).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0007SetAbonneStatut
    @Id      INT,
    @Statut  NVARCHAR(20),
    @AdminId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T010Abonne
    SET Statut            = @Statut,
        ModifiedUtc       = SYSUTCDATETIME(),
        ModifiedByAdminId = @AdminId
    WHERE Id = @Id;
END
GO

/* Rappel du GRANT pour les nouvelles procs. */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'04_abonnes.sql : termine.';
GO
