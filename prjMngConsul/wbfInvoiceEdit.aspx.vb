Imports System.Data.SqlClient
Imports System.Diagnostics.Eventing
Imports System.Runtime.InteropServices
Imports System.Security.Cryptography.X509Certificates
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
    Property CustomerGUID() As Guid
        Get
            Try
                If ViewState("CustomerGUID") Is Nothing Then ViewState("CustomerGUID") = New Guid("00000000-0000-0000-0000-000000000000")
                Dim MyRetVal As Guid = ViewState("CustomerGUID")
                Return MyRetVal

            Catch ex As Exception
                Return New Guid("00000000-0000-0000-0000-000000000000")
            End Try

        End Get
        Set(ByVal Value As Guid)
            ViewState("CustomerGUID") = Value
        End Set
    End Property
    Property Comptabilise() As Boolean
        Get
            Try
                If ViewState("Comptabilise") Is Nothing Then ViewState("Comptabilise") = False
                Dim MyRetVal As Boolean = ViewState("Comptabilise")
                Return MyRetVal

            Catch ex As Exception
                Return False
            End Try

        End Get
        Set(ByVal Value As Boolean)
            ViewState("Comptabilise") = Value
        End Set
    End Property
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        ApplyLocalization()

        If Not IsPostBack Then

            InvoiceId = CInt(Request.QueryString("Id"))
            CreateItemsTable()
            LoadItemTableFromBD()
            ProductsTable = GetProductsTable()
            If InvoiceId = 0 Then lblCustomer.Text = L("selectClient")
            BindData()
            'BinDDL()

            ' Le bouton « Envoyer au client » n'a de sens que pour une facture déjà enregistrée.
            btnSendEmail.Visible = (InvoiceId > 0)
        End If
        ApplyReadOnlyMode()


    End Sub

    ''' <summary>Applique les libellés localisés (fr/en/es) aux contrôles serveur.</summary>
    Private Sub ApplyLocalization()
        Page.Title = L("pageTitle")
        lblPostedBadge.Text = L("postedBadge")
        radSave.Text = L("save")
        btnSendEmail.Text = L("sendEmail")
        SetLiteral(Me, "litDlgTitle", L("dlgEmailTitle"))
        SetLiteral(Me, "litDlgQuestion", L("dlgEmailQuestion"))
        SetLiteral(Me, "litDlgCancel", L("dlgCancel"))
        SetLiteral(Me, "litDlgWithout", L("dlgWithout"))
        SetLiteral(Me, "litDlgWith", L("dlgWith"))
        btnAddLine.ToolTip = L("addLine")
        lblCapSubTotal.Text = L("subtotal")
        SetLiteral(Me, "litLblClient", L("client"))
        SetLiteral(Me, "litLblInvoiceDate", L("invoiceDate"))
        SetLiteral(Me, "litLblDueDate", L("dueDate"))
        SetLiteral(Me, "litLblPosted", L("posted"))
        SetLiteral(Me, "litLines", L("lines"))
        SetLiteral(Me, "litColProduct", L("colProduct"))
        SetLiteral(Me, "litColAccount", L("colAccount"))
        SetLiteral(Me, "litColQty", L("colQty"))
        SetLiteral(Me, "litColUnitPrice", L("colUnitPrice"))
        SetLiteral(Me, "litColTotal", L("colTotal"))
        SetLiteral(Me, "litColTax", L("colTax"))
        SetLiteral(Me, "litColOrder", L("colOrder"))
        SetLiteral(Me, "litCapTotal", L("total"))
    End Sub

    Private Sub rlvProducts_PreRender(sender As Object, e As EventArgs) Handles rlvProducts.PreRender
        SetLiteral(rlvProducts, "litEmptyProducts", L("emptyProducts"))
        SetRadButtonText(rlvProducts, "btnAddProducts", L("addProducts"))
    End Sub

    Private Sub rlvCustomers_PreRender(sender As Object, e As EventArgs) Handles rlvCustomers.PreRender
        SetLiteral(rlvCustomers, "litEmptyCustomers", L("emptyCustomers"))
        SetRadButtonText(rlvCustomers, "btnAddcustomers", L("addCustomers"))
    End Sub

    Private Sub rlvAccounts_PreRender(sender As Object, e As EventArgs) Handles rlvAccounts.PreRender
        SetLiteral(rlvAccounts, "litEmptyAccounts", L("emptyAccounts"))
        SetRadButtonText(rlvAccounts, "btnAddAccounts", L("addAccounts"))
    End Sub

    Private Shared Sub SetLiteral(root As Control, id As String, text As String)
        Dim lit = TryCast(FindDeep(root, id), Literal)
        If lit IsNot Nothing Then lit.Text = text
    End Sub

    Private Shared Sub SetRadButtonText(root As Control, id As String, text As String)
        Dim b = TryCast(FindDeep(root, id), Telerik.Web.UI.RadButton)
        If b IsNot Nothing Then b.Text = text
    End Sub

    Private Shared Function FindDeep(root As Control, id As String) As Control
        If root Is Nothing Then Return Nothing
        Dim direct As Control = root.FindControl(id)
        If direct IsNot Nothing Then Return direct
        For Each ch As Control In root.Controls
            Dim r As Control = FindDeep(ch, id)
            If r IsNot Nothing Then Return r
        Next
        Return Nothing
    End Function

    ''' <summary>Traductions (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Facture client — Édition", "Customer invoice — Edit", "Factura de cliente — Edición")
            Case "client" : Return Choose3(lang, "Client", "Customer", "Cliente")
            Case "selectClient" : Return Choose3(lang, "Sélectionner un client", "Select a customer", "Seleccionar un cliente")
            Case "invoiceDate" : Return Choose3(lang, "Date de facture", "Invoice date", "Fecha de factura")
            Case "dueDate" : Return Choose3(lang, "Date d'échéance", "Due date", "Fecha de vencimiento")
            Case "posted" : Return Choose3(lang, "Comptabilisé", "Posted", "Contabilizado")
            Case "postedBadge" : Return Choose3(lang, "Comptabilisé 🔒", "Posted 🔒", "Contabilizado 🔒")
            Case "lines" : Return Choose3(lang, "Lignes", "Lines", "Líneas")
            Case "colProduct" : Return Choose3(lang, "Produit", "Product", "Producto")
            Case "colAccount" : Return Choose3(lang, "Compte", "Account", "Cuenta")
            Case "colQty" : Return Choose3(lang, "Qté", "Qty", "Cant.")
            Case "colUnitPrice" : Return Choose3(lang, "Prix unitaire", "Unit price", "Precio unitario")
            Case "colTotal" : Return Choose3(lang, "Total", "Total", "Total")
            Case "colTax" : Return Choose3(lang, "Tx", "Tax", "Imp.")
            Case "colOrder" : Return Choose3(lang, "Ordre", "Order", "Orden")
            Case "total" : Return Choose3(lang, "Total", "Total", "Total")
            Case "subtotal" : Return Choose3(lang, "Sous-total", "Subtotal", "Subtotal")
            Case "save" : Return Choose3(lang, "Enregistrer", "Save", "Guardar")
            Case "addLine" : Return Choose3(lang, "Ajouter une ligne", "Add a line", "Agregar una línea")
            Case "searchProduct" : Return Choose3(lang, "Rechercher un produit…", "Search a product…", "Buscar un producto…")
            Case "searchCustomer" : Return Choose3(lang, "Rechercher un client…", "Search a customer…", "Buscar un cliente…")
            Case "searchAccount" : Return Choose3(lang, "Rechercher un compte…", "Search an account…", "Buscar una cuenta…")
            Case "close" : Return Choose3(lang, "Fermer", "Close", "Cerrar")
            Case "addProducts" : Return Choose3(lang, "Ajouter des produits", "Add products", "Agregar productos")
            Case "addCustomers" : Return Choose3(lang, "Ajouter des clients", "Add customers", "Agregar clientes")
            Case "addAccounts" : Return Choose3(lang, "Ajouter des comptes", "Add accounts", "Agregar cuentas")
            Case "emptyProducts" : Return Choose3(lang, "Aucun produit trouvé.", "No product found.", "No se encontró ningún producto.")
            Case "emptyCustomers" : Return Choose3(lang, "Aucun client trouvé.", "No customer found.", "No se encontró ningún cliente.")
            Case "emptyAccounts" : Return Choose3(lang, "Aucun compte trouvé.", "No account found.", "No se encontró ninguna cuenta.")
            Case "confirmDelLine" : Return Choose3(lang, "Supprimer cette ligne ?", "Delete this line?", "¿Eliminar esta línea?")
            Case "sendEmail" : Return Choose3(lang, "Envoyer au client", "Send to customer", "Enviar al cliente")
            Case "dlgEmailTitle" : Return Choose3(lang, "Envoyer la facture par courriel", "Send invoice by email", "Enviar factura por correo")
            Case "dlgEmailQuestion" : Return Choose3(lang, "Voulez-vous inclure un <strong>lien de paiement Square</strong> dans le courriel&nbsp;?", "Do you want to include a <strong>Square payment link</strong> in the email?", "¿Desea incluir un <strong>enlace de pago Square</strong> en el correo?")
            Case "dlgCancel" : Return Choose3(lang, "Annuler", "Cancel", "Cancelar")
            Case "dlgWithout" : Return Choose3(lang, "Envoyer sans lien", "Send without link", "Enviar sin enlace")
            Case "dlgWith" : Return Choose3(lang, "Avec lien Square", "With Square link", "Con enlace Square")
            Case "saveFirst" : Return Choose3(lang, "Veuillez d'abord enregistrer la facture.", "Please save the invoice first.", "Guarde primero la factura.")
            Case "msgNotFound" : Return Choose3(lang, "Facture introuvable.", "Invoice not found.", "Factura no encontrada.")
            Case "msgNoEmail" : Return Choose3(lang, "Aucun courriel de facturation pour ce client.", "No billing email for this customer.", "No hay correo de facturación para este cliente.")
            Case "msgPdfFail" : Return Choose3(lang, "Impossible de générer le PDF de la facture.", "Unable to generate the invoice PDF.", "No se pudo generar el PDF de la factura.")
            Case "msgSent" : Return Choose3(lang, "Facture {0} envoyée à {1}.", "Invoice {0} sent to {1}.", "Factura {0} enviada a {1}.")
            Case "noteAlreadyPaid" : Return Choose3(lang, " (lien Square non ajouté : facture déjà payée)", " (Square link not added: invoice already paid)", " (enlace Square no agregado: factura ya pagada)")
            Case "noteNotConnected" : Return Choose3(lang, " (lien Square non ajouté : compte Square non connecté)", " (Square link not added: Square account not connected)", " (enlace Square no agregado: cuenta Square no conectada)")
            Case "noteNotGenerated" : Return Choose3(lang, " (lien Square non généré)", " (Square link not generated)", " (enlace Square no generado)")
            Case "noteError" : Return Choose3(lang, " (lien Square non ajouté : ", " (Square link not added: ", " (enlace Square no agregado: ")
            Case Else : Return ""
        End Select
    End Function

    Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function
    'Creation d 'une table en mémoire pour stocker les lignes de facture (équivalent d'un DataTable dans une session classique)
    Public Sub CreateItemsTable()
        Dim dt As New DataTable
        dt.Columns.Add("Id", GetType(Integer))
        dt.Columns.Add("ProductId", GetType(Integer))
        dt.Columns.Add("ProductName", GetType(String))
        dt.Columns.Add("AccountId", GetType(Integer))
        dt.Columns.Add("AccountName", GetType(String))
        dt.Columns.Add("Description", GetType(String))
        dt.Columns.Add("Qty", GetType(Double))
        dt.Columns.Add("UnitPrice", GetType(Double))
        dt.Columns.Add("Amount", GetType(Double))
        dt.Columns.Add("Dirty", GetType(Integer))
        dt.Columns.Add("Deleted", GetType(Integer))
        dt.Columns.Add("Ordre", GetType(Integer))
        dt.Columns.Add("TaxeStatus", GetType(Integer))
        ViewState("ItemsTable") = dt
    End Sub


    'Charger les lignes de la facture depuis la BD et les stocker dans le ViewState("ItemsTable")
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
            dr("AccountId") = If(IsDBNull(orow("AccountId")), 0, Convert.ToInt32(orow("AccountId")))
            dr("AccountName") = If(IsDBNull(orow("AccountName")), "", orow("AccountName").ToString())
            dr("Dirty") = 0
            dr("Deleted") = 0
            dr("Ordre") = 0
            dr("TaxeStatus") = orow("TaxeStatus")
            CType(ViewState("ItemsTable"), DataTable).Rows.Add(dr)

        Next
    End Sub


    ' Met à jour le ViewState("ItemsTable") avec les valeurs actuelles des contrôles de chaque ligne (à appeler avant tout bind ou action qui nécessite les données à jour)
    Sub UpdateAllItemInViewstate()

        Dim dt As DataTable = TryCast(ViewState("ItemsTable"), DataTable)
        If dt Is Nothing Then Exit Sub
        Dim MyOrdre As Integer = 0
        For Each item As RepeaterItem In rpItems.Items
            MyOrdre = MyOrdre + 1
            If item.ItemType <> ListItemType.Item AndAlso item.ItemType <> ListItemType.AlternatingItem Then
                Continue For
            End If

            Dim hid As HiddenField = TryCast(item.FindControl("hidId"), HiddenField)
            If hid Is Nothing OrElse String.IsNullOrWhiteSpace(hid.Value) Then Continue For

            Dim id As Integer
            If Not Integer.TryParse(hid.Value, id) Then Continue For

            ' Contrôles (version 1 seule UI)
            Dim ddlTaxeStatus As Telerik.Web.UI.RadDropDownList = TryCast(item.FindControl("rdTaxeStatus"), Telerik.Web.UI.RadDropDownList)

            Dim txtItemCode As Telerik.Web.UI.RadTextBox = TryCast(item.FindControl("txtItemCode"), Telerik.Web.UI.RadTextBox)
            Dim txtDesc As Telerik.Web.UI.RadTextBox = TryCast(item.FindControl("txtDesc"), Telerik.Web.UI.RadTextBox)
            Dim numQty As Telerik.Web.UI.RadTextBox = TryCast(item.FindControl("numQty"), Telerik.Web.UI.RadTextBox)
            Dim numUnitPrice As Telerik.Web.UI.RadTextBox = TryCast(item.FindControl("numUnitPrice"), Telerik.Web.UI.RadTextBox)
            'Dim rcProducts As Telerik.Web.UI.RadComboBox = TryCast(item.FindControl("rcProducts"), Telerik.Web.UI.RadComboBox)
            Dim hidProduct As HiddenField = TryCast(item.FindControl("hidProductId"), HiddenField)
            Dim hidAccount As HiddenField = TryCast(item.FindControl("hidAccountId"), HiddenField)


            Dim itemCode As String = If(txtItemCode Is Nothing, "", txtItemCode.Text.Trim())
            Dim productId As Integer = If(hidProduct Is Nothing OrElse String.IsNullOrWhiteSpace(hidProduct.Value), 0, Convert.ToInt32(hidProduct.Value))
            Dim accountId As Integer = If(hidAccount Is Nothing OrElse String.IsNullOrWhiteSpace(hidAccount.Value), 0, Convert.ToInt32(hidAccount.Value))
            Dim description As String = If(txtDesc Is Nothing, "", txtDesc.Text.Trim())
            Dim taxestatus As Integer = ddlTaxeStatus.SelectedValue
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
            dr("Description") = description
            dr("ProductId") = productId
            dr("AccountId") = accountId
            dr("Qty") = qty
            dr("UnitPrice") = unitPrice
            dr("Amount") = amount
            dr("Ordre") = MyOrdre
            dr("Dirty") = 1
            dr("TaxeStatus") = taxestatus
        Next

        ViewState("ItemsTable") = dt


    End Sub


    'Binding du Repeater avec les données du ViewState("ItemsTable") en filtrant les lignes marquées comme Deleted=1
    Public Sub BindItemGrid()

        Dim dt As DataTable = CType(ViewState("ItemsTable"), DataTable)
        Dim dv As New DataView(dt)
        dv.Sort = "Ordre"
        dv.RowFilter = "Deleted = 0"

        rpItems.DataSource = dv
        rpItems.DataBind()

    End Sub


    'Binding des autres champs de la facture (client, dates, etc) et appel du BindItemGrid() pour les lignes
    Sub BindData()
        If InvoiceId > 0 Then
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@InvoiceId", InvoiceId))
            Dim ds As DataSet = ExecuteSQLds("s0038GetInvoiceById", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return
            Dim orow As DataRow = ds.Tables(0).Rows(0)

            'ddlCustomer.Items.Clear()
            Dim p2 As New Collection
            p2.Add(New SqlClient.SqlParameter("@Search", ""))

            Dim ds2 As DataSet = ExecuteSQLds("s0035Get_Customer_List4DDL", p2)

            'For Each orow2 As DataRow In ds2.Tables(0).Rows
            '    Dim item As New RadComboBoxItem(orow2("ContactName").ToString(), orow2("Value").ToString())
            '    ddlCustomer.Items.Add(item)
            'Next

            'ddlCustomer.Text = orow("Name").ToString()
            CustomerGUID = orow("PartyGUID")
            lblCustomer.Text = orow("Name").ToString()
            rdLabel.Text = orow("FullName").ToString()
            dpIssueDate.SelectedDate = orow("IssueDate")
            dpDueDate.SelectedDate = orow("DueDate")
            Comptabilise = orow("Comptabilise")
            If Comptabilise Then
                chkPost.Checked = True
            Else
                chkPost.Checked = False
            End If
            BindItemGrid()






        Else

        End If
    End Sub


    Private Sub ApplyReadOnlyMode()
        If Comptabilise Then


            lblPostedBadge.Visible = True


            chkPost.Enabled = False




            ' Bloquer visuellement
            pnlMain.CssClass &= " readonly"
            lblCustomer.CssClass &= " readonly-click-block"
            ' Désactiver champs principaux
            dpIssueDate.Enabled = False
            dpDueDate.Enabled = False

            ' Bloquer bouton ajouter
            btnAddLine.Visible = False

            ' Bloquer save
            radSave.Enabled = False

            ' Bloquer repeater (inputs)
            For Each item As RepeaterItem In rpItems.Items

                Dim txtDesc = CType(item.FindControl("txtDesc"), Telerik.Web.UI.RadTextBox)
                Dim numQty = CType(item.FindControl("numQty"), Telerik.Web.UI.RadTextBox)
                Dim numUnitPrice = CType(item.FindControl("numUnitPrice"), Telerik.Web.UI.RadTextBox)

                If txtDesc IsNot Nothing Then txtDesc.Enabled = False
                If numQty IsNot Nothing Then numQty.Enabled = False
                If numUnitPrice IsNot Nothing Then numUnitPrice.Enabled = False

                ' cacher boutons actions
                Dim btnDel = CType(item.FindControl("RadImageButton1"), Telerik.Web.UI.RadImageButton)
                Dim btnUp = CType(item.FindControl("RadImageButton2"), Telerik.Web.UI.RadImageButton)
                Dim btnDown = CType(item.FindControl("RadImageButton3"), Telerik.Web.UI.RadImageButton)

                If btnDel IsNot Nothing Then btnDel.Visible = False
                If btnUp IsNot Nothing Then btnUp.Visible = False
                If btnDown IsNot Nothing Then btnDown.Visible = False

                Dim lblProduct = TryCast(item.FindControl("lblProduct"), Label)
                Dim lblAccount = TryCast(item.FindControl("lblAccount"), Label)

                If lblProduct IsNot Nothing Then lblProduct.CssClass &= " readonly-click-block"
                If lblAccount IsNot Nothing Then lblAccount.CssClass &= " readonly-click-block"



            Next
        Else
            lblPostedBadge.Visible = False
        End If
    End Sub


    'Ajout d'une ligne vide dans le ViewState("ItemsTable") et rebind du Repeater pour afficher la nouvelle ligne
    Private Sub btnAddLine_Click(sender As Object, e As EventArgs) Handles btnAddLine.Click
        If Comptabilise Then Return
        UpdateAllItemInViewstate()

        Dim Newid As Integer = (CType(ViewState("ItemsTable"), DataTable).Rows.Count + 1) * -1 ' Id négatif temporaire pour différencier les nouvelles lignes (les lignes existantes ont des Id positifs issus de la BD, les nouvelles lignes auront des Id négatifs générés à la volée)    



        Dim dr As DataRow = CType(ViewState("ItemsTable"), DataTable).NewRow()
        dr("Id") = Newid
        dr("Description") = ""
        dr("Qty") = 1
        dr("UnitPrice") = 0
        dr("Amount") = 0
        dr("ProductId") = 0
        dr("ProductName") = ""
        dr("AccountId") = 0
        dr("AccountName") = ""
        dr("Dirty") = 1
        dr("Deleted") = 0
        dr("TaxeStatus") = 0
        dr("Ordre") = CType(ViewState("ItemsTable"), DataTable).Rows.Count + 1

        CType(ViewState("ItemsTable"), DataTable).Rows.Add(dr)


        BindItemGrid()

    End Sub



    'Sauvegarde de la facture: mise à jour du ViewState("ItemsTable") avec les valeurs actuelles, puis envoi de toutes les lignes (y compris les marquées comme Deleted=1) à une procédure stockée qui se chargera de faire les insert/update/delete nécessaires en fonction des flags Dirty et Deleted
    Private Sub radSave_Click(sender As Object, e As EventArgs) Handles radSave.Click
        If Comptabilise Then Return
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

        Dim ParamPost As New SqlClient.SqlParameter("@toPost", SqlDbType.Int)
        If chkPost.Checked Then
            ParamPost.Value = 1
        Else
            ParamPost.Value = 0
        End If
        Dim ParamDocumentType As New SqlClient.SqlParameter("@DocumentType", SqlDbType.VarChar)
        ParamDocumentType.Value = "CLIENT "

        Dim ParamPartyGUID As New SqlClient.SqlParameter("@PartyGUID", SqlDbType.UniqueIdentifier)
        ParamPartyGUID.Value = CustomerGUID

        Dim ParamCompanyGUID As New SqlClient.SqlParameter("@CompanyGUID", SqlDbType.UniqueIdentifier)
        ParamCompanyGUID.Value = Company

        Dim ParamIssueDate As New SqlClient.SqlParameter("@IssueDate", SqlDbType.DateTime)
        ParamIssueDate.Value = dpIssueDate.SelectedDate

        Dim ParamDueDate As New SqlClient.SqlParameter("@DueDate", SqlDbType.DateTime)
        ParamDueDate.Value = dpDueDate.SelectedDate


        Dim ParamItems As New SqlClient.SqlParameter("@Items", SqlDbType.Structured)
        ParamItems.Value = tvp
        ParamItems.TypeName = "dbo.TVP_InvoiceItem_v6"

        oCom.Parameters.Add(ParamDocumentType)
        oCom.Parameters.Add(ParamDueDate)
        oCom.Parameters.Add(ParamIssueDate)
        oCom.Parameters.Add(ParamPartyGUID)
        oCom.Parameters.Add(ParamPost)
        oCom.Parameters.Add(ParamInvoiceId)
        oCom.Parameters.Add(ParamItems)
        oCom.Parameters.Add(ParamCompanyGUID)




        oCom.Connection.Open()
        'oCom.ExecuteNonQuery()
        Dim MyInvoiceId As Integer = CInt(oCom.ExecuteScalar())
        oCom.Connection.Close()



        ' Génération du PDF (infos compagnie réelles + logo) via la classe centralisée.
        Dim oPdf As New clsGenerateInvoicePDF()
        oPdf.GenerateAndDownloadPdf(MyInvoiceId)


        Dim script As String = "function fw(){closeWin(); Sys.Application.remove_load(fw);}Sys.Application.add_load(fw);"
        ScriptManager.RegisterStartupScript(Page, Page.GetType(), "close", script, True)


    End Sub

    'ItemCommand du Repeater pour gérer la suppression d'une ligne: on marque la ligne comme Deleted=1 dans le ViewState("ItemsTable") et on rebind le Repeater pour que la ligne disparaisse de l'affichage (le vrai delete en BD sera géré par la procédure stockée lors de la sauvegarde en fonction du flag Deleted)
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

        If e.CommandName = "OrdreHaut" Then
            UpdateAllItemInViewstate()
            Dim id As Integer = Convert.ToInt32(e.CommandArgument)
            Dim dt As DataTable = CType(ViewState("ItemsTable"), DataTable)
            DecrementerOrdre(dt, id)
            BindItemGrid()
        End If


        If e.CommandName = "OrdreBas" Then
            UpdateAllItemInViewstate()
            Dim id As Integer = Convert.ToInt32(e.CommandArgument)
            Dim dt As DataTable = CType(ViewState("ItemsTable"), DataTable)
            IncrementerOrdre(dt, id)
            BindItemGrid()

        End If



    End Sub
    Public Sub IncrementerOrdre(dt As DataTable, targetId As Integer)

        If dt Is Nothing OrElse dt.Rows.Count = 0 Then Exit Sub

        ' 🔹 1. Trouver la ligne cible
        Dim targetRow As DataRow = dt.AsEnumerable().
        FirstOrDefault(Function(r) Convert.ToInt32(r("Id")) = targetId)

        If targetRow Is Nothing Then Exit Sub

        Dim ordreActuel As Integer = Convert.ToInt32(targetRow("Ordre"))

        ' 🔹 2. Trouver le max (pour ne pas dépasser)
        Dim maxOrdre As Integer = dt.AsEnumerable().
        Max(Function(r) Convert.ToInt32(r("Ordre")))

        If ordreActuel >= maxOrdre Then Exit Sub

        ' 🔹 3. Trouver la ligne suivante
        Dim nextRow As DataRow = dt.AsEnumerable().
        FirstOrDefault(Function(r) Convert.ToInt32(r("Ordre")) = ordreActuel + 1)

        ' 🔹 4. Swap
        If nextRow IsNot Nothing Then
            nextRow("Ordre") = ordreActuel
            targetRow("Ordre") = ordreActuel + 1
        End If

        ' 🔹 5. Re-numérotation (sécurité)
        Dim orderedRows = dt.AsEnumerable().
        OrderBy(Function(r) Convert.ToInt32(r("Ordre"))).
        ThenBy(Function(r) Convert.ToInt32(r("Id"))).
        ToList()

        Dim i As Integer = 1
        For Each r In orderedRows
            r("Ordre") = i
            i += 1
        Next

    End Sub
    Public Sub DecrementerOrdre(dt As DataTable, targetId As Integer)

        If dt Is Nothing OrElse dt.Rows.Count = 0 Then Exit Sub

        ' 🔹 1. Trouver la ligne cible
        Dim targetRow As DataRow = dt.AsEnumerable().
        FirstOrDefault(Function(r) Convert.ToInt32(r("Id")) = targetId)

        If targetRow Is Nothing Then Exit Sub

        Dim ordreActuel As Integer = Convert.ToInt32(targetRow("Ordre"))

        ' 🔹 2. Si déjà à 1 → rien à faire
        If ordreActuel <= 1 Then Exit Sub

        ' 🔹 3. Trouver la ligne juste avant
        Dim previousRow As DataRow = dt.AsEnumerable().
        FirstOrDefault(Function(r) Convert.ToInt32(r("Ordre")) = ordreActuel - 1)

        ' 🔹 4. Swap des ordres
        If previousRow IsNot Nothing Then
            previousRow("Ordre") = ordreActuel
            targetRow("Ordre") = ordreActuel - 1
        End If

        ' 🔹 5. Re-numérotation propre (sécurise les trous/doublons)
        Dim orderedRows = dt.AsEnumerable().
        OrderBy(Function(r) Convert.ToInt32(r("Ordre"))).
        ThenBy(Function(r) Convert.ToInt32(r("Id"))).
        ToList()

        Dim i As Integer = 1
        For Each r In orderedRows
            r("Ordre") = i
            i += 1
        Next

    End Sub



    'Creation d'une table en mémoire pour stocker la liste des produits (équivalent d'un DataTable dans une session classique) et méthode pour la charger depuis la BD (proc s0041GetProducts qui retourne Id, Name, Description, Price)
    Private Function GetProductsTable() As DataTable
        Dim p As New Collection

        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0041GetProducts", p) ' <-- ta proc
        Return ds.Tables(0)
    End Function

    Private Function GetCustomersTable() As DataTable
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@Type", "Client"))
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))


        Dim ds As DataSet = ExecuteSQLds("s0043Get_Party", p) '  
        Return ds.Tables(0)
    End Function

    Private Function GetAccountsTable() As DataTable
        ' TODO: adapter le nom de la procédure stockée si nécessaire
        Dim p As New Collection

        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0082Get_GLAccounts_REVENU", p)
        Return ds.Tables(0)
    End Function



    'ItemDataBound du Repeater pour chaque ligne: on charge la liste des produits depuis le ViewState("ProductsTable") et on bind un RadComboBox (ou un autre contrôle de ton choix) pour permettre de sélectionner un produit. On peut aussi afficher le nom du produit dans un Label et ouvrir un product picker au clic (exemple avec un Label et une fonction JavaScript fictive openProductPicker)
    'Charge la liste des produits dans le ViewState("ProductsTable") si ce n'est pas déjà fait, puis pour chaque ligne du Repeater, on trouve le Label lblProduct et le HiddenField hidProductId, on bind le Label avec le nom du produit correspondant au ProductId de la ligne, et on ajoute un onclick pour ouvrir un product picker (fonction JavaScript à implémenter) qui permettra de sélectionner un produit et de mettre à jour le HiddenField hidProductId avec l'Id du produit sélectionné. Le bind du RadComboBox est commenté mais tu peux l'utiliser à la place du Label si tu préfères.
    Private Sub rpItems_ItemDataBound(sender As Object, e As RepeaterItemEventArgs) Handles rpItems.ItemDataBound
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then
            Exit Sub
        End If

        'Dim rc As Telerik.Web.UI.RadComboBox = TryCast(e.Item.FindControl("rcProducts"), Telerik.Web.UI.RadComboBox)

        Dim lblProduct As Label = TryCast(e.Item.FindControl("lblProduct"), Label)
        Dim lblAccount As Label = TryCast(e.Item.FindControl("lblAccount"), Label)
        Dim id As Integer = DataBinder.Eval(e.Item.DataItem, "Id")
        lblProduct.Attributes.Add("onclick", "openProductPicker(this," & id & ")")
        If lblAccount IsNot Nothing Then
            lblAccount.Attributes.Add("onclick", "openAccountPicker(this," & id & ")")
        End If

        Dim hidProduct As HiddenField = TryCast(e.Item.FindControl("hidProductId"), HiddenField)
        'If rc Is Nothing Then Exit Sub

        ' 1) Charger la source UNE fois
        Dim products As DataTable = TryCast(ViewState("ProductsTable"), DataTable)
        If products Is Nothing Then
            products = GetProductsTable()
            ViewState("ProductsTable") = products
        End If


        Dim rdTaxeStatus As RadDropDownList = TryCast(e.Item.FindControl("rdTaxeStatus"), Telerik.Web.UI.RadDropDownList)
        If rdTaxeStatus IsNot Nothing Then
            SetDDL(rdTaxeStatus, "ShortName", "Id", "s0092GetTaxeSatus")
            rdTaxeStatus.SelectedValue = DataBinder.Eval(e.Item.DataItem, "TaxeStatus")

        End If



        If lblAccount IsNot Nothing Then
            lblAccount.Text = Convert.ToString(DataBinder.Eval(e.Item.DataItem, "AccountName"))
        End If



    End Sub


    'Propriete retourne le Viewstate des Produits
    Private Property ProductsTable As DataTable
        Get
            Return CType(ViewState("ProductsTable"), DataTable)
        End Get
        Set(value As DataTable)
            ViewState("ProductsTable") = value
        End Set
    End Property


    'Binding de la liste de produits lors de la selection
    Protected Sub rlvProducts_NeedDataSource(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadListViewNeedDataSourceEventArgs) Handles rlvProducts.NeedDataSource
        Dim dt As DataTable = ProductsTable

        If dt Is Nothing Then
            dt = GetProductsTable()
            ProductsTable = dt
        End If

        Dim searchText As String = ""
        Dim tbSearch As TextBox = CType(rlvProducts.FindControl("tbSearch"), TextBox)
        If tbSearch Is Nothing Then
            searchText = ""
        Else
            searchText = tbSearch.Text.Trim()
        End If


        If Not String.IsNullOrWhiteSpace(searchText) Then
            Dim dv As New DataView(dt)
            Dim safeText As String = searchText.Replace("'", "''")
            dv.RowFilter = "Name LIKE '%" & safeText & "%' OR Code LIKE '%" & safeText & "%' OR Category LIKE '%" & safeText & "%'"
            rlvProducts.DataSource = dv
        Else
            rlvProducts.DataSource = dt
        End If
    End Sub
    Private Sub rlvAccounts_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvAccounts.NeedDataSource
        Dim dt As DataTable = GetAccountsTable()

        Dim searchText As String = ""
        Dim tbSearch As TextBox = CType(rlvAccounts.FindControl("tbSearch"), TextBox)
        If tbSearch Is Nothing Then
            searchText = ""
        Else
            searchText = tbSearch.Text.Trim()
        End If

        If Not String.IsNullOrWhiteSpace(searchText) Then
            Dim dv As New DataView(dt)
            Dim safeText As String = searchText.Replace("'", "''")
            dv.RowFilter = "Name LIKE '%" & safeText & "%' OR NoCompte LIKE '%" & safeText & "%' OR search LIKE '%" & safeText & "%'"
            rlvAccounts.DataSource = dv
        Else
            rlvAccounts.DataSource = dt
        End If
    End Sub

    Private Sub rlvCustomers_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvCustomers.NeedDataSource
        Dim dt As DataTable = GetCustomersTable()



        Dim searchText As String = ""
        Dim tbSearch As TextBox = CType(rlvCustomers.FindControl("tbSearch"), TextBox)
        If tbSearch Is Nothing Then
            searchText = ""
        Else
            searchText = tbSearch.Text.Trim()
        End If


        If Not String.IsNullOrWhiteSpace(searchText) Then
            Dim dv As New DataView(dt)
            Dim safeText As String = searchText.Replace("'", "''")
            dv.RowFilter = "Name LIKE '%" & safeText & "%' OR Code LIKE '%" & safeText & "%' OR Category LIKE '%" & safeText & "%'"
            rlvCustomers.DataSource = dv
        Else
            rlvCustomers.DataSource = dt
        End If
    End Sub
    'Ajout d'un produit: on ajoute une ligne dans le DataTable du ViewState("ProductsTable") et on rebind le RadListView pour afficher le nouveau produit (exemple simple sans formulaire de saisie, juste pour montrer le principe)
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

    'Mise à jour d'un produit: on trouve la ligne correspondante dans le DataTable du ViewState("ProductsTable")
    'en fonction de l'Id, on met à jour les champs avec les nouvelles valeurs,
    'puis on rebind le RadListView pour afficher les changements (exemple simple sans formulaire de saisie, juste pour montrer le principe)
    'Est appeler lors d une selection d un produit
    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        Dim AllParam As String() = e.Argument.Split("|"c)
        Dim CommandName As String = AllParam(0)

        ' L'envoi par courriel est permis même sur une facture comptabilisée.
        If CommandName = "SENDMAIL" Then
            Dim includeSquare As Boolean = (AllParam.Length >= 2 AndAlso AllParam(1) = "1")
            If InvoiceId > 0 Then
                SendInvoiceByEmail(InvoiceId, includeSquare)
            Else
                ShowMsg(L("saveFirst"))
            End If
            Return
        End If

        If Comptabilise Then Return
        Dim ItemLineId As Integer
        Dim CustomerId As Integer
        Dim productId As Integer
        Dim accountId As Integer

        Select Case CommandName
            Case "PRODUCT"

                If Integer.TryParse(AllParam(2), productId) Then
                    If Integer.TryParse(AllParam(1), ItemLineId) Then
                        UpdateItem(ItemLineId, productId)
                        BindItemGrid()
                    End If
                End If
            Case "CUSTOMER"
                If Integer.TryParse(AllParam(1), CustomerId) Then
                    UpdateCustomer(CustomerId)
                End If

            Case "ACCOUNT"
                If Integer.TryParse(AllParam(2), accountId) Then
                    If Integer.TryParse(AllParam(1), ItemLineId) Then
                        UpdateAllItemInViewstate()
                        UpdateItemAccount(ItemLineId, accountId)
                        SetDirtyItem(ItemLineId)

                        BindItemGrid()
                    End If
                End If
        End Select


    End Sub



    Sub SetDirtyItem(ItemLineId As Integer)
        Dim dt As DataTable = CType(ViewState("ItemsTable"), DataTable)
        Dim dr As DataRow = dt.AsEnumerable().FirstOrDefault(Function(r) Convert.ToInt32(r("Id")) = ItemLineId)
        If dr Is Nothing Then Exit Sub
        dr("Dirty") = 1
        ViewState("ItemsTable") = dt
    End Sub





    Sub UpdateCustomer(Customerid As Integer)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@PartyId", Customerid))
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))

        Dim ds As DataSet = ExecuteSQLds("s0037GetCustomerFullById", p)

        Dim Fullanme As String = ds.Tables(0).Rows(0)("FullName").ToString()
        rdLabel.Text = Fullanme
        lblCustomer.Text = ds.Tables(0).Rows(0)("Name").ToString()
        CustomerGUID = ds.Tables(0).Rows(0)("PartyGUID")
    End Sub





    'Mise a jour de la ligne du Viewstate a l aide du productId
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
        dr("AccountId") = AlldsProducts.Tables(0).Rows(0)("Compte")
        dr("AccountName") = AlldsProducts.Tables(0).Rows(0)("AccountName").ToString()
        dr("TaxeStatus") = AlldsProducts.Tables(0).Rows(0)("TaxeStatus")





        ViewState("ItemsTable") = dt




    End Sub

    Sub UpdateItemAccount(ItemLineId As Integer, accountId As Integer)

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@AccountId", accountId))
        ' TODO: adapter le nom de la procédure stockée si nécessaire
        Dim ds As DataSet = ExecuteSQLds("s0083Get_GLAccountById", p)

        Dim dt As DataTable = CType(ViewState("ItemsTable"), DataTable)
        If dt Is Nothing Then Exit Sub

        Dim dr As DataRow = dt.AsEnumerable().
            FirstOrDefault(Function(r) Convert.ToInt32(r("Id")) = ItemLineId)

        If dr Is Nothing Then Exit Sub

        'dr("AccountId") = ds.Tables(0).Rows(0)("Name")
        dr("Dirty") = 1
        dr("Deleted") = 0
        dr("AccountId") = ds.Tables(0).Rows(0)("Nocompte").ToString()
        dr("AccountName") = ds.Tables(0).Rows(0)("Name").ToString()


        ViewState("ItemsTable") = dt
    End Sub

    ''' <summary>
    ''' Envoie la facture (PDF en pièce jointe) au courriel de facturation du client
    ''' via le service de courriels (T400Mails + T402Attachments). Le PDF est généré
    ''' au besoin. Optionnellement, ajoute un lien de paiement Square dans le corps.
    ''' Repris de wbfCustomersInvoices.SendInvoiceByEmail.
    ''' </summary>
    Private Sub SendInvoiceByEmail(invoiceId As Integer, includeSquare As Boolean)

        ' 1. Charger les données de la facture
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@InvoiceId", invoiceId))
        Dim ds As DataSet = ExecuteSQLds("s0696GetInvoiceForEmail", p)
        If ds Is Nothing OrElse ds.Tables(0).Rows.Count = 0 Then
            ShowMsg(L("msgNotFound"))
            Return
        End If
        Dim r As DataRow = ds.Tables(0).Rows(0)

        Dim toEmail As String = If(IsDBNull(r("Email")), "", r("Email").ToString().Trim())
        If toEmail = "" Then
            ShowMsg(L("msgNoEmail"))
            Return
        End If

        ' 2. S'assurer que le PDF existe (sinon le générer)
        If IsDBNull(r("PdfData")) Then
            Dim oGen As New clsGenerateInvoicePDF()
            oGen.GenerateAndDownloadPdf(invoiceId)
            ds = ExecuteSQLds("s0696GetInvoiceForEmail", p)
            r = ds.Tables(0).Rows(0)
        End If
        If IsDBNull(r("PdfData")) Then
            ShowMsg(L("msgPdfFail"))
            Return
        End If

        Dim pdfBytes As Byte() = CType(r("PdfData"), Byte())
        Dim docNumber As String = If(IsDBNull(r("DocumentNumber")), invoiceId.ToString(), r("DocumentNumber").ToString())
        Dim companyName As String = If(IsDBNull(r("CompanyName")), "", r("CompanyName").ToString())
        Dim docGuid As String = If(IsDBNull(r("DocumentGUID")), "", r("DocumentGUID").ToString())
        Dim fileName As String = If(IsDBNull(r("PdfFileName")) OrElse r("PdfFileName").ToString() = "",
                                    "Facture_" & docNumber & ".pdf", r("PdfFileName").ToString())
        Dim companyGuid As Guid = CType(r("CompanyGUID"), Guid)
        Dim reste As Decimal = If(IsDBNull(r("ResteAPayer")), 0D, CDec(r("ResteAPayer")))

        ' 3. Lien de paiement Square (optionnel, sur le solde restant)
        Dim squareLinkHtml As String = ""
        Dim squareNote As String = ""
        If includeSquare Then
            squareLinkHtml = BuildSquarePaymentLink(invoiceId, docNumber, companyName, toEmail, reste, squareNote)
        End If

        ' 4. Corps HTML (+ lien de visualisation en secours)
        Dim viewUrl As String = "https://60sec.ca/InvoicePdf.ashx?g=" & docGuid
        Dim subject As String = "Facture " & docNumber & If(companyName <> "", " — " & companyName, "")
        Dim body As New System.Text.StringBuilder()
        body.Append("<div style=""font-family:Arial,sans-serif;font-size:14px;color:#0f172a"">")
        body.Append("<p>Bonjour,</p>")
        body.Append("<p>Veuillez trouver ci-jointe la facture <strong>").Append(Server.HtmlEncode(docNumber)).Append("</strong>")
        If companyName <> "" Then body.Append(" de ").Append(Server.HtmlEncode(companyName))
        body.Append(".</p>")
        body.Append("<p><a href=""").Append(viewUrl).Append(""" style=""display:inline-block;padding:10px 18px;background:#2563eb;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:700"">Voir la facture (PDF)</a></p>")
        If squareLinkHtml <> "" Then body.Append(squareLinkHtml)
        body.Append("<p>Merci de votre confiance.</p>")
        If companyName <> "" Then body.Append("<p>").Append(Server.HtmlEncode(companyName)).Append("</p>")
        body.Append("</div>")

        ' 5. Insérer le courriel sortant (BD MailService) -> MailId
        Dim pm As New Collection
        pm.Add(New SqlClient.SqlParameter("@To", toEmail))
        pm.Add(New SqlClient.SqlParameter("@Subject", subject))
        pm.Add(New SqlClient.SqlParameter("@HTMLBody", body.ToString()))
        ' Reply-To = courriel vérifié de la compagnie (règle centralisée, sinon NULL)
        CompanyMail.AddReplyToParam(pm, ConnectionString, companyGuid)
        Dim dsm As DataSet = ExecuteSQLdsMail("s0610InsertOutboundMail", pm)
        Dim mailId As Integer = Convert.ToInt32(dsm.Tables(0).Rows(0)(0))

        ' 6. Joindre le PDF (T402Attachments + drapeau HaveAttachment)
        Dim pa As New Collection
        pa.Add(New SqlClient.SqlParameter("@FileName", fileName))
        pa.Add(New SqlClient.SqlParameter("@content", pdfBytes))
        pa.Add(New SqlClient.SqlParameter("@MailId", mailId))
        pa.Add(New SqlClient.SqlParameter("@ContentType", "application/pdf"))
        pa.Add(New SqlClient.SqlParameter("@ContentId", ""))
        ExecuteSQLMail("s1579InsertAttachemnt_A", pa)

        ShowMsg(String.Format(L("msgSent"), docNumber, toEmail) & squareNote)
    End Sub

    ''' <summary>
    ''' Génère un lien de paiement Square (page hébergée) sur le solde restant de la
    ''' facture et retourne le bloc HTML (bouton « Payer ») à insérer dans le courriel.
    ''' Estampille la facture avec le SquareOrderId (réconciliation webhook, s0688).
    ''' Retourne "" si impossible et remplit <paramref name="note"/> avec la raison.
    ''' Repris de wbfCustomersInvoices.BuildSquarePaymentLink.
    ''' </summary>
    Private Function BuildSquarePaymentLink(invoiceId As Integer, docNumber As String,
                                            companyName As String, buyerEmail As String,
                                            reste As Decimal, ByRef note As String) As String
        Try
            If reste <= 0D Then
                note = L("noteAlreadyPaid")
                Return ""
            End If

            Dim token As String = ""
            Try
                token = GetValidSquareAccessToken()
            Catch
            End Try
            If String.IsNullOrEmpty(token) Then
                note = L("noteNotConnected")
                Return ""
            End If

            Dim locationId As String = clsSquare.GetMainLocationId(token)
            Dim cents As Long = CLng(Math.Round(reste * 100D))
            Dim name As String = "Facture #" & docNumber
            Dim linkRes As clsSquare.SquarePaymentLinkResult =
                clsSquare.CreatePaymentLink(token, locationId, cents, name, "Facture client #" & docNumber,
                                            companyName, buyerEmail, UserEmail, Nothing)

            If linkRes Is Nothing OrElse String.IsNullOrEmpty(linkRes.Url) Then
                note = L("noteNotGenerated")
                Return ""
            End If

            ' Réconciliation : estampiller la facture avec le SquareOrderId.
            If Not String.IsNullOrEmpty(linkRes.OrderId) Then
                Dim ps As New Collection
                ps.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
                ps.Add(New SqlClient.SqlParameter("@DocumentId", invoiceId))
                ps.Add(New SqlClient.SqlParameter("@SquareOrderId", linkRes.OrderId))
                ExecuteSQL("s0688LinkDocumentToSquareOrder", ps)
            End If

            Return "<p><a href=""" & linkRes.Url & """ style=""display:inline-block;padding:10px 18px;" &
                   "background:#16a34a;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:700"">" &
                   "Payer maintenant (" & reste.ToString("N2") & " $)</a></p>"
        Catch ex As Exception
            note = L("noteError") & ex.Message & ")"
            Return ""
        End Try
    End Function

    ''' <summary>Affiche un message simple à l'utilisateur (fenêtre du navigateur).</summary>
    Private Sub ShowMsg(msg As String)
        Dim safe As String = msg.Replace("\", "\\").Replace("'", "\'").Replace(ControlChars.Cr, " ").Replace(ControlChars.Lf, " ")
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "invMsg", "alert('" & safe & "');", True)
    End Sub


End Class

