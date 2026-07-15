Imports Telerik.Web.UI

Public Class wbfProductCategory
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ApplyLocalization()

        If Not IsPostBack Then
            rlvCategories.Rebind()
        End If
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal dans RAP1.</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
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
            Case "addCategory" : Return Choose3(lang, "Ajouter une catégorie", "Add a category", "Agregar una categoría")
            Case "searchPh" : Return Choose3(lang, "Rechercher (code, nom…)", "Search (code, name…)", "Buscar (código, nombre…)")
            Case "colCode" : Return Choose3(lang, "Code", "Code", "Código")
            Case "colName" : Return Choose3(lang, "Nom", "Name", "Nombre")
            Case "colSaleAccount" : Return Choose3(lang, "Compte vente", "Sales account", "Cuenta de venta")
            Case "colPurchaseAccount" : Return Choose3(lang, "Compte achat", "Purchase account", "Cuenta de compra")
            Case "colTaxe" : Return Choose3(lang, "Taxe", "Tax", "Impuesto")
            Case "colActive" : Return Choose3(lang, "Actif", "Active", "Activo")
            Case "colAction" : Return Choose3(lang, "Action", "Action", "Acción")
            Case "empty" : Return Choose3(lang, "Aucune catégorie trouvée.", "No category found.", "Ninguna categoría encontrada.")
            Case "winTitle" : Return Choose3(lang, "Ajouter / Modifier une catégorie", "Add / Edit a category", "Agregar / Editar una categoría")
            Case "addCategoryWin" : Return Choose3(lang, "Ajouter une catégorie", "Add a category", "Agregar una categoría")
            Case "editCategoryWin" : Return Choose3(lang, "Modifier une catégorie", "Edit a category", "Editar una categoría")
            Case "categoryCount" : Return Choose3(lang, "catégorie(s)", "category(ies)", "categoría(s)")
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
        Dim dt As DataTable = GetData()
        rlvCategories.DataSource = dt

        If dt IsNot Nothing Then
            lblInfo.Text = dt.Rows.Count & " " & L("categoryCount")
        End If
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
        rlvCategories.Rebind()
    End Sub

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
