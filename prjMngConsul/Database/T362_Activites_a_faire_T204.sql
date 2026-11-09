-- =============================================================================
-- T362_Activites_a_faire_T204
--
-- Les « Activités à faire » du tableau de bord (Default.aspx) proviennent
-- désormais TOUTES de la table des tâches planifiées T204JobPlanned.
--
--   1. Cinq types d'activité dans T200JobDefinition (codes ACT_*), chacun avec
--      un calendrier T201 inerte (ONCE sans date, inactif) qui ne sert qu'à
--      satisfaire la clé étrangère FK_T204_JobSchedule :
--        ACT_FACT_CLIENT  facture client en retard ou due dans 7 jours
--        ACT_FACT_FOURN   facture fournisseur en retard ou due dans 7 jours
--        ACT_BROUILLON    facture client en brouillon
--        ACT_BANQUE       aucun compte bancaire branché
--        ACT_ESSAI        fin de l'essai gratuit dans 30 jours ou moins
--      Les lignes T204 de ces types sont inscrites avec JobActif = 0 : le
--      service exécuteur (s0738PromouvoirPlanningEchu) ne les prend jamais en
--      charge, elles restent « à faire » jusqu'à ce que la situation soit réglée.
--
--   2. La tâche SYNC_ACTIVITES (type SP → s0973SyncActivitesAFaire), lancée par
--      le service exécuteur toutes les 30 minutes pour toutes les compagnies :
--      elle inscrit les nouvelles activités, rafraîchit les autres et passe en
--      ANNULE celles qui sont réglées (facture payée, banque branchée…).
--
--   3. s0974GetActivitesAFaire : la lecture du tableau de bord (activités ACT_*
--      + occurrences en attente d'approbation, toutes PLANIFIE dans T204).
--
--   4. Correctifs pour que les générateurs existants ne touchent pas aux
--      activités :
--        sp_GenererPlanningJobs     n'expire plus les lignes ACT_* échues ;
--        sp_GenererPlanningFactures ne traite plus que ses propres lignes
--                                   (job INVOICE_REMINDER) : avant, il annulait
--                                   toute ligne PLANIFIE portant un DocumentId
--                                   absent de vwCustomersInvoices.
--
--   5. Première synchronisation pour toutes les compagnies.
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1) Les types d'activité et la tâche de synchronisation (T200), idempotent
-- -----------------------------------------------------------------------------
DECLARE @Defs TABLE (JobCode VARCHAR(50), Nom VARCHAR(200), Descr VARCHAR(500),
                     HandlerType VARCHAR(20), HandlerName VARCHAR(200), Systeme BIT);
INSERT INTO @Defs VALUES
 ('ACT_FACT_CLIENT', 'Activité : facture client à relancer',
  'Facture client comptabilisée, non soldée, en retard ou due dans les 7 jours. Inscrite par SYNC_ACTIVITES, jamais exécutée.',
  'CUSTOM', 'ACTIVITE', 1),
 ('ACT_FACT_FOURN', 'Activité : facture fournisseur à payer',
  'Facture fournisseur comptabilisée, non soldée, en retard ou due dans les 7 jours. Inscrite par SYNC_ACTIVITES, jamais exécutée.',
  'CUSTOM', 'ACTIVITE', 1),
 ('ACT_BROUILLON', 'Activité : brouillon de vente à finaliser',
  'Facture client encore en brouillon. Inscrite par SYNC_ACTIVITES, jamais exécutée.',
  'CUSTOM', 'ACTIVITE', 1),
 ('ACT_BANQUE', 'Activité : brancher un compte bancaire',
  'Aucun compte bancaire actif (T143PlaidAccount). Inscrite par SYNC_ACTIVITES, jamais exécutée.',
  'CUSTOM', 'ACTIVITE', 1),
 ('ACT_ESSAI', 'Activité : fin de l''essai gratuit',
  'L''essai gratuit se termine dans 30 jours ou moins. Inscrite par SYNC_ACTIVITES, jamais exécutée.',
  'CUSTOM', 'ACTIVITE', 1),
 ('SYNC_ACTIVITES', 'Inscription des activités à faire',
  'Inscrit dans T204JobPlanned les activités à faire du tableau de bord (ACT_*) pour toutes les compagnies, rafraîchit les autres et annule celles qui sont réglées.',
  'SP', 's0973SyncActivitesAFaire', 1);

DECLARE @Id INT = (SELECT ISNULL(MAX([Id]), 0) FROM dbo.T200JobDefinition);
DECLARE @Code VARCHAR(50), @Nom VARCHAR(200), @Descr VARCHAR(500), @HT VARCHAR(20), @HN VARCHAR(200), @Sys BIT;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT JobCode, Nom, Descr, HandlerType, HandlerName, Systeme FROM @Defs;
OPEN c;
FETCH NEXT FROM c INTO @Code, @Nom, @Descr, @HT, @HN, @Sys;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.T200JobDefinition WHERE RTRIM([JobCode]) = @Code)
    BEGIN
        SET @Id = @Id + 1;
        INSERT INTO dbo.T200JobDefinition
            ([Id], [JobCode], [Nom], [Description], [HandlerType], [HandlerName],
             [TimeoutSeconds], [MaxRetries], [RetryDelayMin], [Actif], [Systeme],
             [CompanyGUID], [CategotyId], [RequiertApprobation])
        VALUES
            (@Id, @Code, @Nom, @Descr, @HT, @HN,
             300, 0, 5, 1, @Sys,
             NULL, NULL, 0);
    END
    FETCH NEXT FROM c INTO @Code, @Nom, @Descr, @HT, @HN, @Sys;
