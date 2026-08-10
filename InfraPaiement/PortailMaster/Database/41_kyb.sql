/* =====================================================================
   PortailMaster - Script 41 : connecteur KYB (Know Your Business), sandbox
   ---------------------------------------------------------------------
   Vérification de la légitimité d'une entreprise abonnée (registre, listes
   de sanctions, adresse) avant/pendant l'exploitation. Connecteur ABSTRAIT
   + fournisseur SANDBOX simulé (le vrai — Trulioo/Onfido — est gaté par le
   fournisseur). Chaque vérification est enregistrée (T057) et pilote le
   StatutKYB de l'abonné (NonDebute/EnCours/Verifie/Rejete).

   Mapping résultat -> StatutKYB : Verified->Verifie, Rejected->Rejete,
   Review->EnCours.

   T057KybCheck + s0101SaveKybCheck / s0102ListKybChecks / s0103SetAbonneKybStatus.
   A executer APRES 04. Procs numerotees s0101+.
   ===================================================================== */

USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.T057KybCheck', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T057KybCheck
    (
        Id               INT           IDENTITY(1,1) NOT NULL,
        AbonneId         INT           NOT NULL,
        Provider         NVARCHAR(30)  NOT NULL,       -- sandbox / trulioo / onfido
        ProviderRef      NVARCHAR(60)  NULL,           -- référence de la vérification chez le fournisseur
        Status           NVARCHAR(20)  NOT NULL,       -- Verified / Rejected / Review / Error
        Score            INT           NULL,           -- 0..100
        RegistryMatch    BIT           NULL,           -- entreprise trouvée au registre
        WatchlistClear   BIT           NULL,           -- absente des listes de sanctions
        AddressValid     BIT           NULL,           -- adresse plausible
        Message          NVARCHAR(500) NULL,
        RequestJson      NVARCHAR(MAX) NULL,
        ResultJson       NVARCHAR(MAX) NULL,
        CreatedByAdminId INT           NULL,
        Utc              DATETIME2(0)  NOT NULL CONSTRAINT DF_T057_Utc DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_T057KybCheck PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_T057_Abonne FOREIGN KEY (AbonneId) REFERENCES dbo.T010Abonne(Id)
    );
    CREATE INDEX IX_T057_Abonne ON dbo.T057KybCheck (AbonneId, Id DESC);
END
GO

/* ---- s0101SaveKybCheck : enregistre une vérification, renvoie l'Id ---- */
CREATE OR ALTER PROCEDURE dbo.s0101SaveKybCheck
    @AbonneId       INT,
    @Provider       NVARCHAR(30),
    @ProviderRef    NVARCHAR(60)  = NULL,
    @Status         NVARCHAR(20),
    @Score          INT           = NULL,
    @RegistryMatch  BIT           = NULL,
    @WatchlistClear BIT           = NULL,
    @AddressValid   BIT           = NULL,
    @Message        NVARCHAR(500) = NULL,
    @RequestJson    NVARCHAR(MAX) = NULL,
    @ResultJson     NVARCHAR(MAX) = NULL,
    @AdminId        INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.T057KybCheck (AbonneId, Provider, ProviderRef, Status, Score,
                                  RegistryMatch, WatchlistClear, AddressValid, Message,
                                  RequestJson, ResultJson, CreatedByAdminId)
    VALUES (@AbonneId, @Provider, @ProviderRef, @Status, @Score,
            @RegistryMatch, @WatchlistClear, @AddressValid, @Message,
            @RequestJson, @ResultJson, @AdminId);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
END
GO

/* ---- s0102ListKybChecks ---- */
CREATE OR ALTER PROCEDURE dbo.s0102ListKybChecks
    @AbonneId INT,
    @Top      INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top) Id, Provider, ProviderRef, Status, Score,
           RegistryMatch, WatchlistClear, AddressValid, Message, Utc
    FROM dbo.T057KybCheck WHERE AbonneId = @AbonneId ORDER BY Id DESC;
END
GO

/* ---- s0103SetAbonneKybStatus : pilote le StatutKYB depuis le résultat ---- */
CREATE OR ALTER PROCEDURE dbo.s0103SetAbonneKybStatus
    @AbonneId  INT,
    @StatutKYB NVARCHAR(20),
    @AdminId   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T010Abonne
    SET StatutKYB = @StatutKYB, ModifiedUtc = SYSUTCDATETIME(), ModifiedByAdminId = @AdminId
    WHERE Id = @AbonneId;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO
PRINT N'41_kyb.sql : termine.';
GO
