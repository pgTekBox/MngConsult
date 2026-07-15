Imports Telerik.Web.UI

Public Class wbfProductEdit
    Inherits clsData

    Property ProductId() As Integer
        Get
            Try
                If ViewState("ProductId") Is Nothing Then ViewState("ProductId") = 0
                Return CInt(ViewState("ProductId"))
            Catch ex As Exception
                Return 0
            End Try
        End Get
        Set(ByVal Value As Integer)
            ViewState("ProductId") = Value
        End Set
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            BindDDL()
            ProductId = CInt(Request.QueryString("Id"))
            BindData()
        End If
        ApplyLocalization()
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux libellés statiques (Literal) et contrôles serveur.
    ''' lblTitle/lblSub sont gérés dans BindData (dépendent du mode new/edit).</summary>
    Private Sub ApplyLocalization()
        Page.Title = L("pageTitle")
        btnSave.Text = L("save")
        btnCancel.Text = L("close")
        rddlCategory.DefaultMessage = L("noCategory")
        rddlTaxeStatus.DefaultMessage = L("select")
        rddlCompteVente.DefaultMessage = L("useCategoryAccount")
        rddlCompteAchat.DefaultMessage = L("useCategoryAccount")

        If rddlTaxeStatus.Items.Count >= 3 Then
            rddlTaxeStatus.Items(0).Text = L("taxTaxable")
            rddlTaxeStatus.Items(1).Text = L("taxExempt")
            rddlTaxeStatus.Items(2).Text = L("taxZeroRated")
        End If

        SetLiteral(Me, "litInfoGeneral", L("infoGeneral"))
        SetLiteral(Me, "litNameLabel", L("nameLabel"))
        SetLiteral(Me, "litCategory", L("category"))
        SetLiteral(Me, "litDescription", L("description"))
        SetLiteral(Me, "litPriceQty", L("priceQty"))
        SetLiteral(Me, "litUnitPrice", L("unitPrice"))
        SetLiteral(Me, "litDefaultQty", L("defaultQty"))
        SetLiteral(Me, "litTaxStatus", L("taxStatus"))
        SetLiteral(Me, "litAddToInvoice", L("addToInvoice"))
        SetLiteral(Me, "litGlAccounts", L("glAccounts"))
        SetLiteral(Me, "litGlHint", L("glHint"))
        SetLiteral(Me, "litSaleAccount", L("saleAccount"))
        SetLiteral(Me, "litPurchaseAccount", L("purchaseAccount"))
        SetLiteral(Me, "litActiveProduct", L("activeProduct"))
        SetLiteral(Me, "litIdLabel", L("idLabel"))
        SetLiteral(Me, "litCreatedLabel", L("createdLabel"))
    End Sub

    ''' <summary>Traductions de l'interface Édition produit (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Produit — Édition", "Product — Edit", "Producto — Edición")
            Case "titleNew" : Return Choose3(lang, "Nouveau produit", "New product", "Nuevo producto")
            Case "titleEdit" : Return Choose3(lang, "Modifier le produit", "Edit product", "Editar producto")
            Case "subNew" : Return Choose3(lang, "Remplissez les informations du produit ou service", "Fill in the product or service information", "Complete la información del producto o servicio")
            Case "save" : Return Choose3(lang, "Enregistrer", "Save", "Guardar")
            Case "close" : Return Choose3(lang, "Fermer", "Close", "Cerrar")
            Case "infoGeneral" : Return Choose3(lang, "Informations générales", "General information", "Información general")
            Case "nameLabel" : Return Choose3(lang, "Nom du produit / service *", "Product / service name *", "Nombre del producto / servicio *")
            Case "category" : Return Choose3(lang, "Catégorie", "Category", "Categoría")
            Case "noCategory" : Return Choose3(lang, "Aucune catégorie", "No category", "Sin categoría")
            Case "description" : Return Choose3(lang, "Description", "Description", "Descripción")
            Case "priceQty" : Return Choose3(lang, "Prix et quantités", "Price and quantities", "Precio y cantidades")
            Case "unitPrice" : Return Choose3(lang, "Prix unitaire ($)", "Unit price ($)", "Precio unitario ($)")
            Case "defaultQty" : Return Choose3(lang, "Quantité par défaut", "Default quantity", "Cantidad predeterminada")
            Case "taxStatus" : Return Choose3(lang, "Statut de taxe", "Tax status", "Estado de impuesto")
            Case "select" : Return Choose3(lang, "Sélectionner…", "Select…", "Seleccionar…")
            Case "taxTaxable" : Return Choose3(lang, "Taxable", "Taxable", "Gravable")
            Case "taxExempt" : Return Choose3(lang, "Exempt", "Exempt", "Exento")
            Case "taxZeroRated" : Return Choose3(lang, "Détaxé", "Zero-rated", "Tasa cero")
            Case "addToInvoice" : Return Choose3(lang, "Ajouter auto aux factures", "Auto-add to invoices", "Agregar automáticamente a facturas")
            Case "glAccounts" : Return Choose3(lang, "Comptes du plan comptable", "Chart of accounts", "Cuentas del plan contable")
            Case "glHint" : Return Choose3(lang, "Ces comptes remplacent ceux de la catégorie pour ce produit spécifique. Laissez vide pour utiliser les comptes de la catégorie.", "These accounts override the category's for this specific product. Leave empty to use the category accounts.", "Estas cuentas reemplazan las de la categoría para este producto específico. Deje vacío para usar las cuentas de la categoría.")
            Case "saleAccount" : Return Choose3(lang, "Compte de vente (Revenus)", "Sales account (Revenue)", "Cuenta de venta (Ingresos)")
            Case "purchaseAccount" : Return Choose3(lang, "Compte d'achat (Coût / Charges)", "Purchase account (Cost / Expenses)", "Cuenta de compra (Costo / Gastos)")
            Case "useCategoryAccount" : Return Choose3(lang, "Utiliser le compte de la catégorie", "Use the category account", "Usar la cuenta de la categoría")
            Case "activeProduct" : Return Choose3(lang, "Produit actif", "Active product", "Producto activo")
            Case "idLabel" : Return Choose3(lang, "ID :", "ID:", "ID:")
            Case "createdLabel" : Return Choose3(lang, "Créé le :", "Created on:", "Creado el:")
            Case "nameRequired" : Return Choose3(lang, "Le nom du produit est obligatoire.", "The product name is required.", "El nombre del producto es obligatorio.")
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

    Private Shared Sub SetLiteral(root As Control, id As String, text As String)
        Dim lit = TryCast(FindDeep(root, id), Literal)
        If lit IsNot Nothing Then lit.Text = text
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

    ' ── Chargement des listes déroulantes ──

    Sub BindDDL()
        ' Catégories
        Dim pCat As New Collection
        pCat.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        SetDDL(rddlCategory, "Name", "Value", "s0081GetCategoriesForDDL", pCat)

        ' Comptes de vente (Revenus — classe parente 6)
        Dim pVente As New Collection
        pVente.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        pVente.Add(New SqlClient.SqlParameter("@ClasseParentIds", "6"))
        SetDDL(rddlCompteVente, "Name", "Value", "s0059GetComptesForDDL", pVente)

        ' Comptes d'achat (CDV + Charges — classes parentes 7,8)
        Dim pAchat As New Collection
        pAchat.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        pAchat.Add(New SqlClient.SqlParameter("@ClasseParentIds", "7,8"))
        SetDDL(rddlCompteAchat, "Name", "Value", "s0059GetComptesForDDL", pAchat)
    End Sub

    ' ── Chargement des données ──

    Sub BindData()
        If ProductId = 0 Then
            ' Nouveau produit
            lblTitle.Text = L("titleNew")
            lblSub.Text = L("subNew")
            txtName.Text = ""
            txtDescription.Text = ""
            txtPrix.Value = Nothing
            txtDefaultQty.Value = 1
            chkActif.Checked = True
            chkAddToNewInvoice.Checked = False
            pnlInfo.Visible = False
        Else
            ' Produit existant
            lblTitle.Text = L("titleEdit")

            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Id", ProductId))
            Dim ds As DataSet = ExecuteSQLds("s0077GetOneProduct", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

            Dim row As DataRow = ds.Tables(0).Rows(0)

            txtName.Text = row("Name").ToString()
            txtDescription.Text = If(IsDBNull(row("Description")), "", row("Description").ToString())

            If Not IsDBNull(row("Prix")) Then txtPrix.Value = CDec(row("Prix"))
            If Not IsDBNull(row("DefaultQty")) Then txtDefaultQty.Value = CDec(row("DefaultQty"))

            chkAddToNewInvoice.Checked = (Not IsDBNull(row("AddToNewInvoice")) AndAlso CInt(row("AddToNewInvoice")) = 1)
            chkActif.Checked = (Not IsDBNull(row("Actif")) AndAlso CBool(row("Actif")))

            ' Catégorie
            If Not IsDBNull(row("CategoryId")) AndAlso CInt(row("CategoryId")) > 0 Then
                Try : rddlCategory.SelectedValue = row("CategoryId").ToString() : Catch : End Try
            End If

            ' Taxe
            If Not IsDBNull(row("TaxeStatusId")) Then
                Try : rddlTaxeStatus.SelectedValue = row("TaxeStatusId").ToString() : Catch : End Try
            End If

            ' Comptes
            If Not IsDBNull(row("CompteVente")) AndAlso row("CompteVente").ToString() <> "" Then
                Try : rddlCompteVente.SelectedValue = row("CompteVente").ToString() : Catch : End Try
            End If

            If Not IsDBNull(row("CompteAchat")) AndAlso row("CompteAchat").ToString() <> "" Then
                Try : rddlCompteAchat.SelectedValue = row("CompteAchat").ToString() : Catch : End Try
            End If

            lblSub.Text = row("Name").ToString()

            ' Info
            pnlInfo.Visible = True
            tlblId.Text = row("Id").ToString()
            If Not IsDBNull(row("Created")) Then
                tlblCreated.Text = CDate(row("Created")).ToString("yyyy-MM-dd HH:mm")
            End If
        End If
    End Sub

    ' ── Sauvegarde ──

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click

        If String.IsNullOrWhiteSpace(txtName.Text) Then
            ShowMsg(L("nameRequired"), False)
            Return
        End If

        If ProductId = 0 Then
            InsertProduct()
        Else
            UpdateProduct()
        End If

        ' Fermer la fenêtre
        Dim script As String = "function fw(){closeWin(); Sys.Application.remove_load(fw);}Sys.Application.add_load(fw);"
        ScriptManager.RegisterStartupScript(Page, Page.GetType(), "close", script, True)
    End Sub

    Private Sub InsertProduct()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Name", txtName.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Description", DbNullIfEmpty(txtDescription.Text)))
        p.Add(New SqlClient.SqlParameter("@Prix", If(txtPrix.Value IsNot Nothing, CDec(txtPrix.Value), CDec(0))))
        p.Add(New SqlClient.SqlParameter("@DefaultQty", If(txtDefaultQty.Value IsNot Nothing, CDec(txtDefaultQty.Value), CDec(1))))
        p.Add(New SqlClient.SqlParameter("@AddToNewInvoice", If(chkAddToNewInvoice.Checked, 1, 0)))
        p.Add(New SqlClient.SqlParameter("@NoTaxe", 0))
        p.Add(New SqlClient.SqlParameter("@CategoryId", DbNullOrInt(rddlCategory.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@CompteVente", DbNullIfEmpty(rddlCompteVente.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@CompteAchat", DbNullIfEmpty(rddlCompteAchat.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@TaxeStatusId", DbNullOrInt(rddlTaxeStatus.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@Actif", chkActif.Checked))

        Dim ds As DataSet = ExecuteSQLds("s0079InsertProduct", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            ProductId = CInt(ds.Tables(0).Rows(0)(0))
        End If
    End Sub

    Private Sub UpdateProduct()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Id", ProductId))
        p.Add(New SqlClient.SqlParameter("@Name", txtName.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Description", DbNullIfEmpty(txtDescription.Text)))
        p.Add(New SqlClient.SqlParameter("@Prix", If(txtPrix.Value IsNot Nothing, CDec(txtPrix.Value), CDec(0))))
        p.Add(New SqlClient.SqlParameter("@DefaultQty", If(txtDefaultQty.Value IsNot Nothing, CDec(txtDefaultQty.Value), CDec(1))))
        p.Add(New SqlClient.SqlParameter("@AddToNewInvoice", If(chkAddToNewInvoice.Checked, 1, 0)))
        p.Add(New SqlClient.SqlParameter("@NoTaxe", 0))
        p.Add(New SqlClient.SqlParameter("@CategoryId", DbNullOrInt(rddlCategory.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@CompteVente", DbNullIfEmpty(rddlCompteVente.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@CompteAchat", DbNullIfEmpty(rddlCompteAchat.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@TaxeStatusId", DbNullOrInt(rddlTaxeStatus.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@Actif", chkActif.Checked))

        ExecuteSQL("s0080UpdateProduct", p)
    End Sub

    ' ── Utilitaires ──

    Private Sub ShowMsg(msg As String, success As Boolean)
        lblMsg.Visible = True
        lblMsg.CssClass = If(success, "msg msg-ok", "msg msg-err")
        lblMsg.Text = msg
    End Sub

    Private Function DbNullIfEmpty(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Return s.Trim()
    End Function

    Private Function DbNullOrInt(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Dim v As Integer
        If Integer.TryParse(s, v) AndAlso v > 0 Then Return v
        Return DBNull.Value
    End Function

End Class
