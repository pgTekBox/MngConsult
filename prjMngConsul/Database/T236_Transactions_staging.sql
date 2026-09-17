-- =============================================================================
-- T236 — Les transactions : engagements, mouvements d'argent, écritures
--
-- Les quinze ressources restantes ne sont pas de la même nature, et c'est ce qui
-- décide du découpage. Quatre familles, pas quinze tables.
--
--  A. CE QUI EST DÉJÀ UN DOCUMENT COMPTABLE — rien à créer.
--     Les avoirs, les dépenses et les reçus de vente ont la forme d'une facture :
--     un tiers, des lignes, des totaux. staging.DocumentImport les reçoit tels
--     quels, distingués par DocumentTypeId, exactement comme les factures :
--        credit-notes       -> 3 CreditClient
--        bill-credit-notes  -> 4 CreditFournisseur
--        expenses           -> 6 Expense
--        sales-receipts     -> 1 FactureClient, solde nul (une vente payée
--                              sur-le-champ reste une vente)
--
--  B. LES ENGAGEMENTS — staging.PieceCommercialeImport
--     Une soumission et un bon de commande ne touchent aucun compte : ce sont des
--     promesses. Les mêler aux documents comptables ferait entrer en comptabilité
--     des montants qui n'y ont rien à faire.
--
--  C. LES MOUVEMENTS D'ARGENT — staging.PaiementImport + ...Affectation
--     Encaissements, décaissements et remboursements sont un même geste : de
--     l'argent change de mains et s'impute sur des documents. Le sens les
--     distingue. L'imputation vit dans la table fille — un paiement peut régler
--     trois factures, et c'est justement ce qu'on veut savoir.
--
--  D. LES ÉCRITURES — staging.EcritureImport + ...Ligne
--     Débits et crédits. La seule famille où l'équilibre se vérifie : une
--     écriture dont les débits ne font pas les crédits est fausse, point.
--
-- Procédures : s0804 à s0809.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) Le registre accepte les nouveaux types
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
                      'EcritureJournal', 'Rapport', 'BalanceAgee'));
GO

-- -----------------------------------------------------------------------------
-- 2) B. Les engagements : soumissions et bons de commande
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.PieceCommercialeImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.PieceCommercialeImport
    (
        [Id]              INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]    INT               NULL,
        [RunId]           INT               NULL,
        [CompanyGUID]     UNIQUEIDENTIFIER  NOT NULL,

        -- Soumission (devis client) ou BonCommande (engagement fournisseur)
        [Genre]           VARCHAR(20)       NOT NULL,
        [Rang]            INT               NOT NULL CONSTRAINT DF_PieceCom_Rang DEFAULT (0),

        [ExterneId]       NVARCHAR(100)     NULL,
        [Numero]          NVARCHAR(60)      NULL,
        [DatePiece]       DATE              NULL,
        [DateExpiration]  DATE              NULL,

        [TiersExterneId]  NVARCHAR(100)     NULL,
        [TiersNom]        NVARCHAR(500)     NULL,
        [PartyGUID]       UNIQUEIDENTIFIER  NULL,

        [Devise]          VARCHAR(10)       NULL,
        [SousTotal]       DECIMAL(18,2)     NULL,
        [TotalTaxes]      DECIMAL(18,2)     NULL,
        [Total]           DECIMAL(18,2)     NULL,

        [StatutSource]    NVARCHAR(60)      NULL,
        [NbLignes]        INT               NOT NULL CONSTRAINT DF_PieceCom_NbLignes DEFAULT (0),

        [Statut]          VARCHAR(20)       NOT NULL CONSTRAINT DF_PieceCom_Statut DEFAULT ('OK'),
        [Anomalie]        NVARCHAR(400)     NULL,
        [Created]         DATETIME          NOT NULL CONSTRAINT DF_PieceCom_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_PieceCommercialeImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT CK_PieceCom_Genre CHECK ([Genre] IN ('Soumission', 'BonCommande')),
        CONSTRAINT FK_PieceCom_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_PieceCom_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_PieceCom_Company ON staging.PieceCommercialeImport ([CompanyGUID], [Genre]);
    CREATE INDEX IX_PieceCom_File ON staging.PieceCommercialeImport ([ImportFileId]);
