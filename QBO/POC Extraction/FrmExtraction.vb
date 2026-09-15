Imports System.Globalization

''' <summary>
''' La fenêtre : se connecter à QuickBooks Online, régler les dates et le
''' dossier, puis extraire — un bouton par fichier, ou tout d'un coup.
''' </summary>
Public Class FrmExtraction
    Inherits Form

    Private ReadOnly _param As Parametres = Parametres.Charger()
    Private _jeton As New JetonQbo()
    Private _annulation As CancellationTokenSource
    Private ReadOnly _boutons As New Dictionary(Of Button, Extraction)
    Private ReadOnly _bulles As New ToolTip() With {.AutoPopDelay = 15000}

    Private txtClientId, txtSecret, txtRedirect, txtRealm, txtRefresh, txtDossier, txtJournal As TextBox
    Private cboEnv, cboSep, cboMethode As ComboBox
    Private dtpDebut, dtpBascule As DateTimePicker
    Private chkFiltrer As CheckBox
    Private btnConnecter, btnTester, btnDossier, btnOuvrir, btnTout, btnAnnuler As Button
    Private lblEtat As Label
    Private barre As ProgressBar

    Public Sub New()
        Text = "Extraction QuickBooks Online → CSV · MngConsul"
        Font = New Font("Segoe UI", 9.0F)
        StartPosition = FormStartPosition.CenterScreen
        MinimumSize = New Size(1100, 760)
        Size = New Size(1280, 900)

        Construire()
        ChargerReglages()
    End Sub

