Imports Telerik.Web.UI

Public Class wbfProductCategoryEdit
    Inherits clsData

    Property CategoryId() As Integer
        Get
            Try
                If ViewState("CategoryId") Is Nothing Then ViewState("CategoryId") = 0
                Return CInt(ViewState("CategoryId"))
            Catch ex As Exception
                Return 0
            End Try
        End Get
        Set(ByVal Value As Integer)
            ViewState("CategoryId") = Value
        End Set
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            BindDDL()
            CategoryId = CInt(Request.QueryString("Id"))
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
        rddlTaxeStatus.DefaultMessage = L("select")
        rddlCompteVente.DefaultMessage = L("noAccount")
        rddlCompteAchat.DefaultMessage = L("noAccount")

        If rddlTaxeStatus.Items.Count >= 3 Then
            rddlTaxeStatus.Items(0).Text = L("taxTaxable")
            rddlTaxeStatus.Items(1).Text = L("taxExempt")
            rddlTaxeStatus.Items(2).Text = L("taxZeroRated")
        End If

        SetLiteral(Me, "litInfoGeneral", L("infoGeneral"))
        SetLiteral(Me, "litCodeLabel", L("codeLabel"))
        SetLiteral(Me, "litNameLabel", L("nameLabel"))
        SetLiteral(Me, "litDescription", L("description"))
        SetLiteral(Me, "litTaxStatusDefault", L("taxStatusDefault"))
        SetLiteral(Me, "litActiveCategory", L("activeCategory"))
        SetLiteral(Me, "litGlAccounts", L("glAccounts"))
        SetLiteral(Me, "litGlHint", L("glHint"))
        SetLiteral(Me, "litSaleAccount", L("saleAccount"))
        SetLiteral(Me, "litPurchaseAccount", L("purchaseAccount"))
        SetLiteral(Me, "litIdLabel", L("idLabel"))
        SetLiteral(Me, "litGuidLabel", L("guidLabel"))
        SetLiteral(Me, "litCreatedLabel", L("createdLabel"))
        SetLiteral(Me, "litOrdreLabel", L("ordreLabel"))
    End Sub

    ''' <summary>Traductions de l'interface Édition catégorie (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Catégorie de produit — Édition", "Product category — Edit", "Categoría de producto — Edición")
            Case "titleNew" : Return Choose3(lang, "Nouvelle catégorie", "New category", "Nueva categoría")
            Case "titleEdit" : Return Choose3(lang, "Modifier la catégorie", "Edit category", "Editar categoría")
            Case "subNew" : Return Choose3(lang, "Remplissez les informations de la catégorie de produit", "Fill in the product category information", "Complete la información de la categoría de producto")
            Case "save" : Return Choose3(lang, "Enregistrer", "Save", "Guardar")
            Case "close" : Return Choose3(lang, "Fermer", "Close", "Cerrar")
            Case "infoGeneral" : Return Choose3(lang, "Informations générales", "General information", "Información general")
            Case "codeLabel" : Return Choose3(lang, "Code *", "Code *", "Código *")
            Case "nameLabel" : Return Choose3(lang, "Nom *", "Name *", "Nombre *")
            Case "description" : Return Choose3(lang, "Description", "Description", "Descripción")
            Case "taxStatusDefault" : Return Choose3(lang, "Statut de taxe par défaut", "Default tax status", "Estado de impuesto predeterminado")
            Case "select" : Return Choose3(lang, "Sélectionner…", "Select…", "Seleccionar…")
            Case "taxTaxable" : Return Choose3(lang, "Taxable", "Taxable", "Gravable")
            Case "taxExempt" : Return Choose3(lang, "Exempt", "Exempt", "Exento")
            Case "taxZeroRated" : Return Choose3(lang, "Détaxé", "Zero-rated", "Tasa cero")
            Case "activeCategory" : Return Choose3(lang, "Catégorie active", "Active category", "Categoría activa")
            Case "glAccounts" : Return Choose3(lang, "Comptes du plan comptable", "Chart of accounts", "Cuentas del plan contable")
            Case "glHint" : Return Choose3(lang, "Associez un compte de revenus et un compte d'achats/coût des ventes à cette catégorie. Ces comptes seront utilisés automatiquement lors de la facturation.", "Link a revenue account and a purchases/cost-of-sales account to this category. These accounts are used automatically during invoicing.", "Asocie una cuenta de ingresos y una cuenta de compras/costo de ventas a esta categoría. Estas cuentas se usan automáticamente durante la facturación.")
            Case "saleAccount" : Return Choose3(lang, "Compte de vente (Revenus)", "Sales account (Revenue)", "Cuenta de venta (Ingresos)")
            Case "purchaseAccount" : Return Choose3(lang, "Compte d'achat (Coût des ventes / Charges)", "Purchase account (Cost of sales / Expenses)", "Cuenta de compra (Costo de ventas / Gastos)")
            Case "noAccount" : Return Choose3(lang, "Aucun compte sélectionné", "No account selected", "Ninguna cuenta seleccionada")
            Case "idLabel" : Return Choose3(lang, "ID :", "ID:", "ID:")
            Case "guidLabel" : Return Choose3(lang, "GUID :", "GUID:", "GUID:")
            Case "createdLabel" : Return Choose3(lang, "Créé le :", "Created on:", "Creado el:")
            Case "ordreLabel" : Return Choose3(lang, "Ordre :", "Order:", "Orden:")
            Case "codeRequired" : Return Choose3(lang, "Le code est obligatoire.", "The code is required.", "El código es obligatorio.")
            Case "nameRequired" : Return Choose3(lang, "Le nom est obligatoire.", "The name is required.", "El nombre es obligatorio.")
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
        ' Comptes de revenus (classe parente 6 = Revenus, numéros 4000-4499)
        Dim pVente As New Collection
        pVente.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        pVente.Add(New SqlClient.SqlParameter("@ClasseParentIds", "6"))  ' Revenus
        SetDDL(rddlCompteVente, "Name", "Value", "s0059GetComptesForDDL", pVente)

        ' Comptes d'achat / CMV (classe parente 7 = CDV + 8 = Charges d'exploitation)
        Dim pAchat As New Collection
        pAchat.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        pAchat.Add(New SqlClient.SqlParameter("@ClasseParentIds", "7,8"))  ' CDV + Charges
        SetDDL(rddlCompteAchat, "Name", "Value", "s0059GetComptesForDDL", pAchat)
    End Sub

    ' ── Chargement des données ──

    Sub BindData()
        If CategoryId = 0 Then
            ' Nouvelle catégorie
            lblTitle.Text = L("titleNew")
            lblSub.Text = L("subNew")
            txtCode.Text = ""
            txtName.Text = ""
            txtDescription.Text = ""
            chkActif.Checked = True
            pnlInfo.Visible = False
        Else
            ' Catégorie existante
            lblTitle.Text = L("titleEdit")

            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Id", CategoryId))
            Dim ds As DataSet = ExecuteSQLds("s0057GetOneProductCategory", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

            Dim row As DataRow = ds.Tables(0).Rows(0)

            txtCode.Text = row("Code").ToString()
            txtName.Text = row("Name").ToString()
            txtDescription.Text = If(IsDBNull(row("Description")), "", row("Description").ToString())
            chkActif.Checked = CBool(row("Actif"))

            ' Taxe
            If Not IsDBNull(row("TaxeStatusDefault")) Then
                rddlTaxeStatus.SelectedValue = row("TaxeStatusDefault").ToString()
            End If

            ' Comptes du plan comptable
            If Not IsDBNull(row("CompteVente")) AndAlso CInt(row("CompteVente")) > 0 Then
                Try
                    rddlCompteVente.SelectedValue = row("CompteVente").ToString()
                Catch
                End Try
            End If

            If Not IsDBNull(row("CompteAchat")) AndAlso CInt(row("CompteAchat")) > 0 Then
                Try
                    rddlCompteAchat.SelectedValue = row("CompteAchat").ToString()
                Catch
                End Try
            End If

            lblSub.Text = row("Code").ToString() & " — " & row("Name").ToString()

            ' Info
            pnlInfo.Visible = True
            tlblId.Text = row("Id").ToString()
            If Not IsDBNull(row("CategoryGUID")) Then
                tlblGuid.Text = row("CategoryGUID").ToString()
            End If
            If Not IsDBNull(row("Created")) Then
                tlblCreated.Text = CDate(row("Created")).ToString("yyyy-MM-dd HH:mm")
            End If
            If Not IsDBNull(row("Ordre")) Then
                tlblOrdre.Text = row("Ordre").ToString()
            End If
        End If
    End Sub

    ' ── Sauvegarde ──

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click

        ' Validation
        If String.IsNullOrWhiteSpace(txtCode.Text) Then
            ShowMsg(L("codeRequired"), False)
            Return
        End If
        If String.IsNullOrWhiteSpace(txtName.Text) Then
            ShowMsg(L("nameRequired"), False)
            Return
        End If

        If CategoryId = 0 Then
            InsertCategory()
        Else
            UpdateCategory()
        End If

        ' Fermer la fenêtre
        Dim script As String = "function fw(){closeWin(); Sys.Application.remove_load(fw);}Sys.Application.add_load(fw);"
        ScriptManager.RegisterStartupScript(Page, Page.GetType(), "close", script, True)
    End Sub

    Private Sub InsertCategory()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Code", txtCode.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Name", txtName.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Description", DbNullIfEmpty(txtDescription.Text)))
        p.Add(New SqlClient.SqlParameter("@CompteVente", DbNullOrInt(rddlCompteVente.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@CompteAchat", DbNullOrInt(rddlCompteAchat.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@TaxeStatusDefault", DbNullOrInt(rddlTaxeStatus.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@Actif", chkActif.Checked))

        Dim ds As DataSet = ExecuteSQLds("s0060InsertProductCategory", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            CategoryId = CInt(ds.Tables(0).Rows(0)(0))
        End If
    End Sub

    Private Sub UpdateCategory()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Id", CategoryId))
        p.Add(New SqlClient.SqlParameter("@Code", txtCode.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Name", txtName.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Description", DbNullIfEmpty(txtDescription.Text)))
        p.Add(New SqlClient.SqlParameter("@CompteVente", DbNullOrInt(rddlCompteVente.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@CompteAchat", DbNullOrInt(rddlCompteAchat.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@TaxeStatusDefault", DbNullOrInt(rddlTaxeStatus.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@Actif", chkActif.Checked))

        ExecuteSQL("s0061UpdateProductCategory", p)
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
