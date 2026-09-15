Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Text

Public Class ApideckException
    Inherits Exception

    Public ReadOnly Property CodeHttp As Integer

    Public Sub New(message As String, Optional codeHttp As Integer = 0)
        MyBase.New(message)
        Me.CodeHttp = codeHttp
    End Sub
End Class

''' <summary>
''' Les appels à Apideck (https://unify.apideck.com).
'''
''' Apideck est une API « unifiée » : chaque appel est traduit à la volée en appel
''' QuickBooks Online, pour le compte d'un consommateur (x-apideck-consumer-id) —
''' ici, la société dont on reprend les données. Le consommateur relie son
''' QuickBooks une fois dans Vault, la page de connexion hébergée par Apideck,
''' avec l'application Intuit dont les clés ont été données à Apideck.
'''
''' Contrairement à Codat, rien n'est synchronisé d'avance : on lit QuickBooks
''' en direct, à chaque extraction.
''' </summary>
Public Class ApideckClient

    Private Const Base As String = "https://unify.apideck.com"
    Private Const TaillePage As Integer = 200

    Private Shared ReadOnly Http As New HttpClient() With {.Timeout = TimeSpan.FromMinutes(3)}

    Private ReadOnly _cle As String
    Private ReadOnly _appId As String
    Private ReadOnly _consumerId As String
    Private ReadOnly _serviceId As String

    Public Sub New(cleApi As String, appId As String, consumerId As String, serviceId As String)
        _cle = cleApi.Trim()
        If _cle.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase) Then _cle = _cle.Substring(7).Trim()
        _appId = appId.Trim()
        _consumerId = consumerId.Trim()
        _serviceId = If(serviceId, "").Trim()
    End Sub

#Region "Appels de base"

    Public Function GetAsync(chemin As String, ct As CancellationToken) As Task(Of JsonNode)
        Return EnvoyerAsync(HttpMethod.Get, chemin, Nothing, ct)
    End Function

    Public Function PostAsync(chemin As String, corpsJson As String, ct As CancellationToken) As Task(Of JsonNode)
        Return EnvoyerAsync(HttpMethod.Post, chemin, corpsJson, ct)
    End Function

    Private Async Function EnvoyerAsync(methode As HttpMethod, chemin As String, corpsJson As String,
                                        ct As CancellationToken) As Task(Of JsonNode)
        Const Essais As Integer = 6

        For essai = 1 To Essais
            Using req As New HttpRequestMessage(methode, Base & chemin)
                req.Headers.Authorization = New AuthenticationHeaderValue("Bearer", _cle)
                req.Headers.Accept.Add(New MediaTypeWithQualityHeaderValue("application/json"))
                req.Headers.Add("x-apideck-app-id", _appId)
                req.Headers.Add("x-apideck-consumer-id", _consumerId)
                If _serviceId <> "" AndAlso chemin.StartsWith("/accounting/") Then req.Headers.Add("x-apideck-service-id", _serviceId)
                If corpsJson IsNot Nothing Then req.Content = New StringContent(corpsJson, Encoding.UTF8, "application/json")

                Using rep = Await Http.SendAsync(req, ct)
                    Dim corps = Await rep.Content.ReadAsStringAsync(ct)
                    If rep.IsSuccessStatusCode Then
                        Return If(String.IsNullOrWhiteSpace(corps), Nothing, JsonNode.Parse(corps))
                    End If

                    Dim code = CInt(rep.StatusCode)
                    If (code = 429 OrElse code >= 500) AndAlso essai < Essais Then
                        Dim delai = If(rep.Headers.RetryAfter?.Delta, TimeSpan.FromSeconds(Math.Pow(2, essai)))
                        Await Task.Delay(delai, ct)
                        Continue For
                    End If

                    Throw New ApideckException(MessageErreur(code, corps), code)
                End Using
            End Using
        Next

        Throw New ApideckException("Apideck ne répond pas après plusieurs essais.")
    End Function

    ''' <summary>
    ''' Toutes les pages d'une liste (200 par page, le maximum d'Apideck), en
    ''' suivant le curseur meta.cursors.next. <paramref name="filtres"/> est déjà
    ''' encodé (« &amp;filter[start_date]=2026-01-01 »), ou vide.
    ''' </summary>
    Public Async Function ListeToutAsync(chemin As String, filtres As String,
                                         progres As Action(Of Integer), ct As CancellationToken) As Task(Of List(Of JsonNode))
        Dim tout As New List(Of JsonNode)
        Dim curseur = ""

        Do
            Dim url = chemin & $"?limit={TaillePage}" & filtres &
                      If(curseur = "", "", "&cursor=" & Uri.EscapeDataString(curseur))
            Dim rep = Await GetAsync(url, ct)

            Dim lot = TryCast(JsonChemin.Enfant(rep, "data"), JsonArray)
            If lot Is Nothing OrElse lot.Count = 0 Then Exit Do

            tout.AddRange(lot)
            progres?.Invoke(tout.Count)

            Dim suivant = JsonChemin.Valeur(rep, "meta.cursors.next")
            If suivant = "" OrElse suivant = curseur Then Exit Do
            curseur = suivant
        Loop

        Return tout
    End Function

    ''' <summary>Un seul objet (informations de la société, rapports) : le contenu de « data ».</summary>
    Public Async Function UnAsync(chemin As String, ct As CancellationToken) As Task(Of JsonNode)
        Return JsonChemin.Enfant(Await GetAsync(chemin, ct), "data")
    End Function

