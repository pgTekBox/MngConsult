-- =============================================================================
-- Tache « courriel de test toutes les 10 minutes »
-- -----------------------------------------------------------------------------
-- Verifie de bout en bout la chaine de l'executeur : calendrier -> planning ->
-- execution -> contexte de compagnie -> file d'envoi. Le nom de la compagnie
-- dans le message est justement ce qui prouve que le contexte a suivi.
--
-- Passe par sp_SaveJobDefinition et sp_SaveJobSchedule, c'est-a-dire par les
-- memes procedures que les ecrans de la console d'administration : ce que ce
-- script cree se modifie ensuite normalement dans « Taches ».
--
-- Pour arreter les envois : decocher Actif sur la definition ou sur le
-- calendrier, ou mettre le calendrier en pause.
--
-- Prerequis : T208_sp_SaveJobDefinition_id.sql (sans lui l'insertion echoue).
-- Re-executable : la tache est reconnue par son code et mise a jour.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- Ce qu'on peut vouloir changer
-- -----------------------------------------------------------------------------
DECLARE @JobCode      VARCHAR(50)      = 'TEST_COURRIEL';
DECLARE @Destinataire VARCHAR(300)     = 'pierre.girouard@cronus.ca';
DECLARE @Minutes      INT              = 10;

-- La compagnie dont le nom apparaitra dans le courriel.
DECLARE @CompanyGUID  UNIQUEIDENTIFIER = 'D89EB638-6B05-443D-B1C9-01A6316443BF';  -- INFORMATIQUE MG

-- Template = TEST : c'est ce mot que clsTaskExecutor reconnait pour choisir le
-- modele de courriel. Destinataires accepte plusieurs adresses.
DECLARE @Params NVARCHAR(MAX) =
    N'{"Template": "TEST", "Destinataires": ["' + @Destinataire + N'"]}';

-- -----------------------------------------------------------------------------
-- 1) La definition de tache
-- -----------------------------------------------------------------------------
DECLARE @JobId INT = ISNULL((SELECT [Id] FROM dbo.T200JobDefinition WHERE [JobCode] = @JobCode), 0);

DECLARE @Retour TABLE (JobDefinitionId INT);
INSERT INTO @Retour
EXEC dbo.sp_SaveJobDefinition
     @JobDefinitionId = @JobId,
     @JobCode         = @JobCode,
     @Nom             = N'Courriel de test',
     @Description     = N'Envoie un courriel de verification portant le nom de la compagnie. Sert a confirmer que l''executeur de taches tourne.',
     @HandlerType     = 'EMAIL',
     @HandlerName     = 'TEST',
     @HandlerParams   = @Params,
     @TimeoutSeconds  = 120,
     @MaxRetries      = 0,
     @RetryDelayMin   = 5,
     @Actif           = 1,
     @CompanyGUID     = @CompanyGUID;

SELECT @JobId = JobDefinitionId FROM @Retour;

-- Le courriel de test doit partir tout seul : pas d'approbation.
UPDATE dbo.T200JobDefinition SET [RequiertApprobation] = 0 WHERE [Id] = @JobId;

-- -----------------------------------------------------------------------------
-- 2) Le calendrier : toutes les @Minutes minutes, sans date de fin
-- -----------------------------------------------------------------------------
DECLARE @SchedId INT = ISNULL((SELECT TOP 1 [Id] FROM dbo.T201JobSchedule
                                WHERE [JobDefinitionId] = @JobId ORDER BY [Id]), 0);

EXEC dbo.sp_SaveJobSchedule
     @ScheduleId      = @SchedId,
     @JobDefinitionId = @JobId,
     @Nom             = N'Toutes les 10 minutes',
     @ScheduleType    = 'INTERVAL',
     @IntervalMinutes = @Minutes,
     @DateDebut       = NULL,
     @DateFin         = NULL,
     @HandlerParams   = @Params,
     @Actif           = 1,
     @Pause           = 0,
     @CompanyGUID     = @CompanyGUID;

-- -----------------------------------------------------------------------------
-- 3) Premiere generation du planning
--    Ensuite c'est ServiceExecuteur qui regarnit (PlanningRefreshMinutes).
-- -----------------------------------------------------------------------------
EXEC dbo.sp_GenererPlanningJobs @CompanyGUID = @CompanyGUID;
GO

-- -----------------------------------------------------------------------------
-- Ce qui a ete cree
-- -----------------------------------------------------------------------------
SELECT
    d.[Id]                AS JobDefinitionId,
    d.[JobCode],
    d.[Nom],
    d.[HandlerType] + ' / ' + d.[HandlerName] AS Handler,
    d.[HandlerParams],
    d.[Actif],
    s.[Id]                AS ScheduleId,
    s.[ScheduleType],
    s.[IntervalMinutes],
    dbo.fCompanyName(s.[CompanyGUID]) AS Compagnie,
    (SELECT COUNT(*) FROM dbo.T204JobPlanned p
      WHERE p.[JobScheduleId] = s.[Id] AND p.[Statut] = 'PLANIFIE') AS OccurrencesEnAttente,
    (SELECT MIN(p.[DateExecutionPrevue]) FROM dbo.T204JobPlanned p
      WHERE p.[JobScheduleId] = s.[Id] AND p.[Statut] = 'PLANIFIE') AS Prochaine
FROM dbo.T200JobDefinition d
LEFT JOIN dbo.T201JobSchedule s ON s.[JobDefinitionId] = d.[Id]
WHERE d.[JobCode] = 'TEST_COURRIEL';
GO
