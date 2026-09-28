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
            ' Deux vocabulaires acceptés : celui de la page (rec de window.Inscriptions : societe, employes, tpsTvq,
            ' consentementTraitement…) et celui, plus explicite, des premiers essais (societeNom, nbEmployes, taxes…).
            Dim profil As String = Texte(d, "profil", 10)
            Dim societe As String = If(Texte(d, "societe", 200), Texte(d, "societeNom", 200))
            Dim p As New List(Of SqlParameter) From {
                Param("@Profil", profil),
                Param("@ProfilLibelle", If(Texte(d, "profilLibelle", 60), LibelleProfil(profil))),
                Param("@Nom", Texte(d, "nom", 200)),
                Param("@Courriel", Texte(d, "courriel", 320)),
                Param("@Secteur", If(Texte(d, "secteur", 200), Texte(d, "activite", 200))),
                Param("@SousCategorie", Texte(d, "sousCategorie", 200)),
                Param("@ActiviteAutre", Texte(d, "activiteAutre", 200)),
                Param("@Taxes", If(Texte(d, "taxes", 60), Texte(d, "tpsTvq", 60))),
                Param("@SocieteNom", If(profil = "cab", Nothing, societe)),
                Param("@FinExercice", Texte(d, "finExercice", 60)),
                Param("@NbEmployes", If(Entier(d, "nbEmployes"), Entier(d, "employes"))),
                Param("@FrequencePaie", Texte(d, "frequencePaie", 60)),
                Param("@CabinetNom", If(Texte(d, "cabinetNom", 200), If(profil = "cab", societe, Nothing))),
                Param("@NbDossiers", If(Texte(d, "nbDossiers", 60), Texte(d, "dossiers", 60))),
                Param("@Logiciel", Texte(d, "logiciel", 60)),
                Param("@Pilote", Bit(d, "pilote")),
                Param("@Langue", If(Texte(d, "langue", 60), Texte(d, "langueTravail", 60))),
                Param("@Estimation", If(Texte(d, "estimation", 60), Texte(d, "forfaitEstime", 60))),
                Param("@Fondateur", Bit(d, "fondateur")),
                Param("@Consentement", If(If(Bit(d, "consentement"), Bit(d, "consentementTraitement")), False)),
                Param("@AvisLancement", If(If(Bit(d, "avisLancement"), Bit(d, "consentementAvis")), False)),
                Param("@Destinataire", If(Texte(d, "destinataire", 320), If(profil = "cab", "certifies@60secondes.ca", "info@60secondes.ca"))),
                Param("@Page", Texte(d, "page", 500)),
                Param("@Ip", Gauche(context.Request.UserHostAddress, 64)),
                Param("@UserAgent", Gauche(context.Request.UserAgent, 400)),
                Param("@Brut", Gauche(brut, 30000)),
                Param("@Source", Texte(d, "source", 20)),
                Param("@LanguePage", Texte(d, "languePage", 10))}

            Dim id As Integer = 0, numero As String = "", avant As Boolean = True
            Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand("s0868InsertLandingReservation", conn) With {.CommandType = CommandType.StoredProcedure}
                    cmd.Parameters.AddRange(p.ToArray())
                    conn.Open()
                    Using rd As SqlDataReader = cmd.ExecuteReader()
                        If rd.Read() Then
                            id = Convert.ToInt32(rd("Id"))
                            numero = Convert.ToString(rd("Numero"))
                            avant = Convert.ToBoolean(rd("AvantLancement"))
                        End If
                    End Using
                End Using
            End Using
            context.Response.Write(js.Serialize(New With {.id = id, .numero = numero, .avantLancement = avant}))
        Catch ex As SqlException When ex.Class = 16
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.erreur = ex.Message}))
        Catch ex As Exception
            context.Response.StatusCode = 500
            context.Response.Write(js.Serialize(New With {.erreur = "La demande n'a pas pu être enregistrée."}))
        End Try
    End Sub

    Private Shared Function LibelleProfil(profil As String) As String
        Select Case If(profil, "")
            Case "ta" : Return "travailleur autonome"
            Case "c0" : Return "société sans employé"
            Case "c4" : Return "société avec employés"
            Case "cab" : Return "cabinet comptable"
            Case Else : Return Nothing
        End Select
    End Function

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
