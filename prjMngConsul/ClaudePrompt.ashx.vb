Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Web
Imports System.Web.SessionState
Imports System.Web.Script.Serialization

''' <summary>
''' Enregistre une « demande à Claude » composée depuis le bouton flottant de
''' l'ERP (POST JSON { page, prompt, url }). L'usager doit être authentifié
''' (Session UserId). La demande est stockée par s0963InsertClaudePrompt et
''' revue dans la console d'admin (prjSec60Admin → wbfClaudePrompts).
''' </summary>
Public Class ClaudePromptHandler
    Implements IHttpHandler, IReadOnlySessionState

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json; charset=utf-8"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Dim js As New JavaScriptSerializer()

        If context.Request.HttpMethod <> "POST" Then
            context.Response.StatusCode = 405
            context.Response.Write(js.Serialize(New With {.ok = False, .erreur = "POST attendu."}))
            Return
        End If

        ' Authentification : UserId en session (posé à la connexion).
        Dim userId As Integer = 0
        Try
            If context.Session IsNot Nothing AndAlso context.Session("UserId") IsNot Nothing Then
                userId = Convert.ToInt32(context.Session("UserId"))
            End If
        Catch
        End Try
        If userId = 0 Then
            context.Response.StatusCode = 403
            context.Response.Write(js.Serialize(New With {.ok = False, .erreur = "Non authentifié."}))
            Return
        End If

        Dim company As Object = DBNull.Value
        Try
            If context.Session("Company") IsNot Nothing Then
                Dim g As Guid = CType(context.Session("Company"), Guid)
                If g <> Guid.Empty Then company = g
            End If
        Catch
        End Try

        Dim brut As String = ""
        Dim d As Dictionary(Of String, Object) = Nothing
        Try
            If context.Request.ContentLength > 200000 Then
                context.Response.StatusCode = 413
                context.Response.Write(js.Serialize(New With {.ok = False, .erreur = "Demande trop volumineuse."}))
                Return
            End If
            Using lecteur As New StreamReader(context.Request.InputStream, Encoding.UTF8)
                brut = lecteur.ReadToEnd()
            End Using
            d = TryCast(js.DeserializeObject(brut), Dictionary(Of String, Object))
        Catch
        End Try
        If d Is Nothing Then
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.ok = False, .erreur = "Demande illisible."}))
            Return
        End If

        Dim page As String = Texte(d, "page", 200)
        Dim prompt As String = Texte(d, "prompt", 100000)
        Dim url As String = Texte(d, "url", 600)
        If String.IsNullOrEmpty(page) OrElse String.IsNullOrEmpty(prompt) Then
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.ok = False, .erreur = "Page et prompt sont requis."}))
            Return
        End If

        Try
            Dim id As Integer = 0
            Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand("s0963InsertClaudePrompt", conn) With {.CommandType = CommandType.StoredProcedure}
                    cmd.Parameters.Add(New SqlParameter("@UserId", userId))
                    cmd.Parameters.Add(New SqlParameter("@CompanyGUID", company))
                    cmd.Parameters.Add(New SqlParameter("@Page", page))
                    cmd.Parameters.Add(New SqlParameter("@Prompt", prompt))
                    cmd.Parameters.Add(New SqlParameter("@Url", If(CObj(url), DBNull.Value)))
                    conn.Open()
                    Dim o As Object = cmd.ExecuteScalar()
                    If o IsNot Nothing AndAlso Not IsDBNull(o) Then id = Convert.ToInt32(o)
                End Using
            End Using
            context.Response.Write(js.Serialize(New With {.ok = True, .id = id}))
        Catch ex As Exception
            context.Response.StatusCode = 500
            context.Response.Write(js.Serialize(New With {.ok = False, .erreur = "La demande n'a pas pu être enregistrée."}))
        End Try
    End Sub

    Private Shared Function Texte(d As Dictionary(Of String, Object), cle As String, max As Integer) As String
        Dim v As Object = Nothing
        If Not d.TryGetValue(cle, v) OrElse v Is Nothing Then Return Nothing
        Dim s As String = Convert.ToString(v).Trim()
        If s.Length = 0 Then Return Nothing
        Return If(s.Length > max, s.Substring(0, max), s)
    End Function

End Class
