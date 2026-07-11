Imports System.Data
Imports System.Data.SqlClient

Public Class wbfActivate
    Inherits clsData

    ''' <summary>Applique la langue aux textes des liens (contrôles serveur) et au titre.</summary>
    Private Sub ApplyLocalization()
        Page.Title = L("pageTitle")
        lnkContinue.Text = L("continueBtn")
        lnkContinue.NavigateUrl = "~/wbfPayment.aspx?lang=" & CurrentLang
        lnkResend.Text = L("restartBtn")
        lnkResend.NavigateUrl = "~/wbfRegister.aspx?lang=" & CurrentLang
        lnkLoginInvalid.Text = L("signinBtn")
        lnkLoginInvalid.NavigateUrl = "~/wbfLogin.aspx?lang=" & CurrentLang
        lnkRegInvalid.Text = L("registerBtn")
        lnkRegInvalid.NavigateUrl = "~/wbfRegister.aspx?lang=" & CurrentLang
        lnkLoginAlready.Text = L("signinBtn")
        lnkLoginAlready.NavigateUrl = "~/wbfLogin.aspx?lang=" & CurrentLang
    End Sub

    ''' <summary>Traductions de la page d'activation (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Activation — 60Sec-AI", "Activation — 60Sec-AI", "Activación — 60Sec-AI")
            Case "successTitle" : Return Choose3(lang, "Compte activé !", "Account activated!", "¡Cuenta activada!")
            Case "successBefore" : Return Choose3(lang, "Votre compte est maintenant actif. Bienvenue chez 60Sec-AI, ", "Your account is now active. Welcome to 60Sec-AI, ", "Su cuenta ya está activa. Bienvenido a 60Sec-AI, ")
            Case "successAfter" : Return Choose3(lang, " !", "!", ".")
            Case "continueBtn" : Return Choose3(lang, "Continuer →", "Continue →", "Continuar →")
            Case "expiredTitle" : Return Choose3(lang, "Lien expiré", "Link expired", "Enlace caducado")
            Case "expiredMsg" : Return Choose3(lang, "Ce lien d'activation a expiré (durée maximale : 24 heures). Demandez un nouveau lien pour activer votre compte.", "This activation link has expired (maximum 24 hours). Request a new link to activate your account.", "Este enlace de activación ha caducado (máximo 24 horas). Solicite un nuevo enlace para activar su cuenta.")
            Case "restartBtn" : Return Choose3(lang, "Recommencer l'inscription", "Start registration again", "Reiniciar el registro")
            Case "invalidTitle" : Return Choose3(lang, "Lien invalide", "Invalid link", "Enlace no válido")
            Case "invalidMsg" : Return Choose3(lang, "Ce lien n'est pas valide ou a déjà été utilisé. Si vous avez déjà activé votre compte, vous pouvez vous connecter directement.", "This link is not valid or has already been used. If you have already activated your account, you can sign in directly.", "Este enlace no es válido o ya se ha utilizado. Si ya ha activado su cuenta, puede iniciar sesión directamente.")
            Case "signinBtn" : Return Choose3(lang, "Se connecter", "Sign in", "Iniciar sesión")
            Case "registerBtn" : Return Choose3(lang, "S'inscrire", "Sign up", "Registrarse")
            Case "alreadyTitle" : Return Choose3(lang, "Compte déjà activé", "Account already activated", "Cuenta ya activada")
            Case "alreadyMsg" : Return Choose3(lang, "Votre compte est déjà actif. Vous pouvez vous connecter dès maintenant.", "Your account is already active. You can sign in right now.", "Su cuenta ya está activa. Puede iniciar sesión ahora mismo.")
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

        If IsPostBack Then Return

        Dim tokenStr As String = Request.QueryString("token")
        Dim token As Guid

        If String.IsNullOrEmpty(tokenStr) OrElse Not Guid.TryParse(tokenStr, token) Then
            ShowInvalid()
            Return
        End If

        ActivateAccount(token)
    End Sub

    Private Sub ActivateAccount(token As Guid)

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Token", token))

            Dim ds As DataSet = ExecuteSQLds("s0221ActivateUser", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ShowInvalid()
                Return
            End If

            Dim r As DataRow = ds.Tables(0).Rows(0)

            Dim result As Integer = If(r("Result") Is DBNull.Value, 0, CInt(r("Result")))

            Select Case result

                Case 1   ' Activation OK
                    UserId = CInt(r("UserId"))
                    UserEmail = If(r("Email") Is DBNull.Value, "", r("Email").ToString())
                    Company = CType(r("CompanyGUID"), Guid)

                    LoadUserSession(UserId)

                    litEmail.Text = UserEmail
                    ShowSuccess()

                Case -1
                    ShowExpired()

                Case -2
                    ShowAlreadyActivated()

                Case Else
                    ShowInvalid()
            End Select

        Catch
            ShowInvalid()
        End Try
    End Sub

    ''' <summary>
    ''' Charge les infos du user dans la session (auto-login après activation).
    ''' Utilise la stored procedure s0223GetUserSessionInfo.
    ''' </summary>
    Private Sub LoadUserSession(userId As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", userId))

            Dim ds As DataSet = ExecuteSQLds("s0223GetUserSessionInfo", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                Return
            End If

            Dim r As DataRow = ds.Tables(0).Rows(0)


            UserFirstName = If(r("FirstName") Is DBNull.Value, "", r("FirstName").ToString())
            UserLastName = If(r("LastName") Is DBNull.Value, "", r("LastName").ToString())
            isAdmin  = (Not r("IsAdmin") Is DBNull.Value) AndAlso CBool(r("IsAdmin"))
            IsAccountant = (Not r("IsAccountant") Is DBNull.Value) AndAlso CBool(r("IsAccountant"))
            Company = CType(r("CompanyGUID"), Guid)
            CompanyName = If(r("CompanyName") Is DBNull.Value, "", r("CompanyName").ToString())

        Catch
            ' Si le chargement échoue, l'utilisateur devra se connecter manuellement
        End Try
    End Sub

    Private Sub ShowSuccess()
        pnlSuccess.Visible = True
    End Sub

    Private Sub ShowExpired()
        pnlExpired.Visible = True
    End Sub

    Private Sub ShowAlreadyActivated()
        pnlAlready.Visible = True
    End Sub

    Private Sub ShowInvalid()
        pnlInvalid.Visible = True
    End Sub

End Class
