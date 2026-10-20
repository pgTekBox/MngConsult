Imports System.Data.SqlClient
Imports Newtonsoft.Json.Linq
Imports System.Data
Imports System.Linq
Imports System.Text
Imports Telerik.Web.UI

Public Class PlaidAccounts
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
        SetLiteral(Me, "litRubrique", L("rubrique"))
        SetLiteral(Me, "litSousTitre", L("sousTitre"))
        SetLiteral(Me, "litReleveBtn", L("releveBtn"))
        btnConnect.Text = "+ " & L("connectBank")

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
        Dim dt As DataTable = GetData()
        rlvAccounts.DataSource = dt
        ChargerIndicateurs(dt)
        SetLiteral(Me, "litPied", Server.HtmlEncode(String.Format(L("pied"), If(dt Is Nothing, 0, dt.Rows.Count))))
    End Sub




    Private Function GetData() As DataTable

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))

        Dim ds As DataSet = ExecuteSQLds("s0044GetBankAccout", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function





    ' =====================================================================
    ' Les indicateurs (connectés / solde / déconnectés / dernière connexion)
    ' et les cellules de la liste, au style du gabarit « Portail du client ».
    ' =====================================================================

    Private Shared Function Vrai(o As Object) As Boolean
        If o Is Nothing OrElse IsDBNull(o) Then Return False
        Try
            Return Convert.ToBoolean(o)
        Catch
            Return False
        End Try
    End Function

    Public Shared Function Nombre(o As Object) As Decimal
        If o Is Nothing OrElse IsDBNull(o) Then Return 0D
        Try
            Return Convert.ToDecimal(o)
        Catch
            Return 0D
        End Try
    End Function

    Private Sub ChargerIndicateurs(dt As DataTable)
        Dim rows As List(Of DataRow) = If(dt Is Nothing, New List(Of DataRow), dt.Rows.Cast(Of DataRow)().ToList())
        Dim actifs As List(Of DataRow) = rows.Where(Function(r) Vrai(r("Active"))).ToList()
        Dim solde As Decimal = actifs.Sum(Function(r) Nombre(r("BalanceCurrent")))
        Dim derniere As String = "—"
        If rows.Count > 0 Then
            Dim d As Object = rows.Select(Function(r) r("Created")).Where(Function(o) o IsNot Nothing AndAlso Not IsDBNull(o)).OrderByDescending(Function(o) Convert.ToDateTime(o)).FirstOrDefault()
            If d IsNot Nothing Then derniere = FormatDateOnly(d)
        End If
        Dim sb As New StringBuilder()
        sb.Append(Kpi(L("kpiConnectes"), actifs.Count & " / " & rows.Count, L("kpiConnectesSub"), If(actifs.Count > 0, "#43B47A", "#AEBBCD")))
        sb.Append(Kpi(L("kpiSolde"), FormatMontant(solde), L("kpiSoldeSub"), "#1B4F9C"))
        sb.Append(Kpi(L("kpiDeconnectes"), (rows.Count - actifs.Count).ToString(), L("kpiDeconnectesSub"), "#AEBBCD"))
        sb.Append(Kpi(L("kpiDerniere"), derniere, L("kpiDerniereSub"), "#E3B341"))
        SetLiteral(Me, "litKpis", sb.ToString())
    End Sub

    Private Function Kpi(lab As String, val As String, sub_ As String, point As String) As String
        Return "<div class=""fc-kpi""><span class=""lab""><i style=""background:" & point & """></i>" & Server.HtmlEncode(lab) & "</span>" &
               "<span class=""val"">" & Server.HtmlEncode(val) & "</span><span class=""sub"">" & Server.HtmlEncode(sub_) & "</span></div>"
    End Function

    ''' <summary>La banque en gras, le compte et son numéro dessous.</summary>
    Public Function BanqueCell(banque As Object, compte As Object, numero As Object) As String
        Dim b As String = Convert.ToString(banque).Trim()
        Dim c As String = (Convert.ToString(compte).Trim() & " " & Convert.ToString(numero).Trim()).Trim()
        Return "<b>" & Server.HtmlEncode(If(b = "", c, b)) & "</b>" & If(b <> "" AndAlso c <> "", "<span>" & Server.HtmlEncode(c) & "</span>", "")
    End Function

    Public Function FormatMontant(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return "—"
        Return Nombre(value).ToString("#,##0.00 $")
    End Function

    Public Function FormatDateOnly(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return "—"
        Return Convert.ToDateTime(value).ToString("d MMM yyyy").ToLower()
    End Function

    ''' <summary>Un point vert « Actif » ou gris « Déconnecté ».</summary>
    Public Function EtatCell(actif As Object) As String
        Dim ok As Boolean = Vrai(actif)
        Return "<span class=""fc-etat"" style=""color:" & If(ok, "#0F5A3A", "#5B6B86") & """><i class=""pt"" style=""background:" & If(ok, "#43B47A", "#AEBBCD") & """></i>" &
               Server.HtmlEncode(If(ok, L("active"), L("inactive"))) & "</span>"
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
            Case "rubrique" : Return Choose3(lang, "Comptabilité", "Accounting", "Contabilidad")
            Case "sousTitre" : Return Choose3(lang, "Vos banques connectées, leurs soldes et l'importation de leurs transactions.", "Your connected banks, their balances and the import of their transactions.", "Sus bancos conectados, sus saldos y la importación de sus transacciones.")
            Case "releveBtn" : Return Choose3(lang, "Relevé bancaire", "Bank statement", "Estado de cuenta")
            Case "kpiConnectes" : Return Choose3(lang, "Comptes connectés", "Connected accounts", "Cuentas conectadas")
            Case "kpiConnectesSub" : Return Choose3(lang, "actifs", "active", "activas")
            Case "kpiSolde" : Return Choose3(lang, "Solde des comptes", "Accounts balance", "Saldo de las cuentas")
            Case "kpiSoldeSub" : Return Choose3(lang, "comptes connectés", "connected accounts", "cuentas conectadas")
            Case "kpiDeconnectes" : Return Choose3(lang, "Déconnectés", "Disconnected", "Desconectadas")
            Case "kpiDeconnectesSub" : Return Choose3(lang, "historique conservé", "history kept", "historial conservado")
            Case "kpiDerniere" : Return Choose3(lang, "Dernière connexion", "Last connection", "Última conexión")
            Case "kpiDerniereSub" : Return Choose3(lang, "banque reliée", "bank linked", "banco vinculado")
            Case "pied" : Return Choose3(lang, "{0} compte(s)", "{0} account(s)", "{0} cuenta(s)")
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
            Case "empty" : Return Choose3(lang, "Aucune banque connectée pour l'instant.", "No bank connected yet.", "Ningún banco conectado por ahora.")
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
