-- =============================================================================
-- T313 — L'avancement réel de la reprise, poste par poste
--
-- Le centre d'importation notait les postes obligatoires (balance, clients,
-- fournisseurs, produits, factures, taxes) sur la maturité du code : 5 ou 8
-- sur 10 pour tout le monde, quoi qu'ait fait la compagnie. La note doit dire
-- où en est la compagnie : rien de lu, en préparation, appliqué.
--
-- s0896GetAvancementImport rend, pour une compagnie, une ligne par poste :
-- ce qui attend en préparation et ce qui a été appliqué (créé en comptabilité,
-- ou reconnu pour les taxes). La balance ne s'applique pas encore : 0.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0896GetAvancementImport]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 'Client' AS Poste,
           COUNT(*) AS Prepares,
           SUM(CASE WHEN p.MigratedToPartyId IS NOT NULL THEN 1 ELSE 0 END) AS Appliques
    FROM staging.PartyImport p
    JOIN staging.ImportFiles f ON f.Id = p.ImportFileId
    WHERE f.CompanyGUID = @CompanyGUID AND p.TypeImport = 'Client'

    UNION ALL
    SELECT 'Fournisseur',
           COUNT(*),
           SUM(CASE WHEN p.MigratedToPartyId IS NOT NULL THEN 1 ELSE 0 END)
    FROM staging.PartyImport p
    JOIN staging.ImportFiles f ON f.Id = p.ImportFileId
    WHERE f.CompanyGUID = @CompanyGUID AND p.TypeImport = 'Fournisseur'

    UNION ALL
    SELECT 'Produit',
           COUNT(*),
           SUM(CASE WHEN p.MigratedToProductId IS NOT NULL THEN 1 ELSE 0 END)
    FROM staging.ProductImport p
    JOIN staging.ImportFiles f ON f.Id = p.ImportFileId
    WHERE f.CompanyGUID = @CompanyGUID

    UNION ALL
    SELECT 'Balance', COUNT(*), 0
    FROM staging.BalanceVerification
    WHERE CompanyGUID = @CompanyGUID

    UNION ALL
    SELECT 'Facture',
           COUNT(*),
           SUM(CASE WHEN DocumentId IS NOT NULL THEN 1 ELSE 0 END)
    FROM staging.DocumentImport
    WHERE CompanyGUID = @CompanyGUID

    UNION ALL
    SELECT 'Taxe',
           COUNT(*),
           SUM(CASE WHEN Statut = 'RECONNUE' THEN 1 ELSE 0 END)
    FROM staging.TaxeImport
    WHERE CompanyGUID = @CompanyGUID;
END
GO
