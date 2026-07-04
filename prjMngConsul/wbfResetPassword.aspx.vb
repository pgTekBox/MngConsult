Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net

Public Class wbfResetPassword
    Inherits clsData

    ''' <summary>
    ''' Langue courante : ?lang=fr|en|es (défaut fr). Transmise par le lien du
    ''' courriel de réinitialisation et conservée au postback.
    ''' </summary>
    Protected ReadOnly Property CurrentLang As String
        Get
            Dim l As String = If(Request.QueryString("lang"), "").Trim().ToLowerInvariant()
            Select Case l
                Case "en", "es", "fr"
                    Return l
                Case Else
                    Return "fr"
            End Select
        End Get
    End Property

    ''' <summary>
    ''' Jeton passé dans le query string (?token=). Guid.Empty si absent/invalide.
    ''' Le query string est conservé au postback (form action inchangée).
    ''' </summary>
    Private ReadOnly Property Token As Guid
        Get
            Dim t As Guid
            If Guid.TryParse(If(Request.QueryString("token"), ""), t) Then Return t
            Return Guid.Empty
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Page.Title = L("pageTitle")
        btnReset.Text = L("reset")
        tbPassword.Attributes("placeholder") = "••••••••"
        tbPasswordConfirm.Attributes("placeholder") = "••••••••"

        If Not IsPostBack Then
            ' Valide le jeton dès l'arrivée : formulaire si valide, sinon message d'erreur.
            If Token = Guid.Empty OrElse Not IsTokenValid(Token) Then
                ShowInvalid()
            End If
        End If
    End Sub

    ''' <summary>
    ''' Vérifie que le jeton existe, n'est pas expiré et cible un compte actif.
    ''' </summary>
    Private Function IsTokenValid(t As Guid) As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Token", t))
            Dim ds As DataSet = ExecuteSQLds("s0680GetUserByResetToken", p)
            Return ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ResetPassword validate error: " & ex.Message)
            Return False
        End Try
    End Function

    Protected Sub btnReset_Click(sender As Object, e As EventArgs) Handles btnReset.Click

        Dim password As String = If(tbPassword.Text, "")
        Dim passwordConfirm As String = If(tbPasswordConfirm.Text, "")

        If Token = Guid.Empty Then
            ShowInvalid()
            Return
        End If

        ' === Validations ===
        If password.Length < 8 Then
            ShowError(L("errShort"))
            Return
        End If
        If password <> passwordConfirm Then
            ShowError(L("errMatch"))
            Return
        End If

        Try
            Dim passwordHash As String = BCrypt.Net.BCrypt.HashPassword(password, 11)

            Dim p As New Collection
            p.Add(New SqlParameter("@Token", Token))
            p.Add(New SqlParameter("@PasswordHash", passwordHash))
            Dim ds As DataSet = ExecuteSQLds("s0681ResetUserPasswordByToken", p)

            Dim affected As Integer = 0
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                affected = Convert.ToInt32(ds.Tables(0).Rows(0)("Affected"))
            End If

            If affected = 1 Then
                ' Succès : masquer le formulaire, montrer la confirmation.
                pnlForm.Visible = False
                pnlInvalid.Visible = False
                pnlError.Visible = False
                pnlSuccess.Visible = True
            Else
                ' Jeton expiré ou déjà consommé entre-temps.
                ShowInvalid()
            End If

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ResetPassword error: " & ex.Message)
            ShowError(L("errGeneric"))
        End Try
    End Sub

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

    Private Sub ShowInvalid()
        pnlForm.Visible = False
        pnlSuccess.Visible = False
        pnlError.Visible = False
        pnlInvalid.Visible = True
    End Sub

    ''' <summary>
    ''' Traductions de l'interface de réinitialisation (fr/en/es).
    ''' </summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle"
                Return Choose3(lang, "Réinitialiser le mot de passe — 60Sec-AI", "Reset password — 60Sec-AI", "Restablecer contraseña — 60Sec-AI")
            Case "heading"
                Return Choose3(lang, "Nouveau mot de passe", "New password", "Nueva contraseña")
            Case "subtitle"
                Return Choose3(lang, "Choisissez un nouveau mot de passe pour votre compte.", "Choose a new password for your account.", "Elija una nueva contraseña para su cuenta.")
            Case "newPassword"
                Return Choose3(lang, "Nouveau mot de passe", "New password", "Nueva contraseña")
            Case "confirmPassword"
                Return Choose3(lang, "Confirmer le mot de passe", "Confirm password", "Confirmar contraseña")
            Case "reset"
                Return Choose3(lang, "Réinitialiser mon mot de passe", "Reset my password", "Restablecer mi contraseña")
            Case "success"
                Return Choose3(lang, "Votre mot de passe a été réinitialisé. Vous pouvez maintenant vous connecter.", "Your password has been reset. You can now sign in.", "Su contraseña ha sido restablecida. Ahora puede iniciar sesión.")
            Case "goToLogin"
                Return Choose3(lang, "Se connecter", "Sign in", "Iniciar sesión")
            Case "invalid"
                Return Choose3(lang, "Ce lien de réinitialisation est invalide ou a expiré.", "This reset link is invalid or has expired.", "Este enlace de restablecimiento no es válido o ha expirado.")
            Case "requestNew"
                Return Choose3(lang, "Demander un nouveau lien", "Request a new link", "Solicitar un nuevo enlace")
            Case "errShort"
                Return Choose3(lang, "Le mot de passe doit contenir au moins 8 caractères.", "The password must be at least 8 characters long.", "La contraseña debe tener al menos 8 caracteres.")
            Case "errMatch"
                Return Choose3(lang, "Les mots de passe ne correspondent pas.", "The passwords do not match.", "Las contraseñas no coinciden.")
            Case "errGeneric"
                Return Choose3(lang, "Une erreur est survenue. Veuillez réessayer.", "An error occurred. Please try again.", "Se produjo un error. Inténtelo de nuevo.")
            Case "footer"
                Return Choose3(lang, "© 2026 60Sec-AI — Tous droits réservés", "© 2026 60Sec-AI — All rights reserved", "© 2026 60Sec-AI — Todos los derechos reservados")
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
