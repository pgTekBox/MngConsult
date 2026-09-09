-- =============================================================================
-- ServiceExecuteur — ce qu'il faut en base pour exécuter les tâches
-- -----------------------------------------------------------------------------
-- Les écrans de tâches existaient déjà (console d'administration) et le
-- planificateur aussi (sp_GenererPlanningJobs remplit T204JobPlanned). Ce qui
-- manquait : quelqu'un pour exécuter.
--
-- sp_LancerJobMaintenant se contente d'inscrire une exécution EN_COURS dans
-- T202JobExecution et attend un worker — d'où l'exécution restée en cours
-- depuis le 28 avril. ServiceExecuteur est ce worker.
--
-- Ce script ajoute :
--   1. l'approbation : un drapeau sur la définition de tâche, un état sur
--      chaque occurrence planifiée. C'est la « boîte de messages » que
--      l'utilisateur valide depuis l'ERP ;
--   2. les procédures dont le service a besoin (s0738 à s0747).
--
-- Ré-exécutable : chaque objet est créé seulement s'il manque.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1) La définition de tâche dit si ses occurrences doivent être approuvées.
--    Défaut 0 : les tâches existantes gardent leur comportement, rien ne se met
--    à demander une validation du jour au lendemain.
-- -----------------------------------------------------------------------------
IF COL_LENGTH('dbo.T200JobDefinition', 'RequiertApprobation') IS NULL
    ALTER TABLE dbo.T200JobDefinition ADD RequiertApprobation BIT NOT NULL CONSTRAINT DF_T200_RequiertApprobation DEFAULT (0);
GO

-- -----------------------------------------------------------------------------
-- 2) L'occurrence planifiée porte son état d'approbation.
--
--    NON_REQUISE  la tâche s'exécute sans demander l'avis de personne
--    A_APPROUVER  elle attend dans la boîte de messages
--    APPROUVE     un utilisateur a dit oui : l'exécuteur peut la prendre
--    REFUSE       un utilisateur a dit non : elle ne s'exécutera pas
-- -----------------------------------------------------------------------------
IF COL_LENGTH('dbo.T204JobPlanned', 'Approbation') IS NULL
    ALTER TABLE dbo.T204JobPlanned ADD Approbation VARCHAR(20) NOT NULL CONSTRAINT DF_T204_Approbation DEFAULT ('NON_REQUISE');
GO
IF COL_LENGTH('dbo.T204JobPlanned', 'ApprouvePar') IS NULL
    ALTER TABLE dbo.T204JobPlanned ADD ApprouvePar INT NULL;
GO
IF COL_LENGTH('dbo.T204JobPlanned', 'ApprouveLe') IS NULL
    ALTER TABLE dbo.T204JobPlanned ADD ApprouveLe DATETIME2(0) NULL;
GO
IF COL_LENGTH('dbo.T204JobPlanned', 'MotifDecision') IS NULL
    ALTER TABLE dbo.T204JobPlanned ADD MotifDecision VARCHAR(500) NULL;
GO
-- Verrou d'exclusion : empêche deux exécuteurs de prendre la même occurrence.
IF COL_LENGTH('dbo.T204JobPlanned', 'SvcLockedUntilUtc') IS NULL
    ALTER TABLE dbo.T204JobPlanned ADD SvcLockedUntilUtc DATETIME2(0) NULL;
GO

-- Même verrou sur l'exécution : c'est elle que le worker prend en charge.
IF COL_LENGTH('dbo.T202JobExecution', 'SvcLockedUntilUtc') IS NULL
    ALTER TABLE dbo.T202JobExecution ADD SvcLockedUntilUtc DATETIME2(0) NULL;
GO