END
CLOSE c; DEALLOCATE c;

-- -----------------------------------------------------------------------------
-- 1b) Les calendriers (T201)
--     ACT_* : un calendrier inerte (ONCE sans date, inactif) : sp_GenererPlanningJobs
--             n'en tire aucune occurrence, il ne sert qu'à la clé étrangère.
--     SYNC_ACTIVITES : toutes les 30 minutes, toutes compagnies (CompanyGUID NULL :
--             la procédure reçoit @CompanyGUID = NULL et traite tout le monde).
-- -----------------------------------------------------------------------------
INSERT INTO dbo.T201JobSchedule ([JobDefinitionId], [Nom], [ScheduleType], [DateOnce], [Actif], [Pause], [CompanyGUID])
SELECT d.[Id], 'Activité inscrite par SYNC_ACTIVITES (aucune exécution)', 'ONCE', NULL, 0, 0, NULL
FROM dbo.T200JobDefinition d
WHERE RTRIM(d.[JobCode]) LIKE 'ACT[_]%'
  AND NOT EXISTS (SELECT 1 FROM dbo.T201JobSchedule s WHERE s.[JobDefinitionId] = d.[Id]);

INSERT INTO dbo.T201JobSchedule ([JobDefinitionId], [Nom], [ScheduleType], [IntervalMinutes], [DateDebut], [Actif], [Pause], [CompanyGUID])
SELECT d.[Id], 'Toutes les 30 minutes', 'INTERVAL', 30, CAST(GETDATE() AS DATE), 1, 0, NULL
FROM dbo.T200JobDefinition d
WHERE RTRIM(d.[JobCode]) = 'SYNC_ACTIVITES'
  AND NOT EXISTS (SELECT 1 FROM dbo.T201JobSchedule s WHERE s.[JobDefinitionId] = d.[Id]);
GO

-- -----------------------------------------------------------------------------
-- 2) s0973SyncActivitesAFaire — inscrit / rafraîchit / annule les activités
-- -----------------------------------------------------------------------------
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
    WHERE RTRIM(d.[JobCode]) IN ('ACT_FACT_CLIENT', 'ACT_FACT_FOURN', 'ACT_BROUILLON', 'ACT_BANQUE', 'ACT_ESSAI');

    IF (SELECT COUNT(*) FROM @Types WHERE JobScheduleId IS NOT NULL) < 5
        THROW 51010, 'Types d''activité ACT_* ou leurs calendriers manquants (script T362).', 1;

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

-- -----------------------------------------------------------------------------
-- 3) s0974GetActivitesAFaire — la lecture du tableau de bord
--    Les colonnes NameSort / NumeroSort / ResteAPayer gardent les noms de
--    s0023/s0026 : les aides du tableau de bord (NumFacture, Noms) s'en servent.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0974GetActivitesAFaire]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.[Id],
        RTRIM(d.[JobCode])  AS JobCode,
        p.[DocumentId],
        doc.[DocumentNumber] AS NumeroSort,
        p.[Beneficiaire]     AS NameSort,
        p.[Montant]          AS ResteAPayer,
        p.[DueDate],
        p.[StatutPaiement],
        p.[Approbation],
        p.[DateExecutionPrevue]
    FROM dbo.T204JobPlanned p
    INNER JOIN dbo.T200JobDefinition d ON d.[Id] = p.[JobDefinitionId]
    LEFT JOIN dbo.T060Document doc ON doc.[Id] = p.[DocumentId]
    WHERE p.[CompanyGUID] = @CompanyGUID
      AND p.[Statut] = 'PLANIFIE'
      AND (RTRIM(d.[JobCode]) LIKE 'ACT[_]%' OR p.[Approbation] = 'A_APPROUVER')
    ORDER BY p.[DueDate], p.[Id];
END
GO

-- -----------------------------------------------------------------------------
-- 4a) sp_GenererPlanningJobs : n'expire plus les activités ACT_*
-- -----------------------------------------------------------------------------
-- ============================================================================
-- sp_GenererPlanningJobs - VERSION CORRIGÉE
--
-- Corrections vs version précédente :
--   1. Prise en compte de IntervalleMois (mensuel/trimestriel/semestriel/annuel)
--   2. Toutes les variables sont déclarées en haut (bonnes pratiques T-SQL)
--   3. @JoursTable est nettoyée AU DÉBUT du bloc WEEKLY (pas à la fin)
--   4. Borne haute MONTHLY étendue : MoisAnticipation × max(IntervalleMois)
-- ============================================================================

