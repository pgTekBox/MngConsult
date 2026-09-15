Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Text

Public Class CodatException
    Inherits Exception

    Public ReadOnly Property CodeHttp As Integer

    Public Sub New(message As String, Optional codeHttp As Integer = 0)
        MyBase.New(message)
        Me.CodeHttp = codeHttp
    End Sub
End Class

''' <summary>
''' Les appels à Codat (https://api.codat.io).
'''
''' Codat se place entre l'application et QuickBooks Online : la société relie
''' une fois son QuickBooks à Codat par un lien, Codat en synchronise les
''' données, et l'application lit ces données chez Codat avec une simple clé
''' d'API. L'OAuth avec Intuit est fait par Codat, avec l'application Intuit
''' dont les clés ont été données dans le portail Codat.
'''
''' Ce qu'on lit est la dernière synchronisation, pas QuickBooks en direct :
''' <see cref="SynchroniserToutAsync"/> en demande une nouvelle.
''' </summary>
Public Class CodatClient

    Private Const Base As String = "https://api.codat.io"
    Private Const TaillePage As Integer = 5000

    Private Shared ReadOnly Http As New HttpClient() With {.Timeout = TimeSpan.FromMinutes(3)}

    Private ReadOnly _autorisation As String

    ''' <param name="cleApi">
    ''' La clé d'API telle que le portail Codat la montre, ou l'en-tête déjà
    ''' encodé (« Basic … ») qu'il propose aussi.
    ''' </param>
    Public Sub New(cleApi As String)
        Dim c = cleApi.Trim()
        If c.StartsWith("Basic ", StringComparison.OrdinalIgnoreCase) Then
            _autorisation = c.Substring(6).Trim()
        Else
            _autorisation = Convert.ToBase64String(Encoding.UTF8.GetBytes(c))
        End If
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
                req.Headers.Authorization = New AuthenticationHeaderValue("Basic", _autorisation)
                req.Headers.Accept.Add(New MediaTypeWithQualityHeaderValue("application/json"))
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

                    Throw New CodatException(MessageErreur(code, corps), code)
                End Using
            End Using
        Next

        Throw New CodatException("Codat ne répond pas après plusieurs essais.")
    End Function

    ''' <summary>
    ''' Toutes les pages d'une liste (5000 par page, le maximum de Codat).
    ''' <paramref name="requete"/> est une requête Codat (« issueDate>=2026-01-01 »), ou vide.
    ''' </summary>
    Public Async Function ListeToutAsync(chemin As String, requete As String,
                                         progres As Action(Of Integer), ct As CancellationToken) As Task(Of List(Of JsonNode))
        Dim tout As New List(Of JsonNode)
        Dim page = 1

        Do
            Dim url = chemin & $"?page={page}&pageSize={TaillePage}" &
                      If(String.IsNullOrEmpty(requete), "", "&query=" & Uri.EscapeDataString(requete))
            Dim rep = Await GetAsync(url, ct)

            Dim lot = TryCast(JsonChemin.Enfant(rep, "results"), JsonArray)
            If lot Is Nothing OrElse lot.Count = 0 Then Exit Do

            tout.AddRange(lot)
            progres?.Invoke(tout.Count)

            Dim total As Integer
            If Integer.TryParse(JsonChemin.Valeur(rep, "totalResults"), total) AndAlso tout.Count >= total Then Exit Do
            If lot.Count < TaillePage Then Exit Do
            page += 1
        Loop

        Return tout
    End Function

#End Region

#Region "Sociétés et connexions (Platform API)"

    ''' <summary>
    ''' Crée une société chez Codat. La réponse porte son identifiant (id) et le
    ''' lien (redirect) à ouvrir pour relier QuickBooks Online.
    ''' </summary>
    Public Function CreerSocieteAsync(nom As String, ct As CancellationToken) As Task(Of JsonNode)
        Dim corps As New JsonObject From {{"name", nom}, {"description", "Reprise des données vers MngConsul"}}
        Return PostAsync("/companies", corps.ToJsonString(), ct)
    End Function

    Public Function SocieteAsync(companyId As String, ct As CancellationToken) As Task(Of JsonNode)
        Return GetAsync("/companies/" & Uri.EscapeDataString(companyId), ct)
    End Function

    Public Function ConnexionsAsync(companyId As String, ct As CancellationToken) As Task(Of List(Of JsonNode))
        Return ListeToutAsync("/companies/" & Uri.EscapeDataString(companyId) & "/connections", "", Nothing, ct)
    End Function

    ''' <summary>Demande à Codat de resynchroniser tous les types de données de la société.</summary>
    Public Function SynchroniserToutAsync(companyId As String, ct As CancellationToken) As Task(Of JsonNode)
        Return PostAsync("/companies/" & Uri.EscapeDataString(companyId) & "/data/all", Nothing, ct)
    End Function

    ''' <summary>La dernière synchronisation réussie et l'état courant de chaque type de données.</summary>
    Public Function EtatDonneesAsync(companyId As String, ct As CancellationToken) As Task(Of JsonNode)
        Return GetAsync("/companies/" & Uri.EscapeDataString(companyId) & "/dataStatus", ct)
    End Function

#End Region

    Private Shared Function MessageErreur(code As Integer, corps As String) As String
        Dim detail = corps
        Dim suivi = ""
        Try
            Dim j = JsonNode.Parse(corps)
            Dim msg = JsonChemin.Valeur(j, "error|message|title")
            If msg <> "" Then detail = msg
            Dim cid = JsonChemin.Valeur(j, "correlationId")
            If cid <> "" Then suivi = " [correlationId " & cid & "]"
        Catch
            ' Le corps n'est pas du JSON : on le garde tel quel.
        End Try

        If detail.Length > 600 Then detail = detail.Substring(0, 600) & "…"

        Select Case code
            Case 401 : Return "Clé d'API refusée (401) : vérifiez la clé copiée depuis le portail Codat (Settings ▸ API keys)." & suivi
            Case 402 : Return "Codat demande un abonnement ou un produit actif pour cette opération (402). " & detail & suivi
            Case 403 : Return "Accès interdit (403) : " & detail & suivi
            Case 404 : Return "Introuvable (404) : " & detail & " — la société, la connexion ou le type de données n'existe pas, ou n'est pas activé dans le portail Codat." & suivi
            Case Else : Return $"Erreur Codat ({code}) : {detail}{suivi}"
        End Select
    End Function

End Class
