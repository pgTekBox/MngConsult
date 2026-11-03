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

            Dim id As Integer = 0, numero As String = "", avant As Boolean = True, token As String = ""
            Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand("s0868InsertLandingReservation", conn) With {.CommandType = CommandType.StoredProcedure}
                    cmd.Parameters.AddRange(p.ToArray())
                    conn.Open()
                    Using rd As SqlDataReader = cmd.ExecuteReader()
                        If rd.Read() Then
                            id = Convert.ToInt32(rd("Id"))
                            numero = Convert.ToString(rd("Numero"))
                            avant = Convert.ToBoolean(rd("AvantLancement"))
                            If HasColumn(rd, "ValidationToken") AndAlso Not IsDBNull(rd("ValidationToken")) Then
                                token = Convert.ToString(rd("ValidationToken"))
                            End If
                        End If
                    End Using
                End Using
            End Using

            ' Courriel de validation : envoyé à l'adresse saisie (non bloquant). La
            ' page prévient l'usager qu'il va le recevoir ; le lien confirme l'adresse.
            Dim valide As Boolean = False
            If id > 0 AndAlso token <> "" Then
                Try
                    EnvoyerCourrielValidation(context, Texte(d, "courriel", 320), Texte(d, "nom", 200), token, Texte(d, "languePage", 10))
                    valide = True
                Catch
                End Try
            End If

            context.Response.Write(js.Serialize(New With {.id = id, .numero = numero, .avantLancement = avant, .validation = valide}))
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

    Private Shared Function HasColumn(rd As SqlDataReader, nom As String) As Boolean
        For i As Integer = 0 To rd.FieldCount - 1
            If String.Equals(rd.GetName(i), nom, StringComparison.OrdinalIgnoreCase) Then Return True
        Next
        Return False
    End Function

    Private Shared Function HtmlEnc(s As String) As String
        Return System.Web.HttpUtility.HtmlEncode(If(s, ""))
    End Function

    Private Shared Function Bouton(lien As String, texte As String) As String
        Return "<p style=""margin:22px 0""><a href=""" & HtmlEnc(lien) &
               """ style=""background:#1B4F9C;color:#fff;text-decoration:none;font-weight:bold;border-radius:999px;padding:12px 22px;display:inline-block"">" &
               HtmlEnc(texte) & "</a></p>"
    End Function

    ''' <summary>
    ''' Dépose un courriel de validation dans la BD MailService (s0610InsertOutboundMail,
    ''' ramassé par SrvAI). Trilingue selon la langue de la page. Non bloquant : toute
    ''' erreur est avalée par l'appelant.
    ''' </summary>
    Private Shared Sub EnvoyerCourrielValidation(context As HttpContext, courriel As String, nom As String, token As String, languePage As String)
        If String.IsNullOrEmpty(courriel) OrElse String.IsNullOrEmpty(token) Then Return
        Dim mailCnx As String = ConfigurationManager.AppSettings("ConnectionStringMail")
        If String.IsNullOrEmpty(mailCnx) Then Return

        Dim lang As String = If(languePage, "fr").Trim().ToLowerInvariant()
        lang = If(lang.Length >= 2, lang.Substring(0, 2), "fr")

        Dim baseUrl As String = context.Request.Url.GetLeftPart(UriPartial.Authority)
        Dim appPath As String = If(context.Request.ApplicationPath, "/").TrimEnd("/"c)
        Dim lien As String = baseUrl & appPath & "/LandingValidation.aspx?t=" & Uri.EscapeDataString(token) & "&lang=" & lang

        Dim prenom As String = If(String.IsNullOrEmpty(nom), "", " " & nom)
        Dim sujet As String, corps As String
        Select Case lang
            Case "en"
                sujet = "Confirm your email — 60secondes"
                corps = "<p>Hello" & HtmlEnc(prenom) & ",</p>" &
                        "<p>Thank you for reserving your spot with <strong>60secondes</strong>. Please confirm this email address by clicking the button below.</p>" &
                        Bouton(lien, "Confirm my email") &
                        "<p style=""color:#44536E;font-size:13px"">If the button does not work, copy this link into your browser:<br>" & HtmlEnc(lien) & "</p>" &
                        "<p style=""color:#44536E;font-size:13px"">If you did not make this request, you can ignore this message.</p>"
            Case "es"
                sujet = "Confirme su correo — 60secondes"
                corps = "<p>Hola" & HtmlEnc(prenom) & ",</p>" &
                        "<p>Gracias por reservar su lugar con <strong>60secondes</strong>. Confirme esta dirección de correo haciendo clic en el botón.</p>" &
                        Bouton(lien, "Confirmar mi correo") &
                        "<p style=""color:#44536E;font-size:13px"">Si el botón no funciona, copie este enlace en su navegador:<br>" & HtmlEnc(lien) & "</p>" &
                        "<p style=""color:#44536E;font-size:13px"">Si no hizo esta solicitud, puede ignorar este mensaje.</p>"
            Case Else
                sujet = "Confirmez votre courriel — 60secondes"
                corps = "<p>Bonjour" & HtmlEnc(prenom) & ",</p>" &
                        "<p>Merci d'avoir réservé votre place avec <strong>60secondes</strong>. Confirmez cette adresse courriel en cliquant sur le bouton.</p>" &
                        Bouton(lien, "Confirmer mon courriel") &
                        "<p style=""color:#44536E;font-size:13px"">Si le bouton ne fonctionne pas, copiez ce lien dans votre navigateur :<br>" & HtmlEnc(lien) & "</p>" &
                        "<p style=""color:#44536E;font-size:13px"">Si vous n'êtes pas à l'origine de cette demande, ignorez ce message.</p>"
        End Select

        Dim html As String = "<div style=""font-family:Arial,Helvetica,sans-serif;font-size:15px;color:#0E1F3D;line-height:1.5"">" & corps & "</div>"

        Using conn As New SqlConnection(mailCnx)
            Using cmd As New SqlCommand("s0610InsertOutboundMail", conn) With {.CommandType = CommandType.StoredProcedure}
                cmd.Parameters.Add(New SqlParameter("@To", courriel))
                cmd.Parameters.Add(New SqlParameter("@Subject", sujet))
                cmd.Parameters.Add(New SqlParameter("@HTMLBody", html))
                cmd.Parameters.Add(New SqlParameter("@TextBody", lien))
                cmd.Parameters.Add(New SqlParameter("@ReplyTo", "info@60secondes.ca"))
                conn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

End Class