-- -----------------------------------------------------------------------------
-- 3) s0738PromouvoirPlanningEchu
--    Transforme les occurrences arrivées à échéance en exécutions à faire.
--    Une occurrence qui attend une approbation n'est pas promue.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0738PromouvoirPlanningEchu]
    @Maintenant DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Maintenant IS NULL SET @Maintenant = GETDATE();

    DECLARE @promues TABLE (PlannedId INT PRIMARY KEY);
    DECLARE @map     TABLE (PlannedId INT, ExecutionId INT);

    ;WITH candidates AS (
        SELECT p.[Id],
               p.[Statut],
               p.[PrisEnChargeLe],
               -- Une seule occurrence par définition et par passage : le retard
               -- se rattrape occurrence après occurrence, jamais en parallèle.
               ROW_NUMBER() OVER (PARTITION BY p.[JobDefinitionId]
                                      ORDER BY p.[DateExecutionPrevue] ASC, p.[Id] ASC) AS rn
        FROM dbo.T204JobPlanned p WITH (UPDLOCK, READPAST, ROWLOCK)
        INNER JOIN dbo.T200JobDefinition d ON d.[Id] = p.[JobDefinitionId]
        WHERE p.[Statut] = 'PLANIFIE'
          AND p.[DateExecutionPrevue] <= @Maintenant
          AND p.[JobActif] = 1
          AND p.[ScheduleActif] = 1
          AND ISNULL(p.[SchedulePause], 0) = 0
          AND d.[Actif] = 1
          AND p.[Approbation] IN ('NON_REQUISE', 'APPROUVE')
          -- Jamais deux exécutions simultanées pour la même définition.
          AND NOT EXISTS (SELECT 1 FROM dbo.T202JobExecution e
                           WHERE e.[JobDefinitionId] = p.[JobDefinitionId] AND e.[Statut] = 'EN_COURS')
    )
    UPDATE candidates
       SET [Statut] = 'PRIS_EN_CHARGE',
           [PrisEnChargeLe] = @Maintenant
    OUTPUT inserted.[Id] INTO @promues(PlannedId)
     WHERE rn = 1;

    -- Une exécution par occurrence promue. MERGE plutôt qu'INSERT : c'est la
    -- seule forme qui laisse sortir, sur la même ligne, l'occurrence source et
    -- l'identifiant de l'exécution créée pour elle.
    MERGE INTO dbo.T202JobExecution AS tgt
    USING (
        SELECT p.[Id] AS PlannedId, p.[JobDefinitionId], p.[JobScheduleId],
               p.[HandlerParams], p.[CompanyGUID]
        FROM dbo.T204JobPlanned p
        INNER JOIN @promues x ON x.PlannedId = p.[Id]
    ) AS src
       ON (1 = 0)                          -- jamais de correspondance : on insère toujours
    WHEN NOT MATCHED THEN
        INSERT ([JobDefinitionId], [JobScheduleId], [Demarre], [TriggerType], [Statut],
                [TentativeNumero], [ParamsUtilises], [CompanyGUID], [LanceePar])
        VALUES (src.[JobDefinitionId], src.[JobScheduleId], @Maintenant, 'SCHEDULE', 'EN_COURS',
                1, src.[HandlerParams], src.[CompanyGUID], NULL)
    OUTPUT src.PlannedId, inserted.[Id] INTO @map(PlannedId, ExecutionId);

    -- Rattache l'exécution à son occurrence (l'écran de suivi s'en sert).
    UPDATE p
       SET p.[ExecutionId] = m.ExecutionId
      FROM dbo.T204JobPlanned p
     INNER JOIN @map m ON m.PlannedId = p.[Id];

    SELECT COUNT(*) AS Promues FROM @map;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0739ClaimNextExecution
