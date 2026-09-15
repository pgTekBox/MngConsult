Imports System.Globalization
Imports System.Net
Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Text

''' <summary>Un jeton d'accès QuickBooks et ce qu'il faut pour le renouveler.</summary>
Public Class JetonQbo
    Public Property AccessToken As String = ""
    Public Property RefreshToken As String = ""
    Public Property ExpireLe As DateTime = DateTime.MinValue

    Public ReadOnly Property Valide As Boolean
        Get
            Return AccessToken <> "" AndAlso DateTime.UtcNow < ExpireLe.AddMinutes(-2)
        End Get
    End Property
End Class

Public Class ResultatConnexion
    Public Property Jeton As JetonQbo
    Public Property RealmId As String
End Class

Public Class QboException
    Inherits Exception

    Public ReadOnly Property CodeHttp As Integer

    Public Sub New(message As String, Optional codeHttp As Integer = 0)
        MyBase.New(message)
        Me.CodeHttp = codeHttp
    End Sub
End Class

''' <summary>
''' OAuth 2.0 d'Intuit, en flux « code d'autorisation ».
'''
''' L'application ouvre la page de consentement d'Intuit dans le navigateur et
''' écoute elle-même sur l'URI de redirection (localhost) : Intuit y renvoie le
''' code et l'identifiant de la société (realmId), que l'application échange
''' contre un jeton. Le jeton d'accès vit une heure ; le jeton de
''' renouvellement, cent jours, et Intuit en rend un nouveau à chaque usage.
''' </summary>
Public NotInheritable Class QboAuth

    Private Const UrlAutorisation As String = "https://appcenter.intuit.com/connect/oauth2"
    Private Const UrlJeton As String = "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
    Private Const Portee As String = "com.intuit.quickbooks.accounting"

    Private Shared ReadOnly Http As New HttpClient() With {.Timeout = TimeSpan.FromSeconds(60)}

    Private Sub New()
    End Sub

    Public Shared Async Function ConnecterAsync(clientId As String, clientSecret As String, redirectUri As String,
                                                ct As CancellationToken) As Task(Of ResultatConnexion)
        Dim adresse As New Uri(redirectUri)
        If Not adresse.IsLoopback Then
            Throw New QboException("L'URI de redirection doit pointer vers localhost (par exemple http://localhost:8765/callback) : " &
                                   "c'est cette application qui reçoit la réponse de QuickBooks.")
        End If

        Dim etat = Guid.NewGuid().ToString("N")
        Dim url = UrlAutorisation &
                  "?client_id=" & Uri.EscapeDataString(clientId) &
                  "&response_type=code" &
                  "&scope=" & Uri.EscapeDataString(Portee) &
                  "&redirect_uri=" & Uri.EscapeDataString(redirectUri) &
                  "&state=" & etat

        Using ecoute As New HttpListener()
            ecoute.Prefixes.Add($"{adresse.Scheme}://{adresse.Host}:{adresse.Port}/")
            ecoute.Start()

            Process.Start(New ProcessStartInfo(url) With {.UseShellExecute = True})

            Dim limite = DateTime.UtcNow.AddMinutes(5)
            Do
                Dim reste = limite - DateTime.UtcNow
                If reste <= TimeSpan.Zero Then Throw New TimeoutException("Aucune réponse de QuickBooks après 5 minutes.")

                Dim attente = ecoute.GetContextAsync()
                Dim premier = Await Task.WhenAny(attente, Task.Delay(reste, ct))
                If premier IsNot attente Then
                    ct.ThrowIfCancellationRequested()
                    Throw New TimeoutException("Aucune réponse de QuickBooks après 5 minutes.")
                End If

                Dim ctx = Await attente
                Dim q = ctx.Request.QueryString
                Dim code = q("code"), erreur = q("error")

                ' Le navigateur demande aussi l'icône du site : ce n'est pas la réponse attendue.
                If String.IsNullOrEmpty(code) AndAlso String.IsNullOrEmpty(erreur) Then
                    ctx.Response.StatusCode = 404
                    ctx.Response.Close()
                    Continue Do
                End If

                If Not String.IsNullOrEmpty(erreur) Then
                    Repondre(ctx, "Connexion refusée", "QuickBooks a refusé l'autorisation : " & WebUtility.HtmlEncode(erreur))
                    Throw New QboException("QuickBooks a refusé l'autorisation : " & erreur)
                End If

                If q("state") <> etat Then
                    Repondre(ctx, "Connexion abandonnée", "La réponse ne correspond pas à la demande.")
                    Throw New QboException("La réponse de QuickBooks ne correspond pas à la demande (state) : connexion abandonnée par sécurité.")
                End If

                Repondre(ctx, "Connexion réussie", "Vous pouvez fermer cette fenêtre et revenir à l'application d'extraction.")

                Dim jeton = Await EchangerCodeAsync(clientId, clientSecret, code, redirectUri, ct)
                Return New ResultatConnexion With {.Jeton = jeton, .RealmId = q("realmId")}
            Loop
        End Using
    End Function

    Public Shared Function EchangerCodeAsync(clientId As String, clientSecret As String, code As String,
                                             redirectUri As String, ct As CancellationToken) As Task(Of JetonQbo)
        Return DemanderJetonAsync(clientId, clientSecret, New Dictionary(Of String, String) From {
            {"grant_type", "authorization_code"}, {"code", code}, {"redirect_uri", redirectUri}}, ct)
    End Function

    Public Shared Function RenouvelerAsync(clientId As String, clientSecret As String, refreshToken As String,
                                           ct As CancellationToken) As Task(Of JetonQbo)
        Return DemanderJetonAsync(clientId, clientSecret, New Dictionary(Of String, String) From {
            {"grant_type", "refresh_token"}, {"refresh_token", refreshToken}}, ct)
    End Function

    Private Shared Async Function DemanderJetonAsync(clientId As String, clientSecret As String,
                                                     champs As Dictionary(Of String, String),
                                                     ct As CancellationToken) As Task(Of JetonQbo)
        Using req As New HttpRequestMessage(HttpMethod.Post, UrlJeton)
            req.Headers.Authorization = New AuthenticationHeaderValue("Basic",
                Convert.ToBase64String(Encoding.UTF8.GetBytes(clientId & ":" & clientSecret)))
            req.Headers.Accept.Add(New MediaTypeWithQualityHeaderValue("application/json"))
            req.Content = New FormUrlEncodedContent(champs)

            Using rep = Await Http.SendAsync(req, ct)
                Dim corps = Await rep.Content.ReadAsStringAsync(ct)
                If Not rep.IsSuccessStatusCode Then
                    Dim detail = corps
                    If corps.Contains("invalid_grant") Then
                        detail = "le jeton de renouvellement est expiré ou déjà utilisé. Reconnectez-vous à QuickBooks."
                    ElseIf corps.Contains("invalid_client") Then
                        detail = "Client ID ou Client Secret incorrect, ou pas celui de cet environnement (Sandbox / Production)."
                    End If
                    Throw New QboException($"QuickBooks a refusé le jeton ({CInt(rep.StatusCode)}) : {detail}", CInt(rep.StatusCode))
                End If

                Dim j = JsonNode.Parse(corps)
                Dim secondes As Double = 3600
                Double.TryParse(JsonChemin.Valeur(j, "expires_in"), NumberStyles.Any, CultureInfo.InvariantCulture, secondes)

                Return New JetonQbo With {
                    .AccessToken = JsonChemin.Valeur(j, "access_token"),
                    .RefreshToken = JsonChemin.Valeur(j, "refresh_token"),
                    .ExpireLe = DateTime.UtcNow.AddSeconds(secondes)
                }
            End Using
        End Using
    End Function

    Private Shared Sub Repondre(ctx As HttpListenerContext, titre As String, message As String)
        Dim html = "<!doctype html><html><head><meta charset='utf-8'><title>" & titre & "</title></head>" &
                   "<body style='font-family:Segoe UI,sans-serif;padding:40px'><h2>" & titre & "</h2><p>" & message & "</p></body></html>"
        Dim octets = Encoding.UTF8.GetBytes(html)
        ctx.Response.ContentType = "text/html; charset=utf-8"
        ctx.Response.ContentLength64 = octets.Length
        ctx.Response.OutputStream.Write(octets, 0, octets.Length)
        ctx.Response.Close()
    End Sub

End Class