#Region "Construction de la fenêtre"

    Private Sub Construire()
        Dim racine As New TableLayoutPanel With {.Dock = DockStyle.Fill, .ColumnCount = 1, .RowCount = 4, .Padding = New Padding(10)}
        racine.RowStyles.Add(New RowStyle(SizeType.AutoSize))
        racine.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100))
        racine.RowStyles.Add(New RowStyle(SizeType.Percent, 72))
        racine.RowStyles.Add(New RowStyle(SizeType.AutoSize))
        racine.RowStyles.Add(New RowStyle(SizeType.Percent, 28))
        Controls.Add(racine)

        ' ── 1 · Connexion et 2 · Options, côte à côte ──────────────────────
        Dim haut As New TableLayoutPanel With {.Dock = DockStyle.Fill, .ColumnCount = 2, .AutoSize = True}
        haut.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 58))
        haut.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 42))
        haut.Controls.Add(ConstruireConnexion(), 0, 0)
        haut.Controls.Add(ConstruireOptions(), 1, 0)
        racine.Controls.Add(haut, 0, 0)

        ' ── 3 · Extraction : une colonne par catégorie ─────────────────────
        Dim grpExt As New GroupBox With {.Text = "3 · Extraction — un bouton par fichier", .Dock = DockStyle.Fill, .Padding = New Padding(8)}
        Dim grille As New TableLayoutPanel With {.Dock = DockStyle.Fill, .ColumnCount = Catalogue.Categories.Length, .RowCount = 1}
        For i = 0 To Catalogue.Categories.Length - 1
            grille.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100.0F / Catalogue.Categories.Length))
        Next

        Dim extractions = Catalogue.Toutes()
        For i = 0 To Catalogue.Categories.Length - 1
            Dim categorie = Catalogue.Categories(i)
            Dim grp As New GroupBox With {.Text = categorie, .Dock = DockStyle.Fill}
            Dim pile As New FlowLayoutPanel With {.Dock = DockStyle.Fill, .FlowDirection = FlowDirection.TopDown, .WrapContents = False, .AutoScroll = True}

            For Each ext In extractions.Where(Function(x) x.Categorie = categorie)
                Dim b As New Button With {.Text = ext.Libelle, .Width = 205, .Height = 28, .TextAlign = ContentAlignment.MiddleLeft, .Margin = New Padding(3, 2, 3, 2)}
                _bulles.SetToolTip(b, ext.Fichiers & If(ext.Rapport <> "", " — rapport " & ext.Rapport, " — entité " & ext.Entite))
                AddHandler b.Click, AddressOf BoutonExtraction_Click
                AddHandler pile.Resize, Sub(s, e) b.Width = Math.Max(150, pile.ClientSize.Width - 10)
                _boutons.Add(b, ext)
                pile.Controls.Add(b)
            Next

            grp.Controls.Add(pile)
            grille.Controls.Add(grp, i, 0)
        Next
        grpExt.Controls.Add(grille)
        racine.Controls.Add(grpExt, 0, 1)

        ' ── Tout extraire, annuler, progression ────────────────────────────
        Dim barreActions As New FlowLayoutPanel With {.Dock = DockStyle.Fill, .AutoSize = True, .WrapContents = False}
        btnTout = New Button With {.Text = "Tout extraire", .Width = 150, .Height = 32, .Font = New Font(Font, FontStyle.Bold)}
        btnAnnuler = New Button With {.Text = "Annuler", .Width = 100, .Height = 32, .Enabled = False}
        barre = New ProgressBar With {.Width = 420, .Height = 20, .Margin = New Padding(12, 9, 3, 3)}
        AddHandler btnTout.Click, AddressOf BtnTout_Click
        AddHandler btnAnnuler.Click, Sub(s, e) _annulation?.Cancel()
        barreActions.Controls.AddRange({btnTout, btnAnnuler, barre})
        racine.Controls.Add(barreActions, 0, 2)

        ' ── Journal ────────────────────────────────────────────────────────
        txtJournal = New TextBox With {.Dock = DockStyle.Fill, .Multiline = True, .ReadOnly = True, .ScrollBars = ScrollBars.Both,
                                       .WordWrap = False, .Font = New Font("Consolas", 9.0F), .BackColor = Color.White}
        racine.Controls.Add(txtJournal, 0, 3)

        AddHandler FormClosing, Sub(s, e) EnregistrerReglages()
    End Sub

    Private Function ConstruireConnexion() As Control
        Dim grp As New GroupBox With {.Text = "1 · Connexion à QuickBooks Online", .Dock = DockStyle.Fill, .AutoSize = True, .Padding = New Padding(8)}
        Dim t = Grille4()

        txtClientId = New TextBox With {.Dock = DockStyle.Fill}
        txtSecret = New TextBox With {.Dock = DockStyle.Fill, .UseSystemPasswordChar = True}
        cboEnv = New ComboBox With {.Dock = DockStyle.Fill, .DropDownStyle = ComboBoxStyle.DropDownList}
        cboEnv.Items.AddRange({"Sandbox", "Production"})
        txtRedirect = New TextBox With {.Dock = DockStyle.Fill}
        txtRealm = New TextBox With {.Dock = DockStyle.Fill}
        txtRefresh = New TextBox With {.Dock = DockStyle.Fill, .UseSystemPasswordChar = True}

        Champ(t, "Client ID", txtClientId, 0, 0)
        Champ(t, "Environnement", cboEnv, 2, 0)
        Champ(t, "Client Secret", txtSecret, 0, 1)
        Champ(t, "URI de redirection", txtRedirect, 2, 1)
        Champ(t, "Realm ID (société)", txtRealm, 0, 2)
        Champ(t, "Refresh token", txtRefresh, 2, 2)

        _bulles.SetToolTip(txtRedirect, "Doit être inscrite telle quelle dans l'application Intuit (onglet Keys & credentials ▸ Redirect URIs).")
        _bulles.SetToolTip(txtRefresh, "Rempli par « Se connecter ». Vous pouvez aussi coller un jeton obtenu dans l'OAuth 2.0 Playground d'Intuit, avec son Realm ID.")

        Dim actions As New FlowLayoutPanel With {.Dock = DockStyle.Fill, .AutoSize = True, .WrapContents = False}
        btnConnecter = New Button With {.Text = "Se connecter à QuickBooks…", .Width = 200, .Height = 30}
        btnTester = New Button With {.Text = "Tester la connexion", .Width = 150, .Height = 30}
        lblEtat = New Label With {.AutoSize = True, .Margin = New Padding(10, 8, 3, 3), .Text = "Non connecté."}
        AddHandler btnConnecter.Click, AddressOf BtnConnecter_Click
        AddHandler btnTester.Click, AddressOf BtnTester_Click
        actions.Controls.AddRange({btnConnecter, btnTester, lblEtat})
        t.Controls.Add(actions, 0, 3)
        t.SetColumnSpan(actions, 4)

        grp.Controls.Add(t)
        Return grp
    End Function

    Private Function ConstruireOptions() As Control
        Dim grp As New GroupBox With {.Text = "2 · Options", .Dock = DockStyle.Fill, .AutoSize = True, .Padding = New Padding(8)}
        Dim t = Grille4()

        Dim ligneDossier As New TableLayoutPanel With {.Dock = DockStyle.Fill, .ColumnCount = 3, .AutoSize = True, .Margin = New Padding(0)}
        ligneDossier.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100))
        ligneDossier.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))
        ligneDossier.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))
        txtDossier = New TextBox With {.Dock = DockStyle.Fill}
        btnDossier = New Button With {.Text = "…", .Width = 32, .Height = 25}
        btnOuvrir = New Button With {.Text = "Ouvrir", .Width = 60, .Height = 25}
        AddHandler btnDossier.Click, AddressOf BtnDossier_Click
        AddHandler btnOuvrir.Click, AddressOf BtnOuvrir_Click
        ligneDossier.Controls.Add(txtDossier, 0, 0)
        ligneDossier.Controls.Add(btnDossier, 1, 0)
        ligneDossier.Controls.Add(btnOuvrir, 2, 0)

        t.Controls.Add(Libelle("Dossier de sortie"), 0, 0)
        t.Controls.Add(ligneDossier, 1, 0)
        t.SetColumnSpan(ligneDossier, 3)

        dtpDebut = New DateTimePicker With {.Format = DateTimePickerFormat.Short, .Dock = DockStyle.Fill}
        dtpBascule = New DateTimePicker With {.Format = DateTimePickerFormat.Short, .Dock = DockStyle.Fill}
        Champ(t, "Début de l'exercice", dtpDebut, 0, 1)
        Champ(t, "Date de bascule", dtpBascule, 2, 1)
        _bulles.SetToolTip(dtpDebut, "Début de la période des rapports (état des résultats, grand livre, balance), et date de départ des transactions si le filtre est coché.")
        _bulles.SetToolTip(dtpBascule, "Date de fin des rapports : balance de vérification, balances âgées, bilan. La veille du premier jour tenu dans MngConsul.")

        cboSep = New ComboBox With {.Dock = DockStyle.Fill, .DropDownStyle = ComboBoxStyle.DropDownList}
        cboSep.Items.AddRange({"Point-virgule ;", "Virgule ,"})
        cboMethode = New ComboBox With {.Dock = DockStyle.Fill, .DropDownStyle = ComboBoxStyle.DropDownList}
        cboMethode.Items.AddRange({"Exercice (Accrual)", "Caisse (Cash)"})
        Champ(t, "Séparateur CSV", cboSep, 0, 2)
        Champ(t, "Méthode comptable", cboMethode, 2, 2)

        chkFiltrer = New CheckBox With {.Text = "Transactions depuis le début de l'exercice seulement", .AutoSize = True}
        t.Controls.Add(chkFiltrer, 0, 3)
        t.SetColumnSpan(chkFiltrer, 4)

        grp.Controls.Add(t)
        Return grp
    End Function

    Private Shared Function Grille4() As TableLayoutPanel
        Dim t As New TableLayoutPanel With {.Dock = DockStyle.Fill, .ColumnCount = 4, .RowCount = 4, .AutoSize = True}
        t.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))
        t.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 50))
        t.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))
        t.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 50))
        Return t
    End Function

    Private Shared Sub Champ(t As TableLayoutPanel, texte As String, ctrl As Control, col As Integer, rang As Integer)
        t.Controls.Add(Libelle(texte), col, rang)
        t.Controls.Add(ctrl, col + 1, rang)
    End Sub

    Private Shared Function Libelle(texte As String) As Label
        Return New Label With {.Text = texte, .AutoSize = True, .Anchor = AnchorStyles.Left, .Margin = New Padding(3, 7, 8, 3)}
    End Function

