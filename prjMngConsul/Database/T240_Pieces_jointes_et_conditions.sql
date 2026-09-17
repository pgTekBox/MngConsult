-- =============================================================================
-- T240 — Les pièces jointes et les conditions de paiement
--
-- Les deux derniers éléments que QuickBooks veut bien donner et qu'on n'avait
-- pas. Ils n'arrivent ni l'un ni l'autre comme les autres ressources.
--
-- LES PIÈCES JOINTES. Apideck n'en rend pas de liste : l'adresse est
-- /accounting/attachments/{type}/{id}. Il faut donc demander document par
-- document, ce qui suppose que les documents soient DÉJÀ en préparation — d'où
-- s0815, qui rend la liste de ce qu'il faut interroger. Types acceptés, vérifiés
-- en direct : invoice, bill, expense, credit-note, bill-credit-note,
-- journal-entry, quote. Les reçus de vente et les bons de commande sont refusés
-- par Apideck : leurs pièces jointes resteront inaccessibles.
--
-- ⚠️ Seules les MÉTADONNÉES sont conservées — nom, type, taille, adresse de
--    téléchargement. Pas les octets. Rapatrier des centaines de PDF pendant une
--    extraction la ferait durer des heures et ne servirait à rien tant que
--    personne ne les a validés. L'adresse permet de les chercher plus tard,
--    au cas par cas.
--
-- LES CONDITIONS DE PAIEMENT. Apideck ne les cartographie pas du tout : elles
-- viennent du passe-plat, donc de l'API native d'Intuit. Forme réelle observée :
--    { Id, Name, Type:"STANDARD", DueDays:30, DiscountDays:0, Active:true }
-- Elles comptent parce qu'elles décident de l'échéance des factures qu'on
-- importe déjà — « Net 30 » n'est pas une étiquette, c'est une date.
--
-- Procédures : s0814 à s0818.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) Le registre accepte les deux nouveaux types
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_staging_ImportFiles_TypeImport')
    ALTER TABLE staging.ImportFiles DROP CONSTRAINT CK_staging_ImportFiles_TypeImport;
GO

ALTER TABLE staging.ImportFiles WITH CHECK
    ADD CONSTRAINT CK_staging_ImportFiles_TypeImport CHECK
    ([TypeImport] IN ('Client', 'Fournisseur', 'Produit',
                      'PlanComptable', 'FactureClient', 'FactureFournisseur',
                      'Societe', 'Taxe',
                      'ModePaiement', 'CategorieSuivi', 'Departement', 'Emplacement',
                      'AvoirClient', 'AvoirFournisseur', 'Depense', 'RecuVente',
                      'Soumission', 'BonCommande',
                      'Encaissement', 'Decaissement', 'Remboursement',
                      'EcritureJournal', 'Rapport', 'BalanceAgee',
                      'PieceJointe', 'ConditionPaiement'));
GO

-- -----------------------------------------------------------------------------
-- 2) staging.PieceJointeImport
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.PieceJointeImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.PieceJointeImport
    (
        [Id]                 INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]       INT               NULL,
        [RunId]              INT               NULL,
        [CompanyGUID]        UNIQUEIDENTIFIER  NOT NULL,

        -- Le document porteur, chez la source : invoice, bill, expense,
        -- credit-note, bill-credit-note, journal-entry, quote.
        [DocumentGenre]      VARCHAR(30)       NOT NULL,
        [DocumentExterneId]  NVARCHAR(100)     NOT NULL,
        [DocumentNumero]     NVARCHAR(60)      NULL,

        [ExterneId]          NVARCHAR(100)     NULL,
        [NomFichier]         NVARCHAR(400)     NULL,
        [Description]        NVARCHAR(1000)    NULL,
        [TypeContenu]        NVARCHAR(150)     NULL,
        [Taille]             BIGINT            NULL,

        -- L'adresse de téléchargement. Elle expire souvent : c'est une piste
        -- pour retrouver le fichier, pas une archive.
        [Url]                NVARCHAR(2000)    NULL,
        [DateSource]         DATETIME          NULL,

        [Statut]             VARCHAR(20)       NOT NULL CONSTRAINT DF_PieceJointe_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]           NVARCHAR(400)     NULL,
        [Created]            DATETIME          NOT NULL CONSTRAINT DF_PieceJointe_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_PieceJointeImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_PieceJointe_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_PieceJointe_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_PieceJointe_Company ON staging.PieceJointeImport ([CompanyGUID], [DocumentGenre]);
    CREATE INDEX IX_PieceJointe_Document ON staging.PieceJointeImport ([CompanyGUID], [DocumentExterneId]);
    CREATE INDEX IX_PieceJointe_File ON staging.PieceJointeImport ([ImportFileId]);
