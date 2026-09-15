Imports System.Net.Http
Imports System.Net.Http.Headers

''' <summary>
''' Les appels à l'API comptable de QuickBooks Online : requêtes paginées sur
''' les entités, et rapports.
'''
''' Le jeton d'accès est renouvelé de lui-même quand il expire ; chaque
''' renouvellement est signalé par <see cref="JetonRenouvele"/>, car Intuit
''' remplace alors le jeton de renouvellement et l'ancien ne vaut plus rien.
''' Les refus pour cadence (429) et les erreurs passagères (5xx) sont rejoués.
''' </summary>
Public Class QboClient

    ''' <summary>Version mineure de l'API : Intuit exige 75 ou plus.</summary>
    Public Const VersionMineure As String = "75"

    Private Const TaillePage As Integer = 1000

    Private Shared ReadOnly Http As New HttpClient() With {.Timeout = TimeSpan.FromMinutes(3)}

    Private ReadOnly _clientId As String
    Private ReadOnly _secret As String
    Private ReadOnly _base As String
    Private _jeton As JetonQbo

    Public ReadOnly Property RealmId As String

    Public Event JetonRenouvele(jeton As JetonQbo)

    Public Sub New(clientId As String, clientSecret As String, realmId As String, sandbox As Boolean, jeton As JetonQbo)
        _clientId = clientId
        _secret = clientSecret
        Me.RealmId = realmId
        _jeton = jeton
        _base = If(sandbox, "https://sandbox-quickbooks.api.intuit.com", "https://quickbooks.api.intuit.com")
    End Sub

    Private Async Function AssurerJetonAsync(forcer As Boolean, ct As CancellationToken) As Task
        If Not forcer AndAlso _jeton.Valide Then Return
        If String.IsNullOrEmpty(_jeton.RefreshToken) Then
            Throw New QboException("Aucun jeton : connectez-vous d'abord à QuickBooks.")
        End If

        _jeton = Await QboAuth.RenouvelerAsync(_clientId, _secret, _jeton.RefreshToken, ct)
        RaiseEvent JetonRenouvele(_jeton)
    End Function

    ''' <summary>Un GET sur l'API, chemin relatif à la racine (/v3/company/...).</summary>
    Public Async Function GetAsync(chemin As String, ct As CancellationToken) As Task(Of JsonNode)
        Dim url = _base & chemin & If(chemin.Contains("?"c), "&", "?") & "minorversion=" & VersionMineure
        Dim dejaRenouvele = False
        Const Essais As Integer = 6

        For essai = 1 To Essais
            Await AssurerJetonAsync(False, ct)

            Using req As New HttpRequestMessage(HttpMethod.Get, url)
                req.Headers.Authorization = New AuthenticationHeaderValue("Bearer", _jeton.AccessToken)
                req.Headers.Accept.Add(New MediaTypeWithQualityHeaderValue("application/json"))

                Using rep = Await Http.SendAsync(req, ct)
                    Dim corps = Await rep.Content.ReadAsStringAsync(ct)
                    If rep.IsSuccessStatusCode Then Return JsonNode.Parse(corps)

                    Dim code = CInt(rep.StatusCode)

                    If code = 401 AndAlso Not dejaRenouvele Then
                        dejaRenouvele = True
                        Await AssurerJetonAsync(True, ct)
                        Continue For
                    End If

                    If (code = 429 OrElse code >= 500) AndAlso essai < Essais Then
                        Dim delai = If(rep.Headers.RetryAfter?.Delta, TimeSpan.FromSeconds(Math.Pow(2, essai)))
                        Await Task.Delay(delai, ct)
                        Continue For
                    End If

                    Throw New QboException(MessageErreur(code, corps, rep), code)
                End Using
            End Using
        Next

        Throw New QboException("QuickBooks ne répond pas après plusieurs essais.")
    End Function

    ''' <summary>
    ''' Toutes les occurrences d'une entité, page par page (1000 par page, le
    ''' maximum permis). <paramref name="condition"/> est la clause WHERE, sans
    ''' le mot WHERE.
    ''' </summary>
    Public Async Function RequeteToutAsync(entite As String, condition As String,
                                           progres As Action(Of Integer), ct As CancellationToken) As Task(Of List(Of JsonNode))
        Dim tout As New List(Of JsonNode)
        Dim debut = 1

        Do
            Dim requete = "select * from " & entite &
                          If(String.IsNullOrEmpty(condition), "", " where " & condition) &
                          $" STARTPOSITION {debut} MAXRESULTS {TaillePage}"

            Dim rep = Await GetAsync($"/v3/company/{RealmId}/query?query={Uri.EscapeDataString(requete)}", ct)
            Dim lot = TryCast(JsonChemin.Enfant(JsonChemin.Enfant(rep, "QueryResponse"), entite), JsonArray)
            If lot Is Nothing OrElse lot.Count = 0 Then Exit Do

            tout.AddRange(lot)
            progres?.Invoke(tout.Count)

            If lot.Count < TaillePage Then Exit Do
            debut += TaillePage
        Loop

        Return tout
    End Function

    Public Function RapportAsync(nom As String, parametres As Dictionary(Of String, String), ct As CancellationToken) As Task(Of JsonNode)
        Dim qs = String.Join("&", parametres.Select(Function(kv) Uri.EscapeDataString(kv.Key) & "=" & Uri.EscapeDataString(kv.Value)))
        Return GetAsync($"/v3/company/{RealmId}/reports/{nom}" & If(qs = "", "", "?" & qs), ct)
    End Function

    Private Shared Function MessageErreur(code As Integer, corps As String, rep As HttpResponseMessage) As String
        Dim detail = corps
        Try
            Dim j = JsonNode.Parse(corps)
            Dim err = JsonChemin.Enfant(JsonChemin.Enfant(j, "Fault"), "Error")
            Dim msg = JsonChemin.Valeur(err, "Message")
            Dim det = JsonChemin.Valeur(err, "Detail")
            If msg <> "" Then detail = msg & If(det <> "" AndAlso det <> msg, " — " & det, "")
        Catch
            ' Le corps n'est pas du JSON (page HTML d'erreur, etc.) : on le garde tel quel.
        End Try

        If detail.Length > 600 Then detail = detail.Substring(0, 600) & "…"

        Dim tid As IEnumerable(Of String) = Nothing
        Dim suivi = If(rep.Headers.TryGetValues("intuit_tid", tid), " [intuit_tid " & tid.First() & "]", "")

        Select Case code
            Case 401 : Return "Accès refusé (401) : le jeton n'est plus valide. Reconnectez-vous à QuickBooks." & suivi
            Case 403 : Return "Accès interdit (403) : l'application n'a pas les droits sur cette société, ou l'abonnement ne comprend pas cette fonction. " & detail & suivi
            Case Else : Return $"Erreur QuickBooks ({code}) : {detail}{suivi}"
        End Select
    End Function

End Class
