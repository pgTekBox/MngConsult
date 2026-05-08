Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net
Imports Telerik.Web.UI

Public Class wbfRegister
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Si déjà connecté, rediriger vers le dashboard

        'wbfRegister.aspx?ab= solo
        'wbfRegister.aspx?ab= comsolo
        'wbfRegister.aspx?ab= scom119
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



                ' Stocker l'email pour le bouton "Renvoyer"
                ViewState("RegisteredEmail") = ds.Tables(0).Rows(0)("Email").ToString()






                'litSuccessEmail.Text = email

                ' Stocker l'email pour le bouton "Renvoyer"
                'ViewState("RegisteredEmail") = email
                'Response.Redirect("~/wbfActivate.aspx?token=" & ActiveToken)
                Return
            End If

        End If
        btnRegister.Text = If(Abonnement = "solo", "Créer mon compte Solo", If(Abonnement = "comsolo", "Créer mon compte ComSolo", If(Abonnement = "scom119", "Créer mon compte SCOM119", "Créer mon compte")))

        If Not IsPostBack AndAlso UserId IsNot "" Then
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
            ShowError("Le courriel est obligatoire.")
            Return
        End If
        If Not email.Contains("@") OrElse Not email.Contains(".") Then
            ShowError("Le courriel n'est pas valide.")
            Return
        End If
        If password.Length < 8 Then
            ShowError("Le mot de passe doit contenir au moins 8 caractères.")
            Return
        End If
        If password <> passwordConfirm Then
            ShowError("Les mots de passe ne correspondent pas.")
            Return
        End If
        If Not cbTerms.Checked Then
            ShowError("Vous devez accepter les conditions d'utilisation.")
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

                Dim errMsg = "Email existe deja"

                ShowError(errMsg)
                Return

            End If

            If ds.Tables(0).Rows(0)("Errorcode") >= 10000 Then
                ShowError("Une erreur est survenue lors de l'inscription. Veuillez réessayer.")
                Return
            End If

            Dim userId As Integer = ds.Tables(0).Rows(0)("NewUserId")
            Dim activationToken As Guid = ds.Tables(0).Rows(0)("activationToken")

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

            ' Stocker l'email pour le bouton "Renvoyer"
            ViewState("RegisteredEmail") = email


        Catch ex As Exception
            ShowError("Une erreur est survenue : " & ex.Message)
        End Try
    End Sub

    Protected Sub lnkResend_Click(sender As Object, e As EventArgs) Handles lnkResend.Click

        Dim email As String = If(ViewState("RegisteredEmail"), "").ToString()
        If String.IsNullOrEmpty(email) Then Return


        Dim p As New Collection


        p.Add(New SqlClient.SqlParameter("@Email", email))


        Dim ds As DataSet = ExecuteSQLds("s0222ResendActivation", p)





        Try


            If ds.Tables(0).Rows(0)("NewToken") IsNot Nothing AndAlso Not IsDBNull(ds.Tables(0).Rows(0)("NewToken")) Then
                Dim newToken As Guid = ds.Tables(0).Rows(0)("NewToken")
                SendActivationEmail(email, "", newToken)
            End If

        Catch
            ' silencieux
        End Try
    End Sub

    ''' <summary>
    ''' Envoie le courriel d'activation. Retourne True si réussi.
    ''' </summary>
    Private Function SendActivationEmail(email As String, firstName As String, token As Guid) As Boolean

        Dim baseUrl As String = Request.Url.GetLeftPart(UriPartial.Authority) &
                                ResolveUrl("~/wbfActivate.aspx")
        Dim activationLink As String = baseUrl & "?token=" & token.ToString("D")

        Dim greeting As String = If(String.IsNullOrEmpty(firstName), "Bonjour !", "Bonjour " & firstName & " !")

        Dim subject As String = "Activez votre compte MngConsul"
        Dim body As String = BuildEmailBody(greeting, activationLink)

        Try
            ' === MODE SIMULATION ===
            ' Au lieu d'envoyer un vrai courriel via SMTP, on stocke le contenu
            ' dans la session et on ouvre une fenêtre navigateur de simulation.
            ' L'envoi SMTP réel sera branché plus tard via EmailHelper.Send().

            'EmailHelper.Send(email, subject, body)

            Session("FakeEmail") = New FakeEmailMessage With {
                .ToEmail = email,
                .Subject = subject,
                .HtmlBody = body,
                .ActionLink = activationLink
            }

            ' Ouvre une nouvelle fenêtre navigateur (popup) avec wbfFakeEmail.aspx
            Dim fakeUrl As String = ResolveUrl("~/wbfFakeEmail.aspx")
            Dim script As String =
                "window.open('" & fakeUrl & "?_t=' + new Date().getTime(), " &
                "'fakeEmail', " &
                "'width=860,height=780,resizable=yes,scrollbars=yes,toolbar=no,menubar=no,location=no,status=no');"

            Page.ClientScript.RegisterStartupScript(Me.GetType(), "openFakeEmail",
                script, addScriptTags:=True)

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
        sb.AppendLine("<div style=""width:64px; height:64px; background:rgba(255,255,255,.2); border-radius:18px; display:inline-flex; align-items:center; justify-content:center; color:#fff; font-size:30px; font-weight:800; margin-bottom:8px;"">M</div>")
        sb.AppendLine("<h1 style=""color:#fff; margin:0; font-size:22px;"">Bienvenue chez MngConsul</h1>")
        sb.AppendLine("</div>")
        sb.AppendLine("<div style=""padding:32px; color:#0f172a;"">")
        sb.AppendLine("<p style=""font-size:16px;"">" & greeting & "</p>")
        sb.AppendLine("<p>Merci de vous être inscrit. Pour finaliser la création de votre compte, cliquez sur le bouton ci-dessous :</p>")
        sb.AppendLine("<div style=""text-align:center; margin:28px 0;"">")
        sb.AppendLine("<a href=""" & activationLink & """  target=""_blank""   style=""display:inline-block; background: linear-gradient(135deg,#2563eb,#06b6d4); color:#fff; padding:14px 32px; border-radius:12px; text-decoration:none; font-weight:800; font-size:15px;"">Activer mon compte</a>")
        sb.AppendLine("</div>")
        sb.AppendLine("<p style=""font-size:13px; color:#64748b;"">Le lien est valide pendant <strong>24 heures</strong>.</p>")
        sb.AppendLine("<p style=""font-size:13px; color:#64748b;"">Si le bouton ne fonctionne pas, copiez ce lien dans votre navigateur :<br/>")
        sb.AppendLine("<span style=""word-break:break-all; color:#2563eb;"">" & activationLink & "</span></p>")
        sb.AppendLine("<hr style=""border:none; border-top:1px solid #e2e8f0; margin:24px 0;"" />")
        sb.AppendLine("<p style=""font-size:12px; color:#94a3b8;"">Si vous n'avez pas créé de compte chez nous, ignorez ce courriel.</p>")
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
