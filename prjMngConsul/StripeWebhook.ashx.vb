Imports System
Imports System.Collections.Generic
Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Web
Imports Stripe

''' <summary>
''' Handler webhook Stripe pour MngConsul.
'''
''' URL endpoint : https://60sec.ca/StripeWebhook.ashx
''' Configurer dans Dashboard Stripe : Developers > Webhooks > Add endpoint
'''
''' Events ecoutes (a configurer cote Stripe Dashboard) :
'''   - checkout.session.completed         : 1er paiement reussi via Checkout
'''   - customer.subscription.created      : Subscription cree
'''   - customer.subscription.updated      : Renouvellement, changement de plan, statut
'''   - customer.subscription.deleted      : Annulation
'''   - invoice.payment_succeeded          : Paiement recurrent reussi
'''   - invoice.payment_failed             : Paiement recurrent echoue
'''
''' Securite :
'''   - Verification HMAC-SHA256 de la signature Stripe (anti-spoofing)
'''   - Idempotence via UNIQUE constraint sur tStripeEvenement.StripeEventId
'''   - Reponse HTTP 200 = traite OK / 400 = signature invalide / 500 = retry
''' </summary>
Public Class StripeWebhook
    Implements IHttpHandler

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest

        ' Accepter uniquement POST
        If context.Request.HttpMethod <> "POST" Then
            context.Response.StatusCode = 405
            context.Response.Write("Method Not Allowed")
            Return
        End If

        ' === Etape 1 : lire le body brut (avant toute deserialisation) ===
        Dim payload As String
        Try
            context.Request.InputStream.Position = 0
            Using reader As New StreamReader(context.Request.InputStream, Encoding.UTF8)
                payload = reader.ReadToEnd()
            End Using
        Catch ex As Exception
            context.Response.StatusCode = 400
            context.Response.Write("Cannot read request body")
            Return
        End Try

        ' === Etape 2 : verifier la signature Stripe-Signature (critique securite) ===
        Dim signatureHeader As String = context.Request.Headers("Stripe-Signature")
        If String.IsNullOrEmpty(signatureHeader) Then
            context.Response.StatusCode = 400
            context.Response.Write("Missing Stripe-Signature header")
            Return
        End If

        Dim stripeEvent As [Event]
        Try
            stripeEvent = clsStripe.VerifyWebhookSignature(payload, signatureHeader)
        Catch ex As StripeException
            ' Signature invalide = potentiel attaquant ou corruption
            System.Diagnostics.Debug.WriteLine("Stripe webhook signature error: " & ex.Message)
            context.Response.StatusCode = 400
            context.Response.Write("Invalid signature: " & ex.Message)
            Return
        Catch ex As Exception
            ' Exception non-Stripe : details inclus pour diagnostic
            System.Diagnostics.Debug.WriteLine("Stripe webhook verify error: " & ex.Message)
            context.Response.StatusCode = 400
            Dim detail As String = ex.GetType().Name & " : " & ex.Message
            If ex.InnerException IsNot Nothing Then
                detail &= " | Inner: " & ex.InnerException.GetType().Name & " : " & ex.InnerException.Message
            End If
            context.Response.Write("Verification Failed - " & detail)
            Return
        End Try

        ' === Etape 3 : idempotence + insertion event ===
        Dim eventId As String = stripeEvent.Id
        Dim eventType As String = stripeEvent.Type

        ' Extraire ids contextuels pour traceability
        Dim stripeCustomerId As String = ExtractCustomerId(stripeEvent)
        Dim stripeSubscriptionId As String = ExtractSubscriptionId(stripeEvent)

        Dim wasInserted As Boolean
        Try
            wasInserted = InsertEventIfNew(
                eventId, eventType,
                stripeEvent.Created,
                payload,
                stripeCustomerId,
                stripeSubscriptionId
            )
        Catch ex As Exception
            ' Erreur BD = retry par Stripe
            System.Diagnostics.Debug.WriteLine("Stripe webhook DB error (insert): " & ex.Message)
            context.Response.StatusCode = 500
            context.Response.Write("DB error: " & ex.Message)
            Return
        End Try

        If Not wasInserted Then
            ' Event deja traite (Stripe a renvoye) - reponse 200 sans retraitement
            context.Response.StatusCode = 200
            context.Response.Write("Already processed")
            Return
        End If

        ' === Etape 4 : dispatch selon le type d'event ===
        Try
            Select Case eventType
                Case "checkout.session.completed"
                    HandleCheckoutSessionCompleted(CType(stripeEvent.Data.Object, Checkout.Session))

                Case "customer.subscription.created", "customer.subscription.updated"
                    HandleSubscriptionUpdated(CType(stripeEvent.Data.Object, Subscription))

                Case "customer.subscription.deleted"
                    HandleSubscriptionDeleted(CType(stripeEvent.Data.Object, Subscription))

                Case "invoice.payment_succeeded"
                    HandleInvoicePaymentSucceeded(CType(stripeEvent.Data.Object, Invoice))

                Case "invoice.payment_failed"
                    HandleInvoicePaymentFailed(CType(stripeEvent.Data.Object, Invoice))

                Case Else
                    ' Event ecoute mais non gere - marquer comme skipped (succes pour Stripe)
                    MarkEventSkipped(eventId, "Event type non gere : " & eventType)
                    context.Response.StatusCode = 200
                    context.Response.Write("OK (skipped: " & eventType & ")")
                    Return
            End Select

            MarkEventProcessed(eventId)
            context.Response.StatusCode = 200
            context.Response.Write("OK")

        Catch ex As Exception
            ' Erreur de traitement - Stripe va retenter automatiquement
            System.Diagnostics.Debug.WriteLine("Stripe webhook processing error (" & eventType & "): " & ex.Message)
            Try
                MarkEventFailed(eventId, ex.Message)
            Catch
                ' Si on ne peut meme pas logguer l'erreur, on laisse Stripe retry
            End Try
            context.Response.StatusCode = 500
            context.Response.Write("Processing failed: " & ex.Message)
        End Try
    End Sub

    ' =========================================================================
    ' EXTRACTION DES IDS CONTEXTUELS (pour log dans tStripeEvenement)
    ' =========================================================================

    Private Function ExtractCustomerId(ev As [Event]) As String
        Try
            Select Case ev.Type
                Case "checkout.session.completed"
                    Return CType(ev.Data.Object, Checkout.Session).CustomerId
                Case "customer.subscription.created", "customer.subscription.updated", "customer.subscription.deleted"
                    Return CType(ev.Data.Object, Subscription).CustomerId
                Case "invoice.payment_succeeded", "invoice.payment_failed"
                    Return CType(ev.Data.Object, Invoice).CustomerId
            End Select
        Catch
        End Try
        Return Nothing
    End Function

    Private Function ExtractSubscriptionId(ev As [Event]) As String
        Try
            Select Case ev.Type
                Case "checkout.session.completed"
                    Return CType(ev.Data.Object, Checkout.Session).SubscriptionId
                Case "customer.subscription.created", "customer.subscription.updated", "customer.subscription.deleted"
                    Return CType(ev.Data.Object, Subscription).Id
                Case "invoice.payment_succeeded", "invoice.payment_failed"
                    Return clsStripe.GetInvoiceSubscriptionId(CType(ev.Data.Object, Invoice))
            End Select
        Catch
        End Try
        Return Nothing
    End Function

    ' =========================================================================
    ' HANDLERS PAR TYPE D'EVENT
    ' =========================================================================

    ''' <summary>
    ''' checkout.session.completed : 2 scenarios distincts selon metadata :
    '''   1. MngConsul_DocumentId present -> paiement FOURNISSEUR (Direct Charge)
    '''      -> creer T140Reglement + T141ReglementDocument
    '''   2. Sinon -> abonnement MngConsul (compte principal)
    '''      -> lier Stripe Customer au user MngConsul
    ''' </summary>
    Private Sub HandleCheckoutSessionCompleted(session As Checkout.Session)

        ' Detection : est-ce un paiement FOURNISSEUR ?
        Dim documentIdStr As String = GetMetadataValue(session.Metadata, "MngConsul_DocumentId", "")
        Dim documentId As Integer = 0
        Integer.TryParse(documentIdStr, documentId)

        If documentId > 0 Then
            ' Cas paiement fournisseur (Stripe Connect Direct Charge)
            HandleSupplierPaymentCompleted(session, documentId)
            Return
        End If

        ' Cas abonnement MngConsul - logique originale
        Dim userId As Integer = GetUserIdFromMetadata(session.Metadata)
        If userId = 0 Then Return

        If Not String.IsNullOrEmpty(session.CustomerId) Then
            ExecProc("s0644StripeCustomerLink", New Dictionary(Of String, Object) From {
                {"@UserId", userId},
                {"@StripeCustomerId", session.CustomerId}
            })
        End If
    End Sub

    ''' <summary>
    ''' Traitement specifique d'un paiement fournisseur reussi via Stripe Connect.
    ''' Cree un decaissement (T140Reglement) lie a la facture (T141ReglementDocument).
    ''' Idempotent via s0080 (cle = StripeSessionId).
    ''' </summary>
    Private Sub HandleSupplierPaymentCompleted(session As Checkout.Session, documentId As Integer)
        Try
            ' Extraire les autres metadata
            Dim partyIdStr As String = GetMetadataValue(session.Metadata, "MngConsul_PartyId", "0")
            Dim userIdStr As String = GetMetadataValue(session.Metadata, "MngConsul_UserId", "0")
            Dim companyGuidStr As String = GetMetadataValue(session.Metadata, "MngConsul_CompanyGUID", "")
            Dim paymentMethod As String = GetMetadataValue(session.Metadata, "MngConsul_PaymentMethod", "card")
            Dim originalAmountStr As String = GetMetadataValue(session.Metadata, "MngConsul_OriginalAmount", "0")

            Dim partyId As Integer = 0
            Dim userId As Integer = 0
            Integer.TryParse(partyIdStr, partyId)
            Integer.TryParse(userIdStr, userId)

            Dim companyGuid As Guid = Guid.Empty
            Guid.TryParse(companyGuidStr, companyGuid)

            Dim originalAmount As Decimal = 0D
            Decimal.TryParse(originalAmountStr, System.Globalization.NumberStyles.Any,
                              System.Globalization.CultureInfo.InvariantCulture, originalAmount)

            If partyId = 0 OrElse companyGuid = Guid.Empty OrElse originalAmount <= 0D Then
                System.Diagnostics.Debug.WriteLine("HandleSupplierPaymentCompleted: metadata incompletes")
                Return
            End If

            ' Creer le decaissement (idempotent)
            ExecProc("s0080CreateDecaissementFromStripe", New Dictionary(Of String, Object) From {
                {"@CompanyGUID", companyGuid},
                {"@PartyId", partyId},
                {"@DocumentId", documentId},
                {"@Amount", originalAmount},
                {"@StripeSessionId", session.Id},
                {"@StripePaymentIntentId", If(String.IsNullOrEmpty(session.PaymentIntentId), CType(DBNull.Value, Object), session.PaymentIntentId)},
                {"@PaymentMethod", paymentMethod},
                {"@CreatedByUserId", If(userId > 0, CType(userId, Object), DBNull.Value)}
            })

            ' === Si autorisation auto-paiement demandee : creer T144Authorization ===
            ' L'utilisateur a coche la case "Autoriser auto-paiement" dans le modal,
            ' et Stripe a sauvegarde la PaymentMethod (setup_future_usage=off_session).
            ' On recupere les details de la PM et on cree l'autorisation en BD.
            Dim authorizeAutoPay As String = GetMetadataValue(session.Metadata, "MngConsul_AuthorizeAutoPay", "false")
            If String.Compare(authorizeAutoPay, "true", True) = 0 Then
                Try
                    CreateAutoPayAuthorizationFromSession(session, companyGuid, partyId, paymentMethod)
                Catch ex As Exception
                    ' Non-bloquant : le paiement (T140Reglement) est deja cree.
                    ' On loggue mais on ne fait pas echouer le webhook complet.
                    System.Diagnostics.Debug.WriteLine("CreateAutoPayAuthorizationFromSession FAILED (non-blocking): " & ex.Message)
                End Try
            End If

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("HandleSupplierPaymentCompleted error: " & ex.Message)
            Throw  ' Faire echouer le webhook pour que Stripe retente
        End Try
    End Sub

    ''' <summary>
    ''' Apres un paiement reussi avec setup_future_usage=off_session, recupere les
    ''' details de la PaymentMethod sauvegardee et cree une T144AuthorizationAutoPay.
    ''' </summary>
    Private Sub CreateAutoPayAuthorizationFromSession(session As Checkout.Session,
                                                       companyGuid As Guid,
                                                       partyId As Integer,
                                                       paymentMethodType As String)
        ' 1. Recuperer stripeAccountId du fournisseur (necessaire pour appels Connect)
        Dim stripeAccountId As String = GetStripeAccountIdForParty(companyGuid, partyId)
        If String.IsNullOrEmpty(stripeAccountId) Then
            System.Diagnostics.Debug.WriteLine("AutoPay setup : StripeAccountId introuvable pour PartyId=" & partyId)
            Return
        End If

        ' 2. Recuperer le PartyGUID (necessaire pour T144.PartyGUID)
        Dim partyGuid As Guid = GetPartyGuidFromId(companyGuid, partyId)
        If partyGuid = Guid.Empty Then
            System.Diagnostics.Debug.WriteLine("AutoPay setup : PartyGUID introuvable pour PartyId=" & partyId)
            Return
        End If

        ' 3. Recuperer le PaymentIntent (sur compte connecte) pour obtenir le PaymentMethodId
        Dim paymentIntentId As String = session.PaymentIntentId
        If String.IsNullOrEmpty(paymentIntentId) Then
            System.Diagnostics.Debug.WriteLine("AutoPay setup : session.PaymentIntentId vide")
            Return
        End If

        Dim pi As PaymentIntent = clsStripe.GetPaymentIntentFromConnectedAccount(paymentIntentId, stripeAccountId)
        If pi Is Nothing OrElse String.IsNullOrEmpty(pi.PaymentMethodId) Then
            System.Diagnostics.Debug.WriteLine("AutoPay setup : PaymentMethod introuvable sur PI " & paymentIntentId)
            Return
        End If

        Dim paymentMethodId As String = pi.PaymentMethodId
        Dim customerId As String = pi.CustomerId
        If String.IsNullOrEmpty(customerId) Then
            ' Fallback : prendre depuis session.CustomerId
            customerId = session.CustomerId
        End If

        If String.IsNullOrEmpty(customerId) Then
            System.Diagnostics.Debug.WriteLine("AutoPay setup : CustomerId introuvable - setup_future_usage a echoue ?")
            Return
        End If

        ' 4. Recuperer les details de la PaymentMethod
        Dim pm As PaymentMethod = clsStripe.GetPaymentMethodFromConnectedAccount(paymentMethodId, stripeAccountId)
        If pm Is Nothing Then
            System.Diagnostics.Debug.WriteLine("AutoPay setup : PaymentMethod inaccessible (pm=" & paymentMethodId & ")")
            Return
        End If

        ' Confirmer le type
        Dim effectiveMethodType As String = If(String.IsNullOrEmpty(pm.Type), paymentMethodType, pm.Type)
        ' Stripe peut classer Interac comme 'card' - on garde 'card' pour T144
        If effectiveMethodType <> "card" AndAlso effectiveMethodType <> "acss_debit" Then
            effectiveMethodType = "card"
        End If

        ' 5. Lire UserGUID + metadata audit
        Dim userGuidStr As String = GetMetadataValue(session.Metadata, "MngConsul_UserGUID", "")
        Dim userGuid As Guid = Guid.Empty
        Guid.TryParse(userGuidStr, userGuid)
        If userGuid = Guid.Empty Then
            System.Diagnostics.Debug.WriteLine("AutoPay setup : UserGUID manquant dans metadata")
            Return
        End If

        Dim authorizedIp As String = GetMetadataValue(session.Metadata, "MngConsul_AuthorizedIp", "")
        Dim authorizedUserAgent As String = GetMetadataValue(session.Metadata, "MngConsul_AuthorizedUserAgent", "")
        Dim authorizationTextRef As String = GetMetadataValue(session.Metadata, "MngConsul_AuthorizationTextRef", "V1")
        Dim language As String = GetMetadataValue(session.Metadata, "MngConsul_AuthorizedLanguage", "fr-CA")

        ' Plafond mensuel (optionnel)
        Dim maxMonthlyStr As String = GetMetadataValue(session.Metadata, "MngConsul_MaxAmountPerMonth", "")
        Dim maxMonthly As Decimal = 0D
        If Not String.IsNullOrEmpty(maxMonthlyStr) Then
            Decimal.TryParse(maxMonthlyStr, System.Globalization.NumberStyles.Any,
                             System.Globalization.CultureInfo.InvariantCulture, maxMonthly)
        End If

        ' 6. Construire le texte legal complet (pour preuve de consentement)
        Dim authorizationText As String = BuildAuthorizationText(effectiveMethodType, maxMonthly, authorizationTextRef)

        ' 7. Extraire les details specifiques au type de PM
        Dim cardBrand As Object = DBNull.Value
        Dim cardLast4 As Object = DBNull.Value
        Dim cardExpMonth As Object = DBNull.Value
        Dim cardExpYear As Object = DBNull.Value
        Dim bankInstitution As Object = DBNull.Value
        Dim bankTransit As Object = DBNull.Value
        Dim bankLast4 As Object = DBNull.Value
        Dim mandateId As Object = DBNull.Value

        Try
            If pm.Card IsNot Nothing Then
                cardBrand = If(String.IsNullOrEmpty(pm.Card.Brand), CType(DBNull.Value, Object), pm.Card.Brand)
                cardLast4 = If(String.IsNullOrEmpty(pm.Card.Last4), CType(DBNull.Value, Object), pm.Card.Last4)
                cardExpMonth = pm.Card.ExpMonth
                cardExpYear = pm.Card.ExpYear
            End If
        Catch
        End Try

        Try
            If pm.AcssDebit IsNot Nothing Then
                bankInstitution = If(String.IsNullOrEmpty(pm.AcssDebit.InstitutionNumber), CType(DBNull.Value, Object), pm.AcssDebit.InstitutionNumber)
                bankTransit = If(String.IsNullOrEmpty(pm.AcssDebit.TransitNumber), CType(DBNull.Value, Object), pm.AcssDebit.TransitNumber)
                bankLast4 = If(String.IsNullOrEmpty(pm.AcssDebit.Last4), CType(DBNull.Value, Object), pm.AcssDebit.Last4)
            End If
        Catch
        End Try

        ' MandateId : seulement disponible si Stripe a cree un mandat ACSS
        Try
            ' Le mandate id peut etre sur pi.Mandate ou pi.LatestCharge.PaymentMethodDetails.AcssDebit.MandateId
            ' Pour ACSS, on prend depuis pm si dispo
        Catch
        End Try

        ' 8. Appeler s0085CreateAuthorizationAutoPay
        ExecProc("s0085CreateAuthorizationAutoPay", New Dictionary(Of String, Object) From {
            {"@CompanyGUID", companyGuid},
            {"@PartyId", partyId},
            {"@PartyGUID", partyGuid},
            {"@StripeAccountId", stripeAccountId},
            {"@StripeCustomerId", customerId},
            {"@StripePaymentMethodId", paymentMethodId},
            {"@PaymentMethodType", effectiveMethodType},
            {"@CardBrand", cardBrand},
            {"@CardLast4", cardLast4},
            {"@CardExpMonth", cardExpMonth},
            {"@CardExpYear", cardExpYear},
            {"@BankInstitutionNumber", bankInstitution},
            {"@BankTransitNumber", bankTransit},
            {"@BankAccountLast4", bankLast4},
            {"@StripeMandateId", mandateId},
            {"@PadAgreementUrl", DBNull.Value},
            {"@MaxAmountPerCharge", DBNull.Value},
            {"@MaxAmountPerMonth", If(maxMonthly > 0D, CType(maxMonthly, Object), DBNull.Value)},
            {"@AuthorizedByUserGUID", userGuid},
            {"@AuthorizedIpAddress", If(String.IsNullOrEmpty(authorizedIp), CType(DBNull.Value, Object), authorizedIp)},
            {"@AuthorizedUserAgent", If(String.IsNullOrEmpty(authorizedUserAgent), CType(DBNull.Value, Object), authorizedUserAgent)},
            {"@AuthorizationText", authorizationText},
            {"@AuthorizationLanguage", language}
        })

        System.Diagnostics.Debug.WriteLine("AutoPay setup : autorisation T144 creee pour PartyId=" & partyId & " UserGUID=" & userGuid.ToString())
    End Sub

    ''' <summary>
    ''' Recupere le StripeAccountId d'un fournisseur (T050Party.StripeAccountId).
    ''' </summary>
    Private Function GetStripeAccountIdForParty(companyGuid As Guid, partyId As Integer) As String
        Dim row As DataRow = ExecSimpleSelect(
            "SELECT StripeAccountId FROM dbo.T050Party WHERE Id = @PartyId AND CompanyGUID = @CompanyGUID",
            New Dictionary(Of String, Object) From {
                {"@PartyId", partyId},
                {"@CompanyGUID", companyGuid}
            })
        If row Is Nothing Then Return ""
        If row("StripeAccountId") Is DBNull.Value Then Return ""
        Return row("StripeAccountId").ToString()
    End Function

    ''' <summary>
    ''' Recupere le PartyGUID a partir de l'Id (T050Party.PartyGUID).
    ''' </summary>
    Private Function GetPartyGuidFromId(companyGuid As Guid, partyId As Integer) As Guid
        Dim row As DataRow = ExecSimpleSelect(
            "SELECT PartyGUID FROM dbo.T050Party WHERE Id = @PartyId AND CompanyGUID = @CompanyGUID",
            New Dictionary(Of String, Object) From {
                {"@PartyId", partyId},
                {"@CompanyGUID", companyGuid}
            })
        If row Is Nothing OrElse row("PartyGUID") Is DBNull.Value Then Return Guid.Empty
        Return CType(row("PartyGUID"), Guid)
    End Function

    ''' <summary>
    ''' Construit le texte legal qui sera stocke dans T144.AuthorizationText
    ''' (preuve de consentement en cas de litige).
    ''' </summary>
    Private Function BuildAuthorizationText(methodType As String, maxMonthly As Decimal, textRef As String) As String
        Dim sb As New StringBuilder()
        sb.AppendLine("=== Autorisation de paiement automatique fournisseur (MngConsul) ===")
        sb.AppendLine("Reference texte : " & textRef)
        sb.AppendLine("Date : " & DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss") & " UTC")
        sb.AppendLine("")
        If methodType = "card" Then
            sb.AppendLine("Type : Carte de credit/debit (MIT - Merchant-Initiated Transaction)")
            sb.AppendLine("J'autorise MngConsul a debiter automatiquement cette carte pour les factures fournisseur que j'aurai approuvees (saisies + comptabilisees), a leur date d'echeance.")
            sb.AppendLine("Je recevrai un email de preavis 24 heures avant chaque debit.")
        ElseIf methodType = "acss_debit" Then
            sb.AppendLine("Type : ACSS Debit / PAD (Pre-Authorized Debit - Regle H1 Paiements Canada)")
            sb.AppendLine("J'autorise les prelevements de type Affaires a montants variables sur le compte bancaire identifie.")
            sb.AppendLine("J'accepte un preavis raccourci de 3 jours avant chaque debit (conformement a la Regle H1).")
            sb.AppendLine("Droit de contestation : 10 jours. Droit au remboursement : 90 jours.")
        End If
        If maxMonthly > 0D Then
            sb.AppendLine("Plafond mensuel maximum : " & maxMonthly.ToString("F2") & " $ CAD")
        End If
        sb.AppendLine("")
        sb.AppendLine("Revocation : je peux annuler cette autorisation a tout moment depuis l'interface MngConsul (page Paiements automatiques).")
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' customer.subscription.created OR customer.subscription.updated :
    ''' insere ou met a jour T020Subscription.
    ''' </summary>
    Private Sub HandleSubscriptionUpdated(sub_ As Subscription)
        ' Resoudre UserId/CompanyGUID via metadata OU lookup customer
        Dim userInfo As DataRow = ResolveUserFromSubscription(sub_)
        If userInfo Is Nothing Then Return

        ' Mapping plan : on cherche le PlanCode/Name depuis T021Plan via StripePriceId
        Dim priceId As String = ""
        If sub_.Items IsNot Nothing AndAlso sub_.Items.Data IsNot Nothing AndAlso sub_.Items.Data.Count > 0 Then
            priceId = sub_.Items.Data(0).Price.Id
        End If

        Dim planInfo As DataRow = GetPlanFromStripePriceId(priceId, sub_.Metadata)
        Dim planCode As String = If(planInfo IsNot Nothing, planInfo("Code").ToString(),
                                     GetMetadataValue(sub_.Metadata, "MngConsul_PlanCode", "unknown"))
        Dim planName As String = If(planInfo IsNot Nothing, planInfo("Name").ToString(), planCode)
        Dim amount As Decimal = If(planInfo IsNot Nothing, CDec(planInfo("Amount")), 0D)
        Dim currency As String = If(planInfo IsNot Nothing, planInfo("Currency").ToString(), "CAD")
        Dim billingCycle As String = If(planInfo IsNot Nothing, planInfo("BillingCycle").ToString(),
                                         GetMetadataValue(sub_.Metadata, "MngConsul_BillingCycle", "monthly"))

        ' Mapping status Stripe -> MngConsul
        Dim status As String = MapStripeStatus(sub_.Status)
        Dim isTrial As Boolean = (sub_.Status = "trialing")

        ' CurrentPeriodEnd est maintenant sur SubscriptionItem (Stripe API 2024+)
        Dim periodEnd As Date = clsStripe.GetSubscriptionPeriodEnd(sub_)

        ExecProc("s0643StripeSubscriptionUpsert", New Dictionary(Of String, Object) From {
            {"@StripeSubscriptionId", sub_.Id},
            {"@UserId", CInt(userInfo("UserId"))},
            {"@CompanyGUID", CType(userInfo("CompanyGUID"), Guid)},
            {"@PlanCode", planCode},
            {"@PlanName", planName},
            {"@Amount", amount},
            {"@Currency", currency},
            {"@BillingCycle", billingCycle},
            {"@Status", status},
            {"@StartDate", sub_.StartDate},
            {"@NextBillingDate", If(periodEnd <> Date.MinValue, CType(periodEnd, Object), DBNull.Value)},
            {"@EndDate", If(sub_.CanceledAt.HasValue, CType(sub_.CanceledAt.Value, Object), DBNull.Value)},
            {"@IsTrial", If(isTrial, 1, 0)},
            {"@TrialEndOn", If(sub_.TrialEnd.HasValue, CType(sub_.TrialEnd.Value, Object), DBNull.Value)}
        })
    End Sub

    ''' <summary>
    ''' customer.subscription.deleted : annulation definitive.
    ''' </summary>
    Private Sub HandleSubscriptionDeleted(sub_ As Subscription)
        Dim userInfo As DataRow = ResolveUserFromSubscription(sub_)
        If userInfo Is Nothing Then Return

        ' Reutilise upsert avec status='cancelled' et EndDate maintenant
        ExecProc("s0643StripeSubscriptionUpsert", New Dictionary(Of String, Object) From {
            {"@StripeSubscriptionId", sub_.Id},
            {"@UserId", CInt(userInfo("UserId"))},
            {"@CompanyGUID", CType(userInfo("CompanyGUID"), Guid)},
            {"@PlanCode", GetMetadataValue(sub_.Metadata, "MngConsul_PlanCode", "unknown")},
            {"@PlanName", "Cancelled"},
            {"@Amount", 0D},
            {"@Currency", "CAD"},
            {"@BillingCycle", "monthly"},
            {"@Status", "cancelled"},
            {"@StartDate", sub_.StartDate},
            {"@NextBillingDate", DBNull.Value},
            {"@EndDate", DateTime.UtcNow},
            {"@IsTrial", 0},
            {"@TrialEndOn", DBNull.Value}
        })
    End Sub

    ''' <summary>
    ''' invoice.payment_succeeded : paiement recurrent reussi.
    ''' Met a jour NextBillingDate sur T020Subscription.
    ''' </summary>
    Private Sub HandleInvoicePaymentSucceeded(invoice As Invoice)
        ' Pour les renouvellements, customer.subscription.updated arrive aussi
        ' donc on a peu de chose a faire ici. On peut juste s'assurer que
        ' le statut est 'active' au cas ou il etait 'past_due'.
        ' Note : SubscriptionId est maintenant sur Invoice.Parent.SubscriptionDetails (Stripe API 2025+)
        Dim subId As String = clsStripe.GetInvoiceSubscriptionId(invoice)
        If String.IsNullOrEmpty(subId) Then Return

        ExecSimpleUpdate(
            "UPDATE dbo.T020Subscription SET Status = 'active', ModifiedOn = GETDATE(), " &
            "ModifiedBy = 'StripeWebhook' WHERE TransactionId = @SubId AND ProcessorName = 'Stripe' " &
            "AND Status = 'past_due'",
            New Dictionary(Of String, Object) From {{"@SubId", subId}}
        )
    End Sub

    ''' <summary>
    ''' invoice.payment_failed : echec de paiement recurrent.
    ''' Met le statut a 'past_due'. Stripe va re-essayer automatiquement.
    ''' </summary>
    Private Sub HandleInvoicePaymentFailed(invoice As Invoice)
        ' Note : SubscriptionId est maintenant sur Invoice.Parent.SubscriptionDetails (Stripe API 2025+)
        Dim subId As String = clsStripe.GetInvoiceSubscriptionId(invoice)
        If String.IsNullOrEmpty(subId) Then Return

        ExecSimpleUpdate(
            "UPDATE dbo.T020Subscription SET Status = 'past_due', ModifiedOn = GETDATE(), " &
            "ModifiedBy = 'StripeWebhook' WHERE TransactionId = @SubId AND ProcessorName = 'Stripe'",
            New Dictionary(Of String, Object) From {{"@SubId", subId}}
        )
    End Sub

    ' =========================================================================
    ' HELPERS RESOLUTION USER / PLAN
    ' =========================================================================

    Private Function ResolveUserFromSubscription(sub_ As Subscription) As DataRow
        ' D'abord : metadata (cas normal, mis dans wbfPayment.aspx.vb)
        Dim userIdFromMeta As Integer = GetUserIdFromMetadata(sub_.Metadata)
        If userIdFromMeta > 0 Then
            Return GetUserById(userIdFromMeta)
        End If

        ' Fallback : lookup par StripeCustomerId
        If Not String.IsNullOrEmpty(sub_.CustomerId) Then
            Return GetUserByStripeCustomerId(sub_.CustomerId)
        End If

        Return Nothing
    End Function

    Private Function GetUserIdFromMetadata(metadata As Dictionary(Of String, String)) As Integer
        If metadata Is Nothing Then Return 0
        Dim val As String = Nothing
        If metadata.TryGetValue("MngConsul_UserId", val) AndAlso Not String.IsNullOrEmpty(val) Then
            Dim parsed As Integer
            If Integer.TryParse(val, parsed) Then Return parsed
        End If
        Return 0
    End Function

    Private Function GetMetadataValue(metadata As Dictionary(Of String, String), key As String, defaultValue As String) As String
        If metadata Is Nothing Then Return defaultValue
        Dim val As String = Nothing
        If metadata.TryGetValue(key, val) AndAlso Not String.IsNullOrEmpty(val) Then Return val
        Return defaultValue
    End Function

    Private Function GetUserById(userId As Integer) As DataRow
        ' Reconstitue un DataRow compatible avec les autres helpers (colonnes UserId + CompanyGUID)
        Dim sql As String = "SELECT Id AS UserId, CompanyGUID, Email, FirstName, LastName, StripeCustomerId " &
                            "FROM dbo.T015User WHERE Id = @UserId AND IsDeleted = 0"
        Return ExecSimpleSelect(sql, New Dictionary(Of String, Object) From {{"@UserId", userId}})
    End Function

    Private Function GetUserByStripeCustomerId(stripeCustomerId As String) As DataRow
        Dim ds As DataSet = ExecuteProcDs("s0645GetUserByStripeCustomerId",
            New Dictionary(Of String, Object) From {{"@StripeCustomerId", stripeCustomerId}})
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
            Return ds.Tables(0).Rows(0)
        End If
        Return Nothing
    End Function

    Private Function GetPlanFromStripePriceId(priceId As String, metadata As Dictionary(Of String, String)) As DataRow
        If Not String.IsNullOrEmpty(priceId) Then
            Dim sql As String = "SELECT TOP 1 Code, Name, Amount, Currency, BillingCycle " &
                                "FROM dbo.T021Plan WHERE StripePriceId = @PriceId AND IsDeleted = 0"
            Dim row As DataRow = ExecSimpleSelect(sql, New Dictionary(Of String, Object) From {{"@PriceId", priceId}})
            If row IsNot Nothing Then Return row
        End If

        ' Fallback : lookup via metadata (PlanCode + BillingCycle)
        Dim planCode As String = GetMetadataValue(metadata, "MngConsul_PlanCode", "")
        Dim billingCycle As String = GetMetadataValue(metadata, "MngConsul_BillingCycle", "monthly")
        If Not String.IsNullOrEmpty(planCode) Then
            Dim ds As DataSet = ExecuteProcDs("s0631GetPlanByCode",
                New Dictionary(Of String, Object) From {
                    {"@Code", planCode},
                    {"@BillingCycle", billingCycle}
                })
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return ds.Tables(0).Rows(0)
            End If
        End If

        Return Nothing
    End Function

    Private Function MapStripeStatus(stripeStatus As String) As String
        Select Case stripeStatus
            Case "active"             : Return "active"
            Case "trialing"           : Return "trial"
            Case "past_due"           : Return "past_due"
            Case "canceled"           : Return "cancelled"
            Case "incomplete"         : Return "pending"
            Case "incomplete_expired" : Return "expired"
            Case "unpaid"             : Return "unpaid"
            Case "paused"             : Return "paused"
            Case Else                 : Return stripeStatus
        End Select
    End Function

    ' =========================================================================
    ' DB ACCESS HELPERS (direct SqlClient, pas via clsData car .ashx ne sait pas hériter de Page)
    ' =========================================================================

    Private ReadOnly Property ConnectionString As String
        Get
            Return ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    Private Function InsertEventIfNew(eventId As String, eventType As String, stripeCreated As DateTime,
                                       payload As String, customerId As String, subscriptionId As String) As Boolean
        Dim ds As DataSet = ExecuteProcDs("s0640StripeEventInsertIfNew",
            New Dictionary(Of String, Object) From {
                {"@StripeEventId", eventId},
                {"@EventType", eventType},
                {"@StripeCreated", stripeCreated},
                {"@Payload", payload},
                {"@StripeCustomerId", If(String.IsNullOrEmpty(customerId), CType(DBNull.Value, Object), customerId)},
                {"@StripeSubscriptionId", If(String.IsNullOrEmpty(subscriptionId), CType(DBNull.Value, Object), subscriptionId)}
            })
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
            Return CBool(ds.Tables(0).Rows(0)("WasInserted"))
        End If
        Return False
    End Function

    Private Sub MarkEventProcessed(eventId As String)
        ExecProc("s0641StripeEventMarkProcessed",
            New Dictionary(Of String, Object) From {{"@StripeEventId", eventId}})
    End Sub

    Private Sub MarkEventFailed(eventId As String, errorMessage As String)
        ExecProc("s0642StripeEventMarkFailed",
            New Dictionary(Of String, Object) From {
                {"@StripeEventId", eventId},
                {"@ErrorMessage", errorMessage}
            })
    End Sub

    Private Sub MarkEventSkipped(eventId As String, reason As String)
        ExecSimpleUpdate(
            "UPDATE dbo.tStripeEvenement SET ProcessingStatus = 'skipped', " &
            "ProcessedOn = GETDATE(), ErrorMessage = @Msg WHERE StripeEventId = @EventId",
            New Dictionary(Of String, Object) From {
                {"@Msg", reason},
                {"@EventId", eventId}
            })
    End Sub

    Private Sub ExecProc(procName As String, params_ As Dictionary(Of String, Object))
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand(procName, conn)
                cmd.CommandType = CommandType.StoredProcedure
                For Each kvp In params_
                    cmd.Parameters.AddWithValue(kvp.Key, If(kvp.Value, DBNull.Value))
                Next
                conn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Private Function ExecuteProcDs(procName As String, params_ As Dictionary(Of String, Object)) As DataSet
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand(procName, conn)
                cmd.CommandType = CommandType.StoredProcedure
                For Each kvp In params_
                    cmd.Parameters.AddWithValue(kvp.Key, If(kvp.Value, DBNull.Value))
                Next
                Using da As New SqlDataAdapter(cmd)
                    Dim ds As New DataSet()
                    da.Fill(ds)
                    Return ds
                End Using
            End Using
        End Using
    End Function

    Private Sub ExecSimpleUpdate(sql As String, params_ As Dictionary(Of String, Object))
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand(sql, conn)
                cmd.CommandType = CommandType.Text
                For Each kvp In params_
                    cmd.Parameters.AddWithValue(kvp.Key, If(kvp.Value, DBNull.Value))
                Next
                conn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Private Function ExecSimpleSelect(sql As String, params_ As Dictionary(Of String, Object)) As DataRow
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand(sql, conn)
                cmd.CommandType = CommandType.Text
                For Each kvp In params_
                    cmd.Parameters.AddWithValue(kvp.Key, If(kvp.Value, DBNull.Value))
                Next
                Using da As New SqlDataAdapter(cmd)
                    Dim ds As New DataSet()
                    da.Fill(ds)
                    If ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                        Return ds.Tables(0).Rows(0)
                    End If
                End Using
            End Using
        End Using
        Return Nothing
    End Function

End Class
