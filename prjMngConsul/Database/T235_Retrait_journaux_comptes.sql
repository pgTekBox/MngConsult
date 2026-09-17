-- =============================================================================
-- T235 — Journaux et comptes bancaires : retirés pour de bon
--
-- T233 leur avait donné une table et une procédure de chargement, en pariant
-- qu'un autre connecteur les fournirait un jour. Le pari ne tient pas : le
-- connecteur QuickBooks d'Apideck ne les expose pas (404 « Spec or operation
-- bankAccountsAll for quickbooks not found », idem journalsAll), rien ne les
-- écrit, et une table que rien ne remplit finit par mentir sur ce que
-- l'application sait faire.
--
-- Elles partent donc entièrement : tables, procédures, valeurs au registre,
-- branches de lecture. Le jour où une source les donnera, les écrire sera un
-- travail d'une heure — et il se fera sur la forme réelle de cette source-là,
-- pas sur une forme devinée aujourd'hui.
--
-- Il reste quatre listes de structure : modes de paiement, catégories de suivi,
-- départements, emplacements.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) Les procédures d'abord, chacune dans son lot.
--    Un lot qui mélange DROP et référence à l'objet supprimé échoue à la
--    compilation du plan (erreur 8624), avant même la première instruction.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.s0801ChargerJournauxImport', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[s0801ChargerJournauxImport];
GO

IF OBJECT_ID('dbo.s0802ChargerComptesBancairesImport', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[s0802ChargerComptesBancairesImport];
GO

IF OBJECT_ID('staging.JournalImport', 'U') IS NOT NULL
    DROP TABLE staging.JournalImport;
GO

IF OBJECT_ID('staging.CompteBancaireImport', 'U') IS NOT NULL
    DROP TABLE staging.CompteBancaireImport;
GO

-- -----------------------------------------------------------------------------
-- 2) Le registre n'accepte plus ces deux types.
--    La liste reste fermée à dessein : une faute de frappe doit rester une
--    erreur, et un type que rien ne produit n'a pas à être permis.
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_staging_ImportFiles_TypeImport')
    ALTER TABLE staging.ImportFiles DROP CONSTRAINT CK_staging_ImportFiles_TypeImport;
GO

-- Par prudence : si une extraction d'essai avait déposé une de ces deux valeurs,
-- la contrainte refuserait de se reposer. On regarde avant de la recréer.
IF EXISTS (SELECT 1 FROM staging.ImportFiles WHERE [TypeImport] IN ('Journal', 'CompteBancaire'))
    THROW 50382, 'Des fichiers de type Journal ou CompteBancaire existent encore : videz-les avant de resserrer la contrainte.', 1;
GO

ALTER TABLE staging.ImportFiles WITH CHECK
    ADD CONSTRAINT CK_staging_ImportFiles_TypeImport CHECK
    ([TypeImport] IN ('Client', 'Fournisseur', 'Produit',
                      'PlanComptable', 'FactureClient', 'FactureFournisseur',
                      'Societe', 'Taxe',
                      'ModePaiement', 'CategorieSuivi', 'Departement', 'Emplacement'));
GO

-- -----------------------------------------------------------------------------
-- 3) s0803GetListesImport — quatre listes, et plus de colonnes bancaires
--
--    Devise, NumeroMasque et Solde n'existaient que pour les comptes bancaires.
--    Elles s'en vont avec eux : une colonne toujours vide occupe l'écran et
--    laisse croire qu'il manque une donnée.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0803GetListesImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Genre       VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Tout AS (
        SELECT 'ModePaiement' AS [Genre], [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], NULL AS [ParentExterneId],
               [TypeSource], NULL AS [Detail1], NULL AS [Detail2],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.ModePaiementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'CategorieSuivi', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId],
               NULL, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.CategorieSuiviImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Departement', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId],
               NULL, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.DepartementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Emplacement', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId],
               NULL, [Adresse], [Ville],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.EmplacementImport WHERE [CompanyGUID] = @CompanyGUID
    )
    SELECT [Genre], COUNT(*) AS [Nb],
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END) AS [NbSoucis],
           MAX([Created]) AS [Dernier]
      FROM Tout
     GROUP BY [Genre]
     ORDER BY [Genre];

    ;WITH Tout AS (
        SELECT 'ModePaiement' AS [Genre], [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], NULL AS [ParentExterneId],
               [TypeSource], NULL AS [Detail1], NULL AS [Detail2],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.ModePaiementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'CategorieSuivi', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId],
               NULL, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.CategorieSuiviImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Departement', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId],
               NULL, NULL, NULL,
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.DepartementImport WHERE [CompanyGUID] = @CompanyGUID
        UNION ALL
        SELECT 'Emplacement', [Id], [ImportFileId], [RunId], [Rang],
               [ExterneId], [Code], [Nom], [ParentExterneId],
               NULL, [Adresse], [Ville],
               [StatutSource], [Statut], [Anomalie], [Created]
          FROM staging.EmplacementImport WHERE [CompanyGUID] = @CompanyGUID
    )
    SELECT * FROM Tout
     WHERE (@Genre IS NULL OR @Genre = '' OR [Genre] = @Genre)
     ORDER BY [Genre],
              CASE WHEN [Statut] <> 'NOUVEAU' THEN 0 ELSE 1 END,
              [Rang], [Nom];
