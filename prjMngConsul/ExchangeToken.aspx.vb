Imports System.Data.SqlClient
Imports System.Drawing.Drawing2D
Imports System.IO
Imports System.Net.Http
Imports System.Runtime.InteropServices.ComTypes
Imports System.Threading.Tasks
Imports Newtonsoft.Json.Linq
Imports Telerik.Web.UI
Imports Telerik.Web.UI.ExportInfrastructure
Imports Telerik.Web.UI.Gantt
Imports Telerik.Web.UI.OrgChartStyles


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

            ' Récupérer tous les comptes
            Dim accounts As JArray = Await svc.GetBalancesAsync(accessToken)

            ' Récupérer les numéros de compte complets
            Dim authData As JObject = Await svc.GetAuthAsync(accessToken)



            If accounts IsNot Nothing Then
                For Each acct As JObject In accounts

                    Dim accountId As String = If(acct("account_id"), "").ToString()


                    ' Chercher le numéro de compte dans les données auth
                    Dim accountNumber As String = ""
                    Dim institutionNumber As String = ""
                    Dim branchNumber As String = ""

                    ' Pour les banques canadiennes (EFT)
                    If authData("numbers") IsNot Nothing AndAlso authData("numbers")("eft") IsNot Nothing Then
                        For Each eft As JObject In authData("numbers")("eft")
                            If eft("account_id").ToString() = accountId Then
                                accountNumber = If(eft("account"), "").ToString()
                                institutionNumber = If(eft("institution"), "").ToString()
                                branchNumber = If(eft("branch"), "").ToString()
                                Exit For
                            End If
                        Next
                    End If

                    ' Pour les banques américaines (ACH)
                    If String.IsNullOrEmpty(accountNumber) AndAlso authData("numbers") IsNot Nothing AndAlso authData("numbers")("ach") IsNot Nothing Then
                        For Each ach As JObject In authData("numbers")("ach")
                            If ach("account_id").ToString() = accountId Then
                                accountNumber = If(ach("account"), "").ToString()
                                Exit For
                            End If
                        Next
                    End If
                    Dim strauthData As String = authData.ToString


                    Dim accountName As String = If(acct("name"), "").ToString()
                    Dim accountType As String = If(acct("type"), "").ToString()
                    Dim accountSubtype As String = If(acct("subtype"), "").ToString()
                    Dim mask As String = If(acct("mask"), "").ToString()

                    Dim balAvailable As Decimal? = Nothing
                    Dim balCurrent As Decimal? = Nothing
                    Dim balLimit As Decimal? = Nothing
                    Dim currency As String = ""
                    Dim accountJson As String = ""
                    If acct("balances") IsNot Nothing Then
                        Dim b As JObject = CType(acct("balances"), JObject)
                        If b("available") IsNot Nothing AndAlso b("available").Type <> JTokenType.Null Then
                            balAvailable = CDec(b("available"))
                        End If
                        If b("current") IsNot Nothing AndAlso b("current").Type <> JTokenType.Null Then
                            balCurrent = CDec(b("current"))
                        End If
                        If b("limit") IsNot Nothing AndAlso b("limit").Type <> JTokenType.Null Then
                            balLimit = CDec(b("limit"))
                        End If
                        currency = If(b("iso_currency_code"), "").ToString()


                        accountJson = acct.ToString()  ' <-- le JSON complet


                    End If

                    SavePlaidAccount(accountNumber, institutionNumber, branchNumber, strauthData, raw, accountJson, Company, accessToken, itemId, institutionName, accountName, accountId, accountType, accountSubtype, mask, balAvailable, balCurrent, balLimit, currency)
                Next
            End If



            'Dim tx As JObject = Await svc.GetTransactionsSyncAsync(accessToken, Date.Today.AddMonths(-3), Date.Today)
            Dim tx As JObject = Await svc.GetTransactionsAsync(accessToken, Date.Today.AddMonths(-5), Date.Today)

            'If tx("transactions") IsNot Nothing Then

            '    For Each t As JObject In tx("transactions")
            '        InsertTransaction(companyGuid, t)
            '    Next
            'End If


            If tx("added") IsNot Nothing Then
                For Each t As JObject In tx("added")
                    InsertTransaction(Company, t)
                Next
            End If




            Response.Write("{""success"":true}")
        Catch ex As Exception
            Response.Write("{""success"":false,""message"":""" & EscapeJson(ex.Message) & """}")
        End Try

        Response.End()
    End Sub
    Private Function GetCompanyGuid() As Guid

        'If Session("CompanyGUID") IsNot Nothing Then
        '    Return Guid.Parse(Session("CompanyGUID").ToString())
        'End If

        Return Company
    End Function
    Private Sub SavePlaidAccount(accountNumber As String, institutionNumber As String, branchNumber As String, authData As String, raw As String, accountJson As String, companyGuid As Guid, accessToken As String, itemId As String, institutionName As String, accountName As String, accountId As String, accountType As String, accountSubtype As String, mask As String, balAvailable As Decimal?, balCurrent As Decimal?, balLimit As Decimal?, currency As String)

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))


        p.Add(New SqlClient.SqlParameter("@AccessToken", accessToken))
        p.Add(New SqlClient.SqlParameter("@ItemId", itemId))
        p.Add(New SqlClient.SqlParameter("@BankName", institutionName))
        p.Add(New SqlClient.SqlParameter("@AccountName", accountName))
        p.Add(New SqlClient.SqlParameter("@AccountId", accountId))
        p.Add(New SqlClient.SqlParameter("@AccountType", accountType))
        p.Add(New SqlClient.SqlParameter("@AccountSubtype", accountSubtype))
        p.Add(New SqlClient.SqlParameter("@Mask", mask))
        p.Add(New SqlClient.SqlParameter("@BalanceAvailable", If(balAvailable, CObj(DBNull.Value))))
        p.Add(New SqlClient.SqlParameter("@BalanceCurrent", If(balCurrent, CObj(DBNull.Value))))
        p.Add(New SqlClient.SqlParameter("@BalanceLimit", If(balLimit, CObj(DBNull.Value))))
        p.Add(New SqlClient.SqlParameter("@CurrencyCode", currency))
        p.Add(New SqlClient.SqlParameter("@Raw", raw))
        p.Add(New SqlClient.SqlParameter("@AccountJson", accountJson))
        p.Add(New SqlClient.SqlParameter("@AccountNumber", accountNumber))
        p.Add(New SqlClient.SqlParameter("@InstitutionNumber", institutionNumber))
        p.Add(New SqlClient.SqlParameter("@BranchNumber", branchNumber))
        p.Add(New SqlClient.SqlParameter("@AuthData", authData))
        ExecuteSQL("s0045SavePlaidAccount", p)
    End Sub



    Private Sub SavePlaidAccountold(accountNumber As String, institutionNumber As String, branchNumber As String, authData As String, raw As String, accountJson As String, companyGuid As Guid, accessToken As String, itemId As String, institutionName As String, accountName As String, accountId As String, accountType As String, accountSubtype As String, mask As String, balAvailable As Decimal?, balCurrent As Decimal?, balLimit As Decimal?, currency As String)
        Dim cs As String = ConnectionString

        Using cn As New SqlConnection(cs)
            cn.Open()

            Dim sql As String =
"IF NOT EXISTS (SELECT 1 FROM dbo.T143PlaidAccount WHERE CompanyGUID=@CompanyGUID AND BankName=@BankName AND Mask=@Mask AND AccountSubtype=@AccountSubtype)
BEGIN
    INSERT INTO dbo.T143PlaidAccount
    (
        CompanyGUID, AccessToken, ItemId, BankName, AccountName, AccountId,
        AccountType, AccountSubtype, Mask,
        BalanceAvailable, BalanceCurrent, BalanceLimit, CurrencyCode,
        BalanceUpdated, Created,Raw,accountJson,accountNumber, institutionNumber, branchNumber, authData
    )
    VALUES
    (
        @CompanyGUID, @AccessToken, @ItemId, @BankName, @AccountName, @AccountId,
        @AccountType, @AccountSubtype, @Mask,
        @BalanceAvailable, @BalanceCurrent, @BalanceLimit, @CurrencyCode,
        GETDATE(), GETDATE(),@Raw,@accountJson,@accountNumber, @institutionNumber, @branchNumber, @authData
    )
END
ELSE
BEGIN
    UPDATE dbo.T143PlaidAccount
    SET AccessToken = @AccessToken,
    Raw = @Raw,
    accountJson=@accountJson,
        ItemId = @ItemId,
        AccountId = @AccountId,
        accountNumber = @accountNumber, 
        institutionNumber=@institutionNumber, 
        branchNumber=@branchNumber, 
        authData=@authData,
        AccountName = @AccountName,
        BalanceAvailable = @BalanceAvailable,
        BalanceCurrent = @BalanceCurrent,
        BalanceLimit = @BalanceLimit,
        CurrencyCode = @CurrencyCode,
        BalanceUpdated = GETDATE()
    WHERE CompanyGUID = @CompanyGUID AND BankName = @BankName AND Mask = @Mask AND AccountSubtype = @AccountSubtype
END"

            Using cmd As New SqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@raw", raw)
                cmd.Parameters.AddWithValue("@accountJson", accountJson)
                cmd.Parameters.AddWithValue("@accountNumber", accountNumber)
                cmd.Parameters.AddWithValue("@institutionNumber", institutionNumber)
                cmd.Parameters.AddWithValue("@branchNumber", branchNumber)
                cmd.Parameters.AddWithValue("@authData", authData)

                cmd.Parameters.AddWithValue("@CompanyGUID", companyGuid)
                cmd.Parameters.AddWithValue("@AccessToken", accessToken)
                cmd.Parameters.AddWithValue("@ItemId", itemId)
                cmd.Parameters.AddWithValue("@BankName", institutionName)
                cmd.Parameters.AddWithValue("@AccountName", accountName)
                cmd.Parameters.AddWithValue("@AccountId", accountId)
                cmd.Parameters.AddWithValue("@AccountType", accountType)
                cmd.Parameters.AddWithValue("@AccountSubtype", accountSubtype)
                cmd.Parameters.AddWithValue("@Mask", mask)
                cmd.Parameters.AddWithValue("@BalanceAvailable", If(balAvailable, CObj(DBNull.Value)))
                cmd.Parameters.AddWithValue("@BalanceCurrent", If(balCurrent, CObj(DBNull.Value)))
                cmd.Parameters.AddWithValue("@BalanceLimit", If(balLimit, CObj(DBNull.Value)))
                cmd.Parameters.AddWithValue("@CurrencyCode", currency)
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Private Sub InsertTransaction(companyGuid As Guid, t As JObject)
        Dim cs As String = ConnectionString

        Dim transactionId As String = If(t("transaction_id"), "").ToString()
        Dim description As String = If(t("name"), "").ToString()
        Dim amount As Decimal = 0D

        Decimal.TryParse(If(t("amount"), "0").ToString(), Globalization.NumberStyles.Any, Globalization.CultureInfo.InvariantCulture, amount)

        amount = -amount
        Dim accountId As String = If(t("account_id"), "").ToString()
        Dim dt As Date = Date.Today

        Date.TryParseExact(If(t("date"), "").ToString(), "yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture, Globalization.DateTimeStyles.None, dt)

        Dim p As New Collection

        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@DateMouvement", dt))
        p.Add(New SqlClient.SqlParameter("@Description", description))
        p.Add(New SqlClient.SqlParameter("@Reference", transactionId))
        p.Add(New SqlClient.SqlParameter("@Montant", amount))
        p.Add(New SqlClient.SqlParameter("@CompteBanque", accountId))
        p.Add(New SqlClient.SqlParameter("@Statut", "Importé"))


        ExecuteSQL("s0046InsertReleveBancaire", p)









        '        Using cn As New SqlConnection(cs)
        '            cn.Open()







        '            Dim sql As String =
        '"IF NOT EXISTS (SELECT 1 FROM dbo.T142ReleveBancaire WHERE Reference=@Reference AND CompanyGUID=@CompanyGUID)
        'BEGIN
        '    INSERT INTO dbo.T142ReleveBancaire
        '    (
        '        ReleveBancaireGUID,
        '        CompanyGUID,
        '        DateMouvement,
        '        Description,
        '        Reference,
        '        Montant,
        '        CompteBanque,
        '        Statut,
        '        Created
        '    )
        '    VALUES
        '    (
        '        NEWID(),
        '        @CompanyGUID,
        '        @DateMouvement,
        '        @Description,
        '        @Reference,
        '        @Montant,
        '        @CompteBanque,
        '        @Statut,
        '        GETDATE()
        '    )
        'END"

        '            Using cmd As New SqlCommand(sql, cn)
        '                cmd.Parameters.AddWithValue("@CompanyGUID", companyGuid)
        '                cmd.Parameters.AddWithValue("@DateMouvement", dt)
        '                cmd.Parameters.AddWithValue("@Description", description)
        '                cmd.Parameters.AddWithValue("@Reference", transactionId)
        '                cmd.Parameters.AddWithValue("@Montant", amount)
        '                cmd.Parameters.AddWithValue("@CompteBanque", accountId)
        '                cmd.Parameters.AddWithValue("@Statut", "Importé")
        '                cmd.ExecuteNonQuery()
        '            End Using
        '        End Using
    End Sub

    Private Function EscapeJson(value As String) As String
        If value Is Nothing Then Return ""
        Return value.Replace("\", "\\").Replace("""", "\""").Replace(vbCrLf, "\n").Replace(vbCr, "\n").Replace(vbLf, "\n")
    End Function
End Class