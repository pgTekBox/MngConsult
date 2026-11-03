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
''' l'ERP. L'usager doit être authentifié (Session UserId). La demande est
''' stockée par s0963InsertClaudePrompt et revue dans la console d'admin
''' (prjSec60Admin → wbfClaudePrompts).
'''
''' Verbes :
'''  - GET  : liste des demandes de l'usager (menu déroulant « Demandes précédentes »).
'''  - POST multipart/form-data : nouvelle demande (champs page/prompt/url + un
'''    fichier joint optionnel « fichier »).
'''  - POST application/json { op:'delete', id } : suppression d'une demande non faite.
'''  - POST application/json { page, prompt, url } : nouvelle demande sans fichier (repli).
''' </summary>
Public Class ClaudePromptHandler
    Implements IHttpHandler, IReadOnlySessionState

    ' Garde-fou serveur sur la taille du fichier joint (le web.config borne déjà
    ' la requête côté IIS via un <location> pour ce handler).
    Private Const MAX_FICHIER As Integer = 20 * 1024 * 1024

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json; charset=utf-8"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Dim js As New JavaScriptSerializer()

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

        Dim methode As String = context.Request.HttpMethod.ToUpperInvariant()
        If methode = "GET" Then
            Lister(context, js, userId)
            Return
        ElseIf methode <> "POST" Then
            context.Response.StatusCode = 405
            context.Response.Write(js.Serialize(New With {.ok = False, .erreur = "Méthode non permise."}))
            Return
        End If

        Dim company As Object = CompagnieSession(context)
        Dim ct As String = If(context.Request.ContentType, "").ToLowerInvariant()

        ' POST multipart/form-data : nouvelle demande avec fichier joint optionnel.
        If ct.StartsWith("multipart/form-data") Then
            EnregistrerMultipart(context, js, userId, company)
            Return
        End If

        ' POST application/json : suppression, ou demande texte sans fichier (repli).
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

        If String.Equals(Texte(d, "op", 20), "delete", StringComparison.OrdinalIgnoreCase) Then
            Supprimer(context, js, userId, d)
            Return
        End If

        Dim page As String = Texte(d, "page", 200)
        Dim prompt As String = Texte(d, "prompt", 100000)
        Dim url As String = Texte(d, "url", 600)
        Inserer(context, js, userId, company, page, prompt, url, Nothing, Nothing, Nothing)
    End Sub

    ''' <summary>Nouvelle demande envoyée en multipart/form-data (avec fichier joint optionnel).</summary>
    Private Sub EnregistrerMultipart(context As HttpContext, js As JavaScriptSerializer, userId As Integer, company As Object)
        ' On lit les champs sans validation de requête (le prompt peut contenir du
        ' texte ressemblant à du HTML) ; les fichiers ne sont pas validés.
        Dim form As Specialized.NameValueCollection = context.Request.Unvalidated.Form
        Dim page As String = Rogner(form("page"), 200)
        Dim prompt As String = Rogner(form("prompt"), 100000)
        Dim url As String = Rogner(form("url"), 600)

        Dim fNom As String = Nothing, fType As String = Nothing
        Dim fData As Byte() = Nothing
        Try
            Dim f As HttpPostedFile = Nothing
            If context.Request.Files IsNot Nothing AndAlso context.Request.Files.Count > 0 Then
                f = context.Request.Files("fichier")
                If f Is Nothing Then f = context.Request.Files(0)
            End If
            If f IsNot Nothing AndAlso f.ContentLength > 0 Then
                If f.ContentLength > MAX_FICHIER Then
                    context.Response.StatusCode = 413
                    context.Response.Write(js.Serialize(New With {.ok = False, .erreur = "Fichier trop volumineux (max 20 Mo)."}))
                    Return
                End If
                Dim buf(f.ContentLength - 1) As Byte
                Dim lu As Integer = 0
                While lu < f.ContentLength
                    Dim n As Integer = f.InputStream.Read(buf, lu, f.ContentLength - lu)
                    If n <= 0 Then Exit While
                    lu += n
                End While
                fData = buf
                fNom = Rogner(Path.GetFileName(f.FileName), 260)
                fType = Rogner(f.ContentType, 150)
            End If
        Catch
            fData = Nothing : fNom = Nothing : fType = Nothing
        End Try

        Inserer(context, js, userId, company, page, prompt, url, fNom, fType, fData)
    End Sub

    ''' <summary>Insertion commune (s0963), avec fichier joint optionnel.</summary>
    Private Shared Sub Inserer(context As HttpContext, js As JavaScriptSerializer, userId As Integer, company As Object,
                               page As String, prompt As String, url As String,
                               fNom As String, fType As String, fData As Byte())
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
                    cmd.Parameters.Add(New SqlParameter("@FichierNom", If(CObj(fNom), DBNull.Value)))
                    cmd.Parameters.Add(New SqlParameter("@FichierType", If(CObj(fType), DBNull.Value)))
                    cmd.Parameters.Add(New SqlParameter("@FichierTaille", If(fData Is Nothing, DBNull.Value, CObj(fData.Length))))
                    Dim pb As New SqlParameter("@FichierData", SqlDbType.VarBinary, -1)
                    pb.Value = If(fData Is Nothing, CObj(DBNull.Value), fData)
                    cmd.Parameters.Add(pb)
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

    Private Shared Function CompagnieSession(context As HttpContext) As Object
        Try
            If context.Session("Company") IsNot Nothing Then
                Dim g As Guid = CType(context.Session("Company"), Guid)
                If g <> Guid.Empty Then Return g
            End If
        Catch
        End Try
        Return DBNull.Value
    End Function

    ''' <summary>Renvoie en JSON TOUTES les demandes de l'usager (toutes pages), récentes d'abord.</summary>
    Private Shared Sub Lister(context As HttpContext, js As JavaScriptSerializer, userId As Integer)
        Dim items As New List(Of Object)()
        Try
            Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand("s0966GetClaudePromptsByPage", conn) With {.CommandType = CommandType.StoredProcedure}
                    cmd.Parameters.Add(New SqlParameter("@UserId", userId))   ' @Page omis → toutes les pages
                    conn.Open()
                    Using rd As SqlDataReader = cmd.ExecuteReader()
                        While rd.Read()
                            Dim quand As Date = Convert.ToDateTime(rd("Created")).ToLocalTime()
                            Dim statut As String = Convert.ToString(rd("Statut"))
                            Dim fnom As String = If(IsDBNull(rd("FichierNom")), "", Convert.ToString(rd("FichierNom")))
                            items.Add(New With {
                                .id = Convert.ToInt32(rd("Id")),
                                .page = Convert.ToString(rd("Page")),
                                .quand = quand.ToString("dd/MM/yyyy HH:mm"),
                                .fait = (statut = "fait"),
                                .fichier = fnom,
                                .prompt = Convert.ToString(rd("Prompt"))})
                        End While
                    End Using
                End Using
            End Using
        Catch
        End Try
        context.Response.Write(js.Serialize(New With {.ok = True, .items = items}))
    End Sub

    ''' <summary>Supprime une demande de l'usager (seulement si non « fait »).</summary>
    Private Shared Sub Supprimer(context As HttpContext, js As JavaScriptSerializer, userId As Integer, d As Dictionary(Of String, Object))
        Dim id As Integer = 0
        Integer.TryParse(If(Texte(d, "id", 20), ""), id)
        Dim n As Integer = 0
        If id > 0 Then
            Try
                Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                    Using cmd As New SqlCommand("s0967DeleteClaudePrompt", conn) With {.CommandType = CommandType.StoredProcedure}
                        cmd.Parameters.Add(New SqlParameter("@UserId", userId))
                        cmd.Parameters.Add(New SqlParameter("@Id", id))
                        conn.Open()
                        Dim o As Object = cmd.ExecuteScalar()
                        If o IsNot Nothing AndAlso Not IsDBNull(o) Then n = Convert.ToInt32(o)
                    End Using
                End Using
            Catch
            End Try
        End If
        context.Response.Write(js.Serialize(New With {.ok = (n > 0), .supprime = n}))
    End Sub

    Private Shared Function Texte(d As Dictionary(Of String, Object), cle As String, max As Integer) As String
        Dim v As Object = Nothing
        If Not d.TryGetValue(cle, v) OrElse v Is Nothing Then Return Nothing
        Return Rogner(Convert.ToString(v), max)
    End Function

    Private Shared Function Rogner(s As String, max As Integer) As String
        If s Is Nothing Then Return Nothing
        s = s.Trim()
        If s.Length = 0 Then Return Nothing
        Return If(s.Length > max, s.Substring(0, max), s)
    End Function

End Class
