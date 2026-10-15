Imports System.Collections.Generic
Imports System.Data
Imports System.Linq
Imports System.Text
Imports Telerik.Web.UI

Public Class wbfProducts
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        ApplyLocalization()

        If Not IsPostBack Then
            BindFilterDDL()
            rlvProducts.Rebind()
            HandleSquareReturn()
        End If
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal dans RAP1.</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("titre"))
        litRubrique.Text = L("rubrique")
        litSousTitre.Text = L("sousTitre")
        SetLiteral(Me, "litFilterCat", L("filterCat"))
        ' Bouton « Connecter Square » déplacé vers wbfPaymentProcessors.aspx.
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
            Case "exportSquare" : Return Choose3(lang, "Envoyer vers Square", "Send to Square", "Enviar a Square")
            Case "importSquare" : Return Choose3(lang, "Importer de Square", "Import from Square", "Importar de Square")
            Case "addProduct" : Return Choose3(lang, "+ Ajouter un produit", "+ Add a product", "+ Agregar un producto")
            Case "searchPh" : Return Choose3(lang, "Chercher un produit ou une description", "Search a product or a description", "Buscar un producto o una descripción")
            Case "filterCat" : Return Choose3(lang, "Catégorie", "Category", "Categoría")
            Case "all" : Return Choose3(lang, "Toutes", "All", "Todas")
            Case "colProduct" : Return Choose3(lang, "Produit", "Product", "Producto")
            Case "colCategory" : Return Choose3(lang, "Catégorie", "Category", "Categoría")
            Case "colPrice" : Return Choose3(lang, "Prix", "Price", "Precio")
            Case "colQty" : Return Choose3(lang, "Qté déf.", "Def. qty", "Cant. pred.")
            Case "colTaxe" : Return Choose3(lang, "Taxe", "Tax", "Impuesto")
            Case "colActive" : Return Choose3(lang, "Actif", "Active", "Activo")
            Case "colAction" : Return Choose3(lang, "Action", "Action", "Acción")
            Case "empty" : Return Choose3(lang, "Aucun produit ne correspond à ces filtres.", "No product matches these filters.", "Ningún producto coincide con estos filtros.")
            Case "winTitle" : Return Choose3(lang, "Ajouter / Modifier un produit", "Add / Edit a product", "Agregar / Editar un producto")
            Case "addProductWin" : Return Choose3(lang, "Ajouter un produit", "Add a product", "Agregar un producto")
            Case "editProductWin" : Return Choose3(lang, "Modifier un produit", "Edit a product", "Editar un producto")
            Case "productCount" : Return Choose3(lang, "produit(s)", "product(s)", "producto(s)")
            Case "taxTaxable" : Return Choose3(lang, "Taxable", "Taxable", "Gravable")
            Case "taxExempt" : Return Choose3(lang, "Exempt", "Exempt", "Exento")
            Case "rubrique" : Return Choose3(lang, "Produits et services", "Products and services", "Productos y servicios")
            Case "titre" : Return Choose3(lang, "Catalogue", "Catalog", "Catálogo")
            Case "sousTitre" : Return Choose3(lang, "Un seul catalogue pour vos factures, vos soumissions et Square.", "One catalog for your invoices, your quotes and Square.", "Un solo catálogo para sus facturas, sus cotizaciones y Square.")
            Case "kpiActifs" : Return Choose3(lang, "Produits actifs", "Active products", "Productos activos")
            Case "kpiActifsSub" : Return Choose3(lang, "en vente", "on sale", "en venta")
            Case "kpiInactifs" : Return Choose3(lang, "Inactifs", "Inactive", "Inactivos")
            Case "kpiInactifsSub" : Return Choose3(lang, "cachés des factures", "hidden from invoices", "ocultos de las facturas")
            Case "kpiAComp" : Return Choose3(lang, "À compléter", "To complete", "Por completar")
            Case "kpiACompSub" : Return Choose3(lang, "prix, catégorie ou taxe", "price, category or tax", "precio, categoría o impuesto")
            Case "kpiCats" : Return Choose3(lang, "Catégories", "Categories", "Categorías")
            Case "kpiCatsSub" : Return Choose3(lang, "ouvrir la liste", "open the list", "abrir la lista")
            Case "triLbl" : Return Choose3(lang, "Trier", "Sort", "Ordenar")
            Case "triNom" : Return Choose3(lang, "Nom", "Name", "Nombre")
            Case "triCat" : Return Choose3(lang, "Catégorie", "Category", "Categoría")
            Case "triPrix" : Return Choose3(lang, "Prix", "Price", "Precio")
            Case "manque" : Return Choose3(lang, "À compléter : {0}", "To complete: {0}", "Por completar: {0}")
            Case "mPrix" : Return Choose3(lang, "prix", "price", "precio")
            Case "mCat" : Return Choose3(lang, "catégorie", "category", "categoría")
            Case "mTaxe" : Return Choose3(lang, "taxe", "tax", "impuesto")
            Case "actifOui" : Return Choose3(lang, "Actif", "Active", "Activo")
            Case "actifNon" : Return Choose3(lang, "Inactif", "Inactive", "Inactivo")
            Case "sansCat" : Return Choose3(lang, "Sans catégorie", "No category", "Sin categoría")
            Case "pied" : Return Choose3(lang, "{0} sur {1} produits", "{0} of {1} products", "{0} de {1} productos")
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
        ChargerIndicateurs()
        Dim dt As DataTable = FiltrerEtTrier(GetData())
        rlvProducts.DataSource = dt
        litPied.Text = Server.HtmlEncode(String.Format(L("pied"), If(dt Is Nothing, 0, dt.Rows.Count), TotalProduits))
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
        FiltreCourant = ""
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

    ' radalert leve « Cannot read properties of undefined (reading 'radalert') »
    ' quand il part d'un script de demarrage : voir clsData.ShowMessageBox.
    Private Sub ShowSquareMessage(msg As String)
        ShowMessageBox(msg, L("sqTitle"))
    End Sub


    ' =====================================================================
    ' Les indicateurs (actifs / inactifs / à compléter / catégories), le filtre
    ' qu'ils posent et le tri des pastilles, conservés en session. Les décomptes
    ' se font sur tout le catalogue, sans recherche ni catégorie.
    ' =====================================================================

    Private Property FiltreCourant As String
        Get
            Return If(TryCast(Session("Prod.Filtre"), String), "")
        End Get
        Set(value As String)
            Session("Prod.Filtre") = value
        End Set
    End Property

    Private Property TriCourant As String
        Get
            Return If(TryCast(Session("Prod.Tri"), String), "nom")
        End Get
        Set(value As String)
            Session("Prod.Tri") = value
        End Set
    End Property

    Private TotalProduits As Integer

    ''' <summary>Un indicateur ou une pastille cliqué (hfChip = « groupe|valeur »).</summary>
    Protected Sub btnChip_Click(sender As Object, e As EventArgs) Handles btnChip.Click
        Dim v As String = If(hfChip.Value, "")
        hfChip.Value = ""
        Dim i As Integer = v.IndexOf("|"c)
        If i < 0 Then Return
        Dim groupe As String = v.Substring(0, i)
        Dim valeur As String = v.Substring(i + 1).Trim().ToLowerInvariant()
        Select Case groupe
            Case "kpi"
                ' Un second clic sur l'indicateur posé l'enlève.
                FiltreCourant = If(FiltreCourant = valeur, "", valeur)
            Case "tri"
                If valeur = "nom" OrElse valeur = "cat" OrElse valeur = "prix" Then TriCourant = valeur
        End Select
        rlvProducts.Rebind()
    End Sub

    Private Shared Function Vrai(o As Object) As Boolean
        If o Is Nothing OrElse IsDBNull(o) Then Return False
        Try
            Return Convert.ToBoolean(o)
        Catch
            Return False
        End Try
    End Function

    Private Shared Function Nombre(o As Object) As Decimal
        If o Is Nothing OrElse IsDBNull(o) Then Return 0D
        Try
            Return Convert.ToDecimal(o)
        Catch
            Return 0D
        End Try
    End Function

    ''' <summary>Ce qui manque à un produit pour être complet : prix, catégorie ou taxe.</summary>
    Private Function Manques(prix As Object, categoryId As Object, taxe As Object) As List(Of String)
        Dim m As New List(Of String)
        If Nombre(prix) <= 0D Then m.Add(L("mPrix"))
        If Nombre(categoryId) <= 0D Then m.Add(L("mCat"))
        If Nombre(taxe) <= 0D Then m.Add(L("mTaxe"))
        Return m
    End Function

    Private Function EstAComplet(r As DataRow) As Boolean
        Return Manques(r("Prix"), r("CategoryId"), r("TaxeStatusId")).Count > 0
    End Function

    Private Function LireTout() As List(Of DataRow)
        Try
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Search", ""))
            p.Add(New SqlClient.SqlParameter("@CategoryId", 0))
            Dim ds As DataSet = ExecuteSQLds("s0076GetProducts", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0).Rows.Cast(Of DataRow)().ToList()
        Catch
        End Try
        Return New List(Of DataRow)
    End Function

    Private Sub ChargerIndicateurs()
        Dim rows As List(Of DataRow) = LireTout()
        TotalProduits = rows.Count
        Dim actifs As Integer = rows.Where(Function(r) Vrai(r("Actif"))).Count()
        Dim aComp As Integer = rows.Where(Function(r) EstAComplet(r)).Count()
        Dim cats As Integer = rows.Select(Function(r) Convert.ToString(r("CategoryName"))).Where(Function(c) c <> "").Distinct().Count()

        Dim sb As New StringBuilder()
        sb.Append(Kpi("actifs", L("kpiActifs"), actifs & " / " & rows.Count, L("kpiActifsSub"), "#43B47A"))
        sb.Append(Kpi("inactifs", L("kpiInactifs"), (rows.Count - actifs).ToString(), L("kpiInactifsSub"), "#AEBBCD"))
        sb.Append(Kpi("acompleter", L("kpiAComp"), aComp.ToString(), L("kpiACompSub"), If(aComp > 0, "#E3B341", "#43B47A")))
        sb.Append("<a class=""fc-kpi"" href=""wbfProductCategory.aspx""><span class=""lab""><i style=""background:#1B4F9C""></i>" & Server.HtmlEncode(L("kpiCats")) &
                  "</span><span class=""val"">" & cats & "</span><span class=""sub"">" & Server.HtmlEncode(L("kpiCatsSub")) & "</span></a>")
        litKpis.Text = sb.ToString()

        Dim tris As New StringBuilder()
        For Each t In New String()() {New String() {"nom", L("triNom")}, New String() {"cat", L("triCat")}, New String() {"prix", L("triPrix")}}
            Dim actif As Boolean = (TriCourant = t(0))
            tris.Append("<button type=""button"" class=""fc-pill").Append(If(actif, " on", "")).Append(""" aria-pressed=""").Append(If(actif, "true", "false")).
                 Append(""" onclick=""fcChip('tri','").Append(t(0)).Append("')"">").Append(Server.HtmlEncode(t(1))).Append("</button>")
        Next
        litChips.Text = tris.ToString()
        litTriLbl.Text = Server.HtmlEncode(L("triLbl"))
    End Sub

    Private Function Kpi(valeur As String, lab As String, val As String, sub_ As String, point As String) As String
        Dim actif As Boolean = (FiltreCourant = valeur)
        Return "<button type=""button"" class=""fc-kpi" & If(actif, " on", "") & """ aria-pressed=""" & If(actif, "true", "false") &
               """ onclick=""fcChip('kpi','" & valeur & "')"">" &
               "<span class=""lab""><i style=""background:" & point & """></i>" & Server.HtmlEncode(lab) & "</span>" &
               "<span class=""val"">" & Server.HtmlEncode(val) & "</span>" &
               "<span class=""sub"">" & Server.HtmlEncode(sub_) & "</span></button>"
    End Function

    ''' <summary>Le filtre de l'indicateur posé, puis le tri des pastilles.</summary>
    Private Function FiltrerEtTrier(dt As DataTable) As DataTable
        If dt Is Nothing Then Return Nothing
        Dim rows As IEnumerable(Of DataRow) = dt.Rows.Cast(Of DataRow)()
        Select Case FiltreCourant
            Case "actifs" : rows = rows.Where(Function(r) Vrai(r("Actif")))
            Case "inactifs" : rows = rows.Where(Function(r) Not Vrai(r("Actif")))
            Case "acompleter" : rows = rows.Where(Function(r) EstAComplet(r))
        End Select
        Select Case TriCourant
            Case "cat" : rows = rows.OrderBy(Function(r) Convert.ToString(r("CategoryName")), StringComparer.CurrentCultureIgnoreCase).ThenBy(Function(r) Convert.ToString(r("Name")), StringComparer.CurrentCultureIgnoreCase)
            Case "prix" : rows = rows.OrderByDescending(Function(r) Nombre(r("Prix"))).ThenBy(Function(r) Convert.ToString(r("Name")), StringComparer.CurrentCultureIgnoreCase)
            Case Else : rows = rows.OrderBy(Function(r) Convert.ToString(r("Name")), StringComparer.CurrentCultureIgnoreCase)
        End Select
        Dim copie As DataTable = dt.Clone()
        For Each r As DataRow In rows
            copie.ImportRow(r)
        Next
        Return copie
    End Function

    ' =====================================================================
    ' Les cellules de la liste, au style du gabarit « Portail du client »
    ' =====================================================================

    ''' <summary>Le nom en gras, la description dessous, puis ce qui manque (prix, catégorie, taxe).</summary>
    Public Function ProduitCell(nom As Object, description As Object, prix As Object, categoryId As Object, taxe As Object) As String
        Dim sb As New StringBuilder()
        sb.Append("<b>").Append(Server.HtmlEncode(Convert.ToString(nom))).Append("</b>")
        Dim d As String = TruncateText(description, 80)
        If d <> "" Then sb.Append("<span>").Append(Server.HtmlEncode(d)).Append("</span>")
        Dim m As List(Of String) = Manques(prix, categoryId, taxe)
        If m.Count > 0 Then sb.Append("<em>● ").Append(Server.HtmlEncode(String.Format(L("manque"), String.Join(", ", m)))).Append("</em>")
        Return sb.ToString()
    End Function

    Public Function CatPill(categorie As Object) As String
        Dim c As String = Convert.ToString(categorie).Trim()
        If c = "" Then Return "<span class=""fc-pay"" style=""background:#F2F5F9;color:#5B6B86"">" & Server.HtmlEncode(L("sansCat")) & "</span>"
        Return "<span class=""fc-pay"" style=""background:#E3EBF7;color:#143A73"">" & Server.HtmlEncode(c) & "</span>"
    End Function

    Public Function PrixCell(prix As Object) As String
        If prix Is Nothing OrElse IsDBNull(prix) Then Return "<span class=""rien"">—</span>"
        Return "<b>" & Server.HtmlEncode(CDec(prix).ToString("N2") & " $") & "</b>"
    End Function

    Public Function TaxePill(taxe As Object) As String
        Dim code As Integer = CInt(Nombre(taxe))
        Select Case code
            Case 1 : Return "<span class=""fc-pay"" style=""background:#E8EDF5;color:#143A73"">" & Server.HtmlEncode(L("taxTaxable")) & "</span>"
            Case 2 : Return "<span class=""fc-pay"" style=""background:#FBF1DC;color:#7A5200"">" & Server.HtmlEncode(L("taxExempt")) & "</span>"
            Case Else : Return "<span class=""fc-pay"" style=""color:#5B6B86"">—</span>"
        End Select
    End Function

    ''' <summary>Un point vert « Actif » ou gris « Inactif ».</summary>
    Public Function ActifCell(actif As Object) As String
        Dim ok As Boolean = Vrai(actif)
        Return "<span class=""fc-etat"" style=""color:" & If(ok, "#0F5A3A", "#5B6B86") & """><i class=""pt"" style=""background:" & If(ok, "#43B47A", "#AEBBCD") & """></i>" &
               Server.HtmlEncode(If(ok, L("actifOui"), L("actifNon"))) & "</span>"
    End Function

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
