Imports Microsoft.Ajax.Utilities
Imports Telerik.Web.UI

Public Class wbfCustomers
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load


        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            rlvClients.Rebind()
        End If
    End Sub



    Private Sub rlvClients_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvClients.NeedDataSource
        Dim dt As DataTable = GetData()
        rlvClients.DataSource = dt

    End Sub


    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvClients.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvClients.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        ' e.Argument contient "refreshgrid"
        If e.Argument = "refreshgrid" Then
            rlvClients.Rebind() ' ← recharge la liste après fermeture de la fenêtre
        End If
    End Sub

    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", q))
        Dim ds As DataSet = ExecuteSQLds("s0010GetCustomers", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function
End Class