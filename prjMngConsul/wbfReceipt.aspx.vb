Imports Telerik.Web.UI

Public Class wbfReceipt
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            RadReceipt.Rebind()
        End If
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        RadReceipt.CurrentPageIndex = 0
        RadReceipt.Rebind()
    End Sub
    Protected Sub RadReceipt_NeedDataSource(sender As Object, e As GridNeedDataSourceEventArgs)
        Dim dt As DataTable = GetData()
        RadReceipt.DataSource = dt

        lblInfo.Visible = True
        lblInfo.Text = $"{If(dt IsNot Nothing, dt.Rows.Count, 0)} reçu(s)"
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


    Protected Async Sub RadReceipt_ItemCommand(sender As Object, e As GridCommandEventArgs)
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
                Dim p As New Collection
                p.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                Dim msds As DataSet = ExecuteSQLds("s0003GetDoc", p)

                If msds Is Nothing OrElse msds.Tables.Count = 0 OrElse msds.Tables(0).Rows.Count = 0 Then Exit Sub
                Dim originalBytes = msds.Tables(0).Rows(0)("ImageSource")
                If originalBytes Is Nothing OrElse IsDBNull(originalBytes) Then Exit Sub

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

                lblInfo.Text = "Receipt optimized ✔"
                lblInfo.Visible = True

                RadReceipt.Rebind()

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
                Dim p As New Collection
                p.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                Dim msds As DataSet = ExecuteSQLds("s0003GetDoc", p)

                If msds Is Nothing OrElse msds.Tables.Count = 0 OrElse msds.Tables(0).Rows.Count = 0 Then Exit Sub
                Dim imageForAIObj = msds.Tables(0).Rows(0)("ImageForAI")
                If imageForAIObj Is Nothing OrElse IsDBNull(imageForAIObj) Then Exit Sub

                Dim imageForAIBytes As Byte() = CType(imageForAIObj, Byte())
                Dim apiKey = System.Configuration.ConfigurationManager.AppSettings("OPENAI_API_KEY")

                Dim reader As New OpenAiReceiptReader()
                Dim result = Await reader.ReadReceiptAsJsonAsync(apiKey, imageForAIBytes, "image/jpeg")

                Dim p3 As New Collection
                p3.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
                p3.Add(New Data.SqlClient.SqlParameter("@JSON", result.JsonResult))
                p3.Add(New Data.SqlClient.SqlParameter("@InputToken", result.InputTokens))
                p3.Add(New Data.SqlClient.SqlParameter("@OutputToken", result.OutputTokens))
                ExecuteSQLds("s0006SaveAIReturn", p3)

                RadReceipt.Rebind()

        End Select
    End Sub

End Class