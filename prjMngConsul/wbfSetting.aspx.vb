Imports System.Data.SqlClient
Imports Telerik.Web.UI

Partial Public Class wbfSetting
    Inherits clsData

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
    End Sub

    ''' <summary>Applique la langue courante aux contrôles serveur (titre, boutons, onglets).</summary>
    Private Sub ApplyLocalization()
        Page.Title = L("pageTitle")
        btnSave.Text = L("save")
        btnReload.Text = L("reload")
        If tsSettings.Tabs.Count >= 7 Then
            tsSettings.Tabs(0).Text = L("tabCompany")
            tsSettings.Tabs(1).Text = L("tabTaxes")
            tsSettings.Tabs(2).Text = L("tabEmail")
            tsSettings.Tabs(3).Text = L("tabPdf")
            tsSettings.Tabs(4).Text = L("tabAccounting")
            tsSettings.Tabs(5).Text = L("tabBank")
            tsSettings.Tabs(6).Text = L("tabAccountant")
        End If
    End Sub

    ''' <summary>Traductions de l'interface des paramètres (fr/en/es). Les LIBELLÉS des
    ''' paramètres viennent de la BD (T102ParamI18n via s0150) ; ici : chrome + combos.</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Paramètres — 60Sec-AI", "Settings — 60Sec-AI", "Ajustes — 60Sec-AI")
            Case "pageTitleShort" : Return Choose3(lang, "Paramètres", "Settings", "Ajustes")
            Case "pageSub" : Return Choose3(lang, "Entreprise, taxes, courriels, PDF et comptabilité.", "Company, taxes, emails, PDF and accounting.", "Empresa, impuestos, correos, PDF y contabilidad.")
            Case "save" : Return Choose3(lang, "Enregistrer", "Save", "Guardar")
            Case "reload" : Return Choose3(lang, "Recharger", "Reload", "Recargar")
            Case "tabCompany" : Return Choose3(lang, "Entreprise", "Company", "Empresa")
            Case "tabTaxes" : Return Choose3(lang, "Taxes", "Taxes", "Impuestos")
            Case "tabEmail" : Return Choose3(lang, "Email", "Email", "Correo")
            Case "tabPdf" : Return Choose3(lang, "PDF", "PDF", "PDF")
            Case "tabAccounting" : Return Choose3(lang, "Comptabilité", "Accounting", "Contabilidad")
            Case "tabBank" : Return Choose3(lang, "Bancaire", "Banking", "Bancario")
            Case "tabAccountant" : Return Choose3(lang, "Comptable", "Accountant", "Contador")
            Case "introAccounting" : Return Choose3(lang, "Comptes par défaut utilisés par les modules de comptabilisation automatique.", "Default accounts used by the automatic bookkeeping modules.", "Cuentas predeterminadas usadas por los módulos de contabilización automática.")
            Case "introBank" : Return Choose3(lang, "Comptes bancaires connectés via Plaid. Sélectionnez le compte par défaut utilisé pour les encaissements et décaissements.", "Bank accounts connected via Plaid. Select the default account used for cash-ins and cash-outs.", "Cuentas bancarias conectadas mediante Plaid. Seleccione la cuenta predeterminada para cobros y pagos.")
            Case "introAccountant" : Return Choose3(lang, "Clé pour votre comptable afin qu'il puisse accéder à vos données comptables sans être utilisateur de votre compte 60Sec-AI.", "Key for your accountant so they can access your accounting data without being a user of your 60Sec-AI account.", "Clave para su contador para que pueda acceder a sus datos contables sin ser usuario de su cuenta 60Sec-AI.")
            Case "emptyTab" : Return Choose3(lang, "Aucun paramètre configuré pour cet onglet.", "No parameter configured for this tab.", "Ningún parámetro configurado para esta pestaña.")
            Case "savedOk" : Return Choose3(lang, "Paramètres enregistrés.", "Settings saved.", "Ajustes guardados.")
            Case "reloadedOk" : Return Choose3(lang, "Paramètres rechargés.", "Settings reloaded.", "Ajustes recargados.")
            Case "saveErr" : Return Choose3(lang, "Erreur lors de la sauvegarde : ", "Error while saving: ", "Error al guardar: ")
            Case "boolYes" : Return Choose3(lang, "Oui", "Yes", "Sí")
            Case "boolNo" : Return Choose3(lang, "Non", "No", "No")
            Case "roundCent" : Return Choose3(lang, "2 décimales (cent)", "2 decimals (cent)", "2 decimales (centavo)")
            Case "roundInternal" : Return Choose3(lang, "4 décimales (interne)", "4 decimals (internal)", "4 decimales (interno)")
            Case "roundTrunc" : Return Choose3(lang, "Tronquer (2 décimales)", "Truncate (2 decimals)", "Truncar (2 decimales)")
            Case "taxExclusive" : Return Choose3(lang, "Taxes en sus", "Taxes added", "Impuestos aparte")
            Case "taxInclusive" : Return Choose3(lang, "Taxes incluses", "Taxes included", "Impuestos incluidos")
            Case "bankNone" : Return Choose3(lang, "(Aucun compte)", "(No account)", "(Sin cuenta)")
            Case "bankPick" : Return Choose3(lang, "-- Sélectionnez un compte --", "-- Select an account --", "-- Seleccione una cuenta --")
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
        BindCategory("ENTREPRISE", rpEntreprise, pnlEmptyEntreprise)
        BindCategory("TAXES", rpTaxes, pnlEmptyTaxes)
        BindCategory("EMAIL", rpEmail, pnlEmptyEmail)
        BindCategory("PDF", rpPdf, pnlEmptyPdf)
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
            Case "COMPTE_BANQUE"
                ' Combo dynamique alimenté depuis T143PlaidAccount
                ' La valeur sélectionnée est l'Id du compte (stocké dans iVal)
                phControl.Controls.Add(BuildCompteBanqueCombo(iVal))
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
        tb.Text = value
        Return tb
    End Function

    Private Function BuildMultilineTextbox(value As String) As RadTextBox
        Dim tb As New RadTextBox()
        tb.ID = "txtValue"
        tb.Width = Unit.Percentage(100)
        tb.TextMode = InputMode.MultiLine
        tb.Rows = 4
        tb.Text = value
        Return tb
    End Function

    Private Function BuildPasswordTextbox(value As String) As RadTextBox
        Dim tb As New RadTextBox()
        tb.ID = "txtValue"
        tb.Width = Unit.Percentage(100)
        tb.TextMode = InputMode.Password
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
    '  SAUVEGARDE
    ' =========================================================

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Try
            SaveRepeater(rpEntreprise)
            SaveRepeater(rpTaxes)
            SaveRepeater(rpEmail)
            SaveRepeater(rpPdf)
            SaveRepeater(rpComptabilite)
            SaveRepeater(rpBancaire)

            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0500InitializeCompanyData", p)


        Catch ex As Exception
            ShowErr(L("saveErr") & ex.Message)
            Return
        End Try

        ' Rafraîchir l'affichage avec les valeurs effectivement en BD
        LoadAllSettings()
        ShowOk(L("savedOk"))
    End Sub

    Protected Sub btnReload_Click(sender As Object, e As EventArgs)
        LoadAllSettings()
        ShowOk(L("reloadedOk"))
    End Sub

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
