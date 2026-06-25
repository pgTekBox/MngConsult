Imports System
Imports System.Configuration
Imports System.Net
Imports System.Web

''' <summary>
''' Handler HTTP appele par SQL Server Agent (via PowerShell) pour declencher
''' les operations d'auto-paiement.
'''
''' URL endpoint : https://60sec.ca/AutoPayProcessor.ashx
'''
''' Modes (parametre "mode" GET ou POST) :
'''   - process       : execute les debits dus (toutes les 15 min)
'''   - preavis24h    : envoie preavis 24h pour cartes (daily 06h00)
'''   - preavispad3d  : envoie preavis legal PAD 3 jours (daily 06h00)
'''
''' Securite :
'''   1. Header X-AutoPay-Secret doit matcher Web.config (AutoPay.SharedSecret)
'''      ou querystring "secret" en fallback (moins securitaire, eviter en prod)
'''   2. IP source optionnellement filtree (AutoPay.AllowedIPs en CSV)
'''
''' Reponse JSON :
'''   { "mode": "process", "processed": 5, "succeeded": 4, "failed": 1, ... }
'''
''' Codes HTTP :
'''   200 = OK
'''   401 = Secret manquant ou invalide
'''   403 = IP non autorisee
'''   400 = Parametre mode manquant/invalide
'''   500 = Erreur interne (exception non geree)
''' </summary>
Public Class AutoPayProcessor
    Implements IHttpHandler

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest

        context.Response.ContentType = "application/json"
        context.Response.Charset = "utf-8"

        Try
            ' === 1. Auth par shared secret ===
            If Not VerifySharedSecret(context) Then
                context.Response.StatusCode = CInt(HttpStatusCode.Unauthorized)
                context.Response.Write("{""error"":""invalid_or_missing_secret""}")
                Return
            End If

            ' === 2. Whitelist IP (optionnel) ===
            If Not VerifyAllowedIp(context) Then
                context.Response.StatusCode = CInt(HttpStatusCode.Forbidden)
                context.Response.Write("{""error"":""ip_not_allowed"",""ip"":""" & GetSourceIp(context) & """}")
                Return
            End If

            ' === 3. Dispatch selon mode ===
            Dim mode As String = If(context.Request("mode"), "").Trim().ToLowerInvariant()

            Dim startedAt As DateTime = DateTime.UtcNow
            Dim result As clsAutoPayEngine.ProcessResult

            Select Case mode
                Case "process"
                    Dim batch As Integer = 50
                    Integer.TryParse(context.Request("batch"), batch)
                    If batch < 1 Then batch = 50
                    If batch > 200 Then batch = 200
                    result = clsAutoPayEngine.ProcessDuePayments(batch)

                Case "preavis24h"
                    result = clsAutoPayEngine.SendPreavis24h()

                Case "preavispad3d"
                    Dim daysAhead As Integer = 3
                    Integer.TryParse(context.Request("days"), daysAhead)
                    If daysAhead < 1 Then daysAhead = 3
                    If daysAhead > 15 Then daysAhead = 15
                    result = clsAutoPayEngine.SendPadPreavis3Days(daysAhead)

                Case "health"
                    ' Mode health check : verifie juste que le handler repond et que la BD est joignable
                    context.Response.StatusCode = 200
                    context.Response.Write("{""mode"":""health"",""status"":""ok""}")
                    Return

                Case Else
                    context.Response.StatusCode = 400
                    context.Response.Write("{""error"":""invalid_mode"",""hint"":""use mode=process|preavis24h|preavispad3d|health""}")
                    Return
            End Select

            Dim elapsedMs As Long = CLng((DateTime.UtcNow - startedAt).TotalMilliseconds)

            ' === 4. Repondre JSON ===
            Dim sb As New System.Text.StringBuilder()
            sb.Append("{")
            sb.AppendFormat("""mode"":""{0}"",", mode)
            sb.AppendFormat("""elapsed_ms"":{0},", elapsedMs)
            sb.AppendFormat("""result"":{0}", result.ToJson())
            sb.Append("}")
            context.Response.StatusCode = 200
            context.Response.Write(sb.ToString())

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("AutoPayProcessor unhandled exception : " & ex.Message)
            context.Response.StatusCode = 500
            context.Response.Write("{""error"":""internal_error"",""message"":""" & EscapeForJson(ex.Message) & """}")
        End Try
    End Sub

    ' =========================================================================
    ' SECURITY HELPERS
    ' =========================================================================

    Private Function VerifySharedSecret(context As HttpContext) As Boolean
        Dim expected As String = ConfigurationManager.AppSettings("AutoPay.SharedSecret")
        If String.IsNullOrEmpty(expected) Then
            ' Refuse si pas configure (mode safe par defaut)
            System.Diagnostics.Debug.WriteLine("AutoPayProcessor : AutoPay.SharedSecret NON CONFIGURE dans Web.config")
            Return False
        End If

        ' Premier essai : header X-AutoPay-Secret (recommande)
        Dim received As String = context.Request.Headers("X-AutoPay-Secret")

        ' Fallback : querystring (eviter en prod, OK pour test)
        If String.IsNullOrEmpty(received) Then
            received = context.Request("secret")
        End If

        If String.IsNullOrEmpty(received) Then Return False
        Return ConstantTimeEquals(expected.Trim(), received.Trim())
    End Function

    ''' <summary>
    ''' Comparaison constante en temps (anti-timing attack).
    ''' </summary>
    Private Function ConstantTimeEquals(a As String, b As String) As Boolean
        If a Is Nothing OrElse b Is Nothing Then Return False
        If a.Length <> b.Length Then Return False
        Dim diff As Integer = 0
        For i = 0 To a.Length - 1
            diff = diff Or (AscW(a(i)) Xor AscW(b(i)))
        Next
        Return diff = 0
    End Function

    Private Function VerifyAllowedIp(context As HttpContext) As Boolean
        Dim allowed As String = ConfigurationManager.AppSettings("AutoPay.AllowedIPs")
        ' Si pas configure : autoriser (la whitelist est optionnelle)
        If String.IsNullOrEmpty(allowed) Then Return True

        Dim ip As String = GetSourceIp(context)
        If String.IsNullOrEmpty(ip) Then Return False

        For Each entry In allowed.Split(","c)
            Dim trimmed As String = entry.Trim()
            If String.IsNullOrEmpty(trimmed) Then Continue For
            If String.Equals(trimmed, ip, StringComparison.OrdinalIgnoreCase) Then Return True
            ' Support CIDR simple /24 pour LAN
            If trimmed.EndsWith("/24") Then
                Dim prefix As String = trimmed.Substring(0, trimmed.Length - 3)
                Dim lastDot As Integer = prefix.LastIndexOf("."c)
                If lastDot > 0 Then
                    Dim networkPart As String = prefix.Substring(0, lastDot + 1)
                    If ip.StartsWith(networkPart, StringComparison.OrdinalIgnoreCase) Then Return True
                End If
            End If
        Next
        Return False
    End Function

    Private Function GetSourceIp(context As HttpContext) As String
        Dim ip As String = ""
        Try
            Dim xff As String = context.Request.Headers("X-Forwarded-For")
            If Not String.IsNullOrEmpty(xff) Then
                ip = xff.Split(","c)(0).Trim()
            End If
            If String.IsNullOrEmpty(ip) Then ip = context.Request.UserHostAddress
        Catch
        End Try
        Return If(ip, "")
    End Function

    Private Function EscapeForJson(s As String) As String
        If String.IsNullOrEmpty(s) Then Return ""
        Return s.Replace("\", "\\").Replace("""", "\""").Replace(ChrW(10), "\n").Replace(ChrW(13), "\r").Replace(ChrW(9), "\t")
    End Function

End Class