#End Region

#Region "Réglages"

    Private Sub ChargerReglages()
        txtClientId.Text = _param.ClientId
        txtSecret.Text = Parametres.Devoiler(_param.ClientSecretProtege)
        cboEnv.SelectedItem = If(_param.Environnement = "Production", "Production", "Sandbox")
        txtRedirect.Text = _param.RedirectUri
        txtRealm.Text = _param.RealmId
        txtRefresh.Text = Parametres.Devoiler(_param.RefreshTokenProtege)
        _jeton = New JetonQbo With {.RefreshToken = txtRefresh.Text}

        txtDossier.Text = If(_param.DossierSortie <> "", _param.DossierSortie,
                             Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "Extraction QBO"))
        cboSep.SelectedIndex = If(_param.Separateur = ",", 1, 0)
        cboMethode.SelectedIndex = If(_param.MethodeComptable = "Cash", 1, 0)

        Dim finMoisDernier = New Date(Today.Year, Today.Month, 1).AddDays(-1)
        dtpBascule.Value = If(_param.DateBascule, finMoisDernier)
        dtpDebut.Value = If(_param.DateDebut, New Date(dtpBascule.Value.Year, 1, 1))
        chkFiltrer.Checked = _param.FiltrerTransactions

        If txtRefresh.Text <> "" AndAlso txtRealm.Text <> "" Then lblEtat.Text = "Jeton enregistré — « Tester la connexion » pour vérifier."
    End Sub

    Private Sub EnregistrerReglages()
        _param.ClientId = txtClientId.Text.Trim()
        _param.ClientSecretProtege = Parametres.Proteger(txtSecret.Text.Trim())
        _param.Environnement = CStr(cboEnv.SelectedItem)
        _param.RedirectUri = txtRedirect.Text.Trim()
        _param.RealmId = txtRealm.Text.Trim()
        _param.RefreshTokenProtege = Parametres.Proteger(txtRefresh.Text.Trim())
        _param.DossierSortie = txtDossier.Text.Trim()
        _param.Separateur = If(cboSep.SelectedIndex = 1, ",", ";")
        _param.MethodeComptable = If(cboMethode.SelectedIndex = 1, "Cash", "Accrual")
        _param.DateDebut = dtpDebut.Value.Date
        _param.DateBascule = dtpBascule.Value.Date
        _param.FiltrerTransactions = chkFiltrer.Checked
        Try
            _param.Enregistrer()
        Catch ex As Exception
            Journal("⚠ Réglages non enregistrés : " & ex.Message)
        End Try
    End Sub

