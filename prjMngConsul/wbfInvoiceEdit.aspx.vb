Imports System.Data.SqlClient
Imports System.Diagnostics.Eventing
Imports System.Runtime.InteropServices
Imports Telerik.Web.UI
Imports Telerik.Web.UI.OrgChartStyles





Public Class wbfInvoiceEdit
    Inherits clsData


    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            BinDDL()

        End If



    End Sub

    Sub BinDDL()
        ddlCustomer.EmptyMessage = "Rechercher un client..."
        ddlCustomer.Filter = RadComboBoxFilter.Contains
        ddlCustomer.MarkFirstMatch = True
        ddlCustomer.EnableLoadOnDemand = True
        ddlCustomer.ShowMoreResultsBox = False
        ddlCustomer.ItemsPerRequest = "50"
        ddlCustomer.DataValueField = "Id"
        ddlCustomer.DataTextField = "Value"


    End Sub

    Private Sub ddlCustomer_ItemsRequested(sender As Object, e As RadComboBoxItemsRequestedEventArgs) Handles ddlCustomer.ItemsRequested
        Dim combo = CType(sender, RadComboBox)
        combo.Items.Clear()

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@Search", e.Text.Trim))

        Dim ds As DataSet = ExecuteSQLds("s0035Get_Customer_List4DDL", p)

        For Each orow As DataRow In ds.Tables(0).Rows
            Dim item As New RadComboBoxItem(orow("Name").ToString(), orow("Value").ToString())
            combo.Items.Add(item)
        Next
    End Sub

    Private Sub ddlCustomer_SelectedIndexChanged(sender As Object, e As RadComboBoxSelectedIndexChangedEventArgs) Handles ddlCustomer.SelectedIndexChanged
        If e.Value <> "" Then


            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@PartyId", e.Value))

            Dim ds As DataSet = ExecuteSQLds("s0037GetCustomerFullById", p)

            Dim Fullanme As String = ds.Tables(0).Rows(0)("FullName").ToString()
            rdLabel.Text = Fullanme
        Else
            rdLabel.Text = ""
        End If
        ddlCustomer.Items.Clear()
        Dim p2 As New Collection
        p2.Add(New SqlClient.SqlParameter("@Search", ""))

        Dim ds2 As DataSet = ExecuteSQLds("s0035Get_Customer_List4DDL", p2)

        For Each orow As DataRow In ds2.Tables(0).Rows
            Dim item As New RadComboBoxItem(orow("Name").ToString(), orow("Value").ToString())
            ddlCustomer.Items.Add(item)
        Next



    End Sub


End Class