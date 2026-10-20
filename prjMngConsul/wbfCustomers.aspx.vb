Imports Microsoft.Ajax.Utilities
Imports System.Data
Imports System.Linq
Imports System.Text
Imports Telerik.Web.UI

Public Class wbfCustomers
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
            rlvClients.Rebind()
        End If
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal de la page.</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
        litRubrique.Text = L("rubrique")
        litSousTitre.Text = L("sousTitre")
        btnAddCustomer.Text = L("addCustomer")
        btnExportSquare.Text = L("exportSquare")
        btnImportSquare.Text = L("importSquare")
        tbSearch.Attributes("placeholder") = L("searchPh")
        btnClear.ToolTip = L("clear")
        rwCustomer.Title = L("winTitle")

        Dim fab As Control = FindDeep(Me, "fabAdd")
        If TypeOf fab Is System.Web.UI.HtmlControls.HtmlControl Then
            CType(fab, System.Web.UI.HtmlControls.HtmlControl).Attributes("title") = L("addCustomerWin")
        End If
    End Sub

    ''' <summary>Libellés du LayoutTemplate / EmptyDataTemplate du RadListView (via Literal).</summary>
    Private Sub rlvClients_PreRender(sender As Object, e As EventArgs) Handles rlvClients.PreRender
        SetSortHeader(rlvClients, "lnkSortName", L("colName"), "Name")
        SetLiteral(rlvClients, "litColAdresse", L("colAdresse"))
        SetSortHeader(rlvClients, "lnkSortDelai", L("colDelai"), "DelaiJours")
        SetSortHeader(rlvClients, "lnkSortAmount", L("colToReceive"), "ARecevoir")
        SetLiteral(rlvClients, "litColAction", L("colAction"))
        SetLiteral(rlvClients, "litEmpty", L("empty"))
    End Sub

    ' =====================================================================
    ' Tri de la grille (colonnes « Nom » et « À recevoir »)
    ' ---------------------------------------------------------------------
    ' Le tri est appliqué sur la DataTable renvoyée par s0010GetCustomers,
    ' donc sur les colonnes brutes : Name et ARecevoir, jamais sur le HTML
    ' affiché. La colonne et le sens sont conservés en ViewState.
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

    ''' <summary>Clic sur un entête : même colonne = on inverse le sens, sinon
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
    Private Sub rlvClients_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvClients.ItemCommand
        If e.CommandArgument Is Nothing Then Return

        Select Case e.CommandName
            Case "DeleteClient"
                Dim clientId As Integer = CInt(e.CommandArgument)
                DeleteClient(clientId)
                rlvClients.Rebind()

            Case "SortBy"
                ApplySortCommand(e.CommandArgument.ToString())
                rlvClients.Rebind()
        End Select
    End Sub

    Sub DeleteClient(clientId As Integer)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@PartyId", clientId))
        ExecuteSQL("s0316DeleteParty", p)
    End Sub
    Private Sub rlvClients_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvClients.NeedDataSource
        ChargerPastilles()
        Dim dt As DataTable = GetData()
        rlvClients.DataSource = dt
        litPied.Text = Server.HtmlEncode(String.Format(L("pied"), If(dt Is Nothing, 0, dt.Rows.Count), TotalClients))

    End Sub


    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvClients.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        FiltreCourant = ""
        rlvClients.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If If(e.Argument, "").StartsWith("chip|") Then
            ChoisirPastille(e.Argument)
            Return
        End If
        ' e.Argument contient "refreshgrid"
        If e.Argument = "refreshgrid" Then
            rlvClients.Rebind() ' ← recharge la liste après fermeture de la fenêtre
        End If
    End Sub

    ' ── Export des clients vers Square (Customers API) ──

    Protected Sub btnExportSquare_Click(sender As Object, e As EventArgs) Handles btnExportSquare.Click
        Try
            ' 1. Lire les clients a exporter (+ identifiants Square existants)
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0664GetClientsForSquareSync", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ShowSquareMessage(L("sqNoExport"))
                Return
            End If

            ' 2. Construire la liste pour Square
            Dim items As New List(Of clsSquare.SquareCustomerInput)
            For Each row As DataRow In ds.Tables(0).Rows
                Dim inp As New clsSquare.SquareCustomerInput
                inp.PartyId = CInt(row("Id"))
                inp.CompanyName = If(IsDBNull(row("Name")), "", CStr(row("Name")))
                inp.Email = If(IsDBNull(row("Email")), "", CStr(row("Email")))
                inp.Phone = If(IsDBNull(row("Phone")), "", CStr(row("Phone")))
                inp.Address1 = If(IsDBNull(row("Address1")), "", CStr(row("Address1")))
                inp.Address2 = If(IsDBNull(row("Address2")), "", CStr(row("Address2")))
                inp.City = If(IsDBNull(row("City")), "", CStr(row("City")))
                inp.PostalCode = If(IsDBNull(row("PostalCode")), "", CStr(row("PostalCode")))
                inp.Note = If(IsDBNull(row("Note")), "", CStr(row("Note")))
                If Not IsDBNull(row("SquareCustomerId")) Then inp.ExistingCustomerId = CStr(row("SquareCustomerId"))
                If Not IsDBNull(row("SquareCustomerVersion")) Then inp.ExistingVersion = CLng(row("SquareCustomerVersion"))
                items.Add(inp)
            Next

            ' 3. Pousser vers Square (jeton OAuth de l'abonne, refresh auto ; fallback Web.config)
            Dim token As String = GetValidSquareAccessToken()
            Dim results As List(Of clsSquare.SquareCustomerResult) = clsSquare.UpsertCustomers(token, items)

            ' 4. Sauvegarder les identifiants Square sur le client (T050Party)
            Dim okCount As Integer = 0
            For Each r As clsSquare.SquareCustomerResult In results
                If Not String.IsNullOrEmpty(r.CustomerId) Then
                    Dim pm As New Collection
                    pm.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
                    pm.Add(New SqlClient.SqlParameter("@PartyId", r.PartyId))
                    pm.Add(New SqlClient.SqlParameter("@SquareCustomerId", r.CustomerId))
                    pm.Add(New SqlClient.SqlParameter("@SquareCustomerVersion", r.Version))
                    pm.Add(New SqlClient.SqlParameter("@Status", "OK"))
                    ExecuteSQL("s0665UpdateClientSquareId", pm)
                    okCount += 1
                End If
            Next

            ShowSquareMessage(String.Format(L("sqExported"), okCount, items.Count))
        Catch ex As Exception
            ShowSquareMessage(L("sqExportError") & ex.Message)
        End Try
    End Sub

    ' ── Import des clients depuis Square (sens entrant, a la demande) ──

    Protected Sub btnImportSquare_Click(sender As Object, e As EventArgs) Handles btnImportSquare.Click
        Try
            Dim token As String = GetValidSquareAccessToken()
            Dim remotes As List(Of clsSquare.SquareCustomerRemote) = clsSquare.ListCustomers(token)

            If remotes Is Nothing OrElse remotes.Count = 0 Then
                ShowSquareMessage(L("sqNoImport"))
                rlvClients.Rebind()
                Return
            End If

            Dim created As Integer = 0, updated As Integer = 0
            For Each c As clsSquare.SquareCustomerRemote In remotes
                If String.IsNullOrEmpty(c.CustomerId) Then Continue For

                Dim p As New Collection
                p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
                p.Add(New SqlClient.SqlParameter("@SquareCustomerId", c.CustomerId))
                p.Add(New SqlClient.SqlParameter("@SquareCustomerVersion", If(c.Version > 0, CObj(c.Version), DBNull.Value)))
                p.Add(New SqlClient.SqlParameter("@ReferenceId", NzParam(c.ReferenceId)))
                p.Add(New SqlClient.SqlParameter("@Name", NzParam(c.Name)))
                p.Add(New SqlClient.SqlParameter("@Email", NzParam(c.Email)))
                p.Add(New SqlClient.SqlParameter("@Phone", NzParam(c.Phone)))
                p.Add(New SqlClient.SqlParameter("@Address1", NzParam(c.Address1)))
                p.Add(New SqlClient.SqlParameter("@Address2", NzParam(c.Address2)))
                p.Add(New SqlClient.SqlParameter("@City", NzParam(c.City)))
                p.Add(New SqlClient.SqlParameter("@PostalCode", NzParam(c.PostalCode)))
                Dim ds As DataSet = ExecuteSQLds("s0666UpsertClientFromSquare", p)

                Dim action As String = ""
                If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 _
                   AndAlso Not IsDBNull(ds.Tables(0).Rows(0)("Action")) Then
                    action = CStr(ds.Tables(0).Rows(0)("Action"))
                End If
                If action = "created" Then created += 1 Else updated += 1
            Next

            ShowSquareMessage(String.Format(L("sqImported"), created, updated, remotes.Count))
            rlvClients.Rebind()
        Catch ex As Exception
            ShowSquareMessage(L("sqImportError") & ex.Message)
        End Try
    End Sub

    Private Shared Function NzParam(s As String) As Object
        If String.IsNullOrEmpty(s) Then Return DBNull.Value
        Return s
    End Function

    ' radalert leve « Cannot read properties of undefined (reading 'radalert') »
    ' quand il part d'un script de demarrage : voir clsData.ShowMessageBox.
    Private Sub ShowSquareMessage(msg As String)
        ShowMessageBox(msg, L("sqTitle"))
    End Sub

    ''' <summary>Traductions de l'interface Clients (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Clients — 60Sec-AI", "Customers — 60Sec-AI", "Clientes — 60Sec-AI")
            Case "pageTitleShort" : Return Choose3(lang, "Clients", "Customers", "Clientes")
            Case "addCustomer" : Return Choose3(lang, "+ Ajouter un client", "+ Add a customer", "+ Agregar un cliente")
            Case "exportSquare" : Return Choose3(lang, "Envoyer vers Square", "Send to Square", "Enviar a Square")
            Case "importSquare" : Return Choose3(lang, "Importer de Square", "Import from Square", "Importar de Square")
            Case "searchPh" : Return Choose3(lang, "Chercher un nom, un courriel ou un téléphone", "Search a name, an email or a phone", "Buscar un nombre, un correo o un teléfono")
            Case "clear" : Return Choose3(lang, "Effacer", "Clear", "Borrar")
            Case "edit" : Return Choose3(lang, "Modifier", "Edit", "Editar")
            Case "delete" : Return Choose3(lang, "Supprimer", "Delete", "Eliminar")
            Case "colName" : Return Choose3(lang, "Client", "Customer", "Cliente")
            Case "colToReceive" : Return Choose3(lang, "À recevoir", "Receivable", "Por cobrar")
            Case "colAction" : Return Choose3(lang, "Action", "Action", "Acción")
            Case "empty" : Return Choose3(lang, "Aucun client ne correspond.", "No customer matches.", "Ningún cliente coincide.")
            Case "rubrique" : Return Choose3(lang, "Ventes", "Sales", "Ventas")
            Case "sousTitre" : Return Choose3(lang, "Vos clients, leurs coordonnées et ce qu'ils vous doivent.", "Your customers, their contact details and what they owe you.", "Sus clientes, sus datos de contacto y lo que le deben.")
            Case "colAdresse" : Return Choose3(lang, "Adresse de facturation", "Billing address", "Dirección de facturación")
            Case "colDelai" : Return Choose3(lang, "Délai", "Terms", "Plazo")
            Case "delaiJours" : Return Choose3(lang, "{0} jours", "{0} days", "{0} días")
            Case "delaiReception" : Return Choose3(lang, "À la réception", "On receipt", "Al recibir")
            Case "chipTous" : Return Choose3(lang, "Tous", "All", "Todos")
            Case "chipSolde" : Return Choose3(lang, "Avec un solde", "With a balance", "Con saldo")
            Case "chipRetard" : Return Choose3(lang, "En retard", "Overdue", "Vencidos")
            Case "enRetardSub" : Return Choose3(lang, "{0} en retard ({1})", "{0} overdue ({1})", "{0} vencido ({1})")
            Case "aJour" : Return Choose3(lang, "à jour", "up to date", "al día")
            Case "pied" : Return Choose3(lang, "{0} sur {1} clients", "{0} of {1} customers", "{0} de {1} clientes")
            Case "winTitle" : Return Choose3(lang, "Ajouter / Modifier un Client", "Add / Edit a customer", "Agregar / Editar un cliente")
            Case "addCustomerWin" : Return Choose3(lang, "Ajouter un client", "Add a customer", "Agregar un cliente")
            Case "editCustomerWin" : Return Choose3(lang, "Modifier un client", "Edit a customer", "Editar un cliente")
            Case "sqTitle" : Return Choose3(lang, "Square", "Square", "Square")
            Case "sqNoExport" : Return Choose3(lang, "Aucun client à exporter.", "No customer to export.", "Ningún cliente para exportar.")
            Case "sqExported" : Return Choose3(lang, "{0} client(s) exporté(s) vers Square sur {1}.", "{0} customer(s) exported to Square out of {1}.", "{0} cliente(s) exportado(s) a Square de {1}.")
            Case "sqExportError" : Return Choose3(lang, "Erreur lors de l'export Square : ", "Error during Square export: ", "Error durante la exportación Square: ")
            Case "sqNoImport" : Return Choose3(lang, "Aucun client à importer depuis Square.", "No customer to import from Square.", "Ningún cliente para importar desde Square.")
            Case "sqImported" : Return Choose3(lang, "{0} client(s) créé(s) et {1} mis à jour depuis Square ({2} trouvé(s)).", "{0} customer(s) created and {1} updated from Square ({2} found).", "{0} cliente(s) creado(s) y {1} actualizado(s) desde Square ({2} encontrado(s)).")
            Case "sqImportError" : Return Choose3(lang, "Erreur lors de l'import Square : ", "Error during Square import: ", "Error durante la importación Square: ")
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

    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", q))
        Dim ds As DataSet = ExecuteSQLds("s0906GetCustomersListe", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing

        Dim dt As DataTable = ds.Tables(0)
        ' Le filtre de la pastille : avec un solde, ou en retard.
        If FiltreCourant = "solde" Then
            dt.DefaultView.RowFilter = "ARecevoir > 0"
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


    ' =====================================================================
    ' Le filtre de la carte « recherche » : Tous / Avec un solde / En retard
    ' (une seule pastille à la fois, conservée en session), et les décomptes,
    ' calculés sur tous les clients de la compagnie, sans recherche.
    ' =====================================================================

    Private Property FiltreCourant As String
        Get
            Return If(TryCast(Session("Cust.Filtre"), String), "")
        End Get
        Set(value As String)
            Session("Cust.Filtre") = value
        End Set
    End Property

    Private TotalClients As Integer

    ''' <summary>Une pastille cliquée (argument AJAX « chip|clients|valeur » ; vide = Tous).</summary>
    Private Sub ChoisirPastille(arg As String)
        Dim parts As String() = If(arg, "").Split("|"c)
        Dim valeur As String = If(parts.Length >= 3, parts(2), "").Trim().ToLowerInvariant()
        FiltreCourant = If(valeur = "solde" OrElse valeur = "retard", valeur, "")
        rlvClients.Rebind()
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
        Dim ds As DataSet = ExecuteSQLds("s0906GetCustomersListe", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    ''' <summary>Les trois pastilles avec leur décompte ; la pastille du filtre posé est blanche.</summary>
    Private Sub ChargerPastilles()
        Dim dt As DataTable = Lire("")
        Dim rows As List(Of DataRow) = If(dt Is Nothing, New List(Of DataRow), dt.Rows.Cast(Of DataRow)().ToList())
        TotalClients = rows.Count
        Dim nSolde As Integer = rows.Where(Function(r) Montant(r, "ARecevoir") > 0D).Count()
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
               """ onclick=""fcChip('clients','" & valeur & "')"">" & Server.HtmlEncode(lab) & " <span>" & n & "</span></button>"
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

    ''' <summary>Le montant à recevoir ; en dessous, ce qui est en retard (en rouge) ou « à jour ».</summary>
    Public Function DuCell(aRecevoir As Object, enRetard As Object, nbRetard As Object) As String
        Dim d As Decimal = If(aRecevoir Is Nothing OrElse IsDBNull(aRecevoir), 0D, Convert.ToDecimal(aRecevoir))
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

    ''' <summary>Montant à recevoir : « — » discret quand il n'y a rien à réclamer.</summary>
    Protected Function FormatAmount(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return "<span class=""field-amount zero"">—</span>"
        Dim d As Decimal = Convert.ToDecimal(o)
        If d = 0D Then Return "<span class=""field-amount zero"">—</span>"
        Return Server.HtmlEncode(d.ToString("N2", Globalization.CultureInfo.GetCultureInfo("fr-CA")) & " $")
    End Function
End Class