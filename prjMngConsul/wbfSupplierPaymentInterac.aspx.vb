Imports System.Globalization

''' <summary>
''' Paiement d'une facture fournisseur par Interac e-Transfer via DreamPayments (rail ETRAN).
''' Ouvert en RadWindow depuis la grille des factures (DocumentId / PartyId / Amount).
'''
''' Orchestration (btnPay) : CreatePayee(courriel) -> CreatePayment -> AcceptPayment(Interac, SANS bankAccountId).
''' Contrairement à l'EFT : pas de compte bancaire ni de vérification — le transfert va au COURRIEL.
'''
''' ⚠️ Mêmes limites que la V1 EFT : payee recréé à chaque paiement (à persister plus tard),
'''    décaissement en base pas encore créé (TODO), code de méthode Interac à confirmer (ETRAN/JPM_ETRAN).
''' </summary>
Public Class wbfSupplierPaymentInterac
    Inherits clsData

    Private Property DocId As String
        Get
            Return CStr(If(ViewState("DocId"), ""))
        End Get
        Set(value As String)
            ViewState("DocId") = value
        End Set
    End Property

    Private Property PartyId As String
        Get
            Return CStr(If(ViewState("PartyId"), ""))
        End Get
        Set(value As String)
            ViewState("PartyId") = value
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

        btnPay.Text = L("pay")

        If Not IsPostBack Then
            DocId = Server.HtmlEncode(If(Request.QueryString("DocumentId"), ""))
            PartyId = Server.HtmlEncode(If(Request.QueryString("PartyId"), ""))

            Dim d As Decimal
            If Decimal.TryParse(If(Request.QueryString("Amount"), ""), NumberStyles.Any, CultureInfo.InvariantCulture, d) Then
                AmountValue = d
            End If

            litDoc.Text = DocId
            litAmount.Text = AmountValue.ToString("N2") & " $"

            Dim name As String = "", email As String = ""
            LoadSupplier(PartyId, name, email)
            litSupplier.Text = name
            txtEmail.Text = email

            If Not clsDreamPayments.IsConfigured() Then
                btnPay.Enabled = False
                ShowMsg(L("notConfigured"), False)
            End If
        End If
    End Sub

    ''' <summary>Nom + courriel du fournisseur (silencieux ; vides en cas d'échec).</summary>
    Private Sub LoadSupplier(pid As String, ByRef name As String, ByRef email As String)
        name = "" : email = ""
        Try
            Dim n As Integer
            If Not Integer.TryParse(pid, n) OrElse n <= 0 Then Return
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@PartyId", n))
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0037GetCustomerFullById", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim row As DataRow = ds.Tables(0).Rows(0)
                name = row("Name").ToString()
                If ds.Tables(0).Columns.Contains("Email") AndAlso Not IsDBNull(row("Email")) Then
                    email = row("Email").ToString()
                End If
            End If
        Catch
        End Try
    End Sub

    ' =====================================================================
    ' ORCHESTRATION INTERAC E-TRANSFER
    ' =====================================================================
    Private Sub btnPay_Click(sender As Object, e As EventArgs) Handles btnPay.Click
        If Not clsDreamPayments.IsConfigured() Then
            ShowMsg(L("notConfigured"), False)
            Return
        End If

        If String.IsNullOrWhiteSpace(txtLastName.Text) AndAlso String.IsNullOrWhiteSpace(txtFirstName.Text) Then
            ShowMsg(L("errName"), False) : Return
        End If
        If String.IsNullOrWhiteSpace(txtEmail.Text) OrElse Not txtEmail.Text.Contains("@") Then
            ShowMsg(L("errEmail"), False) : Return
        End If
        If String.IsNullOrWhiteSpace(txtAddress.Text) OrElse String.IsNullOrWhiteSpace(txtCity.Text) _
           OrElse String.IsNullOrWhiteSpace(txtProvince.Text) OrElse String.IsNullOrWhiteSpace(txtPostal.Text) Then
            ShowMsg(L("errAddress"), False) : Return
        End If
        If AmountValue <= 0D Then
            ShowMsg(L("errAmount"), False) : Return
        End If

        Try
            ' 1) Créer le bénéficiaire (avec courriel — cible de l'e-Transfer)
            Dim payee As clsDreamPayments.PayeeCreatedResult = clsDreamPayments.CreatePayee(
                New clsDreamPayments.PayeeInput With {
                    .AccountName = litSupplier.Text,
                    .FirstName = txtFirstName.Text.Trim(),
                    .LastName = txtLastName.Text.Trim(),
                    .Email = txtEmail.Text.Trim(),
                    .Address1 = txtAddress.Text.Trim(),
                    .City = txtCity.Text.Trim(),
                    .Province = txtProvince.Text.Trim().ToUpperInvariant(),
                    .PostalCode = txtPostal.Text.Trim(),
                    .PreferredLanguage = If(CurrentLang = "en", "en-CA", "fr-CA")
                })

            ' 2) Créer le paiement (⚠️ Value en cents — unité À CONFIRMER)
            Dim cents As Long = CLng(Math.Round(AmountValue * 100D))
            Dim interac As String = clsDreamPayments.InteracPaymentMethod()
            Dim paymentId As String = clsDreamPayments.CreatePayment(
                New clsDreamPayments.PaymentInput With {
                    .PayeeId = payee.PayeeId,
                    .PayeeUserId = payee.PayeeUserId,
                    .CurrencyCode = "CAD",
                    .Value = cents,
                    .PaymentType = "EXPENSE",
                    .Memo = "Facture fournisseur #" & DocId,
                    .ExternalReferenceData = DocId,
                    .NotifyEmail = txtEmail.Text.Trim(),
                    .AllowablePaymentMethods = New String() {interac}
                })

            ' 3) Accepter -> déclenche l'e-Transfer (méthode courriel, PAS de bankAccountId)
            clsDreamPayments.AcceptPayment(paymentId, Nothing, payee.PayeeUserId, interac)

            ' 4) TODO : créer le décaissement en base + marquer la facture payée, puis fermer.
            ShowMsg(String.Format(L("okPaid"), paymentId), True)

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
            Case "sub" : Return Choose3(lang, "Paiement du fournisseur par Interac e-Transfer", "Supplier payment by Interac e-Transfer", "Pago al proveedor por Interac e-Transfer")
            Case "supplier" : Return Choose3(lang, "Fournisseur", "Supplier", "Proveedor")
            Case "invoice" : Return Choose3(lang, "Facture", "Invoice", "Factura")
            Case "amount" : Return Choose3(lang, "Montant à payer", "Amount to pay", "Monto a pagar")
            Case "payeeSection" : Return Choose3(lang, "Bénéficiaire", "Payee", "Beneficiario")
            Case "firstName" : Return Choose3(lang, "Prénom", "First name", "Nombre")
            Case "lastName" : Return Choose3(lang, "Nom", "Last name", "Apellido")
            Case "email" : Return Choose3(lang, "Courriel du destinataire", "Recipient email", "Correo del destinatario")
            Case "address" : Return Choose3(lang, "Adresse", "Address", "Dirección")
            Case "city" : Return Choose3(lang, "Ville", "City", "Ciudad")
            Case "province" : Return Choose3(lang, "Province", "Province", "Provincia")
            Case "postal" : Return Choose3(lang, "Code postal", "Postal code", "Código postal")
            Case "interacNotice" : Return Choose3(lang, "Le fournisseur recevra un Interac e-Transfer à ce courriel (dépôt automatique ou question de sécurité gérés par le fournisseur/Dream).", "The supplier will receive an Interac e-Transfer at this email (autodeposit or security question handled by the supplier/Dream).", "El proveedor recibirá un Interac e-Transfer en este correo (autodepósito o pregunta de seguridad gestionados por el proveedor/Dream).")
            Case "close" : Return Choose3(lang, "Fermer", "Close", "Cerrar")
            Case "pay" : Return Choose3(lang, "Payer par Interac", "Pay by Interac", "Pagar por Interac")
            Case "notConfigured" : Return Choose3(lang, "DreamPaiement n'est pas configuré (Client ID / Secret manquants dans Web.config).", "DreamPayments is not configured (missing Client ID / Secret in Web.config).", "DreamPayments no está configurado (falta Client ID / Secret en Web.config).")
            Case "errName" : Return Choose3(lang, "Le nom du bénéficiaire est requis.", "The payee name is required.", "El nombre del beneficiario es obligatorio.")
            Case "errEmail" : Return Choose3(lang, "Un courriel valide est requis.", "A valid email is required.", "Se requiere un correo válido.")
            Case "errAddress" : Return Choose3(lang, "L'adresse complète du bénéficiaire est requise.", "The full payee address is required.", "La dirección completa del beneficiario es obligatoria.")
            Case "errAmount" : Return Choose3(lang, "Montant invalide.", "Invalid amount.", "Monto inválido.")
            Case "errApi" : Return Choose3(lang, "Erreur DreamPaiement :", "DreamPayments error:", "Error DreamPayments:")
            Case "okPaid" : Return Choose3(lang, "Interac e-Transfer initié avec succès. Paiement : {0}", "Interac e-Transfer initiated successfully. Payment: {0}", "Interac e-Transfer iniciado con éxito. Pago: {0}")
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
