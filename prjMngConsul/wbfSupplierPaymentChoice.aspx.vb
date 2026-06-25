Imports System
Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization

''' <summary>
''' Modal de choix de methode de paiement pour payer un fournisseur.
''' Recoit en QueryString : DocumentId, PartyId, Amount
'''
''' Flow :
'''   1. Affiche les 2 methodes (Carte, ACSS) avec frais calcules
'''   2. Pre-selectionne la derniere methode utilisee (T050Party.LastPaymentMethod)
'''   3. Detecte si une autorisation auto-pay existe deja (T144) -> affiche badge
'''   4. Sinon, propose case a cocher "Autoriser auto-paiement futur" + plafond
'''   5. Au clic "Payer" : sauve la methode + redirige vers Stripe Checkout (Connect)
'''      Si auto-pay coche, passe metadata.MngConsul_AuthorizeAutoPay et setupFutureUsage
''' </summary>
Public Class wbfSupplierPaymentChoice
    Inherits clsData

    ' Proprietes exposees au markup pour injection JS
    Public Property AmountForJs As String = "0"
    Public Property LastUsedMethodForJs As String = ""

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

    Private Property Amount As Decimal
        Get
            Return CDec(If(ViewState("Amount"), 0D))
        End Get
        Set(value As Decimal)
            ViewState("Amount") = value
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

            ' Recuperer les parametres du modal
            Dim docIdStr As String = Request.QueryString("DocumentId")
            Dim partyIdStr As String = Request.QueryString("PartyId")
            Dim amountStr As String = Request.QueryString("Amount")

            Dim docId As Integer = 0
            Dim partId As Integer = 0
            Dim amt As Decimal = 0D

            Integer.TryParse(docIdStr, docId)
            Integer.TryParse(partyIdStr, partId)

            ' Defense culture : si l'URL contient une virgule (cas FR), la convertir
            ' en point pour eviter mauvaise interpretation comme separateur milliers.
            ' Ex : "493,24" -> "493.24" -> 493.24 (et non 49324)
            If Not String.IsNullOrEmpty(amountStr) Then
                amountStr = amountStr.Trim().Replace(" ", "").Replace(",", ".")
                Decimal.TryParse(amountStr, NumberStyles.Any, CultureInfo.InvariantCulture, amt)
            End If

            DocumentId = docId
            PartyId = partId
            Amount = amt

            LoadSupplierInfo()
            DisplayFeeEstimates()
        End If
    End Sub

    ''' <summary>
    ''' Charge les infos du fournisseur + facture pour affichage.
    ''' </summary>
    Private Sub LoadSupplierInfo()
        Try
            ' Recupere les infos depuis T050Party
            Dim p As New Collection
            p.Add(New SqlParameter("@PartyId", PartyId))
            Dim ds As DataSet = ExecuteSQLds("s0071GetPartyForPayment", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ShowError("Fournisseur introuvable.")
                Return
            End If

            Dim row As DataRow = ds.Tables(0).Rows(0)

            Dim supplierName As String = If(row("Name") Is DBNull.Value, "Fournisseur", row("Name").ToString())
            Dim lastMethod As String = If(row("LastPaymentMethod") Is DBNull.Value, "", row("LastPaymentMethod").ToString())
            Dim stripeAcct As String = If(row("StripeAccountId") Is DBNull.Value, "", row("StripeAccountId").ToString())

            StripeAccountId = stripeAcct

            ' Affichage
            litSupplierName.Text = Server.HtmlEncode(supplierName)
            litInvoiceNumber.Text = "Facture n° " & DocumentId.ToString()

            Dim culture As New CultureInfo("fr-CA")
            litAmount.Text = Amount.ToString("N2", culture) & " $ CAD"
            litAmountInvoice.Text = Amount.ToString("N2", culture) & " $"

            ' Injection JS pour le calcul gross-up cote client
            AmountForJs = Amount.ToString("F2", CultureInfo.InvariantCulture)
            LastUsedMethodForJs = If(String.IsNullOrEmpty(lastMethod), "interac_present", lastMethod)

            ' Badge "Derniere utilisee" sur la methode correspondante
            ' (l'ancien 'interac_present' est migrere vers 'card' visuellement)
            Select Case lastMethod
                Case "acss_debit"      : pnlBadgeAcss.Visible = True
                Case "card", "interac_present", "interac" : pnlBadgeCard.Visible = True
            End Select

            ' Pre-remplir hidden field (default = card si rien d'enregistre)
            Dim initialMethod As String = If(String.IsNullOrEmpty(lastMethod), "card", lastMethod)
            If initialMethod = "interac_present" OrElse initialMethod = "interac" Then
                initialMethod = "card"
            End If
            hfSelectedMethod.Value = initialMethod

            ' Avertir si le fournisseur n'a pas de StripeAccountId
            If String.IsNullOrEmpty(stripeAcct) Then
                pnlNoStripe.Visible = True
                btnPay.Enabled = False
                btnPay.Text = "Fournisseur non configuré"
                ' Lien direct vers la page de configuration du fournisseur
                lnkConfigure.NavigateUrl = "~/wbfSupplierStripeOnboarding.aspx?PartyId=" & PartyId.ToString()
                lnkConfigure.Target = "_blank"
            End If

            ' Section autorisation auto-paiement
            litAutoPaySupplierName.Text = Server.HtmlEncode(supplierName)
            LoadAutoPayState(supplierName)

        Catch ex As Exception
            ShowError("Erreur : " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Detecte si une autorisation T144 active existe pour ce couple
    ''' (Company, Party, User). Si oui, affiche un badge "deja configure"
    ''' et masque la proposition d'activation.
    ''' </summary>
    Private Sub LoadAutoPayState(supplierName As String)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@PartyId", PartyId))
            p.Add(New SqlParameter("@UserGUID", UserGUID))
            p.Add(New SqlParameter("@PaymentMethodType", DBNull.Value))

            Dim ds As DataSet = ExecuteSQLds("s0086GetActiveAuthorization", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ' Pas d'autorisation -> propose activation (par defaut)
                Return
            End If

            ' Au moins une autorisation active : affiche badge "deja configure"
            Dim row As DataRow = ds.Tables(0).Rows(0)
            Dim methodType As String = row("PaymentMethodType").ToString()
            Dim methodDesc As String = ""

            If methodType = "card" Then
                Dim brand As String = If(row("CardBrand") Is DBNull.Value, "Carte", row("CardBrand").ToString())
                Dim last4 As String = If(row("CardLast4") Is DBNull.Value, "????", row("CardLast4").ToString())
                methodDesc = brand & " se terminant par " & last4
            ElseIf methodType = "acss_debit" Then
                Dim last4 As String = If(row("BankAccountLast4") Is DBNull.Value, "????", row("BankAccountLast4").ToString())
                methodDesc = "ACSS Debit, compte se terminant par " & last4
            Else
                methodDesc = methodType
            End If

            litExistingMethod.Text = Server.HtmlEncode(methodDesc)
            pnlAutoPayPropose.Visible = False
            pnlAutoPayExisting.Visible = True

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("LoadAutoPayState error: " & ex.Message)
            ' Non-bloquant : la section autorisation reste visible mais l'erreur est loggee
        End Try
    End Sub

    ''' <summary>
    ''' Recupere l'UserGUID de l'utilisateur courant depuis Session ou BD.
    ''' Si non disponible en Session, fait un lookup T015User par UserId.
    ''' </summary>
    Private ReadOnly Property UserGUID As Guid
        Get
            ' Premier essai : ViewState (cache durant la vie de la page)
            If ViewState("UserGUID") IsNot Nothing Then
                Return CType(ViewState("UserGUID"), Guid)
            End If
            ' Deuxieme essai : Session (selon comment clsData expose)
            Try
                If Session("UserGUID") IsNot Nothing Then
                    Dim g As Guid = CType(Session("UserGUID"), Guid)
                    ViewState("UserGUID") = g
                    Return g
                End If
            Catch
            End Try
            ' Fallback : lookup T015User par UserId
            Try
                Dim cmd As New SqlCommand("SELECT UserGUID FROM T015User WHERE Id = @Id")
                cmd.Parameters.AddWithValue("@Id", UserId)
                Dim cs As String = ConfigurationManager.AppSettings("ConnectionString")
                Using conn As New SqlConnection(cs)
                    conn.Open()
                    cmd.Connection = conn
                    Dim res As Object = cmd.ExecuteScalar()
                    If res IsNot Nothing AndAlso Not IsDBNull(res) Then
                        Dim g As Guid = CType(res, Guid)
                        ViewState("UserGUID") = g
                        Return g
                    End If
                End Using
            Catch ex As Exception
                System.Diagnostics.Debug.WriteLine("UserGUID lookup error: " & ex.Message)
            End Try
            Return Guid.Empty
        End Get
    End Property

    ''' <summary>
    ''' Affiche les frais estimes pour chaque methode (gross-up).
    ''' </summary>
    Private Sub DisplayFeeEstimates()
        Dim culture As New CultureInfo("fr-CA")

        ' ACSS : 1% plafonne a 12$
        Dim feeAcss As Decimal = Math.Min(Amount * 0.01D, 12D)
        litFeeAcss.Text = "+ " & feeAcss.ToString("N2", culture) & " $"

        ' Carte (incluant Interac Debit) : gross-up (2.9% + 0.30$)
        ' Formule : brut = (net + 0.30) / (1 - 0.029)
        Dim grossCard As Decimal = (Amount + 0.3D) / 0.971D
        Dim feeCard As Decimal = Math.Round(grossCard - Amount, 2)
        litFeeCard.Text = "+ " & feeCard.ToString("N2", culture) & " $"
    End Sub

    ''' <summary>
    ''' Clic sur "Payer avec Stripe" : sauve la methode + cree Stripe Checkout Session.
    ''' Supporte les paiements PARTIELS : le user peut saisir un montant inferieur au ResteAPayer.
    ''' </summary>
    Protected Sub btnPay_Click(sender As Object, e As EventArgs) Handles btnPay.Click

        Dim selectedMethod As String = If(hfSelectedMethod.Value, "").Trim()

        ' Migration : l'ancien 'interac_present' est maintenant 'card' (Interac debit
        ' delivre via cartes Visa Debit / MC Debit dans Stripe Checkout moderne)
        If selectedMethod = "interac_present" OrElse selectedMethod = "interac" Then
            selectedMethod = "card"
        End If

        ' Validation methode (2 valides desormais : card + acss_debit)
        If selectedMethod <> "card" AndAlso selectedMethod <> "acss_debit" Then
            ShowError("Méthode de paiement invalide.")
            Return
        End If

        ' Validation montant (paiement partiel possible)
        Dim amountToPay As Decimal = 0D
        Dim amountStr As String = If(hfAmountToPay.Value, "").Trim()
        Decimal.TryParse(amountStr, NumberStyles.Any, CultureInfo.InvariantCulture, amountToPay)

        ' Fallback : si rien dans le hidden field, utiliser le ResteAPayer complet
        If amountToPay <= 0D Then
            amountToPay = Amount  ' la propriete Amount = ResteAPayer initial
        End If

        ' Bornes : min 0.01, max = ResteAPayer
        If amountToPay <= 0D Then
            ShowError("Le montant doit être supérieur à 0.")
            Return
        End If
        If amountToPay > Amount + 0.005D Then
            ShowError("Le montant ne peut dépasser le reste à payer (" & Amount.ToString("N2", New CultureInfo("fr-CA")) & " $).")
            Return
        End If

        If String.IsNullOrEmpty(StripeAccountId) Then
            ShowError("Le fournisseur n'a pas de compte Stripe Connect configuré.")
            Return
        End If

        Try
            ' 1. Sauvegarder la methode comme "derniere utilisee" pour ce fournisseur
            SaveLastPaymentMethod(PartyId, selectedMethod)

            ' 2. Calculer le montant brut (gross-up) selon la methode
            '    Le NET (ce que recoit Acme + ce qu'on inscrit en BD) = amountToPay
            Dim grossAmount As Decimal = CalculateGrossAmount(amountToPay, selectedMethod)

            ' 3. Creer la Stripe Checkout Session (Direct Charge vers le fournisseur)
            Dim baseUrl As String = Request.Url.GetLeftPart(UriPartial.Authority)
            Dim successUrl As String = baseUrl & ResolveUrl("~/wbfSupplierPaymentSuccess.aspx") &
                                        "?DocumentId=" & DocumentId.ToString()
            Dim cancelUrl As String = baseUrl & ResolveUrl("~/wbfSuppliersInvoices.aspx")

            ' OriginalAmount = ce qui doit être créditée à Acme (= amountToPay)
            ' Le webhook s'en sert pour créer T141ReglementDocument.MontantImpute
            Dim metadata As New Dictionary(Of String, String) From {
                {"MngConsul_DocumentId", DocumentId.ToString()},
                {"MngConsul_PartyId", PartyId.ToString()},
                {"MngConsul_UserId", UserId.ToString()},
                {"MngConsul_CompanyGUID", Company.ToString()},
                {"MngConsul_PaymentMethod", selectedMethod},
                {"MngConsul_OriginalAmount", amountToPay.ToString("F2", CultureInfo.InvariantCulture)},
                {"MngConsul_InvoiceTotal", Amount.ToString("F2", CultureInfo.InvariantCulture)}
            }

            ' === Autorisation auto-paiement (MIT) ===
            ' Si l'utilisateur a coche la case, on demande a Stripe de sauvegarder la
            ' PaymentMethod (setup_future_usage = off_session) et on passe les infos
            ' necessaires en metadata pour que le webhook cree T144Authorization.
            Dim authorizeAutoPay As Boolean = (String.Compare(If(hfAuthorizeAutoPay.Value, ""), "true", True) = 0)

            If authorizeAutoPay AndAlso Not pnlAutoPayExisting.Visible Then
                metadata.Add("MngConsul_AuthorizeAutoPay", "true")
                metadata.Add("MngConsul_UserGUID", UserGUID.ToString())
                metadata.Add("MngConsul_AuthorizedLanguage", "fr-CA")

                ' Plafond mensuel (optionnel)
                Dim maxMonthly As Decimal = 0D
                Dim maxMonthlyStr As String = If(hfMaxAmountPerMonth.Value, "").Trim()
                If Not String.IsNullOrEmpty(maxMonthlyStr) Then
                    Decimal.TryParse(maxMonthlyStr.Replace(",", "."), NumberStyles.Any, CultureInfo.InvariantCulture, maxMonthly)
                    If maxMonthly > 0D Then
                        metadata.Add("MngConsul_MaxAmountPerMonth", maxMonthly.ToString("F2", CultureInfo.InvariantCulture))
                    End If
                End If

                ' Audit trail : IP + User-Agent pour T144 (preuve de consentement)
                metadata.Add("MngConsul_AuthorizedIp", GetClientIpAddress())
                metadata.Add("MngConsul_AuthorizedUserAgent", TruncateUserAgent(Request.UserAgent, 400))

                ' Texte legal expose au consentement (pour audit + litige)
                metadata.Add("MngConsul_AuthorizationTextRef", "V1_" & selectedMethod & "_2026")
            Else
                authorizeAutoPay = False
            End If

            Dim checkoutUrl As String = clsStripe.CreateSupplierPaymentSession(
                stripeAccountId:=StripeAccountId,
                amountInCents:=CLng(Math.Round(grossAmount * 100)),
                currency:="cad",
                paymentMethodType:=selectedMethod,
                description:="Facture #" & DocumentId.ToString(),
                successUrl:=successUrl,
                cancelUrl:=cancelUrl,
                metadata:=metadata,
                authorizeAutoPay:=authorizeAutoPay
            )

            ' 4. Rediriger vers Stripe Checkout
            '
            ' IMPORTANT : cette page est ouverte dans une RadWindow (iframe).
            ' Stripe Checkout REFUSE de tourner dans un iframe (anti-clickjacking).
            ' On doit donc briser l'iframe avec JS : window.top.location.href = ...
            ' au lieu de Response.Redirect qui resterait dans l'iframe.
            Dim escapedUrl As String = checkoutUrl.Replace("\", "\\").Replace("'", "\'")
            Dim script As String =
                "(function(){" &
                "  var url = '" & escapedUrl & "';" &
                "  if (window.top && window.top !== window.self) {" &
                "    window.top.location.href = url;" &
                "  } else {" &
                "    window.location.href = url;" &
                "  }" &
                "})();"

            Page.ClientScript.RegisterStartupScript(Me.GetType(), "redirectToStripe", script, addScriptTags:=True)

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Supplier payment error: " & ex.Message)
            ShowError("Erreur lors de la création de la session de paiement : " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Sauvegarde la methode comme derniere utilisee pour ce fournisseur.
    ''' </summary>
    Private Sub SaveLastPaymentMethod(partId As Integer, method As String)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@PartyId", partId))
            p.Add(New SqlParameter("@LastPaymentMethod", method))
            ExecuteSQL("s0070UpdatePartyLastPaymentMethod", p)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("SaveLastPaymentMethod error: " & ex.Message)
            ' Non-bloquant : on continue avec le paiement
        End Try
    End Sub

    ''' <summary>
    ''' Calcule le montant brut (avec frais) selon la methode pour que le fournisseur
    ''' recoive exactement le montant facture (gross-up).
    ''' </summary>
    Private Function CalculateGrossAmount(netAmount As Decimal, method As String) As Decimal
        Select Case method
            Case "acss_debit"
                Dim fee As Decimal = Math.Min(netAmount * 0.01D, 12D)
                Return netAmount + fee
            Case Else
                ' 'card' (default) - couvre aussi les anciens 'interac_present' migres
                Return Math.Round((netAmount + 0.3D) / 0.971D, 2)
        End Select
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

    ''' <summary>
    ''' Recupere l'adresse IP du client en gerant les proxys/reverse-proxy
    ''' (X-Forwarded-For). Retourne max 45 caracteres pour la colonne VARCHAR(45).
    ''' </summary>
    Private Function GetClientIpAddress() As String
        Try
            Dim ip As String = ""
            ' Premier essai : header X-Forwarded-For (si derriere reverse-proxy)
            Dim xff As String = Request.Headers("X-Forwarded-For")
            If Not String.IsNullOrEmpty(xff) Then
                ' Format : "client, proxy1, proxy2..." -> garder le premier
                ip = xff.Split(","c)(0).Trim()
            End If
            ' Fallback : Request.UserHostAddress
            If String.IsNullOrEmpty(ip) Then
                ip = Request.UserHostAddress
            End If
            If String.IsNullOrEmpty(ip) Then Return ""
            If ip.Length > 45 Then ip = ip.Substring(0, 45)
            Return ip
        Catch
            Return ""
        End Try
    End Function

    ''' <summary>
    ''' Tronque le User-Agent a une longueur max (colonne VARCHAR(500)).
    ''' </summary>
    Private Function TruncateUserAgent(ua As String, maxLen As Integer) As String
        If String.IsNullOrEmpty(ua) Then Return ""
        If ua.Length > maxLen Then Return ua.Substring(0, maxLen)
        Return ua
    End Function

End Class