CREATE OR ALTER PROCEDURE [dbo].[sp_GenererPlanningJobs]
    @CompanyGUID       UNIQUEIDENTIFIER = NULL,
    @MoisAnticipation  INT = 3,
    @InclureInactifs   BIT = 1,
    @LimiteParSchedule INT = 500
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- ════════════════════════════════════════════════════════════════
    -- DÉCLARATIONS — toutes en haut pour respecter le hoisting T-SQL
    -- ════════════════════════════════════════════════════════════════
    DECLARE @Maintenant DATETIME = GETDATE();
    DECLARE @Borne      DATETIME = DATEADD(MONTH, @MoisAnticipation, @Maintenant);
    DECLARE @NbLignesAvant INT = (SELECT COUNT(*) FROM [dbo].[T204JobPlanned] WHERE [Statut] = 'PLANIFIE');

    DECLARE @Planning TABLE (
        JobDefinitionId      INT,
        JobScheduleId        INT,
        DateExecutionPrevue  DATETIME,
        HandlerParams        NVARCHAR(MAX),
        ScheduleActif        BIT,
        SchedulePause        BIT,
        JobActif             BIT,
        CompanyGUID          UNIQUEIDENTIFIER
    );

    DECLARE @JoursTable TABLE (Jour INT);

    -- Variables du curseur
    DECLARE
        @SchedId        INT,
        @JobDefId       INT,
        @SchedType      VARCHAR(20),
        @IntervalMin    INT,
        @HeureExec      TIME,
        @JoursSemaine   VARCHAR(20),
        @JourMois       INT,
        @IntervalleMois INT,                    -- ← NOUVEAU
        @CronExpr       VARCHAR(100),
        @DateOnce       DATETIME,
        @DateDebut      DATE,
        @DateFin        DATE,
        @SchedParams    NVARCHAR(MAX),
        @JobParams      NVARCHAR(MAX),
        @SchedActif     BIT,
        @SchedPause     BIT,
        @JobActif       BIT,
        @SchedProchaine DATETIME,
        @SchedCompany   UNIQUEIDENTIFIER;

    -- Variables de calcul (réinitialisées à chaque itération)
    DECLARE
        @ParamsEffectifs NVARCHAR(MAX),
        @BorneDebut      DATETIME,
        @BorneFin        DATETIME,
        @CurrentDate     DATETIME,
        @CompteurInt     INT,
        @JourCourant     DATE,
        @PremiereCetteJour DATETIME,
        @CompteurDaily   INT,
        @ExecDaily       DATETIME,
        @JourW           DATE,
        @CompteurWeekly  INT,
        @ExecW           DATETIME,
        @JourISO         INT,
        @MoisIdx         INT,
        @CompteurMonth   INT,
        @PremJour        DATE,
        @DerJour         INT,
        @JourEffectif    INT,
        @ExecMonth       DATETIME,
        @MoisLookahead   INT;                    -- ← NOUVEAU pour MONTHLY étendu

    -- ════════════════════════════════════════════════════════════════
    -- CURSEUR avec lecture de IntervalleMois
    -- ════════════════════════════════════════════════════════════════
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            s.[Id], s.[JobDefinitionId], s.[ScheduleType],
            s.[IntervalMinutes], s.[HeureExecution], s.[JoursSemaine],
            s.[JourMois],
            ISNULL(s.[IntervalleMois], 1),                          -- ← NOUVEAU
            s.[CronExpression], s.[DateOnce],
            s.[DateDebut], s.[DateFin],
            s.[HandlerParams], d.[HandlerParams],
            s.[Actif], s.[Pause], d.[Actif],
            s.[ProchaineExec], s.[CompanyGUID]
        FROM [dbo].[T201JobSchedule] s
        INNER JOIN [dbo].[T200JobDefinition] d ON d.[Id] = s.[JobDefinitionId]
        WHERE (@CompanyGUID IS NULL
               OR s.[CompanyGUID] = @CompanyGUID
               OR s.[CompanyGUID] IS NULL)
          AND (@InclureInactifs = 1
               OR (s.[Actif] = 1 AND s.[Pause] = 0 AND d.[Actif] = 1));

    OPEN cur;
    FETCH NEXT FROM cur INTO
        @SchedId, @JobDefId, @SchedType,
        @IntervalMin, @HeureExec, @JoursSemaine,
        @JourMois, @IntervalleMois,                               -- ← NOUVEAU
        @CronExpr, @DateOnce,
        @DateDebut, @DateFin,
        @SchedParams, @JobParams,
        @SchedActif, @SchedPause, @JobActif,
        @SchedProchaine, @SchedCompany;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Réinitialiser les variables de calcul à chaque tour
        SET @ParamsEffectifs = ISNULL(@SchedParams, @JobParams);
        SET @BorneDebut = @Maintenant;
        IF CAST(@DateDebut AS DATETIME) > @BorneDebut
            SET @BorneDebut = CAST(@DateDebut AS DATETIME);

        SET @BorneFin = @Borne;
        IF @DateFin IS NOT NULL AND CAST(DATEADD(DAY, 1, @DateFin) AS DATETIME) < @BorneFin
            SET @BorneFin = CAST(DATEADD(DAY, 1, @DateFin) AS DATETIME);

        -- ────────────────────────────────────────────────────────────
        -- INTERVAL
        -- ────────────────────────────────────────────────────────────
        IF @SchedType = 'INTERVAL' AND @IntervalMin IS NOT NULL AND @IntervalMin > 0
        BEGIN
            SET @CompteurInt = 0;

            IF @SchedProchaine IS NOT NULL AND @SchedProchaine >= @BorneDebut
                SET @CurrentDate = @SchedProchaine;
            ELSE
                SET @CurrentDate = DATEADD(MINUTE, @IntervalMin, @BorneDebut);

            WHILE @CurrentDate < @BorneFin AND @CompteurInt < @LimiteParSchedule
            BEGIN
                INSERT INTO @Planning VALUES (
                    @JobDefId, @SchedId, @CurrentDate,
                    @ParamsEffectifs, @SchedActif, @SchedPause, @JobActif, @SchedCompany);

                SET @CurrentDate = DATEADD(MINUTE, @IntervalMin, @CurrentDate);
                SET @CompteurInt = @CompteurInt + 1;
            END
        END

        -- ────────────────────────────────────────────────────────────
        -- DAILY
        -- ────────────────────────────────────────────────────────────
        ELSE IF @SchedType = 'DAILY' AND @HeureExec IS NOT NULL
        BEGIN
            SET @JourCourant = CAST(@BorneDebut AS DATE);
            SET @PremiereCetteJour = CAST(@JourCourant AS DATETIME) + CAST(@HeureExec AS DATETIME);

            IF @PremiereCetteJour < @BorneDebut
                SET @JourCourant = DATEADD(DAY, 1, @JourCourant);

            SET @CompteurDaily = 0;

            WHILE @JourCourant < CAST(@BorneFin AS DATE)
                  AND @CompteurDaily < @LimiteParSchedule
            BEGIN
                SET @ExecDaily = CAST(@JourCourant AS DATETIME) + CAST(@HeureExec AS DATETIME);

                INSERT INTO @Planning VALUES (
                    @JobDefId, @SchedId, @ExecDaily,
                    @ParamsEffectifs, @SchedActif, @SchedPause, @JobActif, @SchedCompany);

                SET @JourCourant = DATEADD(DAY, 1, @JourCourant);
                SET @CompteurDaily = @CompteurDaily + 1;
            END
        END

        -- ────────────────────────────────────────────────────────────
        -- WEEKLY
        -- ────────────────────────────────────────────────────────────
        ELSE IF @SchedType = 'WEEKLY' AND @HeureExec IS NOT NULL AND @JoursSemaine IS NOT NULL
        BEGIN
            -- Vider la table avant de la remplir (déclarée une seule fois en haut)
            DELETE FROM @JoursTable;

            INSERT INTO @JoursTable
            SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
            FROM STRING_SPLIT(@JoursSemaine, ',')
            WHERE TRY_CAST(LTRIM(RTRIM(value)) AS INT) BETWEEN 1 AND 7;

            SET @JourW = CAST(@BorneDebut AS DATE);
            SET @CompteurWeekly = 0;

            WHILE @JourW < CAST(@BorneFin AS DATE)
                  AND @CompteurWeekly < @LimiteParSchedule
            BEGIN
                SET @ExecW = CAST(@JourW AS DATETIME) + CAST(@HeureExec AS DATETIME);
                SET @JourISO = ((DATEPART(WEEKDAY, @JourW) + @@DATEFIRST + 5) % 7) + 1;

                IF @ExecW > @BorneDebut
                   AND EXISTS (SELECT 1 FROM @JoursTable WHERE Jour = @JourISO)
                BEGIN
                    INSERT INTO @Planning VALUES (
                        @JobDefId, @SchedId, @ExecW,
                        @ParamsEffectifs, @SchedActif, @SchedPause, @JobActif, @SchedCompany);

                    SET @CompteurWeekly = @CompteurWeekly + 1;
                END

                SET @JourW = DATEADD(DAY, 1, @JourW);
            END
        END

        -- ────────────────────────────────────────────────────────────
        -- MONTHLY (avec IntervalleMois pour trimestriel/semestriel/annuel)
        -- ────────────────────────────────────────────────────────────
        ELSE IF @SchedType = 'MONTHLY' AND @HeureExec IS NOT NULL AND @JourMois IS NOT NULL
        BEGIN
            -- IntervalleMois par défaut = 1 si NULL
            IF @IntervalleMois IS NULL OR @IntervalleMois <= 0
                SET @IntervalleMois = 1;

            -- Calculer combien d'occurrences chercher :
            -- Pour 3 mois d'anticipation et IntervalleMois=12 (annuel), il en faut peu (0 ou 1)
            -- Pour 3 mois d'anticipation et IntervalleMois=1 (mensuel), il en faut 3-4
            -- On teste large : MoisAnticipation + 1 itérations
            SET @MoisLookahead = (@MoisAnticipation / @IntervalleMois) + 2;

            SET @MoisIdx = 0;
            SET @CompteurMonth = 0;

            WHILE @MoisIdx <= @MoisLookahead
                  AND @CompteurMonth < @LimiteParSchedule
            BEGIN
                -- ★ MODIF : multiplier @MoisIdx par @IntervalleMois
                SET @PremJour = DATEFROMPARTS(
                    YEAR(DATEADD(MONTH, @MoisIdx * @IntervalleMois, @Maintenant)),
                    MONTH(DATEADD(MONTH, @MoisIdx * @IntervalleMois, @Maintenant)),
                    1);

                SET @DerJour = DAY(EOMONTH(@PremJour));

                IF @JourMois = -1
                    SET @JourEffectif = @DerJour;
                ELSE IF @JourMois > @DerJour
                    SET @JourEffectif = @DerJour;
                ELSE
                    SET @JourEffectif = @JourMois;

                SET @ExecMonth =
                    CAST(DATEFROMPARTS(YEAR(@PremJour), MONTH(@PremJour), @JourEffectif) AS DATETIME)
                    + CAST(@HeureExec AS DATETIME);

                IF @ExecMonth > @BorneDebut AND @ExecMonth < @BorneFin
                BEGIN
                    INSERT INTO @Planning VALUES (
                        @JobDefId, @SchedId, @ExecMonth,
                        @ParamsEffectifs, @SchedActif, @SchedPause, @JobActif, @SchedCompany);

                    SET @CompteurMonth = @CompteurMonth + 1;
                END

                SET @MoisIdx = @MoisIdx + 1;
            END
        END

        -- ────────────────────────────────────────────────────────────
        -- CRON
        -- ────────────────────────────────────────────────────────────
        ELSE IF @SchedType = 'CRON'
        BEGIN
            IF @SchedProchaine IS NOT NULL
               AND @SchedProchaine > @BorneDebut
               AND @SchedProchaine < @BorneFin
            BEGIN
                INSERT INTO @Planning VALUES (
                    @JobDefId, @SchedId, @SchedProchaine,
                    @ParamsEffectifs, @SchedActif, @SchedPause, @JobActif, @SchedCompany);
            END
        END

        -- ────────────────────────────────────────────────────────────
        -- ONCE
        -- ────────────────────────────────────────────────────────────
        ELSE IF @SchedType = 'ONCE' AND @DateOnce IS NOT NULL
        BEGIN
            IF @DateOnce > @BorneDebut AND @DateOnce < @BorneFin
            BEGIN
                INSERT INTO @Planning VALUES (
                    @JobDefId, @SchedId, @DateOnce,
                    @ParamsEffectifs, @SchedActif, @SchedPause, @JobActif, @SchedCompany);
            END
        END

        FETCH NEXT FROM cur INTO
            @SchedId, @JobDefId, @SchedType,
            @IntervalMin, @HeureExec, @JoursSemaine,
            @JourMois, @IntervalleMois,                            -- ← NOUVEAU
            @CronExpr, @DateOnce,
            @DateDebut, @DateFin,
            @SchedParams, @JobParams,
            @SchedActif, @SchedPause, @JobActif,
            @SchedProchaine, @SchedCompany;
    END

    CLOSE cur;
    DEALLOCATE cur;

    -- ════════════════════════════════════════════════════════════════
    -- MERGE dans T204JobPlanned (idempotent)
    -- ════════════════════════════════════════════════════════════════
    BEGIN TRY
        BEGIN TRANSACTION;

        MERGE [dbo].[T204JobPlanned] AS target
        USING (
            SELECT JobDefinitionId, JobScheduleId, DateExecutionPrevue,
                   HandlerParams, ScheduleActif, SchedulePause, JobActif, CompanyGUID
            FROM @Planning
        ) AS src
            ON target.[JobScheduleId]       = src.JobScheduleId
           AND target.[DateExecutionPrevue] = src.DateExecutionPrevue

        WHEN NOT MATCHED THEN
            INSERT ([JobDefinitionId], [JobScheduleId], [DateExecutionPrevue],
                    [HandlerParams], [ScheduleActif], [SchedulePause], [JobActif],
                    [Statut], [GenereLe], [CompanyGUID])
            VALUES (src.JobDefinitionId, src.JobScheduleId, src.DateExecutionPrevue,
                    src.HandlerParams, src.ScheduleActif, src.SchedulePause, src.JobActif,
                    'PLANIFIE', GETDATE(), src.CompanyGUID)

        WHEN MATCHED AND target.[Statut] = 'PLANIFIE' THEN
            UPDATE SET
                target.[HandlerParams]  = src.HandlerParams,
                target.[ScheduleActif]  = src.ScheduleActif,
                target.[SchedulePause]  = src.SchedulePause,
                target.[JobActif]       = src.JobActif,
                target.[GenereLe]       = GETDATE();

        UPDATE [dbo].[T204JobPlanned]
        SET [Statut] = 'EXPIRE',
            [Notes]  = ISNULL([Notes] + ' | ', '') + 'Auto-expiré le ' +
                       CONVERT(VARCHAR(19), GETDATE(), 120)
        WHERE [Statut] = 'PLANIFIE'
          AND [DateExecutionPrevue] < @Maintenant
          -- Les activités à faire (ACT_*, T362) restent PLANIFIE tant qu'elles ne sont pas réglées.
          AND [JobDefinitionId] NOT IN (SELECT [Id] FROM [dbo].[T200JobDefinition] WHERE RTRIM([JobCode]) LIKE 'ACT[_]%');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
        RETURN;
    END CATCH

    -- ════════════════════════════════════════════════════════════════
    -- RETOUR
    -- ════════════════════════════════════════════════════════════════
    DECLARE @NbLignesApres INT = (SELECT COUNT(*) FROM [dbo].[T204JobPlanned] WHERE [Statut] = 'PLANIFIE');

    SELECT
        @NbLignesAvant                    AS NbLignesAvant,
        @NbLignesApres                    AS NbLignesApres,
        @NbLignesApres - @NbLignesAvant   AS Delta,
        (SELECT COUNT(*) FROM @Planning)  AS NbCalcules,
        @MoisAnticipation                 AS MoisAnticipation,
        @Maintenant                       AS DateDebut,
        @Borne                            AS DateFin,
        (SELECT COUNT(*) FROM [dbo].[T204JobPlanned] WHERE [Statut] = 'EXPIRE')      AS NbExpires,
        (SELECT COUNT(*) FROM [dbo].[T204JobPlanned] WHERE [Statut] = 'PRIS_EN_CHARGE') AS NbPrisEnCharge;

    SELECT
        d.[JobCode],
        d.[Nom]                                              AS JobNom,
        s.[Nom]                                              AS ScheduleNom,
        s.[ScheduleType],
        ISNULL(s.[IntervalleMois], 1)                        AS IntervalleMois,
        CASE WHEN d.[Actif] = 0 THEN 'JOB INACTIF'
             WHEN s.[Pause] = 1 THEN 'EN PAUSE'
             WHEN s.[Actif] = 0 THEN 'INACTIF'
             ELSE 'ACTIF' END                                AS Etat,
        COUNT(p.[Id])                                        AS NbPlanifie,
        MIN(p.[DateExecutionPrevue])                         AS Premiere,
        MAX(p.[DateExecutionPrevue])                         AS Derniere
    FROM [dbo].[T201JobSchedule] s
    INNER JOIN [dbo].[T200JobDefinition] d ON d.[Id] = s.[JobDefinitionId]
    LEFT JOIN [dbo].[T204JobPlanned] p
           ON p.[JobScheduleId] = s.[Id]
          AND p.[Statut] = 'PLANIFIE'
    WHERE (@CompanyGUID IS NULL
           OR s.[CompanyGUID] = @CompanyGUID
           OR s.[CompanyGUID] IS NULL)
    GROUP BY d.[JobCode], d.[Nom], s.[Nom], s.[ScheduleType],
             s.[IntervalleMois],
             d.[Actif], s.[Actif], s.[Pause]
    ORDER BY NbPlanifie DESC, d.[JobCode];

