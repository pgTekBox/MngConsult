Imports System.Globalization

''' <summary>
''' Paiement d'une facture fournisseur par EFT via DreamPayments (InsureTech API).
''' Ouvert en RadWindow depuis la grille des factures (DocumentId / PartyId / Amount).
'''
''' Orchestration (btnPay) : CreatePayee -> AddPayeeBankAccount -> CreatePayment -> AcceptPayment(EFT).
'''
''' ⚠️ Limites de cette V1 :
'''   - On crée un payee + un compte à CHAQUE paiement (pas de réutilisation) : à terme, persister
'''     payeeId / payeeUserId / bankAccountId sur le fournisseur (T050Party) pour les réutiliser.
'''   - La vérification du compte (micro-dépôt) est asynchrone : on demande autoVerify=True (OK en
'''     sandbox / comptes auto-vérifiés) ; en production le fournisseur devra vérifier avant l'accept.
'''   - Le décaissement en base n'est pas encore créé (TODO — voir en fin de PaySupplierByEft).
''' </summary>
Public Class wbfSupplierPaymentDream
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
            litSupplier.Text = LoadSupplierName(PartyId)
            txtAccountName.Text = litSupplier.Text

            ' Pré-remplissage : personne-contact + adresse depuis la fiche fournisseur.
            PrefillFromSupplier(PartyId)

            ' Garde-fou : credentials non configurés -> on désactive le paiement.
            If Not clsDreamPayments.IsConfigured() Then
                btnPay.Enabled = False
                ShowMsg(L("notConfigured"), False)
            End If
        End If
    End Sub

    ''' <summary>Nom du fournisseur (silencieux ; vide en cas d'échec).</summary>
    Private Function LoadSupplierName(pid As String) As String
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

    ''' <summary>
    ''' Pré-remplit la personne-contact (prénom/nom/courriel) et l'adresse de
    ''' l'entreprise depuis l'adresse de facturation du fournisseur (s0013).
    ''' L'utilisateur peut tout corriger avant de payer.
    ''' </summary>
    Private Sub PrefillFromSupplier(pid As String)
        Try
            Dim n As Integer
            If Not Integer.TryParse(pid, n) OrElse n <= 0 Then Return

            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@PartyId", n))
            Dim ds As DataSet = ExecuteSQLds("s0013GetPastyAddress", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

            ' Adresse de facturation (AddressTypeId = 1) si présente, sinon la première.
            Dim dt As DataTable = ds.Tables(0)
            Dim row As DataRow = Nothing
            For Each r As DataRow In dt.Rows
                If dt.Columns.Contains("AddressTypeId") AndAlso Not IsDBNull(r("AddressTypeId")) AndAlso CInt(r("AddressTypeId")) = 1 Then
                    row = r : Exit For
                End If
            Next
            If row Is Nothing Then row = dt.Rows(0)

            ' Personne-contact : « Attention » découpé en prénom / nom (heuristique).
            Dim contact As String = SafeStr(row, "Attention")
            If contact <> "" Then
                Dim sp As Integer = contact.IndexOf(" "c)
                If sp > 0 Then
                    txtFirstName.Text = contact.Substring(0, sp).Trim()
                    txtLastName.Text = contact.Substring(sp + 1).Trim()
                Else
                    txtFirstName.Text = contact
                End If
            End If

            SetIfEmpty(txtEmail, SafeStr(row, "Email"))

            ' Adresse de l'entreprise (province laissée vide : pas de code 2 lettres en BD).
            SetIfEmpty(txtAddress, SafeStr(row, "Address1"))
            SetIfEmpty(txtCity, SafeStr(row, "City"))
            SetIfEmpty(txtPostal, SafeStr(row, "PostalCode"))
        Catch
        End Try
    End Sub

    Private Shared Function SafeStr(r As DataRow, col As String) As String
        If r.Table.Columns.Contains(col) AndAlso Not IsDBNull(r(col)) Then Return r(col).ToString().Trim()
        Return ""
    End Function

    Private Shared Sub SetIfEmpty(tb As TextBox, val As String)
        If Not String.IsNullOrWhiteSpace(val) AndAlso String.IsNullOrWhiteSpace(tb.Text) Then tb.Text = val
    End Sub

    ' =====================================================================
    ' ORCHESTRATION EFT
    ' =====================================================================
    Private Sub btnPay_Click(sender As Object, e As EventArgs) Handles btnPay.Click
        If Not clsDreamPayments.IsConfigured() Then
            ShowMsg(L("notConfigured"), False)
            Return
        End If

        ' Validation minimale
        If String.IsNullOrWhiteSpace(txtLastName.Text) AndAlso String.IsNullOrWhiteSpace(txtFirstName.Text) Then
            ShowMsg(L("errName"), False) : Return
        End If
        If String.IsNullOrWhiteSpace(txtAddress.Text) OrElse String.IsNullOrWhiteSpace(txtCity.Text) _
           OrElse String.IsNullOrWhiteSpace(txtProvince.Text) OrElse String.IsNullOrWhiteSpace(txtPostal.Text) Then
            ShowMsg(L("errAddress"), False) : Return
        End If
        If String.IsNullOrWhiteSpace(txtInstitution.Text) OrElse String.IsNullOrWhiteSpace(txtTransit.Text) _
           OrElse String.IsNullOrWhiteSpace(txtAccountNumber.Text) Then
            ShowMsg(L("errBank"), False) : Return
        End If
        If AmountValue <= 0D Then
            ShowMsg(L("errAmount"), False) : Return
        End If

        Try
            ' 1) Créer le bénéficiaire (fournisseur)
            Dim payee As clsDreamPayments.PayeeCreatedResult = clsDreamPayments.CreatePayee(
                New clsDreamPayments.PayeeInput With {
                    .AccountName = If(String.IsNullOrWhiteSpace(txtAccountName.Text), litSupplier.Text, txtAccountName.Text.Trim()),
                    .FirstName = txtFirstName.Text.Trim(),
                    .LastName = txtLastName.Text.Trim(),
                    .Email = txtEmail.Text.Trim(),
                    .Address1 = txtAddress.Text.Trim(),
                    .City = txtCity.Text.Trim(),
                    .Province = txtProvince.Text.Trim().ToUpperInvariant(),
                    .PostalCode = txtPostal.Text.Trim(),
                    .PreferredLanguage = If(CurrentLang = "en", "en-CA", "fr-CA")
                })

            ' 2) Ajouter le compte bancaire EFT (autoVerify pour le sandbox)
            Dim bankAccountId As String = clsDreamPayments.AddPayeeBankAccount(
                payee.PayeeId, payee.PayeeUserId,
                New clsDreamPayments.BankAccountInput With {
                    .AccountName = txtAccountName.Text.Trim(),
                    .AccountNumber = txtAccountNumber.Text.Trim(),
                    .InstitutionNumber = txtInstitution.Text.Trim(),
                    .TransitNumber = txtTransit.Text.Trim(),
                    .BankAccountType = ddlAccountType.SelectedValue,
                    .CurrencyCode = "CAD",
                    .CountryCode = "CA"
                }, autoVerify:=True)

            ' 3) Créer le paiement (⚠️ Value en cents — unité À CONFIRMER)
            Dim cents As Long = CLng(Math.Round(AmountValue * 100D))
            Dim paymentId As String = clsDreamPayments.CreatePayment(
                New clsDreamPayments.PaymentInput With {
                    .PayeeId = payee.PayeeId,
                    .PayeeUserId = payee.PayeeUserId,
                    .CurrencyCode = "CAD",
                    .Value = cents,
                    .PaymentType = "EXPENSE",
                    .Memo = "Facture fournisseur #" & DocId,
                    .ExternalReferenceData = DocId,
                    .AllowablePaymentMethods = New String() {"EFT"}
                })

            ' 4) Accepter -> déclenche le virement EFT
            clsDreamPayments.AcceptPayment(paymentId, bankAccountId, payee.PayeeUserId, "EFT")

            ' 5) TODO : créer le décaissement en base et marquer la facture payée
            '    (proc à définir, cf. équivalent Stripe s0080CreateDecaissementFromStripe),
            '    puis fermer la fenêtre pour rafraîchir la grille.
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
            Case "sub" : Return Choose3(lang, "Paiement du fournisseur par virement bancaire", "Supplier payment by bank transfer", "Pago al proveedor por transferencia bancaria")
            Case "supplier" : Return Choose3(lang, "Fournisseur", "Supplier", "Proveedor")
            Case "invoice" : Return Choose3(lang, "Facture", "Invoice", "Factura")
            Case "amount" : Return Choose3(lang, "Montant à payer", "Amount to pay", "Monto a pagar")
            Case "companySection" : Return Choose3(lang, "Entreprise (bénéficiaire)", "Company (beneficiary)", "Empresa (beneficiario)")
            Case "companyHint" : Return Choose3(lang, "Le fournisseur qui reçoit le paiement : raison sociale et adresse.", "The supplier receiving the payment: legal name and address.", "El proveedor que recibe el pago: razón social y dirección.")
            Case "companyName" : Return Choose3(lang, "Nom de l'entreprise (raison sociale)", "Company name (legal name)", "Nombre de la empresa (razón social)")
            Case "contactSection" : Return Choose3(lang, "Personne-contact", "Contact person", "Persona de contacto")
            Case "contactHint" : Return Choose3(lang, "La personne de ce fournisseur qui gère le compte (vérification du compte bancaire, notifications).", "The person at this supplier who manages the account (bank account verification, notifications).", "La persona de este proveedor que gestiona la cuenta (verificación de la cuenta bancaria, notificaciones).")
            Case "payeeSection" : Return Choose3(lang, "Bénéficiaire", "Payee", "Beneficiario")
            Case "firstName" : Return Choose3(lang, "Prénom", "First name", "Nombre")
            Case "lastName" : Return Choose3(lang, "Nom", "Last name", "Apellido")
            Case "email" : Return Choose3(lang, "Courriel", "Email", "Correo")
            Case "address" : Return Choose3(lang, "Adresse", "Address", "Dirección")
            Case "city" : Return Choose3(lang, "Ville", "City", "Ciudad")
            Case "province" : Return Choose3(lang, "Province", "Province", "Provincia")
            Case "postal" : Return Choose3(lang, "Code postal", "Postal code", "Código postal")
            Case "bankSection" : Return Choose3(lang, "Compte bancaire (EFT)", "Bank account (EFT)", "Cuenta bancaria (EFT)")
            Case "accountName" : Return Choose3(lang, "Nom au compte", "Account name", "Nombre en la cuenta")
            Case "accountType" : Return Choose3(lang, "Type de compte", "Account type", "Tipo de cuenta")
            Case "institution" : Return Choose3(lang, "No institution (3)", "Institution no. (3)", "No. institución (3)")
            Case "transit" : Return Choose3(lang, "No transit / succursale (5)", "Transit / branch no. (5)", "No. tránsito / sucursal (5)")
            Case "accountNumber" : Return Choose3(lang, "No de compte", "Account number", "No. de cuenta")
            Case "verifyNotice" : Return Choose3(lang, "Le compte bancaire fait l'objet d'une vérification (dépôt-test). En production, le fournisseur doit confirmer avant le virement.", "The bank account is verified (test deposit). In production, the supplier must confirm before the transfer.", "La cuenta bancaria se verifica (depósito de prueba). En producción, el proveedor debe confirmar antes de la transferencia.")
            Case "close" : Return Choose3(lang, "Fermer", "Close", "Cerrar")
            Case "pay" : Return Choose3(lang, "Payer par EFT", "Pay by EFT", "Pagar por EFT")
            Case "notConfigured" : Return Choose3(lang, "DreamPaiement n'est pas configuré (Client ID / Secret manquants dans Web.config).", "DreamPayments is not configured (missing Client ID / Secret in Web.config).", "DreamPayments no está configurado (falta Client ID / Secret en Web.config).")
            Case "errName" : Return Choose3(lang, "Le nom du bénéficiaire est requis.", "The payee name is required.", "El nombre del beneficiario es obligatorio.")
            Case "errAddress" : Return Choose3(lang, "L'adresse complète du bénéficiaire est requise.", "The full payee address is required.", "La dirección completa del beneficiario es obligatoria.")
            Case "errBank" : Return Choose3(lang, "Institution, transit et numéro de compte sont requis.", "Institution, transit and account number are required.", "Institución, tránsito y número de cuenta son obligatorios.")
            Case "errAmount" : Return Choose3(lang, "Montant invalide.", "Invalid amount.", "Monto inválido.")
            Case "errApi" : Return Choose3(lang, "Erreur DreamPaiement :", "DreamPayments error:", "Error DreamPayments:")
            Case "okPaid" : Return Choose3(lang, "Virement EFT initié avec succès. Paiement : {0}", "EFT transfer initiated successfully. Payment: {0}", "Transferencia EFT iniciada con éxito. Pago: {0}")
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
