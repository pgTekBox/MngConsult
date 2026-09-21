-- =============================================================================
-- T253 — La paie en préparation
--
-- Quatre tables, calquées sur le modèle « paie » de l'application : l'employé
-- et ses paramètres fiscaux, le lot de paie, la paie d'un employé dans ce lot,
-- et les lignes qui la composent. C'est la forme d'une reprise de paie — on ne
-- reprend pas « des montants », on reprend des employés, des périodes, et le
-- détail de ce qui a été versé et retenu.
--
-- CE QUE LA SOURCE DONNE : RIEN, POUR L'INSTANT.
--
-- QuickBooks n'expose pas la paie par son API v3 : l'entité Employee revient
-- vide (trois essais), TimeActivity aussi, /accounting/employees répond 404
-- pour ce connecteur, et l'API HRIS d'Apideck répond 401 — l'application n'y
-- est pas abonnée. La paie de QBO est un produit séparé dont les talons ne
-- passent pas par cette porte.
--
-- La table existe quand même, et c'est délibéré : une reprise de paie viendra
-- d'un fichier ou d'un autre connecteur, et le point d'arrivée doit être décidé
-- AVANT de savoir d'où ça vient. Ce qui y est déposé aujourd'hui est simulé, et
-- le registre le dit.
--
-- CE QU'ON N'EN FAIT PAS. Rien ne s'applique : paie.Employe_V1, paie.LotPaie,
-- paie.Paie et paie.PaieLigne ne sont pas touchées. Une paie reprise doit être
-- relue avant d'exister — un net mal repris, c'est un employé mal payé et un
-- relevé d'emploi faux.
--
-- LES MONTANTS SONT GARDÉS TELS QUELS, JAMAIS RECALCULÉS. On reprend ce qui a
-- ÉTÉ versé, pas ce qui aurait dû l'être : les taux de l'année passée ne sont
-- pas ceux d'aujourd'hui, et recalculer une paie déjà versée la ferait diverger
-- du T4 et du relevé 1 déjà produits. Le contrôle d'équilibre
-- (brut − retenues = net) est vérifié, mais il n'est jamais corrigé.
--
-- Procédures : s0829 (charger, les quatre tables d'un coup), s0830 (lire).
-- La liste blanche du registre accueille « Paie ».
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) L'employé et ses paramètres fiscaux
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.PaieEmployeImport') IS NULL
CREATE TABLE staging.PaieEmployeImport (
    [Id]               INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PaieEmployeImport PRIMARY KEY,
    [ImportFileId]     INT NULL,
    [RunId]            INT NULL,
    [CompanyGUID]      UNIQUEIDENTIFIER NOT NULL,

    [Rang]             INT NOT NULL CONSTRAINT DF_PaieEmployeImport_Rang DEFAULT (0),
    [ExterneId]        NVARCHAR(100) NULL,
    [Code]             NVARCHAR(50) NULL,
    [Prenom]           NVARCHAR(200) NULL,
    [Nom]              NVARCHAR(200) NULL,
    [Courriel]         NVARCHAR(320) NULL,
    [Telephone]        NVARCHAR(50) NULL,
    [Adresse1]         NVARCHAR(300) NULL,
    [Ville]            NVARCHAR(200) NULL,
    [Province]         NVARCHAR(10) NULL,
    [CodePostal]       NVARCHAR(20) NULL,
    [Langue]           NVARCHAR(10) NULL,
    [DateNaissance]    DATE NULL,

    -- Le NAS n'est PAS repris. Il ne sert à rien en préparation, et une donnée
    -- qu'on ne garde pas est une donnée qu'on ne peut pas perdre. Seul un
    -- indicateur dit si la source en avait un, pour savoir ce qu'il restera à
    -- saisir.
    [NASFourni]        BIT NOT NULL CONSTRAINT DF_PaieEmployeImport_NASFourni DEFAULT (0),

    [Poste]            NVARCHAR(200) NULL,
    [DateEmbauche]     DATE NULL,
    [DateFinEmploi]    DATE NULL,
    [Actif]            BIT NOT NULL CONSTRAINT DF_PaieEmployeImport_Actif DEFAULT (1),

    [PeriodesParAnnee] INT NULL,
    [HeuresSemaine]    DECIMAL(9,2) NULL,
    [TauxHoraire]      DECIMAL(18,4) NULL,
    [SalaireAnnuel]    DECIMAL(18,2) NULL,
    [TauxVacances]     DECIMAL(9,4) NULL,

    -- Le dépôt direct : l'institution et le transit suffisent à savoir qu'il
    -- est en place. Le numéro de compte n'est pas repris, pour la même raison
    -- que le NAS.
    [DepotDirect]      BIT NOT NULL CONSTRAINT DF_PaieEmployeImport_DepotDirect DEFAULT (0),
    [Institution]      NVARCHAR(10) NULL,
    [Transit]          NVARCHAR(10) NULL,

    [Statut]           VARCHAR(20) NOT NULL CONSTRAINT DF_PaieEmployeImport_Statut DEFAULT ('OK'),
    [Anomalie]         NVARCHAR(500) NULL,
    [Created]          DATETIME NOT NULL CONSTRAINT DF_PaieEmployeImport_Created DEFAULT (SYSDATETIME())
);
GO