END
GO

IF OBJECT_ID('staging.PieceCommercialeImportLigne', 'U') IS NULL
BEGIN
    CREATE TABLE staging.PieceCommercialeImportLigne
    (
        [Id]                INT IDENTITY(1,1) NOT NULL,
        [EnteteId]          INT               NOT NULL,
        [LigneNo]           INT               NOT NULL,
        [Description]       NVARCHAR(1000)    NULL,
        [ProduitExterneId]  NVARCHAR(100)     NULL,
        [ProduitNom]        NVARCHAR(500)     NULL,
        [Quantite]          DECIMAL(18,4)     NULL,
        [PrixUnitaire]      DECIMAL(18,4)     NULL,
        [Montant]           DECIMAL(18,2)     NULL,
        [TaxeCode]          NVARCHAR(50)      NULL,
        [Created]           DATETIME          NOT NULL CONSTRAINT DF_PieceComLigne_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_PieceCommercialeImportLigne PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_PieceComLigne_Entete FOREIGN KEY ([EnteteId])
            REFERENCES staging.PieceCommercialeImport ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_PieceComLigne_Entete ON staging.PieceCommercialeImportLigne ([EnteteId]);
END
GO

-- -----------------------------------------------------------------------------
-- 3) C. Les mouvements d'argent
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.PaiementImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.PaiementImport
    (
        [Id]                INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]      INT               NULL,
        [RunId]             INT               NULL,
        [CompanyGUID]       UNIQUEIDENTIFIER  NOT NULL,

        -- Encaissement (client paie) · Decaissement (on paie un fournisseur) ·
        -- Remboursement (l'argent repart dans l'autre sens)
        [Sens]              VARCHAR(20)       NOT NULL,
        [Rang]              INT               NOT NULL CONSTRAINT DF_Paiement_Rang DEFAULT (0),

        [ExterneId]         NVARCHAR(100)     NULL,
        [Reference]         NVARCHAR(100)     NULL,
        [DatePaiement]      DATE              NULL,

        [TiersExterneId]    NVARCHAR(100)     NULL,
        [TiersNom]          NVARCHAR(500)     NULL,
        [PartyGUID]         UNIQUEIDENTIFIER  NULL,

        [Devise]            VARCHAR(10)       NULL,
        [Montant]           DECIMAL(18,2)     NULL,
        -- Ce qui n'a pas encore été imputé sur un document chez la source.
        [MontantNonImpute]  DECIMAL(18,2)     NULL,

        [ModePaiementNom]   NVARCHAR(200)     NULL,
        [CompteExterneId]   NVARCHAR(100)     NULL,
        [CompteNom]         NVARCHAR(300)     NULL,
        [StatutSource]      NVARCHAR(60)      NULL,
        [NbAffectations]    INT               NOT NULL CONSTRAINT DF_Paiement_NbAff DEFAULT (0),

        [Statut]            VARCHAR(20)       NOT NULL CONSTRAINT DF_Paiement_Statut DEFAULT ('OK'),
        [Anomalie]          NVARCHAR(400)     NULL,
        [Created]           DATETIME          NOT NULL CONSTRAINT DF_Paiement_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_PaiementImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT CK_Paiement_Sens CHECK ([Sens] IN ('Encaissement', 'Decaissement', 'Remboursement')),
        CONSTRAINT FK_Paiement_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_Paiement_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_Paiement_Company ON staging.PaiementImport ([CompanyGUID], [Sens]);
    CREATE INDEX IX_Paiement_File ON staging.PaiementImport ([ImportFileId]);
END
GO

