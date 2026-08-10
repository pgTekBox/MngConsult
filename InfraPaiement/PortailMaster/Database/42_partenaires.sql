/* =====================================================================
   PortailMaster / PortailPartenaire / webAPI - Script 42 : Partenaires
   (canal de distribution / revente - Modele B)
   ---------------------------------------------------------------------
   Un PARTENAIRE est un distributeur (ex. Dentitek - cliniques dentaires)
   qui embarque le
   service EFT de 60secPaiement et le revend a SES propres abonnes. Chaque
   abonne provisionne par un partenaire devient un locataire (T010Abonne) a
   part entiere, isole, avec son propre grand livre et son KYB.

   Hierarchie Modele B :
     Plateforme -> Partenaire -> Abonnes (tenants) -> clients/fournisseurs

   Le portail PortailPartenaire est le libre-service du partenaire (login
   T046PartenaireUser, BCrypt). Il provisionne/liste ses abonnes, lance leur
   KYB et gere ses cles d'API. Cote API : une cle "pk_..." (T040 avec
   PartenaireId) + en-tete X-Abonne-Id permet d'agir au nom d'un tenant.

   A executer APRES 01-41. Table T045/T046 ; procs s0104+.
   ===================================================================== */

USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   T045Partenaire : canal de distribution / revendeur.
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.T045Partenaire', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T045Partenaire
    (
        Id                 INT              IDENTITY(1,1) NOT NULL,
        PartnerGUID        UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_T045_Guid   DEFAULT (NEWID()),
        RaisonSociale      NVARCHAR(200)    NOT NULL,
        NomAffichage       NVARCHAR(200)    NULL,
        CourrielContact    NVARCHAR(256)    NULL,
        Telephone          NVARCHAR(40)     NULL,
        -- Statut : Actif / Suspendu / Ferme
        Statut             NVARCHAR(20)     NOT NULL CONSTRAINT DF_T045_Statut DEFAULT (N'Actif'),
        Notes              NVARCHAR(MAX)    NULL,
        CreatedUtc         DATETIME2(0)     NOT NULL CONSTRAINT DF_T045_Created DEFAULT (SYSUTCDATETIME()),
        CreatedByAdminId   INT              NULL,
        ModifiedUtc        DATETIME2(0)     NULL,
        ModifiedByAdminId  INT              NULL,
        CONSTRAINT PK_T045Partenaire PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UX_T045_Guid UNIQUE (PartnerGUID),
        CONSTRAINT FK_T045_CreatedBy  FOREIGN KEY (CreatedByAdminId)  REFERENCES dbo.T001PortalAdmin(Id),
        CONSTRAINT FK_T045_ModifiedBy FOREIGN KEY (ModifiedByAdminId) REFERENCES dbo.T001PortalAdmin(Id)
    );
    CREATE INDEX IX_T045_Statut ON dbo.T045Partenaire (Statut);
END
GO

/* ---------------------------------------------------------------------
   T046PartenaireUser : utilisateurs du portail partenaire (login BCrypt).
   Memes regles de verrouillage que T011AbonneUser.
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.T046PartenaireUser', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T046PartenaireUser
    (
        Id                 INT              IDENTITY(1,1) NOT NULL,
        PartenaireId       INT              NOT NULL,
        Email              NVARCHAR(256)    NOT NULL,
        PasswordHash       NVARCHAR(100)    NOT NULL,   -- BCrypt
        FirstName          NVARCHAR(100)    NULL,
        LastName           NVARCHAR(100)    NULL,
        IsAdmin            BIT              NOT NULL CONSTRAINT DF_T046_Admin   DEFAULT (1),
        IsActive           BIT              NOT NULL CONSTRAINT DF_T046_Active  DEFAULT (1),
        FailedAttempts     INT              NOT NULL CONSTRAINT DF_T046_Failed  DEFAULT (0),
        LockoutUntilUtc    DATETIME2(0)     NULL,
        LastLoginUtc       DATETIME2(0)     NULL,
        CreatedUtc         DATETIME2(0)     NOT NULL CONSTRAINT DF_T046_Created DEFAULT (SYSUTCDATETIME()),
        ModifiedUtc        DATETIME2(0)     NULL,
        CONSTRAINT PK_T046PartenaireUser PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UX_T046_Email UNIQUE (Email),
        CONSTRAINT FK_T046_Partenaire FOREIGN KEY (PartenaireId) REFERENCES dbo.T045Partenaire(Id)
    );
    CREATE INDEX IX_T046_Partenaire ON dbo.T046PartenaireUser (PartenaireId);
END
GO

/* ---------------------------------------------------------------------
   T010Abonne : rattachement au partenaire (NULL = abonne direct staff).
   --------------------------------------------------------------------- */
