-- =============================================================================
-- T310 — L'extraction QuickBooks tourne en arrière-plan, l'écran la suit
--
-- Une extraction complète — quarante-quatre ressources, des dizaines de
-- milliers d'enregistrements — ne tient pas dans une requête : le navigateur
-- abandonnait, et l'extraction restait « EN_COURS » pour toujours. Elle part
-- désormais sur un fil de fond, et l'écran lit son avancement par
-- s0895GetConnecteurRun : l'extraction elle-même, puis l'issue de chaque
-- ressource au fur et à mesure (staging.ConnecteurRessource, T309).
--
-- Une extraction qu'un redémarrage du serveur a tuée ne se ferme jamais
-- d'elle-même : à l'ouverture de la suivante, celles qui sont « EN_COURS »
-- sans signe de vie depuis trente minutes sont marquées INTERROMPUE, pour ne pas bloquer
-- la compagnie ni mentir sur l'écran.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- s0776OuvrirConnecteurRun — ouvre une extraction (et solde celles qui
-- ont été abandonnées).
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

    UPDATE staging.ConnecteurRun
       SET [Statut] = 'INTERROMPUE',
           [Fin]    = GETDATE(),
           [Note]   = N'Extraction abandonnée : le serveur s''est arrêté avant la fin.'
     WHERE [CompanyGUID] = @CompanyGUID
       AND [Statut] = 'EN_COURS'
       AND ISNULL((SELECT MAX(x.[Quand]) FROM staging.ConnecteurRessource x WHERE x.[RunId] = staging.ConnecteurRun.[Id]), [Debut])
           < DATEADD(MINUTE, -30, GETDATE());

    INSERT INTO staging.ConnecteurRun ([CompanyGUID], [Connecteur], [Service], [ConsumerId], [CreatedBy])
    VALUES (@CompanyGUID, @Connecteur, @Service, @ConsumerId, @UserId);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS RunId;
END
GO

-- -----------------------------------------------------------------------------
-- s0895GetConnecteurRun — une extraction de la compagnie (la dernière si
-- @RunId est vide) et l'issue de chacune de ses ressources, dans l'ordre où
-- elles ont été lues. Deux jeux de résultats. Rien si la compagnie n'a
-- jamais extrait, ou si l'extraction demandée n'est pas la sienne.
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
           -- Une extraction sans signe de vie depuis trente minutes est morte :
           -- le serveur a redémarré, et personne ne la fermera. On le dit.
           CASE WHEN r.[Statut] = 'EN_COURS'
                 AND ISNULL((SELECT MAX(x.[Quand]) FROM staging.ConnecteurRessource x WHERE x.[RunId] = r.[Id]), r.[Debut])
                     < DATEADD(MINUTE, -30, GETDATE())
                THEN 'INTERROMPUE' ELSE r.[Statut] END AS [Statut],
           r.[Debut], r.[Fin],
           r.[NbRessources], r.[NbEnregistrements], r.[NbDemandees], r.[NbEchecs], r.[Note]
      FROM staging.ConnecteurRun r
     WHERE r.[Id] = @Id;

    SELECT x.[Ressource], x.[Nb], x.[Reussie], x.[Erreur], x.[Quand]
      FROM staging.ConnecteurRessource x
     WHERE x.[RunId] = @Id
     ORDER BY x.[Id];
END
GO
