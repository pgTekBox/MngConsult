Imports System.Net.Http
Imports System.Net.Http.Headers

''' <summary>
''' A failure worth showing, in both languages: the English wording goes to
''' Dream, the French one to whoever is running the tool.
''' </summary>
Public Class DreamException
    Inherits Exception

    Public ReadOnly Property FrenchMessage As String
    Public ReadOnly Property HttpCode As Integer
    Public ReadOnly Property DreamCode As String

    Public Sub New(message As String, frenchMessage As String,
                   Optional httpCode As Integer = 0, Optional dreamCode As String = "")
        MyBase.New(message)
        Me.FrenchMessage = frenchMessage
        Me.HttpCode = httpCode
        Me.DreamCode = dreamCode
    End Sub
End Class

''' <summary>The connection settings, as the screen supplies them.</summary>
Public Class ConnectionSettings
    Public Property ClientId As String = ""
    Public Property ClientSecret As String = ""
    Public Property TokenUrl As String = ""
    Public Property ApiBase As String = ""
    Public Property BasePath As String = ""
    Public Property PayerHeaderName As String = ""
    Public Property PayerHeaderValue As String = ""
End Class

''' <summary>
''' The calls to Dream Payments.
'''
''' OAuth 2.0 client_credentials: the client ID and secret go out as Basic auth
''' to the token URL (AWS Cognito), which returns a token valid for about an
''' hour. Business calls then carry that token as a Bearer.
'''
''' Everything sent and everything received is written to the log — twice, once
''' in each language. What travels on the wire (URLs, JSON, Dream's own words) is
''' identical in both; only the narration around it is translated. The secret and
''' the token are never logged in clear.
''' </summary>
Public Class DreamClient

    Private Shared ReadOnly Http As New HttpClient() With {.Timeout = TimeSpan.FromMinutes(2)}

    Private ReadOnly _s As ConnectionSettings

    ''' <summary>Writes one line: first the English wording, then the French.</summary>
    Private ReadOnly _log As Action(Of String, String)

    Private _token As String = ""
    Private _tokenType As String = ""
    Private _expiresAt As DateTime = DateTime.MinValue

    Public Sub New(settings As ConnectionSettings, log As Action(Of String, String))
        _s = settings
        _log = log
    End Sub

    ''' <summary>Same text both sides — a wire dump reads the same in any language.</summary>
    Private Sub LogBoth(text As String)
        _log(text, text)
    End Sub

    Public ReadOnly Property TokenType As String
        Get
            Return _tokenType
        End Get
    End Property

    Public ReadOnly Property ExpiresAt As DateTime
        Get
            Return _expiresAt
        End Get
    End Property

    Public ReadOnly Property HasValidToken As Boolean
        Get
            Return _token <> "" AndAlso DateTime.UtcNow < _expiresAt.AddSeconds(-60)
        End Get
    End Property

    Public Sub ForgetToken()
        _token = ""
        _tokenType = ""
        _expiresAt = DateTime.MinValue
    End Sub

#Region "Token"

    ''' <summary>
    ''' POST {TokenUrl} — grant_type=client_credentials, client ID and secret as
    ''' Basic auth. Returns the token and notes when it expires.
    ''' </summary>
    Public Async Function GetTokenAsync(ct As CancellationToken) As Task(Of String)
        If _s.ClientId = "" OrElse _s.ClientSecret = "" Then
            Throw New DreamException(
                "Client ID and secret are required: these are the credentials issued by Dream.",
                "L'identifiant et le secret sont obligatoires : ce sont ceux fournis par Dream.")
        End If
        If _s.TokenUrl = "" Then
            Throw New DreamException("The token URL is empty.", "L'URL du jeton n'est pas renseignée.")
        End If

        Using req As New HttpRequestMessage(HttpMethod.Post, _s.TokenUrl)
            Dim pair = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(_s.ClientId & ":" & _s.ClientSecret))
            req.Headers.Authorization = New AuthenticationHeaderValue("Basic", pair)
            req.Headers.Accept.Add(New MediaTypeWithQualityHeaderValue("application/json"))

            Dim fields As New Dictionary(Of String, String) From {{"grant_type", "client_credentials"}}
            req.Content = New FormUrlEncodedContent(fields)

            _log("--> POST " & _s.TokenUrl & vbCrLf & "    grant_type=client_credentials (Basic: client ID + secret)",
                 "--> POST " & _s.TokenUrl & vbCrLf & "    grant_type=client_credentials (Basic : identifiant + secret)")

            Using rep = Await Http.SendAsync(req, ct)
                Dim body = Await rep.Content.ReadAsStringAsync(ct)
                LogBoth("<-- " & CInt(rep.StatusCode) & " " & rep.ReasonPhrase & vbCrLf & Truncate(MaskToken(body)))

                If Not rep.IsSuccessStatusCode Then Throw BuildError(CInt(rep.StatusCode), body, "the token", "le jeton")

                Dim j = JsonNode.Parse(body)
                _token = JsonPath.Value(j, "access_token")
                _tokenType = JsonPath.Value(j, "token_type")

                Dim seconds As Double = 3600
                Double.TryParse(JsonPath.Value(j, "expires_in"), Globalization.NumberStyles.Any,
                                Globalization.CultureInfo.InvariantCulture, seconds)
                _expiresAt = DateTime.UtcNow.AddSeconds(seconds)

                If _token = "" Then
                    Throw New DreamException("Response contained no access_token.", "Réponse sans access_token.")
                End If
                Return _token
            End Using
        End Using
    End Function

#End Region

#Region "Business calls"

    Public Function GetAsync(path As String, ct As CancellationToken) As Task(Of JsonNode)
        Return SendAsync(HttpMethod.Get, path, "", ct)
    End Function

    Public Function PostAsync(path As String, body As JsonNode, ct As CancellationToken) As Task(Of JsonNode)
        Return SendAsync(HttpMethod.Post, path, ToJson(body), ct)
    End Function

    ''' <summary>
    ''' Readable JSON, as it will appear in the log — and as it goes out.
    '''
    ''' The relaxed encoder leaves accents and apostrophes alone instead of
    ''' escaping them to é and '. Two reasons: the log stays readable,
    ''' and above all the ERP sends raw UTF-8 (Newtonsoft), so the POC must send
    ''' the same thing or it proves nothing.
    ''' </summary>
    Public Shared Function ToJson(node As JsonNode) As String
        If node Is Nothing Then Return ""
        Return node.ToJsonString(New System.Text.Json.JsonSerializerOptions With {
            .WriteIndented = True,
            .Encoder = Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping})
    End Function

    ''' <summary>
    ''' One API call, token included. <paramref name="path"/> is relative to the
    ''' API base ("/payees/add"); the configured base path goes in between.
    ''' </summary>
    Public Async Function SendAsync(method As HttpMethod, path As String, jsonBody As String,
                                    ct As CancellationToken) As Task(Of JsonNode)
        If Not HasValidToken Then Await GetTokenAsync(ct)

        Dim url = _s.ApiBase.TrimEnd("/"c) & _s.BasePath.TrimEnd("/"c) & path

        Using req As New HttpRequestMessage(method, url)
            req.Headers.Authorization = New AuthenticationHeaderValue("Bearer", _token)
            req.Headers.Accept.Add(New MediaTypeWithQualityHeaderValue("application/json"))

            ' The hook laid down for the "Multiple payers exist" blocker: as soon
            ' as Dream tells us which header identifies the payer, it is set here.
            Dim headerLine = ""
            If _s.PayerHeaderName <> "" AndAlso _s.PayerHeaderValue <> "" Then
                req.Headers.TryAddWithoutValidation(_s.PayerHeaderName, _s.PayerHeaderValue)
                headerLine = vbCrLf & "    " & _s.PayerHeaderName & ": " & _s.PayerHeaderValue
            End If

            If jsonBody <> "" Then
                req.Content = New StringContent(jsonBody, System.Text.Encoding.UTF8, "application/json")
            End If

            LogBoth("--> " & method.Method & " " & url & headerLine & If(jsonBody = "", "", vbCrLf & jsonBody))

            Using rep = Await Http.SendAsync(req, ct)
                Dim body = Await rep.Content.ReadAsStringAsync(ct)
                Dim head = "<-- " & CInt(rep.StatusCode) & " " & rep.ReasonPhrase
                If body = "" Then
                    _log(head & " (no content)", head & " (aucun contenu)")
                Else
                    LogBoth(head & vbCrLf & Truncate(body))
                End If

                If Not rep.IsSuccessStatusCode Then Throw BuildError(CInt(rep.StatusCode), body, path, path)
                If String.IsNullOrWhiteSpace(body) Then Return Nothing

                Try
                    Return JsonNode.Parse(body)
                Catch
                    Return Nothing
                End Try
            End Using
        End Using
    End Function

#End Region

#Region "Errors"

    ''' <summary>
    ''' Dream returns its errors as { errorCode, errorMessage }. The codes met so
    ''' far are explained here, with what to do about them — that is what is
    ''' missing most when trying the API blind. Both languages, since the English
    ''' log is the one that goes to Dream.
    ''' </summary>
    Private Shared Function BuildError(httpCode As Integer, body As String,
                                       context As String, contexteFr As String) As DreamException
        Dim code = ""
        Dim message = ""
        Try
            Dim j = JsonNode.Parse(body)
            code = JsonPath.Value(j, "errorCode|error")
            message = JsonPath.Value(j, "errorMessage|error_description|message")
        Catch
            ' Not a JSON response: keep the body as it came.
        End Try

        Dim detail = If(message <> "", message, Truncate(body))
        Dim hint = ""
        Dim aide = ""

        Select Case code
            Case "G00021"
                hint = " -- The credentials are tied to several payers and Dream cannot tell which one to use. " &
                       "Ask Dream either to scope the credentials to a single payer, or for the name of the header " &
                       "(or field) that designates the payer, then fill in ""Payer header"" or ""legalEntityLabel"" " &
                       "on the Connection tab."
                aide = " — Les identifiants portent plusieurs payeurs et Dream ne sait pas lequel utiliser. " &
                       "Demandez à Dream soit de restreindre les identifiants à un seul payeur, soit le nom de " &
                       "l'en-tête (ou du champ) qui désigne le payeur, puis renseignez « Payer header » ou " &
                       "« legalEntityLabel » dans l'onglet Connection."
            Case "G00001"
                hint = " -- A required field is missing or malformed: compare the body sent above with the docs."
                aide = " — Un champ obligatoire est absent ou mal formé : comparez le corps envoyé, ci-dessus, avec la doc."
            Case "G00002"
                hint = " -- Dream's own server failed on a request it had accepted: the route exists and the token " &
                       "is valid, since other endpoints answer normally. Nothing to change on this side; send Dream " &
                       "this log, with the timestamp, so they can look it up on their end."
                aide = " — Le serveur de Dream a échoué sur une requête qu'il avait acceptée : la route existe et le " &
                       "jeton est valide, puisque les autres appels répondent normalement. Rien à changer de notre " &
                       "côté ; envoyez ce journal à Dream, avec l'heure, pour qu'ils le retrouvent."
            Case "BA0002"
                hint = " -- The identifier does not exist. Expected when probing with a made-up id; it also proves " &
                       "the route is live and the token accepted."
                aide = " — L'identifiant n'existe pas. Normal quand on sonde avec un identifiant inventé ; cela " &
                       "prouve au passage que la route est vivante et le jeton accepté."
        End Select

        ' The HTTP-level hints only apply when Dream sent no error code of its
        ' own. A 404 carrying BA0002 is a real answer, not a wrong path.
        If hint = "" AndAlso code = "" Then
            If httpCode = 503 OrElse httpCode = 502 Then
                hint = " -- The gateway answers but the InsureTech service behind it is down. " &
                       "This is not about the request: try ""/"" on the Raw request tab; if that returns a JSON 404 " &
                       "while the real routes stay 503, the Dream environment is down and should be reported."
                aide = " — La passerelle répond mais le service InsureTech derrière est arrêté. Ce n'est pas la " &
                       "requête : essayez « / » dans l'onglet Raw request ; s'il rend un 404 JSON alors que les " &
                       "vraies routes restent en 503, l'environnement de Dream est en panne, à signaler."
            ElseIf httpCode = 404 Then
                hint = " -- Unknown path: check the API base and the base path (the ""/platform"" prefix from the " &
                       "docs returns 404 on the insuretechv2 environment, which wants an empty base path)."
                aide = " — Chemin inconnu : vérifiez la base de l'API et le chemin de base (le « /platform » de la " &
                       "doc donne un 404 sur l'environnement insuretechv2, qui veut un chemin de base vide)."
            ElseIf httpCode = 401 OrElse httpCode = 403 Then
                hint = " -- Token refused: get a new token, and check that the client ID matches this environment."
                aide = " — Jeton refusé : reprenez un jeton, et vérifiez que l'identifiant va avec cet environnement."
            End If
        End If

        Dim head = If(code <> "", "Dream " & code, "HTTP error " & httpCode)
        Dim tete = If(code <> "", "Dream " & code, "Erreur HTTP " & httpCode)

        Return New DreamException(head & " on " & context & ": " & detail & hint,
                                  tete & " sur " & contexteFr & " : " & detail & aide,
                                  httpCode, code)
    End Function

    Private Shared Function Truncate(text As String) As String
        If text Is Nothing Then Return ""
        If text.Length <= 4000 Then Return text
        Return text.Substring(0, 4000) & "... (truncated)"
    End Function

    ''' <summary>Hides the token in the logged text: it is as good as a secret.</summary>
    Private Shared Function MaskToken(body As String) As String
        Return Text.RegularExpressions.Regex.Replace(If(body, ""),
            """access_token""\s*:\s*""[^""]+""",
            """access_token"": ""... masked ...""")
    End Function

#End Region

End Class
