Imports System
Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text
Imports System.Web

''' <summary>
''' Page de résumé du forfait + lancement Stripe Checkout.
''' Flow : user arrive ici après activation email → voit le résumé du forfait
'''        choisi (lookup T021Plan via clsData) → clique "Payer avec Stripe →"
'''        → MngConsul crée une Stripe Checkout Session côté serveur
'''        → user redirigé vers checkout.stripe.com
'''        → après paiement, retour sur wbfPaymentSuccess.aspx?session_id=cs_xxx
''' </summary>
Public Class wbfPayment
    Inherits clsData

    ''' <summary>Langue courante : ?lang=fr|en|es (défaut fr), transmise depuis l'onboarding.</summary>

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        ' Vérifier que l'utilisateur est connecté
        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx?lang=" & CurrentLang)
            Return
        End If

        ApplyLocalization()

        If Not IsPostBack Then
            LoadPlanDetails()
        End If
    End Sub

    ''' <summary>Applique la langue aux contrôles serveur (titre, bouton).</summary>
    Private Sub ApplyLocalization()
        Page.Title = L("pageTitle")
        btnPay.Text = L("payBtn")
    End Sub

    ''' <summary>Locale de la page Stripe Checkout selon la langue courante.</summary>
    Private Function StripeLocale() As String
        Select Case CurrentLang
            Case "en" : Return "en"
            Case "es" : Return "es"
            Case Else : Return "fr-CA"
        End Select
    End Function

    ''' <summary>Formate un montant selon la langue (en : « $69.99 » ; fr/es : « 69,99 $ »).</summary>
    Private Function FormatMoney(amount As Decimal) As String
        If CurrentLang = "en" Then
            Return "$" & amount.ToString("N2", New CultureInfo("en-CA"))
        End If
        Return amount.ToString("N2", New CultureInfo("fr-CA")) & " $"
    End Function

    ''' <summary>Traductions de la page de paiement (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Paiement — 60Sec-AI", "Payment — 60Sec-AI", "Pago — 60Sec-AI")
            Case "yourPlan" : Return Choose3(lang, "Votre forfait", "Your plan", "Su plan")
            Case "planPrefix" : Return Choose3(lang, "Forfait", "Plan", "Plan")
            Case "gst" : Return Choose3(lang, "TPS (5 %)", "GST (5%)", "GST (5%)")
            Case "qst" : Return Choose3(lang, "TVQ (9,975 %)", "QST (9.975%)", "QST (9.975%)")
            Case "monthlyTotal" : Return Choose3(lang, "Total mensuel", "Monthly total", "Total mensual")
            Case "taxNote" : Return Choose3(lang, "Taxes estimées (Québec). Le montant exact est calculé selon votre adresse de facturation au moment du paiement.", "Estimated taxes (Quebec). The exact amount is calculated from your billing address at checkout.", "Impuestos estimados (Quebec). El importe exacto se calcula según su dirección de facturación en el pago.")
            Case "trialBanner" : Return Choose3(lang, "{0} jours gratuits — aucun prélèvement aujourd'hui, annulable à tout moment.", "{0} days free — no charge today, cancel anytime.", "{0} días gratis — sin cargo hoy, cancele cuando quiera.")
            Case "securePayment" : Return Choose3(lang, "Paiement sécurisé", "Secure payment", "Pago seguro")
            Case "redirectStripe" : Return Choose3(lang, "Vous serez redirigé vers Stripe pour finaliser votre paiement.", "You'll be redirected to Stripe to complete your payment.", "Será redirigido a Stripe para completar su pago.")
            Case "processedByStripe" : Return Choose3(lang, "Paiement traité par Stripe", "Payment processed by Stripe", "Pago procesado por Stripe")
            Case "feat256" : Return Choose3(lang, "Chiffrement SSL 256 bits", "256-bit SSL encryption", "Cifrado SSL de 256 bits")
            Case "featPci" : Return Choose3(lang, "Conforme PCI-DSS", "PCI-DSS compliant", "Conforme con PCI-DSS")
            Case "featWallets" : Return Choose3(lang, "Apple Pay, Google Pay, Link supportés", "Apple Pay, Google Pay, Link supported", "Apple Pay, Google Pay, Link compatibles")
            Case "featNoCard" : Return Choose3(lang, "Aucune carte stockée chez 60Sec-AI", "No card stored by 60Sec-AI", "Ninguna tarjeta almacenada por 60Sec-AI")
            Case "payBtn" : Return Choose3(lang, "Payer avec Stripe →", "Pay with Stripe →", "Pagar con Stripe →")
            Case "redirectInfo" : Return Choose3(lang, "Vous serez redirigé vers checkout.stripe.com", "You'll be redirected to checkout.stripe.com", "Será redirigido a checkout.stripe.com")
            Case "errAccount" : Return Choose3(lang, "Impossible de récupérer vos informations de compte.", "Unable to retrieve your account information.", "No se pudo recuperar la información de su cuenta.")
            Case "errPlanUnavailable" : Return Choose3(lang, "Ce forfait n'est pas disponible. Veuillez contacter le support.", "This plan is not available. Please contact support.", "Este plan no está disponible. Contacte con soporte.")
            Case "errStripeConfig" : Return Choose3(lang, "La configuration de paiement pour ce forfait est incomplète. Veuillez contacter le support.", "The payment configuration for this plan is incomplete. Please contact support.", "La configuración de pago para este plan está incompleta. Contacte con soporte.")
            Case "errCheckout" : Return Choose3(lang, "Une erreur est survenue lors de la création de la session de paiement : ", "An error occurred while creating the payment session: ", "Se produjo un error al crear la sesión de pago: ")
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

    ''' <summary>
    ''' Récupère le code abonnement + GUID compagnie + email du user connecté.
    ''' </summary>
    Private Function GetUserAndCompanyInfo(uId As Integer) As DataRow
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", uId))

        Dim ds As DataSet = ExecuteSQLds("s0230GetUserAndCompanyInfo", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Return Nothing
        End If
        Return ds.Tables(0).Rows(0)
    End Function

    ''' <summary>
    ''' Récupère le détail du forfait depuis T021Plan via s0631GetPlanByCode.
    ''' Pour l'instant on défaut à BillingCycle = 'monthly'.
    ''' </summary>
    Private Function GetPlan(planCode As String, billingCycle As String) As DataRow
        Dim p As New Collection
        p.Add(New SqlParameter("@Code", planCode))
        p.Add(New SqlParameter("@BillingCycle", billingCycle))
        p.Add(New SqlParameter("@Lang", CurrentLang))

        Dim ds As DataSet = ExecuteSQLds("s0631GetPlanByCode", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Return Nothing
        End If
        Return ds.Tables(0).Rows(0)
    End Function

    ''' <summary>
    ''' Charge les détails du forfait choisi par le user et affiche le résumé.
    ''' </summary>
    Private Sub LoadPlanDetails()

        Dim userRow As DataRow = GetUserAndCompanyInfo(UserId)
        If userRow Is Nothing Then
            ShowError(L("errAccount"))
            Return
        End If

        Company = CType(userRow("CompanyGUID"), Guid)
        Dim planCode As String = If(userRow("Abonnement") Is DBNull.Value, "solo", userRow("Abonnement").ToString())

        ' Lookup dans T021Plan (BD = source de vérité, plus de hardcode)
        Dim planRow As DataRow = GetPlan(planCode, "monthly")
        If planRow Is Nothing Then
            ShowError(L("errPlanUnavailable"))
            Return
        End If

        Dim planName As String = planRow("Name").ToString()
        Dim tagline As String = If(planRow("Tagline") Is DBNull.Value, "", planRow("Tagline").ToString())
        Dim amount As Decimal = CDec(planRow("Amount"))
        Dim features As String = If(planRow("Features") Is DBNull.Value, "", planRow("Features").ToString())

        ' Sauvegarder en ViewState pour le postback du bouton Stripe
        ViewState("PlanCode") = planCode
        ViewState("PlanName") = planName
        ViewState("PlanAmount") = amount
        ViewState("PlanBillingCycle") = "monthly"
        ' StripePriceId : null pour l'instant (à remplir dans Stripe Dashboard + UPDATE T021Plan)
        ViewState("StripePriceId") = If(planRow("StripePriceId") Is DBNull.Value, "", planRow("StripePriceId").ToString())

        ' === Calculs taxes Québec ===
        Dim tps As Decimal = Math.Round(amount * 0.05D, 2)
        Dim tvq As Decimal = Math.Round(amount * 0.09975D, 2)
        Dim total As Decimal = amount + tps + tvq

        ' === Affichage des Literals ===
        litPlanName.Text = planName
        litPlanTagline.Text = tagline
        litPlanLabel.Text = L("planPrefix") & " " & planName
        litPlanAmount.Text = FormatMoney(amount)
        litTps.Text = FormatMoney(tps)
        litTvq.Text = FormatMoney(tvq)
        litTotal.Text = FormatMoney(total)

        ' === Bandeau essai gratuit (si le forfait a des jours d'essai) ===
        Dim trialDays As Integer = If(planRow("TrialDays") Is DBNull.Value, 0, CInt(planRow("TrialDays")))
        If trialDays > 0 Then
            pnlTrial.Visible = True
            litTrialBanner.Text = String.Format(L("trialBanner"), trialDays)
        End If

        ' === Liste des features (depuis T021Plan.Features, une ligne = une feature) ===
        litFeatures.Text = RenderFeaturesHtml(features)
    End Sub

    ''' <summary>
    ''' Construit le HTML des features (li + svg check) depuis le texte multi-ligne.
    ''' </summary>
    Private Function RenderFeaturesHtml(featuresText As String) As String
        If String.IsNullOrWhiteSpace(featuresText) Then Return ""
        Dim sb As New StringBuilder()
        Dim lines() As String = featuresText.Split(New String() {vbCrLf, vbLf, vbCr}, StringSplitOptions.RemoveEmptyEntries)
        For Each line As String In lines
            Dim clean As String = line.Trim()
            If clean.Length > 0 Then
                sb.Append("<li>")
                sb.Append("<svg width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='3' stroke-linecap='round' stroke-linejoin='round'>")
                sb.Append("<polyline points='20 6 9 17 4 12'></polyline></svg> ")
                sb.Append(HttpUtility.HtmlEncode(clean))
                sb.Append("</li>")
            End If
        Next
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Crée une Stripe Checkout Session et redirige le user vers Stripe.
    ''' </summary>
    Protected Sub btnPay_Click(sender As Object, e As EventArgs) Handles btnPay.Click

        Try
            Dim planCode As String = If(ViewState("PlanCode"), "").ToString()
            Dim billingCycle As String = If(ViewState("PlanBillingCycle"), "monthly").ToString()
            Dim priceId As String = If(ViewState("StripePriceId"), "").ToString()

            If String.IsNullOrEmpty(priceId) Then
                ' Détail technique en log seulement ; message générique localisé pour l'utilisateur.
                System.Diagnostics.Debug.WriteLine("StripePriceId manquant dans T021Plan pour Code='" & planCode & "' BillingCycle='" & billingCycle & "'.")
                ShowError(L("errStripeConfig"))
                Return
            End If

            ' Récupérer email et stripe customer id existant pour le user
            Dim customerEmail As String = UserEmail
            Dim stripeCustomerId As String = GetUserStripeCustomerId(UserId)

            ' Forfait peut inclure essai gratuit (T021Plan.TrialDays)
            Dim trialDays As Integer = GetPlanTrialDays(planCode, billingCycle)

            ' URLs de retour (absolues, requis par Stripe)
            Dim baseUrl As String = Request.Url.GetLeftPart(UriPartial.Authority)
            Dim langQs As String = "?lang=" & CurrentLang
            Dim successUrl As String = baseUrl & ResolveUrl(ConfigurationManager.AppSettings("Stripe.SuccessUrlPath")) & langQs
            Dim cancelUrl As String = baseUrl & ResolveUrl(ConfigurationManager.AppSettings("Stripe.CancelUrlPath")) & langQs

            ' Metadata pour traçabilité dans webhook Stripe
            Dim meta As New Dictionary(Of String, String) From {
                {"MngConsul_UserId", UserId.ToString()},
                {"MngConsul_CompanyGUID", Company.ToString()},
                {"MngConsul_PlanCode", planCode},
                {"MngConsul_BillingCycle", billingCycle}
            }

            ' === Création Stripe Checkout Session ===
            Dim checkoutUrl As String = clsStripe.CreateCheckoutSession(
                customerEmail:=customerEmail,
                stripeCustomerId:=stripeCustomerId,
                priceId:=priceId,
                successUrl:=successUrl,
                cancelUrl:=cancelUrl,
                trialDays:=trialDays,
                metadata:=meta,
                locale:=StripeLocale()
            )

            ' Redirection vers Stripe (URL de type https://checkout.stripe.com/c/pay/cs_xxx)
            Response.Redirect(checkoutUrl, endResponse:=True)

        Catch ex As Threading.ThreadAbortException
            ' Normal lors d'un Response.Redirect, ignorer
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Stripe Checkout error: " & ex.Message)
            ShowError(L("errCheckout") & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Retourne le StripeCustomerId stocké pour ce user (cus_xxx) ou chaîne vide.
    ''' </summary>
    Private Function GetUserStripeCustomerId(uId As Integer) As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", uId))
            Dim ds As DataSet = ExecuteSQLds("s0314GetUserByUserId", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim row As DataRow = ds.Tables(0).Rows(0)
                If row.Table.Columns.Contains("StripeCustomerId") AndAlso Not IsDBNull(row("StripeCustomerId")) Then
                    Return row("StripeCustomerId").ToString()
                End If
            End If
        Catch
            ' silencieux
        End Try
        Return ""
    End Function

    ''' <summary>
    ''' Retourne TrialDays du forfait (depuis T021Plan).
    ''' </summary>
    Private Function GetPlanTrialDays(planCode As String, billingCycle As String) As Integer
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Code", planCode))
            p.Add(New SqlParameter("@BillingCycle", billingCycle))
            Dim ds As DataSet = ExecuteSQLds("s0631GetPlanByCode", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return CInt(ds.Tables(0).Rows(0)("TrialDays"))
            End If
        Catch
        End Try
        Return 0
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

End Class
