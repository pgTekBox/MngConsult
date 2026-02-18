Imports Telerik.Web.UI

Public Class wbfSuppliers
    Inherits clsData


    Public SupplierId As Integer

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            rgFournisseurs.Rebind()
        End If
    End Sub

    Private Sub rgFournisseurs_NeedDataSource(sender As Object, e As GridNeedDataSourceEventArgs) Handles rgFournisseurs.NeedDataSource
        Dim dt As DataTable = GetData()
        rgFournisseurs.DataSource = dt

        'lblInfo.Visible = True
        'lblInfo.Text = $"{If(dt IsNot Nothing, dt.Rows.Count, 0)} reçu(s)"
    End Sub

    Private Sub rgFournisseurs_ItemCommand(sender As Object, e As GridCommandEventArgs) Handles rgFournisseurs.ItemCommand



        If e.CommandArgument Is Nothing Then Return




        Select Case e.CommandName
            Case "EditSupplier"
                SupplierId = e.CommandArgument
                Server.Transfer("wbfSupplierEdit.aspx")
        End Select

    End Sub

    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()



        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0011GetSuppliers", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

End Class