END;
GO

-- -----------------------------------------------------------------------------
-- 4b) sp_GenererPlanningFactures : ne traite plus que ses lignes INVOICE_REMINDER
-- -----------------------------------------------------------------------------
-- ============================================================================
-- sp_GenererPlanningFactures
--
-- But :
--   Génère des lignes T204JobPlanned à partir de toutes les factures
--   de la vue vwCustomersInvoices (peu importe leur StatutPaiement).
--
-- Logique :
--   - JobDefinitionId fixe = 4 (job 'INVOICE_REMINDER')
--   - JobScheduleId = premier schedule existant dans T201JobSchedule
--                     qui pointe vers JobDefinitionId=4
--                     (respecte la FK FK_T204_JobSchedule)
--   - DocumentId = T060Document.Id (lien vers la facture)
--   - DateExecutionPrevue = DueDate (ou DocumentDate si DueDate NULL)
--   - Beneficiaire = NameRaw de la facture
--   - Montant = ResteAPayer (paiements partiels déjà soustraits)
--   - StatutPaiement = recopié depuis la vue
--
-- Prérequis :
--   - Job sentinelle Id=4 avec JobCode='INVOICE_REMINDER' présent
--     dans T200JobDefinition
--   - AU MOINS UN T201JobSchedule existe avec JobDefinitionId=4
--
-- Idempotence :
--   - MERGE sur DocumentId (clé naturelle pour les factures)
--   - Re-run : refresh des champs Beneficiaire/Montant/StatutPaiement/DateExecutionPrevue
--   - Facture devenue PAYEE → ligne passée en 'ANNULE'
--   - Facture supprimée → ligne passée en 'ANNULE'
--
-- Test :
--   EXEC sp_GenererPlanningFactures '87893D29-6D64-40C8-8E45-A3492B4FBB91';
--   delete [dbo].[T204JobPlanned]
--   select * from [T204JobPlanned]
--   select * from vwCustomersInvoices
-- ============================================================================

