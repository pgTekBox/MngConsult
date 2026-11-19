-- =============================================================================
-- T403 — « Recommencer l'assistant » (Importation 2) : remettre la compagnie
-- dans l'état d'avant la reprise, SANS effacer les données importées de
-- QuickBooks (staging : ConnecteurDonnee, plan, balance, tiers, produits,
-- factures en préparation — tout reste, prêt à être repris).
--
-- Contrairement à s1026 (outil de test qui vide TOUTE la comptabilité), on ne
-- défait ici que ce que la reprise a elle-même créé, retrouvé par les liens que
-- la préparation garde :
--   · les factures créées depuis la préparation (DocumentImport.DocumentId),
--     leurs lignes, adresses, taxes et écritures liées ;
--   · l'écriture des soldes d'ouverture (NumeroPiece « OUV-REPRISE ») ;
--   · les clients et fournisseurs créés (PartyImport.MigratedToPartyId) ;
--   · les produits créés (ProductImport.MigratedToProductId) ;
--   · les comptes créés au plan par « Créer » (CorrespondanceCompte CREER,
--     ImportPlanComptable.AppliqueLe) ;
--   · toutes les décisions de correspondance : chaque compte redevient « à
--     décider » (les propositions par numéro, nom et IA restent).
--
-- Garde-fous — rien de ce qui a été VALIDÉ ou réutilisé depuis n'est retiré :
--   · une écriture validée (VALIDEE, EXTOURNEE) reste, et la facture qui y
--     mène aussi ; une écriture liée à un règlement reste ;
--   · un tiers resté utilisé (facture, règlement, écriture, rendez-vous) reste ;
--   · un produit resté sur une ligne de facture reste ;
--   · un compte resté utilisé (écriture, gabarit, ligne de facture, produit)
--     ou compte système reste.
-- Ce qui est gardé est compté dans le résultat (« gardé : … »).
--
--   s1027RecommencerReprise @CompanyGUID, @Confirmation = 'RECOMMENCER'
--   → un jeu : Quoi, Nb
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s1027RecommencerReprise]
    @CompanyGUID  UNIQUEIDENTIFIER,
    @Confirmation VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Confirmation IS NULL OR @Confirmation <> 'RECOMMENCER'
        THROW 51080, N'Recommencement non confirmé.', 1;
    IF @CompanyGUID IS NULL OR @CompanyGUID = '00000000-0000-0000-0000-000000000001'
        THROW 51081, N'Compagnie invalide.', 1;

    DECLARE @c UNIQUEIDENTIFIER = @CompanyGUID;
    DECLARE @n TABLE (Quoi NVARCHAR(80), Nb INT);
    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable WHERE [CompanyGUID] = @c);

    BEGIN TRANSACTION;

    -- ── 1. Écritures de la reprise ──────────────────────────────────────────
    -- Les factures créées depuis la préparation, et les écritures qui y mènent.
    DECLARE @docsImport TABLE (Id INT PRIMARY KEY);
    INSERT INTO @docsImport
    SELECT DISTINCT d.[Id]
      FROM staging.DocumentImport di
      JOIN dbo.T060Document d ON d.[Id] = di.[DocumentId] AND d.[CompanyGUID] = @c
     WHERE di.[CompanyGUID] = @c;

    -- Écritures candidates : celles des factures importées + l'ouverture.
    DECLARE @ecrCand TABLE (Id INT PRIMARY KEY);
    INSERT INTO @ecrCand
    SELECT de.[EcrituresId] FROM dbo.T137DocumentEcriture de JOIN @docsImport d ON d.Id = de.[DocumentId]
    UNION
    SELECT e.[Id] FROM dbo.T135Ecritures e WHERE e.[CompanyGUID] = @c AND e.[NumeroPiece] = 'OUV-REPRISE';

    -- Gardées : validées, ou liées à un règlement.
    DECLARE @ecr TABLE (Id INT PRIMARY KEY);
    INSERT INTO @ecr
    SELECT x.Id FROM @ecrCand x JOIN dbo.T135Ecritures e ON e.[Id] = x.Id
     WHERE ISNULL(e.[Statut], '') NOT IN ('VALIDEE', 'EXTOURNEE')
       AND NOT EXISTS (SELECT 1 FROM dbo.T140Reglement r WHERE r.[EcrituresId] = x.Id);
    INSERT INTO @n SELECT N'Écritures validées gardées', COUNT(*) FROM @ecrCand WHERE Id NOT IN (SELECT Id FROM @ecr);

    -- Une facture dont une écriture est gardée reste aussi.
    DECLARE @docs TABLE (Id INT PRIMARY KEY);
    INSERT INTO @docs
    SELECT d.Id FROM @docsImport d
     WHERE NOT EXISTS (SELECT 1 FROM dbo.T137DocumentEcriture de
                        WHERE de.[DocumentId] = d.Id AND de.[EcrituresId] NOT IN (SELECT Id FROM @ecr))
       AND NOT EXISTS (SELECT 1 FROM dbo.T141ReglementDocument rd WHERE rd.[DocumentId] = d.Id);
    INSERT INTO @n SELECT N'Factures gardées (validées ou réglées)', COUNT(*) FROM @docsImport WHERE Id NOT IN (SELECT Id FROM @docs);

    -- ── 2. Factures ─────────────────────────────────────────────────────────
    DELETE x FROM dbo.T071_T061DocumentLine_T070RapportTaxe x
     WHERE x.[T061DocumentLine_id] IN (SELECT l.[Id] FROM dbo.T061DocumentLine l JOIN @docs d ON d.Id = l.[DocumentId]);
    DELETE l FROM dbo.T061DocumentLine l JOIN @docs d ON d.Id = l.[DocumentId];
    DELETE a FROM dbo.T062DocumentAddress a JOIN @docs d ON d.Id = a.[DocumentId];
    DELETE FROM dbo.T208ReleveLien WHERE [EcrituresId] IN (SELECT Id FROM @ecr);
    DELETE de FROM dbo.T137DocumentEcriture de
     WHERE de.[DocumentId] IN (SELECT Id FROM @docs) OR de.[EcrituresId] IN (SELECT Id FROM @ecr);
    DELETE FROM dbo.T060Document WHERE [Id] IN (SELECT Id FROM @docs);
    INSERT INTO @n VALUES (N'Factures créées par la reprise', @@ROWCOUNT);

    UPDATE dbo.T135Ecritures SET [EcritureOrigId] = NULL WHERE [EcritureOrigId] IN (SELECT Id FROM @ecr);
    DELETE l FROM dbo.T136LignesEcriture l JOIN @ecr e ON e.Id = l.[EcrituresId];
    DELETE FROM dbo.T135Ecritures WHERE [Id] IN (SELECT Id FROM @ecr);
    INSERT INTO @n VALUES (N'Écritures (ouverture, factures)', @@ROWCOUNT);

    -- ── 3. Clients et fournisseurs créés par la reprise ─────────────────────
    DECLARE @tiersCand TABLE (Id INT PRIMARY KEY, PartyGUID UNIQUEIDENTIFIER);
    INSERT INTO @tiersCand
    SELECT DISTINCT p.[Id], p.[PartyGUID]
      FROM staging.PartyImport pi
      JOIN staging.ImportFiles f ON f.[Id] = pi.[ImportFileId] AND f.[CompanyGUID] = @c
      JOIN dbo.T050Party p ON p.[Id] = pi.[MigratedToPartyId] AND p.[CompanyGUID] = @c;

    DECLARE @tiers TABLE (Id INT PRIMARY KEY, PartyGUID UNIQUEIDENTIFIER);
    INSERT INTO @tiers
    SELECT t.Id, t.PartyGUID FROM @tiersCand t
     WHERE NOT EXISTS (SELECT 1 FROM dbo.T060Document d WHERE d.[PartyGUID] = t.PartyGUID)
       AND NOT EXISTS (SELECT 1 FROM dbo.T140Reglement r WHERE r.[PartyId] = t.Id)
       AND NOT EXISTS (SELECT 1 FROM dbo.T135Ecritures e WHERE e.[PartyId] = t.Id)
       AND NOT EXISTS (SELECT 1 FROM dbo.T136LignesEcriture l WHERE l.[PartyId] = t.Id)
       AND NOT EXISTS (SELECT 1 FROM dbo.Appointments a WHERE a.[CompanyGUID] = @c AND a.[CustomerId] = t.Id)
       AND NOT EXISTS (SELECT 1 FROM dbo.T050Party enf WHERE enf.[ParentPartyId] = t.Id
                          AND enf.[Id] NOT IN (SELECT Id FROM @tiersCand));
    INSERT INTO @n SELECT N'Tiers gardés (utilisés depuis)', COUNT(*) FROM @tiersCand WHERE Id NOT IN (SELECT Id FROM @tiers);

    UPDATE r SET r.[PartyId] = NULL, r.[PartyGUID] = NULL
      FROM dbo.T0001Receipt r
     WHERE r.[PartyId] IN (SELECT Id FROM @tiers) OR r.[PartyGUID] IN (SELECT PartyGUID FROM @tiers);
    DELETE FROM dbo.T145AutoPayAttempt WHERE [PartyId] IN (SELECT Id FROM @tiers);
    DELETE FROM dbo.T144AuthorizationAutoPay
     WHERE [PartyId] IN (SELECT Id FROM @tiers) OR [PartyGUID] IN (SELECT PartyGUID FROM @tiers);
    UPDATE dbo.T050Party SET [ParentPartyId] = NULL WHERE [ParentPartyId] IN (SELECT Id FROM @tiers);
    DELETE FROM dbo.T054PartyAddress WHERE [PartyId] IN (SELECT Id FROM @tiers);
    DELETE FROM dbo.T057PartyDocument WHERE [PartyId] IN (SELECT Id FROM @tiers);
    DELETE FROM dbo.T050Party WHERE [Id] IN (SELECT Id FROM @tiers);
    INSERT INTO @n VALUES (N'Clients et fournisseurs créés par la reprise', @@ROWCOUNT);

    -- ── 4. Produits créés par la reprise ────────────────────────────────────
    DECLARE @prodCand TABLE (Id INT PRIMARY KEY);
    INSERT INTO @prodCand
    SELECT DISTINCT p.[Id]
      FROM staging.ProductImport pr
      JOIN staging.ImportFiles f ON f.[Id] = pr.[ImportFileId] AND f.[CompanyGUID] = @c
      JOIN dbo.T075Products p ON p.[Id] = pr.[MigratedToProductId] AND p.[CompanyGUID] = @c;

    DECLARE @prod TABLE (Id INT PRIMARY KEY);
    INSERT INTO @prod
    SELECT x.Id FROM @prodCand x
     WHERE NOT EXISTS (SELECT 1 FROM dbo.T061DocumentLine l WHERE l.[ProductId] = x.Id);
    INSERT INTO @n SELECT N'Produits gardés (sur une facture)', COUNT(*) FROM @prodCand WHERE Id NOT IN (SELECT Id FROM @prod);

    DELETE FROM dbo.T331ServiceLieu WHERE [ProductId] IN (SELECT Id FROM @prod);
    DELETE FROM dbo.T075Products WHERE [Id] IN (SELECT Id FROM @prod);
    INSERT INTO @n VALUES (N'Produits créés par la reprise', @@ROWCOUNT);

    -- ── 5. Comptes créés au plan par « Créer » ──────────────────────────────
    DECLARE @cptCand TABLE (Id INT PRIMARY KEY, Compte VARCHAR(50));
    INSERT INTO @cptCand
    SELECT DISTINCT pc.[Id], pc.[Compte]
      FROM staging.CorrespondanceCompte cc
      JOIN staging.ImportPlanComptable p
        ON p.[CompanyGUID] = @c AND p.[CleSource] = cc.[CleSource] AND p.[AppliqueLe] IS NOT NULL
      JOIN dbo.T121PlanComptable pc ON pc.[Id] = cc.[PlanComptableId] AND pc.[CompanyGUID] = @c
     WHERE cc.[CompanyGUID] = @c AND cc.[Action] = 'CREER'
       AND ISNULL(pc.[Systeme], 0) = 0;

    DECLARE @cpt TABLE (Id INT PRIMARY KEY);
    INSERT INTO @cpt
    SELECT x.Id FROM @cptCand x
     WHERE NOT EXISTS (SELECT 1 FROM dbo.T136LignesEcriture l WHERE l.[PlanComptableId] = x.Id)
       AND NOT EXISTS (SELECT 1 FROM dbo.T139TemplateLignes t WHERE t.[PlanComptableId] = x.Id)
       AND NOT EXISTS (SELECT 1 FROM dbo.T061DocumentLine l JOIN dbo.T060Document d ON d.[Id] = l.[DocumentId]
                        WHERE d.[CompanyGUID] = @c AND l.[CompteComptable] = x.Compte)
       AND NOT EXISTS (SELECT 1 FROM dbo.T075Products pr WHERE pr.[CompanyGUID] = @c
                          AND x.Compte IN (pr.[CompteVente], pr.[CompteAchat], pr.[Account]));
    INSERT INTO @n SELECT N'Comptes créés gardés (utilisés depuis)', COUNT(*) FROM @cptCand WHERE Id NOT IN (SELECT Id FROM @cpt);

    -- La préparation qui pointe vers ces comptes n'y pointe plus.
    UPDATE staging.ImportPlanComptable
       SET [PlanComptableId] = NULL,
           [Statut] = CASE WHEN [Statut] = 'EXISTE' THEN 'OK' ELSE [Statut] END
     WHERE [CompanyGUID] = @c AND [PlanComptableId] IN (SELECT Id FROM @cpt);
    UPDATE staging.ImportPlanComptable SET [ProposeIAId] = NULL
     WHERE [CompanyGUID] = @c AND [ProposeIAId] IN (SELECT Id FROM @cpt);

    -- ── 6. Décisions de correspondance : toutes remises à décider ──────────
    DELETE FROM staging.CorrespondanceCompte WHERE [CompanyGUID] = @c;
    INSERT INTO @n VALUES (N'Décisions de correspondance remises à décider', @@ROWCOUNT);

    DELETE FROM dbo.T121PlanComptable WHERE [Id] IN (SELECT Id FROM @cpt);
    INSERT INTO @n VALUES (N'Comptes créés au plan par la reprise', @@ROWCOUNT);

    UPDATE staging.ImportPlanComptable
       SET [AppliqueLe] = NULL, [AppliquePar] = NULL
     WHERE [CompanyGUID] = @c AND [AppliqueLe] IS NOT NULL;

    -- ── 7. La préparation redevient « à faire » (rien n'y est effacé) ──────
    UPDATE pi
       SET pi.[Status] = 'Pending', pi.[MigratedToPartyId] = NULL, pi.[MigratedDate] = NULL, pi.[ErrorMessage] = NULL
      FROM staging.PartyImport pi
      JOIN staging.ImportFiles f ON f.[Id] = pi.[ImportFileId] AND f.[CompanyGUID] = @c
     WHERE pi.[Status] <> 'Pending'
       AND NOT EXISTS (SELECT 1 FROM dbo.T050Party p WHERE p.[Id] = pi.[MigratedToPartyId]);

    UPDATE pr
       SET pr.[Status] = 'Pending', pr.[MigratedToProductId] = NULL, pr.[MigratedDate] = NULL, pr.[ErrorMessage] = NULL
      FROM staging.ProductImport pr
      JOIN staging.ImportFiles f ON f.[Id] = pr.[ImportFileId] AND f.[CompanyGUID] = @c
     WHERE pr.[Status] <> 'Pending'
       AND NOT EXISTS (SELECT 1 FROM dbo.T075Products p WHERE p.[Id] = pr.[MigratedToProductId]);

    UPDATE di
       SET di.[DocumentId] = NULL, di.[MigratedDate] = NULL,
           di.[Statut] = CASE WHEN di.[Statut] = 'EXISTE' THEN 'OK' ELSE di.[Statut] END,
           di.[PartyGUID] = CASE WHEN EXISTS (SELECT 1 FROM dbo.T050Party p WHERE p.[PartyGUID] = di.[PartyGUID]) THEN di.[PartyGUID] ELSE NULL END
      FROM staging.DocumentImport di
     WHERE di.[CompanyGUID] = @c
       AND (di.[DocumentId] IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.T060Document d WHERE d.[Id] = di.[DocumentId]));

    UPDATE l SET l.[ProductId] = NULL
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport di ON di.[Id] = l.[EnteteId] AND di.[CompanyGUID] = @c
     WHERE l.[ProductId] IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.T075Products p WHERE p.[Id] = l.[ProductId]);

    UPDATE staging.PaiementImport SET [PartyGUID] = NULL
     WHERE [CompanyGUID] = @c AND [PartyGUID] IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.T050Party p WHERE p.[PartyGUID] = staging.PaiementImport.[PartyGUID]);
    UPDATE staging.PieceCommercialeImport SET [PartyGUID] = NULL
     WHERE [CompanyGUID] = @c AND [PartyGUID] IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.T050Party p WHERE p.[PartyGUID] = staging.PieceCommercialeImport.[PartyGUID]);
    UPDATE staging.BalanceAgeeImport SET [PartyGUID] = NULL
     WHERE [CompanyGUID] = @c AND [PartyGUID] IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.T050Party p WHERE p.[PartyGUID] = staging.BalanceAgeeImport.[PartyGUID]);

    COMMIT TRANSACTION;

    SELECT Quoi, Nb FROM @n;
END
GO
