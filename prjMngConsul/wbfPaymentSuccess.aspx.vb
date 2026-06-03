Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports Stripe
Imports Stripe.Checkout

''' <summary>
''' Page de retour apres paiement Stripe Checkout.
'''
''' URL : wbfPaymentSuccess.aspx?session_id=cs_xxx (renvoye par Stripe)
'''
''' Source de verite : Stripe API (via clsStripe.GetCheckoutSessionWithDetails).
''' On ne lit PAS T020Subscription car le webhook peut ne pas etre encore arrive
''' (race condition entre redirection Stripe et POST webhook).
''' Le webhook va creer/mettre a jour T020Subscription en arriere-plan.
''' </summary>
Public Class wbfPaymentSuccess
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        ' Verifier que l'utilisateur est toujours connecte
        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            DisplayConfirmation()
        End If
    End Sub

    Private Sub DisplayConfirmation()

        ' Lecture du session_id retourne par Stripe (parametre {CHECKOUT_SESSION_ID})
        Dim sessionId As String = If(Request.QueryString("session_id"), "").Trim()
        If String.IsNullOrEmpty(sessionId) OrElse Not sessionId.StartsWith("cs_") Then
            ShowGenericSuccess()
            Return
        End If

        ' Appel direct Stripe API : source de verite immediate (pas de race condition)
        Dim session As Session
        Try
            session = clsStripe.GetCheckoutSessionWithDetails(sessionId)
        Catch ex As StripeException
            System.Diagnostics.Debug.WriteLine("Stripe session lookup error: " & ex.Message)
            ShowGenericSuccess()
            Return
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Session lookup error: " & ex.Message)
            ShowGenericSuccess()
            Return
        End Try

        If session Is Nothing Then
            ShowGenericSuccess()
            Return
        End If

        ' Verifier le statut de paiement
        ' "paid"               = paiement reussi (cas normal)
        ' "no_payment_required"= essai gratuit (pas de paiement immediat)
        ' "unpaid"             = en cours (rare, redirection trop rapide)
        Dim isPaymentOk As Boolean = (session.PaymentStatus = "paid" OrElse session.PaymentStatus = "no_payment_required")

        ' Extraction des donnees du Checkout Session
        Dim planName As String = ExtractPlanName(session)
        Dim amountTotal As Decimal = If(session.AmountTotal.HasValue, CDec(session.AmountTotal.Value) / 100D, 0D)
        Dim currency As String = If(session.Currency, "cad").ToUpper()

        ' Subscription Id (sub_xxx) sert de "transaction id" affiche
        Dim subscriptionId As String = If(session.SubscriptionId, "")
        If String.IsNullOrEmpty(subscriptionId) AndAlso session.Subscription IsNot Nothing Then
            subscriptionId = session.Subscription.Id
        End If

        ' Prochaine facturation : depuis l'objet Subscription expanded
        ' Note : CurrentPeriodEnd est sur SubscriptionItem depuis Stripe API 2024+
        Dim nextBilling As Date = Date.MinValue
        Dim isTrial As Boolean = False
        Dim trialEnd As Date = Date.MinValue
        If session.Subscription IsNot Nothing Then
            nextBilling = clsStripe.GetSubscriptionPeriodEnd(session.Subscription)
            isTrial = (session.Subscription.Status = "trialing")
            If session.Subscription.TrialEnd.HasValue Then
                trialEnd = session.Subscription.TrialEnd.Value
            End If
        End If

        ' === Affichage ===
        Dim culture As New CultureInfo("fr-CA")

        litPlanName.Text = planName
        litPlanName2.Text = planName

        ' Format ID transaction (subscription Stripe ou session ID)
        Dim displayTxn As String = If(Not String.IsNullOrEmpty(subscriptionId), subscriptionId, sessionId)
        litTransactionId.Text = displayTxn

        ' Date du paiement (maintenant)
        litDate.Text = Date.Now.ToString("dd MMMM yyyy", culture)

        ' Carte : on n'a pas le brand/last4 sans appel supplementaire, on affiche generique
        ' (sera enrichi plus tard si besoin via session.PaymentIntent ou Customer.default_payment_method)
        litCard.Text = "Carte de crédit · via Stripe"

        ' Prochaine facturation
        If nextBilling <> Date.MinValue Then
            If isTrial AndAlso trialEnd <> Date.MinValue Then
                litNextBilling.Text = trialEnd.ToString("dd MMMM yyyy", culture) & " (fin de l'essai gratuit)"
            Else
                litNextBilling.Text = nextBilling.ToString("dd MMMM yyyy", culture)
            End If
        Else
            litNextBilling.Text = "—"
        End If

        ' Montant : si essai gratuit on affiche 0.00, sinon le montant total
        Dim displayAmount As Decimal = amountTotal
        If isTrial AndAlso displayAmount = 0D Then
            litAmount.Text = "Gratuit (essai)"
        Else
            litAmount.Text = displayAmount.ToString("N2", culture) & " " & currency
        End If

        ' Statut warning si paiement pas confirme
        If Not isPaymentOk Then
            ' Note : Stripe peut prendre quelques secondes a finaliser. On affiche quand meme
            ' la confirmation puisque le user vient de payer.
            System.Diagnostics.Debug.WriteLine("PaymentStatus inattendu : " & session.PaymentStatus)
        End If
    End Sub

    ''' <summary>
    ''' Extrait le nom du forfait du premier line item du Checkout Session.
    ''' Fallback : metadata MngConsul_PlanCode.
    ''' </summary>
    Private Function ExtractPlanName(session As Session) As String
        Try
            If session.LineItems IsNot Nothing AndAlso
               session.LineItems.Data IsNot Nothing AndAlso
               session.LineItems.Data.Count > 0 Then

                Dim firstItem = session.LineItems.Data(0)
                If firstItem.Price IsNot Nothing AndAlso firstItem.Price.Product IsNot Nothing Then
                    Return firstItem.Price.Product.Name
                End If
                If firstItem.Description IsNot Nothing Then
                    Return firstItem.Description
                End If
            End If
        Catch
        End Try

        ' Fallback : metadata
        If session.Metadata IsNot Nothing Then
            Dim planCode As String = Nothing
            If session.Metadata.TryGetValue("MngConsul_PlanCode", planCode) AndAlso Not String.IsNullOrEmpty(planCode) Then
                Return CapitalizeFirst(planCode)
            End If
        End If

        Return "Votre forfait"
    End Function

    Private Function CapitalizeFirst(s As String) As String
        If String.IsNullOrEmpty(s) Then Return s
        Return Char.ToUpper(s(0)) & s.Substring(1)
    End Function

    ''' <summary>
    ''' Affichage minimum si le session_id est manquant ou invalide.
    ''' Le webhook fera son travail en arriere-plan de toute facon.
    ''' </summary>
    Private Sub ShowGenericSuccess()
        Dim culture As New CultureInfo("fr-CA")
        litPlanName.Text = "Votre forfait"
        litPlanName2.Text = "Votre forfait"
        litTransactionId.Text = "—"
        litDate.Text = Date.Now.ToString("dd MMMM yyyy", culture)
        litCard.Text = "Carte de crédit · via Stripe"
        litNextBilling.Text = "—"
        litAmount.Text = "—"
    End Sub

End Class
