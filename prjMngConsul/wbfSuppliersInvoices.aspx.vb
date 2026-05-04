
Imports Telerik.Web.UI



Public Class wbfSuppliersInvoices
    Inherits clsData
    Public SupplierInvoiceId As Integer

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            rgFournisseursFactures.Rebind()
        End If
    End Sub



    Private Sub rgFournisseursFactures_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rgFournisseursFactures.NeedDataSource
        Dim dt As DataTable = GetData()
        rgFournisseursFactures.DataSource = dt
    End Sub

    Private Sub rgFournisseursFactures_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rgFournisseursFactures.ItemCommand
        If e.CommandArgument Is Nothing Then Return




        Select Case e.CommandName
            Case "EditSupplierInvoice"
                SupplierInvoiceId = e.CommandArgument
                Response.Redirect("wbfSupplierInvoinceEdit.aspx?SupplierId=" & SupplierInvoiceId.ToString)

        End Select
    End Sub


    Private Sub RAP1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles RAP1.AjaxRequest
        If e.Argument = "refreshgrid" Then
            rgFournisseursFactures.Rebind()
        End If
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