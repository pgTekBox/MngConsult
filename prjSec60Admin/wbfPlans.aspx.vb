Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class wbfPlans
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            rlvPlans.Rebind()
        End If
    End Sub

    Private Sub rlvPlans_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvPlans.NeedDataSource
        rlvPlans.DataSource = GetData()
    End Sub

    Private Sub rlvPlans_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvPlans.ItemCommand
        Select Case e.CommandName
            Case "DeletePlan"
                Dim id As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), id)
                If id > 0 Then
                    DeletePlan(id)
                    rlvPlans.Rebind()
                End If
        End Select
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvPlans.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvPlans.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If e.Argument = "refreshgrid" Then
            rlvPlans.Rebind()
        End If
    End Sub

    Private Function GetData() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@Search", tbSearch.Text.Trim()))
        Dim ds As DataSet = ExecuteSQLds("s0632GetPlansList", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Sub DeletePlan(id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@ModifiedBy", UserEmail))
        ExecuteSQL("s0635DeletePlan", p)
    End Sub

    ''' <summary>
    ''' Initiales pour l'icône du forfait (nom, sinon code).
    ''' </summary>
    Public Function GetInitials(name As Object, code As Object) As String
        Dim nm As String = If(name Is Nothing OrElse name Is DBNull.Value, "", name.ToString().Trim())
        If nm.Length > 0 Then Return nm.Substring(0, 1).ToUpper()
        Dim cd As String = If(code Is Nothing OrElse code Is DBNull.Value, "?", code.ToString())
        If cd.Length > 0 Then Return cd.Substring(0, 1).ToUpper()
        Return "?"
    End Function

    ''' <summary>
    ''' Formate le montant avec 2 décimales.
    ''' </summary>
    Public Function FormatAmount(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then Return "0.00"
        Return CDec(value).ToString("N2", Globalization.CultureInfo.InvariantCulture)
    End Function

    ''' <summary>
    ''' Libellé lisible du cycle de facturation.
    ''' </summary>
    Public Function GetCycleLabel(value As Object) As String
        Dim s As String = If(value Is Nothing OrElse value Is DBNull.Value, "", value.ToString().ToLower())
        Select Case s
            Case "monthly" : Return "Mensuel"
            Case "annual", "yearly" : Return "Annuel"
            Case "weekly" : Return "Hebdo"
            Case Else : Return If(s = "", "—", value.ToString())
        End Select
    End Function

End Class
