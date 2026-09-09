Imports System.IO
Imports System.Net
Imports System.Text
Imports Newtonsoft.Json.Linq

''' <summary>Ce que la console d'administration a repondu.</summary>
Public Class AdminJobResult
    Public Property Succes As Boolean
    Public Property Message As String = ""
    Public Property Detail As String = Nothing
    Public Property LignesTraitees As Integer? = Nothing
End Class

''' <summary>
''' Le seul lien entre le service et ce que font vraiment les taches.
'''
''' Le service ne sait rien d'aucune tache : il repere ce qui est du, le
''' reserve, et passe la main a JobRunner.ashx dans la console
''' d'administration. Les particularites de chaque tache vivent la-bas, dans
''' clsJobRunner. Changer une tache ne demande donc que de redeployer
''' l'application web ; ce service, lui, ne rebouge pas.
'''
''' Le service reste maitre du cycle de vie : c'est lui qui pose le verrou,
''' enregistre le statut, journalise et decide des reprises. La page ne fait
''' que le travail et rend un compte rendu.
''' </summary>
Public Class clsAdminGateway

    Private ReadOnly _baseUrl As String
    Private ReadOnly _cle As String

    Public Sub New(baseUrl As String, cle As String)
        _baseUrl = If(baseUrl, "").Trim()
        _cle = If(cle, "").Trim()
    End Sub

    ''' <summary>Adresse complete du point d'entree, quelle que soit la forme de l'URL de base.</summary>
    Public ReadOnly Property UrlRunner As String
        Get
            Dim b As String = _baseUrl
            If b = "" Then Return ""
            If b.EndsWith("/") Then b = b.TrimEnd("/"c)
            If b.EndsWith("JobRunner.ashx", StringComparison.OrdinalIgnoreCase) Then Return b
            Return b & "/JobRunner.ashx"
        End Get
    End Property

    Public ReadOnly Property EstConfigure As Boolean
        Get
            Return _baseUrl <> "" AndAlso _cle <> ""
        End Get
    End Property

    ''' <summary>
    ''' Demande a la console d'executer une tache. Le delai d'attente suit celui
    ''' de la definition : une tache qui a le droit de durer cinq minutes ne doit
    ''' pas etre coupee au bout de cent secondes par le defaut de .NET.
    '''
    ''' Ne leve pas sur une reponse d'erreur : une tache en echec est un
    ''' resultat, pas une panne. Ne leve que si la console est injoignable, et
    ''' l'appelant traduit ca en echec d'execution.
    ''' </summary>
    Public Function ExecuterTache(executionId As Integer, timeoutSeconds As Integer) As AdminJobResult

        If Not EstConfigure Then
            Throw New InvalidOperationException(
                "La console d'administration n'est pas configurée : renseignez son adresse et sa clé dans les paramètres du service.")
        End If

        Dim corps As Byte() = Encoding.UTF8.GetBytes("executionId=" & executionId.ToString())

        Dim req As HttpWebRequest = CType(WebRequest.Create(UrlRunner), HttpWebRequest)
        req.Method = "POST"
        req.ContentType = "application/x-www-form-urlencoded"
        req.ContentLength = corps.Length
        req.Headers("X-Job-Key") = _cle
        req.UserAgent = "ServiceExecuteur/" & Environment.MachineName

        ' Marge sur le delai de la tache : le temps du reseau et du demarrage
        ' d'IIS ne doit pas etre pris sur le temps de travail.
        Dim ms As Integer = (If(timeoutSeconds > 0, timeoutSeconds, 300) + 30) * 1000
        req.Timeout = ms
        req.ReadWriteTimeout = ms

        Using flux As Stream = req.GetRequestStream()
            flux.Write(corps, 0, corps.Length)
        End Using

        Dim brut As String
        Try
            Using rep As HttpWebResponse = CType(req.GetResponse(), HttpWebResponse)
                brut = Lire(rep)
            End Using

        Catch ex As WebException When ex.Response IsNot Nothing
            ' 400, 403... : la console a quand meme repondu quelque chose
            ' d'exploitable, on prefere son message a « erreur distante ».
            Using rep As HttpWebResponse = CType(ex.Response, HttpWebResponse)
                brut = Lire(rep)
                Dim issue As AdminJobResult = Analyser(brut)
                If issue IsNot Nothing Then
                    issue.Succes = False
                    If issue.Message = "" Then issue.Message = "HTTP " & CInt(rep.StatusCode) & " sur " & UrlRunner
                    Return issue
                End If
                Return New AdminJobResult With {
                    .Succes = False,
                    .Message = "HTTP " & CInt(rep.StatusCode) & " sur " & UrlRunner,
                    .Detail = brut
                }
            End Using
        End Try

        Dim resultat As AdminJobResult = Analyser(brut)
        If resultat Is Nothing Then
            Throw New InvalidOperationException(
                "Réponse illisible de la console d'administration (" & UrlRunner & ") : " &
                Tronquer(brut, 300))
        End If

        Return resultat
    End Function

    Private Shared Function Lire(rep As HttpWebResponse) As String
        Using flux As Stream = rep.GetResponseStream()
            If flux Is Nothing Then Return ""
            Using sr As New StreamReader(flux, Encoding.UTF8)
                Return sr.ReadToEnd()
            End Using
        End Using
    End Function

    ''' <summary>
    ''' Lit le compte rendu JSON. Renvoie Nothing quand ce n'en est pas — le cas
    ''' typique etant une page d'erreur ASP.NET ou la redirection vers le login,
    ''' qui rendent du HTML.
    ''' </summary>
    Private Shared Function Analyser(brut As String) As AdminJobResult
        If String.IsNullOrWhiteSpace(brut) Then Return Nothing

        Try
            Dim o As JObject = JObject.Parse(brut)

            Dim r As New AdminJobResult()
            r.Succes = (o("success") IsNot Nothing AndAlso o("success").Value(Of Boolean)())
            r.Message = If(o("message") Is Nothing, "", o("message").Value(Of String)())
            If o("detail") IsNot Nothing Then r.Detail = o("detail").Value(Of String)()
            If o("rows") IsNot Nothing AndAlso o("rows").Type <> JTokenType.Null Then
                r.LignesTraitees = o("rows").Value(Of Integer)()
            End If
            Return r

        Catch
            Return Nothing
        End Try
    End Function

    Private Shared Function Tronquer(valeur As String, max As Integer) As String
        If valeur Is Nothing Then Return ""
        Dim v As String = valeur.Replace(vbCr, " ").Replace(vbLf, " ").Trim()
        If v.Length <= max Then Return v
        Return v.Substring(0, max) & "…"
    End Function

End Class
