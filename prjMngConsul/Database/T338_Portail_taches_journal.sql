-- =============================================================================
-- T338_Portail_taches_journal.sql — Portail comptable Phase 4, Part C
-- Suivi d'avancement : tâches libres par dossier + journal d'événements.
-- Accès borné au périmètre du cabinet (dbo.fCabinetDossiers).
-- Procs libres : s0942+. Tables : T339DossierTache, T340DossierJournal.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.T339DossierTache', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T339DossierTache (
        Id               INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CabinetId        INT               NOT NULL,
        CompanyGUID      UNIQUEIDENTIFIER  NOT NULL,
        Titre            NVARCHAR(200)     NOT NULL,
        Description      NVARCHAR(MAX)     NULL,
        AssignedUserGUID UNIQUEIDENTIFIER  NULL,
        Echeance         DATE              NULL,
        Statut           NVARCHAR(20)      NOT NULL CONSTRAINT DF_T339_Statut DEFAULT 'afaire',
        CreatedUtc       DATETIME2(0)      NOT NULL CONSTRAINT DF_T339_Created DEFAULT SYSUTCDATETIME(),
        CreatedBy        UNIQUEIDENTIFIER  NULL,
        DoneUtc          DATETIME2(0)      NULL,
        CONSTRAINT CK_T339_Statut CHECK (Statut IN ('afaire','encours','fait','bloque'))
    );
    CREATE INDEX IX_T339_Company ON dbo.T339DossierTache(CompanyGUID, Statut);
END
GO

IF OBJECT_ID('dbo.T340DossierJournal', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T340DossierJournal (
        Id          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CabinetId   INT               NOT NULL,
        CompanyGUID UNIQUEIDENTIFIER  NOT NULL,
        Utc         DATETIME2(0)      NOT NULL CONSTRAINT DF_T340_Utc DEFAULT SYSUTCDATETIME(),
        UserGUID    UNIQUEIDENTIFIER  NULL,
        [Type]      NVARCHAR(30)      NOT NULL CONSTRAINT DF_T340_Type DEFAULT 'note',
        Texte       NVARCHAR(500)     NOT NULL
    );
    CREATE INDEX IX_T340_Company ON dbo.T340DossierJournal(CompanyGUID, Utc);
END
GO

-- Helper interne : résout cabinet + valide le périmètre pour l'appelant.
-- (Réutilisé par les procs ci-dessous via un bloc commun inline.)

-- ---------------------------------------------------------------------------
-- s0946AddJournal : ajoute une ligne de journal (appelée par l'app et les procs).
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0946AddJournal
    @CabinetId   INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserGUID    UNIQUEIDENTIFIER = NULL,
    @Type        NVARCHAR(30),
    @Texte       NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.T340DossierJournal (CabinetId, CompanyGUID, UserGUID, [Type], Texte)
    VALUES (@CabinetId, @CompanyGUID, @UserGUID, @Type, @Texte);
END
GO

-- ---------------------------------------------------------------------------
-- s0942ListTaches : tâches d'un dossier (si dans le périmètre de l'appelant).
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0942ListTaches
    @UserId      varchar(200),
    @CompanyGUID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @uid uniqueidentifier;
    SELECT TOP 1 @uid = u.UserGUID FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0 ORDER BY m.Id;
    IF @uid IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.fCabinetDossiers(@uid) WHERE CompanyGUID = @CompanyGUID) RETURN;

    SELECT t.Id, t.Titre, t.Description, t.AssignedUserGUID,
           LTRIM(RTRIM(ISNULL(au.FirstName,N'') + N' ' + ISNULL(au.LastName,N''))) AS AssignedNom,
           t.Echeance, t.Statut, t.CreatedUtc, t.DoneUtc
    FROM dbo.T339DossierTache t
    LEFT JOIN dbo.T015User au ON au.UserGUID = t.AssignedUserGUID
    WHERE t.CompanyGUID = @CompanyGUID
    ORDER BY CASE t.Statut WHEN 'bloque' THEN 0 WHEN 'encours' THEN 1 WHEN 'afaire' THEN 2 ELSE 3 END,
             ISNULL(t.Echeance, '9999-12-31'), t.Id;
END
GO

