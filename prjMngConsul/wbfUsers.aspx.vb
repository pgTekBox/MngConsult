Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class wbfUsers
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        ' Vérifier que l'utilisateur est connecté ET admin
        If Session("UserId") = "" Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If





        If Not isAdmin Then
            Response.Redirect("~/Default.aspx?err=admin_required")
            Return
        End If

        If Not IsPostBack Then
            rlvUsers.Rebind()
        End If
    End Sub

    Private Sub rlvUsers_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvUsers.NeedDataSource
        rlvUsers.DataSource = GetData()
    End Sub

    Private Sub rlvUsers_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvUsers.ItemCommand
        Select Case e.CommandName
            Case "DeleteUser"
                Dim id As String = ""
                Integer.TryParse(e.CommandArgument.ToString(), id)
                If id > 0 Then
                    ' Empêcher de se supprimer soi-même
                    If UserId IsNot Nothing AndAlso UserId = id Then
                        ' On pourrait afficher un message
                    Else
                        DeleteUser(id)
                        rlvUsers.Rebind()
                    End If
                End If
        End Select
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvUsers.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvUsers.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If e.Argument = "refreshgrid" Then
            rlvUsers.Rebind()
        End If
    End Sub

    Private Function GetData() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Search", tbSearch.Text.Trim()))
        Dim ds As DataSet = ExecuteSQLds("s0202GetUsersList", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Sub DeleteUser(id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@ModifiedBy", If(Session("UserEmail"), "")))
        ExecuteSQL("s0205DeleteUser", p)
    End Sub

    ''' <summary>
    ''' Génère les initiales pour l'avatar.
    ''' Utilisé depuis le markup avec Eval.
    ''' </summary>
    Public Function GetInitials(firstName As Object, lastName As Object, email As Object) As String
        Dim fn As String = If(firstName Is Nothing OrElse firstName Is DBNull.Value, "", firstName.ToString().Trim())
        Dim ln As String = If(lastName Is Nothing OrElse lastName Is DBNull.Value, "", lastName.ToString().Trim())

        If fn.Length > 0 AndAlso ln.Length > 0 Then
            Return (fn.Substring(0, 1) & ln.Substring(0, 1)).ToUpper()
        ElseIf fn.Length > 0 Then
            Return fn.Substring(0, 1).ToUpper()
        End If

        Dim em As String = If(email Is Nothing OrElse email Is DBNull.Value, "?", email.ToString())
        If em.Length > 0 Then Return em.Substring(0, 1).ToUpper()
        Return "?"
    End Function

End Class
