Imports System.Data
Imports System.Data.SqlClient

Public Class wbfForgotPassword
    Inherits clsData

    ' Durée de validité du lien de réinitialisation (minutes).
    Private Const RESET_EXPIRES_MINUTES As Integer = 60

    ''' <summary>
    ''' Langue courante : ?lang=fr|en|es (défaut fr). Transmise depuis le login
    ''' et conservée sur les liens et le courriel de réinitialisation.
    ''' </summary>

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Page.Title = L("pageTitle")
        btnSend.Text = L("send")
        tbEmail.Attributes("placeholder") = L("emailPh")
    End Sub

    ''' <summary>
    ''' Génère un jeton de réinitialisation et envoie le courriel. Pour ne pas
    ''' révéler l'existence d'un compte, le même message générique est affiché
    ''' que le courriel existe ou non.
    ''' </summary>
    Protected Sub btnSend_Click(sender As Object, e As EventArgs) Handles btnSend.Click

        Dim email As String = If(tbEmail.Text, "").Trim().ToLower()

        If String.IsNullOrEmpty(email) OrElse Not email.Contains("@") OrElse Not email.Contains(".") Then
            ShowError(L("errEmail"))
            Return
        End If

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Email", email))
            p.Add(New SqlParameter("@ExpiresMinutes", RESET_EXPIRES_MINUTES))
            Dim ds As DataSet = ExecuteSQLds("s0679CreateUserResetToken", p)

            ' Si un compte actif existe, la SP retourne (Token, Email, FirstName).
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim token As Guid = CType(ds.Tables(0).Rows(0)("Token"), Guid)
                Dim firstName As String = If(IsDBNull(ds.Tables(0).Rows(0)("FirstName")), "", ds.Tables(0).Rows(0)("FirstName").ToString())
                ' T389 : le lien part au courriel de récupération quand il existe (une boîte
                ' @60sec.ca partage le mot de passe oublié et n'est donc pas lisible).
                Dim dest As String = email
                If ds.Tables(0).Columns.Contains("RecoveryEmail") AndAlso Not IsDBNull(ds.Tables(0).Rows(0)("RecoveryEmail")) Then
                    Dim recup As String = ds.Tables(0).Rows(0)("RecoveryEmail").ToString().Trim()
                    If recup <> "" Then dest = recup
                End If
                SendResetEmail(dest, firstName, token)
            End If

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ForgotPassword error: " & ex.Message)
        End Try

        ' Message générique dans tous les cas (sécurité : ne pas révéler l'existence du compte).
        pnlForm.Visible = False
        pnlSent.Visible = True
    End Sub

    ''' <summary>
    ''' Envoie le courriel de réinitialisation en insérant dans T400Mails
    ''' (BD MailService). Le service Windows SrvAI poll cette table et envoie via SMTP.
    ''' </summary>
    Private Function SendResetEmail(email As String, firstName As String, token As Guid) As Boolean

        Dim baseUrl As String = Request.Url.GetLeftPart(UriPartial.Authority) &
                                ResolveUrl("~/wbfResetPassword.aspx")
        Dim resetLink As String = baseUrl & "?token=" & token.ToString("D") & "&lang=" & CurrentLang

        Dim greeting As String
        If String.IsNullOrEmpty(firstName) Then
            greeting = Choose3(CurrentLang, "Bonjour !", "Hello!", "¡Hola!")
        Else
            greeting = Choose3(CurrentLang, "Bonjour " & firstName & " !", "Hello " & firstName & "!", "¡Hola " & firstName & "!")
        End If

        Dim subject As String = L("mailSubject")
        Dim body As String = BuildEmailBody(greeting, resetLink)

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@To", email))
            p.Add(New SqlParameter("@Subject", subject))
            p.Add(New SqlParameter("@HTMLBody", body))
            p.Add(New SqlParameter("@TextBody", DBNull.Value))

            ExecuteSQLMail("s0610InsertOutboundMail", p)
            Return True
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Reset email error: " & ex.Message)
            Return False
        End Try
    End Function

    Private Function BuildEmailBody(greeting As String, resetLink As String) As String
        ' Gabarit commun des courriels de compte (App_Code/clsCourrielModele.vb)
        Return clsCourrielModele.Construire(CurrentLang, L("mailIntro"),
                                            Choose3(CurrentLang, "Réinitialisation de votre mot de passe", "Reset your password", "Restablecimiento de su contraseña"),
                                            greeting, {L("mailIntro")}, L("mailButton"), resetLink,
                                            L("mailExpiry") & " " & Choose3(CurrentLang, "60Sec-AI ne vous demandera jamais votre mot de passe par courriel.", "60Sec-AI will never ask for your password by email.", "60Sec-AI nunca le pedirá su contraseña por correo."),
                                            L("mailIgnore"))
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

    ''' <summary>
    ''' Traductions de l'interface « mot de passe oublié » (fr/en/es).
    ''' </summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle"
                Return Choose3(lang, "Mot de passe oublié — 60Sec-AI", "Forgot password — 60Sec-AI", "Contraseña olvidada — 60Sec-AI")
            Case "heading"
                Return Choose3(lang, "Mot de passe oublié ?", "Forgot your password?", "¿Olvidó su contraseña?")
            Case "subtitle"
                Return Choose3(lang, "Entrez votre courriel et nous vous enverrons un lien de réinitialisation.", "Enter your email and we'll send you a reset link.", "Introduzca su correo y le enviaremos un enlace de restablecimiento.")
            Case "email"
                Return Choose3(lang, "Courriel", "Email", "Correo electrónico")
            Case "emailPh"
                Return Choose3(lang, "vous@exemple.com", "you@example.com", "usted@ejemplo.com")
            Case "send"
                Return Choose3(lang, "Envoyer le lien", "Send the link", "Enviar el enlace")
            Case "sent"
                Return Choose3(lang, "Si un compte est associé à ce courriel, un lien de réinitialisation vient d'être envoyé. Vérifiez votre boîte de réception.", "If an account matches this email, a reset link has just been sent. Please check your inbox.", "Si existe una cuenta con este correo, se acaba de enviar un enlace de restablecimiento. Revise su bandeja de entrada.")
            Case "backToLogin"
                Return Choose3(lang, "← Retour à la connexion", "← Back to login", "← Volver al inicio de sesión")
            Case "errEmail"
                Return Choose3(lang, "Veuillez entrer un courriel valide.", "Please enter a valid email.", "Introduzca un correo electrónico válido.")
            Case "footer"
                Return Choose3(lang, "© 2026 60Sec-AI — Tous droits réservés", "© 2026 60Sec-AI — All rights reserved", "© 2026 60Sec-AI — Todos los derechos reservados")
            Case "mailSubject"
                Return Choose3(lang, "Réinitialisation de votre mot de passe 60Sec-AI", "Reset your 60Sec-AI password", "Restablecimiento de su contraseña 60Sec-AI")
            Case "mailIntro"
                Return Choose3(lang, "Vous avez demandé la réinitialisation de votre mot de passe. Cliquez sur le bouton ci-dessous pour en choisir un nouveau :", "You requested to reset your password. Click the button below to choose a new one:", "Ha solicitado restablecer su contraseña. Haga clic en el botón de abajo para elegir una nueva:")
            Case "mailButton"
                Return Choose3(lang, "Réinitialiser mon mot de passe", "Reset my password", "Restablecer mi contraseña")
            Case "mailExpiry"
                Return Choose3(lang, "Le lien est valide pendant 60 minutes.", "This link is valid for 60 minutes.", "El enlace es válido durante 60 minutos.")
            Case "mailFallback"
                Return Choose3(lang, "Si le bouton ne fonctionne pas, copiez ce lien dans votre navigateur :", "If the button doesn't work, copy this link into your browser:", "Si el botón no funciona, copie este enlace en su navegador:")
            Case "mailIgnore"
                Return Choose3(lang, "Si vous n'avez pas demandé cette réinitialisation, ignorez ce courriel.", "If you didn't request this reset, please ignore this email.", "Si no solicitó este restablecimiento, ignore este correo.")
            Case Else
                Return ""
        End Select
    End Function

    Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

End Class
