Imports System.Data.SqlClient
Imports System.IO
Imports System.Runtime.InteropServices.ComTypes
Imports Newtonsoft.Json.Linq
Imports Telerik.Web.UI


Public Class ExchangeToken
    Inherits clsData

    Protected Async Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Response.ContentType = "application/json"

        If Request.HttpMethod <> "POST" Then
            Response.Write("{""success"":false,""message"":""POST requis""}")
            Response.End()
            Return
        End If

        Try
            Dim raw As String
            Using sr As New StreamReader(Request.InputStream)
                raw = Await sr.ReadToEndAsync()
            End Using

            Dim input As JObject = JObject.Parse(raw)
            Dim publicToken As String = input("public_token").ToString()
            Dim institutionName As String = If(input("institution_name"), "").ToString()

            Dim svc As New Plaid()
            Dim ex As JObject = Await svc.ExchangePublicTokenAsync(publicToken)

            Dim accessToken As String = ex("access_token").ToString()
            Dim itemId As String = ex("item_id").ToString()

            Dim companyGuid As Guid = GetCompanyGuid()

            SavePlaidAccount(companyGuid, accessToken, itemId, institutionName)

            'Dim tx As JObject = Await svc.GetTransactionsSyncAsync(accessToken, Date.Today.AddMonths(-3), Date.Today)
            Dim tx As JObject = Await svc.GetTransactionsAsync(accessToken, Date.Today.AddMonths(-5), Date.Today)

            'If tx("transactions") IsNot Nothing Then

            '    For Each t As JObject In tx("transactions")
            '        InsertTransaction(companyGuid, t)
            '    Next
            'End If


            If tx("added") IsNot Nothing Then
                For Each t As JObject In tx("added")
                    InsertTransaction(companyGuid, t)
                Next
            End If




            Response.Write("{""success"":true}")
        Catch ex As Exception
            Response.Write("{""success"":false,""message"":""" & EscapeJson(ex.Message) & """}")
        End Try

        Response.End()
    End Sub
    Private Function GetCompanyGuid() As Guid
        If Session("CompanyGUID") IsNot Nothing Then
            Return Guid.Parse(Session("CompanyGUID").ToString())
        End If

        Return Guid.Empty
    End Function

    Private Sub SavePlaidAccount(companyGuid As Guid, accessToken As String, itemId As String, institutionName As String)
        Dim cs As String = ConnectionString

        Using cn As New SqlConnection(cs)
            cn.Open()

            Dim sql As String =
"IF NOT EXISTS (SELECT 1 FROM dbo.T143PlaidAccount WHERE CompanyGUID=@CompanyGUID AND ItemId=@ItemId)
BEGIN
    INSERT INTO dbo.T143PlaidAccount
    (
        CompanyGUID,
        AccessToken,
        ItemId,
        BankName,
        Created
    )
    VALUES
    (
        @CompanyGUID,
        @AccessToken,
        @ItemId,
        @BankName,
        GETDATE()
    )
END"

            Using cmd As New SqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@CompanyGUID", companyGuid)
                cmd.Parameters.AddWithValue("@AccessToken", accessToken)
                cmd.Parameters.AddWithValue("@ItemId", itemId)
                cmd.Parameters.AddWithValue("@BankName", institutionName)
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Private Sub InsertTransaction(companyGuid As Guid, t As JObject)
        Dim cs As String = ConnectionString

        Dim transactionId As String = If(t("transaction_id"), "").ToString()
        Dim description As String = If(t("name"), "").ToString()
        Dim amount As Decimal = 0D
        Decimal.TryParse(If(t("amount"), "0").ToString(), amount)

        Dim accountId As String = If(t("account_id"), "").ToString()
        Dim dt As Date = Date.Today
        Date.TryParse(If(t("date"), "").ToString(), dt)

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
                cmd.Parameters.AddWithValue("@CompanyGUID", companyGuid)
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

    Private Function EscapeJson(value As String) As String
        If value Is Nothing Then Return ""
        Return value.Replace("\", "\\").Replace("""", "\""").Replace(vbCrLf, "\n").Replace(vbCr, "\n").Replace(vbLf, "\n")
    End Function
End Class