#End Region

#Region "Connexion"

    Private Async Sub BtnConnecter_Click(sender As Object, e As EventArgs)
        If Not VerifierCles() Then Return

        Occupe(True)
        lblEtat.Text = "Autorisez l'accès dans le navigateur qui vient de s'ouvrir…"
        _annulation = New CancellationTokenSource()
        Try
            Dim res = Await QboAuth.ConnecterAsync(txtClientId.Text.Trim(), txtSecret.Text.Trim(), txtRedirect.Text.Trim(), _annulation.Token)
            _jeton = res.Jeton
            txtRealm.Text = res.RealmId
            txtRefresh.Text = res.Jeton.RefreshToken
            EnregistrerReglages()
            Journal($"✔ Connecté à la société {res.RealmId}.")
            Await TesterAsync()
        Catch ex As OperationCanceledException
            lblEtat.Text = "Connexion annulée."
        Catch ex As Exception
            lblEtat.Text = "Échec de la connexion."
            Journal("✖ Connexion : " & ex.Message)
        Finally
            Occupe(False)
        End Try
    End Sub

    Private Async Sub BtnTester_Click(sender As Object, e As EventArgs)
        If Not VerifierCles() OrElse Not VerifierJeton() Then Return
        Occupe(True)
        _annulation = New CancellationTokenSource()
        Try
            Await TesterAsync()
        Catch ex As Exception
            lblEtat.Text = "Échec du test."
            Journal("✖ Test : " & ex.Message)
        Finally
            Occupe(False)
        End Try
    End Sub

    Private Async Function TesterAsync() As Task
        Dim client = CreerClient()
        Dim rep = Await client.GetAsync($"/v3/company/{client.RealmId}/companyinfo/{client.RealmId}", _annulation.Token)
        Dim nom = JsonChemin.Valeur(rep, "CompanyInfo.CompanyName")
        lblEtat.Text = $"Connecté : {nom} ({CStr(cboEnv.SelectedItem)})"
        Journal($"✔ Connexion vérifiée : {nom}, société {client.RealmId}.")
    End Function

    Private Function CreerClient() As QboClient
        If _jeton.RefreshToken <> txtRefresh.Text.Trim() Then
            _jeton = New JetonQbo With {.RefreshToken = txtRefresh.Text.Trim()}
        End If

        Dim client As New QboClient(txtClientId.Text.Trim(), txtSecret.Text.Trim(), txtRealm.Text.Trim(),
                                    CStr(cboEnv.SelectedItem) = "Sandbox", _jeton)

        ' Intuit remplace le jeton de renouvellement à chaque usage : l'ancien
        ' ne vaut plus rien, il faut garder le nouveau tout de suite.
        AddHandler client.JetonRenouvele, Sub(j)
                                              BeginInvoke(Sub()
                                                              _jeton = j
                                                              txtRefresh.Text = j.RefreshToken
                                                              EnregistrerReglages()
                                                          End Sub)
                                          End Sub
        Return client
    End Function

    Private Function VerifierCles() As Boolean
        If txtClientId.Text.Trim() = "" OrElse txtSecret.Text.Trim() = "" Then
            MessageBox.Show(Me, "Entrez le Client ID et le Client Secret de votre application Intuit (developer.intuit.com ▸ Keys & credentials).",
                            "Clés manquantes", MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return False
        End If
        Return True
    End Function

    Private Function VerifierJeton() As Boolean
        If txtRealm.Text.Trim() = "" OrElse txtRefresh.Text.Trim() = "" Then
            MessageBox.Show(Me, "Connectez-vous d'abord à QuickBooks (ou collez un Realm ID et un Refresh token).",
                            "Pas encore connecté", MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return False
        End If
        Return True
    End Function

#End Region

#Region "Extraction"

    Private Async Sub BoutonExtraction_Click(sender As Object, e As EventArgs)
        Dim b = DirectCast(sender, Button)
        Await ExtraireAsync({_boutons(b)})
    End Sub

    Private Async Sub BtnTout_Click(sender As Object, e As EventArgs)
        Await ExtraireAsync(_boutons.Values.ToList())
    End Sub

    Private Async Function ExtraireAsync(liste As IList(Of Extraction)) As Task
        If Not VerifierCles() OrElse Not VerifierJeton() Then Return

        If dtpDebut.Value.Date > dtpBascule.Value.Date Then
            MessageBox.Show(Me, "Le début de l'exercice est après la date de bascule.", "Dates", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        Dim dossier = txtDossier.Text.Trim()
        Try
            Directory.CreateDirectory(dossier)
        Catch ex As Exception
            MessageBox.Show(Me, "Dossier de sortie invalide : " & ex.Message, "Dossier", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End Try

        EnregistrerReglages()

        Dim opt As New OptionsExtraction With {
            .Dossier = dossier,
            .Separateur = If(cboSep.SelectedIndex = 1, ","c, ";"c),
            .DateDebut = dtpDebut.Value.Date,
            .DateBascule = dtpBascule.Value.Date,
            .FiltrerTransactions = chkFiltrer.Checked,
            .MethodeComptable = If(cboMethode.SelectedIndex = 1, "Cash", "Accrual")
        }

        Occupe(True)
        _annulation = New CancellationTokenSource()
        barre.Maximum = liste.Count
        barre.Value = 0
        Dim reussies = 0
        Dim debut = DateTime.Now

        Try
            Dim client = CreerClient()
            Journal($"— Extraction de {liste.Count} élément(s) vers {dossier}")

            For Each ext In liste
                Dim bouton = _boutons.First(Function(kv) kv.Value Is ext).Key
                Try
                    bouton.Text = "⏳ " & ext.Libelle
                    Dim bilan = Await Extracteur.ExecuterAsync(ext, client, opt, AddressOf Journal, _annulation.Token)
                    bouton.Text = "✔ " & ext.Libelle
                    bouton.ForeColor = Color.DarkGreen
                    Journal("✔ " & bilan)
                    reussies += 1
                Catch ex As OperationCanceledException
                    bouton.Text = ext.Libelle
                    Journal("■ Extraction annulée.")
                    Exit For
                Catch ex As Exception
                    bouton.Text = "✖ " & ext.Libelle
                    bouton.ForeColor = Color.Firebrick
                    Journal($"✖ {ext.Libelle} : {ex.Message}")
                End Try
                barre.Value += 1
            Next
        Finally
            Occupe(False)
            Journal($"— Terminé : {reussies}/{liste.Count} en {(DateTime.Now - debut).TotalSeconds.ToString("N0", CultureInfo.CurrentCulture)} s.")
        End Try
    End Function

    Private Sub BtnDossier_Click(sender As Object, e As EventArgs)
        Using d As New FolderBrowserDialog With {.Description = "Dossier où écrire les fichiers CSV", .UseDescriptionForTitle = True, .SelectedPath = txtDossier.Text}
            If d.ShowDialog(Me) = DialogResult.OK Then txtDossier.Text = d.SelectedPath
        End Using
    End Sub

    Private Sub BtnOuvrir_Click(sender As Object, e As EventArgs)
        Dim dossier = txtDossier.Text.Trim()
        If Directory.Exists(dossier) Then
            Process.Start(New ProcessStartInfo(dossier) With {.UseShellExecute = True})
        Else
            MessageBox.Show(Me, "Ce dossier n'existe pas encore : il sera créé à la première extraction.", "Dossier", MessageBoxButtons.OK, MessageBoxIcon.Information)
        End If
    End Sub

#End Region

    Private Sub Occupe(occupe As Boolean)
        For Each b In _boutons.Keys
            b.Enabled = Not occupe
        Next
        btnTout.Enabled = Not occupe
        btnConnecter.Enabled = Not occupe
        btnTester.Enabled = Not occupe
        btnAnnuler.Enabled = occupe
        UseWaitCursor = occupe
    End Sub

    Private Sub Journal(message As String)
        If InvokeRequired Then
            BeginInvoke(Sub() Journal(message))
            Return
        End If
        txtJournal.AppendText($"{DateTime.Now:HH:mm:ss}  {message}{Environment.NewLine}")
    End Sub

End Class