IF COL_LENGTH(N'dbo.T010Abonne', N'PartenaireId') IS NULL
BEGIN
    ALTER TABLE dbo.T010Abonne ADD PartenaireId INT NULL
        CONSTRAINT FK_T010_Partenaire FOREIGN KEY (PartenaireId) REFERENCES dbo.T045Partenaire(Id);
END
GO
-- Index NON filtre volontairement : un index filtre (WHERE PartenaireId IS
-- NOT NULL) declenche l'erreur 8624 du moteur SQL lors de la verification de
-- cle etrangere quand on supprime un partenaire (T045). Le non-filtre l'evite.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_T010_Partenaire' AND object_id = OBJECT_ID(N'dbo.T010Abonne'))
    CREATE INDEX IX_T010_Partenaire ON dbo.T010Abonne (PartenaireId);
GO

/* ---------------------------------------------------------------------
   T040ApiKey : une cle appartient SOIT a un abonne (AbonneId) SOIT a un
   partenaire (PartenaireId). AbonneId devient nullable ; contrainte
   d'exclusivite CK_T040_Owner.
   --------------------------------------------------------------------- */
IF COL_LENGTH(N'dbo.T040ApiKey', N'PartenaireId') IS NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_T040_Abonne' AND object_id = OBJECT_ID(N'dbo.T040ApiKey'))
        DROP INDEX IX_T040_Abonne ON dbo.T040ApiKey;

    ALTER TABLE dbo.T040ApiKey ALTER COLUMN AbonneId INT NULL;

    ALTER TABLE dbo.T040ApiKey ADD PartenaireId INT NULL
        CONSTRAINT FK_T040_Partenaire FOREIGN KEY (PartenaireId) REFERENCES dbo.T045Partenaire(Id);

    EXEC(N'CREATE INDEX IX_T040_Abonne ON dbo.T040ApiKey (AbonneId, Id)');
    EXEC(N'CREATE INDEX IX_T040_PartenaireKey ON dbo.T040ApiKey (PartenaireId, Id)');

    -- EXEC (resolution differee) : la colonne PartenaireId vient d'etre
    -- ajoutee dans ce meme lot ; un CHECK direct echouerait a la compilation.
    EXEC(N'ALTER TABLE dbo.T040ApiKey ADD CONSTRAINT CK_T040_Owner CHECK (
        (AbonneId IS NOT NULL AND PartenaireId IS NULL) OR
        (AbonneId IS NULL AND PartenaireId IS NOT NULL))');
END
GO

/* =====================================================================
   Authentification des utilisateurs partenaire (mirroir s0067-s0070).
   ===================================================================== */

