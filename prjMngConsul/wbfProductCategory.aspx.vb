Imports System.Collections.Generic
Imports System.Data
Imports System.Linq
Imports System.Text
Imports Telerik.Web.UI

Public Class wbfProductCategory
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        ApplyLocalization()

        If Not IsPostBack Then
            rlvCategories.Rebind()
        End If
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal dans RAP1.</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
        litRubrique.Text = L("rubrique")
        litSousTitre.Text = L("sousTitre")
        btnAdd.Text = L("addCategory")
        tbSearch.Attributes("placeholder") = L("searchPh")
        rwCategory.Title = L("winTitle")

        Dim fab As Control = FindDeep(Me, "fabAdd")
        If TypeOf fab Is System.Web.UI.HtmlControls.HtmlControl Then
            CType(fab, System.Web.UI.HtmlControls.HtmlControl).Attributes("title") = L("addCategoryWin")
        End If
    End Sub

    ''' <summary>Libellés du LayoutTemplate / EmptyDataTemplate du RadListView (via Literal).</summary>
    Private Sub rlvCategories_PreRender(sender As Object, e As EventArgs) Handles rlvCategories.PreRender
        SetLiteral(rlvCategories, "litColCode", L("colCode"))
        SetLiteral(rlvCategories, "litColName", L("colName"))
        SetLiteral(rlvCategories, "litColSaleAccount", L("colSaleAccount"))
        SetLiteral(rlvCategories, "litColPurchaseAccount", L("colPurchaseAccount"))
        SetLiteral(rlvCategories, "litColTaxe", L("colTaxe"))
        SetLiteral(rlvCategories, "litColActive", L("colActive"))
        SetLiteral(rlvCategories, "litColAction", L("colAction"))
        SetLiteral(rlvCategories, "litEmpty", L("empty"))
    End Sub

    ''' <summary>Traductions de l'interface Catégories de produits (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Catégories de produits — 60Sec-AI", "Product categories — 60Sec-AI", "Categorías de productos — 60Sec-AI")
            Case "pageTitleShort" : Return Choose3(lang, "Catégories de produits", "Product categories", "Categorías de productos")
            Case "addCategory" : Return Choose3(lang, "+ Ajouter une catégorie", "+ Add a category", "+ Agregar una categoría")
            Case "searchPh" : Return Choose3(lang, "Chercher un code ou un nom", "Search a code or a name", "Buscar un código o un nombre")
            Case "colCode" : Return Choose3(lang, "Code", "Code", "Código")
            Case "colName" : Return Choose3(lang, "Nom", "Name", "Nombre")
            Case "colSaleAccount" : Return Choose3(lang, "Compte vente", "Sales account", "Cuenta de venta")
            Case "colPurchaseAccount" : Return Choose3(lang, "Compte achat", "Purchase account", "Cuenta de compra")
            Case "colTaxe" : Return Choose3(lang, "Taxe", "Tax", "Impuesto")
            Case "colActive" : Return Choose3(lang, "Actif", "Active", "Activo")
            Case "colAction" : Return Choose3(lang, "Action", "Action", "Acción")
            Case "empty" : Return Choose3(lang, "Aucune catégorie ne correspond.", "No category matches.", "Ninguna categoría coincide.")
            Case "winTitle" : Return Choose3(lang, "Ajouter / Modifier une catégorie", "Add / Edit a category", "Agregar / Editar una categoría")
            Case "addCategoryWin" : Return Choose3(lang, "Ajouter une catégorie", "Add a category", "Agregar una categoría")
            Case "editCategoryWin" : Return Choose3(lang, "Modifier une catégorie", "Edit a category", "Editar una categoría")
            Case "categoryCount" : Return Choose3(lang, "catégorie(s)", "category(ies)", "categoría(s)")
            Case "rubrique" : Return Choose3(lang, "Produits et services", "Products and services", "Productos y servicios")
            Case "sousTitre" : Return Choose3(lang, "Regroupez vos produits et donnez-leur d'avance leurs comptes et leur taxe.", "Group your products and give them their accounts and tax in advance.", "Agrupe sus productos y asígneles de antemano sus cuentas y su impuesto.")
            Case "kpiActives" : Return Choose3(lang, "Catégories actives", "Active categories", "Categorías activas")
            Case "kpiActivesSub" : Return Choose3(lang, "offertes dans les fiches", "offered in the records", "ofrecidas en las fichas")
            Case "kpiInactives" : Return Choose3(lang, "Inactives", "Inactive", "Inactivas")
            Case "kpiInactivesSub" : Return Choose3(lang, "retirées du choix", "removed from the choice", "retiradas de la elección")
            Case "kpiSansCompte" : Return Choose3(lang, "Sans compte", "Without account", "Sin cuenta")
            Case "kpiSansCompteSub" : Return Choose3(lang, "vente ou achat à régler", "sales or purchase to set", "venta o compra por definir")
            Case "kpiProduits" : Return Choose3(lang, "Produits", "Products", "Productos")
            Case "kpiProduitsSub" : Return Choose3(lang, "ouvrir le catalogue", "open the catalog", "abrir el catálogo")
            Case "manque" : Return Choose3(lang, "À compléter : {0}", "To complete: {0}", "Por completar: {0}")
            Case "mVente" : Return Choose3(lang, "compte vente", "sales account", "cuenta de venta")
            Case "mAchat" : Return Choose3(lang, "compte achat", "purchase account", "cuenta de compra")
            Case "actifOui" : Return Choose3(lang, "Active", "Active", "Activa")
            Case "actifNon" : Return Choose3(lang, "Inactive", "Inactive", "Inactiva")
            Case "pied" : Return Choose3(lang, "{0} sur {1} catégories", "{0} of {1} categories", "{0} de {1} categorías")
            Case "taxTaxable" : Return Choose3(lang, "Taxable", "Taxable", "Gravable")
            Case "taxExempt" : Return Choose3(lang, "Exempt", "Exempt", "Exento")
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

    Private Sub rlvCategories_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvCategories.NeedDataSource
        ChargerIndicateurs()
        Dim dt As DataTable = Filtrer(GetData())
        rlvCategories.DataSource = dt
        litPied.Text = Server.HtmlEncode(String.Format(L("pied"), If(dt Is Nothing, 0, dt.Rows.Count), TotalCategories))
    End Sub

    Private Sub rlvCategories_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvCategories.ItemCommand
        If e.CommandArgument Is Nothing Then Return

        Select Case e.CommandName
            Case "DeleteCategory"
                Dim catId As Integer = CInt(e.CommandArgument)
                DeleteCategory(catId)
                rlvCategories.Rebind()
        End Select
    End Sub

    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", q))

        Dim ds As DataSet = ExecuteSQLds("s0056GetProductCategories", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Sub DeleteCategory(catId As Integer)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Id", catId))
        ExecuteSQL("s0058DeleteProductCategory", p)
    End Sub

    ' ── Recherche ──

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvCategories.Rebind()
    End Sub

    Protected Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        FiltreCourant = ""
        rlvCategories.Rebind()
    End Sub


    ' =====================================================================
    ' Les indicateurs (actives / inactives / sans compte / produits) et le
    ' filtre qu'ils posent, conservé en session. Les décomptes se font sur
    ' toutes les catégories, sans la recherche.
    ' =====================================================================

    Private Property FiltreCourant As String
        Get
            Return If(TryCast(Session("Cat.Filtre"), String), "")
        End Get
        Set(value As String)
            Session("Cat.Filtre") = value
        End Set
    End Property

    Private TotalCategories As Integer

    ''' <summary>Un indicateur cliqué (hfChip = « kpi|valeur ») : un second clic l'enlève.</summary>
    Protected Sub btnChip_Click(sender As Object, e As EventArgs) Handles btnChip.Click
        Dim v As String = If(hfChip.Value, "")
        hfChip.Value = ""
        Dim i As Integer = v.IndexOf("|"c)
        If i < 0 Then Return
        Dim valeur As String = v.Substring(i + 1).Trim().ToLowerInvariant()
        If v.Substring(0, i) = "kpi" Then FiltreCourant = If(FiltreCourant = valeur, "", valeur)
        rlvCategories.Rebind()
    End Sub

    Private Shared Function Vrai(o As Object) As Boolean
        If o Is Nothing OrElse IsDBNull(o) Then Return False
        Try
            Return Convert.ToBoolean(o)
        Catch
            Return False
        End Try
    End Function

    Private Shared Function Texte(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return Convert.ToString(o).Trim()
    End Function

    ''' <summary>Ce qui manque à une catégorie : le compte de vente, le compte d'achat.</summary>
    Private Function Manques(compteVente As Object, compteAchat As Object) As List(Of String)
        Dim m As New List(Of String)
        If Texte(compteVente) = "" Then m.Add(L("mVente"))
        If Texte(compteAchat) = "" Then m.Add(L("mAchat"))
        Return m
    End Function

    Private Function SansCompte(r As DataRow) As Boolean
        Return Manques(r("CompteVenteNumero"), r("CompteAchatNumero")).Count > 0
    End Function

    Private Function LireTout() As List(Of DataRow)
        Try
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Search", ""))
            Dim ds As DataSet = ExecuteSQLds("s0056GetProductCategories", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0).Rows.Cast(Of DataRow)().ToList()
        Catch
        End Try
        Return New List(Of DataRow)
    End Function

    Private Function CompterProduits() As Integer
        Try
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Search", ""))
            p.Add(New SqlClient.SqlParameter("@CategoryId", 0))
            Dim ds As DataSet = ExecuteSQLds("s0076GetProducts", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0).Rows.Count
        Catch
        End Try
        Return 0
    End Function

    Private Sub ChargerIndicateurs()
        Dim rows As List(Of DataRow) = LireTout()
        TotalCategories = rows.Count
        Dim actives As Integer = rows.Where(Function(r) Vrai(r("Actif"))).Count()
        Dim sansCpt As Integer = rows.Where(Function(r) SansCompte(r)).Count()

        Dim sb As New StringBuilder()
        sb.Append(Kpi("actives", L("kpiActives"), actives & " / " & rows.Count, L("kpiActivesSub"), "#43B47A"))
        sb.Append(Kpi("inactives", L("kpiInactives"), (rows.Count - actives).ToString(), L("kpiInactivesSub"), "#AEBBCD"))
        sb.Append(Kpi("sanscompte", L("kpiSansCompte"), sansCpt.ToString(), L("kpiSansCompteSub"), If(sansCpt > 0, "#E3B341", "#43B47A")))
        sb.Append("<a class=""fc-kpi"" href=""wbfProducts.aspx""><span class=""lab""><i style=""background:#1B4F9C""></i>" & Server.HtmlEncode(L("kpiProduits")) &
                  "</span><span class=""val"">" & CompterProduits() & "</span><span class=""sub"">" & Server.HtmlEncode(L("kpiProduitsSub")) & "</span></a>")
        litKpis.Text = sb.ToString()
    End Sub

    Private Function Kpi(valeur As String, lab As String, val As String, sub_ As String, point As String) As String
        Dim actif As Boolean = (FiltreCourant = valeur)
        Return "<button type=""button"" class=""fc-kpi" & If(actif, " on", "") & """ aria-pressed=""" & If(actif, "true", "false") &
               """ onclick=""fcChip('kpi','" & valeur & "')"">" &
               "<span class=""lab""><i style=""background:" & point & """></i>" & Server.HtmlEncode(lab) & "</span>" &
               "<span class=""val"">" & Server.HtmlEncode(val) & "</span>" &
               "<span class=""sub"">" & Server.HtmlEncode(sub_) & "</span></button>"
    End Function

    ''' <summary>Le filtre de l'indicateur posé, appliqué en mémoire.</summary>
    Private Function Filtrer(dt As DataTable) As DataTable
        If dt Is Nothing OrElse FiltreCourant = "" Then Return dt
        Dim rows As IEnumerable(Of DataRow) = dt.Rows.Cast(Of DataRow)()
        Select Case FiltreCourant
            Case "actives" : rows = rows.Where(Function(r) Vrai(r("Actif")))
            Case "inactives" : rows = rows.Where(Function(r) Not Vrai(r("Actif")))
            Case "sanscompte" : rows = rows.Where(Function(r) SansCompte(r))
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

    ''' <summary>Le nom en gras, la description dessous, puis ce qui manque (les comptes).</summary>
    Public Function NomCell(nom As Object, description As Object, compteVente As Object, compteAchat As Object) As String
        Dim sb As New StringBuilder()
        sb.Append("<b>").Append(Server.HtmlEncode(Texte(nom))).Append("</b>")
        Dim d As String = Texte(description)
        If d.Length > 80 Then d = d.Substring(0, 80) & "…"
        If d <> "" Then sb.Append("<span>").Append(Server.HtmlEncode(d)).Append("</span>")
        Dim m As List(Of String) = Manques(compteVente, compteAchat)
        If m.Count > 0 Then sb.Append("<em>● ").Append(Server.HtmlEncode(String.Format(L("manque"), String.Join(", ", m)))).Append("</em>")
        Return sb.ToString()
    End Function

    ''' <summary>Le numéro du compte en gras, son nom dessous ; un tiret s'il n'y en a pas.</summary>
    Public Function CompteCell(numero As Object, nom As Object) As String
        Dim n As String = Texte(numero)
        If n = "" Then Return "<span class=""rien"">—</span>"
        Return "<b>" & Server.HtmlEncode(n) & "</b><span>" & Server.HtmlEncode(Texte(nom)) & "</span>"
    End Function

    Public Function TaxePill(taxe As Object) As String
        Dim code As Integer = 0
        If taxe IsNot Nothing AndAlso Not IsDBNull(taxe) Then Integer.TryParse(Convert.ToString(taxe), code)
        Select Case code
            Case 1 : Return "<span class=""fc-pay"" style=""background:#E8EDF5;color:#143A73"">" & Server.HtmlEncode(L("taxTaxable")) & "</span>"
            Case 2 : Return "<span class=""fc-pay"" style=""background:#FBF1DC;color:#7A5200"">" & Server.HtmlEncode(L("taxExempt")) & "</span>"
            Case Else : Return "<span class=""fc-pay"" style=""color:#5B6B86"">—</span>"
        End Select
    End Function

    ''' <summary>Un point vert « Active » ou gris « Inactive ».</summary>
    Public Function ActifCell(actif As Object) As String
        Dim ok As Boolean = Vrai(actif)
        Return "<span class=""fc-etat"" style=""color:" & If(ok, "#0F5A3A", "#5B6B86") & """><i class=""pt"" style=""background:" & If(ok, "#43B47A", "#AEBBCD") & """></i>" &
               Server.HtmlEncode(If(ok, L("actifOui"), L("actifNon"))) & "</span>"
    End Function

    ' ── Helpers pour badges de taxe ──

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
