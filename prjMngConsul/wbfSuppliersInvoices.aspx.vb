Imports System.Data.SqlClient
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


    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()
        Dim sSearch As String = tbSearch.Text


        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", sSearch))
        Dim ds As DataSet = ExecuteSQLds("s0023GetSuppliersInvoices", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function


    Private Sub RAP1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles RAP1.AjaxRequest
        If e.Argument = "refreshgrid" Then
            rgFournisseursFactures.Rebind()
        End If
    End Sub



    Private Sub rgFournisseursFactures_ItemDataBound(sender As Object, e As RadListViewItemEventArgs) Handles rgFournisseursFactures.ItemDataBound
        If TypeOf e.Item Is Telerik.Web.UI.RadListViewDataItem Then


            Dim item As Telerik.Web.UI.RadListViewDataItem = CType(e.Item, Telerik.Web.UI.RadListViewDataItem)
            Dim data As DataRowView = CType(item.DataItem, DataRowView)



            If data("ComptabilisationStatus") = "COMPTABILISE" Then
                Dim btnDelete As Button = CType(item.FindControl("btnDelete"), Button)
                btnDelete.CssClass &= " btn-icon-lock-red readonly-click-block"

                btnDelete.CommandName = ""


            End If


        End If

    End Sub

    ''' <summary>
    ''' Gère les boutons CommandName de la grille (DeleteInvoice, etc.)
    ''' </summary>
    Private Sub rgFournisseursFactures_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rgFournisseursFactures.ItemCommand

        If e.CommandArgument Is Nothing Then Return

        Select Case e.CommandName

            Case "DeleteInvoice"
                Dim invoiceId As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), invoiceId)
                DeleteDocument(invoiceId)
                rgFournisseursFactures.Rebind()

            Case "EditSupplierInvoice"
                SupplierInvoiceId = e.CommandArgument
                Response.Redirect("wbfSupplierInvoinceEdit.aspx?SupplierId=" & SupplierInvoiceId.ToString)

        End Select
    End Sub

    Sub DeleteDocument(invoiceId As Integer)

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@DocumentId", invoiceId))
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s317DeleteDocument ", p)
        If ds.Tables(0).Rows(0)("RetCode") = 2 Then


        End If
    End Sub


    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rgFournisseursFactures.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rgFournisseursFactures.Rebind()
    End Sub

End Class
