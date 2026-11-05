Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Web
Imports System.Web.SessionState
Imports System.Web.Script.Serialization

''' <summary>
''' Comptabilise directement le brouillon de facture lié à un rendez-vous, depuis
''' le bouton « Facturer » de la boîte « Aujourd'hui » du tableau de bord.
''' L'usager doit être authentifié (Session UserId) et avoir une compagnie en
''' session (Session Company). Appelle s0972ComptabiliserFactureCompagnie, qui
''' valide l'appartenance à la compagnie puis exécute sp_ComptabiliserDocument.
'''
''' POST application/json { docId } → { ok, numero } en cas de succès ;
'''   { ok:false, besoinClient:true, erreur } si le brouillon n'a pas de client ;
'''   { ok:false, erreur } pour toute autre erreur (période fermée, etc.).
''' </summary>
Public Class ComptabiliserFactureHandler
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

        If context.Request.HttpMethod.ToUpperInvariant() <> "POST" Then
            context.Response.StatusCode = 405
            context.Response.Write(js.Serialize(New With {.ok = False, .erreur = "Méthode non permise."}))
            Return
        End If

        ' Compagnie de session : obligatoire (isolation par compagnie).
        Dim company As Object = CompagnieSession(context)
        If company Is DBNull.Value Then
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.ok = False, .erreur = "Aucune compagnie sélectionnée."}))
            Return
        End If

        ' Corps JSON : { docId }
        Dim docId As Integer = 0
        Try
            If context.Request.ContentLength > 10000 Then
                context.Response.StatusCode = 413
                context.Response.Write(js.Serialize(New With {.ok = False, .erreur = "Demande trop volumineuse."}))
                Return
            End If
            Dim brut As String = ""
            Using lecteur As New StreamReader(context.Request.InputStream, Encoding.UTF8)
                brut = lecteur.ReadToEnd()
            End Using
            Dim d As Dictionary(Of String, Object) = TryCast(js.DeserializeObject(brut), Dictionary(Of String, Object))
            If d IsNot Nothing AndAlso d.ContainsKey("docId") AndAlso d("docId") IsNot Nothing Then
                Integer.TryParse(Convert.ToString(d("docId")), docId)
            End If
        Catch
        End Try

        If docId <= 0 Then
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.ok = False, .erreur = "Document invalide."}))
            Return
        End If

        Try
            Dim numero As String = ""
            Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand("s0972ComptabiliserFactureCompagnie", conn) With {.CommandType = CommandType.StoredProcedure}
                    cmd.Parameters.Add(New SqlParameter("@DocumentId", docId))
                    cmd.Parameters.Add(New SqlParameter("@CompanyGUID", company))
                    cmd.Parameters.Add(New SqlParameter("@UserId", userId))
                    Dim pNum As New SqlParameter("@Numero", SqlDbType.VarChar, 200) With {.Direction = ParameterDirection.Output}
                    cmd.Parameters.Add(pNum)
                    conn.Open()
                    cmd.ExecuteNonQuery()
                    If pNum.Value IsNot Nothing AndAlso Not IsDBNull(pNum.Value) Then numero = Convert.ToString(pNum.Value)
                End Using
            End Using
            context.Response.Write(js.Serialize(New With {.ok = True, .numero = numero}))
        Catch sx As SqlException
            ' 51002 = brouillon sans client : l'app ouvre le brouillon à compléter.
            If sx.Number = 51002 Then
                context.Response.Write(js.Serialize(New With {.ok = False, .besoinClient = True,
                    .erreur = "Choisissez d'abord un client sur le brouillon."}))
            Else
                context.Response.Write(js.Serialize(New With {.ok = False, .erreur = MessageLisible(sx)}))
            End If
        Catch ex As Exception
            context.Response.StatusCode = 500
            context.Response.Write(js.Serialize(New With {.ok = False, .erreur = "La facture n'a pas pu être comptabilisée."}))
        End Try
    End Sub

    ''' <summary>Message d'erreur présentable : celui du THROW métier (50001-51001), sinon générique.</summary>
    Private Shared Function MessageLisible(sx As SqlException) As String
        Dim m As String = If(sx.Message, "")
        If sx.Number >= 50001 AndAlso sx.Number <= 51001 AndAlso m.Length > 0 AndAlso m.Length < 300 Then
            Return m
        End If
        Return "La facture n'a pas pu être comptabilisée."
    End Function

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

End Class
