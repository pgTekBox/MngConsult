Imports Microsoft.Ajax.Utilities
Imports System.Data
Imports System.Linq
Imports System.Text
Imports Telerik.Web.UI

Public Class wbfSuppliers
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        ApplyLocalization()

        If Not IsPostBack Then
            rlvSuppliers.Rebind()
        End If
    End Sub

    ''' <summary>Applique la langue courante (fr/en/es) aux contrôles serveur hors templates.
    ''' Les libellés JS et le titre du FAB sont injectés via un script de démarrage : on évite
    ''' ainsi tout bloc &lt;%= %&gt; dans MainContent, qui empêcherait RadAjax de déplacer le
    ''' RadUpdatePanel de la liste (erreur « La collection Controls ne peut pas être modifiée »).</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
        litRubrique.Text = L("rubrique")
        litSousTitre.Text = L("sousTitre")
        btnAddSupplier.Text = L("addSupplier")
        btnClear.ToolTip = L("clear")
        tbSearch.Attributes("placeholder") = L("searchPh")
        rwSupplier.Title = L("winTitle")

        Dim js As String =
            "var L_ADD_SUPPLIER=" & JsStr(L("addSupplierWin")) & ";" &
            "var L_EDIT_SUPPLIER=" & JsStr(L("editSupplierWin")) & ";" &
            "(function(){var f=document.querySelector('.fab-add');if(f)f.title=" & JsStr(L("addSupplier")) & ";})();"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "supLang", js, True)
    End Sub

    ''' <summary>Encode une chaîne en littéral JS (guillemets inclus, accents et quotes échappés).</summary>
    Private Shared Function JsStr(s As String) As String
        Return System.Web.HttpUtility.JavaScriptStringEncode(If(s, ""), True)
    End Function

    ''' <summary>Localise les libellés du LayoutTemplate / EmptyDataTemplate du RadListView.
    ''' On ne peut PAS y mettre de blocs &lt;%# %&gt; : le RadListView doit modifier la
    ''' collection Controls du LayoutTemplate (injection des lignes dans itemPlaceholder),
    ''' ce qui est interdit si le conteneur contient des blocs de code. On passe donc par
    ''' des Literal renseignés ici, une fois le gabarit instancié.</summary>
    Private Sub rlvSuppliers_PreRender(sender As Object, e As EventArgs) Handles rlvSuppliers.PreRender
        SetSortHeader(rlvSuppliers, "lnkSortName", L("colName"), "Name")
        SetLiteral(rlvSuppliers, "litColAdresse", L("colAdresse"))
        SetSortHeader(rlvSuppliers, "lnkSortDelai", L("colDelai"), "DelaiJours")
        SetSortHeader(rlvSuppliers, "lnkSortAmount", L("colToPay"), "APayer")
        SetSortHeader(rlvSuppliers, "lnkSortStripe", L("colStripe"), "StripeAccountId")
        SetLiteral(rlvSuppliers, "litColAction", L("colAction"))
        SetLiteral(rlvSuppliers, "litEmpty", L("empty"))
    End Sub

    ' =====================================================================
    ' Tri de la grille (« Nom » et « À payer »)
    ' ---------------------------------------------------------------------
    ' Appliqué sur la DataTable renvoyée par s0011GetSuppliers, donc sur les
    ' colonnes brutes Name et APayer — jamais sur le HTML affiché.
    ' =====================================================================

    Private Property SortCol() As String
        Get
            Return If(TryCast(ViewState("SortCol"), String), "Name")
        End Get
        Set(value As String)
            ViewState("SortCol") = value
        End Set
    End Property

    Private Property SortDesc() As Boolean
        Get
            Dim v As Object = ViewState("SortDesc")
            Return v IsNot Nothing AndAlso CBool(v)
        End Get
        Set(value As Boolean)
            ViewState("SortDesc") = value
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

    ''' <summary>Montant dû : « — » discret quand il n'y a rien à payer.</summary>
    Protected Function FormatAmount(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return "<span class=""field-amount zero"">—</span>"
        Dim d As Decimal = Convert.ToDecimal(o)
        If d = 0D Then Return "<span class=""field-amount zero"">—</span>"
        Return Server.HtmlEncode(d.ToString("N2", Globalization.CultureInfo.GetCultureInfo("fr-CA")) & " $")
    End Function

    ''' <summary>Recherche récursive d'un Literal par Id (les contrôles de gabarit du
    ''' RadListView sont dans des conteneurs de nommage imbriqués) et lui assigne un texte.</summary>
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

    ''' <summary>Traductions de l'interface Fournisseurs (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Fournisseurs — 60Sec-AI", "Suppliers — 60Sec-AI", "Proveedores — 60Sec-AI")
            Case "pageTitleShort" : Return Choose3(lang, "Fournisseurs", "Suppliers", "Proveedores")
            Case "addSupplier" : Return Choose3(lang, "+ Ajouter un fournisseur", "+ Add a supplier", "+ Agregar un proveedor")
            Case "searchPh" : Return Choose3(lang, "Chercher un nom, un courriel ou un téléphone", "Search a name, an email or a phone", "Buscar un nombre, un correo o un teléfono")
            Case "clear" : Return Choose3(lang, "Effacer", "Clear", "Borrar")
            Case "colName" : Return Choose3(lang, "Fournisseur", "Supplier", "Proveedor")
            Case "colToPay" : Return Choose3(lang, "À payer", "Payable", "Por pagar")
            Case "colStripe" : Return Choose3(lang, "Stripe", "Stripe", "Stripe")
            Case "colAction" : Return Choose3(lang, "Action", "Action", "Acción")
            Case "stripeTip" : Return Choose3(lang, "Configurer paiements Stripe Connect", "Configure Stripe Connect payments", "Configurar pagos Stripe Connect")
            Case "edit" : Return Choose3(lang, "Modifier", "Edit", "Editar")
            Case "delete" : Return Choose3(lang, "Supprimer", "Delete", "Eliminar")
            Case "empty" : Return Choose3(lang, "Aucun fournisseur ne correspond.", "No supplier matches.", "Ningún proveedor coincide.")
            Case "rubrique" : Return Choose3(lang, "Achats", "Purchases", "Compras")
            Case "sousTitre" : Return Choose3(lang, "Vos fournisseurs, leurs coordonnées et ce que vous leur devez.", "Your suppliers, their contact details and what you owe them.", "Sus proveedores, sus datos de contacto y lo que les debe.")
            Case "colAdresse" : Return Choose3(lang, "Adresse de facturation", "Billing address", "Dirección de facturación")
            Case "colDelai" : Return Choose3(lang, "Délai", "Terms", "Plazo")
            Case "delaiJours" : Return Choose3(lang, "{0} jours", "{0} days", "{0} días")
            Case "delaiReception" : Return Choose3(lang, "À la réception", "On receipt", "Al recibir")
            Case "chipTous" : Return Choose3(lang, "Tous", "All", "Todos")
            Case "chipSolde" : Return Choose3(lang, "Avec un solde", "With a balance", "Con saldo")
            Case "chipRetard" : Return Choose3(lang, "En retard", "Overdue", "Vencidos")
            Case "enRetardSub" : Return Choose3(lang, "{0} en retard ({1})", "{0} overdue ({1})", "{0} vencido ({1})")
            Case "aJour" : Return Choose3(lang, "à jour", "up to date", "al día")
            Case "pied" : Return Choose3(lang, "{0} sur {1} fournisseurs", "{0} of {1} suppliers", "{0} de {1} proveedores")
            Case "winTitle" : Return Choose3(lang, "Ajouter / Modifier un Fournisseur", "Add / Edit a supplier", "Agregar / Editar un proveedor")
            Case "addSupplierWin" : Return Choose3(lang, "Ajouter un fournisseur", "Add a supplier", "Agregar un proveedor")
            Case "editSupplierWin" : Return Choose3(lang, "Modifier un fournisseur", "Edit a supplier", "Editar un proveedor")
            Case "stripeYes" : Return Choose3(lang, "Compte Stripe", "Stripe account", "Cuenta Stripe")
            Case "stripeNo" : Return Choose3(lang, "Aucun compte Stripe", "No Stripe account", "Sin cuenta Stripe")
            Case "stripeViewStatus" : Return Choose3(lang, "Voir le statut Stripe", "View Stripe status", "Ver estado de Stripe")
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


    ' =====================================================================
    ' Le filtre de la carte « recherche » : Tous / Avec un solde / En retard
    ' (une seule pastille à la fois, conservée en session), et les décomptes,
    ' calculés sur tous les fournisseurs de la compagnie, sans recherche.
    ' =====================================================================

    Private Property FiltreCourant As String
        Get
            Return If(TryCast(Session("Supp.Filtre"), String), "")
        End Get
        Set(value As String)
            Session("Supp.Filtre") = value
        End Set
    End Property

    Private TotalFournisseurs As Integer

    ''' <summary>Une pastille cliquée (argument AJAX « chip|fournisseurs|valeur » ; vide = Tous).</summary>
    Private Sub ChoisirPastille(arg As String)
        Dim parts As String() = If(arg, "").Split("|"c)
        Dim valeur As String = If(parts.Length >= 3, parts(2), "").Trim().ToLowerInvariant()
        FiltreCourant = If(valeur = "solde" OrElse valeur = "retard", valeur, "")
        rlvSuppliers.Rebind()
    End Sub

    Private Shared Function Montant(r As DataRow, col As String) As Decimal
        If IsDBNull(r(col)) Then Return 0D
        Return Convert.ToDecimal(r(col))
    End Function

    Private Shared Function Entier(r As DataRow, col As String) As Integer
        If IsDBNull(r(col)) Then Return 0
        Return Convert.ToInt32(r(col))
    End Function

    Private Function Lire(recherche As String) As DataTable
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", recherche))
        Dim ds As DataSet = ExecuteSQLds("s0907GetSuppliersListe", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    ''' <summary>Les trois pastilles avec leur décompte ; la pastille du filtre posé est blanche.</summary>
    Private Sub ChargerPastilles()
        Dim dt As DataTable = Lire("")
        Dim rows As List(Of DataRow) = If(dt Is Nothing, New List(Of DataRow), dt.Rows.Cast(Of DataRow)().ToList())
        TotalFournisseurs = rows.Count
        Dim nSolde As Integer = rows.Where(Function(r) Montant(r, "APayer") > 0D).Count()
        Dim nRetard As Integer = rows.Where(Function(r) Entier(r, "NbRetard") > 0).Count()
        Dim sb As New StringBuilder()
        sb.Append(Pastille("", L("chipTous"), rows.Count))
        sb.Append(Pastille("solde", L("chipSolde"), nSolde))
        sb.Append(Pastille("retard", L("chipRetard"), nRetard))
        litChips.Text = sb.ToString()
    End Sub

    Private Function Pastille(valeur As String, lab As String, n As Integer) As String
        Dim actif As Boolean = (FiltreCourant = valeur)
        Return "<button type=""button"" class=""fc-pill" & If(actif, " on", "") & """ aria-pressed=""" & If(actif, "true", "false") &
               """ onclick=""fcChip('fournisseurs','" & valeur & "')"">" & Server.HtmlEncode(lab) & " <span>" & n & "</span></button>"
    End Function

    ' =====================================================================
    ' Les cellules de la liste, au style du gabarit « Portail du client »
    ' =====================================================================

    Private Shared Function Initiales(nom As String) As String
        Dim sb As New StringBuilder()
        For Each mot As String In If(nom, "").Split(New Char() {" "c, "-"c}, StringSplitOptions.RemoveEmptyEntries)
            If Char.IsLetterOrDigit(mot(0)) Then sb.Append(Char.ToUpperInvariant(mot(0)))
            If sb.Length = 2 Then Exit For
        Next
        Return If(sb.Length = 0, "?", sb.ToString())
    End Function

    Private Shared Function Texte(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return o.ToString().Trim()
    End Function

    ''' <summary>Le rond aux initiales, le nom en gras, puis le courriel et le téléphone.</summary>
    Public Function ClientCell(nom As Object, courriel As Object, tel As Object) As String
        Dim n As String = Texte(nom)
        Dim contact As String = String.Join(" · ", New String() {Texte(courriel), Texte(tel)}.Where(Function(x) x <> ""))
        Dim sb As New StringBuilder()
        sb.Append("<span class=""av"" aria-hidden=""true"">").Append(Server.HtmlEncode(Initiales(n))).Append("</span>")
        sb.Append("<span class=""txt""><b>").Append(Server.HtmlEncode(n)).Append("</b>")
        If contact <> "" Then sb.Append("<span>").Append(Server.HtmlEncode(contact)).Append("</span>")
        sb.Append("</span>")
        Return sb.ToString()
    End Function

    Public Function AdresseCell(adresse As Object) As String
        Dim a As String = Texte(adresse)
        Return If(a = "", "—", Server.HtmlEncode(a))
    End Function

    ''' <summary>« 30 jours », ou « À la réception » quand aucun délai n'est fixé.</summary>
    Public Function DelaiCell(jours As Object) As String
        Dim j As Integer = 0
        If jours IsNot Nothing AndAlso Not IsDBNull(jours) Then Integer.TryParse(jours.ToString(), j)
        If j <= 0 Then Return Server.HtmlEncode(L("delaiReception"))
        Return Server.HtmlEncode(String.Format(L("delaiJours"), j))
    End Function

    Public Function DuClass(nbRetard As Object) As String
        Dim n As Integer = 0
        If nbRetard IsNot Nothing AndAlso Not IsDBNull(nbRetard) Then Integer.TryParse(nbRetard.ToString(), n)
        Return "c-du" & If(n > 0, " retard", "")
    End Function

    ''' <summary>Le montant à payer ; en dessous, ce qui est en retard (en rouge) ou « à jour ».</summary>
    Public Function DuCell(aPayer As Object, enRetard As Object, nbRetard As Object) As String
        Dim d As Decimal = If(aPayer Is Nothing OrElse IsDBNull(aPayer), 0D, Convert.ToDecimal(aPayer))
        Dim r As Decimal = If(enRetard Is Nothing OrElse IsDBNull(enRetard), 0D, Convert.ToDecimal(enRetard))
        Dim n As Integer = 0
        If nbRetard IsNot Nothing AndAlso Not IsDBNull(nbRetard) Then Integer.TryParse(nbRetard.ToString(), n)
        If d <= 0D AndAlso n = 0 Then Return "<b class=""rien"">—</b>"
        Dim sb As New StringBuilder()
        sb.Append("<b>").Append(Server.HtmlEncode(d.ToString("C2"))).Append("</b>")
        If n > 0 Then
            sb.Append("<span>").Append(Server.HtmlEncode(String.Format(L("enRetardSub"), r.ToString("C2"), n))).Append("</span>")
        Else
            sb.Append("<span>").Append(Server.HtmlEncode(L("aJour"))).Append("</span>")
        End If
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Badge « inscription Stripe » pour la liste : vert « Compte Stripe » si le
    ''' fournisseur a un acct_xxx, gris « Aucun compte Stripe » sinon. Cliquable :
    ''' ouvre la page de statut/onboarding (détail live) dans un nouvel onglet.
    ''' </summary>
    Public Function StripeBadge(acct As Object, partyId As Object) As String
        Dim pid As String = If(partyId Is Nothing OrElse IsDBNull(partyId), "0", partyId.ToString())
        Dim url As String = "wbfSupplierStripeOnboarding.aspx?PartyId=" & pid
        Dim tip As String = L("stripeViewStatus")
        Dim hasAcct As Boolean = (acct IsNot Nothing AndAlso Not IsDBNull(acct) AndAlso Not String.IsNullOrWhiteSpace(acct.ToString()))

        Dim cls As String = If(hasAcct, "on", "off")
        Dim label As String = If(hasAcct, L("stripeYes"), L("stripeNo"))

        Return "<a class=""stripe-badge " & cls & """ href=""" & url & """ target=""_blank"" title=""" & tip &
               """ onclick=""event.stopPropagation();""><span class=""dot""></span>" & label & "</a>"
    End Function
    Private Sub rlvSuppliers_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvSuppliers.ItemCommand
        If e.CommandArgument Is Nothing Then Return

        Select Case e.CommandName
            Case "DeleteSupplier"
                Dim supplierId As Integer = CInt(e.CommandArgument)
                DeleteSupplier(supplierId)
                rlvSuppliers.Rebind()

            Case "SortBy"
                ApplySortCommand(e.CommandArgument.ToString())
                rlvSuppliers.Rebind()
        End Select
    End Sub

    Sub DeleteSupplier(supplierId As Integer)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@PartyId", supplierId))
        ExecuteSQL("s0316DeleteParty", p)
    End Sub
    Private Sub rlvSuppliers_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvSuppliers.NeedDataSource
        ChargerPastilles()
        Dim dt As DataTable = GetData()
        rlvSuppliers.DataSource = dt
        litPied.Text = Server.HtmlEncode(String.Format(L("pied"), If(dt Is Nothing, 0, dt.Rows.Count), TotalFournisseurs))

    End Sub


    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvSuppliers.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        FiltreCourant = ""
        rlvSuppliers.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If If(e.Argument, "").StartsWith("chip|") Then
            ChoisirPastille(e.Argument)
            Return
        End If
        ' e.Argument contient "refreshgrid"
        If e.Argument = "refreshgrid" Then
            rlvSuppliers.Rebind() ' ← recharge la liste après fermeture de la fenêtre
        End If
    End Sub

    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", q))
        Dim ds As DataSet = ExecuteSQLds("s0907GetSuppliersListe", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing

        Dim dt As DataTable = ds.Tables(0)
        ' Le filtre de la pastille : avec un solde, ou en retard.
        If FiltreCourant = "solde" Then
            dt.DefaultView.RowFilter = "APayer > 0"
            dt = dt.DefaultView.ToTable()
        ElseIf FiltreCourant = "retard" Then
            dt.DefaultView.RowFilter = "NbRetard > 0"
            dt = dt.DefaultView.ToTable()
        End If
        If dt.Columns.Contains(SortCol) Then
            dt.DefaultView.Sort = "[" & SortCol & "]" & If(SortDesc, " DESC", " ASC")
            dt = dt.DefaultView.ToTable()
        End If
        Return dt
    End Function
End Class