CREATE OR ALTER PROCEDURE [dbo].[sp_GenererPlanningFactures]
    @CompanyGUID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- ════════════════════════════════════════════════════════════════
    -- CONSTANTES
    -- ════════════════════════════════════════════════════════════════
    DECLARE @JobIdFactures INT = 10;       -- 'INVOICE_REMINDER'
    DECLARE @Maintenant    DATETIME = GETDATE();

    -- Récupère le premier schedule qui correspond au job INVOICE_REMINDER
    -- pour respecter la FK FK_T204_JobSchedule
    DECLARE @JobScheduleId INT = (
        SELECT TOP 1 [Id]
        FROM [dbo].[T201JobSchedule]
        WHERE [JobDefinitionId] = @JobIdFactures
        ORDER BY [Id]
    );

    IF @JobScheduleId IS NULL
    BEGIN
        RAISERROR('Aucun T201JobSchedule trouvé pour JobDefinitionId=%d. Créez d''abord un schedule pour le job INVOICE_REMINDER.',
                  16, 1, @JobIdFactures);
        RETURN;
    END

    DECLARE @NbLignesAvant INT = (
        SELECT COUNT(*) FROM [dbo].[T204JobPlanned]
        WHERE [DocumentId] IS NOT NULL AND [Statut] = 'PLANIFIE'
    );

    -- ════════════════════════════════════════════════════════════════
    -- TABLE TEMPORAIRE : on accumule toutes les factures à planifier
    -- ════════════════════════════════════════════════════════════════
    DECLARE @Planning TABLE (
        JobDefinitionId      INT,
        JobScheduleId        INT,
        DateExecutionPrevue  DATETIME,
		DueDate              DATETIME,
        ScheduleActif        BIT,
        SchedulePause        BIT,
        JobActif             BIT,
        CompanyGUID          UNIQUEIDENTIFIER,
        Beneficiaire         VARCHAR(200),
		DejaRecu             NUMERIC(18,2),
        Montant              NUMERIC(18,2),
        DocumentId           INT,
        StatutPaiement       VARCHAR(200)
    );

    -- ════════════════════════════════════════════════════════════════
    -- ALIMENTATION depuis vwCustomersInvoices
    -- (TOUTES les factures, peu importe leur StatutPaiement)
    -- ════════════════════════════════════════════════════════════════
    INSERT INTO @Planning (
        JobDefinitionId, JobScheduleId, DateExecutionPrevue,DueDate,
        ScheduleActif, SchedulePause, JobActif, CompanyGUID,
        Beneficiaire, DejaRecu,Montant, DocumentId, StatutPaiement
    )
    SELECT
        @JobIdFactures,
        @JobScheduleId                                       AS JobScheduleId,  -- premier schedule du job INVOICE_REMINDER
        ISNULL(CAST(v.[DueDate] AS DATETIME),
               ISNULL(v.[DocumentDate], @Maintenant))        AS DateExecutionPrevue,
        ISNULL(CAST(v.[DueDate] AS DATETIME),
               ISNULL(v.[DocumentDate], @Maintenant))        AS DueDate,
        1                                                    AS ScheduleActif,
        0                                                    AS SchedulePause,
        1                                                    AS JobActif,
        v.[CompanyGUID],
        LEFT(ISNULL(v.[NameRaw], ''), 200)                   AS Beneficiaire,
        v.DejaRecu                                           AS DejaRecu,
		v.[ResteAPayer]                                      AS Montant,
        v.[Id]                                               AS DocumentId,
        v.[StatutPaiement]
    FROM [dbo].[vwCustomersInvoices] v
    WHERE (@CompanyGUID IS NULL OR v.[CompanyGUID] = @CompanyGUID) and ComptabilisationStatus='COMPTABILISE';
	--select * from vwCustomersInvoices
    -- ════════════════════════════════════════════════════════════════
    -- MERGE dans T204JobPlanned (idempotent)
    -- ════════════════════════════════════════════════════════════════
    BEGIN TRY
        BEGIN TRANSACTION;

        MERGE [dbo].[T204JobPlanned] AS target
        USING (
            SELECT JobDefinitionId, JobScheduleId, DateExecutionPrevue,DueDate,
                   ScheduleActif, SchedulePause, JobActif, CompanyGUID,
                   Beneficiaire,DejaRecu, Montant, DocumentId, StatutPaiement
            FROM @Planning
        ) AS src
            -- Clé unique pour les factures = DocumentId
            -- (le JobScheduleId est partagé par toutes les factures)
            ON target.[DocumentId] = src.DocumentId
           AND target.[JobDefinitionId] = src.JobDefinitionId   -- T362 : seulement les lignes INVOICE_REMINDER
           AND target.[DocumentId] IS NOT NULL    -- ne touche pas aux lignes-schedules

        WHEN NOT MATCHED THEN
            INSERT ([JobDefinitionId], [JobScheduleId], [DateExecutionPrevue],DueDate,
                    [ScheduleActif], [SchedulePause], [JobActif],
                    [Statut], [GenereLe], [CompanyGUID],
                    [Beneficiaire],DejaRecu, [Montant], [DocumentId], [StatutPaiement])
            VALUES (src.JobDefinitionId, src.JobScheduleId, src.DateExecutionPrevue,src.DueDate,
                    src.ScheduleActif, src.SchedulePause, src.JobActif,
                    'PLANIFIE', GETDATE(), src.CompanyGUID,
                    src.Beneficiaire, src.DejaRecu, src.Montant, src.DocumentId, src.StatutPaiement)

        WHEN MATCHED AND target.[Statut] = 'PLANIFIE' THEN
            UPDATE SET
                target.[DateExecutionPrevue] = src.DateExecutionPrevue,
				 target.[DueDate]            = src.[DueDate],
                target.[ScheduleActif]       = src.ScheduleActif,
                target.[SchedulePause]       = src.SchedulePause,
                target.[JobActif]            = src.JobActif,
                target.[GenereLe]            = GETDATE(),
                target.[Beneficiaire]        = src.Beneficiaire,
				target.DejaRecu             = src.DejaRecu,
                target.[Montant]             = src.Montant,
                target.[StatutPaiement]      = src.StatutPaiement;

        -- ─── Marquer ANNULE les T204 dont la facture est devenue PAYEE ───
        UPDATE p
        SET p.[Statut] = 'ANNULE',
            p.[Notes]  = ISNULL(p.[Notes] + ' | ', '') + 'Facture payée le ' +
                         CONVERT(VARCHAR(19), GETDATE(), 120)
        FROM [dbo].[T204JobPlanned] p
        INNER JOIN [dbo].[vwCustomersInvoices] v ON v.[Id] = p.[DocumentId]
        WHERE p.[Statut] = 'PLANIFIE'
          AND p.[DocumentId] IS NOT NULL
          AND v.[StatutPaiement] = 'PAYEE'
          AND p.[JobDefinitionId] = @JobIdFactures;   -- T362

        -- ─── Marquer ANNULE les T204 dont la facture n'existe plus ───
        --     (facture supprimée → on annule la ligne planifiée orpheline)
        UPDATE p
        SET p.[Statut] = 'ANNULE',
            p.[Notes]  = ISNULL(p.[Notes] + ' | ', '') + 'Facture introuvable, annulé le ' +
                         CONVERT(VARCHAR(19), GETDATE(), 120)
        FROM [dbo].[T204JobPlanned] p
        WHERE p.[Statut] = 'PLANIFIE'
          AND p.[DocumentId] IS NOT NULL
          AND p.[JobDefinitionId] = @JobIdFactures   -- T362 : ne pas annuler les activités ACT_*
          AND NOT EXISTS (
                SELECT 1 FROM [dbo].[vwCustomersInvoices] v
                WHERE v.[Id] = p.[DocumentId]
          );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
        RETURN;
    END CATCH

    -- ════════════════════════════════════════════════════════════════
    -- RETOUR : 2 result sets
    -- ════════════════════════════════════════════════════════════════
    DECLARE @NbLignesApres INT = (
        SELECT COUNT(*) FROM [dbo].[T204JobPlanned]
        WHERE [DocumentId] IS NOT NULL AND [Statut] = 'PLANIFIE'
    );

    -- Result set 1 : statistiques globales
    SELECT
        @NbLignesAvant                       AS NbLignesAvant,
        @NbLignesApres                       AS NbLignesApres,
        @NbLignesApres - @NbLignesAvant      AS Delta,
        (SELECT COUNT(*) FROM @Planning)     AS NbCalcules,
        @JobIdFactures                       AS JobIdFactures,
        @JobScheduleId                       AS JobScheduleIdUtilise,
        @Maintenant                          AS GenereLe,
        (SELECT COUNT(*) FROM [dbo].[T204JobPlanned]
         WHERE [DocumentId] IS NOT NULL AND [Statut] = 'ANNULE')  AS NbAnnules,
        (SELECT COUNT(*) FROM [dbo].[T204JobPlanned]
         WHERE [DocumentId] IS NOT NULL AND [Statut] = 'PLANIFIE'
           AND [StatutPaiement] = 'EN_RETARD')                    AS NbEnRetard,
        (SELECT COUNT(*) FROM [dbo].[T204JobPlanned]
         WHERE [DocumentId] IS NOT NULL AND [Statut] = 'PLANIFIE'
           AND [StatutPaiement] = 'PARTIELLE')                    AS NbPartielles,
        (SELECT COUNT(*) FROM [dbo].[T204JobPlanned]
         WHERE [DocumentId] IS NOT NULL AND [Statut] = 'PLANIFIE'
           AND [StatutPaiement] = 'IN_PROGRESS')                  AS NbInProgress,
        (SELECT COUNT(*) FROM [dbo].[T204JobPlanned]
         WHERE [DocumentId] IS NOT NULL AND [Statut] = 'PLANIFIE'
           AND [StatutPaiement] = 'OUVERTE')                      AS NbOuvertes;

    -- Result set 2 : répartition par StatutPaiement avec totaux
    SELECT
        p.[StatutPaiement],
        COUNT(*)                                AS NbFactures,
		SUM(p.DejaRecu)                        AS TotalDejaRecu,
        SUM(p.[Montant])                        AS TotalAPayer,
        MIN(p.DueDate)            AS PremiereEcheance,
        MAX(p.DueDate)            AS DerniereEcheance
    FROM [dbo].[T204JobPlanned] p
    WHERE p.[DocumentId] IS NOT NULL
      AND p.[Statut] = 'PLANIFIE'
      AND (@CompanyGUID IS NULL OR p.[CompanyGUID] = @CompanyGUID)
    GROUP BY p.[StatutPaiement]
    ORDER BY
        CASE p.[StatutPaiement]
            WHEN 'EN_RETARD'   THEN 1
            WHEN 'PARTIELLE'   THEN 2
            WHEN 'OUVERTE'     THEN 3
            WHEN 'IN_PROGRESS' THEN 4
            ELSE                    5
        END;

END;
GO

-- -----------------------------------------------------------------------------
-- 5) Première synchronisation, toutes compagnies
-- -----------------------------------------------------------------------------
EXEC dbo.s0973SyncActivitesAFaire @CompanyGUID = NULL;
GO
