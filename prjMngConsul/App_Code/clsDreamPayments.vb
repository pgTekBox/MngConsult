Imports System
Imports System.Configuration
Imports System.Net
Imports System.Text
Imports Newtonsoft.Json.Linq

''' <summary>
''' Helper Dream Payments (InsureTech API) pour MngConsul.
''' Étape 1 (ce fichier) : authentification OAuth 2.0 en flow client_credentials,
''' avec mise en cache du token (valide ~1 h). Les appels métier (payees / payments
''' pour le paiement EFT des fournisseurs) viendront s'appuyer sur GetAccessToken().
'''
''' Même approche que clsSquare/clsStripe : HttpWebRequest + Newtonsoft.Json,
''' pas de SDK, configuration lue depuis Web.config &lt;appSettings&gt;.
'''
''' Clés Web.config :
'''   DreamPayments.Environment    ("sandbox" | "production")   défaut : sandbox
'''   DreamPayments.ClientId        (identifiant application, fourni par Dream)
'''   DreamPayments.ClientSecret    (secret application — À GARDER CÔTÉ SERVEUR)
'''   DreamPayments.TokenUrl        (optionnel — override de l'endpoint OAuth /token)
'''   DreamPayments.ApiBase         (optionnel — override de l'URL de base API)
''' </summary>
Public Class clsDreamPayments

    ' Endpoints par défaut du bac à sable (NPE) tirés du guide « Getting Started ».
    ' Les URLs de Production diffèrent et doivent être fournies via Web.config.
    Private Const SANDBOX_TOKEN_URL As String = "https://rails-c-npe-dreampayments-com.auth.us-east-1.amazoncognito.com/token"
    Private Const SANDBOX_API_BASE As String = "https://fapi-c-rails.npe.dreampayments.com"

    ' -------------------------------------------------------------------------
    ' Cache du token (statique, partagé entre requêtes). Thread-safe via _lock.
    ' -------------------------------------------------------------------------
    Private Shared _cachedToken As String
    Private Shared _tokenExpiresUtc As DateTime = DateTime.MinValue
    Private Shared ReadOnly _lock As New Object()

    ''' <summary>Infos renvoyées par l'endpoint OAuth /token.</summary>
    Public Class DreamTokenInfo
        Public Property AccessToken As String
        Public Property TokenType As String
        Public Property ExpiresIn As Integer
    End Class

    ' =========================================================================
    ' CONFIGURATION
    ' =========================================================================

    Private Shared Function IsProduction() As Boolean
        Dim env As String = ConfigurationManager.AppSettings("DreamPayments.Environment")
        Return Not String.IsNullOrEmpty(env) AndAlso env.Trim().ToLowerInvariant() = "production"
    End Function

    Private Shared Function ClientId() As String
        Return If(ConfigurationManager.AppSettings("DreamPayments.ClientId"), "").Trim()
    End Function

    Private Shared Function ClientSecret() As String
        Return If(ConfigurationManager.AppSettings("DreamPayments.ClientSecret"), "").Trim()
    End Function

    ''' <summary>True si ClientId et ClientSecret sont présents dans Web.config.</summary>
    Public Shared Function IsConfigured() As Boolean
        Return Not String.IsNullOrEmpty(ClientId()) AndAlso Not String.IsNullOrEmpty(ClientSecret())
    End Function

    ''' <summary>Endpoint OAuth /token. Sandbox par défaut ; en production il DOIT être configuré.</summary>
    Private Shared Function TokenUrl() As String
        Dim u As String = ConfigurationManager.AppSettings("DreamPayments.TokenUrl")
        If Not String.IsNullOrEmpty(u) Then Return u.Trim()
        If IsProduction() Then
            Throw New Exception("DreamPayments.TokenUrl (production) n'est pas configuré dans Web.config.")
        End If
        Return SANDBOX_TOKEN_URL
    End Function

    ''' <summary>URL de base des API. Sandbox par défaut ; en production elle DOIT être configurée.</summary>
    Public Shared Function ApiBase() As String
        Dim b As String = ConfigurationManager.AppSettings("DreamPayments.ApiBase")
        If Not String.IsNullOrEmpty(b) Then Return b.Trim().TrimEnd("/"c)
        If IsProduction() Then
            Throw New Exception("DreamPayments.ApiBase (production) n'est pas configuré dans Web.config.")
        End If
        Return SANDBOX_API_BASE
    End Function

    ' =========================================================================
    ' TOKEN OAUTH (client_credentials)
    ' =========================================================================

    ''' <summary>
    ''' Retourne un access token valide. Réutilise le token en cache tant qu'il n'est
    ''' pas expiré (marge de 60 s), sinon en demande un nouveau. Thread-safe.
    ''' </summary>
    ''' <param name="forceRefresh">True pour ignorer le cache et forcer un nouveau token.</param>
    Public Shared Function GetAccessToken(Optional forceRefresh As Boolean = False) As String
        SyncLock _lock
            If (Not forceRefresh) _
               AndAlso Not String.IsNullOrEmpty(_cachedToken) _
               AndAlso DateTime.UtcNow < _tokenExpiresUtc Then
                Return _cachedToken
            End If

            Dim info As DreamTokenInfo = RequestClientCredentialsToken()
            _cachedToken = info.AccessToken

            Dim ttl As Integer = If(info.ExpiresIn > 0, info.ExpiresIn, 3600)
            ' Marge de sécurité : on renouvelle 60 s avant l'expiration réelle.
            _tokenExpiresUtc = DateTime.UtcNow.AddSeconds(Math.Max(30, ttl - 60))

            Return _cachedToken
        End SyncLock
    End Function

    ''' <summary>
    ''' Appelle l'endpoint OAuth /token en grant_type=client_credentials.
    ''' Les identifiants (client_id:client_secret) sont envoyés en en-tête
    ''' Authorization: Basic base64(...), comme décrit dans le guide.
    ''' </summary>
    Public Shared Function RequestClientCredentialsToken() As DreamTokenInfo
        Dim cid As String = ClientId()
        Dim secret As String = ClientSecret()
        If String.IsNullOrEmpty(cid) OrElse String.IsNullOrEmpty(secret) Then
            Throw New Exception("DreamPayments : ClientId / ClientSecret manquants (Web.config appSettings).")
        End If

        Dim basic As String = Convert.ToBase64String(Encoding.UTF8.GetBytes(cid & ":" & secret))
        Dim respText As String = PostForm(TokenUrl(), "grant_type=client_credentials", basic)

        Dim root As JObject = JObject.Parse(respText)
        Dim info As New DreamTokenInfo()
        info.AccessToken = JStr(root("access_token"))
        info.TokenType = JStr(root("token_type"))
        Dim exp As Integer
        If root("expires_in") IsNot Nothing AndAlso Integer.TryParse(root("expires_in").ToString(), exp) Then
            info.ExpiresIn = exp
        End If

        If String.IsNullOrEmpty(info.AccessToken) Then
            Throw New Exception("DreamPayments : access_token absent dans la réponse OAuth. Réponse : " & respText)
        End If
        Return info
    End Function

    ''' <summary>Vide le cache du token (ex. après un 401, ou pour tests).</summary>
    Public Shared Sub ClearTokenCache()
        SyncLock _lock
            _cachedToken = Nothing
            _tokenExpiresUtc = DateTime.MinValue
        End SyncLock
    End Sub

    ''' <summary>Teste la configuration : obtient un token et renvoie True si OK (sinon lève).</summary>
    Public Shared Function TestConnection() As Boolean
        Return Not String.IsNullOrEmpty(GetAccessToken(forceRefresh:=True))
    End Function

    ' =========================================================================
    ' APPELS API (Bearer) — prêts pour les endpoints payees / payments à venir
    ' =========================================================================

    ''' <summary>POST JSON authentifié (Bearer). path relatif, ex. "/platform/payeeUsers".</summary>
    Public Shared Function ApiPost(path As String, jsonBody As String) As String
        Return SendJson(path, "POST", jsonBody)
    End Function

    ''' <summary>GET JSON authentifié (Bearer).</summary>
    Public Shared Function ApiGet(path As String) As String
        Return SendJson(path, "GET", Nothing)
    End Function

    ''' <summary>Envoi HTTP vers l'API Dream avec le token Bearer courant.</summary>
    Private Shared Function SendJson(path As String, method As String, jsonBody As String) As String
        Dim url As String = ApiBase() & path
        Dim token As String = GetAccessToken()

        EnsureTls12()
        Dim req As HttpWebRequest = DirectCast(WebRequest.Create(url), HttpWebRequest)
        req.Method = method
        req.Accept = "application/json"
        req.Headers.Add("Authorization", "Bearer " & token)

        If jsonBody IsNot Nothing Then
            req.ContentType = "application/json"
            Dim bytes As Byte() = Encoding.UTF8.GetBytes(jsonBody)
            req.ContentLength = bytes.Length
            Using rs As IO.Stream = req.GetRequestStream()
                rs.Write(bytes, 0, bytes.Length)
            End Using
        End If

        Return ReadResponse(req, "API")
    End Function

    ' =========================================================================
    ' MÉTHODES MÉTIER — Payees / Bank accounts / Payments (InsureTech API)
    '
    ' Séquence pour PAYER UN FOURNISSEUR PAR EFT :
    '   1) CreatePayee(...)                       -> payeeId + payeeUserId
    '   2) AddPayeeBankAccount(...)               -> bankAccountId (déclenche un
    '                                                micro-dépôt de vérification)
    '   3) (le fournisseur vérifie son compte)    -> VerifyBankAccount(...)  puis
    '                                                AcceptBankAccount(...)  => statut ACTIVE
    '   4) CreatePayment(...)                      -> paymentId
    '   5) AcceptPayment(paymentId, bankAccountId,
    '                    payeeUserId, "EFT")       -> déclenche le virement EFT
    '
    ' ⚠️ Les sous-objets marqués TODO (addresses, contactInfo, contactName,
    '    BankAccount variante EFT institution/transit/compte, amount/Money) ne sont
    '    PAS dans le PDF (export Swagger « collapsed »). Ils sont passés en JObject
    '    brut par l'appelant en attendant l'OpenAPI complet de l'InsureTech.
    '
    ' ⚠️ Base path « /platform » à CONFIRMER (le Getting Started appelle
    '    .../platform/payeeUsers ; la référence liste des chemins relatifs).
    ' =========================================================================

    ' -- Payees ---------------------------------------------------------------

    ''' <summary>Champs d'un bénéficiaire. Schéma confirmé via l'API Overview (exemples dépliés).</summary>
    Public Class PayeeInput
        ' payeeAccountInfo
        Public Property AccountName As String                 ' requis (nom du bénéficiaire)
        Public Property CustomerNumber As String
        Public Property PayeeType As String = "INSURED"       ' TODO : valeur adéquate pour un fournisseur ?
        ' Adresse (type BILLING)
        Public Property Address1 As String
        Public Property Address2 As String
        Public Property City As String
        Public Property Province As String                    ' ex. "QC"
        Public Property PostalCode As String                  ' -> zipCode
        ' payeeUserAccountInfo / contactName
        Public Property FirstName As String
        Public Property LastName As String
        ' contactInfo
        Public Property Email As String
        Public Property Phone As String                       ' ex. "15145551234"
        Public Property PreferredLanguage As String = "fr-CA"
    End Class

    Public Class PayeeCreatedResult
        Public Property PayeeId As String
        Public Property PayeeUserId As String
    End Class

    ''' <summary>POST /payees/add — crée le bénéficiaire (= fournisseur) et son utilisateur principal.</summary>
    Public Shared Function CreatePayee(input As PayeeInput) As PayeeCreatedResult
        If input Is Nothing OrElse String.IsNullOrWhiteSpace(input.AccountName) Then
            Throw New Exception("DreamPayments.CreatePayee : accountName est obligatoire.")
        End If

        ' payeeAccountInfo
        Dim acc As New JObject()
        acc("accountName") = input.AccountName
        If Not String.IsNullOrWhiteSpace(input.Address1) Then
            Dim a As New JObject()
            a("address") = input.Address1
            a("address2") = If(input.Address2, "")
            a("addressType") = "BILLING"
            AddIf(a, "city", input.City)
            a("primary") = True
            AddIf(a, "province", input.Province)
            AddIf(a, "zipCode", input.PostalCode)
            acc("addresses") = New JObject(New JProperty("address", New JArray(a)))
        End If
        AddIf(acc, "customerNumber", input.CustomerNumber)
        acc("payeeType") = input.PayeeType

        ' payeeUserAccountInfo
        Dim cname As New JObject()
        AddIf(cname, "firstName", input.FirstName)
        AddIf(cname, "lastName", input.LastName)

        Dim cinfo As New JObject()
        If Not String.IsNullOrWhiteSpace(input.Email) Then
            Dim em As New JObject()
            em("address") = input.Email
            em("emailStatus") = "NOT_VERIFIED"
            cinfo("emails") = New JObject(New JProperty("email", New JArray(em)))
        End If
        If Not String.IsNullOrWhiteSpace(input.Phone) Then
            Dim ph As New JObject()
            ph("deviceType") = "OTHER"
            ph("phoneNumber") = input.Phone
            cinfo("phones") = New JObject(New JProperty("phone", New JArray(ph)))
        End If

        Dim usr As New JObject()
        If cinfo.HasValues Then usr("contactInfo") = cinfo
        usr("contactName") = cname
        AddIf(usr, "preferredLanguage", input.PreferredLanguage)

        Dim body As New JObject()
        body("payeeAccountInfo") = acc
        body("payeeUserAccountInfo") = usr

        Dim r As JObject = JObject.Parse(ApiPost(PlatformPath("/payees/add"), body.ToString()))
        Return New PayeeCreatedResult With {
            .PayeeId = JStr(r("payeeId")),
            .PayeeUserId = JStr(r("payeeUserId"))
        }
    End Function

    ''' <summary>GET /payees/{payeeId} — détails complets du bénéficiaire.</summary>
    Public Shared Function GetPayee(payeeId As String) As JObject
        Return JObject.Parse(ApiGet(PlatformPath("/payees/" & payeeId)))
    End Function

    ''' <summary>POST /payees/{payeeId}/deactivate — désactive un bénéficiaire.</summary>
    Public Shared Sub DeactivatePayee(payeeId As String, Optional userNotes As String = Nothing)
        Dim body As New JObject()
        AddIf(body, "userNotes", userNotes)
        ApiPost(PlatformPath("/payees/" & payeeId & "/deactivate"), body.ToString())
    End Sub

    ' -- Comptes bancaires (le nerf de l'EFT) ---------------------------------

    ''' <summary>Coordonnées d'un compte bancaire EFT canadien (schéma BankAccount confirmé).</summary>
    Public Class BankAccountInput
        Public Property AccountName As String                  ' nom au compte
        Public Property AccountNumber As String                ' numéro de compte
        Public Property InstitutionNumber As String            ' Canada : 3 chiffres (ex. "003")
        Public Property TransitNumber As String                ' Canada : succursale, 5 chiffres
        Public Property BankAccountType As String = "CHEQUING" ' ⚠️ enum à confirmer ("SAVINGS" confirmé)
        Public Property CurrencyCode As String = "CAD"
        Public Property CountryCode As String = "CA"
        Public Property BankName As String
        Public Property AutoAcceptPaymentMethod As String      ' optionnel (ex. "EFT")
    End Class

    ''' <summary>
    ''' POST /payees/{payeeId}/accounts — associe un compte bancaire EFT au bénéficiaire et lance
    ''' la vérification (micro-dépôt). Retourne le bankAccountId. genericAccountType forcé à "BANK".
    ''' </summary>
    Public Shared Function AddPayeeBankAccount(payeeId As String, payeeUserId As String,
                                               account As BankAccountInput, Optional autoVerify As Boolean = False) As String
        If account Is Nothing Then Throw New Exception("DreamPayments.AddPayeeBankAccount : compte requis.")
        Dim ba As New JObject()
        ba("genericAccountType") = "BANK"
        AddIf(ba, "accountName", account.AccountName)
        AddIf(ba, "accountNumber", account.AccountNumber)
        AddIf(ba, "institutionNumber", account.InstitutionNumber)
        AddIf(ba, "transitNumber", account.TransitNumber)
        AddIf(ba, "bankAccountType", account.BankAccountType)
        AddIf(ba, "currencyCode", account.CurrencyCode)
        AddIf(ba, "countryCode", account.CountryCode)
        AddIf(ba, "bankName", account.BankName)
        AddIf(ba, "autoAcceptPaymentMethod", account.AutoAcceptPaymentMethod)
        Return AddPayeeBankAccount(payeeId, payeeUserId, ba, autoVerify)
    End Function

    ''' <summary>Surcharge bas niveau : bankAccount fourni tel quel (BANK ou CARD).</summary>
    Public Shared Function AddPayeeBankAccount(payeeId As String, payeeUserId As String,
                                               bankAccount As JObject, Optional autoVerify As Boolean = False) As String
        If bankAccount Is Nothing Then Throw New Exception("DreamPayments.AddPayeeBankAccount : bankAccount requis.")
        Dim body As New JObject()
        body("bankAccount") = bankAccount
        body("payeeUserId") = payeeUserId
        body("autoVerify") = autoVerify
        Dim r As JObject = JObject.Parse(ApiPost(PlatformPath("/payees/" & payeeId & "/accounts"), body.ToString()))
        Return JStr(r("bankAccountId"))
    End Function

    ''' <summary>GET /payees/{payeeId}/accounts — liste des comptes bancaires du bénéficiaire.</summary>
    Public Shared Function ListPayeeBankAccounts(payeeId As String) As JObject
        Return JObject.Parse(ApiGet(PlatformPath("/payees/" & payeeId & "/accounts")))
    End Function

    ''' <summary>POST /payees/{payeeId}/accounts/{accountId}/verify — confirme le compte via le
    ''' code du micro-dépôt. ⚠️ Corps exact À CONFIRMER (schéma non capturé) : passer un JObject brut.</summary>
    Public Shared Sub VerifyBankAccount(payeeId As String, accountId As String, body As JObject)
        ApiPost(PlatformPath("/payees/" & payeeId & "/accounts/" & accountId & "/verify"),
                If(body, New JObject()).ToString())
    End Sub

    ''' <summary>POST /payees/{payeeId}/accounts/{accountId}/acceptance — accepte/active le compte.
    ''' ⚠️ Corps exact À CONFIRMER : passer un JObject brut si nécessaire.</summary>
    Public Shared Sub AcceptBankAccount(payeeId As String, accountId As String, Optional body As JObject = Nothing)
        ApiPost(PlatformPath("/payees/" & payeeId & "/accounts/" & accountId & "/acceptance"),
                If(body, New JObject()).ToString())
    End Sub

    ' -- Paiements ------------------------------------------------------------

    ''' <summary>Champs d'un paiement. amount = { currencyCode, value } (confirmé via l'Overview).</summary>
    Public Class PaymentInput
        Public Property PayeeId As String                     ' requis
        Public Property PayeeUserId As String                 ' requis
        ' amount (paymentInfo.amount)
        Public Property CurrencyCode As String = "CAD"
        Public Property Value As Long                         ' ⚠️ unité (cents vs dollars) À CONFIRMER
        ' paymentInfo (optionnels)
        Public Property Memo As String
        Public Property PaymentType As String                 ' ex. "EXPENSE"
        Public Property PayoutDate As String                  ' ISO 8601 (ex. "2026-07-14T00:00:00Z")
        Public Property ExternalReferenceData As String       ' pratique : y mettre notre DocumentId
        Public Property DraftNumber As String
        Public Property ClaimNumber As String
        Public Property PolicyNumber As String
        Public Property PcoNumber As String
        Public Property LegalEntity As String                 ' ex. "INST CAD" (conditionnel avec legalEntityLabel)
        ' racine
        Public Property AllowablePaymentMethods As String() = {"EFT"}
        Public Property LegalEntityLabel As String
        Public Property NotifyEmail As String
    End Class

    ''' <summary>POST /payments/add — crée un paiement pour le bénéficiaire. Retourne le paymentId.</summary>
    Public Shared Function CreatePayment(input As PaymentInput) As String
        If input Is Nothing OrElse String.IsNullOrWhiteSpace(input.PayeeId) OrElse String.IsNullOrWhiteSpace(input.PayeeUserId) Then
            Throw New Exception("DreamPayments.CreatePayment : payeeId et payeeUserId sont obligatoires.")
        End If

        Dim amount As New JObject()
        amount("currencyCode") = If(input.CurrencyCode, "CAD")
        amount("value") = input.Value

        Dim pi As New JObject()
        pi("amount") = amount
        AddIf(pi, "memo", input.Memo)
        AddIf(pi, "paymentType", input.PaymentType)
        AddIf(pi, "payoutDate", input.PayoutDate)
        AddIf(pi, "externalReferenceData", input.ExternalReferenceData)
        AddIf(pi, "draftNumber", input.DraftNumber)
        AddIf(pi, "claimNumber", input.ClaimNumber)
        AddIf(pi, "policyNumber", input.PolicyNumber)
        AddIf(pi, "pcoNumber", input.PcoNumber)
        AddIf(pi, "legalEntity", input.LegalEntity)

        Dim body As New JObject()
        body("payeeId") = input.PayeeId
        body("payeeUserId") = input.PayeeUserId
        body("paymentInfo") = pi
        AddIf(body, "legalEntityLabel", input.LegalEntityLabel)
        AddIf(body, "notifyEmail", input.NotifyEmail)
        If input.AllowablePaymentMethods IsNot Nothing AndAlso input.AllowablePaymentMethods.Length > 0 Then
            Dim arr As New JArray()
            For Each m As String In input.AllowablePaymentMethods
                arr.Add(m)
            Next
            body("allowablePaymentMethods") = arr
        End If

        Dim r As JObject = JObject.Parse(ApiPost(PlatformPath("/payments/add"), body.ToString()))
        Return JStr(r("paymentId"))
    End Function

    ''' <summary>
    ''' POST /payments/{paymentId}/accept — accepte le paiement et DÉCLENCHE le transfert.
    ''' Réponse 204 (aucun contenu). bankAccountId requis pour EFT ; NON requis pour les
    ''' méthodes courriel (Interac e-Transfer / ETRAN) — laisser vide dans ce cas.
    ''' </summary>
    Public Shared Sub AcceptPayment(paymentId As String, bankAccountId As String,
                                    payeeUserId As String, Optional paymentMethod As String = "EFT")
        Dim body As New JObject()
        If Not String.IsNullOrEmpty(bankAccountId) Then body("bankAccountId") = bankAccountId
        body("payeeUserId") = payeeUserId
        body("paymentMethod") = paymentMethod
        ApiPost(PlatformPath("/payments/" & paymentId & "/accept"), body.ToString())
    End Sub

    ''' <summary>Code de méthode Interac e-Transfer (rail ETRAN). Configurable ; défaut "ETRAN".
    ''' ⚠️ À CONFIRMER (le doc mentionne ETRAN ; l'enum liste JPM_ETRAN).</summary>
    Public Shared Function InteracPaymentMethod() As String
        Dim m As String = ConfigurationManager.AppSettings("DreamPayments.InteracMethod")
        If String.IsNullOrEmpty(m) Then m = "ETRAN"
        Return m.Trim()
    End Function

    ''' <summary>GET /payments/{paymentId} — statut/détails du paiement.</summary>
    Public Shared Function GetPayment(paymentId As String) As JObject
        Return JObject.Parse(ApiGet(PlatformPath("/payments/" & paymentId)))
    End Function

    ''' <summary>POST /payments/{paymentId}/cancel — annule un paiement non encore réglé.</summary>
    Public Shared Sub CancelPayment(paymentId As String, Optional body As JObject = Nothing)
        ApiPost(PlatformPath("/payments/" & paymentId & "/cancel"), If(body, New JObject()).ToString())
    End Sub

    ' -- Utilitaires internes -------------------------------------------------

    ''' <summary>Préfixe le chemin par le base path de l'InsureTech (defaut "/platform", override Web.config).</summary>
    Private Shared Function PlatformPath(rel As String) As String
        Dim bp As String = ConfigurationManager.AppSettings("DreamPayments.BasePath")
        If String.IsNullOrEmpty(bp) Then bp = "/platform"
        Return bp.Trim().TrimEnd("/"c) & rel
    End Function

    ''' <summary>Ajoute une propriété string seulement si non vide.</summary>
    Private Shared Sub AddIf(o As JObject, name As String, value As String)
        If Not String.IsNullOrEmpty(value) Then o(name) = value
    End Sub

    ' =========================================================================
    ' BAS NIVEAU HTTP
    ' =========================================================================

    ''' <summary>POST application/x-www-form-urlencoded avec en-tête Basic (endpoint OAuth).</summary>
    Private Shared Function PostForm(url As String, formBody As String, basicAuth As String) As String
        EnsureTls12()
        Dim req As HttpWebRequest = DirectCast(WebRequest.Create(url), HttpWebRequest)
        req.Method = "POST"
        req.Accept = "application/json"
        req.ContentType = "application/x-www-form-urlencoded"
        If Not String.IsNullOrEmpty(basicAuth) Then
            req.Headers.Add("Authorization", "Basic " & basicAuth)
        End If

        Dim bytes As Byte() = Encoding.UTF8.GetBytes(formBody)
        req.ContentLength = bytes.Length
        Using rs As IO.Stream = req.GetRequestStream()
            rs.Write(bytes, 0, bytes.Length)
        End Using

        Return ReadResponse(req, "OAuth")
    End Function

    Private Shared Sub EnsureTls12()
        ' Requis sous .NET Framework pour les endpoints HTTPS modernes.
        ServicePointManager.SecurityProtocol = ServicePointManager.SecurityProtocol Or SecurityProtocolType.Tls12
    End Sub

    Private Shared Function ReadResponse(req As HttpWebRequest, context As String) As String
        Try
            Using resp As HttpWebResponse = DirectCast(req.GetResponse(), HttpWebResponse)
                Using sr As New IO.StreamReader(resp.GetResponseStream(), Encoding.UTF8)
                    Return sr.ReadToEnd()
                End Using
            End Using
        Catch ex As WebException
            Dim body As String = ""
            If ex.Response IsNot Nothing Then
                Using sr As New IO.StreamReader(ex.Response.GetResponseStream(), Encoding.UTF8)
                    body = sr.ReadToEnd()
                End Using
            End If
            Throw New Exception("DreamPayments " & context & " : " & body & " (" & ex.Message & ")")
        End Try
    End Function

    Private Shared Function JStr(t As JToken) As String
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return Nothing
        Return t.Value(Of String)()
    End Function

End Class
