Imports Microsoft.Ajax.Utilities
Imports Telerik.Web.UI

Public Class wbfCustomers
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ApplyLocalization()

        If Not IsPostBack Then
            rlvClients.Rebind()
        End If
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal de la page.</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
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
        SetLiteral(rlvClients, "litColName", L("colName"))
        SetLiteral(rlvClients, "litColAction", L("colAction"))
        SetLiteral(rlvClients, "litEmpty", L("empty"))
    End Sub
    Private Sub rlvClients_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvClients.ItemCommand
        If e.CommandArgument Is Nothing Then Return

        Select Case e.CommandName
            Case "DeleteClient"
                Dim clientId As Integer = CInt(e.CommandArgument)
                DeleteClient(clientId)
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
        Dim dt As DataTable = GetData()
        rlvClients.DataSource = dt

    End Sub


    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvClients.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvClients.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
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
            Case "addCustomer" : Return Choose3(lang, "Ajouter Client", "Add customer", "Agregar cliente")
            Case "exportSquare" : Return Choose3(lang, "Exporter vers Square", "Export to Square", "Exportar a Square")
            Case "importSquare" : Return Choose3(lang, "Importer depuis Square", "Import from Square", "Importar desde Square")
            Case "searchPh" : Return Choose3(lang, "Rechercher (nom, email, téléphone…)", "Search (name, email, phone…)", "Buscar (nombre, correo, teléfono…)")
            Case "clear" : Return Choose3(lang, "Effacer", "Clear", "Borrar")
            Case "edit" : Return Choose3(lang, "Modifier", "Edit", "Editar")
            Case "delete" : Return Choose3(lang, "Supprimer", "Delete", "Eliminar")
            Case "colName" : Return Choose3(lang, "Nom", "Name", "Nombre")
            Case "colAction" : Return Choose3(lang, "Action", "Action", "Acción")
            Case "empty" : Return Choose3(lang, "Aucun client trouvé.", "No customer found.", "Ningún cliente encontrado.")
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
        Dim ds As DataSet = ExecuteSQLds("s0010GetCustomers", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function
End Class