#End Region

#Region "Vault : relier la société"

    ''' <summary>
    ''' Ouvre une session Vault pour le consommateur. La réponse porte l'adresse
    ''' (session_uri) de la page où il relie son QuickBooks.
    ''' </summary>
    Public Async Function CreerSessionAsync(nomSociete As String, ct As CancellationToken) As Task(Of String)
        Dim corps As New JsonObject From {
            {"consumer_metadata", New JsonObject From {{"account_name", nomSociete}}},
            {"settings", New JsonObject From {{"unified_apis", New JsonArray("accounting")}}}
        }
        Dim rep = Await PostAsync("/vault/sessions", corps.ToJsonString(), ct)
        Return JsonChemin.Valeur(rep, "data.session_uri")
    End Function

    ''' <summary>Les connexions du consommateur à l'API comptable.</summary>
    Public Async Function ConnexionsAsync(ct As CancellationToken) As Task(Of List(Of JsonNode))
        Dim rep = Await GetAsync("/vault/connections?api=accounting", ct)
        Dim t = TryCast(JsonChemin.Enfant(rep, "data"), JsonArray)
        Return If(t Is Nothing, New List(Of JsonNode), t.Where(Function(x) x IsNot Nothing).ToList())
    End Function

#End Region

    Private Shared Function MessageErreur(code As Integer, corps As String) As String
        Dim detail = corps
        Dim suivi = ""
        Try
            Dim j = JsonNode.Parse(corps)
            Dim msg = JsonChemin.Valeur(j, "message|error")
            Dim det = JsonChemin.Valeur(j, "detail")
            If msg <> "" Then detail = msg & If(det <> "" AndAlso det <> msg, " — " & det, "")
            Dim ref = JsonChemin.Valeur(j, "ref")
            If ref <> "" Then suivi = " [" & ref & "]"
        Catch
            ' Le corps n'est pas du JSON : on le garde tel quel.
        End Try

        If detail.Length > 600 Then detail = detail.Substring(0, 600) & "…"

        Select Case code
            Case 401 : Return "Clé d'API ou App ID refusé (401) : vérifiez-les dans le tableau de bord Apideck (Configuration ▸ API Keys)." & suivi
            Case 402 : Return "Apideck demande un forfait qui couvre cette opération (402). " & detail & suivi
            Case 404 : Return "Introuvable (404) : " & detail & " — la ressource n'existe pas pour ce connecteur, ou le consommateur n'a pas relié QuickBooks." & suivi
            Case Else : Return $"Erreur Apideck ({code}) : {detail}{suivi}"
        End Select
    End Function

End Class