IF OBJECT_ID('staging.PaiementImportAffectation', 'U') IS NULL
BEGIN
    CREATE TABLE staging.PaiementImportAffectation
    (
        [Id]                 INT IDENTITY(1,1) NOT NULL,
        [PaiementId]         INT               NOT NULL,
        [Rang]               INT               NOT NULL,

        -- Le document réglé, chez la source. C'est par lui qu'on retrouvera
        -- plus tard la facture correspondante de notre côté.
        [DocumentExterneId]  NVARCHAR(100)     NULL,
        [DocumentNumero]     NVARCHAR(60)      NULL,
        [DocumentType]       NVARCHAR(60)      NULL,
        [Montant]            DECIMAL(18,2)     NULL,
        [Created]            DATETIME          NOT NULL CONSTRAINT DF_PaiementAff_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_PaiementImportAffectation PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_PaiementAff_Paiement FOREIGN KEY ([PaiementId])
            REFERENCES staging.PaiementImport ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_PaiementAff_Paiement ON staging.PaiementImportAffectation ([PaiementId]);
END
GO

-- -----------------------------------------------------------------------------
-- 4) D. Les écritures de journal
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.EcritureImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.EcritureImport
    (
        [Id]             INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]   INT               NULL,
        [RunId]          INT               NULL,
        [CompanyGUID]    UNIQUEIDENTIFIER  NOT NULL,
        [Rang]           INT               NOT NULL CONSTRAINT DF_Ecriture_Rang DEFAULT (0),

        [ExterneId]      NVARCHAR(100)     NULL,
        [Numero]         NVARCHAR(60)      NULL,
        [DateEcriture]   DATE              NULL,
        [Libelle]        NVARCHAR(1000)    NULL,
        [Devise]         VARCHAR(10)       NULL,
        [JournalSymbole] NVARCHAR(40)      NULL,

        [TotalDebit]     DECIMAL(18,2)     NULL,
        [TotalCredit]    DECIMAL(18,2)     NULL,
        [NbLignes]       INT               NOT NULL CONSTRAINT DF_Ecriture_NbLignes DEFAULT (0),

        [StatutSource]   NVARCHAR(60)      NULL,
        -- OK · DESEQUILIBREE · INVALIDE
        [Statut]         VARCHAR(20)       NOT NULL CONSTRAINT DF_Ecriture_Statut DEFAULT ('OK'),
        [Anomalie]       NVARCHAR(400)     NULL,
        [Created]        DATETIME          NOT NULL CONSTRAINT DF_Ecriture_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_EcritureImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_Ecriture_File FOREIGN KEY ([ImportFileId]) REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_Ecriture_Run FOREIGN KEY ([RunId]) REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_Ecriture_Company ON staging.EcritureImport ([CompanyGUID]);
    CREATE INDEX IX_Ecriture_File ON staging.EcritureImport ([ImportFileId]);
END
GO

