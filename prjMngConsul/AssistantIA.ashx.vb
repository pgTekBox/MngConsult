Imports System.IO
Imports System.Text
Imports System.Threading.Tasks
Imports System.Web.Script.Serialization
Imports System.Web.SessionState

''' <summary>
''' Le point d'appel de l'assistant flottant (la boîte à droite de chaque page).
'''   GET    : la conversation en cours, pour la réafficher à l'ouverture.
'''   POST   : { "question": "…", "section": "ventes" } → { "reponse": "…", "quand": "HH:mm", "cout": 0.0021 }.
'''   DELETE : efface la conversation.
''' Même session, même historique et même journal que la page wbfAssistant : les
''' deux montrent la même conversation. Sans session ouverte ou sans compagnie
''' active, 403.
''' </summary>
Public Class AssistantHandler
    Inherits HttpTaskAsyncHandler
    Implements IRequiresSessionState

    Public Const CleSession As String = "AssistantIA"

    Public Overrides Async Function ProcessRequestAsync(context As HttpContext) As Task
        context.Response.ContentType = "application/json; charset=utf-8"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Dim js As New JavaScriptSerializer() With {.MaxJsonLength = Integer.MaxValue}

        Dim userId As Integer = 0
        Dim companyGuid As Guid = Guid.Empty
        Try
            If context.Session("UserId") IsNot Nothing Then userId = Convert.ToInt32(context.Session("UserId"))
            If context.Session("Company") IsNot Nothing Then companyGuid = CType(context.Session("Company"), Guid)
        Catch
        End Try
        Dim langue As String = TryCast(context.Session("Lang"), String)
        If langue <> "en" AndAlso langue <> "es" Then langue = "fr"
        Dim utilisateur As String = Convert.ToString(context.Session("UserEmail"))

        If userId = 0 OrElse companyGuid = Guid.Empty Then
            context.Response.StatusCode = 403
            context.Response.Write(js.Serialize(New With {.erreur = clsAssistantIA.Tr(langue, "Ouvrez une session pour utiliser l'assistant.", "Sign in to use the assistant.", "Inicie sesión para usar el asistente.")}))
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
                .cout = clsAssistantIA.CoutDuMois(companyGuid)}))
            Return
        End If

        If context.Request.HttpMethod = "DELETE" Then
            context.Session.Remove(CleSession)
            context.Response.Write("{}")
            Return
        End If

        Dim question As String = ""
        Dim section As String = Nothing
        Try
            Using lecteur As New StreamReader(context.Request.InputStream, Encoding.UTF8)
                Dim corps = TryCast(js.DeserializeObject(lecteur.ReadToEnd()), Dictionary(Of String, Object))
                If corps IsNot Nothing AndAlso corps.ContainsKey("question") Then question = Convert.ToString(corps("question"))
                If corps IsNot Nothing AndAlso corps.ContainsKey("section") Then section = Convert.ToString(corps("section"))
            End Using
        Catch
            question = ""
        End Try
        If section IsNot Nothing AndAlso Array.IndexOf(clsAide.Sections, section) < 0 Then section = Nothing

        Try
            Dim r = Await clsAssistantIA.DemanderAsync(companyGuid, utilisateur, question, historique, langue, section)
            historique.Add(New TourIA With {.Role = "user", .Texte = question.Trim(), .Quand = Date.Now})
            historique.Add(New TourIA With {.Role = "assistant", .Texte = r.Texte, .Quand = Date.Now})
            context.Response.Write(js.Serialize(New With {.reponse = r.Texte, .quand = Date.Now.ToString("HH:mm"), .cout = clsAssistantIA.CoutDuMois(companyGuid)}))
        Catch ex As SaisieAssistantException
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.erreur = ex.Message}))
        Catch ex As Exception
            context.Response.StatusCode = 502
            context.Response.Write(js.Serialize(New With {.erreur = clsAssistantIA.Tr(langue, "L'assistant n'a pas pu répondre : ", "The assistant could not answer: ", "El asistente no pudo responder: ") & ex.Message}))
        End Try
    End Function

End Class
