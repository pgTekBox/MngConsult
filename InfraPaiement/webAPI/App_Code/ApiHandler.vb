Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Web
Imports Newtonsoft.Json
Imports Newtonsoft.Json.Linq

''' <summary>
''' Point d'entrée de l'API 60secPaiement. Authentifie chaque requête par
''' clé d'API (en-tête X-Api-Key ou Authorization: Bearer), résout l'abonné
''' propriétaire, puis dispatche vers l'endpoint. Tout est scopé à cet
''' abonné (isolation multi-locataire). Les montants sont en cents entiers.
''' </summary>
Public Class ApiHandler
    Implements IHttpHandler

    Private ReadOnly _path As String
    Private ReadOnly _version As String
    Private ReadOnly _deprecated As Boolean

    Public Sub New(path As String, version As String)
        _path = If(path, "")
        _deprecated = String.IsNullOrEmpty(version)
        _version = If(String.IsNullOrEmpty(version), "v1", version)
    End Sub

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        Dim ctx As HttpContext = context
        ctx.Response.ContentType = "application/json"
        ctx.Response.Headers("X-Content-Type-Options") = "nosniff"
        ctx.Response.Headers("X-Api-Version") = _version
        If _deprecated Then ctx.Response.Headers("X-Api-Deprecation") = "Unversioned path is deprecated; use /api/v1/"

        Try
            Dim segs() As String = _path.Trim("/"c).Split("/"c)
            Dim resource As String = If(segs.Length > 0, segs(0).ToLowerInvariant(), "")
            Dim idPart As String = If(segs.Length > 1, segs(1), "")
            Dim method As String = ctx.Request.HttpMethod.ToUpperInvariant()

            ' Endpoint public de santé (sans authentification).
            If resource = "ping" AndAlso method = "GET" Then
                Dim ok As New JObject()
                ok("ok") = True
                ok("service") = "60secPaiement API"
                ok("version") = _version
                WriteJson(ctx, 200, ok)
                Return
            End If

            ' --- Authentification par clé d'API (abonné "sk_…" ou partenaire "pk_…") ---
            Dim principal As ApiPrincipal = ApiData.ResolvePrincipal(ExtractApiKey(ctx))
            If principal Is Nothing Then
                Throw New ApiException(401, "unauthorized", "Clé d'API absente ou invalide.")
            End If

            ' --- Rate limiting (par clé d'API) ---
            Dim rl As RateLimiter.RateResult = RateLimiter.Check(principal.ApiKeyId)
            ctx.Response.Headers("X-RateLimit-Limit") = rl.Limit.ToString()
            ctx.Response.Headers("X-RateLimit-Remaining") = rl.Remaining.ToString()
            ctx.Response.Headers("X-RateLimit-Reset") = rl.ResetEpoch.ToString()
            If Not rl.Allowed Then
                ctx.Response.Headers("Retry-After") = rl.RetryAfter.ToString()
                Throw New ApiException(429, "rate_limited", "Trop de requêtes. Réessayez plus tard.")
            End If

            ' --- Résolution du locataire effectif (isolation multi-locataire) ---
            ' Clé abonné : agit pour son propre abonné.
            ' Clé partenaire (Modèle B) : la ressource "abonnes" = provisioning
            '   (scope partenaire) ; les autres ressources exigent l'en-tête
            '   X-Abonne-Id désignant un tenant appartenant au partenaire.
            Dim abonneId As Integer = 0
            If principal.IsPartner Then
                If resource <> "abonnes" Then
                    abonneId = ResolveDelegatedTenant(ctx, principal)
                End If
            Else
                abonneId = principal.AbonneId
            End If

            Select Case resource
                Case "abonnes"
                    ' Provisioning de locataires — réservé aux clés partenaire.
                    If Not principal.IsPartner Then Throw New ApiException(403, "forbidden", "Réservé aux clés partenaire.")
                    Dim sub2 As String = If(segs.Length > 2, segs(2).ToLowerInvariant(), "")
                    If method = "GET" AndAlso idPart = "" Then
                        ListAbonnes(ctx, principal)
                    ElseIf method = "POST" AndAlso idPart = "" Then
                        CreateAbonne(ctx, principal)
                    ElseIf method = "GET" AndAlso idPart <> "" AndAlso sub2 = "" Then
                        GetAbonne(ctx, principal, ParseId(idPart))
                    ElseIf idPart <> "" AndAlso sub2 = "kyb" AndAlso method = "POST" Then
                        RunKyb(ctx, principal, ParseId(idPart))
                    ElseIf idPart <> "" AndAlso sub2 = "kyb" AndAlso method = "GET" Then
                        ListKyb(ctx, principal, ParseId(idPart))
                    Else
                        Throw New ApiException(405, "method_not_allowed", "Méthode non permise.")
                    End If

                Case "balance"
                    RequireMethod(method, "GET")
                    GetBalance(ctx, abonneId)

                Case "clients"
                    If method = "GET" AndAlso idPart = "" Then
                        ListClients(ctx, abonneId)
                    ElseIf method = "GET" Then
                        GetClient(ctx, abonneId, ParseId(idPart))
                    ElseIf method = "POST" AndAlso idPart = "" Then
                        CreateClient(ctx, abonneId)
                    Else
                        Throw New ApiException(405, "method_not_allowed", "Méthode non permise.")
                    End If

                Case "payments"
                    If method = "GET" AndAlso idPart = "" Then
                        ListPayments(ctx, abonneId)
                    ElseIf method = "GET" Then
                        GetPayment(ctx, abonneId, ParseId(idPart))
                    ElseIf method = "POST" AndAlso idPart = "" Then
                        CreatePayment(ctx, abonneId)
                    Else
                        Throw New ApiException(405, "method_not_allowed", "Méthode non permise.")
                    End If

                Case "fournisseurs"
                    If method = "GET" AndAlso idPart = "" Then
                        ListFournisseurs(ctx, abonneId)
                    ElseIf method = "GET" Then
                        GetFournisseur(ctx, abonneId, ParseId(idPart))
                    ElseIf method = "POST" AndAlso idPart = "" Then
                        CreateFournisseur(ctx, abonneId)
                    Else
                        Throw New ApiException(405, "method_not_allowed", "Méthode non permise.")
                    End If

                Case "payouts"
                    If method = "GET" AndAlso idPart = "" Then
                        ListPayouts(ctx, abonneId)
                    ElseIf method = "GET" Then
                        GetPayout(ctx, abonneId, ParseId(idPart))
                    ElseIf method = "POST" AndAlso idPart = "" Then
                        CreatePayout(ctx, abonneId)
                    Else
                        Throw New ApiException(405, "method_not_allowed", "Méthode non permise.")
                    End If

                Case "webhook"
                    If method = "GET" AndAlso idPart = "deliveries" Then
                        ListWebhookDeliveries(ctx, abonneId)
                    ElseIf method = "GET" AndAlso idPart = "" Then
                        GetWebhook(ctx, abonneId)
                    ElseIf method = "PUT" AndAlso idPart = "" Then
                        PutWebhook(ctx, abonneId)
                    ElseIf method = "DELETE" AndAlso idPart = "" Then
                        DeleteWebhook(ctx, abonneId)
                    Else
                        Throw New ApiException(405, "method_not_allowed", "Méthode non permise.")
                    End If

                Case Else
                    Throw New ApiException(404, "not_found", "Ressource inconnue.")
            End Select

        Catch apiEx As ApiException
            WriteError(ctx, apiEx.StatusCode, apiEx.ErrorCode, apiEx.Message)
        Catch sqlEx As SqlException
            ' RAISERROR applicatif (règles métier) -> 400 ; sinon 500.
            If sqlEx.Class = 16 Then
                WriteError(ctx, 400, "bad_request", sqlEx.Message)
            Else
                WriteError(ctx, 500, "server_error", "Erreur interne.")
                System.Diagnostics.Debug.WriteLine("API SQL: " & sqlEx.Message)
            End If
        Catch ex As Exception
            WriteError(ctx, 500, "server_error", "Erreur interne.")
            System.Diagnostics.Debug.WriteLine("API: " & ex.ToString())
        End Try
    End Sub

    ' =====================================================================
    ' Endpoints
    ' =====================================================================

    Private Sub GetBalance(ctx As HttpContext, abonneId As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@AbonneId", abonneId))
        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0015GetAbonneBalances", p)
        Dim r As DataRow = dt.Rows(0)
        Dim o As New JObject()
        o("available_cents") = Lng(r, "SoldeCents")
        o("reserve_cents") = Lng(r, "ReserveCents")
        o("eft_incoming_cents") = Lng(r, "EftInCents")
        o("eft_outgoing_cents") = Lng(r, "EftOutCents")
        o("currency") = "CAD"
        WriteJson(ctx, 200, o)
    End Sub

    Private Sub ListClients(ctx As HttpContext, abonneId As Integer)
        Dim limit As Integer = GetLimit(ctx), offset As Integer = GetOffset(ctx)
        Dim p As New Collection
        p.Add(New SqlParameter("@AbonneId", abonneId))
        p.Add(New SqlParameter("@Search", DBNull.Value))
        p.Add(New SqlParameter("@Statut", DBNull.Value))
        p.Add(New SqlParameter("@Limit", limit + 1))
        p.Add(New SqlParameter("@Offset", offset))
        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0011ListClients", p)
        WritePaged(ctx, dt, limit, offset, AddressOf ClientJson)
    End Sub

    Private Sub GetClient(ctx As HttpContext, abonneId As Integer, id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0012GetClient", p)
        If dt.Rows.Count = 0 OrElse CInt(dt.Rows(0)("AbonneId")) <> abonneId Then
            Throw New ApiException(404, "not_found", "Client introuvable.")
        End If
        WriteJson(ctx, 200, ClientJson(dt.Rows(0)))
    End Sub

    Private Sub CreateClient(ctx As HttpContext, abonneId As Integer)
        Dim body As JObject = ReadBody(ctx)
        Dim nom As String = JStr(body, "name")
        If String.IsNullOrEmpty(nom) Then Throw New ApiException(400, "validation", "Le champ 'name' est requis.")

        Dim p As New Collection
        Dim outId As New SqlParameter("@Id", SqlDbType.Int) With {.Direction = ParameterDirection.InputOutput, .Value = 0}
        p.Add(outId)
        p.Add(New SqlParameter("@AbonneId", abonneId))
        p.Add(New SqlParameter("@TypeClient", DefStr(body, "type", "Entreprise")))
        p.Add(New SqlParameter("@Nom", nom))
        p.Add(New SqlParameter("@ReferenceExterne", NullStr(body, "reference")))
        p.Add(New SqlParameter("@CourrielContact", NullStr(body, "email")))
        p.Add(New SqlParameter("@Telephone", NullStr(body, "phone")))
        p.Add(New SqlParameter("@Adresse1", NullStr(body, "address1")))
        p.Add(New SqlParameter("@Adresse2", NullStr(body, "address2")))
        p.Add(New SqlParameter("@Ville", NullStr(body, "city")))
        p.Add(New SqlParameter("@Province", NullStr(body, "province")))
        p.Add(New SqlParameter("@CodePostal", NullStr(body, "postal_code")))
        p.Add(New SqlParameter("@Pays", DefStr(body, "country", "Canada")))
        p.Add(New SqlParameter("@Statut", DefStr(body, "status", "Actif")))
        p.Add(New SqlParameter("@Notes", DBNull.Value))
        p.Add(New SqlParameter("@AdminId", DBNull.Value))

        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0013SaveClient", p)
        Dim newId As Integer = If(dt.Rows.Count > 0, CInt(dt.Rows(0)("Id")), 0)

        ' Relire pour renvoyer l'objet complet.
        Dim gp As New Collection
        gp.Add(New SqlParameter("@Id", newId))
        Dim g As DataTable = ApiData.ExecuteSQLdt("s0012GetClient", gp)
        WriteJson(ctx, 201, ClientJson(g.Rows(0)))
    End Sub

    Private Sub ListPayments(ctx As HttpContext, abonneId As Integer)
        Dim limit As Integer = GetLimit(ctx), offset As Integer = GetOffset(ctx)
        Dim p As New Collection
        p.Add(New SqlParameter("@AbonneId", abonneId))
        p.Add(New SqlParameter("@Status", DBNull.Value))
        p.Add(New SqlParameter("@Search", DBNull.Value))
        p.Add(New SqlParameter("@Direction", "Entrant"))
        p.Add(New SqlParameter("@Limit", limit + 1))
        p.Add(New SqlParameter("@Offset", offset))
        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0023ListPayments", p)
        WritePaged(ctx, dt, limit, offset, AddressOf PaymentJson)
    End Sub

    Private Sub GetPayment(ctx As HttpContext, abonneId As Integer, id As Long)
        Dim r As DataRow = LoadPayment(id)
        If r Is Nothing OrElse CInt(r("AbonneId")) <> abonneId OrElse r("Direction").ToString() <> "Entrant" Then
            Throw New ApiException(404, "not_found", "Paiement introuvable.")
        End If
        WriteJson(ctx, 200, PaymentJson(r))
    End Sub

    ' ---- Fournisseurs ----

    Private Sub ListFournisseurs(ctx As HttpContext, abonneId As Integer)
        Dim limit As Integer = GetLimit(ctx), offset As Integer = GetOffset(ctx)
        Dim p As New Collection
        p.Add(New SqlParameter("@AbonneId", abonneId))
        p.Add(New SqlParameter("@Search", DBNull.Value))
        p.Add(New SqlParameter("@Statut", DBNull.Value))
        p.Add(New SqlParameter("@Limit", limit + 1))
        p.Add(New SqlParameter("@Offset", offset))
        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0035ListFournisseurs", p)
        WritePaged(ctx, dt, limit, offset, AddressOf FournisseurJson)
    End Sub

    Private Sub GetFournisseur(ctx As HttpContext, abonneId As Integer, id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0036GetFournisseur", p)
        If dt.Rows.Count = 0 OrElse CInt(dt.Rows(0)("AbonneId")) <> abonneId Then
            Throw New ApiException(404, "not_found", "Fournisseur introuvable.")
        End If
        WriteJson(ctx, 200, FournisseurJson(dt.Rows(0)))
    End Sub

    Private Sub CreateFournisseur(ctx As HttpContext, abonneId As Integer)
        Dim body As JObject = ReadBody(ctx)
        Dim nom As String = JStr(body, "name")
        If String.IsNullOrEmpty(nom) Then Throw New ApiException(400, "validation", "Le champ 'name' est requis.")

        Dim p As New Collection
        Dim outId As New SqlParameter("@Id", SqlDbType.Int) With {.Direction = ParameterDirection.InputOutput, .Value = 0}
        p.Add(outId)
        p.Add(New SqlParameter("@AbonneId", abonneId))
        p.Add(New SqlParameter("@TypeFournisseur", DefStr(body, "type", "Entreprise")))
        p.Add(New SqlParameter("@Nom", nom))
        p.Add(New SqlParameter("@ReferenceExterne", NullStr(body, "reference")))
        p.Add(New SqlParameter("@CourrielContact", NullStr(body, "email")))
        p.Add(New SqlParameter("@Telephone", NullStr(body, "phone")))
        p.Add(New SqlParameter("@Adresse1", NullStr(body, "address1")))
        p.Add(New SqlParameter("@Adresse2", NullStr(body, "address2")))
        p.Add(New SqlParameter("@Ville", NullStr(body, "city")))
        p.Add(New SqlParameter("@Province", NullStr(body, "province")))
        p.Add(New SqlParameter("@CodePostal", NullStr(body, "postal_code")))
        p.Add(New SqlParameter("@Pays", DefStr(body, "country", "Canada")))
        p.Add(New SqlParameter("@Statut", DefStr(body, "status", "Actif")))
        p.Add(New SqlParameter("@Notes", DBNull.Value))
        p.Add(New SqlParameter("@AdminId", DBNull.Value))

        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0037SaveFournisseur", p)
        Dim newId As Integer = If(dt.Rows.Count > 0, CInt(dt.Rows(0)("Id")), 0)

        Dim gp As New Collection
        gp.Add(New SqlParameter("@Id", newId))
        Dim g As DataTable = ApiData.ExecuteSQLdt("s0036GetFournisseur", gp)
        WriteJson(ctx, 201, FournisseurJson(g.Rows(0)))
    End Sub

    ' ---- Décaissements (payouts) ----

    Private Sub ListPayouts(ctx As HttpContext, abonneId As Integer)
        Dim limit As Integer = GetLimit(ctx), offset As Integer = GetOffset(ctx)
        Dim p As New Collection
        p.Add(New SqlParameter("@AbonneId", abonneId))
        p.Add(New SqlParameter("@Status", DBNull.Value))
        p.Add(New SqlParameter("@Search", DBNull.Value))
        p.Add(New SqlParameter("@Direction", "Sortant"))
        p.Add(New SqlParameter("@Limit", limit + 1))
        p.Add(New SqlParameter("@Offset", offset))
        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0023ListPayments", p)
        WritePaged(ctx, dt, limit, offset, AddressOf PaymentJson)
    End Sub

    Private Sub GetPayout(ctx As HttpContext, abonneId As Integer, id As Long)
        Dim r As DataRow = LoadPayment(id)
        If r Is Nothing OrElse CInt(r("AbonneId")) <> abonneId OrElse r("Direction").ToString() <> "Sortant" Then
            Throw New ApiException(404, "not_found", "Décaissement introuvable.")
        End If
        WriteJson(ctx, 200, PaymentJson(r))
    End Sub

    Private Sub CreatePayout(ctx As HttpContext, abonneId As Integer)
        Dim body As JObject = ReadBody(ctx)
        Dim fournisseurId As Integer = JInt(body, "fournisseur_id")
        Dim amount As Long = JLong(body, "amount_cents")
        Dim fee As Long = JLongOpt(body, "fee_cents", 0)
        If fournisseurId <= 0 Then Throw New ApiException(400, "validation", "Le champ 'fournisseur_id' est requis.")
        If amount <= 0 Then Throw New ApiException(400, "validation", "Le champ 'amount_cents' doit être un entier positif.")

        Dim idem As String = ctx.Request.Headers("Idempotency-Key")
        If String.IsNullOrEmpty(idem) Then idem = JStr(body, "idempotency_key")

        Dim p As New Collection
        p.Add(New SqlParameter("@AbonneId", abonneId))
        p.Add(New SqlParameter("@FournisseurId", fournisseurId))
        p.Add(New SqlParameter("@AmountCents", amount))
        p.Add(New SqlParameter("@FeeCents", fee))
        p.Add(New SqlParameter("@Description", NullStr(body, "description")))
        p.Add(New SqlParameter("@Reference", NullStr(body, "reference")))
        p.Add(New SqlParameter("@SettlementDays", 2))
        p.Add(New SqlParameter("@IdempotencyKey", If(String.IsNullOrEmpty(idem), CObj(DBNull.Value), idem)))
        p.Add(New SqlParameter("@AdminId", DBNull.Value))

        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0038InitiatePayout", p)
        Dim pid As Long = If(dt.Rows.Count > 0, CLng(dt.Rows(0)("PaymentId")), 0)

        Dim r As DataRow = LoadPayment(pid)
        WriteJson(ctx, 201, PaymentJson(r))
    End Sub

    Private Sub CreatePayment(ctx As HttpContext, abonneId As Integer)
        Dim body As JObject = ReadBody(ctx)
        Dim clientId As Integer = JInt(body, "client_id")
        Dim amount As Long = JLong(body, "amount_cents")
        Dim fee As Long = JLongOpt(body, "fee_cents", 0)
        If clientId <= 0 Then Throw New ApiException(400, "validation", "Le champ 'client_id' est requis.")
        If amount <= 0 Then Throw New ApiException(400, "validation", "Le champ 'amount_cents' doit être un entier positif.")

        ' Idempotency-Key : en-tête prioritaire, sinon champ du corps.
        Dim idem As String = ctx.Request.Headers("Idempotency-Key")
        If String.IsNullOrEmpty(idem) Then idem = JStr(body, "idempotency_key")

        Dim p As New Collection
        p.Add(New SqlParameter("@AbonneId", abonneId))
        p.Add(New SqlParameter("@ClientId", clientId))
        p.Add(New SqlParameter("@AmountCents", amount))
        p.Add(New SqlParameter("@FeeCents", fee))
        p.Add(New SqlParameter("@Description", NullStr(body, "description")))
        p.Add(New SqlParameter("@Reference", NullStr(body, "reference")))
        p.Add(New SqlParameter("@SettlementDays", 2))
        p.Add(New SqlParameter("@IdempotencyKey", If(String.IsNullOrEmpty(idem), CObj(DBNull.Value), idem)))
        p.Add(New SqlParameter("@AdminId", DBNull.Value))

        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0020InitiateClientPayment", p)
        Dim pid As Long = If(dt.Rows.Count > 0, CLng(dt.Rows(0)("PaymentId")), 0)

        Dim r As DataRow = LoadPayment(pid)
        WriteJson(ctx, 201, PaymentJson(r))
    End Sub

    Private Function LoadPayment(id As Long) As DataRow
        Dim p As New Collection
        p.Add(New SqlParameter("@PaymentId", id))
        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0025GetPayment", p)
        If dt.Rows.Count = 0 Then Return Nothing
        Return dt.Rows(0)
    End Function

    ' =====================================================================
    ' Abonnés — provisioning par un partenaire (Modèle B)
    ' =====================================================================

    Private Sub ListAbonnes(ctx As HttpContext, principal As ApiPrincipal)
        Dim limit As Integer = GetLimit(ctx), offset As Integer = GetOffset(ctx)
        Dim search As String = ctx.Request.QueryString("search")
        Dim p As New Collection
        p.Add(New SqlParameter("@PartenaireId", principal.PartenaireId))
        p.Add(New SqlParameter("@Search", If(String.IsNullOrEmpty(search), CObj(DBNull.Value), search)))
        p.Add(New SqlParameter("@Limit", limit + 1))
        p.Add(New SqlParameter("@Offset", offset))
        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0116ListAbonnesForPartner", p)
        WritePaged(ctx, dt, limit, offset, AddressOf AbonneJson)
    End Sub

    Private Function LoadPartnerTenant(partenaireId As Integer, id As Integer) As DataRow
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@PartenaireId", partenaireId))
        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0117GetAbonneForPartner", p)
        If dt.Rows.Count = 0 Then Return Nothing
        Return dt.Rows(0)
    End Function

    Private Sub GetAbonne(ctx As HttpContext, principal As ApiPrincipal, id As Integer)
        Dim r As DataRow = LoadPartnerTenant(principal.PartenaireId, id)
        If r Is Nothing Then Throw New ApiException(404, "not_found", "Abonné introuvable.")
        WriteJson(ctx, 200, AbonneJson(r))
    End Sub

    Private Sub CreateAbonne(ctx As HttpContext, principal As ApiPrincipal)
        Dim body As JObject = ReadBody(ctx)
        Dim nom As String = JStr(body, "legal_name")
        If String.IsNullOrEmpty(nom) Then nom = JStr(body, "name")
        If String.IsNullOrEmpty(nom) Then Throw New ApiException(400, "validation", "Le champ 'legal_name' est requis.")

        Dim p As New Collection
        p.Add(New SqlParameter("@PartenaireId", principal.PartenaireId))
        p.Add(New SqlParameter("@RaisonSociale", nom))
        p.Add(New SqlParameter("@NomAffichage", NullStr(body, "display_name")))
        p.Add(New SqlParameter("@NumeroEntreprise", NullStr(body, "business_number")))
        p.Add(New SqlParameter("@CourrielContact", NullStr(body, "email")))
        p.Add(New SqlParameter("@Telephone", NullStr(body, "phone")))
        p.Add(New SqlParameter("@Adresse1", NullStr(body, "address1")))
        p.Add(New SqlParameter("@Adresse2", NullStr(body, "address2")))
        p.Add(New SqlParameter("@Ville", NullStr(body, "city")))
        p.Add(New SqlParameter("@Province", NullStr(body, "province")))
        p.Add(New SqlParameter("@CodePostal", NullStr(body, "postal_code")))
        p.Add(New SqlParameter("@Pays", DefStr(body, "country", "Canada")))
        p.Add(New SqlParameter("@Statut", DefStr(body, "status", "Prospect")))
        Dim outId As New SqlParameter("@Id", SqlDbType.Int) With {.Direction = ParameterDirection.InputOutput, .Value = 0}
        p.Add(outId)

        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0115CreateAbonneForPartner", p)
        If dt.Rows.Count = 0 Then Throw New ApiException(500, "server_error", "Création échouée.")
        Dim r As DataRow = dt.Rows(0)

        Try
            clsAudit.Write(0, "partner:" & principal.PartenaireId, "AbonneProvision", "Abonne",
                           CInt(r("Id")), r("RaisonSociale").ToString(), "via API partenaire", ctx.Request.UserHostAddress)
        Catch
        End Try

        WriteJson(ctx, 201, AbonneJson(r))
    End Sub

    Private Sub RunKyb(ctx As HttpContext, principal As ApiPrincipal, id As Integer)
        If LoadPartnerTenant(principal.PartenaireId, id) Is Nothing Then
            Throw New ApiException(404, "not_found", "Abonné introuvable.")
        End If
        Dim res As KybResult = clsKyb.RunCheck(id, 0, "partner:" & principal.PartenaireId, ctx.Request.UserHostAddress)
        Dim reloaded As DataRow = LoadPartnerTenant(principal.PartenaireId, id)
        Dim o As New JObject()
        o("abonne_id") = id
        o("kyb_status") = If(reloaded IsNot Nothing, SVal(reloaded, "StatutKYB"), JValue.CreateNull())
        o("result") = KybResultJson(res)
        WriteJson(ctx, 200, o)
    End Sub

    Private Sub ListKyb(ctx As HttpContext, principal As ApiPrincipal, id As Integer)
        If LoadPartnerTenant(principal.PartenaireId, id) Is Nothing Then
            Throw New ApiException(404, "not_found", "Abonné introuvable.")
        End If
        Dim p As New Collection
        p.Add(New SqlParameter("@AbonneId", id))
        p.Add(New SqlParameter("@Top", 20))
        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0102ListKybChecks", p)
        Dim arr As New JArray()
        For Each r As DataRow In dt.Rows
            Dim o As New JObject()
            o("id") = CInt(r("Id"))
            o("provider") = SVal(r, "Provider")
            o("status") = SVal(r, "Status")
            o("score") = If(IsDBNull(r("Score")), CType(Nothing, JToken), New JValue(CInt(r("Score"))))
            o("message") = SVal(r, "Message")
            o("utc") = DateTimeVal(r, "Utc")
            arr.Add(o)
        Next
        Dim wrap As New JObject()
        wrap("data") = arr
        WriteJson(ctx, 200, wrap)
    End Sub

    Private Function AbonneJson(r As DataRow) As JObject
        Dim o As New JObject()
        o("id") = CInt(r("Id"))
        o("tenant_guid") = SVal(r, "TenantGUID")
        o("legal_name") = SVal(r, "RaisonSociale")
        o("display_name") = SVal(r, "NomAffichage")
        o("business_number") = SVal(r, "NumeroEntreprise")
        o("email") = SVal(r, "CourrielContact")
        o("phone") = SVal(r, "Telephone")
        o("city") = SVal(r, "Ville")
        o("province") = SVal(r, "Province")
        o("status") = SVal(r, "Statut")
        o("kyb_status") = SVal(r, "StatutKYB")
        o("created_utc") = DateTimeVal(r, "CreatedUtc")
        Return o
    End Function

    Private Function KybResultJson(res As KybResult) As JObject
        Dim o As New JObject()
        o("status") = res.Status
        o("score") = res.Score
        o("registry_match") = res.RegistryMatch
        o("watchlist_clear") = res.WatchlistClear
        o("address_valid") = res.AddressValid
        o("provider_ref") = res.ProviderRef
        o("message") = res.Message
        Return o
    End Function

    ''' <summary>Auth déléguée : pour une clé partenaire, valide l'en-tête
    ''' X-Abonne-Id et vérifie que le tenant appartient bien au partenaire.</summary>
    Private Function ResolveDelegatedTenant(ctx As HttpContext, principal As ApiPrincipal) As Integer
        Dim h As String = ctx.Request.Headers("X-Abonne-Id")
        Dim aid As Integer
        If String.IsNullOrEmpty(h) OrElse Not Integer.TryParse(h, aid) OrElse aid <= 0 Then
            Throw New ApiException(400, "validation", "En-tête X-Abonne-Id requis pour une clé partenaire.")
        End If
        If LoadPartnerTenant(principal.PartenaireId, aid) Is Nothing Then
            Throw New ApiException(403, "forbidden", "Cet abonné n'appartient pas au partenaire.")
        End If
        Return aid
    End Function

    ' ---- Webhook (configuration) ----

    Private Function LoadEndpoint(abonneId As Integer) As DataRow
        Dim p As New Collection
        p.Add(New SqlParameter("@AbonneId", abonneId))
        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0031GetWebhookEndpoint", p)
        If dt.Rows.Count = 0 Then Return Nothing
        Return dt.Rows(0)
    End Function

    Private Sub GetWebhook(ctx As HttpContext, abonneId As Integer)
        Dim r As DataRow = LoadEndpoint(abonneId)
        If r Is Nothing Then Throw New ApiException(404, "not_found", "Aucun webhook configuré.")
        WriteJson(ctx, 200, WebhookJson(r))
    End Sub

    Private Sub PutWebhook(ctx As HttpContext, abonneId As Integer)
        Dim body As JObject = ReadBody(ctx)
        Dim url As String = JStr(body, "url")
        If String.IsNullOrEmpty(url) Then Throw New ApiException(400, "validation", "Le champ 'url' est requis.")
        If Not (url.StartsWith("http://", StringComparison.OrdinalIgnoreCase) OrElse url.StartsWith("https://", StringComparison.OrdinalIgnoreCase)) Then
            Throw New ApiException(400, "validation", "L'URL doit commencer par http:// ou https://.")
        End If
        Dim active As Boolean = JBoolOpt(body, "active", True)

        Dim existing As DataRow = LoadEndpoint(abonneId)
        Dim provided As String = JStr(body, "secret")
        Dim secret As String
        Dim returnSecret As Boolean

        If Not String.IsNullOrEmpty(provided) Then
            If provided.Length < 8 Then Throw New ApiException(400, "validation", "Le secret doit contenir au moins 8 caractères.")
            secret = provided
            returnSecret = True
        ElseIf existing Is Nothing Then
            secret = GenerateSecret()
            returnSecret = True
        Else
            secret = existing("Secret").ToString()
            returnSecret = False
        End If

        Dim p As New Collection
        p.Add(New SqlParameter("@AbonneId", abonneId))
        p.Add(New SqlParameter("@Url", url))
        p.Add(New SqlParameter("@Secret", secret))
        p.Add(New SqlParameter("@IsActive", active))
        ApiData.ExecuteSQL("s0030SaveWebhookEndpoint", p)

        Dim o As JObject = WebhookJson(LoadEndpoint(abonneId))
        If returnSecret Then o("secret") = secret
        WriteJson(ctx, 200, o)
    End Sub

    Private Sub DeleteWebhook(ctx As HttpContext, abonneId As Integer)
        Dim existing As DataRow = LoadEndpoint(abonneId)
        If existing Is Nothing Then Throw New ApiException(404, "not_found", "Aucun webhook configuré.")
        Dim p As New Collection
        p.Add(New SqlParameter("@AbonneId", abonneId))
        p.Add(New SqlParameter("@Url", existing("Url").ToString()))
        p.Add(New SqlParameter("@Secret", existing("Secret").ToString()))
        p.Add(New SqlParameter("@IsActive", False))
        ApiData.ExecuteSQL("s0030SaveWebhookEndpoint", p)
        Dim o As New JObject()
        o("url") = existing("Url").ToString()
        o("active") = False
        WriteJson(ctx, 200, o)
    End Sub

    Private Sub ListWebhookDeliveries(ctx As HttpContext, abonneId As Integer)
        Dim limit As Integer = GetLimit(ctx), offset As Integer = GetOffset(ctx)
        Dim p As New Collection
        p.Add(New SqlParameter("@AbonneId", abonneId))
        p.Add(New SqlParameter("@Limit", limit + 1))
        p.Add(New SqlParameter("@Offset", offset))
        Dim dt As DataTable = ApiData.ExecuteSQLdt("s0034ListDeliveries", p)
        WritePaged(ctx, dt, limit, offset, AddressOf DeliveryJson)
    End Sub

    Private Function WebhookJson(r As DataRow) As JObject
        Dim o As New JObject()
        o("url") = SVal(r, "Url")
        o("active") = (Not IsDBNull(r("IsActive"))) AndAlso CBool(r("IsActive"))
        Dim sec As String = If(IsDBNull(r("Secret")), "", r("Secret").ToString())
        o("has_secret") = (sec.Length > 0)
        o("created_utc") = DateTimeVal(r, "CreatedUtc")
        o("updated_utc") = DateTimeVal(r, "UpdatedUtc")
        Return o
    End Function

    Private Function DeliveryJson(r As DataRow) As JObject
        Dim o As New JObject()
        o("id") = CLng(r("Id"))
        o("event") = SVal(r, "EventType")
        o("payment_id") = If(IsDBNull(r("PaymentId")), CType(Nothing, JToken), New JValue(CLng(r("PaymentId"))))
        o("status") = SVal(r, "Status")
        o("attempts") = CInt(r("Attempts"))
        o("max_attempts") = CInt(r("MaxAttempts"))
        o("response_status") = If(IsDBNull(r("ResponseStatus")), CType(Nothing, JToken), New JValue(CInt(r("ResponseStatus"))))
        o("last_error") = SVal(r, "LastError")
        o("next_attempt_utc") = DateTimeVal(r, "NextAttemptUtc")
        o("created_utc") = DateTimeVal(r, "CreatedUtc")
        o("delivered_utc") = DateTimeVal(r, "DeliveredUtc")
        Return o
    End Function

    Private Shared Function GenerateSecret() As String
        Dim bytes(23) As Byte
        Using rng As System.Security.Cryptography.RandomNumberGenerator = System.Security.Cryptography.RandomNumberGenerator.Create()
            rng.GetBytes(bytes)
        End Using
        Return "whsec_" & Convert.ToBase64String(bytes).Replace("+", "").Replace("/", "").Replace("=", "")
    End Function

    ' =====================================================================
    ' Mapping JSON
    ' =====================================================================

    Private Function ClientJson(r As DataRow) As JObject
        Dim o As New JObject()
        o("id") = CInt(r("Id"))
        o("name") = SVal(r, "Nom")
        o("type") = SVal(r, "TypeClient")
        o("reference") = SVal(r, "ReferenceExterne")
        o("email") = SVal(r, "CourrielContact")
        If r.Table.Columns.Contains("Telephone") Then o("phone") = SVal(r, "Telephone")
        o("city") = SVal(r, "Ville")
        o("province") = SVal(r, "Province")
        o("status") = SVal(r, "Statut")
        Return o
    End Function

    Private Function FournisseurJson(r As DataRow) As JObject
        Dim o As New JObject()
        o("id") = CInt(r("Id"))
        o("name") = SVal(r, "Nom")
        o("type") = SVal(r, "TypeFournisseur")
        o("reference") = SVal(r, "ReferenceExterne")
        o("email") = SVal(r, "CourrielContact")
        If r.Table.Columns.Contains("Telephone") Then o("phone") = SVal(r, "Telephone")
        o("city") = SVal(r, "Ville")
        o("province") = SVal(r, "Province")
        o("status") = SVal(r, "Statut")
        Return o
    End Function

    Private Function PaymentJson(r As DataRow) As JObject
        Dim o As New JObject()
        o("id") = CLng(r("Id"))
        o("client_id") = If(IsDBNull(r("ClientId")), CType(Nothing, JToken), New JValue(CInt(r("ClientId"))))
        o("client_name") = SVal(r, "ClientNom")
        If r.Table.Columns.Contains("FournisseurId") Then
            o("fournisseur_id") = If(IsDBNull(r("FournisseurId")), CType(Nothing, JToken), New JValue(CInt(r("FournisseurId"))))
        End If
        o("fournisseur_name") = SVal(r, "FournisseurNom")
        o("direction") = SVal(r, "Direction")
        o("method") = SVal(r, "Method")
        o("amount_cents") = Lng(r, "AmountCents")
        o("fee_cents") = Lng(r, "FeeCents")
        o("net_cents") = Lng(r, "NetCents")
        o("currency") = SVal(r, "Devise")
        o("status") = MapStatus(SVal(r, "Status"))
        o("reference") = SVal(r, "Reference")
        o("description") = SVal(r, "Description")
        o("expected_settlement_date") = DateVal(r, "ExpectedSettlementDate")
        o("created_utc") = DateTimeVal(r, "InitiatedUtc")
        Return o
    End Function

    Private Function MapStatus(s As String) As String
        Select Case s
            Case "Initie" : Return "initiated"
            Case "Regle" : Return "settled"
            Case "Retourne" : Return "returned"
            Case Else : Return s
        End Select
    End Function

    ' =====================================================================
    ' Utilitaires
    ' =====================================================================

    Private Function ExtractApiKey(ctx As HttpContext) As String
        Dim k As String = ctx.Request.Headers("X-Api-Key")
        If Not String.IsNullOrEmpty(k) Then Return k.Trim()
        Dim auth As String = ctx.Request.Headers("Authorization")
        If Not String.IsNullOrEmpty(auth) AndAlso auth.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase) Then
            Return auth.Substring(7).Trim()
        End If
        Return ""
    End Function

    ' --- Pagination ---
    Private Const DefaultLimit As Integer = 25
    Private Const MaxLimit As Integer = 100

    Private Function GetLimit(ctx As HttpContext) As Integer
        Dim v As Integer
        If Integer.TryParse(ctx.Request.QueryString("limit"), v) Then
            If v < 1 Then Return 1
            If v > MaxLimit Then Return MaxLimit
            Return v
        End If
        Return DefaultLimit
    End Function

    Private Function GetOffset(ctx As HttpContext) As Integer
        Dim v As Integer
        If Integer.TryParse(ctx.Request.QueryString("offset"), v) AndAlso v > 0 Then Return v
        Return 0
    End Function

    ''' <summary>Écrit une liste paginée. La proc renvoie limit+1 lignes ;
    ''' s'il y en a plus que limit, il existe une page suivante.</summary>
    Private Sub WritePaged(ctx As HttpContext, dt As DataTable, limit As Integer, offset As Integer, mapper As Func(Of DataRow, JObject))
        Dim hasMore As Boolean = (dt.Rows.Count > limit)
        Dim take As Integer = Math.Min(limit, dt.Rows.Count)
        Dim arr As New JArray()
        For i As Integer = 0 To take - 1
            arr.Add(mapper(dt.Rows(i)))
        Next
        Dim o As New JObject()
        o("data") = arr
        Dim pg As New JObject()
        pg("limit") = limit
        pg("offset") = offset
        pg("count") = take
        pg("has_more") = hasMore
        If hasMore Then pg("next_offset") = offset + limit Else pg("next_offset") = CType(Nothing, JToken)
        o("pagination") = pg
        WriteJson(ctx, 200, o)
    End Sub

    Private Function ReadBody(ctx As HttpContext) As JObject
        Dim raw As String
        ctx.Request.InputStream.Position = 0
        Using sr As New StreamReader(ctx.Request.InputStream, ctx.Request.ContentEncoding)
            raw = sr.ReadToEnd()
        End Using
        If String.IsNullOrWhiteSpace(raw) Then Throw New ApiException(400, "validation", "Corps JSON requis.")
        Try
            Return JObject.Parse(raw)
        Catch
            Throw New ApiException(400, "validation", "JSON invalide.")
        End Try
    End Function

    Private Sub RequireMethod(method As String, expected As String)
        If method <> expected Then Throw New ApiException(405, "method_not_allowed", "Méthode non permise.")
    End Sub

    Private Function ParseId(s As String) As Integer
        Dim v As Integer
        If Not Integer.TryParse(s, v) Then Throw New ApiException(400, "validation", "Identifiant invalide.")
        Return v
    End Function

    ' --- lecture JSON entrant ---
    Private Function JStr(o As JObject, name As String) As String
        Dim t As JToken = o(name)
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return Nothing
        Return t.ToString()
    End Function
    Private Function DefStr(o As JObject, name As String, dflt As String) As String
        Dim s As String = JStr(o, name)
        Return If(String.IsNullOrEmpty(s), dflt, s)
    End Function
    Private Function NullStr(o As JObject, name As String) As Object
        Dim s As String = JStr(o, name)
        If String.IsNullOrEmpty(s) Then Return DBNull.Value
        Return s
    End Function
    Private Function JInt(o As JObject, name As String) As Integer
        Dim t As JToken = o(name)
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return 0
        Dim v As Integer
        Integer.TryParse(t.ToString(), v)
        Return v
    End Function
    Private Function JLong(o As JObject, name As String) As Long
        Dim t As JToken = o(name)
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return 0
        Dim v As Long
        Long.TryParse(t.ToString(), v)
        Return v
    End Function
    Private Function JLongOpt(o As JObject, name As String, dflt As Long) As Long
        Dim t As JToken = o(name)
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return dflt
        Dim v As Long
        If Long.TryParse(t.ToString(), v) Then Return v
        Return dflt
    End Function
    Private Function JBoolOpt(o As JObject, name As String, dflt As Boolean) As Boolean
        Dim t As JToken = o(name)
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return dflt
        Dim b As Boolean
        If Boolean.TryParse(t.ToString(), b) Then Return b
        Return dflt
    End Function

    ' --- lecture DataRow -> JSON ---
    Private Function SVal(r As DataRow, col As String) As JToken
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return JValue.CreateNull()
        Return New JValue(r(col).ToString())
    End Function
    Private Function Lng(r As DataRow, col As String) As Long
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return 0
        Return Convert.ToInt64(r(col))
    End Function
    Private Function DateVal(r As DataRow, col As String) As JToken
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return JValue.CreateNull()
        Return New JValue(CDate(r(col)).ToString("yyyy-MM-dd"))
    End Function
    Private Function DateTimeVal(r As DataRow, col As String) As JToken
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return JValue.CreateNull()
        Return New JValue(CDate(r(col)).ToString("yyyy-MM-ddTHH:mm:ss") & "Z")
    End Function

    Private Sub WriteJson(ctx As HttpContext, status As Integer, obj As JToken)
        ctx.Response.StatusCode = status
        ctx.Response.Write(obj.ToString(Formatting.None))
    End Sub

    Private Sub WriteError(ctx As HttpContext, status As Integer, code As String, message As String)
        ctx.Response.StatusCode = status
        Dim err As New JObject()
        Dim inner As New JObject()
        inner("code") = code
        inner("message") = message
        err("error") = inner
        ctx.Response.Write(err.ToString(Formatting.None))
    End Sub

End Class

''' <summary>Exception applicative portant un code HTTP + un code d'erreur.</summary>
Public Class ApiException
    Inherits Exception
    Public ReadOnly StatusCode As Integer
    Public ReadOnly ErrorCode As String
    Public Sub New(statusCode As Integer, errorCode As String, message As String)
        MyBase.New(message)
        Me.StatusCode = statusCode
        Me.ErrorCode = errorCode
    End Sub
End Class
