Imports System.Data

Public Class Receipts
    Inherits clsdata

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            BindGrid()
        End If
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        gvReceipts.PageIndex = 0
        BindGrid()
    End Sub

    Protected Sub gvReceipts_PageIndexChanging(sender As Object, e As GridViewPageEventArgs) Handles gvReceipts.PageIndexChanging
        gvReceipts.PageIndex = e.NewPageIndex
        BindGrid()
    End Sub

    Private Sub BindGrid()
        Dim q As String = tbSearch.Text.Trim()

        'Dim MyParam As New Collection
        'MyParam.Add(New Data.SqlClient.SqlParameter("@Title", Title))

        'MyParam.Add(New Data.SqlClient.SqlParameter("@text", Text))
        'MyParam.Add(New Data.SqlClient.SqlParameter("@email", email))


        'Dim Myds As DataSet = ExecuteSQLds("s0001GetReceipts", MyParam)




        Dim dt As DataTable = Me.ExecuteSQLds("s0001GetReceipts").Tables(0)
        If dt Is Nothing Then Return
        gvReceipts.DataSource = dt
        gvReceipts.DataBind()

        lblInfo.Visible = True
        lblInfo.Text = $"{dt.Rows.Count} reçu(s)"
    End Sub
    Protected Async Sub gvReceipts_RowCommand(sender As Object, e As GridViewCommandEventArgs)


        If e.CommandName = "DeleteR" Then
            Dim imageGUID As Guid = New Guid(e.CommandArgument.ToString)
            Dim MyParam2 As New Collection
            MyParam2.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))


            Dim msds As DataSet = ExecuteSQLds("s0006DeleteReceipt", MyParam2)
            BindGrid()

        End If

        If e.CommandName = "Optimize" Then

            Dim imageGUID As Guid = New Guid(e.CommandArgument.ToString)

            ' 1️⃣ Lire image originale
            Dim MyParam As New Collection
            MyParam.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))


            Dim msds As DataSet = ExecuteSQLds("s0003GetDoc", MyParam)


            Dim originalBytes = msds.Tables(0).Rows(0)("ImageSource")

            If originalBytes Is Nothing Then Exit Sub

            ' 2️⃣ Optimiser pour AI / OCR
            Dim oReceiptImageOptimizer As clsReceiptImageOptimizer = New clsReceiptImageOptimizer()

            Dim optimizedBytes = oReceiptImageOptimizer.OptimizeReceiptForAI(
                originalBytes,
                maxWidth:=1024,
                jpegQuality:=55,
                autoContrast:=True,
                toGrayscale:=True
            )

            ' 3️⃣ Sauvegarder


            Dim MyParam2 As New Collection
            MyParam2.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
            MyParam2.Add(New Data.SqlClient.SqlParameter("@optimizedImage", optimizedBytes))


            Dim msds2 As DataSet = ExecuteSQLds("s0004SaveoptimizedImage", MyParam2)
            lblInfo.Text = "Receipt optimized ✔"
            lblInfo.Visible = True

            BindGrid()


        End If
        If e.CommandName = "ProcessJSON" Then
            Dim imageGUID As Guid = New Guid(e.CommandArgument.ToString)
            Dim MyParam As New Collection
            MyParam.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
            Dim msds As DataSet = ExecuteSQLds("s0007GetJSON", MyParam)
            Dim json As String = msds.Tables(0).Rows(0)("AI_JSON")
            Dim oReceiptAI As New ReceiptAI(json, imageGUID)

            oReceiptAI.ProcesJSON()


        End If


        If e.CommandName = "VoirJSON" Then
            Dim imageGUID As Guid = New Guid(e.CommandArgument.ToString)
            Dim MyParam As New Collection
            MyParam.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
            Dim msds As DataSet = ExecuteSQLds("s0007GetJSON", MyParam)
            Dim json As String = msds.Tables(0).Rows(0)("AI_VIEWJSON")

            Dim safeJson = HttpUtility.JavaScriptStringEncode(json)
            Dim script = $"showJsonModal('{safeJson}');"
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "jsonpopup", script, True)
        End If
        If e.CommandName = "Process" Then

            Dim imageGUID As Guid = New Guid(e.CommandArgument.ToString)

            ' 1️⃣ Lire image originale
            Dim MyParam As New Collection
            MyParam.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
            Dim msds As DataSet = ExecuteSQLds("s0003GetDoc", MyParam)
            Dim ImageForAIBytes = msds.Tables(0).Rows(0)("ImageForAI")

            If ImageForAIBytes Is Nothing Then Exit Sub

            Dim apiKey = System.Configuration.ConfigurationManager.AppSettings("OPENAI_API_KEY")


            ' 2️⃣ Appeler OpenAI
            Dim reader As New OpenAiReceiptReader()
            Dim result = Await reader.ReadReceiptAsJsonAsync(apiKey, ImageForAIBytes, "image/jpeg")

            Dim MyParam3 As New Collection
            MyParam3.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
            MyParam3.Add(New Data.SqlClient.SqlParameter("@JSON", result.JsonResult))
            MyParam3.Add(New Data.SqlClient.SqlParameter("@InputToken", result.InputTokens))
            MyParam3.Add(New Data.SqlClient.SqlParameter("@OutputToken", result.OutputTokens))

            Dim msds3 As DataSet = ExecuteSQLds("s0006SaveAIReturn", MyParam3)




            BindGrid()


        End If




    End Sub
    'Dim originalBytes As Byte() = jpegBytesFromSql

    'Dim optimizedBytes As Byte() =
    '    ReceiptImageOptimizer.OptimizeReceiptForAI(
    '        originalBytes,
    '        maxWidth:=1024,
    '        jpegQuality:=55,
    '        autoContrast:=True,
    '        toGrayscale:=True
    '    )




End Class
