/* =====================================================================
   PortailMaster / webAPI - Script 09 : Cles d'API par abonne
   ---------------------------------------------------------------------
   Chaque abonne peut avoir des cles d'API que son application SaaS utilise
   pour appeler l'API 60secPaiement (projet webAPI). La cle en clair n'est
   JAMAIS stockee : seul son hash SHA-256 (hex) est conserve. Le prefixe
   sert a identifier la cle dans l'interface. Scoping : la resolution d'une
   cle -> AbonneId isole le locataire.

   Gestion (creation/revocation) depuis PortailMaster ; consommation par
   le projet webAPI. A executer APRES 01-08. Procs s0026+.
   ===================================================================== */

USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.T040ApiKey', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T040ApiKey
    (
        Id               INT           IDENTITY(1,1) NOT NULL,
        AbonneId         INT           NOT NULL,
        KeyHash          CHAR(64)      NOT NULL,          -- SHA-256 hex (minuscule) de la cle complete
        Prefix           NVARCHAR(20)  NOT NULL,          -- affichage (ex. sk_test_a1b2c3d4)
        Label            NVARCHAR(100) NULL,
        Environment      NVARCHAR(10)  NOT NULL CONSTRAINT DF_T040_Env DEFAULT (N'test'),
        IsActive         BIT           NOT NULL CONSTRAINT DF_T040_Active DEFAULT (1),
        CreatedUtc       DATETIME2(0)  NOT NULL CONSTRAINT DF_T040_Created DEFAULT (SYSUTCDATETIME()),
        CreatedByAdminId INT           NULL,
        LastUsedUtc      DATETIME2(0)  NULL,
        RevokedUtc       DATETIME2(0)  NULL,
        CONSTRAINT PK_T040ApiKey PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_T040_Abonne FOREIGN KEY (AbonneId) REFERENCES dbo.T010Abonne(Id),
        CONSTRAINT FK_T040_Admin  FOREIGN KEY (CreatedByAdminId) REFERENCES dbo.T001PortalAdmin(Id)
    );
    CREATE UNIQUE INDEX UX_T040_KeyHash ON dbo.T040ApiKey (KeyHash);
    CREATE INDEX IX_T040_Abonne ON dbo.T040ApiKey (AbonneId, Id);
END
GO

/* --- s0026CreateApiKey : enregistre une cle (hash calcule cote app). --- */
CREATE OR ALTER PROCEDURE dbo.s0026CreateApiKey
    @AbonneId    INT,
    @KeyHash     CHAR(64),
    @Prefix      NVARCHAR(20),
    @Label       NVARCHAR(100) = NULL,
    @Environment NVARCHAR(10)  = N'test',
    @AdminId     INT           = NULL,
    @Id          INT           = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @AbonneId IS NULL BEGIN RAISERROR(N'AbonneId est requis.',16,1); RETURN; END
    INSERT INTO dbo.T040ApiKey (AbonneId, KeyHash, Prefix, Label, Environment, CreatedByAdminId)
    VALUES (@AbonneId, @KeyHash, @Prefix, @Label, @Environment, @AdminId);
    SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    SELECT @Id AS Id;
END
GO

/* --- s0027ResolveApiKey : hash -> abonne (si active). Met a jour LastUsed.
       Renvoie 0 ligne si aucune cle active ne correspond (=> 401 cote API). */
CREATE OR ALTER PROCEDURE dbo.s0027ResolveApiKey
    @KeyHash CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T040ApiKey
    SET LastUsedUtc = SYSUTCDATETIME()
    OUTPUT inserted.Id AS ApiKeyId, inserted.AbonneId, inserted.Environment
    WHERE KeyHash = @KeyHash AND IsActive = 1;
END
GO

/* --- s0028ListApiKeys : cles d'un abonne (sans hash). --- */
CREATE OR ALTER PROCEDURE dbo.s0028ListApiKeys
    @AbonneId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Prefix, Label, Environment, IsActive, CreatedUtc, LastUsedUtc, RevokedUtc
    FROM dbo.T040ApiKey
    WHERE AbonneId = @AbonneId
    ORDER BY IsActive DESC, Id DESC;
END
GO

/* --- s0029RevokeApiKey : desactive une cle (scopee a l'abonne). --- */
CREATE OR ALTER PROCEDURE dbo.s0029RevokeApiKey
    @Id       INT,
    @AbonneId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T040ApiKey
    SET IsActive = 0, RevokedUtc = SYSUTCDATETIME()
    WHERE Id = @Id AND AbonneId = @AbonneId AND IsActive = 1;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'09_api_keys.sql : termine.';
GO
