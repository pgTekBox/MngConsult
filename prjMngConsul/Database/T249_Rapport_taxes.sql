-- =============================================================================
-- T249 — Les rapports de taxes en préparation
--
-- Le poste « Taxes » de l'écran d'import : les déclarations que la source tient
-- pour l'exercice. Au Québec, c'est le formulaire que tout le monde connaît —
-- ligne 101 les ventes, 106 le CTI, 206 le RTI, 217 le montant à payer ou à
-- rembourser. Apideck ne l'expose pas, il arrive par la passerelle, comme la
-- balance de vérification et le grand livre.
--
-- CE QU'ON N'EN FAIT PAS. Rien. Aucune écriture, aucun compte, aucune
-- déclaration produite. C'est une PIÈCE DE CONTRÔLE : elle reste en
-- préparation, on la regarde, on la compare, et elle est remplacée à la
-- prochaine extraction. La comptabilité de l'application n'en sait rien.
--
-- TROIS DIMENSIONS, PAS UNE. Un abonné n'a pas UN rapport de taxes : il en a un
-- par PÉRIODE DE DÉCLARATION et par ADMINISTRATION FISCALE. Un trimestriel
-- québécois arrivé en septembre en a trois — janvier-mars, avril-juin, puis le
-- trimestre en cours arrêté à la date demandée. La table porte donc les deux :
--
--   PeriodeOrdre + PeriodeDebut/Fin   la déclaration
--   AgenceId + AgenceNom              qui la reçoit
--   LigneCode + Libelle               la ligne du formulaire
--   ColonneOrdre + ColonneTitre       la colonne, telle que la source la nomme
--
-- L'écran croise les deux premières en colonnes et la troisième en lignes : les
-- déclarations se lisent côte à côte, comme au centre de taxes de la source.
--
-- POURQUOI LA TABLE EST HAUTE PLUTÔT QUE LARGE. Les colonnes de ce rapport ne
-- sont pas les mêmes partout : elles suivent le régime de taxes du pays et de
-- la province. Un abonné ontarien n'a pas les lignes d'un québécois, et un
-- rapport résumé par mois aurait une colonne par mois au lieu d'un « Total ».
-- Deviner leur nombre et leur ordre serait l'erreur commise sur le grand livre,
-- où la huitième colonne s'est avérée être un solde cumulé sous l'entête
-- « Crédit ». Alors : UNE LIGNE PAR CELLULE, chacune portant le titre que la
-- source donne à sa colonne et la clé technique qui l'accompagne.
--
-- Procédures : s0822 (charger), s0823 (lire).
-- La liste blanche du registre accueille « RapportTaxes ».
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('staging.TaxeRapportImport') IS NULL
CREATE TABLE staging.TaxeRapportImport (
    [Id]            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TaxeRapportImport PRIMARY KEY,
    [ImportFileId]  INT NULL,
    [RunId]         INT NULL,
    [CompanyGUID]   UNIQUEIDENTIFIER NOT NULL,

    -- La période de déclaration. Les dates sont celles que la source a
    -- réellement retenues, pas celles qu'on croit avoir demandées.
    [PeriodeOrdre]  INT NOT NULL CONSTRAINT DF_TaxeRapportImport_PeriodeOrdre DEFAULT (0),
    [PeriodeDebut]  DATE NULL,
    [PeriodeFin]    DATE NULL,
    [Devise]        VARCHAR(10) NULL,

    -- L'administration fiscale qui reçoit la déclaration
    [AgenceId]      NVARCHAR(50) NULL,
    [AgenceNom]     NVARCHAR(200) NULL,

    -- La ligne du rapport
    [LigneOrdre]    INT NOT NULL CONSTRAINT DF_TaxeRapportImport_LigneOrdre DEFAULT (0),
    [Niveau]        INT NOT NULL CONSTRAINT DF_TaxeRapportImport_Niveau DEFAULT (0),
    [LigneCode]     NVARCHAR(100) NULL,   -- « Ligne 106 » : le code que la source donne à la ligne
    [Groupe]        NVARCHAR(400) NULL,   -- la section qui la contient, quand le rapport en a
    [Libelle]       NVARCHAR(400) NULL,   -- la première colonne : ce que la ligne nomme
    [EstTotal]      BIT NOT NULL CONSTRAINT DF_TaxeRapportImport_EstTotal DEFAULT (0),

    -- La cellule
    [ColonneOrdre]  INT NOT NULL CONSTRAINT DF_TaxeRapportImport_ColonneOrdre DEFAULT (0),
    [ColonneTitre]  NVARCHAR(200) NULL,   -- le titre tel que la source l'écrit
    [ColonneCle]    NVARCHAR(100) NULL,   -- sa clé technique (ColKey), quand elle en donne une
    [Valeur]        NVARCHAR(400) NULL,   -- la valeur brute, telle quelle
    [Montant]       DECIMAL(18,2) NULL,   -- la même, quand elle se lit comme un nombre

    [Created]       DATETIME NOT NULL CONSTRAINT DF_TaxeRapportImport_Created DEFAULT (SYSDATETIME())
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TaxeRapportImport_Compagnie')
    CREATE INDEX IX_TaxeRapportImport_Compagnie
        ON staging.TaxeRapportImport ([CompanyGUID], [PeriodeOrdre], [LigneOrdre], [ColonneOrdre]);
GO

-- -----------------------------------------------------------------------------
-- s0822ChargerRapportTaxes — dépose les déclarations lues chez la source
--
-- Une seule extraction en préparation à la fois : la nouvelle remplace la
-- précédente, toutes périodes et toutes administrations confondues. Garder un
-- trimestre et remplacer l'autre ne voudrait rien dire.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0822ChargerRapportTaxes]
    @RunId        INT,
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL,
    @Lignes       NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50396, 'Aucune compagnie : impossible de déposer un rapport de taxes.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.TaxeRapportImport WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.TaxeRapportImport
        ([RunId], [ImportFileId], [CompanyGUID],
         [PeriodeOrdre], [PeriodeDebut], [PeriodeFin], [Devise],
         [AgenceId], [AgenceNom],
         [LigneOrdre], [Niveau], [LigneCode], [Groupe], [Libelle], [EstTotal],
         [ColonneOrdre], [ColonneTitre], [ColonneCle], [Valeur], [Montant])
    SELECT @RunId, @ImportFileId, @CompanyGUID,
           ISNULL(TRY_CONVERT(INT, NULLIF(j.[periode_ordre], '')), 0),
           TRY_CONVERT(DATE, NULLIF(j.[debut], '')),
           TRY_CONVERT(DATE, NULLIF(j.[fin], '')),
           LEFT(j.[devise], 10),
           LEFT(j.[agence_id], 50),
           LEFT(j.[agence], 200),
           ISNULL(TRY_CONVERT(INT, NULLIF(j.[ligne_ordre], '')), 0),
           ISNULL(TRY_CONVERT(INT, NULLIF(j.[niveau], '')), 0),
           LEFT(j.[ligne_code], 100),
           j.[groupe],
           j.[libelle],
           CASE WHEN j.[est_total] = '1' THEN 1 ELSE 0 END,
           ISNULL(TRY_CONVERT(INT, NULLIF(j.[colonne_ordre], '')), 0),
           LEFT(j.[colonne_titre], 200),
           LEFT(j.[colonne_cle], 100),
           j.[valeur],
           -- Le montant est un CONFORT, pas la source de vérité : la valeur
           -- brute reste à côté. Une cellule qui ne se lit pas comme un nombre
           -- reste lisible plutôt que de disparaître.
           TRY_CONVERT(DECIMAL(18,2), NULLIF(REPLACE(j.[valeur], ' ', ''), ''))
      FROM OPENJSON(@Lignes)
           WITH ([periode_ordre]  NVARCHAR(40)  '$.periode_ordre',
                 [debut]          NVARCHAR(40)  '$.debut',
                 [fin]            NVARCHAR(40)  '$.fin',
                 [devise]         NVARCHAR(20)  '$.devise',
                 [agence_id]      NVARCHAR(50)  '$.agence_id',
                 [agence]         NVARCHAR(200) '$.agence',
                 [ligne_ordre]    NVARCHAR(40)  '$.ligne_ordre',
                 [niveau]         NVARCHAR(40)  '$.niveau',
                 [ligne_code]     NVARCHAR(100) '$.ligne_code',
                 [groupe]         NVARCHAR(400) '$.groupe',
                 [libelle]        NVARCHAR(400) '$.libelle',
                 [est_total]      NVARCHAR(10)  '$.est_total',
                 [colonne_ordre]  NVARCHAR(40)  '$.colonne_ordre',
                 [colonne_titre]  NVARCHAR(200) '$.colonne_titre',
                 [colonne_cle]    NVARCHAR(100) '$.colonne_cle',
                 [valeur]         NVARCHAR(400) '$.valeur') AS j;

    DECLARE @n INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @n AS [NbCellules],
           (SELECT COUNT(DISTINCT [PeriodeOrdre]) FROM staging.TaxeRapportImport
             WHERE [CompanyGUID] = @CompanyGUID) AS [NbPeriodes],
           (SELECT COUNT(DISTINCT [AgenceNom]) FROM staging.TaxeRapportImport
             WHERE [CompanyGUID] = @CompanyGUID) AS [NbAgences],
           (SELECT COUNT(DISTINCT ISNULL(NULLIF([LigneCode], ''), [Libelle]))
              FROM staging.TaxeRapportImport
             WHERE [CompanyGUID] = @CompanyGUID) AS [NbLignes];
END
GO

-- -----------------------------------------------------------------------------
-- s0823GetRapportTaxes — ce que l'écran affiche
--
-- Quatre jeux, parce que le tableau a deux axes :
--   0) l'entête de l'extraction
--   1) les COLONNES : une par (période × colonne du rapport)
--   2) les LIGNES : une par (administration × ligne du formulaire)
--   3) les CELLULES, qui croisent les deux
--
-- La ligne est identifiée par son CODE quand la source en donne un — « Ligne
-- 106 » — et par son libellé sinon. C'est ce qui permet de reconnaître la même
-- ligne d'une période à l'autre : leur ordre d'apparition, lui, ne se répète
-- pas d'un rapport au suivant.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0823GetRapportTaxes]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- 0) L'entête
    SELECT MIN([PeriodeDebut])                AS [PeriodeDebut],
           MAX([PeriodeFin])                  AS [PeriodeFin],
           MAX([Devise])                      AS [Devise],
           COUNT(*)                           AS [NbCellules],
           COUNT(DISTINCT [PeriodeOrdre])     AS [NbPeriodes],
           COUNT(DISTINCT [AgenceNom])        AS [NbAgences],
           COUNT(DISTINCT ISNULL(NULLIF([LigneCode], ''), [Libelle])) AS [NbLignes],
           MAX([Created])                     AS [Depose]
      FROM staging.TaxeRapportImport
     WHERE [CompanyGUID] = @CompanyGUID;

    -- 1) Les colonnes : une par période, et par colonne du rapport
    SELECT [PeriodeOrdre], [ColonneOrdre],
           MIN([PeriodeDebut])  AS [PeriodeDebut],
           MAX([PeriodeFin])    AS [PeriodeFin],
           MAX([ColonneTitre])  AS [ColonneTitre],
           MAX([ColonneCle])    AS [ColonneCle]
      FROM staging.TaxeRapportImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND [ColonneOrdre] > 0
     GROUP BY [PeriodeOrdre], [ColonneOrdre]
     ORDER BY [PeriodeOrdre], [ColonneOrdre];

    -- 2) Les lignes, dans l'ordre où la première période les a écrites
    SELECT ISNULL(NULLIF([LigneCode], ''), [Libelle]) AS [CleLigne],
           [AgenceId],
           MAX([AgenceNom])    AS [AgenceNom],
           MAX([LigneCode])    AS [LigneCode],
           MAX([Libelle])      AS [Libelle],
           MIN([Niveau])       AS [Niveau],
           MAX(CONVERT(INT, [EstTotal])) AS [EstTotal],
           MIN([LigneOrdre])   AS [Ordre]
      FROM staging.TaxeRapportImport
     WHERE [CompanyGUID] = @CompanyGUID
     GROUP BY ISNULL(NULLIF([LigneCode], ''), [Libelle]), [AgenceId]
     ORDER BY MIN([LigneOrdre]);

    -- 3) Les cellules
    SELECT ISNULL(NULLIF([LigneCode], ''), [Libelle]) AS [CleLigne],
           [AgenceId], [PeriodeOrdre], [ColonneOrdre], [Valeur], [Montant]
      FROM staging.TaxeRapportImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND [ColonneOrdre] > 0
     ORDER BY [LigneOrdre], [PeriodeOrdre], [ColonneOrdre];
