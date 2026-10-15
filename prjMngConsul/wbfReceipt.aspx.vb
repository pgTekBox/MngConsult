Imports System.Data
Imports System.Linq
Imports Telerik.Web.UI

Public Class wbfReceipt
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        litRubrique.Text = L("rubrique")
        litTitre.Text = L("titre")
        litSousTitre.Text = L("sousTitre")
        tbSearch.Attributes("placeholder") = L("searchPh")

        If Not IsPostBack Then
            RadReceipt.Rebind()
        End If
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        RadReceipt.CurrentPageIndex = 0
        RadReceipt.Rebind()
    End Sub

    Private Sub RadReceipt_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles RadReceipt.NeedDataSource
        Dim tout As DataTable = GetData()
        ChargerIndicateurs(tout)
        Dim dt As DataTable = tout
        Dim q As String = tbSearch.Text.Trim()
        If dt IsNot Nothing AndAlso q <> "" Then
            dt = tout.Clone()
            For Each r As DataRow In tout.Rows
                If Correspond(r, q) Then dt.ImportRow(r)
            Next
        End If
        RadReceipt.DataSource = dt
        litPied.Text = Server.HtmlEncode(String.Format(L("pied"), If(dt Is Nothing, 0, dt.Rows.Count), TotalRecus))

        'lblInfo.Visible = True
        'lblInfo.Text = $"{If(dt IsNot Nothing, dt.Rows.Count, 0)} reçu(s)"
    End Sub
    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()

        ' TODO: si tu veux passer @q au SP, ajoute les params ici
        'Dim p As New Collection
        'p.Add(New SqlClient.SqlParameter("@q", q))
        'Dim ds As DataSet = ExecuteSQLds("s0001GetReceipts", p)

        Dim pCie As New Collection
        pCie.Add(New Data.SqlClient.SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0001GetReceipts", pCie)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function



    ' =====================================================================
    ' La signature « Portail du client » : titre sur le fond, trois indicateurs,
    ' une recherche qui filtre vraiment (fichier, fournisseur, statut), un pied.
    ' =====================================================================

    Private TotalRecus As Integer

    ''' <summary>Le texte d'une cellule HTML, pour la recherche.</summary>
    Private Shared Function SansBalises(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Dim s As String = System.Text.RegularExpressions.Regex.Replace(o.ToString(), "<[^>]+>", " ")
        Return System.Web.HttpUtility.HtmlDecode(s)
    End Function

    ''' <summary>Vrai si la ligne contient le texte cherché (fichier, fournisseur ou statut).</summary>
    Private Shared Function Correspond(r As DataRow, q As String) As Boolean
        If String.IsNullOrEmpty(q) Then Return True
        Dim texte As String = SansBalises(r("SourceFileName")) & " " & SansBalises(r("SupplierInfo")) & " " & Convert.ToString(r("ProcessingStatus"))
        Return texte.IndexOf(q, StringComparison.OrdinalIgnoreCase) >= 0
    End Function

    Private Shared Function Vrai(o As Object) As Boolean
        If o Is Nothing OrElse IsDBNull(o) Then Return False
        Try
            Return Convert.ToInt32(o) <> 0
        Catch
            Return False
        End Try
    End Function

    ''' <summary>Les indicateurs, comptés sur tous les reçus de la compagnie.</summary>
    Private Sub ChargerIndicateurs(dt As DataTable)
        Dim rows As List(Of DataRow) = If(dt Is Nothing, New List(Of DataRow), dt.Rows.Cast(Of DataRow)().ToList())
        TotalRecus = rows.Count
        Dim aLire As Integer = rows.Where(Function(r) Vrai(r("CanProcessAI"))).Count()
        Dim lus As Integer = rows.Where(Function(r) Vrai(r("CanViewJSON"))).Count()
        Dim debutMois As Date = New Date(Date.Today.Year, Date.Today.Month, 1)
        Dim duMois As Integer = rows.Where(Function(r) Not IsDBNull(r("Created")) AndAlso CDate(r("Created")) >= debutMois).Count()
        Dim mois As String = Globalization.CultureInfo.GetCultureInfo(If(CurrentLang = "en", "en-CA", If(CurrentLang = "es", "es-ES", "fr-CA"))).DateTimeFormat.GetMonthName(Date.Today.Month)
        litKpis.Text = Kpi(L("kpiALire"), aLire.ToString(), L("kpiALireSub"), If(aLire > 0, "#E3B341", "#43B47A")) &
                       Kpi(L("kpiLus"), lus.ToString(), L("kpiLusSub"), "#1B4F9C") &
                       Kpi(String.Format(L("kpiMois"), mois), duMois.ToString(), L("kpiMoisSub"), "#43B47A")
    End Sub

    Private Function Kpi(lab As String, val As String, sub_ As String, point As String) As String
        Return "<div class=""fc-kpi""><span class=""lab""><i style=""background:" & point & """></i>" & Server.HtmlEncode(lab) & "</span><span class=""val"">" &
               Server.HtmlEncode(val) & "</span><span class=""sub"">" & Server.HtmlEncode(sub_) & "</span></div>"
    End Function

    ''' <summary>Les entêtes de colonnes et le texte vide, dans les gabarits du RadListView.</summary>
    Private Sub RadReceipt_PreRender(sender As Object, e As EventArgs) Handles RadReceipt.PreRender
        SetLiteral(RadReceipt, "litColFichier", L("colFichier"))
        SetLiteral(RadReceipt, "litColFournisseur", L("colFournisseur"))
        SetLiteral(RadReceipt, "litColIA", L("colIA"))
        SetLiteral(RadReceipt, "litColResultat", L("colResultat"))
        SetLiteral(RadReceipt, "litColCompta", L("colCompta"))
        SetLiteral(RadReceipt, "litColStatut", L("colStatut"))
        SetLiteral(RadReceipt, "litColAction", L("colAction"))
        SetLiteral(RadReceipt, "litEmpty", L("empty"))
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

    Protected Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        RadReceipt.Rebind()
    End Sub

    ''' <summary>Traductions (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "rubrique" : Return Choose3(lang, "Achats", "Purchases", "Compras")
            Case "titre" : Return Choose3(lang, "Reçus", "Receipts", "Recibos")
            Case "sousTitre" : Return Choose3(lang, "Les reçus photographiés ou arrivés par courriel : l'IA les lit, vous les passez en comptabilité.", "Receipts photographed or received by email: the AI reads them, you post them to the books.", "Los recibos fotografiados o recibidos por correo: la IA los lee, usted los contabiliza.")
            Case "searchPh" : Return Choose3(lang, "Chercher un fournisseur, un fichier ou un statut", "Search a supplier, a file or a status", "Buscar un proveedor, un archivo o un estado")
            Case "kpiALire" : Return Choose3(lang, "À lire par l'IA", "To be read by the AI", "Por leer por la IA")
            Case "kpiALireSub" : Return Choose3(lang, "reçus en attente", "receipts waiting", "recibos en espera")
            Case "kpiLus" : Return Choose3(lang, "Lus par l'IA", "Read by the AI", "Leídos por la IA")
            Case "kpiLusSub" : Return Choose3(lang, "résultat à contrôler ou à comptabiliser", "result to check or to post", "resultado por revisar o contabilizar")
            Case "kpiMois" : Return Choose3(lang, "Reçus en {0}", "Received in {0}", "Recibidos en {0}")
            Case "kpiMoisSub" : Return Choose3(lang, "fichiers arrivés ce mois", "files received this month", "archivos recibidos este mes")
            Case "colFichier" : Return Choose3(lang, "Fichier", "File", "Archivo")
            Case "colFournisseur" : Return Choose3(lang, "Fournisseur", "Supplier", "Proveedor")
            Case "colIA" : Return Choose3(lang, "Lecture IA", "AI reading", "Lectura IA")
            Case "colResultat" : Return Choose3(lang, "Résultat", "Result", "Resultado")
            Case "colCompta" : Return Choose3(lang, "Comptabiliser", "Post", "Contabilizar")
            Case "colStatut" : Return Choose3(lang, "Statut", "Status", "Estado")
            Case "colAction" : Return Choose3(lang, "Action", "Action", "Acción")
            Case "btnIA" : Return Choose3(lang, "Lire avec l'IA", "Read with the AI", "Leer con la IA")
            Case "btnVoir" : Return Choose3(lang, "Voir le résultat", "View the result", "Ver el resultado")
            Case "btnCompta" : Return Choose3(lang, "Créer en comptabilité", "Create in the books", "Crear en contabilidad")
            Case "empty" : Return Choose3(lang, "Aucun reçu ne correspond.", "No receipt matches.", "Ningún recibo coincide.")
            Case "pied" : Return Choose3(lang, "{0} sur {1} reçus", "{0} of {1} receipts", "{0} de {1} recibos")
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