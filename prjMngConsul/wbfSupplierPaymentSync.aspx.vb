Imports System
Imports System.Collections.Generic
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text
Imports Stripe
Imports Stripe.Checkout

''' <summary>
''' Page de synchronisation manuelle des paiements Stripe pour une facture.
'''
''' URL : wbfSupplierPaymentSync.aspx?DocumentId=N
'''
''' Cas d'usage : si le webhook a echoue (raison inconnue) et que la facture
''' n'a pas ete marquee comme payee alors que le client a paye sur Stripe.
'''
''' Flow :
'''   1. Recupere StripeAccountId du fournisseur via DocumentId
'''   2. Liste les Sessions Stripe filtrees par metadata.MngConsul_DocumentId
'''   3. Pour chacune : verifie si T140Reglement existe (s0082)
'''   4. Pour les sessions paid mais sans T140 : bouton "Importer"
'''   5. Clic Importer -> appel s0080CreateDecaissementFromStripe
''' </summary>
Public Class wbfSupplierPaymentSync
    Inherits clsData

    Private Property DocumentId As Integer
        Get
            Return CInt(If(ViewState("DocumentId"), 0))
        End Get
        Set(value As Integer)
            ViewState("DocumentId") = value
        End Set
    End Property

    Private Property PartyId As Integer
        Get
            Return CInt(If(ViewState("PartyId"), 0))
        End Get
        Set(value As Integer)
            ViewState("PartyId") = value
        End Set
    End Property

    Private Property StripeAccountId As String
        Get
            Return If(ViewState("StripeAccountId"), "").ToString()
        End Get
        Set(value As String)
            ViewState("StripeAccountId") = value
        End Set
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            Dim docIdStr As String = Request.QueryString("DocumentId")
            Dim docId As Integer = 0
            Integer.TryParse(docIdStr, docId)

            If docId = 0 Then
                ShowError("DocumentId manquant.")
                Return
            End If

            DocumentId = docId
            LoadAndDisplay()
        End If
    End Sub

    Private Sub LoadAndDisplay()

        ' Recuperer infos facture + fournisseur via T060Document + T050Party
        Dim supplierName As String = ""
        Dim stripeAccountId As String = ""
        Dim partyId As Integer = 0

        Try
            Dim sql As String = "SELECT TOP 1 T050.Id AS PartyId, T050.Name, T050.StripeAccountId " &
                                "FROM dbo.T060Document T060 " &
                                "JOIN dbo.T050Party T050 ON T050.PartyGUID = T060.PartyGUID " &
                                "WHERE T060.Id = @DocumentId"
            Using conn As New SqlConnection(ConnectionString)
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@DocumentId", DocumentId)
                    conn.Open()
                    Using reader = cmd.ExecuteReader()
                        If reader.Read() Then
                            partyId = If(reader("PartyId") Is DBNull.Value, 0, CInt(reader("PartyId")))
                            supplierName = If(reader("Name") Is DBNull.Value, "", reader("Name").ToString())
                            stripeAccountId = If(reader("StripeAccountId") Is DBNull.Value, "", reader("StripeAccountId").ToString())
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("LoadAndDisplay error: " & ex.Message)
        End Try

        PartyId = partyId
        StripeAccountId = stripeAccountId

        litDocumentId.Text = "#" & DocumentId.ToString()
        litSupplierName.Text = Server.HtmlEncode(If(String.IsNullOrEmpty(supplierName), "Fournisseur inconnu", supplierName))

        If String.IsNullOrEmpty(stripeAccountId) Then
            ShowError("Ce fournisseur n'a pas de compte Stripe Connect configuré. Aucune session à synchroniser.")
            pnlSessionList.Visible = False
            Return
        End If

        ' Lister les sessions Stripe pour cette facture
        Try
            Dim sessions As List(Of Session) = clsStripe.ListSessionsForDocument(stripeAccountId, DocumentId)

            If sessions Is Nothing OrElse sessions.Count = 0 Then
                pnlSessionList.Visible = False
                pnlEmpty.Visible = True
                Return
            End If

            ' Render chaque session
            Dim sb As New StringBuilder()
            Dim culture As New CultureInfo("fr-CA")

            For Each s As Session In sessions
                Dim amount As Decimal = If(s.AmountTotal.HasValue, CDec(s.AmountTotal.Value) / 100D, 0D)
                Dim createdDate As Date = If(s.Created <> Date.MinValue, s.Created, Date.Now)
                Dim isPaid As Boolean = (s.PaymentStatus = "paid" OrElse s.PaymentStatus = "no_payment_required")

                ' Verifier en BD si ce session_id a deja un T140
                Dim alreadyInBD As Boolean = CheckReglementExists(s.Id)

                Dim cardClass As String = "session-card "
                If isPaid AndAlso alreadyInBD Then
                    cardClass &= "synced"
                ElseIf isPaid AndAlso Not alreadyInBD Then
                    cardClass &= "missing"
                Else
                    cardClass &= "unpaid"
                End If

                sb.Append("<div class=""" & cardClass & """>")

                ' En-tete : montant + date
                sb.Append("<div class=""session-info"">")
                sb.Append("<span class=""session-amount"">" & amount.ToString("N2", culture) & " $ CAD</span>")
                sb.Append("<span class=""session-date"">" & createdDate.ToString("dd MMM yyyy HH:mm", culture) & "</span>")
                sb.Append("</div>")

                ' Session ID
                sb.Append("<div class=""session-id"">" & Server.HtmlEncode(s.Id) & "</div>")

                ' Badges statut
                sb.Append("<div class=""status-badges"">")
                If isPaid Then
                    sb.Append("<span class=""badge badge-stripe-paid"">Stripe : Payé</span>")
                Else
                    sb.Append("<span class=""badge badge-stripe-unpaid"">Stripe : " & Server.HtmlEncode(s.PaymentStatus) & "</span>")
                End If

                If alreadyInBD Then
                    sb.Append("<span class=""badge badge-bd-yes"">✓ Enregistré en BD</span>")
                ElseIf isPaid Then
                    sb.Append("<span class=""badge badge-bd-no"">⚠ Manquant en BD</span>")
                End If
                sb.Append("</div>")

                ' Bouton importer si paid + pas en BD
                If isPaid AndAlso Not alreadyInBD Then
                    sb.Append("<div class=""action-row"">")
                    sb.Append("<button type=""submit"" name=""import"" value=""" & Server.HtmlEncode(s.Id) & """ class=""btn-import"" formnovalidate>")
                    sb.Append("Importer dans 60Sec-AI →")
                    sb.Append("</button>")
                    sb.Append("</div>")
                End If

                sb.Append("</div>")
            Next

            litSessions.Text = sb.ToString()

        Catch ex As StripeException
            ShowError("Erreur Stripe : " & ex.Message)
        Catch ex As Exception
            ShowError("Erreur : " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Gere le clic sur un bouton "Importer" (genere dynamiquement).
    ''' Le submit envoie le session_id via le parametre POST 'import'.
    ''' </summary>
    Protected Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        If IsPostBack Then
            Dim importSessionId As String = Request.Form("import")
            If Not String.IsNullOrEmpty(importSessionId) AndAlso importSessionId.StartsWith("cs_") Then

                ' Au cas ou DocumentId/PartyId/StripeAccountId ont ete perdus du ViewState,
                ' on les recharge depuis la BD via le DocumentId du QueryString.
                If DocumentId = 0 Then
                    Dim docIdStr As String = Request.QueryString("DocumentId")
                    Dim docId As Integer = 0
                    Integer.TryParse(docIdStr, docId)
                    DocumentId = docId
                End If

                If String.IsNullOrEmpty(StripeAccountId) Then
                    ReloadStripeAccountFromDB()
                End If

                ImportSession(importSessionId)
                LoadAndDisplay()
            End If
        End If
    End Sub

    ''' <summary>
    ''' Recharge StripeAccountId + PartyId depuis la BD via DocumentId.
    ''' Utile si le ViewState a ete perdu sur un postback.
    ''' </summary>
    Private Sub ReloadStripeAccountFromDB()
        Try
            Dim sql As String = "SELECT TOP 1 T050.Id AS PartyId, T050.StripeAccountId " &
                                "FROM dbo.T060Document T060 " &
                                "JOIN dbo.T050Party T050 ON T050.PartyGUID = T060.PartyGUID " &
                                "WHERE T060.Id = @DocumentId"
            Using conn As New SqlConnection(ConnectionString)
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@DocumentId", DocumentId)
                    conn.Open()
                    Using reader = cmd.ExecuteReader()
                        If reader.Read() Then
                            PartyId = If(reader("PartyId") Is DBNull.Value, 0, CInt(reader("PartyId")))
                            StripeAccountId = If(reader("StripeAccountId") Is DBNull.Value, "", reader("StripeAccountId").ToString())
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ReloadStripeAccountFromDB error: " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Importe un paiement Stripe (session) dans T140Reglement en appelant s0080.
    ''' Idempotent : la SP detecte si le reglement existe deja.
    ''' </summary>
    Private Sub ImportSession(sessionId As String)
        Try
            ' Defensive : si StripeAccountId est vide, recharger depuis BD
            If String.IsNullOrEmpty(StripeAccountId) Then
                ReloadStripeAccountFromDB()
            End If

            If String.IsNullOrEmpty(StripeAccountId) Then
                ShowError("Impossible de retrouver le compte Stripe du fournisseur (DocumentId=" & DocumentId.ToString() & "). Veuillez recharger la page.")
                Return
            End If

            ' Recuperer les details de la session Stripe sur le compte connecte
            Dim session As Session = clsStripe.GetCheckoutSessionFromConnectedAccount(sessionId, StripeAccountId)

            If session Is Nothing Then
                ShowError("Session Stripe introuvable : " & sessionId)
                Return
            End If

            ' Extraire les donnees pour s0080
            Dim originalAmount As Decimal = 0D
            Dim companyGuidStr As String = ""
            Dim userIdMeta As Integer = 0
            Dim paymentMethod As String = "card"
            Dim partyIdMeta As Integer = 0
            Dim docIdMeta As Integer = 0

            If session.Metadata IsNot Nothing Then
                Dim v As String = Nothing

                If session.Metadata.TryGetValue("MngConsul_OriginalAmount", v) AndAlso Not String.IsNullOrEmpty(v) Then
                    Decimal.TryParse(v, NumberStyles.Any, CultureInfo.InvariantCulture, originalAmount)
                End If

                If session.Metadata.TryGetValue("MngConsul_CompanyGUID", v) AndAlso Not String.IsNullOrEmpty(v) Then
                    companyGuidStr = v
                End If

                If session.Metadata.TryGetValue("MngConsul_UserId", v) AndAlso Not String.IsNullOrEmpty(v) Then
                    Integer.TryParse(v, userIdMeta)
                End If

                If session.Metadata.TryGetValue("MngConsul_PaymentMethod", v) AndAlso Not String.IsNullOrEmpty(v) Then
                    paymentMethod = v
                End If

                If session.Metadata.TryGetValue("MngConsul_PartyId", v) AndAlso Not String.IsNullOrEmpty(v) Then
                    Integer.TryParse(v, partyIdMeta)
                End If

                If session.Metadata.TryGetValue("MngConsul_DocumentId", v) AndAlso Not String.IsNullOrEmpty(v) Then
                    Integer.TryParse(v, docIdMeta)
                End If
            End If

            ' Fallback : si metadata absente, utiliser ce qu'on a
            If partyIdMeta = 0 Then partyIdMeta = PartyId
            If docIdMeta = 0 Then docIdMeta = DocumentId

            Dim companyGuid As Guid = Guid.Empty
            Guid.TryParse(companyGuidStr, companyGuid)
            If companyGuid = Guid.Empty Then companyGuid = Company

            ' Si pas de OriginalAmount, utiliser le montant total
            If originalAmount <= 0D AndAlso session.AmountTotal.HasValue Then
                originalAmount = CDec(session.AmountTotal.Value) / 100D
            End If

            If originalAmount <= 0D Then
                ShowError("Impossible de déterminer le montant de la facture pour cette session.")
                Return
            End If

            ' Appeler s0080 (idempotent : ne fera rien si deja existe)
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", companyGuid))
            p.Add(New SqlParameter("@PartyId", partyIdMeta))
            p.Add(New SqlParameter("@DocumentId", docIdMeta))
            p.Add(New SqlParameter("@Amount", originalAmount))
            p.Add(New SqlParameter("@StripeSessionId", sessionId))
            p.Add(New SqlParameter("@StripePaymentIntentId", If(String.IsNullOrEmpty(session.PaymentIntentId), CType(DBNull.Value, Object), session.PaymentIntentId)))
            p.Add(New SqlParameter("@PaymentMethod", paymentMethod))
            p.Add(New SqlParameter("@CreatedByUserId", If(userIdMeta > 0, CType(userIdMeta, Object), UserId)))

            ExecuteSQL("s0080CreateDecaissementFromStripe", p)

            ShowAlert("✓ Paiement importé avec succès dans la comptabilité.", isSuccess:=True)

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ImportSession error: " & ex.Message)
            ShowError("Erreur lors de l'import : " & ex.Message)
        End Try
    End Sub

    Protected Sub btnRefresh_Click(sender As Object, e As EventArgs) Handles btnRefresh.Click
        LoadAndDisplay()
    End Sub

    Private Function CheckReglementExists(sessionId As String) As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@StripeSessionId", sessionId))
            Dim ds As DataSet = ExecuteSQLds("s0082CheckReglementExists", p)
            Return ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0
        Catch
            Return False
        End Try
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

    Private Sub ShowAlert(msg As String, Optional isSuccess As Boolean = False)
        pnlAlert.Visible = True
        litAlert.Text = msg
        If isSuccess Then
            pnlAlert.CssClass = "alert success"
        Else
            pnlAlert.CssClass = "alert info"
        End If
    End Sub

End Class