-- -----------------------------------------------------------------------------
-- 2) Le lot de paie — une période payée
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.PaieLotImport') IS NULL
CREATE TABLE staging.PaieLotImport (
    [Id]                INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PaieLotImport PRIMARY KEY,
    [ImportFileId]      INT NULL,
    [RunId]             INT NULL,
    [CompanyGUID]       UNIQUEIDENTIFIER NOT NULL,

    [Rang]              INT NOT NULL CONSTRAINT DF_PaieLotImport_Rang DEFAULT (0),
    [ExterneId]         NVARCHAR(100) NULL,
    [PeriodesParAnnee]  INT NULL,
    [DateDebutPeriode]  DATE NULL,
    [DateFinPeriode]    DATE NULL,
    [DatePaie]          DATE NULL,
    [StatutSource]      NVARCHAR(50) NULL,
    [NbPaies]           INT NOT NULL CONSTRAINT DF_PaieLotImport_NbPaies DEFAULT (0),
    [Created]           DATETIME NOT NULL CONSTRAINT DF_PaieLotImport_Created DEFAULT (SYSDATETIME())
);
GO

-- -----------------------------------------------------------------------------
-- 3) La paie d'un employé dans un lot
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.PaieImport') IS NULL
CREATE TABLE staging.PaieImport (
    [Id]                 INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PaieImport PRIMARY KEY,
    [ImportFileId]       INT NULL,
    [RunId]              INT NULL,
    [CompanyGUID]        UNIQUEIDENTIFIER NOT NULL,

    [Rang]               INT NOT NULL CONSTRAINT DF_PaieImport_Rang DEFAULT (0),
    [ExterneId]          NVARCHAR(100) NULL,
    [LotExterneId]       NVARCHAR(100) NULL,
    [EmployeExterneId]   NVARCHAR(100) NULL,
    [NumeroCheque]       NVARCHAR(50) NULL,

    [Heures]             DECIMAL(9,2) NULL,
    [BrutVerse]          DECIMAL(18,2) NULL,
    [AvantagesNonMonetaires] DECIMAL(18,2) NULL,

    -- Les retenues de l'employé
    [ImpotFederal]       DECIMAL(18,2) NULL,
    [ImpotQuebec]        DECIMAL(18,2) NULL,
    [RRQ]                DECIMAL(18,2) NULL,
    [RRQ2]               DECIMAL(18,2) NULL,
    [AE]                 DECIMAL(18,2) NULL,
    [RQAP]               DECIMAL(18,2) NULL,
    [AutresDeductions]   DECIMAL(18,2) NULL,
    [Net]                DECIMAL(18,2) NULL,

    -- Les charges de l'employeur
    [EmployeurRRQ]       DECIMAL(18,2) NULL,
    [EmployeurRRQ2]      DECIMAL(18,2) NULL,
    [EmployeurAE]        DECIMAL(18,2) NULL,
    [EmployeurRQAP]      DECIMAL(18,2) NULL,
    [EmployeurFSS]       DECIMAL(18,2) NULL,
    [EmployeurCNESST]    DECIMAL(18,2) NULL,
    [EmployeurCNT]       DECIMAL(18,2) NULL,

    [VacancesAccumulees] DECIMAL(18,2) NULL,
    [VacancesPayees]     DECIMAL(18,2) NULL,

    -- Le contrôle, calculé À L'ARRIVÉE et jamais appliqué : brut moins retenues
    -- doit faire le net. Un écart se signale, il ne se corrige pas.
    [EcartNet]           DECIMAL(18,2) NULL,
    [Statut]             VARCHAR(20) NOT NULL CONSTRAINT DF_PaieImport_Statut DEFAULT ('OK'),
    [Anomalie]           NVARCHAR(500) NULL,
    [Created]            DATETIME NOT NULL CONSTRAINT DF_PaieImport_Created DEFAULT (SYSDATETIME())
);
GO

