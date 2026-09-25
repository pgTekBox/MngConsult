Imports System.IO
Imports System.Text
Imports System.Threading.Tasks
Imports System.Web.Script.Serialization
Imports System.Web.SessionState

''' <summary>
''' Le point d'appel de l'assistant flottant (la boîte à droite de chaque page).
'''   GET  : la conversation en cours, pour la réafficher à l'ouverture.
'''   POST : { "question": "…" } → { "reponse": "…", "cout": 0.0021 }.
''' Même session, même historique et même journal que la page Assistant : les
''' deux montrent la même conversation. Un visiteur sans compte actif ou sans
''' compagnie configurée reçoit 403 ; l'autorisation globale (deny users=?)
''' arrête déjà les anonymes avant d'arriver ici.
''' </summary>
Public Class AssistantHandler
    Inherits HttpTaskAsyncHandler
    Implements IRequiresSessionState

    Private Const CleSession As String = "AssistantIA"

    Public Overrides Async Function ProcessRequestAsync(context As HttpContext) As Task
        context.Response.ContentType = "application/json; charset=utf-8"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Dim js As New JavaScriptSerializer() With {.MaxJsonLength = Integer.MaxValue}

        If Contexte.Compte Is Nothing OrElse Contexte.CompagnieId = 0 Then
            context.Response.StatusCode = 403
            context.Response.Write(js.Serialize(New With {.erreur = Tr("La paie n'est pas encore configurée pour cette compagnie.")}))
            Return
        End If

        Dim historique = TryCast(context.Session(CleSession), List(Of TourIA))
        If historique Is Nothing Then
            historique = New List(Of TourIA)()
            context.Session(CleSession) = historique
        End If

        If context.Request.HttpMethod = "GET" Then
            context.Response.Write(js.Serialize(New With {
                .tours = historique.Select(Function(t) New With {.role = t.Role, .texte = t.Texte, .quand = t.Quand.ToString("HH:mm")}).ToList(),
                .cout = AssistantIA.CoutDuMois()}))
            Return
        End If

        If context.Request.HttpMethod = "DELETE" Then
            context.Session.Remove(CleSession)
            context.Response.Write("{}")
            Return
        End If

        Dim question As String = ""
        Try
            Using lecteur As New StreamReader(context.Request.InputStream, Encoding.UTF8)
                Dim corps = TryCast(js.DeserializeObject(lecteur.ReadToEnd()), Dictionary(Of String, Object))
                If corps IsNot Nothing AndAlso corps.ContainsKey("question") Then question = Convert.ToString(corps("question"))
            End Using
        Catch
            question = ""
        End Try

        Try
            Dim r = Await AssistantIA.DemanderAsync(question, historique, I18n.Langue)
            historique.Add(New TourIA With {.Role = "user", .Texte = question.Trim(), .Quand = Date.Now})
            historique.Add(New TourIA With {.Role = "assistant", .Texte = r.Texte, .Quand = Date.Now})
            context.Response.Write(js.Serialize(New With {.reponse = r.Texte, .quand = Date.Now.ToString("HH:mm"), .cout = AssistantIA.CoutDuMois()}))
        Catch ex As SaisieInvalideException
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.erreur = ex.Message}))
        Catch ex As Exception
            context.Response.StatusCode = 502
            context.Response.Write(js.Serialize(New With {.erreur = Tr("L'assistant n'a pas pu répondre : {0}", ex.Message)}))
        End Try
    End Function

End Class
