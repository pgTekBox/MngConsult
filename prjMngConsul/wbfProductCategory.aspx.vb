Imports Telerik.Web.UI

Public Class wbfProductCategory
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then

            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            rlvCategories.Rebind()
        End If
    End Sub

    Private Sub rlvCategories_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvCategories.NeedDataSource
        Dim dt As DataTable = GetData()
        rlvCategories.DataSource = dt

        If dt IsNot Nothing Then
            lblInfo.Text = dt.Rows.Count & " catégorie(s)"
        End If
    End Sub

    Private Sub rlvCategories_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvCategories.ItemCommand
        If e.CommandArgument Is Nothing Then Return

        Select Case e.CommandName
            Case "DeleteCategory"
                Dim catId As Integer = CInt(e.CommandArgument)
                DeleteCategory(catId)
                rlvCategories.Rebind()
        End Select
    End Sub

    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", q))

        Dim ds As DataSet = ExecuteSQLds("s0056GetProductCategories", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Sub DeleteCategory(catId As Integer)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Id", catId))
        ExecuteSQL("s0058DeleteProductCategory", p)
    End Sub

    ' ── Recherche ──

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvCategories.Rebind()
    End Sub

    Protected Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvCategories.Rebind()
    End Sub

    ' ── Helpers pour badges de taxe ──

    Public Function GetTaxeBadgeClass(taxeStatus As Object) As String
        If taxeStatus Is Nothing OrElse IsDBNull(taxeStatus) Then Return "badge-zero"
        Select Case CInt(taxeStatus)
            Case 1 : Return "badge-taxable"
            Case 2 : Return "badge-exempt"
            Case Else : Return "badge-zero"
        End Select
    End Function

    Public Function GetTaxeLabel(taxeStatus As Object) As String
        If taxeStatus Is Nothing OrElse IsDBNull(taxeStatus) Then Return "—"
        Select Case CInt(taxeStatus)
            Case 1 : Return "Taxable"
            Case 2 : Return "Exempt"
            Case Else : Return "—"
        End Select
    End Function

End Class