-- -----------------------------------------------------------------------------
-- 4) Les lignes d'une paie
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.PaieLigneImport') IS NULL
CREATE TABLE staging.PaieLigneImport (
    [Id]              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PaieLigneImport PRIMARY KEY,
    [CompanyGUID]     UNIQUEIDENTIFIER NOT NULL,
    [PaieExterneId]   NVARCHAR(100) NULL,
    [Rang]            INT NOT NULL CONSTRAINT DF_PaieLigneImport_Rang DEFAULT (0),
    [ElementCode]     NVARCHAR(50) NULL,
    [Description]     NVARCHAR(400) NULL,
    [CategorieCode]   NVARCHAR(50) NULL,
    [Heures]          DECIMAL(9,2) NULL,
    [Taux]            DECIMAL(18,4) NULL,
    [Montant]         DECIMAL(18,2) NULL,
    [CompteGL]        NVARCHAR(100) NULL,
    [Created]         DATETIME NOT NULL CONSTRAINT DF_PaieLigneImport_Created DEFAULT (SYSDATETIME())
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PaieImport_Compagnie')
    CREATE INDEX IX_PaieImport_Compagnie ON staging.PaieImport ([CompanyGUID], [Rang]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PaieLigneImport_Paie')
    CREATE INDEX IX_PaieLigneImport_Paie ON staging.PaieLigneImport ([CompanyGUID], [PaieExterneId], [Rang]);
GO

-- -----------------------------------------------------------------------------
-- s0829ChargerPaie — les quatre tables d'un seul coup
--
-- Tout ou rien. Des employés sans leurs paies, ou des paies sans leurs lignes,
-- donneraient une reprise d'apparence complète et fausse en détail.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0829ChargerPaie]
    @RunId        INT,
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL,
    @Employes     NVARCHAR(MAX),
    @Lots         NVARCHAR(MAX),
    @Paies        NVARCHAR(MAX),
    @Lignes       NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50399, 'Aucune compagnie : impossible de déposer une paie.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.PaieLigneImport   WHERE [CompanyGUID] = @CompanyGUID;
    DELETE FROM staging.PaieImport        WHERE [CompanyGUID] = @CompanyGUID;
    DELETE FROM staging.PaieLotImport     WHERE [CompanyGUID] = @CompanyGUID;
    DELETE FROM staging.PaieEmployeImport WHERE [CompanyGUID] = @CompanyGUID;

    -- ── Les employés ────────────────────────────────────────────────────────
    INSERT INTO staging.PaieEmployeImport
        ([RunId], [ImportFileId], [CompanyGUID], [Rang], [ExterneId], [Code],
         [Prenom], [Nom], [Courriel], [Telephone], [Adresse1], [Ville], [Province],
         [CodePostal], [Langue], [DateNaissance], [NASFourni], [Poste],
         [DateEmbauche], [DateFinEmploi], [Actif], [PeriodesParAnnee], [HeuresSemaine],
         [TauxHoraire], [SalaireAnnuel], [TauxVacances], [DepotDirect], [Institution],
         [Transit], [Statut], [Anomalie])
    SELECT @RunId, @ImportFileId, @CompanyGUID,
           ISNULL(TRY_CONVERT(INT, NULLIF(j.[rang], '')), 0),
           LEFT(j.[externe_id], 100), LEFT(j.[code], 50),
           j.[prenom], j.[nom], LEFT(j.[courriel], 320), LEFT(j.[telephone], 50),
           j.[adresse1], j.[ville], LEFT(j.[province], 10), LEFT(j.[code_postal], 20),
           LEFT(j.[langue], 10),
           TRY_CONVERT(DATE, NULLIF(j.[date_naissance], '')),
           CASE WHEN j.[nas_fourni] = 'true' THEN 1 ELSE 0 END,
           j.[poste],
           TRY_CONVERT(DATE, NULLIF(j.[date_embauche], '')),
           TRY_CONVERT(DATE, NULLIF(j.[date_fin], '')),
           CASE WHEN j.[actif] = 'false' THEN 0 ELSE 1 END,
           TRY_CONVERT(INT, NULLIF(j.[periodes], '')),
           TRY_CONVERT(DECIMAL(9,2), NULLIF(j.[heures_semaine], '')),
           TRY_CONVERT(DECIMAL(18,4), NULLIF(j.[taux_horaire], '')),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[salaire_annuel], '')),
           TRY_CONVERT(DECIMAL(9,4), NULLIF(j.[taux_vacances], '')),
           CASE WHEN j.[depot_direct] = 'true' THEN 1 ELSE 0 END,
           LEFT(j.[institution], 10), LEFT(j.[transit], 10),
           -- Un employé sans nom ni code ne pourra pas être rapproché.
           CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(j.[nom], ''))), '') IS NULL
                 AND NULLIF(LTRIM(RTRIM(ISNULL(j.[code], ''))), '') IS NULL
                THEN 'ANOMALIE' ELSE 'OK' END,
           CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(j.[nom], ''))), '') IS NULL
                 AND NULLIF(LTRIM(RTRIM(ISNULL(j.[code], ''))), '') IS NULL
                THEN N'Ni nom ni code : impossible de reconnaître cet employé.' END
      FROM OPENJSON(@Employes)
           WITH ([rang] NVARCHAR(40) '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                 [code] NVARCHAR(50) '$.code', [prenom] NVARCHAR(200) '$.prenom',
                 [nom] NVARCHAR(200) '$.nom', [courriel] NVARCHAR(320) '$.courriel',
                 [telephone] NVARCHAR(50) '$.telephone', [adresse1] NVARCHAR(300) '$.adresse1',
                 [ville] NVARCHAR(200) '$.ville', [province] NVARCHAR(20) '$.province',
                 [code_postal] NVARCHAR(20) '$.code_postal', [langue] NVARCHAR(20) '$.langue',
                 [date_naissance] NVARCHAR(40) '$.date_naissance',
                 [nas_fourni] NVARCHAR(10) '$.nas_fourni', [poste] NVARCHAR(200) '$.poste',
                 [date_embauche] NVARCHAR(40) '$.date_embauche', [date_fin] NVARCHAR(40) '$.date_fin',
                 [actif] NVARCHAR(10) '$.actif', [periodes] NVARCHAR(40) '$.periodes',
                 [heures_semaine] NVARCHAR(40) '$.heures_semaine',
                 [taux_horaire] NVARCHAR(40) '$.taux_horaire',
                 [salaire_annuel] NVARCHAR(40) '$.salaire_annuel',
                 [taux_vacances] NVARCHAR(40) '$.taux_vacances',
                 [depot_direct] NVARCHAR(10) '$.depot_direct',
                 [institution] NVARCHAR(10) '$.institution', [transit] NVARCHAR(10) '$.transit') AS j;

    DECLARE @nEmp INT = @@ROWCOUNT;

    -- ── Les lots ────────────────────────────────────────────────────────────
    INSERT INTO staging.PaieLotImport
        ([RunId], [ImportFileId], [CompanyGUID], [Rang], [ExterneId], [PeriodesParAnnee],
         [DateDebutPeriode], [DateFinPeriode], [DatePaie], [StatutSource])
    SELECT @RunId, @ImportFileId, @CompanyGUID,
           ISNULL(TRY_CONVERT(INT, NULLIF(j.[rang], '')), 0),
           LEFT(j.[externe_id], 100),
           TRY_CONVERT(INT, NULLIF(j.[periodes], '')),
           TRY_CONVERT(DATE, NULLIF(j.[debut], '')),
           TRY_CONVERT(DATE, NULLIF(j.[fin], '')),
           TRY_CONVERT(DATE, NULLIF(j.[date_paie], '')),
           LEFT(j.[statut], 50)
      FROM OPENJSON(@Lots)
           WITH ([rang] NVARCHAR(40) '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                 [periodes] NVARCHAR(40) '$.periodes', [debut] NVARCHAR(40) '$.debut',
                 [fin] NVARCHAR(40) '$.fin', [date_paie] NVARCHAR(40) '$.date_paie',
                 [statut] NVARCHAR(50) '$.statut') AS j;

    DECLARE @nLots INT = @@ROWCOUNT;

    -- ── Les paies ───────────────────────────────────────────────────────────
    INSERT INTO staging.PaieImport
        ([RunId], [ImportFileId], [CompanyGUID], [Rang], [ExterneId], [LotExterneId],
         [EmployeExterneId], [NumeroCheque], [Heures], [BrutVerse], [AvantagesNonMonetaires],
         [ImpotFederal], [ImpotQuebec], [RRQ], [RRQ2], [AE], [RQAP], [AutresDeductions], [Net],
         [EmployeurRRQ], [EmployeurRRQ2], [EmployeurAE], [EmployeurRQAP], [EmployeurFSS],
         [EmployeurCNESST], [EmployeurCNT], [VacancesAccumulees], [VacancesPayees],
         [EcartNet], [Statut], [Anomalie])
    SELECT @RunId, @ImportFileId, @CompanyGUID,
           ISNULL(TRY_CONVERT(INT, NULLIF(j.[rang], '')), 0),
           LEFT(j.[externe_id], 100), LEFT(j.[lot_id], 100), LEFT(j.[employe_id], 100),
           LEFT(j.[cheque], 50),
           TRY_CONVERT(DECIMAL(9,2), NULLIF(j.[heures], '')),
           x.[brut], TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[avantages], '')),
           x.[fed], x.[qc], x.[rrq], x.[rrq2], x.[ae], x.[rqap], x.[autres], x.[net],
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[e_rrq], '')),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[e_rrq2], '')),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[e_ae], '')),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[e_rqap], '')),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[e_fss], '')),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[e_cnesst], '')),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[e_cnt], '')),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[vac_accum], '')),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[vac_payees], '')),
           x.[ecart],
           CASE WHEN ABS(x.[ecart]) > 0.01 THEN 'ANOMALIE' ELSE 'OK' END,
           CASE WHEN ABS(x.[ecart]) > 0.01
                THEN N'Le net ne correspond pas au brut moins les retenues : écart de '
                     + CONVERT(NVARCHAR(30), x.[ecart]) + N' $. Repris tel quel, non corrigé.' END
      FROM OPENJSON(@Paies)
           WITH ([rang] NVARCHAR(40) '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                 [lot_id] NVARCHAR(100) '$.lot_id', [employe_id] NVARCHAR(100) '$.employe_id',
                 [cheque] NVARCHAR(50) '$.cheque', [heures] NVARCHAR(40) '$.heures',
                 [brut] NVARCHAR(40) '$.brut', [avantages] NVARCHAR(40) '$.avantages',
                 [fed] NVARCHAR(40) '$.fed', [qc] NVARCHAR(40) '$.qc',
                 [rrq] NVARCHAR(40) '$.rrq', [rrq2] NVARCHAR(40) '$.rrq2',
                 [ae] NVARCHAR(40) '$.ae', [rqap] NVARCHAR(40) '$.rqap',
                 [autres] NVARCHAR(40) '$.autres', [net] NVARCHAR(40) '$.net',
                 [e_rrq] NVARCHAR(40) '$.e_rrq', [e_rrq2] NVARCHAR(40) '$.e_rrq2',
                 [e_ae] NVARCHAR(40) '$.e_ae', [e_rqap] NVARCHAR(40) '$.e_rqap',
                 [e_fss] NVARCHAR(40) '$.e_fss', [e_cnesst] NVARCHAR(40) '$.e_cnesst',
                 [e_cnt] NVARCHAR(40) '$.e_cnt', [vac_accum] NVARCHAR(40) '$.vac_accum',
                 [vac_payees] NVARCHAR(40) '$.vac_payees') AS j
     CROSS APPLY (
        SELECT ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[brut], '')), 0)   AS [brut],
               ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[fed], '')), 0)    AS [fed],
               ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[qc], '')), 0)     AS [qc],
               ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[rrq], '')), 0)    AS [rrq],
               ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[rrq2], '')), 0)   AS [rrq2],
               ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[ae], '')), 0)     AS [ae],
               ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[rqap], '')), 0)   AS [rqap],
               ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[autres], '')), 0) AS [autres],
               ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[net], '')), 0)    AS [net]
     ) AS v
     CROSS APPLY (
        SELECT v.[brut], v.[fed], v.[qc], v.[rrq], v.[rrq2], v.[ae], v.[rqap],
               v.[autres], v.[net],
               v.[brut] - (v.[fed] + v.[qc] + v.[rrq] + v.[rrq2] + v.[ae] + v.[rqap]
                           + v.[autres]) - v.[net] AS [ecart]
     ) AS x;

    DECLARE @nPaies INT = @@ROWCOUNT;

    -- ── Les lignes ──────────────────────────────────────────────────────────
    INSERT INTO staging.PaieLigneImport
        ([CompanyGUID], [PaieExterneId], [Rang], [ElementCode], [Description],
         [CategorieCode], [Heures], [Taux], [Montant], [CompteGL])
    SELECT @CompanyGUID, LEFT(j.[paie_id], 100),
           ISNULL(TRY_CONVERT(INT, NULLIF(j.[rang], '')), 0),
           LEFT(j.[element], 50), j.[description], LEFT(j.[categorie], 50),
           TRY_CONVERT(DECIMAL(9,2), NULLIF(j.[heures], '')),
           TRY_CONVERT(DECIMAL(18,4), NULLIF(j.[taux], '')),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[montant], '')),
           LEFT(j.[compte], 100)
      FROM OPENJSON(@Lignes)
           WITH ([paie_id] NVARCHAR(100) '$.paie_id', [rang] NVARCHAR(40) '$.rang',
                 [element] NVARCHAR(50) '$.element', [description] NVARCHAR(400) '$.description',
                 [categorie] NVARCHAR(50) '$.categorie', [heures] NVARCHAR(40) '$.heures',
                 [taux] NVARCHAR(40) '$.taux', [montant] NVARCHAR(40) '$.montant',
                 [compte] NVARCHAR(100) '$.compte') AS j;

    DECLARE @nLignes INT = @@ROWCOUNT;

    -- Le nombre de paies par lot, pour l'écran.
    UPDATE l
       SET l.[NbPaies] = (SELECT COUNT(*) FROM staging.PaieImport p
                           WHERE p.[CompanyGUID] = @CompanyGUID
                             AND p.[LotExterneId] = l.[ExterneId])
      FROM staging.PaieLotImport l
     WHERE l.[CompanyGUID] = @CompanyGUID;

    COMMIT TRANSACTION;

    SELECT @nEmp AS [NbEmployes], @nLots AS [NbLots],
           @nPaies AS [NbPaies], @nLignes AS [NbLignes],
           (SELECT COUNT(*) FROM staging.PaieImport
             WHERE [CompanyGUID] = @CompanyGUID AND [Statut] <> 'OK') AS [NbAnomalies];
