Imports System
Imports System.Collections.Generic
Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.IO
Imports System.Text
Imports System.Web
Imports Newtonsoft.Json.Linq

''' <summary>
''' Handler webhook Square pour MngConsul (sens entrant Square -> application).
'''
''' URL endpoint : https://60sec.ca/SquareWebhook.ashx
''' A configurer dans Square Developer Console > Webhooks (Production) :
'''   - Notification URL = l'URL ci-dessus (doit matcher Square.WebhookUrl)
'''   - Events : customer.created, customer.updated
'''   - Copier la "Signature Key" dans Web.config (Square.WebhookSignatureKey)
'''
''' Securite : verification HMAC-SHA256 (Square.WebhookSignatureKey + URL + body).
''' Idempotence : UNIQUE sur tSquareEvenement.SquareEventId.
''' Reponses : 200 traite/skipped/deja-vu, 400 signature invalide, 500 retry.
''' </summary>
Public Class SquareWebhook
    Implements IHttpHandler

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest

        If context.Request.HttpMethod <> "POST" Then
            context.Response.StatusCode = 405
            context.Response.Write("Method Not Allowed")
            Return
        End If

        ' === 1. Body brut ===
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

        ' === 2. Verification de la signature HMAC ===
        Dim sigHeader As String = context.Request.Headers("x-square-hmacsha256-signature")
        Dim notifUrl As String = clsSquare.WebhookUrl()
        If String.IsNullOrEmpty(notifUrl) Then notifUrl = context.Request.Url.GetLeftPart(UriPartial.Path)
        If Not clsSquare.VerifyWebhookSignature(payload, sigHeader, notifUrl) Then
            context.Response.StatusCode = 400
            context.Response.Write("Invalid signature")
            Return
        End If

        ' === 3. Parsing ===
        Dim root As JObject
        Try
            root = JObject.Parse(payload)
        Catch ex As Exception
            context.Response.StatusCode = 400
            context.Response.Write("Invalid JSON")
            Return
        End Try

        Dim eventId As String = Js(root("event_id"))
        Dim eventType As String = Js(root("type"))
        Dim merchantId As String = Js(root("merchant_id"))
        If String.IsNullOrEmpty(eventId) Then eventId = Guid.NewGuid().ToString()

        Dim createdAt As Object = DBNull.Value
        Dim dtTmp As DateTime
        If DateTime.TryParse(Js(root("created_at")), Nothing, DateTimeStyles.RoundtripKind, dtTmp) Then createdAt = dtTmp

        ' === 4. Idempotence ===
        Dim wasInserted As Boolean
        Try
            Dim ds As DataSet = ExecuteProcDs("s0668SquareEventInsertIfNew", New Dictionary(Of String, Object) From {
                {"@SquareEventId", eventId},
                {"@EventType", eventType},
                {"@MerchantId", If(String.IsNullOrEmpty(merchantId), CType(DBNull.Value, Object), merchantId)},
                {"@SquareCreatedAt", createdAt},
                {"@Payload", payload}
            })
            wasInserted = ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 _
                          AndAlso CBool(ds.Tables(0).Rows(0)("WasInserted"))
        Catch ex As Exception
            context.Response.StatusCode = 500
            context.Response.Write("DB error: " & ex.Message)
            Return
        End Try

        If Not wasInserted Then
            context.Response.StatusCode = 200
            context.Response.Write("Already processed")
            Return
        End If

        ' === 5. Dispatch ===
        Try
            Select Case eventType
                Case "customer.created", "customer.updated"
                    HandleCustomerUpsert(root, merchantId)
                Case "catalog.version.updated"
                    HandleCatalogUpdate(merchantId)
                Case "invoice.created", "invoice.updated", "invoice.payment_made", "invoice.canceled", "invoice.published"
                    HandleInvoiceUpsert(root, merchantId)
                Case "payment.created", "payment.updated"
                    HandlePayment(root, merchantId)
                Case Else
                    MarkStatus(eventId, "skipped", "Event non gere : " & eventType)
                    context.Response.StatusCode = 200
                    context.Response.Write("OK (skipped: " & eventType & ")")
                    Return
            End Select

            MarkStatus(eventId, "processed", Nothing)
            context.Response.StatusCode = 200
            context.Response.Write("OK")

        Catch ex As Exception
            Try
                MarkStatus(eventId, "failed", ex.Message)
            Catch
            End Try
            context.Response.StatusCode = 500
            context.Response.Write("Processing failed: " & ex.Message)
        End Try
    End Sub

    ''' <summary>customer.created / customer.updated : upsert dans T050Party.</summary>
    Private Sub HandleCustomerUpsert(root As JObject, merchantId As String)
        ' merchant_id -> CompanyGUID
        If String.IsNullOrEmpty(merchantId) Then Throw New Exception("merchant_id absent du webhook.")
        Dim companyGuid As Object = ResolveCompany(merchantId)
        If companyGuid Is Nothing Then Throw New Exception("Aucune compagnie pour merchant_id=" & merchantId)

        ' data.object.customer
        Dim data As JObject = TryCast(root("data"), JObject)
        Dim obj As JObject = If(data Is Nothing, Nothing, TryCast(data("object"), JObject))
        Dim cust As JObject = If(obj Is Nothing, Nothing, TryCast(obj("customer"), JObject))
        If cust Is Nothing Then Throw New Exception("Objet customer absent du payload.")

        Dim c As clsSquare.SquareCustomerRemote = clsSquare.MapRemoteCustomer(cust)
        If String.IsNullOrEmpty(c.CustomerId) Then Throw New Exception("customer.id absent.")

        ExecProc("s0666UpsertClientFromSquare", New Dictionary(Of String, Object) From {
            {"@CompanyGUID", companyGuid},
            {"@SquareCustomerId", c.CustomerId},
            {"@SquareCustomerVersion", If(c.Version > 0, CType(c.Version, Object), DBNull.Value)},
            {"@ReferenceId", Nz(c.ReferenceId)},
            {"@Name", Nz(c.Name)},
            {"@Email", Nz(c.Email)},
            {"@Phone", Nz(c.Phone)},
            {"@Address1", Nz(c.Address1)},
            {"@Address2", Nz(c.Address2)},
            {"@City", Nz(c.City)},
            {"@PostalCode", Nz(c.PostalCode)}
        })
    End Sub

    ''' <summary>
    ''' catalog.version.updated : l'event ne contient pas les objets modifies,
    ''' on re-liste donc le catalogue Square et on upsert chaque produit.
    ''' </summary>
    Private Sub HandleCatalogUpdate(merchantId As String)
        If String.IsNullOrEmpty(merchantId) Then Throw New Exception("merchant_id absent du webhook.")
        Dim companyGuid As Object = ResolveCompany(merchantId)
        If companyGuid Is Nothing Then Throw New Exception("Aucune compagnie pour merchant_id=" & merchantId)

        Dim token As String = GetCompanyAccessToken(CType(companyGuid, Guid))
        If String.IsNullOrEmpty(token) Then Throw New Exception("Aucun token Square pour la compagnie.")

        Dim items As List(Of clsSquare.SquareProductRemote) = clsSquare.ListCatalogItems(token)
        For Each p As clsSquare.SquareProductRemote In items
            If String.IsNullOrEmpty(p.ItemId) Then Continue For
            ExecProc("s0670UpsertProductFromSquare", New Dictionary(Of String, Object) From {
                {"@CompanyGUID", companyGuid},
                {"@SquareItemId", p.ItemId},
                {"@SquareVariationId", Nz(p.VariationId)},
                {"@SquareItemVersion", If(p.ItemVersion > 0, CType(p.ItemVersion, Object), DBNull.Value)},
                {"@SquareVariationVersion", If(p.VariationVersion > 0, CType(p.VariationVersion, Object), DBNull.Value)},
                {"@Name", Nz(p.Name)},
                {"@Description", Nz(p.Description)},
                {"@PriceCents", If(p.PriceCents > 0, CType(p.PriceCents, Object), DBNull.Value)}
            })
        Next
    End Sub

    ''' <summary>
    ''' invoice.* : upsert d'une Facture Client (T060Document) + lignes. L'event
    ''' contient l'objet invoice (id, order_id, customer, statut) mais PAS les
    ''' lignes -> on lit l'Order via l'API. On garantit d'abord le client local.
    ''' </summary>
    Private Sub HandleInvoiceUpsert(root As JObject, merchantId As String)
        If String.IsNullOrEmpty(merchantId) Then Throw New Exception("merchant_id absent du webhook.")
        Dim companyGuid As Object = ResolveCompany(merchantId)
        If companyGuid Is Nothing Then Throw New Exception("Aucune compagnie pour merchant_id=" & merchantId)

        Dim data As JObject = TryCast(root("data"), JObject)
        Dim obj As JObject = If(data Is Nothing, Nothing, TryCast(data("object"), JObject))
        Dim invJson As JObject = If(obj Is Nothing, Nothing, TryCast(obj("invoice"), JObject))
        If invJson Is Nothing Then Throw New Exception("Objet invoice absent du payload.")

        Dim inv As clsSquare.SquareInvoiceRemote = clsSquare.MapRemoteInvoice(invJson)
        If String.IsNullOrEmpty(inv.InvoiceId) Then Throw New Exception("invoice.id absent.")

        ' 1. Garantir le client local (SquareCustomerId -> T050Party) via le snapshot destinataire
        If Not String.IsNullOrEmpty(inv.CustomerId) Then
            ExecProc("s0666UpsertClientFromSquare", New Dictionary(Of String, Object) From {
                {"@CompanyGUID", companyGuid},
                {"@SquareCustomerId", inv.CustomerId},
                {"@SquareCustomerVersion", DBNull.Value},
                {"@ReferenceId", DBNull.Value},
                {"@Name", Nz(inv.RecipientName)},
                {"@Email", Nz(inv.RecipientEmail)},
                {"@Phone", Nz(inv.RecipientPhone)},
                {"@Address1", Nz(inv.RecipientAddress1)},
                {"@Address2", Nz(inv.RecipientAddress2)},
                {"@City", Nz(inv.RecipientCity)},
                {"@PostalCode", Nz(inv.RecipientPostalCode)}
            })
        End If

        ' 2. Lire l'Order (lignes + totaux) via le token de la compagnie
        Dim order As clsSquare.SquareOrderRemote = Nothing
        If Not String.IsNullOrEmpty(inv.OrderId) Then
            Dim token As String = GetCompanyAccessToken(CType(companyGuid, Guid))
            If Not String.IsNullOrEmpty(token) Then order = clsSquare.RetrieveOrder(token, inv.OrderId)
        End If

        ' 3. Upsert facture + lignes
        UpsertInvoice(companyGuid, inv, order, Nothing, Nothing)
    End Sub

    ''' <summary>
    ''' payment.* : rapproche le paiement avec une facture existante (par order) et
    ''' la passe en Paye. Si aucune facture ne correspond (vente TPV/Terminal sans
    ''' facture Square), cree une Facture Client payee depuis l'Order.
    ''' </summary>
    Private Sub HandlePayment(root As JObject, merchantId As String)
        If String.IsNullOrEmpty(merchantId) Then Throw New Exception("merchant_id absent du webhook.")
        Dim companyGuid As Object = ResolveCompany(merchantId)
        If companyGuid Is Nothing Then Throw New Exception("Aucune compagnie pour merchant_id=" & merchantId)

        Dim data As JObject = TryCast(root("data"), JObject)
        Dim obj As JObject = If(data Is Nothing, Nothing, TryCast(data("object"), JObject))
        Dim payJson As JObject = If(obj Is Nothing, Nothing, TryCast(obj("payment"), JObject))
        If payJson Is Nothing Then Throw New Exception("Objet payment absent du payload.")

        Dim pay As clsSquare.SquarePaymentRemote = clsSquare.MapRemotePayment(payJson)
        If String.IsNullOrEmpty(pay.PaymentId) Then Throw New Exception("payment.id absent.")

        ' 1. Rapprochement avec une facture existante
        Dim needsInvoice As Boolean = False
        Dim ds As DataSet = ExecuteProcDs("s0672ApplySquarePayment", New Dictionary(Of String, Object) From {
            {"@CompanyGUID", companyGuid},
            {"@SquareOrderId", Nz(pay.OrderId)},
            {"@SquarePaymentId", pay.PaymentId},
            {"@SquareStatus", Nz(pay.Status)},
            {"@AmountCents", If(pay.AmountCents <> 0, CType(pay.AmountCents, Object), DBNull.Value)}
        })
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 _
           AndAlso ds.Tables(0).Columns.Contains("NeedsInvoice") Then
            needsInvoice = CBool(ds.Tables(0).Rows(0)("NeedsInvoice"))
        End If

        ' 2. Vente sans facture preexistante -> creer la Facture Client payee.
        '    Avec Order (panier itemise Square POS) : lignes + taxes. Sans Order
        '    (vente rapide "montant seul") : facture a 1 ligne avec le montant total.
        If needsInvoice Then
            Dim token As String = GetCompanyAccessToken(CType(companyGuid, Guid))
            Dim order As clsSquare.SquareOrderRemote = Nothing
            If Not String.IsNullOrEmpty(token) AndAlso Not String.IsNullOrEmpty(pay.OrderId) Then
                order = clsSquare.RetrieveOrder(token, pay.OrderId)
            End If
            If order Is Nothing Then order = SyntheticOrder(pay)
            Dim inv As New clsSquare.SquareInvoiceRemote()
            inv.OrderId = pay.OrderId
            inv.CustomerId = pay.CustomerId
            inv.Status = pay.Status
            UpsertInvoice(companyGuid, inv, order, pay.PaymentId, pay.Status)
        End If
    End Sub

    ''' <summary>
    ''' Construit un Order synthetique (1 ligne, montant total du paiement) quand la
    ''' vente n'a pas d'Order Square (vente rapide "montant seul"). On garde l'OrderId
    ''' du paiement s'il existe pour le rapprochement futur ; sinon cle = SquarePaymentId.
    ''' </summary>
    Private Shared Function SyntheticOrder(pay As clsSquare.SquarePaymentRemote) As clsSquare.SquareOrderRemote
        Dim o As New clsSquare.SquareOrderRemote()
        o.OrderId = pay.OrderId
        o.CustomerId = pay.CustomerId
        o.TotalCents = pay.AmountCents
        o.SubTotalCents = pay.AmountCents
        o.TpsCents = 0
        o.TvqCents = 0
        Dim ln As New clsSquare.SquareOrderLine()
        ln.Name = "Vente au terminal (Square)"
        ln.Qty = 1D
        ln.UnitPriceCents = pay.AmountCents
        ln.AmountCents = pay.AmountCents
        ln.HasTax = False
        o.Lines.Add(ln)
        Return o
    End Function

    ''' <summary>
    ''' Appelle s0671UpsertInvoiceFromSquare : entete (totaux autoritatifs de l'Order)
    ''' + lignes (TVP). paymentId/paymentStatus non vides -> chemin paiement (force le
    ''' statut a partir du paiement et stampe le SquarePaymentId).
    ''' </summary>
    Private Sub UpsertInvoice(companyGuid As Object,
                              inv As clsSquare.SquareInvoiceRemote,
                              order As clsSquare.SquareOrderRemote,
                              paymentId As String,
                              paymentStatus As String)

        Dim status As String = If(Not String.IsNullOrEmpty(paymentStatus), paymentStatus,
                                  If(inv IsNot Nothing, inv.Status, Nothing))
        Dim orderId As String = If(order IsNot Nothing, order.OrderId,
                                   If(inv IsNot Nothing, inv.OrderId, Nothing))
        Dim customerId As String = If(inv IsNot Nothing AndAlso Not String.IsNullOrEmpty(inv.CustomerId),
                                      inv.CustomerId, If(order IsNot Nothing, order.CustomerId, Nothing))

        Dim p As New Dictionary(Of String, Object) From {
            {"@CompanyGUID", companyGuid},
            {"@SquareInvoiceId", Nz(If(inv IsNot Nothing, inv.InvoiceId, Nothing))},
            {"@SquareInvoiceVersion", If(inv IsNot Nothing AndAlso inv.Version > 0, CType(inv.Version, Object), DBNull.Value)},
            {"@SquareOrderId", Nz(orderId)},
            {"@SquarePaymentId", Nz(paymentId)},
            {"@SquareCustomerId", Nz(customerId)},
            {"@InvoiceNumber", Nz(If(inv IsNot Nothing, inv.InvoiceNumber, Nothing))},
            {"@SquareStatus", Nz(status)},
            {"@IssueDate", DateOrNull(If(inv IsNot Nothing, inv.IssueDate, Nothing))},
            {"@DueDate", DateOrNull(If(inv IsNot Nothing, inv.DueDate, Nothing))},
            {"@SubTotalCents", If(order IsNot Nothing, CType(order.SubTotalCents, Object), DBNull.Value)},
            {"@TpsCents", If(order IsNot Nothing, CType(order.TpsCents, Object), DBNull.Value)},
            {"@TvqCents", If(order IsNot Nothing, CType(order.TvqCents, Object), DBNull.Value)},
            {"@TotalCents", If(order IsNot Nothing, CType(order.TotalCents, Object), DBNull.Value)},
            {"@RecipientName", Nz(If(inv IsNot Nothing, inv.RecipientName, Nothing))},
            {"@RecipientEmail", Nz(If(inv IsNot Nothing, inv.RecipientEmail, Nothing))},
            {"@RecipientPhone", Nz(If(inv IsNot Nothing, inv.RecipientPhone, Nothing))},
            {"@RecipientAddress1", Nz(If(inv IsNot Nothing, inv.RecipientAddress1, Nothing))},
            {"@RecipientAddress2", Nz(If(inv IsNot Nothing, inv.RecipientAddress2, Nothing))},
            {"@RecipientCity", Nz(If(inv IsNot Nothing, inv.RecipientCity, Nothing))},
            {"@RecipientState", Nz(If(inv IsNot Nothing, inv.RecipientState, Nothing))},
            {"@RecipientPostalCode", Nz(If(inv IsNot Nothing, inv.RecipientPostalCode, Nothing))}
        }

        ExecProcWithLines("s0671UpsertInvoiceFromSquare", p, BuildLinesTable(order))
    End Sub

    ''' <summary>Construit le TVP_SquareInvoiceLine a partir des lignes de l'Order.</summary>
    Private Shared Function BuildLinesTable(order As clsSquare.SquareOrderRemote) As DataTable
        Dim dt As New DataTable()
        dt.Columns.Add("Ordre", GetType(Integer))
        dt.Columns.Add("SquareItemId", GetType(String))
        dt.Columns.Add("Description", GetType(String))
        dt.Columns.Add("Qty", GetType(Decimal))
        dt.Columns.Add("UnitPrice", GetType(Decimal))
        dt.Columns.Add("Amount", GetType(Decimal))
        dt.Columns.Add("HasTax", GetType(Boolean))
        If order IsNot Nothing AndAlso order.Lines IsNot Nothing Then
            Dim i As Integer = 0
            For Each l As clsSquare.SquareOrderLine In order.Lines
                i += 1
                dt.Rows.Add(i,
                            If(String.IsNullOrEmpty(l.CatalogObjectId), CType(DBNull.Value, Object), l.CatalogObjectId),
                            If(l.Name, CType(DBNull.Value, Object)),
                            l.Qty,
                            l.UnitPriceCents / 100D,
                            l.AmountCents / 100D,
                            l.HasTax)
            Next
        End If
        Return dt
    End Function

    Private Shared Function DateOrNull(d As DateTime?) As Object
        If d.HasValue Then Return d.Value
        Return DBNull.Value
    End Function

    ''' <summary>
    ''' Recupere le token d'acces Square (dechiffre) d'une compagnie pour les
    ''' appels sortants declenches par webhook (pas de session). Repli : token
    ''' unique de Web.config. Pas de refresh ici (l'app rafraichit cote bouton).
    ''' </summary>
    Private Function GetCompanyAccessToken(companyGuid As Guid) As String
        Try
            Dim ds As DataSet = ExecuteProcDs("s0663GetCompanySquareAuth",
                New Dictionary(Of String, Object) From {{"@CompanyGUID", companyGuid}})
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim accEnc As Object = ds.Tables(0).Rows(0)("SquareAccessTokenEnc")
                If accEnc IsNot Nothing AndAlso Not IsDBNull(accEnc) AndAlso accEnc.ToString().Length > 0 Then
                    Return clsCrypto.Decrypt(accEnc.ToString())
                End If
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("GetCompanyAccessToken (webhook): " & ex.Message)
        End Try
        Return ConfigurationManager.AppSettings("Square.AccessToken")
    End Function

    Private Function ResolveCompany(merchantId As String) As Object
        Dim ds As DataSet = ExecuteProcDs("s0667GetCompanyBySquareMerchantId",
            New Dictionary(Of String, Object) From {{"@SquareMerchantId", merchantId}})
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
            Return ds.Tables(0).Rows(0)("CompanyGUID")
        End If
        Return Nothing
    End Function

    Private Sub MarkStatus(eventId As String, status As String, errorMessage As String)
        ExecProc("s0669SquareEventMarkStatus", New Dictionary(Of String, Object) From {
            {"@SquareEventId", eventId},
            {"@Status", status},
            {"@ErrorMessage", If(String.IsNullOrEmpty(errorMessage), CType(DBNull.Value, Object), errorMessage)}
        })
    End Sub

    ' ── Helpers ──
    Private Shared Function Js(t As JToken) As String
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return Nothing
        Return t.Value(Of String)()
    End Function

    Private Shared Function Nz(s As String) As Object
        If String.IsNullOrEmpty(s) Then Return DBNull.Value
        Return s
    End Function

    ' ── Acces DB direct (le .ashx n'herite pas de Page/clsData) ──
    Private ReadOnly Property ConnectionString As String
        Get
            Return ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

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

    ''' <summary>Execute une proc avec un parametre TVP @Lines (dbo.TVP_SquareInvoiceLine).</summary>
    Private Sub ExecProcWithLines(procName As String, params_ As Dictionary(Of String, Object), lines As DataTable)
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand(procName, conn)
                cmd.CommandType = CommandType.StoredProcedure
                For Each kvp In params_
                    cmd.Parameters.AddWithValue(kvp.Key, If(kvp.Value, DBNull.Value))
                Next
                Dim pLines As New SqlParameter("@Lines", SqlDbType.Structured)
                pLines.TypeName = "dbo.TVP_SquareInvoiceLine"
                pLines.Value = lines
                cmd.Parameters.Add(pLines)
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

End Class
