Imports System.Configuration
Imports System.Data.SqlClient
Imports System.IO
Imports System.Threading.Tasks
Imports Newtonsoft.Json.Linq

''' <summary>
''' Récepteur des webhooks Plaid (appel serveur-à-serveur, sans session utilisateur).
''' URL configurée dans Web.config (Plaid.WebhookUrl) et envoyée à Plaid via le link-token.
''' Sécurité : secret partagé optionnel comparé au paramètre ?k= (Plaid.WebhookSecret).
''' Sur un événement de transactions, synchronise l'item concerné vers T142ReleveBancaire.
''' </summary>
Public Class PlaidWebhook
    Inherits System.Web.UI.Page

    Protected Async Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Response.ContentType = "application/json"

        ' --- Vérification optionnelle par secret partagé (?k=) ---
        Dim expected As String = If(ConfigurationManager.AppSettings("Plaid.WebhookSecret"), "").Trim()
        If Not String.IsNullOrEmpty(expected) Then
            If Not String.Equals(If(Request.QueryString("k"), ""), expected, StringComparison.Ordinal) Then
                Response.StatusCode = 401
                Response.Write("{""error"":""unauthorized""}")
                Response.End()
                Return
            End If
        End If

        ' --- Lecture du corps JSON ---
        Dim body As String = ""
        Try
            Request.InputStream.Position = 0
            Using rd As New StreamReader(Request.InputStream)
                body = rd.ReadToEnd()
            End Using
        Catch
        End Try

        If String.IsNullOrWhiteSpace(body) Then
            Response.Write("{""success"":true}")
            Response.End()
            Return
        End If

        Try
            Dim jo As JObject = JObject.Parse(body)
            Dim webhookType As String = If(jo("webhook_type"), "").ToString().ToUpperInvariant()
            Dim webhookCode As String = If(jo("webhook_code"), "").ToString().ToUpperInvariant()
            Dim itemId As String = If(jo("item_id"), "").ToString()

            Select Case webhookType
                Case "TRANSACTIONS"
                    Select Case webhookCode
                        Case "INITIAL_UPDATE", "HISTORICAL_UPDATE", "DEFAULT_UPDATE", "SYNC_UPDATES_AVAILABLE"
                            Await SyncItemTransactions(itemId)
                    End Select

                Case "ITEM"
                    If webhookCode = "ERROR" OrElse webhookCode = "PENDING_EXPIRATION" _
                       OrElse webhookCode = "USER_PERMISSION_REVOKED" OrElse webhookCode = "LOGIN_REPAIRED" Then
                        LogWebhook(itemId, webhookType & "/" & webhookCode & " : " & body)
                    End If
            End Select
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("PlaidWebhook error: " & ex.Message)
            ' On répond 200 malgré tout : évite les ré-essais en boucle de Plaid.
        End Try

        Response.Write("{""success"":true}")
        Response.End()
    End Sub

    Private Function CS() As String
        Return ConfigurationManager.AppSettings("ConnectionString")
    End Function

    ''' <summary>Synchronise les transactions récentes de l'item Plaid concerné.</summary>
    Private Async Function SyncItemTransactions(itemId As String) As Task
        If String.IsNullOrWhiteSpace(itemId) Then Return

        Dim accessToken As String = ""
        Dim companyGuid As Guid = Guid.Empty
        Dim autoImport As Boolean = True

        Using cn As New SqlConnection(CS())
            cn.Open()
            ' On joint T010Company pour lire l'interrupteur d'import automatique de la compagnie.
            Using cmd As New SqlCommand("SELECT TOP 1 a.AccessToken, a.CompanyGUID, ISNULL(c.PlaidAutoImport, 1) " &
                                        "FROM dbo.T143PlaidAccount a " &
                                        "INNER JOIN dbo.T010Company c ON c.CompanyGUID = a.CompanyGUID " &
                                        "WHERE a.ItemId=@ItemId AND a.Active=1", cn)
                cmd.Parameters.AddWithValue("@ItemId", itemId)
                Using dr = cmd.ExecuteReader()
                    If dr.Read() Then
                        accessToken = dr.GetString(0)
                        companyGuid = dr.GetGuid(1)
                        autoImport = dr.GetBoolean(2)
                    End If
                End Using
            End Using
        End Using

        If String.IsNullOrEmpty(accessToken) Then Return

        ' Import automatique désactivé pour cette compagnie : on ne synchronise pas.
        If Not autoImport Then Return

        Try
            Dim svc As New Plaid()
            Dim tx As JObject = Await svc.GetTransactionsAsync(accessToken, Date.Today.AddDays(-14), Date.Today)
            If tx("added") IsNot Nothing Then
                For Each t As JObject In tx("added")
                    InsertTransaction(companyGuid, t)
                Next
            End If
        Catch ex As Exception
            LogWebhook(itemId, "SYNC_ERROR : " & ex.Message, companyGuid)
        End Try
    End Function

    Private Sub InsertTransaction(companyGuid As Guid, t As JObject)
        Dim transactionId As String = If(t("transaction_id"), "").ToString()
        Dim description As String = If(t("name"), "").ToString()
        Dim amount As Decimal = 0D
        Decimal.TryParse(If(t("amount"), "0").ToString(), Globalization.NumberStyles.Any, Globalization.CultureInfo.InvariantCulture, amount)
        amount = -amount
        Dim accountId As String = If(t("account_id"), "").ToString()
        Dim dt As Date = Date.Today
        Date.TryParseExact(If(t("date"), "").ToString(), "yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture, Globalization.DateTimeStyles.None, dt)

        Using cn As New SqlConnection(CS())
            cn.Open()
            Dim sql As String =
"IF NOT EXISTS (SELECT 1 FROM dbo.T142ReleveBancaire WHERE Reference=@Reference AND CompanyGUID=@CompanyGUID)
BEGIN
    INSERT INTO dbo.T142ReleveBancaire
    (ReleveBancaireGUID, CompanyGUID, DateMouvement, Description, Reference, Montant, CompteBanque, Statut, Created)
    VALUES (NEWID(), @CompanyGUID, @DateMouvement, @Description, @Reference, @Montant, @CompteBanque, @Statut, GETDATE())
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

    Private Sub LogWebhook(itemId As String, message As String, Optional companyGuid As Guid = Nothing)
        Try
            Using cn As New SqlConnection(CS())
                cn.Open()
                Dim sql As String =
"INSERT INTO dbo.T144PlaidSyncLog (CompanyGUID, ItemId, ErrorMessage, Created)
VALUES (@CompanyGUID, @ItemId, @ErrorMessage, GETDATE())"
                Using cmd As New SqlCommand(sql, cn)
                    cmd.Parameters.AddWithValue("@CompanyGUID", companyGuid)
                    cmd.Parameters.AddWithValue("@ItemId", If(itemId, ""))
                    cmd.Parameters.AddWithValue("@ErrorMessage", If(message, ""))
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch
            ' log best-effort
        End Try
    End Sub

End Class