--    Réserve la prochaine exécution à faire et renvoie tout ce dont le service
--    a besoin pour la lancer. Rien à faire = aucune ligne.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0739ClaimNextExecution]
    @LockSeconds INT          = 900,
    @WorkerName  VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @claimed TABLE (Id INT);

    ;WITH nxt AS (
        SELECT TOP (1) e.*
        FROM dbo.T202JobExecution e WITH (UPDLOCK, READPAST, ROWLOCK)
        WHERE e.[Statut] = 'EN_COURS'
          AND (e.[SvcLockedUntilUtc] IS NULL OR e.[SvcLockedUntilUtc] <= SYSUTCDATETIME())
        ORDER BY e.[Demarre] ASC, e.[Id] ASC   -- la plus ancienne d'abord
    )
    UPDATE nxt
       SET [SvcLockedUntilUtc] = DATEADD(SECOND, @LockSeconds, SYSUTCDATETIME()),
           [WorkerName]        = ISNULL(@WorkerName, [WorkerName]),
           [Demarre]           = ISNULL([Demarre], GETDATE())
    OUTPUT inserted.[Id] INTO @claimed(Id);

    SELECT
        e.[Id]              AS ExecutionId,
        e.[JobDefinitionId],
        e.[JobScheduleId],
        e.[TentativeNumero],
        e.[CompanyGUID],
        e.[TriggerType],
        COALESCE(e.[ParamsUtilises], d.[HandlerParams]) AS HandlerParams,
        d.[JobCode],
        d.[Nom]             AS JobNom,
        d.[HandlerType],
        d.[HandlerName],
        ISNULL(d.[TimeoutSeconds], 300)  AS TimeoutSeconds,
        ISNULL(d.[MaxRetries], 0)        AS MaxRetries,
        ISNULL(d.[RetryDelayMin], 5)     AS RetryDelayMin
    FROM dbo.T202JobExecution e
    INNER JOIN @claimed c ON c.Id = e.[Id]
    INNER JOIN dbo.T200JobDefinition d ON d.[Id] = e.[JobDefinitionId];
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0740SaveExecutionResult — issue d'une exécution
--    @Statut : SUCCES | ECHEC | TIMEOUT
--    Une occurrence rattachée suit le même sort.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0740SaveExecutionResult]
    @ExecutionId      INT,
    @Statut           VARCHAR(20),
    @ResultatMessage  VARCHAR(2000) = NULL,
    @ResultatDetail   NVARCHAR(MAX) = NULL,
    @LignesTraitees   INT           = NULL,
    @DureeMs          INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T202JobExecution
       SET [Statut]            = @Statut,
           [Termine]           = GETDATE(),
           [DureeMs]           = @DureeMs,
           [ResultatMessage]   = LEFT(ISNULL(@ResultatMessage, ''), 2000),
           [ResultatDetail]    = @ResultatDetail,
           [LignesTraitees]    = @LignesTraitees,
           [SvcLockedUntilUtc] = NULL
     WHERE [Id] = @ExecutionId;

    -- L'occurrence reste PRIS_EN_CHARGE : chk_T204_Statut n'admet que PLANIFIE,
    -- PRIS_EN_CHARGE, ANNULE et EXPIRE. Le sort de la tache se lit sur
    -- l'execution pointee par ExecutionId, pas sur l'occurrence.
    UPDATE dbo.T204JobPlanned
       SET [SvcLockedUntilUtc] = NULL
     WHERE [ExecutionId] = @ExecutionId;

    -- La prochaine échéance du calendrier avance avec l'exécution.
    UPDATE s
       SET s.[DerniereExec] = GETDATE()
      FROM dbo.T201JobSchedule s
     INNER JOIN dbo.T202JobExecution e ON e.[JobScheduleId] = s.[Id]
     WHERE e.[Id] = @ExecutionId;
END
GO

-- -----------------------------------------------------------------------------
-- 6) s0741LogExecution — une ligne de journal
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0741LogExecution]
    @JobExecutionId INT,
    @Niveau         VARCHAR(20),
    @Message        VARCHAR(MAX),
    @Detail         NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.T203JobLog ([JobExecutionId], [Horodatage], [Niveau], [Message], [Detail])
    VALUES (@JobExecutionId, SYSDATETIME(), @Niveau, @Message, @Detail);
END
GO

-- -----------------------------------------------------------------------------
-- 7) s0742MarquerAApprouver
--    Fait passer en attente d'approbation les occurrences dont la définition
--    l'exige. Appelée par le service à chaque tour : une occurrence créée par
--    le planificateur après coup est ainsi rattrapée.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0742MarquerAApprouver]
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
       SET p.[Approbation] = 'A_APPROUVER'
      FROM dbo.T204JobPlanned p
     INNER JOIN dbo.T200JobDefinition d ON d.[Id] = p.[JobDefinitionId]
     WHERE p.[Statut] = 'PLANIFIE'
       AND p.[Approbation] = 'NON_REQUISE'
       AND d.[RequiertApprobation] = 1;

    SELECT @@ROWCOUNT AS Marquees;
END
GO

-- -----------------------------------------------------------------------------
-- 8) s0743GetApprobations — la boîte de messages de l'ERP
--    Cadrée sur la compagnie ; @Etat filtre l'onglet affiché.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0743GetApprobations]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Etat        VARCHAR(20) = 'A_APPROUVER',   -- ou TOUTES
    @Top         INT = 200
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        p.[Id]                                   AS PlannedId,
        p.[DateExecutionPrevue],
        p.[Approbation],
        CASE p.[Approbation]
             WHEN 'A_APPROUVER' THEN N'À approuver'
             WHEN 'APPROUVE'    THEN N'Approuvée'
             WHEN 'REFUSE'      THEN N'Refusée'
             ELSE                    N'Automatique' END   AS EtatLisible,
        p.[Statut]                               AS StatutPlanning,
        d.[Id]                                   AS JobDefinitionId,
        d.[JobCode],
        d.[Nom]                                  AS JobNom,
        d.[Description]                          AS JobDescription,
        d.[HandlerType],
        d.[HandlerName],
        c.[Name]                                 AS Categorie,
        p.[Beneficiaire],
        p.[Montant],
        p.[DueDate],
        p.[DocumentId],
        p.[Notes],
        p.[ApprouvePar],
        p.[ApprouveLe],
        p.[MotifDecision],
        u.[Email]                                AS ApprouveParEmail,
        -- En retard : l'échéance est passée et personne n'a tranché.
        CASE WHEN p.[Approbation] = 'A_APPROUVER' AND p.[DateExecutionPrevue] < GETDATE()
             THEN 1 ELSE 0 END                   AS EnRetard
    FROM dbo.T204JobPlanned p
    INNER JOIN dbo.T200JobDefinition d ON d.[Id] = p.[JobDefinitionId]
    LEFT  JOIN dbo.T205JobCategories c ON c.[Id] = d.[CategotyId]
    LEFT  JOIN dbo.T015User u          ON u.[Id] = p.[ApprouvePar]
    WHERE p.[CompanyGUID] = @CompanyGUID
      AND (@Etat = 'TOUTES' OR p.[Approbation] = @Etat)
      AND p.[Statut] IN ('PLANIFIE', 'PRIS_EN_CHARGE', 'ANNULE', 'EXPIRE')
    ORDER BY
        CASE WHEN p.[Approbation] = 'A_APPROUVER' THEN 0 ELSE 1 END,
        p.[DateExecutionPrevue] ASC, p.[Id] ASC;
