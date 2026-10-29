-- =============================================================================
-- T341_Portail_echanges.sql — Portail comptable Phase 4, Part D
-- Échanges : fil de discussion à deux sens entre le cabinet et le client (son
-- entreprise). Le cabinet écrit depuis la fiche ; le client lit et répond dans
-- SON ERP (page + pastille au tableau de bord).
-- Procs libres : s0951+. Table : T341Echange.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.T341Echange', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T341Echange (
        Id          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CabinetId   INT               NOT NULL,
        CompanyGUID UNIQUEIDENTIFIER  NOT NULL,
        Utc         DATETIME2(0)      NOT NULL CONSTRAINT DF_T341_Utc DEFAULT SYSUTCDATETIME(),
        Expediteur  NVARCHAR(10)      NOT NULL,   -- 'cabinet' | 'client'
        UserGUID    UNIQUEIDENTIFIER  NULL,
        Texte       NVARCHAR(2000)    NOT NULL,
        LuCabinet   BIT               NOT NULL CONSTRAINT DF_T341_LuCab DEFAULT 0,
        LuClient    BIT               NOT NULL CONSTRAINT DF_T341_LuCli DEFAULT 0,
        CONSTRAINT CK_T341_Exp CHECK (Expediteur IN ('cabinet','client'))
    );
    CREATE INDEX IX_T341_Company ON dbo.T341Echange(CompanyGUID, Utc);
END
GO

-- ---------------------------------------------------------------------------
-- s0951ListEchanges : le fil d'un dossier (par compagnie). Les deux côtés
-- l'utilisent ; le contrôle d'accès est assuré par l'appelant (périmètre cabinet
-- côté portail, compagnie de session côté client).
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0951ListEchanges
    @CompanyGUID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SELECT e.Utc, e.Expediteur, e.Texte,
           LTRIM(RTRIM(ISNULL(u.FirstName,N'') + N' ' + ISNULL(u.LastName,N''))) AS ExpNom
    FROM dbo.T341Echange e
    LEFT JOIN dbo.T015User u ON u.UserGUID = e.UserGUID
    WHERE e.CompanyGUID = @CompanyGUID
    ORDER BY e.Utc, e.Id;
END
GO

-- ---------------------------------------------------------------------------
-- s0952AddEchangeCabinet : le cabinet écrit au client (membre du périmètre).
-- Renvoie le courriel de l'admin du client (@ClientEmail) pour notification.
-- ErrorCode : 0=OK, 6=hors périmètre.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0952AddEchangeCabinet
    @UserId      varchar(200),
    @CompanyGUID uniqueidentifier,
    @Texte       nvarchar(2000),
    @ClientEmail nvarchar(200) OUTPUT,
    @ErrorCode   int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0; SET @ClientEmail = NULL;

    DECLARE @uid uniqueidentifier, @cabId int;
    SELECT TOP 1 @uid = u.UserGUID, @cabId = m.CabinetId FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0 ORDER BY m.Id;
    IF @uid IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.fCabinetDossiers(@uid) WHERE CompanyGUID = @CompanyGUID)
    BEGIN SET @ErrorCode = 6; RETURN; END

    INSERT INTO dbo.T341Echange (CabinetId, CompanyGUID, Expediteur, UserGUID, Texte, LuCabinet, LuClient)
    VALUES (@cabId, @CompanyGUID, 'cabinet', @uid, @Texte, 1, 0);

    DECLARE @jtxt nvarchar(500) = N'Message envoyé au client.';
    EXEC dbo.s0946AddJournal @cabId, @CompanyGUID, @uid, 'echange', @jtxt;

    SELECT TOP 1 @ClientEmail = Email FROM dbo.T015User
    WHERE CompanyGUID = @CompanyGUID AND IsAdmin = 1 AND IsActive = 1 AND IsDeleted = 0 ORDER BY Id;
END
GO

-- ---------------------------------------------------------------------------
-- s0953AddEchangeClient : le client répond (dans son ERP, compagnie de session).
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0953AddEchangeClient
    @CompanyGUID uniqueidentifier,
    @UserId      int,
    @Texte       nvarchar(2000),
    @ErrorCode   int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;

    -- Le cabinet du dossier (via ComptableGUID d'un membre).
    DECLARE @cabId int, @ug uniqueidentifier;
    SELECT @ug = UserGUID FROM dbo.T015User WHERE Id = @UserId;
    SELECT TOP 1 @cabId = m.CabinetId
    FROM dbo.T010Company c
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = c.ComptableGUID AND m.IsActive = 1
    JOIN dbo.T331Cabinet cab ON cab.Id = m.CabinetId AND cab.IsActive = 1
    WHERE c.CompanyGUID = @CompanyGUID;
    IF @cabId IS NULL BEGIN SET @ErrorCode = 6; RETURN; END   -- pas de cabinet rattaché

    INSERT INTO dbo.T341Echange (CabinetId, CompanyGUID, Expediteur, UserGUID, Texte, LuCabinet, LuClient)
    VALUES (@cabId, @CompanyGUID, 'client', @ug, @Texte, 0, 1);
END
GO

-- ---------------------------------------------------------------------------
-- s0954MarkEchangesLus : marque le fil comme lu pour un côté ('cabinet'|'client').
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0954MarkEchangesLus
    @CompanyGUID uniqueidentifier,
    @Cote        nvarchar(10)
AS
BEGIN
    SET NOCOUNT ON;
    IF @Cote = 'cabinet'
        UPDATE dbo.T341Echange SET LuCabinet = 1 WHERE CompanyGUID = @CompanyGUID AND Expediteur = 'client' AND LuCabinet = 0;
    ELSE
        UPDATE dbo.T341Echange SET LuClient = 1 WHERE CompanyGUID = @CompanyGUID AND Expediteur = 'cabinet' AND LuClient = 0;
END
GO

-- ---------------------------------------------------------------------------
-- s0955CountEchangesNonLus : nombre de messages non lus pour un côté.
-- 'client' = messages du cabinet non lus par le client (pour la pastille client).
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0955CountEchangesNonLus
    @CompanyGUID uniqueidentifier,
    @Cote        nvarchar(10)
AS
BEGIN
    SET NOCOUNT ON;
    IF @Cote = 'cabinet'
        SELECT COUNT(*) AS N FROM dbo.T341Echange WHERE CompanyGUID = @CompanyGUID AND Expediteur = 'client' AND LuCabinet = 0;
    ELSE
        SELECT COUNT(*) AS N FROM dbo.T341Echange WHERE CompanyGUID = @CompanyGUID AND Expediteur = 'cabinet' AND LuClient = 0;
END
GO
