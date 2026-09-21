''' <summary>
''' The Dream Payments POC, built around the one thing MngConsul has to do:
''' a subscriber, working in the application, pays one of its suppliers by EFT.
'''
''' That is a single click on the website — "Pay by bank transfer" on a supplier
''' invoice — and behind it four chained calls. So the main tab here is that same
''' click: one button, one set of fields, the four calls in order, stopping at
''' the first one that fails.
'''
''' Two logs run side by side, the same events in both: the English one is what
''' gets sent to Dream, the French one is for whoever is running the tool. What
''' travels on the wire appears identically in both; only the narration differs.
'''
''' What goes out is what clsDreamPayments.vb sends, field for field. That is the
''' whole value of this tool: whatever happens here would happen on the website.
''' </summary>
Public Class FrmPoc
    Inherits Form

    Private ReadOnly _settings As Settings = Settings.Load()
    Private ReadOnly _conn As New ConnectionSettings()
    Private ReadOnly _client As DreamClient
    Private _busy As Boolean

    ' Header — the identifiers the flow produces as it goes
    Private ReadOnly lblStatus As New Label()
    Private ReadOnly txtPayeeId As New TextBox()
    Private ReadOnly txtPayeeUserId As New TextBox()
    Private ReadOnly txtBankAccountId As New TextBox()
    Private ReadOnly txtPaymentId As New TextBox()

    ' Connection
    Private ReadOnly cboEnv As New ComboBox()
    Private ReadOnly txtClientId As New TextBox()
    Private ReadOnly txtSecret As New TextBox()
    Private ReadOnly txtTokenUrl As New TextBox()
    Private ReadOnly txtApiBase As New TextBox()
    Private ReadOnly txtBasePath As New TextBox()
    Private ReadOnly txtPayerHeader As New TextBox()
    Private ReadOnly txtPayerValue As New TextBox()
    Private ReadOnly txtLegalLabel As New TextBox()
    Private ReadOnly txtLegalEntity As New TextBox()
    Private ReadOnly lstPayers As New ListView()
    Private ReadOnly lstPayees As New ListView()

    ' The use case — supplier, contact, bank account, invoice
    Private ReadOnly txtSupplierName As New TextBox()
    Private ReadOnly txtAddress As New TextBox()
    Private ReadOnly txtCity As New TextBox()
    Private ReadOnly txtProvince As New TextBox()
    Private ReadOnly txtPostalCode As New TextBox()
    Private ReadOnly txtFirstName As New TextBox()
    Private ReadOnly txtLastName As New TextBox()
    Private ReadOnly txtEmail As New TextBox()
    Private ReadOnly cboAccountType As New ComboBox()
    Private ReadOnly txtInstitution As New TextBox()
    Private ReadOnly txtTransit As New TextBox()
    Private ReadOnly txtAccountNumber As New TextBox()
    Private ReadOnly txtInvoiceNo As New TextBox()
    Private ReadOnly txtAmount As New TextBox()

    ' Options — what the website leaves alone
    Private ReadOnly txtPayeeType As New TextBox()
    Private ReadOnly txtLanguage As New TextBox()
    Private ReadOnly txtCustomerNumber As New TextBox()
    Private ReadOnly txtPhone As New TextBox()
    Private ReadOnly txtBankName As New TextBox()
    Private ReadOnly txtBankCurrency As New TextBox()
    Private ReadOnly txtAutoAccept As New TextBox()
    Private ReadOnly chkAutoVerify As New CheckBox()
    Private ReadOnly cboAmountFormat As New ComboBox()
    Private ReadOnly txtCurrency As New TextBox()
    Private ReadOnly txtPaymentType As New TextBox()
    Private ReadOnly txtMethods As New TextBox()
    Private ReadOnly chkSendPayoutDate As New CheckBox()
    Private ReadOnly dtpPayoutDate As New DateTimePicker()
    Private ReadOnly txtMemo As New TextBox()
    Private ReadOnly txtReference As New TextBox()
    Private ReadOnly txtDraftNumber As New TextBox()
    Private ReadOnly txtClaimNumber As New TextBox()
    Private ReadOnly txtPolicyNumber As New TextBox()
    Private ReadOnly txtPcoNumber As New TextBox()
    Private ReadOnly txtNotifyEmail As New TextBox()
    Private ReadOnly txtInteracMethod As New TextBox()

    ' Raw request
    Private ReadOnly cboMethod As New ComboBox()
    Private ReadOnly txtPath As New TextBox()
    Private ReadOnly txtBody As New TextBox()

    ' The two logs, side by side
    Private ReadOnly txtLogEn As New TextBox()
    Private ReadOnly txtLogFr As New TextBox()
    Private ReadOnly tabs As New TabControl()

    Public Sub New()
        _client = New DreamClient(_conn, AddressOf WriteLog)
        Build()
        LoadFields()
        UpdateStatus()
    End Sub

