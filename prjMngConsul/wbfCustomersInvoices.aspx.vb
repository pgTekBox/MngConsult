Imports System.Data.SqlClient
Imports System.Drawing
Imports Telerik.Web.UI
Imports Telerik.Web.UI.OrgChartStyles
Imports Telerik.Web.UI.PageLayout

Public Class wbfCustomersInvoices
    Inherits clsData

    Public CustomerInvoiceId As Integer

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ApplyLocalization()

        If Not IsPostBack Then
            rlvClientsFactures.Rebind()
        End If
    End Sub

    ''' <summary>Applique les libellés localisés (fr/en/es) aux contrôles serveur de la page.</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
        btnAddCustomerInvoice.Text = L("addInvoice")
        btnImportSquare.Text = L("importSquare")
        btnImportSquare.ToolTip = L("importSquareTip")
        tbSearch.Attributes("placeholder") = L("searchPh")
        rwInvoice.Title = L("winInvoiceTitle")
        rwEncaissement.Title = L("winCashInTitle")
        rwSquarePay.Title = L("winSquare")
        SetLiteral(Me, "litDlgTitle", L("dlgEmailTitle"))
        SetLiteral(Me, "litDlgQuestion", L("dlgEmailQuestion"))
        SetLiteral(Me, "litDlgCancel", L("dlgCancel"))
        SetLiteral(Me, "litDlgWithout", L("dlgWithout"))
        SetLiteral(Me, "litDlgWithoutSub", L("dlgWithoutSub"))
        SetLiteral(Me, "litDlgWith", L("dlgWith"))
        SetLiteral(Me, "litDlgWithSub", L("dlgWithSub"))
        SetLiteral(Me, "litDlgLink", L("dlgLink"))
        SetLiteral(Me, "litDlgLinkSub", L("dlgLinkSub"))
        SetLiteral(Me, "litDlgPaidNote", L("dlgPaidNote"))
        SetLiteral(Me, "litMediaOptTitle", L("mediaOptTitle"))
        SetLiteral(Me, "litInclGeo", L("inclGeo"))
        ' Titre/sous-titre de la visionneuse : posés par LoadInvoicePhotos (qui
        ' s'exécute après Page_Load), pas ici.
        SetLiteral(Me, "litPhotoClose", L("dlgCancel"))
    End Sub

    ''' <summary>Libellés des en-têtes de colonnes / message vide (dans les templates du RadListView).</summary>
    Private Sub rlvClientsFactures_PreRender(sender As Object, e As EventArgs) Handles rlvClientsFactures.PreRender
        SetLiteral(rlvClientsFactures, "litColNum", L("colNum"))
        SetLiteral(rlvClientsFactures, "litColDate", L("colDate"))
        SetLiteral(rlvClientsFactures, "litColCustomer", L("colCustomer"))
        SetLiteral(rlvClientsFactures, "litColStatutPaiement", L("colStatutPaiement"))
        SetLiteral(rlvClientsFactures, "litColResteAPayer", L("colResteAPayer"))
        SetLiteral(rlvClientsFactures, "litColDejaRecu", L("colDejaRecu"))
        SetLiteral(rlvClientsFactures, "litColTotal", L("colTotal"))
        SetLiteral(rlvClientsFactures, "litColEtat", L("colEtat"))
        SetLiteral(rlvClientsFactures, "litColAction", L("colAction"))
        SetLiteral(rlvClientsFactures, "litEmpty", L("empty"))
    End Sub

    Private Shared Sub SetLiteral(root As Control, id As String, text As String)
        Dim lit = TryCast(FindDeep(root, id), Literal)
        If lit IsNot Nothing Then lit.Text = text
    End Sub

    Private Shared Function FindDeep(root As Control, id As String) As Control
        If root Is Nothing Then Return Nothing
        Dim direct As Control = root.FindControl(id)
        If direct IsNot Nothing Then Return direct
        For Each ch As Control In root.Controls
            Dim r As Control = FindDeep(ch, id)
            If r IsNot Nothing Then Return r
        Next
        Return Nothing
    End Function

    ''' <summary>Traductions (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Factures clients — 60Sec-AI", "Customer invoices — 60Sec-AI", "Facturas de clientes — 60Sec-AI")
            Case "pageTitleShort" : Return Choose3(lang, "Factures clients", "Customer invoices", "Facturas de clientes")
            Case "addInvoice" : Return Choose3(lang, "Ajouter une facture", "Add invoice", "Agregar factura")
            Case "importSquare" : Return Choose3(lang, "Importer depuis Square", "Import from Square", "Importar desde Square")
            Case "importSquareTip" : Return Choose3(lang, "Rapatrier les factures et paiements Square comme factures clients", "Bring back Square invoices and payments as customer invoices", "Traer facturas y pagos de Square como facturas de clientes")
            Case "searchPh" : Return Choose3(lang, "Rechercher (nom, courriel, téléphone…)", "Search (name, email, phone…)", "Buscar (nombre, correo, teléfono…)")
            Case "colNum" : Return Choose3(lang, "#", "#", "#")
            Case "colDate" : Return Choose3(lang, "Date", "Date", "Fecha")
            Case "colCustomer" : Return Choose3(lang, "Client", "Customer", "Cliente")
            Case "colStatutPaiement" : Return Choose3(lang, "Statut paiement", "Payment status", "Estado de pago")
            Case "colResteAPayer" : Return Choose3(lang, "Reste à payer", "Balance due", "Saldo pendiente")
            Case "colDejaRecu" : Return Choose3(lang, "Déjà reçu", "Received", "Recibido")
            Case "colTotal" : Return Choose3(lang, "Total", "Total", "Total")
            Case "colEtat" : Return Choose3(lang, "État", "Status", "Estado")
            Case "colAction" : Return Choose3(lang, "Action", "Action", "Acción")
            Case "tipCashIn" : Return Choose3(lang, "Encaissement", "Cash receipt", "Cobro")
            Case "tipInvoiceSend" : Return Choose3(lang, "Envoyer la facture / Encaisser", "Send invoice / Collect", "Enviar factura / Cobrar")
            Case "tipPost" : Return Choose3(lang, "Comptabiliser la facture", "Post the invoice", "Contabilizar la factura")
            Case "confirmPost" : Return Choose3(lang,
                "Comptabiliser ce brouillon ? Le numéro officiel, la date de facture et l'échéance seront attribués, et la facture ne pourra plus être modifiée.",
                "Post this draft? The official number, invoice date and due date will be assigned, and the invoice can no longer be edited.",
                "¿Contabilizar este borrador? Se asignarán el número oficial, la fecha de factura y el vencimiento, y la factura ya no podrá modificarse.")
            Case "msgPosted" : Return Choose3(lang, "Facture comptabilisée.", "Invoice posted.", "Factura contabilizada.")
            Case "msgPostFailed" : Return Choose3(lang, "Comptabilisation impossible.", "Posting failed.", "No se pudo contabilizar.")
            Case "tipEdit" : Return Choose3(lang, "Modifier", "Edit", "Editar")
            Case "tipDelete" : Return Choose3(lang, "Supprimer", "Delete", "Eliminar")
            Case "empty" : Return Choose3(lang, "Aucune facture trouvée.", "No invoice found.", "No se encontró ninguna factura.")
            Case "winInvoiceTitle" : Return Choose3(lang, "Ajouter / Modifier une facture", "Add / Edit invoice", "Agregar / Editar factura")
            Case "winCashInTitle" : Return Choose3(lang, "Ajouter / Modifier un encaissement", "Add / Edit cash receipt", "Agregar / Editar cobro")
            Case "winEditInvoice" : Return Choose3(lang, "Modifier une facture", "Edit invoice", "Editar factura")
            Case "winAddInvoice" : Return Choose3(lang, "Ajouter une facture", "Add invoice", "Agregar factura")
            Case "winEditCashIn" : Return Choose3(lang, "Modifier un encaissement", "Edit cash receipt", "Editar cobro")
            Case "winAddCashIn" : Return Choose3(lang, "Ajouter un encaissement", "Add cash receipt", "Agregar cobro")
            Case "winSquare" : Return Choose3(lang, "Encaisser (Square)", "Collect (Square)", "Cobrar (Square)")
            Case "dlgEmailTitle" : Return Choose3(lang, "Envoyer la facture / Encaisser", "Send invoice / Collect", "Enviar factura / Cobrar")
            Case "dlgEmailQuestion" : Return Choose3(lang, "Que voulez-vous faire&nbsp;?", "What do you want to do?", "¿Qué desea hacer?")
            Case "dlgCancel" : Return Choose3(lang, "Annuler", "Cancel", "Cancelar")
            Case "dlgWithout" : Return Choose3(lang, "Envoyer la facture par courriel", "Send the invoice by email", "Enviar la factura por correo")
            Case "dlgWithoutSub" : Return Choose3(lang, "PDF en pièce jointe, sans lien de paiement.", "PDF attached, no payment link.", "PDF adjunto, sin enlace de pago.")
            Case "dlgWith" : Return Choose3(lang, "Envoyer par courriel avec lien de paiement", "Send by email with payment link", "Enviar por correo con enlace de pago")
            Case "dlgWithSub" : Return Choose3(lang, "PDF en pièce jointe + bouton « Payer maintenant » (Square).", "PDF attached + « Pay now » button (Square).", "PDF adjunto + botón « Pagar ahora » (Square).")
            Case "dlgLink" : Return Choose3(lang, "Obtenir le lien de paiement seulement", "Get the payment link only", "Obtener solo el enlace de pago")
            Case "dlgLinkSub" : Return Choose3(lang, "Génère le lien Square à copier (texto, téléphone, en personne). Aucun courriel envoyé.", "Generates the Square link to copy (text, phone, in person). No email sent.", "Genera el enlace Square para copiar (SMS, teléfono, en persona). No se envía correo.")
            Case "dlgPaidNote" : Return Choose3(lang, "Facture déjà payée : les options de paiement ne sont pas offertes.", "Invoice already paid: payment options are not available.", "Factura ya pagada: las opciones de pago no están disponibles.")
            Case "msgNotFound" : Return Choose3(lang, "Facture introuvable.", "Invoice not found.", "Factura no encontrada.")
            Case "msgNoEmail" : Return Choose3(lang, "Aucun courriel de facturation pour ce client.", "No billing email for this customer.", "No hay correo de facturación para este cliente.")
            Case "msgPdfFail" : Return Choose3(lang, "Impossible de générer le PDF de la facture.", "Unable to generate the invoice PDF.", "No se pudo generar el PDF de la factura.")
            Case "msgSent" : Return Choose3(lang, "Facture {0} envoyée à {1}.", "Invoice {0} sent to {1}.", "Factura {0} enviada a {1}.")
            Case "noteAlreadyPaid" : Return Choose3(lang, " (lien Square non ajouté : facture déjà payée)", " (Square link not added: invoice already paid)", " (enlace Square no agregado: factura ya pagada)")
            Case "noteNotConnected" : Return Choose3(lang, " (lien Square non ajouté : compte Square non connecté)", " (Square link not added: Square account not connected)", " (enlace Square no agregado: cuenta Square no conectada)")
            Case "noteNotGenerated" : Return Choose3(lang, " (lien Square non généré)", " (Square link not generated)", " (enlace Square no generado)")
            Case "noteError" : Return Choose3(lang, " (lien Square non ajouté : ", " (Square link not added: ", " (enlace Square no agregado: ")
            Case "msgImportDone" : Return Choose3(lang, "{0} facture(s) et {1} paiement(s) traités depuis Square.", "{0} invoice(s) and {1} payment(s) processed from Square.", "{0} factura(s) y {1} pago(s) procesados desde Square.")
            Case "msgImportError" : Return Choose3(lang, "Erreur lors de l'import Square : ", "Error during Square import: ", "Error durante la importación de Square: ")
            Case "msgBoxTitle" : Return Choose3(lang, "Information", "Information", "Información")
            Case "mediaOptTitle" : Return Choose3(lang, "À inclure dans le courriel", "Include in the email", "Incluir en el correo")
            Case "inclPhotos" : Return Choose3(lang, "Joindre les {0} photo(s) prises sur place", "Attach the {0} photo(s) taken on site", "Adjuntar las {0} foto(s) tomadas en el lugar")
            Case "inclGeo" : Return Choose3(lang, "Inclure le lien vers le lieu d'intervention", "Include the link to the job location", "Incluir el enlace al lugar de intervención")
            Case "notePhotos" : Return Choose3(lang, " ({0} photo(s) jointe(s), {1})", " ({0} photo(s) attached, {1})", " ({0} foto(s) adjuntada(s), {1})")
            Case "noteGeo" : Return Choose3(lang, " (lieu d'intervention inclus)", " (job location included)", " (lugar de intervención incluido)")
            Case "tipPhotos" : Return Choose3(lang, "{0} photo(s) prise(s) sur place — cliquer pour voir", "{0} photo(s) taken on site — click to view", "{0} foto(s) tomadas en el lugar — clic para ver")
            Case "tipGeo" : Return Choose3(lang, "Lieu d'intervention — ouvrir la carte", "Job location — open the map", "Lugar de intervención — abrir el mapa")
            Case "photoTitle" : Return Choose3(lang, "Photos — facture {0}", "Photos — invoice {0}", "Fotos — factura {0}")
            Case "photoSubtitle" : Return Choose3(lang, "{0} photo(s)", "{0} photo(s)", "{0} foto(s)")
            Case "photoNone" : Return Choose3(lang, "Aucune photo pour cette facture.", "No photo for this invoice.", "Ninguna foto para esta factura.")
            Case "photoGeoLabel" : Return Choose3(lang, "Lieu d'intervention", "Job location", "Lugar de intervención")
            Case "photoGeoAt" : Return Choose3(lang, "capté le {0}", "captured on {0}", "capturado el {0}")
            Case "photoGeoLink" : Return Choose3(lang, "Ouvrir dans Google Maps", "Open in Google Maps", "Abrir en Google Maps")
            Case Else : Return ""
        End Select
    End Function

    Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function
    Private Sub rlvClientsFactures_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvClientsFactures.NeedDataSource
        Dim dt As DataTable = GetData()
        rlvClientsFactures.DataSource = dt
    End Sub




    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()
        Dim sSearch As String = tbSearch.Text


        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", sSearch))
        Dim ds As DataSet = ExecuteSQLds("s0026GetCustomersInvoices", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    ''' <summary>Le bouton "Encaisser" est visible tant que la facture n'est pas entièrement payée.</summary>
    Public Function CanCollect(statutPaiement As Object) As Boolean
        If statutPaiement Is Nothing OrElse IsDBNull(statutPaiement) Then Return True
        Return statutPaiement.ToString().Trim().ToUpperInvariant() <> "PAYEE"
    End Function

    ' =====================================================================
    ' Visibilité des actions de la grille
    '   Brouillon         → seul « Comptabiliser » est offert.
    '   Facture impayée   → encaissement et envoi.
    '   Facture payée     → ni encaissement ni envoi (plus rien à réclamer).
    ' =====================================================================

    ''' <summary>
    ''' Vrai pour un brouillon, c'est-à-dire un document explicitement marqué
    ''' NON_COMPTABILISE (ce qu'écrit s0040SaveInvoiceItems à la création).
    ''' Le statut vide ou NULL, lui, désigne des factures anciennes jamais
    ''' estampillées (19 en base au 2026-09-03, avec de vrais numéros) : elles
    ''' ne sont PAS des brouillons et gardent leurs boutons habituels.
    ''' </summary>
    Public Function IsDraft(item As Object) As Boolean
        Dim v As Object = DataBinder.Eval(item, "ComptabilisationStatus")
        If v Is Nothing OrElse IsDBNull(v) Then Return False
        Return v.ToString().Trim().ToUpperInvariant() = "NON_COMPTABILISE"
    End Function

    ''' <summary>Vrai si la facture est entièrement payée.</summary>
    Public Function IsPaid(item As Object) As Boolean
        Return Not CanCollect(DataBinder.Eval(item, "StatutPaiement"))
    End Function

    ''' <summary>« Comptabiliser » : uniquement sur un brouillon.</summary>
    Public Function ShowPost(item As Object) As Boolean
        Return IsDraft(item)
    End Function

    ''' <summary>« Encaisser » : facture comptabilisée et pas encore soldée.</summary>
    Public Function ShowCollect(item As Object) As Boolean
        Return (Not IsDraft(item)) AndAlso (Not IsPaid(item))
    End Function

    ''' <summary>« Envoyer la facture » : même règle que l'encaissement.</summary>
    Public Function ShowSend(item As Object) As Boolean
        Return (Not IsDraft(item)) AndAlso (Not IsPaid(item))
    End Function

    ''' <summary>Confirmation avant comptabilisation (geste irréversible).</summary>
    Public Function ConfirmPost() As String
        Return "return confirm(""" & L("confirmPost") & """);"
    End Function

    ''' <summary>Entier sûr pour un argument JavaScript (0 si NULL / non numérique) :
    ''' évite un « openInvoiceActions(5,,... ) » qui casserait tout le dialogue.</summary>
    Public Function FormatIntForJs(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return "0"
        Dim n As Integer
        If Integer.TryParse(value.ToString(), n) Then Return n.ToString(System.Globalization.CultureInfo.InvariantCulture)
        Return "0"
    End Function

    ''' <summary>Formate un montant pour l'URL (point décimal, InvariantCulture).</summary>
    Public Function FormatAmountForUrl(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return "0"
        Try
            Return Convert.ToDecimal(value).ToString("F2", System.Globalization.CultureInfo.InvariantCulture)
        Catch
            Return "0"
        End Try
    End Function


    ' =====================================================================
    ' MÉDIAS CAPTÉS PAR L'APP MOBILE (60SecAI) : photos de chantier + géoloc.
    ' Les données sont écrites par 60SecAI.Api (T063DocumentPhoto et
    ' T060Document.Latitude/Longitude) ; ici on ne fait que les consulter.
    ' =====================================================================

    ''' <summary>
    ''' Badges « photos » et « lieu » affichés sous le nom du client. Retourne ""
    ''' quand la facture n'a ni photo ni géolocalisation (cas le plus courant),
    ''' pour ne pas alourdir la grille d'un conteneur vide.
    ''' </summary>
    Public Function RenderMediaBadges(idObj As Object, photoCountObj As Object,
                                      latObj As Object, lngObj As Object) As String
        Dim id As Integer = 0
        If Not Integer.TryParse(FormatIntForJs(idObj), id) OrElse id <= 0 Then Return ""

        Dim count As Integer = 0
        If photoCountObj IsNot Nothing AndAlso Not IsDBNull(photoCountObj) Then
            Integer.TryParse(photoCountObj.ToString(), count)
        End If

        Dim lat As Double = 0, lng As Double = 0
        Dim hasGeo As Boolean = TryGetGeo(latObj, lngObj, lat, lng)

        If count <= 0 AndAlso Not hasGeo Then Return ""

        Dim sb As New System.Text.StringBuilder()
        sb.Append("<span class=""media-badges"">")

        If count > 0 Then
            sb.Append("<span class=""media-badge"" title=""")
            sb.Append(Server.HtmlEncode(String.Format(L("tipPhotos"), count)))
            sb.Append(""" onclick=""openPhotos(").Append(id).Append(");"">")
            sb.Append(SvgCamera()).Append(count.ToString(System.Globalization.CultureInfo.InvariantCulture))
            sb.Append("</span>")
        End If

        If hasGeo Then
            sb.Append("<span class=""media-badge"" title=""")
            sb.Append(Server.HtmlEncode(L("tipGeo")))
            sb.Append(""" onclick=""openMap(").Append(InvariantNum(lat)).Append(",").Append(InvariantNum(lng))
            sb.Append(");"">").Append(SvgPin()).Append("</span>")
        End If

        sb.Append("</span>")
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Extrait la géolocalisation d'une ligne. Latitude/Longitude sont des FLOAT :
    ''' on convertit depuis l'objet SQL plutôt que depuis sa chaîne, qui serait
    ''' formatée selon la culture courante (« 45,52 » en fr-CA) et ne se reparserait
    ''' pas en invariant.
    ''' </summary>
    Private Shared Function TryGetGeo(latObj As Object, lngObj As Object,
                                      ByRef lat As Double, ByRef lng As Double) As Boolean
        lat = 0 : lng = 0
        If latObj Is Nothing OrElse IsDBNull(latObj) OrElse
           lngObj Is Nothing OrElse IsDBNull(lngObj) Then Return False
        Try
            lat = Convert.ToDouble(latObj)
            lng = Convert.ToDouble(lngObj)
            Return True
        Catch
            Return False
        End Try
    End Function

    ''' <summary>La facture porte-t-elle une géolocalisation ? (liaison de la grille)</summary>
    Public Function HasGeo(latObj As Object, lngObj As Object) As Boolean
        Dim lat As Double, lng As Double
        Return TryGetGeo(latObj, lngObj, lat, lng)
    End Function

    ''' <summary>Nombre en culture invariante (point décimal) pour un argument JS.</summary>
    Private Shared Function InvariantNum(value As Double) As String
        Return value.ToString("0.######", System.Globalization.CultureInfo.InvariantCulture)
    End Function

    Private Shared Function SvgCamera() As String
        Return "<svg viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""2"" " &
               "stroke-linecap=""round"" stroke-linejoin=""round"">" &
               "<path d=""M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3Z""/>" &
               "<circle cx=""12"" cy=""13"" r=""3""/></svg>"
    End Function

    Private Shared Function SvgPin() As String
        Return "<svg viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""2"" " &
               "stroke-linecap=""round"" stroke-linejoin=""round"">" &
               "<path d=""M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z""/>" &
               "<circle cx=""12"" cy=""10"" r=""3""/></svg>"
    End Function

    ''' <summary>
    ''' Remplit la visionneuse avec les photos de la facture puis l'affiche.
    ''' La lecture est scopée à la compagnie de la session (s0727) : la grille
    ''' n'expose que le nombre de photos, jamais leurs identifiants.
    ''' </summary>
    Private Sub LoadInvoicePhotos(invoiceId As Integer)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@DocumentId", invoiceId))
        Dim ds As DataSet = ExecuteSQLds("s0727GetInvoicePhotos", p)

        ' Jeu 0 = en-tête du document ; vide = facture inexistante ou d'une autre compagnie.
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ShowSquareMessage(L("msgNotFound"))
            Return
        End If
        Dim head As DataRow = ds.Tables(0).Rows(0)
        Dim docNumber As String = If(IsDBNull(head("DocumentNumber")), invoiceId.ToString(),
                                     head("DocumentNumber").ToString())

        Dim photos As DataTable = If(ds.Tables.Count > 1, ds.Tables(1), Nothing)
        Dim nb As Integer = If(photos Is Nothing, 0, photos.Rows.Count)

        SetLiteral(Me, "litPhotoTitle", String.Format(L("photoTitle"), Server.HtmlEncode(docNumber)))
        SetLiteral(Me, "litPhotoSubtitle", String.Format(L("photoSubtitle"), nb))

        Dim sb As New System.Text.StringBuilder()

        ' Bloc géolocalisation (si l'app mobile l'a captée).
        If Not IsDBNull(head("Latitude")) AndAlso Not IsDBNull(head("Longitude")) Then
            Dim lat As Double = Convert.ToDouble(head("Latitude"))
            Dim lng As Double = Convert.ToDouble(head("Longitude"))
            Dim coords As String = InvariantNum(lat) & ", " & InvariantNum(lng)
            sb.Append("<div class=""photo-geo""><strong>").Append(Server.HtmlEncode(L("photoGeoLabel")))
            sb.Append("</strong> : ").Append(Server.HtmlEncode(coords))
            If Not IsDBNull(head("GeoCapturedAt")) Then
                sb.Append(" (").Append(Server.HtmlEncode(String.Format(L("photoGeoAt"),
                    CDate(head("GeoCapturedAt")).ToString("yyyy-MM-dd HH:mm")))).Append(")")
            End If
            sb.Append(" — <a href=""https://www.google.com/maps?q=").Append(InvariantNum(lat)).Append(",")
            sb.Append(InvariantNum(lng)).Append(""" target=""_blank"" rel=""noopener"">")
            sb.Append(Server.HtmlEncode(L("photoGeoLink"))).Append("</a></div>")
        End If

        If nb = 0 Then
            sb.Append("<div style=""color:#64748b;font-size:13px"">").Append(Server.HtmlEncode(L("photoNone"))).Append("</div>")
        Else
            sb.Append("<div class=""photo-grid"">")
            For Each r As DataRow In photos.Rows
                ' Le blob n'est jamais dans le DataSet : chaque vignette est servie
                ' par InvoicePhoto.ashx, lui aussi scopé à la compagnie de la session.
                Dim url As String = "InvoicePhoto.ashx?d=" & invoiceId.ToString(System.Globalization.CultureInfo.InvariantCulture) &
                                    "&p=" & Convert.ToInt32(r("Id")).ToString(System.Globalization.CultureInfo.InvariantCulture)
                sb.Append("<a class=""photo-item"" href=""").Append(url).Append(""" target=""_blank"" rel=""noopener"">")
                sb.Append("<img src=""").Append(url).Append(""" alt="""" loading=""lazy"" />")
                sb.Append("<span class=""photo-cap"">").Append(Server.HtmlEncode(PhotoCaption(r))).Append("</span></a>")
            Next
            sb.Append("</div>")
        End If

        SetLiteral(Me, "litPhotoBody", sb.ToString())
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "showPhotos", "showPhotos();", True)
    End Sub

    ''' <summary>Légende d'une vignette : date de prise (EXIF si connue) et poids.</summary>
    Private Shared Function PhotoCaption(r As DataRow) As String
        Dim parts As New List(Of String)
        If Not IsDBNull(r("Created")) Then
            parts.Add(CDate(r("Created")).ToString("yyyy-MM-dd HH:mm"))
        End If
        If Not IsDBNull(r("SizeBytes")) Then
            Dim ko As Double = Convert.ToDouble(r("SizeBytes")) / 1024.0
            If ko >= 1024 Then
                parts.Add((ko / 1024.0).ToString("N1") & " Mo")
            Else
                parts.Add(ko.ToString("N0") & " Ko")
            End If
        End If
        Return String.Join(" · ", parts)
    End Function

    Private Sub SaveInvoicePdfToDb(fileName As String, contentType As String, pdfBytes As Byte())
        'Dim cs As String = ConfigurationManager.ConnectionStrings("YourConnectionStringName").ConnectionString

        '        Using cn As New SqlConnection(cs)
        '            cn.Open()

        '            Dim sql As String =
        '    "MERGE dbo.CustomerInvoicePdf AS tgt
        'USING (SELECT @InvoiceId AS InvoiceId) AS src
        'ON tgt.InvoiceId = src.InvoiceId
        'WHEN MATCHED THEN
        '    UPDATE SET FileName=@FileName, ContentType=@ContentType, PdfData=@PdfData, CreatedOn=SYSUTCDATETIME()
        'WHEN NOT MATCHED THEN
        '    INSERT (InvoiceId, FileName, ContentType, PdfData)
        '    VALUES (@InvoiceId, @FileName, @ContentType, @PdfData);"

        '            Using cmd As New SqlCommand(sql, cn)
        '                cmd.Parameters.AddWithValue("@InvoiceId", invoiceId)
        '                cmd.Parameters.AddWithValue("@FileName", fileName)
        '                cmd.Parameters.AddWithValue("@ContentType", contentType)
        '                cmd.Parameters.Add("@PdfData", SqlDbType.VarBinary, -1).Value = pdfBytes
        '                cmd.ExecuteNonQuery()
        '            End Using
        '        End Using
    End Sub

    Private Sub RAP1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles RAP1.AjaxRequest
        Dim arg As String = If(e.Argument, "")
        If arg = "refreshgrid" Then
            rlvClientsFactures.Rebind()
        ElseIf arg.StartsWith("photos|") Then
            ' Format : photos|<invoiceId>
            Dim photoId As Integer = 0
            Integer.TryParse(arg.Split("|"c)(1), photoId)
            If photoId > 0 Then LoadInvoicePhotos(photoId)
            ' Le RadAjaxPanel re-rend tout son contenu : sans rebind, la grille
            ' repartirait du ViewState. On la relit, comme le fait l'envoi courriel.
            rlvClientsFactures.Rebind()
        ElseIf arg.StartsWith("sendmail|") Then
            ' Format : sendmail|<invoiceId>|<includeSquare>|<includePhotos>|<includeGeo> (0/1)
            Dim parts As String() = arg.Split("|"c)
            Dim invoiceId As Integer = 0
            Dim includeSquare As Boolean = False
            Dim includePhotos As Boolean = False
            Dim includeGeo As Boolean = False
            If parts.Length >= 3 Then
                Integer.TryParse(parts(1), invoiceId)
                includeSquare = (parts(2) = "1")
            End If
            If parts.Length >= 5 Then
                includePhotos = (parts(3) = "1")
                includeGeo = (parts(4) = "1")
            End If
            If invoiceId > 0 Then SendInvoiceByEmail(invoiceId, includeSquare, includePhotos, includeGeo)
            rlvClientsFactures.Rebind()
        End If
    End Sub



    Private Sub rlvClientsFactures_ItemDataBound(sender As Object, e As RadListViewItemEventArgs) Handles rlvClientsFactures.ItemDataBound
        If TypeOf e.Item Is Telerik.Web.UI.RadListViewDataItem Then


            Dim item As Telerik.Web.UI.RadListViewDataItem = CType(e.Item, Telerik.Web.UI.RadListViewDataItem)
            Dim data As DataRowView = CType(item.DataItem, DataRowView)



            If data("ComptabilisationStatus") = "COMPTABILISE" Then
                Dim btnDelete As Button = CType(item.FindControl("btnDelete"), Button)
                btnDelete.CssClass &= " btn-icon-lock-red readonly-click-block"

                btnDelete.CommandName = ""


            End If


        End If

    End Sub

    ''' <summary>
    ''' Gère les boutons CommandName de la grille (DownloadPdf, DeleteInvoice, etc.)
    ''' </summary>
    Private Sub rlvClientsFactures_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvClientsFactures.ItemCommand


        Select Case e.CommandName

            Case "CreatePdf"
                Dim invoiceId As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), invoiceId)
                If invoiceId > 0 Then
                    Dim oPdf As New clsGenerateInvoicePDF()
                    oPdf.GenerateAndDownloadPdf(invoiceId)
                    rlvClientsFactures.Rebind()
                End If

            Case "DeleteInvoice"
                Dim invoiceId As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), invoiceId)
                DeleteDocument(invoiceId)
                rlvClientsFactures.Rebind()

            Case "PostInvoice"
                Dim invoiceId As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), invoiceId)
                If invoiceId > 0 Then PostDocument(invoiceId)
                rlvClientsFactures.Rebind()
        End Select
    End Sub

    ''' <summary>
    ''' Envoie la facture (PDF en pièce jointe) au courriel de facturation du
    ''' client via le service de courriels (T400Mails + T402Attachments).
    ''' Reply-To = courriel vérifié de la compagnie. Le PDF est généré au besoin.
    ''' </summary>
    Private Sub SendInvoiceByEmail(invoiceId As Integer, includeSquare As Boolean,
                                   includePhotos As Boolean, includeGeo As Boolean)

        ' 1. Charger les données de la facture
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@InvoiceId", invoiceId))
        Dim ds As DataSet = ExecuteSQLds("s0696GetInvoiceForEmail", p)
        If ds Is Nothing OrElse ds.Tables(0).Rows.Count = 0 Then
            ShowSquareMessage(L("msgNotFound"))
            Return
        End If
        Dim r As DataRow = ds.Tables(0).Rows(0)

        Dim toEmail As String = If(IsDBNull(r("Email")), "", r("Email").ToString().Trim())
        If toEmail = "" Then
            ShowSquareMessage(L("msgNoEmail"))
            Return
        End If

        ' 2. S'assurer que le PDF existe (sinon le générer)
        If IsDBNull(r("PdfData")) Then
            Dim oGen As New clsGenerateInvoicePDF()
            oGen.GenerateAndDownloadPdf(invoiceId)
            ds = ExecuteSQLds("s0696GetInvoiceForEmail", p)
            r = ds.Tables(0).Rows(0)
        End If
        If IsDBNull(r("PdfData")) Then
            ShowSquareMessage(L("msgPdfFail"))
            Return
        End If

        Dim pdfBytes As Byte() = CType(r("PdfData"), Byte())
        Dim docNumber As String = If(IsDBNull(r("DocumentNumber")), invoiceId.ToString(), r("DocumentNumber").ToString())
        Dim companyName As String = If(IsDBNull(r("CompanyName")), "", r("CompanyName").ToString())
        Dim docGuid As String = If(IsDBNull(r("DocumentGUID")), "", r("DocumentGUID").ToString())
        Dim fileName As String = If(IsDBNull(r("PdfFileName")) OrElse r("PdfFileName").ToString() = "",
                                    "Facture_" & docNumber & ".pdf", r("PdfFileName").ToString())
        Dim companyGuid As Guid = CType(r("CompanyGUID"), Guid)
        Dim reste As Decimal = If(IsDBNull(r("ResteAPayer")), 0D, CDec(r("ResteAPayer")))

        ' 3b. Lien de paiement Square (optionnel, sur le solde restant)
        Dim squareLinkHtml As String = ""
        Dim squareNote As String = ""
        If includeSquare Then
            squareLinkHtml = BuildSquarePaymentLink(invoiceId, docNumber, companyName, toEmail, reste, companyGuid, squareNote)
        End If

        ' 3c. Médias captés par l'app mobile. Un seul appel sert les deux options :
        ' s0727 renvoie l'en-tête (géoloc) puis la liste des photos, scopé compagnie.
        Dim geoHtml As String = ""
        Dim photoRows As New List(Of DataRow)
        If includePhotos OrElse includeGeo Then
            Dim pm2 As New Collection
            pm2.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            pm2.Add(New SqlClient.SqlParameter("@DocumentId", invoiceId))
            Dim dsm2 As DataSet = ExecuteSQLds("s0727GetInvoicePhotos", pm2)
            If dsm2 IsNot Nothing AndAlso dsm2.Tables.Count > 0 AndAlso dsm2.Tables(0).Rows.Count > 0 Then
                If includeGeo Then
                    Dim h As DataRow = dsm2.Tables(0).Rows(0)
                    Dim glat As Double, glng As Double
                    If TryGetGeo(h("Latitude"), h("Longitude"), glat, glng) Then
                        ' Lien Google Maps public : le destinataire n'a pas de session ici.
                        Dim mapUrl As String = "https://www.google.com/maps?q=" &
                                               InvariantNum(glat) & "," & InvariantNum(glng)
                        geoHtml = "<p style=""margin-top:18px""><strong>Lieu d'intervention :</strong> " &
                                  "<a href=""" & mapUrl & """>" & Server.HtmlEncode(
                                      InvariantNum(glat) & ", " & InvariantNum(glng)) & "</a></p>"
                    End If
                End If
                If includePhotos AndAlso dsm2.Tables.Count > 1 Then
                    For Each pr As DataRow In dsm2.Tables(1).Rows
                        photoRows.Add(pr)
                    Next
                End If
            End If
        End If

        ' 4. Corps HTML (+ lien de visualisation en secours)
        Dim viewUrl As String = "https://60sec.ca/InvoicePdf.ashx?g=" & docGuid
        Dim subject As String = "Facture " & docNumber & If(companyName <> "", " — " & companyName, "")
        Dim body As New System.Text.StringBuilder()
        body.Append("<div style=""font-family:Arial,sans-serif;font-size:14px;color:#0f172a"">")
        body.Append("<p>Bonjour,</p>")
        body.Append("<p>Veuillez trouver ci-jointe la facture <strong>").Append(Server.HtmlEncode(docNumber)).Append("</strong>")
        If companyName <> "" Then body.Append(" de ").Append(Server.HtmlEncode(companyName))
        body.Append(".</p>")
        body.Append("<p><a href=""").Append(viewUrl).Append(""" style=""display:inline-block;padding:10px 18px;background:#2563eb;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:700"">Voir la facture (PDF)</a></p>")
        If squareLinkHtml <> "" Then body.Append(squareLinkHtml)
        If photoRows.Count > 0 Then
            body.Append("<p style=""margin-top:18px"">Vous trouverez également ")
            body.Append(photoRows.Count.ToString(System.Globalization.CultureInfo.InvariantCulture))
            body.Append(If(photoRows.Count = 1, " photo prise", " photos prises"))
            body.Append(" sur place en pièce jointe.</p>")
        End If
        If geoHtml <> "" Then body.Append(geoHtml)
        body.Append("<p>Merci de votre confiance.</p>")
        If companyName <> "" Then body.Append("<p>").Append(Server.HtmlEncode(companyName)).Append("</p>")
        body.Append("</div>")

        ' 5. Insérer le courriel sortant (BD MailService) -> MailId
        Dim pm As New Collection
        pm.Add(New SqlClient.SqlParameter("@To", toEmail))
        pm.Add(New SqlClient.SqlParameter("@Subject", subject))
        pm.Add(New SqlClient.SqlParameter("@HTMLBody", body.ToString()))
        ' Reply-To = courriel vérifié de la compagnie (règle centralisée, sinon NULL)
        CompanyMail.AddReplyToParam(pm, ConnectionString, companyGuid)
        Dim dsm As DataSet = ExecuteSQLdsMail("s0610InsertOutboundMail", pm)
        Dim mailId As Integer = Convert.ToInt32(dsm.Tables(0).Rows(0)(0))

        ' 6. Joindre le PDF (T402Attachments + drapeau HaveAttachment)
        Dim pa As New Collection
        pa.Add(New SqlClient.SqlParameter("@FileName", fileName))
        pa.Add(New SqlClient.SqlParameter("@content", pdfBytes))
        pa.Add(New SqlClient.SqlParameter("@MailId", mailId))
        pa.Add(New SqlClient.SqlParameter("@ContentType", "application/pdf"))
        pa.Add(New SqlClient.SqlParameter("@ContentId", ""))
        ExecuteSQLMail("s1579InsertAttachemnt_A", pa)

        ' 7. Joindre les photos demandées. Le blob n'était pas dans la liste (s0727
        ' ne renvoie que les métadonnées) : on le relit photo par photo via s0728,
        ' lui aussi scopé compagnie. Ce sont des originaux d'appareil photo, donc
        ' quelques Mo chacun — d'où le total rappelé dans la confirmation.
        Dim photoNote As String = ""
        If photoRows.Count > 0 Then
            Dim attached As Integer = 0
            Dim totalBytes As Long = 0
            Dim optimizer As New clsReceiptImageOptimizer()
            For Each pr As DataRow In photoRows
                Dim pc As New Collection
                pc.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
                pc.Add(New SqlClient.SqlParameter("@DocumentId", invoiceId))
                pc.Add(New SqlClient.SqlParameter("@PhotoId", Convert.ToInt32(pr("Id"))))
                Dim dsp As DataSet = ExecuteSQLds("s0728GetInvoicePhotoContent", pc)
                If dsp Is Nothing OrElse dsp.Tables.Count = 0 OrElse dsp.Tables(0).Rows.Count = 0 Then Continue For
                Dim prow As DataRow = dsp.Tables(0).Rows(0)
                If IsDBNull(prow("ImageSource")) Then Continue For

                Dim bytes As Byte() = CType(prow("ImageSource"), Byte())
                Dim pName As String = If(IsDBNull(prow("FileName")) OrElse prow("FileName").ToString() = "",
                                         "photo_" & Convert.ToInt32(pr("Id")).ToString() & ".jpg",
                                         prow("FileName").ToString())
                Dim pType As String = If(IsDBNull(prow("ContentType")) OrElse prow("ContentType").ToString() = "",
                                         "image/jpeg", prow("ContentType").ToString())

                ' Redimensionnement pour le courriel : les originaux font 2-3 Mo pièce
                ' et plusieurs photos dépasseraient vite les limites des serveurs de
                ' courriel. L'original reste intact en base ; seule la copie jointe
                ' est réduite. OptimizeForEmail retourne le tableau d'entrée lui-même
                ' quand elle n'a rien pu (ou rien eu) à réduire : la comparaison de
                ' référence dit s'il faut annoncer du JPEG.
                Dim sendBytes As Byte() = optimizer.OptimizeForEmail(bytes)
                If Not Object.ReferenceEquals(sendBytes, bytes) Then
                    pType = "image/jpeg"
                    pName = System.IO.Path.ChangeExtension(pName, ".jpg")
                End If

                Dim pp As New Collection
                pp.Add(New SqlClient.SqlParameter("@FileName", pName))
                pp.Add(New SqlClient.SqlParameter("@content", sendBytes))
                pp.Add(New SqlClient.SqlParameter("@MailId", mailId))
                pp.Add(New SqlClient.SqlParameter("@ContentType", pType))
                pp.Add(New SqlClient.SqlParameter("@ContentId", ""))
                ExecuteSQLMail("s1579InsertAttachemnt_A", pp)

                attached += 1
                totalBytes += sendBytes.LongLength
            Next
            If attached > 0 Then
                photoNote = String.Format(L("notePhotos"), attached, FormatBytes(totalBytes))
            End If
        End If

        Dim geoNote As String = If(geoHtml <> "", L("noteGeo"), "")

        ShowSquareMessage(String.Format(L("msgSent"), docNumber, toEmail) &
                          squareNote & photoNote & geoNote)
    End Sub

    ''' <summary>Taille lisible (Ko / Mo) pour la confirmation d'envoi.</summary>
    Private Shared Function FormatBytes(bytes As Long) As String
        Dim ko As Double = bytes / 1024.0
        If ko >= 1024 Then Return (ko / 1024.0).ToString("N1") & " Mo"
        Return ko.ToString("N0") & " Ko"
    End Function

    ''' <summary>
    ''' Génère un lien de paiement Square (page hébergée) sur le solde restant de la
    ''' facture et retourne le bloc HTML (bouton « Payer ») à insérer dans le courriel.
    ''' Estampille la facture avec le SquareOrderId (réconciliation webhook, s0688).
    ''' Après paiement le client est renvoyé sur la page « merci » brandée, comme pour
    ''' le lien généré depuis la fenêtre « Encaisser » (clsSquare.PaymentRedirectUrl).
    ''' Retourne "" si impossible (Square non connecté, solde nul, erreur) et remplit
    ''' <paramref name="note"/> avec la raison (affichée dans la confirmation).
    ''' </summary>
    Private Function BuildSquarePaymentLink(invoiceId As Integer, docNumber As String,
                                            companyName As String, buyerEmail As String,
                                            reste As Decimal, companyGuid As Guid,
                                            ByRef note As String) As String
        Try
            If reste <= 0D Then
                note = L("noteAlreadyPaid")
                Return ""
            End If

            Dim token As String = ""
            Try
                token = GetValidSquareAccessToken()
            Catch
            End Try
            If String.IsNullOrEmpty(token) Then
                note = L("noteNotConnected")
                Return ""
            End If

            Dim locationId As String = clsSquare.GetMainLocationId(token)
            Dim cents As Long = CLng(Math.Round(reste * 100D))
            Dim name As String = "Facture #" & docNumber
            Dim redirectUrl As String = clsSquare.PaymentRedirectUrl(CurrentLang, reste, companyName, companyGuid)
            Dim linkRes As clsSquare.SquarePaymentLinkResult =
                clsSquare.CreatePaymentLink(token, locationId, cents, name, "Facture client #" & docNumber,
                                            companyName, buyerEmail, UserEmail, redirectUrl)

            If linkRes Is Nothing OrElse String.IsNullOrEmpty(linkRes.Url) Then
                note = L("noteNotGenerated")
                Return ""
            End If

            ' Réconciliation : estampiller la facture avec le SquareOrderId.
            If Not String.IsNullOrEmpty(linkRes.OrderId) Then
                Dim ps As New Collection
                ps.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
                ps.Add(New SqlClient.SqlParameter("@DocumentId", invoiceId))
                ps.Add(New SqlClient.SqlParameter("@SquareOrderId", linkRes.OrderId))
                ExecuteSQL("s0688LinkDocumentToSquareOrder", ps)
            End If

            Return "<p><a href=""" & linkRes.Url & """ style=""display:inline-block;padding:10px 18px;" &
                   "background:#16a34a;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:700"">" &
                   "Payer maintenant (" & reste.ToString("N2") & " $)</a></p>"
        Catch ex As Exception
            note = L("noteError") & ex.Message & ")"
            Return ""
        End Try
    End Function

    ''' <summary>
    ''' Comptabilise un brouillon depuis la grille : sp_ComptabiliserDocument
    ''' attribue le numéro officiel, la date de facture (aujourd'hui) et
    ''' l'échéance (date + délai du client), puis écrit au journal. Toute erreur
    ''' remontée par la procédure est affichée telle quelle : elle explique ce
    ''' qui manque (aucune ligne, total à zéro, période fermée…).
    ''' </summary>
    Sub PostDocument(invoiceId As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@DocumentId", invoiceId))
            ExecuteSQL("sp_ComptabiliserDocument", p)
            ShowSquareMessage(L("msgPosted"))
        Catch ex As SqlClient.SqlException
            ShowSquareMessage(ex.Message)
        Catch ex As Exception
            ShowSquareMessage(L("msgPostFailed"))
            System.Diagnostics.Debug.WriteLine("PostDocument: " & ex.Message)
        End Try
    End Sub

    Sub DeleteDocument(invoiceId As Integer)

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@DocumentId", invoiceId))
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s317DeleteDocument ", p)
        If ds.Tables(0).Rows(0)("RetCode") = 2 Then


        End If
    End Sub



    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvClientsFactures.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvClientsFactures.Rebind()
    End Sub

    ' ── Import des factures + paiements Square (sens entrant, a la demande) ──

    Protected Sub btnImportSquare_Click(sender As Object, e As EventArgs) Handles btnImportSquare.Click
        Try
            Dim token As String = GetValidSquareAccessToken()
            Dim locationId As String = GetCompanySquareLocationId()

            Dim invCount As Integer = 0, payCount As Integer = 0

            ' 1. Factures Square -> Factures Clients (entete + lignes via l'Order)
            Dim invoices As List(Of clsSquare.SquareInvoiceRemote) = clsSquare.ListInvoices(token, locationId)
            If invoices IsNot Nothing Then
                For Each inv As clsSquare.SquareInvoiceRemote In invoices
                    If String.IsNullOrEmpty(inv.InvoiceId) Then Continue For
                    EnsureClient(inv)
                    Dim order As clsSquare.SquareOrderRemote = Nothing
                    If Not String.IsNullOrEmpty(inv.OrderId) Then order = clsSquare.RetrieveOrder(token, inv.OrderId)
                    UpsertSquareInvoice(inv, order, Nothing, Nothing)
                    invCount += 1
                Next
            End If

            ' 2. Paiements Square -> rapprochement (Paye) ou creation facture payee (vente TPV)
            Dim payments As List(Of clsSquare.SquarePaymentRemote) = clsSquare.ListPayments(token, locationId)
            If payments IsNot Nothing Then
                For Each pay As clsSquare.SquarePaymentRemote In payments
                    If String.IsNullOrEmpty(pay.PaymentId) Then Continue For
                    Dim needsInvoice As Boolean = ApplyPayment(pay)
                    If needsInvoice Then
                        Dim order As clsSquare.SquareOrderRemote = Nothing
                        If Not String.IsNullOrEmpty(pay.OrderId) Then order = clsSquare.RetrieveOrder(token, pay.OrderId)
                        If order Is Nothing Then order = SyntheticOrder(pay)
                        Dim inv As New clsSquare.SquareInvoiceRemote()
                        inv.OrderId = pay.OrderId
                        inv.CustomerId = pay.CustomerId
                        inv.Status = pay.Status
                        UpsertSquareInvoice(inv, order, pay.PaymentId, pay.Status)
                    End If
                    payCount += 1
                Next
            End If

            ShowSquareMessage(String.Format(L("msgImportDone"), invCount, payCount))
            rlvClientsFactures.Rebind()
        Catch ex As Exception
            ShowSquareMessage(L("msgImportError") & ex.Message)
        End Try
    End Sub

    ''' <summary>Garantit le client local (SquareCustomerId -> T050Party) via le snapshot destinataire.</summary>
    Private Sub EnsureClient(inv As clsSquare.SquareInvoiceRemote)
        If inv Is Nothing OrElse String.IsNullOrEmpty(inv.CustomerId) Then Return
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@SquareCustomerId", inv.CustomerId))
        p.Add(New SqlClient.SqlParameter("@SquareCustomerVersion", DBNull.Value))
        p.Add(New SqlClient.SqlParameter("@ReferenceId", DBNull.Value))
        p.Add(New SqlClient.SqlParameter("@Name", NzP(inv.RecipientName)))
        p.Add(New SqlClient.SqlParameter("@Email", NzP(inv.RecipientEmail)))
        p.Add(New SqlClient.SqlParameter("@Phone", NzP(inv.RecipientPhone)))
        p.Add(New SqlClient.SqlParameter("@Address1", NzP(inv.RecipientAddress1)))
        p.Add(New SqlClient.SqlParameter("@Address2", NzP(inv.RecipientAddress2)))
        p.Add(New SqlClient.SqlParameter("@City", NzP(inv.RecipientCity)))
        p.Add(New SqlClient.SqlParameter("@PostalCode", NzP(inv.RecipientPostalCode)))
        ExecuteSQLds("s0666UpsertClientFromSquare", p)
    End Sub

    ''' <summary>Rapproche un paiement (s0672) ; retourne True si aucune facture ne correspond.</summary>
    Private Function ApplyPayment(pay As clsSquare.SquarePaymentRemote) As Boolean
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@SquareOrderId", NzP(pay.OrderId)))
        p.Add(New SqlClient.SqlParameter("@SquarePaymentId", pay.PaymentId))
        p.Add(New SqlClient.SqlParameter("@SquareStatus", NzP(pay.Status)))
        p.Add(New SqlClient.SqlParameter("@AmountCents", If(pay.AmountCents <> 0, CObj(pay.AmountCents), DBNull.Value)))
        Dim ds As DataSet = ExecuteSQLds("s0672ApplySquarePayment", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 _
           AndAlso ds.Tables(0).Columns.Contains("NeedsInvoice") Then
            Return CBool(ds.Tables(0).Rows(0)("NeedsInvoice"))
        End If
        Return False
    End Function

    ''' <summary>Appelle s0671UpsertInvoiceFromSquare (entete + lignes TVP).</summary>
    Private Sub UpsertSquareInvoice(inv As clsSquare.SquareInvoiceRemote,
                                    order As clsSquare.SquareOrderRemote,
                                    paymentId As String,
                                    paymentStatus As String)

        Dim status As String = If(Not String.IsNullOrEmpty(paymentStatus), paymentStatus,
                                  If(inv IsNot Nothing, inv.Status, Nothing))
        Dim orderId As String = If(order IsNot Nothing, order.OrderId,
                                   If(inv IsNot Nothing, inv.OrderId, Nothing))
        Dim customerId As String = If(inv IsNot Nothing AndAlso Not String.IsNullOrEmpty(inv.CustomerId),
                                      inv.CustomerId, If(order IsNot Nothing, order.CustomerId, Nothing))

        Using conn As New SqlClient.SqlConnection(ConnectionString)
            Using cmd As New SqlClient.SqlCommand("s0671UpsertInvoiceFromSquare", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@SquareInvoiceId", NzP(If(inv IsNot Nothing, inv.InvoiceId, Nothing)))
                cmd.Parameters.AddWithValue("@SquareInvoiceVersion", If(inv IsNot Nothing AndAlso inv.Version > 0, CObj(inv.Version), DBNull.Value))
                cmd.Parameters.AddWithValue("@SquareOrderId", NzP(orderId))
                cmd.Parameters.AddWithValue("@SquarePaymentId", NzP(paymentId))
                cmd.Parameters.AddWithValue("@SquareCustomerId", NzP(customerId))
                cmd.Parameters.AddWithValue("@InvoiceNumber", NzP(If(inv IsNot Nothing, inv.InvoiceNumber, Nothing)))
                cmd.Parameters.AddWithValue("@SquareStatus", NzP(status))
                cmd.Parameters.AddWithValue("@IssueDate", DateP(If(inv IsNot Nothing, inv.IssueDate, Nothing)))
                cmd.Parameters.AddWithValue("@DueDate", DateP(If(inv IsNot Nothing, inv.DueDate, Nothing)))
                cmd.Parameters.AddWithValue("@SubTotalCents", If(order IsNot Nothing, CObj(order.SubTotalCents), DBNull.Value))
                cmd.Parameters.AddWithValue("@TpsCents", If(order IsNot Nothing, CObj(order.TpsCents), DBNull.Value))
                cmd.Parameters.AddWithValue("@TvqCents", If(order IsNot Nothing, CObj(order.TvqCents), DBNull.Value))
                cmd.Parameters.AddWithValue("@TotalCents", If(order IsNot Nothing, CObj(order.TotalCents), DBNull.Value))
                cmd.Parameters.AddWithValue("@RecipientName", NzP(If(inv IsNot Nothing, inv.RecipientName, Nothing)))
                cmd.Parameters.AddWithValue("@RecipientEmail", NzP(If(inv IsNot Nothing, inv.RecipientEmail, Nothing)))
                cmd.Parameters.AddWithValue("@RecipientPhone", NzP(If(inv IsNot Nothing, inv.RecipientPhone, Nothing)))
                cmd.Parameters.AddWithValue("@RecipientAddress1", NzP(If(inv IsNot Nothing, inv.RecipientAddress1, Nothing)))
                cmd.Parameters.AddWithValue("@RecipientAddress2", NzP(If(inv IsNot Nothing, inv.RecipientAddress2, Nothing)))
                cmd.Parameters.AddWithValue("@RecipientCity", NzP(If(inv IsNot Nothing, inv.RecipientCity, Nothing)))
                cmd.Parameters.AddWithValue("@RecipientState", NzP(If(inv IsNot Nothing, inv.RecipientState, Nothing)))
                cmd.Parameters.AddWithValue("@RecipientPostalCode", NzP(If(inv IsNot Nothing, inv.RecipientPostalCode, Nothing)))

                Dim pLines As New SqlClient.SqlParameter("@Lines", SqlDbType.Structured)
                pLines.TypeName = "dbo.TVP_SquareInvoiceLine"
                pLines.Value = BuildLinesTable(order)
                cmd.Parameters.Add(pLines)

                conn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    ''' <summary>Order synthetique (1 ligne = montant total) pour une vente sans Order Square.</summary>
    Private Shared Function SyntheticOrder(pay As clsSquare.SquarePaymentRemote) As clsSquare.SquareOrderRemote
        Dim o As New clsSquare.SquareOrderRemote()
        o.OrderId = pay.OrderId
        o.CustomerId = pay.CustomerId
        o.TotalCents = pay.AmountCents
        o.SubTotalCents = pay.AmountCents
        o.TpsCents = 0
        o.TvqCents = 0
        Dim ln As New clsSquare.SquareOrderLine()
        ln.Name = "Vente au terminal (Square)"
        ln.Qty = 1D
        ln.UnitPriceCents = pay.AmountCents
        ln.AmountCents = pay.AmountCents
        ln.HasTax = False
        o.Lines.Add(ln)
        Return o
    End Function

    ''' <summary>Construit le TVP_SquareInvoiceLine a partir des lignes de l'Order.</summary>
    Private Shared Function BuildLinesTable(order As clsSquare.SquareOrderRemote) As DataTable
        Dim dt As New DataTable()
        dt.Columns.Add("Ordre", GetType(Integer))
        dt.Columns.Add("SquareItemId", GetType(String))
        dt.Columns.Add("Description", GetType(String))
        dt.Columns.Add("Qty", GetType(Decimal))
        dt.Columns.Add("UnitPrice", GetType(Decimal))
        dt.Columns.Add("Amount", GetType(Decimal))
        dt.Columns.Add("HasTax", GetType(Boolean))
        If order IsNot Nothing AndAlso order.Lines IsNot Nothing Then
            Dim i As Integer = 0
            For Each l As clsSquare.SquareOrderLine In order.Lines
                i += 1
                dt.Rows.Add(i,
                            If(String.IsNullOrEmpty(l.CatalogObjectId), CType(DBNull.Value, Object), l.CatalogObjectId),
                            If(l.Name, CType(DBNull.Value, Object)),
                            l.Qty,
                            l.UnitPriceCents / 100D,
                            l.AmountCents / 100D,
                            l.HasTax)
            Next
        End If
        Return dt
    End Function

    Private Shared Function NzP(s As String) As Object
        If String.IsNullOrEmpty(s) Then Return DBNull.Value
        Return s
    End Function

    Private Shared Function DateP(d As DateTime?) As Object
        If d.HasValue Then Return d.Value
        Return DBNull.Value
    End Function

    ' radalert levait « Cannot read properties of undefined (reading 'radalert') »
    ' quand il partait d'un script de demarrage, ce qui cassait le traitement de la
    ' reponse AJAX et rendait la page sourde aux clics : voir clsData.ShowMessageBox.
    Private Sub ShowSquareMessage(msg As String)
        ShowMessageBox(msg, L("msgBoxTitle"))
    End Sub
End Class