END
GO

-- -----------------------------------------------------------------------------
-- s0830GetPaie — ce que l'écran affiche
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0830GetPaie]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- 0) Le récapitulatif
    SELECT (SELECT COUNT(*) FROM staging.PaieEmployeImport WHERE [CompanyGUID] = @CompanyGUID) AS [NbEmployes],
           (SELECT COUNT(*) FROM staging.PaieLotImport     WHERE [CompanyGUID] = @CompanyGUID) AS [NbLots],
           (SELECT COUNT(*) FROM staging.PaieImport        WHERE [CompanyGUID] = @CompanyGUID) AS [NbPaies],
           (SELECT SUM(ISNULL([BrutVerse], 0)) FROM staging.PaieImport WHERE [CompanyGUID] = @CompanyGUID) AS [TotalBrut],
           (SELECT SUM(ISNULL([Net], 0))       FROM staging.PaieImport WHERE [CompanyGUID] = @CompanyGUID) AS [TotalNet],
           (SELECT SUM(ISNULL([EmployeurRRQ],0) + ISNULL([EmployeurRRQ2],0) + ISNULL([EmployeurAE],0)
                     + ISNULL([EmployeurRQAP],0) + ISNULL([EmployeurFSS],0) + ISNULL([EmployeurCNESST],0)
                     + ISNULL([EmployeurCNT],0))
              FROM staging.PaieImport WHERE [CompanyGUID] = @CompanyGUID) AS [TotalCharges],
           (SELECT COUNT(*) FROM staging.PaieImport WHERE [CompanyGUID] = @CompanyGUID AND [Statut] <> 'OK') AS [NbAnomalies],
           (SELECT MAX([Created]) FROM staging.PaieImport WHERE [CompanyGUID] = @CompanyGUID) AS [Depose];

    -- 1) Les employés
    SELECT [Rang], [ExterneId], [Code], [Prenom], [Nom], [Courriel], [Poste],
           [DateEmbauche], [DateFinEmploi], [Actif], [PeriodesParAnnee], [HeuresSemaine],
           [TauxHoraire], [SalaireAnnuel], [TauxVacances], [DepotDirect], [Institution],
           [Transit], [NASFourni], [Statut], [Anomalie]
      FROM staging.PaieEmployeImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY [Rang], [Id];

    -- 2) Les lots
    SELECT [Rang], [ExterneId], [PeriodesParAnnee], [DateDebutPeriode], [DateFinPeriode],
           [DatePaie], [StatutSource], [NbPaies]
      FROM staging.PaieLotImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY [DatePaie], [Rang], [Id];

    -- 3) Les paies, avec le nom de l'employé
    SELECT p.[Rang], p.[ExterneId], p.[LotExterneId], p.[EmployeExterneId], p.[NumeroCheque],
           p.[Heures], p.[BrutVerse], p.[ImpotFederal], p.[ImpotQuebec], p.[RRQ], p.[RRQ2],
           p.[AE], p.[RQAP], p.[AutresDeductions], p.[Net],
           p.[EmployeurRRQ] + p.[EmployeurRRQ2] + p.[EmployeurAE] + p.[EmployeurRQAP]
             + p.[EmployeurFSS] + p.[EmployeurCNESST] + p.[EmployeurCNT] AS [ChargesEmployeur],
           p.[VacancesAccumulees], p.[EcartNet], p.[Statut], p.[Anomalie],
           e.[Prenom] + ' ' + e.[Nom] AS [EmployeNom], l.[DatePaie]
      FROM staging.PaieImport p
      LEFT JOIN staging.PaieEmployeImport e
        ON e.[CompanyGUID] = p.[CompanyGUID] AND e.[ExterneId] = p.[EmployeExterneId]
      LEFT JOIN staging.PaieLotImport l
        ON l.[CompanyGUID] = p.[CompanyGUID] AND l.[ExterneId] = p.[LotExterneId]
     WHERE p.[CompanyGUID] = @CompanyGUID
     ORDER BY CASE WHEN p.[Statut] <> 'OK' THEN 0 ELSE 1 END, l.[DatePaie], p.[Rang], p.[Id];

    -- 4) Les lignes
    SELECT [PaieExterneId], [Rang], [ElementCode], [Description], [CategorieCode],
           [Heures], [Taux], [Montant], [CompteGL]
      FROM staging.PaieLigneImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY [PaieExterneId], [Rang], [Id];
