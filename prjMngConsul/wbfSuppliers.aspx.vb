Imports Microsoft.Ajax.Utilities
Imports Telerik.Web.UI

Public Class wbfSuppliers
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load


        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            rlvSuppliers.Rebind()
        End If
    End Sub
    Private Sub rlvSuppliers_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvSuppliers.ItemCommand
        If e.CommandArgument Is Nothing Then Return

        Select Case e.CommandName
            Case "DeleteSupplier"
                Dim supplierId As Integer = CInt(e.CommandArgument)
                DeleteSupplier(supplierId)
                rlvSuppliers.Rebind()
        End Select
    End Sub

    Sub DeleteSupplier(supplierId As Integer)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@PartyId", supplierId))
        ExecuteSQL("s0316DeleteParty", p)
    End Sub
    Private Sub rlvSuppliers_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvSuppliers.NeedDataSource
        Dim dt As DataTable = GetData()
        rlvSuppliers.DataSource = dt

    End Sub


    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvSuppliers.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvSuppliers.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        ' e.Argument contient "refreshgrid"
        If e.Argument = "refreshgrid" Then
            rlvSuppliers.Rebind() ' ← recharge la liste après fermeture de la fenêtre
        End If
    End Sub

    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", q))
        Dim ds As DataSet = ExecuteSQLds("s0011GetSuppliers", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function
End Class