#Region "Building the screen"

    Private Sub Build()
        Text = "Dream Payments POC - pay a supplier by EFT - 60sec"
        StartPosition = FormStartPosition.CenterScreen
        ClientSize = New Size(1240, 950)
        MinimumSize = New Size(1040, 700)
        Font = New Font("Segoe UI", 9.0F)

        Dim root As New TableLayoutPanel With {.Dock = DockStyle.Fill, .ColumnCount = 1, .RowCount = 3}
        root.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100))
        root.RowStyles.Add(New RowStyle(SizeType.Absolute, 122))
        root.RowStyles.Add(New RowStyle(SizeType.Percent, 70))
        root.RowStyles.Add(New RowStyle(SizeType.Percent, 30))

        root.Controls.Add(Header(), 0, 0)
        root.Controls.Add(TabArea(), 0, 1)
        root.Controls.Add(LogArea(), 0, 2)
        Controls.Add(root)
    End Sub

    ''' <summary>
    ''' The identifiers the flow produces, visible at all times: each step fills
    ''' in the one the next step needs.
    ''' </summary>
    Private Function Header() As Control
        Dim box As New GroupBox With {.Text = "Current run", .Dock = DockStyle.Fill,
                                      .Padding = New Padding(8, 4, 8, 8)}
        Dim g As New Grid(110)
        g.Field("payeeId", txtPayeeId)
        g.Field("payeeUserId", txtPayeeUserId)
        g.Field("bankAccountId", txtBankAccountId)
        g.Field("paymentId", txtPaymentId)

        lblStatus.Dock = DockStyle.Fill
        lblStatus.TextAlign = ContentAlignment.MiddleLeft
        g.FullWidth(lblStatus, 26)

        g.Finish(False)
        box.Controls.Add(g.Panel)
        Return box
    End Function

    Private Function TabArea() As Control
        tabs.Dock = DockStyle.Fill
        tabs.TabPages.Add(MakeTab("1. Pay a supplier (EFT)", PaymentFlowTab()))
        tabs.TabPages.Add(MakeTab("2. Connection", ConnectionTab()))
        tabs.TabPages.Add(MakeTab("3. Options", OptionsTab()))
        tabs.TabPages.Add(MakeTab("4. Other calls", OtherCallsTab()))
        tabs.TabPages.Add(MakeTab("5. Raw request", RawTab()))
        Return tabs
    End Function

    Private Shared Function MakeTab(title As String, content As Control) As TabPage
        Dim p As New TabPage(title) With {.BackColor = SystemColors.Window, .Padding = New Padding(6)}
        p.Controls.Add(content)
        Return p
    End Function

    ''' <summary>
    ''' The use case itself. Same fields as the website's
    ''' wbfSupplierPaymentDream.aspx, in the same three sections, because the
    ''' person filling this in is a subscriber paying a supplier invoice.
    ''' </summary>
    Private Function PaymentFlowTab() As Control
        Dim g As New Grid()
        g.Note("A subscriber pays one of its suppliers by EFT. On the website this is one click on a supplier invoice; here it is one button, running the same four calls in order: create the payee, attach its bank account, create the payment, accept it. It stops at the first call that fails.")

        g.Section("Supplier (the beneficiary)")
        g.FullWidth("Legal name", txtSupplierName)
        g.FullWidth("Address", txtAddress)
        g.Field("City", txtCity)
        g.Field("Province", txtProvince)
        g.Field("Postal code", txtPostalCode)

        g.Section("Contact person at the supplier")
        g.Field("First name", txtFirstName)
        g.Field("Last name", txtLastName)
        g.FullWidth("Email", txtEmail)

        g.Section("Bank account to credit")
        cboAccountType.DropDownStyle = ComboBoxStyle.DropDownList
        cboAccountType.Items.AddRange(New Object() {"CHEQUING", "SAVINGS"})
        g.Field("Account type", cboAccountType)
        g.Field("Institution (3 digits)", txtInstitution)
        g.Field("Transit (5 digits)", txtTransit)
        g.Field("Account number", txtAccountNumber)

        g.Section("Invoice being paid")
        g.Field("Invoice number", txtInvoiceNo)
        g.Field("Amount (dollars)", txtAmount)

        Dim pay = MakeButton("Pay the supplier by EFT", AddressOf PaySupplier)
        pay.Font = New Font("Segoe UI", 9.5F, FontStyle.Bold)
        pay.Height = 34
        g.Buttons(pay)

        g.Section("Or the same four calls one at a time, from the same fields")
        g.Buttons(MakeButton("1. Create payee", AddressOf CreatePayee),
                  MakeButton("2. Add bank account", AddressOf AddBankAccount),
                  MakeButton("3. Create payment", AddressOf CreatePayment),
                  MakeButton("4. Accept by EFT", AddressOf AcceptEft),
                  MakeButton("Clear the run", Sub() ClearRun()))
        g.Finish()
        Return g.Panel
    End Function

    Private Function ConnectionTab() As Control
        Dim g As New Grid()
        g.Note("The client ID and secret come from Dream. The secret is stored encrypted for your Windows account (DPAPI); it never appears in the log.")

        cboEnv.DropDownStyle = ComboBoxStyle.DropDownList
        cboEnv.Items.AddRange(New Object() {"sandbox", "production"})
        AddHandler cboEnv.SelectedIndexChanged, AddressOf OnEnvironmentChanged
        g.Field("Environment", cboEnv)
        g.Field("Client ID", txtClientId)

        txtSecret.UseSystemPasswordChar = True
        g.Field("Client secret", txtSecret)
        g.Field("Base path", txtBasePath)

        g.FullWidth("Token URL", txtTokenUrl)
        g.FullWidth("API base", txtApiBase)

        g.Section("Payer - which subscriber is sending the money")
        g.Note("The ""G00021 Multiple payers exist"" error comes from the credentials carrying several payers. As soon as Dream says how to designate the one paying, it is set right here - through a header on every call, or through legalEntity in the payment body. Both exist in the website's Web.config too, so whatever works here is a config change there, not a code change.")
        g.Field("Payer header", txtPayerHeader)
        g.Field("Header value", txtPayerValue)
        g.Field("legalEntityLabel", txtLegalLabel)
        g.Field("legalEntity", txtLegalEntity)

        ' The payers, on screen rather than buried in the log: pick a row and it
        ' goes into legalEntity above.
        lstPayers.View = View.Details
        lstPayers.FullRowSelect = True
        lstPayers.HideSelection = False
        lstPayers.MultiSelect = False
        lstPayers.Columns.Add("legalEntity", 170)
        lstPayers.Columns.Add("Business name", 200)
        lstPayers.Columns.Add("Payments", 90, HorizontalAlignment.Right)
        AddHandler lstPayers.SelectedIndexChanged, Sub() PickPayer()
        g.FullWidth(lstPayers, 132)
        g.Note("Dream names no payer in its error. There is no endpoint that lists them either - but every payment carries its payer in legalEntity, so listing the payments answers the question. Click a row to use that payer.")
        g.Buttons(MakeButton("List the payers", AddressOf ListPayers))

        g.Buttons(MakeButton("Get a token", AddressOf GetToken),
                  MakeButton("Forget the token", Sub() ForgetToken()),
                  MakeButton("Save settings", Sub() SaveSettings()))
        g.Finish()
        Return g.Panel
    End Function

    ''' <summary>
    ''' Everything the website leaves at its default. Changing anything here
    ''' means the POC no longer mirrors the website exactly - fine while hunting,
    ''' as long as it is deliberate, hence the button to put it all back.
    ''' </summary>
    Private Function OptionsTab() As Control
        Dim g As New Grid()

        g.Section("Payee")
        g.Field("payeeType", txtPayeeType)
        g.Field("preferredLanguage", txtLanguage)
        g.Field("customerNumber", txtCustomerNumber)
        g.Field("Phone", txtPhone)

        g.Section("Bank account")
        g.Field("bankName", txtBankName)
        g.Field("currencyCode", txtBankCurrency)
        g.Field("autoAcceptPaymentMethod", txtAutoAccept)
        chkAutoVerify.Text = "autoVerify (the website sends True)"
        g.FullWidth(chkAutoVerify, 24)

        g.Section("Payment")
        ' The unit of amount.value is still unconfirmed by Dream; the website
        ' sends cents. This switch is here to settle the question for good.
        cboAmountFormat.DropDownStyle = ComboBoxStyle.DropDownList
        cboAmountFormat.Items.AddRange(New Object() {"cents, number (as the website)", "dollars, string"})
        g.Field("amount.value sent as", cboAmountFormat)
        g.Field("currencyCode", txtCurrency)
        g.Field("paymentType", txtPaymentType)
        g.Field("allowablePaymentMethods", txtMethods)
        g.FullWidth("memo (blank = as the website)", txtMemo)
        g.Field("externalReferenceData", txtReference)
        g.Field("notifyEmail", txtNotifyEmail)
        g.Field("draftNumber", txtDraftNumber)
        g.Field("claimNumber", txtClaimNumber)
        g.Field("policyNumber", txtPolicyNumber)
        g.Field("pcoNumber", txtPcoNumber)
        g.Field("Interac method", txtInteracMethod)

        chkSendPayoutDate.Text = "Send payoutDate (the website does not)"
        dtpPayoutDate.Format = DateTimePickerFormat.Short
        g.Field("", chkSendPayoutDate)
        g.Field("payoutDate", dtpPayoutDate)

        g.Buttons(MakeButton("Restore the website's values", Sub() RestoreWebsiteDefaults()))
        g.Finish()
        Return g.Panel
    End Function

    ''' <summary>The calls the EFT flow does not use, kept for digging.</summary>
    Private Function OtherCallsTab() As Control
        Dim g As New Grid()
        g.Note("Calls outside the EFT flow. They act on the identifiers shown at the top of the window.")

        g.Section("Find an existing payee")
        g.Note("/payees/add is blocked, but payees already exist - and a payee can be recovered: each payment names its own, and the payee record carries its primary user. That gives a payeeId and a payeeUserId without creating anything, so steps 2 to 4 can be tried. Click a row to use it.")
        lstPayees.View = View.Details
        lstPayees.FullRowSelect = True
        lstPayees.HideSelection = False
        lstPayees.MultiSelect = False
        lstPayees.Columns.Add("payeeId", 250)
        lstPayees.Columns.Add("Name", 190)
        lstPayees.Columns.Add("payeeUserId", 250)
        lstPayees.Columns.Add("Accounts", 80, HorizontalAlignment.Right)
        AddHandler lstPayees.SelectedIndexChanged, Sub() PickPayee()
        g.FullWidth(lstPayees, 132)
        g.Buttons(MakeButton("Find the payees of this payer", AddressOf FindPayees))

        g.Section("Raw listings")
        g.Note("The searches behind the payer list, with their answers in full. The payer list itself is on the Connection tab.")
        g.Buttons(MakeButton("List the payments", AddressOf ListPayments),
                  MakeButton("List the payee users", AddressOf ListPayeeUsers))

        g.Section("Payee and bank account")
        g.Buttons(MakeButton("Get payee", AddressOf GetPayee),
                  MakeButton("List accounts", AddressOf ListAccounts),
                  MakeButton("Verify account", AddressOf VerifyAccount),
                  MakeButton("Account acceptance", AddressOf AcceptAccount))

        g.Section("Payment")
        g.Note("Interac is the other rail: the money goes to the contact's email address and no bank account is involved. The website has a separate page for it.")
        g.Buttons(MakeButton("Accept by Interac", AddressOf AcceptInterac),
                  MakeButton("Get payment", AddressOf GetPayment),
                  MakeButton("Cancel payment", AddressOf CancelPayment))
        g.Finish()
        Return g.Panel
    End Function

    Private Function RawTab() As Control
        Dim g As New Grid()
        g.Note("For trying a path this POC does not cover. The path is relative to the API base; the token is added automatically.")
        cboMethod.DropDownStyle = ComboBoxStyle.DropDownList
        cboMethod.Items.AddRange(New Object() {"GET", "POST", "PUT", "DELETE"})
        cboMethod.SelectedIndex = 0
        g.Field("Method", cboMethod)
        g.Field("Path", txtPath)

        txtBody.Multiline = True
        txtBody.ScrollBars = ScrollBars.Vertical
        txtBody.Font = New Font("Consolas", 9.0F)
        g.FullWidth("JSON body", txtBody, 150)

        g.Buttons(MakeButton("Send", AddressOf SendRaw))
        g.Finish()
        Return g.Panel
    End Function

    ''' <summary>
    ''' The two logs, side by side. Same events, same wire content; the English
    ''' one is the one to send Dream, the French one is for reading along.
    ''' </summary>
    Private Function LogArea() As Control
        Dim row As New TableLayoutPanel With {.Dock = DockStyle.Fill, .ColumnCount = 2, .RowCount = 1}
        row.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 50))
        row.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 50))
        row.RowStyles.Add(New RowStyle(SizeType.Percent, 100))

        row.Controls.Add(LogBox("Log (English) - the one to send Dream", txtLogEn,
                                "dream-log-en-", "Clear", "Copy", "Save..."), 0, 0)
        row.Controls.Add(LogBox("Journal (français)", txtLogFr,
                                "journal-dream-fr-", "Effacer", "Copier", "Enregistrer..."), 1, 0)
        Return row
    End Function

    Private Function LogBox(caption As String, box As TextBox, filePrefix As String,
                            clearText As String, copyText As String, saveText As String) As Control
        Dim group As New GroupBox With {.Text = caption, .Dock = DockStyle.Fill, .Padding = New Padding(8, 4, 8, 8)}
        Dim t As New TableLayoutPanel With {.Dock = DockStyle.Fill, .ColumnCount = 1, .RowCount = 2}
        t.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100))
        t.RowStyles.Add(New RowStyle(SizeType.Percent, 100))
        t.RowStyles.Add(New RowStyle(SizeType.AutoSize))

        box.Multiline = True
        box.ReadOnly = True
        box.Dock = DockStyle.Fill
        box.ScrollBars = ScrollBars.Both
        box.WordWrap = False
        box.Font = New Font("Consolas", 9.0F)
        box.BackColor = Color.FromArgb(250, 250, 252)
        t.Controls.Add(box, 0, 0)

        Dim bar As New FlowLayoutPanel With {.Dock = DockStyle.Fill, .AutoSize = True,
                                             .FlowDirection = FlowDirection.LeftToRight}
        bar.Controls.Add(MakeButton(clearText, Sub() box.Clear()))
        bar.Controls.Add(MakeButton(copyText, Sub() CopyLog(box)))
        bar.Controls.Add(MakeButton(saveText, Sub() SaveLog(box, filePrefix)))
        t.Controls.Add(bar, 0, 1)

        group.Controls.Add(t)
        Return group
    End Function

    Private Shared Function MakeButton(caption As String, action As Action) As Button
        Dim b As New Button With {.Text = caption, .AutoSize = True, .Height = 28, .Margin = New Padding(0, 0, 8, 0),
                                  .Padding = New Padding(10, 2, 10, 2)}
        AddHandler b.Click, Sub() action()
        Return b
    End Function

#End Region

#Region "Settings and defaults"

    Private Sub LoadFields()
        cboEnv.SelectedItem = If(_settings.EnvironmentName = "production", "production", "sandbox")

        ' Whatever was saved wins; failing that, the sandbox credentials, so the
        ' screen is usable from the very first run.
        Dim secret = Settings.Unprotect(_settings.ClientSecretProtected)
        txtClientId.Text = If(_settings.ClientId = "", Settings.SandboxClientId, _settings.ClientId)
        txtSecret.Text = If(secret = "", Settings.SandboxClientSecret, secret)

        txtTokenUrl.Text = _settings.TokenUrl
        txtApiBase.Text = _settings.ApiBase
        txtBasePath.Text = _settings.BasePath
        txtPayerHeader.Text = _settings.PayerHeaderName
        txtPayerValue.Text = _settings.PayerHeaderValue
        txtLegalLabel.Text = _settings.LegalEntityLabel
        txtLegalEntity.Text = _settings.LegalEntity

        txtPayeeId.Text = _settings.PayeeId
        txtPayeeUserId.Text = _settings.PayeeUserId
        txtBankAccountId.Text = _settings.BankAccountId
        txtPaymentId.Text = _settings.PaymentId

        ' A supplier invoice that could plausibly be sitting in the application.
        txtSupplierName.Text = "Fournitures Boreal inc."
        txtAddress.Text = "100 rue Principale"
        txtCity.Text = "Montreal"
        txtProvince.Text = "QC"
        txtPostalCode.Text = "H2X1Y4"
        txtFirstName.Text = "Jean"
        txtLastName.Text = "Tremblay"
        txtEmail.Text = "comptes@exemple.ca"
        ' A branch Dream actually knows. Invented numbers are refused: BK0037
        ' "bank branch is not found", or BK0036 when the institution is wrong.
        txtInstitution.Text = "004"
        txtTransit.Text = "44581"
        txtAccountNumber.Text = "1234567"
        txtInvoiceNo.Text = "12345"
        txtAmount.Text = "10.00"

        RestoreWebsiteDefaults()
        txtPath.Text = "/payees/" & If(_settings.PayeeId = "", "{payeeId}", _settings.PayeeId)
    End Sub

    ''' <summary>
    ''' Puts every option back to what the website actually sends. Also the
    ''' starting point, so a fresh run mirrors production without thinking.
    ''' </summary>
    Private Sub RestoreWebsiteDefaults()
        cboAccountType.SelectedItem = "CHEQUING"
        txtPayeeType.Text = _settings.PayeeType
        txtLanguage.Text = "fr-CA"
        txtCustomerNumber.Text = ""
        txtPhone.Text = ""

        txtBankName.Text = ""
        txtBankCurrency.Text = "CAD"
        txtAutoAccept.Text = ""
        chkAutoVerify.Checked = True

        cboAmountFormat.SelectedIndex = 0
        txtCurrency.Text = "CAD"
        txtPaymentType.Text = "EXPENSE"
        txtMethods.Text = "EFT"
        txtMemo.Text = ""
        txtReference.Text = ""
        txtNotifyEmail.Text = ""
        txtDraftNumber.Text = ""
        txtClaimNumber.Text = ""
        txtPolicyNumber.Text = ""
        txtPcoNumber.Text = ""
        txtInteracMethod.Text = _settings.InteracMethod
        chkSendPayoutDate.Checked = False
        dtpPayoutDate.Value = Date.Today
    End Sub

    Private Sub OnEnvironmentChanged(sender As Object, e As EventArgs)
        ' The known sandbox URLs. Production is still to be confirmed by Dream,
        ' so it is not guessed: the field is left as it is.
        If CStr(cboEnv.SelectedItem) = "sandbox" Then
            txtApiBase.Text = "https://fapi-test-insuretechv2.npe.dreampayments.com/v1"
            txtTokenUrl.Text = "https://partner-userpool-test-insuretech.auth.us-east-1.amazoncognito.com/oauth2/token"
        End If
    End Sub

    ''' <summary>Picks up in the connection settings what the screen shows.</summary>
    Private Sub ReadSettings()
        Dim before = _conn.ClientId & "|" & _conn.ClientSecret & "|" & _conn.TokenUrl

        _conn.ClientId = txtClientId.Text.Trim()
        _conn.ClientSecret = txtSecret.Text.Trim()
        _conn.TokenUrl = txtTokenUrl.Text.Trim()
        _conn.ApiBase = txtApiBase.Text.Trim()
        _conn.BasePath = txtBasePath.Text.Trim()
        _conn.PayerHeaderName = txtPayerHeader.Text.Trim()
        _conn.PayerHeaderValue = txtPayerValue.Text.Trim()

        ' Changing credentials makes the token in hand meaningless.
        If before <> _conn.ClientId & "|" & _conn.ClientSecret & "|" & _conn.TokenUrl Then _client.ForgetToken()
    End Sub

    Private Sub SaveSettings()
        _settings.EnvironmentName = CStr(cboEnv.SelectedItem)
        _settings.ClientId = txtClientId.Text.Trim()
        _settings.ClientSecretProtected = Settings.Protect(txtSecret.Text.Trim())
        _settings.TokenUrl = txtTokenUrl.Text.Trim()
        _settings.ApiBase = txtApiBase.Text.Trim()
        _settings.BasePath = txtBasePath.Text.Trim()
        _settings.PayerHeaderName = txtPayerHeader.Text.Trim()
        _settings.PayerHeaderValue = txtPayerValue.Text.Trim()
        _settings.LegalEntityLabel = txtLegalLabel.Text.Trim()
        _settings.LegalEntity = txtLegalEntity.Text.Trim()
        _settings.PayeeType = txtPayeeType.Text.Trim()
        _settings.InteracMethod = txtInteracMethod.Text.Trim()
        _settings.PayeeId = txtPayeeId.Text.Trim()
        _settings.PayeeUserId = txtPayeeUserId.Text.Trim()
        _settings.BankAccountId = txtBankAccountId.Text.Trim()
        _settings.PaymentId = txtPaymentId.Text.Trim()
        Try
            _settings.Save()
            WriteLog("Settings saved.", "Réglages enregistrés.")
        Catch ex As Exception
            WriteLog("[x] Could not save the settings: " & ex.Message,
                     "[x] Enregistrement impossible : " & ex.Message)
        End Try
    End Sub

    Private Sub ForgetToken()
        _client.ForgetToken()
        UpdateStatus()
        WriteLog("Token forgotten: the next call will request a new one.",
                 "Jeton oublié : le prochain appel en redemandera un.")
    End Sub

    ''' <summary>Empties the identifiers, so the next run starts from scratch.</summary>
    Private Sub ClearRun()
        txtPayeeId.Clear()
        txtPayeeUserId.Clear()
        txtBankAccountId.Clear()
        txtPaymentId.Clear()
        WriteLog("Run cleared: the next payment will create a new payee.",
                 "Parcours réinitialisé : le prochain paiement créera un nouveau bénéficiaire.")
    End Sub

    Protected Overrides Sub OnFormClosing(e As FormClosingEventArgs)
        SaveSettings()
        MyBase.OnFormClosing(e)
    End Sub

#End Region

#Region "Reading the screen into the payloads"

    Private Function ReadPayee() As PayeeInput
        Return New PayeeInput With {
            .AccountName = txtSupplierName.Text.Trim(),
            .CustomerNumber = txtCustomerNumber.Text.Trim(),
            .PayeeType = txtPayeeType.Text.Trim(),
            .FirstName = txtFirstName.Text.Trim(),
            .LastName = txtLastName.Text.Trim(),
            .Email = txtEmail.Text.Trim(),
            .Phone = txtPhone.Text.Trim(),
            .Language = txtLanguage.Text.Trim(),
            .Address = txtAddress.Text.Trim(),
            .City = txtCity.Text.Trim(),
            .Province = txtProvince.Text.Trim().ToUpperInvariant(),
            .PostalCode = txtPostalCode.Text.Trim()}
    End Function

    ''' <summary>
    ''' Note the account name: the website reuses the supplier's legal name for
    ''' the bank account too. Same field here, for the same reason.
    ''' </summary>
    Private Function ReadBankAccount() As BankAccountInput
        Return New BankAccountInput With {
            .PayeeUserId = txtPayeeUserId.Text.Trim(),
            .AccountName = txtSupplierName.Text.Trim(),
            .InstitutionNumber = txtInstitution.Text.Trim(),
            .TransitNumber = txtTransit.Text.Trim(),
            .AccountNumber = txtAccountNumber.Text.Trim(),
            .AccountType = CStr(cboAccountType.SelectedItem),
            .CurrencyCode = txtBankCurrency.Text.Trim(),
            .BankName = txtBankName.Text.Trim(),
            .AutoAcceptPaymentMethod = txtAutoAccept.Text.Trim(),
            .AutoVerify = chkAutoVerify.Checked}
    End Function

    Private Function ReadPayment(amount As Decimal) As PaymentInput
        Dim invoice = txtInvoiceNo.Text.Trim()

        ' Left blank, memo and reference are built from the invoice number the
        ' way the website builds them.
        Dim memo = txtMemo.Text.Trim()
        If memo = "" Then memo = "Facture fournisseur #" & invoice
        Dim reference = txtReference.Text.Trim()
        If reference = "" Then reference = invoice

        Return New PaymentInput With {
            .PayeeId = txtPayeeId.Text.Trim(),
            .PayeeUserId = txtPayeeUserId.Text.Trim(),
            .Amount = amount,
            .AmountInCents = (cboAmountFormat.SelectedIndex = 0),
            .CurrencyCode = txtCurrency.Text.Trim(),
            .Memo = memo,
            .PaymentType = txtPaymentType.Text.Trim(),
            .SendPayoutDate = chkSendPayoutDate.Checked,
            .PayoutDate = dtpPayoutDate.Value.Date,
            .ExternalReference = reference,
            .DraftNumber = txtDraftNumber.Text.Trim(),
            .ClaimNumber = txtClaimNumber.Text.Trim(),
            .PolicyNumber = txtPolicyNumber.Text.Trim(),
            .PcoNumber = txtPcoNumber.Text.Trim(),
            .LegalEntity = txtLegalEntity.Text.Trim(),
            .LegalEntityLabel = txtLegalLabel.Text.Trim(),
            .NotifyEmail = txtNotifyEmail.Text.Trim(),
            .AllowedMethods = txtMethods.Text.Trim()}
    End Function

    ''' <summary>
    ''' The same checks the website runs before it calls anything: bank details
    ''' complete, amount positive.
    ''' </summary>
    Private Function ReadAmount(ByRef amount As Decimal) As Boolean
        If txtInstitution.Text.Trim() = "" OrElse txtTransit.Text.Trim() = "" _
           OrElse txtAccountNumber.Text.Trim() = "" Then
            WriteLog("[x] Institution, transit and account number are all required.",
                     "[x] Institution, transit et numéro de compte sont tous obligatoires.")
            Return False
        End If
        If Not Decimal.TryParse(txtAmount.Text.Replace(","c, "."c), Globalization.NumberStyles.Any,
                                Globalization.CultureInfo.InvariantCulture, amount) OrElse amount <= 0D Then
            WriteLog("[x] The amount must be a positive number.",
                     "[x] Le montant doit être un nombre positif.")
            Return False
        End If
        Return True
    End Function

#End Region

#Region "The use case"

    ''' <summary>
    ''' The whole thing, in one go — what one click on the website does.
    ''' Four calls, in order, stopping at the first failure, with the reason.
    ''' </summary>
    Private Sub PaySupplier()
        Dim amount As Decimal
        If Not ReadAmount(amount) Then Return

        Dim supplier = txtSupplierName.Text.Trim()
        Dim shown = amount.ToString("0.00", Globalization.CultureInfo.InvariantCulture) & " " & txtCurrency.Text.Trim()

        RunStep("Pay " & supplier & " " & shown & " by EFT",
                "Payer " & supplier & " " & shown & " par EFT",
            Async Function(ct)
                WriteLog("", "")
                WriteLog("Step 1 of 4 - create the payee", "Étape 1 sur 4 — créer le bénéficiaire")
                Dim payee = Await _client.PostAsync("/payees/add", Payloads.PayeeBody(ReadPayee()), ct)
                Keep(txtPayeeId, JsonPath.Value(payee, "payeeId|payee.payeeId"))
                Keep(txtPayeeUserId, JsonPath.Value(payee, "payeeUserId|payeeUser.payeeUserId"))
                If txtPayeeId.Text.Trim() = "" Then
                    Throw New DreamException(
                        "No payeeId came back, so there is nothing to attach an account to.",
                        "Aucun payeeId n'est revenu : il n'y a rien à quoi rattacher un compte.")
                End If

                WriteLog("", "")
                WriteLog("Step 2 of 4 - attach the supplier's bank account",
                         "Étape 2 sur 4 — rattacher le compte bancaire du fournisseur")
                Dim account = Await _client.PostAsync("/payees/" & txtPayeeId.Text.Trim() & "/accounts",
                                                      Payloads.BankAccountBody(ReadBankAccount()), ct)
                Keep(txtBankAccountId, JsonPath.Value(account, "bankAccountId|bankAccount.bankAccountId"))
                If txtBankAccountId.Text.Trim() = "" Then
                    Throw New DreamException(
                        "No bankAccountId came back; an EFT cannot be accepted without one.",
                        "Aucun bankAccountId n'est revenu ; un EFT ne peut pas être accepté sans lui.")
                End If

                WriteLog("", "")
                WriteLog("Step 3 of 4 - create the payment", "Étape 3 sur 4 — créer le paiement")
                Dim payment = Await _client.PostAsync("/payments/add", Payloads.PaymentBody(ReadPayment(amount)), ct)
                Keep(txtPaymentId, JsonPath.Value(payment, "paymentId|payment.paymentId"))
                If txtPaymentId.Text.Trim() = "" Then
                    Throw New DreamException(
                        "No paymentId came back, so there is nothing to accept.",
                        "Aucun paymentId n'est revenu : il n'y a rien à accepter.")
                End If

                WriteLog("", "")
                WriteLog("Step 4 of 4 - accept the payment. This is the step that moves the money.",
                         "Étape 4 sur 4 — accepter le paiement. C'est l'étape qui déplace l'argent.")
                Await _client.PostAsync("/payments/" & txtPaymentId.Text.Trim() & "/accept",
                                        Payloads.AcceptBody(txtPayeeUserId.Text.Trim(), "EFT",
                                                            txtBankAccountId.Text.Trim()), ct)

                WriteLog("", "")
                WriteLog("The supplier has been paid. paymentId " & txtPaymentId.Text.Trim() &
                         " for invoice " & txtInvoiceNo.Text.Trim() & ".",
                         "Le fournisseur a été payé. paymentId " & txtPaymentId.Text.Trim() &
                         " pour la facture " & txtInvoiceNo.Text.Trim() & ".")
                WriteLog("On the website this is where the disbursement would be written to the books and the " &
                         "invoice marked paid - which is still a TODO there.",
                         "Sur le site, c'est ici que le décaissement serait écrit en comptabilité et la facture " &
                         "marquée payée — ce qui reste un TODO là-bas.")
            End Function)
    End Sub

#End Region

#Region "The four calls, one at a time"

    Private Sub CreatePayee()
        RunStep("Create payee", "Créer le bénéficiaire",
            Async Function(ct)
                Dim rep = Await _client.PostAsync("/payees/add", Payloads.PayeeBody(ReadPayee()), ct)
                Keep(txtPayeeId, JsonPath.Value(rep, "payeeId|payee.payeeId"))
                Keep(txtPayeeUserId, JsonPath.Value(rep, "payeeUserId|payeeUser.payeeUserId"))
            End Function)
    End Sub

    Private Sub AddBankAccount()
        Dim id = txtPayeeId.Text.Trim()
        If Require(id, "payeeId") Then Return
        RunStep("Add bank account", "Ajouter le compte bancaire",
            Async Function(ct)
                Dim rep = Await _client.PostAsync("/payees/" & id & "/accounts",
                                                  Payloads.BankAccountBody(ReadBankAccount()), ct)
                Keep(txtBankAccountId, JsonPath.Value(rep, "bankAccountId|bankAccount.bankAccountId"))
            End Function)
    End Sub

    Private Sub CreatePayment()
        Dim amount As Decimal
        If Not ReadAmount(amount) Then Return
        If Require(txtPayeeId.Text.Trim(), "payeeId") Then Return
        RunStep("Create payment", "Créer le paiement",
            Async Function(ct)
                Dim rep = Await _client.PostAsync("/payments/add", Payloads.PaymentBody(ReadPayment(amount)), ct)
                Keep(txtPaymentId, JsonPath.Value(rep, "paymentId|payment.paymentId"))
            End Function)
    End Sub

    Private Sub AcceptEft()
        Dim acct = txtBankAccountId.Text.Trim()
        If Require(acct, "bankAccountId") Then Return
        AcceptPayment("Accept by EFT", "Accepter en EFT", "EFT", acct)
    End Sub

#End Region

#Region "Other calls"

    Private Sub GetToken()
        RunStep("Get a token", "Obtenir un jeton",
            Async Function(ct)
                Await _client.GetTokenAsync(ct)
            End Function)
    End Sub

    ''' <summary>
    ''' The search body that /payments and /payeeUsers accept. Undocumented for
    ''' /payments — found by trying: the documented shape, with its filters and
    ''' sort fields, is rejected with HBE006; this bare one works.
    ''' </summary>
    Private Const SearchBody As String = "{""query"":{""size"":100,""startIndex"":0}}"

    ''' <summary>
    ''' Answers "which payers?" the only way the API allows: no endpoint lists
    ''' them, but every payment carries its payer in legalEntity, so the existing
    ''' payments are grouped by it.
    ''' </summary>
    Private Sub ListPayers()
        RunStep("List the payers", "Lister les payeurs",
            Async Function(ct)
                Dim rep = Await _client.SendAsync(Net.Http.HttpMethod.Post, "/payments", SearchBody, ct)
                Dim rows = TryCast(JsonPath.Child(JsonPath.Child(rep, "paymentList"), "paymentListInfo"), JsonArray)
                If rows Is Nothing OrElse rows.Count = 0 Then
                    WriteLog("No payment to read a payer from.", "Aucun paiement où lire un payeur.")
                    Return
                End If

                ' legalEntity -> business name, and how many payments carry it.
                Dim names As New Dictionary(Of String, String)
                Dim counts As New Dictionary(Of String, Integer)
                For Each row In rows
                    Dim entity = JsonPath.Value(row, "legalEntity")
                    If entity = "" Then Continue For
                    If Not counts.ContainsKey(entity) Then
                        counts(entity) = 0
                        names(entity) = JsonPath.Value(row, "clientBusinessName")
                    End If
                    counts(entity) += 1
                Next

                WriteLog("", "")
                WriteLog(counts.Count & " payer(s) seen across " & rows.Count & " payment(s):",
                         counts.Count & " payeur(s) sur " & rows.Count & " paiement(s) :")
                For Each entity In counts.Keys.OrderBy(Function(k) k)
                    Dim line = "    " & entity.PadRight(18) & names(entity).PadRight(16) &
                               counts(entity) & " payment(s)"
                    Dim ligne = "    " & entity.PadRight(18) & names(entity).PadRight(16) &
                                counts(entity) & " paiement(s)"
                    WriteLog(line, ligne)
                Next
                ShowPayers(counts, names)
                WriteLog("", "")
                WriteLog("Put the right one in ""legalEntity"" on the Connection tab. It is sent with the payment - " &
                         "but note it does not lift the G00021 on /payees/add, which comes earlier.",
                         "Reportez le bon dans « legalEntity », onglet Connection. Il part avec le paiement — mais " &
                         "il ne lève pas le G00021 de /payees/add, qui arrive avant.")
            End Function)
    End Sub

    ''' <summary>
    ''' Puts the payers on screen, the one already chosen selected. Bold marks
    ''' it, so the right row is obvious among eight.
    ''' </summary>
    Private Sub ShowPayers(counts As Dictionary(Of String, Integer), names As Dictionary(Of String, String))
        If InvokeRequired Then
            BeginInvoke(New Action(Of Dictionary(Of String, Integer), Dictionary(Of String, String))(
                AddressOf ShowPayers), counts, names)
            Return
        End If

        Dim chosen = txtLegalEntity.Text.Trim()
        Dim picked As ListViewItem = Nothing

        lstPayers.BeginUpdate()
        lstPayers.Items.Clear()
        For Each entity In counts.Keys.OrderBy(Function(k) k)
            Dim row As New ListViewItem(entity)
            row.SubItems.Add(names(entity))
            row.SubItems.Add(counts(entity).ToString())
            If entity = chosen Then
                row.Font = New Font(lstPayers.Font, FontStyle.Bold)
                row.Selected = True
                picked = row
            End If
            lstPayers.Items.Add(row)
        Next
        lstPayers.EndUpdate()

        ' Eight payers do not fit: bring the chosen one into view rather than
        ' leaving it selected somewhere below the fold.
        If picked IsNot Nothing Then picked.EnsureVisible()
    End Sub

    ''' <summary>Clicking a payer puts it in legalEntity.</summary>
    Private Sub PickPayer()
        If lstPayers.SelectedItems.Count = 0 Then Return
        Dim entity = lstPayers.SelectedItems(0).Text
        If entity = txtLegalEntity.Text.Trim() Then Return
        txtLegalEntity.Text = entity
        WriteLog("Payer set to " & entity & " (" & lstPayers.SelectedItems(0).SubItems(1).Text & ").",
                 "Payeur choisi : " & entity & " (" & lstPayers.SelectedItems(0).SubItems(1).Text & ").")
    End Sub

    ''' <summary>
    ''' Recovers payees without creating one, since /payees/add is blocked.
    '''
    ''' Nothing lists payees — /payees answers G00002 — but each payment names
    ''' the payee it went to, and the payee record carries its primary user. So:
    ''' payments of this payer, then each payment's detail for its payeeId, then
    ''' each payee for its name and primaryPayeeUserId.
    ''' </summary>
    Private Sub FindPayees()
        Dim payer = txtLegalEntity.Text.Trim()
        RunStep("Find the payees" & If(payer = "", "", " of " & payer),
                "Retrouver les bénéficiaires" & If(payer = "", "", " de " & payer),
            Async Function(ct)
                Dim rep = Await _client.SendAsync(Net.Http.HttpMethod.Post, "/payments", SearchBody, ct)
                Dim rows = TryCast(JsonPath.Child(JsonPath.Child(rep, "paymentList"), "paymentListInfo"), JsonArray)
                If rows Is Nothing OrElse rows.Count = 0 Then
                    WriteLog("No payment to read a payee from.", "Aucun paiement où lire un bénéficiaire.")
                    Return
                End If

                Dim ids As New List(Of String)
                For Each row In rows
                    If payer <> "" AndAlso JsonPath.Value(row, "legalEntity") <> payer Then Continue For
                    Dim paymentId = JsonPath.Value(row, "paymentId")
                    If paymentId = "" Then Continue For
                    Dim detail = Await _client.GetAsync("/payments/" & paymentId, ct)
                    Dim found = JsonPath.Value(detail, "payment.payeeId")
                    If found <> "" AndAlso Not ids.Contains(found) Then ids.Add(found)
                Next

                If ids.Count = 0 Then
                    WriteLog("No payee found for this payer. Clear legalEntity to search them all.",
                             "Aucun bénéficiaire pour ce payeur. Videz legalEntity pour chercher partout.")
                    Return
                End If

                Dim found2 As New List(Of ListViewItem)
                For Each one In ids
                    Dim payee = Await _client.GetAsync("/payees/" & one, ct)
                    Dim name = JsonPath.Value(payee, "payeeAccount.name|payeeAccount.businessDetails.legalName")
                    Dim userId = JsonPath.Value(payee, "payeeAccount.primaryPayeeUserId")

                    ' How many bank accounts it already has: an EFT needs one.
                    Dim accounts = Await _client.GetAsync("/payees/" & one & "/accounts", ct)
                    Dim list = TryCast(JsonPath.Child(JsonPath.Child(accounts, "bankAccounts"), "bankAccount"), JsonArray)
                    Dim howMany = If(list Is Nothing, 0, list.Count)

                    Dim row As New ListViewItem(one)
                    row.SubItems.Add(name)
                    row.SubItems.Add(userId)
                    row.SubItems.Add(howMany.ToString())
                    found2.Add(row)
                Next

                ShowPayees(found2)
                WriteLog("", "")
                WriteLog(found2.Count & " payee(s) recovered. Click one to fill payeeId and payeeUserId, then run " &
                         "step 2 to attach a bank account.",
                         found2.Count & " bénéficiaire(s) retrouvé(s). Cliquez-en un pour remplir payeeId et " &
                         "payeeUserId, puis lancez l'étape 2 pour rattacher un compte bancaire.")
            End Function)
    End Sub

    Private Sub ShowPayees(rows As List(Of ListViewItem))
        If InvokeRequired Then
            BeginInvoke(New Action(Of List(Of ListViewItem))(AddressOf ShowPayees), rows)
            Return
        End If
        lstPayees.BeginUpdate()
        lstPayees.Items.Clear()
        For Each row In rows
            lstPayees.Items.Add(row)
        Next
        lstPayees.EndUpdate()
    End Sub

    ''' <summary>Clicking a payee fills the two identifiers the next steps need.</summary>
    Private Sub PickPayee()
        If lstPayees.SelectedItems.Count = 0 Then Return
        Dim row = lstPayees.SelectedItems(0)
        If row.Text = txtPayeeId.Text.Trim() Then Return
        txtPayeeId.Text = row.Text
        txtPayeeUserId.Text = row.SubItems(2).Text
        WriteLog("Payee set to " & row.SubItems(1).Text & " (" & row.Text & ").",
                 "Bénéficiaire choisi : " & row.SubItems(1).Text & " (" & row.Text & ").")
    End Sub

    Private Sub ListPayments()
        RunStep("List the payments", "Lister les paiements",
            Async Function(ct)
                Await _client.SendAsync(Net.Http.HttpMethod.Post, "/payments", SearchBody, ct)
            End Function)
    End Sub

    Private Sub ListPayeeUsers()
        RunStep("List the payee users", "Lister les utilisateurs bénéficiaires",
            Async Function(ct)
                Await _client.SendAsync(Net.Http.HttpMethod.Post, "/payeeUsers", SearchBody, ct)
            End Function)
    End Sub

    Private Sub GetPayee()
        Dim id = txtPayeeId.Text.Trim()
        If Require(id, "payeeId") Then Return
        RunStep("Get payee", "Consulter le bénéficiaire",
            Async Function(ct)
                Await _client.GetAsync("/payees/" & id, ct)
            End Function)
    End Sub

    Private Sub ListAccounts()
        Dim id = txtPayeeId.Text.Trim()
        If Require(id, "payeeId") Then Return
        RunStep("List accounts", "Lister les comptes",
            Async Function(ct)
                Dim rep = Await _client.GetAsync("/payees/" & id & "/accounts", ct)

                ' An account already attached is one the flow does not need to
                ' create again: take the first, so step 4 has what it needs.
                Dim list = TryCast(JsonPath.Child(JsonPath.Child(rep, "bankAccounts"), "bankAccount"), JsonArray)
                If list Is Nothing OrElse list.Count = 0 Then
                    WriteLog("This payee has no bank account yet.",
                             "Ce bénéficiaire n'a pas encore de compte bancaire.")
                    Return
                End If
                For Each account In list
                    WriteLog("    " & JsonPath.Value(account, "institutionNumber") & " " &
                             JsonPath.Value(account, "transitNumber") & " " &
                             JsonPath.Value(account, "bankAccountType") & " " &
                             JsonPath.Value(account, "currencyCode") & "   " &
                             JsonPath.Value(account, "bankAccountId|genAccountDbId"),
                             "    " & JsonPath.Value(account, "institutionNumber") & " " &
                             JsonPath.Value(account, "transitNumber") & " " &
                             JsonPath.Value(account, "bankAccountType") & " " &
                             JsonPath.Value(account, "currencyCode") & "   " &
                             JsonPath.Value(account, "bankAccountId|genAccountDbId"))
                Next
                Keep(txtBankAccountId, JsonPath.Value(list(0), "bankAccountId|genAccountDbId"))
            End Function)
    End Sub

    Private Sub VerifyAccount()
        AccountCall("Verify account", "Vérifier le compte", "/verify")
    End Sub

    Private Sub AcceptAccount()
        AccountCall("Account acceptance", "Acceptation du compte", "/acceptance")
    End Sub

    Private Sub AccountCall(title As String, titre As String, suffix As String)
        Dim id = txtPayeeId.Text.Trim()
        Dim acct = txtBankAccountId.Text.Trim()
        If Require(id, "payeeId") OrElse Require(acct, "bankAccountId") Then Return
        RunStep(title, titre,
            Async Function(ct)
                ' The website posts an empty object here; the exact body is still
                ' unconfirmed. Use the Raw request tab to try something else.
                Await _client.PostAsync("/payees/" & id & "/accounts/" & acct & suffix, New JsonObject(), ct)
            End Function)
    End Sub

    Private Sub AcceptInterac()
        ' Over Interac the money goes to an email address: no bank account needed.
        AcceptPayment("Accept by Interac", "Accepter en Interac", txtInteracMethod.Text.Trim(), "")
    End Sub

    Private Sub AcceptPayment(title As String, titre As String, method As String, bankAccountId As String)
        Dim id = txtPaymentId.Text.Trim()
        If Require(id, "paymentId") Then Return
        RunStep(title, titre,
            Async Function(ct)
                Dim body = Payloads.AcceptBody(txtPayeeUserId.Text.Trim(), method, bankAccountId)
                Await _client.PostAsync("/payments/" & id & "/accept", body, ct)
            End Function)
    End Sub

    Private Sub GetPayment()
        Dim id = txtPaymentId.Text.Trim()
        If Require(id, "paymentId") Then Return
        RunStep("Get payment", "Consulter le paiement",
            Async Function(ct)
                Await _client.GetAsync("/payments/" & id, ct)
            End Function)
    End Sub

    Private Sub CancelPayment()
        Dim id = txtPaymentId.Text.Trim()
        If Require(id, "paymentId") Then Return
        If MessageBox.Show("Cancel payment " & id & "?" & Environment.NewLine &
                           "Annuler le paiement " & id & " ?", "Dream Payments",
                           MessageBoxButtons.YesNo, MessageBoxIcon.Question) <> DialogResult.Yes Then Return
        RunStep("Cancel payment", "Annuler le paiement",
            Async Function(ct)
                ' Empty object, as the website sends.
                Await _client.PostAsync("/payments/" & id & "/cancel", New JsonObject(), ct)
            End Function)
    End Sub

    Private Sub SendRaw()
        Dim path = txtPath.Text.Trim()
        If Require(path, "path") Then Return
        If Not path.StartsWith("/") Then path = "/" & path

        Dim body = txtBody.Text.Trim()
        If body <> "" Then
            Try
                body = DreamClient.ToJson(JsonNode.Parse(body))
            Catch ex As Exception
                WriteLog("[x] The body is not valid JSON: " & ex.Message,
                         "[x] Le corps n'est pas du JSON valide : " & ex.Message)
                Return
            End Try
        End If

        Dim method = New Net.Http.HttpMethod(CStr(cboMethod.SelectedItem))
        Dim title = method.Method & " " & path
        RunStep(title, title,
            Async Function(ct)
                Await _client.SendAsync(method, path, body, ct)
            End Function)
    End Sub

#End Region

#Region "Plumbing"

    ''' <summary>
    ''' Runs one step: reads the settings back, locks the screen, logs the title,
    ''' and reports failure into both logs rather than throwing.
    ''' </summary>
    Private Async Sub RunStep(title As String, titre As String, work As Func(Of CancellationToken, Task))
        If _busy Then Return
        _busy = True
        Enabled = False
        Cursor = Cursors.WaitCursor
        ReadSettings()

        Dim rule = New String("-"c, 78) & Environment.NewLine
        Dim stamp = "   " & DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
        WriteLog(rule & title & stamp, rule & titre & stamp)
        Try
            Await work(CancellationToken.None)
            WriteLog("[ok] " & title & ": succeeded.", "[ok] " & titre & " : réussi.")
        Catch ex As DreamException
            WriteLog("[x] " & ex.Message, "[x] " & ex.FrenchMessage)
        Catch ex As Exception
            WriteLog("[x] " & ex.GetType().Name & ": " & ex.Message,
                     "[x] " & ex.GetType().Name & " : " & ex.Message)
        Finally
            _busy = False
            Enabled = True
            Cursor = Cursors.Default
            UpdateStatus()
        End Try
    End Sub

    Private Function Require(value As String, name As String) As Boolean
        If value <> "" Then Return False
        WriteLog("[x] " & name & " is required for this call. Run the full flow, or the earlier steps first.",
                 "[x] " & name & " est requis pour cet appel. Lancez le parcours complet, ou les étapes précédentes.")
        Return True
    End Function

    ''' <summary>Keeps an identifier returned by Dream, and says so in both logs.</summary>
    Private Sub Keep(field As TextBox, value As String)
        If value = "" Then Return
        field.Text = value
        WriteLog("    -> " & value, "    -> " & value)
    End Sub

    ''' <summary>
    ''' One line in each log. Called from async continuations, so it marshals
    ''' back to the UI thread when it has to.
    ''' </summary>
    Private Sub WriteLog(english As String, french As String)
        If InvokeRequired Then
            BeginInvoke(New Action(Of String, String)(AddressOf WriteLog), english, french)
            Return
        End If
        txtLogEn.AppendText(english & Environment.NewLine)
        txtLogFr.AppendText(french & Environment.NewLine)
    End Sub

    Private Sub UpdateStatus()
        If _client.HasValidToken Then
            lblStatus.Text = _client.TokenType & " token valid until " &
                             _client.ExpiresAt.ToLocalTime().ToString("HH:mm:ss") & "."
            lblStatus.ForeColor = Color.FromArgb(21, 128, 61)
        Else
            lblStatus.Text = "No token: the next call will request one."
            lblStatus.ForeColor = Color.FromArgb(120, 113, 108)
        End If
    End Sub

    Private Sub CopyLog(box As TextBox)
        If box.TextLength = 0 Then Return
        Clipboard.SetText(box.Text)
        WriteLog("Log copied to the clipboard.", "Journal copié dans le presse-papiers.")
    End Sub

    Private Sub SaveLog(box As TextBox, filePrefix As String)
        Using d As New SaveFileDialog With {.Filter = "Text (*.txt)|*.txt",
                                            .FileName = filePrefix & DateTime.Now.ToString("yyyyMMdd-HHmm") & ".txt"}
            If d.ShowDialog(Me) <> DialogResult.OK Then Return
            File.WriteAllText(d.FileName, box.Text, New Text.UTF8Encoding(True))
            WriteLog("Log saved: " & d.FileName, "Journal enregistré : " & d.FileName)
        End Using
    End Sub

