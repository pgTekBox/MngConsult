Imports System.Collections.Generic
Imports System.Data
Imports System.Linq
Imports System.Text
Imports Telerik.Web.UI

Public Class wbfPlanComptable
    Inherits clsData

    Private _currentFilter As String = "ALL"

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        ApplyLocalization()

        If Not IsPostBack Then
            ViewState("Filter") = "ALL"
            rlvComptes.Rebind()
        ElseIf Request("__EVENTTARGET") = "rlvComptes" AndAlso Request("__EVENTARGUMENT") = "Rebind" Then
            ' La fenêtre d'édition vient de se fermer : rwCompte_OnClientClose
            ' lance __doPostBack("rlvComptes", "Rebind"). Le RadListView ne
            ' traite pas cet argument de lui-même — sans ce relais, la liste
            ' restait telle quelle après l'ajout d'un compte.
            rlvComptes.Rebind()
        End If
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal dans RAP1.</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
        SetLiteral(Me, "litRubrique", L("rubrique"))
        SetLiteral(Me, "litSousTitre", L("sousTitre"))
        SetLiteral(Me, "litAfficher", L("afficher"))
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
            Case "addCompte" : Return Choose3(lang, "+ Ajouter un compte", "+ Add an account", "+ Agregar una cuenta")
            Case "searchPh" : Return Choose3(lang, "Chercher un numéro ou un nom de compte", "Search an account number or name", "Buscar un número o un nombre de cuenta")
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
            Case "empty" : Return Choose3(lang, "Aucun compte ne correspond.", "No account matches.", "Ninguna cuenta coincide.")
            Case "winTitle" : Return Choose3(lang, "Ajouter / Modifier un compte", "Add / Edit an account", "Agregar / Editar una cuenta")
            Case "addCompteWin" : Return Choose3(lang, "Ajouter un compte", "Add an account", "Agregar una cuenta")
            Case "editCompteWin" : Return Choose3(lang, "Modifier un compte", "Edit an account", "Editar una cuenta")
            Case "compteCount" : Return Choose3(lang, "compte(s)", "account(s)", "cuenta(s)")
            Case "rubrique" : Return Choose3(lang, "Comptabilité", "Accounting", "Contabilidad")
            Case "sousTitre" : Return Choose3(lang, "Vos comptes de bilan et de résultats, avec leurs classes et leur sens.", "Your balance sheet and income statement accounts, with their classes and direction.", "Sus cuentas de balance y de resultados, con sus clases y su sentido.")
            Case "afficher" : Return Choose3(lang, "Afficher", "Show", "Mostrar")
            Case "kpiActifs" : Return Choose3(lang, "Comptes actifs", "Active accounts", "Cuentas activas")
            Case "kpiActifsSub" : Return Choose3(lang, "utilisables dans les écritures", "usable in entries", "utilizables en los asientos")
            Case "kpiBilan" : Return Choose3(lang, "Bilan", "Balance sheet", "Balance")
            Case "kpiBilanSub" : Return Choose3(lang, "actif, passif, capitaux", "assets, liabilities, equity", "activo, pasivo, capital")
            Case "kpiResultat" : Return Choose3(lang, "Résultats", "Income statement", "Resultados")
            Case "kpiResultatSub" : Return Choose3(lang, "revenus et charges", "revenues and expenses", "ingresos y gastos")
            Case "kpiInactifs" : Return Choose3(lang, "Inactifs", "Inactive", "Inactivas")
            Case "kpiInactifsSub" : Return Choose3(lang, "retirés du choix", "removed from the choice", "retiradas de la elección")
            Case "actifOui" : Return Choose3(lang, "Actif", "Active", "Activa")
            Case "actifNon" : Return Choose3(lang, "Inactif", "Inactive", "Inactiva")
            Case "pied" : Return Choose3(lang, "{0} sur {1} comptes", "{0} of {1} accounts", "{0} de {1} cuentas")
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

    ' =====================================================================
    ' Les indicateurs (actifs / bilan / résultats / inactifs) — bilan et résultats
    ' posent le même filtre que les pastilles — et les cellules au style du gabarit.
    ' Les décomptes se font sur tout le plan, sans recherche ni filtre.
    ' =====================================================================

    Private TotalComptes As Integer

    ''' <summary>Un indicateur cliqué (hfChip = « kpi|BILAN|RESULTAT ») : un second clic revient à Tous.</summary>
    Protected Sub btnChip_Click(sender As Object, e As EventArgs) Handles btnChip.Click
        Dim v As String = If(hfChip.Value, "")
        hfChip.Value = ""
        Dim i As Integer = v.IndexOf("|"c)
        If i < 0 Then Return
        Dim valeur As String = v.Substring(i + 1).Trim().ToUpperInvariant()
        If valeur <> "BILAN" AndAlso valeur <> "RESULTAT" Then Return
        Dim courant As String = If(ViewState("Filter") IsNot Nothing, ViewState("Filter").ToString(), "ALL")
        Dim nouveau As String = If(courant = valeur, "ALL", valeur)
        ViewState("Filter") = nouveau
        SetActiveFilter(If(nouveau = "BILAN", btnFilterBilan, If(nouveau = "RESULTAT", btnFilterResultat, btnFilterAll)))
        rlvComptes.Rebind()
    End Sub

    Private Shared Function Vrai(o As Object) As Boolean
        If o Is Nothing OrElse IsDBNull(o) Then Return False
        Try
            Return Convert.ToBoolean(o)
        Catch
            Return False
        End Try
    End Function

    Private Function LireTout() As List(Of DataRow)
        Try
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Search", ""))
            p.Add(New SqlClient.SqlParameter("@Filtre", "ALL"))
            p.Add(New SqlClient.SqlParameter("@Lang", CurrentLang))
            Dim ds As DataSet = ExecuteSQLds("s0048GetPlanComptable", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0).Rows.Cast(Of DataRow)().ToList()
        Catch
        End Try
        Return New List(Of DataRow)
    End Function

    Private Sub ChargerIndicateurs()
        Dim rows As List(Of DataRow) = LireTout()
        TotalComptes = rows.Count
        Dim actifs As Integer = rows.Where(Function(r) Vrai(r("Actif"))).Count()
        Dim bilan As Integer = rows.Where(Function(r) Convert.ToString(r("GroupeEtatFinancier")) = "BILAN").Count()
        Dim resultat As Integer = rows.Where(Function(r) Convert.ToString(r("GroupeEtatFinancier")) = "RESULTAT").Count()
        Dim filtre As String = If(ViewState("Filter") IsNot Nothing, ViewState("Filter").ToString(), "ALL")

        Dim sb As New StringBuilder()
        sb.Append(Kpi("", L("kpiActifs"), actifs & " / " & rows.Count, L("kpiActifsSub"), "#43B47A", False))
        sb.Append(Kpi("BILAN", L("kpiBilan"), bilan.ToString(), L("kpiBilanSub"), "#1B4F9C", filtre = "BILAN"))
        sb.Append(Kpi("RESULTAT", L("kpiResultat"), resultat.ToString(), L("kpiResultatSub"), "#0F5A3A", filtre = "RESULTAT"))
        sb.Append(Kpi("", L("kpiInactifs"), (rows.Count - actifs).ToString(), L("kpiInactifsSub"), "#AEBBCD", False))
        SetLiteral(Me, "litKpis", sb.ToString())
    End Sub

    Private Function Kpi(valeur As String, lab As String, val As String, sub_ As String, point As String, actif As Boolean) As String
        Dim corps As String = "<span class=""lab""><i style=""background:" & point & """></i>" & Server.HtmlEncode(lab) & "</span>" &
                              "<span class=""val"">" & Server.HtmlEncode(val) & "</span><span class=""sub"">" & Server.HtmlEncode(sub_) & "</span>"
        If valeur = "" Then Return "<div class=""fc-kpi"">" & corps & "</div>"
        Return "<button type=""button"" class=""fc-kpi" & If(actif, " on", "") & """ aria-pressed=""" & If(actif, "true", "false") &
               """ onclick=""fcChip('kpi','" & valeur & "')"">" & corps & "</button>"
    End Function

    ''' <summary>Le nom en gras, le code de sous-classe dessous.</summary>
    Public Function NomCell(nom As Object, classeCode As Object) As String
        Dim c As String = Convert.ToString(classeCode).Trim()
        Return "<b>" & Server.HtmlEncode(Convert.ToString(nom)) & "</b>" & If(c <> "", "<span>" & Server.HtmlEncode(c) & "</span>", "")
    End Function

    Public Function TypePill(groupe As Object) As String
        Dim g As String = Convert.ToString(groupe).Trim().ToUpperInvariant()
        If g = "BILAN" Then Return "<span class=""fc-pay"" style=""background:#E8EDF5;color:#143A73"">" & Server.HtmlEncode(L("filterBilan")) & "</span>"
        If g = "RESULTAT" Then Return "<span class=""fc-pay"" style=""background:#E3F3EA;color:#0F5A3A"">" & Server.HtmlEncode(L("filterResultat")) & "</span>"
        Return "<span class=""fc-pay"" style=""color:#5B6B86"">—</span>"
    End Function

    Public Function SensPill(sens As Object) As String
        Dim s As String = Convert.ToString(sens).Trim().ToUpperInvariant()
        If s = "D" Then Return "<span class=""fc-pay"" style=""background:#FBF1DC;color:#7A5200"">" & Server.HtmlEncode(L("debit")) & "</span>"
        If s = "" Then Return "<span class=""fc-pay"" style=""color:#5B6B86"">—</span>"
        Return "<span class=""fc-pay"" style=""background:#E3EBF7;color:#143A73"">" & Server.HtmlEncode(L("credit")) & "</span>"
    End Function

    ''' <summary>Un point vert « Actif » ou gris « Inactif ».</summary>
    Public Function ActifCell(actif As Object) As String
        Dim ok As Boolean = Vrai(actif)
        Return "<span class=""fc-etat"" style=""color:" & If(ok, "#0F5A3A", "#5B6B86") & """><i class=""pt"" style=""background:" & If(ok, "#43B47A", "#AEBBCD") & """></i>" &
               Server.HtmlEncode(If(ok, L("actifOui"), L("actifNon"))) & "</span>"
    End Function

    ''' <summary>Libellé Débit/Crédit selon le sens du compte (data-bound).</summary>
    Public Function SensLabel(sens As Object) As String
        If sens Is Nothing OrElse IsDBNull(sens) Then Return ""
        If sens.ToString() = "D" Then Return L("debit")
        Return L("credit")
    End Function

    Private Sub rlvComptes_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvComptes.NeedDataSource
        ChargerIndicateurs()
        Dim dt As DataTable = GetData()
        rlvComptes.DataSource = dt
        SetLiteral(Me, "litPied", Server.HtmlEncode(String.Format(L("pied"), If(dt Is Nothing, 0, dt.Rows.Count), TotalComptes)))
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
        btnFilterAll.CssClass = "fc-pill"
        btnFilterBilan.CssClass = "fc-pill"
        btnFilterResultat.CssClass = "fc-pill"
        activeBtn.CssClass = "fc-pill on"
    End Sub

    ' ── Recherche ──

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvComptes.Rebind()
    End Sub

    Protected Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        ViewState("Filter") = "ALL"
        SetActiveFilter(btnFilterAll)
        rlvComptes.Rebind()
    End Sub

End Class
