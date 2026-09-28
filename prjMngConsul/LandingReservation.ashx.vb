Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Web.Script.Serialization

''' <summary>
''' « Réserver ma place » de la page d'accueil : reçoit la demande en JSON
''' (POST, anonyme), l'enregistre par s0868InsertLandingReservation et rend
''' { "id": n } ou { "erreur": "…" }. Les refus de la procédure (courriel
''' invalide, consentement absent, rafale) reviennent tels quels, en 400.
''' </summary>
Public Class LandingReservationHandler
    Implements IHttpHandler

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return True
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json; charset=utf-8"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Dim js As New JavaScriptSerializer()

        If context.Request.HttpMethod <> "POST" Then
            context.Response.StatusCode = 405
            context.Response.Write(js.Serialize(New With {.erreur = "POST attendu."}))
            Return
        End If
        If context.Request.ContentLength > 32768 Then
            context.Response.StatusCode = 413
            context.Response.Write(js.Serialize(New With {.erreur = "Demande trop volumineuse."}))
            Return
        End If

        Dim brut As String
        Dim d As Dictionary(Of String, Object)
        Try
            Using lecteur As New StreamReader(context.Request.InputStream, Encoding.UTF8)
                brut = lecteur.ReadToEnd()
            End Using
            d = TryCast(js.DeserializeObject(brut), Dictionary(Of String, Object))
        Catch
            d = Nothing
            brut = ""
        End Try
        If d Is Nothing Then
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.erreur = "Demande illisible."}))
            Return
        End If

        Try
            Dim p As New List(Of SqlParameter) From {
                Param("@Profil", Texte(d, "profil", 10)),
                Param("@ProfilLibelle", Texte(d, "profilLibelle", 60)),
                Param("@Nom", Texte(d, "nom", 200)),
                Param("@Courriel", Texte(d, "courriel", 320)),
                Param("@Secteur", Texte(d, "secteur", 200)),
                Param("@SousCategorie", Texte(d, "sousCategorie", 200)),
                Param("@ActiviteAutre", Texte(d, "activiteAutre", 200)),
                Param("@Taxes", Texte(d, "taxes", 60)),
                Param("@SocieteNom", Texte(d, "societeNom", 200)),
                Param("@FinExercice", Texte(d, "finExercice", 60)),
                Param("@NbEmployes", Entier(d, "nbEmployes")),
                Param("@FrequencePaie", Texte(d, "frequencePaie", 60)),
                Param("@CabinetNom", Texte(d, "cabinetNom", 200)),
                Param("@NbDossiers", Texte(d, "nbDossiers", 60)),
                Param("@Logiciel", Texte(d, "logiciel", 60)),
                Param("@Pilote", Bit(d, "pilote")),
                Param("@Langue", Texte(d, "langue", 60)),
                Param("@Estimation", Texte(d, "estimation", 60)),
                Param("@Fondateur", Bit(d, "fondateur")),
                Param("@Consentement", If(Bit(d, "consentement"), True, False)),
                Param("@AvisLancement", If(Bit(d, "avisLancement"), True, False)),
                Param("@Destinataire", Texte(d, "destinataire", 320)),
                Param("@Page", Texte(d, "page", 500)),
                Param("@Ip", Gauche(context.Request.UserHostAddress, 64)),
                Param("@UserAgent", Gauche(context.Request.UserAgent, 400)),
                Param("@Brut", Gauche(brut, 30000))}

            Dim id As Integer = 0
            Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand("s0868InsertLandingReservation", conn) With {.CommandType = CommandType.StoredProcedure}
                    cmd.Parameters.AddRange(p.ToArray())
                    conn.Open()
                    Dim r As Object = cmd.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then id = Convert.ToInt32(r)
                End Using
            End Using
            context.Response.Write(js.Serialize(New With {.id = id}))
        Catch ex As SqlException When ex.Class = 16
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.erreur = ex.Message}))
        Catch ex As Exception
            context.Response.StatusCode = 500
            context.Response.Write(js.Serialize(New With {.erreur = "La demande n'a pas pu être enregistrée."}))
        End Try
    End Sub

    Private Shared Function Param(nom As String, valeur As Object) As SqlParameter
        Return New SqlParameter(nom, If(valeur, DBNull.Value))
    End Function

    Private Shared Function Texte(d As Dictionary(Of String, Object), cle As String, max As Integer) As String
        Dim v As Object = Nothing
        If Not d.TryGetValue(cle, v) OrElse v Is Nothing Then Return Nothing
        Dim s As String = Convert.ToString(v).Trim()
        If s.Length = 0 Then Return Nothing
        Return Gauche(s, max)
    End Function

    Private Shared Function Entier(d As Dictionary(Of String, Object), cle As String) As Object
        Dim s As String = Texte(d, cle, 20)
        Dim n As Integer
        If s IsNot Nothing AndAlso Integer.TryParse(s, n) Then Return n
        Return Nothing
    End Function

    ''' <summary>"1", "true", "oui" → True ; "0", "false", "non", vide → False ; absent → Nothing.</summary>
    Private Shared Function Bit(d As Dictionary(Of String, Object), cle As String) As Object
        Dim s As String = Texte(d, cle, 20)
        If s Is Nothing Then Return Nothing
        Select Case s.ToLowerInvariant()
            Case "1", "true", "oui", "yes", "sí", "si", "on" : Return True
            Case Else : Return False
        End Select
    End Function

    Private Shared Function Gauche(s As String, n As Integer) As String
        If s Is Nothing Then Return Nothing
        Return If(s.Length > n, s.Substring(0, n), s)
    End Function

End Class
