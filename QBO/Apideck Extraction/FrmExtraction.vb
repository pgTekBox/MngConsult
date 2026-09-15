Imports System.Globalization

''' <summary>
''' La fenêtre : relier la société QuickBooks Online par Apideck Vault, régler les
''' dates et le dossier, puis extraire — un bouton par fichier, ou tout d'un coup.
''' </summary>
Public Class FrmExtraction
    Inherits Form

    Private ReadOnly _param As Parametres = Parametres.Charger()
    Private _annulation As CancellationTokenSource
    Private ReadOnly _boutons As New Dictionary(Of Button, Extraction)
    Private ReadOnly _bulles As New ToolTip() With {.AutoPopDelay = 15000}

    Private txtCle, txtAppId, txtConsumer, txtNom, txtDossier, txtJournal As TextBox
    Private cboService, cboSep, cboMethode As ComboBox
    Private nudPeriodes As NumericUpDown
    Private dtpDebut, dtpBascule As DateTimePicker
    Private chkFiltrer As CheckBox
    Private btnRelier, btnVerifier, btnDossier, btnOuvrir, btnTout, btnAnnuler As Button
    Private lblEtat As Label
    Private barre As ProgressBar

    Public Sub New()
        Text = "Extraction QuickBooks Online par Apideck → CSV · MngConsul"
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
        racine.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100))
        racine.RowStyles.Add(New RowStyle(SizeType.AutoSize))
        racine.RowStyles.Add(New RowStyle(SizeType.Percent, 72))
        racine.RowStyles.Add(New RowStyle(SizeType.AutoSize))
        racine.RowStyles.Add(New RowStyle(SizeType.Percent, 28))
        Controls.Add(racine)

        Dim haut As New TableLayoutPanel With {.Dock = DockStyle.Fill, .ColumnCount = 2, .AutoSize = True}
        haut.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 58))
        haut.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 42))
        haut.Controls.Add(ConstruireConnexion(), 0, 0)
        haut.Controls.Add(ConstruireOptions(), 1, 0)
        racine.Controls.Add(haut, 0, 0)

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
                _bulles.SetToolTip(b, ext.Fichiers & " — ressource Apideck /accounting/" & ext.Ressource)
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

        Dim barreActions As New FlowLayoutPanel With {.Dock = DockStyle.Fill, .AutoSize = True, .WrapContents = False}
        btnTout = New Button With {.Text = "Tout extraire", .Width = 150, .Height = 32, .Font = New Font(Font, FontStyle.Bold)}
        btnAnnuler = New Button With {.Text = "Annuler", .Width = 100, .Height = 32, .Enabled = False}
        barre = New ProgressBar With {.Width = 420, .Height = 20, .Margin = New Padding(12, 9, 3, 3)}
        AddHandler btnTout.Click, AddressOf BtnTout_Click
        AddHandler btnAnnuler.Click, Sub(s, e) _annulation?.Cancel()
        barreActions.Controls.AddRange({btnTout, btnAnnuler, barre})
        racine.Controls.Add(barreActions, 0, 2)

        txtJournal = New TextBox With {.Dock = DockStyle.Fill, .Multiline = True, .ReadOnly = True, .ScrollBars = ScrollBars.Both,
                                       .WordWrap = False, .Font = New Font("Consolas", 9.0F), .BackColor = Color.White}
        racine.Controls.Add(txtJournal, 0, 3)

        AddHandler FormClosing, Sub(s, e) EnregistrerReglages()
    End Sub

    Private Function ConstruireConnexion() As Control
        Dim grp As New GroupBox With {.Text = "1 · Connexion par Apideck", .Dock = DockStyle.Fill, .AutoSize = True, .Padding = New Padding(8)}
        Dim t = Grille4()

        txtCle = New TextBox With {.Dock = DockStyle.Fill, .UseSystemPasswordChar = True}
        txtAppId = New TextBox With {.Dock = DockStyle.Fill}
        txtConsumer = New TextBox With {.Dock = DockStyle.Fill}
        txtNom = New TextBox With {.Dock = DockStyle.Fill}
        cboService = New ComboBox With {.Dock = DockStyle.Fill, .DropDownStyle = ComboBoxStyle.DropDown}
        cboService.Items.AddRange({"quickbooks", "xero", "sage-intacct", "netsuite"})

        Champ(t, "Clé d'API Apideck", txtCle, 0, 0)
        Champ(t, "App ID", txtAppId, 2, 0)
        Champ(t, "Consumer ID", txtConsumer, 0, 1)
        Champ(t, "Nom de la société", txtNom, 2, 1)
        Champ(t, "Connecteur", cboService, 0, 2)

        _bulles.SetToolTip(txtCle, "Tableau de bord Apideck ▸ Configuration ▸ API Keys.")
        _bulles.SetToolTip(txtAppId, "Tableau de bord Apideck ▸ Configuration ▸ API Keys (Application ID).")
        _bulles.SetToolTip(txtConsumer, "Un identifiant de votre choix pour la société dont on reprend les données, par exemple « long-for-success ». Il est créé à la première connexion.")
        _bulles.SetToolTip(cboService, "L'identifiant du connecteur Apideck : « quickbooks » pour QuickBooks Online.")

        Dim actions As New FlowLayoutPanel With {.Dock = DockStyle.Fill, .AutoSize = True, .WrapContents = True}
        btnRelier = New Button With {.Text = "Relier QuickBooks (Vault)…", .Width = 200, .Height = 30}
        btnVerifier = New Button With {.Text = "Vérifier la connexion", .Width = 150, .Height = 30}
        lblEtat = New Label With {.AutoSize = True, .Margin = New Padding(10, 8, 3, 3), .Text = "Non relié."}
        AddHandler btnRelier.Click, AddressOf BtnRelier_Click
        AddHandler btnVerifier.Click, AddressOf BtnVerifier_Click
        actions.Controls.AddRange({btnRelier, btnVerifier, lblEtat})
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
        _bulles.SetToolTip(dtpDebut, "Début de l'état des résultats, et date de départ des transactions si le filtre est coché.")
        _bulles.SetToolTip(dtpBascule, "Date des balances âgées, du bilan et fin de l'état des résultats.")

        cboSep = New ComboBox With {.Dock = DockStyle.Fill, .DropDownStyle = ComboBoxStyle.DropDownList}
        cboSep.Items.AddRange({"Point-virgule ;", "Virgule ,"})
        cboMethode = New ComboBox With {.Dock = DockStyle.Fill, .DropDownStyle = ComboBoxStyle.DropDownList}
        cboMethode.Items.AddRange({"Exercice (accrual)", "Caisse (cash)"})
        Champ(t, "Séparateur CSV", cboSep, 0, 2)
        Champ(t, "Méthode comptable", cboMethode, 2, 2)

        nudPeriodes = New NumericUpDown With {.Minimum = 1, .Maximum = 12, .Value = 4, .Dock = DockStyle.Fill}
        Champ(t, "Tranches de 30 jours", nudPeriodes, 0, 3)
        chkFiltrer = New CheckBox With {.Text = "Transactions depuis le début de l'exercice", .AutoSize = True, .Margin = New Padding(3, 6, 3, 3)}
        t.Controls.Add(chkFiltrer, 2, 3)
        t.SetColumnSpan(chkFiltrer, 2)
        _bulles.SetToolTip(chkFiltrer, "Apideck n'offre ce filtre que pour les factures fournisseurs et les écritures de journal ; le reste est extrait en entier.")

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
        txtCle.Text = Parametres.Devoiler(_param.CleApiProtegee)
        txtAppId.Text = _param.AppId
        txtConsumer.Text = _param.ConsumerId
        txtNom.Text = _param.NomSociete
        cboService.Text = If(_param.ServiceId <> "", _param.ServiceId, "quickbooks")

        txtDossier.Text = If(_param.DossierSortie <> "", _param.DossierSortie,
                             Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "Extraction Apideck"))
        cboSep.SelectedIndex = If(_param.Separateur = ",", 1, 0)
        cboMethode.SelectedIndex = If(_param.MethodeComptable = "cash", 1, 0)

        Dim finMoisDernier = New Date(Today.Year, Today.Month, 1).AddDays(-1)
        dtpBascule.Value = If(_param.DateBascule, finMoisDernier)
        dtpDebut.Value = If(_param.DateDebut, New Date(dtpBascule.Value.Year, 1, 1))
        chkFiltrer.Checked = _param.FiltrerTransactions

        If txtConsumer.Text <> "" Then lblEtat.Text = "Consommateur enregistré — « Vérifier la connexion » pour confirmer."
    End Sub

    Private Sub EnregistrerReglages()
        _param.CleApiProtegee = Parametres.Proteger(txtCle.Text.Trim())
        _param.AppId = txtAppId.Text.Trim()
        _param.ConsumerId = txtConsumer.Text.Trim()
        _param.NomSociete = txtNom.Text.Trim()
        _param.ServiceId = cboService.Text.Trim()
        _param.DossierSortie = txtDossier.Text.Trim()
        _param.Separateur = If(cboSep.SelectedIndex = 1, ",", ";")
        _param.MethodeComptable = If(cboMethode.SelectedIndex = 1, "cash", "accrual")
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

    Private Function CreerClient() As ApideckClient
        Return New ApideckClient(txtCle.Text, txtAppId.Text, txtConsumer.Text, cboService.Text)
    End Function

    Private Async Sub BtnRelier_Click(sender As Object, e As EventArgs)
        If Not VerifierCles() Then Return
        EnregistrerReglages()

        Await OccuperAsync(Async Function(ct)
                               Dim nom = If(txtNom.Text.Trim() <> "", txtNom.Text.Trim(), txtConsumer.Text.Trim())
                               Dim lien = Await CreerClient().CreerSessionAsync(nom, ct)
                               If lien = "" Then
                                   Journal("✖ Apideck n'a pas rendu d'adresse de session Vault.")
                                   Return
                               End If
                               Journal($"✔ Session Vault ouverte pour « {txtConsumer.Text.Trim()} ». Choisissez QuickBooks et autorisez l'accès.")
                               Process.Start(New ProcessStartInfo(lien) With {.UseShellExecute = True})
                               lblEtat.Text = "Reliez QuickBooks dans le navigateur, puis « Vérifier la connexion »."
                           End Function)
    End Sub

    Private Async Sub BtnVerifier_Click(sender As Object, e As EventArgs)
        If Not VerifierCles() Then Return
        Await OccuperAsync(AddressOf VerifierAsync)
    End Sub

    Private Async Function VerifierAsync(ct As CancellationToken) As Task
        Dim client = CreerClient()
        Dim connexions = Await client.ConnexionsAsync(ct)
        Dim service = cboService.Text.Trim()

        Journal($"Connexions comptables de « {txtConsumer.Text.Trim()} » :")
        For Each c In connexions.Where(Function(x) JsonChemin.Valeur(x, "enabled") = "true" OrElse JsonChemin.Valeur(x, "service_id") = service)
            Journal($"   {JsonChemin.Valeur(c, "service_id"),-16} état {JsonChemin.Valeur(c, "state"),-14} santé {JsonChemin.Valeur(c, "health")}")
        Next

        Dim cible = connexions.FirstOrDefault(Function(x) JsonChemin.Valeur(x, "service_id") = service)
        Dim etat = If(cible Is Nothing, "", JsonChemin.Valeur(cible, "state"))

        If etat <> "callable" Then
            lblEtat.Text = $"« {service} » n'est pas encore relié (état : {If(etat = "", "absent", etat)})."
            Journal("   La connexion doit être à l'état « callable » : ouvrez « Relier QuickBooks (Vault)… ».")
            Return
        End If

        Dim info = Await client.UnAsync("/accounting/company-info", ct)
        Dim nom = JsonChemin.Valeur(info, "company_name|legal_name")
        lblEtat.Text = $"Relié : {nom} ({service})"
        Journal($"✔ Connexion vérifiée : {nom}.")
    End Function

    Private Function VerifierCles() As Boolean
        If txtCle.Text.Trim() = "" OrElse txtAppId.Text.Trim() = "" Then
            MessageBox.Show(Me, "Entrez la clé d'API et l'App ID (tableau de bord Apideck ▸ Configuration ▸ API Keys).",
                            "Clés manquantes", MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return False
        End If
        If txtConsumer.Text.Trim() = "" Then
            MessageBox.Show(Me, "Entrez un Consumer ID : un identifiant de votre choix pour la société, par exemple « long-for-success ».",
                            "Consumer ID manquant", MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return False
        End If
        Return True
    End Function

#End Region

#Region "Extraction"

    Private Async Sub BoutonExtraction_Click(sender As Object, e As EventArgs)
        Await ExtraireAsync({_boutons(DirectCast(sender, Button))})
    End Sub

    Private Async Sub BtnTout_Click(sender As Object, e As EventArgs)
        Await ExtraireAsync(_boutons.Values.ToList())
    End Sub

    Private Async Function ExtraireAsync(liste As IList(Of Extraction)) As Task
        If Not VerifierCles() Then Return

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
            .PeriodesAgees = CInt(nudPeriodes.Value),
            .MethodeComptable = If(cboMethode.SelectedIndex = 1, "cash", "accrual")
        }

        barre.Maximum = liste.Count
        barre.Value = 0
        Dim reussies = 0
        Dim debut = DateTime.Now

        Await OccuperAsync(Async Function(ct)
                               Dim client = CreerClient()
                               Journal($"— Extraction de {liste.Count} élément(s) vers {dossier}")

                               For Each ext In liste
                                   Dim bouton = _boutons.First(Function(kv) kv.Value Is ext).Key
                                   Try
                                       bouton.Text = "⏳ " & ext.Libelle
                                       Dim bilan = Await Extracteur.ExecuterAsync(ext, client, opt, AddressOf Journal, ct)
                                       bouton.Text = "✔ " & ext.Libelle
                                       bouton.ForeColor = Color.DarkGreen
                                       Journal("✔ " & bilan)
                                       reussies += 1
                                   Catch ex As OperationCanceledException
                                       bouton.Text = ext.Libelle
                                       Throw
                                   Catch ex As Exception
                                       bouton.Text = "✖ " & ext.Libelle
                                       bouton.ForeColor = Color.Firebrick
                                       Journal($"✖ {ext.Libelle} : {ex.Message}")
                                   End Try
                                   barre.Value += 1
                               Next
                           End Function)

        Journal($"— Terminé : {reussies}/{liste.Count} en {(DateTime.Now - debut).TotalSeconds.ToString("N0", CultureInfo.CurrentCulture)} s.")
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

    ''' <summary>
    ''' Exécute une action en désactivant les boutons, avec annulation possible ;
    ''' les erreurs vont au journal.
    ''' </summary>
    Private Async Function OccuperAsync(action As Func(Of CancellationToken, Task)) As Task
        Occupe(True)
        _annulation = New CancellationTokenSource()
        Try
            Await action(_annulation.Token)
        Catch ex As OperationCanceledException
            Journal("■ Opération annulée.")
        Catch ex As Exception
            Journal("✖ " & ex.Message)
        Finally
            Occupe(False)
        End Try
    End Function

    Private Sub Occupe(occupe As Boolean)
        For Each b In _boutons.Keys
            b.Enabled = Not occupe
        Next
        For Each b In {btnTout, btnRelier, btnVerifier}
            b.Enabled = Not occupe
        Next
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
