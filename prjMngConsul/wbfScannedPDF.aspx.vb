Imports Telerik.Web.UI

Public Class wbfScannedPDF
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            RadScannedPDF.Rebind()
        End If
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        RadScannedPDF.CurrentPageIndex = 0
        RadScannedPDF.Rebind()
    End Sub
    Protected Sub RadScannedPDF_NeedDataSource(sender As Object, e As GridNeedDataSourceEventArgs)
        Dim dt As DataTable = GetData()
        RadScannedPDF.DataSource = dt

        lblInfo.Visible = True
        lblInfo.Text = $"{If(dt IsNot Nothing, dt.Rows.Count, 0)} reçu(s)"
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


    Protected Async Sub RadScannedPDF_ItemCommand(sender As Object, e As GridCommandEventArgs)
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
                oReceiptAI.ProcesJSON()

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
                Dim imageForAIObj = msds.Tables(0).Rows(0)("ImageForAI")
                If imageForAIObj Is Nothing OrElse IsDBNull(imageForAIObj) Then Exit Sub

                Dim imageForAIBytes As Byte() = CType(imageForAIObj, Byte())

                Dim MyParam2 As New Collection
                MyParam2.Add(New Data.SqlClient.SqlParameter("@Parameter", "CHATGPT"))
                Dim msds2 As DataSet = ExecuteSQLds("s0000GetParameter", MyParam2)
                Dim apiKey As String = msds2.Tables(0).Rows(0)("Value")

                Dim prompt As String =
            "Tu es un moteur OCR + extraction comptable. " &
            "Lis le document pdf fourni et retourne UNIQUEMENT un JSON valide (pas de texte autour). " &
            "Schéma souhaité: " &
            "{ receipt_type,receipt_number, merchant_name,merchant_email,number_tps,number_tvq,merchant_website,  merchant_street, merchant_address, merchant_city,merchant_country,merchant_state,merchand_postalcode,merchant_phonenumber, receipt_date, currency, subtotal, taxes:[{name,amount}], total, tip, payment_method, last4, items:[{desc, qty, unit_price, amount}], confidence_notes }." &
            "Si une valeur est inconnue: null."

                Dim reader As New OpenAiReceiptReader()
                Dim result = Await reader.ReadReceiptAsJsonAsync(apiKey, imageForAIBytes, "application/pdf", prompt)


                Dim p3 As New Collection
                p3.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                p3.Add(New Data.SqlClient.SqlParameter("@JSON", result.JsonResult))
                p3.Add(New Data.SqlClient.SqlParameter("@InputToken", result.InputTokens))
                p3.Add(New Data.SqlClient.SqlParameter("@OutputToken", result.OutputTokens))
                ExecuteSQLds("s0006SaveAIReturn", p3)

                RadScannedPDF.Rebind()

        End Select
    End Sub

End Class