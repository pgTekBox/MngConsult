Imports System.Data.SqlClient
Imports Newtonsoft.Json.Linq
Imports Telerik.Web.UI

Partial Public Class wbfSetting
    Inherits clsData

    ''' <summary>
    ''' Prompt d'extraction des informations d'entreprise à partir d'un document
    ''' (immatriculation REQ, lettre ARC/Revenu Québec, en-tête de lettre, facture…).
    ''' </summary>
    Private Const EXTRACT_PROMPT_COMPANY As String =
        "Tu es un extracteur d'informations d'entreprise québécoise et canadienne. " &
        "À partir du document fourni (immatriculation au Registraire des entreprises du Québec, " &
        "lettre de l'ARC ou de Revenu Québec, en-tête de lettre, facture, etc.), " &
        "retourne UNIQUEMENT un objet JSON valide avec exactement ces clés (mets null si absent) : " &
        "{""legal_name"": string, ""trade_name"": string, ""neq"": string, ""phone"": string, " &
        """address1"": string, ""address2"": string, ""city"": string, ""province"": string, " &
        """postal_code"": string, ""country"": string, ""gst_number"": string, ""qst_number"": string}. " &
        "legal_name = dénomination / nom légal. trade_name = nom commercial usuel. " &
        "neq = Numéro d'entreprise du Québec (10 chiffres). phone = téléphone. " &
        "address1 = adresse civique (numéro et rue). address2 = complément (bureau, suite). " &
        "city = ville. province = province ou état. postal_code = code postal. country = pays. " &
        "gst_number = numéro de TPS. qst_number = numéro de TVQ. " &
        "Ne retourne que le JSON, sans texte ni balises de code autour."

    ' --- Valeurs exposées au markup (haut de page : progression + identité admin) ---
    Protected ProfilePct As Integer = 0
    Protected AdminName As String = ""
    Protected AdminMeta As String = ""
    Protected AdminRole As String = ""
    Protected AdminInitials As String = ""

    ' =========================================================
    '  PAGE LIFECYCLE
    '
    '  IMPORTANT : pour que les contrôles dynamiques injectés dans
    '  les PlaceHolder via ItemDataBound persistent au postback, on
    '  DOIT binder les Repeaters AVANT que ASP.NET restaure le
    '  ViewState et les valeurs postées (Page_Load c'est trop tard).
    '
    '  Solution : binder dans OnInit ou OnLoad, mais SANS la garde
    '  Not IsPostBack — il faut le faire à CHAQUE cycle.
    '
    '  Les valeurs saisies par l'utilisateur sont automatiquement
    '  réinjectées par ASP.NET dans les contrôles via le LoadPostData
    '  (qui se produit après OnInit, avant Page_Load).
    ' =========================================================

    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)

        ' Binder les Repeaters à CHAQUE cycle (pas seulement au premier load)
        ' pour que les contrôles dynamiques existent quand les valeurs postées
        ' sont restaurées par ASP.NET.
        LoadAllSettings()
    End Sub

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If
        ApplyLocalization()
        If Not IsPostBack Then LoadCompanyLogo()
    End Sub

    ''' <summary>Applique la langue courante aux contrôles serveur (titre, boutons, onglets).</summary>
    Private Sub ApplyLocalization()
        Page.Title = L("pageTitle")
        btnSave.Text = L("save")
        btnReload.Text = L("reload")
        btnScanExtract.Text = L("scanBtn")
        If tsSettings.Tabs.Count >= 8 Then
            tsSettings.Tabs(0).Text = L("tabCompany")
            tsSettings.Tabs(1).Text = L("tabTaxes")
            tsSettings.Tabs(2).Text = L("tabEmail")
            tsSettings.Tabs(3).Text = L("tabInvoice")
            tsSettings.Tabs(4).Text = L("tabProcessing")
            tsSettings.Tabs(5).Text = L("tabAccounting")
            tsSettings.Tabs(6).Text = L("tabBank")
            tsSettings.Tabs(7).Text = L("tabAccountant")
        End If
    End Sub

    ''' <summary>Traductions de l'interface des paramètres (fr/en/es). Les LIBELLÉS des
    ''' paramètres viennent de la BD (T102ParamI18n via s0150) ; ici : chrome + combos.</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Paramètres — 60Sec-AI", "Settings — 60Sec-AI", "Ajustes — 60Sec-AI")
            Case "pageTitleShort" : Return Choose3(lang, "Paramètres", "Settings", "Ajustes")
            Case "pageSub" : Return Choose3(lang, "Entreprise, taxes, courriels, factures et comptabilité.", "Company, taxes, emails, invoices and accounting.", "Empresa, impuestos, correos, facturas y contabilidad.")
            Case "save" : Return Choose3(lang, "Enregistrer", "Save", "Guardar")
            Case "reload" : Return Choose3(lang, "Recharger", "Reload", "Recargar")
            Case "tabCompany" : Return Choose3(lang, "Entreprise", "Company", "Empresa")
            Case "tabTaxes" : Return Choose3(lang, "Taxes", "Taxes", "Impuestos")
            Case "tabEmail" : Return Choose3(lang, "Email", "Email", "Correo")
            Case "tabInvoice" : Return Choose3(lang, "Facture", "Invoice", "Factura")
            Case "tabProcessing" : Return Choose3(lang, "Traitement", "Processing", "Procesamiento")
            Case "tabAccounting" : Return Choose3(lang, "Comptabilité", "Accounting", "Contabilidad")
            Case "tabBank" : Return Choose3(lang, "Bancaire", "Banking", "Bancario")
            Case "tabAccountant" : Return Choose3(lang, "Comptable", "Accountant", "Contador")
            Case "introAccounting" : Return Choose3(lang, "Comptes par défaut utilisés par les modules de comptabilisation automatique.", "Default accounts used by the automatic bookkeeping modules.", "Cuentas predeterminadas usadas por los módulos de contabilización automática.")
            Case "introBank" : Return Choose3(lang, "Comptes bancaires connectés via Plaid. Sélectionnez le compte par défaut utilisé pour les encaissements et décaissements.", "Bank accounts connected via Plaid. Select the default account used for cash-ins and cash-outs.", "Cuentas bancarias conectadas mediante Plaid. Seleccione la cuenta predeterminada para cobros y pagos.")
            Case "introAccountant" : Return Choose3(lang, "Clé pour votre comptable afin qu'il puisse accéder à vos données comptables sans être utilisateur de votre compte 60Sec-AI.", "Key for your accountant so they can access your accounting data without being a user of your 60Sec-AI account.", "Clave para su contador para que pueda acceder a sus datos contables sin ser usuario de su cuenta 60Sec-AI.")
            Case "emptyTab" : Return Choose3(lang, "Aucun paramètre configuré pour cet onglet.", "No parameter configured for this tab.", "Ningún parámetro configurado para esta pestaña.")
            Case "savedOk" : Return Choose3(lang, "Paramètres enregistrés.", "Settings saved.", "Ajustes guardados.")
            Case "reloadedOk" : Return Choose3(lang, "Paramètres rechargés.", "Settings reloaded.", "Ajustes recargados.")

            ' === Haut de page : progression + identité admin ===
            Case "profileLabel" : Return Choose3(lang, "Progression du profil", "Profile completion", "Progreso del perfil")
            Case "roleAdmin" : Return Choose3(lang, "Administrateur", "Administrator", "Administrador")
            Case "roleAccountant" : Return Choose3(lang, "Comptable", "Accountant", "Contador")

            ' === Scan de document / remplissage automatique ===
            Case "scanTitle" : Return Choose3(lang, "Remplissage automatique par document", "Auto-fill from a document", "Autocompletar desde un documento")
            Case "scanHint" : Return Choose3(lang, "Déposez une immatriculation, une lettre de l'ARC/Revenu Québec ou un en-tête : l'IA remplit les champs vides (Entreprise, Taxes).", "Drop a registration, a CRA/Revenu Québec letter or a letterhead: AI fills the empty fields (Company, Taxes).", "Suelte un registro, una carta de la CRA/Revenu Québec o un membrete: la IA rellena los campos vacíos (Empresa, Impuestos).")
            Case "scanDrop" : Return Choose3(lang, "Glissez un fichier ici ou cliquez pour choisir (PDF, JPG, PNG)", "Drag a file here or click to choose (PDF, JPG, PNG)", "Arrastre un archivo aquí o haga clic para elegir (PDF, JPG, PNG)")
            Case "scanBtn" : Return Choose3(lang, "Analyser le document", "Analyze document", "Analizar documento")
            Case "upChoose" : Return Choose3(lang, "Veuillez d'abord choisir un fichier.", "Please choose a file first.", "Elija un archivo primero.")
            Case "upEmpty" : Return Choose3(lang, "Le fichier est vide.", "The file is empty.", "El archivo está vacío.")
            Case "upNoKey" : Return Choose3(lang, "Clé OpenAI absente. Contactez l'administrateur.", "OpenAI key missing. Contact the administrator.", "Falta la clave de OpenAI. Contacte al administrador.")
            Case "upFormat" : Return Choose3(lang, "Format non pris en charge (PDF, JPG ou PNG uniquement).", "Unsupported format (PDF, JPG or PNG only).", "Formato no admitido (solo PDF, JPG o PNG).")
            Case "upFilled" : Return Choose3(lang, "{0} champ(s) rempli(s) automatiquement. Vérifiez, puis cliquez Enregistrer.", "{0} field(s) filled automatically. Review, then click Save.", "{0} campo(s) rellenado(s) automáticamente. Revise y haga clic en Guardar.")
            Case "upNone" : Return Choose3(lang, "Aucune information exploitable trouvée (ou champs déjà remplis).", "No usable information found (or fields already filled).", "No se encontró información utilizable (o los campos ya están llenos).")
            Case "upError" : Return Choose3(lang, "Erreur lors de l'analyse du document.", "Error while analyzing the document.", "Error al analizar el documento.")
            Case "saveErr" : Return Choose3(lang, "Erreur lors de la sauvegarde : ", "Error while saving: ", "Error al guardar: ")
            Case "boolYes" : Return Choose3(lang, "Oui", "Yes", "Sí")
            Case "boolNo" : Return Choose3(lang, "Non", "No", "No")
            Case "roundCent" : Return Choose3(lang, "2 décimales (cent)", "2 decimals (cent)", "2 decimales (centavo)")
            Case "roundInternal" : Return Choose3(lang, "4 décimales (interne)", "4 decimals (internal)", "4 decimales (interno)")
            Case "roundTrunc" : Return Choose3(lang, "Tronquer (2 décimales)", "Truncate (2 decimals)", "Truncar (2 decimales)")
            Case "taxExclusive" : Return Choose3(lang, "Taxes en sus", "Taxes added", "Impuestos aparte")
            Case "taxInclusive" : Return Choose3(lang, "Taxes incluses", "Taxes included", "Impuestos incluidos")
            Case "freqMonthly" : Return Choose3(lang, "Mensuelle", "Monthly", "Mensual")
            Case "freqQuarterly" : Return Choose3(lang, "Trimestrielle", "Quarterly", "Trimestral")
            Case "freqAnnual" : Return Choose3(lang, "Annuelle", "Annual", "Anual")
            Case "bankNone" : Return Choose3(lang, "(Aucun compte)", "(No account)", "(Sin cuenta)")
            Case "bankPick" : Return Choose3(lang, "-- Sélectionnez un compte --", "-- Select an account --", "-- Seleccione una cuenta --")
            Case "logoLabel" : Return Choose3(lang, "Logo de l'entreprise", "Company logo", "Logotipo de la empresa")
            Case "logoHint" : Return Choose3(lang, "PNG, JPG ou SVG — 1 Mo max. Enregistrez pour appliquer.", "PNG, JPG or SVG — 1 MB max. Save to apply.", "PNG, JPG o SVG — 1 MB máx. Guarde para aplicar.")
            Case "logoNone" : Return Choose3(lang, "Aucun logo", "No logo", "Sin logotipo")
            Case "logoRemove" : Return Choose3(lang, "Retirer le logo", "Remove logo", "Quitar el logotipo")
            Case "logoTooBig" : Return Choose3(lang, "Le logo dépasse 1 Mo.", "The logo exceeds 1 MB.", "El logotipo supera 1 MB.")
            Case "logoBadType" : Return Choose3(lang, "Format non supporté (PNG, JPG ou SVG).", "Unsupported format (PNG, JPG or SVG).", "Formato no soportado (PNG, JPG o SVG).")
            Case "mailVerifyBtn" : Return Choose3(lang, "Vérifier cette adresse", "Verify this address", "Verificar esta dirección")
            Case "mailVerifyAgainBtn" : Return Choose3(lang, "Renvoyer le lien", "Resend the link", "Reenviar el enlace")
            Case "mailVerified" : Return Choose3(lang, "Adresse vérifiée le", "Address verified on", "Dirección verificada el")
            Case "mailPending" : Return Choose3(lang, "Lien envoyé — en attente de confirmation", "Link sent — awaiting confirmation", "Enlace enviado — esperando confirmación")
            Case "mailNotVerified" : Return Choose3(lang, "Adresse non vérifiée", "Address not verified", "Dirección no verificada")
            Case "mailEmpty" : Return Choose3(lang, "Saisissez d'abord une adresse courriel.", "Enter an email address first.", "Introduzca primero una dirección de correo.")
            Case "mailInvalid" : Return Choose3(lang, "Adresse courriel invalide.", "Invalid email address.", "Dirección de correo no válida.")
            Case "mailSent" : Return Choose3(lang, "Courriel de vérification envoyé à ", "Verification email sent to ", "Correo de verificación enviado a ")
            Case "mailSendErr" : Return Choose3(lang, "Impossible d'envoyer le courriel de vérification : ", "Unable to send the verification email: ", "No se pudo enviar el correo de verificación: ")
            Case "mailSubject" : Return Choose3(lang, "Vérifiez l'adresse courriel de votre entreprise", "Verify your company email address", "Verifique la dirección de correo de su empresa")
            Case "mailHeader" : Return Choose3(lang, "Vérification de votre adresse courriel", "Email address verification", "Verificación de su dirección de correo")
            Case "mailGreeting" : Return Choose3(lang, "Bonjour !", "Hello!", "¡Hola!")
            Case "mailIntro" : Return Choose3(lang, "Cette adresse a été inscrite comme adresse d'expédition des courriels de votre entreprise. Cliquez sur le bouton ci-dessous pour confirmer que vous y avez bien accès.", "This address was set as your company's sending email address. Click the button below to confirm you have access to it.", "Esta dirección se registró como dirección de envío de correos de su empresa. Haga clic en el botón siguiente para confirmar que tiene acceso a ella.")
            Case "mailCta" : Return Choose3(lang, "Confirmer mon adresse", "Confirm my address", "Confirmar mi dirección")
            Case "mailExpiry" : Return Choose3(lang, "Ce lien est valide 24 heures.", "This link is valid for 24 hours.", "Este enlace es válido durante 24 horas.")
            Case "mailIgnore" : Return Choose3(lang, "Si vous n'êtes pas à l'origine de cette demande, ignorez simplement ce message.", "If you did not request this, simply ignore this message.", "Si no ha solicitado esto, simplemente ignore este mensaje.")
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

    ' =========================================================
    '  CHARGEMENT DE TOUS LES ONGLETS
    ' =========================================================

    Private Sub LoadAllSettings()
        ' L'état de vérification du courriel est relu à chaque (re)chargement :
        ' le badge doit refléter la BD, pas le cycle précédent.
        m_MailStatus = Nothing
        BindCategory("ENTREPRISE", rpEntreprise, pnlEmptyEntreprise)
        BindCategory("TAXES", rpTaxes, pnlEmptyTaxes)
        BindCategory("EMAIL", rpEmail, pnlEmptyEmail)
        BindCategory("PDF", rpPdf, pnlEmptyPdf)
        BindCategory("TRAITEMENT", rpTraitement, pnlEmptyTraitement)
        BindCategory("COMPTABILITE", rpComptabilite, pnlEmptyComptabilite)
        BindCategory("BANCAIRE", rpBancaire, pnlEmptyBancaire)
        BindCategory("COMPTABLE", rpComptable, pnlEmptyComptable)
        phStatus.Visible = False
    End Sub

    ''' <summary>
    ''' Charge les paramètres d'une catégorie via s0150GetParamsForCompany
    ''' et les bindÃ¨e sur le Repeater fourni.
    ''' </summary>
    Private Sub BindCategory(categorie As String, rp As Repeater, pnlEmpty As Panel)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Categorie", categorie))
        p.Add(New SqlParameter("@Lang", CurrentLang))

        Dim ds As DataSet = ExecuteSQLds("s0150GetParamsForCompany", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            rp.DataSource = Nothing
            rp.DataBind()
            pnlEmpty.Visible = True
            Return
        End If

        pnlEmpty.Visible = False
        rp.DataSource = ds.Tables(0)
        rp.DataBind()
    End Sub

    ' =========================================================
    '  HELPERS POUR L'ASPX
    ' =========================================================

    ''' <summary>
    ''' Retourne la classe CSS pour le wrapper de la field. Les paramètres
    ''' multiligne (TEXT) prennent toute la largeur de la grille.
    ''' </summary>
    Public Function GetFieldCssClass(dataItem As Object) As String
        Dim row As DataRowView = TryCast(dataItem, DataRowView)
        If row Is Nothing Then Return "field"

        Dim paramType As String = If(IsDBNull(row("ParamType")), "STRING", row("ParamType").ToString().ToUpper())
        Dim shortName As String = If(IsDBNull(row("ShortName")), "", row("ShortName").ToString().ToUpper())

        ' TEXT et signature multiligne occupent toute la largeur
        If paramType = "TEXT" Then Return "field field-fullwidth"

        Return "field"
    End Function

    ' =========================================================
    '  ITEM DATA BOUND — INJECTION DYNAMIQUE DES CONTRÔLES
    ' =========================================================

    Protected Sub rp_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim row As DataRowView = TryCast(e.Item.DataItem, DataRowView)
        If row Is Nothing Then Return

        Dim phControl As PlaceHolder = TryCast(e.Item.FindControl("phControl"), PlaceHolder)
        If phControl Is Nothing Then Return

        Dim shortName As String = If(IsDBNull(row("ShortName")), "", row("ShortName").ToString().ToUpper())
        Dim paramType As String = If(IsDBNull(row("ParamType")), "STRING", row("ParamType").ToString().ToUpper())
        Dim sVal As String = If(IsDBNull(row("sVal")), "", row("sVal").ToString())
        Dim iVal As String = If(IsDBNull(row("iVal")), "", row("iVal").ToString())
        ' DATE lue depuis la colonne typée dVal (format ISO pour le RadDatePicker)
        Dim dVal As String = If(IsDBNull(row("dVal")), "", CDate(row("dVal")).ToString("yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture))
        ' DECIMAL lu depuis la colonne typée fVal (chaîne invariante)
        Dim fVal As String = If(IsDBNull(row("fVal")), "", CDec(row("fVal")).ToString(Globalization.CultureInfo.InvariantCulture))

        ' Cas spéciaux : combos avec valeurs fixes (par ShortName)
        Select Case shortName
            Case "PROVINCE"
                phControl.Controls.Add(BuildProvinceCombo(sVal))
                Return
            Case "TAX_ROUNDING"
                phControl.Controls.Add(BuildTaxRoundingCombo(sVal))
                Return
            Case "TAX_MODE"
                phControl.Controls.Add(BuildTaxModeCombo(sVal))
                Return
            Case "TAX_FREQ"
                phControl.Controls.Add(BuildTaxFreqCombo(sVal))
                Return
            Case "INV_NUM_FORMAT"
                phControl.Controls.Add(BuildInvNumFormatCombo(sVal))
                Return
            Case "COMPTE_BANQUE"
                ' Combo dynamique alimenté depuis T143PlaidAccount
                ' La valeur sélectionnée est l'Id du compte (stocké dans iVal)
                phControl.Controls.Add(BuildCompteBanqueCombo(iVal))
                Return
            Case "MAIL_FROM_EMAIL"
                ' Textbox + bouton de vérification par courriel + badge d'état
                phControl.Controls.Add(BuildMailFromEmailField(sVal))
                Return
        End Select

        ' Cas génériques : selon le ParamType
        Select Case paramType
            Case "TEXT"
                ' Multiline (signature, conditions, notes)
                phControl.Controls.Add(BuildMultilineTextbox(sVal))
            Case "PASSWORD"
                phControl.Controls.Add(BuildPasswordTextbox(sVal))
            Case "INT", "INTEGER"
                phControl.Controls.Add(BuildNumericTextbox(iVal, isInt:=True))
            Case "DECIMAL"
                phControl.Controls.Add(BuildNumericTextbox(fVal, isInt:=False))
            Case "BOOL", "BOOLEAN"
                phControl.Controls.Add(BuildBoolCombo(sVal, iVal))
            Case "DATE"
                phControl.Controls.Add(BuildDatePicker(dVal))
            Case Else
                ' STRING par défaut
                phControl.Controls.Add(BuildSimpleTextbox(sVal))
        End Select
    End Sub

    ' =========================================================
    '  CONSTRUCTEURS DE CONTRÔLES
    '   (chacun crée un contrôle Telerik avec ID "txtValue" et la valeur)
    ' =========================================================

    Private Function BuildSimpleTextbox(value As String) As RadTextBox
        Dim tb As New RadTextBox()
        tb.ID = "txtValue"
        tb.Width = Unit.Percentage(100)
        tb.MaxLength = 300   ' = plafond de SaveParamString (sVal varchar(8000), tronqué à 300 côté code)
        tb.Text = value
        Return tb
    End Function

    Private Function BuildMultilineTextbox(value As String) As RadTextBox
        Dim tb As New RadTextBox()
        tb.ID = "txtValue"
        tb.Width = Unit.Percentage(100)
        tb.TextMode = InputMode.MultiLine
        tb.Rows = 4
        tb.MaxLength = 300   ' plafond SaveParamString
        tb.Text = value
        Return tb
    End Function

    Private Function BuildPasswordTextbox(value As String) As RadTextBox
        Dim tb As New RadTextBox()
        tb.ID = "txtValue"
        tb.Width = Unit.Percentage(100)
        tb.TextMode = InputMode.Password
        tb.MaxLength = 300   ' plafond SaveParamString
        tb.Text = value
        Return tb
    End Function

    Private Function BuildNumericTextbox(value As String, isInt As Boolean) As RadNumericTextBox
        Dim ntb As New RadNumericTextBox()
        ntb.ID = "txtValue"
        ntb.Width = Unit.Percentage(100)
        If isInt Then
            ntb.NumberFormat.DecimalDigits = 0
        Else
            ntb.NumberFormat.DecimalDigits = 3
        End If
        Dim parsed As Decimal = 0
        If Not String.IsNullOrEmpty(value) AndAlso Decimal.TryParse(value.Replace(",", "."),
            Globalization.NumberStyles.Any, Globalization.CultureInfo.InvariantCulture, parsed) Then
            ntb.Value = CDbl(parsed)
        End If
        Return ntb
    End Function

    ''' <summary>
    ''' Construit un RadDatePicker. La valeur est stockée en sVal au format
    ''' ISO 'yyyy-MM-dd' pour éviter les problèmes de culture.
    ''' </summary>
    Private Function BuildDatePicker(value As String) As RadDatePicker
        Dim dp As New RadDatePicker()
        dp.ID = "txtValue"
        dp.Width = Unit.Percentage(100)
        dp.DateInput.DateFormat = "yyyy-MM-dd"
        dp.DateInput.DisplayDateFormat = "yyyy-MM-dd"

        If Not String.IsNullOrEmpty(value) Then
            Dim parsedDate As Date
            ' On tente d'abord le format ISO, puis le format de la culture courante
            If Date.TryParseExact(value, "yyyy-MM-dd",
                                  Globalization.CultureInfo.InvariantCulture,
                                  Globalization.DateTimeStyles.None, parsedDate) Then
                dp.SelectedDate = parsedDate
            ElseIf Date.TryParse(value, parsedDate) Then
                dp.SelectedDate = parsedDate
            End If
        End If

        Return dp
    End Function

    Private Function BuildBoolCombo(sVal As String, iVal As String) As RadComboBox
        Dim cb As New RadComboBox()
        cb.ID = "txtValue"
        cb.Width = Unit.Percentage(100)
        cb.Items.Add(New RadComboBoxItem(L("boolYes"), "1"))
        cb.Items.Add(New RadComboBoxItem(L("boolNo"), "0"))

        ' La valeur peut être dans iVal (préféré) ou sVal
        Dim selected As String = "0"
        If Not String.IsNullOrEmpty(iVal) AndAlso iVal <> "0" Then selected = "1"
        If Not String.IsNullOrEmpty(sVal) Then
            If sVal = "1" OrElse sVal.ToUpper() = "TRUE" OrElse sVal.ToUpper() = "OUI" Then selected = "1"
        End If
        cb.SelectedValue = selected
        Return cb
    End Function

    Private Function BuildProvinceCombo(value As String) As RadComboBox
        Dim cb As New RadComboBox()
        cb.ID = "txtValue"
        cb.Width = Unit.Percentage(100)
        Dim lang As String = CurrentLang
        cb.Items.Add(New RadComboBoxItem("Québec", "QC"))
        cb.Items.Add(New RadComboBoxItem("Ontario", "ON"))
        cb.Items.Add(New RadComboBoxItem(Choose3(lang, "Nouveau-Brunswick", "New Brunswick", "Nuevo Brunswick"), "NB"))
        cb.Items.Add(New RadComboBoxItem(Choose3(lang, "Nouvelle-Écosse", "Nova Scotia", "Nueva Escocia"), "NS"))
        cb.Items.Add(New RadComboBoxItem("Manitoba", "MB"))
        cb.Items.Add(New RadComboBoxItem("Saskatchewan", "SK"))
        cb.Items.Add(New RadComboBoxItem("Alberta", "AB"))
        cb.Items.Add(New RadComboBoxItem(Choose3(lang, "Colombie-Britannique", "British Columbia", "Columbia Británica"), "BC"))
        cb.Items.Add(New RadComboBoxItem(Choose3(lang, "Terre-Neuve-et-Labrador", "Newfoundland and Labrador", "Terranova y Labrador"), "NL"))
        cb.Items.Add(New RadComboBoxItem(Choose3(lang, "Île-du-Prince-Édouard", "Prince Edward Island", "Isla del Príncipe Eduardo"), "PE"))
        cb.Items.Add(New RadComboBoxItem(Choose3(lang, "Territoires du Nord-Ouest", "Northwest Territories", "Territorios del Noroeste"), "NT"))
        cb.Items.Add(New RadComboBoxItem("Nunavut", "NU"))
        cb.Items.Add(New RadComboBoxItem("Yukon", "YT"))
        If Not String.IsNullOrEmpty(value) Then cb.SelectedValue = value
        Return cb
    End Function

    Private Function BuildTaxRoundingCombo(value As String) As RadComboBox
        Dim cb As New RadComboBox()
        cb.ID = "txtValue"
        cb.Width = Unit.Percentage(100)
        cb.Items.Add(New RadComboBoxItem(L("roundCent"), "2"))
        cb.Items.Add(New RadComboBoxItem(L("roundInternal"), "4"))
        cb.Items.Add(New RadComboBoxItem(L("roundTrunc"), "TRUNC2"))
        If Not String.IsNullOrEmpty(value) Then cb.SelectedValue = value Else cb.SelectedValue = "2"
        Return cb
    End Function

    Private Function BuildTaxModeCombo(value As String) As RadComboBox
        Dim cb As New RadComboBox()
        cb.ID = "txtValue"
        cb.Width = Unit.Percentage(100)
        cb.Items.Add(New RadComboBoxItem(L("taxExclusive"), "EXCLUSIVE"))
        cb.Items.Add(New RadComboBoxItem(L("taxInclusive"), "INCLUSIVE"))
        If Not String.IsNullOrEmpty(value) Then cb.SelectedValue = value Else cb.SelectedValue = "EXCLUSIVE"
        Return cb
    End Function

    ''' <summary>Format du numéro de facture : menu déroulant de gabarits à jetons
    ''' ({PREFIXE} {AAAA} {MM} {NUMERO}). La valeur stockée est le gabarit lui-même.
    ''' Défaut : {PREFIXE}-{AAAA}-{NUMERO}.</summary>
    Private Function BuildInvNumFormatCombo(value As String) As RadComboBox
        Dim cb As New RadComboBox()
        cb.ID = "txtValue"
        cb.Width = Unit.Percentage(100)
        ' Libellé = exemple lisible ; Valeur = gabarit à jetons
        cb.Items.Add(New RadComboBoxItem("PREFIXE-2026-0001", "{PREFIXE}-{AAAA}-{NUMERO}"))
        cb.Items.Add(New RadComboBoxItem("PREFIXE202612-0001", "{PREFIXE}{AAAA}{MM}-{NUMERO}"))
        cb.Items.Add(New RadComboBoxItem("PREFIXE-0001", "{PREFIXE}-{NUMERO}"))
        cb.Items.Add(New RadComboBoxItem("2026-0001", "{AAAA}-{NUMERO}"))
        cb.Items.Add(New RadComboBoxItem("0001", "{NUMERO}"))
        If Not String.IsNullOrEmpty(value) Then cb.SelectedValue = value Else cb.SelectedValue = "{PREFIXE}-{AAAA}-{NUMERO}"
        Return cb
    End Function

    ''' <summary>Fréquence de remise des taxes (TPS/TVQ) : valeurs MENSUELLE / TRIMESTRIELLE / ANNUELLE
    ''' (lues par wbfRapportTaxe). Défaut : TRIMESTRIELLE.</summary>
    Private Function BuildTaxFreqCombo(value As String) As RadComboBox
        Dim cb As New RadComboBox()
        cb.ID = "txtValue"
        cb.Width = Unit.Percentage(100)
        cb.Items.Add(New RadComboBoxItem(L("freqMonthly"), "MENSUELLE"))
        cb.Items.Add(New RadComboBoxItem(L("freqQuarterly"), "TRIMESTRIELLE"))
        cb.Items.Add(New RadComboBoxItem(L("freqAnnual"), "ANNUELLE"))
        If Not String.IsNullOrEmpty(value) Then cb.SelectedValue = value Else cb.SelectedValue = "TRIMESTRIELLE"
        Return cb
    End Function

    ''' <summary>
    ''' Construit un combo alimenté dynamiquement depuis T143PlaidAccount
    ''' filtré par CompanyGUID. Affiche AccountName, stocke l'Id du compte
    ''' (qui ira dans iVal au moment de la sauvegarde puisque le ParamType
    ''' est INT pour ce paramètre COMPTE_BANQUE).
    ''' </summary>
    Private Function BuildCompteBanqueCombo(selectedId As String) As RadComboBox
        Dim cb As New RadComboBox()
        cb.ID = "txtValue"
        cb.Width = Unit.Percentage(100)
        cb.EmptyMessage = L("bankPick")

        ' Item vide pour permettre la désélection
        cb.Items.Add(New RadComboBoxItem(L("bankNone"), ""))

        Dim sql As String =
            "SELECT [Id], [AccountName], [BankName], [Mask] " &
            "FROM [dbo].[T143PlaidAccount] " &
            "WHERE [CompanyGUID] = @CompanyGUID AND [Active] = 1 " &
            "ORDER BY [BankName], [AccountName]"

        Using conn As New SqlConnection(ConnectionString)
            conn.Open()
            Using cmd As New SqlCommand(sql, conn)
                cmd.Parameters.Add(New SqlParameter("@CompanyGUID", Company))
                Using rd = cmd.ExecuteReader()
                    While rd.Read()
                        Dim id As String = rd("Id").ToString()
                        Dim accName As String = If(IsDBNull(rd("AccountName")), "", rd("AccountName").ToString())
                        Dim bankName As String = If(IsDBNull(rd("BankName")), "", rd("BankName").ToString())
                        Dim mask As String = If(IsDBNull(rd("Mask")), "", rd("Mask").ToString())

                        ' Texte affiché : "AccountName — BankName ••1234"
                        Dim displayText As String = If(String.IsNullOrEmpty(accName), "(sans nom)", accName)
                        If Not String.IsNullOrEmpty(bankName) Then
                            displayText &= " — " & bankName
                        End If
                        If Not String.IsNullOrEmpty(mask) Then
                            displayText &= " ••" & mask
                        End If

                        cb.Items.Add(New RadComboBoxItem(displayText, id))
                    End While
                End Using
            End Using
        End Using

        ' Sélection courante (l'Id stocké dans iVal)
        If Not String.IsNullOrEmpty(selectedId) AndAlso selectedId <> "0" Then
            cb.SelectedValue = selectedId
        End If

        Return cb
    End Function

    ' =========================================================
    '  VÉRIFICATION DU COURRIEL D'ENTREPRISE (MAIL_FROM_EMAIL)
    '
    '  La VALEUR du courriel reste un paramètre normal (T101, sauvegardé
    '  comme les autres par SaveRepeater). Seul le SUIVI de la vérification
    '  vit dans T010Company (MailVerified*/MailVerify*).
    '
    '  L'état est dérivé par s0693 : l'adresse confirmée doit toujours
    '  correspondre à MAIL_FROM_EMAIL, donc changer le courriel invalide
    '  la vérification d'office.
    ' =========================================================

    ''' <summary>État de vérification (s0693), lu une seule fois par chargement.</summary>
    Private m_MailStatus As DataRow

    Private Function GetMailStatus() As DataRow
        If m_MailStatus IsNot Nothing Then Return m_MailStatus
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0693GetCompanyMailStatus", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                m_MailStatus = ds.Tables(0).Rows(0)
            End If
        Catch
        End Try
        Return m_MailStatus
    End Function

    ''' <summary>
    ''' Champ du paramètre MAIL_FROM_EMAIL : la textbox habituelle (ID "txtValue",
    ''' donc sauvegardée par SaveRepeater comme n'importe quel STRING) plus un
    ''' bouton de vérification et le badge d'état.
    ''' </summary>
    Private Function BuildMailFromEmailField(value As String) As Panel
        Dim pnl As New Panel()

        Dim tb As New RadTextBox()
        tb.ID = "txtValue"
        tb.Width = Unit.Percentage(100)
        tb.MaxLength = 300   ' plafond SaveParamString
        tb.Text = value
        pnl.Controls.Add(tb)

        Dim row As New Panel()
        row.CssClass = "mail-verify-row"

        Dim st As DataRow = GetMailStatus()
        Dim isVerified As Boolean = st IsNot Nothing AndAlso Not IsDBNull(st("IsVerified")) AndAlso CBool(st("IsVerified"))

        Dim btn As New RadButton()
        btn.ID = "btnVerifyMail"
        btn.Text = If(isVerified, L("mailVerifyAgainBtn"), L("mailVerifyBtn"))
        btn.CssClass = "btn"
        btn.AutoPostBack = True
        btn.CausesValidation = False
        AddHandler btn.Click, AddressOf btnVerifyMail_Click
        row.Controls.Add(btn)

        Dim lit As New Literal()
        lit.Text = BuildMailStatusBadge()
        row.Controls.Add(lit)

        pnl.Controls.Add(row)
        Return pnl
    End Function

    ''' <summary>Badge « vérifiée / en attente / non vérifiée » du courriel d'entreprise.</summary>
    Private Function BuildMailStatusBadge() As String
        Dim st As DataRow = GetMailStatus()
        If st Is Nothing Then Return ""

        Dim isVerified As Boolean = Not IsDBNull(st("IsVerified")) AndAlso CBool(st("IsVerified"))
        Dim isPending As Boolean = Not IsDBNull(st("IsPending")) AndAlso CBool(st("IsPending"))

        If isVerified Then
            Dim onDate As String = ""
            If Not IsDBNull(st("VerifiedOn")) Then onDate = " " & CDate(st("VerifiedOn")).ToString("yyyy-MM-dd")
            Return "<span class=""mail-badge ok"">✔ " & Server.HtmlEncode(L("mailVerified") & onDate) & "</span>"
        ElseIf isPending Then
            Return "<span class=""mail-badge pending"">⏳ " & Server.HtmlEncode(L("mailPending")) & "</span>"
        Else
            Return "<span class=""mail-badge no"">✖ " & Server.HtmlEncode(L("mailNotVerified")) & "</span>"
        End If
    End Function

    ''' <summary>
    ''' Bouton « Vérifier » : enregistre l'adresse saisie (on ne vérifie que ce qui
    ''' est réellement en BD), génère un token 24 h via s0691 et dépose le courriel
    ''' dans T400Mails.
    ''' </summary>
    Protected Sub btnVerifyMail_Click(sender As Object, e As EventArgs)
        Dim btn As Control = TryCast(sender, Control)
        If btn Is Nothing Then Return

        Dim item As RepeaterItem = TryCast(btn.NamingContainer, RepeaterItem)
        If item Is Nothing Then Return

        Dim hidParamId As HiddenField = TryCast(item.FindControl("hidParamId"), HiddenField)
        Dim tb As RadTextBox = TryCast(item.FindControl("txtValue"), RadTextBox)
        If hidParamId Is Nothing OrElse tb Is Nothing Then Return

        Dim paramId As Integer = 0
        If Not Integer.TryParse(hidParamId.Value, paramId) OrElse paramId <= 0 Then Return

        Dim email As String = tb.Text.Trim()
        If String.IsNullOrEmpty(email) Then
            ShowErr(L("mailEmpty"))
            Return
        End If
        If Not IsValidEmail(email) Then
            ShowErr(L("mailInvalid"))
            Return
        End If

        Try
            ' 1) Persister l'adresse : le lien doit confirmer la valeur en BD,
            '    pas une saisie non enregistrée.
            SaveParamString(paramId, email)

            ' 2) Token de vérification (24 h)
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Email", email))
            Dim ds As DataSet = ExecuteSQLds("s0691StartCompanyMailVerification", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ShowErr(L("mailSendErr") & "s0691")
                Return
            End If

            Dim r As DataRow = ds.Tables(0).Rows(0)
            If IsDBNull(r("Result")) OrElse CInt(r("Result")) <> 1 OrElse IsDBNull(r("Token")) Then
                ShowErr(L("mailSendErr") & "s0691")
                Return
            End If

            Dim token As Guid = CType(r("Token"), Guid)

            ' 3) Dépôt dans T400Mails (le service SrvAI l'envoie par SMTP)
            SendMailVerification(email, token)

        Catch ex As Exception
            ShowErr(L("mailSendErr") & ex.Message)
            Return
        End Try

        LoadAllSettings()
        LoadCompanyLogo()
        ShowOk(L("mailSent") & email)
    End Sub

    ''' <summary>Insère le courriel de vérification dans T400Mails (BD MailService).</summary>
    Private Sub SendMailVerification(email As String, token As Guid)
        Dim link As String = Request.Url.GetLeftPart(UriPartial.Authority) &
                             ResolveUrl("~/wbfVerifyCompanyMail.aspx") &
                             "?token=" & token.ToString("D") & "&lang=" & CurrentLang

        Dim p As New Collection
        p.Add(New SqlParameter("@To", email))
        p.Add(New SqlParameter("@Subject", L("mailSubject")))
        p.Add(New SqlParameter("@HTMLBody", BuildMailVerificationBody(email, link)))
        p.Add(New SqlParameter("@TextBody", DBNull.Value))

        ExecuteSQLMail("s0610InsertOutboundMail", p)
    End Sub

    Private Function BuildMailVerificationBody(email As String, link As String) As String
        Dim sb As New System.Text.StringBuilder()
        sb.AppendLine("<!DOCTYPE html>")
        sb.AppendLine("<html><body style=""font-family: Arial, sans-serif; background:#f6f7fb; margin:0; padding:20px;"">")
        sb.AppendLine("<div style=""max-width:560px; margin:0 auto; background:#fff; border-radius:16px; overflow:hidden; box-shadow:0 8px 24px rgba(0,0,0,.06);"">")
        sb.AppendLine("<div style=""background: linear-gradient(135deg,#2563eb,#06b6d4); padding:32px; text-align:center;"">")
        sb.AppendLine("<h1 style=""color:#fff; margin:0; font-size:24px; font-weight:800;"">60Sec-AI</h1>")
        sb.AppendLine("<p style=""color:#e0f2fe; margin:6px 0 0 0; font-size:15px;"">" & L("mailHeader") & "</p>")
        sb.AppendLine("</div>")
        sb.AppendLine("<div style=""padding:32px;"">")
        sb.AppendLine("<p style=""margin:0 0 12px 0; font-size:16px; font-weight:700;"">" & L("mailGreeting") & "</p>")
        sb.AppendLine("<p style=""color:#475569; line-height:1.6; margin:0 0 8px 0;"">" & L("mailIntro") & "</p>")
        sb.AppendLine("<p style=""margin:0 0 24px 0; font-weight:700;"">" & Server.HtmlEncode(email) & "</p>")
        sb.AppendLine("<div style=""text-align:center; margin:0 0 24px 0;"">")
        sb.AppendLine("<a href=""" & link & """ style=""display:inline-block; padding:13px 28px; background:#2563eb; color:#fff; border-radius:12px; font-weight:800; text-decoration:none;"">" & L("mailCta") & "</a>")
        sb.AppendLine("</div>")
        sb.AppendLine("<p style=""color:#64748b; font-size:13px; margin:0 0 6px 0;"">" & L("mailExpiry") & "</p>")
        sb.AppendLine("<p style=""color:#64748b; font-size:13px; margin:0;"">" & L("mailIgnore") & "</p>")
        sb.AppendLine("</div></div></body></html>")
        Return sb.ToString()
    End Function

    Private Shared Function IsValidEmail(email As String) As Boolean
        Try
            Dim addr As New System.Net.Mail.MailAddress(email)
            Return addr.Address.Equals(email, StringComparison.OrdinalIgnoreCase) AndAlso email.Contains(".")
        Catch
            Return False
        End Try
    End Function

    ''' <summary>Écrit un paramètre STRING (sVal) via s0151UpdateParamValue.</summary>
    Private Sub SaveParamString(paramId As Integer, value As String)
        Using conn As New SqlConnection(ConnectionString)
            conn.Open()
            Using cmd As New SqlCommand("s0151UpdateParamValue", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.Add(New SqlParameter("@ParamId", SqlDbType.Int) With {.Value = paramId})
                cmd.Parameters.Add(New SqlParameter("@sVal", SqlDbType.VarChar, 300) With {.Value = value})
                cmd.Parameters.Add(New SqlParameter("@iVal", SqlDbType.Int) With {.Value = DBNull.Value})
                cmd.Parameters.Add(New SqlParameter("@dVal", SqlDbType.DateTime) With {.Value = DBNull.Value})
                cmd.Parameters.Add(New SqlParameter("@fVal", SqlDbType.Decimal) With {.Precision = 18, .Scale = 6, .Value = DBNull.Value})
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    ' =========================================================
    '  SAUVEGARDE
    ' =========================================================

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Try
            ' Logo d'abord : si validation échoue, on n'enregistre rien et on informe.
            If Not SaveCompanyLogoFromUpload() Then Return

            SaveRepeater(rpEntreprise)
            SaveRepeater(rpTaxes)
            SaveRepeater(rpEmail)
            SaveRepeater(rpPdf)
            SaveRepeater(rpTraitement)
            SaveRepeater(rpComptabilite)
            SaveRepeater(rpBancaire)

            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0500InitializeCompanyData", p)

            ' Attribue la boîte @60sec.ca maintenant que le nom commercial est connu
            ' (best-effort, non bloquant ; no-op si le nom est encore vide).
            Try
                Dim pm As New Collection
                pm.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
                ExecuteSQLds("s0712AssignMailbox", pm)
            Catch
            End Try

        Catch ex As Exception
            ShowErr(L("saveErr") & ex.Message)
            Return
        End Try

        ' Rafraîchir l'affichage avec les valeurs effectivement en BD
        LoadAllSettings()
        chkRemoveLogo.Checked = False
        LoadCompanyLogo()
        ShowOk(L("savedOk"))
    End Sub

    ' =========================================================
    '  LOGO D'ENTREPRISE (T010Company.Logo)
    ' =========================================================

    ''' <summary>Charge le logo courant (data URI) dans l'aperçu, ou affiche « Aucun logo ».</summary>
    Private Sub LoadCompanyLogo()
        Try
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0690GetCompanyLogo", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                If Not IsDBNull(r("Logo")) Then
                    Dim bytes As Byte() = CType(r("Logo"), Byte())
                    If bytes IsNot Nothing AndAlso bytes.Length > 0 Then
                        Dim ct As String = If(IsDBNull(r("LogoContentType")), "image/png", r("LogoContentType").ToString())
                        imgLogo.ImageUrl = "data:" & ct & ";base64," & Convert.ToBase64String(bytes)
                        imgLogo.Visible = True
                        pnlNoLogo.Visible = False
                        Return
                    End If
                End If
            End If
        Catch
        End Try
        imgLogo.Visible = False
        pnlNoLogo.Visible = True
    End Sub

    ''' <summary>Enregistre ou retire le logo. Retourne False si validation échoue (message affiché).</summary>
    Private Function SaveCompanyLogoFromUpload() As Boolean
        ' Retrait explicite
        If chkRemoveLogo.Checked Then
            Dim pr As New Collection
            pr.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            pr.Add(New SqlClient.SqlParameter("@Logo", DBNull.Value))
            pr.Add(New SqlClient.SqlParameter("@ContentType", DBNull.Value))
            ExecuteSQL("s0689SaveCompanyLogo", pr)
            Return True
        End If

        If Not fuLogo.HasFile Then Return True

        Dim bytes As Byte() = fuLogo.FileBytes
        If bytes Is Nothing OrElse bytes.Length = 0 Then Return True
        If bytes.Length > 1048576 Then
            ShowErr(L("logoTooBig"))
            Return False
        End If

        Dim ct As String = DetectImageContentType()
        If String.IsNullOrEmpty(ct) Then
            ShowErr(L("logoBadType"))
            Return False
        End If

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        Dim pLogo As New SqlClient.SqlParameter("@Logo", SqlDbType.VarBinary, -1) With {.Value = bytes}
        p.Add(pLogo)
        p.Add(New SqlClient.SqlParameter("@ContentType", ct))
        ExecuteSQL("s0689SaveCompanyLogo", p)
        Return True
    End Function

    ''' <summary>Type MIME normalisé du fichier téléversé (PNG/JPEG/SVG), ou "" si non supporté.</summary>
    Private Function DetectImageContentType() As String
        Dim ct As String = If(fuLogo.PostedFile IsNot Nothing, fuLogo.PostedFile.ContentType, "").ToLower()
        Dim ext As String = System.IO.Path.GetExtension(fuLogo.FileName).ToLower()
        If ct = "image/png" OrElse ext = ".png" Then Return "image/png"
        If ct = "image/jpeg" OrElse ct = "image/jpg" OrElse ext = ".jpg" OrElse ext = ".jpeg" Then Return "image/jpeg"
        If ct = "image/svg+xml" OrElse ext = ".svg" Then Return "image/svg+xml"
        Return ""
    End Function

    Protected Sub btnReload_Click(sender As Object, e As EventArgs)
        LoadAllSettings()
        ShowOk(L("reloadedOk"))
    End Sub

    ' =========================================================
    '  HAUT DE PAGE : progression du profil + identité admin
    '  Calculé en OnPreRender (après les événements) pour refléter
    '  l'état sauvegardé le plus récent.
    ' =========================================================
    Protected Overrides Sub OnPreRender(e As EventArgs)
        MyBase.OnPreRender(e)
        LoadProfileHeader()
    End Sub

    Private Sub LoadProfileHeader()
        ' --- Identité de l'administrateur (affichage seulement) ---
        Dim fn As String = If(UserFirstName, "").Trim()
        Dim ln As String = If(UserLastName, "").Trim()
        Dim full As String = (fn & " " & ln).Trim()
        If String.IsNullOrEmpty(full) Then full = If(UserEmail, "").Trim()
        AdminName = Server.HtmlEncode(full)

        Dim company As String = If(CompanyName, "").Trim()
        Dim email As String = If(UserEmail, "").Trim()
        If Not String.IsNullOrEmpty(company) AndAlso Not String.IsNullOrEmpty(email) Then
            AdminMeta = Server.HtmlEncode(company & " · " & email)
        ElseIf Not String.IsNullOrEmpty(email) Then
            AdminMeta = Server.HtmlEncode(email)
        Else
            AdminMeta = Server.HtmlEncode(company)
        End If

        AdminRole = If(IsAccountant, L("roleAccountant"), L("roleAdmin"))

        Dim ini As String = ""
        If fn.Length > 0 Then ini &= fn.Substring(0, 1)
        If ln.Length > 0 Then ini &= ln.Substring(0, 1)
        If ini = "" AndAlso email.Length > 0 Then ini = email.Substring(0, 1)
        AdminInitials = Server.HtmlEncode(ini.ToUpper())

        ' --- Progression du profil ---
        ProfilePct = ComputeProfileProgress()
    End Sub

    ''' <summary>% de complétion du profil = champs remplis / total sur les onglets
    ''' Entreprise et Taxes (valeurs de la compagnie).</summary>
    Private Function ComputeProfileProgress() As Integer
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0150GetParamsForCompany", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return 0

            Dim total As Integer = 0, filled As Integer = 0
            For Each r As DataRow In ds.Tables(0).Rows
                Dim cat As String = If(IsDBNull(r("Categorie")), "", r("Categorie").ToString()).ToUpper()
                If cat <> "ENTREPRISE" AndAlso cat <> "TAXES" Then Continue For
                total += 1
                If IsParamFilled(r) Then filled += 1
            Next

            If total = 0 Then Return 0
            Return CInt(Math.Round(filled / total * 100.0))
        Catch
            Return 0
        End Try
    End Function

    Private Shared Function IsParamFilled(r As DataRow) As Boolean
        If r.Table.Columns.Contains("sVal") AndAlso Not IsDBNull(r("sVal")) AndAlso Not String.IsNullOrWhiteSpace(r("sVal").ToString()) Then Return True
        If r.Table.Columns.Contains("iVal") AndAlso Not IsDBNull(r("iVal")) Then Return True
        If r.Table.Columns.Contains("dVal") AndAlso Not IsDBNull(r("dVal")) Then Return True
        If r.Table.Columns.Contains("fVal") AndAlso Not IsDBNull(r("fVal")) Then Return True
        Return False
    End Function

    ' =====================================================================
    ' SCAN DE DOCUMENT : extraction IA (OpenAI) → remplit les champs VIDES
    ' des onglets Entreprise / Taxes. L'utilisateur révise puis clique Enregistrer.
    ' =====================================================================
    Protected Async Sub btnScanExtract_Click(sender As Object, e As EventArgs) Handles btnScanExtract.Click

        If Not fileDocScan.HasFile Then
            ShowScanMsg(L("upChoose"))
            Return
        End If

        Try
            Dim bytes As Byte() = fileDocScan.FileBytes
            If bytes Is Nothing OrElse bytes.Length = 0 Then
                ShowScanMsg(L("upEmpty"))
                Return
            End If

            Dim fileName As String = If(fileDocScan.FileName, "").ToLowerInvariant()
            Dim ct As String = If(fileDocScan.PostedFile IsNot Nothing, If(fileDocScan.PostedFile.ContentType, ""), "").ToLowerInvariant()

            Dim apiKey As String = GetChatGptKey()
            If String.IsNullOrEmpty(apiKey) Then
                ShowScanMsg(L("upNoKey"))
                Return
            End If

            Dim reader As New OpenAiReceiptReader(apiKey)
            Dim json As String

            If ct.Contains("pdf") OrElse fileName.EndsWith(".pdf") Then
                Dim res = Await reader.ParseInvoicePdfAsync(bytes, EXTRACT_PROMPT_COMPANY)
                json = res.JsonText
            ElseIf ct.StartsWith("image") OrElse fileName.EndsWith(".jpg") OrElse fileName.EndsWith(".jpeg") OrElse fileName.EndsWith(".png") Then
                Dim mime As String = If(ct.StartsWith("image"), ct, If(fileName.EndsWith(".png"), "image/png", "image/jpeg"))
                Dim res = Await reader.ReadReceiptAsJsonAsync(bytes, mime, EXTRACT_PROMPT_COMPANY)
                json = res.JsonResult
            Else
                ShowScanMsg(L("upFormat"))
                Return
            End If

            Dim n As Integer = FillSettingsFromJson(json)
            If n > 0 Then
                ShowScanMsg(String.Format(L("upFilled"), n))
            Else
                ShowScanMsg(L("upNone"))
            End If

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("wbfSetting scan error: " & ex.Message)
            ShowScanMsg(L("upError"))
        End Try
    End Sub

    ''' <summary>
    ''' Remplit les champs (contrôles txtValue) des onglets Entreprise et Taxes
    ''' à partir du JSON, UNIQUEMENT quand le champ est vide. Mapping par ShortName.
    ''' Retourne le nombre de champs remplis.
    ''' </summary>
    Private Function FillSettingsFromJson(json As String) As Integer
        If String.IsNullOrWhiteSpace(json) Then Return 0

        Dim iStart As Integer = json.IndexOf("{"c)
        Dim iEnd As Integer = json.LastIndexOf("}"c)
        If iStart < 0 OrElse iEnd <= iStart Then Return 0

        Dim jo As JObject
        Try
            jo = JObject.Parse(json.Substring(iStart, iEnd - iStart + 1))
        Catch
            Return 0
        End Try

        ' Mapping ShortName -> clé JSON
        Dim map As New Dictionary(Of String, String) From {
            {"LEGAL_NAME", "legal_name"},
            {"TRADE_NAME", "trade_name"},
            {"NEQ", "neq"},
            {"PHONE", "phone"},
            {"ADDR1", "address1"},
            {"ADDR2", "address2"},
            {"CITY", "city"},
            {"PROVINCE", "province"},
            {"POSTAL", "postal_code"},
            {"COUNTRY", "country"},
            {"GST_NO", "gst_number"},
            {"QST_NO", "qst_number"}
        }

        Dim n As Integer = 0
        n += FillRepeater(rpEntreprise, jo, map)
        n += FillRepeater(rpTaxes, jo, map)
        Return n
    End Function

    Private Function FillRepeater(rp As Repeater, jo As JObject, map As Dictionary(Of String, String)) As Integer
        Dim n As Integer = 0
        For Each item As RepeaterItem In rp.Items
            If item.ItemType <> ListItemType.Item AndAlso item.ItemType <> ListItemType.AlternatingItem Then Continue For

            Dim hidShort As HiddenField = TryCast(item.FindControl("hidShortName"), HiddenField)
            Dim ph As PlaceHolder = TryCast(item.FindControl("phControl"), PlaceHolder)
            If hidShort Is Nothing OrElse ph Is Nothing Then Continue For

            Dim sn As String = If(hidShort.Value, "").Trim().ToUpper()
            Dim jsonKey As String = Nothing
            If Not map.TryGetValue(sn, jsonKey) Then Continue For

            Dim val As String = J(jo, jsonKey)
            If String.IsNullOrWhiteSpace(val) Then Continue For

            Dim ctrl As Control = ph.FindControl("txtValue")
            If ctrl Is Nothing Then Continue For

            If TypeOf ctrl Is RadTextBox Then
                Dim tb As RadTextBox = CType(ctrl, RadTextBox)
                If String.IsNullOrWhiteSpace(tb.Text) Then
                    tb.Text = val.Trim()
                    n += 1
                End If
            ElseIf TypeOf ctrl Is RadComboBox Then
                ' Ex. PROVINCE : sélection au mieux par texte (si vide et correspondance trouvée)
                Dim cb As RadComboBox = CType(ctrl, RadComboBox)
                If String.IsNullOrEmpty(cb.SelectedValue) Then
                    Dim match As RadComboBoxItem = cb.FindItemByText(val.Trim())
                    If match IsNot Nothing Then
                        match.Selected = True
                        n += 1
                    End If
                End If
            End If
        Next
        Return n
    End Function

    Private Shared Function J(jo As JObject, key As String) As String
        Dim t As JToken = jo(key)
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return ""
        Return t.ToString().Trim()
    End Function

    Private Sub ShowScanMsg(msg As String)
        pnlScanMsg.Visible = True
        litScanMsg.Text = Server.HtmlEncode(msg)
    End Sub

    Private Function GetChatGptKey() As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Parameter", "CHATGPT"))
            Dim ds As DataSet = ExecuteSQLds("s0000GetParameter", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return ds.Tables(0).Rows(0)("Value").ToString()
            End If
        Catch
        End Try
        Return ""
    End Function

    ''' <summary>
    ''' Boucle sur les items d'un Repeater et appelle s0151UpdateParamValue
    ''' pour chaque ligne en récupérant la valeur du contrôle dynamique.
    ''' </summary>
    Private Sub SaveRepeater(rp As Repeater)
        Using conn As New SqlConnection(ConnectionString)
            conn.Open()

            For Each item As RepeaterItem In rp.Items
                If item.ItemType <> ListItemType.Item AndAlso item.ItemType <> ListItemType.AlternatingItem Then Continue For

                Dim hidParamId As HiddenField = TryCast(item.FindControl("hidParamId"), HiddenField)
                Dim hidParamType As HiddenField = TryCast(item.FindControl("hidParamType"), HiddenField)
                Dim phControl As PlaceHolder = TryCast(item.FindControl("phControl"), PlaceHolder)

                If hidParamId Is Nothing OrElse phControl Is Nothing Then Continue For

                Dim paramId As Integer = 0
                If Not Integer.TryParse(hidParamId.Value, paramId) Then Continue For
                If paramId <= 0 Then Continue For

                Dim paramType As String = If(hidParamType IsNot Nothing, hidParamType.Value.ToUpper(), "STRING")

                ' Récupérer le contrôle "txtValue" injecté dans le PlaceHolder
                Dim ctrl As Control = phControl.FindControl("txtValue")
                If ctrl Is Nothing Then Continue For

                Dim sVal As Object = DBNull.Value
                Dim iVal As Object = DBNull.Value
                Dim dVal As Object = DBNull.Value   ' miroir typé (DATE)
                Dim fVal As Object = DBNull.Value   ' miroir typé (DECIMAL/float)

                ' Extraction de la valeur selon le type de contrôle
                If TypeOf ctrl Is RadNumericTextBox Then
                    Dim ntb As RadNumericTextBox = CType(ctrl, RadNumericTextBox)
                    If ntb.Value.HasValue Then
                        Select Case paramType
                            Case "INT", "INTEGER"
                                iVal = CInt(ntb.Value.Value)
                            Case Else
                                ' DECIMAL : stockée UNIQUEMENT dans la colonne typée fVal (sVal reste NULL)
                                fVal = CDec(ntb.Value.Value)
                        End Select
                    End If
                ElseIf TypeOf ctrl Is RadDatePicker Then
                    ' DATE : stockée UNIQUEMENT dans la colonne typée dVal (sVal reste NULL)
                    Dim dp As RadDatePicker = CType(ctrl, RadDatePicker)
                    If dp.SelectedDate.HasValue Then
                        dVal = dp.SelectedDate.Value
                    End If
                ElseIf TypeOf ctrl Is RadComboBox Then
                    Dim cb As RadComboBox = CType(ctrl, RadComboBox)
                    Dim selected As String = If(cb.SelectedValue, "")
                    If paramType = "BOOL" OrElse paramType = "BOOLEAN" Then
                        Dim ival2 As Integer = 0
                        Integer.TryParse(selected, ival2)
                        iVal = ival2
                    ElseIf paramType = "INT" OrElse paramType = "INTEGER" Then
                        ' Combo avec valeur entière (ex: COMPTE_BANQUE → Id du compte)
                        Dim ival2 As Integer = 0
                        If Not String.IsNullOrEmpty(selected) AndAlso Integer.TryParse(selected, ival2) Then
                            iVal = ival2
                        End If
                    Else
                        sVal = If(String.IsNullOrEmpty(selected), CType(DBNull.Value, Object), selected)
                    End If
                ElseIf TypeOf ctrl Is RadTextBox Then
                    Dim tb As RadTextBox = CType(ctrl, RadTextBox)
                    Dim text As String = tb.Text.Trim()

                    If paramType = "INT" OrElse paramType = "INTEGER" Then
                        Dim ival2 As Integer = 0
                        If Integer.TryParse(text, ival2) Then iVal = ival2
                    Else
                        sVal = If(String.IsNullOrEmpty(text), CType(DBNull.Value, Object), text)
                    End If
                End If

                Using cmd As New SqlCommand("s0151UpdateParamValue", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.Add(New SqlParameter("@ParamId", SqlDbType.Int) With {.Value = paramId})
                    cmd.Parameters.Add(New SqlParameter("@sVal", SqlDbType.VarChar, 300) With {.Value = sVal})
                    cmd.Parameters.Add(New SqlParameter("@iVal", SqlDbType.Int) With {.Value = iVal})
                    cmd.Parameters.Add(New SqlParameter("@dVal", SqlDbType.DateTime) With {.Value = dVal})
                    cmd.Parameters.Add(New SqlParameter("@fVal", SqlDbType.Decimal) With {.Precision = 18, .Scale = 6, .Value = fVal})
                    cmd.ExecuteNonQuery()
                End Using
            Next
        End Using
    End Sub

    ' =========================================================
    '  ACTIONS
    ' =========================================================

    Private Sub ShowOk(msg As String)
        phStatus.Visible = True
        litStatus.Text = "<span class=""status-ok"">✔ " & Server.HtmlEncode(msg) & "</span>"
    End Sub

    Private Sub ShowErr(msg As String)
        phStatus.Visible = True
        litStatus.Text = "<span class=""status-err"">✖ " & Server.HtmlEncode(msg) & "</span>"
    End Sub

    Private Sub btnSave_PreRender(sender As Object, e As EventArgs) Handles btnSave.PreRender

    End Sub
End Class
