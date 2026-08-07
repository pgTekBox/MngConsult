Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net
Imports Telerik.Web.UI

Public Class wbfRegister
    Inherits clsData

    ''' <summary>
    ''' Applique la langue courante aux contrôles serveur (titre, placeholders,
    ''' boutons, lien de connexion). Les textes statiques sont localisés dans le
    ''' markup via &lt;%= L("clé") %&gt;.
    ''' </summary>
    Private Sub ApplyLocalization()
        Page.Title = L("pageTitle")
        tbFirstName.Attributes("placeholder") = L("phFirstName")
        tbLastName.Attributes("placeholder") = L("phLastName")
        tbEmail.Attributes("placeholder") = L("phEmail")
        tbPassword.Attributes("placeholder") = "••••••••"
        tbPasswordConfirm.Attributes("placeholder") = "••••••••"
        btnFerme.Text = L("closeBtn")
        lnkResend.Text = L("resendLink")
        lnkLogin.Text = L("signin")
        lnkLogin.NavigateUrl = "~/wbfLogin.aspx?lang=" & CurrentLang
    End Sub

    ''' <summary>Traductions de la page d'inscription (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Inscription — 60Sec-AI", "Sign up — 60Sec-AI", "Registro — 60Sec-AI")
            Case "heading" : Return Choose3(lang, "Créer votre compte", "Create your account", "Cree su cuenta")
            Case "subtitle" : Return Choose3(lang, "Commencez en quelques secondes — gratuit, aucune carte requise", "Get started in seconds — free, no card required", "Comience en segundos — gratis, sin tarjeta")
            Case "firstName" : Return Choose3(lang, "Prénom", "First name", "Nombre")
            Case "lastName" : Return Choose3(lang, "Nom", "Last name", "Apellido")
            Case "phFirstName" : Return Choose3(lang, "Jean", "John", "Juan")
            Case "phLastName" : Return Choose3(lang, "Tremblay", "Smith", "García")
            Case "phEmail" : Return Choose3(lang, "vous@exemple.com", "you@example.com", "usted@ejemplo.com")
            Case "email" : Return Choose3(lang, "Adresse courriel *", "Email address *", "Correo electrónico *")
            Case "password" : Return Choose3(lang, "Mot de passe *", "Password *", "Contraseña *")
            Case "passwordConfirm" : Return Choose3(lang, "Confirmer le mot de passe *", "Confirm password *", "Confirmar contraseña *")
            Case "pwHint" : Return Choose3(lang, "Minimum 8 caractères", "Minimum 8 characters", "Mínimo 8 caracteres")
            Case "strWeak" : Return Choose3(lang, "Très faible", "Very weak", "Muy débil")
            Case "strLow" : Return Choose3(lang, "Faible", "Weak", "Débil")
            Case "strGood" : Return Choose3(lang, "Bon", "Good", "Bueno")
            Case "strExcellent" : Return Choose3(lang, "Excellent", "Excellent", "Excelente")
            Case "termsBefore" : Return Choose3(lang, "J'accepte les ", "I accept the ", "Acepto los ")
            Case "termsCgu" : Return Choose3(lang, "Conditions d'utilisation", "Terms of Use", "Términos de uso")
            Case "termsMid" : Return Choose3(lang, " et la ", " and the ", " y la ")
            Case "termsPrivacy" : Return Choose3(lang, "Politique de confidentialité", "Privacy Policy", "Política de privacidad")
            Case "termsAfter" : Return Choose3(lang, " de 60Sec-AI.", " of 60Sec-AI.", " de 60Sec-AI.")
            Case "createAccount" : Return Choose3(lang, "Créer mon compte", "Create my account", "Crear mi cuenta")
            Case "already" : Return Choose3(lang, "Déjà un compte ?", "Already have an account?", "¿Ya tiene una cuenta?")
            Case "signin" : Return Choose3(lang, "Se connecter", "Sign in", "Iniciar sesión")
            Case "successTitle" : Return Choose3(lang, "Vérifiez votre courriel", "Check your email", "Revise su correo")
            Case "successIntro" : Return Choose3(lang, "Nous venons d'envoyer un lien d'activation à", "We just sent an activation link to", "Acabamos de enviar un enlace de activación a")
            Case "successBody" : Return Choose3(lang, "Cliquez sur le lien dans le courriel pour activer votre compte. Le lien est valide pendant 24 heures.", "Click the link in the email to activate your account. The link is valid for 24 hours.", "Haga clic en el enlace del correo para activar su cuenta. El enlace es válido durante 24 horas.")
            Case "resendPrompt" : Return Choose3(lang, "Vous n'avez rien reçu ? Vérifiez vos courriels indésirables ou", "Didn't receive anything? Check your spam folder or", "¿No recibió nada? Revise su correo no deseado o")
            Case "resendLink" : Return Choose3(lang, "renvoyer le lien", "resend the link", "reenviar el enlace")
            Case "closeBtn" : Return Choose3(lang, "Vous pouvez fermer cette page.", "You can close this page.", "Puede cerrar esta página.")
            Case "errEmailReq" : Return Choose3(lang, "Le courriel est obligatoire.", "Email is required.", "El correo es obligatorio.")
            Case "errEmailInvalid" : Return Choose3(lang, "Le courriel n'est pas valide.", "The email is not valid.", "El correo no es válido.")
            Case "errPwShort" : Return Choose3(lang, "Le mot de passe doit contenir au moins 8 caractères.", "The password must be at least 8 characters long.", "La contraseña debe tener al menos 8 caracteres.")
            Case "errPwMatch" : Return Choose3(lang, "Les mots de passe ne correspondent pas.", "The passwords do not match.", "Las contraseñas no coinciden.")
            Case "errTerms" : Return Choose3(lang, "Vous devez accepter les conditions d'utilisation.", "You must accept the terms of use.", "Debe aceptar los términos de uso.")
            Case "errEmailExists" : Return Choose3(lang, "Ce courriel est déjà utilisé.", "This email is already in use.", "Este correo ya está en uso.")
            Case "errRegister" : Return Choose3(lang, "Une erreur est survenue lors de l'inscription. Veuillez réessayer.", "An error occurred during registration. Please try again.", "Se produjo un error durante el registro. Inténtelo de nuevo.")
            Case "errException" : Return Choose3(lang, "Une erreur est survenue : ", "An error occurred: ", "Se produjo un error: ")
            Case "resendTooMany" : Return Choose3(lang, "Trop de tentatives. Réessayez dans 1 minute.", "Too many attempts. Try again in 1 minute.", "Demasiados intentos. Inténtelo en 1 minuto.")
            Case "resendSent" : Return Choose3(lang, "Courriel renvoyé à ", "Email resent to ", "Correo reenviado a ")
            Case "resendFail" : Return Choose3(lang, "Échec d'envoi. Réessayez dans quelques instants.", "Sending failed. Try again shortly.", "Error al enviar. Inténtelo en unos instantes.")
            Case "resendError" : Return Choose3(lang, "Une erreur est survenue. Réessayez dans quelques instants.", "An error occurred. Try again shortly.", "Se produjo un error. Inténtelo en unos instantes.")
            Case "mailSubject" : Return Choose3(lang, "Activez votre compte 60Sec-AI", "Activate your 60Sec-AI account", "Active su cuenta 60Sec-AI")
            Case "mailWelcome" : Return Choose3(lang, "Bienvenue chez 60Sec-AI", "Welcome to 60Sec-AI", "Bienvenido a 60Sec-AI")
            Case "mailIntro" : Return Choose3(lang, "Merci de vous être inscrit. Pour finaliser la création de votre compte, cliquez sur le bouton ci-dessous :", "Thank you for signing up. To complete your account setup, click the button below:", "Gracias por registrarse. Para completar la creación de su cuenta, haga clic en el botón de abajo:")
            Case "mailButton" : Return Choose3(lang, "Activer mon compte", "Activate my account", "Activar mi cuenta")
            Case "mailExpiry" : Return Choose3(lang, "Le lien est valide pendant 24 heures.", "This link is valid for 24 hours.", "El enlace es válido durante 24 horas.")
            Case "mailFallback" : Return Choose3(lang, "Si le bouton ne fonctionne pas, copiez ce lien dans votre navigateur :", "If the button doesn't work, copy this link into your browser:", "Si el botón no funciona, copie este enlace en su navegador:")
            Case "mailIgnore" : Return Choose3(lang, "Si vous n'avez pas créé de compte chez nous, ignorez ce courriel.", "If you didn't create an account with us, please ignore this email.", "Si no creó una cuenta con nosotros, ignore este correo.")
            Case Else : Return ""
        End Select
    End Function

    Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ApplyLocalization()
        ' Si déjà connecté, rediriger vers le dashboard

        'wbfRegister.aspx?ab= solo
        'wbfRegister.aspx?ab= comsolo
        'wbfRegister.aspx?ab= com119
        'Session.Clear()
        'Session.Abandon()

        Abonnement = Request.QueryString("ab")
        Dim ActiveToken As String = Request.QueryString("ac")



        If Not IsPostBack Then



            If Not ActiveToken Is Nothing AndAlso Guid.TryParse(ActiveToken, Nothing) Then
                ' Redirection depuis le lien d'activation
                ' Afficher la vue de succès
                pnlForm.Visible = False
                pnlSuccess.Visible = True
                Dim MyToken As Guid
                Guid.TryParse(ActiveToken, MyToken)

                Dim p As New Collection
                p.Add(New SqlClient.SqlParameter("@ActivationToken", MyToken))
                Dim ds As DataSet = ExecuteSQLds("s0256GetUserByActivationToken", p)

                ' Vérification défensive : si la SP retourne 0 row, ne pas crasher
                If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                    Dim userEmail As String = ds.Tables(0).Rows(0)("Email").ToString()

                    ' Stocker l'email pour le bouton "Renvoyer"
                    ViewState("RegisteredEmail") = userEmail

                    ' Afficher l'email dans le panneau de succès (FIX bug : était vide)
                    litSuccessEmail.Text = userEmail
                End If

            End If

        End If
        Dim planSuffix As String = If(Abonnement = "solo", " Solo", If(Abonnement = "comsolo", " ComSolo", If(Abonnement = "com119", " COM119", "")))
        btnRegister.Text = L("createAccount") & planSuffix

        If Not IsPostBack AndAlso UserId <> 0 Then
            Response.Redirect("~/Default.aspx")
        End If
    End Sub

    Protected Sub btnRegister_Click(sender As Object, e As EventArgs) Handles btnRegister.Click

        Dim email As String = If(tbEmail.Text, "").Trim().ToLower()
        Dim password As String = If(tbPassword.Text, "")
        Dim passwordConfirm As String = If(tbPasswordConfirm.Text, "")
        Dim firstName As String = If(tbFirstName.Text, "").Trim()
        Dim lastName As String = If(tbLastName.Text, "").Trim()

        ' === Validations ===
        If String.IsNullOrEmpty(email) Then
            ShowError(L("errEmailReq"))
            Return
        End If
        If Not email.Contains("@") OrElse Not email.Contains(".") Then
            ShowError(L("errEmailInvalid"))
            Return
        End If
        If password.Length < 8 Then
            ShowError(L("errPwShort"))
            Return
        End If
        If password <> passwordConfirm Then
            ShowError(L("errPwMatch"))
            Return
        End If
        If Not cbTerms.Checked Then
            ShowError(L("errTerms"))
            Return
        End If

        ' === Hash bcrypt ===
        Dim passwordHash As String = BCrypt.Net.BCrypt.HashPassword(password, 11)

        ' === Inscription via stored procedure ===
        Try

            Dim p As New Collection


            p.Add(New SqlClient.SqlParameter("@Email", email))
            p.Add(New SqlClient.SqlParameter("@PasswordHash", passwordHash))
            p.Add(New SqlClient.SqlParameter("@FirstName", If(String.IsNullOrEmpty(firstName), CObj(DBNull.Value), firstName)))
            p.Add(New SqlClient.SqlParameter("@LastName", If(String.IsNullOrEmpty(lastName), CObj(DBNull.Value), lastName)))
            p.Add(New SqlClient.SqlParameter("@CompanyName", DBNull.Value))
            p.Add(New SqlClient.SqlParameter("@Abonnement", Abonnement))
            Dim ds As DataSet = ExecuteSQLds("s0220RegisterUser", p)


            ' Erreur retournée par la procédure (ex: email déjà utilisé)
            If ds.Tables(0).Rows(0)("Errorcode") = 1 Then
                ShowError(L("errEmailExists"))
                Return
            End If

            If ds.Tables(0).Rows(0)("Errorcode") >= 10000 Then
                ShowError(L("errRegister"))
                Return
            End If

            Dim userId As Integer = ds.Tables(0).Rows(0)("NewUserId")
            Dim activationToken As Guid = ds.Tables(0).Rows(0)("activationToken")

            ' === Attribution de l'adresse courriel @60sec.ca de la compagnie (best-effort) ===
            ' Génère un slug du nom commercial, écrit T010Company.Sec60Email et enregistre
            ' l'adresse locale (SmtpLocalRecipient). Non bloquant : une erreur ici ne doit
            ' jamais faire échouer une inscription déjà réussie.
            Try
                If ds.Tables(0).Columns.Contains("NewCompanyGUID") _
                   AndAlso Not IsDBNull(ds.Tables(0).Rows(0)("NewCompanyGUID")) Then
                    Dim pm As New Collection
                    pm.Add(New SqlClient.SqlParameter("@CompanyGUID", CType(ds.Tables(0).Rows(0)("NewCompanyGUID"), Guid)))
                    ExecuteSQLds("s0712AssignMailbox", pm)
                End If
            Catch
            End Try

            ' === Envoi du courriel d'activation ===
            Dim emailSent = SendActivationEmail(email, firstName, activationToken)

            If Not emailSent Then
                ' L'inscription est faite mais le courriel n'a pas pu être envoyé
                ' On affiche quand même la confirmation, l'utilisateur pourra "renvoyer le lien"
                ' Vous pouvez aussi logger l'erreur côté serveur ici
            End If

            ' Afficher la vue de succès
            pnlForm.Visible = False
            pnlSuccess.Visible = True
            litSuccessEmail.Text = email

            ' Stocker l'email + prénom pour le bouton "Renvoyer"
            ViewState("RegisteredEmail") = email
            ViewState("RegisteredFirstName") = firstName


        Catch ex As Exception
            ShowError(L("errException") & ex.Message)
        End Try
    End Sub

    Protected Sub lnkResend_Click(sender As Object, e As EventArgs) Handles lnkResend.Click

        Dim email As String = If(ViewState("RegisteredEmail"), "").ToString()
        Dim firstName As String = If(ViewState("RegisteredFirstName"), "").ToString()
        If String.IsNullOrEmpty(email) Then Return

        Try
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@Email", email))

            Dim ds As DataSet = ExecuteSQLds("s0222ResendActivation", p)

            ' Protection contre les retours vides ou inattendus de la SP
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                System.Diagnostics.Debug.WriteLine("Resend: s0222ResendActivation n'a retourné aucune ligne pour " & email)
                ShowResendStatus(False, L("resendTooMany"))
                Return
            End If

            Dim newTokenObj As Object = ds.Tables(0).Rows(0)("NewToken")
            If newTokenObj Is Nothing OrElse IsDBNull(newTokenObj) Then
                ' Rate limited ou compte déjà activé
                ShowResendStatus(False, L("resendTooMany"))
                Return
            End If

            Dim newToken As Guid = CType(newTokenObj, Guid)
            Dim ok As Boolean = SendActivationEmail(email, firstName, newToken)
            If ok Then
                ShowResendStatus(True, L("resendSent") & email)
            Else
                ShowResendStatus(False, L("resendFail"))
                System.Diagnostics.Debug.WriteLine("Resend: SendActivationEmail a échoué pour " & email)
            End If

        Catch ex As Exception
            ShowResendStatus(False, L("resendError"))
            System.Diagnostics.Debug.WriteLine("Resend error pour " & email & " : " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Affiche un message de statut (succès vert / échec rouge) sous le lien Renvoyer.
    ''' </summary>
    Private Sub ShowResendStatus(success As Boolean, message As String)
        Dim color As String = If(success, "#10b981", "#ef4444")
        Dim icon As String = If(success, "&#10003;", "&#10007;")
        litResendStatus.Text = "<p style=""color:" & color & "; font-weight:700; margin-top:12px; font-size:13px;"">" & icon & " " & Server.HtmlEncode(message) & "</p>"
    End Sub

    ''' <summary>
    ''' Envoie le courriel d'activation en insérant dans T400Mails (BD MailService).
    ''' Le service Windows SrvAI poll cette table et envoie via SMTP.
    ''' Retourne True si l'insertion a réussi.
    ''' </summary>
    Private Function SendActivationEmail(email As String, firstName As String, token As Guid) As Boolean

        Dim baseUrl As String = Request.Url.GetLeftPart(UriPartial.Authority) &
                                ResolveUrl("~/wbfActivate.aspx")
        Dim activationLink As String = baseUrl & "?token=" & token.ToString("D") & "&lang=" & CurrentLang

        Dim greeting As String
        If String.IsNullOrEmpty(firstName) Then
            greeting = Choose3(CurrentLang, "Bonjour !", "Hello!", "¡Hola!")
        Else
            greeting = Choose3(CurrentLang, "Bonjour " & firstName & " !", "Hello " & firstName & "!", "¡Hola " & firstName & "!")
        End If

        Dim subject As String = L("mailSubject")
        Dim body As String = BuildEmailBody(greeting, activationLink)

        Try
            ' === INSERT DANS T400Mails (BD MailService via 2e connection string) ===
            ' Le service Windows SrvAI poll T400Mails et envoie via SMTP les rows
            ' avec ToSend = 1 et SendWithSuccess IS NULL.

            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@To", email))
            p.Add(New SqlClient.SqlParameter("@Subject", subject))
            p.Add(New SqlClient.SqlParameter("@HTMLBody", body))
            p.Add(New SqlClient.SqlParameter("@TextBody", DBNull.Value))

            ExecuteSQLMail("s0610InsertOutboundMail", p)

            Return True
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Email error: " & ex.Message)
            Return False
        End Try
    End Function

    Private Function BuildEmailBody(greeting As String, activationLink As String) As String
        Dim sb As New System.Text.StringBuilder()
        sb.AppendLine("<!DOCTYPE html>")
        sb.AppendLine("<html><body style=""font-family: Arial, sans-serif; background:#f6f7fb; margin:0; padding:20px;"">")
        sb.AppendLine("<div style=""max-width:560px; margin:0 auto; background:#fff; border-radius:16px; overflow:hidden; box-shadow:0 8px 24px rgba(0,0,0,.06);"">")
        sb.AppendLine("<div style=""background: linear-gradient(135deg,#2563eb,#06b6d4); padding:32px; text-align:center;"">")
        sb.AppendLine("<h1 style=""color:#fff; margin:0; font-size:24px; font-weight:800;"">60Sec-AI</h1>")
        sb.AppendLine("<p style=""color:#e0f2fe; margin:6px 0 0 0; font-size:15px;"">" & L("mailWelcome") & "</p>")
        sb.AppendLine("</div>")
        sb.AppendLine("<div style=""padding:32px; color:#0f172a;"">")
        sb.AppendLine("<p style=""font-size:16px;"">" & greeting & "</p>")
        sb.AppendLine("<p>" & L("mailIntro") & "</p>")
        sb.AppendLine("<div style=""text-align:center; margin:28px 0;"">")
        sb.AppendLine("<a href=""" & activationLink & """  target=""_blank""   style=""display:inline-block; background: linear-gradient(135deg,#2563eb,#06b6d4); color:#fff; padding:14px 32px; border-radius:12px; text-decoration:none; font-weight:800; font-size:15px;"">" & L("mailButton") & "</a>")
        sb.AppendLine("</div>")
        sb.AppendLine("<p style=""font-size:13px; color:#64748b;"">" & L("mailExpiry") & "</p>")
        sb.AppendLine("<p style=""font-size:13px; color:#64748b;"">" & L("mailFallback") & "<br/>")
        sb.AppendLine("<span style=""word-break:break-all; color:#2563eb;"">" & activationLink & "</span></p>")
        sb.AppendLine("<hr style=""border:none; border-top:1px solid #e2e8f0; margin:24px 0;"" />")
        sb.AppendLine("<p style=""font-size:12px; color:#94a3b8;"">" & L("mailIgnore") & "</p>")
        sb.AppendLine("</div>")
        sb.AppendLine("</div></body></html>")
        Return sb.ToString()
    End Function



    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

    Private Sub btnFerme_Click(sender As Object, e As EventArgs) Handles btnFerme.Click
        Session.Clear()
        Session.Abandon()

        Response.Redirect("~/LandingPage.aspx")
    End Sub
End Class