#End Region

#Region "Grid"

    ''' <summary>
    ''' A grid of labels and fields, two pairs per row. It saves repeating the
    ''' same six lines of positioning thirty times over.
    ''' </summary>
    Private Class Grid

        Public ReadOnly Panel As New TableLayoutPanel()
        Private _col As Integer
        Private _row As Integer

        Public Sub New(Optional labelWidth As Integer = 175)
            Panel.Dock = DockStyle.Fill
            Panel.AutoScroll = True
            Panel.ColumnCount = 4
            Panel.Padding = New Padding(8, 6, 8, 6)
            Panel.ColumnStyles.Add(New ColumnStyle(SizeType.Absolute, labelWidth))
            Panel.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 50))
            Panel.ColumnStyles.Add(New ColumnStyle(SizeType.Absolute, labelWidth))
            Panel.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 50))
            NewRow(28)
        End Sub

        Public Sub Field(caption As String, control As Control)
            If control Is Nothing Then control = New TextBox()
            control.Dock = DockStyle.Fill
            Panel.Controls.Add(MakeLabel(caption), _col, _row)
            Panel.Controls.Add(control, _col + 1, _row)
            _col += 2
            If _col >= 4 Then NewRow(28)
        End Sub

        ''' <summary>A field taking the whole width: URL, address, JSON.</summary>
        Public Sub FullWidth(caption As String, control As Control, Optional height As Integer = 28)
            If _col <> 0 Then NewRow(height) Else SetRowHeight(height)
            control.Dock = DockStyle.Fill
            Panel.Controls.Add(MakeLabel(caption), 0, _row)
            Panel.Controls.Add(control, 1, _row)
            Panel.SetColumnSpan(control, 3)
            NewRow(28)
        End Sub

        Public Sub FullWidth(control As Control, Optional height As Integer = 28)
            If _col <> 0 Then NewRow(height) Else SetRowHeight(height)
            control.Dock = DockStyle.Fill
            Panel.Controls.Add(control, 0, _row)
            Panel.SetColumnSpan(control, 4)
            NewRow(28)
        End Sub

        ''' <summary>A section heading, so the screen reads like the website's.</summary>
        Public Sub Section(caption As String)
            Dim l As New Label With {.Text = caption, .Dock = DockStyle.Fill, .AutoSize = False,
                                     .TextAlign = ContentAlignment.BottomLeft,
                                     .ForeColor = Color.FromArgb(30, 64, 175),
                                     .Font = New Font("Segoe UI", 9.5F, FontStyle.Bold),
                                     .Padding = New Padding(0, 8, 0, 2)}
            FullWidth(l, 26)
        End Sub

        ''' <summary>An explanation, at the head of a section.</summary>
        Public Sub Note(text As String)
            Dim l As New Label With {.Text = text, .Dock = DockStyle.Fill, .AutoSize = False,
                                     .ForeColor = Color.FromArgb(87, 83, 78),
                                     .Padding = New Padding(0, 2, 0, 6)}
            FullWidth(l, 40)
        End Sub

        Public Sub Buttons(ParamArray list As Button())
            Dim bar As New FlowLayoutPanel With {.Dock = DockStyle.Fill, .AutoSize = True,
                                                 .Margin = New Padding(0, 8, 0, 0)}
            bar.Controls.AddRange(list)
            FullWidth(bar, 44)
        End Sub

        ''' <summary>Closes the grid: the last row takes up the space left.</summary>
        Public Sub Finish(Optional stretch As Boolean = True)
            If stretch Then
                Panel.RowStyles(_row) = New RowStyle(SizeType.Percent, 100)
            Else
                Panel.RowStyles(_row) = New RowStyle(SizeType.Absolute, 0)
                Panel.AutoScroll = False
            End If
        End Sub

        Private Shared Function MakeLabel(caption As String) As Label
            Return New Label With {.Text = caption, .Dock = DockStyle.Fill, .AutoEllipsis = True,
                                   .TextAlign = ContentAlignment.MiddleLeft}
        End Function

        Private Sub SetRowHeight(value As Integer)
            Panel.RowStyles(_row) = New RowStyle(SizeType.Absolute, value)
        End Sub

        Private Sub NewRow(height As Integer)
            _col = 0
            If Panel.RowCount > 0 Then _row = Panel.RowCount
            Panel.RowCount = _row + 1
            Panel.RowStyles.Add(New RowStyle(SizeType.Absolute, height))
        End Sub

    End Class

#End Region

End Class