CREATE OR ALTER PROCEDURE dbo.s0104GetPartnerUserByEmail
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  u.Id, u.PartenaireId, u.Email, u.PasswordHash, u.FirstName, u.LastName,
            u.IsAdmin, u.IsActive, u.LockoutUntilUtc,
            p.RaisonSociale, p.NomAffichage, p.Statut AS PartenaireStatut
    FROM    dbo.T046PartenaireUser u
    JOIN    dbo.T045Partenaire p ON p.Id = u.PartenaireId
    WHERE   u.Email = @Email;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0105UpdatePartnerUserLastLogin
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T046PartenaireUser
    SET LastLoginUtc = SYSUTCDATETIME(), FailedAttempts = 0, LockoutUntilUtc = NULL
    WHERE Id = @Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0106RegisterPartnerUserFailedLogin
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T046PartenaireUser
    SET FailedAttempts  = FailedAttempts + 1,
        LockoutUntilUtc = CASE WHEN FailedAttempts + 1 >= 5
                               THEN DATEADD(MINUTE, 15, SYSUTCDATETIME())
                               ELSE LockoutUntilUtc END
    WHERE Id = @Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0107SavePartnerUser
    @Id           INT OUTPUT,
    @PartenaireId INT,
    @Email        NVARCHAR(256),
    @PasswordHash NVARCHAR(100) = NULL,
    @FirstName    NVARCHAR(100) = NULL,
    @LastName     NVARCHAR(100) = NULL,
    @IsAdmin      BIT           = 1,
    @IsActive     BIT           = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF @Id IS NULL OR @Id = 0
    BEGIN
        INSERT INTO dbo.T046PartenaireUser (PartenaireId, Email, PasswordHash, FirstName, LastName, IsAdmin, IsActive)
        VALUES (@PartenaireId, @Email, @PasswordHash, @FirstName, @LastName, @IsAdmin, @IsActive);
        SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    END
    ELSE
    BEGIN
        UPDATE dbo.T046PartenaireUser
        SET PartenaireId = @PartenaireId, Email = @Email,
            PasswordHash = COALESCE(@PasswordHash, PasswordHash),
            FirstName = @FirstName, LastName = @LastName,
            IsAdmin = @IsAdmin, IsActive = @IsActive, ModifiedUtc = SYSUTCDATETIME()
        WHERE Id = @Id;
    END
    SELECT @Id AS Id;
END
GO

/* =====================================================================
   CRUD partenaire (cote staff PortailMaster).
   ===================================================================== */

CREATE OR ALTER PROCEDURE dbo.s0108ListPartenaires
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.Id, p.PartnerGUID, p.RaisonSociale, p.NomAffichage, p.CourrielContact,
           p.Statut, p.CreatedUtc,
           (SELECT COUNT(*) FROM dbo.T010Abonne a WHERE a.PartenaireId = p.Id) AS NbAbonnes
    FROM   dbo.T045Partenaire p
    WHERE  (@Search IS NULL OR @Search = N''
            OR p.RaisonSociale   LIKE N'%' + @Search + N'%'
            OR p.NomAffichage    LIKE N'%' + @Search + N'%'
            OR p.CourrielContact LIKE N'%' + @Search + N'%')
    ORDER BY p.RaisonSociale;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0109GetPartenaire
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.Id, p.PartnerGUID, p.RaisonSociale, p.NomAffichage, p.CourrielContact, p.Telephone,
           p.Statut, p.Notes, p.CreatedUtc, p.CreatedByAdminId, p.ModifiedUtc, p.ModifiedByAdminId,
           (SELECT COUNT(*) FROM dbo.T010Abonne a WHERE a.PartenaireId = p.Id) AS NbAbonnes
    FROM   dbo.T045Partenaire p
    WHERE  p.Id = @Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0110SavePartenaire
    @Id              INT OUTPUT,
    @RaisonSociale   NVARCHAR(200),
    @NomAffichage    NVARCHAR(200) = NULL,
    @CourrielContact NVARCHAR(256) = NULL,
    @Telephone       NVARCHAR(40)  = NULL,
    @Statut          NVARCHAR(20)  = N'Actif',
    @Notes           NVARCHAR(MAX) = NULL,
    @AdminId         INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Id IS NULL OR @Id = 0
    BEGIN
        INSERT INTO dbo.T045Partenaire (RaisonSociale, NomAffichage, CourrielContact, Telephone, Statut, Notes, CreatedByAdminId)
        VALUES (@RaisonSociale, @NomAffichage, @CourrielContact, @Telephone, @Statut, @Notes, @AdminId);
        SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    END
    ELSE
    BEGIN
        UPDATE dbo.T045Partenaire
        SET RaisonSociale = @RaisonSociale, NomAffichage = @NomAffichage,
            CourrielContact = @CourrielContact, Telephone = @Telephone,
            Statut = @Statut, Notes = @Notes,
            ModifiedUtc = SYSUTCDATETIME(), ModifiedByAdminId = @AdminId
        WHERE Id = @Id;
    END
    SELECT @Id AS Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0111SetPartenaireStatut
    @Id INT, @Statut NVARCHAR(20), @AdminId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T045Partenaire
    SET Statut = @Statut, ModifiedUtc = SYSUTCDATETIME(), ModifiedByAdminId = @AdminId
    WHERE Id = @Id;
