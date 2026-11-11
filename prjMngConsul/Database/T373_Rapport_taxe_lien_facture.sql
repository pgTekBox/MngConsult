-- =============================================================================
-- T373 — Rapport de taxes : la pièce mène à sa facture
--
-- Le détail des écritures du rapport (2e jeu de sp_GenererRapportTaxe) renvoie
-- en plus la source de l'écriture : SourceType (FACTURE_CLIENT, FACTURE_FOURN,
-- REGLEMENT, MANUEL…) et DocumentId (T060Document, via T135.SourceId, seulement
-- pour les factures et bornée à la compagnie). wbfRapportTaxe fait du numéro de
-- pièce un lien qui ouvre la facture (client : wbfInvoiceEdit ; fournisseur :
-- wbfSupplierInvoinceEdit).
--
-- La procédure n'est pas réécrite : son texte actuel est relu sur le serveur
-- et seuls deux morceaux du 2e jeu de résultats sont remplacés (colonnes +
-- jointure), puis ALTER. Sans effet si c'est déjà fait (colonne DocumentId).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

DECLARE @def NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_GenererRapportTaxe'));

IF @def IS NULL
    THROW 51090, 'sp_GenererRapportTaxe introuvable.', 1;

IF CHARINDEX(N'AS DocumentId', @def) = 0
BEGIN
    DECLARE @col NVARCHAR(200) = N'c.[Nom] AS NomCompte,';
    DECLARE @jn  NVARCHAR(200) = N'INNER JOIN [dbo].[T121PlanComptable]  c ON c.[Id] = l.[PlanComptableId]';

    -- « c.[Nom] AS NomCompte, » et la jointure à deux espaces n'existent que dans le 2e jeu
    IF (LEN(@def) - LEN(REPLACE(@def, @col, N''))) / LEN(@col) <> 1
        THROW 51091, 'sp_GenererRapportTaxe : colonne NomCompte du détail introuvable ou ambiguë.', 1;
    IF (LEN(@def) - LEN(REPLACE(@def, @jn, N''))) / LEN(@jn) <> 1
        THROW 51092, 'sp_GenererRapportTaxe : jointure T121 du détail introuvable ou ambiguë.', 1;

    SET @def = REPLACE(@def, @col,
        N'c.[Nom] AS NomCompte, e.[SourceType], doc.[Id] AS DocumentId,');
    SET @def = REPLACE(@def, @jn, @jn +
        N' LEFT JOIN [dbo].[T060Document] doc ON doc.[Id] = e.[SourceId] AND doc.[CompanyGUID] = e.[CompanyGUID]' +
        N' AND e.[SourceType] IN (''FACTURE_CLIENT'', ''FACTURE_FOURN'')');

    -- CREATE → ALTER (premier mot-clé de la définition)
    DECLARE @p INT = CHARINDEX(N'CREATE', @def);
    SET @def = STUFF(@def, @p, 6, N'ALTER');

    EXEC sys.sp_executesql @def;
END
GO
