Imports Telerik.Web.UI

Public Class wbfProducts
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            BindFilterDDL()
            rlvProducts.Rebind()
        End If
    End Sub

    Private Sub BindFilterDDL()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        SetDDL(rddlFilterCat, "Name", "Value", "s0081GetCategoriesForDDL", p)
    End Sub

    Private Sub rlvProducts_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvProducts.NeedDataSource
        Dim dt As DataTable = GetData()
        rlvProducts.DataSource = dt

        If dt IsNot Nothing Then
            lblInfo.Text = dt.Rows.Count & " produit(s)"
        End If
    End Sub

    Private Sub rlvProducts_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvProducts.ItemCommand
        If e.CommandArgument Is Nothing Then Return

        Select Case e.CommandName
            Case "DeleteProduct"
                Dim prodId As Integer = CInt(e.CommandArgument)
                DeleteProduct(prodId)
                rlvProducts.Rebind()
        End Select
    End Sub

    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()
        Dim catId As Integer = 0
        If Not String.IsNullOrEmpty(rddlFilterCat.SelectedValue) Then
            Integer.TryParse(rddlFilterCat.SelectedValue, catId)
        End If

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", q))
        p.Add(New SqlClient.SqlParameter("@CategoryId", catId))

        Dim ds As DataSet = ExecuteSQLds("s0076GetProducts", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Sub DeleteProduct(prodId As Integer)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Id", prodId))
        ExecuteSQL("s0078DeleteProduct", p)
    End Sub

    ' ── Filtre catégorie ──

    Protected Sub rddlFilterCat_SelectedIndexChanged(sender As Object, e As DropDownListEventArgs) Handles rddlFilterCat.SelectedIndexChanged
        rlvProducts.Rebind()
    End Sub

    ' ── Recherche ──

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvProducts.Rebind()
    End Sub

    Protected Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rddlFilterCat.ClearSelection()
        rlvProducts.Rebind()
    End Sub

    ' ── Helpers ──

    Public Function FormatPrix(prix As Object) As String
        If prix Is Nothing OrElse IsDBNull(prix) Then Return "—"
        Return CDec(prix).ToString("N2") & " $"
    End Function

    Public Function FormatQty(qty As Object) As String
        If qty Is Nothing OrElse IsDBNull(qty) Then Return "—"
        Dim d As Decimal = CDec(qty)
        If d = Math.Floor(d) Then Return CInt(d).ToString()
        Return d.ToString("N2")
    End Function

    Public Function TruncateText(txt As Object, maxLen As Integer) As String
        If txt Is Nothing OrElse IsDBNull(txt) Then Return ""
        Dim s As String = txt.ToString()
        If s.Length <= maxLen Then Return s
        Return s.Substring(0, maxLen) & "…"
    End Function

    Public Function IsActif(val As Object) As Boolean
        If val Is Nothing OrElse IsDBNull(val) Then Return False
        Return CBool(val)
    End Function

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
