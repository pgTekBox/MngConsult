-- =============================================================================
-- T402 — OUTIL DE TEST : réinitialiser la comptabilité d'une compagnie pour
-- rejouer la reprise (Importation 2) avec les données déjà en préparation.
--
-- Bouton « Réinitialiser » de l'en-tête d'Importation2.aspx, offert seulement
-- aux compagnies listées dans Web.config (Importation2.Reinitialisables).
--
-- EFFACE, pour la compagnie :
--   · les factures et documents (T060 et leurs lignes, adresses, taxes)
--   · les règlements (T140/T141) ; un relevé bancaire garde ses lignes mais
--     perd son lien au règlement ou à l'écriture (T142, T208)
--   · toutes les écritures (T135/T136, T137)
--   · tous les rendez-vous (et leurs demandes, T328, en cascade)
--   · tous les clients et fournisseurs (types 1, 2, 3) ; les reçus restent,
--     sans lien au tiers ; les préautorisations de paiement sont effacées
--   · tous les produits, et leurs liens aux lieux de service (T331)
-- RAMÈNE le plan comptable au plan par défaut (s0877, compagnie modèle) :
--   les comptes absents du modèle sont retirés, les comptes manquants rétablis.
-- REMET la préparation en état « à faire », sans rien y effacer :
--   · décisions de correspondance : toutes effacées, chaque compte redevient
--     « à décider » (les propositions par numéro, nom et IA restent)
--   · plan, tiers, produits et factures en préparation : plus de « déjà créé »
--
-- Ne touche pas : la préparation elle-même (staging), les journaux, les
-- exercices, les taxes, les paramètres, les usagers.
--
--   s1026ReinitialiserReprise @CompanyGUID, @Confirmation = 'REINITIALISER'
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s1026ReinitialiserReprise]
    @CompanyGUID  UNIQUEIDENTIFIER,
    @Confirmation VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Confirmation IS NULL OR @Confirmation <> 'REINITIALISER'
        THROW 51070, N'Réinitialisation non confirmée.', 1;
    IF @CompanyGUID IS NULL OR @CompanyGUID = '00000000-0000-0000-0000-000000000001'
        THROW 51071, N'Compagnie invalide.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE [CompanyGUID] = @CompanyGUID)
        THROW 51072, N'La compagnie n''existe pas.', 1;

    DECLARE @c UNIQUEIDENTIFIER = @CompanyGUID;
    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';
    DECLARE @n TABLE (Quoi NVARCHAR(60), Nb INT);

    BEGIN TRANSACTION;

    -- ── 1. Factures et documents ────────────────────────────────────────────
    DECLARE @docs TABLE (Id INT PRIMARY KEY);
    INSERT INTO @docs SELECT [Id] FROM dbo.T060Document WHERE [CompanyGUID] = @c;

    DELETE x FROM dbo.T071_T061DocumentLine_T070RapportTaxe x
     WHERE x.[T061DocumentLine_id] IN (SELECT l.[Id] FROM dbo.T061DocumentLine l JOIN @docs d ON d.Id = l.[DocumentId]);
    DELETE l FROM dbo.T061DocumentLine l JOIN @docs d ON d.Id = l.[DocumentId];
    DELETE a FROM dbo.T062DocumentAddress a JOIN @docs d ON d.Id = a.[DocumentId];

    -- ── 2. Règlements ───────────────────────────────────────────────────────
    DECLARE @regl TABLE (Id INT PRIMARY KEY);
    INSERT INTO @regl SELECT [Id] FROM dbo.T140Reglement WHERE [CompanyGUID] = @c;

    DELETE rd FROM dbo.T141ReglementDocument rd
     WHERE rd.[DocumentId] IN (SELECT Id FROM @docs) OR rd.[ReglementId] IN (SELECT Id FROM @regl);
    UPDATE dbo.T142ReleveBancaire SET [ReglementId] = NULL WHERE [ReglementId] IN (SELECT Id FROM @regl);
    DELETE FROM dbo.T145AutoPayAttempt WHERE [ReglementId] IN (SELECT Id FROM @regl);

    -- ── 3. Écritures ────────────────────────────────────────────────────────
    DECLARE @ecr TABLE (Id INT PRIMARY KEY);
    INSERT INTO @ecr SELECT [Id] FROM dbo.T135Ecritures WHERE [CompanyGUID] = @c;

    DELETE FROM dbo.T208ReleveLien
     WHERE [CompanyGUID] = @c OR [ReglementId] IN (SELECT Id FROM @regl) OR [EcrituresId] IN (SELECT Id FROM @ecr);
    DELETE de FROM dbo.T137DocumentEcriture de
     WHERE de.[DocumentId] IN (SELECT Id FROM @docs) OR de.[EcrituresId] IN (SELECT Id FROM @ecr);

    DELETE FROM dbo.T140Reglement WHERE [Id] IN (SELECT Id FROM @regl);
    INSERT INTO @n VALUES (N'Règlements', @@ROWCOUNT);

    DELETE FROM dbo.T060Document WHERE [Id] IN (SELECT Id FROM @docs);
    INSERT INTO @n VALUES (N'Factures et documents', @@ROWCOUNT);

    UPDATE dbo.T135Ecritures SET [EcritureOrigId] = NULL WHERE [EcritureOrigId] IN (SELECT Id FROM @ecr);
    DELETE l FROM dbo.T136LignesEcriture l JOIN @ecr e ON e.Id = l.[EcrituresId];
    DELETE FROM dbo.T135Ecritures WHERE [Id] IN (SELECT Id FROM @ecr);
    INSERT INTO @n VALUES (N'Écritures', @@ROWCOUNT);

    -- ── 4. Plan comptable : ce qui sera retiré, puis la préparation qui y pointe
    DECLARE @retires TABLE (Id INT PRIMARY KEY);
    INSERT INTO @retires
    SELECT d.[Id] FROM dbo.T121PlanComptable d
     WHERE d.[CompanyGUID] = @c AND ISNULL(d.[Systeme], 0) = 0
       AND NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable m WHERE m.[CompanyGUID] = @Model AND m.[Compte] = d.[Compte])
       AND NOT EXISTS (SELECT 1 FROM dbo.T139TemplateLignes l WHERE l.[PlanComptableId] = d.[Id]);

    -- Départ neuf : toutes les décisions de correspondance (Lier, Créer,
    -- Ignorer) sont effacées ; chaque compte redevient « à décider ». Les
    -- propositions (numéro, nom, IA) restent : elles font partie de la préparation.
    DELETE FROM staging.CorrespondanceCompte WHERE [CompanyGUID] = @c;
    INSERT INTO @n VALUES (N'Décisions de correspondance remises à décider', @@ROWCOUNT);

    UPDATE staging.ImportPlanComptable
       SET [AppliqueLe] = NULL, [AppliquePar] = NULL
     WHERE [CompanyGUID] = @c AND [AppliqueLe] IS NOT NULL;

    UPDATE staging.ImportPlanComptable
       SET [PlanComptableId] = NULL,
           [Statut] = CASE WHEN [Statut] = 'EXISTE' THEN 'OK' ELSE [Statut] END
     WHERE [CompanyGUID] = @c AND [PlanComptableId] IN (SELECT Id FROM @retires);

    UPDATE staging.ImportPlanComptable SET [ProposeIAId] = NULL
     WHERE [CompanyGUID] = @c AND [ProposeIAId] IN (SELECT Id FROM @retires);

    -- ── 5. Rendez-vous, clients, fournisseurs, produits ─────────────────────
    -- Départ neuf : tous les rendez-vous (leurs demandes T328 suivent en
    -- cascade) et TOUS les clients et fournisseurs. Les reçus sont gardés,
    -- sans leur lien au tiers ; les préautorisations de paiement sont effacées.
    DELETE FROM dbo.Appointments WHERE [CompanyGUID] = @c;
    INSERT INTO @n VALUES (N'Rendez-vous', @@ROWCOUNT);

    DECLARE @tiers TABLE (Id INT PRIMARY KEY, PartyGUID UNIQUEIDENTIFIER);
    INSERT INTO @tiers
    SELECT p.[Id], p.[PartyGUID] FROM dbo.T050Party p
     WHERE p.[CompanyGUID] = @c AND p.[Type] IN (1, 2, 3);

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
    INSERT INTO @n VALUES (N'Clients et fournisseurs', @@ROWCOUNT);

    -- Tous les produits ; leurs liens aux lieux de service (T331) partent avec eux.
    DECLARE @prod TABLE (Id INT PRIMARY KEY);
    INSERT INTO @prod SELECT pr.[Id] FROM dbo.T075Products pr WHERE pr.[CompanyGUID] = @c;

    DELETE FROM dbo.T331ServiceLieu WHERE [ProductId] IN (SELECT Id FROM @prod);
    INSERT INTO @n VALUES (N'Liens produit ↔ lieu de service', @@ROWCOUNT);

    DELETE FROM dbo.T075Products WHERE [Id] IN (SELECT Id FROM @prod);
    INSERT INTO @n VALUES (N'Produits et services', @@ROWCOUNT);

    -- ── 6. La préparation redevient « à faire » ────────────────────────────
    UPDATE pi
       SET pi.[Status] = 'Pending', pi.[MigratedToPartyId] = NULL, pi.[MigratedDate] = NULL, pi.[ErrorMessage] = NULL
      FROM staging.PartyImport pi
      JOIN staging.ImportFiles f ON f.[Id] = pi.[ImportFileId] AND f.[CompanyGUID] = @c
     WHERE pi.[Status] <> 'Pending'
       AND NOT EXISTS (SELECT 1 FROM dbo.T050Party p WHERE p.[Id] = pi.[MigratedToPartyId]);
    INSERT INTO @n VALUES (N'Tiers en préparation remis à créer', @@ROWCOUNT);

    UPDATE pr
       SET pr.[Status] = 'Pending', pr.[MigratedToProductId] = NULL, pr.[MigratedDate] = NULL, pr.[ErrorMessage] = NULL
      FROM staging.ProductImport pr
      JOIN staging.ImportFiles f ON f.[Id] = pr.[ImportFileId] AND f.[CompanyGUID] = @c
     WHERE pr.[Status] <> 'Pending'
       AND NOT EXISTS (SELECT 1 FROM dbo.T075Products p WHERE p.[Id] = pr.[MigratedToProductId]);
    INSERT INTO @n VALUES (N'Produits en préparation remis à créer', @@ROWCOUNT);

    UPDATE di
       SET di.[DocumentId] = NULL, di.[MigratedDate] = NULL,
           di.[Statut] = CASE WHEN di.[Statut] = 'EXISTE' THEN 'OK' ELSE di.[Statut] END,
           di.[PartyGUID] = CASE WHEN EXISTS (SELECT 1 FROM dbo.T050Party p WHERE p.[PartyGUID] = di.[PartyGUID]) THEN di.[PartyGUID] ELSE NULL END
      FROM staging.DocumentImport di
     WHERE di.[CompanyGUID] = @c;
    INSERT INTO @n VALUES (N'Factures en préparation remises à créer', @@ROWCOUNT);

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

    -- ── 7. Plan par défaut (s0877 : retire les comptes hors modèle désormais
    --       libres, rétablit les comptes du modèle qui manquent) ─────────────
    -- s0877 rend ses deux jeux avant le nôtre : l'appelant lit le DERNIER jeu.
    BEGIN TRY
        EXEC dbo.s0877ResyncPlanComptableDepuisModele @CompanyGUID = @c, @SupprimerEnTrop = 1, @Simuler = 0;
    END TRY
    BEGIN CATCH
        INSERT INTO @n VALUES (N'Plan par défaut : échec — ' + LEFT(ERROR_MESSAGE(), 200), 0);
    END CATCH

    INSERT INTO @n SELECT N'Comptes au plan après réinitialisation', COUNT(*) FROM dbo.T121PlanComptable WHERE [CompanyGUID] = @c;

    SELECT Quoi, Nb FROM @n;
END
GO
