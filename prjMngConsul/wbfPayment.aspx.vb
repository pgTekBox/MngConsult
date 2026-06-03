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

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        ' Vérifier que l'utilisateur est connecté
        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            LoadPlanDetails()
        End If
    End Sub

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
            ShowError("Impossible de récupérer vos informations de compte.")
            Return
        End If

        Company = CType(userRow("CompanyGUID"), Guid)
        Dim planCode As String = If(userRow("Abonnement") Is DBNull.Value, "solo", userRow("Abonnement").ToString())

        ' Lookup dans T021Plan (BD = source de vérité, plus de hardcode)
        Dim planRow As DataRow = GetPlan(planCode, "monthly")
        If planRow Is Nothing Then
            ShowError("Le forfait '" & planCode & "' n'est pas disponible. Contactez le support.")
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
        Dim culture As New CultureInfo("fr-CA")
        litPlanName.Text = planName
        litPlanTagline.Text = tagline
        litPlanLabel.Text = "Forfait " & planName
        litPlanAmount.Text = amount.ToString("N2", culture) & " $"
        litTps.Text = tps.ToString("N2", culture) & " $"
        litTvq.Text = tvq.ToString("N2", culture) & " $"
        litTotal.Text = total.ToString("N2", culture) & " $"

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
                ShowError("La configuration Stripe pour ce forfait est incomplète. " &
                          "Le StripePriceId n'est pas défini dans T021Plan. " &
                          "Allez dans le dashboard Stripe, créez le Product+Price, puis : " &
                          "UPDATE T021Plan SET StripePriceId='price_xxx' WHERE Code='" & planCode & "' AND BillingCycle='" & billingCycle & "';")
                Return
            End If

            ' Récupérer email et stripe customer id existant pour le user
            Dim customerEmail As String = UserEmail
            Dim stripeCustomerId As String = GetUserStripeCustomerId(UserId)

            ' Forfait peut inclure essai gratuit (T021Plan.TrialDays)
            Dim trialDays As Integer = GetPlanTrialDays(planCode, billingCycle)

            ' URLs de retour (absolues, requis par Stripe)
            Dim baseUrl As String = Request.Url.GetLeftPart(UriPartial.Authority)
            Dim successUrl As String = baseUrl & ResolveUrl(ConfigurationManager.AppSettings("Stripe.SuccessUrlPath"))
            Dim cancelUrl As String = baseUrl & ResolveUrl(ConfigurationManager.AppSettings("Stripe.CancelUrlPath"))

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
                metadata:=meta
            )

            ' Redirection vers Stripe (URL de type https://checkout.stripe.com/c/pay/cs_xxx)
            Response.Redirect(checkoutUrl, endResponse:=True)

        Catch ex As Threading.ThreadAbortException
            ' Normal lors d'un Response.Redirect, ignorer
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Stripe Checkout error: " & ex.Message)
            ShowError("Une erreur est survenue lors de la création de la session de paiement : " & ex.Message)
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
