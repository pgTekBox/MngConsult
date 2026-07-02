Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class wbfCompanies
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            rlvCompanies.Rebind()
        End If
    End Sub

    Private Sub rlvCompanies_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvCompanies.NeedDataSource
        rlvCompanies.DataSource = GetData()
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvCompanies.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvCompanies.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If e.Argument = "refreshgrid" Then rlvCompanies.Rebind()
    End Sub

    Private Function GetData() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@Search", tbSearch.Text.Trim()))
        Dim ds As DataSet = ExecuteSQLds("s0653GetCompaniesList", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Public Function GetInitials(name As Object) As String
        Dim nm As String = If(name Is Nothing OrElse name Is DBNull.Value, "", name.ToString().Trim())
        If nm.Length > 0 Then Return nm.Substring(0, 1).ToUpper()
        Return "?"
    End Function

    Public Function GetStatusClass(status As Object) As String
        Dim s As String = If(status Is Nothing OrElse status Is DBNull.Value, "", status.ToString().ToLower())
        Select Case s
            Case "active" : Return "active"
            Case "trial" : Return "trial"
            Case "cancelled", "canceled", "expired" : Return "cancelled"
            Case "" : Return "none"
            Case Else : Return "trial"
        End Select
    End Function

    Public Function GetStatusLabel(status As Object) As String
        Dim s As String = If(status Is Nothing OrElse status Is DBNull.Value, "", status.ToString().ToLower())
        Select Case s
            Case "active" : Return "Actif"
            Case "trial" : Return "Essai"
            Case "cancelled", "canceled" : Return "Annulé"
            Case "expired" : Return "Expiré"
            Case "" : Return "Aucun"
            Case Else : Return status.ToString()
        End Select
    End Function

End Class
