/* =====================================================================
   PortailMaster - Script 06 : Clients des abonnes (niveau 3)
   ---------------------------------------------------------------------
   Hierarchie : Plateforme -> Abonne (tenant) -> CLIENTS (payeurs).
   Chaque client appartient a UN abonne (isolation multi-locataire via
   AbonneId). Les clients sont des contreparties externes : ils n'ont PAS
   de solde sur la plateforme (le solde est detenu par l'abonne).

   A executer APRES 01-05. Procs numerotees s0011+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   Table des clients
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.T020Client', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T020Client
    (
        Id                 INT              IDENTITY(1,1) NOT NULL,
        ClientGUID         UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_T020_Guid    DEFAULT (NEWID()),
        AbonneId           INT              NOT NULL,   -- tenant (T010Abonne.Id)
        TypeClient         NVARCHAR(20)     NOT NULL CONSTRAINT DF_T020_Type     DEFAULT (N'Entreprise'), -- Entreprise / Particulier
        Nom                NVARCHAR(200)    NOT NULL,   -- raison sociale ou nom complet
        ReferenceExterne   NVARCHAR(100)    NULL,       -- id du client dans le systeme de l'abonne (mapping API)
        CourrielContact    NVARCHAR(256)    NULL,
        Telephone          NVARCHAR(40)     NULL,
        Adresse1           NVARCHAR(200)    NULL,
        Adresse2           NVARCHAR(200)    NULL,
        Ville              NVARCHAR(120)    NULL,
        Province           NVARCHAR(60)     NULL,
        CodePostal         NVARCHAR(20)     NULL,
        Pays               NVARCHAR(60)     NOT NULL CONSTRAINT DF_T020_Pays     DEFAULT (N'Canada'),
        -- Statut : Actif / Inactif / Bloque
        Statut             NVARCHAR(20)     NOT NULL CONSTRAINT DF_T020_Statut   DEFAULT (N'Actif'),
        Notes              NVARCHAR(MAX)    NULL,
        CreatedUtc         DATETIME2(0)     NOT NULL CONSTRAINT DF_T020_Created  DEFAULT (SYSUTCDATETIME()),
        CreatedByAdminId   INT              NULL,
        ModifiedUtc        DATETIME2(0)     NULL,
        ModifiedByAdminId  INT              NULL,
        CONSTRAINT PK_T020Client PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UX_T020Client_Guid UNIQUE (ClientGUID),
        CONSTRAINT FK_T020_Abonne     FOREIGN KEY (AbonneId)          REFERENCES dbo.T010Abonne(Id),
        CONSTRAINT FK_T020_CreatedBy  FOREIGN KEY (CreatedByAdminId)  REFERENCES dbo.T001PortalAdmin(Id),
        CONSTRAINT FK_T020_ModifiedBy FOREIGN KEY (ModifiedByAdminId) REFERENCES dbo.T001PortalAdmin(Id)
    );

    -- Recherche / tri par abonne
    CREATE INDEX IX_T020Client_AbonneNom ON dbo.T020Client (AbonneId, Nom);
    -- Reference externe unique DANS un abonne (quand fournie)
    CREATE UNIQUE INDEX UX_T020Client_AbonneRef
        ON dbo.T020Client (AbonneId, ReferenceExterne)
        WHERE ReferenceExterne IS NOT NULL;
END
GO

/* ---------------------------------------------------------------------
   s0011ListClients : clients d'un abonne (filtrables).
   @AbonneId OBLIGATOIRE (scoping locataire). @Search / @Statut optionnels.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0011ListClients
    @AbonneId INT,
    @Search   NVARCHAR(200) = NULL,
    @Statut   NVARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  Id, ClientGUID, AbonneId, TypeClient, Nom, ReferenceExterne,
            CourrielContact, Telephone, Ville, Province, Statut, CreatedUtc
    FROM    dbo.T020Client
    WHERE   AbonneId = @AbonneId
      AND   (@Search IS NULL OR @Search = N''
             OR Nom              LIKE N'%' + @Search + N'%'
             OR CourrielContact  LIKE N'%' + @Search + N'%'
             OR ReferenceExterne LIKE N'%' + @Search + N'%')
      AND   (@Statut IS NULL OR @Statut = N'' OR Statut = @Statut)
    ORDER BY Nom;
END
GO

/* ---------------------------------------------------------------------
   s0012GetClient : fiche d'un client (inclut AbonneId pour verifier
   l'appartenance cote application).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0012GetClient
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  Id, ClientGUID, AbonneId, TypeClient, Nom, ReferenceExterne,
            CourrielContact, Telephone, Adresse1, Adresse2, Ville, Province,
            CodePostal, Pays, Statut, Notes,
            CreatedUtc, CreatedByAdminId, ModifiedUtc, ModifiedByAdminId
    FROM    dbo.T020Client
    WHERE   Id = @Id;
END
GO

/* ---------------------------------------------------------------------
   s0013SaveClient : upsert d'un client.
     @Id = 0  -> insertion (dans @AbonneId) ; renvoie le nouvel Id.
     @Id > 0  -> mise a jour (AbonneId non modifiable ici).
   L'unicite (AbonneId, ReferenceExterne) est garantie par index filtre
   (l'app intercepte 2601/2627 pour un message convivial).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0013SaveClient
    @Id                INT OUTPUT,
    @AbonneId          INT,
    @TypeClient        NVARCHAR(20)  = N'Entreprise',
    @Nom               NVARCHAR(200),
    @ReferenceExterne  NVARCHAR(100) = NULL,
    @CourrielContact   NVARCHAR(256) = NULL,
    @Telephone         NVARCHAR(40)  = NULL,
    @Adresse1          NVARCHAR(200) = NULL,
    @Adresse2          NVARCHAR(200) = NULL,
    @Ville             NVARCHAR(120) = NULL,
    @Province          NVARCHAR(60)  = NULL,
    @CodePostal        NVARCHAR(20)  = NULL,
    @Pays              NVARCHAR(60)  = N'Canada',
    @Statut            NVARCHAR(20)  = N'Actif',
    @Notes             NVARCHAR(MAX) = NULL,
    @AdminId           INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id IS NULL OR @Id = 0
    BEGIN
        INSERT INTO dbo.T020Client
            (AbonneId, TypeClient, Nom, ReferenceExterne, CourrielContact, Telephone,
             Adresse1, Adresse2, Ville, Province, CodePostal, Pays, Statut, Notes, CreatedByAdminId)
        VALUES
            (@AbonneId, @TypeClient, @Nom, @ReferenceExterne, @CourrielContact, @Telephone,
             @Adresse1, @Adresse2, @Ville, @Province, @CodePostal, @Pays, @Statut, @Notes, @AdminId);

        SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    END
    ELSE
    BEGIN
        UPDATE dbo.T020Client
        SET TypeClient        = @TypeClient,
            Nom               = @Nom,
            ReferenceExterne  = @ReferenceExterne,
            CourrielContact   = @CourrielContact,
            Telephone         = @Telephone,
            Adresse1          = @Adresse1,
            Adresse2          = @Adresse2,
            Ville             = @Ville,
            Province          = @Province,
            CodePostal        = @CodePostal,
            Pays              = @Pays,
            Statut            = @Statut,
            Notes             = @Notes,
            ModifiedUtc       = SYSUTCDATETIME(),
            ModifiedByAdminId = @AdminId
        WHERE Id = @Id;
    END

    SELECT @Id AS Id;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner ; utile s'il est
   plus tard restreint a EXECUTE-seul). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'06_clients.sql : termine.';
GO
