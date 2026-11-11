-- =============================================================================
-- T372 — Activité à faire : la conciliation bancaire du mois
--
-- Nouveau type ACT_CONCILIATION (T200), inscrit dans T204JobPlanned par la
-- tâche planifiée SYNC_ACTIVITES (s0973, toutes les 30 minutes, toutes les
-- compagnies) comme les autres ACT_* : JobActif = 0, jamais exécutée, elle
-- reste « à faire » au tableau de bord jusqu'à ce que la période soit
-- conciliée et clôturée (T207ConciliationBancaire, T368), puis passe ANNULE.
--
-- Pour chaque compagnie qui a un compte bancaire actif avec un relevé :
--   période à concilier = le lendemain de la dernière conciliation clôturée
--                         jusqu'à la fin de ce mois-là (sinon le mois
--                         précédent quand rien n'a encore été clôturé) ;
--   inscrite dès que ce mois est terminé ; échéance = 10 jours après la fin
--   du mois (rouge au tableau de bord une fois dépassée).
--   Beneficiaire = « aaaa-mm-jj_aaaa-mm-jj » (la période, reprise par le
--   lien du tableau de bord vers wbfReleve?du=…&au=…) ;
--   Montant      = le nombre de lignes de la période encore à apparier.
--
-- s0973 est reprise de T362 avec ce sixième type.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.T200JobDefinition WHERE RTRIM([JobCode]) = 'ACT_CONCILIATION')
    INSERT INTO dbo.T200JobDefinition
        ([Id], [JobCode], [Nom], [Description], [HandlerType], [HandlerName],
         [TimeoutSeconds], [MaxRetries], [RetryDelayMin], [Actif], [Systeme],
         [CompanyGUID], [CategotyId], [RequiertApprobation])
    VALUES
        ((SELECT ISNULL(MAX([Id]), 0) + 1 FROM dbo.T200JobDefinition), 'ACT_CONCILIATION',
         'Activité : faire la conciliation bancaire',
         'Le mois terminé n''est pas encore concilié et clôturé (T207). Inscrite par SYNC_ACTIVITES, jamais exécutée.',
         'CUSTOM', 'ACTIVITE', 300, 0, 5, 1, 1, NULL, NULL, 0);

INSERT INTO dbo.T201JobSchedule ([JobDefinitionId], [Nom], [ScheduleType], [DateOnce], [Actif], [Pause], [CompanyGUID])
SELECT d.[Id], 'Activité inscrite par SYNC_ACTIVITES (aucune exécution)', 'ONCE', NULL, 0, 0, NULL
FROM dbo.T200JobDefinition d
WHERE RTRIM(d.[JobCode]) = 'ACT_CONCILIATION'
  AND NOT EXISTS (SELECT 1 FROM dbo.T201JobSchedule s WHERE s.[JobDefinitionId] = d.[Id]);
GO

