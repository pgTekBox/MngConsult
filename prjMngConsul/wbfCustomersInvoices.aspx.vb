Imports System.Data.SqlClient
Imports Telerik.Web.UI
Imports Telerik.Web.UI.PageLayout

Public Class wbfCustomersInvoices
    Inherits clsData

    Public CustomerInvoiceId As Integer

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            rgClientsFactures.Rebind()
        End If
    End Sub

    Private Sub rgCustomersFactures_NeedDataSource(sender As Object, e As GridNeedDataSourceEventArgs) Handles rgClientsFactures.NeedDataSource
        Dim dt As DataTable = GetData()
        rgClientsFactures.DataSource = dt
    End Sub

    Private Sub rgFournisseursFactures_InsertCommand(sender As Object, e As GridCommandEventArgs) Handles rgClientsFactures.InsertCommand
        If e.CommandArgument Is Nothing Then Return




        Select Case e.CommandName
            Case "EditSupplierInvoice"
                CustomerInvoiceId = e.CommandArgument
                Response.Redirect("wbfCustomerInvoinceEdit.aspx?SupplierId=" & CustomerInvoiceId.ToString)

        End Select
    End Sub


    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()



        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
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

    Private Sub rauInvoicePdf_FileUploaded(sender As Object, e As FileUploadedEventArgs) Handles rauInvoicePdf.FileUploaded
        ' 1) InvoiceId sélectionné
        'Dim invoiceId As Integer
        'If Not Integer.TryParse(hfSelectedInvoiceId.Value, invoiceId) OrElse invoiceId <= 0 Then
        '    Throw New ApplicationException("Veuillez sélectionner une facture dans la grille avant d'uploader le PDF.")
        'End If

        ' 2) Sécurité: s'assurer que c'est bien un PDF
        Dim fileName As String = e.File.FileName
        Dim contentType As String = If(String.IsNullOrWhiteSpace(e.File.ContentType), "application/pdf", e.File.ContentType)

        If Not fileName.ToLower().EndsWith(".pdf") Then
            Throw New ApplicationException("Seuls les fichiers PDF sont acceptés.")
        End If

        ' 3) Lire les bytes
        Dim pdfBytes As Byte()
        Using s = e.File.InputStream
            Using ms As New IO.MemoryStream()
                s.CopyTo(ms)
                pdfBytes = ms.ToArray()
            End Using
        End Using

        If pdfBytes Is Nothing OrElse pdfBytes.Length = 0 Then
            Throw New ApplicationException("Fichier PDF vide ou invalide.")
        End If



        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@SourceFileName", fileName))
        p.Add(New SqlClient.SqlParameter("@SourceContentType", contentType))
        p.Add(New SqlClient.SqlParameter("@SourceSizeBytes", pdfBytes.Length))
        p.Add(New SqlClient.SqlParameter("@SourceBlob", pdfBytes))

        Dim ds As DataSet = ExecuteSQLds("s0027InsertDocumentClient", p)
    End Sub


End Class