END
GO

/* =====================================================================
   Cles d'API partenaire (hash SHA-256 calcule cote appli).
   ===================================================================== */

CREATE OR ALTER PROCEDURE dbo.s0112CreatePartnerApiKey
    @PartenaireId INT,
    @KeyHash      CHAR(64),
    @Prefix       NVARCHAR(20),
    @Label        NVARCHAR(100) = NULL,
    @Environment  NVARCHAR(10)  = N'test',
    @AdminId      INT           = NULL,
    @Id           INT           = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @PartenaireId IS NULL BEGIN RAISERROR(N'PartenaireId est requis.',16,1); RETURN; END
    INSERT INTO dbo.T040ApiKey (AbonneId, PartenaireId, KeyHash, Prefix, Label, Environment, CreatedByAdminId)
    VALUES (NULL, @PartenaireId, @KeyHash, @Prefix, @Label, @Environment, @AdminId);
    SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    SELECT @Id AS Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0113ListPartnerApiKeys
    @PartenaireId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Prefix, Label, Environment, IsActive, CreatedUtc, LastUsedUtc, RevokedUtc
    FROM   dbo.T040ApiKey
    WHERE  PartenaireId = @PartenaireId
    ORDER BY IsActive DESC, Id DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0114RevokePartnerApiKey
    @Id INT, @PartenaireId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T040ApiKey
    SET IsActive = 0, RevokedUtc = SYSUTCDATETIME()
    WHERE Id = @Id AND PartenaireId = @PartenaireId AND IsActive = 1;
END
GO

/* =====================================================================
   Provisioning des abonnes (tenants) par un partenaire.
   ===================================================================== */

CREATE OR ALTER PROCEDURE dbo.s0115CreateAbonneForPartner
    @PartenaireId     INT,
    @RaisonSociale    NVARCHAR(200),
    @NomAffichage     NVARCHAR(200) = NULL,
    @NumeroEntreprise NVARCHAR(50)  = NULL,
    @CourrielContact  NVARCHAR(256) = NULL,
    @Telephone        NVARCHAR(40)  = NULL,
    @Adresse1         NVARCHAR(200) = NULL,
    @Adresse2         NVARCHAR(200) = NULL,
    @Ville            NVARCHAR(120) = NULL,
    @Province         NVARCHAR(60)  = NULL,
    @CodePostal       NVARCHAR(20)  = NULL,
    @Pays             NVARCHAR(60)  = N'Canada',
    @Statut           NVARCHAR(20)  = N'Prospect',
    @Id               INT           = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @PartenaireId IS NULL BEGIN RAISERROR(N'PartenaireId est requis.',16,1); RETURN; END
    IF NOT EXISTS (SELECT 1 FROM dbo.T045Partenaire WHERE Id = @PartenaireId AND Statut = N'Actif')
    BEGIN RAISERROR(N'Partenaire inconnu ou inactif.',16,1); RETURN; END

    INSERT INTO dbo.T010Abonne
        (PartenaireId, RaisonSociale, NomAffichage, NumeroEntreprise, CourrielContact, Telephone,
         Adresse1, Adresse2, Ville, Province, CodePostal, Pays, Statut, StatutKYB)
    VALUES
        (@PartenaireId, @RaisonSociale, @NomAffichage, @NumeroEntreprise, @CourrielContact, @Telephone,
         @Adresse1, @Adresse2, @Ville, @Province, @CodePostal, @Pays, @Statut, N'NonDebute');

    SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    SELECT a.Id, a.TenantGUID, a.RaisonSociale, a.NomAffichage, a.CourrielContact,
           a.Statut, a.StatutKYB, a.CreatedUtc
    FROM   dbo.T010Abonne a WHERE a.Id = @Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0116ListAbonnesForPartner
    @PartenaireId INT,
    @Search       NVARCHAR(200) = NULL,
    @Limit        INT = 26,
    @Offset       INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, TenantGUID, RaisonSociale, NomAffichage, CourrielContact, Statut, StatutKYB, CreatedUtc
    FROM   dbo.T010Abonne
    WHERE  PartenaireId = @PartenaireId
      AND  (@Search IS NULL OR @Search = N''
            OR RaisonSociale   LIKE N'%' + @Search + N'%'
            OR NomAffichage    LIKE N'%' + @Search + N'%'
            OR CourrielContact LIKE N'%' + @Search + N'%')
    ORDER BY Id DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0117GetAbonneForPartner
    @Id INT, @PartenaireId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, TenantGUID, RaisonSociale, NomAffichage, NumeroEntreprise, CourrielContact,
           Telephone, Adresse1, Adresse2, Ville, Province, CodePostal, Pays,
           Statut, StatutKYB, CreatedUtc
    FROM   dbo.T010Abonne
    WHERE  Id = @Id AND PartenaireId = @PartenaireId;
