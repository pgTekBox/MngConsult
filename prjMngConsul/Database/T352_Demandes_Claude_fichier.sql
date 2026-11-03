-- =============================================================================
-- T352 — « Demande à Claude » : pièce jointe (un fichier par demande)
--
-- On ajoute à T026ClaudePrompt de quoi stocker un fichier joint (nom, type MIME,
-- taille et contenu binaire). Le handler ERP (ClaudePrompt.ashx) l'enregistre via
-- s0963 (étendue). La console d'admin (prjSec60Admin) affiche un lien de
-- téléchargement ; le contenu est servi par s0968GetClaudePromptFichier.
--
-- Idempotent (colonnes ajoutées si absentes, CREATE OR ALTER procs). Rejouable.
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.T026ClaudePrompt', 'FichierNom') IS NULL
    ALTER TABLE dbo.T026ClaudePrompt ADD FichierNom NVARCHAR(260) NULL;
GO
IF COL_LENGTH('dbo.T026ClaudePrompt', 'FichierType') IS NULL
    ALTER TABLE dbo.T026ClaudePrompt ADD FichierType NVARCHAR(150) NULL;
GO
IF COL_LENGTH('dbo.T026ClaudePrompt', 'FichierTaille') IS NULL
    ALTER TABLE dbo.T026ClaudePrompt ADD FichierTaille INT NULL;
GO
IF COL_LENGTH('dbo.T026ClaudePrompt', 'FichierData') IS NULL
    ALTER TABLE dbo.T026ClaudePrompt ADD FichierData VARBINARY(MAX) NULL;
GO

-- ---------------------------------------------------------------------------
-- s0963InsertClaudePrompt : enregistre une demande, avec un fichier joint
-- optionnel. L'adresse de l'usager est résolue à partir de @UserId.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0963InsertClaudePrompt
    @UserId        int = NULL,
    @CompanyGUID   uniqueidentifier = NULL,
    @Page          nvarchar(200),
    @Prompt        nvarchar(max),
    @Url           nvarchar(600) = NULL,
    @FichierNom    nvarchar(260) = NULL,
    @FichierType   nvarchar(150) = NULL,
    @FichierTaille int = NULL,
    @FichierData   varbinary(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page IS NULL OR LTRIM(RTRIM(@Page)) = '' OR @Prompt IS NULL OR LTRIM(RTRIM(@Prompt)) = ''
    BEGIN
        RAISERROR('Page et prompt sont requis.', 16, 1);
        RETURN;
    END
    IF @CompanyGUID = '00000000-0000-0000-0000-000000000000' SET @CompanyGUID = NULL;
    IF @FichierData IS NOT NULL AND DATALENGTH(@FichierData) = 0 SET @FichierData = NULL;
    IF @FichierData IS NULL
    BEGIN
        SET @FichierNom = NULL; SET @FichierType = NULL; SET @FichierTaille = NULL;
    END

    DECLARE @email nvarchar(320) = NULL;
    IF @UserId IS NOT NULL AND @UserId <> 0
        SELECT @email = Email FROM dbo.T015User WHERE Id = @UserId;

    INSERT INTO dbo.T026ClaudePrompt
        (Page, Prompt, Url, UserId, UserEmail, CompanyGUID,
         FichierNom, FichierType, FichierTaille, FichierData)
    OUTPUT INSERTED.Id
    VALUES
        (LEFT(@Page, 200), @Prompt, LEFT(@Url, 600), @UserId, @email, @CompanyGUID,
         LEFT(@FichierNom, 260), LEFT(@FichierType, 150), @FichierTaille, @FichierData);
END
GO

-- ---------------------------------------------------------------------------
-- s0964ListClaudePrompts : liste pour la console d'admin. Ajoute le nom et la
-- taille du fichier joint (le contenu est servi à la demande par s0968).
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0964ListClaudePrompts
    @Filtre varchar(10) = 'tous'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.Id, p.Page, p.Prompt, p.Url, p.UserEmail, p.CompanyGUID,
        CASE WHEN p.CompanyGUID IS NULL THEN NULL ELSE dbo.fCompanyName(p.CompanyGUID) END AS DossierNom,
        p.Created, p.Statut, p.DoneUtc, p.DoneBy,
        p.FichierNom, p.FichierTaille
    FROM dbo.T026ClaudePrompt p
    WHERE (@Filtre = 'tous' OR p.Statut = @Filtre)
    ORDER BY CASE p.Statut WHEN 'nouveau' THEN 0 ELSE 1 END, p.Created DESC, p.Id DESC;
END
GO

-- ---------------------------------------------------------------------------
-- s0966GetClaudePromptsByPage : menu déroulant de l'ERP. Ajoute le nom du
-- fichier joint, pour que l'aperçu puisse l'indiquer.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0966GetClaudePromptsByPage
    @UserId int = NULL,
    @Page   nvarchar(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (200)
        Id, Page, Created, Statut, Prompt, FichierNom
    FROM dbo.T026ClaudePrompt
    WHERE (@Page IS NULL OR Page = @Page)
      AND (@UserId IS NULL OR UserId = @UserId)
    ORDER BY Created DESC, Id DESC;
END
GO

-- ---------------------------------------------------------------------------
-- s0968GetClaudePromptFichier : le fichier joint d'une demande (téléchargement
-- depuis la console d'admin). Ne renvoie rien si la demande n'a pas de fichier.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0968GetClaudePromptFichier
    @Id int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT FichierNom, FichierType, FichierData
    FROM dbo.T026ClaudePrompt
    WHERE Id = @Id AND FichierData IS NOT NULL;
END
GO
