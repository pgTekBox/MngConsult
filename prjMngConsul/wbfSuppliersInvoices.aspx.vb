Imports System.Data.SqlClient
Imports System.Data
Imports System.Linq
Imports System.Text
Imports Telerik.Web.UI

Public Class wbfSuppliersInvoices
    Inherits clsData

    Public SupplierInvoiceId As Integer

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        ApplyLocalization()

        If Not IsPostBack Then
            rgFournisseursFactures.Rebind()
        End If
    End Sub

    ' =====================================================================
    ' Filtres à sélection multiple (état comptable / statut de paiement)
    ' ---------------------------------------------------------------------
    ' Les valeurs envoyées à s0023 sont celles produites par la procédure,
    ' jamais les libellés traduits. Rien de choisi = aucun filtre. Les puces
    ' basculent une valeur ; les indicateurs posent exactement leur jeu (un
    ' second clic l'enlève). « RETARD » n'existe pas dans la procédure : c'est
    ' une facture comptabilisée, non soldée, dont l'échéance est passée ; il se
    ' filtre ici, en mémoire. Les choix sont conservés en session, comme le tri.
    ' =====================================================================

    Private Property EtatsCsv As String
        Get
            Return If(TryCast(Session("SuppInv.Etats"), String), "")
        End Get
        Set(value As String)
            Session("SuppInv.Etats") = value
        End Set
    End Property

    Private Property PaiementsCsv As String
        Get
            Return If(TryCast(Session("SuppInv.Paiements"), String), "")
        End Get
        Set(value As String)
            Session("SuppInv.Paiements") = value
        End Set
    End Property

    Private Shared Function LireCsv(csv As String) As HashSet(Of String)
        Dim s As New HashSet(Of String)(StringComparer.OrdinalIgnoreCase)
        For Each v As String In If(csv, "").Split(New Char() {","c}, StringSplitOptions.RemoveEmptyEntries)
            s.Add(v.Trim())
        Next
        Return s
    End Function

    Private Shared Function EcrireCsv(s As IEnumerable(Of String)) As String
        Return String.Join(",", s.OrderBy(Function(x) x, StringComparer.OrdinalIgnoreCase))
    End Function

    Private Shared Function Basculer(csv As String, valeur As String) As String
        If String.IsNullOrEmpty(valeur) Then Return ""
        Dim s As HashSet(Of String) = LireCsv(csv)
        If Not s.Remove(valeur) Then s.Add(valeur)
        Return EcrireCsv(s)
    End Function

    ''' <summary>Un indicateur ou une puce cliqué (hfChip = « groupe|valeur »).</summary>
    Protected Sub btnChip_Click(sender As Object, e As EventArgs) Handles btnChip.Click
        Dim v As String = If(hfChip.Value, "")
        hfChip.Value = ""
        Dim i As Integer = v.IndexOf("|"c)
        If i < 0 Then Return
        Dim groupe As String = v.Substring(0, i)
        Dim valeur As String = EcrireCsv(LireCsv(v.Substring(i + 1)))
        Select Case groupe
            Case "etat" : EtatsCsv = Basculer(EtatsCsv, valeur)
            Case "pay" : PaiementsCsv = Basculer(PaiementsCsv, valeur)
            Case "kpi-etat"
                If EtatsCsv = valeur AndAlso PaiementsCsv = "" Then
                    EtatsCsv = ""
                Else
                    EtatsCsv = valeur : PaiementsCsv = ""
                End If
            Case "kpi-pay"
                If PaiementsCsv = valeur AndAlso EtatsCsv = "" Then
                    PaiementsCsv = ""
                Else
                    PaiementsCsv = valeur : EtatsCsv = ""
                End If
        End Select
        rgFournisseursFactures.Rebind()
    End Sub

    ' =====================================================================
    ' Les indicateurs et les puces : comptés sur TOUTES les factures d'achat
    ' de la compagnie (sans recherche ni filtre).
    ' =====================================================================

    Private Const PAY_OUVERTS As String = "OUVERTE,PARTIELLE"
    Private TotalFactures As Integer

    Private Shared Function PayDe(r As DataRow) As String
        Return Convert.ToString(r("StatutPaiement")).Trim().ToUpperInvariant()
    End Function

    Private Shared Function Montant(r As DataRow, col As String) As Decimal
        If IsDBNull(r(col)) Then Return 0D
        Return Convert.ToDecimal(r(col))
    End Function

    ''' <summary>Comptabilisée, non soldée, échéance passée.</summary>
    Private Shared Function EstEnRetard(statut As Object, dueDate As Object, compta As Object) As Boolean
        If dueDate Is Nothing OrElse IsDBNull(dueDate) Then Return False
        Dim s As String = Convert.ToString(statut).Trim().ToUpperInvariant()
        If s = "PAYEE" Then Return False
        If Convert.ToString(compta) <> "COMPTABILISE" Then Return False
        Return CDate(dueDate).Date < Date.Today
    End Function

    Private Shared Function EnRetard(r As DataRow) As Boolean
        Return EstEnRetard(r("StatutPaiement"), r("DueDate"), r("ComptabilisationStatus"))
    End Function

    Private Sub ChargerIndicateurs()
        Dim rows As New List(Of DataRow)
        Try
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Search", ""))
            p.Add(New SqlClient.SqlParameter("@Etats", ""))
            p.Add(New SqlClient.SqlParameter("@StatutsPaiement", ""))
            Dim ds As DataSet = ExecuteSQLds("s0023GetSuppliersInvoices", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then rows = ds.Tables(0).Rows.Cast(Of DataRow)().ToList()
        Catch
        End Try
        TotalFactures = rows.Count

        Dim ouverts = LireCsv(PAY_OUVERTS)
        Dim lOuvertes = rows.Where(Function(r) ouverts.Contains(PayDe(r))).ToList()
        Dim lRetard = rows.Where(Function(r) EnRetard(r)).ToList()
        Dim lPayees = rows.Where(Function(r) PayDe(r) = "PAYEE").ToList()
        Dim nBrouillons As Integer = rows.Where(Function(r) Convert.ToString(r("Status")) = "Brouillon").Count()
        Dim nCompta As Integer = rows.Where(Function(r) Convert.ToString(r("Status")) = "Comptabilisé").Count()

        Dim sb As New StringBuilder()
        sb.Append(Kpi("kpi-pay", PAY_OUVERTS, L("kpiAPayer"), lOuvertes.Sum(Function(r) Montant(r, "ResteAPayer")).ToString("C0"),
                      String.Format(L("kpiOuvertes"), lOuvertes.Count), "#1B4F9C"))
        sb.Append(Kpi("kpi-pay", "RETARD", L("payLate"), lRetard.Sum(Function(r) Montant(r, "ResteAPayer")).ToString("C0"),
                      String.Format(L("kpiFactures"), lRetard.Count), If(lRetard.Count > 0, "#E35D55", "#43B47A")))
        sb.Append(Kpi("kpi-etat", "Brouillon", L("kpiBrouillons"), nBrouillons.ToString(), L("kpiACompta"), "#E3B341"))
        sb.Append(Kpi("kpi-pay", "PAYEE", L("kpiPayees"), lPayees.Sum(Function(r) Montant(r, "Total")).ToString("C0"),
                      String.Format(L("kpiFactures"), lPayees.Count), "#43B47A"))
        litKpis.Text = sb.ToString()

        Dim etats As New List(Of Tuple(Of String, String, Integer, String)) From {
            Tuple.Create("", L("chipToutes"), rows.Count, ""),
            Tuple.Create("Brouillon", L("chipBrouillons"), nBrouillons, ""),
            Tuple.Create("Comptabilisé", L("chipComptabilisees"), nCompta, "")}
        Dim pays As New List(Of Tuple(Of String, String, Integer, String)) From {
            Tuple.Create("", L("chipTous"), rows.Count, ""),
            Tuple.Create("RETARD", L("payLate"), lRetard.Count, "#E35D55"),
            Tuple.Create("PARTIELLE", L("payPartial"), rows.Where(Function(r) PayDe(r) = "PARTIELLE").Count(), "#E3B341"),
            Tuple.Create("OUVERTE", L("payOpen"), rows.Where(Function(r) PayDe(r) = "OUVERTE").Count(), "#1B4F9C"),
            Tuple.Create("PAYEE", L("payPaid"), lPayees.Count, "#43B47A")}
        litChips.Text = Groupe(L("colEtat"), "etat", EtatsCsv, etats) & Groupe(L("colPaiement"), "pay", PaiementsCsv, pays)
    End Sub

    Private Function Kpi(groupe As String, valeurs As String, lab As String, val As String, sub_ As String, point As String) As String
        Dim actif As Boolean
        If groupe = "kpi-etat" Then
            actif = (EtatsCsv = valeurs AndAlso PaiementsCsv = "")
        Else
            actif = (PaiementsCsv = valeurs AndAlso EtatsCsv = "")
        End If
        Return "<button type=""button"" class=""fc-kpi" & If(actif, " on", "") & """ aria-pressed=""" & If(actif, "true", "false") &
               """ onclick=""fcChip('" & groupe & "','" & valeurs & "')"">" &
               "<span class=""lab""><i style=""background:" & point & """></i>" & Server.HtmlEncode(lab) & "</span>" &
               "<span class=""val"">" & Server.HtmlEncode(val) & "</span>" &
               "<span class=""sub"">" & Server.HtmlEncode(sub_) & "</span></button>"
    End Function

    Private Function Groupe(titre As String, grp As String, csv As String, puces As List(Of Tuple(Of String, String, Integer, String))) As String
        Dim choisis As HashSet(Of String) = LireCsv(csv)
        Dim sb As New StringBuilder()
        sb.Append("<div class=""fc-groupe"">").Append(Server.HtmlEncode(titre)).Append("<div class=""fc-chips"">")
        For Each p In puces
            Dim actif As Boolean = If(p.Item1 = "", choisis.Count = 0, choisis.Contains(p.Item1))
            sb.Append("<button type=""button"" class=""fc-chip").Append(If(actif, " on", "")).Append(""" aria-pressed=""").Append(If(actif, "true", "false")).
               Append(""" onclick=""fcChip('").Append(grp).Append("','").Append(HttpUtility.JavaScriptStringEncode(p.Item1)).Append("')"">")
            If p.Item4 <> "" Then sb.Append("<i style=""background:").Append(p.Item4).Append("""></i>")
            sb.Append(Server.HtmlEncode(p.Item2)).Append(" <b>").Append(p.Item3).Append("</b></button>")
        Next
        sb.Append("</div></div>")
        Return sb.ToString()
    End Function

    ' =====================================================================
    ' Les cellules de la liste, au style du gabarit « Portail du client »
    ' =====================================================================

    Private Function DateCourte(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "—"
        Dim d As DateTime = CDate(v)
        Dim ci As New Globalization.CultureInfo(If(CurrentLang = "en", "en-CA", If(CurrentLang = "es", "es-ES", "fr-CA")))
        Return Server.HtmlEncode(d.ToString("d MMM yyyy", ci))
    End Function

    ''' <summary>L'échéance en gras, la date de facture en petit dessous.</summary>
    Public Function EcheanceCell(due As Object, docDate As Object) As String
        Dim sb As New StringBuilder()
        sb.Append("<b>").Append(DateCourte(due)).Append("</b>")
        If docDate IsNot Nothing AndAlso Not IsDBNull(docDate) Then
            sb.Append("<span>").Append(Server.HtmlEncode(L("emise"))).Append(DateCourte(docDate)).Append("</span>")
        End If
        Return sb.ToString()
    End Function

    ''' <summary>Le statut de paiement en pastille ; « En retard » prime sur Ouverte/Partielle quand l'échéance est passée.</summary>
    Public Function PayPill(statut As Object, dueDate As Object, compta As Object) As String
        Dim code As String = Convert.ToString(statut).Trim().ToUpperInvariant()
        Dim lab As String, bg As String, fg As String
        If EstEnRetard(statut, dueDate, compta) Then
            lab = L("payLate") : bg = "#FDECEA" : fg = "#A3261C"
        Else
            Select Case code
                Case "PARTIELLE" : lab = L("payPartial") : bg = "#FBF1DC" : fg = "#7A5200"
                Case "OUVERTE" : lab = L("payOpen") : bg = "#E8EDF5" : fg = "#143A73"
                Case "PAYEE" : lab = L("payPaid") : bg = "#E3F3EA" : fg = "#0F5A3A"
                Case Else : Return "<span class=""fc-pay"" style=""color:#5B6B86"">—</span>"
            End Select
        End If
        Return "<span class=""fc-pay"" style=""background:" & bg & ";color:" & fg & """>" & Server.HtmlEncode(lab) & "</span>"
    End Function

    Public Function ResteClass(statut As Object, dueDate As Object, compta As Object) As String
        Return "c-reste" & If(EstEnRetard(statut, dueDate, compta), " retard", "")
    End Function

    ''' <summary>Le reste à payer ; le déjà payé en petit dessous quand il y en a un.</summary>
    Public Function ResteCell(reste As Object, deja As Object) As String
        Dim r As Decimal = If(reste Is Nothing OrElse IsDBNull(reste), 0D, Convert.ToDecimal(reste))
        Dim d As Decimal = If(deja Is Nothing OrElse IsDBNull(deja), 0D, Convert.ToDecimal(deja))
        Dim s As String = Server.HtmlEncode(r.ToString("C2"))
        If d > 0D Then s &= "<span>" & Server.HtmlEncode(String.Format(L("paye"), d.ToString("C2"))) & "</span>"
        Return s
    End Function

    ''' <summary>L'état comptable : vert avec un cadenas quand la facture est comptabilisée, gris sinon.</summary>
    Public Function EtatCell(status As Object, compta As Object) As String
        Dim comptabilisee As Boolean = (Convert.ToString(compta) = "COMPTABILISE")
        Dim brut As String = Convert.ToString(status)
        Dim lab As String = brut
        If brut = "Comptabilisé" Then lab = L("stPosted")
        If brut = "Brouillon" Then lab = L("stDraft")
        Dim fg As String = If(comptabilisee OrElse brut = "Comptabilisé", "#0F5A3A", "#44536E")
        Dim sb As New StringBuilder()
        sb.Append("<span class=""fc-etat"" style=""color:").Append(fg).Append(""">")
        If comptabilisee Then
            sb.Append("<svg aria-hidden=""true"" width=""15"" height=""15"" viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""2.4"" stroke-linecap=""round"" stroke-linejoin=""round""><path d=""M6 11h12v10H6zM8 11V7a4 4 0 0 1 8 0v4""></path></svg>")
        End If
        sb.Append(Server.HtmlEncode(lab)).Append("</span>")
        Return sb.ToString()
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
        litRubrique.Text = L("rubrique")
        litSousTitre.Text = L("sousTitre")
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
            Case "addInvoice" : Return Choose3(lang, "+ Nouvelle facture fournisseur", "+ New supplier invoice", "+ Nueva factura de proveedor")
            Case "searchPh" : Return Choose3(lang, "Chercher un fournisseur", "Search a supplier", "Buscar un proveedor")
            Case "colNum" : Return Choose3(lang, "Numéro", "Number", "Número")
            Case "colDate" : Return Choose3(lang, "Date", "Date", "Fecha")
            Case "colDueDate" : Return Choose3(lang, "Échéance", "Due date", "Vencimiento")
            Case "checkAll" : Return Choose3(lang, "Tout cocher", "Check all", "Marcar todo")
            Case "filterStateAll" : Return Choose3(lang, "État : tous", "Status: all", "Estado: todos")
            Case "filterPayAll" : Return Choose3(lang, "Statut paiement : tous", "Payment status: all", "Estado de pago: todos")
            Case "stDraft" : Return Choose3(lang, "Brouillon", "Draft", "Borrador")
            Case "stPosted" : Return Choose3(lang, "Comptabilisé", "Posted", "Contabilizado")
            Case "payOpen" : Return Choose3(lang, "Ouverte", "Open", "Abierta")
            Case "payPartial" : Return Choose3(lang, "Partielle", "Partial", "Parcial")
            Case "payPaid" : Return Choose3(lang, "Payée", "Paid", "Pagada")
            Case "colSupplier" : Return Choose3(lang, "Fournisseur", "Supplier", "Proveedor")
            Case "colStatutPaiement" : Return Choose3(lang, "Paiement", "Payment", "Pago")
            Case "colResteAPayer" : Return Choose3(lang, "Reste", "Balance", "Saldo")
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
            Case "empty" : Return Choose3(lang, "Aucune facture ne correspond à ces filtres.", "No invoice matches these filters.", "Ninguna factura coincide con estos filtros.")
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
            Case "rubrique" : Return Choose3(lang, "Achats", "Purchases", "Compras")
            Case "sousTitre" : Return Choose3(lang, "Ce que vous devez à vos fournisseurs, et ce qui est payé.", "What you owe your suppliers, and what is paid.", "Lo que debe a sus proveedores, y lo que está pagado.")
            Case "kpiAPayer" : Return Choose3(lang, "À payer", "To pay", "Por pagar")
            Case "kpiOuvertes" : Return Choose3(lang, "{0} facture(s) ouverte(s)", "{0} open invoice(s)", "{0} factura(s) abierta(s)")
            Case "kpiFactures" : Return Choose3(lang, "{0} facture(s)", "{0} invoice(s)", "{0} factura(s)")
            Case "kpiBrouillons" : Return Choose3(lang, "Brouillons", "Drafts", "Borradores")
            Case "kpiACompta" : Return Choose3(lang, "à comptabiliser", "to post", "por contabilizar")
            Case "kpiPayees" : Return Choose3(lang, "Payées", "Paid", "Pagadas")
            Case "chipToutes" : Return Choose3(lang, "Toutes", "All", "Todas")
            Case "chipTous" : Return Choose3(lang, "Tous", "All", "Todos")
            Case "chipBrouillons" : Return Choose3(lang, "Brouillons", "Drafts", "Borradores")
            Case "chipComptabilisees" : Return Choose3(lang, "Comptabilisées", "Posted", "Contabilizadas")
            Case "colPaiement" : Return Choose3(lang, "Paiement", "Payment", "Pago")
            Case "payLate" : Return Choose3(lang, "En retard", "Overdue", "Vencida")
            Case "emise" : Return Choose3(lang, "facturée ", "invoiced ", "facturada ")
            Case "paye" : Return Choose3(lang, "payé {0}", "paid {0}", "pagado {0}")
            Case "pied" : Return Choose3(lang, "{0} sur {1} factures", "{0} of {1} invoices", "{0} de {1} facturas")
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
        ChargerIndicateurs()
        Dim dt As DataTable = GetData()
        rgFournisseursFactures.DataSource = dt
        litPied.Text = Server.HtmlEncode(String.Format(L("pied"), If(dt Is Nothing, 0, dt.Rows.Count), TotalFactures))
    End Sub


    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()
        Dim sSearch As String = tbSearch.Text


        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", sSearch))
        Dim pays As HashSet(Of String) = LireCsv(PaiementsCsv)
        Dim avecRetard As Boolean = pays.Remove("RETARD")
        p.Add(New SqlClient.SqlParameter("@Etats", EtatsCsv))
        p.Add(New SqlClient.SqlParameter("@StatutsPaiement", If(avecRetard, "", EcrireCsv(pays))))
        Dim ds As DataSet = ExecuteSQLds("s0023GetSuppliersInvoices", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing

        Dim dt As DataTable = ds.Tables(0)
        If avecRetard Then
            ' En retard, ou l'un des autres statuts choisis en même temps.
            Dim garde = dt.Rows.Cast(Of DataRow)().Where(Function(r) EnRetard(r) OrElse pays.Contains(PayDe(r))).ToList()
            Dim copie As DataTable = dt.Clone()
            For Each r As DataRow In garde
                copie.ImportRow(r)
            Next
            dt = copie
        End If
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



            If Convert.ToString(data("ComptabilisationStatus")) = "COMPTABILISE" Then
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
        EtatsCsv = "" : PaiementsCsv = ""
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
