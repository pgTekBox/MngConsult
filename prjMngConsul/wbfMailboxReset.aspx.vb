Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net

''' <summary>
''' Page PUBLIQUE (sans authentification) : un employé définit le mot de passe
''' de sa boîte @60sec.ca via le lien reçu à son courriel externe.
'''   ?token=&lt;GUID&gt;  -> validé par s0725GetEmployeeByMailResetToken
''' Le mot de passe est posé dans MailService.SmtpLocalRecipient (s0629), puis le
''' jeton est effacé (s0726).
''' </summary>
Public Class wbfMailboxReset
    Inherits clsData

    Private _box As String = ""
    Private _name As String = ""
    Private _validToken As Boolean = False

    Private ReadOnly Property TokenRaw As String
        Get
            Return If(Request.QueryString("token"), "")
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        btnSet.Text = L("set")
        ValidateToken()

        If Not _validToken Then
            pnlForm.Visible = False
            pnlInvalid.Visible = True
            Return
        End If

        If Not IsPostBack Then
            litIntro.Text = String.Format(Server.HtmlEncode(L("intro")), "<span class=""mono"">" & Server.HtmlEncode(_box) & "</span>")
        End If
    End Sub

    Private Sub ValidateToken()
        Dim g As Guid
        If Not Guid.TryParse(TokenRaw, g) Then Return
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Token", g))
            Dim ds As DataSet = ExecuteSQLds("s0725GetEmployeeByMailResetToken", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r = ds.Tables(0).Rows(0)
                _box = If(IsDBNull(r("Sec60Email")), "", r("Sec60Email").ToString())
                _name = If(IsDBNull(r("FullName")), "", r("FullName").ToString())
                _validToken = (_box <> "")
            End If
        Catch
        End Try
    End Sub

    Private Sub btnSet_Click(sender As Object, e As EventArgs) Handles btnSet.Click
        If Not _validToken Then
            pnlForm.Visible = False : pnlInvalid.Visible = True : Return
        End If

        Dim pwd As String = txtPwd.Text
        Dim pwd2 As String = txtPwd2.Text

        If pwd Is Nothing OrElse pwd.Length < 6 Then
            ShowErr(L("errShort")) : Return
        End If
        If pwd <> pwd2 Then
            ShowErr(L("errMatch")) : Return
        End If

        Try
            Dim hash As String = BCrypt.Net.BCrypt.HashPassword(pwd, 11)

            ' 1) poser le mot de passe sur la boîte locale (MailService)
            Dim pm As New Collection
            pm.Add(New SqlParameter("@Email", _box))
            pm.Add(New SqlParameter("@PasswordHash", hash))
            ExecuteSQLMail("s0629SetLocalRecipientPassword", pm)

            ' 2) invalider le jeton (MngConsul)
            Dim g As Guid = Guid.Parse(TokenRaw)
            Dim pc As New Collection
            pc.Add(New SqlParameter("@Token", g))
            ExecuteSQL("s0726ClearEmployeeMailReset", pc)

            pnlForm.Visible = False
            pnlInvalid.Visible = False
            pnlDone.Visible = True
            litDone.Text = String.Format(Server.HtmlEncode(L("doneMsg")), "<span class=""mono"">" & Server.HtmlEncode(_box) & "</span>")
        Catch ex As Exception
            ShowErr(L("errSave") & ex.Message)
        End Try
    End Sub

    Private Sub ShowErr(msg As String)
        pnlErr.Visible = True
        litErr.Text = Server.HtmlEncode(msg)
    End Sub

    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "title" : Return Choose3(lang, "Définir le mot de passe de votre boîte", "Set your mailbox password", "Establecer la contraseña de su buzón")
            Case "intro" : Return Choose3(lang, "Choisissez un mot de passe pour votre boîte de courriel {0}.", "Choose a password for your mailbox {0}.", "Elija una contraseña para su buzón {0}.")
            Case "pwd" : Return Choose3(lang, "Nouveau mot de passe", "New password", "Nueva contraseña")
            Case "pwd2" : Return Choose3(lang, "Confirmer le mot de passe", "Confirm password", "Confirmar contraseña")
            Case "rule" : Return Choose3(lang, "Au moins 6 caractères.", "At least 6 characters.", "Al menos 6 caracteres.")
            Case "set" : Return Choose3(lang, "Définir le mot de passe", "Set password", "Establecer contraseña")
            Case "errShort" : Return Choose3(lang, "Le mot de passe doit contenir au moins 6 caractères.", "Password must be at least 6 characters.", "La contraseña debe tener al menos 6 caracteres.")
            Case "errMatch" : Return Choose3(lang, "Les deux mots de passe ne correspondent pas.", "The two passwords do not match.", "Las dos contraseñas no coinciden.")
            Case "errSave" : Return Choose3(lang, "Erreur : ", "Error: ", "Error: ")
            Case "invalidTitle" : Return Choose3(lang, "Lien invalide ou expiré", "Invalid or expired link", "Enlace inválido o caducado")
            Case "invalidBody" : Return Choose3(lang, "Ce lien de réinitialisation n'est plus valide. Demandez-en un nouveau à votre gestionnaire.", "This reset link is no longer valid. Ask your manager for a new one.", "Este enlace ya no es válido. Solicite uno nuevo a su gerente.")
            Case "doneTitle" : Return Choose3(lang, "Mot de passe défini", "Password set", "Contraseña establecida")
            Case "doneMsg" : Return Choose3(lang, "Le mot de passe de la boîte {0} a été enregistré.", "The password for mailbox {0} has been saved.", "La contraseña del buzón {0} se ha guardado.")
            Case "doneHint" : Return Choose3(lang, "Vous pouvez maintenant configurer votre appareil (IMAP/SMTP) avec ce mot de passe.", "You can now set up your device (IMAP/SMTP) with this password.", "Ahora puede configurar su dispositivo (IMAP/SMTP) con esta contraseña.")
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

End Class
