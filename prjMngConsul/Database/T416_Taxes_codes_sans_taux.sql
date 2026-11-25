-- =============================================================================
-- T416 — Codes et taux de taxe : les codes à 0 % se classent tout seuls
--
-- QuickBooks donne toujours, à côté de TPS et TPS/TVQ, des codes sans taux :
-- « Détaxé », « Exonéré », « Hors champ », et des codes de « Redressement ».
-- Le versement les laissait « à vérifier » (aucune composante TPS ou TVQ), et
-- la carte « Codes et taux de taxe » d'Importation 2 ne se terminait jamais.
--
-- Leur nom suffit à les classer — c'est ce que fait déjà s0785 pour le statut
-- de taxe des lignes de facture (Détaxé / Exempt) :
--   · détaxé, zero-rated, taux zéro           → RECONNUE, TPS 0, TVQ 0 (détaxé)
--   · exonéré, exempt, hors champ, out of scope → RECONNUE, TPS 0, TVQ 0 (exempt)
--   · redressement, adjustment                 → RECONNUE, TPS 0, TVQ 0 : il ne
--     sert qu'aux déclarations, jamais de taux sur une facture.
-- Un code à 0 % au nom inconnu reste « à vérifier ».
--
--   s1037ClasserTaxesSansTaux @CompanyGUID → NbClasses
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s1037ClasserTaxesSansTaux]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE t
       SET t.[Statut]   = 'RECONNUE',
           t.[TauxTPS]  = 0,
           t.[TauxTVQ]  = 0,
           t.[Anomalie] = k.[Motif]
      FROM staging.TaxeImport t
     CROSS APPLY (SELECT ISNULL(t.[Code], '') + N' ' + ISNULL(t.[Nom], '') AS [Texte]) n
     CROSS APPLY (SELECT CASE
                    WHEN n.[Texte] LIKE N'%détax%' OR n.[Texte] LIKE N'%detax%' OR n.[Texte] LIKE N'%zero%rated%'
                      OR n.[Texte] LIKE N'%zéro%' OR n.[Texte] LIKE N'%zero-rated%'
                         THEN N'Détaxé : taux 0 %, classé d''après son nom.'
                    WHEN n.[Texte] LIKE N'%exon%r%' OR n.[Texte] LIKE N'%exempt%'
                      OR n.[Texte] LIKE N'%hors champ%' OR n.[Texte] LIKE N'%out of scope%'
                         THEN N'Exonéré ou hors champ : aucune taxe, classé d''après son nom.'
                    WHEN n.[Texte] LIKE N'%redressement%' OR n.[Texte] LIKE N'%adjustment%'
                         THEN N'Redressement : sert aux déclarations, jamais de taux sur une facture.'
                  END AS [Motif]) k
     WHERE t.[CompanyGUID] = @CompanyGUID
       AND t.[Statut] = 'A_VERIFIER'
       AND ISNULL(t.[TauxTPS], 0) = 0
       AND ISNULL(t.[TauxTVQ], 0) = 0
       AND ISNULL(t.[TauxAutre], 0) = 0
       AND k.[Motif] IS NOT NULL;

    SELECT @@ROWCOUNT AS NbClasses;
END
GO
