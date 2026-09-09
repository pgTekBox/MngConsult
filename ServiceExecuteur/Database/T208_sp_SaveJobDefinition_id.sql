-- =============================================================================
-- Correction de sp_SaveJobDefinition
-- -----------------------------------------------------------------------------
-- T200JobDefinition.Id n'est pas IDENTITY (les lignes de depart ont ete
-- numerotees a la main), mais la procedure lisait SCOPE_IDENTITY() apres son
-- INSERT. Resultat : Id NULL, violation de la contrainte NOT NULL, et aucune
-- tache creable depuis la console d'administration.
--
-- La procedure numerote maintenant elle-meme, sous verrou. On ne reconstruit
-- pas la table pour y poser une IDENTITY : quatre tables la referencent et une
-- tache se cree une fois de temps en temps.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_SaveJobDefinition]
    @JobDefinitionId INT,                       -- 0 = INSERT
    @JobCode         VARCHAR(50),
    @Nom             VARCHAR(200),
    @Description     VARCHAR(1000) = NULL,
    @HandlerType     VARCHAR(20),
    @HandlerName     VARCHAR(200),
    @HandlerParams   NVARCHAR(MAX) = NULL,
    @TimeoutSeconds  INT = 300,
    @MaxRetries      INT = 0,
    @RetryDelayMin   INT = 5,
    @Actif           BIT = 1,
    @CompanyGUID     UNIQUEIDENTIFIER = NULL,
    @UserId          INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- ─── Validations ───
    IF @JobCode IS NULL OR LTRIM(RTRIM(@JobCode)) = ''
    BEGIN
        RAISERROR('Le code du job est obligatoire.', 16, 1);
        RETURN;
    END

    IF @Nom IS NULL OR LTRIM(RTRIM(@Nom)) = ''
    BEGIN
        RAISERROR('Le nom du job est obligatoire.', 16, 1);
        RETURN;
    END

    IF @HandlerType NOT IN ('SP', 'CONNECTOR', 'EMAIL', 'CUSTOM')
    BEGIN
        RAISERROR('Type de handler invalide. Doit être SP, CONNECTOR, EMAIL ou CUSTOM.', 16, 1);
        RETURN;
    END

    IF @HandlerName IS NULL OR LTRIM(RTRIM(@HandlerName)) = ''
    BEGIN
        RAISERROR('Le nom du handler est obligatoire.', 16, 1);
        RETURN;
    END

    IF @TimeoutSeconds <= 0 OR @TimeoutSeconds > 86400
    BEGIN
        RAISERROR('Le timeout doit être entre 1 et 86400 secondes.', 16, 1);
        RETURN;
    END

    -- Le code du job doit être unique
    IF EXISTS (
        SELECT 1 FROM [dbo].[T200JobDefinition]
        WHERE [JobCode] = @JobCode
          AND [Id] <> @JobDefinitionId
    )
    BEGIN
        RAISERROR('Le code "%s" est déjà utilisé par un autre job.', 16, 1, @JobCode);
        RETURN;
    END

    -- ─── INSERT ───
    IF @JobDefinitionId = 0
    BEGIN
        -- T200JobDefinition.Id n'est pas une colonne IDENTITY : les lignes de
        -- depart ont ete numerotees a la main. SCOPE_IDENTITY() rendait donc
        -- NULL et l'INSERT echouait sur la contrainte NOT NULL — autrement dit
        -- creer une tache depuis la console etait impossible.
        -- On numerote ici, sous verrou, plutot que de reconstruire la table :
        -- une tache se cree une fois de temps en temps, la serialisation ne
        -- coute rien.
        SELECT @JobDefinitionId = ISNULL(MAX([Id]), 0) + 1
        FROM [dbo].[T200JobDefinition] WITH (UPDLOCK, HOLDLOCK);

        INSERT INTO [dbo].[T200JobDefinition] (
            [Id],
            [JobCode], [Nom], [Description],
            [HandlerType], [HandlerName], [HandlerParams],
            [TimeoutSeconds], [MaxRetries], [RetryDelayMin],
            [Actif], [Systeme], [CompanyGUID],
            [Created], [CreatedBy]
        )
        VALUES (
            @JobDefinitionId,
            @JobCode, @Nom, @Description,
            @HandlerType, @HandlerName, @HandlerParams,
            @TimeoutSeconds, @MaxRetries, @RetryDelayMin,
            @Actif, 0, @CompanyGUID,
            GETDATE(), @UserId
        );
    END
    -- ─── UPDATE ───
    ELSE
    BEGIN
        DECLARE @Systeme BIT;
        SELECT @Systeme = [Systeme] FROM [dbo].[T200JobDefinition] WHERE [Id] = @JobDefinitionId;

        IF @Systeme IS NULL
        BEGIN
            RAISERROR('Job introuvable (Id=%d).', 16, 1, @JobDefinitionId);
            RETURN;
        END

        IF @Systeme = 1
        BEGIN
            -- Job système : on autorise SEULEMENT Actif et HandlerParams
            UPDATE [dbo].[T200JobDefinition]
            SET [Actif]         = @Actif,
                [HandlerParams] = @HandlerParams,
                [TimeoutSeconds] = @TimeoutSeconds,
                [MaxRetries]    = @MaxRetries,
                [RetryDelayMin] = @RetryDelayMin,
                [Modified]      = GETDATE(),
                [ModifiedBy]    = @UserId
            WHERE [Id] = @JobDefinitionId;
        END
        ELSE
        BEGIN
            -- Job custom : full update
            UPDATE [dbo].[T200JobDefinition]
            SET [JobCode]       = @JobCode,
                [Nom]           = @Nom,
                [Description]   = @Description,
                [HandlerType]   = @HandlerType,
                [HandlerName]   = @HandlerName,
                [HandlerParams] = @HandlerParams,
                [TimeoutSeconds] = @TimeoutSeconds,
                [MaxRetries]    = @MaxRetries,
                [RetryDelayMin] = @RetryDelayMin,
                [Actif]         = @Actif,
                [Modified]      = GETDATE(),
                [ModifiedBy]    = @UserId
            WHERE [Id] = @JobDefinitionId;
        END
    END

    SELECT @JobDefinitionId AS JobDefinitionId;
END;

GO

PRINT N'T208_sp_SaveJobDefinition_id.sql : termine.';
GO
