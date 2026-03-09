Imports System.Data.SqlClient
Imports System.Diagnostics.Eventing
Imports System.Runtime.InteropServices
Imports Telerik.Web.UI
Imports Telerik.Web.UI.Editor.DialogControls
Imports Telerik.Web.UI.OrgChartStyles





Public Class wbfInvoiceEdit
    Inherits clsData


    Property InvoiceId() As Integer
        Get
            Try
                If ViewState("InvoiceId") Is Nothing Then ViewState("InvoiceId") = 0
                Dim MyRetVal As Integer = ViewState("InvoiceId")
                Return MyRetVal

            Catch ex As Exception
                Return 0
            End Try

        End Get
        Set(ByVal Value As Integer)
            ViewState("InvoiceId") = Value
        End Set
    End Property
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then

            InvoiceId = CInt(Request.QueryString("InvoiceId"))
            CreateItemsTable()
            LoadItemTableFromBD()

            ProductsTable = GetProductsTable()

            BindData()


            BinDDL()

        End If
        'Dim eventTarget As String = Request("__EVENTTARGET")

        'If eventTarget = "ProductSelected" Then

        '    Dim productId As Integer = Convert.ToInt32(hidSelectedProductId.Value)


        'End If


    End Sub

    Public Sub CreateItemsTable()
        Dim dt As New DataTable
        dt.Columns.Add("Id", GetType(Integer))
        dt.Columns.Add("ProductId", GetType(Integer))
        dt.Columns.Add("ProductName", GetType(String))
        dt.Columns.Add("Description", GetType(String))
        dt.Columns.Add("Qty", GetType(Double))
        dt.Columns.Add("UnitPrice", GetType(Double))
        dt.Columns.Add("Amount", GetType(Double))
        dt.Columns.Add("Dirty", GetType(Integer))
        dt.Columns.Add("Deleted", GetType(Integer))
        ViewState("ItemsTable") = dt
    End Sub
    Public Sub LoadItemTableFromBD()

        Dim p2 As New Collection
        p2.Add(New SqlClient.SqlParameter("@InvoiceId", InvoiceId))
        Dim ds2 As DataSet = ExecuteSQLds("s0039GetInvoiceItems", p2)


        For Each orow As DataRow In ds2.Tables(0).Rows
            Dim dr As DataRow = CType(ViewState("ItemsTable"), DataTable).NewRow()
            dr("Id") = orow("Id")
            dr("Description") = orow("Description")
            dr("Qty") = orow("Qty")
            dr("UnitPrice") = orow("UnitPrice")
            dr("Amount") = orow("Amount")
            dr("ProductId") = orow("ProductId")
            dr("ProductName") = orow("ProductName")
            dr("Dirty") = 0
            dr("Deleted") = 0
            CType(ViewState("ItemsTable"), DataTable).Rows.Add(dr)

        Next
    End Sub
    Sub UpdateAllItemInViewstate()

        Dim dt As DataTable = TryCast(ViewState("ItemsTable"), DataTable)
        If dt Is Nothing Then Exit Sub

        For Each item As RepeaterItem In rpItems.Items

            If item.ItemType <> ListItemType.Item AndAlso item.ItemType <> ListItemType.AlternatingItem Then
                Continue For
            End If

            Dim hid As HiddenField = TryCast(item.FindControl("hidId"), HiddenField)
            If hid Is Nothing OrElse String.IsNullOrWhiteSpace(hid.Value) Then Continue For

            Dim id As Integer
            If Not Integer.TryParse(hid.Value, id) Then Continue For

            ' Contrôles (version 1 seule UI)
            Dim txtItemCode As Telerik.Web.UI.RadTextBox = TryCast(item.FindControl("txtItemCode"), Telerik.Web.UI.RadTextBox)
            Dim txtDesc As Telerik.Web.UI.RadTextBox = TryCast(item.FindControl("txtDesc"), Telerik.Web.UI.RadTextBox)
            Dim numQty As Telerik.Web.UI.RadTextBox = TryCast(item.FindControl("numQty"), Telerik.Web.UI.RadTextBox)
            Dim numUnitPrice As Telerik.Web.UI.RadTextBox = TryCast(item.FindControl("numUnitPrice"), Telerik.Web.UI.RadTextBox)
            'Dim rcProducts As Telerik.Web.UI.RadComboBox = TryCast(item.FindControl("rcProducts"), Telerik.Web.UI.RadComboBox)
            Dim hidProduct As HiddenField = TryCast(item.FindControl("hidProductId"), HiddenField)


            Dim itemCode As String = If(txtItemCode Is Nothing, "", txtItemCode.Text.Trim())
            Dim productId As Integer = If(hidProduct Is Nothing, 0, hidProduct.Value)
            Dim description As String = If(txtDesc Is Nothing, "", txtDesc.Text.Trim())

            Dim qty As Double = 0
            'If numQty IsNot Nothing AndAlso numQty.Text.HasValue Then
            qty = ToDoubleAnyCulture(numQty.Text)
            Dim unitPrice As Double = 0
            'If numUnitPrice IsNot Nothing AndAlso numUnitPrice.Value.HasValue Then unitPrice = CDbl(numUnitPrice.Value.Value)
            unitPrice = ToDoubleAnyCulture(numUnitPrice.Text)
            Dim amount As Double = Math.Round(qty * unitPrice, 2)

            ' Trouver la ligne dans le DataTable
            Dim rows() As DataRow = dt.Select("Id=" & id.ToString())
            If rows Is Nothing OrElse rows.Length = 0 Then Continue For

            Dim dr As DataRow = rows(0)

            ' Si la ligne est déjà supprimée, on ne touche plus (optionnel)
            If dt.Columns.Contains("Deleted") Then
                Dim deleted As Integer = 0
                If Not IsDBNull(dr("Deleted")) Then deleted = Convert.ToInt32(dr("Deleted"))
                If deleted = 1 Then Continue For
            End If

            ' Détecter changement
            Dim changed As Boolean = False

            ' Description
            If dt.Columns.Contains("Description") Then
                Dim oldDesc As String = If(IsDBNull(dr("Description")), "", CStr(dr("Description")))
                If oldDesc <> description Then
                    dr("Description") = description
                    changed = True
                End If
            End If

            ' ProductId
            If dt.Columns.Contains("ProductId") Then
                Dim oldDesc As Integer = If(IsDBNull(dr("ProductId")), 0, CInt(dr("ProductId")))
                If oldDesc <> productId Then
                    dr("ProductId") = productId
                    changed = True
                End If
            End If



            '' Name (si tu t'en sers)
            'If dt.Columns.Contains("Name") Then
            '    Dim oldName As String = If(IsDBNull(dr("Name")), "", CStr(dr("Name")))
            '    If oldName <> itemCode Then
            '        dr("Name") = itemCode
            '        changed = True
            '    End If
            'End If

            ' Qty
            If dt.Columns.Contains("Qty") Then
                Dim oldQty As Double = If(IsDBNull(dr("Qty")), 0, Convert.ToDouble(dr("Qty")))
                If Math.Abs(oldQty - qty) > 0.0000001 Then
                    dr("Qty") = qty
                    changed = True
                End If
            End If

            ' UnitPrice
            If dt.Columns.Contains("UnitPrice") Then
                Dim oldUP As Double = If(IsDBNull(dr("UnitPrice")), 0, Convert.ToDouble(dr("UnitPrice")))
                If Math.Abs(oldUP - unitPrice) > 0.0000001 Then
                    dr("UnitPrice") = unitPrice
                    changed = True
                End If
            End If

            ' Amount (recalcul)
            If dt.Columns.Contains("Amount") Then
                Dim oldAmt As Double = If(IsDBNull(dr("Amount")), 0, Convert.ToDouble(dr("Amount")))
                If Math.Abs(oldAmt - amount) > 0.0000001 Then
                    dr("Amount") = amount
                    changed = True
                End If
            End If

            ' ProductId (si tu veux le dériver du "code" -> ici j'essaie de parser un int)
            'If dt.Columns.Contains("ProductId") Then
            '    Dim parsedPid As Integer
            '    If Integer.TryParse(itemCode, parsedPid) Then
            '        Dim oldPid As Integer = If(IsDBNull(dr("ProductId")), 0, Convert.ToInt32(dr("ProductId")))
            '        If oldPid <> parsedPid Then
            '            dr("ProductId") = parsedPid
            '            changed = True
            '        End If
            '    End If
            'End If

            ' Dirty
            If changed AndAlso dt.Columns.Contains("Dirty") Then
                dr("Dirty") = 1
            End If

        Next

        ViewState("ItemsTable") = dt


    End Sub
    Public Sub BindItemGrid()

        Dim dt As DataTable = CType(ViewState("ItemsTable"), DataTable)

        Dim dv As New DataView(dt)
        dv.RowFilter = "Deleted = 0"

        rpItems.DataSource = dv
        rpItems.DataBind()




    End Sub

    Sub BindData()
        If InvoiceId > 0 Then
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@InvoiceId", InvoiceId))
            Dim ds As DataSet = ExecuteSQLds("s0038GetInvoiceById", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return
            Dim orow As DataRow = ds.Tables(0).Rows(0)

            ddlCustomer.Items.Clear()
            Dim p2 As New Collection
            p2.Add(New SqlClient.SqlParameter("@Search", ""))

            Dim ds2 As DataSet = ExecuteSQLds("s0035Get_Customer_List4DDL", p2)

            For Each orow2 As DataRow In ds2.Tables(0).Rows
                Dim item As New RadComboBoxItem(orow2("Name").ToString(), orow2("Value").ToString())
                ddlCustomer.Items.Add(item)
            Next

            ddlCustomer.Text = orow("Name").ToString()

            rdLabel.Text = orow("FullName").ToString()
            dpIssueDate.SelectedDate = orow("IssueDate")
            dpDueDate.SelectedDate = orow("DueDate")
            BindItemGrid()
        Else

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

        'For Each it As Telerik.Web.UI.GridDataItem In rgItems.MasterTableView.Items
        '    Dim id As Integer = CInt(it.GetDataKeyValue("Id"))
        '    Dim code = CType(it.FindControl("txtItemCode"), Telerik.Web.UI.RadTextBox).Text
        '    Dim desc = CType(it.FindControl("txtDesc"), Telerik.Web.UI.RadTextBox).Text
        '    Dim qty = CType(it.FindControl("numQty"), Telerik.Web.UI.RadNumericTextBox).Value
        '    Dim unitPrice = CType(it.FindControl("numUnitPrice"), Telerik.Web.UI.RadNumericTextBox).Value

        '    ' UPDATE SQL...
        'Next


        '    ' UPDATE SQL...
        'Next
    End Sub

    Private Sub btnAddLine_Click(sender As Object, e As EventArgs) Handles btnAddLine.Click




        UpdateAllItemInViewstate()

        Dim dr As DataRow = CType(ViewState("ItemsTable"), DataTable).NewRow()
        dr("Id") = 0
        dr("Description") = ""
        dr("Qty") = 1
        dr("UnitPrice") = 0
        dr("Amount") = 0
        dr("ProductId") = 0
        dr("ProductName") = ""
        dr("Dirty") = 1
        dr("Deleted") = 0
        CType(ViewState("ItemsTable"), DataTable).Rows.Add(dr)


        BindItemGrid()

    End Sub

    Private Sub radSave_Click(sender As Object, e As EventArgs) Handles radSave.Click

        UpdateAllItemInViewstate()


        Dim DRconn As SqlClient.SqlConnection
        DRconn = New SqlClient.SqlConnection(ConnectionString)

        Dim tvp As DataTable = CType(ViewState("ItemsTable"), DataTable)

        Dim oCom As New SqlClient.SqlCommand
        oCom.CommandText = "s0040SaveInvoiceItems"
        oCom.Connection = DRconn
        oCom.CommandType = CommandType.StoredProcedure

        Dim ParamInvoiceId As New SqlClient.SqlParameter("@InvoiceId", SqlDbType.Int)
        ParamInvoiceId.Value = InvoiceId

        Dim ParamItems As New SqlClient.SqlParameter("@Items", SqlDbType.Structured)
        ParamItems.Value = tvp
        ParamItems.TypeName = "dbo.TVP_InvoiceItem_v2"

        oCom.Parameters.Add(ParamInvoiceId)
        oCom.Parameters.Add(ParamItems)

        oCom.Connection.Open()
        oCom.ExecuteNonQuery()
        oCom.Connection.Close()



    End Sub

    Private Sub rpItems_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rpItems.ItemCommand
        If e.CommandName = "DeleteLine" Then

            UpdateAllItemInViewstate()

            Dim id As Integer = Convert.ToInt32(e.CommandArgument)

            Dim dt As DataTable = CType(ViewState("ItemsTable"), DataTable)

            For Each dr As DataRow In dt.Rows
                If Convert.ToInt32(dr("Id")) = id Then
                    dr("Deleted") = 1
                    dr("Dirty") = 1
                    Exit For
                End If
            Next

            BindItemGrid()

        End If
    End Sub


    Private Function GetProductsTable() As DataTable

        Dim ds As DataSet = ExecuteSQLds("s0041GetProducts") ' <-- ta proc
        Return ds.Tables(0)
    End Function
    Private Sub rpItems_ItemDataBound(sender As Object, e As RepeaterItemEventArgs) Handles rpItems.ItemDataBound
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then
            Exit Sub
        End If

        'Dim rc As Telerik.Web.UI.RadComboBox = TryCast(e.Item.FindControl("rcProducts"), Telerik.Web.UI.RadComboBox)

        Dim lblProduct As Label = TryCast(e.Item.FindControl("lblProduct"), Label)
        Dim id As Integer = DataBinder.Eval(e.Item.DataItem, "Id")
        lblProduct.Attributes.Add("onclick", "openProductPicker(this," & id & ")")



        Dim hidProduct As HiddenField = TryCast(e.Item.FindControl("hidProductId"), HiddenField)
        'If rc Is Nothing Then Exit Sub

        ' 1) Charger la source UNE fois
        Dim products As DataTable = TryCast(ViewState("ProductsTable"), DataTable)
        If products Is Nothing Then
            products = GetProductsTable()
            ViewState("ProductsTable") = products
        End If

        lblProduct.Text = "ProductId: " & Convert.ToString(DataBinder.Eval(e.Item.DataItem, "ProductId")) ' juste pour debug






        ' 2) Binder
        'rc.DataSource = products
        'rc.DataBind()

        ' 3) Appliquer SelectedValue après bind
        'If hidProduct IsNot Nothing AndAlso Not String.IsNullOrWhiteSpace(hidProduct.Value) Then
        '    rc.SelectedValue = hidProduct.Value
        'End If
    End Sub

    Sub RecalcTotalsFromViewState()

    End Sub

    '=======================================================listview




    Private Property ProductsTable As DataTable
            Get
                Return CType(ViewState("ProductsTable"), DataTable)
            End Get
            Set(value As DataTable)
                ViewState("ProductsTable") = value
            End Set
        End Property



    Protected Sub rlvProducts_NeedDataSource(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadListViewNeedDataSourceEventArgs)
            Dim dt As DataTable = ProductsTable

        If dt Is Nothing Then
            dt = GetProductsTable()
            ProductsTable = dt
        End If

        Dim searchText As String = GetSearchText()

            If Not String.IsNullOrWhiteSpace(searchText) Then
                Dim dv As New DataView(dt)
                Dim safeText As String = searchText.Replace("'", "''")
                dv.RowFilter = "Name LIKE '%" & safeText & "%' OR Code LIKE '%" & safeText & "%' OR Category LIKE '%" & safeText & "%'"
                rlvProducts.DataSource = dv
            Else
                rlvProducts.DataSource = dt
            End If
        End Sub

        Protected Sub btnSearch_Click(ByVal sender As Object, ByVal e As EventArgs)
            rlvProducts.Rebind()
        End Sub

        Protected Sub btnClear_Click(ByVal sender As Object, ByVal e As EventArgs)
            Dim tbSearch As TextBox = CType(rlvProducts.FindControl("tbSearch"), TextBox)
            If tbSearch IsNot Nothing Then
                tbSearch.Text = ""
            End If

            rlvProducts.Rebind()
        End Sub

        Protected Sub btnAddProducts_Click(ByVal sender As Object, ByVal e As EventArgs)
        ' Exemple simple
        Return
        Dim dt As DataTable = ProductsTable
        'If dt Is Nothing Then
        '    dt = BuildProductsTable()
        'End If

        Dim rnd As New Random()

            Dim row As DataRow = dt.NewRow()
            row("Id") = dt.Rows.Count + 1
            row("Code") = "NEW-" & (dt.Rows.Count + 1).ToString("000")
            row("Name") = "Nouveau produit " & (dt.Rows.Count + 1).ToString()
            row("Category") = "Ajouté"
            row("Qty") = rnd.Next(1, 50)
            row("Price") = Math.Round(CDec(rnd.NextDouble() * 400 + 10), 2)

            dt.Rows.Add(row)
            ProductsTable = dt

            rlvProducts.Rebind()
        End Sub

        Private Function GetSearchText() As String
            Dim tbSearch As TextBox = CType(rlvProducts.FindControl("tbSearch"), TextBox)
            If tbSearch Is Nothing Then Return ""
            Return tbSearch.Text.Trim()
        End Function

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest

        Dim AllParam As String() = e.Argument.Split("|"c)


        Dim ItemLineId As Integer
        Dim productId As Integer

        If Integer.TryParse(AllParam(1), productId) Then
            If Integer.TryParse(AllParam(0), ItemLineId) Then

                UpdateItem(ItemLineId, productId)




                BindItemGrid()
            End If
        End If

    End Sub

    Sub UpdateItem(ItemLineId As Integer, productId As Integer)

        Dim p2 As New Collection
        p2.Add(New SqlClient.SqlParameter("@ProductId", productId))
        Dim AlldsProducts As DataSet = ExecuteSQLds("s0042GetProductById", p2)



        Dim dt As DataTable = CType(ViewState("ItemsTable"), DataTable)
        If dt Is Nothing Then Exit Sub

        Dim dr As DataRow = dt.AsEnumerable().
        FirstOrDefault(Function(r) Convert.ToInt32(r("Id")) = ItemLineId)

        If dr Is Nothing Then Exit Sub

        dr("ProductId") = productId
        dr("Dirty") = 1

        ' Exemple: si tu veux aussi vider ou reset certains champs
        dr("Description") = AlldsProducts.Tables(0).Rows(0)("Description").ToString() ' ou "" si tu préfères
        dr("ProductName") = AlldsProducts.Tables(0).Rows(0)("Name").ToString()
        dr("Qty") = 1
        dr("UnitPrice") = AlldsProducts.Tables(0).Rows(0)("Prix").ToString()
        dr("Amount") = 0D
        dr("Deleted") = 0

        ViewState("ItemsTable") = dt




    End Sub




    'Private Function BuildProductsTable() As DataTable
    '    Dim dt As New DataTable()

    '    dt.Columns.Add("Id", GetType(Integer))
    '    dt.Columns.Add("Code", GetType(String))
    '    dt.Columns.Add("Name", GetType(String))
    '    dt.Columns.Add("Category", GetType(String))
    '    dt.Columns.Add("Qty", GetType(Integer))
    '    dt.Columns.Add("Price", GetType(Decimal))

    '    Dim productNames As String() = {
    '        "Baignoire classique", "Baignoire antique", "Lavabo blanc", "Robinet chrome", "Douche murale",
    '        "Panneau de verre", "Vanité moderne", "Miroir LED", "Toilette compacte", "Évier inox",
    '        "Colonne de douche", "Mitigeur noir", "Bonde universelle", "Base de douche", "Cabine vitrée",
    '        "Armoire salle de bain", "Tiroir vanity", "Céramique murale", "Plancher vinyle", "Pommeau pluie",
    '        "Ensemble bain-douche", "Porte-serviette", "Distributeur savon", "Lumière vanity", "Extracteur d'air",
    '        "Silicone blanc", "Joint étanche", "Accessoire inox", "Banc de douche", "Poignée de sécurité"
    '    }

    '    Dim categories As String() = {
    '        "Bain", "Douche", "Lavabo", "Robinetterie", "Accessoires"
    '    }

    '    Dim rnd As New Random()

    '    For i As Integer = 1 To 30
    '        Dim row As DataRow = dt.NewRow()
    '        row("Id") = i
    '        row("Code") = "PRD-" & i.ToString("000")
    '        row("Name") = productNames(i - 1)
    '        row("Category") = categories(rnd.Next(0, categories.Length))
    '        row("Qty") = rnd.Next(1, 101)
    '        row("Price") = Math.Round(CDec(rnd.NextDouble() * 450 + 25), 2)
    '        dt.Rows.Add(row)
    '    Next

    '    Return dt
    'End Function

End Class

