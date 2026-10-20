Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Web
Imports System.Web.Script.Serialization
Imports System.Web.SessionState

''' <summary>
''' Le cabinet choisi et la répartition des tâches de la fenêtre « Mon cabinet
''' comptable » (js/cabinet-60s.js), enregistrés par compagnie (T323MonCabinet).
''' Toujours la compagnie de la session : aucun identifiant n'est lu de la requête.
'''
'''   GET  MonCabinet.ashx   → { etat: {…} | null, maj: "aaaa-mm-jjThh:mm:ssZ" | null }
'''   POST MonCabinet.ashx   (corps JSON = l'état)  → { ok: true, maj: … }
''' </summary>
Public Class MonCabinetHandler
    Implements IHttpHandler, IReadOnlySessionState

    ' Un état complet pèse environ 2 Ko ; la limite ne laisse passer rien d'autre.
    Private Const TailleMax As Integer = 32 * 1024

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json; charset=utf-8"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Dim js As New JavaScriptSerializer() With {.MaxJsonLength = TailleMax * 2}

        Dim userId As Integer = 0
        Dim company As Guid = Guid.Empty
        Try
            If context.Session("UserId") IsNot Nothing Then userId = Convert.ToInt32(context.Session("UserId"))
            If context.Session("Company") IsNot Nothing Then company = CType(context.Session("Company"), Guid)
        Catch
        End Try
        If userId = 0 OrElse company = Guid.Empty Then
            context.Response.StatusCode = 401
            context.Response.Write(js.Serialize(New With {.erreur = "Session expirée : reconnectez-vous."}))
            Return
        End If

        Dim hote As New ApideckExtraction.HoteFond(company, userId)
        Try
            If context.Request.HttpMethod = "POST" Then
                Enregistrer(context, js, hote, company, userId)
            Else
                Lire(context, js, hote, company)
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("MonCabinet : " & ex.Message)
            context.Response.StatusCode = 500
            context.Response.Write(js.Serialize(New With {.erreur = "Enregistrement impossible pour l'instant."}))
        End Try
    End Sub

    Private Sub Lire(context As HttpContext, js As JavaScriptSerializer, hote As ApideckExtraction.HoteFond, company As Guid)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", company))
        Dim ds As DataSet = hote.ExecuteSQLds("s0908GetMonCabinet", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            context.Response.Write("{""etat"":null,""maj"":null}")
            Return
        End If
        Dim r As DataRow = ds.Tables(0).Rows(0)
        ' L'état est déjà du JSON validé par la base : on l'insère tel quel.
        Dim maj As String = CDate(r("MajUtc")).ToString("yyyy-MM-ddTHH:mm:ssZ")
        context.Response.Write("{""etat"":" & Convert.ToString(r("Etat")) & ",""maj"":" & js.Serialize(maj) & "}")
    End Sub

    Private Sub Enregistrer(context As HttpContext, js As JavaScriptSerializer, hote As ApideckExtraction.HoteFond, company As Guid, userId As Integer)
        ' Même origine seulement : un autre site ne peut pas écrire à la place de l'utilisateur.
        Dim origine As String = context.Request.Headers("Origin")
        If Not String.IsNullOrEmpty(origine) Then
            Dim o As Uri = Nothing
            If Not Uri.TryCreate(origine, UriKind.Absolute, o) OrElse
               Not String.Equals(o.Authority, context.Request.Url.Authority, StringComparison.OrdinalIgnoreCase) Then
                context.Response.StatusCode = 403
                context.Response.Write(js.Serialize(New With {.erreur = "Origine refusée."}))
                Return
            End If
        End If
        If Not If(context.Request.ContentType, "").StartsWith("application/json", StringComparison.OrdinalIgnoreCase) Then
            context.Response.StatusCode = 415
            context.Response.Write(js.Serialize(New With {.erreur = "JSON attendu."}))
            Return
        End If
        If context.Request.ContentLength > TailleMax Then
            context.Response.StatusCode = 413
            context.Response.Write(js.Serialize(New With {.erreur = "État trop volumineux."}))
            Return
        End If

        Dim corps As String
        Using lecteur As New StreamReader(context.Request.InputStream, Encoding.UTF8)
            corps = lecteur.ReadToEnd()
        End Using
        If corps.Length > TailleMax Then
            context.Response.StatusCode = 413
            context.Response.Write(js.Serialize(New With {.erreur = "État trop volumineux."}))
            Return
        End If

        ' Doit être un objet JSON ; on le réécrit pour ne garder que du JSON propre.
        Dim etat As Dictionary(Of String, Object) = Nothing
        Try
            etat = js.Deserialize(Of Dictionary(Of String, Object))(corps)
        Catch
        End Try
        If etat Is Nothing Then
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.erreur = "État invalide."}))
            Return
        End If

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", company))
        p.Add(New SqlParameter("@Etat", SqlDbType.NVarChar, -1) With {.Value = js.Serialize(etat)})
        p.Add(New SqlParameter("@UserId", userId))
        hote.ExecuteSQL("s0909SaveMonCabinet", p)

        context.Response.Write(js.Serialize(New With {.ok = True, .maj = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")}))
    End Sub

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property
End Class
