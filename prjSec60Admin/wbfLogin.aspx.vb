Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Security
Imports BCrypt.Net

Public Class wbfLogin
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        ' Toute ouverture (GET) de la page de login déconnecte la session courante.
        ' On ne le fait pas sur les postbacks (connexion, mot de passe oublié).
        If Not IsPostBack Then
            FormsAuthentication.SignOut()
            Session.Clear()
        End If
    End Sub

    ' ====================== CONNEXION ======================
    Private Sub btnLogin_Click(sender As Object, e As EventArgs) Handles btnLogin.Click

        Dim email As String = txtEmail.Text.Trim().ToLower()
        Dim password As String = txtPassword.Text

        If String.IsNullOrEmpty(email) OrElse String.IsNullOrEmpty(password) Then
            ShowMsg("Veuillez saisir votre courriel et votre mot de passe.", True)
            Return
        End If

        Dim r As DataRow = GetAdminByEmail(email)
        If r Is Nothing Then
            ShowMsg("Courriel ou mot de passe invalide.", True) : Return
        End If

        Dim isActive As Boolean = (Not r("IsActive") Is DBNull.Value) AndAlso CBool(r("IsActive"))
        If Not isActive Then
            ShowMsg("Ce compte est désactivé.", True) : Return
        End If

        Dim hash As String = If(r("PasswordHash") Is DBNull.Value, "", r("PasswordHash").ToString())
        Dim ok As Boolean = False
        Try
            ok = (hash.Length > 0) AndAlso BCrypt.Net.BCrypt.Verify(password, hash)
        Catch
            ok = False
        End Try

        If Not ok Then
            ShowMsg("Courriel ou mot de passe invalide.", True) : Return
        End If

        ' === Connexion réussie ===
        AdminId = CInt(r("Id"))
        AdminEmail = r("Email").ToString()

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", AdminId))
            ExecuteSQL("s0641TouchAdminLastLogin", p)
        Catch
        End Try

        FormsAuthentication.SetAuthCookie(AdminEmail, False)
        Response.Redirect(ResolveReturnUrl())
    End Sub

    ' ====================== MOT DE PASSE OUBLIÉ ======================
    Private Sub lnkForgot_Click(sender As Object, e As EventArgs) Handles lnkForgot.Click
        pnlLogin.Visible = False
        pnlForgot.Visible = True
        pnlMsg.Visible = False
    End Sub

    Private Sub lnkBackToLogin_Click(sender As Object, e As EventArgs) Handles lnkBackToLogin.Click
        pnlForgot.Visible = False
        pnlLogin.Visible = True
        pnlMsg.Visible = False
    End Sub

    Private Sub btnSendReset_Click(sender As Object, e As EventArgs) Handles btnSendReset.Click

        ' On reste sur le panneau "oublié"
        pnlLogin.Visible = False
        pnlForgot.Visible = True

        Dim email As String = txtForgotEmail.Text.Trim().ToLower()
        If String.IsNullOrEmpty(email) OrElse Not email.Contains("@") Then
            ShowMsg("Veuillez saisir un courriel valide.", True)
            Return
        End If

        Try
            ' 1) Générer le jeton (uniquement si un compte actif existe)
            Dim token As String = ""
            Dim firstName As String = ""
            Dim p As New Collection
            p.Add(New SqlParameter("@Email", email))
            p.Add(New SqlParameter("@ExpiresMinutes", 60))
            Dim ds As DataSet = ExecuteSQLds("s0650CreateAdminResetToken", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim row As DataRow = ds.Tables(0).Rows(0)
                token = row("Token").ToString()
                firstName = If(row("FirstName") Is DBNull.Value, "", row("FirstName").ToString())
            End If

            ' 2) Si un jeton a été créé, envoyer le courriel
            If token.Length > 0 Then
                SendResetEmail(email, firstName, token)
            End If

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Reset error: " & ex.Message)
        End Try

        ' Message générique (ne révèle pas si le compte existe)
        ShowMsg("Si un compte existe pour ce courriel, un lien de réinitialisation a été envoyé.", False)
    End Sub

    ''' <summary>Insère le courriel de réinitialisation dans la file MailService (T400Mails).</summary>
    Private Sub SendResetEmail(email As String, firstName As String, token As String)
        Dim baseUrl As String = Request.Url.GetLeftPart(UriPartial.Authority) & ResolveUrl("~/wbfResetPassword.aspx")
        Dim resetLink As String = baseUrl & "?token=" & token

        Dim greeting As String = If(String.IsNullOrEmpty(firstName), "Bonjour,", "Bonjour " & firstName & ",")
        Dim subject As String = "Réinitialisation de votre mot de passe — Sec60Admin"
        Dim body As String = BuildResetEmailBody(greeting, resetLink)

        Dim p As New Collection
        p.Add(New SqlParameter("@To", email))
        p.Add(New SqlParameter("@Subject", subject))
        p.Add(New SqlParameter("@HTMLBody", body))
        p.Add(New SqlParameter("@TextBody", DBNull.Value))
        ExecuteSQLMail("s0610InsertOutboundMail", p)
    End Sub

    Private Function BuildResetEmailBody(greeting As String, resetLink As String) As String
        Dim sb As New System.Text.StringBuilder()
        sb.AppendLine("<!DOCTYPE html>")
        sb.AppendLine("<html><body style=""font-family:Arial,sans-serif; background:#f6f7fb; margin:0; padding:20px;"">")
        sb.AppendLine("<div style=""max-width:560px; margin:0 auto; background:#fff; border-radius:16px; overflow:hidden; box-shadow:0 8px 24px rgba(0,0,0,.06);"">")
        sb.AppendLine("<div style=""background:linear-gradient(135deg,#2563eb,#06b6d4); padding:32px; text-align:center;"">")
        sb.AppendLine("<h1 style=""color:#fff; margin:0; font-size:22px;"">Sec60Admin</h1></div>")
        sb.AppendLine("<div style=""padding:32px; color:#0f172a;"">")
        sb.AppendLine("<p style=""font-size:16px;"">" & greeting & "</p>")
        sb.AppendLine("<p>Vous avez demandé la réinitialisation de votre mot de passe. Cliquez sur le bouton ci-dessous pour en choisir un nouveau :</p>")
        sb.AppendLine("<div style=""text-align:center; margin:28px 0;"">")
        sb.AppendLine("<a href=""" & resetLink & """ target=""_blank"" style=""display:inline-block; background:linear-gradient(135deg,#2563eb,#06b6d4); color:#fff; padding:14px 32px; border-radius:12px; text-decoration:none; font-weight:800; font-size:15px;"">Réinitialiser mon mot de passe</a></div>")
        sb.AppendLine("<p style=""font-size:13px; color:#64748b;"">Ce lien est valide pendant <strong>60 minutes</strong>.</p>")
        sb.AppendLine("<p style=""font-size:13px; color:#64748b;"">Si le bouton ne fonctionne pas, copiez ce lien :<br/>")
        sb.AppendLine("<span style=""word-break:break-all; color:#2563eb;"">" & resetLink & "</span></p>")
        sb.AppendLine("<hr style=""border:none; border-top:1px solid #e2e8f0; margin:24px 0;"" />")
        sb.AppendLine("<p style=""font-size:12px; color:#94a3b8;"">Si vous n'êtes pas à l'origine de cette demande, ignorez ce courriel.</p>")
        sb.AppendLine("</div></div></body></html>")
        Return sb.ToString()
    End Function

    ' ====================== HELPERS ======================
    Private Function GetAdminByEmail(email As String) As DataRow
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Email", email))
            Dim ds As DataSet = ExecuteSQLds("s0640GetAdminByEmail", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return ds.Tables(0).Rows(0)
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Login error: " & ex.Message)
        End Try
        Return Nothing
    End Function

    Private Function ResolveReturnUrl() As String
        Dim ru As String = Request.QueryString("ReturnUrl")
        If Not String.IsNullOrEmpty(ru) AndAlso ru.StartsWith("/") AndAlso Not ru.StartsWith("//") AndAlso Not ru = "/" Then
            Return ru
        End If
        Return "~/Default.aspx"
    End Function

    Private Sub ShowMsg(text As String, isError As Boolean)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = "msg " & If(isError, "", "ok")
    End Sub

End Class