-- ---------------------------------------------------------------------------
-- s0943SaveTache : créer (@Id=0) ou éditer une tâche + journal.
-- ErrorCode : 0=OK, 6=hors périmètre.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0943SaveTache
    @UserId           varchar(200),
    @Id               int,
    @CompanyGUID      uniqueidentifier,
    @Titre            nvarchar(200),
    @Description      nvarchar(max) = NULL,
    @AssignedUserGUID uniqueidentifier = NULL,
    @Echeance         date = NULL,
    @Statut           nvarchar(20) = 'afaire',
    @NewId            int OUTPUT,
    @ErrorCode        int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0; SET @NewId = @Id;
    DECLARE @jtxt nvarchar(500);

    DECLARE @uid uniqueidentifier, @cabId int;
    SELECT TOP 1 @uid = u.UserGUID, @cabId = m.CabinetId FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0 ORDER BY m.Id;
    IF @uid IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.fCabinetDossiers(@uid) WHERE CompanyGUID = @CompanyGUID)
    BEGIN SET @ErrorCode = 6; RETURN; END

    IF @Statut NOT IN ('afaire','encours','fait','bloque') SET @Statut = 'afaire';

    IF @Id = 0
    BEGIN
        INSERT INTO dbo.T339DossierTache (CabinetId, CompanyGUID, Titre, Description, AssignedUserGUID, Echeance, Statut, CreatedBy, DoneUtc)
        VALUES (@cabId, @CompanyGUID, @Titre, @Description, @AssignedUserGUID, @Echeance, @Statut,
                @uid, CASE WHEN @Statut = 'fait' THEN SYSUTCDATETIME() ELSE NULL END);
        SET @NewId = SCOPE_IDENTITY();
        SET @jtxt = N'Tâche créée : ' + @Titre;
        EXEC dbo.s0946AddJournal @cabId, @CompanyGUID, @uid, 'tache', @jtxt;
    END
    ELSE
    BEGIN
        UPDATE dbo.T339DossierTache
        SET Titre = @Titre, Description = @Description, AssignedUserGUID = @AssignedUserGUID,
            Echeance = @Echeance, Statut = @Statut,
            DoneUtc = CASE WHEN @Statut = 'fait' AND DoneUtc IS NULL THEN SYSUTCDATETIME()
                           WHEN @Statut <> 'fait' THEN NULL ELSE DoneUtc END
        WHERE Id = @Id AND CompanyGUID = @CompanyGUID;
        SET @jtxt = N'Tâche modifiée : ' + @Titre;
        EXEC dbo.s0946AddJournal @cabId, @CompanyGUID, @uid, 'tache', @jtxt;
    END
END
GO

-- ---------------------------------------------------------------------------
-- s0944SetStatutTache : change le statut d'une tâche + journal.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0944SetStatutTache
    @UserId    varchar(200),
    @Id        int,
    @Statut    nvarchar(20),
    @ErrorCode int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;

    DECLARE @uid uniqueidentifier, @cabId int, @cg uniqueidentifier, @titre nvarchar(200);
    SELECT TOP 1 @uid = u.UserGUID, @cabId = m.CabinetId FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0 ORDER BY m.Id;

    SELECT @cg = CompanyGUID, @titre = Titre FROM dbo.T339DossierTache WHERE Id = @Id;
    IF @uid IS NULL OR @cg IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.fCabinetDossiers(@uid) WHERE CompanyGUID = @cg)
    BEGIN SET @ErrorCode = 6; RETURN; END
    IF @Statut NOT IN ('afaire','encours','fait','bloque') BEGIN SET @ErrorCode = 7; RETURN; END

    UPDATE dbo.T339DossierTache
    SET Statut = @Statut,
        DoneUtc = CASE WHEN @Statut = 'fait' THEN SYSUTCDATETIME() ELSE NULL END
    WHERE Id = @Id;

    DECLARE @jtxt nvarchar(500) = N'« ' + @titre + N' » → ' + @Statut;
    EXEC dbo.s0946AddJournal @cabId, @cg, @uid, 'statut', @jtxt;
END
GO

-- ---------------------------------------------------------------------------
-- s0945ListJournal : le journal d'un dossier (si dans le périmètre).
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0945ListJournal
    @UserId      varchar(200),
    @CompanyGUID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @uid uniqueidentifier;
    SELECT TOP 1 @uid = u.UserGUID FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0 ORDER BY m.Id;
    IF @uid IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.fCabinetDossiers(@uid) WHERE CompanyGUID = @CompanyGUID) RETURN;

    SELECT TOP 200 j.Utc, j.[Type], j.Texte,
           LTRIM(RTRIM(ISNULL(u2.FirstName,N'') + N' ' + ISNULL(u2.LastName,N''))) AS ParNom
    FROM dbo.T340DossierJournal j
    LEFT JOIN dbo.T015User u2 ON u2.UserGUID = j.UserGUID
    WHERE j.CompanyGUID = @CompanyGUID
    ORDER BY j.Utc DESC, j.Id DESC;
END
GO
