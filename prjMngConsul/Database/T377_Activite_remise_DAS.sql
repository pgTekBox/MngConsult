-- =============================================================================
-- T377 — Activité : remise des retenues à la source (DAS)
--
-- Selon la fréquence de remise du paramètre SAL_REMISE_FREQ (onglet Salaires,
-- T376), règles de Revenu Québec et de l'ARC :
--   MENSUELLE     (remettant régulier)  : le mois civil, dû le 15 du mois suivant
--   TRIMESTRIELLE (remettant trimestriel): le trimestre civil, dû le 15 du mois
--                                          qui suit le trimestre
--   BIMENSUELLE   (accéléré, seuil 1)   : du 1er au 15, dû le 25 du même mois ;
--                                          du 16 à la fin, dû le 10 du mois suivant
--   HEBDOMADAIRE  (accéléré, seuil 2)   : du 1er au 7, du 8 au 14, du 15 au 21,
--                                          du 22 à la fin ; dû 3 jours ouvrables après
--
-- fPeriodeDAS(@CompanyGUID, @Date) : la période de remise qui contient @Date.
-- T209RemiseDAS : les remises faites (marquées depuis le tableau de bord).
-- s0996MarquerRemiseDAS : marque une période terminée comme remise.
-- ACT_DAS : la tâche SYNC_ACTIVITES (s0973) inscrit, pour chaque compagnie qui
-- a des employés actifs (T300Employees), la plus ancienne période terminée non
-- remise dont la date limite date de moins de 20 jours (pas de rappel pour un
-- passé lointain) ; échéance = date limite. Elle disparaît une fois marquée.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T209RemiseDAS') IS NULL
CREATE TABLE dbo.T209RemiseDAS (
    Id           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T209RemiseDAS PRIMARY KEY,
    CompanyGUID  UNIQUEIDENTIFIER NOT NULL,
    Frequence    VARCHAR(20) NOT NULL,
    DebutPeriode DATE NOT NULL,
    FinPeriode   DATE NOT NULL,
    DateLimite   DATE NOT NULL,
    RemiseLe     DATE NOT NULL,
    Montant      DECIMAL(15, 2) NULL,
    Reference    VARCHAR(100) NULL,
    Created      DATETIME NOT NULL CONSTRAINT DF_T209_Created DEFAULT (GETDATE()),
    CreatedBy    INT NULL
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_T209_Periode')
    CREATE UNIQUE INDEX UX_T209_Periode ON dbo.T209RemiseDAS (CompanyGUID, DebutPeriode, FinPeriode);
GO

-- ── La période de remise qui contient une date ─────────────────────────────
CREATE OR ALTER FUNCTION dbo.fPeriodeDAS (@CompanyGUID UNIQUEIDENTIFIER, @Date DATE)
RETURNS @P TABLE (Frequence VARCHAR(20), DebutPeriode DATE, FinPeriode DATE, DateLimite DATE)
AS
BEGIN
    DECLARE @Freq VARCHAR(20) = (SELECT TOP 1 v.[sVal]
                                 FROM dbo.T100ParamComptable p
                                 JOIN dbo.T101ParamValues v ON v.[T100Id] = p.[Id]
                                 WHERE p.[ShortName] = 'SAL_REMISE_FREQ' AND v.[CompanyGUID] = @CompanyGUID
                                 ORDER BY CASE WHEN p.[CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END);
    IF @Freq IS NULL OR @Freq NOT IN ('MENSUELLE', 'TRIMESTRIELLE', 'BIMENSUELLE', 'HEBDOMADAIRE') SET @Freq = 'MENSUELLE';

    DECLARE @Y INT = YEAR(@Date), @M INT = MONTH(@Date), @J INT = DAY(@Date);
    DECLARE @Debut DATE, @Fin DATE, @Limite DATE;

    IF @Freq = 'MENSUELLE'
    BEGIN
        SET @Debut = DATEFROMPARTS(@Y, @M, 1);
        SET @Fin = EOMONTH(@Debut);
        SET @Limite = DATEADD(DAY, 14, DATEADD(DAY, 1, @Fin));                 -- le 15 du mois suivant
    END
    ELSE IF @Freq = 'TRIMESTRIELLE'
    BEGIN
        SET @Debut = DATEFROMPARTS(@Y, ((@M - 1) / 3) * 3 + 1, 1);
        SET @Fin = EOMONTH(DATEADD(MONTH, 2, @Debut));
        SET @Limite = DATEADD(DAY, 14, DATEADD(DAY, 1, @Fin));                 -- le 15 du mois suivant
    END
    ELSE IF @Freq = 'BIMENSUELLE'
    BEGIN
        IF @J <= 15
        BEGIN
            SET @Debut = DATEFROMPARTS(@Y, @M, 1); SET @Fin = DATEFROMPARTS(@Y, @M, 15);
            SET @Limite = DATEFROMPARTS(@Y, @M, 25);                           -- le 25 du même mois
        END
        ELSE
        BEGIN
            SET @Debut = DATEFROMPARTS(@Y, @M, 16); SET @Fin = EOMONTH(@Debut);
            SET @Limite = DATEADD(DAY, 9, DATEADD(DAY, 1, @Fin));              -- le 10 du mois suivant
        END
    END
    ELSE  -- HEBDOMADAIRE : 1-7, 8-14, 15-21, 22-fin ; 3 jours ouvrables après
    BEGIN
        DECLARE @Bloc INT = CASE WHEN @J <= 7 THEN 1 WHEN @J <= 14 THEN 8 WHEN @J <= 21 THEN 15 ELSE 22 END;
        SET @Debut = DATEFROMPARTS(@Y, @M, @Bloc);
        SET @Fin = CASE WHEN @Bloc = 22 THEN EOMONTH(@Debut) ELSE DATEADD(DAY, 6, @Debut) END;
        SET @Limite = @Fin;
        DECLARE @n INT = 0;
        WHILE @n < 3
        BEGIN
            SET @Limite = DATEADD(DAY, 1, @Limite);
            -- 1900-01-01 était un lundi : 5 = samedi, 6 = dimanche
            IF DATEDIFF(DAY, '19000101', @Limite) % 7 < 5 SET @n = @n + 1;
        END
    END

    INSERT INTO @P VALUES (@Freq, @Debut, @Fin, @Limite);
    RETURN;
END
GO

-- ── Marquer une période comme remise ───────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0996MarquerRemiseDAS
    @CompanyGUID UNIQUEIDENTIFIER,
    @DebutPeriode DATE,
    @Montant     DECIMAL(15, 2) = NULL,
    @Reference   VARCHAR(100) = NULL,
    @RemiseLe    DATE = NULL,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Freq VARCHAR(20), @Debut DATE, @Fin DATE, @Limite DATE;
    SELECT @Freq = Frequence, @Debut = DebutPeriode, @Fin = FinPeriode, @Limite = DateLimite
    FROM dbo.fPeriodeDAS(@CompanyGUID, @DebutPeriode);

    IF @Debut <> @DebutPeriode THROW 51110, 'Cette date ne commence pas une période de remise.', 1;
    IF @Fin >= CAST(GETDATE() AS DATE) THROW 51111, 'La période n''est pas terminée.', 1;
    IF EXISTS (SELECT 1 FROM dbo.T209RemiseDAS WHERE CompanyGUID = @CompanyGUID AND DebutPeriode = @Debut AND FinPeriode = @Fin)
        THROW 51112, 'Cette remise est déjà notée.', 1;

    INSERT INTO dbo.T209RemiseDAS (CompanyGUID, Frequence, DebutPeriode, FinPeriode, DateLimite, RemiseLe, Montant, Reference, CreatedBy)
    VALUES (@CompanyGUID, @Freq, @Debut, @Fin, @Limite, ISNULL(@RemiseLe, CAST(GETDATE() AS DATE)),
            @Montant, NULLIF(LTRIM(RTRIM(ISNULL(@Reference, ''))), ''), @UserId);

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- ── Le type d'activité ACT_DAS ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM dbo.T200JobDefinition WHERE RTRIM([JobCode]) = 'ACT_DAS')
    INSERT INTO dbo.T200JobDefinition
        ([Id], [JobCode], [Nom], [Description], [HandlerType], [HandlerName],
         [TimeoutSeconds], [MaxRetries], [RetryDelayMin], [Actif], [Systeme],
         [CompanyGUID], [CategotyId], [RequiertApprobation])
    VALUES
        ((SELECT ISNULL(MAX([Id]), 0) + 1 FROM dbo.T200JobDefinition), 'ACT_DAS',
         'Activité : remettre les retenues à la source',
         'Une période de remise des DAS est terminée et pas encore marquée remise (T209). Inscrite par SYNC_ACTIVITES, jamais exécutée.',
         'CUSTOM', 'ACTIVITE', 300, 0, 5, 1, 1, NULL, NULL, 0);

INSERT INTO dbo.T201JobSchedule ([JobDefinitionId], [Nom], [ScheduleType], [DateOnce], [Actif], [Pause], [CompanyGUID])
SELECT d.[Id], 'Activité inscrite par SYNC_ACTIVITES (aucune exécution)', 'ONCE', NULL, 0, 0, NULL
FROM dbo.T200JobDefinition d
WHERE RTRIM(d.[JobCode]) = 'ACT_DAS'
  AND NOT EXISTS (SELECT 1 FROM dbo.T201JobSchedule s WHERE s.[JobDefinitionId] = d.[Id]);
GO

-- s0973 reprise de T375 avec le huitième type ACT_DAS
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
    WHERE RTRIM(d.[JobCode]) IN ('ACT_FACT_CLIENT', 'ACT_FACT_FOURN', 'ACT_BROUILLON', 'ACT_BANQUE', 'ACT_ESSAI', 'ACT_CONCILIATION', 'ACT_TAXES', 'ACT_DAS');

    IF (SELECT COUNT(*) FROM @Types WHERE JobScheduleId IS NOT NULL) < 8
        THROW 51010, 'Types d''activité ACT_* ou leurs calendriers manquants (scripts T362, T372, T375, T377).', 1;

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

    -- Déclaration de taxes à produire (T375) : la plus ancienne période terminée
    -- (24 derniers mois, périodes de l'exercice selon TAX_FREQ) qui a des écritures de
    -- taxes et dont le rapport n'est ni finalisé ni remis. Échéance = date limite.
    ;WITH Mois AS (
        SELECT DISTINCT e.[CompanyGUID], DATEFROMPARTS(YEAR(e.[DateEcriture]), MONTH(e.[DateEcriture]), 1) AS Mois
        FROM dbo.T135Ecritures e
        INNER JOIN dbo.T136LignesEcriture l ON l.[EcrituresId] = e.[Id]
        INNER JOIN dbo.T121PlanComptable c ON c.[Id] = l.[PlanComptableId]
        WHERE e.[Statut] = 'VALIDEE'
          AND (@CompanyGUID IS NULL OR e.[CompanyGUID] = @CompanyGUID)
          AND c.[Compte] IN ('2200', '2210', '1450', '1460')
          AND e.[DateEcriture] >= DATEADD(MONTH, -24, @Auj) AND e.[DateEcriture] < @Auj
    ), Periodes AS (
        SELECT DISTINCT m.[CompanyGUID], p.[DebutPeriode], p.[FinPeriode], p.[DateLimite]
        FROM Mois m
        CROSS APPLY dbo.fPeriodeTaxe(m.[CompanyGUID], m.Mois) p
        WHERE p.[FinPeriode] < @Auj
    ), AFaire AS (
        SELECT p.*, r.[Id] AS RapportId,
               ISNULL(r.[TPS_Nette], 0) + ISNULL(r.[CTI_Ajustement], 0) + ISNULL(r.[TVQ_Nette], 0) + ISNULL(r.[RTI_Ajustement], 0) AS Total,
               ROW_NUMBER() OVER (PARTITION BY p.[CompanyGUID] ORDER BY p.[DebutPeriode]) AS rn
        FROM Periodes p
        LEFT JOIN dbo.T070RapportTaxe r
               ON r.[CompanyGUID] = p.[CompanyGUID] AND r.[DebutPeriode] = p.[DebutPeriode] AND r.[FinPeriode] = p.[FinPeriode]
        WHERE ISNULL(r.[Statut], 'BROUILLON') NOT IN ('FINALISE', 'PAYE')
    )
    INSERT INTO @Act (JobCode, CompanyGUID, DueDate, Beneficiaire, Montant)
    SELECT 'ACT_TAXES', a.[CompanyGUID], CAST(a.[DateLimite] AS DATETIME),
           CONVERT(VARCHAR(10), a.[DebutPeriode], 23) + '_' + CONVERT(VARCHAR(10), a.[FinPeriode], 23),
           CASE WHEN a.RapportId IS NULL THEN NULL ELSE a.Total END
    FROM AFaire a
    WHERE a.rn = 1;

    -- Remise des retenues à la source (T377) : compagnies avec employés actifs ; la plus
    -- ancienne période terminée non remise (T209) dont la date limite date de moins de
    -- 20 jours. Périodes selon SAL_REMISE_FREQ (fPeriodeDAS). Échéance = date limite.
    ;WITH Jours AS (
        SELECT TOP (100) DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), @Auj) AS Jour
        FROM sys.all_objects
    ), Employeurs AS (
        SELECT DISTINCT e.[CompanyGUID]
        FROM dbo.T300Employees e
        WHERE e.[CompanyGUID] IS NOT NULL AND ISNULL(e.[Active], 0) = 1
          AND (@CompanyGUID IS NULL OR e.[CompanyGUID] = @CompanyGUID)
    ), PeriodesDAS AS (
        SELECT DISTINCT c.[CompanyGUID], p.[DebutPeriode], p.[FinPeriode], p.[DateLimite]
        FROM Employeurs c
        CROSS JOIN Jours j
        CROSS APPLY dbo.fPeriodeDAS(c.[CompanyGUID], j.Jour) p
        WHERE p.[FinPeriode] < @Auj
          AND p.[DateLimite] >= DATEADD(DAY, -20, @Auj)
    ), DASAFaire AS (
        SELECT p.*, ROW_NUMBER() OVER (PARTITION BY p.[CompanyGUID] ORDER BY p.[DebutPeriode]) AS rn
        FROM PeriodesDAS p
        WHERE NOT EXISTS (SELECT 1 FROM dbo.T209RemiseDAS r
                          WHERE r.[CompanyGUID] = p.[CompanyGUID] AND r.[DebutPeriode] = p.[DebutPeriode] AND r.[FinPeriode] = p.[FinPeriode])
    )
    INSERT INTO @Act (JobCode, CompanyGUID, DueDate, Beneficiaire)
    SELECT 'ACT_DAS', d.[CompanyGUID], CAST(d.[DateLimite] AS DATETIME),
           CONVERT(VARCHAR(10), d.[DebutPeriode], 23) + '_' + CONVERT(VARCHAR(10), d.[FinPeriode], 23)
    FROM DASAFaire d
    WHERE d.rn = 1;

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
