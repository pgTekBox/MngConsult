-- =============================================================================
-- T247 — Le registre des imports accepte le grand livre
--
-- Même histoire que T245, un cran plus loin : staging.ImportFiles.TypeImport
-- est contrôlé par une liste blanche, et « GrandLivre » n'y était pas. L'import
-- aurait chargé ses lignes, puis échoué à s'inscrire au registre — la faute
-- serait ressortie en violation de contrainte, loin de sa cause.
--
-- La liste est reprise en entier plutôt que complétée : une contrainte CHECK ne
-- s'étend pas, elle se remplace. Tout ce qui y était y reste, anciens types
-- compris, pour la raison donnée dans T245 — les fichiers déjà inscrits ne
-- doivent pas devenir invalides à cause d'une règle écrite après eux.
--
-- La colonne fait déjà VARCHAR(30) depuis T245 : « GrandLivre » en compte dix,
-- rien à élargir.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

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
        'RapportBilan', 'RapportResultats',
        -- Anciens types : gardés pour les fichiers déjà inscrits
        'BalanceAgee', 'Rapport'
    ));
GO
