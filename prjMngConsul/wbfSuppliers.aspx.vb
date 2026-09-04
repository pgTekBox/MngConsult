Imports Microsoft.Ajax.Utilities
Imports Telerik.Web.UI

Public Class wbfSuppliers
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

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
        SetSortHeader(rlvSuppliers, "lnkSortAmount", L("colToPay"), "APayer")
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
            Case "addSupplier" : Return Choose3(lang, "Ajouter Fournisseur", "Add supplier", "Agregar proveedor")
            Case "searchPh" : Return Choose3(lang, "Rechercher (nom, email, téléphone…)", "Search (name, email, phone…)", "Buscar (nombre, correo, teléfono…)")
            Case "clear" : Return Choose3(lang, "Effacer", "Clear", "Borrar")
            Case "colName" : Return Choose3(lang, "Nom", "Name", "Nombre")
            Case "colToPay" : Return Choose3(lang, "À payer", "Payable", "Por pagar")
            Case "colAction" : Return Choose3(lang, "Action", "Action", "Acción")
            Case "stripeTip" : Return Choose3(lang, "Configurer paiements Stripe Connect", "Configure Stripe Connect payments", "Configurar pagos Stripe Connect")
            Case "edit" : Return Choose3(lang, "Modifier", "Edit", "Editar")
            Case "delete" : Return Choose3(lang, "Supprimer", "Delete", "Eliminar")
            Case "empty" : Return Choose3(lang, "Aucun fournisseur trouvé.", "No supplier found.", "Ningún proveedor encontrado.")
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
        Dim dt As DataTable = GetData()
        rlvSuppliers.DataSource = dt

    End Sub


    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvSuppliers.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvSuppliers.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
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
        Dim ds As DataSet = ExecuteSQLds("s0011GetSuppliers", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing

        Dim dt As DataTable = ds.Tables(0)
        If dt.Columns.Contains(SortCol) Then
            dt.DefaultView.Sort = "[" & SortCol & "]" & If(SortDesc, " DESC", " ASC")
            dt = dt.DefaultView.ToTable()
        End If
        Return dt
    End Function
End Class