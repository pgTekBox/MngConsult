-- =============================================================================
-- T375 — Déclarations de taxes : périodes de l'exercice, date limite, rappel
--
-- Règles de Revenu Québec / ARC (TPS-TVQ) :
--   - les périodes de déclaration suivent l'EXERCICE FINANCIER de l'entreprise
--     (paramètre FISCAL_YEAR_END) : mois ou trimestres de l'exercice, ou
--     l'exercice entier ;
--   - mensuelle et trimestrielle : déclaration et paiement dus 1 mois après la
--     fin de la période ; annuelle : 3 mois après la fin de l'exercice.
--
-- 1. fDebutExerciceMois(@CompanyGUID) : le mois où commence l'exercice
--    (lendemain de FISCAL_YEAR_END ; janvier par défaut).
-- 2. fPeriodeTaxe(@CompanyGUID, @Date) : fréquence (TAX_FREQ), début et fin de
--    la période qui contient @Date, date limite, n° de la période dans
--    l'exercice et bornes de l'exercice.
-- 3. sp_GenererRapportTaxe : son calcul de période (année civile) est remplacé
--    par fPeriodeTaxe, et la date limite est enregistrée (DateLimitePaiement).
--    Le texte de la procédure est relu sur le serveur et seuls ces morceaux
--    sont remplacés (accents intacts) ; sans effet si c'est déjà fait.
-- 4. Les rapports existants reçoivent leur date limite (colonne vide jusqu'ici).
-- 5. s0994MarquerRapportTaxeProduit : une déclaration en REMBOURSEMENT (total
--    à remettre ≤ 0, rien à payer) se marque « produite » (FINALISE).
-- 6. s0995GetPeriodeTaxe : la période d'une date, pour la page.
-- 7. Activité ACT_TAXES : la tâche SYNC_ACTIVITES (s0973) inscrit, pour chaque
--    compagnie qui a des écritures de taxes, la plus ancienne période terminée
--    (24 derniers mois) dont la déclaration n'est ni finalisée ni remise ;
--    échéance = date limite. Elle disparaît quand le rapport est remis (PAYE)
--    ou marqué produit (FINALISE).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ── 1. Le mois où commence l'exercice ──────────────────────────────────────
CREATE OR ALTER FUNCTION dbo.fDebutExerciceMois (@CompanyGUID UNIQUEIDENTIFIER)
RETURNS INT
AS
BEGIN
    DECLARE @Fin DATE = (SELECT TOP 1 v.[dVal]
                         FROM dbo.T100ParamComptable p
                         JOIN dbo.T101ParamValues v ON v.[T100Id] = p.[Id]
                         WHERE p.[ShortName] = 'FISCAL_YEAR_END' AND v.[CompanyGUID] = @CompanyGUID
                           AND v.[dVal] IS NOT NULL
                         ORDER BY CASE WHEN p.[CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END);
    RETURN CASE WHEN @Fin IS NULL THEN 1 ELSE MONTH(DATEADD(DAY, 1, @Fin)) END;
END
GO

-- ── 2. La période de taxes qui contient une date ───────────────────────────
CREATE OR ALTER FUNCTION dbo.fPeriodeTaxe (@CompanyGUID UNIQUEIDENTIFIER, @Date DATE)
RETURNS @P TABLE (
    Frequence     VARCHAR(20),
    DebutPeriode  DATE,
    FinPeriode    DATE,
    DateLimite    DATE,
    NoPeriode     INT,
    NbPeriodes    INT,
    ExerciceDebut DATE,
    ExerciceFin   DATE
)
AS
BEGIN
    DECLARE @Freq VARCHAR(20) = (SELECT TOP 1 v.[sVal]
                                 FROM dbo.T100ParamComptable p
                                 JOIN dbo.T101ParamValues v ON v.[T100Id] = p.[Id]
                                 WHERE p.[ShortName] = 'TAX_FREQ' AND v.[CompanyGUID] = @CompanyGUID
                                 ORDER BY CASE WHEN p.[CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END);
    IF @Freq IS NULL OR @Freq NOT IN ('MENSUELLE', 'TRIMESTRIELLE', 'ANNUELLE') SET @Freq = 'TRIMESTRIELLE';

    DECLARE @S INT = dbo.fDebutExerciceMois(@CompanyGUID);
    DECLARE @ExDebut DATE = DATEFROMPARTS(CASE WHEN MONTH(@Date) >= @S THEN YEAR(@Date) ELSE YEAR(@Date) - 1 END, @S, 1);
    DECLARE @ExFin DATE = DATEADD(DAY, -1, DATEADD(YEAR, 1, @ExDebut));
    DECLARE @k INT = DATEDIFF(MONTH, @ExDebut, DATEFROMPARTS(YEAR(@Date), MONTH(@Date), 1));   -- 0..11

    DECLARE @Debut DATE, @Fin DATE, @Limite DATE, @No INT, @Nb INT;
    IF @Freq = 'MENSUELLE'
    BEGIN
        SET @Debut = DATEADD(MONTH, @k, @ExDebut);
        SET @Fin = EOMONTH(@Debut);
        SET @No = @k + 1; SET @Nb = 12;
        SET @Limite = EOMONTH(@Fin, 1);
    END
    ELSE IF @Freq = 'TRIMESTRIELLE'
    BEGIN
        SET @Debut = DATEADD(MONTH, 3 * (@k / 3), @ExDebut);
        SET @Fin = EOMONTH(DATEADD(MONTH, 2, @Debut));
        SET @No = @k / 3 + 1; SET @Nb = 4;
        SET @Limite = EOMONTH(@Fin, 1);
    END
    ELSE
    BEGIN
        SET @Debut = @ExDebut; SET @Fin = @ExFin;
        SET @No = 1; SET @Nb = 1;
        SET @Limite = EOMONTH(@Fin, 3);
    END

    INSERT INTO @P VALUES (@Freq, @Debut, @Fin, @Limite, @No, @Nb, @ExDebut, @ExFin);
    RETURN;
END
GO

-- ── 3. sp_GenererRapportTaxe : période de l'exercice + date limite ─────────
DECLARE @def NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_GenererRapportTaxe'));
IF @def IS NULL THROW 51100, 'sp_GenererRapportTaxe introuvable.', 1;

IF CHARINDEX(N'dbo.fPeriodeTaxe', @def) = 0
BEGIN
    DECLARE @a INT = CHARINDEX(N'DECLARE @Frequence VARCHAR(20);', @def);
    DECLARE @b INT = CHARINDEX(N'SET @FinPeriode   = DATEFROMPARTS(@Annee, 12, 31);', @def);
    IF @a = 0 OR @b = 0 THROW 51101, 'sp_GenererRapportTaxe : bloc de calcul de période introuvable.', 1;
    DECLARE @e INT = CHARINDEX(N'END', @def, @b) + 3;      -- le END du bloc ANNUELLE

    SET @def = STUFF(@def, @a, @e - @a,
        N'DECLARE @Frequence VARCHAR(20), @DebutPeriode DATE, @FinPeriode DATE, @DateLimite DATE;' + NCHAR(13) + NCHAR(10) +
        N'    -- Fréquence (TAX_FREQ), période alignée sur l''exercice financier (FISCAL_YEAR_END)' + NCHAR(13) + NCHAR(10) +
        N'    -- et date limite de déclaration et de paiement : dbo.fPeriodeTaxe (T375).' + NCHAR(13) + NCHAR(10) +
        N'    SELECT @Frequence = [Frequence], @DebutPeriode = [DebutPeriode], @FinPeriode = [FinPeriode], @DateLimite = [DateLimite]' + NCHAR(13) + NCHAR(10) +
        N'    FROM dbo.fPeriodeTaxe(@CompanyGUID, @DateReference);');

    DECLARE @i1 NVARCHAR(100) = N'[DebutPeriode], [FinPeriode], [Frequence],';
    DECLARE @i2 NVARCHAR(100) = N'@DebutPeriode, @FinPeriode, @Frequence,';
    DECLARE @u1 NVARCHAR(100) = N'SET [Frequence]  = @Frequence,';
    IF (LEN(@def) - LEN(REPLACE(@def, @i1, N''))) / LEN(@i1) <> 1
       OR (LEN(@def) - LEN(REPLACE(@def, @i2, N''))) / LEN(@i2) <> 1
       OR (LEN(@def) - LEN(REPLACE(@def, @u1, N''))) / LEN(@u1) <> 1
        THROW 51102, 'sp_GenererRapportTaxe : INSERT / UPDATE de T070 introuvables ou ambigus.', 1;

    SET @def = REPLACE(@def, @i1, @i1 + N' [DateLimitePaiement],');
    SET @def = REPLACE(@def, @i2, @i2 + N' @DateLimite,');
    SET @def = REPLACE(@def, @u1, @u1 + N' [DateLimitePaiement] = @DateLimite,');

    DECLARE @p INT = CHARINDEX(N'CREATE', @def);
    SET @def = STUFF(@def, @p, 6, N'ALTER');
    EXEC sys.sp_executesql @def;
END
GO

-- ── 4. Date limite des rapports existants ──────────────────────────────────
UPDATE dbo.T070RapportTaxe
SET [DateLimitePaiement] = CASE WHEN [Frequence] = 'ANNUELLE' THEN EOMONTH([FinPeriode], 3) ELSE EOMONTH([FinPeriode], 1) END
WHERE [DateLimitePaiement] IS NULL AND [FinPeriode] IS NOT NULL;
GO

-- ── 5. Déclaration en remboursement : la marquer produite ──────────────────
CREATE OR ALTER PROCEDURE dbo.s0994MarquerRapportTaxeProduit
    @CompanyGUID UNIQUEIDENTIFIER,
    @RapportId   INT,
    @DateProduite DATE = NULL,
    @Reference   VARCHAR(100) = NULL,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Statut VARCHAR(20), @Total DECIMAL(15, 2), @Fin DATE;
    SELECT @Statut = [Statut], @Fin = [FinPeriode],
           @Total = ISNULL([TPS_Nette], 0) + ISNULL([CTI_Ajustement], 0) + ISNULL([TVQ_Nette], 0) + ISNULL([RTI_Ajustement], 0)
    FROM dbo.T070RapportTaxe WHERE [Id] = @RapportId AND [CompanyGUID] = @CompanyGUID;

    IF @Statut IS NULL THROW 51103, 'Rapport de taxes introuvable.', 1;
    IF @Statut <> 'BROUILLON' THROW 51104, 'Ce rapport est déjà finalisé ou remis.', 1;
    IF @Total > 0 THROW 51105, 'Il y a un montant à remettre : utilisez « Marquer comme remis ».', 1;
    IF @Fin >= CAST(GETDATE() AS DATE) THROW 51106, 'La période n''est pas terminée.', 1;

    UPDATE dbo.T070RapportTaxe
    SET [Statut] = 'FINALISE',
        [Reference] = NULLIF(LTRIM(RTRIM(ISNULL(@Reference, ''))), ''),
        [Notes] = LEFT(ISNULL([Notes] + ' | ', '') + 'Déclaration produite le ' + CONVERT(VARCHAR(10), ISNULL(@DateProduite, CAST(GETDATE() AS DATE)), 23)
                       + CASE WHEN @Total < 0 THEN ' (remboursement de ' + CONVERT(VARCHAR(20), -@Total) + ' $)' ELSE ' (solde nul)' END, 500)
    WHERE [Id] = @RapportId AND [CompanyGUID] = @CompanyGUID;

    SELECT @RapportId AS RapportId;
END
GO

-- ── 6. La période d'une date, pour la page ─────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0995GetPeriodeTaxe
    @CompanyGUID UNIQUEIDENTIFIER,
    @Date        DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.fPeriodeTaxe(@CompanyGUID, @Date);
END
GO

-- ── 7. Activité ACT_TAXES ──────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM dbo.T200JobDefinition WHERE RTRIM([JobCode]) = 'ACT_TAXES')
    INSERT INTO dbo.T200JobDefinition
        ([Id], [JobCode], [Nom], [Description], [HandlerType], [HandlerName],
         [TimeoutSeconds], [MaxRetries], [RetryDelayMin], [Actif], [Systeme],
         [CompanyGUID], [CategotyId], [RequiertApprobation])
    VALUES
        ((SELECT ISNULL(MAX([Id]), 0) + 1 FROM dbo.T200JobDefinition), 'ACT_TAXES',
         'Activité : produire la déclaration de taxes',
         'Une période de taxes terminée n''est pas déclarée (rapport ni finalisé ni remis). Inscrite par SYNC_ACTIVITES, jamais exécutée.',
         'CUSTOM', 'ACTIVITE', 300, 0, 5, 1, 1, NULL, NULL, 0);

INSERT INTO dbo.T201JobSchedule ([JobDefinitionId], [Nom], [ScheduleType], [DateOnce], [Actif], [Pause], [CompanyGUID])
SELECT d.[Id], 'Activité inscrite par SYNC_ACTIVITES (aucune exécution)', 'ONCE', NULL, 0, 0, NULL
FROM dbo.T200JobDefinition d
WHERE RTRIM(d.[JobCode]) = 'ACT_TAXES'
  AND NOT EXISTS (SELECT 1 FROM dbo.T201JobSchedule s WHERE s.[JobDefinitionId] = d.[Id]);
GO

-- s0973 reprise de T372 avec le septième type ACT_TAXES
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
    WHERE RTRIM(d.[JobCode]) IN ('ACT_FACT_CLIENT', 'ACT_FACT_FOURN', 'ACT_BROUILLON', 'ACT_BANQUE', 'ACT_ESSAI', 'ACT_CONCILIATION', 'ACT_TAXES');

    IF (SELECT COUNT(*) FROM @Types WHERE JobScheduleId IS NOT NULL) < 7
        THROW 51010, 'Types d''activité ACT_* ou leurs calendriers manquants (scripts T362, T372, T375).', 1;

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
