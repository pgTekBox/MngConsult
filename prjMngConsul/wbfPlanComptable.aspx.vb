Imports Telerik.Web.UI

Public Class wbfPlanComptable
    Inherits clsData

    Private _currentFilter As String = "ALL"

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ViewState("Filter") = "ALL"
            rlvComptes.Rebind()
        End If
    End Sub

    Private Sub rlvComptes_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvComptes.NeedDataSource
        Dim dt As DataTable = GetData()
        rlvComptes.DataSource = dt

        If dt IsNot Nothing Then
            lblInfo.Text = dt.Rows.Count & " compte(s)"
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