END
GO

-- -----------------------------------------------------------------------------
-- La liste blanche du registre accueille « Paie »
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_staging_ImportFiles_TypeImport')
    ALTER TABLE staging.ImportFiles DROP CONSTRAINT CK_staging_ImportFiles_TypeImport;
GO

ALTER TABLE staging.ImportFiles WITH CHECK
    ADD CONSTRAINT CK_staging_ImportFiles_TypeImport CHECK ([TypeImport] IN (
        -- Structure
        'PlanComptable', 'Societe', 'Taxe', 'ModePaiement', 'ConditionPaiement',
        'CategorieSuivi', 'Departement', 'Emplacement', 'CompteBancaire',
        -- Tiers et articles
        'Client', 'Fournisseur', 'Produit',
        -- Ventes et achats
        'FactureClient', 'FactureFournisseur', 'AvoirClient', 'AvoirFournisseur',
        'Depense', 'RecuVente', 'Soumission', 'BonCommande',
        'Encaissement', 'Decaissement', 'Remboursement',
        -- Paie
        'Paie',
        -- Grand livre et contrôles
        'EcritureJournal', 'PieceJointe',
        'GrandLivre', 'Rapprochement',
        'BalanceVerification',
        'BalanceAgeeClient', 'BalanceAgeeFournisseur',
        'RapportBilan', 'RapportResultats', 'RapportTaxes',
        -- Anciens types : gardés pour les fichiers déjà inscrits
        'BalanceAgee', 'Rapport'
    ));
GO
