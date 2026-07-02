Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class wbfAdmins
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            rlvAdmins.Rebind()
        End If
    End Sub

    Private Sub rlvAdmins_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvAdmins.NeedDataSource
        rlvAdmins.DataSource = GetData()
    End Sub

    Private Sub rlvAdmins_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvAdmins.ItemCommand
        Select Case e.CommandName
            Case "DeleteAdmin"
                Dim id As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), id)
                ' Empêcher de se supprimer soi-même
                If id > 0 AndAlso id <> AdminId Then
                    DeleteAdmin(id)
                    rlvAdmins.Rebind()
                End If
        End Select
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvAdmins.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvAdmins.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If e.Argument = "refreshgrid" Then
            rlvAdmins.Rebind()
        End If
    End Sub

    Private Function GetData() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@Search", tbSearch.Text.Trim()))
        Dim ds As DataSet = ExecuteSQLds("s0646GetAdminsList", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Sub DeleteAdmin(id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@ModifiedBy", UserEmail))
        ExecuteSQL("s0649DeleteAdmin", p)
    End Sub

    Public Function GetInitials(firstName As Object, lastName As Object, email As Object) As String
        Dim fn As String = If(firstName Is Nothing OrElse firstName Is DBNull.Value, "", firstName.ToString().Trim())
        Dim ln As String = If(lastName Is Nothing OrElse lastName Is DBNull.Value, "", lastName.ToString().Trim())
        If fn.Length > 0 AndAlso ln.Length > 0 Then Return (fn.Substring(0, 1) & ln.Substring(0, 1)).ToUpper()
        If fn.Length > 0 Then Return fn.Substring(0, 1).ToUpper()
        Dim em As String = If(email Is Nothing OrElse email Is DBNull.Value, "?", email.ToString())
        If em.Length > 0 Then Return em.Substring(0, 1).ToUpper()
        Return "?"
    End Function

End Class
