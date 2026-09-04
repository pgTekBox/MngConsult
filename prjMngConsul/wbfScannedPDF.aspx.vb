Imports Telerik.Web.UI

Public Class wbfScannedPDF
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            RadScannedPDF.Rebind()
        End If
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        RadScannedPDF.CurrentPageIndex = 0
        RadScannedPDF.Rebind()
    End Sub

    Private Sub RadScannedPDF_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles RadScannedPDF.NeedDataSource
        Dim dt As DataTable = GetData()
        RadScannedPDF.DataSource = dt
    End Sub
    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()

        ' TODO: si tu veux passer @q au SP, ajoute les params ici
        'Dim p As New Collection
        'p.Add(New SqlClient.SqlParameter("@q", q))
        'Dim ds As DataSet = ExecuteSQLds("s0001GetReceipts", p)

        Dim ds As DataSet = ExecuteSQLds("s0028GetDocScanned")
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function


    Protected Async Sub RadScannedPDF_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles RadScannedPDF.ItemCommand
        If e.CommandArgument Is Nothing Then Return

        Dim imageGUID As Guid
        If Not Guid.TryParse(e.CommandArgument.ToString(), imageGUID) Then Return

        Select Case e.CommandName

            Case "DeleteR"
                Dim p As New Collection
                p.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                ExecuteSQLds("s0006DeleteReceipt", p)
                RadScannedPDF.Rebind()



            Case "ProcessJSON"
                Dim p As New Collection
                p.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                Dim msds As DataSet = ExecuteSQLds("s0007GetJSON", p)

                If msds Is Nothing OrElse msds.Tables.Count = 0 OrElse msds.Tables(0).Rows.Count = 0 Then Exit Sub
                Dim json As String = CStr(msds.Tables(0).Rows(0)("AI_JSON"))

                Dim oReceiptAI As New ReceiptAI(json, imageGUID)
                oReceiptAI.ProcesJSONForCustomerInvoice()

                ' optionnel:
                RadScannedPDF.Rebind()






            Case "VoirJSON"
                Dim p As New Collection
                p.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                Dim msds As DataSet = ExecuteSQLds("s0007GetJSON", p)

                If msds Is Nothing OrElse msds.Tables.Count = 0 OrElse msds.Tables(0).Rows.Count = 0 Then Exit Sub
                Dim json As String = CStr(msds.Tables(0).Rows(0)("AI_VIEWJSON"))

                Dim safeJson = HttpUtility.JavaScriptStringEncode(json)
                Dim script = $"showJsonModal('{safeJson}');"
                ScriptManager.RegisterStartupScript(Me, Me.GetType(), "jsonpopup", script, True)

            Case "Process"
                Dim p As New Collection
                p.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                Dim msds As DataSet = ExecuteSQLds("s0003GetDoc", p)

                If msds Is Nothing OrElse msds.Tables.Count = 0 OrElse msds.Tables(0).Rows.Count = 0 Then Exit Sub
                Dim imageForAIObj = msds.Tables(0).Rows(0)("ImageSource")
                Dim ContentType As String = CStr(msds.Tables(0).Rows(0)("ContentType"))


                If imageForAIObj Is Nothing OrElse IsDBNull(imageForAIObj) Then Exit Sub

                Dim imageForAIBytes As Byte() = CType(imageForAIObj, Byte())

                Dim MyParam2 As New Collection
                MyParam2.Add(New Data.SqlClient.SqlParameter("@Parameter", "CHATGPT"))
                Dim msds2 As DataSet = ExecuteSQLds("s0000GetParameter", MyParam2)
                Dim apiKey As String = msds2.Tables(0).Rows(0)("Value")

                Dim MyParam3 As New Collection
                MyParam3.Add(New Data.SqlClient.SqlParameter("@Parameter", "PROMPT_INVPDF"))
                Dim msds3 As DataSet = ExecuteSQLds("s0032GetPromptOpenAPI", MyParam3)
                Dim prompt As String = msds3.Tables(0).Rows(0)("Prompt")

                Dim reader As New OpenAiReceiptReader(apiKey)
                Dim result = Await reader.ParseInvoicePdfAsync(imageForAIBytes, prompt)


                Dim p3 As New Collection
                p3.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                p3.Add(New Data.SqlClient.SqlParameter("@JSON", result.JsonText))
                p3.Add(New Data.SqlClient.SqlParameter("@InputToken", result.InputTokens))
                p3.Add(New Data.SqlClient.SqlParameter("@OutputToken", result.OutputTokens))
                p3.Add(New Data.SqlClient.SqlParameter("@EstimatedCostUsd", result.EstimatedCostUsd))
                ExecuteSQLds("s0006SaveAIReturn", p3)

                RadScannedPDF.Rebind()

        End Select
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
        ' La compagnie du document est celle de la session : la procédure
        ' écrivait auparavant une compagnie codée en dur, et le document
        ' n'apparaissait pas chez celui qui venait de le déposer.
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))

        Dim ds As DataSet = ExecuteSQLds("s0027InsertDocumentClient", p)

        RadScannedPDF.Rebind()

    End Sub


End Class