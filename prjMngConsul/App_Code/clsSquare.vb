Imports System
Imports System.Collections.Generic
Imports System.Configuration
Imports System.Net
Imports System.Security.Cryptography
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
    ' CLIENTS (Square Customers API)
    ' =========================================================================

    ''' <summary>Donnees d'entree : un client MngConsul a pousser vers Square.</summary>
    Public Class SquareCustomerInput
        Public Property PartyId As Integer
        Public Property CompanyName As String
        Public Property Email As String
        Public Property Phone As String
        Public Property Address1 As String
        Public Property Address2 As String
        Public Property City As String
        Public Property PostalCode As String
        Public Property Note As String
        Public Property ExistingCustomerId As String   ' customer_xxx si deja synchronise
        Public Property ExistingVersion As Long
    End Class

    ''' <summary>Resultat retourne par Square pour un client.</summary>
    Public Class SquareCustomerResult
        Public Property PartyId As Integer
        Public Property CustomerId As String
        Public Property Version As Long
    End Class

    ''' <summary>
    ''' Pousse une liste de clients MngConsul vers Square (Customers API).
    ''' Cree (POST /v2/customers) ceux sans identifiant Square ; met a jour
    ''' (PUT /v2/customers/{id} + version) ceux qui en ont deja un.
    ''' Un appel HTTP par client : l'API Customers n'a pas de batch-upsert.
    ''' Retourne, pour chaque client, l'id et la version Square obtenus.
    ''' </summary>
    Public Shared Function UpsertCustomers(accessToken As String,
                                           items As List(Of SquareCustomerInput)) As List(Of SquareCustomerResult)

        If String.IsNullOrEmpty(accessToken) OrElse accessToken.StartsWith("REMPLACE") Then
            Throw New InvalidOperationException("Square.AccessToken n'est pas configure dans Web.config.")
        End If

        Dim results As New List(Of SquareCustomerResult)()
        If items Is Nothing OrElse items.Count = 0 Then Return results

        For Each it As SquareCustomerInput In items
            ' ── Construction du corps JSON ───────────────────────────────────
            Dim body As New JObject()
            If Not String.IsNullOrEmpty(it.CompanyName) Then body("company_name") = it.CompanyName
            If Not String.IsNullOrEmpty(it.Email) Then body("email_address") = it.Email
            If Not String.IsNullOrEmpty(it.Phone) Then body("phone_number") = it.Phone
            If Not String.IsNullOrEmpty(it.Note) Then body("note") = it.Note
            body("reference_id") = it.PartyId.ToString()   ' lien retour vers T050Party.Id

            If Not String.IsNullOrEmpty(it.Address1) OrElse Not String.IsNullOrEmpty(it.City) _
               OrElse Not String.IsNullOrEmpty(it.PostalCode) Then
                Dim addr As New JObject()
                If Not String.IsNullOrEmpty(it.Address1) Then addr("address_line_1") = it.Address1
                If Not String.IsNullOrEmpty(it.Address2) Then addr("address_line_2") = it.Address2
                If Not String.IsNullOrEmpty(it.City) Then addr("locality") = it.City
                If Not String.IsNullOrEmpty(it.PostalCode) Then addr("postal_code") = it.PostalCode
                body("address") = addr
            End If

            ' ── Create (POST) ou Update (PUT) ────────────────────────────────
            Dim respText As String
            If Not String.IsNullOrEmpty(it.ExistingCustomerId) Then
                If it.ExistingVersion > 0 Then body("version") = it.ExistingVersion
                respText = PutJson("/v2/customers/" & it.ExistingCustomerId, body.ToString(), accessToken)
            Else
                body("idempotency_key") = Guid.NewGuid().ToString()
                respText = PostJson("/v2/customers", body.ToString(), accessToken)
            End If

            ' ── Lecture de la reponse ────────────────────────────────────────
            Dim root As JObject = JObject.Parse(respText)
            Dim cust As JObject = TryCast(root("customer"), JObject)
            Dim r As New SquareCustomerResult()
            r.PartyId = it.PartyId
            If cust IsNot Nothing Then
                r.CustomerId = JStr(cust("id"))
                r.Version = JLng(cust("version"))
            End If
            If String.IsNullOrEmpty(r.CustomerId) Then r.CustomerId = it.ExistingCustomerId
            results.Add(r)
        Next

        Return results
    End Function

    ''' <summary>Client Square tel que renvoye par l'API (sens entrant Square -> app).</summary>
    Public Class SquareCustomerRemote
        Public Property CustomerId As String
        Public Property Version As Long
        Public Property ReferenceId As String
        Public Property Name As String          ' company_name, sinon given_name + family_name
        Public Property Email As String
        Public Property Phone As String
        Public Property Address1 As String
        Public Property Address2 As String
        Public Property City As String
        Public Property PostalCode As String
    End Class

    ''' <summary>
    ''' Liste tous les clients du compte Square du marchand (pagination cursor).
    ''' Utilise par l'import a la demande (Square -> T050Party).
    ''' </summary>
    Public Shared Function ListCustomers(accessToken As String) As List(Of SquareCustomerRemote)
        If String.IsNullOrEmpty(accessToken) OrElse accessToken.StartsWith("REMPLACE") Then
            Throw New InvalidOperationException("Square.AccessToken n'est pas configure dans Web.config.")
        End If

        Dim out As New List(Of SquareCustomerRemote)()
        Dim cursor As String = Nothing
        Do
            Dim path As String = "/v2/customers?limit=100"
            If Not String.IsNullOrEmpty(cursor) Then path &= "&cursor=" & Uri.EscapeDataString(cursor)
            Dim root As JObject = JObject.Parse(GetJson(path, accessToken))
            Dim arr As JArray = TryCast(root("customers"), JArray)
            If arr IsNot Nothing Then
                For Each c As JToken In arr
                    out.Add(MapRemoteCustomer(CType(c, JObject)))
                Next
            End If
            cursor = JStr(root("cursor"))
        Loop While Not String.IsNullOrEmpty(cursor)
        Return out
    End Function

    ''' <summary>Convertit un objet customer JSON Square en SquareCustomerRemote.</summary>
    Public Shared Function MapRemoteCustomer(c As JObject) As SquareCustomerRemote
        Dim r As New SquareCustomerRemote()
        If c Is Nothing Then Return r
        r.CustomerId = JStr(c("id"))
        r.Version = JLng(c("version"))
        r.ReferenceId = JStr(c("reference_id"))
        Dim company As String = JStr(c("company_name"))
        If Not String.IsNullOrEmpty(company) Then
            r.Name = company
        Else
            Dim gn As String = JStr(c("given_name"))
            Dim fn As String = JStr(c("family_name"))
            r.Name = (If(gn, "") & " " & If(fn, "")).Trim()
        End If
        r.Email = JStr(c("email_address"))
        r.Phone = JStr(c("phone_number"))
        Dim addr As JObject = TryCast(c("address"), JObject)
        If addr IsNot Nothing Then
            r.Address1 = JStr(addr("address_line_1"))
            r.Address2 = JStr(addr("address_line_2"))
            r.City = JStr(addr("locality"))
            r.PostalCode = JStr(addr("postal_code"))
        End If
        Return r
    End Function

    ''' <summary>Produit Square (catalogue) tel que renvoye par l'API (sens entrant).</summary>
    Public Class SquareProductRemote
        Public Property ItemId As String
        Public Property ItemVersion As Long
        Public Property VariationId As String
        Public Property VariationVersion As Long
        Public Property Name As String
        Public Property Description As String
        Public Property PriceCents As Long
        Public Property Currency As String
    End Class

    ''' <summary>
    ''' Liste tous les ITEMs du catalogue Square du marchand (pagination cursor).
    ''' Retient, pour chaque item, sa 1re variation (prix). Utilise par l'import
    ''' a la demande et par le webhook catalog.version.updated (re-sync complet).
    ''' </summary>
    Public Shared Function ListCatalogItems(accessToken As String) As List(Of SquareProductRemote)
        If String.IsNullOrEmpty(accessToken) OrElse accessToken.StartsWith("REMPLACE") Then
            Throw New InvalidOperationException("Square.AccessToken n'est pas configure dans Web.config.")
        End If

        Dim out As New List(Of SquareProductRemote)()
        Dim cursor As String = Nothing
        Do
            Dim path As String = "/v2/catalog/list?types=ITEM"
            If Not String.IsNullOrEmpty(cursor) Then path &= "&cursor=" & Uri.EscapeDataString(cursor)
            Dim root As JObject = JObject.Parse(GetJson(path, accessToken))
            Dim arr As JArray = TryCast(root("objects"), JArray)
            If arr IsNot Nothing Then
                For Each o As JToken In arr
                    Dim p As SquareProductRemote = MapRemoteItem(CType(o, JObject))
                    If p IsNot Nothing Then out.Add(p)
                Next
            End If
            cursor = JStr(root("cursor"))
        Loop While Not String.IsNullOrEmpty(cursor)
        Return out
    End Function

    ''' <summary>Convertit un objet ITEM JSON Square en SquareProductRemote (1re variation).</summary>
    Public Shared Function MapRemoteItem(o As JObject) As SquareProductRemote
        If o Is Nothing OrElse Not String.Equals(JStr(o("type")), "ITEM", StringComparison.Ordinal) Then Return Nothing
        Dim p As New SquareProductRemote()
        p.ItemId = JStr(o("id"))
        p.ItemVersion = JLng(o("version"))
        Dim idata As JObject = TryCast(o("item_data"), JObject)
        If idata IsNot Nothing Then
            p.Name = JStr(idata("name"))
            p.Description = JStr(idata("description"))
            Dim vars As JArray = TryCast(idata("variations"), JArray)
            If vars IsNot Nothing AndAlso vars.Count > 0 Then
                Dim v As JObject = TryCast(vars(0), JObject)
                If v IsNot Nothing Then
                    p.VariationId = JStr(v("id"))
                    p.VariationVersion = JLng(v("version"))
                    Dim vdata As JObject = TryCast(v("item_variation_data"), JObject)
                    If vdata IsNot Nothing Then
                        Dim money As JObject = TryCast(vdata("price_money"), JObject)
                        If money IsNot Nothing Then
                            p.PriceCents = JLng(money("amount"))
                            p.Currency = JStr(money("currency"))
                        End If
                    End If
                End If
            End If
        End If
        Return p
    End Function

    ' =========================================================================
    ' FACTURES & PAIEMENTS (Square Invoices / Payments / Orders API) -- sens entrant
    ' =========================================================================

    ''' <summary>Une ligne d'Order Square (alimente T061DocumentLine).</summary>
    Public Class SquareOrderLine
        Public Property CatalogObjectId As String   ' id de variation Square (lien -> T075Products.SquareVariationId/SquareItemId)
        Public Property Name As String
        Public Property Qty As Decimal
        Public Property UnitPriceCents As Long
        Public Property AmountCents As Long          ' montant de ligne hors taxes
        Public Property HasTax As Boolean
    End Class

    ''' <summary>Un Order Square : lignes + ventilation TPS/TVQ + totaux (cents).</summary>
    Public Class SquareOrderRemote
        Public Property OrderId As String
        Public Property CustomerId As String
        Public Property SubTotalCents As Long
        Public Property TpsCents As Long
        Public Property TvqCents As Long
        Public Property TotalCents As Long
        Public Property Lines As New List(Of SquareOrderLine)
    End Class

    ''' <summary>Facture Square (Invoices API) telle que recue (webhook / list).</summary>
    Public Class SquareInvoiceRemote
        Public Property InvoiceId As String
        Public Property Version As Long
        Public Property OrderId As String
        Public Property CustomerId As String
        Public Property InvoiceNumber As String
        Public Property Status As String
        Public Property IssueDate As DateTime?
        Public Property DueDate As DateTime?
        Public Property RecipientName As String
        Public Property RecipientEmail As String
        Public Property RecipientPhone As String
        Public Property RecipientAddress1 As String
        Public Property RecipientAddress2 As String
        Public Property RecipientCity As String
        Public Property RecipientState As String
        Public Property RecipientPostalCode As String
    End Class

    ''' <summary>Paiement Square (Payments API) tel que recu (webhook / list).</summary>
    Public Class SquarePaymentRemote
        Public Property PaymentId As String
        Public Property OrderId As String
        Public Property CustomerId As String
        Public Property Status As String
        Public Property AmountCents As Long
        Public Property CreatedAt As DateTime?
    End Class

    ''' <summary>
    ''' Recupere un Order Square (GET /v2/orders/{id}) : lignes + ventilation des
    ''' taxes en TPS (GST ~5%) / TVQ (QST ~9.975%) par nom/pourcentage + totaux.
    ''' Les events invoice.*/payment.* ne contiennent pas les lignes -> on lit l'Order.
    ''' </summary>
    Public Shared Function RetrieveOrder(accessToken As String, orderId As String) As SquareOrderRemote
        If String.IsNullOrEmpty(accessToken) OrElse String.IsNullOrEmpty(orderId) Then Return Nothing
        Dim root As JObject = JObject.Parse(GetJson("/v2/orders/" & Uri.EscapeDataString(orderId), accessToken))
        Dim o As JObject = TryCast(root("order"), JObject)
        If o Is Nothing Then Return Nothing

        Dim r As New SquareOrderRemote()
        r.OrderId = JStr(o("id"))
        r.CustomerId = JStr(o("customer_id"))

        Dim lines As JArray = TryCast(o("line_items"), JArray)
        If lines IsNot Nothing Then
            For Each li As JToken In lines
                Dim l As JObject = TryCast(li, JObject)
                If l Is Nothing Then Continue For
                Dim line As New SquareOrderLine()
                line.CatalogObjectId = JStr(l("catalog_object_id"))
                line.Name = JStr(l("name"))
                Dim qd As Decimal = 0D
                Decimal.TryParse(JStr(l("quantity")), Globalization.NumberStyles.Any, Globalization.CultureInfo.InvariantCulture, qd)
                If qd = 0D Then qd = 1D
                line.Qty = qd
                Dim baseMoney As JObject = TryCast(l("base_price_money"), JObject)
                If baseMoney IsNot Nothing Then line.UnitPriceCents = JLng(baseMoney("amount"))
                Dim gross As JObject = TryCast(l("gross_sales_money"), JObject)
                If gross IsNot Nothing Then
                    line.AmountCents = JLng(gross("amount"))
                Else
                    line.AmountCents = CLng(Decimal.Truncate(line.UnitPriceCents * qd))
                End If
                Dim lineTax As JObject = TryCast(l("total_tax_money"), JObject)
                line.HasTax = (lineTax IsNot Nothing AndAlso JLng(lineTax("amount")) > 0)
                r.Lines.Add(line)
            Next
        End If

        Dim totalMoney As JObject = TryCast(o("total_money"), JObject)
        Dim totalTax As JObject = TryCast(o("total_tax_money"), JObject)
        r.TotalCents = If(totalMoney IsNot Nothing, JLng(totalMoney("amount")), 0L)
        Dim taxCents As Long = If(totalTax IsNot Nothing, JLng(totalTax("amount")), 0L)
        r.SubTotalCents = r.TotalCents - taxCents

        ' Ventilation TPS / TVQ par nom (GST/TPS, QST/TVQ) puis pourcentage.
        Dim taxes As JArray = TryCast(o("taxes"), JArray)
        Dim tps As Long = 0L, tvq As Long = 0L, autres As Long = 0L
        If taxes IsNot Nothing Then
            For Each t As JToken In taxes
                Dim tj As JObject = TryCast(t, JObject)
                If tj Is Nothing Then Continue For
                Dim am As JObject = TryCast(tj("applied_money"), JObject)
                Dim cents As Long = If(am IsNot Nothing, JLng(am("amount")), 0L)
                Dim nm As String = (If(JStr(tj("name")), "")).ToUpperInvariant()
                Dim pct As String = If(JStr(tj("percentage")), "")
                If nm.Contains("TPS") OrElse nm.Contains("GST") OrElse pct.StartsWith("5") Then
                    tps += cents
                ElseIf nm.Contains("TVQ") OrElse nm.Contains("QST") OrElse pct.StartsWith("9.9") Then
                    tvq += cents
                Else
                    autres += cents
                End If
            Next
        End If
        tps += autres   ' taxe non classee -> versee dans TPS (a ajuster selon les taxes Square reelles)
        If tps = 0L AndAlso tvq = 0L AndAlso taxCents > 0L Then tps = taxCents   ' repli : taxes non detaillees
        r.TpsCents = tps
        r.TvqCents = tvq

        Return r
    End Function

    ''' <summary>Convertit un objet invoice JSON Square en SquareInvoiceRemote.</summary>
    Public Shared Function MapRemoteInvoice(inv As JObject) As SquareInvoiceRemote
        Dim r As New SquareInvoiceRemote()
        If inv Is Nothing Then Return r
        r.InvoiceId = JStr(inv("id"))
        r.Version = JLng(inv("version"))
        r.OrderId = JStr(inv("order_id"))
        r.InvoiceNumber = JStr(inv("invoice_number"))
        r.Status = JStr(inv("status"))
        Dim dt As DateTime
        If DateTime.TryParse(JStr(inv("created_at")), Nothing, Globalization.DateTimeStyles.RoundtripKind, dt) Then r.IssueDate = dt

        Dim pr As JObject = TryCast(inv("primary_recipient"), JObject)
        If pr IsNot Nothing Then
            r.CustomerId = JStr(pr("customer_id"))
            Dim company As String = JStr(pr("company_name"))
            If Not String.IsNullOrEmpty(company) Then
                r.RecipientName = company
            Else
                r.RecipientName = ((If(JStr(pr("given_name")), "")) & " " & (If(JStr(pr("family_name")), ""))).Trim()
            End If
            r.RecipientEmail = JStr(pr("email_address"))
            r.RecipientPhone = JStr(pr("phone_number"))
            Dim addr As JObject = TryCast(pr("address"), JObject)
            If addr IsNot Nothing Then
                r.RecipientAddress1 = JStr(addr("address_line_1"))
                r.RecipientAddress2 = JStr(addr("address_line_2"))
                r.RecipientCity = JStr(addr("locality"))
                r.RecipientState = JStr(addr("administrative_district_level_1"))
                r.RecipientPostalCode = JStr(addr("postal_code"))
            End If
        End If

        Dim prs As JArray = TryCast(inv("payment_requests"), JArray)
        If prs IsNot Nothing AndAlso prs.Count > 0 Then
            Dim pr0 As JObject = TryCast(prs(0), JObject)
            If pr0 IsNot Nothing Then
                Dim dd As DateTime
                If DateTime.TryParse(JStr(pr0("due_date")), Nothing, Globalization.DateTimeStyles.AssumeLocal, dd) Then r.DueDate = dd
            End If
        End If
        Return r
    End Function

    ''' <summary>Convertit un objet payment JSON Square en SquarePaymentRemote.</summary>
    Public Shared Function MapRemotePayment(pay As JObject) As SquarePaymentRemote
        Dim r As New SquarePaymentRemote()
        If pay Is Nothing Then Return r
        r.PaymentId = JStr(pay("id"))
        r.OrderId = JStr(pay("order_id"))
        r.CustomerId = JStr(pay("customer_id"))
        r.Status = JStr(pay("status"))
        Dim am As JObject = TryCast(pay("amount_money"), JObject)
        If am IsNot Nothing Then r.AmountCents = JLng(am("amount"))
        Dim dt As DateTime
        If DateTime.TryParse(JStr(pay("created_at")), Nothing, Globalization.DateTimeStyles.RoundtripKind, dt) Then r.CreatedAt = dt
        Return r
    End Function

    ''' <summary>
    ''' Liste les factures Square d'une location (pagination cursor). Necessite le
    ''' scope INVOICES_READ. Utilise par l'import a la demande (Square -> T060Document).
    ''' </summary>
    Public Shared Function ListInvoices(accessToken As String, locationId As String) As List(Of SquareInvoiceRemote)
        Dim out As New List(Of SquareInvoiceRemote)()
        If String.IsNullOrEmpty(accessToken) OrElse String.IsNullOrEmpty(locationId) Then Return out
        Dim cursor As String = Nothing
        Do
            Dim path As String = "/v2/invoices?location_id=" & Uri.EscapeDataString(locationId) & "&limit=100"
            If Not String.IsNullOrEmpty(cursor) Then path &= "&cursor=" & Uri.EscapeDataString(cursor)
            Dim root As JObject = JObject.Parse(GetJson(path, accessToken))
            Dim arr As JArray = TryCast(root("invoices"), JArray)
            If arr IsNot Nothing Then
                For Each iv As JToken In arr
                    out.Add(MapRemoteInvoice(CType(iv, JObject)))
                Next
            End If
            cursor = JStr(root("cursor"))
        Loop While Not String.IsNullOrEmpty(cursor)
        Return out
    End Function

    ''' <summary>
    ''' Liste les paiements Square (pagination cursor), filtres par location si fournie.
    ''' Necessite le scope PAYMENTS_READ. Utilise par l'import a la demande.
    ''' </summary>
    Public Shared Function ListPayments(accessToken As String, locationId As String) As List(Of SquarePaymentRemote)
        Dim out As New List(Of SquarePaymentRemote)()
        If String.IsNullOrEmpty(accessToken) Then Return out
        Dim cursor As String = Nothing
        Do
            Dim path As String = "/v2/payments?limit=100"
            If Not String.IsNullOrEmpty(locationId) Then path &= "&location_id=" & Uri.EscapeDataString(locationId)
            If Not String.IsNullOrEmpty(cursor) Then path &= "&cursor=" & Uri.EscapeDataString(cursor)
            Dim root As JObject = JObject.Parse(GetJson(path, accessToken))
            Dim arr As JArray = TryCast(root("payments"), JArray)
            If arr IsNot Nothing Then
                For Each py As JToken In arr
                    out.Add(MapRemotePayment(CType(py, JObject)))
                Next
            End If
            cursor = JStr(root("cursor"))
        Loop While Not String.IsNullOrEmpty(cursor)
        Return out
    End Function

    ' =========================================================================
    ' WEBHOOK (notifications Square -> app, temps reel)
    ' =========================================================================

    ''' <summary>
    ''' Verifie la signature HMAC-SHA256 d'un webhook Square.
    ''' Square signe : Base64( HMAC-SHA256( cle = signatureKey, message = notificationUrl + body ) ).
    ''' En-tete : x-square-hmacsha256-signature. Comparaison a temps constant.
    ''' </summary>
    Public Shared Function VerifyWebhookSignature(rawBody As String, signatureHeader As String, notificationUrl As String) As Boolean
        Dim key As String = ConfigurationManager.AppSettings("Square.WebhookSignatureKey")
        If String.IsNullOrEmpty(key) OrElse String.IsNullOrEmpty(signatureHeader) Then Return False
        Dim payload As String = If(notificationUrl, "") & If(rawBody, "")
        Using h As New HMACSHA256(Encoding.UTF8.GetBytes(key))
            Dim computed As String = Convert.ToBase64String(h.ComputeHash(Encoding.UTF8.GetBytes(payload)))
            Return FixedTimeEquals(computed, signatureHeader)
        End Using
    End Function

    ''' <summary>URL exacte de l'endpoint webhook (doit matcher la console Square).</summary>
    Public Shared Function WebhookUrl() As String
        Dim u As String = ConfigurationManager.AppSettings("Square.WebhookUrl")
        Return If(u, "")
    End Function

    ''' <summary>Comparaison de chaines a temps constant (anti timing-attack).</summary>
    Private Shared Function FixedTimeEquals(a As String, b As String) As Boolean
        If a Is Nothing OrElse b Is Nothing OrElse a.Length <> b.Length Then Return False
        Dim diff As Integer = 0
        For i As Integer = 0 To a.Length - 1
            diff = diff Or (Convert.ToInt32(a(i)) Xor Convert.ToInt32(b(i)))
        Next
        Return diff = 0
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
            s = "MERCHANT_PROFILE_READ ITEMS_READ ITEMS_WRITE ORDERS_READ ORDERS_WRITE PAYMENTS_READ PAYMENTS_WRITE INVOICES_READ INVOICES_WRITE CUSTOMERS_READ CUSTOMERS_WRITE DEVICE_CREDENTIAL_MANAGEMENT"
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
    ' -------------------------------------------------------------------------
    ' PAYMENT LINK (Square Online Checkout) -- encaissement facture client
    ' -------------------------------------------------------------------------
    Public Class SquarePaymentLinkResult
        Public Property Id As String
        Public Property Url As String          ' page de paiement hebergee (https://square.link/...)
        Public Property LongUrl As String
        Public Property OrderId As String
    End Class

    ''' <summary>
    ''' Cree un lien de paiement Square (POST /v2/online-checkout/payment-links) pour un
    ''' montant donne. Square heberge la page de paiement (carte + Interac debit). Le client
    ''' paie via l'URL retournee ; le paiement revient par webhook (reconciliation existante).
    ''' amountCents en cents CAD. note/reference : y mettre notre no de facture.
    ''' </summary>
    Public Shared Function CreatePaymentLink(accessToken As String, locationId As String,
                                             amountCents As Long, name As String, note As String) As SquarePaymentLinkResult
        Dim price As New JObject()
        price("amount") = amountCents
        price("currency") = "CAD"

        Dim quick As New JObject()
        quick("name") = name
        quick("price_money") = price
        If Not String.IsNullOrEmpty(locationId) Then quick("location_id") = locationId

        Dim body As New JObject()
        body("idempotency_key") = Guid.NewGuid().ToString()
        body("quick_pay") = quick
        If Not String.IsNullOrEmpty(note) Then body("description") = note

        Dim resp As String = PostJson("/v2/online-checkout/payment-links", body.ToString(), accessToken)
        Dim pl As JToken = JObject.Parse(resp)("payment_link")
        Dim r As New SquarePaymentLinkResult()
        If pl IsNot Nothing Then
            r.Id = JStr(pl("id"))
            r.Url = JStr(pl("url"))
            r.LongUrl = JStr(pl("long_url"))
            r.OrderId = JStr(pl("order_id"))
        End If
        Return r
    End Function

    Private Shared Function PostJson(path As String, jsonBody As String, accessToken As String) As String
        Return SendRequest(path, "POST", jsonBody, accessToken)
    End Function

    Private Shared Function GetJson(path As String, accessToken As String) As String
        Return SendRequest(path, "GET", Nothing, accessToken)
    End Function

    Private Shared Function PutJson(path As String, jsonBody As String, accessToken As String) As String
        Return SendRequest(path, "PUT", jsonBody, accessToken)
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
