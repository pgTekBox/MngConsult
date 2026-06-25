Imports System
Imports System.Collections.Generic
Imports System.Configuration
Imports System.Net
Imports System.Text
Imports Newtonsoft.Json.Linq

''' <summary>
''' Helper Square pour MngConsul. Encapsule les appels a l'API Square.
'''
''' Pour cette premiere etape : export du catalogue (produits/services) vers
''' Square via BatchUpsertCatalogObjects. Utilise HttpClient + Newtonsoft.Json
''' (meme approche que MyClass/Plaid.vb), sans dependance au SDK Square.
'''
''' Cles lues depuis Web.config :
'''   Square.Environment  ("sandbox" | "production")
'''   Square.AccessToken  (jeton Sandbox au depart ; plus tard le token OAuth de l'abonne)
'''   Square.ApiVersion   (date de version d'API, ex. "2025-06-18")
''' </summary>
Public Class clsSquare

    ' -------------------------------------------------------------------------
    ' Donnees d'entree : un produit/service MngConsul a pousser vers Square.
    ' ExistingXxx renseignes => mise a jour (UPDATE) ; sinon creation (INSERT).
    ' -------------------------------------------------------------------------
    Public Class SquareProductInput
        Public Property ProductId As Integer
        Public Property Name As String
        Public Property Description As String
        Public Property PriceCents As Long
        Public Property ExistingItemId As String
        Public Property ExistingItemVersion As Long
        Public Property ExistingVariationId As String
        Public Property ExistingVariationVersion As Long
    End Class

    ' -------------------------------------------------------------------------
    ' Resultat par produit : identifiants + versions Square a sauvegarder.
    ' -------------------------------------------------------------------------
    Public Class SquareSyncResult
        Public Property ProductId As Integer
        Public Property ItemId As String
        Public Property VariationId As String
        Public Property ItemVersion As Long
        Public Property VariationVersion As Long
    End Class

    Private Shared Function ApiBase() As String
        Dim env As String = ConfigurationManager.AppSettings("Square.Environment")
        If Not String.IsNullOrEmpty(env) AndAlso env.Trim().ToLowerInvariant() = "production" Then
            Return "https://connect.squareup.com"
        End If
        Return "https://connect.squareupsandbox.com"
    End Function

    Private Shared Function ApiVersion() As String
        Dim v As String = ConfigurationManager.AppSettings("Square.ApiVersion")
        If String.IsNullOrEmpty(v) Then v = "2025-06-18"
        Return v
    End Function

    ''' <summary>
    ''' Pousse une liste de produits/services vers le catalogue Square (un seul lot).
    ''' Cree les objets absents et met a jour ceux qui ont deja un identifiant Square.
    ''' Retourne, pour chaque produit, les identifiants et versions Square obtenus.
    ''' </summary>
    Public Shared Function BatchUpsertCatalog(accessToken As String,
                                              items As List(Of SquareProductInput)) As List(Of SquareSyncResult)

        If String.IsNullOrEmpty(accessToken) OrElse accessToken.StartsWith("REMPLACE") Then
            Throw New InvalidOperationException("Square.AccessToken n'est pas configure dans Web.config.")
        End If

        Dim results As New List(Of SquareSyncResult)()
        If items Is Nothing OrElse items.Count = 0 Then Return results

        ' ── Construction du corps JSON ─────────────────────────────────────────
        Dim objArr As New JArray()
        For Each it As SquareProductInput In items
            Dim isUpdate As Boolean = Not String.IsNullOrEmpty(it.ExistingItemId)
            Dim itemId As String = If(isUpdate, it.ExistingItemId, "#item_" & it.ProductId)
            Dim varIsUpdate As Boolean = Not String.IsNullOrEmpty(it.ExistingVariationId)
            Dim varId As String = If(varIsUpdate, it.ExistingVariationId, "#var_" & it.ProductId)

            Dim priceMoney As New JObject()
            priceMoney("amount") = it.PriceCents
            priceMoney("currency") = "CAD"

            Dim varData As New JObject()
            varData("item_id") = itemId
            varData("name") = "Standard"
            varData("pricing_type") = "FIXED_PRICING"
            varData("price_money") = priceMoney

            Dim variation As New JObject()
            variation("type") = "ITEM_VARIATION"
            variation("id") = varId
            If varIsUpdate Then variation("version") = it.ExistingVariationVersion
            variation("item_variation_data") = varData

            Dim variations As New JArray()
            variations.Add(variation)

            Dim itemData As New JObject()
            itemData("name") = If(it.Name, "")
            If Not String.IsNullOrEmpty(it.Description) Then itemData("description") = it.Description
            itemData("variations") = variations

            Dim itemObj As New JObject()
            itemObj("type") = "ITEM"
            itemObj("id") = itemId
            If isUpdate Then itemObj("version") = it.ExistingItemVersion
            itemObj("item_data") = itemData

            objArr.Add(itemObj)
        Next

        Dim batch As New JObject()
        batch("objects") = objArr
        Dim batches As New JArray()
        batches.Add(batch)

        Dim body As New JObject()
        body("idempotency_key") = Guid.NewGuid().ToString()
        body("batches") = batches

        ' ── Appel API ──────────────────────────────────────────────────────────
        Dim respText As String = PostJson("/v2/catalog/batch-upsert", body.ToString(), accessToken)
        Dim root As JObject = JObject.Parse(respText)

        ' ── Mapping ID temporaire -> ID reel Square ─────────────────────────────
        Dim clientToReal As New Dictionary(Of String, String)(StringComparer.Ordinal)
        Dim mappings As JArray = TryCast(root("id_mappings"), JArray)
        If mappings IsNot Nothing Then
            For Each m As JToken In mappings
                Dim c As String = JStr(m("client_object_id"))
                Dim r As String = JStr(m("object_id"))
                If Not String.IsNullOrEmpty(c) Then clientToReal(c) = r
            Next
        End If

        ' ── Versions retournees (item + variations) ─────────────────────────────
        Dim itemVersions As New Dictionary(Of String, Long)(StringComparer.Ordinal)
        Dim varVersions As New Dictionary(Of String, Long)(StringComparer.Ordinal)
        Dim objects As JArray = TryCast(root("objects"), JArray)
        If objects IsNot Nothing Then
            For Each o As JToken In objects
                Dim oid As String = JStr(o("id"))
                If Not String.IsNullOrEmpty(oid) Then itemVersions(oid) = JLng(o("version"))
                Dim idata As JObject = TryCast(o("item_data"), JObject)
                If idata IsNot Nothing Then
                    Dim vars As JArray = TryCast(idata("variations"), JArray)
                    If vars IsNot Nothing Then
                        For Each v As JToken In vars
                            Dim vid As String = JStr(v("id"))
                            If Not String.IsNullOrEmpty(vid) Then varVersions(vid) = JLng(v("version"))
                        Next
                    End If
                End If
            Next
        End If

        ' ── Resolution par produit ──────────────────────────────────────────────
        For Each it As SquareProductInput In items
            Dim itemTemp As String = If(Not String.IsNullOrEmpty(it.ExistingItemId), it.ExistingItemId, "#item_" & it.ProductId)
            Dim varTemp As String = If(Not String.IsNullOrEmpty(it.ExistingVariationId), it.ExistingVariationId, "#var_" & it.ProductId)

            Dim realItemId As String = it.ExistingItemId
            If String.IsNullOrEmpty(realItemId) Then clientToReal.TryGetValue(itemTemp, realItemId)
            Dim realVarId As String = it.ExistingVariationId
            If String.IsNullOrEmpty(realVarId) Then clientToReal.TryGetValue(varTemp, realVarId)

            Dim r As New SquareSyncResult()
            r.ProductId = it.ProductId
            r.ItemId = realItemId
            r.VariationId = realVarId
            If Not String.IsNullOrEmpty(realItemId) AndAlso itemVersions.ContainsKey(realItemId) Then r.ItemVersion = itemVersions(realItemId)
            If Not String.IsNullOrEmpty(realVarId) AndAlso varVersions.ContainsKey(realVarId) Then r.VariationVersion = varVersions(realVarId)
            results.Add(r)
        Next

        Return results
    End Function

    ' =========================================================================
    ' OAUTH (connexion du compte Square d'un abonne)
    ' =========================================================================

    ''' <summary>Jetons retournes par l'echange de code / le refresh OAuth.</summary>
    Public Class SquareTokenInfo
        Public Property AccessToken As String
        Public Property RefreshToken As String
        Public Property ExpiresAt As DateTime
        Public Property MerchantId As String
    End Class

    Private Shared Function AppId() As String
        Return ConfigurationManager.AppSettings("Square.ApplicationId")
    End Function

    Private Shared Function AppSecret() As String
        Return ConfigurationManager.AppSettings("Square.ApplicationSecret")
    End Function

    Private Shared Function OAuthScopes() As String
        Dim s As String = ConfigurationManager.AppSettings("Square.OAuthScopes")
        If String.IsNullOrEmpty(s) Then
            s = "MERCHANT_PROFILE_READ ITEMS_READ ITEMS_WRITE ORDERS_READ ORDERS_WRITE PAYMENTS_READ PAYMENTS_WRITE DEVICE_CREDENTIAL_MANAGEMENT"
        End If
        Return s
    End Function

    ''' <summary>URL d'autorisation Square vers laquelle rediriger l'abonne.</summary>
    Public Shared Function GetAuthorizeUrl(state As String) As String
        Dim clientId As String = AppId()
        If String.IsNullOrEmpty(clientId) OrElse clientId.StartsWith("REMPLACE") Then
            Throw New InvalidOperationException("Square.ApplicationId n'est pas configure dans Web.config.")
        End If
        Dim sb As New StringBuilder()
        sb.Append(ApiBase()).Append("/oauth2/authorize")
        sb.Append("?client_id=").Append(Uri.EscapeDataString(clientId))
        sb.Append("&scope=").Append(Uri.EscapeDataString(OAuthScopes()))
        sb.Append("&session=false")
        sb.Append("&state=").Append(Uri.EscapeDataString(state))
        Dim redirect As String = ConfigurationManager.AppSettings("Square.OAuthRedirectUrl")
        If Not String.IsNullOrEmpty(redirect) Then
            sb.Append("&redirect_uri=").Append(Uri.EscapeDataString(redirect))
        End If
        Return sb.ToString()
    End Function

    ''' <summary>Echange le code d'autorisation contre des jetons.</summary>
    Public Shared Function ExchangeCodeForToken(code As String) As SquareTokenInfo
        Dim body As New JObject()
        body("client_id") = AppId()
        body("client_secret") = AppSecret()
        body("code") = code
        body("grant_type") = "authorization_code"
        Dim redirect As String = ConfigurationManager.AppSettings("Square.OAuthRedirectUrl")
        If Not String.IsNullOrEmpty(redirect) Then body("redirect_uri") = redirect
        Return ParseTokenResponse(PostJson("/oauth2/token", body.ToString(), Nothing))
    End Function

    ''' <summary>Renouvelle l'access token a partir du refresh token.</summary>
    Public Shared Function RefreshAccessToken(refreshToken As String) As SquareTokenInfo
        Dim body As New JObject()
        body("client_id") = AppId()
        body("client_secret") = AppSecret()
        body("refresh_token") = refreshToken
        body("grant_type") = "refresh_token"
        Return ParseTokenResponse(PostJson("/oauth2/token", body.ToString(), Nothing))
    End Function

    Private Shared Function ParseTokenResponse(respText As String) As SquareTokenInfo
        Dim root As JObject = JObject.Parse(respText)
        Dim info As New SquareTokenInfo()
        info.AccessToken = JStr(root("access_token"))
        info.RefreshToken = JStr(root("refresh_token"))
        info.MerchantId = JStr(root("merchant_id"))
        Dim exp As String = JStr(root("expires_at"))
        Dim dt As DateTime
        If Not String.IsNullOrEmpty(exp) AndAlso DateTime.TryParse(exp, Nothing, Globalization.DateTimeStyles.RoundtripKind, dt) Then
            info.ExpiresAt = dt
        Else
            info.ExpiresAt = DateTime.Now.AddDays(30)
        End If
        Return info
    End Function

    ''' <summary>Retourne l'Id de la premiere location ACTIVE du marchand (ou la premiere).</summary>
    Public Shared Function GetMainLocationId(accessToken As String) As String
        Dim respText As String = GetJson("/v2/locations", accessToken)
        Dim root As JObject = JObject.Parse(respText)
        Dim locs As JArray = TryCast(root("locations"), JArray)
        If locs Is Nothing OrElse locs.Count = 0 Then Return Nothing

        Dim fallback As String = Nothing
        For Each l As JToken In locs
            Dim id As String = JStr(l("id"))
            If fallback Is Nothing Then fallback = id
            If String.Equals(JStr(l("status")), "ACTIVE", StringComparison.OrdinalIgnoreCase) Then
                Return id
            End If
        Next
        Return fallback
    End Function

    ' -------------------------------------------------------------------------
    ' Helpers HTTP synchrones via HttpWebRequest (pas de dependance System.Net.Http,
    ' ce qui permet a clsSquare de vivre dans App_Code).
    ' accessToken Nothing/"" => pas d'en-tete Authorization (ex. /oauth2/token).
    ' -------------------------------------------------------------------------
    Private Shared Function PostJson(path As String, jsonBody As String, accessToken As String) As String
        Return SendRequest(path, "POST", jsonBody, accessToken)
    End Function

    Private Shared Function GetJson(path As String, accessToken As String) As String
        Return SendRequest(path, "GET", Nothing, accessToken)
    End Function

    Private Shared Function SendRequest(path As String, method As String, jsonBody As String, accessToken As String) As String
        ' Square exige TLS 1.2 (important sous .NET Framework).
        ServicePointManager.SecurityProtocol = ServicePointManager.SecurityProtocol Or SecurityProtocolType.Tls12

        Dim req As HttpWebRequest = DirectCast(WebRequest.Create(ApiBase() & path), HttpWebRequest)
        req.Method = method
        req.Accept = "application/json"
        req.Headers.Add("Square-Version", ApiVersion())
        If Not String.IsNullOrEmpty(accessToken) Then
            req.Headers.Add("Authorization", "Bearer " & accessToken)
        End If

        If jsonBody IsNot Nothing Then
            req.ContentType = "application/json"
            Dim bytes As Byte() = Encoding.UTF8.GetBytes(jsonBody)
            req.ContentLength = bytes.Length
            Using rs As IO.Stream = req.GetRequestStream()
                rs.Write(bytes, 0, bytes.Length)
            End Using
        End If

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
            Throw New Exception("Square API : " & body & " (" & ex.Message & ")")
        End Try
    End Function

    Private Shared Function JStr(t As JToken) As String
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return Nothing
        Return t.Value(Of String)()
    End Function

    Private Shared Function JLng(t As JToken) As Long
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return 0L
        Return t.Value(Of Long)()
    End Function

End Class