END
GO

-- -----------------------------------------------------------------------------
-- 3) staging.ConditionPaiementImport
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.ConditionPaiementImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.ConditionPaiementImport
    (
        [Id]               INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]     INT               NULL,
        [RunId]            INT               NULL,
        [CompanyGUID]      UNIQUEIDENTIFIER  NOT NULL,
        [Rang]             INT               NOT NULL CONSTRAINT DF_CondPaiement_Rang DEFAULT (0),

        [ExterneId]        NVARCHAR(100)     NULL,
        [Nom]              NVARCHAR(200)     NULL,
        -- STANDARD (n jours après la facture) ou DATE_DRIVEN (le n du mois)
        [TypeSource]       NVARCHAR(40)      NULL,

        -- Le cœur de la chose : combien de jours avant l'échéance.
        [JoursEcheance]    INT               NULL,
        [JoursEscompte]    INT               NULL,
        [PourcentEscompte] DECIMAL(9,4)      NULL,
        [JourDuMois]       INT               NULL,

        [Actif]            BIT               NULL,

        [Statut]           VARCHAR(20)       NOT NULL CONSTRAINT DF_CondPaiement_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]         NVARCHAR(400)     NULL,
        [Created]          DATETIME          NOT NULL CONSTRAINT DF_CondPaiement_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_ConditionPaiementImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_CondPaiement_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_CondPaiement_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_CondPaiement_Company ON staging.ConditionPaiementImport ([CompanyGUID]);
    CREATE INDEX IX_CondPaiement_File ON staging.ConditionPaiementImport ([ImportFileId]);
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0815GetSourcesPiecesJointes
--    Ce qu'il faut interroger, et sous quel nom Apideck le connaît. La
--    correspondance vit ici plutôt que dans le code : c'est une donnée, pas une
--    règle métier, et elle se corrige sans recompiler.
--
--    Les reçus de vente (type 7) et les bons de commande sont ABSENTS à dessein :
--    Apideck refuse ces deux types de référence.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0815GetSourcesPiecesJointes]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Genre], [ExterneId], [Numero] FROM (
        SELECT CASE d.[DocumentTypeId]
                   WHEN 1 THEN 'invoice'
                   WHEN 2 THEN 'bill'
                   WHEN 3 THEN 'credit-note'
                   WHEN 4 THEN 'bill-credit-note'
                   WHEN 6 THEN 'expense'
               END AS [Genre],
               d.[ExterneId], d.[Numero], 1 AS [Ordre]
          FROM staging.DocumentImport d
         WHERE d.[CompanyGUID] = @CompanyGUID
           AND d.[DocumentTypeId] IN (1, 2, 3, 4, 6)
           AND NULLIF(d.[ExterneId], '') IS NOT NULL

        UNION ALL

        SELECT 'journal-entry', e.[ExterneId], e.[Numero], 2
          FROM staging.EcritureImport e
         WHERE e.[CompanyGUID] = @CompanyGUID
           AND NULLIF(e.[ExterneId], '') IS NOT NULL

        UNION ALL

        SELECT 'quote', p.[ExterneId], p.[Numero], 3
          FROM staging.PieceCommercialeImport p
         WHERE p.[CompanyGUID] = @CompanyGUID
           AND p.[Genre] = 'Soumission'
           AND NULLIF(p.[ExterneId], '') IS NOT NULL
    ) x
     ORDER BY [Ordre], [ExterneId];
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0814ChargerPiecesJointes
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0814ChargerPiecesJointes]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL, @Pieces NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL THROW 50392, 'Aucune compagnie : impossible de déposer ces pièces jointes.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.PieceJointeImport WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.PieceJointeImport
        ([RunId], [ImportFileId], [CompanyGUID], [DocumentGenre], [DocumentExterneId],
         [DocumentNumero], [ExterneId], [NomFichier], [Description], [TypeContenu],
         [Taille], [Url], [DateSource], [Statut], [Anomalie])
    SELECT @RunId, @ImportFileId, @CompanyGUID,
           LEFT(j.[genre], 30), LEFT(j.[document_id], 100), LEFT(j.[document_numero], 60),
           LEFT(j.[externe_id], 100), j.[nom], j.[description], LEFT(j.[type], 150),
           TRY_CONVERT(BIGINT, j.[taille]),
           j.[url],
           TRY_CONVERT(DATETIME, NULLIF(j.[date], '')),
           CASE WHEN NULLIF(j.[url], '') IS NULL THEN 'SANS_LIEN' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(j.[url], '') IS NULL
                THEN N'La source ne donne pas d''adresse de téléchargement : le fichier restera inaccessible.' END
      FROM OPENJSON(@Pieces)
           WITH ([genre]           NVARCHAR(40)   '$.genre',
                 [document_id]     NVARCHAR(200)  '$.document_id',
                 [document_numero] NVARCHAR(100)  '$.document_numero',
                 [externe_id]      NVARCHAR(200)  '$.externe_id',
                 [nom]             NVARCHAR(400)  '$.nom',
                 [description]     NVARCHAR(1000) '$.description',
                 [type]            NVARCHAR(200)  '$.type',
                 [taille]          NVARCHAR(40)   '$.taille',
                 [url]             NVARCHAR(2000) '$.url',
                 [date]            NVARCHAR(60)   '$.date') AS j;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbPieces],
           COUNT(DISTINCT [DocumentExterneId]) AS [NbDocuments],
           SUM(CASE WHEN [Statut] = 'SANS_LIEN' THEN 1 ELSE 0 END) AS [NbSansLien],
           SUM(ISNULL([Taille], 0)) AS [TailleTotale]
      FROM staging.PieceJointeImport
     WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0816GetPiecesJointes]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [DocumentGenre], COUNT(*) AS [Nb], SUM(ISNULL([Taille], 0)) AS [Taille]
      FROM staging.PieceJointeImport
     WHERE [CompanyGUID] = @CompanyGUID
     GROUP BY [DocumentGenre]
     ORDER BY [DocumentGenre];

    SELECT [Id], [DocumentGenre], [DocumentExterneId], [DocumentNumero], [ExterneId],
           [NomFichier], [Description], [TypeContenu], [Taille], [Url], [DateSource],
           [Statut], [Anomalie], [Created]
      FROM staging.PieceJointeImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY CASE WHEN [Statut] <> 'NOUVEAU' THEN 0 ELSE 1 END,
              [DocumentGenre], [DocumentNumero], [NomFichier];
