-- =============================================================================
-- T365_Recherche_factures_clients_numeros
-- s0026GetCustomersInvoices : la recherche de la liste des factures clients
-- accepte des numéros de facture (un ou plusieurs, séparés par , ; ou espace),
-- en plus du nom du client. @Search passe à VARCHAR(1000). Même règle que
-- s0023 pour les factures fournisseurs (T364).
-- Sert aux activités du tableau de bord, qui ouvrent la liste filtrée sur les
-- factures concernées (wbfCustomersInvoices.aspx?factures=… ou ?etat=Brouillon).
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- @Etats / @StatutsPaiement : listes separees par des virgules, pour les filtres
--   a selection multiple de la grille. Vide ou NULL = aucun filtre (tout sort).
--   Valeurs attendues :
--     @Etats           'Brouillon', 'Comptabilise'  (accents ignores, cf. collation)
--     @StatutsPaiement 'OUVERTE', 'PARTIELLE', 'EN_RETARD', 'PAYEE', 'IN_PROGRESS'
--   Les deux parametres ont une valeur par defaut : les appelants existants
--   (application mobile, rapports) ne changent pas.
CREATE OR ALTER PROCEDURE [dbo].[s0026GetCustomersInvoices]
    @CompanyGUID uniqueidentifier,
    @Search varchar(1000),
    @Etats varchar(200) = NULL,
    @StatutsPaiement varchar(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        v.[Id],

        -- Reconstitution du HTML : nom + adresse, puis courriel (billing) en dessous
        '<div>' + ISNULL(v.[NameRaw], '') + ' '
            + ISNULL(v.[Address1], '')
            + ISNULL(v.[Address2], '') + ' '
            + ISNULL(v.[City], '') + '</div>'
            + CASE WHEN NULLIF(LTRIM(RTRIM(d.[Email])), '') IS NOT NULL
                   THEN '<div class="cust-email">' + d.[Email] + '</div>'
                   ELSE '' END                             AS [Name],

        d.[Email]                                          AS [Email],

        -- Colonnes BRUTES pour le tri de la grille : les colonnes affichées
        -- ci-dessus contiennent du HTML, on ne peut pas trier dessus.
        v.[NameRaw]                                        AS [NameSort],
        v.[DocumentNumber]                                 AS [NumeroSort],

        v.[Total],

        -- Indicateurs de paiement (déjà calculés dans la vue)
        v.[DejaRecu],
        v.[ResteAPayer],
        v.[StatutPaiement],

        -- DocumentNumber TOUJOURS avec lien PDF.
        -- Le PDF est servi/généré à la demande par InvoicePdf.ashx (assembly
        -- principal), qui le crée s'il n'existe pas encore.
        '<span class="lien" onclick="openPdfOverlay(''InvoicePdf.ashx?g='
            + CONVERT(varchar(100), v.[DocumentGUID]) + ''',''Facture '
            + ISNULL(v.[DocumentNumber], '') + ''');" >'
            + ISNULL(v.[DocumentNumber], '') + '</span>'   AS [DocumentNumber],

        v.[PartyId],

        -- Bouton "Post" pour comptabilisation
        '<span class="lien" onclick="postcustomerinvoice('''
            + v.[DocumentNumber] + ''','''
            + CONVERT(varchar(100), v.[Id]) + ''','''
            + CONVERT(varchar(100), v.[StatusId]) + '''</span>' AS [Post],

        v.[Created],
        v.[PartyGUID],
        v.[PdfContentType],
        v.[StatusOld]                                      AS [Statusold],
        v.[ComptabilisationStatus],
        v.[StatusComptable]                                AS [Status],
        v.[DocumentDate],
        v.[DueDate],

        -- Médias capturés par l'app mobile (60SecAI) : photos de chantier et
        -- géolocalisation du lieu d'intervention. Servent à afficher les
        -- indicateurs (badge photo / épingle) dans la grille des factures.
        -- PhotoCount = 0 et Latitude/Longitude NULL quand rien n'a été capturé.
        (SELECT COUNT(*)
           FROM dbo.T063DocumentPhoto ph
          WHERE ph.[DocumentId] = v.[Id])                  AS [PhotoCount],
        d.[Latitude],
        d.[Longitude],
        d.[GeoCapturedAt]
    FROM [dbo].[vwCustomersInvoices] v
    LEFT JOIN dbo.T060Document d ON d.[Id] = v.[Id]
    WHERE v.[CompanyGUID] = @CompanyGUID
      -- T365 : nom du client OU numéro de facture ; plusieurs numéros séparés par
      -- , ; ou espace (ex. « FCD-0012, FCD-0018 ») donnent exactement ces factures.
      AND (ISNULL(@Search, '') = ''
           OR COALESCE(v.[NameRaw], '') LIKE '%' + @Search + '%'
           OR COALESCE(v.[DocumentNumber], '') LIKE '%' + @Search + '%'
           OR EXISTS (SELECT 1
                      FROM STRING_SPLIT(REPLACE(REPLACE(@Search, ';', ','), ' ', ','), ',') s
                      WHERE LTRIM(RTRIM(s.value)) <> ''
                        AND v.[DocumentNumber] = LTRIM(RTRIM(s.value))))
      -- Filtres a selection multiple de la grille (vide = pas de filtre)
      AND (@Etats IS NULL OR LTRIM(RTRIM(@Etats)) = ''
           OR v.[StatusComptable] IN (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@Etats, ',')))
      AND (@StatutsPaiement IS NULL OR LTRIM(RTRIM(@StatutsPaiement)) = ''
           OR v.[StatutPaiement] IN (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@StatutsPaiement, ',')))
    -- Ordre par defaut de la grille : de la plus recente a la plus vieille.
    -- L'Id departage les factures de meme date (les plus recemment saisies
    -- d'abord) et rend l'ordre deterministe.
    -- Un brouillon n'a pas encore de date de facture : on retombe sur sa date de
    -- creation pour qu'il se classe quand meme au bon endroit (et non en fin de liste).
    ORDER BY COALESCE(v.[DocumentDate], d.[Created]) DESC, v.[Id] DESC;

END;
GO
