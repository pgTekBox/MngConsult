Imports Microsoft.Ajax.Utilities
Imports Telerik.Web.UI

Public Class wbfCustomers
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load


        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            rlvClients.Rebind()
        End If
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
                ShowSquareMessage("Aucun client a exporter.")
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

            ShowSquareMessage(okCount & " client(s) exporte(s) vers Square sur " & items.Count & ".")
        Catch ex As Exception
            ShowSquareMessage("Erreur lors de l'export Square : " & ex.Message)
        End Try
    End Sub

    ' ── Import des clients depuis Square (sens entrant, a la demande) ──

    Protected Sub btnImportSquare_Click(sender As Object, e As EventArgs) Handles btnImportSquare.Click
        Try
            Dim token As String = GetValidSquareAccessToken()
            Dim remotes As List(Of clsSquare.SquareCustomerRemote) = clsSquare.ListCustomers(token)

            If remotes Is Nothing OrElse remotes.Count = 0 Then
                ShowSquareMessage("Aucun client a importer depuis Square.")
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

            ShowSquareMessage(created & " client(s) cree(s) et " & updated & " mis a jour depuis Square (" & remotes.Count & " trouve(s)).")
            rlvClients.Rebind()
        Catch ex As Exception
            ShowSquareMessage("Erreur lors de l'import Square : " & ex.Message)
        End Try
    End Sub

    Private Shared Function NzParam(s As String) As Object
        If String.IsNullOrEmpty(s) Then Return DBNull.Value
        Return s
    End Function

    Private Sub ShowSquareMessage(msg As String)
        Dim safe As String = msg.Replace("\", "\\").Replace("'", "\'").Replace(ControlChars.Cr, " ").Replace(ControlChars.Lf, " ")
        Dim script As String = "radalert('" & safe & "', 400, 200, 'Export Square');"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "squareMsg", script, True)
    End Sub

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