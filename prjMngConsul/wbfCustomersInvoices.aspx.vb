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
        inv.CompanyEmail = "info@mngconsul.com"
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
End Class
