Imports System.Data.SqlClient
Imports System.Drawing
Imports Telerik.Web.UI
Imports Telerik.Web.UI.OrgChartStyles
Imports Telerik.Web.UI.PageLayout

Public Class wbfCustomersInvoices
    Inherits clsData

    Public CustomerInvoiceId As Integer

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            rlvClientsFactures.Rebind()
        End If
    End Sub
    Private Sub rlvClientsFactures_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvClientsFactures.NeedDataSource
        Dim dt As DataTable = GetData()
        rlvClientsFactures.DataSource = dt
    End Sub




    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()



        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0026GetCustomersInvoices", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function


    Private Sub SaveInvoicePdfToDb(fileName As String, contentType As String, pdfBytes As Byte())
        'Dim cs As String = ConfigurationManager.ConnectionStrings("YourConnectionStringName").ConnectionString

        '        Using cn As New SqlConnection(cs)
        '            cn.Open()

        '            Dim sql As String =
        '    "MERGE dbo.CustomerInvoicePdf AS tgt
        'USING (SELECT @InvoiceId AS InvoiceId) AS src
        'ON tgt.InvoiceId = src.InvoiceId
        'WHEN MATCHED THEN
        '    UPDATE SET FileName=@FileName, ContentType=@ContentType, PdfData=@PdfData, CreatedOn=SYSUTCDATETIME()
        'WHEN NOT MATCHED THEN
        '    INSERT (InvoiceId, FileName, ContentType, PdfData)
        '    VALUES (@InvoiceId, @FileName, @ContentType, @PdfData);"

        '            Using cmd As New SqlCommand(sql, cn)
        '                cmd.Parameters.AddWithValue("@InvoiceId", invoiceId)
        '                cmd.Parameters.AddWithValue("@FileName", fileName)
        '                cmd.Parameters.AddWithValue("@ContentType", contentType)
        '                cmd.Parameters.Add("@PdfData", SqlDbType.VarBinary, -1).Value = pdfBytes
        '                cmd.ExecuteNonQuery()
        '            End Using
        '        End Using
    End Sub

    Private Sub RAP1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles RAP1.AjaxRequest
        If e.Argument = "refreshgrid" Then
            rlvClientsFactures.Rebind()
        End If
    End Sub



    Private Sub rlvClientsFactures_ItemDataBound(sender As Object, e As RadListViewItemEventArgs) Handles rlvClientsFactures.ItemDataBound
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
End Class