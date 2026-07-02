Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class wbfUsers
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            LoadCompanies()
            ' Contexte de compagnie = sélection courante du DDL
            ApplySelectedCompany()
            rlvUsers.Rebind()
        End If
    End Sub

    ''' <summary>
    ''' Remplit le sélecteur de compagnie (procédure s0620GetAllCompanies).
    ''' </summary>
    Private Sub LoadCompanies()
        Dim ds As DataSet = ExecuteSQLds("s0620GetAllCompanies")
        ddlCompany.Items.Clear()
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            ddlCompany.DataSource = ds.Tables(0)
            ddlCompany.DataBind()
        End If

        ' Restaurer la compagnie déjà choisie (session) si présente dans la liste.
        If Company <> Guid.Empty Then
            Dim item As ListItem = ddlCompany.Items.FindByValue(Company.ToString())
            If item IsNot Nothing Then
                ddlCompany.ClearSelection()
                item.Selected = True
            End If
        End If
    End Sub

    ''' <summary>
    ''' Mémorise en session la compagnie sélectionnée dans le DDL.
    ''' </summary>
    Private Sub ApplySelectedCompany()
        Dim g As Guid
        If Guid.TryParse(ddlCompany.SelectedValue, g) Then
            Company = g
        Else
            Company = Guid.Empty
        End If
    End Sub

    Private Sub ddlCompany_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlCompany.SelectedIndexChanged
        ApplySelectedCompany()
        rlvUsers.Rebind()
    End Sub

    Private Sub rlvUsers_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvUsers.NeedDataSource
        rlvUsers.DataSource = GetData()
    End Sub

    Private Sub rlvUsers_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvUsers.ItemCommand
        Select Case e.CommandName
            Case "DeleteUser"
                Dim id As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), id)
                If id > 0 Then
                    DeleteUser(id)
                    rlvUsers.Rebind()
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
        ' Sans compagnie sélectionnée, on ne charge rien (liste vide).
        If Company = Guid.Empty Then Return Nothing

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
        p.Add(New SqlParameter("@ModifiedBy", UserEmail))
        ExecuteSQL("s0205DeleteUser", p)
    End Sub

    ''' <summary>
    ''' Génère les initiales pour l'avatar. Utilisé depuis le markup avec Eval.
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
