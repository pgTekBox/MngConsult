-- =============================================================================
-- T316 — L'extraction QuickBooks donne signe de vie pendant une ressource
--
-- La fenêtre de suivi comptait les ressources lues : 39 sur 44, 89 %, puis
-- plus rien pendant que la ressource « Pièces jointes » interroge QuickBooks
-- document par document — sept cents appels, rien d'écrit avant la fin. Et
-- une extraction que le redémarrage du serveur a tuée restait à 89 % jusqu'à
-- la règle des trente minutes.
--
-- L'extraction signe désormais à chaque ressource et à chaque lot de
-- documents (s0898SignerConnecteurRun : staging.ConnecteurRun.Signe, Progression).
-- s0895GetConnecteurRun rend cette progression à l'écran, et juge une
-- extraction interrompue après dix minutes sans signe — ressource lue, signe
-- ou début — au lieu de trente : les signes sont fréquents, un appel HTTP
-- dure deux minutes au plus.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('staging.ConnecteurRun', 'Signe') IS NULL
    ALTER TABLE staging.ConnecteurRun ADD [Signe] DATETIME NULL;
GO
IF COL_LENGTH('staging.ConnecteurRun', 'Progression') IS NULL
    ALTER TABLE staging.ConnecteurRun ADD [Progression] NVARCHAR(300) NULL;
GO
-- La sous-progression en chiffres : la jauge avance DANS la ressource (le
-- document N sur M), au lieu de rester à 89 % un quart d'heure.
IF COL_LENGTH('staging.ConnecteurRun', 'SousFait') IS NULL
    ALTER TABLE staging.ConnecteurRun ADD [SousFait] INT NULL, [SousTotal] INT NULL;
GO

-- -----------------------------------------------------------------------------
-- s0898SignerConnecteurRun — un signe de vie : l'heure, et où en est la lecture.
-- Ne touche qu'une extraction EN_COURS de la compagnie.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0898SignerConnecteurRun]
    @RunId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @Progression NVARCHAR(300) = NULL,
    @Fait        INT = NULL,
    @Total       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE staging.ConnecteurRun
       SET [Signe] = GETDATE(),
           [Progression] = @Progression,
           [SousFait]    = @Fait,
           [SousTotal]   = @Total
     WHERE [Id] = @RunId
       AND [CompanyGUID] = @CompanyGUID
       AND [Statut] = 'EN_COURS';
END
GO

-- -----------------------------------------------------------------------------
-- s0895GetConnecteurRun — une extraction de la compagnie (la dernière si
-- @RunId est nul), puis l'issue de chaque ressource. Rend la progression, et
-- juge « INTERROMPUE » une extraction EN_COURS sans signe depuis dix minutes.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0895GetConnecteurRun]
    @CompanyGUID UNIQUEIDENTIFIER,
    @RunId       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Id INT = (SELECT TOP 1 r.[Id]
                         FROM staging.ConnecteurRun r
                        WHERE r.[CompanyGUID] = @CompanyGUID
                          AND (@RunId IS NULL OR r.[Id] = @RunId)
                        ORDER BY r.[Debut] DESC, r.[Id] DESC);

    SELECT r.[Id], r.[Service],
           -- Le dernier signe de vie : une ressource lue, un signe pendant la
           -- ressource, ou le début. Dix minutes sans rien : le serveur a
           -- redémarré, personne ne la fermera. On le dit.
           CASE WHEN r.[Statut] = 'EN_COURS'
                 AND (SELECT MAX(v.[Quand]) FROM (
                          SELECT r.[Debut] AS [Quand]
                          UNION ALL SELECT r.[Signe]
                          UNION ALL SELECT MAX(x.[Quand]) FROM staging.ConnecteurRessource x WHERE x.[RunId] = r.[Id]
                      ) v) < DATEADD(MINUTE, -10, GETDATE())
                THEN 'INTERROMPUE' ELSE r.[Statut] END AS [Statut],
           r.[Debut], r.[Fin],
           r.[NbRessources], r.[NbEnregistrements], r.[NbDemandees], r.[NbEchecs], r.[Note],
           r.[Signe], r.[Progression], r.[SousFait], r.[SousTotal]
      FROM staging.ConnecteurRun r
     WHERE r.[Id] = @Id;

    SELECT x.[Ressource], x.[Nb], x.[Reussie], x.[Erreur], x.[Quand]
      FROM staging.ConnecteurRessource x
     WHERE x.[RunId] = @Id
     ORDER BY x.[Id];
END
GO

-- -----------------------------------------------------------------------------
-- s0776OuvrirConnecteurRun — la même règle à l'ouverture : solde les extractions
-- EN_COURS sans signe depuis dix minutes avant d'en ouvrir une nouvelle.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0776OuvrirConnecteurRun]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Connecteur  VARCHAR(20),
    @Service     VARCHAR(40),
    @ConsumerId  NVARCHAR(100) = NULL,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @CompanyGUID IS NULL
        THROW 50361, 'Aucune compagnie : impossible d''ouvrir une extraction.', 1;

    UPDATE r
       SET [Statut] = 'INTERROMPUE',
           [Fin]    = GETDATE(),
           [Note]   = N'Extraction abandonnée : le serveur s''est arrêté avant la fin.'
      FROM staging.ConnecteurRun r
     WHERE r.[CompanyGUID] = @CompanyGUID
       AND r.[Statut] = 'EN_COURS'
       AND (SELECT MAX(v.[Quand]) FROM (
                SELECT r.[Debut] AS [Quand]
                UNION ALL SELECT r.[Signe]
                UNION ALL SELECT MAX(x.[Quand]) FROM staging.ConnecteurRessource x WHERE x.[RunId] = r.[Id]
            ) v) < DATEADD(MINUTE, -10, GETDATE());

    INSERT INTO staging.ConnecteurRun ([CompanyGUID], [Connecteur], [Service], [ConsumerId], [CreatedBy])
    VALUES (@CompanyGUID, @Connecteur, @Service, @ConsumerId, @UserId);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS RunId;
END
GO
