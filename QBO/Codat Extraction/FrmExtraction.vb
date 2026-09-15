Imports System.Globalization

''' <summary>
''' La fenêtre : relier la société QuickBooks Online à Codat, régler les dates et
''' le dossier, puis extraire — un bouton par fichier, ou tout d'un coup.
''' </summary>
Public Class FrmExtraction
    Inherits Form

    Private ReadOnly _param As Parametres = Parametres.Charger()
    Private _annulation As CancellationTokenSource
    Private ReadOnly _boutons As New Dictionary(Of Button, Extraction)
    Private ReadOnly _bulles As New ToolTip() With {.AutoPopDelay = 15000}

    Private txtCle, txtNom, txtCompany, txtConnexion, txtDossier, txtJournal As TextBox
    Private cboSep As ComboBox
    Private nudPeriodes As NumericUpDown
    Private dtpDebut, dtpBascule As DateTimePicker
    Private chkFiltrer As CheckBox
    Private btnCreer, btnVerifier, btnSynchroniser, btnEtat, btnDossier, btnOuvrir, btnTout, btnAnnuler As Button
    Private lblEtat As Label
    Private barre As ProgressBar

    Public Sub New()
        Text = "Extraction QuickBooks Online par Codat → CSV · MngConsul"
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
                _bulles.SetToolTip(b, ext.Fichiers & " — type de données Codat « " & ext.TypeDonnees & " »" &
                                      If(ext.ParConnexion, " (lu par connexion)", ""))
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
        Dim grp As New GroupBox With {.Text = "1 · Connexion par Codat", .Dock = DockStyle.Fill, .AutoSize = True, .Padding = New Padding(8)}
        Dim t = Grille4()

        txtCle = New TextBox With {.Dock = DockStyle.Fill, .UseSystemPasswordChar = True}
        txtNom = New TextBox With {.Dock = DockStyle.Fill}
        txtCompany = New TextBox With {.Dock = DockStyle.Fill}
        txtConnexion = New TextBox With {.Dock = DockStyle.Fill}

        Champ(t, "Clé d'API Codat", txtCle, 0, 0)
        Champ(t, "Nom de la société", txtNom, 2, 0)
        Champ(t, "Company ID", txtCompany, 0, 1)
        Champ(t, "Connection ID", txtConnexion, 2, 1)

        _bulles.SetToolTip(txtCle, "Portail Codat ▸ Settings ▸ Developers ▸ API keys. La clé brute ou l'en-tête « Basic … » conviennent.")
        _bulles.SetToolTip(txtCompany, "Rempli par « Créer la société… », ou copié depuis le portail Codat pour une société existante.")
        _bulles.SetToolTip(txtConnexion, "La connexion QuickBooks de la société. Trouvée par « Vérifier la connexion ».")

        Dim actions As New FlowLayoutPanel With {.Dock = DockStyle.Fill, .AutoSize = True, .WrapContents = True}
        btnCreer = New Button With {.Text = "Créer la société et relier QuickBooks…", .Width = 250, .Height = 30}
        btnVerifier = New Button With {.Text = "Vérifier la connexion", .Width = 150, .Height = 30}
        btnSynchroniser = New Button With {.Text = "Synchroniser", .Width = 110, .Height = 30}
        btnEtat = New Button With {.Text = "État des données", .Width = 130, .Height = 30}
        lblEtat = New Label With {.AutoSize = True, .Margin = New Padding(10, 8, 3, 3), .Text = "Non relié."}
        AddHandler btnCreer.Click, AddressOf BtnCreer_Click
        AddHandler btnVerifier.Click, AddressOf BtnVerifier_Click
        AddHandler btnSynchroniser.Click, AddressOf BtnSynchroniser_Click
        AddHandler btnEtat.Click, AddressOf BtnEtat_Click
        _bulles.SetToolTip(btnSynchroniser, "Demande à Codat de relire QuickBooks. Les extractions lisent la dernière synchronisation.")
        actions.Controls.AddRange({btnCreer, btnVerifier, btnSynchroniser, btnEtat, lblEtat})
        t.Controls.Add(actions, 0, 2)
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
        _bulles.SetToolTip(dtpDebut, "Premier mois du bilan et de l'état des résultats, et date de départ des transactions si le filtre est coché.")
        _bulles.SetToolTip(dtpBascule, "Date des balances âgées et dernier mois des états financiers.")

        cboSep = New ComboBox With {.Dock = DockStyle.Fill, .DropDownStyle = ComboBoxStyle.DropDownList}
        cboSep.Items.AddRange({"Point-virgule ;", "Virgule ,"})
        nudPeriodes = New NumericUpDown With {.Minimum = 1, .Maximum = 12, .Value = 4, .Dock = DockStyle.Fill}
        Champ(t, "Séparateur CSV", cboSep, 0, 2)
        Champ(t, "Tranches de 30 jours", nudPeriodes, 2, 2)
        _bulles.SetToolTip(nudPeriodes, "Nombre de tranches d'âge des balances âgées (30 jours chacune).")

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
        txtCle.Text = Parametres.Devoiler(_param.CleApiProtegee)
        txtNom.Text = _param.NomSociete
        txtCompany.Text = _param.CompanyId
        txtConnexion.Text = _param.ConnectionId

        txtDossier.Text = If(_param.DossierSortie <> "", _param.DossierSortie,
                             Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "Extraction Codat"))
        cboSep.SelectedIndex = If(_param.Separateur = ",", 1, 0)

        Dim finMoisDernier = New Date(Today.Year, Today.Month, 1).AddDays(-1)
        dtpBascule.Value = If(_param.DateBascule, finMoisDernier)
        dtpDebut.Value = If(_param.DateDebut, New Date(dtpBascule.Value.Year, 1, 1))
        chkFiltrer.Checked = _param.FiltrerTransactions

        If txtCompany.Text <> "" Then lblEtat.Text = "Société enregistrée — « Vérifier la connexion » pour confirmer."
    End Sub

    Private Sub EnregistrerReglages()
        _param.CleApiProtegee = Parametres.Proteger(txtCle.Text.Trim())
        _param.NomSociete = txtNom.Text.Trim()
        _param.CompanyId = txtCompany.Text.Trim()
        _param.ConnectionId = txtConnexion.Text.Trim()
        _param.DossierSortie = txtDossier.Text.Trim()
        _param.Separateur = If(cboSep.SelectedIndex = 1, ",", ";")
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

    Private Async Sub BtnCreer_Click(sender As Object, e As EventArgs)
        If Not VerifierCle() Then Return
        If txtNom.Text.Trim() = "" Then
            MessageBox.Show(Me, "Donnez un nom à la société (par exemple le nom du client dont on reprend les données).",
                            "Nom manquant", MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return
        End If
        If txtCompany.Text.Trim() <> "" AndAlso
           MessageBox.Show(Me, "Une société Codat est déjà enregistrée. En créer une nouvelle ?", "Nouvelle société",
                           MessageBoxButtons.YesNo, MessageBoxIcon.Question) <> DialogResult.Yes Then Return

        Await OccuperAsync(Async Function(ct)
                               Dim societe = Await New CodatClient(txtCle.Text).CreerSocieteAsync(txtNom.Text.Trim(), ct)
                               txtCompany.Text = JsonChemin.Valeur(societe, "id")
                               txtConnexion.Text = ""
                               EnregistrerReglages()

                               Dim lien = JsonChemin.Valeur(societe, "redirect")
                               Journal($"✔ Société Codat créée : {txtNom.Text.Trim()} ({txtCompany.Text}).")
                               If lien <> "" Then
                                   Journal("   Lien pour relier QuickBooks Online : " & lien)
                                   Process.Start(New ProcessStartInfo(lien) With {.UseShellExecute = True})
                                   lblEtat.Text = "Reliez QuickBooks dans le navigateur, puis « Vérifier la connexion »."
                               End If
                           End Function)
    End Sub

    Private Async Sub BtnVerifier_Click(sender As Object, e As EventArgs)
        If Not VerifierCle() OrElse Not VerifierSociete() Then Return
        Await OccuperAsync(AddressOf VerifierAsync)
    End Sub

    Private Async Function VerifierAsync(ct As CancellationToken) As Task
        Dim client As New CodatClient(txtCle.Text)
        Dim societe = Await client.SocieteAsync(txtCompany.Text.Trim(), ct)
        Dim connexions = Await client.ConnexionsAsync(txtCompany.Text.Trim(), ct)

        Journal($"Société « {JsonChemin.Valeur(societe, "name")} » : {connexions.Count} connexion(s).")
        For Each c In connexions
            Journal($"   {JsonChemin.Valeur(c, "platformName")} — {JsonChemin.Valeur(c, "status")} — {JsonChemin.Valeur(c, "id")}")
        Next

        ' La connexion QuickBooks reliée, à défaut la première connexion reliée.
        Dim reliees = connexions.Where(Function(c) JsonChemin.Valeur(c, "status") = "Linked").ToList()
        Dim choisie = If(reliees.FirstOrDefault(Function(c) JsonChemin.Valeur(c, "platformName").Contains("QuickBooks")), reliees.FirstOrDefault())

        If choisie Is Nothing Then
            lblEtat.Text = "Aucune connexion reliée : ouvrez le lien Codat et reliez QuickBooks."
            Dim lien = JsonChemin.Valeur(societe, "redirect")
            If lien <> "" Then Journal("   Lien pour relier QuickBooks Online : " & lien)
            Return
        End If

        txtConnexion.Text = JsonChemin.Valeur(choisie, "id")
        EnregistrerReglages()
        lblEtat.Text = $"Relié : {JsonChemin.Valeur(choisie, "platformName")} (synchro {JsonChemin.Valeur(choisie, "lastSync")})"
        Journal("✔ Connexion retenue : " & txtConnexion.Text)
    End Function

    Private Async Sub BtnSynchroniser_Click(sender As Object, e As EventArgs)
        If Not VerifierCle() OrElse Not VerifierSociete() Then Return
        Await OccuperAsync(Async Function(ct)
                               Await New CodatClient(txtCle.Text).SynchroniserToutAsync(txtCompany.Text.Trim(), ct)
                               Journal("✔ Synchronisation demandée à Codat. Suivez l'avancement avec « État des données » avant d'extraire.")
                           End Function)
    End Sub

    Private Async Sub BtnEtat_Click(sender As Object, e As EventArgs)
        If Not VerifierCle() OrElse Not VerifierSociete() Then Return
        Await OccuperAsync(Async Function(ct)
                               Dim etat = Await New CodatClient(txtCle.Text).EtatDonneesAsync(txtCompany.Text.Trim(), ct)
                               Journal("État des données chez Codat :")
                               For Each st In ElementsEtat(etat)
                                   Journal($"   {JsonChemin.Valeur(st, "dataType"),-22} {JsonChemin.Valeur(st, "currentStatus"),-22} dernière synchro réussie : {JsonChemin.Valeur(st, "lastSuccessfulSync")}")
                               Next
                           End Function)
    End Sub

    ''' <summary>dataStatus rend un objet indexé par type de données ; on accepte aussi une liste.</summary>
    Private Shared Function ElementsEtat(etat As JsonNode) As IEnumerable(Of JsonNode)
        Dim liste = TryCast(etat, JsonArray)
        If liste IsNot Nothing Then Return liste
        Dim objet = TryCast(etat, JsonObject)
        If objet Is Nothing Then Return Enumerable.Empty(Of JsonNode)()
        Return objet.Select(Function(kv) kv.Value).Where(Function(v) v IsNot Nothing).OrderBy(Function(v) JsonChemin.Valeur(v, "dataType")).ToList()
    End Function

    Private Function VerifierCle() As Boolean
        If txtCle.Text.Trim() = "" Then
            MessageBox.Show(Me, "Entrez la clé d'API Codat (portail Codat ▸ Settings ▸ Developers ▸ API keys).",
                            "Clé manquante", MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return False
        End If
        Return True
    End Function

    Private Function VerifierSociete() As Boolean
        If txtCompany.Text.Trim() = "" Then
            MessageBox.Show(Me, "Créez d'abord la société (ou collez le Company ID d'une société existante du portail Codat).",
                            "Société manquante", MessageBoxButtons.OK, MessageBoxIcon.Information)
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
        If Not VerifierCle() OrElse Not VerifierSociete() Then Return

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
            .CompanyId = txtCompany.Text.Trim(),
            .ConnectionId = txtConnexion.Text.Trim()
        }

        barre.Maximum = liste.Count
        barre.Value = 0
        Dim reussies = 0
        Dim debut = DateTime.Now

        Await OccuperAsync(Async Function(ct)
                               Dim client As New CodatClient(txtCle.Text)
                               Journal($"— Extraction de {liste.Count} élément(s) vers {dossier}")

                               ' La date de la dernière synchronisation de chaque type : ce qu'on
                               ' lit chez Codat n'est jamais plus récent qu'elle.
                               Dim synchros As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
                               Try
                                   For Each st In ElementsEtat(Await client.EtatDonneesAsync(opt.CompanyId, ct))
                                       synchros(JsonChemin.Valeur(st, "dataType")) = JsonChemin.Valeur(st, "lastSuccessfulSync")
                                   Next
                               Catch ex As CodatException
                                   Journal("   (état des synchronisations indisponible : " & ex.Message & ")")
                               End Try

                               For Each ext In liste
                                   Dim bouton = _boutons.First(Function(kv) kv.Value Is ext).Key
                                   Try
                                       bouton.Text = "⏳ " & ext.Libelle
                                       Dim bilan = Await Extracteur.ExecuterAsync(ext, client, opt, AddressOf Journal, ct)
                                       Dim synchro As String = Nothing
                                       If synchros.TryGetValue(ext.TypeDonnees, synchro) Then
                                           bilan &= If(synchro = "", " — ⚠ jamais synchronisé chez Codat", " — synchro du " & synchro)
                                       End If
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
        For Each b In {btnTout, btnCreer, btnVerifier, btnSynchroniser, btnEtat}
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
