Imports Telerik.Web.UI

Public Class wbfReceipt
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            RadReceipt.Rebind()
        End If
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        RadReceipt.CurrentPageIndex = 0
        RadReceipt.Rebind()
    End Sub

    Private Sub RadReceipt_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles RadReceipt.NeedDataSource
        Dim dt As DataTable = GetData()
        RadReceipt.DataSource = dt

        'lblInfo.Visible = True
        'lblInfo.Text = $"{If(dt IsNot Nothing, dt.Rows.Count, 0)} reçu(s)"
    End Sub
    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()

        ' TODO: si tu veux passer @q au SP, ajoute les params ici
        'Dim p As New Collection
        'p.Add(New SqlClient.SqlParameter("@q", q))
        'Dim ds As DataSet = ExecuteSQLds("s0001GetReceipts", p)

        Dim ds As DataSet = ExecuteSQLds("s0001GetReceipts")
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function


    Protected Async Sub RadReceipt_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles RadReceipt.ItemCommand
        If e.CommandArgument Is Nothing Then Return

        Dim imageGUID As Guid
        If Not Guid.TryParse(e.CommandArgument.ToString(), imageGUID) Then Return

        Select Case e.CommandName

            Case "DeleteR"
                Dim p As New Collection
                p.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                ExecuteSQLds("s0006DeleteReceipt", p)
                RadReceipt.Rebind()

            Case "Optimize"


            Case "ProcessJSON"






                Dim p As New Collection
                p.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                Dim msds As DataSet = ExecuteSQLds("s0007GetJSON", p)

                If msds Is Nothing OrElse msds.Tables.Count = 0 OrElse msds.Tables(0).Rows.Count = 0 Then Exit Sub
                Dim json As String = CStr(msds.Tables(0).Rows(0)("AI_JSON"))

                Dim oReceiptAI As New ReceiptAI(json, imageGUID)
                oReceiptAI.ProcesJSON()

                ' optionnel:
                RadReceipt.Rebind()






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

                Dim pPro As New Collection
                pPro.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                Dim msdsPro As DataSet = ExecuteSQLds("s0003GetDoc", pPro)

                If msdsPro Is Nothing OrElse msdsPro.Tables.Count = 0 OrElse msdsPro.Tables(0).Rows.Count = 0 Then Exit Sub
                Dim originalBytes = msdsPro.Tables(0).Rows(0)("ImageSource")
                Dim ContentType As String = msdsPro.Tables(0).Rows(0)("ContentType")
                If originalBytes Is Nothing OrElse IsDBNull(originalBytes) Then Exit Sub


                Dim MyParam2 As New Collection
                MyParam2.Add(New Data.SqlClient.SqlParameter("@Parameter", "CHATGPT"))
                Dim msds2 As DataSet = ExecuteSQLds("s0000GetParameter", MyParam2)
                Dim apiKey As String = msds2.Tables(0).Rows(0)("Value")

                Dim MyParam3 As New Collection
                MyParam3.Add(New Data.SqlClient.SqlParameter("@Parameter", "PROMPT_RECEIPT"))
                Dim msds3 As DataSet = ExecuteSQLds("s0032GetPromptOpenAPI", MyParam3)
                Dim prompt As String = msds3.Tables(0).Rows(0)("Prompt")

                If ContentType = "text/plain" Then


                    Dim imageForAIText = msdsPro.Tables(0).Rows(0)("ImageSourceText")


                    If imageForAIText Is Nothing OrElse IsDBNull(imageForAIText) Then Exit Sub





                    Dim reader As New OpenAiReceiptReader(apiKey)
                    Dim result = Await reader.ParseInvoiceEmailAsync(imageForAIText, prompt)

                    'Dim imageForAIObj = msdsPro.Tables(0).Rows(0)("ImageSource")
                    'Dim imageForAIBytes As Byte() = CType(imageForAIObj, Byte())
                    'Dim result = Await reader.ParseInvoicePdfAsync(imageForAIBytes, prompt)








                    Dim p3 As New Collection
                    p3.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                    p3.Add(New Data.SqlClient.SqlParameter("@JSON", result.JsonText))
                    p3.Add(New Data.SqlClient.SqlParameter("@InputToken", result.InputTokens))
                    p3.Add(New Data.SqlClient.SqlParameter("@OutputToken", result.OutputTokens))
                    p3.Add(New Data.SqlClient.SqlParameter("@EstimatedCostUsd", result.EstimatedCostUsd))
                    ExecuteSQLds("s0006SaveAIReturn", p3)
                End If

                If ContentType = "application/pdf" Then


                    Dim imageForAIObj = msdsPro.Tables(0).Rows(0)("ImageSource")


                    If imageForAIObj Is Nothing OrElse IsDBNull(imageForAIObj) Then Exit Sub

                    Dim imageForAIBytes As Byte() = CType(imageForAIObj, Byte())



                    Dim reader As New OpenAiReceiptReader(apiKey)
                    Dim result = Await reader.ParseInvoicePdfAsync(imageForAIBytes, prompt)


                    Dim p3 As New Collection
                    p3.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                    p3.Add(New Data.SqlClient.SqlParameter("@JSON", result.JsonText))
                    p3.Add(New Data.SqlClient.SqlParameter("@InputToken", result.InputTokens))
                    p3.Add(New Data.SqlClient.SqlParameter("@OutputToken", result.OutputTokens))
                    p3.Add(New Data.SqlClient.SqlParameter("@EstimatedCostUsd", result.EstimatedCostUsd))
                    ExecuteSQLds("s0006SaveAIReturn", p3)
                End If

                If ContentType = "image/jpeg" Then


                    Dim opt As New clsReceiptImageOptimizer()
                    Dim optimizedBytes = opt.OptimizeReceiptForAI(
                        CType(originalBytes, Byte()),
                        maxWidth:=1024,
                        jpegQuality:=55,
                        autoContrast:=True,
                        toGrayscale:=True
                    )

                    Dim p2 As New Collection
                    p2.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                    p2.Add(New Data.SqlClient.SqlParameter("@optimizedImage", optimizedBytes))
                    ExecuteSQLds("s0004SaveoptimizedImage", p2)




                    Dim p As New Collection
                    p.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                    Dim msds As DataSet = ExecuteSQLds("s0003GetDoc", p)

                    If msds Is Nothing OrElse msds.Tables.Count = 0 OrElse msds.Tables(0).Rows.Count = 0 Then Exit Sub
                    Dim imageForAIObj = msds.Tables(0).Rows(0)("ImageForAI")
                    ContentType = CStr(msds.Tables(0).Rows(0)("ContentType"))
                    If imageForAIObj Is Nothing OrElse IsDBNull(imageForAIObj) Then Exit Sub

                    Dim imageForAIBytes As Byte() = CType(imageForAIObj, Byte())


                    '    Dim prompt As String =
                    '"Tu es un moteur OCR + extraction comptable. " &
                    '"Lis le reçu fourni (image) et retourne UNIQUEMENT un JSON valide (pas de texte autour). " &
                    '"Retourne aussi le type de recu dans receipt_type, exemples :Restaurant, essence ou autre" &
                    '"Schéma souhaité: " &
                    '"{ receipt_type,receipt_number, merchant_name,merchant_email,number_tps,number_tvq,merchant_website,  merchant_street, merchant_address, merchant_city,merchant_country,merchant_state,merchand_postalcode,merchant_phonenumber, receipt_date, currency, subtotal, taxes:[{name,amount}], total, tip, payment_method, last4, items:[{desc, qty, unit_price, amount}], confidence_notes }." &
                    '"Si une valeur est inconnue: null."

                    Dim reader As New OpenAiReceiptReader(apiKey)
                    Dim result = Await reader.ReadReceiptAsJsonAsync(imageForAIBytes, ContentType, prompt)

                    Dim p3 As New Collection
                    p3.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                    p3.Add(New Data.SqlClient.SqlParameter("@JSON", result.JsonResult))
                    p3.Add(New Data.SqlClient.SqlParameter("@InputToken", result.InputTokens))
                    p3.Add(New Data.SqlClient.SqlParameter("@OutputToken", result.OutputTokens))
                    p3.Add(New Data.SqlClient.SqlParameter("@EstimatedCostUsd", 0))



                    ExecuteSQLds("s0006SaveAIReturn", p3)
                End If
                RadReceipt.Rebind()

                End Select
    End Sub

End Class