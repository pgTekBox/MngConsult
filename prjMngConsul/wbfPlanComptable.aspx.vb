Imports Telerik.Web.UI

Public Class wbfPlanComptable
    Inherits clsData

    Private _currentFilter As String = "ALL"

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ApplyLocalization()

        If Not IsPostBack Then
            ViewState("Filter") = "ALL"
            rlvComptes.Rebind()
        End If
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal dans RAP1.</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
        btnAdd.Text = L("addCompte")
        tbSearch.Attributes("placeholder") = L("searchPh")
        btnFilterAll.Text = L("filterAll")
        btnFilterBilan.Text = L("filterBilan")
        btnFilterResultat.Text = L("filterResultat")
        rwCompte.Title = L("winTitle")

        Dim fab As Control = FindDeep(Me, "fabAdd")
        If TypeOf fab Is System.Web.UI.HtmlControls.HtmlControl Then
            CType(fab, System.Web.UI.HtmlControls.HtmlControl).Attributes("title") = L("addCompteWin")
        End If
    End Sub

    ''' <summary>Libellés du LayoutTemplate / EmptyDataTemplate du RadListView (via Literal).</summary>
    Private Sub rlvComptes_PreRender(sender As Object, e As EventArgs) Handles rlvComptes.PreRender
        SetLiteral(rlvComptes, "litColNumero", L("colNumero"))
        SetLiteral(rlvComptes, "litColNom", L("colNom"))
        SetLiteral(rlvComptes, "litColClasse", L("colClasse"))
        SetLiteral(rlvComptes, "litColType", L("colType"))
        SetLiteral(rlvComptes, "litColSens", L("colSens"))
        SetLiteral(rlvComptes, "litColActif", L("colActif"))
        SetLiteral(rlvComptes, "litColAction", L("colAction"))
        SetLiteral(rlvComptes, "litEmpty", L("empty"))
    End Sub

    ''' <summary>Traductions de l'interface Plan comptable (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Plan comptable — 60Sec-AI", "Chart of accounts — 60Sec-AI", "Plan contable — 60Sec-AI")
            Case "pageTitleShort" : Return Choose3(lang, "Plan comptable", "Chart of accounts", "Plan contable")
            Case "addCompte" : Return Choose3(lang, "Ajouter un compte", "Add an account", "Agregar una cuenta")
            Case "searchPh" : Return Choose3(lang, "Rechercher (numéro, nom…)", "Search (number, name…)", "Buscar (número, nombre…)")
            Case "filterAll" : Return Choose3(lang, "Tous", "All", "Todos")
            Case "filterBilan" : Return Choose3(lang, "Bilan", "Balance sheet", "Balance")
            Case "filterResultat" : Return Choose3(lang, "Résultats", "Income statement", "Resultados")
            Case "colNumero" : Return Choose3(lang, "Numéro", "Number", "Número")
            Case "colNom" : Return Choose3(lang, "Nom du compte", "Account name", "Nombre de la cuenta")
            Case "colClasse" : Return Choose3(lang, "Classe", "Class", "Clase")
            Case "colType" : Return Choose3(lang, "Type", "Type", "Tipo")
            Case "colSens" : Return Choose3(lang, "Sens", "Direction", "Sentido")
            Case "colActif" : Return Choose3(lang, "Actif", "Active", "Activo")
            Case "colAction" : Return Choose3(lang, "Action", "Action", "Acción")
            Case "empty" : Return Choose3(lang, "Aucun compte trouvé.", "No account found.", "Ninguna cuenta encontrada.")
            Case "winTitle" : Return Choose3(lang, "Ajouter / Modifier un compte", "Add / Edit an account", "Agregar / Editar una cuenta")
            Case "addCompteWin" : Return Choose3(lang, "Ajouter un compte", "Add an account", "Agregar una cuenta")
            Case "editCompteWin" : Return Choose3(lang, "Modifier un compte", "Edit an account", "Editar una cuenta")
            Case "compteCount" : Return Choose3(lang, "compte(s)", "account(s)", "cuenta(s)")
            Case "debit" : Return Choose3(lang, "Débit", "Debit", "Débito")
            Case "credit" : Return Choose3(lang, "Crédit", "Credit", "Crédito")
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

    ''' <summary>Libellé Débit/Crédit selon le sens du compte (data-bound).</summary>
    Public Function SensLabel(sens As Object) As String
        If sens Is Nothing OrElse IsDBNull(sens) Then Return ""
        If sens.ToString() = "D" Then Return L("debit")
        Return L("credit")
    End Function

    Private Sub rlvComptes_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvComptes.NeedDataSource
        Dim dt As DataTable = GetData()
        rlvComptes.DataSource = dt

        If dt IsNot Nothing Then
            lblInfo.Text = dt.Rows.Count & " " & L("compteCount")
        End If
    End Sub

    Private Sub rlvComptes_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvComptes.ItemCommand
        If e.CommandArgument Is Nothing Then Return

        Select Case e.CommandName
            Case "DeleteCompte"
                Dim compteId As Integer = CInt(e.CommandArgument)
                DeleteCompte(compteId)
                rlvComptes.Rebind()
        End Select
    End Sub

    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()
        Dim filtre As String = If(ViewState("Filter") IsNot Nothing, ViewState("Filter").ToString(), "ALL")

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", q))
        p.Add(New SqlClient.SqlParameter("@Filtre", filtre))
        p.Add(New SqlClient.SqlParameter("@Lang", CurrentLang))

        Dim ds As DataSet = ExecuteSQLds("s0048GetPlanComptable", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Sub DeleteCompte(compteId As Integer)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Id", compteId))
        ExecuteSQL("s0050DeletePlanComptableCompte", p)
    End Sub

    ' ── Filtres rapides ──

    Protected Sub btnFilterAll_Click(sender As Object, e As EventArgs) Handles btnFilterAll.Click
        ViewState("Filter") = "ALL"
        SetActiveFilter(btnFilterAll)
        rlvComptes.Rebind()
    End Sub

    Protected Sub btnFilterBilan_Click(sender As Object, e As EventArgs) Handles btnFilterBilan.Click
        ViewState("Filter") = "BILAN"
        SetActiveFilter(btnFilterBilan)
        rlvComptes.Rebind()
    End Sub

    Protected Sub btnFilterResultat_Click(sender As Object, e As EventArgs) Handles btnFilterResultat.Click
        ViewState("Filter") = "RESULTAT"
        SetActiveFilter(btnFilterResultat)
        rlvComptes.Rebind()
    End Sub

    Private Sub SetActiveFilter(activeBtn As Button)
        btnFilterAll.CssClass = "filter-tab"
        btnFilterBilan.CssClass = "filter-tab"
        btnFilterResultat.CssClass = "filter-tab"
        activeBtn.CssClass = "filter-tab active"
    End Sub

    ' ── Recherche ──

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvComptes.Rebind()
    End Sub

    Protected Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvComptes.Rebind()
    End Sub

End Class