END
GO

-- -----------------------------------------------------------------------------
-- 9) s0744DeciderApprobation — l'utilisateur tranche
--    @Decision : APPROUVE | REFUSE
--    Un refus annule l'occurrence : elle ne sera jamais promue.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0744DeciderApprobation]
    @PlannedId   INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @Decision    VARCHAR(20),
    @UserId      INT,
    @Motif       VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Decision NOT IN ('APPROUVE', 'REFUSE')
        THROW 50201, 'Décision inconnue : attendu APPROUVE ou REFUSE.', 1;

    -- On ne tranche que ce qui attend, et seulement dans sa propre compagnie.
    IF NOT EXISTS (SELECT 1 FROM dbo.T204JobPlanned
                    WHERE [Id] = @PlannedId
                      AND [CompanyGUID] = @CompanyGUID
                      AND [Approbation] = 'A_APPROUVER'
                      AND [Statut] = 'PLANIFIE')
        THROW 50202, 'Cette tâche n''attend plus de décision.', 1;

    UPDATE dbo.T204JobPlanned
       SET [Approbation]   = @Decision,
           [ApprouvePar]   = @UserId,
           -- GETDATE() et non SYSUTCDATETIME() : tout le reste du planning est en
           -- heure locale, une decision horodatee en UTC s'afficherait decalee.
           [ApprouveLe]    = GETDATE(),
           [MotifDecision] = @Motif,
           -- Un refus sort l'occurrence du planning ; une approbation l'y laisse
           -- pour que l'exécuteur la prenne à l'heure prévue.
           [Statut]        = CASE WHEN @Decision = 'REFUSE' THEN 'ANNULE' ELSE [Statut] END
     WHERE [Id] = @PlannedId;
END
GO

-- -----------------------------------------------------------------------------
-- 10) s0745GetApprobationsCount — le compteur du menu
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0745GetApprobationsCount]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- COALESCE : sans occurrence du tout, SUM rend NULL et la pastille du menu
    -- afficherait du vide au lieu d'un zéro.
    SELECT
        COALESCE(SUM(CASE WHEN p.[Approbation] = 'A_APPROUVER' THEN 1 ELSE 0 END), 0)       AS AApprouver,
        COALESCE(SUM(CASE WHEN p.[Approbation] = 'A_APPROUVER'
                           AND p.[DateExecutionPrevue] < GETDATE() THEN 1 ELSE 0 END), 0)   AS EnRetard
    FROM dbo.T204JobPlanned p
    WHERE p.[CompanyGUID] = @CompanyGUID
      AND p.[Statut] = 'PLANIFIE';
END
GO