IF OBJECT_ID('staging.EcritureImportLigne', 'U') IS NULL
BEGIN
    CREATE TABLE staging.EcritureImportLigne
    (
        [Id]                INT IDENTITY(1,1) NOT NULL,
        [EnteteId]          INT               NOT NULL,
        [LigneNo]           INT               NOT NULL,

        [CompteExterneId]   NVARCHAR(100)     NULL,
        [CompteNumero]      NVARCHAR(100)     NULL,
        [CompteNom]         NVARCHAR(300)     NULL,

        [Description]       NVARCHAR(1000)    NULL,
        [Debit]             DECIMAL(18,2)     NULL,
        [Credit]            DECIMAL(18,2)     NULL,

        [TiersExterneId]    NVARCHAR(100)     NULL,
        [TiersNom]          NVARCHAR(500)     NULL,
        [Created]           DATETIME          NOT NULL CONSTRAINT DF_EcritureLigne_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_EcritureImportLigne PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_EcritureLigne_Entete FOREIGN KEY ([EnteteId])
            REFERENCES staging.EcritureImport ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX IX_EcritureLigne_Entete ON staging.EcritureImportLigne ([EnteteId]);
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0804ChargerPiecesCommerciales
--    Une relecture remplace le genre concerné, pas l'autre : on peut réimporter
--    les soumissions sans perdre les bons de commande.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0804ChargerPiecesCommerciales]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @Genre VARCHAR(20),
    @ImportFileId INT = NULL, @Pieces NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL THROW 50383, 'Aucune compagnie : impossible de déposer ces pièces.', 1;
    IF @Genre NOT IN ('Soumission', 'BonCommande') THROW 50384, 'Genre de pièce inconnu.', 1;

    BEGIN TRANSACTION;

    DELETE l
      FROM staging.PieceCommercialeImportLigne l
      JOIN staging.PieceCommercialeImport e ON e.[Id] = l.[EnteteId]
     WHERE e.[CompanyGUID] = @CompanyGUID AND e.[Genre] = @Genre;

    DELETE FROM staging.PieceCommercialeImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Genre] = @Genre;

    DECLARE @Entetes TABLE ([Id] INT, [Rang] INT);

    INSERT INTO staging.PieceCommercialeImport
        ([RunId], [ImportFileId], [CompanyGUID], [Genre], [Rang], [ExterneId], [Numero],
         [DatePiece], [DateExpiration], [TiersExterneId], [TiersNom], [Devise],
         [SousTotal], [TotalTaxes], [Total], [StatutSource], [Statut], [Anomalie])
    OUTPUT INSERTED.[Id], INSERTED.[Rang] INTO @Entetes
    SELECT @RunId, @ImportFileId, @CompanyGUID, @Genre, j.[Rang],
           LEFT(j.[ExterneId], 100), LEFT(j.[Numero], 60),
           TRY_CONVERT(DATE, NULLIF(j.[DatePiece], '')),
           TRY_CONVERT(DATE, NULLIF(j.[DateExpiration], '')),
           LEFT(j.[TiersExterneId], 100), j.[TiersNom], LEFT(j.[Devise], 10),
           TRY_CONVERT(DECIMAL(18,2), j.[SousTotal]),
           TRY_CONVERT(DECIMAL(18,2), j.[TotalTaxes]),
           TRY_CONVERT(DECIMAL(18,2), j.[Total]),
           LEFT(j.[StatutSource], 60),
           CASE WHEN NULLIF(j.[Numero], '') IS NULL AND NULLIF(j.[ExterneId], '') IS NULL
                THEN 'INVALIDE' ELSE 'OK' END,
           CASE WHEN NULLIF(j.[Numero], '') IS NULL AND NULLIF(j.[ExterneId], '') IS NULL
                THEN N'Ni numéro ni identifiant : rien pour désigner cette pièce.' END
      FROM OPENJSON(@Pieces)
           WITH ([Rang]           INT            '$.rang',
                 [ExterneId]      NVARCHAR(200)  '$.externe_id',
                 [Numero]         NVARCHAR(100)  '$.numero',
                 [DatePiece]      NVARCHAR(40)   '$.date',
                 [DateExpiration] NVARCHAR(40)   '$.expiration',
                 [TiersExterneId] NVARCHAR(200)  '$.tiers_id',
                 [TiersNom]       NVARCHAR(500)  '$.tiers',
                 [Devise]         NVARCHAR(20)   '$.devise',
                 [SousTotal]      NVARCHAR(40)   '$.sous_total',
                 [TotalTaxes]     NVARCHAR(40)   '$.taxes',
                 [Total]          NVARCHAR(40)   '$.total',
                 [StatutSource]   NVARCHAR(100)  '$.statut') AS j;

    INSERT INTO staging.PieceCommercialeImportLigne
        ([EnteteId], [LigneNo], [Description], [ProduitExterneId], [ProduitNom],
         [Quantite], [PrixUnitaire], [Montant], [TaxeCode])
    SELECT e.[Id], l.[LigneNo], l.[Description],
           LEFT(l.[ProduitExterneId], 100), l.[ProduitNom],
           TRY_CONVERT(DECIMAL(18,4), l.[Quantite]),
           TRY_CONVERT(DECIMAL(18,4), l.[PrixUnitaire]),
           TRY_CONVERT(DECIMAL(18,2), l.[Montant]),
           LEFT(l.[TaxeCode], 50)
      FROM OPENJSON(@Pieces)
           WITH ([Rang] INT '$.rang', [Lignes] NVARCHAR(MAX) '$.lignes' AS JSON) AS d
     CROSS APPLY OPENJSON(d.[Lignes])
           WITH ([LigneNo]          INT            '$.no',
                 [Description]      NVARCHAR(1000) '$.description',
                 [ProduitExterneId] NVARCHAR(200)  '$.produit_id',
                 [ProduitNom]       NVARCHAR(500)  '$.produit',
                 [Quantite]         NVARCHAR(40)   '$.qte',
                 [PrixUnitaire]     NVARCHAR(40)   '$.prix',
                 [Montant]          NVARCHAR(40)   '$.montant',
                 [TaxeCode]         NVARCHAR(100)  '$.taxe') AS l
     INNER JOIN @Entetes e ON e.[Rang] = d.[Rang];

    UPDATE e
       SET [NbLignes] = x.[Nb]
      FROM staging.PieceCommercialeImport e
     CROSS APPLY (SELECT COUNT(*) AS [Nb] FROM staging.PieceCommercialeImportLigne l
                   WHERE l.[EnteteId] = e.[Id]) x
     WHERE e.[Id] IN (SELECT [Id] FROM @Entetes);

    -- Le tiers, retrouvé par son nom — même règle que pour les documents.
    UPDATE e
       SET e.[PartyGUID] = p.[PartyGUID]
      FROM staging.PieceCommercialeImport e
      JOIN dbo.T050Party p
        ON p.[CompanyGUID] = @CompanyGUID
       AND (p.[Name] = e.[TiersNom] OR p.[DisplayName] = e.[TiersNom])
     WHERE e.[Id] IN (SELECT [Id] FROM @Entetes)
       AND e.[TiersNom] IS NOT NULL;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbPieces],
           SUM(CASE WHEN [Statut] = 'OK' THEN 1 ELSE 0 END)        AS [NbValides],
           SUM(CASE WHEN [Statut] <> 'OK' THEN 1 ELSE 0 END)       AS [NbAnomalies],
           SUM(CASE WHEN [PartyGUID] IS NULL THEN 1 ELSE 0 END)    AS [NbSansTiers]
      FROM staging.PieceCommercialeImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Genre] = @Genre;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0805GetPiecesCommerciales]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Genre       VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [Genre], [Rang], [ExterneId], [Numero], [DatePiece], [DateExpiration],
           [TiersExterneId], [TiersNom], [PartyGUID], [Devise],
           [SousTotal], [TotalTaxes], [Total], [StatutSource], [NbLignes],
           [Statut], [Anomalie], [Created]
      FROM staging.PieceCommercialeImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND (@Genre IS NULL OR @Genre = '' OR [Genre] = @Genre)
     ORDER BY [Genre], CASE WHEN [Statut] <> 'OK' THEN 0 ELSE 1 END, [DatePiece] DESC, [Numero];

    SELECT l.[EnteteId], l.[LigneNo], l.[Description], l.[ProduitNom],
           l.[Quantite], l.[PrixUnitaire], l.[Montant], l.[TaxeCode]
      FROM staging.PieceCommercialeImportLigne l
      JOIN staging.PieceCommercialeImport e ON e.[Id] = l.[EnteteId]
     WHERE e.[CompanyGUID] = @CompanyGUID
       AND (@Genre IS NULL OR @Genre = '' OR e.[Genre] = @Genre)
     ORDER BY l.[EnteteId], l.[LigneNo];
