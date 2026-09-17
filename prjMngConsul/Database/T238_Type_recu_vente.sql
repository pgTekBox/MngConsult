-- =============================================================================
-- T238 — Un type de document pour le reçu de vente
--
-- ⚠️ SEULE MODIFICATION DE CE CHANTIER QUI TOUCHE UNE TABLE DE RÉFÉRENCE DE
--    L'ERP. Elle est additive et se défait par un DELETE.
--
-- Un reçu de vente est une vente payée sur-le-champ : du revenu, pas un devis.
-- Il a donc sa place parmi les documents, à côté des factures.
--
-- On ne peut PAS le ranger sous FactureClient (1). `s0781ChargerDocumentsImport`
-- remplace ce qu'elle charge par (compagnie + type + extraction) : verser les
-- reçus en type 1 EFFACERAIT les factures chargées quelques secondes plus tôt
-- dans la même extraction. Le défaut serait silencieux — des factures qui
-- disparaissent sans message.
--
-- Les types voisins ne conviennent pas davantage : 5 ReceiptOCR désigne un reçu
-- d'ACHAT photographié, 9 Autre ne veut rien dire. D'où le type 7.
--
-- Les identifiants 7 et 8 étaient libres (la table va de 1 à 6, puis 9).
-- [Id] n'est pas une colonne d'identité : l'insertion se fait directement.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.T065DocumentType WHERE [Id] = 7)
BEGIN
    INSERT INTO dbo.T065DocumentType ([Id], [Name], [Description], [Created])
    VALUES (7, 'RecuVente', 'Reçu de vente (vente payée comptant)', GETDATE());
END
GO

SELECT [Id], [Name], [Description] FROM dbo.T065DocumentType ORDER BY [Id];
GO
