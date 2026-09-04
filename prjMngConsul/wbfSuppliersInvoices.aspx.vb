Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class wbfSuppliersInvoices
    Inherits clsData

    Public SupplierInvoiceId As Integer

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ApplyLocalization()

        If Not IsPostBack Then
            BindFilters()
            rgFournisseursFactures.Rebind()
        End If
    End Sub

    ' =====================================================================
    ' Filtres à sélection multiple (état comptable / statut de paiement)
    ' ---------------------------------------------------------------------
    ' Les valeurs envoyées à s0023 sont celles produites par la procédure,
    ' jamais les libellés traduits. Rien de coché = aucun filtre.
    ' =====================================================================

    ''' <summary>Remplit les deux listes déroulantes à cases à cocher.</summary>
    Private Sub BindFilters()
        ' « Check All » de Telerik est en anglais par défaut.
        rcbEtat.Localization.CheckAllString = L("checkAll")
        rcbStatutPaiement.Localization.CheckAllString = L("checkAll")

        rcbEtat.EmptyMessage = L("filterStateAll")
        rcbEtat.Items.Clear()
        rcbEtat.Items.Add(New RadComboBoxItem(L("stDraft"), "Brouillon"))
        rcbEtat.Items.Add(New RadComboBoxItem(L("stPosted"), "Comptabilisé"))

        rcbStatutPaiement.EmptyMessage = L("filterPayAll")
        rcbStatutPaiement.Items.Clear()
        rcbStatutPaiement.Items.Add(New RadComboBoxItem(L("payOpen"), "OUVERTE"))
        rcbStatutPaiement.Items.Add(New RadComboBoxItem(L("payPartial"), "PARTIELLE"))
        rcbStatutPaiement.Items.Add(New RadComboBoxItem(L("payPaid"), "PAYEE"))

        ' Persistance : on retrouve ses filtres en revenant sur la page.
        RestoreChecked(rcbEtat, TryCast(Session("SuppInv.Etats"), String))
        RestoreChecked(rcbStatutPaiement, TryCast(Session("SuppInv.Paiements"), String))
    End Sub

    ''' <summary>Recoche les valeurs mémorisées et remet le texte du champ.</summary>
    Private Sub RestoreChecked(rcb As RadComboBox, csv As String)
        If String.IsNullOrEmpty(csv) Then Return
        Dim voulues As New List(Of String)(csv.Split(","c))
        Dim libelles As New List(Of String)
        For Each it As RadComboBoxItem In rcb.Items
            If voulues.Contains(it.Value) Then
                it.Checked = True
                libelles.Add(it.Text)
            End If
        Next
        If libelles.Count > 0 Then rcb.Text = String.Join(", ", libelles)
    End Sub

    ''' <summary>Mémorise l'état des deux filtres pour la prochaine visite.</summary>
    Private Sub SaveFilterState()
        Session("SuppInv.Etats") = CheckedCsv(rcbEtat)
        Session("SuppInv.Paiements") = CheckedCsv(rcbStatutPaiement)
    End Sub

    ''' <summary>Une case cochée/décochée dans l'un des filtres : on recharge la grille.</summary>
    Protected Sub rcbFiltre_ItemChecked(sender As Object, e As RadComboBoxItemEventArgs)
        SaveFilterState()
        rgFournisseursFactures.Rebind()
    End Sub

    ''' <summary>Valeurs cochées d'un filtre, en liste séparée par des virgules
    ''' (chaîne vide si rien n'est coché = pas de filtre).</summary>
    Private Function CheckedCsv(rcb As RadComboBox) As String
        Dim vals As New List(Of String)
        For Each it As RadComboBoxItem In rcb.CheckedItems
            If Not String.IsNullOrEmpty(it.Value) Then vals.Add(it.Value)
        Next
        Return String.Join(",", vals)
    End Function

    ' =====================================================================
    ' Tri de la grille — toutes les colonnes sauf « Action »
    ' ---------------------------------------------------------------------
    ' Le tri s'applique sur la DataTable, donc sur les colonnes BRUTES :
    ' NumeroSort et NameSort (le numéro et le fournisseur affichés contiennent
    ' du HTML), DueDate, StatutPaiement, ResteAPayer, DejaPaye, Total, Status.
    ' Colonne et sens sont conservés en session, comme les filtres.
    ' =====================================================================

    Private Property SortCol() As String
        Get
            Return If(TryCast(Session("SuppInv.SortCol"), String), "DocumentDate")
        End Get
        Set(value As String)
            Session("SuppInv.SortCol") = value
        End Set
    End Property

    Private Property SortDesc() As Boolean
        Get
            Dim v As Object = Session("SuppInv.SortDesc")
            Return v Is Nothing OrElse CBool(v)   ' défaut : plus récent en premier
        End Get
        Set(value As Boolean)
            Session("SuppInv.SortDesc") = value
        End Set
    End Property

    ''' <summary>Libellé d'un entête cliquable, avec la flèche du tri courant.</summary>
    Private Sub SetSortHeader(root As Control, id As String, text As String, col As String)
        Dim lnk = TryCast(FindDeep(root, id), LinkButton)
        If lnk Is Nothing Then Return
        Dim fleche As String = ""
        If String.Equals(SortCol, col, StringComparison.OrdinalIgnoreCase) Then
            fleche = If(SortDesc, " ▼", " ▲")
        End If
        lnk.Text = Server.HtmlEncode(text) & fleche
    End Sub

    ''' <summary>Clic sur un entête : même colonne = sens inversé, sinon
    ''' nouvelle colonne en ordre croissant.</summary>
    Private Sub ApplySortCommand(col As String)
        If String.IsNullOrEmpty(col) Then Return
        If String.Equals(SortCol, col, StringComparison.OrdinalIgnoreCase) Then
            SortDesc = Not SortDesc
        Else
            SortCol = col
            SortDesc = False
        End If
    End Sub

    ''' <summary>Applique la langue courante (fr/en/es) aux contrôles serveur hors gabarits.
    ''' Aucun libellé n'est mis en &lt;%= %&gt; dans RAP1 (RadAjaxPanel = UpdatePanel :
    ''' les blocs de rendu y sont interdits). Les libellés HTML passent par des Literal,
    ''' les titres de fenêtres/boutons JS par des variables injectées dans le script du bas.</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
        btnAddSupplierInvoice.Text = L("addInvoice")
        tbSearch.Attributes("placeholder") = L("searchPh")
        rwSupplierInvoices.Title = L("winInvoiceTitle")
        rwEncaissement.Title = L("winDecaissTitle")
        ' rwSupplierPayment / rwScheduleAutoPay / rwDreamPayment ne sont pas dans le designer → via FindDeep
        Dim rwPay = TryCast(FindDeep(Me, "rwSupplierPayment"), RadWindow)
        If rwPay IsNot Nothing Then rwPay.Title = L("payWin")
        Dim rwSched = TryCast(FindDeep(Me, "rwScheduleAutoPay"), RadWindow)
        If rwSched IsNot Nothing Then rwSched.Title = L("winSchedTitle")
        Dim rwDream = TryCast(FindDeep(Me, "rwDreamPayment"), RadWindow)
        If rwDream IsNot Nothing Then rwDream.Title = L("winDreamTitle")
        Dim rwInterac = TryCast(FindDeep(Me, "rwInteracPayment"), RadWindow)
        If rwInterac IsNot Nothing Then rwInterac.Title = L("winInteracTitle")

        Dim fab As Control = FindDeep(Me, "fabAdd")
        If TypeOf fab Is System.Web.UI.HtmlControls.HtmlControl Then
            CType(fab, System.Web.UI.HtmlControls.HtmlControl).Attributes("title") = L("addInvoiceWin")
        End If
    End Sub

    ''' <summary>Localise les libellés du LayoutTemplate / EmptyDataTemplate (via Literal :
    ''' interdit d'y mettre des blocs de code car le RadListView remplace itemPlaceholder).</summary>
    Private Sub rgFournisseursFactures_PreRender(sender As Object, e As EventArgs) Handles rgFournisseursFactures.PreRender
        SetSortHeader(rgFournisseursFactures, "lnkSortNum", L("colNum"), "NumeroSort")
        SetSortHeader(rgFournisseursFactures, "lnkSortDue", L("colDueDate"), "DueDate")
        SetSortHeader(rgFournisseursFactures, "lnkSortSupplier", L("colSupplier"), "NameSort")
        SetSortHeader(rgFournisseursFactures, "lnkSortPay", L("colStatutPaiement"), "StatutPaiement")
        SetSortHeader(rgFournisseursFactures, "lnkSortReste", L("colResteAPayer"), "ResteAPayer")
        SetSortHeader(rgFournisseursFactures, "lnkSortPaye", L("colDejaPaye"), "DejaPaye")
        SetSortHeader(rgFournisseursFactures, "lnkSortTotal", L("colTotal"), "Total")
        SetSortHeader(rgFournisseursFactures, "lnkSortEtat", L("colEtat"), "Status")
        SetLiteral(rgFournisseursFactures, "litColAction", L("colAction"))
        SetLiteral(rgFournisseursFactures, "litEmpty", L("empty"))
    End Sub

    ''' <summary>Traductions de l'interface Factures fournisseurs (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Factures fournisseurs — 60Sec-AI", "Supplier invoices — 60Sec-AI", "Facturas de proveedores — 60Sec-AI")
            Case "pageTitleShort" : Return Choose3(lang, "Factures fournisseurs", "Supplier invoices", "Facturas de proveedor")
            Case "addInvoice" : Return Choose3(lang, "Ajouter Facture", "Add invoice", "Agregar factura")
            Case "searchPh" : Return Choose3(lang, "Rechercher (nom, email, téléphone…)", "Search (name, email, phone…)", "Buscar (nombre, correo, teléfono…)")
            Case "colNum" : Return Choose3(lang, "#", "#", "#")
            Case "colDate" : Return Choose3(lang, "Date", "Date", "Fecha")
            Case "colDueDate" : Return Choose3(lang, "Date échéance", "Due date", "Vencimiento")
            Case "checkAll" : Return Choose3(lang, "Tout cocher", "Check all", "Marcar todo")
            Case "filterStateAll" : Return Choose3(lang, "État : tous", "Status: all", "Estado: todos")
            Case "filterPayAll" : Return Choose3(lang, "Statut paiement : tous", "Payment status: all", "Estado de pago: todos")
            Case "stDraft" : Return Choose3(lang, "Brouillon", "Draft", "Borrador")
            Case "stPosted" : Return Choose3(lang, "Comptabilisé", "Posted", "Contabilizado")
            Case "payOpen" : Return Choose3(lang, "Ouverte", "Open", "Abierta")
            Case "payPartial" : Return Choose3(lang, "Partielle", "Partial", "Parcial")
            Case "payPaid" : Return Choose3(lang, "Payée", "Paid", "Pagada")
            Case "colSupplier" : Return Choose3(lang, "Fournisseur", "Supplier", "Proveedor")
            Case "colStatutPaiement" : Return Choose3(lang, "Statut paiement", "Payment status", "Estado de pago")
            Case "colResteAPayer" : Return Choose3(lang, "Reste à payer", "Balance due", "Saldo pendiente")
            Case "colDejaPaye" : Return Choose3(lang, "Déjà payé", "Already paid", "Ya pagado")
            Case "colTotal" : Return Choose3(lang, "Total", "Total", "Total")
            Case "colEtat" : Return Choose3(lang, "État", "Status", "Estado")
            Case "colAction" : Return Choose3(lang, "Action", "Action", "Acción")
            Case "tipDecaiss" : Return Choose3(lang, "Décaissement", "Disbursement", "Desembolso")
            Case "tipPay" : Return Choose3(lang, "Payer avec Stripe (Interac / ACSS / Carte)", "Pay with Stripe (Interac / ACSS / Card)", "Pagar con Stripe (Interac / ACSS / Tarjeta)")
            Case "tipDreamPay" : Return Choose3(lang, "Payer via DreamPaiement (EFT / virement bancaire)", "Pay via DreamPaiement (EFT / bank transfer)", "Pagar con DreamPaiement (EFT / transferencia bancaria)")
            Case "winDreamTitle" : Return Choose3(lang, "Payer via DreamPaiement (EFT)", "Pay via DreamPaiement (EFT)", "Pagar con DreamPaiement (EFT)")
            Case "tipInteracPay" : Return Choose3(lang, "Payer via Interac e-Transfer (courriel)", "Pay via Interac e-Transfer (email)", "Pagar con Interac e-Transfer (correo)")
            Case "winInteracTitle" : Return Choose3(lang, "Payer via Interac e-Transfer", "Pay via Interac e-Transfer", "Pagar con Interac e-Transfer")
            Case "tipSync" : Return Choose3(lang, "Synchroniser les paiements Stripe (si webhook a échoué)", "Sync Stripe payments (if the webhook failed)", "Sincronizar pagos Stripe (si el webhook falló)")
            Case "tipAutoPayActive" : Return Choose3(lang, "Auto-paiement programmé - cliquer pour gérer", "Automatic payment scheduled - click to manage", "Pago automático programado - clic para gestionar")
            Case "tipAutoPaySched" : Return Choose3(lang, "Programmer un paiement automatique", "Schedule an automatic payment", "Programar un pago automático")
            Case "edit" : Return Choose3(lang, "Modifier", "Edit", "Editar")
            Case "delete" : Return Choose3(lang, "Supprimer", "Delete", "Eliminar")
            Case "empty" : Return Choose3(lang, "Aucune facture trouvée.", "No invoice found.", "Ninguna factura encontrada.")
            Case "addInvoiceWin" : Return Choose3(lang, "Ajouter une facture", "Add an invoice", "Agregar una factura")
            Case "editInvoiceWin" : Return Choose3(lang, "Modifier une facture", "Edit an invoice", "Editar una factura")
            Case "addDecaissWin" : Return Choose3(lang, "Ajouter un décaissement", "Add a disbursement", "Agregar un desembolso")
            Case "editDecaissWin" : Return Choose3(lang, "Modifier un décaissement", "Edit a disbursement", "Editar un desembolso")
            Case "payWin" : Return Choose3(lang, "Payer le fournisseur", "Pay the supplier", "Pagar al proveedor")
            Case "pay" : Return Choose3(lang, "Payer", "Pay", "Pagar")
            Case "schedAutoPayWin" : Return Choose3(lang, "Programmer auto-paiement", "Schedule auto-payment", "Programar pago automático")
            Case "schedule" : Return Choose3(lang, "Programmer", "Schedule", "Programar")
            Case "winInvoiceTitle" : Return Choose3(lang, "Ajouter / Modifier une facture fournisseur", "Add / Edit a supplier invoice", "Agregar / Editar una factura de proveedor")
            Case "winDecaissTitle" : Return Choose3(lang, "Ajouter / Modifier un décaissement", "Add / Edit a disbursement", "Agregar / Editar un desembolso")
            Case "winSchedTitle" : Return Choose3(lang, "Programmer paiement automatique", "Schedule automatic payment", "Programar pago automático")
            Case "confirmUnsaved" : Return Choose3(lang, "⚠️ Vous avez des modifications non sauvegardées.<br/>Voulez-vous vraiment fermer ?", "⚠️ You have unsaved changes.<br/>Do you really want to close?", "⚠️ Tiene cambios sin guardar.<br/>¿Desea cerrar de todos modos?")
            Case "confirmTitle" : Return Choose3(lang, "Confirmation", "Confirmation", "Confirmación")
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
        p.Add(New SqlClient.SqlParameter("@Etats", CheckedCsv(rcbEtat)))
        p.Add(New SqlClient.SqlParameter("@StatutsPaiement", CheckedCsv(rcbStatutPaiement)))
        Dim ds As DataSet = ExecuteSQLds("s0023GetSuppliersInvoices", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing

        Dim dt As DataTable = ds.Tables(0)
        If dt.Columns.Contains(SortCol) Then
            dt.DefaultView.Sort = "[" & SortCol & "]" & If(SortDesc, " DESC", " ASC")
            dt = dt.DefaultView.ToTable()
        End If
        Return dt
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

            Case "SortBy"
                ApplySortCommand(If(e.CommandArgument, "").ToString())
                rgFournisseursFactures.Rebind()

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

    ''' <summary>
    ''' Détermine si le bouton "Payer" doit être visible sur une ligne.
    ''' Visible UNIQUEMENT si :
    '''   - StatutPaiement <> 'PAYEE' (il reste à payer)
    '''   - ComptabilisationStatus = 'COMPTABILISE' (facture finalisée, pas en brouillon)
    ''' </summary>
    Public Function CanPay(statutPaiement As Object, comptabilisationStatus As Object) As Boolean
        If statutPaiement Is Nothing OrElse IsDBNull(statutPaiement) Then Return False
        If comptabilisationStatus Is Nothing OrElse IsDBNull(comptabilisationStatus) Then Return False

        Dim statut As String = statutPaiement.ToString().Trim().ToUpper()
        Dim compta As String = comptabilisationStatus.ToString().Trim().ToUpper()

        Return statut <> "PAYEE" AndAlso compta = "COMPTABILISE"
    End Function

    ''' <summary>
    ''' Formate un montant decimal pour usage dans une URL (point comme separateur).
    ''' Evite que la virgule FR soit interpretee comme separateur de milliers cote
    ''' destination, transformant 493,24 en 49324.
    ''' </summary>
    Public Function FormatAmountForUrl(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return "0"
        Try
            Return Convert.ToDecimal(value).ToString("F2", System.Globalization.CultureInfo.InvariantCulture)
        Catch
            Return "0"
        End Try
    End Function

    ''' <summary>
    ''' Determine si le bouton "Programmer auto-paiement" doit etre affiche.
    ''' Affiche si :
    '''   - Facture non payee (StatutPaiement <> 'PAYEE')
    '''   - Facture comptabilisee
    '''   - Une autorisation T144 active existe pour ce fournisseur
    ''' </summary>
    Public Function CanShowAutoPayButton(statutPaiement As Object, comptabilisation As Object, hasAuth As Object) As Boolean
        If statutPaiement Is Nothing OrElse IsDBNull(statutPaiement) Then Return False
        If comptabilisation Is Nothing OrElse IsDBNull(comptabilisation) Then Return False

        Dim statut As String = statutPaiement.ToString().Trim().ToUpper()
        Dim compta As String = comptabilisation.ToString().Trim().ToUpper()

        If statut = "PAYEE" Then Return False
        If compta <> "COMPTABILISE" Then Return False

        ' Necessite une autorisation T144 active
        If hasAuth Is Nothing OrElse IsDBNull(hasAuth) Then Return False
        Try
            Return CBool(hasAuth)
        Catch
            Return False
        End Try
    End Function

    ''' <summary>
    ''' Determine si la facture est deja programmee pour auto-paiement
    ''' (affiche l'icone verte avec checkmark au lieu de l'icone neutre violette).
    ''' </summary>
    Public Function IsAutoPayActive(autoPay As Object, autoPayStatus As Object) As Boolean
        If autoPay Is Nothing OrElse IsDBNull(autoPay) Then Return False
        Try
            If Not CBool(autoPay) Then Return False
        Catch
            Return False
        End Try

        If autoPayStatus Is Nothing OrElse IsDBNull(autoPayStatus) Then Return True
        Dim s As String = autoPayStatus.ToString().Trim().ToUpper()
        Return s = "PLANIFIE" OrElse s = "EN_COURS" OrElse s = "REQUIRES_3DS"
    End Function

End Class