CREATE OR ALTER PROCEDURE [dbo].[s0973SyncActivitesAFaire]
    @CompanyGUID UNIQUEIDENTIFIER = NULL     -- NULL = toutes les compagnies
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Maintenant DATETIME = GETDATE();
    DECLARE @Auj        DATE     = CAST(@Maintenant AS DATE);
    DECLARE @Horizon    DATE     = DATEADD(DAY, 7, @Auj);

    -- Les types d'activité et leur calendrier (clé étrangère obligatoire)
    DECLARE @Types TABLE (JobCode VARCHAR(50) PRIMARY KEY, JobDefinitionId INT, JobScheduleId INT);
    INSERT INTO @Types (JobCode, JobDefinitionId, JobScheduleId)
    SELECT RTRIM(d.[JobCode]), d.[Id],
           (SELECT TOP 1 s.[Id] FROM dbo.T201JobSchedule s WHERE s.[JobDefinitionId] = d.[Id] ORDER BY s.[Id])
    FROM dbo.T200JobDefinition d
    WHERE RTRIM(d.[JobCode]) IN ('ACT_FACT_CLIENT', 'ACT_FACT_FOURN', 'ACT_BROUILLON', 'ACT_BANQUE', 'ACT_ESSAI', 'ACT_CONCILIATION');

    IF (SELECT COUNT(*) FROM @Types WHERE JobScheduleId IS NOT NULL) < 6
        THROW 51010, 'Types d''activité ACT_* ou leurs calendriers manquants (scripts T362, T372).', 1;

    -- Ce qui est à faire maintenant
    DECLARE @Act TABLE (
        JobCode        VARCHAR(50),
        CompanyGUID    UNIQUEIDENTIFIER,
        DocumentId     INT NULL,
        DueDate        DATETIME NULL,
        Beneficiaire   VARCHAR(200) NULL,
        Montant        NUMERIC(18, 2) NULL,
        DejaRecu       NUMERIC(18, 2) NULL,
        StatutPaiement VARCHAR(200) NULL
    );

    -- Factures clients comptabilisées, non soldées, en retard ou dues dans 7 jours
    INSERT INTO @Act
    SELECT 'ACT_FACT_CLIENT', v.[CompanyGUID], v.[Id], v.[DueDate],
           LEFT(ISNULL(v.[NameRaw], ''), 200), v.[ResteAPayer], v.[DejaRecu], v.[StatutPaiement]
    FROM dbo.vwCustomersInvoices v
    WHERE (@CompanyGUID IS NULL OR v.[CompanyGUID] = @CompanyGUID)
      AND v.[ComptabilisationStatus] = 'COMPTABILISE'
      AND ISNULL(v.[ResteAPayer], 0) > 0.005
      AND ISNULL(v.[StatutPaiement], '') <> 'PAYEE'
      AND (v.[StatutPaiement] = 'EN_RETARD'
           OR (v.[DueDate] IS NOT NULL AND CAST(v.[DueDate] AS DATE) <= @Horizon));

    -- Factures clients en brouillon
    INSERT INTO @Act
    SELECT 'ACT_BROUILLON', v.[CompanyGUID], v.[Id], v.[DocumentDate],
           LEFT(ISNULL(v.[NameRaw], ''), 200), v.[Total], NULL, NULL
    FROM dbo.vwCustomersInvoices v
    WHERE (@CompanyGUID IS NULL OR v.[CompanyGUID] = @CompanyGUID)
      AND ISNULL(v.[ComptabilisationStatus], '') <> 'COMPTABILISE';

    -- Factures fournisseurs comptabilisées, non soldées, en retard ou dues dans 7 jours
    -- (même calcul du solde que s0023GetSuppliersInvoices)
    ;WITH Paye AS (
        SELECT rd.[DocumentId], SUM(rd.[MontantImpute]) AS DejaPaye
        FROM dbo.T141ReglementDocument rd
        INNER JOIN dbo.T140Reglement r ON r.[Id] = rd.[ReglementId]
        WHERE r.[Statut] <> 'ANNULE' AND r.[Sens] = 'DECAISSEMENT'
        GROUP BY rd.[DocumentId]
    )
    INSERT INTO @Act
    SELECT 'ACT_FACT_FOURN', d.[CompanyGUID], d.[Id], d.[DueDate],
           LEFT(ISNULL(d.[Name], ''), 200),
           CAST(ISNULL(d.[Total], 0) - ISNULL(p.DejaPaye, 0) AS NUMERIC(18, 2)),
           ISNULL(p.DejaPaye, 0),
           CASE WHEN ISNULL(p.DejaPaye, 0) > 0.005 THEN 'PARTIELLE' ELSE 'OUVERTE' END
    FROM dbo.T060Document d
    INNER JOIN dbo.T066DocumentStatus st ON st.[Id] = d.[StatusId]
    LEFT JOIN Paye p ON p.[DocumentId] = d.[Id]
    WHERE (@CompanyGUID IS NULL OR d.[CompanyGUID] = @CompanyGUID)
      AND d.[DocumentTypeId] IN (2, 5)
      AND d.[ComptabilisationStatus] = 'COMPTABILISE'
      AND ISNULL(d.[Total], 0) - ISNULL(p.DejaPaye, 0) > 0.005
      AND d.[DueDate] IS NOT NULL
      AND CAST(d.[DueDate] AS DATE) <= @Horizon;

    -- Compagnies sans compte bancaire actif
    INSERT INTO @Act (JobCode, CompanyGUID)
    SELECT 'ACT_BANQUE', c.[CompanyGUID]
    FROM dbo.T010Company c
    WHERE (@CompanyGUID IS NULL OR c.[CompanyGUID] = @CompanyGUID)
      AND NOT EXISTS (SELECT 1 FROM dbo.T143PlaidAccount a
                      WHERE a.[CompanyGUID] = c.[CompanyGUID] AND a.[Active] = 1);

    -- Essai gratuit qui se termine dans 30 jours ou moins (même lecture que s0687)
    INSERT INTO @Act (JobCode, CompanyGUID, DueDate, Beneficiaire)
    SELECT 'ACT_ESSAI', s.[CompanyGUID], s.[TrialEndOn], LEFT(ISNULL(CONVERT(VARCHAR(200), s.[PlanName]), ''), 200)
    FROM (
        SELECT [CompanyGUID], [TrialEndOn], [PlanName], [IsTrial],
               ROW_NUMBER() OVER (PARTITION BY [CompanyGUID] ORDER BY [CreatedOn] DESC) AS rn
        FROM dbo.T020Subscription
        WHERE [Status] = 'active' AND [IsDeleted] = 0
          AND (@CompanyGUID IS NULL OR [CompanyGUID] = @CompanyGUID)
    ) s
    WHERE s.rn = 1
      AND s.[IsTrial] = 1
      AND s.[TrialEndOn] IS NOT NULL
      AND DATEDIFF(DAY, @Auj, CAST(s.[TrialEndOn] AS DATE)) BETWEEN 0 AND 30;

    -- Conciliation bancaire du mois terminé (T368) : le premier compte actif avec un
    -- relevé ; la période suit la dernière conciliation clôturée, sinon le mois précédent.
    ;WITH Comptes AS (
        SELECT a.[CompanyGUID], a.[AccountId],
               ROW_NUMBER() OVER (PARTITION BY a.[CompanyGUID] ORDER BY a.[Id]) AS rn
        FROM dbo.T143PlaidAccount a
        WHERE a.[Active] = 1
          AND (@CompanyGUID IS NULL OR a.[CompanyGUID] = @CompanyGUID)
          AND EXISTS (SELECT 1 FROM dbo.T142ReleveBancaire x
                      WHERE x.[CompanyGUID] = a.[CompanyGUID] AND x.[CompteBanque] = a.[AccountId])
    ), Periodes AS (
        SELECT c.[CompanyGUID], c.[AccountId],
               CASE WHEN v.Verrou IS NULL THEN DATEADD(DAY, 1, EOMONTH(@Auj, -2))
                    ELSE DATEADD(DAY, 1, v.Verrou) END AS Debut
        FROM Comptes c
        CROSS APPLY (SELECT dbo.fConciliationVerrou(c.[CompanyGUID], c.[AccountId]) AS Verrou) v
        WHERE c.rn = 1
    )
    INSERT INTO @Act (JobCode, CompanyGUID, DueDate, Beneficiaire, Montant)
    SELECT 'ACT_CONCILIATION', p.[CompanyGUID],
           DATEADD(DAY, 10, CAST(EOMONTH(p.Debut) AS DATETIME)),
           CONVERT(VARCHAR(10), p.Debut, 23) + '_' + CONVERT(VARCHAR(10), EOMONTH(p.Debut), 23),
           (SELECT COUNT(*) FROM dbo.T142ReleveBancaire x
            WHERE x.[CompanyGUID] = p.[CompanyGUID] AND x.[CompteBanque] = p.[AccountId]
              AND x.[DateMouvement] BETWEEN p.Debut AND EOMONTH(p.Debut)
              AND x.[Statut] NOT IN ('Ignoré', 'Ignore')
              AND ABS(x.[Montant]) - dbo.fReleveRelie(x.[Id]) > 0.005)
    FROM Periodes p
    WHERE EOMONTH(p.Debut) <= EOMONTH(@Auj, -1);

    -- Inscription : une ligne par (type, compagnie, document). Une activité qui
    -- revient (facture de nouveau en retard…) reprend sa ligne et repasse PLANIFIE.
    DECLARE @Bilan TABLE (Action NVARCHAR(10));

    BEGIN TRANSACTION;

    ;WITH tgt AS (
        SELECT p.*
        FROM dbo.T204JobPlanned p
        WHERE p.[JobDefinitionId] IN (SELECT JobDefinitionId FROM @Types)
          AND (@CompanyGUID IS NULL OR p.[CompanyGUID] = @CompanyGUID)
    ),
    src AS (
        SELECT t.JobDefinitionId, t.JobScheduleId, a.*
        FROM @Act a
        INNER JOIN @Types t ON t.JobCode = a.JobCode
    )
    MERGE tgt AS target
    USING src
       ON target.[JobDefinitionId] = src.JobDefinitionId
      AND target.[CompanyGUID]     = src.CompanyGUID
      AND ISNULL(target.[DocumentId], 0) = ISNULL(src.DocumentId, 0)
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([JobDefinitionId], [JobScheduleId], [DateExecutionPrevue], [DueDate],
                [ScheduleActif], [SchedulePause], [JobActif], [Statut], [GenereLe],
                [CompanyGUID], [Beneficiaire], [DejaRecu], [Montant], [DocumentId], [StatutPaiement])
        VALUES (src.JobDefinitionId, src.JobScheduleId, ISNULL(src.DueDate, @Maintenant), src.DueDate,
                0, 0, 0, 'PLANIFIE', @Maintenant,
                src.CompanyGUID, src.Beneficiaire, src.DejaRecu, src.Montant, src.DocumentId, src.StatutPaiement)
    WHEN MATCHED THEN
        UPDATE SET
            target.[DateExecutionPrevue] = ISNULL(src.DueDate, target.[DateExecutionPrevue]),
            target.[DueDate]             = src.DueDate,
            target.[Beneficiaire]        = src.Beneficiaire,
            target.[DejaRecu]            = src.DejaRecu,
            target.[Montant]             = src.Montant,
            target.[StatutPaiement]      = src.StatutPaiement,
            target.[JobActif]            = 0,
            target.[ScheduleActif]       = 0,
            target.[Statut]              = 'PLANIFIE',
            target.[GenereLe]            = @Maintenant
    WHEN NOT MATCHED BY SOURCE AND target.[Statut] = 'PLANIFIE' THEN
        UPDATE SET
            target.[Statut] = 'ANNULE',
            target.[Notes]  = LEFT(ISNULL(target.[Notes] + ' | ', '') + 'Réglée le ' + CONVERT(VARCHAR(19), @Maintenant, 120), 500)
    OUTPUT $action INTO @Bilan;

    COMMIT TRANSACTION;

    SELECT
        SUM(CASE WHEN Action = 'INSERT' THEN 1 ELSE 0 END) AS Inscrites,
        SUM(CASE WHEN Action = 'UPDATE' THEN 1 ELSE 0 END) AS MisesAJourOuReglees,
        (SELECT COUNT(*) FROM @Act)                        AS AFaire
    FROM @Bilan;
END
GO
