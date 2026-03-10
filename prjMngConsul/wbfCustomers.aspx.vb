Imports Microsoft.Ajax.Utilities
Imports Telerik.Web.UI

Public Class wbfCustomers
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load


        If Not IsPostBack Then
            rlvClients.Rebind()
        End If
    End Sub



    Private Sub rlvClients_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvClients.NeedDataSource
        Dim dt As DataTable = GetData()
        rlvClients.DataSource = dt

        'lblInfo.Visible = True
        'lblInfo.Text = $"{If(dt IsNot Nothing, dt.Rows.Count, 0)} reçu(s)"
    End Sub

    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))

        Dim ds As DataSet = ExecuteSQLds("s0010GetCustomers", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function
End Class