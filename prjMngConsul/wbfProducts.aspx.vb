Imports System.Collections.Generic
Imports Telerik.Web.UI

Public Class wbfProducts
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ApplyLocalization()

        If Not IsPostBack Then
            BindFilterDDL()
            rlvProducts.Rebind()
            HandleSquareReturn()
        End If
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal dans RAP1.</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
        SetLiteral(Me, "litFilterCat", L("filterCat"))
        If IsSquareConnected() Then
            btnConnectSquare.Text = L("reconnectSquare")
        Else
            btnConnectSquare.Text = L("connectSquare")
        End If
        btnExportSquare.Text = L("exportSquare")
        btnImportSquare.Text = L("importSquare")
        btnAdd.Text = L("addProduct")
        tbSearch.Attributes("placeholder") = L("searchPh")
        rddlFilterCat.DefaultMessage = L("all")
        rwProduct.Title = L("winTitle")

        Dim fab As Control = FindDeep(Me, "fabAdd")
        If TypeOf fab Is System.Web.UI.HtmlControls.HtmlControl Then
            CType(fab, System.Web.UI.HtmlControls.HtmlControl).Attributes("title") = L("addProductWin")
        End If
    End Sub

    ''' <summary>Libellés du LayoutTemplate / EmptyDataTemplate du RadListView (via Literal).</summary>
    Private Sub rlvProducts_PreRender(sender As Object, e As EventArgs) Handles rlvProducts.PreRender
        SetLiteral(rlvProducts, "litColProduct", L("colProduct"))
        SetLiteral(rlvProducts, "litColCategory", L("colCategory"))
        SetLiteral(rlvProducts, "litColPrice", L("colPrice"))
        SetLiteral(rlvProducts, "litColQty", L("colQty"))
        SetLiteral(rlvProducts, "litColTaxe", L("colTaxe"))
        SetLiteral(rlvProducts, "litColActive", L("colActive"))
        SetLiteral(rlvProducts, "litColAction", L("colAction"))
        SetLiteral(rlvProducts, "litEmpty", L("empty"))
    End Sub

    ''' <summary>Traductions de l'interface Produits (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Produits — 60Sec-AI", "Products — 60Sec-AI", "Productos — 60Sec-AI")
            Case "pageTitleShort" : Return Choose3(lang, "Produits et services", "Products and services", "Productos y servicios")
            Case "connectSquare" : Return Choose3(lang, "Connecter Square", "Connect Square", "Conectar Square")
            Case "reconnectSquare" : Return Choose3(lang, "Reconnecter Square", "Reconnect Square", "Reconectar Square")
            Case "exportSquare" : Return Choose3(lang, "Exporter vers Square", "Export to Square", "Exportar a Square")
            Case "importSquare" : Return Choose3(lang, "Importer depuis Square", "Import from Square", "Importar desde Square")
            Case "addProduct" : Return Choose3(lang, "Ajouter un produit", "Add a product", "Agregar un producto")
            Case "searchPh" : Return Choose3(lang, "Rechercher (nom, description…)", "Search (name, description…)", "Buscar (nombre, descripción…)")
            Case "filterCat" : Return Choose3(lang, "Catégorie :", "Category:", "Categoría:")
            Case "all" : Return Choose3(lang, "Toutes", "All", "Todas")
            Case "colProduct" : Return Choose3(lang, "Produit", "Product", "Producto")
            Case "colCategory" : Return Choose3(lang, "Catégorie", "Category", "Categoría")
            Case "colPrice" : Return Choose3(lang, "Prix", "Price", "Precio")
            Case "colQty" : Return Choose3(lang, "Qté déf.", "Def. qty", "Cant. pred.")
            Case "colTaxe" : Return Choose3(lang, "Taxe", "Tax", "Impuesto")
            Case "colActive" : Return Choose3(lang, "Actif", "Active", "Activo")
            Case "colAction" : Return Choose3(lang, "Action", "Action", "Acción")
            Case "empty" : Return Choose3(lang, "Aucun produit trouvé.", "No product found.", "Ningún producto encontrado.")
            Case "winTitle" : Return Choose3(lang, "Ajouter / Modifier un produit", "Add / Edit a product", "Agregar / Editar un producto")
            Case "addProductWin" : Return Choose3(lang, "Ajouter un produit", "Add a product", "Agregar un producto")
            Case "editProductWin" : Return Choose3(lang, "Modifier un produit", "Edit a product", "Editar un producto")
            Case "productCount" : Return Choose3(lang, "produit(s)", "product(s)", "producto(s)")
            Case "taxTaxable" : Return Choose3(lang, "Taxable", "Taxable", "Gravable")
            Case "taxExempt" : Return Choose3(lang, "Exempt", "Exempt", "Exento")
            Case "sqConnected" : Return Choose3(lang, "Compte Square connecté avec succès.", "Square account connected successfully.", "Cuenta Square conectada con éxito.")
            Case "sqDenied" : Return Choose3(lang, "Connexion Square refusée par l'utilisateur.", "Square connection denied by the user.", "Conexión Square rechazada por el usuario.")
            Case "sqBadState" : Return Choose3(lang, "Échec de sécurité OAuth (state invalide). Réessaie la connexion.", "OAuth security failure (invalid state). Retry the connection.", "Fallo de seguridad OAuth (estado inválido). Reintente la conexión.")
            Case "sqError" : Return Choose3(lang, "Erreur lors de la connexion à Square.", "Error connecting to Square.", "Error al conectar con Square.")
            Case "sqNoActiveExport" : Return Choose3(lang, "Aucun produit actif à exporter.", "No active product to export.", "Ningún producto activo para exportar.")
            Case "sqExported" : Return Choose3(lang, "{0} produit(s) exporté(s) vers Square sur {1}.", "{0} product(s) exported to Square out of {1}.", "{0} producto(s) exportado(s) a Square de {1}.")
            Case "sqExportError" : Return Choose3(lang, "Erreur lors de l'export Square : ", "Error during Square export: ", "Error durante la exportación Square: ")
            Case "sqNoImport" : Return Choose3(lang, "Aucun produit à importer depuis Square.", "No product to import from Square.", "Ningún producto para importar desde Square.")
            Case "sqImported" : Return Choose3(lang, "{0} produit(s) créé(s) et {1} mis à jour depuis Square ({2} trouvé(s)).", "{0} product(s) created and {1} updated from Square ({2} found).", "{0} producto(s) creado(s) y {1} actualizado(s) desde Square ({2} encontrado(s)).")
            Case "sqImportError" : Return Choose3(lang, "Erreur lors de l'import Square : ", "Error during Square import: ", "Error durante la importación Square: ")
            Case "sqTitle" : Return Choose3(lang, "Square", "Square", "Square")
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

    ''' <summary>Affiche un message selon le retour OAuth Square (?square=...).</summary>
    Private Sub HandleSquareReturn()
        Dim s As String = Request.QueryString("square")
        If String.IsNullOrEmpty(s) Then Return
        Select Case s
            Case "connected" : ShowSquareMessage(L("sqConnected"))
            Case "denied" : ShowSquareMessage(L("sqDenied"))
            Case "badstate" : ShowSquareMessage(L("sqBadState"))
            Case "error" : ShowSquareMessage(L("sqError"))
        End Select
    End Sub

    Private Sub BindFilterDDL()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        SetDDL(rddlFilterCat, "Name", "Value", "s0081GetCategoriesForDDL", p)
    End Sub

    Private Sub rlvProducts_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvProducts.NeedDataSource
        Dim dt As DataTable = GetData()
        rlvProducts.DataSource = dt

        If dt IsNot Nothing Then
            lblInfo.Text = dt.Rows.Count & " " & L("productCount")
        End If
    End Sub

    Private Sub rlvProducts_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvProducts.ItemCommand
        If e.CommandArgument Is Nothing Then Return

        Select Case e.CommandName
            Case "DeleteProduct"
                Dim prodId As Integer = CInt(e.CommandArgument)
                DeleteProduct(prodId)
                rlvProducts.Rebind()
        End Select
    End Sub

    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()
        Dim catId As Integer = 0
        If Not String.IsNullOrEmpty(rddlFilterCat.SelectedValue) Then
            Integer.TryParse(rddlFilterCat.SelectedValue, catId)
        End If

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", q))
        p.Add(New SqlClient.SqlParameter("@CategoryId", catId))

        Dim ds As DataSet = ExecuteSQLds("s0076GetProducts", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Sub DeleteProduct(prodId As Integer)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Id", prodId))
        ExecuteSQL("s0078DeleteProduct", p)
    End Sub

    ' ── Filtre catégorie ──

    Protected Sub rddlFilterCat_SelectedIndexChanged(sender As Object, e As DropDownListEventArgs) Handles rddlFilterCat.SelectedIndexChanged
        rlvProducts.Rebind()
    End Sub

    ' ── Recherche ──

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvProducts.Rebind()
    End Sub

    Protected Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rddlFilterCat.ClearSelection()
        rlvProducts.Rebind()
    End Sub

    ' ── Export vers Square ──

    Protected Sub btnExportSquare_Click(sender As Object, e As EventArgs) Handles btnExportSquare.Click
        Try
            ' 1. Lire les produits/services actifs a exporter (+ mapping existant)
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0660GetProductsForSquareSync", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ShowSquareMessage(L("sqNoActiveExport"))
                Return
            End If

            ' 2. Construire la liste pour Square
            Dim items As New List(Of clsSquare.SquareProductInput)
            For Each row As DataRow In ds.Tables(0).Rows
                Dim inp As New clsSquare.SquareProductInput
                inp.ProductId = CInt(row("Id"))
                inp.Name = If(IsDBNull(row("Name")), "", CStr(row("Name")))
                inp.Description = If(IsDBNull(row("Description")), "", CStr(row("Description")))
                Dim prix As Decimal = If(IsDBNull(row("Prix")), 0D, CDec(row("Prix")))
                inp.PriceCents = CLng(Math.Round(prix * 100D))
                If Not IsDBNull(row("SquareItemId")) Then inp.ExistingItemId = CStr(row("SquareItemId"))
                If Not IsDBNull(row("SquareVariationId")) Then inp.ExistingVariationId = CStr(row("SquareVariationId"))
                If Not IsDBNull(row("SquareItemVersion")) Then inp.ExistingItemVersion = CLng(row("SquareItemVersion"))
                If Not IsDBNull(row("SquareVariationVersion")) Then inp.ExistingVariationVersion = CLng(row("SquareVariationVersion"))
                items.Add(inp)
            Next

            ' 3. Pousser vers Square (BatchUpsertCatalogObjects)
            '    Jeton de l'abonne (OAuth) avec refresh auto ; fallback Web.config.
            Dim token As String = GetValidSquareAccessToken()
            Dim results As List(Of clsSquare.SquareSyncResult) = clsSquare.BatchUpsertCatalog(token, items)

            ' 4. Sauvegarder les identifiants Square sur le produit (T075Products)
            Dim okCount As Integer = 0
            For Each r As clsSquare.SquareSyncResult In results
                If Not String.IsNullOrEmpty(r.ItemId) Then
                    Dim pm As New Collection
                    pm.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
                    pm.Add(New SqlClient.SqlParameter("@ProductId", r.ProductId))
                    pm.Add(New SqlClient.SqlParameter("@SquareItemId", r.ItemId))
                    pm.Add(New SqlClient.SqlParameter("@SquareVariationId", If(String.IsNullOrEmpty(r.VariationId), CObj(DBNull.Value), r.VariationId)))
                    pm.Add(New SqlClient.SqlParameter("@SquareItemVersion", r.ItemVersion))
                    pm.Add(New SqlClient.SqlParameter("@SquareVariationVersion", r.VariationVersion))
                    pm.Add(New SqlClient.SqlParameter("@Status", "OK"))
                    ExecuteSQL("s0661UpdateProductSquareIds", pm)
                    okCount += 1
                End If
            Next

            ShowSquareMessage(String.Format(L("sqExported"), okCount, items.Count))
        Catch ex As Exception
            ShowSquareMessage(L("sqExportError") & ex.Message)
        End Try
    End Sub

    ' ── Import des produits depuis Square (sens entrant, a la demande) ──

    Protected Sub btnImportSquare_Click(sender As Object, e As EventArgs) Handles btnImportSquare.Click
        Try
            Dim token As String = GetValidSquareAccessToken()
            Dim remotes As List(Of clsSquare.SquareProductRemote) = clsSquare.ListCatalogItems(token)

            If remotes Is Nothing OrElse remotes.Count = 0 Then
                ShowSquareMessage(L("sqNoImport"))
                rlvProducts.Rebind()
                Return
            End If

            Dim created As Integer = 0, updated As Integer = 0
            For Each p As clsSquare.SquareProductRemote In remotes
                If String.IsNullOrEmpty(p.ItemId) Then Continue For

                Dim pr As New Collection
                pr.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
                pr.Add(New SqlClient.SqlParameter("@SquareItemId", p.ItemId))
                pr.Add(New SqlClient.SqlParameter("@SquareVariationId", NzProd(p.VariationId)))
                pr.Add(New SqlClient.SqlParameter("@SquareItemVersion", If(p.ItemVersion > 0, CObj(p.ItemVersion), DBNull.Value)))
                pr.Add(New SqlClient.SqlParameter("@SquareVariationVersion", If(p.VariationVersion > 0, CObj(p.VariationVersion), DBNull.Value)))
                pr.Add(New SqlClient.SqlParameter("@Name", NzProd(p.Name)))
                pr.Add(New SqlClient.SqlParameter("@Description", NzProd(p.Description)))
                pr.Add(New SqlClient.SqlParameter("@PriceCents", If(p.PriceCents > 0, CObj(p.PriceCents), DBNull.Value)))
                Dim ds As DataSet = ExecuteSQLds("s0670UpsertProductFromSquare", pr)

                Dim action As String = ""
                If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 _
                   AndAlso Not IsDBNull(ds.Tables(0).Rows(0)("Action")) Then
                    action = CStr(ds.Tables(0).Rows(0)("Action"))
                End If
                If action = "created" Then created += 1 Else updated += 1
            Next

            ShowSquareMessage(String.Format(L("sqImported"), created, updated, remotes.Count))
            rlvProducts.Rebind()
        Catch ex As Exception
            ShowSquareMessage(L("sqImportError") & ex.Message)
        End Try
    End Sub

    Private Shared Function NzProd(s As String) As Object
        If String.IsNullOrEmpty(s) Then Return DBNull.Value
        Return s
    End Function

    Private Sub ShowSquareMessage(msg As String)
        Dim safe As String = msg.Replace("\", "\\").Replace("'", "\'").Replace(ControlChars.Cr, " ").Replace(ControlChars.Lf, " ")
        Dim titleSafe As String = L("sqTitle").Replace("'", "\'")
        Dim script As String = "radalert('" & safe & "', 400, 200, '" & titleSafe & "');"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "squareMsg", script, True)
    End Sub

    ' ── Helpers ──

    Public Function FormatPrix(prix As Object) As String
        If prix Is Nothing OrElse IsDBNull(prix) Then Return "—"
        Return CDec(prix).ToString("N2") & " $"
    End Function

    Public Function FormatQty(qty As Object) As String
        If qty Is Nothing OrElse IsDBNull(qty) Then Return "—"
        Dim d As Decimal = CDec(qty)
        If d = Math.Floor(d) Then Return CInt(d).ToString()
        Return d.ToString("N2")
    End Function

    Public Function TruncateText(txt As Object, maxLen As Integer) As String
        If txt Is Nothing OrElse IsDBNull(txt) Then Return ""
        Dim s As String = txt.ToString()
        If s.Length <= maxLen Then Return s
        Return s.Substring(0, maxLen) & "…"
    End Function

    Public Function IsActif(val As Object) As Boolean
        If val Is Nothing OrElse IsDBNull(val) Then Return False
        Return CBool(val)
    End Function

    Public Function GetTaxeBadgeClass(taxeStatus As Object) As String
        If taxeStatus Is Nothing OrElse IsDBNull(taxeStatus) Then Return "badge-zero"
        Select Case CInt(taxeStatus)
            Case 1 : Return "badge-taxable"
            Case 2 : Return "badge-exempt"
            Case Else : Return "badge-zero"
        End Select
    End Function

    Public Function GetTaxeLabel(taxeStatus As Object) As String
        If taxeStatus Is Nothing OrElse IsDBNull(taxeStatus) Then Return "—"
        Select Case CInt(taxeStatus)
            Case 1 : Return L("taxTaxable")
            Case 2 : Return L("taxExempt")
            Case Else : Return "—"
        End Select
    End Function

End Class
