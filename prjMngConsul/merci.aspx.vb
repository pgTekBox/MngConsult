''' <summary>
''' Page publique de remerciement — cible de la redirection Square après un paiement réussi
''' (checkout_options.redirect_url du lien de paiement, cf. Web.config Square.PaymentRedirectUrl).
''' AUCUNE authentification : c'est le navigateur du client payeur qui atterrit ici.
''' Square ajoute des paramètres à l'URL (orderId / transactionId / referenceId) — affichés si présents.
''' Langue via ?lang=fr|en|es (défaut fr).
''' </summary>
Public Class merci
    Inherits System.Web.UI.Page

    ''' <summary>Langue d'affichage (query ?lang=), défaut « fr ».</summary>
    Protected ReadOnly Property Lang As String
        Get
            Dim l As String = LCase(Server.HtmlEncode(If(Request.QueryString("lang"), "")).Trim())
            If l = "en" OrElse l = "es" Then Return l
            Return "fr"
        End Get
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        ' Numéro de confirmation éventuel fourni par Square dans l'URL de retour.
        Dim ref As String = FirstNonEmpty(Request.QueryString("orderId"),
                                          Request.QueryString("transactionId"),
                                          Request.QueryString("referenceId"),
                                          Request.QueryString("checkoutId"))
        If Not String.IsNullOrEmpty(ref) Then
            litRef.Text = Server.HtmlEncode(ref)
            pnlRef.Visible = True
        End If

        ' Nom de la compagnie payée (paramètre « co » ajouté par nous à la redirect_url).
        ' Logo = monogramme (initiale du nom), même convention que le PDF de facture.
        Dim co As String = If(Request.QueryString("co"), "").Trim()
        If Not String.IsNullOrEmpty(co) Then
            litCompany.Text = Server.HtmlEncode(co)
            litInitial.Text = Server.HtmlEncode(GetInitial(co))
            pnlBrand.Visible = True

            ' Vrai logo si la compagnie en a un (handler public par GUID). Sinon l'image
            ' échoue (404) et onerror la retire → le monogramme (initiale) reste visible.
            Dim cg As String = If(Request.QueryString("c"), "").Trim()
            Dim g As Guid
            If Guid.TryParse(cg, g) Then
                litLogoImg.Text = "<img src=""CompanyLogo.ashx?c=" & HttpUtility.UrlEncode(g.ToString()) &
                                  """ alt="""" onerror=""this.parentNode.removeChild(this);"" />"
            End If
        End If

        ' Montant payé (paramètre « amt » en culture invariante, ex. 1234.56).
        Dim amtRaw As String = If(Request.QueryString("amt"), "").Trim()
        Dim amt As Decimal
        If Decimal.TryParse(amtRaw, Globalization.NumberStyles.Any,
                            Globalization.CultureInfo.InvariantCulture, amt) AndAlso amt > 0D Then
            litAmount.Text = Server.HtmlEncode(FormatMoney(amt))
            pnlAmount.Visible = True
        End If
    End Sub

    ''' <summary>Formate un montant CAD selon la langue (fr/es : « 1 234,56 $ » ; en : « $1,234.56 »).</summary>
    Private Function FormatMoney(amount As Decimal) As String
        If Lang = "en" Then
            Return "$" & amount.ToString("N2", Globalization.CultureInfo.GetCultureInfo("en-CA"))
        End If
        Return amount.ToString("N2", Globalization.CultureInfo.GetCultureInfo("fr-CA")) & " $"
    End Function

    ''' <summary>Initiale (1re lettre majuscule) du nom de compagnie, pour le monogramme-logo.</summary>
    Private Shared Function GetInitial(s As String) As String
        s = If(s, "").Trim()
        If s.Length = 0 Then Return ""
        Return s.Substring(0, 1).ToUpper()
    End Function

    Private Shared Function FirstNonEmpty(ParamArray vals As String()) As String
        For Each v As String In vals
            If Not String.IsNullOrEmpty(v) AndAlso v.Trim() <> "" Then Return v.Trim()
        Next
        Return ""
    End Function

    ''' <summary>Traductions (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Select Case key
            Case "title" : Return Choose3(Lang, "Merci pour votre paiement", "Thank you for your payment", "Gracias por su pago")
            Case "sub" : Return Choose3(Lang,
                "Votre paiement a été reçu avec succès. Un reçu vous a été envoyé par courriel.",
                "Your payment was received successfully. A receipt has been emailed to you.",
                "Su pago se recibió con éxito. Se le ha enviado un recibo por correo electrónico.")
            Case "paidTo" : Return Choose3(Lang, "Payé à", "Paid to", "Pagado a")
            Case "amountLbl" : Return Choose3(Lang, "Montant payé", "Amount paid", "Monto pagado")
            Case "refLabel" : Return Choose3(Lang, "Numéro de confirmation", "Confirmation number", "Número de confirmación")
            Case "foot" : Return Choose3(Lang,
                "Vous pouvez fermer cette fenêtre en toute sécurité.",
                "You may safely close this window.",
                "Puede cerrar esta ventana de forma segura.")
            Case Else : Return ""
        End Select
    End Function

    Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

End Class
