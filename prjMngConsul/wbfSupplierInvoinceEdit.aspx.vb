Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class wbfSupplierInvoinceEdit
    Inherits clsData

    ' =========================================================
    '  PROPRIÉTÉS EN VIEWSTATE
    ' =========================================================

    ''' <summary>Id de la facture fournisseur (0 = nouvelle facture)</summary>
    Property InvoiceId() As Integer
        Get
            Try
                If ViewState("InvoiceId") Is Nothing Then ViewState("InvoiceId") = 0
                Return CInt(ViewState("InvoiceId"))
            Catch
                Return 0
            End Try
        End Get
        Set(value As Integer)
            ViewState("InvoiceId") = value
        End Set
    End Property

    ''' <summary>Cache local de la table produits</summary>
    Private Property ProductsTable As DataTable
        Get
            Return CType(ViewState("ProductsTable"), DataTable)
        End Get
        Set(value As DataTable)
            ViewState("ProductsTable") = value
        End Set
    End Property

    ' =========================================================
    '  PAGE LOAD
    ' =========================================================

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ' Récupérer l'Id depuis la QueryString (?Id=xx ou ?InvoiceId=xx)
            Dim qsId As String = If(Request.QueryString("Id"), Request.QueryString("InvoiceId"))
            Dim parsedId As Integer = 0
            Integer.TryParse(qsId, parsedId)
            InvoiceId = parsedId

            ' Initialiser la table en mémoire et charger depuis la BD si modification
            CreateItemsTable()
            If InvoiceId > 0 Then
                LoadItemTableFromBD()
            End If

            ' Pré-charger les produits
            ProductsTable = GetProductsTable()

            ' Binder les champs de l'en-tête + les lignes
            BindData()
        End If
    End Sub

    ' =========================================================
    '  CRÉATION / CHARGEMENT DE LA TABLE EN MÉMOIRE
    ' =========================================================

    ''' <summary>
    ''' Crée une DataTable vide pour stocker les lignes de facture en ViewState.
    ''' </summary>
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

    ''' <summary>
    ''' Charge les lignes existantes depuis la BD pour la facture fournisseur.
    ''' Procédure SQL à créer : s0039GetSupplierInvoiceItems (@InvoiceId)
    ''' Retourne : Id, ProductId, ProductName, Description, Qty, UnitPrice, Amount
    ''' </summary>
    Public Sub LoadItemTableFromBD()
        Dim p As New Collection
        p.Add(New SqlParameter("@InvoiceId", InvoiceId))

        ' ⚠️ Remplacer par votre procédure stockée fournisseur
        Dim ds As DataSet = ExecuteSQLds("s0039GetInvoiceItems", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return

        Dim dt As DataTable = CType(ViewState("ItemsTable"), DataTable)
        For Each orow As DataRow In ds.Tables(0).Rows
            Dim dr As DataRow = dt.NewRow()
            dr("Id") = orow("Id")
            dr("ProductId") = orow("ProductId")
            dr("ProductName") = orow("ProductName")
            dr("Description") = orow("Description")
            dr("Qty") = orow("Qty")
            dr("UnitPrice") = orow("UnitPrice")
            dr("Amount") = orow("Amount")
            dr("Dirty") = 0
            dr("Deleted") = 0
            dt.Rows.Add(dr)
        Next
    End Sub

    ' =========================================================
    '  BINDING
    ' =========================================================

    ''' <summary>
    ''' Charge et affiche les données de l'en-tête de la facture fournisseur.
    ''' Procédure SQL : s0038GetSupplierInvoiceById (@InvoiceId)
    ''' Retourne : SupplierId, Name, FullName, IssueDate, DueDate, ReceivedDate, PoNumber, RefNo
    ''' </summary>
    Sub BindData()
        If InvoiceId > 0 Then
            Dim p As New Collection
            p.Add(New SqlParameter("@InvoiceId", InvoiceId))

            ' ⚠️ Remplacer par votre procédure stockée fournisseur
            Dim ds As DataSet = ExecuteSQLds("s0038GetInvoiceById", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return

            Dim orow As DataRow = ds.Tables(0).Rows(0)

            ' En-tête facture
            lblSupplier.Text = orow("Name").ToString()
            lblSupplier.Attributes.Add("onclick", "openSupplierPicker(this)")
            rdLabel.Text = orow("FullName").ToString()

            dpIssueDate.SelectedDate = orow("IssueDate")
            dpDueDate.SelectedDate = orow("DueDate")
            dpReceivedDate.SelectedDate = If(IsDBNull(orow("ReceivedDate")), Nothing, orow("ReceivedDate"))
            txtPoNumber.Text = If(IsDBNull(orow("PoNumber")), "", orow("PoNumber").ToString())
            txtRefNo.Text = If(IsDBNull(orow("RefNo")), "", orow("RefNo").ToString())
        Else
            ' Nouvelle facture : onclick sur le label pour ouvrir le picker
            lblSupplier.Attributes.Add("onclick", "openSupplierPicker(this)")
        End If

        BindItemGrid()
    End Sub

    ''' <summary>
    ''' Lie le Repeater avec les lignes du ViewState en excluant les lignes Deleted=1.
    ''' </summary>
    Public Sub BindItemGrid()
        Dim dt As DataTable = CType(ViewState("ItemsTable"), DataTable)
        If dt Is Nothing Then Return

        Dim dv As New DataView(dt)
        dv.RowFilter = "Deleted = 0"
        rpItems.DataSource = dv
        rpItems.DataBind()
    End Sub

    ' =========================================================
    '  MISE À JOUR DU VIEWSTATE DEPUIS LES CONTRÔLES
    ' =========================================================

    ''' <summary>
    ''' Parcourt toutes les lignes du Repeater et met à jour le ViewState("ItemsTable")
    ''' avec les valeurs saisies. À appeler avant toute action (Ajouter, Sauvegarder, Supprimer).
    ''' </summary>
    Sub UpdateAllItemInViewstate()
        Dim dt As DataTable = TryCast(ViewState("ItemsTable"), DataTable)
        If dt Is Nothing Then Return

        For Each item As RepeaterItem In rpItems.Items
            If item.ItemType <> ListItemType.Item AndAlso
               item.ItemType <> ListItemType.AlternatingItem Then Continue For

            Dim hid As HiddenField = TryCast(item.FindControl("hidId"), HiddenField)
            If hid Is Nothing OrElse String.IsNullOrWhiteSpace(hid.Value) Then Continue For

            Dim id As Integer
            If Not Integer.TryParse(hid.Value, id) Then Continue For

            ' Contrôles de la ligne
            Dim txtDesc As RadTextBox = TryCast(item.FindControl("txtDesc"), RadTextBox)
            Dim numQty As RadTextBox = TryCast(item.FindControl("numQty"), RadTextBox)
            Dim numUnitPrice As RadTextBox = TryCast(item.FindControl("numUnitPrice"), RadTextBox)
            Dim hidProduct As HiddenField = TryCast(item.FindControl("hidProductId"), HiddenField)

            Dim description As String = If(txtDesc Is Nothing, "", txtDesc.Text.Trim())
            Dim productId As Integer = If(hidProduct Is Nothing, 0, CInt(If(hidProduct.Value = "", "0", hidProduct.Value)))
            Dim qty As Double = ToDoubleAnyCulture(If(numQty Is Nothing, "0", numQty.Text))
            Dim unitPrice As Double = ToDoubleAnyCulture(If(numUnitPrice Is Nothing, "0", numUnitPrice.Text))
            Dim amount As Double = Math.Round(qty * unitPrice, 2)

            ' Trouver la ligne dans le DataTable
            Dim rows() As DataRow = dt.Select("Id=" & id.ToString())
            If rows Is Nothing OrElse rows.Length = 0 Then Continue For

            Dim dr As DataRow = rows(0)

            ' Ignorer les lignes déjà supprimées
            If dt.Columns.Contains("Deleted") Then
                If Not IsDBNull(dr("Deleted")) AndAlso CInt(dr("Deleted")) = 1 Then Continue For
            End If

            Dim changed As Boolean = False

            ' --- Description ---
            Dim oldDesc As String = If(IsDBNull(dr("Description")), "", CStr(dr("Description")))
            If oldDesc <> description Then
                dr("Description") = description : changed = True
            End If

            ' --- ProductId ---
            Dim oldProductId As Integer = If(IsDBNull(dr("ProductId")), 0, CInt(dr("ProductId")))
            If oldProductId <> productId Then
                dr("ProductId") = productId : changed = True
            End If

            ' --- Qty ---
            Dim oldQty As Double = If(IsDBNull(dr("Qty")), 0, CDbl(dr("Qty")))
            If Math.Abs(oldQty - qty) > 0.0000001 Then
                dr("Qty") = qty : changed = True
            End If

            ' --- UnitPrice ---
            Dim oldUP As Double = If(IsDBNull(dr("UnitPrice")), 0, CDbl(dr("UnitPrice")))
            If Math.Abs(oldUP - unitPrice) > 0.0000001 Then
                dr("UnitPrice") = unitPrice : changed = True
            End If

            ' --- Amount (recalcul) ---
            Dim oldAmt As Double = If(IsDBNull(dr("Amount")), 0, CDbl(dr("Amount")))
            If Math.Abs(oldAmt - amount) > 0.0000001 Then
                dr("Amount") = amount : changed = True
            End If

            If changed Then dr("Dirty") = 1
        Next

        ViewState("ItemsTable") = dt
    End Sub

    ' =========================================================
    '  AJOUTER UNE LIGNE
    ' =========================================================

    ''' <summary>Ajoute une ligne vide dans le ViewState et rebinde.</summary>
    Private Sub btnAddLine_Click(sender As Object, e As EventArgs) Handles btnAddLine.Click
        UpdateAllItemInViewstate()

        Dim dr As DataRow = CType(ViewState("ItemsTable"), DataTable).NewRow()
        dr("Id") = 0
        dr("ProductId") = 0
        dr("ProductName") = ""
        dr("Description") = ""
        dr("Qty") = 1
        dr("UnitPrice") = 0
        dr("Amount") = 0
        dr("Dirty") = 1
        dr("Deleted") = 0
        CType(ViewState("ItemsTable"), DataTable).Rows.Add(dr)

        BindItemGrid()
    End Sub

    ' =========================================================
    '  SAUVEGARDE
    ' =========================================================

    ''' <summary>
    ''' Enregistre l'en-tête et les lignes de la facture fournisseur.
    ''' Procédures SQL à créer :
    '''   s0044SaveSupplierInvoiceHeader (@InvoiceId OUT, @SupplierId, @IssueDate, @DueDate,
    '''                                   @ReceivedDate, @PoNumber, @RefNo, @CompanyGUID)
    '''   s0040SaveSupplierInvoiceItems  (@InvoiceId, @Items TVP_InvoiceItem_v3)
    ''' </summary>
    Private Sub radSave_Click(sender As Object, e As EventArgs) Handles radSave.Click
        UpdateAllItemInViewstate()


        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@SupplierId", 1))
        p.Add(New SqlClient.SqlParameter("@IssueDate", dpIssueDate.SelectedDate))
        p.Add(New SqlClient.SqlParameter("@DueDate", dpDueDate.SelectedDate))
        p.Add(New SqlClient.SqlParameter("@ReceivedDate", If(dpReceivedDate.SelectedDate, DBNull.Value)))
        p.Add(New SqlClient.SqlParameter("@PoNumber", txtPoNumber.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@RefNo", txtRefNo.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))

        Dim ds As DataSet = ExecuteSQLds(" ", p)



        Using conn As New SqlConnection(ConnectionString)
            conn.Open()

            ' --- 1. Sauvegarder l'en-tête ---
            Using cmdHeader As New SqlCommand("s0044SaveSupplierInvoiceHeader", conn)
                cmdHeader.CommandType = CommandType.StoredProcedure

                ' InvoiceId en entrée/sortie (0 = INSERT, >0 = UPDATE)
                Dim pId As New SqlParameter("@InvoiceId", SqlDbType.Int)
                pId.Direction = ParameterDirection.InputOutput
                pId.Value = InvoiceId
                cmdHeader.Parameters.Add(pId)

                ' Récupérer le SupplierId depuis le HiddenField (rempli par le picker JS)
                Dim supplierId As Integer = 0
                Integer.TryParse(hidSelectedSupplierId.Value, supplierId)
                cmdHeader.Parameters.AddWithValue("@SupplierId", supplierId)
                cmdHeader.Parameters.AddWithValue("@IssueDate", dpIssueDate.SelectedDate)
                cmdHeader.Parameters.AddWithValue("@DueDate", dpDueDate.SelectedDate)
                cmdHeader.Parameters.AddWithValue("@ReceivedDate", If(dpReceivedDate.SelectedDate, DBNull.Value))
                cmdHeader.Parameters.AddWithValue("@PoNumber", txtPoNumber.Text.Trim())
                cmdHeader.Parameters.AddWithValue("@RefNo", txtRefNo.Text.Trim())
                cmdHeader.Parameters.AddWithValue("@CompanyGUID", Company)

                cmdHeader.ExecuteNonQuery()

                ' Récupérer l'Id de la nouvelle facture si INSERT
                InvoiceId = CInt(pId.Value)
            End Using

            ' --- 2. Sauvegarder les lignes via TVP ---
            Using cmdItems As New SqlCommand("s0040SaveSupplierInvoiceItems", conn)
                cmdItems.CommandType = CommandType.StoredProcedure

                Dim pInvId As New SqlParameter("@InvoiceId", SqlDbType.Int)
                pInvId.Value = InvoiceId
                cmdItems.Parameters.Add(pInvId)

                Dim pItems As New SqlParameter("@Items", SqlDbType.Structured)
                pItems.Value = CType(ViewState("ItemsTable"), DataTable)
                pItems.TypeName = "dbo.TVP_InvoiceItem_v3"
                cmdItems.Parameters.Add(pItems)

                cmdItems.ExecuteNonQuery()
            End Using
        End Using

        ' Retour à la liste des factures fournisseurs
        Response.Redirect("wbfSuppliersInvoices.aspx")
    End Sub

    ' =========================================================
    '  COMMANDES DU REPEATER (Supprimer / Réordonner)
    ' =========================================================

    ''' <summary>
    ''' Gère les commandes sur les lignes : DeleteLine, Up, Down.
    ''' </summary>
    Private Sub rpItems_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rpItems.ItemCommand

        Select Case e.CommandName

            Case "DeleteLine"
                UpdateAllItemInViewstate()

                Dim id As Integer = CInt(e.CommandArgument)
                Dim dt As DataTable = CType(ViewState("ItemsTable"), DataTable)
                For Each dr As DataRow In dt.Rows
                    If CInt(dr("Id")) = id Then
                        dr("Deleted") = 1
                        dr("Dirty") = 1
                        Exit For
                    End If
                Next
                BindItemGrid()

            Case "Up"
                UpdateAllItemInViewstate()
                MoveRow(CInt(e.CommandArgument), -1)
                BindItemGrid()

            Case "Down"
                UpdateAllItemInViewstate()
                MoveRow(CInt(e.CommandArgument), 1)
                BindItemGrid()

        End Select
    End Sub

    ''' <summary>
    ''' Déplace une ligne d'une position vers le haut (direction=-1) ou le bas (direction=1)
    ''' dans la DataView filtrée (Deleted=0).
    ''' </summary>
    Private Sub MoveRow(id As Integer, direction As Integer)
        Dim dt As DataTable = CType(ViewState("ItemsTable"), DataTable)
        If dt Is Nothing Then Return

        ' Construire la liste ordonnée des lignes visibles
        Dim visible As List(Of DataRow) = dt.AsEnumerable().
            Where(Function(r) CInt(r("Deleted")) = 0).ToList()

        Dim idx As Integer = visible.FindIndex(Function(r) CInt(r("Id")) = id)
        If idx < 0 Then Return

        Dim newIdx As Integer = idx + direction
        If newIdx < 0 OrElse newIdx >= visible.Count Then Return

        ' Permuter les lignes dans le DataTable réel
        Dim rowA As DataRow = visible(idx)
        Dim rowB As DataRow = visible(newIdx)

        ' Permuter par échange de toutes les colonnes de données
        For Each col As DataColumn In dt.Columns
            Dim tmp As Object = rowA(col)
            rowA(col) = rowB(col)
            rowB(col) = tmp
        Next
    End Sub

    ' =========================================================
    '  DATABOUND DU REPEATER
    ' =========================================================

    ''' <summary>
    ''' Pour chaque ligne du Repeater : configure le onclick du sélecteur produit.
    ''' </summary>
    Private Sub rpItems_ItemDataBound(sender As Object, e As RepeaterItemEventArgs) Handles rpItems.ItemDataBound
        If e.Item.ItemType <> ListItemType.Item AndAlso
           e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim lblProduct As Label = TryCast(e.Item.FindControl("lblProduct"), Label)
        If lblProduct Is Nothing Then Return

        Dim id As Integer = DataBinder.Eval(e.Item.DataItem, "Id")
        lblProduct.Attributes.Add("onclick", "openProductPicker(this," & id & ")")
        lblProduct.Text = DataBinder.Eval(e.Item.DataItem, "ProductName").ToString()
    End Sub

    ' =========================================================
    '  BINDING DES LISTES (NeedDataSource)
    ' =========================================================

    ''' <summary>Fournit les données au RadListView des produits.</summary>
    Protected Sub rlvProducts_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs)
        Dim dt As DataTable = ProductsTable
        If dt Is Nothing Then
            dt = GetProductsTable()
            ProductsTable = dt
        End If
        rlvProducts.DataSource = dt
    End Sub

    ''' <summary>Fournit les données au RadListView des fournisseurs.</summary>
    Private Sub rlvSuppliers_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvSuppliers.NeedDataSource
        rlvSuppliers.DataSource = GetSuppliersTable()
    End Sub

    ' =========================================================
    '  REQUÊTES AJAX (PRODUCT / SUPPLIER)
    ' =========================================================

    ''' <summary>
    ''' Traite les requêtes AJAX émises par les pickers JS.
    ''' Protocole : "PRODUCT|{itemLineId}|{productCode}"
    '''             "SUPPLIER|{supplierId}"
    ''' </summary>
    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        Dim parts() As String = e.Argument.Split("|"c)
        If parts.Length = 0 Then Return

        Select Case parts(0)

            Case "PRODUCT"
                ' Mettre à jour une ligne avec le produit sélectionné
                Dim itemLineId As Integer = 0
                Dim productCode As String = ""
                If parts.Length >= 3 Then
                    Integer.TryParse(parts(1), itemLineId)
                    productCode = parts(2)
                End If
                If productCode <> "" Then
                    UpdateItemByProductCode(itemLineId, productCode)
                    BindItemGrid()
                End If

            Case "SUPPLIER"
                ' Mettre à jour l'affichage du fournisseur sélectionné
                Dim supplierId As Integer = 0
                If parts.Length >= 2 AndAlso Integer.TryParse(parts(1), supplierId) Then
                    UpdateSupplierDisplay(supplierId)
                End If

        End Select
    End Sub

    ''' <summary>
    ''' Met à jour l'affichage du fournisseur (label + adresse).
    ''' Procédure SQL : s0037GetSupplierFullById (@PartyId)
    ''' Retourne : Name, FullName
    ''' </summary>
    Sub UpdateSupplierDisplay(supplierId As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@PartyId", supplierId))

        ' ⚠️ Remplacer par votre procédure stockée fournisseur
        Dim ds As DataSet = ExecuteSQLds("s0037GetSupplierFullById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

        Dim orow As DataRow = ds.Tables(0).Rows(0)
        lblSupplier.Text = orow("Name").ToString()
        rdLabel.Text = orow("FullName").ToString()
    End Sub

    ''' <summary>
    ''' Met à jour la ligne du ViewState avec les infos du produit sélectionné (par Code).
    ''' Procédure SQL : s0042GetProductByCode (@ProductCode)
    ''' Retourne : Id, Name, Description, Prix
    ''' </summary>
    Sub UpdateItemByProductCode(itemLineId As Integer, productCode As String)
        Dim p As New Collection
        p.Add(New SqlParameter("@ProductCode", productCode))

        Dim ds As DataSet = ExecuteSQLds("s0042GetProductByCode", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

        Dim prodRow As DataRow = ds.Tables(0).Rows(0)

        Dim dt As DataTable = CType(ViewState("ItemsTable"), DataTable)
        If dt Is Nothing Then Return

        Dim dr As DataRow = dt.AsEnumerable().
            FirstOrDefault(Function(r) CInt(r("Id")) = itemLineId)
        If dr Is Nothing Then Return

        dr("ProductId") = CInt(prodRow("Id"))
        dr("ProductName") = prodRow("Name").ToString()
        dr("Description") = prodRow("Description").ToString()
        dr("UnitPrice") = CDbl(prodRow("Prix"))
        dr("Qty") = 1
        dr("Amount") = 0D
        dr("Deleted") = 0
        dr("Dirty") = 1

        ViewState("ItemsTable") = dt
    End Sub

    ' =========================================================
    '  DONNÉES DEPUIS LA BD
    ' =========================================================

    ''' <summary>Retourne la liste des produits pour le picker.</summary>
    Private Function GetProductsTable() As DataTable
        ' ⚠️ Même procédure que les factures clients
        Dim ds As DataSet = ExecuteSQLds("s0041GetProducts")
        Return If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
    End Function

    ''' <summary>
    ''' Retourne la liste des fournisseurs pour le picker.
    ''' Procédure SQL : s0043Get_Supplier
    ''' Retourne : Id, ContactName, BillingTo, search
    ''' </summary>
    Private Function GetSuppliersTable() As DataTable
        ' ⚠️ Remplacer par votre procédure stockée fournisseurs
        Dim ds As DataSet = ExecuteSQLds("s0043Get_Party")
        Return If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
    End Function

    ' =========================================================
    '  BOUTON AJOUT PRODUIT (placeholder)
    ' =========================================================

    ''' <summary>Placeholder — à implémenter si nécessaire.</summary>
    Protected Sub btnAddProducts_Click(sender As Object, e As EventArgs)
        Return
    End Sub

End Class
