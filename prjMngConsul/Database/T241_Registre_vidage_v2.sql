-- =============================================================================
-- T241 — Le registre et le vidage prennent les pièces jointes et les conditions
--
-- Deux tables de plus, deux endroits à mettre à jour. Un vidage qui oublie une
-- table est pire qu'un vidage absent : on croit repartir propre.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

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
          + (SELECT COUNT(*) FROM staging.EmplacementImport x WHERE x.[ImportFileId] = f.[Id])) AS [NbReferences],
           (SELECT COUNT(*) FROM staging.PieceCommercialeImport x WHERE x.[ImportFileId] = f.[Id]) AS [NbPieces],
           (SELECT COUNT(*) FROM staging.PaiementImport x WHERE x.[ImportFileId] = f.[Id])         AS [NbPaiements],
           (SELECT COUNT(*) FROM staging.EcritureImport x WHERE x.[ImportFileId] = f.[Id])         AS [NbEcritures],
           ((SELECT COUNT(*) FROM staging.RapportImport x WHERE x.[ImportFileId] = f.[Id])
          + (SELECT COUNT(*) FROM staging.BalanceAgeeImport x WHERE x.[ImportFileId] = f.[Id]))    AS [NbRapports],
           (SELECT COUNT(*) FROM staging.PieceJointeImport x WHERE x.[ImportFileId] = f.[Id])      AS [NbPiecesJointes],
           (SELECT COUNT(*) FROM staging.ConditionPaiementImport x WHERE x.[ImportFileId] = f.[Id]) AS [NbConditions]
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

    -- ── Ce qui existait avant ────────────────────────────────────────────
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

    -- ── Les transactions ─────────────────────────────────────────────────
    -- L'enfant avant le parent, même quand la cascade existe : on veut compter
    -- ce qui part, et un compte que la cascade fait dans notre dos serait faux.
    DELETE l
      FROM staging.PieceCommercialeImportLigne l
      JOIN staging.PieceCommercialeImport e ON e.[Id] = l.[EnteteId]
     WHERE e.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (12, 'PieceCommercialeImportLigne', @@ROWCOUNT);

    DELETE x FROM staging.PieceCommercialeImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (13, 'PieceCommercialeImport', @@ROWCOUNT);

    DELETE a
      FROM staging.PaiementImportAffectation a
      JOIN staging.PaiementImport p ON p.[Id] = a.[PaiementId]
     WHERE p.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (14, 'PaiementImportAffectation', @@ROWCOUNT);

    DELETE x FROM staging.PaiementImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (15, 'PaiementImport', @@ROWCOUNT);

    DELETE l
      FROM staging.EcritureImportLigne l
      JOIN staging.EcritureImport e ON e.[Id] = l.[EnteteId]
     WHERE e.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (16, 'EcritureImportLigne', @@ROWCOUNT);

    DELETE x FROM staging.EcritureImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (17, 'EcritureImport', @@ROWCOUNT);

    -- ── Les rapports ─────────────────────────────────────────────────────
    DELETE l
      FROM staging.RapportImportLigne l
      JOIN staging.RapportImport r ON r.[Id] = l.[RapportId]
     WHERE r.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (18, 'RapportImportLigne', @@ROWCOUNT);

    DELETE x FROM staging.RapportImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (19, 'RapportImport', @@ROWCOUNT);

    DELETE x FROM staging.BalanceAgeeImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (20, 'BalanceAgeeImport', @@ROWCOUNT);

    -- ── Les pièces jointes et les conditions ─────────────────────────────
    DELETE x FROM staging.PieceJointeImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (2005, 'PieceJointeImport', @@ROWCOUNT);

    DELETE x FROM staging.ConditionPaiementImport x WHERE x.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (2006, 'ConditionPaiementImport', @@ROWCOUNT);

    -- ── Les listes rattachées au fichier ─────────────────────────────────
    DELETE pi
      FROM staging.PartyImport pi
      JOIN staging.ImportFiles f ON f.[Id] = pi.[ImportFileId]
     WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (21, 'PartyImport', @@ROWCOUNT);

    DELETE pr
      FROM staging.ProductImport pr
      JOIN staging.ImportFiles f ON f.[Id] = pr.[ImportFileId]
     WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (22, 'ProductImport', @@ROWCOUNT);

    DELETE cd FROM staging.ConnecteurDonnee cd WHERE cd.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (23, 'ConnecteurDonnee', @@ROWCOUNT);

    DELETE cr FROM staging.ConnecteurRun cr WHERE cr.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (24, 'ConnecteurRun', @@ROWCOUNT);

    DELETE bv FROM staging.BalanceVerification bv WHERE bv.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (25, 'BalanceVerification', @@ROWCOUNT);

    DELETE f FROM staging.ImportFiles f WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (26, 'ImportFiles', @@ROWCOUNT);

    COMMIT TRANSACTION;

    SELECT [Table], [Lignes] FROM @Compte WHERE [Lignes] > 0 ORDER BY [Ordre];
    SELECT SUM([Lignes]) AS [Total] FROM @Compte;
END

GO