END
GO

-- -----------------------------------------------------------------------------
-- 6) s0817ChargerConditionsPaiement
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0817ChargerConditionsPaiement]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL, @Conditions NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL THROW 50393, 'Aucune compagnie : impossible de déposer ces conditions.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.ConditionPaiementImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[externe_id], '') ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Conditions)
               WITH ([rang]        INT           '$.rang',
                     [externe_id]  NVARCHAR(200) '$.externe_id',
                     [nom]         NVARCHAR(200) '$.nom',
                     [type]        NVARCHAR(40)  '$.type',
                     [jours]       NVARCHAR(40)  '$.jours',
                     [jours_esc]   NVARCHAR(40)  '$.jours_escompte',
                     [pct_esc]     NVARCHAR(40)  '$.pourcent_escompte',
                     [jour_mois]   NVARCHAR(40)  '$.jour_du_mois',
                     [actif]       NVARCHAR(20)  '$.actif') AS j
    )
    INSERT INTO staging.ConditionPaiementImport
        ([RunId], [ImportFileId], [CompanyGUID], [Rang], [ExterneId], [Nom], [TypeSource],
         [JoursEcheance], [JoursEscompte], [PourcentEscompte], [JourDuMois], [Actif],
         [Statut], [Anomalie])
    SELECT @RunId, @ImportFileId, @CompanyGUID, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[nom], ''), NULLIF(l.[type], ''),
           TRY_CONVERT(INT, l.[jours]),
           TRY_CONVERT(INT, l.[jours_esc]),
           TRY_CONVERT(DECIMAL(9,4), l.[pct_esc]),
           TRY_CONVERT(INT, l.[jour_mois]),
           CASE WHEN LOWER(ISNULL(l.[actif], '')) IN ('true', '1') THEN 1
                WHEN LOWER(ISNULL(l.[actif], '')) IN ('false', '0') THEN 0 END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL THEN 'INVALIDE'
                WHEN l.[Occ] > 1 THEN 'DOUBLON' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL
                     THEN N'Condition sans nom : rien pour la désigner.'
                WHEN l.[Occ] > 1
                     THEN N'Cet identifiant apparaît plusieurs fois dans la même extraction.'
                ELSE NULL END
      FROM Lu l;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbConditions],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouvelles],
           SUM(CASE WHEN [Actif] = 1 THEN 1 ELSE 0 END)           AS [NbActives],
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END) AS [NbAnomalies]
      FROM staging.ConditionPaiementImport
     WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0818GetConditionsPaiement]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [Rang], [ExterneId], [Nom], [TypeSource], [JoursEcheance],
           [JoursEscompte], [PourcentEscompte], [JourDuMois], [Actif],
           [Statut], [Anomalie], [Created]
      FROM staging.ConditionPaiementImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY CASE WHEN [Statut] <> 'NOUVEAU' THEN 0 ELSE 1 END,
              ISNULL([JoursEcheance], 9999), [Nom];
END
GO
