Imports System.Data.SqlClient
Imports System.Drawing
Imports Telerik.Web.UI
Imports Telerik.Web.UI.OrgChartStyles
Imports Telerik.Web.UI.PageLayout

Public Class wbfCustomersInvoices
    Inherits clsData

    Public CustomerInvoiceId As Integer

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            rlvClientsFactures.Rebind()
        End If
    End Sub
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
        If e.Argument = "refreshgrid" Then
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
                    GenerateAndDownloadPdf(invoiceId)
                    rlvClientsFactures.Rebind()
                End If

            Case "DeleteInvoice"
                Dim invoiceId As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), invoiceId)
                DeleteDocument(invoiceId)
                rlvClientsFactures.Rebind()
        End Select
    End Sub

    Sub DeleteDocument(invoiceId As Integer)

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@DocumentId", invoiceId))
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s317DeleteDocument ", p)
        If ds.Tables(0).Rows(0)("RetCode") = 2 Then


        End If
    End Sub



    ''' <summary>
    ''' Génère le PDF de la facture, le stocke dans T060Document.PdfData,
    ''' puis l'envoie au navigateur en téléchargement.
    ''' </summary>
    Private Sub GenerateAndDownloadPdf(invoiceId As Integer)

        ' 1. Charger les données de la facture
        Dim inv As InvoiceData = LoadInvoiceForPdf(invoiceId)
        If inv Is Nothing Then Exit Sub

        ' 2. Générer le PDF en mémoire
        Dim pdfBytes As Byte() = InvoicePdfBuilder.Build(inv)

        ' 3. Stocker dans T060Document
        Dim fileName As String = "Invoice_" & inv.InvoiceNumber & ".pdf"

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@InvoiceId", invoiceId))
        p.Add(New SqlClient.SqlParameter("@PdfData", pdfBytes))
        p.Add(New SqlClient.SqlParameter("@FileName", fileName))
        ExecuteSQL("s0116SaveInvoicePdf", p)

        ' 4. Envoyer au navigateur
        'Response.Clear()
        'Response.ContentType = "application/pdf"
        'Response.AddHeader("Content-Disposition", "attachment; filename=""" & fileName & """")
        'Response.AddHeader("Content-Length", pdfBytes.Length.ToString())
        'Response.BinaryWrite(pdfBytes)
        'Response.Flush()
        'Response.SuppressContent = True
        'Context.ApplicationInstance.CompleteRequest()
    End Sub

    ''' <summary>
    ''' Charge l'objet InvoiceData (entête + lignes) depuis la BD via s0115.
    ''' </summary>
    Private Function LoadInvoiceForPdf(invoiceId As Integer) As InvoiceData

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@InvoiceId", invoiceId))
        Dim ds As DataSet = ExecuteSQLds("s0115GetInvoiceForPdf", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Return Nothing
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim inv As New InvoiceData()

        ' === Émetteur (votre entreprise) — à externaliser dans une config plus tard ===
        inv.CompanyName = "MngConsul Inc."
        inv.CompanyTagline = "Cabinet de massothérapie"
        inv.CompanyAddressLine1 = "123 rue Principale"
        inv.CompanyAddressLine2 = "Montréal, QC H2X 1A1"
        inv.CompanyPhone = "(514) 555-1234"
        inv.CompanyEmail = "info@60sec.ca"
        inv.CompanyTpsNumber = "123456789 RT0001"
        inv.CompanyTvqNumber = "1234567890 TQ0001"

        ' === Facture ===
        inv.InvoiceNumber = If(r("DocumentNumber") Is DBNull.Value, invoiceId.ToString(), r("DocumentNumber").ToString())
        inv.IssueDate = If(r("DocumentDate") Is DBNull.Value, Date.Now.Date, CDate(r("DocumentDate")))
        inv.DueDate = If(r("DueDate") Is DBNull.Value, inv.IssueDate.AddDays(30), CDate(r("DueDate")))

        ' === Client (depuis les colonnes copiées dans T060Document) ===
        inv.CustomerName = If(r("Name") Is DBNull.Value, "", r("Name").ToString())
        inv.CustomerAddressLine1 = If(r("Address1") Is DBNull.Value, "", r("Address1").ToString())

        Dim line2 As New System.Text.StringBuilder()
        If Not (r("City") Is DBNull.Value) Then line2.Append(r("City").ToString())
        If Not (r("State") Is DBNull.Value) Then line2.Append(", ").Append(r("State").ToString())
        If Not (r("PostalCode") Is DBNull.Value) Then line2.Append(" ").Append(r("PostalCode").ToString())
        inv.CustomerAddressLine2 = line2.ToString()

        inv.CustomerPhone = If(r("Phone") Is DBNull.Value, "", r("Phone").ToString())
        inv.CustomerEmail = If(r("Email") Is DBNull.Value, "", r("Email").ToString())

        ' === Totaux ===
        inv.SubTotal = If(r("SubTotal") Is DBNull.Value, 0D, CDec(r("SubTotal")))
        inv.Tps = If(r("TPS") Is DBNull.Value, 0D, CDec(r("TPS")))
        inv.Tvq = If(r("TVQ") Is DBNull.Value, 0D, CDec(r("TVQ")))
        inv.Total = If(r("Total") Is DBNull.Value, 0D, CDec(r("Total")))

        ' === État de paiement ===
        '   Apposera le tampon « PAYÉ » sur le PDF si la facture est totalement réglée.
        '   Rétrocompatible : si la proc s0115 ne retourne ni ResteAPayer ni IsPaid,
        '   IsPaid reste False et aucun tampon n'est dessiné.
        If ds.Tables(0).Columns.Contains("ResteAPayer") Then
            Dim reste As Decimal = If(r("ResteAPayer") Is DBNull.Value, inv.Total, CDec(r("ResteAPayer")))
            inv.IsPaid = (reste <= 0D AndAlso inv.Total > 0D)
        ElseIf ds.Tables(0).Columns.Contains("IsPaid") Then
            inv.IsPaid = If(r("IsPaid") Is DBNull.Value, False, CBool(r("IsPaid")))
        End If

        ' === Lignes (table 2 du DataSet) ===
        If ds.Tables.Count >= 2 Then
            For Each rl As DataRow In ds.Tables(1).Rows
                inv.Items.Add(New InvoiceLine With {
                    .Description = If(rl("ProductName") Is DBNull.Value OrElse rl("ProductName").ToString() = "",
                                       If(rl("Description") Is DBNull.Value, "", rl("Description").ToString()),
                                       rl("ProductName").ToString()),
                    .SubDescription = If(rl("Description") Is DBNull.Value, "", rl("Description").ToString()),
                    .Qty = If(rl("Qty") Is DBNull.Value, 1D, CDec(rl("Qty"))),
                    .UnitPrice = If(rl("UnitPrice") Is DBNull.Value, 0D, CDec(rl("UnitPrice"))),
                    .Amount = If(rl("Amount") Is DBNull.Value, 0D, CDec(rl("Amount")))
                })
            Next
        End If

        Return inv
    End Function

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

            ShowSquareMessage(invCount & " facture(s) et " & payCount & " paiement(s) traites depuis Square.")
            rlvClientsFactures.Rebind()
        Catch ex As Exception
            ShowSquareMessage("Erreur lors de l'import Square : " & ex.Message)
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
