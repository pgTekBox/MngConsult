-- =============================================================================
-- T075Products_AddSquareColumns
-- Ajoute les colonnes de correspondance Square directement sur la table produits
-- (relation 1-a-1 : un produit appartient a une compagnie => un seul item Square).
-- Meme approche que les colonnes Stripe ajoutees sur T050Party / T015User.
--
-- Les versions Square (item + variation) sont requises par l'API pour les
-- mises a jour ulterieures.
-- =============================================================================

IF COL_LENGTH('dbo.T075Products', 'SquareItemId') IS NULL
BEGIN
    ALTER TABLE dbo.T075Products ADD
        SquareItemId            VARCHAR(100) NULL,
        SquareVariationId       VARCHAR(100) NULL,
        SquareItemVersion       BIGINT       NULL,
        SquareVariationVersion  BIGINT       NULL,
        SquareSyncStatus        VARCHAR(20)  NULL,   -- 'OK' | 'ERROR'
        SquareSyncDate          DATETIME     NULL;
END
GO
