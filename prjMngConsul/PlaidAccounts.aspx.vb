Imports System.Data.SqlClient
Imports Newtonsoft.Json.Linq
Imports Telerik.Web.UI

Public Class PlaidAccounts
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ApplyLocalization()

        If Not IsPostBack Then
            rlvAccounts.Rebind()
            BindAccountDropdown()

            Dim txtStart As TextBox = CType(rlvAccounts.FindControl("txtStartDate"), TextBox)
            Dim txtEnd As TextBox = CType(rlvAccounts.FindControl("txtEndDate"), TextBox)
            If txtStart IsNot Nothing Then txtStart.Text = Date.Today.AddMonths(-1).ToString("yyyy-MM-dd")
            If txtEnd IsNot Nothing Then txtEnd.Text = Date.Today.ToString("yyyy-MM-dd")
        End If
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal de la page.</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
        btnConnect.Text = L("connectBank")

        Dim fab As Control = FindDeep(Me, "fabAdd")
        If TypeOf fab Is System.Web.UI.HtmlControls.HtmlControl Then
            CType(fab, System.Web.UI.HtmlControls.HtmlControl).Attributes("title") = L("connectBank")
        End If
    End Sub

    ''' <summary>Libellés du LayoutTemplate / EmptyDataTemplate du RadListView (via Literal).</summary>
    Private Sub rlvAccounts_PreRender(sender As Object, e As EventArgs) Handles rlvAccounts.PreRender
        SetLiteral(rlvAccounts, "litColBank", L("colBank"))
        SetLiteral(rlvAccounts, "litColBalance", L("colBalance"))
        SetLiteral(rlvAccounts, "litColDate", L("colDate"))
        SetLiteral(rlvAccounts, "litColStatus", L("colStatus"))
        SetLiteral(rlvAccounts, "litColAction", L("colAction"))
        SetLiteral(rlvAccounts, "litLblAccount", L("lblAccount"))
        SetLiteral(rlvAccounts, "litLblFrom", L("lblFrom"))
        SetLiteral(rlvAccounts, "litLblTo", L("lblTo"))
        SetLiteral(rlvAccounts, "litEmpty", L("empty"))

        Dim bi As Button = TryCast(FindDeep(rlvAccounts, "btnImport"), Button)
        If bi IsNot Nothing Then bi.Text = L("import")
    End Sub

    ' ==========================================
    ' DataSource
    ' ==========================================
    Private Sub rlvAccounts_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvAccounts.NeedDataSource
        rlvAccounts.DataSource = GetData()
    End Sub




    Private Function GetData() As DataTable

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))

        Dim ds As DataSet = ExecuteSQLds("s0044GetBankAccout", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function




    ' ==========================================
    ' Dropdown comptes actifs
    ' ==========================================
    Private Sub BindAccountDropdown()
        Dim ddl As DropDownList = CType(rlvAccounts.FindControl("ddlAccount"), DropDownList)
        If ddl Is Nothing Then Return

        Dim cs As String = ConnectionString

        Using cn As New SqlConnection(cs)
            cn.Open()
            Dim sql As String = "SELECT ItemId, BankName,AccountName FROM dbo.T143PlaidAccount WHERE CompanyGUID = @CompanyGUID AND Active = 1 ORDER BY BankName"
            Using cmd As New SqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                Using da As New SqlDataAdapter(cmd)
                    Dim dt As New DataTable()
                    da.Fill(dt)
                    ddl.DataSource = dt
                    ddl.DataTextField = "AccountName"
                    ddl.DataValueField = "ItemId"
                    ddl.DataBind()
                End Using
            End Using
        End Using
    End Sub

    ' ==========================================
    ' Déconnecter un compte
    ' ==========================================
    Private Sub rlvAccounts_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvAccounts.ItemCommand
        If e.CommandName = "Disconnect" Then
            Dim itemId As String = e.CommandArgument.ToString()
            DisconnectAccount(itemId)
            rlvAccounts.Rebind()
            BindAccountDropdown()
        End If
    End Sub

    Private Sub DisconnectAccount(itemId As String)
        Dim cs As String = ConnectionString

        Using cn As New SqlConnection(cs)
            cn.Open()
            Dim sql As String = "UPDATE dbo.T143PlaidAccount SET Active = 0 WHERE CompanyGUID = @CompanyGUID AND ItemId = @ItemId"
            Using cmd As New SqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@ItemId", itemId)
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    ' ==========================================
    ' Importer des transactions
    ' ==========================================
    Protected Async Sub btnImport_Click(sender As Object, e As EventArgs)
        Dim ddl As DropDownList = CType(rlvAccounts.FindControl("ddlAccount"), DropDownList)
        Dim txtStart As TextBox = CType(rlvAccounts.FindControl("txtStartDate"), TextBox)
        Dim txtEnd As TextBox = CType(rlvAccounts.FindControl("txtEndDate"), TextBox)
        Dim lbl As Label = CType(rlvAccounts.FindControl("lblResult"), Label)

        If ddl Is Nothing OrElse txtStart Is Nothing OrElse txtEnd Is Nothing Then Return

        Try
            Dim itemId As String = ddl.SelectedValue
            Dim startDate As Date = Date.Parse(txtStart.Text)
            Dim endDate As Date = Date.Parse(txtEnd.Text)

            Dim accessToken As String = GetAccessToken(itemId)

            If String.IsNullOrEmpty(accessToken) Then
                lbl.Text = L("accountNotFound")
                lbl.CssClass = "import-result text-danger"
                lbl.Visible = True
                Return
            End If

            Dim svc As New Plaid()
            Dim tx As JObject = Await svc.GetTransactionsAsync(accessToken, startDate, endDate)

            Dim count As Integer = 0
            If tx("added") IsNot Nothing Then
                For Each t As JObject In tx("added")
                    InsertTransaction(t)
                    count += 1
                Next
            End If

            lbl.Text = String.Format(L("txImported"), count)
            lbl.CssClass = "import-result text-success"
            lbl.Visible = True

        Catch ex As Exception
            lbl.Text = L("errorPrefix") & ex.Message
            lbl.CssClass = "import-result text-danger"
            lbl.Visible = True
        End Try
    End Sub

    Private Function GetAccessToken(itemId As String) As String
        Dim cs As String = ConnectionString

        Using cn As New SqlConnection(cs)
            cn.Open()
            Dim sql As String = "SELECT AccessToken FROM dbo.T143PlaidAccount WHERE CompanyGUID = @CompanyGUID AND ItemId = @ItemId AND Active = 1"
            Using cmd As New SqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@ItemId", itemId)
                Dim result = cmd.ExecuteScalar()
                If result IsNot Nothing Then Return result.ToString()
            End Using
        End Using

        Return Nothing
    End Function

    ' ==========================================
    ' Insérer une transaction
    ' ==========================================
    Private Sub InsertTransaction(t As JObject)
        Dim cs As String = ConnectionString

        Dim transactionId As String = If(t("transaction_id"), "").ToString()
        Dim description As String = If(t("name"), "").ToString()
        Dim amount As Decimal = 0D
        Decimal.TryParse(If(t("amount"), "0").ToString(), Globalization.NumberStyles.Any, Globalization.CultureInfo.InvariantCulture, amount)

        Dim accountId As String = If(t("account_id"), "").ToString()
        Dim dt As Date = Date.Today
        Date.TryParseExact(If(t("date"), "").ToString(), "yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture, Globalization.DateTimeStyles.None, dt)

        Using cn As New SqlConnection(cs)
            cn.Open()

            Dim sql As String =
"IF NOT EXISTS (SELECT 1 FROM dbo.T142ReleveBancaire WHERE Reference=@Reference AND CompanyGUID=@CompanyGUID)
BEGIN
    INSERT INTO dbo.T142ReleveBancaire
    (
        ReleveBancaireGUID,
        CompanyGUID,
        DateMouvement,
        Description,
        Reference,
        Montant,
        CompteBanque,
        Statut,
        Created
    )
    VALUES
    (
        NEWID(),
        @CompanyGUID,
        @DateMouvement,
        @Description,
        @Reference,
        @Montant,
        @CompteBanque,
        @Statut,
        GETDATE()
    )
END"

            Using cmd As New SqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@DateMouvement", dt)
                cmd.Parameters.AddWithValue("@Description", description)
                cmd.Parameters.AddWithValue("@Reference", transactionId)
                cmd.Parameters.AddWithValue("@Montant", amount)
                cmd.Parameters.AddWithValue("@CompteBanque", accountId)
                cmd.Parameters.AddWithValue("@Statut", "Importé")
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    ' ==========================================
    ' Ajax refresh
    ' ==========================================
    Private Sub RAP1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles RAP1.AjaxRequest
        If e.Argument = "refreshgrid" Then
            rlvAccounts.Rebind()
            BindAccountDropdown()
        End If
    End Sub

    ''' <summary>Traductions de l'interface Comptes bancaires (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Comptes bancaires — 60Sec-AI", "Bank accounts — 60Sec-AI", "Cuentas bancarias — 60Sec-AI")
            Case "pageTitleShort" : Return Choose3(lang, "Comptes bancaires", "Bank accounts", "Cuentas bancarias")
            Case "connectBank" : Return Choose3(lang, "Connecter une banque", "Connect a bank", "Conectar un banco")
            Case "colBank" : Return Choose3(lang, "Banque", "Bank", "Banco")
            Case "colBalance" : Return Choose3(lang, "Solde actuel", "Current balance", "Saldo actual")
            Case "colDate" : Return Choose3(lang, "Date de connexion", "Connection date", "Fecha de conexión")
            Case "colStatus" : Return Choose3(lang, "Statut", "Status", "Estado")
            Case "colAction" : Return Choose3(lang, "Action", "Action", "Acción")
            Case "lblAccount" : Return Choose3(lang, "Compte :", "Account:", "Cuenta:")
            Case "lblFrom" : Return Choose3(lang, "Du :", "From:", "Desde:")
            Case "lblTo" : Return Choose3(lang, "Au :", "To:", "Hasta:")
            Case "import" : Return Choose3(lang, "Importer", "Import", "Importar")
            Case "active" : Return Choose3(lang, "Actif", "Active", "Activo")
            Case "inactive" : Return Choose3(lang, "Déconnecté", "Disconnected", "Desconectado")
            Case "disconnect" : Return Choose3(lang, "Déconnecter", "Disconnect", "Desconectar")
            Case "confirmDisconnect" : Return Choose3(lang, "Voulez-vous vraiment déconnecter ce compte?", "Do you really want to disconnect this account?", "¿Realmente desea desconectar esta cuenta?")
            Case "empty" : Return Choose3(lang, "Aucun compte bancaire connecté.", "No bank account connected.", "Ninguna cuenta bancaria conectada.")
            Case "accountNotFound" : Return Choose3(lang, "Compte introuvable.", "Account not found.", "Cuenta no encontrada.")
            Case "txImported" : Return Choose3(lang, "{0} transaction(s) importée(s).", "{0} transaction(s) imported.", "{0} transacción(es) importada(s).")
            Case "errorPrefix" : Return Choose3(lang, "Erreur : ", "Error: ", "Error: ")
            Case "mBank" : Return Choose3(lang, "Banque : ", "Bank: ", "Banco: ")
            Case "mConnected" : Return Choose3(lang, "Connecté le : ", "Connected on: ", "Conectado el: ")
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

End Class
