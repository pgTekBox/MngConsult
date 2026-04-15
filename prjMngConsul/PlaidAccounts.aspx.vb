Imports System.Data.SqlClient
Imports Newtonsoft.Json.Linq
Imports Telerik.Web.UI

Public Class PlaidAccounts
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            rlvAccounts.Rebind()
            BindAccountDropdown()

            Dim txtStart As TextBox = CType(rlvAccounts.FindControl("txtStartDate"), TextBox)
            Dim txtEnd As TextBox = CType(rlvAccounts.FindControl("txtEndDate"), TextBox)
            If txtStart IsNot Nothing Then txtStart.Text = Date.Today.AddMonths(-1).ToString("yyyy-MM-dd")
            If txtEnd IsNot Nothing Then txtEnd.Text = Date.Today.ToString("yyyy-MM-dd")
        End If
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
                lbl.Text = "Compte introuvable."
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

            lbl.Text = count & " transaction(s) importée(s)."
            lbl.CssClass = "import-result text-success"
            lbl.Visible = True

        Catch ex As Exception
            lbl.Text = "Erreur : " & ex.Message
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

End Class