END
GO

-- -----------------------------------------------------------------------------
-- La liste blanche du registre accueille « RapportTaxes »
--
-- Même précaution qu'en T245 et T247 : une contrainte CHECK ne s'étend pas,
-- elle se remplace. Tout ce qui y était y reste.
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_staging_ImportFiles_TypeImport')
    ALTER TABLE staging.ImportFiles DROP CONSTRAINT CK_staging_ImportFiles_TypeImport;
GO

ALTER TABLE staging.ImportFiles WITH CHECK
    ADD CONSTRAINT CK_staging_ImportFiles_TypeImport CHECK ([TypeImport] IN (
        -- Structure
        'PlanComptable', 'Societe', 'Taxe', 'ModePaiement', 'ConditionPaiement',
        'CategorieSuivi', 'Departement', 'Emplacement',
        -- Tiers et articles
        'Client', 'Fournisseur', 'Produit',
        -- Ventes et achats
        'FactureClient', 'FactureFournisseur', 'AvoirClient', 'AvoirFournisseur',
        'Depense', 'RecuVente', 'Soumission', 'BonCommande',
        'Encaissement', 'Decaissement', 'Remboursement',
        -- Grand livre et contrôles
        'EcritureJournal', 'PieceJointe',
        'GrandLivre',
        'BalanceVerification',
        'BalanceAgeeClient', 'BalanceAgeeFournisseur',
        'RapportBilan', 'RapportResultats', 'RapportTaxes',
        -- Anciens types : gardés pour les fichiers déjà inscrits
        'BalanceAgee', 'Rapport'
    ));
GO
