Imports System.Data.SqlClient
Imports Newtonsoft.Json.Linq

Public Class PlaidDailySync
    Inherits clsData

    Protected Async Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Response.ContentType = "application/json"

        Try
            Dim accounts As List(Of PlaidAccountInfo) = GetAllPlaidAccounts()
            Dim totalInserted As Integer = 0

            Dim svc As New Plaid()

            For Each acct In accounts
                Try
                    Dim tx As JObject = Await svc.GetTransactionsAsync(acct.AccessToken, Date.Today.AddDays(-2), Date.Today)

                    If tx("added") IsNot Nothing Then
                        For Each t As JObject In tx("added")
                            InsertTransaction(acct.CompanyGUID, t)
                            totalInserted += 1
                        Next
                    End If
                Catch exAcct As Exception
                    ' Log l'erreur mais continue avec les autres comptes
                    LogSyncError(acct.CompanyGUID, acct.ItemId, exAcct.Message)
                End Try
            Next

            Response.Write("{""success"":true,""inserted"":" & totalInserted & "}")
        Catch ex As Exception
            Response.Write("{""success"":false,""message"":""" & EscapeJson(ex.Message) & """}")
        End Try

        Response.End()
    End Sub

    Private Function GetAllPlaidAccounts() As List(Of PlaidAccountInfo)
        Dim result As New List(Of PlaidAccountInfo)
        Dim cs As String = ConnectionString

        Using cn As New SqlConnection(cs)
            cn.Open()
            Dim sql As String = "SELECT CompanyGUID, AccessToken, ItemId, BankName FROM dbo.T143PlaidAccount WHERE Active = 1"
            Using cmd As New SqlCommand(sql, cn)
                Using dr = cmd.ExecuteReader()
                    While dr.Read()
                        result.Add(New PlaidAccountInfo With {
                            .CompanyGUID = dr.GetGuid(0),
                            .AccessToken = dr.GetString(1),
                            .ItemId = dr.GetString(2),
                            .BankName = dr.GetString(3)
                        })
                    End While
                End Using
            End Using
        End Using

        Return result
    End Function

    Private Sub LogSyncError(companyGuid As Guid, itemId As String, errorMessage As String)
        Dim cs As String = ConnectionString

        Using cn As New SqlConnection(cs)
            cn.Open()
            Dim sql As String =
"INSERT INTO dbo.T144PlaidSyncLog (CompanyGUID, ItemId, ErrorMessage, Created)
VALUES (@CompanyGUID, @ItemId, @ErrorMessage, GETDATE())"
            Using cmd As New SqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@CompanyGUID", companyGuid)
                cmd.Parameters.AddWithValue("@ItemId", itemId)
                cmd.Parameters.AddWithValue("@ErrorMessage", errorMessage)
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
    Private Class PlaidAccountInfo
        Public Property CompanyGUID As Guid
        Public Property AccessToken As String
        Public Property ItemId As String
        Public Property BankName As String
    End Class
End Class