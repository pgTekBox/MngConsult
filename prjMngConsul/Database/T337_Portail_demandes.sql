-- =============================================================================
-- T337_Portail_demandes.sql — Portail comptable Phase 4, Part A
-- Flux entrant : une entreprise (client) demande un cabinet depuis l'annuaire ;
-- le cabinet accepte (la compagnie devient un dossier) ou refuse.
-- Patron calqué sur T328RdvDemande (EnAttente/Acceptee/Refusee).
-- Procs libres : s0938+. Script/table : T337.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.T337DemandeCabinet', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T337DemandeCabinet (
        Id                INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyGUID       UNIQUEIDENTIFIER  NOT NULL,   -- l'entreprise qui demande
        CabinetCertifieId INT               NOT NULL,   -- la fiche d'annuaire visée (T319)
        Message           NVARCHAR(1000)    NULL,
        Canal             NVARCHAR(20)       NOT NULL CONSTRAINT DF_T337_Canal DEFAULT 'Portail',
        Statut            NVARCHAR(20)       NOT NULL CONSTRAINT DF_T337_Statut DEFAULT 'EnAttente',
        RecueLe           DATETIME2(0)       NOT NULL CONSTRAINT DF_T337_Recue DEFAULT SYSUTCDATETIME(),
        TraiteeLe         DATETIME2(0)       NULL,
        TraiteePar        UNIQUEIDENTIFIER   NULL,       -- UserGUID du membre qui a tranché
        CONSTRAINT CK_T337_Statut CHECK (Statut IN ('EnAttente','Acceptee','Refusee'))
    );
    CREATE INDEX IX_T337_Cabinet ON dbo.T337DemandeCabinet(CabinetCertifieId, Statut);
    CREATE INDEX IX_T337_Company ON dbo.T337DemandeCabinet(CompanyGUID, Statut);
END
GO

-- ---------------------------------------------------------------------------
-- s0938CreerDemandeCabinet : une entreprise demande un cabinet (côté client).
-- Refuse un doublon encore en attente pour le même (compagnie, cabinet).
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0938CreerDemandeCabinet
    @CompanyGUID       UNIQUEIDENTIFIER,
    @CabinetCertifieId INT,
    @Message           NVARCHAR(1000) = NULL,
    @ErrorCode         INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;

    IF @CabinetCertifieId IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.T319CabinetCertifie WHERE Id = @CabinetCertifieId AND IsActive = 1)
    BEGIN SET @ErrorCode = 2; RETURN; END   -- cabinet inconnu / hors annuaire

    IF EXISTS (SELECT 1 FROM dbo.T337DemandeCabinet
               WHERE CompanyGUID = @CompanyGUID AND CabinetCertifieId = @CabinetCertifieId AND Statut = 'EnAttente')
    BEGIN SET @ErrorCode = 1; RETURN; END    -- déjà une demande en attente

    INSERT INTO dbo.T337DemandeCabinet (CompanyGUID, CabinetCertifieId, Message)
    VALUES (@CompanyGUID, @CabinetCertifieId, @Message);
END
GO

-- ---------------------------------------------------------------------------
-- s0939ListDemandesCabinet : les demandes EN ATTENTE adressées au cabinet de
-- l'appelant (via T331.CabinetCertifieId). Réservé admin/solo côté app.
-- ---------------------------------------------------------------------------
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

    IF @certId IS NULL
    BEGIN
        SELECT CAST(NULL AS INT) AS Id, CAST(NULL AS UNIQUEIDENTIFIER) AS CompanyGUID,
               CAST(NULL AS NVARCHAR(200)) AS Name, CAST(NULL AS NVARCHAR(1000)) AS Message,
               CAST(NULL AS DATETIME2(0)) AS RecueLe
        WHERE 1 = 0;
        RETURN;
    END

    SELECT d.Id, d.CompanyGUID, dbo.fCompanyName(d.CompanyGUID) AS Name, d.Message, d.RecueLe
    FROM dbo.T337DemandeCabinet d
    WHERE d.CabinetCertifieId = @certId AND d.Statut = 'EnAttente'
    ORDER BY d.RecueLe;
END
GO

-- ---------------------------------------------------------------------------
-- s0940TraiterDemandeCabinet : accepter (la compagnie devient un dossier :
-- ComptableGUID = UserGUID de l'admin appelant) ou refuser. admin/solo.
-- ErrorCode : 0=OK, 2=non autorisé, 5=introuvable/déjà traitée.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0940TraiterDemandeCabinet
    @UserId    varchar(200),
    @Id        INT,
    @Decision  NVARCHAR(10),            -- 'accepter' | 'refuser'
    @ErrorCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;

    DECLARE @uid UNIQUEIDENTIFIER, @certId INT, @role NVARCHAR(20);
    SELECT TOP 1 @uid = u.UserGUID, @certId = cab.CabinetCertifieId, @role = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    JOIN dbo.T331Cabinet cab     ON cab.Id = m.CabinetId AND cab.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    IF @certId IS NULL OR @role NOT IN ('admin','solo') BEGIN SET @ErrorCode = 2; RETURN; END

    DECLARE @cg UNIQUEIDENTIFIER;
    SELECT @cg = CompanyGUID FROM dbo.T337DemandeCabinet
    WHERE Id = @Id AND CabinetCertifieId = @certId AND Statut = 'EnAttente';
    IF @cg IS NULL BEGIN SET @ErrorCode = 5; RETURN; END

    IF @Decision = 'accepter'
    BEGIN
        UPDATE dbo.T010Company SET ComptableGUID = @uid WHERE CompanyGUID = @cg;
        UPDATE dbo.T337DemandeCabinet
        SET Statut = 'Acceptee', TraiteeLe = SYSUTCDATETIME(), TraiteePar = @uid
        WHERE Id = @Id;
    END
    ELSE
    BEGIN
        UPDATE dbo.T337DemandeCabinet
        SET Statut = 'Refusee', TraiteeLe = SYSUTCDATETIME(), TraiteePar = @uid
        WHERE Id = @Id;
    END
END
GO

-- ---------------------------------------------------------------------------
-- s0941GetMaDemande : la dernière demande d'une entreprise (côté client), pour
-- afficher son statut dans l'annuaire (« en attente » / « acceptée »).
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0941GetMaDemande
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 d.Id, d.CabinetCertifieId, c.Nom AS CabinetNom, d.Statut, d.RecueLe, d.TraiteeLe
    FROM dbo.T337DemandeCabinet d
    JOIN dbo.T319CabinetCertifie c ON c.Id = d.CabinetCertifieId
    WHERE d.CompanyGUID = @CompanyGUID
    ORDER BY d.Id DESC;
END
GO
