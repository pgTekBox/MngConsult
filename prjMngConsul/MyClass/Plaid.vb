Imports System.Configuration
Imports System.Net.Http
Imports System.Threading.Tasks
Imports Newtonsoft.Json.Linq

Public Class Plaid

    ' Identifiants et environnement lus depuis Web.config (appSettings).
    ' Plaid.Environment = "sandbox" | "development" | "production" ; l'URL de base en decoule.
    Private ReadOnly _clientId As String = If(ConfigurationManager.AppSettings("Plaid.ClientId"), "")
    Private ReadOnly _secret As String = If(ConfigurationManager.AppSettings("Plaid.Secret"), "")
    Private ReadOnly _baseUrl As String = ResolvePlaidBaseUrl()
    Private ReadOnly _redirectUri As String = If(ConfigurationManager.AppSettings("Plaid.RedirectUri"), "").Trim()
    Private ReadOnly _webhookUrl As String = If(ConfigurationManager.AppSettings("Plaid.WebhookUrl"), "").Trim()

    ''' <summary>Derive l'URL de base Plaid depuis Plaid.Environment (defaut : sandbox).</summary>
    Private Shared Function ResolvePlaidBaseUrl() As String
        Dim env As String = If(ConfigurationManager.AppSettings("Plaid.Environment"), "sandbox").Trim().ToLowerInvariant()
        Select Case env
            Case "production", "prod" : Return "https://production.plaid.com"
            Case "development", "dev" : Return "https://development.plaid.com"
            Case Else : Return "https://sandbox.plaid.com"
        End Select
    End Function

    Public Async Function CreateLinkTokenAsync(clientUserId As Guid) As Task(Of String)

        Dim url As String = _baseUrl & "/link/token/create"

        ' Construction via JObject pour ajouter proprement les champs optionnels
        ' (redirect_uri pour les banques OAuth, webhook pour les notifications de transactions).
        Dim jo As New JObject()
        jo("client_id") = _clientId
        jo("secret") = _secret
        jo("client_name") = "60Sec-AI"
        jo("language") = "fr"
        jo("country_codes") = New JArray("CA")
        jo("user") = New JObject(New JProperty("client_user_id", clientUserId.ToString()))
        jo("products") = New JArray("transactions")
        jo("optional_products") = New JArray("auth")

        ' redirect_uri : requis pour les institutions OAuth ; DOIT etre enregistre dans le Dashboard Plaid.
        If Not String.IsNullOrEmpty(_redirectUri) Then jo("redirect_uri") = _redirectUri
        ' webhook : Plaid POST les evenements (nouvelles transactions, erreurs d'item) a cette URL.
        If Not String.IsNullOrEmpty(_webhookUrl) Then jo("webhook") = _webhookUrl

        Dim payload As String = jo.ToString()

        Using client As New HttpClient()
            Dim content As New StringContent(payload, Encoding.UTF8, "application/json")
            Dim response = Await client.PostAsync(url, content)
            Dim body = Await response.Content.ReadAsStringAsync()

            If Not response.IsSuccessStatusCode Then
                Throw New Exception("Erreur Plaid link/token/create : " & body)
            End If

            Dim j As JObject = JObject.Parse(body)
            Return j("link_token").ToString()
        End Using
    End Function

    Public Async Function ExchangePublicTokenAsync(publicToken As String) As Task(Of JObject)
        Dim url As String = _baseUrl & "/item/public_token/exchange"

        Dim payload As String =
"{
  ""client_id"": """ & JsonSafe(_clientId) & """,
  ""secret"": """ & JsonSafe(_secret) & """,
  ""public_token"": """ & JsonSafe(publicToken) & """
}"

        Using client As New HttpClient()
            Dim content As New StringContent(payload, Encoding.UTF8, "application/json")
            Dim response = Await client.PostAsync(url, content)
            Dim body = Await response.Content.ReadAsStringAsync()

            If Not response.IsSuccessStatusCode Then
                Throw New Exception("Erreur Plaid public_token/exchange : " & body)
            End If

            Return JObject.Parse(body)
        End Using
    End Function
    Public Async Function GetTransactionsAsync(accessToken As String, startDate As Date, endDate As Date) As Task(Of JObject)
        Dim url As String = _baseUrl & "/transactions/get"
        Dim allAdded As New JArray()
        Dim offset As Integer = 0
        Dim totalTransactions As Integer = 1

        Using client As New HttpClient()
            While offset < totalTransactions
                Dim payload As String =
"{
  ""client_id"": """ & JsonSafe(_clientId) & """,
  ""secret"": """ & JsonSafe(_secret) & """,
  ""access_token"": """ & JsonSafe(accessToken) & """,
  ""start_date"": """ & startDate.ToString("yyyy-MM-dd") & """,
  ""end_date"": """ & endDate.ToString("yyyy-MM-dd") & """,
  ""options"": {
    ""count"": 100,
    ""offset"": " & offset & "
  }
}"
                Dim content As New StringContent(payload, Encoding.UTF8, "application/json")
                Dim response = Await client.PostAsync(url, content)
                Dim body = Await response.Content.ReadAsStringAsync()

                If Not response.IsSuccessStatusCode Then
                    Throw New Exception("Erreur Plaid transactions/get : " & body)
                End If

                Dim j As JObject = JObject.Parse(body)

                If j("transactions") IsNot Nothing Then
                    For Each item In j("transactions")
                        allAdded.Add(item)
                    Next
                End If

                totalTransactions = CInt(j("total_transactions"))
                offset += 100
            End While

            Dim result As New JObject()
            result("added") = allAdded
            Return result
        End Using
    End Function
    Public Async Function GetTransactionsSyncAsync(accessToken As String, startDate As Date, endDate As Date) As Task(Of JObject)
        Dim url As String = _baseUrl & "/transactions/sync"

        Dim payload As String =
"{
  ""client_id"": """ & JsonSafe(_clientId) & """,
  ""secret"": """ & JsonSafe(_secret) & """,
  ""access_token"": """ & JsonSafe(accessToken) & """
}"

        Using client As New HttpClient()
            Dim allAdded As New JArray()
            Dim hasMore As Boolean = True
            Dim cursor As String = Nothing

            While hasMore
                Dim currentPayload As String = payload

                If Not String.IsNullOrWhiteSpace(cursor) Then
                    currentPayload = currentPayload.TrimEnd("}"c) & ",""cursor"":""" & JsonSafe(cursor) & """}"
                End If

                Dim content As New StringContent(currentPayload, Encoding.UTF8, "application/json")
                Dim response = Await client.PostAsync(url, content)
                Dim body = Await response.Content.ReadAsStringAsync()

                If Not response.IsSuccessStatusCode Then
                    Throw New Exception("Erreur Plaid transactions/sync : " & body)
                End If

                Dim j As JObject = JObject.Parse(body)

                If j("added") IsNot Nothing Then
                    For Each item In j("added")
                        Dim dt As Date
                        If item("date") IsNot Nothing AndAlso Date.TryParse(item("date").ToString(), dt) Then
                            If dt >= startDate AndAlso dt <= endDate Then
                                allAdded.Add(item)
                            End If
                        End If
                    Next
                End If

                hasMore = False
                If j("has_more") IsNot Nothing Then
                    hasMore = CBool(j("has_more"))
                End If

                If j("next_cursor") IsNot Nothing Then
                    cursor = j("next_cursor").ToString()
                Else
                    cursor = Nothing
                End If
            End While

            Dim result As New JObject()
            result("added") = allAdded
            Return result
        End Using
    End Function
    Public Async Function GetAccountsAsync(accessToken As String) As Task(Of JArray)
        Dim url As String = _baseUrl & "/accounts/get"
        Dim payload As String =
"{
  ""client_id"": """ & JsonSafe(_clientId) & """,
  ""secret"": """ & JsonSafe(_secret) & """,
  ""access_token"": """ & JsonSafe(accessToken) & """
}"

        Using client As New HttpClient()
            Dim content As New StringContent(payload, Encoding.UTF8, "application/json")
            Dim response = Await client.PostAsync(url, content)
            Dim body = Await response.Content.ReadAsStringAsync()

            If Not response.IsSuccessStatusCode Then
                Throw New Exception("Erreur Plaid accounts/get : " & body)
            End If

            Dim j As JObject = JObject.Parse(body)
            Return CType(j("accounts"), JArray)
        End Using
    End Function



    Public Async Function GetBalancesAsync(accessToken As String) As Task(Of JArray)
        Dim url As String = _baseUrl & "/accounts/balance/get"
        Dim payload As String =
"{
  ""client_id"": """ & JsonSafe(_clientId) & """,
  ""secret"": """ & JsonSafe(_secret) & """,
  ""access_token"": """ & JsonSafe(accessToken) & """
}"

        Using client As New HttpClient()
            Dim content As New StringContent(payload, Encoding.UTF8, "application/json")
            Dim response = Await client.PostAsync(url, content)
            Dim body = Await response.Content.ReadAsStringAsync()

            If Not response.IsSuccessStatusCode Then
                Throw New Exception("Erreur Plaid accounts/balance/get : " & body)
            End If

            Dim j As JObject = JObject.Parse(body)
            Return CType(j("accounts"), JArray)
        End Using
    End Function

    Public Async Function GetAuthAsync(accessToken As String) As Task(Of JObject)
        Dim url As String = _baseUrl & "/auth/get"
        Dim payload As String =
"{
  ""client_id"": """ & JsonSafe(_clientId) & """,
  ""secret"": """ & JsonSafe(_secret) & """,
  ""access_token"": """ & JsonSafe(accessToken) & """
}"

        Using client As New HttpClient()
            Dim content As New StringContent(payload, Encoding.UTF8, "application/json")
            Dim response = Await client.PostAsync(url, content)
            Dim body = Await response.Content.ReadAsStringAsync()

            If Not response.IsSuccessStatusCode Then
                Throw New Exception("Erreur Plaid auth/get : " & body)
            End If

            Return JObject.Parse(body)
        End Using
    End Function




    Private Function JsonSafe(value As String) As String
        If value Is Nothing Then Return ""
        Return value.Replace("\", "\\").Replace("""", "\""")
    End Function


End Class
