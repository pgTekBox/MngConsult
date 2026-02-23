
Imports Telerik.Web.UI



Public Class wbfSuppliersInvoices
    Inherits clsData
    Public SupplierInvoiceId As Integer

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            rgFournisseursFactures.Rebind()
        End If
    End Sub

    Private Sub rgFournisseursFactures_NeedDataSource(sender As Object, e As GridNeedDataSourceEventArgs) Handles rgFournisseursFactures.NeedDataSource
        Dim dt As DataTable = GetData()
        rgFournisseursFactures.DataSource = dt
    End Sub

    Private Sub rgFournisseursFactures_InsertCommand(sender As Object, e As GridCommandEventArgs) Handles rgFournisseursFactures.InsertCommand
        If e.CommandArgument Is Nothing Then Return




        Select Case e.CommandName
            Case "EditSupplierInvoice"
                SupplierInvoiceId = e.CommandArgument
                Response.Redirect("wbfSupplierEdit.aspx?SupplierId=" & SupplierInvoiceId.ToString)

        End Select
    End Sub


    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()



        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0023GetSuppliersInvoices", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function


End Class