END
GO

-- -----------------------------------------------------------------------------
-- 6) s0806ChargerPaiementsImport
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0806ChargerPaiementsImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @Sens VARCHAR(20),
    @ImportFileId INT = NULL, @Paiements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL THROW 50385, 'Aucune compagnie : impossible de déposer ces paiements.', 1;
    IF @Sens NOT IN ('Encaissement', 'Decaissement', 'Remboursement')
        THROW 50386, 'Sens de paiement inconnu.', 1;

    BEGIN TRANSACTION;

    DELETE a
      FROM staging.PaiementImportAffectation a
      JOIN staging.PaiementImport p ON p.[Id] = a.[PaiementId]
     WHERE p.[CompanyGUID] = @CompanyGUID AND p.[Sens] = @Sens;

    DELETE FROM staging.PaiementImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Sens] = @Sens;

    DECLARE @Entetes TABLE ([Id] INT, [Rang] INT);

    INSERT INTO staging.PaiementImport
        ([RunId], [ImportFileId], [CompanyGUID], [Sens], [Rang], [ExterneId], [Reference],
         [DatePaiement], [TiersExterneId], [TiersNom], [Devise], [Montant],
         [MontantNonImpute], [ModePaiementNom], [CompteExterneId], [CompteNom],
         [StatutSource], [Statut], [Anomalie])
    OUTPUT INSERTED.[Id], INSERTED.[Rang] INTO @Entetes
    SELECT @RunId, @ImportFileId, @CompanyGUID, @Sens, j.[Rang],
           LEFT(j.[ExterneId], 100), LEFT(j.[Reference], 100),
           TRY_CONVERT(DATE, NULLIF(j.[DatePaiement], '')),
           LEFT(j.[TiersExterneId], 100), j.[TiersNom], LEFT(j.[Devise], 10),
           TRY_CONVERT(DECIMAL(18,2), j.[Montant]),
           TRY_CONVERT(DECIMAL(18,2), j.[NonImpute]),
           j.[ModePaiement], LEFT(j.[CompteExterneId], 100), j.[CompteNom],
           LEFT(j.[StatutSource], 60),
           CASE WHEN TRY_CONVERT(DECIMAL(18,2), j.[Montant]) IS NULL THEN 'INVALIDE' ELSE 'OK' END,
           CASE WHEN TRY_CONVERT(DECIMAL(18,2), j.[Montant]) IS NULL
                THEN N'Aucun montant lisible : un paiement sans montant ne veut rien dire.' END
      FROM OPENJSON(@Paiements)
           WITH ([Rang]            INT            '$.rang',
                 [ExterneId]       NVARCHAR(200)  '$.externe_id',
                 [Reference]       NVARCHAR(200)  '$.reference',
                 [DatePaiement]    NVARCHAR(40)   '$.date',
                 [TiersExterneId]  NVARCHAR(200)  '$.tiers_id',
                 [TiersNom]        NVARCHAR(500)  '$.tiers',
                 [Devise]          NVARCHAR(20)   '$.devise',
                 [Montant]         NVARCHAR(40)   '$.montant',
                 [NonImpute]       NVARCHAR(40)   '$.non_impute',
                 [ModePaiement]    NVARCHAR(200)  '$.mode',
                 [CompteExterneId] NVARCHAR(200)  '$.compte_id',
                 [CompteNom]       NVARCHAR(300)  '$.compte',
                 [StatutSource]    NVARCHAR(100)  '$.statut') AS j;

    INSERT INTO staging.PaiementImportAffectation
        ([PaiementId], [Rang], [DocumentExterneId], [DocumentNumero], [DocumentType], [Montant])
    SELECT e.[Id], a.[Rang], LEFT(a.[DocumentExterneId], 100),
           LEFT(a.[DocumentNumero], 60), LEFT(a.[DocumentType], 60),
           TRY_CONVERT(DECIMAL(18,2), a.[Montant])
      FROM OPENJSON(@Paiements)
           WITH ([Rang] INT '$.rang', [Affectations] NVARCHAR(MAX) '$.affectations' AS JSON) AS d
     CROSS APPLY OPENJSON(d.[Affectations])
           WITH ([Rang]              INT           '$.no',
                 [DocumentExterneId] NVARCHAR(200) '$.document_id',
                 [DocumentNumero]    NVARCHAR(100) '$.document_numero',
                 [DocumentType]      NVARCHAR(100) '$.document_type',
                 [Montant]           NVARCHAR(40)  '$.montant') AS a
     INNER JOIN @Entetes e ON e.[Rang] = d.[Rang];

    UPDATE p
       SET [NbAffectations] = x.[Nb]
      FROM staging.PaiementImport p
     CROSS APPLY (SELECT COUNT(*) AS [Nb] FROM staging.PaiementImportAffectation a
                   WHERE a.[PaiementId] = p.[Id]) x
     WHERE p.[Id] IN (SELECT [Id] FROM @Entetes);

    UPDATE p
       SET p.[PartyGUID] = t.[PartyGUID]
      FROM staging.PaiementImport p
      JOIN dbo.T050Party t
        ON t.[CompanyGUID] = @CompanyGUID
       AND (t.[Name] = p.[TiersNom] OR t.[DisplayName] = p.[TiersNom])
     WHERE p.[Id] IN (SELECT [Id] FROM @Entetes)
       AND p.[TiersNom] IS NOT NULL;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbPaiements],
           SUM(CASE WHEN [Statut] = 'OK' THEN 1 ELSE 0 END)     AS [NbValides],
           SUM(CASE WHEN [Statut] <> 'OK' THEN 1 ELSE 0 END)    AS [NbAnomalies],
           SUM(CASE WHEN [PartyGUID] IS NULL THEN 1 ELSE 0 END) AS [NbSansTiers],
           SUM([NbAffectations])                                AS [NbAffectations]
      FROM staging.PaiementImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Sens] = @Sens;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0807GetPaiementsImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Sens        VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [Sens], [Rang], [ExterneId], [Reference], [DatePaiement],
           [TiersExterneId], [TiersNom], [PartyGUID], [Devise], [Montant],
           [MontantNonImpute], [ModePaiementNom], [CompteNom], [StatutSource],
           [NbAffectations], [Statut], [Anomalie], [Created]
      FROM staging.PaiementImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND (@Sens IS NULL OR @Sens = '' OR [Sens] = @Sens)
     ORDER BY [Sens], CASE WHEN [Statut] <> 'OK' THEN 0 ELSE 1 END, [DatePaiement] DESC;

    SELECT a.[PaiementId], a.[Rang], a.[DocumentExterneId], a.[DocumentNumero],
           a.[DocumentType], a.[Montant]
      FROM staging.PaiementImportAffectation a
      JOIN staging.PaiementImport p ON p.[Id] = a.[PaiementId]
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND (@Sens IS NULL OR @Sens = '' OR p.[Sens] = @Sens)
     ORDER BY a.[PaiementId], a.[Rang];
