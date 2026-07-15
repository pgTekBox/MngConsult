Imports System.Globalization

''' <summary>
''' Encaissement d'une facture client par lien de paiement Square (page hébergée : carte / Interac débit).
''' Ouvert en RadWindow depuis la grille des factures client (DocumentId / PartyId / Amount).
'''
''' « Générer le lien » -> clsSquare.CreatePaymentLink (compte Square de l'abonné via OAuth) -> URL hébergée.
''' L'opérateur envoie l'URL au client ; le paiement revient par le webhook Square existant.
'''
''' ⚠️ TODO réconciliation : associer le paymentLink/orderId Square à notre DocumentId pour marquer
'''    NOTRE facture payée au retour du webhook (aujourd'hui s0671/s0672 traitent les factures nées côté Square).
''' </summary>
Public Class wbfCustomerPaymentLink
    Inherits clsData

    Private Property DocId As String
        Get
            Return CStr(If(ViewState("DocId"), ""))
        End Get
        Set(value As String)
            ViewState("DocId") = value
        End Set
    End Property

    Private Property AmountValue As Decimal
        Get
            Return CDec(If(ViewState("Amount"), 0D))
        End Get
        Set(value As Decimal)
            ViewState("Amount") = value
        End Set
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        btnGenerate.Text = L("generate")

        If Not IsPostBack Then
            DocId = Server.HtmlEncode(If(Request.QueryString("DocumentId"), ""))
            Dim pid As String = Server.HtmlEncode(If(Request.QueryString("PartyId"), ""))

            Dim d As Decimal
            If Decimal.TryParse(If(Request.QueryString("Amount"), ""), NumberStyles.Any, CultureInfo.InvariantCulture, d) Then
                AmountValue = d
            End If

            litDoc.Text = DocId
            litAmount.Text = AmountValue.ToString("N2") & " $"
            litCustomer.Text = LoadCustomerName(pid)

            ' Garde-fou : compte Square non connecté -> on désactive.
            If String.IsNullOrEmpty(SafeSquareToken()) Then
                btnGenerate.Enabled = False
                ShowMsg(L("notConnected"), False)
            End If
        End If
    End Sub

    Private Function LoadCustomerName(pid As String) As String
        Try
            Dim n As Integer
            If Not Integer.TryParse(pid, n) OrElse n <= 0 Then Return ""
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@PartyId", n))
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0037GetCustomerFullById", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return ds.Tables(0).Rows(0)("Name").ToString()
            End If
        Catch
        End Try
        Return ""
    End Function

    Private Function SafeSquareToken() As String
        Try
            Return GetValidSquareAccessToken()
        Catch
            Return ""
        End Try
    End Function

    ' =====================================================================
    ' GÉNÉRATION DU LIEN DE PAIEMENT SQUARE
    ' =====================================================================
    Private Sub btnGenerate_Click(sender As Object, e As EventArgs) Handles btnGenerate.Click
        If AmountValue <= 0D Then
            ShowMsg(L("errAmount"), False)
            Return
        End If

        Try
            Dim token As String = SafeSquareToken()
            If String.IsNullOrEmpty(token) Then
                ShowMsg(L("notConnected"), False)
                Return
            End If

            Dim locationId As String = clsSquare.GetMainLocationId(token)
            Dim cents As Long = CLng(Math.Round(AmountValue * 100D))
            Dim name As String = L("invoice") & " #" & DocId
            Dim note As String = "Facture client #" & DocId

            Dim link As clsSquare.SquarePaymentLinkResult = clsSquare.CreatePaymentLink(token, locationId, cents, name, note)

            If link Is Nothing OrElse String.IsNullOrEmpty(link.Url) Then
                ShowMsg(L("errApi") & " (URL vide)", False)
                Return
            End If

            ' Réconciliation : on estampille NOTRE facture avec le SquareOrderId du lien.
            ' Au paiement, le webhook payment.created -> s0672ApplySquarePayment retrouvera cette
            ' facture par SquareOrderId et la marquera payée (pas de facture synthétique / doublon).
            Dim n As Integer
            If Not String.IsNullOrEmpty(link.OrderId) AndAlso Integer.TryParse(DocId, n) Then
                Dim ps As New Collection
                ps.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
                ps.Add(New SqlClient.SqlParameter("@DocumentId", n))
                ps.Add(New SqlClient.SqlParameter("@SquareOrderId", link.OrderId))
                ExecuteSQL("s0688LinkDocumentToSquareOrder", ps)
            End If

            txtLink.Text = link.Url
            lnkOpen.NavigateUrl = link.Url
            pnlLink.Visible = True
            ShowMsg(L("generated"), True)

        Catch ex As Exception
            ShowMsg(L("errApi") & " " & ex.Message, False)
        End Try
    End Sub

    Private Sub ShowMsg(msg As String, success As Boolean)
        lblMsg.Visible = True
        lblMsg.CssClass = If(success, "msg msg-ok", "msg msg-err")
        lblMsg.Text = msg
    End Sub

    ''' <summary>Traductions (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "title" : Return Choose3(lang, "Encaisser (Square)", "Collect (Square)", "Cobrar (Square)")
            Case "sub" : Return Choose3(lang, "Lien de paiement — le client paie en ligne", "Payment link — the customer pays online", "Enlace de pago — el cliente paga en línea")
            Case "customer" : Return Choose3(lang, "Client", "Customer", "Cliente")
            Case "invoice" : Return Choose3(lang, "Facture", "Invoice", "Factura")
            Case "amount" : Return Choose3(lang, "Montant à encaisser", "Amount to collect", "Monto a cobrar")
            Case "linkLabel" : Return Choose3(lang, "Lien de paiement à envoyer au client", "Payment link to send to the customer", "Enlace de pago para enviar al cliente")
            Case "copy" : Return Choose3(lang, "Copier", "Copy", "Copiar")
            Case "open" : Return Choose3(lang, "Ouvrir", "Open", "Abrir")
            Case "payNotice" : Return Choose3(lang, "Le client peut payer par carte ou Interac sur la page hébergée par Square. Le paiement sera rapproché automatiquement.", "The customer can pay by card or Interac on Square's hosted page. The payment will be reconciled automatically.", "El cliente puede pagar con tarjeta o Interac en la página alojada por Square. El pago se conciliará automáticamente.")
            Case "close" : Return Choose3(lang, "Fermer", "Close", "Cerrar")
            Case "generate" : Return Choose3(lang, "Générer le lien", "Generate link", "Generar enlace")
            Case "generated" : Return Choose3(lang, "Lien de paiement généré.", "Payment link generated.", "Enlace de pago generado.")
            Case "notConnected" : Return Choose3(lang, "Aucun compte Square connecté pour cette entreprise.", "No Square account connected for this business.", "Ninguna cuenta Square conectada para esta empresa.")
            Case "errAmount" : Return Choose3(lang, "Montant invalide.", "Invalid amount.", "Monto inválido.")
            Case "errApi" : Return Choose3(lang, "Erreur Square :", "Square error:", "Error Square:")
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
