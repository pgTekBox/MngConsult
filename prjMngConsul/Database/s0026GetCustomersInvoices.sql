-- ============================================================================
-- Procédure : s0026GetCustomersInvoices
-- Description :
--   Consomme la vue vwCustomersInvoices et reformate les colonnes avec
--   le HTML/JS attendu par les écrans existants.
--
--   MODIF : le numéro de facture (DocumentNumber) est TOUJOURS rendu comme
--   un lien cliquable (openPdfOverlay) pour visualiser le PDF. Le PDF est
--   généré à la demande côté serveur (clsImage.LoadPDFInvoice) s'il n'existe
--   pas encore, donc plus besoin de conditionner le lien à PDFContentType.
-- ============================================================================
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE [dbo].[s0026GetCustomersInvoices]
    @CompanyGUID uniqueidentifier,@Search varchar(200)
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
    WHERE v.[CompanyGUID] = @CompanyGUID and coalesce(nameRaw,'') like '%' + @Search +  '%';

END;
GO