-- -----------------------------------------------------------------------------
-- 11) s0746GetFacturesEnRetard
--     Alimente le gestionnaire de rappels : les factures clients non payées
--     dont l'échéance tombe dans la fenêtre demandée.
--       @JoursAvant  0 = pas de rappel préventif ; 3 = trois jours avant
--       @JoursApres  jusqu'à combien de jours après l'échéance on relance
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0746GetFacturesEnRetard]
    @CompanyGUID UNIQUEIDENTIFIER,
    @JoursAvant  INT = 0,
    @JoursApres  INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Aujourdhui DATE = CAST(GETDATE() AS DATE);

    ;WITH Regle AS (
        SELECT rd.[DocumentId], SUM(rd.[MontantImpute]) AS DejaRecu
        FROM dbo.T141ReglementDocument rd
        INNER JOIN dbo.T140Reglement r ON r.[Id] = rd.[ReglementId]
        WHERE r.[Statut] <> 'ANNULE' AND r.[Sens] = 'ENCAISSEMENT'
        GROUP BY rd.[DocumentId]
    )
    SELECT
        d.[Id]                                                        AS DocumentId,
        d.[DocumentNumber],
        d.[Name]                                                      AS Client,
        d.[Email],
        d.[DocumentDate],
        d.[DueDate],
        d.[Total],
        ISNULL(g.DejaRecu, 0)                                         AS DejaRecu,
        CAST(ISNULL(d.[Total], 0) - ISNULL(g.DejaRecu, 0) AS DECIMAL(15,2)) AS Solde,
        DATEDIFF(DAY, d.[DueDate], @Aujourdhui)                       AS JoursDeRetard
    FROM dbo.T060Document d
    LEFT JOIN Regle g ON g.[DocumentId] = d.[Id]
    WHERE d.[CompanyGUID] = @CompanyGUID
      AND d.[DocumentTypeId] = 1                       -- facture client
      AND d.[ComptabilisationStatus] = 'COMPTABILISE'  -- un brouillon ne se relance pas
      AND d.[DueDate] IS NOT NULL
      AND ISNULL(d.[Email], '') <> ''
      AND ISNULL(d.[Total], 0) - ISNULL(g.DejaRecu, 0) > 0.005
      AND d.[DueDate] <= DATEADD(DAY, @JoursAvant, @Aujourdhui)
      AND d.[DueDate] >= DATEADD(DAY, -@JoursApres, @Aujourdhui)
    ORDER BY d.[DueDate] ASC, d.[Id] ASC;
END
GO

-- -----------------------------------------------------------------------------
-- 12) s0747GetExecutionsEnCours — ce que l'interface du service affiche
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0747GetExecutionsEnCours]
    @Top INT = 200
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        e.[Id]              AS ExecutionId,
        e.[Demarre],
        e.[Termine],
        e.[DureeMs],
        e.[Statut],
        e.[TriggerType],
        e.[TentativeNumero],
        e.[WorkerName],
        e.[ResultatMessage],
        e.[LignesTraitees],
        d.[JobCode],
        d.[Nom]             AS JobNom,
        d.[HandlerType],
        d.[HandlerName],
        CASE WHEN e.[SvcLockedUntilUtc] > SYSUTCDATETIME() THEN 1 ELSE 0 END AS Reservee
    FROM dbo.T202JobExecution e
    INNER JOIN dbo.T200JobDefinition d ON d.[Id] = e.[JobDefinitionId]
    ORDER BY e.[Id] DESC;
END
GO

-- -----------------------------------------------------------------------------
-- 13) s0748GetCompanyMailInfo
--     Identité de la compagnie pour la mise en forme d'un courriel envoyé en
--     son nom : le nom affiché, et l'adresse de réponse vérifiée.
--
--     Le From reste celui du service : SrvAI envoie en direct-to-MX depuis
--     notre IP, un From au domaine du client échouerait son SPF. C'est le
--     Reply-To qui porte l'adresse de la compagnie, et seulement vérifiée
--     (même règle que s0694GetCompanyReplyTo, dont la logique est reprise ici
--     pour éviter un deuxième aller-retour depuis le service).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0748GetCompanyMailInfo]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentEmail VARCHAR(300) = dbo.fParamS(@CompanyGUID, 'MAIL_FROM_EMAIL');

    SELECT
        dbo.fCompanyName(@CompanyGUID) AS CompanyName,
        CASE WHEN c.[MailVerifiedOn] IS NOT NULL
              AND @CurrentEmail IS NOT NULL
              AND LTRIM(RTRIM(@CurrentEmail)) <> ''
              AND c.[MailVerifiedAddress] = @CurrentEmail
             THEN @CurrentEmail
        END AS ReplyTo
    FROM dbo.T010Company c
    WHERE c.[CompanyGUID] = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 14) s0749GetApprobationsCountGlobal
--     Le compteur affiché par l'interface du service, toutes compagnies
--     confondues : le service n'appartient à aucune d'elles.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0749GetApprobationsCountGlobal]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        COALESCE(SUM(CASE WHEN p.[Approbation] = 'A_APPROUVER' THEN 1 ELSE 0 END), 0)       AS AApprouver,
        COALESCE(SUM(CASE WHEN p.[Approbation] = 'A_APPROUVER'
                           AND p.[DateExecutionPrevue] < GETDATE() THEN 1 ELSE 0 END), 0)   AS EnRetard
    FROM dbo.T204JobPlanned p
    WHERE p.[Statut] = 'PLANIFIE';
END
GO

PRINT N'T206_Approbation_et_executeur.sql : termine.';
GO
