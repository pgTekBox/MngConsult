-- =============================================================================
-- s0750GetJobExecutionContext
-- -----------------------------------------------------------------------------
-- Tout ce dont JobRunner.ashx (console d'administration) a besoin pour executer
-- une tache, a partir du seul identifiant d'execution.
--
-- Le service ne transmet que cet identifiant : les particularites de la tache se
-- lisent en base, la ou les ecrans d'administration les ecrivent. Rien ne
-- voyage en double, et modifier une tache dans la console suffit.
--
-- Les parametres effectifs viennent de l'execution (figes a la promotion), a
-- defaut de la definition : c'est ce qui permet de rejouer une execution telle
-- qu'elle a ete planifiee, meme si la definition a change depuis.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0750GetJobExecutionContext]
    @ExecutionId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.[Id]              AS ExecutionId,
        e.[JobDefinitionId],
        e.[JobScheduleId],
        e.[TentativeNumero],
        e.[TriggerType],
        e.[Statut],
        e.[CompanyGUID],
        dbo.fCompanyName(e.[CompanyGUID])                AS CompanyName,
        COALESCE(e.[ParamsUtilises], d.[HandlerParams])  AS HandlerParams,
        d.[JobCode],
        d.[Nom]             AS JobNom,
        d.[Description]     AS JobDescription,
        d.[HandlerType],
        d.[HandlerName],
        ISNULL(d.[TimeoutSeconds], 300)                  AS TimeoutSeconds
    FROM dbo.T202JobExecution e
    INNER JOIN dbo.T200JobDefinition d ON d.[Id] = e.[JobDefinitionId]
    WHERE e.[Id] = @ExecutionId;
END
GO

PRINT N'T209_JobRunner.sql : termine.';
GO
