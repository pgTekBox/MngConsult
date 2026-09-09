Imports System.Configuration
Imports System.Security.Cryptography
Imports System.Text
Imports System.Web
Imports System.Web.Script.Serialization

''' <summary>
''' Point d'entrée appelé par ServiceExecuteur pour exécuter une tâche.
'''
'''     POST /JobRunner.ashx
'''     X-Job-Key: &lt;clé partagée&gt;
'''     executionId=123
'''
''' Le service ne transmet que l'identifiant de l'exécution : le handler relit
''' tout le reste en base, là où les écrans d'administration l'écrivent. Il rend
''' un JSON, et c'est le service qui enregistre l'issue — lui seul tient le
''' cycle de vie de l'exécution (verrou, statut, journal, réessais).
'''
'''     { "success": true, "message": "...", "rows": 1, "detail": "..." }
'''
''' Sécurité : le service n'a pas de session, donc l'authentification passe par
''' une clé partagée (paramètre JobRunnerKey du Web.config) comparée en temps
''' constant. Sans clé configurée, le handler refuse tout : mieux vaut une tâche
''' qui ne part pas qu'un point d'entrée ouvert capable de déclencher des
''' traitements et des envois de courriels.
''' </summary>
Public Class JobRunner
    Implements IHttpHandler

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest

        context.Response.ContentType = "application/json"
        context.Response.ContentEncoding = Encoding.UTF8
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)

        Try
            If Not CleValide(context) Then
                context.Response.StatusCode = 403
                Ecrire(context, False, "Clé d'accès absente ou invalide.")
                Return
            End If

            Dim executionId As Integer
            If Not Integer.TryParse(context.Request("executionId"), executionId) OrElse executionId <= 0 Then
                context.Response.StatusCode = 400
                Ecrire(context, False, "Paramètre executionId manquant ou invalide.")
                Return
            End If

            Dim issue As JobResult = clsJobRunner.Run(executionId)
            Ecrire(context, issue.Succes, issue.Message, issue.LignesTraitees, issue.Detail)

        Catch ex As Exception
            ' Une tâche qui explose reste une réponse exploitable pour le
            ' service : il l'enregistrera en ECHEC avec le message.
            context.Response.StatusCode = 200
            Ecrire(context, False, ex.Message, Nothing, ex.ToString())
        End Try
    End Sub

#Region "Sécurité"

    ''' <summary>
    ''' Compare la clé reçue à celle du Web.config, sans court-circuit : une
    ''' comparaison qui s'arrête au premier caractère différent laisse deviner
    ''' la clé caractère par caractère.
    ''' </summary>
    Private Shared Function CleValide(context As HttpContext) As Boolean
        Dim attendue As String = ConfigurationManager.AppSettings("JobRunnerKey")
        If String.IsNullOrWhiteSpace(attendue) Then Return False

        Dim recue As String = context.Request.Headers("X-Job-Key")
        If String.IsNullOrEmpty(recue) Then recue = context.Request("key")
        If String.IsNullOrEmpty(recue) Then Return False

        Dim a As Byte() = Encoding.UTF8.GetBytes(attendue)
        Dim b As Byte() = Encoding.UTF8.GetBytes(recue)
        If a.Length <> b.Length Then Return False

        Dim diff As Integer = 0
        For i As Integer = 0 To a.Length - 1
            diff = diff Or (a(i) Xor b(i))
        Next
        Return diff = 0
    End Function

#End Region

    Private Shared Sub Ecrire(context As HttpContext,
                              succes As Boolean,
                              message As String,
                              Optional lignes As Integer? = Nothing,
                              Optional detail As String = Nothing)

        Dim charge As New Dictionary(Of String, Object) From {
            {"success", succes},
            {"message", If(message, "")}
        }
        If lignes.HasValue Then charge("rows") = lignes.Value
        If Not String.IsNullOrEmpty(detail) Then charge("detail") = detail

        context.Response.Write(New JavaScriptSerializer().Serialize(charge))
    End Sub

End Class