END
GO

-- -----------------------------------------------------------------------------
-- 7) s0808ChargerEcrituresImport
--    La seule famille où l'équilibre se vérifie : une écriture dont les débits
--    ne font pas les crédits est fausse, et le dire ici évite de le découvrir
--    au moment de comptabiliser.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0808ChargerEcrituresImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL, @Ecritures NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL THROW 50387, 'Aucune compagnie : impossible de déposer ces écritures.', 1;

    BEGIN TRANSACTION;

    DELETE l
      FROM staging.EcritureImportLigne l
      JOIN staging.EcritureImport e ON e.[Id] = l.[EnteteId]
     WHERE e.[CompanyGUID] = @CompanyGUID;

    DELETE FROM staging.EcritureImport WHERE [CompanyGUID] = @CompanyGUID;

    DECLARE @Entetes TABLE ([Id] INT, [Rang] INT);

    INSERT INTO staging.EcritureImport
        ([RunId], [ImportFileId], [CompanyGUID], [Rang], [ExterneId], [Numero],
         [DateEcriture], [Libelle], [Devise], [JournalSymbole], [StatutSource])
    OUTPUT INSERTED.[Id], INSERTED.[Rang] INTO @Entetes
    SELECT @RunId, @ImportFileId, @CompanyGUID, j.[Rang],
           LEFT(j.[ExterneId], 100), LEFT(j.[Numero], 60),
           TRY_CONVERT(DATE, NULLIF(j.[DateEcriture], '')),
           j.[Libelle], LEFT(j.[Devise], 10), LEFT(j.[Journal], 40),
           LEFT(j.[StatutSource], 60)
      FROM OPENJSON(@Ecritures)
           WITH ([Rang]         INT            '$.rang',
                 [ExterneId]    NVARCHAR(200)  '$.externe_id',
                 [Numero]       NVARCHAR(100)  '$.numero',
                 [DateEcriture] NVARCHAR(40)   '$.date',
                 [Libelle]      NVARCHAR(1000) '$.libelle',
                 [Devise]       NVARCHAR(20)   '$.devise',
                 [Journal]      NVARCHAR(100)  '$.journal',
                 [StatutSource] NVARCHAR(100)  '$.statut') AS j;

    INSERT INTO staging.EcritureImportLigne
        ([EnteteId], [LigneNo], [CompteExterneId], [CompteNumero], [CompteNom],
         [Description], [Debit], [Credit], [TiersExterneId], [TiersNom])
    SELECT e.[Id], l.[LigneNo], LEFT(l.[CompteExterneId], 100),
           LEFT(l.[CompteNumero], 100), l.[CompteNom], l.[Description],
           TRY_CONVERT(DECIMAL(18,2), l.[Debit]),
           TRY_CONVERT(DECIMAL(18,2), l.[Credit]),
           LEFT(l.[TiersExterneId], 100), l.[TiersNom]
      FROM OPENJSON(@Ecritures)
           WITH ([Rang] INT '$.rang', [Lignes] NVARCHAR(MAX) '$.lignes' AS JSON) AS d
     CROSS APPLY OPENJSON(d.[Lignes])
           WITH ([LigneNo]         INT            '$.no',
                 [CompteExterneId] NVARCHAR(200)  '$.compte_id',
                 [CompteNumero]    NVARCHAR(200)  '$.compte',
                 [CompteNom]       NVARCHAR(300)  '$.compte_nom',
                 [Description]     NVARCHAR(1000) '$.description',
                 [Debit]           NVARCHAR(40)   '$.debit',
                 [Credit]          NVARCHAR(40)   '$.credit',
                 [TiersExterneId]  NVARCHAR(200)  '$.tiers_id',
                 [TiersNom]        NVARCHAR(500)  '$.tiers') AS l
     INNER JOIN @Entetes e ON e.[Rang] = d.[Rang];

    -- Les totaux se calculent, ils ne se croient pas : c'est la seule façon de
    -- juger l'équilibre indépendamment de ce que la source affirme.
    UPDATE e
       SET [TotalDebit]  = x.[Debit],
           [TotalCredit] = x.[Credit],
           [NbLignes]    = x.[Nb],
           [Statut]      = CASE
                               WHEN x.[Nb] = 0 THEN 'INVALIDE'
                               WHEN ABS(ISNULL(x.[Debit], 0) - ISNULL(x.[Credit], 0)) > 0.01
                                   THEN 'DESEQUILIBREE'
                               ELSE 'OK'
                           END,
           [Anomalie]    = CASE
                               WHEN x.[Nb] = 0
                                   THEN N'Écriture sans ligne : rien à comptabiliser.'
                               WHEN ABS(ISNULL(x.[Debit], 0) - ISNULL(x.[Credit], 0)) > 0.01
                                   THEN N'Débits ' + CONVERT(NVARCHAR(30), ISNULL(x.[Debit], 0))
                                        + N' ≠ crédits ' + CONVERT(NVARCHAR(30), ISNULL(x.[Credit], 0))
                                        + N' : écart de '
                                        + CONVERT(NVARCHAR(30), ABS(ISNULL(x.[Debit], 0) - ISNULL(x.[Credit], 0)))
                               ELSE NULL
                           END
      FROM staging.EcritureImport e
     CROSS APPLY (SELECT SUM(l.[Debit]) AS [Debit], SUM(l.[Credit]) AS [Credit],
                         COUNT(*) AS [Nb]
                    FROM staging.EcritureImportLigne l WHERE l.[EnteteId] = e.[Id]) x
     WHERE e.[Id] IN (SELECT [Id] FROM @Entetes);

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbEcritures],
           SUM(CASE WHEN [Statut] = 'OK' THEN 1 ELSE 0 END)            AS [NbEquilibrees],
           SUM(CASE WHEN [Statut] = 'DESEQUILIBREE' THEN 1 ELSE 0 END) AS [NbDesequilibrees],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END)      AS [NbInvalides]
      FROM staging.EcritureImport
     WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0809GetEcrituresImport]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [Rang], [ExterneId], [Numero], [DateEcriture], [Libelle], [Devise],
           [JournalSymbole], [TotalDebit], [TotalCredit], [NbLignes],
           [StatutSource], [Statut], [Anomalie], [Created]
      FROM staging.EcritureImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY CASE WHEN [Statut] <> 'OK' THEN 0 ELSE 1 END, [DateEcriture] DESC, [Numero];

    SELECT l.[EnteteId], l.[LigneNo], l.[CompteNumero], l.[CompteNom],
           l.[Description], l.[Debit], l.[Credit], l.[TiersNom]
      FROM staging.EcritureImportLigne l
      JOIN staging.EcritureImport e ON e.[Id] = l.[EnteteId]
     WHERE e.[CompanyGUID] = @CompanyGUID
     ORDER BY l.[EnteteId], l.[LigneNo];
END
GO
