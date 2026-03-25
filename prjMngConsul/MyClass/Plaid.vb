Imports System.Net.Http
Imports System.Threading.Tasks
Imports Newtonsoft.Json.Linq

Public Class Plaid

    Private ReadOnly _clientId As String = "69c41b51df332d000d1bec94"
    Private ReadOnly _secret As String = "fe6a83feeae60c5e7512af8f0691fa"
    Private ReadOnly _baseUrl As String = "https://sandbox.plaid.com"

    Public Async Function CreateLinkTokenAsync(clientUserId As String) As Task(Of String)

        Dim url As String = "https://sandbox.plaid.com/link/token/create"



        Dim payload As String =
"{
  ""client_id"": """ & JsonSafe(_clientId) & """,
  ""secret"": """ & JsonSafe(_secret) & """,
  ""client_name"": ""MngConsul"",
  ""language"": ""fr"",
  ""country_codes"": [""CA""],
  ""user"": {
    ""client_user_id"": """ & JsonSafe(clientUserId) & """
  },
  ""products"": [""transactions""]
}"

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

    Private Function JsonSafe(value As String) As String
        If value Is Nothing Then Return ""
        Return value.Replace("\", "\\").Replace("""", "\""")
    End Function


End Class
