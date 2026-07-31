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

        ApplyLocalization()

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

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur.</summary>
    Private Sub ApplyLocalization()
        btnStartOnboarding.Text = L("btnConfigNow")
        btnSendInvitation.Text = L("btnSendInv")
        btnResumeOnboarding.Text = L("btnResume")
        btnResendInvitation.Text = L("btnResend")
        lnkBack.Text = L("btnBack")
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

        litSupplierName.Text = Server.HtmlEncode(If(String.IsNullOrEmpty(supplierName), L("supplierUnknown"), supplierName))
        litSupplierEmail.Text = Server.HtmlEncode(If(String.IsNullOrEmpty(supplierEmail), L("emailMissing"), supplierEmail))
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
                litRestrictedMessage.Text = L("msgDocsRequired") & String.Join(", ", acct.Requirements.CurrentlyDue)
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
                litRestrictedMessage.Text = L("msgInvalidEmail")
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
            litRestrictedMessage.Text = L("msgSendError") & ex.Message
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
                litRestrictedMessage.Text = L("msgNoEmail")
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
        Dim subject As String = L("emailSubject")
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
        sb.AppendLine("<h1 style=""color:#fff; margin:0; font-size:22px;"">" & L("emailH1") & "</h1>")
        sb.AppendLine("</div>")
        sb.AppendLine("<div style=""padding:32px; color:#0f172a;"">")
        sb.AppendLine("<p style=""font-size:16px;"">" & L("emailHello") & "</p>")
        sb.AppendLine("<p>" & L("emailP1") & "</p>")
        sb.AppendLine("<p>" & L("emailP2") & "</p>")
        sb.AppendLine("<div style=""text-align:center; margin:28px 0;"">")
        sb.AppendLine("<a href=""" & activationLink & """ target=""_blank"" style=""display:inline-block; background:linear-gradient(135deg,#635BFF,#4F46E5); color:#fff; padding:14px 32px; border-radius:12px; text-decoration:none; font-weight:800; font-size:15px;"">" & L("emailBtn") & "</a>")
        sb.AppendLine("</div>")
        sb.AppendLine("<p style=""font-size:13px; color:#64748b;"">" & L("emailNote1") & "</p>")
        sb.AppendLine("<p style=""font-size:13px; color:#64748b;"">" & L("emailNote2") & "</p>")
        sb.AppendLine("<hr style=""border:none; border-top:1px solid #e2e8f0; margin:24px 0;"" />")
        sb.AppendLine("<p style=""font-size:12px; color:#94a3b8;"">" & L("emailFallbackLink") & "<br/>")
        sb.AppendLine("<span style=""word-break:break-all; color:#635BFF;"">" & activationLink & "</span></p>")
        sb.AppendLine("<p style=""font-size:12px; color:#94a3b8;"">" & L("emailExpire") & "</p>")
        sb.AppendLine("</div>")
        sb.AppendLine("</div></body></html>")
        Return sb.ToString()
    End Function

    ''' <summary>Traductions de l'onboarding Stripe fournisseur (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Configuration Stripe Connect — 60Sec-AI", "Stripe Connect setup — 60Sec-AI", "Configuración de Stripe Connect — 60Sec-AI")
            Case "hTitle" : Return Choose3(lang, "Configuration des paiements", "Payment setup", "Configuración de pagos")
            Case "subtitle" : Return Choose3(lang, "Permettre à ce fournisseur de recevoir des paiements via 60Sec-AI", "Allow this supplier to receive payments through 60Sec-AI", "Permitir que este proveedor reciba pagos a través de 60Sec-AI")
            Case "supplierLabel" : Return Choose3(lang, "Fournisseur", "Supplier", "Proveedor")
            Case "supplierUnknown" : Return Choose3(lang, "Fournisseur inconnu", "Unknown supplier", "Proveedor desconocido")
            Case "emailMissing" : Return Choose3(lang, "Courriel non renseigné dans la fiche", "No email in the record", "Correo no indicado en la ficha")
            Case "stNewTitle" : Return Choose3(lang, "⚠ Paiements non configurés", "⚠ Payments not configured", "⚠ Pagos no configurados")
            Case "stNewBody" : Return Choose3(lang, "Ce fournisseur n'a pas encore de compte Stripe Connect. Cliquez sur le bouton ci-dessous pour démarrer l'inscription.", "This supplier does not have a Stripe Connect account yet. Click the button below to start onboarding.", "Este proveedor aún no tiene una cuenta de Stripe Connect. Haga clic en el botón de abajo para iniciar el registro.")
            Case "stPendTitle" : Return Choose3(lang, "⏳ Inscription en cours", "⏳ Onboarding in progress", "⏳ Registro en curso")
            Case "stPendBody" : Return Choose3(lang, "Le fournisseur a démarré son inscription Stripe mais ne l'a pas complétée.", "The supplier started their Stripe onboarding but did not complete it.", "El proveedor inició su registro en Stripe pero no lo completó.")
            Case "stActiveTitle" : Return Choose3(lang, "✓ Compte actif", "✓ Account active", "✓ Cuenta activa")
            Case "stActiveBody" : Return Choose3(lang, "Ce fournisseur peut recevoir des paiements via MngConsul.", "This supplier can receive payments through MngConsul.", "Este proveedor puede recibir pagos a través de MngConsul.")
            Case "stRestrTitle" : Return Choose3(lang, "⚠ Action requise", "⚠ Action required", "⚠ Acción requerida")
            Case "feat1" : Return Choose3(lang, "Recevoir des paiements par carte de crédit, Interac et ACSS Debit", "Receive payments by credit card, Interac and ACSS Debit", "Recibir pagos con tarjeta de crédito, Interac y ACSS Debit")
            Case "feat2" : Return Choose3(lang, "Versement automatique dans votre compte bancaire (1-2 jours)", "Automatic payout to your bank account (1-2 days)", "Depósito automático en su cuenta bancaria (1-2 días)")
            Case "feat3" : Return Choose3(lang, "Sécurité maximale (PCI-DSS, conforme Paiements Canada)", "Maximum security (PCI-DSS, Payments Canada compliant)", "Máxima seguridad (PCI-DSS, conforme a Payments Canada)")
            Case "feat4" : Return Choose3(lang, "Inscription gratuite, ~5 minutes", "Free registration, ~5 minutes", "Registro gratuito, ~5 minutos")
            Case "modeChoiceTitle" : Return Choose3(lang, "Choisir comment inscrire ce fournisseur", "Choose how to onboard this supplier", "Elija cómo registrar a este proveedor")
            Case "modeATitle" : Return Choose3(lang, "🖥️ Configurer maintenant", "🖥️ Configure now", "🖥️ Configurar ahora")
            Case "modeADesc" : Return Choose3(lang, "Vous serez redirigé vers Stripe pour remplir les informations du fournisseur. Utile si vous avez toutes ses infos (NEQ, banque, etc.) ou s'il est avec vous.", "You will be redirected to Stripe to fill in the supplier's information. Useful if you have all their details (business number, bank, etc.) or if they are with you.", "Será redirigido a Stripe para completar la información del proveedor. Útil si tiene todos sus datos (número de empresa, banco, etc.) o si está con usted.")
            Case "btnConfigNow" : Return Choose3(lang, "Configurer maintenant →", "Configure now →", "Configurar ahora →")
            Case "modeBTitle" : Return Choose3(lang, "✉️ Envoyer une invitation par courriel", "✉️ Send an email invitation", "✉️ Enviar una invitación por correo")
            Case "modeBDesc" : Return Choose3(lang, "Le fournisseur reçoit un courriel avec un lien sécurisé. Il remplit lui-même ses informations sur Stripe. ", "The supplier receives an email with a secure link. They fill in their own information on Stripe. ", "El proveedor recibe un correo con un enlace seguro. Completa su propia información en Stripe. ")
            Case "modeBRecommended" : Return Choose3(lang, "Recommandé en B2B", "Recommended for B2B", "Recomendado en B2B")
            Case "lblSupplierEmail" : Return Choose3(lang, "Courriel du fournisseur", "Supplier email", "Correo del proveedor")
            Case "btnSendInv" : Return Choose3(lang, "Envoyer l'invitation par courriel ✉️", "Send email invitation ✉️", "Enviar invitación por correo ✉️")
            Case "invSentTitle" : Return Choose3(lang, "✓ Invitation envoyée", "✓ Invitation sent", "✓ Invitación enviada")
            Case "invSentPre" : Return Choose3(lang, "Un courriel a été envoyé à", "An email was sent to", "Se envió un correo a")
            Case "invSentPost" : Return Choose3(lang, "avec le lien d'inscription Stripe Connect. Vous serez notifié quand le fournisseur aura complété son inscription.", "with the Stripe Connect onboarding link. You will be notified once the supplier completes their registration.", "con el enlace de registro de Stripe Connect. Se le notificará cuando el proveedor complete su registro.")
            Case "btnResume" : Return Choose3(lang, "Reprendre l'inscription →", "Resume onboarding →", "Reanudar el registro →")
            Case "btnResend" : Return Choose3(lang, "Renvoyer l'invitation ✉️", "Resend invitation ✉️", "Reenviar invitación ✉️")
            Case "btnBack" : Return Choose3(lang, "Retour", "Back", "Volver")
            Case "msgDocsRequired" : Return Choose3(lang, "Documents requis : ", "Required documents: ", "Documentos requeridos: ")
            Case "msgInvalidEmail" : Return Choose3(lang, "Veuillez saisir un courriel valide pour le fournisseur.", "Please enter a valid email for the supplier.", "Ingrese un correo válido para el proveedor.")
            Case "msgSendError" : Return Choose3(lang, "Erreur lors de l'envoi de l'invitation : ", "Error while sending the invitation: ", "Error al enviar la invitación: ")
            Case "msgNoEmail" : Return Choose3(lang, "Aucun courriel disponible pour ce fournisseur.", "No email available for this supplier.", "No hay correo disponible para este proveedor.")
            Case "emailSubject" : Return Choose3(lang, "Invitation à configurer vos paiements - 60Sec-AI", "Invitation to set up your payments - 60Sec-AI", "Invitación para configurar sus pagos - 60Sec-AI")
            Case "emailH1" : Return Choose3(lang, "Invitation 60Sec-AI", "60Sec-AI invitation", "Invitación 60Sec-AI")
            Case "emailHello" : Return Choose3(lang, "Bonjour,", "Hello,", "Hola,")
            Case "emailP1" : Return Choose3(lang, "Vous avez été ajouté comme fournisseur sur la plateforme <strong>60Sec-AI</strong> par un de vos clients qui souhaite vous payer électroniquement.", "You have been added as a supplier on the <strong>60Sec-AI</strong> platform by one of your customers who wishes to pay you electronically.", "Uno de sus clientes lo agregó como proveedor en la plataforma <strong>60Sec-AI</strong> porque desea pagarle electrónicamente.")
            Case "emailP2" : Return Choose3(lang, "Pour activer la réception de paiements (carte de crédit, Interac, ACSS), complétez votre inscription Stripe en cliquant sur le bouton ci-dessous :", "To enable receiving payments (credit card, Interac, ACSS), complete your Stripe registration by clicking the button below:", "Para habilitar la recepción de pagos (tarjeta de crédito, Interac, ACSS), complete su registro en Stripe haciendo clic en el botón de abajo:")
            Case "emailBtn" : Return Choose3(lang, "Configurer mes paiements →", "Set up my payments →", "Configurar mis pagos →")
            Case "emailNote1" : Return Choose3(lang, "L'inscription prend environ 5 minutes et est gratuite.", "Registration takes about 5 minutes and is free.", "El registro toma unos 5 minutos y es gratuito.")
            Case "emailNote2" : Return Choose3(lang, "Vous aurez besoin de : nom légal de l'entreprise, NEQ, adresse, représentant + pièce d'identité, compte bancaire pour recevoir les versements.", "You will need: the company's legal name, business number, address, a representative + ID, and a bank account to receive payouts.", "Necesitará: el nombre legal de la empresa, número de empresa, dirección, un representante + identificación, y una cuenta bancaria para recibir los depósitos.")
            Case "emailFallbackLink" : Return Choose3(lang, "Si le bouton ne fonctionne pas, copiez ce lien dans votre navigateur :", "If the button does not work, copy this link into your browser:", "Si el botón no funciona, copie este enlace en su navegador:")
            Case "emailExpire" : Return Choose3(lang, "Ce lien expire dans quelques minutes pour des raisons de sécurité. Si vous ne pouvez pas l'utiliser tout de suite, demandez un nouveau lien à votre client.", "This link expires in a few minutes for security reasons. If you cannot use it right away, ask your customer for a new link.", "Este enlace caduca en unos minutos por razones de seguridad. Si no puede usarlo de inmediato, solicite un nuevo enlace a su cliente.")
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
