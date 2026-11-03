-- =============================================================================
-- T349 — Demandes à Claude depuis l'ERP
--
-- Un bouton flottant, sur toutes les pages authentifiées de l'ERP, ouvre une
-- fenêtre où l'utilisateur compose un prompt pour Claude (modification de la page
-- courante). La demande est enregistrée dans T026ClaudePrompt (handler
-- ClaudePrompt.ashx → s0963). La console d'admin (prjSec60Admin) les liste
-- (s0964) et permet de marquer une demande « faite » (s0965).
--
-- Idempotent (CREATE TABLE si absente, CREATE OR ALTER procs). Rejouable.
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.T026ClaudePrompt', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T026ClaudePrompt (
        Id          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Page        NVARCHAR(200)     NOT NULL,
        Prompt      NVARCHAR(MAX)     NOT NULL,
        Url         NVARCHAR(600)     NULL,
        UserId      INT               NULL,
        UserEmail   NVARCHAR(320)     NULL,
        CompanyGUID UNIQUEIDENTIFIER  NULL,
        Created     DATETIME2(0)      NOT NULL CONSTRAINT DF_T026_Created DEFAULT SYSUTCDATETIME(),
        Statut      NVARCHAR(20)      NOT NULL CONSTRAINT DF_T026_Statut DEFAULT 'nouveau',
        DoneUtc     DATETIME2(0)      NULL,
        DoneBy      NVARCHAR(200)     NULL,
        CONSTRAINT CK_T026_Statut CHECK (Statut IN ('nouveau', 'fait'))
    );
    CREATE INDEX IX_T026_Statut ON dbo.T026ClaudePrompt (Statut, Created DESC);
END
GO

-- ---------------------------------------------------------------------------
-- s0963InsertClaudePrompt : enregistre une demande. L'adresse de l'usager est
-- résolue à partir de @UserId (la session n'a pas toujours le courriel chargé).
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0963InsertClaudePrompt
    @UserId      int = NULL,
    @CompanyGUID uniqueidentifier = NULL,
    @Page        nvarchar(200),
    @Prompt      nvarchar(max),
    @Url         nvarchar(600) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page IS NULL OR LTRIM(RTRIM(@Page)) = '' OR @Prompt IS NULL OR LTRIM(RTRIM(@Prompt)) = ''
    BEGIN
        RAISERROR('Page et prompt sont requis.', 16, 1);
        RETURN;
    END
    IF @CompanyGUID = '00000000-0000-0000-0000-000000000000' SET @CompanyGUID = NULL;

    DECLARE @email nvarchar(320) = NULL;
    IF @UserId IS NOT NULL AND @UserId <> 0
        SELECT @email = Email FROM dbo.T015User WHERE Id = @UserId;

    INSERT INTO dbo.T026ClaudePrompt (Page, Prompt, Url, UserId, UserEmail, CompanyGUID)
    OUTPUT INSERTED.Id
    VALUES (LEFT(@Page, 200), @Prompt, LEFT(@Url, 600), @UserId, @email, @CompanyGUID);
END
GO

-- ---------------------------------------------------------------------------
-- s0964ListClaudePrompts : la liste des demandes (console d'admin), récentes
-- d'abord. @Filtre : 'tous' (défaut), 'nouveau' ou 'fait'.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0964ListClaudePrompts
    @Filtre varchar(10) = 'tous'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.Id, p.Page, p.Prompt, p.Url, p.UserEmail, p.CompanyGUID,
        CASE WHEN p.CompanyGUID IS NULL THEN NULL ELSE dbo.fCompanyName(p.CompanyGUID) END AS DossierNom,
        p.Created, p.Statut, p.DoneUtc, p.DoneBy
    FROM dbo.T026ClaudePrompt p
    WHERE (@Filtre = 'tous' OR p.Statut = @Filtre)
    ORDER BY CASE p.Statut WHEN 'nouveau' THEN 0 ELSE 1 END, p.Created DESC, p.Id DESC;
END
GO

-- ---------------------------------------------------------------------------
-- s0965SetClaudePromptDone : marque une demande « faite » (@Done=1) ou la rouvre.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0965SetClaudePromptDone
    @Id     int,
    @DoneBy nvarchar(200) = NULL,
    @Done   bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T026ClaudePrompt
    SET Statut  = CASE WHEN @Done = 1 THEN 'fait' ELSE 'nouveau' END,
        DoneUtc = CASE WHEN @Done = 1 THEN SYSUTCDATETIME() ELSE NULL END,
        DoneBy  = CASE WHEN @Done = 1 THEN @DoneBy ELSE NULL END
    WHERE Id = @Id;
END
GO
