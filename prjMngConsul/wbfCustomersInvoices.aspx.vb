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
        SetLiteral(Me, "litDlgWith", L("dlgWith"))
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
            Case "tipSquarePay" : Return Choose3(lang, "Encaisser (lien de paiement Square)", "Collect (Square payment link)", "Cobrar (enlace de pago Square)")
            Case "tipSendEmail" : Return Choose3(lang, "Envoyer la facture par courriel", "Send invoice by email", "Enviar factura por correo")
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
            Case "dlgEmailTitle" : Return Choose3(lang, "Envoyer la facture par courriel", "Send invoice by email", "Enviar factura por correo")
            Case "dlgEmailQuestion" : Return Choose3(lang, "Voulez-vous inclure un <strong>lien de paiement Square</strong> dans le courriel&nbsp;?", "Do you want to include a <strong>Square payment link</strong> in the email?", "¿Desea incluir un <strong>enlace de pago Square</strong> en el correo?")
            Case "dlgCancel" : Return Choose3(lang, "Annuler", "Cancel", "Cancelar")
            Case "dlgWithout" : Return Choose3(lang, "Envoyer sans lien", "Send without link", "Enviar sin enlace")
            Case "dlgWith" : Return Choose3(lang, "Avec lien Square", "With Square link", "Con enlace Square")
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

    ''' <summary>Formate un montant pour l'URL (point décimal, InvariantCulture).</summary>
    Public Function FormatAmountForUrl(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return "0"
        Try
            Return Convert.ToDecimal(value).ToString("F2", System.Globalization.CultureInfo.InvariantCulture)
        Catch
            Return "0"
        End Try
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
        ElseIf arg.StartsWith("sendmail|") Then
            ' Format : sendmail|<invoiceId>|<includeSquare 0/1>
            Dim parts As String() = arg.Split("|"c)
            Dim invoiceId As Integer = 0
            Dim includeSquare As Boolean = False
            If parts.Length >= 3 Then
                Integer.TryParse(parts(1), invoiceId)
                includeSquare = (parts(2) = "1")
            End If
            If invoiceId > 0 Then SendInvoiceByEmail(invoiceId, includeSquare)
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
        End Select
    End Sub

    ''' <summary>
    ''' Envoie la facture (PDF en pièce jointe) au courriel de facturation du
    ''' client via le service de courriels (T400Mails + T402Attachments).
    ''' Reply-To = courriel vérifié de la compagnie. Le PDF est généré au besoin.
    ''' </summary>
    Private Sub SendInvoiceByEmail(invoiceId As Integer, includeSquare As Boolean)

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
            squareLinkHtml = BuildSquarePaymentLink(invoiceId, docNumber, companyName, toEmail, reste, squareNote)
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

        ShowSquareMessage(String.Format(L("msgSent"), docNumber, toEmail) & squareNote)
    End Sub

    ''' <summary>
    ''' Génère un lien de paiement Square (page hébergée) sur le solde restant de la
    ''' facture et retourne le bloc HTML (bouton « Payer ») à insérer dans le courriel.
    ''' Estampille la facture avec le SquareOrderId (réconciliation webhook, s0688).
    ''' Retourne "" si impossible (Square non connecté, solde nul, erreur) et remplit
    ''' <paramref name="note"/> avec la raison (affichée dans la confirmation).
    ''' </summary>
    Private Function BuildSquarePaymentLink(invoiceId As Integer, docNumber As String,
                                            companyName As String, buyerEmail As String,
                                            reste As Decimal, ByRef note As String) As String
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
            Dim linkRes As clsSquare.SquarePaymentLinkResult =
                clsSquare.CreatePaymentLink(token, locationId, cents, name, "Facture client #" & docNumber,
                                            companyName, buyerEmail, UserEmail, Nothing)

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

    Private Sub ShowSquareMessage(msg As String)
        Dim safe As String = msg.Replace("\", "\\").Replace("'", "\'").Replace(ControlChars.Cr, " ").Replace(ControlChars.Lf, " ")
        Dim script As String = "radalert('" & safe & "', 400, 200, 'Import Square');"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "squareMsg", script, True)
    End Sub
End Class
