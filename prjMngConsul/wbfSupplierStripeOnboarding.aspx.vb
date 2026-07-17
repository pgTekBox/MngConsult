Imports System
Imports System.Collections.Generic
Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports Stripe

''' <summary>
''' Page d'onboarding Stripe Connect Express pour un fournisseur.
'''
''' URL : wbfSupplierStripeOnboarding.aspx?PartyId=N
'''
''' Flow :
'''   1. Page_Load : charge fournisseur + email + StripeAccountId
'''   2. Si pas configure : affiche 2 boutons (direct / invitation email)
'''   3. Mode A (direct) : btnStartOnboarding -> crée account + redirect Stripe
'''   4. Mode B (email)  : btnSendInvitation  -> crée account + envoie email
'''   5. Si onboarding en cours : btnResumeOnboarding (regenere AccountLink)
'''   6. Si compte actif : message confirmation
''' </summary>
Public Class wbfSupplierStripeOnboarding
    Inherits clsData

    Private Property PartyId As Integer
        Get
            Return CInt(If(ViewState("PartyId"), 0))
        End Get
        Set(value As Integer)
            ViewState("PartyId") = value
        End Set
    End Property

    Private Property SupplierName As String
        Get
            Return If(ViewState("SupplierName"), "").ToString()
        End Get
        Set(value As String)
            ViewState("SupplierName") = value
        End Set
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            Dim partyIdStr As String = Request.QueryString("PartyId")
            Dim pid As Integer = 0
            Integer.TryParse(partyIdStr, pid)
            PartyId = pid

            If PartyId = 0 Then
                Response.Redirect("~/wbfSuppliers.aspx")
                Return
            End If

            LoadSupplierAndStatus()
        End If
    End Sub

    Private Sub LoadSupplierAndStatus()

        Dim supplierName As String = ""
        Dim supplierEmail As String = ""
        Dim stripeAccountId As String = ""

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@PartyId", PartyId))
            Dim ds As DataSet = ExecuteSQLds("s0073GetPartyForOnboarding", p)

            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim row As DataRow = ds.Tables(0).Rows(0)
                supplierName = If(row("Name") Is DBNull.Value, "", row("Name").ToString())
                supplierEmail = If(row("Email") Is DBNull.Value, "", row("Email").ToString())
                stripeAccountId = If(row("StripeAccountId") Is DBNull.Value, "", row("StripeAccountId").ToString())
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("LoadSupplierAndStatus error: " & ex.Message)
        End Try

        SupplierName = supplierName

        litSupplierName.Text = Server.HtmlEncode(If(String.IsNullOrEmpty(supplierName), "Fournisseur inconnu", supplierName))
        litSupplierEmail.Text = Server.HtmlEncode(If(String.IsNullOrEmpty(supplierEmail), "Courriel non renseigné dans la fiche", supplierEmail))
        tbInvitationEmail.Text = supplierEmail  ' pre-remplir si dispo

        ' Statut selon le StripeAccountId
        If String.IsNullOrEmpty(stripeAccountId) Then
            pnlStatusNew.Visible = True
            pnlModeChoice.Visible = True
        Else
            CheckStripeAccountStatus(stripeAccountId)
        End If
    End Sub

    Private Sub CheckStripeAccountStatus(stripeAccountId As String)
        Try
            Dim acct As Account = clsStripe.GetConnectedAccount(stripeAccountId)
            If acct Is Nothing Then
                pnlStatusNew.Visible = True
                pnlModeChoice.Visible = True
                Return
            End If

            If acct.ChargesEnabled AndAlso acct.PayoutsEnabled Then
                pnlStatusActive.Visible = True
                litAcctIdActive.Text = acct.Id
                Return
            End If

            If acct.Requirements IsNot Nothing AndAlso
               acct.Requirements.CurrentlyDue IsNot Nothing AndAlso
               acct.Requirements.CurrentlyDue.Count > 0 Then

                pnlStatusRestricted.Visible = True
                litRestrictedMessage.Text = "Documents requis : " & String.Join(", ", acct.Requirements.CurrentlyDue)
                btnResumeOnboarding.Visible = True
                btnResendInvitation.Visible = True
                Return
            End If

            pnlStatusPending.Visible = True
            litAcctIdPending.Text = acct.Id
            btnResumeOnboarding.Visible = True
            btnResendInvitation.Visible = True

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("CheckStripeAccountStatus error: " & ex.Message)
            pnlStatusNew.Visible = True
            pnlModeChoice.Visible = True
        End Try
    End Sub

    ''' <summary>
    ''' MODE A - Configuration directe : crée Account + AccountLink + redirige Stripe.
    ''' </summary>
    Protected Sub btnStartOnboarding_Click(sender As Object, e As EventArgs) Handles btnStartOnboarding.Click

        Try
            Dim acct As Account = EnsureStripeAccountExists()
            If acct Is Nothing Then Return

            ' Generer AccountLink + redirect
            Dim onboardingUrl As String = GenerateOnboardingLink(acct.Id)
            Response.Redirect(onboardingUrl, endResponse:=True)

        Catch ex As Threading.ThreadAbortException
            ' Normal
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("StartOnboarding error: " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' MODE B - Invitation par courriel : crée Account + envoie un email
    ''' via T400Mails avec le AccountLink (le fournisseur cliquera plus tard).
    ''' </summary>
    Protected Sub btnSendInvitation_Click(sender As Object, e As EventArgs) Handles btnSendInvitation.Click

        Try
            Dim email As String = If(tbInvitationEmail.Text, "").Trim()

            If String.IsNullOrEmpty(email) OrElse Not email.Contains("@") OrElse Not email.Contains(".") Then
                pnlStatusRestricted.Visible = True
                litRestrictedMessage.Text = "Veuillez saisir un courriel valide pour le fournisseur."
                Return
            End If

            ' Creer Account + AccountLink
            Dim acct As Account = EnsureStripeAccountExists()
            If acct Is Nothing Then Return

            Dim onboardingUrl As String = GenerateOnboardingLink(acct.Id)

            ' Envoyer l'invitation par courriel via T400Mails
            SendInvitationEmail(email, onboardingUrl)

            ' Confirmation visuelle
            pnlModeChoice.Visible = False
            pnlInvitationSent.Visible = True
            litInvitationEmailSent.Text = Server.HtmlEncode(email)

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("SendInvitation error: " & ex.Message)
            pnlStatusRestricted.Visible = True
            litRestrictedMessage.Text = "Erreur lors de l'envoi de l'invitation : " & ex.Message
        End Try
    End Sub

    ''' <summary>
    ''' Re-envoyer l'invitation (AccountLink expire vite, on en regenere un nouveau).
    ''' </summary>
    Protected Sub btnResendInvitation_Click(sender As Object, e As EventArgs) Handles btnResendInvitation.Click

        Try
            Dim email As String = If(tbInvitationEmail.Text, "").Trim()
            If String.IsNullOrEmpty(email) Then
                ' Si pas dans textbox, prendre celui de la BD
                email = GetSupplierEmail()
            End If

            If String.IsNullOrEmpty(email) Then
                pnlStatusRestricted.Visible = True
                litRestrictedMessage.Text = "Aucun courriel disponible pour ce fournisseur."
                Return
            End If

            ' Recuperer le StripeAccountId existant
            Dim stripeAccountId As String = GetStoredStripeAccountId()
            If String.IsNullOrEmpty(stripeAccountId) Then
                ' Aucun compte : creer
                Dim acct As Account = EnsureStripeAccountExists()
                If acct Is Nothing Then Return
                stripeAccountId = acct.Id
            End If

            Dim onboardingUrl As String = GenerateOnboardingLink(stripeAccountId)
            SendInvitationEmail(email, onboardingUrl)

            pnlInvitationSent.Visible = True
            litInvitationEmailSent.Text = Server.HtmlEncode(email)

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ResendInvitation error: " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Reprendre l'onboarding direct - regenere AccountLink + redirect.
    ''' </summary>
    Protected Sub btnResumeOnboarding_Click(sender As Object, e As EventArgs) Handles btnResumeOnboarding.Click

        Try
            Dim stripeAccountId As String = GetStoredStripeAccountId()

            If String.IsNullOrEmpty(stripeAccountId) Then
                btnStartOnboarding_Click(sender, e)
                Return
            End If

            Dim onboardingUrl As String = GenerateOnboardingLink(stripeAccountId)
            Response.Redirect(onboardingUrl, endResponse:=True)

        Catch ex As Threading.ThreadAbortException
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ResumeOnboarding error: " & ex.Message)
        End Try
    End Sub

    ' =========================================================================
    ' HELPERS
    ' =========================================================================

    ''' <summary>
    ''' S'assure qu'un Connected Account existe pour ce fournisseur.
    ''' Si non, le crée et stocke l'acct_xxx dans T050Party.
    ''' </summary>
    Private Function EnsureStripeAccountExists() As Account
        Dim existingId As String = GetStoredStripeAccountId()
        If Not String.IsNullOrEmpty(existingId) Then
            Try
                Return clsStripe.GetConnectedAccount(existingId)
            Catch
                ' Si l'account n'existe plus, on en recree
            End Try
        End If

        Dim metadata As New Dictionary(Of String, String) From {
            {"MngConsul_PartyId", PartyId.ToString()},
            {"MngConsul_CompanyGUID", Company.ToString()},
            {"MngConsul_CreatedByUserId", UserId.ToString()}
        }

        Dim emailForStripe As String = If(tbInvitationEmail.Text, "").Trim()
        If String.IsNullOrEmpty(emailForStripe) Then
            emailForStripe = "fournisseur" & PartyId.ToString() & "@mngconsul.local"
        End If

        Dim acct As Account = clsStripe.CreateConnectExpressAccount(
            email:=emailForStripe,
            businessName:=If(String.IsNullOrEmpty(SupplierName), "Fournisseur 60Sec-AI", SupplierName),
            country:="CA",
            metadata:=metadata
        )

        SaveStripeAccountId(PartyId, acct.Id)
        Return acct
    End Function

    Private Function GenerateOnboardingLink(stripeAccountId As String) As String
        Dim baseUrl As String = Request.Url.GetLeftPart(UriPartial.Authority)
        Dim returnUrl As String = baseUrl & ResolveUrl("~/wbfSupplierStripeOnboarding.aspx") & "?PartyId=" & PartyId.ToString()
        Dim refreshUrl As String = baseUrl & ResolveUrl("~/wbfSupplierStripeOnboarding.aspx") & "?PartyId=" & PartyId.ToString() & "&refresh=1"
        Return clsStripe.CreateAccountOnboardingLink(stripeAccountId, returnUrl, refreshUrl)
    End Function

    Private Function GetStoredStripeAccountId() As String
        Try
            Using conn As New SqlConnection(ConnectionString)
                Using cmd As New SqlCommand("SELECT StripeAccountId FROM dbo.T050Party WHERE Id = @PartyId", conn)
                    cmd.Parameters.AddWithValue("@PartyId", PartyId)
                    conn.Open()
                    Dim result = cmd.ExecuteScalar()
                    If result IsNot Nothing AndAlso Not IsDBNull(result) Then
                        Return result.ToString()
                    End If
                End Using
            End Using
        Catch
        End Try
        Return ""
    End Function

    Private Function GetSupplierEmail() As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@PartyId", PartyId))
            Dim ds As DataSet = ExecuteSQLds("s0073GetPartyForOnboarding", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim row As DataRow = ds.Tables(0).Rows(0)
                If Not row("Email") Is DBNull.Value Then Return row("Email").ToString()
            End If
        Catch
        End Try
        Return ""
    End Function

    Private Sub SaveStripeAccountId(partyId As Integer, stripeAccountId As String)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@PartyId", partyId))
            p.Add(New SqlParameter("@StripeAccountId", stripeAccountId))
            ExecuteSQL("s0072UpdatePartyStripeAccountId", p)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("SaveStripeAccountId error: " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Envoie l'invitation Stripe Connect par courriel via T400Mails (s0610).
    ''' Courriel envoyé au nom de la compagnie : le From reste noreply@60sec.ca
    ''' (aligné SPF) et son adresse vérifiée sert de Reply-To, pour que le
    ''' fournisseur réponde à la compagnie et non à la plateforme.
    ''' </summary>
    Private Sub SendInvitationEmail(toEmail As String, onboardingUrl As String)
        Dim subject As String = "Invitation à configurer vos paiements - 60Sec-AI"
        Dim htmlBody As String = BuildInvitationEmailBody(onboardingUrl)

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@To", toEmail))
            p.Add(New SqlParameter("@Subject", subject))
            p.Add(New SqlParameter("@HTMLBody", htmlBody))
            p.Add(New SqlParameter("@TextBody", DBNull.Value))
            CompanyMail.AddReplyToParam(p, ConnectionString, Company)

            ExecuteSQLMail("s0610InsertOutboundMail", p)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("SendInvitationEmail error: " & ex.Message)
            Throw
        End Try
    End Sub

    Private Function BuildInvitationEmailBody(activationLink As String) As String
        Dim sb As New StringBuilder()
        sb.AppendLine("<!DOCTYPE html>")
        sb.AppendLine("<html><body style=""font-family: Arial, sans-serif; background:#f6f7fb; margin:0; padding:20px;"">")
        sb.AppendLine("<div style=""max-width:560px; margin:0 auto; background:#fff; border-radius:16px; overflow:hidden; box-shadow:0 8px 24px rgba(0,0,0,.06);"">")
        sb.AppendLine("<div style=""background: linear-gradient(135deg,#635BFF,#4F46E5); padding:32px; text-align:center;"">")
        sb.AppendLine("<h1 style=""color:#fff; margin:0; font-size:22px;"">Invitation 60Sec-AI</h1>")
        sb.AppendLine("</div>")
        sb.AppendLine("<div style=""padding:32px; color:#0f172a;"">")
        sb.AppendLine("<p style=""font-size:16px;"">Bonjour,</p>")
        sb.AppendLine("<p>Vous avez été ajouté comme fournisseur sur la plateforme <strong>60Sec-AI</strong> ")
        sb.AppendLine("par un de vos clients qui souhaite vous payer électroniquement.</p>")
        sb.AppendLine("<p>Pour activer la réception de paiements (carte de crédit, Interac, ACSS), ")
        sb.AppendLine("complétez votre inscription Stripe en cliquant sur le bouton ci-dessous :</p>")
        sb.AppendLine("<div style=""text-align:center; margin:28px 0;"">")
        sb.AppendLine("<a href=""" & activationLink & """ target=""_blank"" style=""display:inline-block; background:linear-gradient(135deg,#635BFF,#4F46E5); color:#fff; padding:14px 32px; border-radius:12px; text-decoration:none; font-weight:800; font-size:15px;"">Configurer mes paiements →</a>")
        sb.AppendLine("</div>")
        sb.AppendLine("<p style=""font-size:13px; color:#64748b;"">L'inscription prend environ 5 minutes et est gratuite.</p>")
        sb.AppendLine("<p style=""font-size:13px; color:#64748b;"">Vous aurez besoin de : nom légal de l'entreprise, NEQ, adresse, ")
        sb.AppendLine("représentant + pièce d'identité, compte bancaire pour recevoir les versements.</p>")
        sb.AppendLine("<hr style=""border:none; border-top:1px solid #e2e8f0; margin:24px 0;"" />")
        sb.AppendLine("<p style=""font-size:12px; color:#94a3b8;"">Si le bouton ne fonctionne pas, copiez ce lien dans votre navigateur :<br/>")
        sb.AppendLine("<span style=""word-break:break-all; color:#635BFF;"">" & activationLink & "</span></p>")
        sb.AppendLine("<p style=""font-size:12px; color:#94a3b8;"">Ce lien expire dans quelques minutes pour des raisons de sécurité. ")
        sb.AppendLine("Si vous ne pouvez pas l'utiliser tout de suite, demandez un nouveau lien à votre client.</p>")
        sb.AppendLine("</div>")
        sb.AppendLine("</div></body></html>")
        Return sb.ToString()
    End Function

End Class