END
GO

-- -----------------------------------------------------------------------------
-- 4) Le registre et le vidage suivent
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0787GetImportsCompagnie]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 100
           f.[Id], f.[TypeImport], f.[OriginalName], f.[FileExtension], f.[FileSize],
           f.[UploadDate], f.[Status], f.[ProcessedRows], f.[ModelUsed],
           l.[Id]            AS [LotId],
           l.[SystemeSource],
           l.[NbLignesLues], l.[NbLignesRetenues], l.[NbAnomalies],
           (SELECT COUNT(*) FROM staging.PartyImport pi WHERE pi.[ImportFileId] = f.[Id])      AS [NbTiers],
           (SELECT COUNT(*) FROM staging.ProductImport pr WHERE pr.[ImportFileId] = f.[Id])    AS [NbProduits],
           (SELECT COUNT(*) FROM staging.ImportPlanComptable pc WHERE pc.[LotId] = l.[Id])     AS [NbComptes],
           (SELECT COUNT(*) FROM staging.DocumentImport di WHERE di.[ImportFileId] = f.[Id])   AS [NbDocuments],
           (SELECT COUNT(*) FROM staging.SocieteImport si WHERE si.[ImportFileId] = f.[Id])    AS [NbChampsSociete],
           (SELECT COUNT(*) FROM staging.TaxeImport ti WHERE ti.[ImportFileId] = f.[Id])       AS [NbTaux],
           ((SELECT COUNT(*) FROM staging.ModePaiementImport x WHERE x.[ImportFileId] = f.[Id])
          + (SELECT COUNT(*) FROM staging.CategorieSuiviImport x WHERE x.[ImportFileId] = f.[Id])
          + (SELECT COUNT(*) FROM staging.DepartementImport x WHERE x.[ImportFileId] = f.[Id])
          + (SELECT COUNT(*) FROM staging.EmplacementImport x WHERE x.[ImportFileId] = f.[Id])) AS [NbReferences]
      FROM staging.ImportFiles f
      LEFT JOIN staging.ImportLot l ON l.[ImportFileId] = f.[Id]
     WHERE f.[CompanyGUID] = @CompanyGUID
     ORDER BY f.[UploadDate] DESC;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0790ViderStaging]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50370, 'Aucune compagnie : refus de vider la préparation.', 1;

    DECLARE @Compte TABLE ([Ordre] INT, [Table] VARCHAR(60), [Lignes] INT);

    BEGIN TRANSACTION;

    DELETE cc FROM staging.CorrespondanceCompte cc WHERE cc.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (1, 'CorrespondanceCompte', @@ROWCOUNT);

    DELETE pc FROM staging.ImportPlanComptable pc WHERE pc.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (2, 'ImportPlanComptable', @@ROWCOUNT);

    DELETE l FROM staging.ImportLot l WHERE l.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (3, 'ImportLot', @@ROWCOUNT);

    DELETE dl
      FROM staging.DocumentImportLigne dl
      JOIN staging.DocumentImport di ON di.[Id] = dl.[EnteteId]
     WHERE di.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (4, 'DocumentImportLigne', @@ROWCOUNT);

    DELETE di FROM staging.DocumentImport di WHERE di.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (5, 'DocumentImport', @@ROWCOUNT);

    DELETE si FROM staging.SocieteImport si WHERE si.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (6, 'SocieteImport', @@ROWCOUNT);

    DELETE ti FROM staging.TaxeImport ti WHERE ti.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (7, 'TaxeImport', @@ROWCOUNT);

    DELETE x FROM staging.ModePaiementImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (8, 'ModePaiementImport', @@ROWCOUNT);

    DELETE x FROM staging.CategorieSuiviImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (9, 'CategorieSuiviImport', @@ROWCOUNT);

    DELETE x FROM staging.DepartementImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (10, 'DepartementImport', @@ROWCOUNT);

    DELETE x FROM staging.EmplacementImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (11, 'EmplacementImport', @@ROWCOUNT);

    DELETE pi
      FROM staging.PartyImport pi
      JOIN staging.ImportFiles f ON f.[Id] = pi.[ImportFileId]
     WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (12, 'PartyImport', @@ROWCOUNT);

    DELETE pr
      FROM staging.ProductImport pr
      JOIN staging.ImportFiles f ON f.[Id] = pr.[ImportFileId]
     WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (13, 'ProductImport', @@ROWCOUNT);

    DELETE cd FROM staging.ConnecteurDonnee cd WHERE cd.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (14, 'ConnecteurDonnee', @@ROWCOUNT);

    DELETE cr FROM staging.ConnecteurRun cr WHERE cr.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (15, 'ConnecteurRun', @@ROWCOUNT);

    DELETE bv FROM staging.BalanceVerification bv WHERE bv.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (16, 'BalanceVerification', @@ROWCOUNT);

    DELETE f FROM staging.ImportFiles f WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (17, 'ImportFiles', @@ROWCOUNT);

    COMMIT TRANSACTION;

    SELECT [Table], [Lignes] FROM @Compte WHERE [Lignes] > 0 ORDER BY [Ordre];
    SELECT SUM([Lignes]) AS [Total] FROM @Compte;
END
GO
