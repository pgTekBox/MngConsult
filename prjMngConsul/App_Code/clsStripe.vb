Imports System
Imports System.Collections.Generic
Imports System.Configuration
Imports Stripe
Imports Stripe.Checkout

''' <summary>
''' Helper Stripe pour MngConsul. Encapsule les appels API Stripe pour
''' Checkout Sessions, Customers et Subscriptions.
'''
''' PRE-REQUIS : installer le NuGet "Stripe.net" dans le projet.
''' (Visual Studio - Manage NuGet Packages - chercher "Stripe.net" officiel).
'''
''' Cles API lues depuis Web.config :
'''   Stripe.SecretKey       (sk_test_xxx ou sk_live_xxx)
'''   Stripe.PublishableKey  (utilise cote client si besoin de Stripe.js)
'''   Stripe.WebhookSecret   (whsec_xxx, utilise par StripeWebhook.ashx)
''' </summary>
Public Class clsStripe

    ''' <summary>
    ''' Initialise la cle API Stripe au demarrage de l'application.
    ''' Appelee une fois lors du premier appel.
    ''' </summary>
    Private Shared _initialized As Boolean = False
    Private Shared ReadOnly _initLock As New Object()

    Private Shared Sub EnsureInitialized()
        If _initialized Then Return
        SyncLock _initLock
            If _initialized Then Return
            Dim secretKey As String = ConfigurationManager.AppSettings("Stripe.SecretKey")
            If String.IsNullOrEmpty(secretKey) Then
                Throw New InvalidOperationException("Stripe.SecretKey n'est pas configure dans Web.config.")
            End If
            StripeConfiguration.ApiKey = secretKey
            _initialized = True
        End SyncLock
    End Sub

    ''' <summary>
    ''' Cree une session Stripe Checkout pour un abonnement recurrent.
    ''' Retourne l'URL vers laquelle rediriger l'utilisateur.
    '''
    ''' Apres paiement, Stripe redirigera vers SuccessUrl avec ?session_id=cs_xxx
    ''' Si l'utilisateur annule, redirige vers CancelUrl.
    ''' </summary>
    ''' <param name="customerEmail">Email du user (Stripe creera le Customer si pas existant)</param>
    ''' <param name="stripeCustomerId">cus_xxx si deja existant (NULL/empty = creation auto)</param>
    ''' <param name="priceId">price_xxx du forfait (depuis T021Plan.StripePriceId)</param>
    ''' <param name="successUrl">URL absolue de retour apres succes</param>
    ''' <param name="cancelUrl">URL absolue de retour si annulation</param>
    ''' <param name="trialDays">Nombre de jours d'essai gratuit (0 = pas d'essai)</param>
    ''' <param name="metadata">Metadata custom a attacher a la subscription (Dictionnaire facultatif)</param>
    ''' <returns>URL Stripe Checkout (https://checkout.stripe.com/...)</returns>
    Public Shared Function CreateCheckoutSession(
        customerEmail As String,
        stripeCustomerId As String,
        priceId As String,
        successUrl As String,
        cancelUrl As String,
        Optional trialDays As Integer = 0,
        Optional metadata As Dictionary(Of String, String) = Nothing
    ) As String

        EnsureInitialized()

        ' Lecture du flag EnableAutomaticTax depuis Web.config (default false)
        ' Stripe Tax requiert une adresse de siege social configuree dans le dashboard.
        ' Si false, MngConsul calcule TPS/TVQ manuellement cote wbfPayment.aspx.
        Dim enableAutoTax As Boolean = False
        Dim autoTaxSetting As String = ConfigurationManager.AppSettings("Stripe.EnableAutomaticTax")
        If Not String.IsNullOrEmpty(autoTaxSetting) Then
            Boolean.TryParse(autoTaxSetting, enableAutoTax)
        End If

        ' Construction des options de la session
        Dim options As New SessionCreateOptions With {
            .Mode = "subscription",
            .SuccessUrl = successUrl & (If(successUrl.Contains("?"), "&", "?")) & "session_id={CHECKOUT_SESSION_ID}",
            .CancelUrl = cancelUrl,
            .LineItems = New List(Of SessionLineItemOptions) From {
                New SessionLineItemOptions With {
                    .Price = priceId,
                    .Quantity = 1
                }
            },
            .BillingAddressCollection = "required",
            .AllowPromotionCodes = True
        }

        ' AutomaticTax seulement si activee dans Web.config (et configuree cote Stripe Dashboard)
        If enableAutoTax Then
            options.AutomaticTax = New SessionAutomaticTaxOptions With {.Enabled = True}
        End If

        ' Customer : reutiliser cus_xxx si existant, sinon utiliser email
        ' Note : en mode "subscription", Stripe cree TOUJOURS un Customer automatiquement,
        ' donc CustomerCreation est interdit (reserve au mode "payment").
        If Not String.IsNullOrEmpty(stripeCustomerId) AndAlso stripeCustomerId.StartsWith("cus_") Then
            options.Customer = stripeCustomerId
        Else
            options.CustomerEmail = customerEmail
        End If

        ' Essai gratuit si specifie
        If trialDays > 0 Then
            options.SubscriptionData = New SessionSubscriptionDataOptions With {
                .TrialPeriodDays = trialDays
            }
        End If

        ' Metadata custom (visible dans Stripe Dashboard + webhooks)
        If metadata IsNot Nothing AndAlso metadata.Count > 0 Then
            options.Metadata = metadata
            ' Aussi attacher aux subscription pour qu'on les retrouve dans webhooks
            If options.SubscriptionData Is Nothing Then
                options.SubscriptionData = New SessionSubscriptionDataOptions With {
                    .Metadata = metadata
                }
            Else
                options.SubscriptionData.Metadata = metadata
            End If
        End If

        ' Locale francaise pour clients quebecois
        options.Locale = "fr-CA"

        Dim service As New SessionService()
        Dim session As Session = service.Create(options)
        Return session.Url
    End Function

    ''' <summary>
    ''' Recupere une session Stripe Checkout existante (utilise par wbfPaymentSuccess
    ''' pour confirmer le paiement et lire les details).
    ''' </summary>
    Public Shared Function GetCheckoutSession(sessionId As String) As Session
        EnsureInitialized()
        Dim service As New SessionService()
        Return service.Get(sessionId)
    End Function

    ''' <summary>
    ''' Cree une Stripe Checkout Session pour payer un fournisseur via Stripe Connect
    ''' Direct Charge. L'argent va DIRECTEMENT au compte du fournisseur (acct_xxx),
    ''' MngConsul ne touche jamais l'argent.
    '''
    ''' Le montant est en cents (Long). Le caller doit deja avoir applique le gross-up
    ''' pour que le fournisseur recoive le montant facture exact (apres frais Stripe).
    ''' </summary>
    ''' <param name="stripeAccountId">acct_xxx du fournisseur (T050Party.StripeAccountId)</param>
    ''' <param name="amountInCents">Montant brut en cents (avec gross-up applique)</param>
    ''' <param name="currency">cad / usd / etc.</param>
    ''' <param name="paymentMethodType">card | interac_present | acss_debit</param>
    ''' <param name="description">Description (n° facture)</param>
    ''' <param name="successUrl">URL retour si succes</param>
    ''' <param name="cancelUrl">URL retour si annulation</param>
    ''' <param name="metadata">Metadonnees (DocumentId, PartyId, UserId, etc.)</param>
    ''' <param name="authorizeAutoPay">
    ''' Si True, demande a Stripe de sauvegarder la PaymentMethod (setup_future_usage
    ''' = off_session) et de creer un Customer sur le compte connecte. Necessaire pour
    ''' permettre les debits automatiques futurs (MIT - Merchant-Initiated Transactions).
    ''' La metadata doit aussi contenir MngConsul_AuthorizeAutoPay='true' pour que
    ''' le webhook cree l'autorisation T144 apres reussite.
    ''' </param>
    ''' <returns>URL Stripe Checkout</returns>
    Public Shared Function CreateSupplierPaymentSession(
        stripeAccountId As String,
        amountInCents As Long,
        currency As String,
        paymentMethodType As String,
        description As String,
        successUrl As String,
        cancelUrl As String,
        Optional metadata As Dictionary(Of String, String) = Nothing,
        Optional authorizeAutoPay As Boolean = False
    ) As String

        EnsureInitialized()

        ' Direct Charge : on agit au nom du compte du fournisseur
        ' (le request est envoye avec header Stripe-Account: acct_xxx)
        Dim requestOptions As New RequestOptions With {
            .StripeAccount = stripeAccountId
        }

        ' Construction des options de la session
        Dim options As New SessionCreateOptions With {
            .Mode = "payment",
            .SuccessUrl = successUrl & (If(successUrl.Contains("?"), "&", "?")) & "session_id={CHECKOUT_SESSION_ID}",
            .CancelUrl = cancelUrl,
            .LineItems = New List(Of SessionLineItemOptions) From {
                New SessionLineItemOptions With {
                    .PriceData = New SessionLineItemPriceDataOptions With {
                        .Currency = currency,
                        .UnitAmount = amountInCents,
                        .ProductData = New SessionLineItemPriceDataProductDataOptions With {
                            .Name = If(String.IsNullOrEmpty(description), "Paiement fournisseur", description)
                        }
                    },
                    .Quantity = 1
                }
            },
            .BillingAddressCollection = "auto",
            .Locale = "fr-CA"
        }

        ' Restreindre la methode de paiement choisie par l'utilisateur.
        '
        ' IMPORTANT : Stripe Checkout n'accepte PAS 'interac_present' (qui est
        ' reserve au Terminal physique). Pour Interac online, il faut laisser
        ' Stripe afficher toutes les methodes activees dans Dashboard
        ' (Interac apparaitra automatiquement si active cote Stripe).
        '
        ' Types acceptes par Stripe Checkout :
        '   card, acss_debit, affirm, klarna, paypal, link, pay_by_bank, etc.
        '   (voir https://docs.stripe.com/payments/payment-methods/integration-options)
        Select Case paymentMethodType
            Case "card", "acss_debit"
                ' Types valides : on peut restreindre
                options.PaymentMethodTypes = New List(Of String) From {paymentMethodType}
            Case "interac_present", "interac"
                ' Interac online : ne pas restreindre, Stripe affichera selon Dashboard.
                ' (Interac debit apparait via card, ou via pay_by_bank si active)
                ' On ne specifie pas PaymentMethodTypes -> Stripe utilise tous ceux actifs.
            Case Else
                ' Autres : ne pas restreindre
        End Select

        ' Pour ACSS Debit, options de mandat requises
        ' Note : en mode "payment", la currency vient du LineItem - on NE doit PAS
        ' la repeter dans PaymentMethodOptions.AcssDebit.Currency (Stripe la rejette).
        If paymentMethodType = "acss_debit" Then
            options.PaymentMethodOptions = New SessionPaymentMethodOptionsOptions With {
                .AcssDebit = New SessionPaymentMethodOptionsAcssDebitOptions With {
                    .MandateOptions = New SessionPaymentMethodOptionsAcssDebitMandateOptionsOptions With {
                        .PaymentSchedule = "sporadic",
                        .TransactionType = "business"
                    }
                }
            }
        End If

        ' Initialisation PaymentIntentData (metadata + setup_future_usage)
        ' Doit etre initialise meme si pas de metadata, si on veut activer authorizeAutoPay
        Dim hasMetadata As Boolean = (metadata IsNot Nothing AndAlso metadata.Count > 0)
        If hasMetadata Or authorizeAutoPay Then
            options.PaymentIntentData = New SessionPaymentIntentDataOptions()

            If hasMetadata Then
                options.Metadata = metadata
                options.PaymentIntentData.Metadata = metadata
            End If

            ' === MIT (Merchant-Initiated Transactions) ===
            ' Demander a Stripe de sauvegarder la PaymentMethod pour usage futur
            ' off-session (debits automatiques). Necessite un Customer.
            If authorizeAutoPay Then
                options.PaymentIntentData.SetupFutureUsage = "off_session"

                ' En mode payment, Stripe Checkout ne cree PAS de Customer par defaut.
                ' CustomerCreation = "always" force la creation d'un Customer sur le
                ' compte connecte pour stocker la PaymentMethod.
                options.CustomerCreation = "always"

                ' Pour les cartes : enregistrer automatiquement le mode "off_session"
                ' permet aussi l'authentification 3DS au moment de l'autorisation
                ' (le client doit confirmer 3DS pour autoriser les debits futurs).
            End If
        End If

        Dim service As New SessionService()
        Dim session As Session = service.Create(options, requestOptions)
        Return session.Url
    End Function

    ''' <summary>
    ''' Recupere une PaymentMethod sur un compte connecte (Direct Charge).
    ''' Utilise par le webhook apres checkout.session.completed pour lire
    ''' les details (card.brand, card.last4, etc.) et creer la T144Authorization.
    ''' </summary>
    Public Shared Function GetPaymentMethodFromConnectedAccount(paymentMethodId As String, stripeAccountId As String) As PaymentMethod
        EnsureInitialized()
        If String.IsNullOrEmpty(paymentMethodId) Then Return Nothing
        Try
            Dim requestOptions As New RequestOptions With {.StripeAccount = stripeAccountId}
            Dim service As New PaymentMethodService()
            Return service.Get(paymentMethodId, Nothing, requestOptions)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("GetPaymentMethodFromConnectedAccount failed : " & ex.Message)
            Return Nothing
        End Try
    End Function

    ''' <summary>
    ''' Recupere un PaymentIntent sur un compte connecte. Sert a obtenir
    ''' le PaymentMethodId attache apres confirmation d'une checkout.session.
    ''' </summary>
    Public Shared Function GetPaymentIntentFromConnectedAccount(paymentIntentId As String, stripeAccountId As String) As PaymentIntent
        EnsureInitialized()
        If String.IsNullOrEmpty(paymentIntentId) Then Return Nothing
        Try
            Dim requestOptions As New RequestOptions With {.StripeAccount = stripeAccountId}
            Dim service As New PaymentIntentService()
            Return service.Get(paymentIntentId, Nothing, requestOptions)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("GetPaymentIntentFromConnectedAccount failed : " & ex.Message)
            Return Nothing
        End Try
    End Function

    ''' <summary>
    ''' Cree un PaymentIntent off-session pour debiter un Customer avec une
    ''' PaymentMethod deja sauvegardee. Mode MIT (Merchant-Initiated Transaction).
    '''
    ''' Utilise par AutoPayProcessor.ashx pour les debits automatiques.
    '''
    ''' Comportement :
    '''   - confirm = true : execute le paiement immediatement
    '''   - off_session = true : indique a Stripe qu'aucun client n'est present
    '''   - Si carte demande 3DS : retourne PI avec status 'requires_action'
    '''   - Si succes : retourne PI avec status 'succeeded'
    ''' </summary>
    ''' <param name="stripeAccountId">acct_xxx du fournisseur</param>
    ''' <param name="customerId">cus_xxx Customer sur compte connecte</param>
    ''' <param name="paymentMethodId">pm_xxx PaymentMethod sauvegardee</param>
    ''' <param name="amountInCents">Montant brut (avec gross-up)</param>
    ''' <param name="currency">cad</param>
    ''' <param name="description">Description visible dans Stripe (n° facture)</param>
    ''' <param name="metadata">Metadata MngConsul (DocumentId, etc.)</param>
    Public Shared Function CreateOffSessionPaymentIntent(
        stripeAccountId As String,
        customerId As String,
        paymentMethodId As String,
        amountInCents As Long,
        currency As String,
        description As String,
        Optional metadata As Dictionary(Of String, String) = Nothing
    ) As PaymentIntent

        EnsureInitialized()

        Dim requestOptions As New RequestOptions With {.StripeAccount = stripeAccountId}

        Dim options As New PaymentIntentCreateOptions With {
            .Amount = amountInCents,
            .Currency = currency,
            .Customer = customerId,
            .PaymentMethod = paymentMethodId,
            .Confirm = True,
            .OffSession = True,
            .Description = description
        }

        If metadata IsNot Nothing AndAlso metadata.Count > 0 Then
            options.Metadata = metadata
        End If

        Dim service As New PaymentIntentService()
        Return service.Create(options, requestOptions)
    End Function

    ''' <summary>
    ''' Detache une PaymentMethod d'un Customer sur compte connecte.
    ''' Appelee lors de la revocation d'une autorisation (s0090) pour que
    ''' la PM ne soit plus utilisable.
    ''' </summary>
    Public Shared Sub DetachPaymentMethodFromConnectedAccount(paymentMethodId As String, stripeAccountId As String)
        EnsureInitialized()
        If String.IsNullOrEmpty(paymentMethodId) Then Return
        Try
            Dim requestOptions As New RequestOptions With {.StripeAccount = stripeAccountId}
            Dim service As New PaymentMethodService()
            service.Detach(paymentMethodId, Nothing, requestOptions)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("DetachPaymentMethod failed : " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Recupere une session Checkout avec expansion : subscription complete,
    ''' product des line items, et invoice du subscription si dispo.
    ''' Utilise pour afficher le recu sur wbfPaymentSuccess.aspx.
    ''' </summary>
    Public Shared Function GetCheckoutSessionWithDetails(sessionId As String) As Session
        EnsureInitialized()
        Dim options As New SessionGetOptions
        options.Expand = New List(Of String) From {
            "subscription",
            "subscription.items",
            "line_items.data.price.product",
            "customer"
        }
        Dim service As New SessionService()
        Return service.Get(sessionId, options)
    End Function

    ''' <summary>
    ''' Retourne la fin de la periode courante d'une subscription.
    '''
    ''' L'API Stripe (a partir de v2024) a deplace CurrentPeriodEnd de Subscription
    ''' vers SubscriptionItem pour supporter des cycles de facturation differents
    ''' par item. Cette methode gere les deux cas (legacy + nouveau).
    '''
    ''' Retourne Date.MinValue si non trouvable.
    ''' </summary>
    Public Shared Function GetSubscriptionPeriodEnd(sub_ As Subscription) As Date
        If sub_ Is Nothing Then Return Date.MinValue
        Try
            If sub_.Items IsNot Nothing AndAlso sub_.Items.Data IsNot Nothing AndAlso sub_.Items.Data.Count > 0 Then
                Return sub_.Items.Data(0).CurrentPeriodEnd
            End If
        Catch
            ' Si echec, retourne MinValue (caller affichera "—")
        End Try
        Return Date.MinValue
    End Function

    ''' <summary>
    ''' Retourne le debut de la periode courante (meme logique que GetSubscriptionPeriodEnd).
    ''' </summary>
    Public Shared Function GetSubscriptionPeriodStart(sub_ As Subscription) As Date
        If sub_ Is Nothing Then Return Date.MinValue
        Try
            If sub_.Items IsNot Nothing AndAlso sub_.Items.Data IsNot Nothing AndAlso sub_.Items.Data.Count > 0 Then
                Return sub_.Items.Data(0).CurrentPeriodStart
            End If
        Catch
        End Try
        Return Date.MinValue
    End Function

    ''' <summary>
    ''' Retourne le SubscriptionId associe a un Invoice.
    '''
    ''' L'API Stripe (a partir de v2025-XX) a deplace Invoice.SubscriptionId vers
    ''' Invoice.Parent.SubscriptionDetails.Subscription pour supporter d'autres
    ''' types de "parent" (quotes, subscription_schedule, etc.).
    '''
    ''' Retourne chaine vide si l'invoice n'est pas lie a une subscription.
    ''' </summary>
    Public Shared Function GetInvoiceSubscriptionId(invoice As Invoice) As String
        If invoice Is Nothing Then Return ""

        ' Nouveau path : Parent.SubscriptionDetails.Subscription (ID string)
        Try
            If invoice.Parent IsNot Nothing AndAlso invoice.Parent.SubscriptionDetails IsNot Nothing Then
                Dim subId As String = invoice.Parent.SubscriptionDetails.SubscriptionId
                If Not String.IsNullOrEmpty(subId) Then Return subId
            End If
        Catch
        End Try

        Return ""
    End Function

    ''' <summary>
    ''' Cree un Stripe Customer (cus_xxx) - utile si on veut le creer en avance,
    ''' avant la premiere Checkout Session.
    ''' </summary>
    Public Shared Function CreateCustomer(email As String, name As String, Optional metadata As Dictionary(Of String, String) = Nothing) As Customer
        EnsureInitialized()

        Dim options As New CustomerCreateOptions With {
            .Email = email,
            .Name = name
        }
        If metadata IsNot Nothing AndAlso metadata.Count > 0 Then
            options.Metadata = metadata
        End If

        Dim service As New CustomerService()
        Return service.Create(options)
    End Function

    ''' <summary>
    ''' Cree une session pour le Stripe Customer Portal (page hebergee Stripe ou
    ''' le client peut gerer son abonnement : changer carte, annuler, voir factures).
    ''' </summary>
    Public Shared Function CreatePortalSession(stripeCustomerId As String, returnUrl As String) As String
        EnsureInitialized()

        Dim options As New Stripe.BillingPortal.SessionCreateOptions With {
            .Customer = stripeCustomerId,
            .ReturnUrl = returnUrl,
            .Locale = "fr-CA"
        }

        Dim service As New Stripe.BillingPortal.SessionService()
        Dim portalSession = service.Create(options)
        Return portalSession.Url
    End Function

    ''' <summary>
    ''' Recupere une Checkout Session sur un compte Connect (Direct Charge).
    ''' Necessite l'acct_xxx du compte connecte.
    ''' </summary>
    Public Shared Function GetCheckoutSessionFromConnectedAccount(sessionId As String, stripeAccountId As String) As Session
        EnsureInitialized()
        Dim requestOptions As New RequestOptions With {.StripeAccount = stripeAccountId}
        Dim service As New SessionService()
        Return service.Get(sessionId, Nothing, requestOptions)
    End Function

    ''' <summary>
    ''' Liste les Checkout Sessions recentes (limite 100) sur le compte connecte
    ''' d'un fournisseur, puis filtre client-side celles qui ont
    ''' metadata.MngConsul_DocumentId = documentId.
    '''
    ''' Utilise par la page de synchronisation manuelle (wbfSupplierPaymentSync)
    ''' pour retrouver les paiements Stripe lies a une facture, et detecter ceux
    ''' qui ne sont pas en BD (webhook rate, etc.).
    ''' </summary>
    Public Shared Function ListSessionsForDocument(stripeAccountId As String, documentId As Integer) As List(Of Session)
        EnsureInitialized()

        Dim requestOptions As New RequestOptions With {.StripeAccount = stripeAccountId}
        Dim listOptions As New SessionListOptions With {
            .Limit = 100,
            .Expand = New List(Of String) From {"data.payment_intent"}
        }

        Dim service As New SessionService()
        Dim allSessions = service.List(listOptions, requestOptions)

        Dim result As New List(Of Session)()
        Dim docIdStr As String = documentId.ToString()

        For Each s As Session In allSessions
            If s.Metadata IsNot Nothing Then
                Dim mdValue As String = Nothing
                If s.Metadata.TryGetValue("MngConsul_DocumentId", mdValue) AndAlso mdValue = docIdStr Then
                    result.Add(s)
                End If
            End If
        Next

        Return result
    End Function

    ' =========================================================================
    ' STRIPE CONNECT - ONBOARDING FOURNISSEUR (EXPRESS)
    ' =========================================================================

    ''' <summary>
    ''' Cree un Stripe Connected Account de type Express pour un fournisseur.
    ''' Retourne acct_xxx a stocker dans T050Party.StripeAccountId.
    ''' </summary>
    ''' <param name="email">Email du fournisseur</param>
    ''' <param name="businessName">Nom legal du fournisseur</param>
    ''' <param name="country">Code pays ISO (default CA)</param>
    ''' <param name="metadata">Metadata MngConsul (PartyId, CompanyGUID, etc.)</param>
    Public Shared Function CreateConnectExpressAccount(
        email As String,
        businessName As String,
        Optional country As String = "CA",
        Optional metadata As Dictionary(Of String, String) = Nothing
    ) As Account
        EnsureInitialized()

        Dim options As New AccountCreateOptions With {
            .Type = "express",
            .Country = country,
            .Email = email,
            .Capabilities = New AccountCapabilitiesOptions With {
                .CardPayments = New AccountCapabilitiesCardPaymentsOptions With {.Requested = True},
                .Transfers = New AccountCapabilitiesTransfersOptions With {.Requested = True}
            },
            .BusinessProfile = New AccountBusinessProfileOptions With {
                .Name = businessName
            }
        }

        If metadata IsNot Nothing AndAlso metadata.Count > 0 Then
            options.Metadata = metadata
        End If

        Dim service As New AccountService()
        Return service.Create(options)
    End Function

    ''' <summary>
    ''' Genere un AccountLink (URL d'onboarding hebergee par Stripe) pour qu'un
    ''' compte Connect Express puisse completer son inscription.
    '''
    ''' Les liens expirent rapidement (quelques minutes) - regenerer si necessaire.
    ''' </summary>
    Public Shared Function CreateAccountOnboardingLink(stripeAccountId As String, returnUrl As String, refreshUrl As String) As String
        EnsureInitialized()

        Dim options As New AccountLinkCreateOptions With {
            .Account = stripeAccountId,
            .ReturnUrl = returnUrl,
            .RefreshUrl = refreshUrl,
            .Type = "account_onboarding",
            .Collect = "eventually_due"
        }

        Dim service As New AccountLinkService()
        Dim link = service.Create(options)
        Return link.Url
    End Function

    ''' <summary>
    ''' Recupere le statut actuel d'un Connected Account (pour savoir si onboarding
    ''' est complete, s'il peut recevoir des paiements, etc.).
    ''' </summary>
    Public Shared Function GetConnectedAccount(stripeAccountId As String) As Account
        EnsureInitialized()
        Dim service As New AccountService()
        Return service.Get(stripeAccountId)
    End Function

    ''' <summary>
    ''' Verifie la signature d'un webhook Stripe (anti-spoofing).
    ''' A appeler dans StripeWebhook.ashx avant tout traitement.
    '''
    ''' Verifications strictes :
    '''   - Web.config contient Stripe.WebhookSecret non vide
    '''   - Le secret commence par 'whsec_'
    '''   - Payload et signature non vides
    '''   - Tolerance de 5 minutes pour le timestamp
    ''' </summary>
    Public Shared Function VerifyWebhookSignature(payload As String, signatureHeader As String) As [Event]

        Dim webhookSecret As String = ConfigurationManager.AppSettings("Stripe.WebhookSecret")

        ' === Diagnostic precis : tells exactly what's wrong ===
        If String.IsNullOrWhiteSpace(webhookSecret) Then
            Throw New InvalidOperationException(
                "Stripe.WebhookSecret est VIDE dans Web.config. Verifier la cle 'Stripe.WebhookSecret' " &
                "et redemarrer le pool IIS apres modification.")
        End If

        Dim trimmedSecret As String = webhookSecret.Trim()
        If trimmedSecret <> webhookSecret Then
            Throw New InvalidOperationException(
                "Stripe.WebhookSecret contient des espaces avant/apres. Supprimer les espaces dans Web.config.")
        End If

        If Not trimmedSecret.StartsWith("whsec_") Then
            Dim preview As String = If(trimmedSecret.Length > 10, trimmedSecret.Substring(0, 10), trimmedSecret)
            Throw New InvalidOperationException(
                "Stripe.WebhookSecret ne commence pas par 'whsec_' (valeur lue : '" & preview & "...'). " &
                "Verifier la cle dans Web.config et copier le bon secret depuis Stripe Dashboard.")
        End If

        If trimmedSecret = "whsec_PLACEHOLDER_REPLACE_WITH_REAL_SECRET" Then
            Throw New InvalidOperationException(
                "Stripe.WebhookSecret est encore le PLACEHOLDER. Remplacer par le vrai secret depuis Stripe Dashboard.")
        End If

        If String.IsNullOrEmpty(payload) Then
            Throw New InvalidOperationException("Body de la requete webhook est vide (impossible de verifier).")
        End If

        If String.IsNullOrEmpty(signatureHeader) Then
            Throw New InvalidOperationException("Header Stripe-Signature est vide (Stripe ne l'a pas envoye ?).")
        End If

        ' === Verification cryptographique ===
        ' Tolerance 5 minutes pour le timestamp (default Stripe)
        Return EventUtility.ConstructEvent(payload, signatureHeader, trimmedSecret, tolerance:=300, throwOnApiVersionMismatch:=False)
    End Function

End Class
