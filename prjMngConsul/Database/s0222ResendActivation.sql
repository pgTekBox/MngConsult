-- =============================================================================
-- s0222ResendActivation
-- Régénère un token d'activation pour un user non encore activé.
--
-- RATE LIMITING : refuse de générer un nouveau token si le dernier a été
-- créé il y a moins de 60 secondes. Retourne NewToken=NULL dans ce cas.
-- Le code-behind (wbfRegister.aspx.vb) affiche un message à l'utilisateur.
--
-- Détection du rate limit : la valeur de ActivationExpires est toujours
-- égale à NOW+24h après chaque reset. Si DATEDIFF(SECOND, NOW, ActivationExpires)
-- > 86340 (24h - 60s), c'est que le dernier reset date de < 60 secondes.
--
-- ATTENTION : cette proc REMPLACE la version existante en BD (qui n'avait
-- pas de rate limiting). À déployer avec confirmation explicite.
--
-- Base de données cible : MngConsul (PAS MailService)
-- Utilisé par : wbfRegister.aspx.vb (lnkResend_Click)
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0222ResendActivation', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0222ResendActivation;
GO

CREATE PROCEDURE dbo.s0222ResendActivation
    @Email NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewToken UNIQUEIDENTIFIER;
    DECLARE @UserId   INT;

    SET @NewToken = NULL;
    SET @UserId   = 0;

    DECLARE @LocalId               INT;
    DECLARE @LocalActivatedOn      DATETIME;
    DECLARE @LocalActivationExpires DATETIME;

    SELECT TOP 1
        @LocalId                = Id,
        @LocalActivatedOn       = ActivatedOn,
        @LocalActivationExpires = ActivationExpires
    FROM dbo.T015User
    WHERE Email = @Email
      AND IsDeleted = 0;

    -- Compte introuvable ou déjà activé : retour silencieux
    IF @LocalId IS NULL OR @LocalActivatedOn IS NOT NULL
        RETURN;

    -- RATE LIMIT : si le dernier reset date de < 60 sec, refuser
    -- (ActivationExpires = NOW+24h après chaque reset, donc > 86340 sec
    --  de différence avec NOW = reset il y a < 60 sec)
    IF @LocalActivationExpires IS NOT NULL
       AND DATEDIFF(SECOND, GETDATE(), @LocalActivationExpires) > 86340
    BEGIN
        -- Rate limited : retourne quand même une ligne avec NewToken=NULL
        -- pour que le code-behind puisse différencier "rate limit"
        -- d'une erreur SQL
        SELECT
            CAST(NULL AS UNIQUEIDENTIFIER) AS NewToken,
            @LocalId AS UserId;
        RETURN;
    END

    -- Génération nouveau token + extension expiration
    SET @NewToken = NEWID();
    SET @UserId   = @LocalId;

    UPDATE dbo.T015User
    SET ActivationToken   = @NewToken,
        ActivationExpires = DATEADD(HOUR, 24, GETDATE()),
        ModifiedOn        = GETDATE()
    WHERE Id = @LocalId;

    SELECT
        @NewToken AS NewToken,
        @UserId   AS UserId;
END
GO