END
GO

/* ---- Tableau de bord partenaire : compteurs ---- */
CREATE OR ALTER PROCEDURE dbo.s0118GetPartnerDashboard
    @PartenaireId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        (SELECT COUNT(*) FROM dbo.T010Abonne WHERE PartenaireId = @PartenaireId)                                AS NbAbonnes,
        (SELECT COUNT(*) FROM dbo.T010Abonne WHERE PartenaireId = @PartenaireId AND Statut = N'Actif')          AS NbActifs,
        (SELECT COUNT(*) FROM dbo.T010Abonne WHERE PartenaireId = @PartenaireId AND StatutKYB = N'Verifie')     AS NbKybVerifie,
        (SELECT COUNT(*) FROM dbo.T010Abonne WHERE PartenaireId = @PartenaireId AND StatutKYB IN (N'NonDebute', N'EnCours')) AS NbKybEnAttente,
        (SELECT COUNT(*) FROM dbo.T040ApiKey WHERE PartenaireId = @PartenaireId AND IsActive = 1)               AS NbClesActives;
END
GO

/* ---------------------------------------------------------------------
   s0027ResolveApiKey : ajoute PartenaireId a la sortie (retro-compatible :
   NULL pour une cle abonne). Consomme par le webAPI (auth deleguee).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0027ResolveApiKey
    @KeyHash CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T040ApiKey
    SET LastUsedUtc = SYSUTCDATETIME()
    OUTPUT inserted.Id AS ApiKeyId, inserted.AbonneId, inserted.PartenaireId, inserted.Environment
    WHERE KeyHash = @KeyHash AND IsActive = 1;
END
GO

/* =====================================================================
   Seed de demonstration : un partenaire + un utilisateur portail.
   Mot de passe : Partner2026 (BCrypt cost 11). Idempotent.
   ===================================================================== */
IF NOT EXISTS (SELECT 1 FROM dbo.T045Partenaire WHERE RaisonSociale = N'Dentitek (demo)')
BEGIN
    DECLARE @pid INT = 0;
    EXEC dbo.s0110SavePartenaire
        @Id = @pid OUTPUT,
        @RaisonSociale = N'Dentitek (demo)',
        @NomAffichage = N'Dentitek',
        @CourrielContact = N'partenaire@demo.ca',
        @Statut = N'Actif';

    IF NOT EXISTS (SELECT 1 FROM dbo.T046PartenaireUser WHERE Email = N'partenaire@demo.ca')
    BEGIN
        INSERT INTO dbo.T046PartenaireUser (PartenaireId, Email, PasswordHash, FirstName, LastName, IsAdmin, IsActive)
        VALUES (@pid, N'partenaire@demo.ca',
                N'$2a$11$mPhZBWntF9IYs6mlth.JzuRECIgxE8mQ8M8XrdZP2vgPjBSd0siHu', -- Partner2026
                N'Demo', N'Partenaire', 1, 1);
        PRINT N'Partenaire de demonstration cree : partenaire@demo.ca / Partner2026';
    END
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'42_partenaires.sql : termine.';
GO
