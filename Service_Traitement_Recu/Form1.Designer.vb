<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class Form1
    Inherits System.Windows.Forms.Form

    <System.Diagnostics.DebuggerNonUserCode()>
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    Private components As System.ComponentModel.IContainer

    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.components = New System.ComponentModel.Container()
        Me.pnlTop = New System.Windows.Forms.Panel()
        Me.lblTitre = New System.Windows.Forms.Label()
        Me.lblEtatCaption = New System.Windows.Forms.Label()
        Me.lblEtat = New System.Windows.Forms.Label()
        Me.lblDernierPassageCaption = New System.Windows.Forms.Label()
        Me.lblDernierPassage = New System.Windows.Forms.Label()
        Me.lblFileCaption = New System.Windows.Forms.Label()
        Me.lblFile = New System.Windows.Forms.Label()
        Me.lblTraitesCaption = New System.Windows.Forms.Label()
        Me.lblTraites = New System.Windows.Forms.Label()
        Me.lblErreursCaption = New System.Windows.Forms.Label()
        Me.lblErreurs = New System.Windows.Forms.Label()
        Me.btnTraiterMaintenant = New System.Windows.Forms.Button()
        Me.btnRefresh = New System.Windows.Forms.Button()
        Me.btnSetting = New System.Windows.Forms.Button()
        Me.tabMain = New System.Windows.Forms.TabControl()
        Me.tabQueue = New System.Windows.Forms.TabPage()
        Me.dvQueue = New System.Windows.Forms.DataGridView()
        Me.colQReceiptId = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colQCreated = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colQFileName = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colQContentType = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colQType = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colQEtat = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colQProchaine = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colQTentatives = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colQErreur = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colQGuid = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.pnlQueueBottom = New System.Windows.Forms.Panel()
        Me.chkOnlyPending = New System.Windows.Forms.CheckBox()
        Me.btnRefaireTout = New System.Windows.Forms.Button()
        Me.btnRefaireJson = New System.Windows.Forms.Button()
        Me.btnVoirJsonQueue = New System.Windows.Forms.Button()
        Me.tabResult = New System.Windows.Forms.TabPage()
        Me.splitResult = New System.Windows.Forms.SplitContainer()
        Me.dvLog = New System.Windows.Forms.DataGridView()
        Me.colLId = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colLCreated = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colLFileName = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colLStep = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colLResultat = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colLMessage = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colLDuration = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colLInput = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colLOutput = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colLCost = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colLGuid = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colLJson = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.txtJson = New System.Windows.Forms.TextBox()
        Me.pnlResultBottom = New System.Windows.Forms.Panel()
        Me.btnCopyJson = New System.Windows.Forms.Button()
        Me.lblJsonCaption = New System.Windows.Forms.Label()
        Me.tabJournal = New System.Windows.Forms.TabPage()
        Me.txtLog = New System.Windows.Forms.TextBox()
        Me.pnlJournalTop = New System.Windows.Forms.Panel()
        Me.rbEvent = New System.Windows.Forms.RadioButton()
        Me.rbError = New System.Windows.Forms.RadioButton()
        Me.btnClearLog = New System.Windows.Forms.Button()
        Me.Timer1 = New System.Windows.Forms.Timer(Me.components)
        Me.pnlTop.SuspendLayout()
        Me.tabMain.SuspendLayout()
        Me.tabQueue.SuspendLayout()
        CType(Me.dvQueue, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.pnlQueueBottom.SuspendLayout()
        Me.tabResult.SuspendLayout()
        CType(Me.splitResult, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.splitResult.Panel1.SuspendLayout()
        Me.splitResult.Panel2.SuspendLayout()
        Me.splitResult.SuspendLayout()
        CType(Me.dvLog, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.pnlResultBottom.SuspendLayout()
        Me.tabJournal.SuspendLayout()
        Me.pnlJournalTop.SuspendLayout()
        Me.SuspendLayout()
        '
        'pnlTop
        '
        Me.pnlTop.BackColor = System.Drawing.Color.WhiteSmoke
        Me.pnlTop.Controls.Add(Me.btnSetting)
        Me.pnlTop.Controls.Add(Me.btnRefresh)
        Me.pnlTop.Controls.Add(Me.btnTraiterMaintenant)
        Me.pnlTop.Controls.Add(Me.lblErreurs)
        Me.pnlTop.Controls.Add(Me.lblErreursCaption)
        Me.pnlTop.Controls.Add(Me.lblTraites)
        Me.pnlTop.Controls.Add(Me.lblTraitesCaption)
        Me.pnlTop.Controls.Add(Me.lblFile)
        Me.pnlTop.Controls.Add(Me.lblFileCaption)
        Me.pnlTop.Controls.Add(Me.lblDernierPassage)
        Me.pnlTop.Controls.Add(Me.lblDernierPassageCaption)
        Me.pnlTop.Controls.Add(Me.lblEtat)
        Me.pnlTop.Controls.Add(Me.lblEtatCaption)
        Me.pnlTop.Controls.Add(Me.lblTitre)
        Me.pnlTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.pnlTop.Location = New System.Drawing.Point(0, 0)
        Me.pnlTop.Name = "pnlTop"
        Me.pnlTop.Size = New System.Drawing.Size(1184, 104)
        Me.pnlTop.TabIndex = 0
        '
        'lblTitre
        '
        Me.lblTitre.AutoSize = True
        Me.lblTitre.Font = New System.Drawing.Font("Segoe UI", 12.0!, System.Drawing.FontStyle.Bold)
        Me.lblTitre.Location = New System.Drawing.Point(14, 12)
        Me.lblTitre.Name = "lblTitre"
        Me.lblTitre.Size = New System.Drawing.Size(260, 21)
        Me.lblTitre.TabIndex = 0
        Me.lblTitre.Text = "Traitement des reçus"
        '
        'lblEtatCaption
        '
        Me.lblEtatCaption.AutoSize = True
        Me.lblEtatCaption.Location = New System.Drawing.Point(16, 46)
        Me.lblEtatCaption.Name = "lblEtatCaption"
        Me.lblEtatCaption.Size = New System.Drawing.Size(35, 13)
        Me.lblEtatCaption.TabIndex = 1
        Me.lblEtatCaption.Text = "État :"
        '
        'lblEtat
        '
        Me.lblEtat.AutoSize = True
        Me.lblEtat.Font = New System.Drawing.Font("Segoe UI", 9.0!, System.Drawing.FontStyle.Bold)
        Me.lblEtat.Location = New System.Drawing.Point(64, 46)
        Me.lblEtat.Name = "lblEtat"
        Me.lblEtat.Size = New System.Drawing.Size(100, 13)
        Me.lblEtat.TabIndex = 2
        Me.lblEtat.Text = "Service non joint"
        '
        'lblDernierPassageCaption
        '
        Me.lblDernierPassageCaption.AutoSize = True
        Me.lblDernierPassageCaption.Location = New System.Drawing.Point(16, 74)
        Me.lblDernierPassageCaption.Name = "lblDernierPassageCaption"
        Me.lblDernierPassageCaption.Size = New System.Drawing.Size(90, 13)
        Me.lblDernierPassageCaption.TabIndex = 3
        Me.lblDernierPassageCaption.Text = "Dernier passage :"
        '
        'lblDernierPassage
        '
        Me.lblDernierPassage.AutoSize = True
        Me.lblDernierPassage.Location = New System.Drawing.Point(118, 74)
        Me.lblDernierPassage.Name = "lblDernierPassage"
        Me.lblDernierPassage.Size = New System.Drawing.Size(40, 13)
        Me.lblDernierPassage.TabIndex = 4
        Me.lblDernierPassage.Text = "Jamais"
        '
        'lblFileCaption
        '
        Me.lblFileCaption.AutoSize = True
        Me.lblFileCaption.Location = New System.Drawing.Point(380, 46)
        Me.lblFileCaption.Name = "lblFileCaption"
        Me.lblFileCaption.Size = New System.Drawing.Size(70, 13)
        Me.lblFileCaption.TabIndex = 5
        Me.lblFileCaption.Text = "Reçus à faire :"
        '
        'lblFile
        '
        Me.lblFile.AutoSize = True
        Me.lblFile.Font = New System.Drawing.Font("Segoe UI", 9.0!, System.Drawing.FontStyle.Bold)
        Me.lblFile.Location = New System.Drawing.Point(462, 46)
        Me.lblFile.Name = "lblFile"
        Me.lblFile.Size = New System.Drawing.Size(13, 13)
        Me.lblFile.TabIndex = 6
        Me.lblFile.Text = "0"
        '
        'lblTraitesCaption
        '
        Me.lblTraitesCaption.AutoSize = True
        Me.lblTraitesCaption.Location = New System.Drawing.Point(380, 74)
        Me.lblTraitesCaption.Name = "lblTraitesCaption"
        Me.lblTraitesCaption.Size = New System.Drawing.Size(50, 13)
        Me.lblTraitesCaption.TabIndex = 7
        Me.lblTraitesCaption.Text = "Traités :"
        '
        'lblTraites
        '
        Me.lblTraites.AutoSize = True
        Me.lblTraites.Location = New System.Drawing.Point(462, 74)
        Me.lblTraites.Name = "lblTraites"
        Me.lblTraites.Size = New System.Drawing.Size(13, 13)
        Me.lblTraites.TabIndex = 8
        Me.lblTraites.Text = "0"
        '
        'lblErreursCaption
        '
        Me.lblErreursCaption.AutoSize = True
        Me.lblErreursCaption.Location = New System.Drawing.Point(560, 74)
        Me.lblErreursCaption.Name = "lblErreursCaption"
        Me.lblErreursCaption.Size = New System.Drawing.Size(50, 13)
        Me.lblErreursCaption.TabIndex = 9
        Me.lblErreursCaption.Text = "Erreurs :"
        '
        'lblErreurs
        '
        Me.lblErreurs.AutoSize = True
        Me.lblErreurs.ForeColor = System.Drawing.Color.Firebrick
        Me.lblErreurs.Location = New System.Drawing.Point(620, 74)
        Me.lblErreurs.Name = "lblErreurs"
        Me.lblErreurs.Size = New System.Drawing.Size(13, 13)
        Me.lblErreurs.TabIndex = 10
        Me.lblErreurs.Text = "0"
        '
        'btnTraiterMaintenant
        '
        Me.btnTraiterMaintenant.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnTraiterMaintenant.Location = New System.Drawing.Point(760, 40)
        Me.btnTraiterMaintenant.Name = "btnTraiterMaintenant"
        Me.btnTraiterMaintenant.Size = New System.Drawing.Size(140, 30)
        Me.btnTraiterMaintenant.TabIndex = 11
        Me.btnTraiterMaintenant.Text = "Traiter maintenant"
        Me.btnTraiterMaintenant.UseVisualStyleBackColor = True
        '
        'btnRefresh
        '
        Me.btnRefresh.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnRefresh.Location = New System.Drawing.Point(910, 40)
        Me.btnRefresh.Name = "btnRefresh"
        Me.btnRefresh.Size = New System.Drawing.Size(110, 30)
        Me.btnRefresh.TabIndex = 12
        Me.btnRefresh.Text = "Rafraîchir"
        Me.btnRefresh.UseVisualStyleBackColor = True
        '
        'btnSetting
        '
        Me.btnSetting.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnSetting.Location = New System.Drawing.Point(1030, 40)
        Me.btnSetting.Name = "btnSetting"
        Me.btnSetting.Size = New System.Drawing.Size(130, 30)
        Me.btnSetting.TabIndex = 13
        Me.btnSetting.Text = "Paramètres..."
        Me.btnSetting.UseVisualStyleBackColor = True
        '
        'tabMain
        '
        Me.tabMain.Controls.Add(Me.tabQueue)
        Me.tabMain.Controls.Add(Me.tabResult)
        Me.tabMain.Controls.Add(Me.tabJournal)
        Me.tabMain.Dock = System.Windows.Forms.DockStyle.Fill
        Me.tabMain.Location = New System.Drawing.Point(0, 104)
        Me.tabMain.Name = "tabMain"
        Me.tabMain.SelectedIndex = 0
        Me.tabMain.Size = New System.Drawing.Size(1184, 657)
        Me.tabMain.TabIndex = 1
        '
        'tabQueue
        '
        Me.tabQueue.Controls.Add(Me.dvQueue)
        Me.tabQueue.Controls.Add(Me.pnlQueueBottom)
        Me.tabQueue.Location = New System.Drawing.Point(4, 22)
        Me.tabQueue.Name = "tabQueue"
        Me.tabQueue.Padding = New System.Windows.Forms.Padding(3)
        Me.tabQueue.Size = New System.Drawing.Size(1176, 631)
        Me.tabQueue.TabIndex = 0
        Me.tabQueue.Text = "Reçus à faire"
        Me.tabQueue.UseVisualStyleBackColor = True
        '
        'dvQueue
        '
        Me.dvQueue.AllowUserToAddRows = False
        Me.dvQueue.AllowUserToDeleteRows = False
        Me.dvQueue.AutoGenerateColumns = False
        Me.dvQueue.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
        Me.dvQueue.Columns.AddRange(New System.Windows.Forms.DataGridViewColumn() {Me.colQReceiptId, Me.colQCreated, Me.colQFileName, Me.colQContentType, Me.colQType, Me.colQEtat, Me.colQProchaine, Me.colQTentatives, Me.colQErreur, Me.colQGuid})
        Me.dvQueue.Dock = System.Windows.Forms.DockStyle.Fill
        Me.dvQueue.Location = New System.Drawing.Point(3, 3)
        Me.dvQueue.MultiSelect = False
        Me.dvQueue.Name = "dvQueue"
        Me.dvQueue.ReadOnly = True
        Me.dvQueue.RowHeadersVisible = False
        Me.dvQueue.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect
        Me.dvQueue.Size = New System.Drawing.Size(1170, 581)
        Me.dvQueue.TabIndex = 0
        '
        'colQReceiptId
        '
        Me.colQReceiptId.DataPropertyName = "ReceiptId"
        Me.colQReceiptId.HeaderText = "#"
        Me.colQReceiptId.Name = "colQReceiptId"
        Me.colQReceiptId.ReadOnly = True
        Me.colQReceiptId.Width = 60
        '
        'colQCreated
        '
        Me.colQCreated.DataPropertyName = "Created"
        Me.colQCreated.HeaderText = "Reçu le"
        Me.colQCreated.Name = "colQCreated"
        Me.colQCreated.ReadOnly = True
        Me.colQCreated.Width = 130
        '
        'colQFileName
        '
        Me.colQFileName.DataPropertyName = "FileName"
        Me.colQFileName.HeaderText = "Fichier"
        Me.colQFileName.Name = "colQFileName"
        Me.colQFileName.ReadOnly = True
        Me.colQFileName.Width = 220
        '
        'colQContentType
        '
        Me.colQContentType.DataPropertyName = "ContentType"
        Me.colQContentType.HeaderText = "Format"
        Me.colQContentType.Name = "colQContentType"
        Me.colQContentType.ReadOnly = True
        Me.colQContentType.Width = 110
        '
        'colQType
        '
        Me.colQType.DataPropertyName = "ReceiptType"
        Me.colQType.HeaderText = "Type"
        Me.colQType.Name = "colQType"
        Me.colQType.ReadOnly = True
        Me.colQType.Width = 140
        '
        'colQEtat
        '
        Me.colQEtat.DataPropertyName = "Etat"
        Me.colQEtat.HeaderText = "État"
        Me.colQEtat.Name = "colQEtat"
        Me.colQEtat.ReadOnly = True
        Me.colQEtat.Width = 120
        '
        'colQProchaine
        '
        Me.colQProchaine.DataPropertyName = "ProchaineEtape"
        Me.colQProchaine.HeaderText = "Prochaine étape"
        Me.colQProchaine.Name = "colQProchaine"
        Me.colQProchaine.ReadOnly = True
        Me.colQProchaine.Width = 130
        '
        'colQTentatives
        '
        Me.colQTentatives.DataPropertyName = "Tentatives"
        Me.colQTentatives.HeaderText = "Tent."
        Me.colQTentatives.Name = "colQTentatives"
        Me.colQTentatives.ReadOnly = True
        Me.colQTentatives.Width = 50
        '
        'colQErreur
        '
        Me.colQErreur.DataPropertyName = "SvcLastError"
        Me.colQErreur.HeaderText = "Dernière erreur"
        Me.colQErreur.Name = "colQErreur"
        Me.colQErreur.ReadOnly = True
        Me.colQErreur.Width = 300
        '
        'colQGuid
        '
        Me.colQGuid.DataPropertyName = "imageGUID"
        Me.colQGuid.HeaderText = "imageGUID"
        Me.colQGuid.Name = "colQGuid"
        Me.colQGuid.ReadOnly = True
        Me.colQGuid.Visible = False
        '
        'pnlQueueBottom
        '
        Me.pnlQueueBottom.Controls.Add(Me.btnVoirJsonQueue)
        Me.pnlQueueBottom.Controls.Add(Me.btnRefaireJson)
        Me.pnlQueueBottom.Controls.Add(Me.btnRefaireTout)
        Me.pnlQueueBottom.Controls.Add(Me.chkOnlyPending)
        Me.pnlQueueBottom.Dock = System.Windows.Forms.DockStyle.Bottom
        Me.pnlQueueBottom.Location = New System.Drawing.Point(3, 584)
        Me.pnlQueueBottom.Name = "pnlQueueBottom"
        Me.pnlQueueBottom.Size = New System.Drawing.Size(1170, 44)
        Me.pnlQueueBottom.TabIndex = 1
        '
        'chkOnlyPending
        '
        Me.chkOnlyPending.AutoSize = True
        Me.chkOnlyPending.Checked = True
        Me.chkOnlyPending.CheckState = System.Windows.Forms.CheckState.Checked
        Me.chkOnlyPending.Location = New System.Drawing.Point(8, 14)
        Me.chkOnlyPending.Name = "chkOnlyPending"
        Me.chkOnlyPending.Size = New System.Drawing.Size(180, 17)
        Me.chkOnlyPending.TabIndex = 0
        Me.chkOnlyPending.Text = "Seulement ce qui reste à faire"
        Me.chkOnlyPending.UseVisualStyleBackColor = True
        '
        'btnRefaireTout
        '
        Me.btnRefaireTout.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnRefaireTout.Location = New System.Drawing.Point(700, 9)
        Me.btnRefaireTout.Name = "btnRefaireTout"
        Me.btnRefaireTout.Size = New System.Drawing.Size(160, 28)
        Me.btnRefaireTout.TabIndex = 1
        Me.btnRefaireTout.Text = "Tout refaire (IA incluse)"
        Me.btnRefaireTout.UseVisualStyleBackColor = True
        '
        'btnRefaireJson
        '
        Me.btnRefaireJson.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnRefaireJson.Location = New System.Drawing.Point(870, 9)
        Me.btnRefaireJson.Name = "btnRefaireJson"
        Me.btnRefaireJson.Size = New System.Drawing.Size(150, 28)
        Me.btnRefaireJson.TabIndex = 2
        Me.btnRefaireJson.Text = "Refaire le Process JSON"
        Me.btnRefaireJson.UseVisualStyleBackColor = True
        '
        'btnVoirJsonQueue
        '
        Me.btnVoirJsonQueue.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnVoirJsonQueue.Location = New System.Drawing.Point(1030, 9)
        Me.btnVoirJsonQueue.Name = "btnVoirJsonQueue"
        Me.btnVoirJsonQueue.Size = New System.Drawing.Size(130, 28)
        Me.btnVoirJsonQueue.TabIndex = 3
        Me.btnVoirJsonQueue.Text = "Voir le JSON"
        Me.btnVoirJsonQueue.UseVisualStyleBackColor = True
        '
        'tabResult
        '
        Me.tabResult.Controls.Add(Me.splitResult)
        Me.tabResult.Location = New System.Drawing.Point(4, 22)
        Me.tabResult.Name = "tabResult"
        Me.tabResult.Padding = New System.Windows.Forms.Padding(3)
        Me.tabResult.Size = New System.Drawing.Size(1176, 631)
        Me.tabResult.TabIndex = 1
        Me.tabResult.Text = "Résultat (JSON)"
        Me.tabResult.UseVisualStyleBackColor = True
        '
        'splitResult
        '
        Me.splitResult.Dock = System.Windows.Forms.DockStyle.Fill
        Me.splitResult.Location = New System.Drawing.Point(3, 3)
        Me.splitResult.Name = "splitResult"
        Me.splitResult.Orientation = System.Windows.Forms.Orientation.Horizontal
        Me.splitResult.Panel1.Controls.Add(Me.dvLog)
        Me.splitResult.Panel2.Controls.Add(Me.txtJson)
        Me.splitResult.Panel2.Controls.Add(Me.pnlResultBottom)
        Me.splitResult.Size = New System.Drawing.Size(1170, 625)
        Me.splitResult.SplitterDistance = 320
        Me.splitResult.TabIndex = 0
        '
        'dvLog
        '
        Me.dvLog.AllowUserToAddRows = False
        Me.dvLog.AllowUserToDeleteRows = False
        Me.dvLog.AutoGenerateColumns = False
        Me.dvLog.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
        Me.dvLog.Columns.AddRange(New System.Windows.Forms.DataGridViewColumn() {Me.colLId, Me.colLCreated, Me.colLFileName, Me.colLStep, Me.colLResultat, Me.colLMessage, Me.colLDuration, Me.colLInput, Me.colLOutput, Me.colLCost, Me.colLGuid, Me.colLJson})
        Me.dvLog.Dock = System.Windows.Forms.DockStyle.Fill
        Me.dvLog.Location = New System.Drawing.Point(0, 0)
        Me.dvLog.MultiSelect = False
        Me.dvLog.Name = "dvLog"
        Me.dvLog.ReadOnly = True
        Me.dvLog.RowHeadersVisible = False
        Me.dvLog.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect
        Me.dvLog.Size = New System.Drawing.Size(1170, 320)
        Me.dvLog.TabIndex = 0
        '
        'colLId
        '
        Me.colLId.DataPropertyName = "Id"
        Me.colLId.HeaderText = "#"
        Me.colLId.Name = "colLId"
        Me.colLId.ReadOnly = True
        Me.colLId.Width = 60
        '
        'colLCreated
        '
        Me.colLCreated.DataPropertyName = "Created"
        Me.colLCreated.HeaderText = "Quand (UTC)"
        Me.colLCreated.Name = "colLCreated"
        Me.colLCreated.ReadOnly = True
        Me.colLCreated.Width = 130
        '
        'colLFileName
        '
        Me.colLFileName.DataPropertyName = "FileName"
        Me.colLFileName.HeaderText = "Fichier"
        Me.colLFileName.Name = "colLFileName"
        Me.colLFileName.ReadOnly = True
        Me.colLFileName.Width = 200
        '
        'colLStep
        '
        Me.colLStep.DataPropertyName = "Step"
        Me.colLStep.HeaderText = "Étape"
        Me.colLStep.Name = "colLStep"
        Me.colLStep.ReadOnly = True
        Me.colLStep.Width = 110
        '
        'colLResultat
        '
        Me.colLResultat.DataPropertyName = "Resultat"
        Me.colLResultat.HeaderText = "Résultat"
        Me.colLResultat.Name = "colLResultat"
        Me.colLResultat.ReadOnly = True
        Me.colLResultat.Width = 70
        '
        'colLMessage
        '
        Me.colLMessage.DataPropertyName = "Message"
        Me.colLMessage.HeaderText = "Message"
        Me.colLMessage.Name = "colLMessage"
        Me.colLMessage.ReadOnly = True
        Me.colLMessage.Width = 320
        '
        'colLDuration
        '
        Me.colLDuration.DataPropertyName = "DurationMs"
        Me.colLDuration.HeaderText = "ms"
        Me.colLDuration.Name = "colLDuration"
        Me.colLDuration.ReadOnly = True
        Me.colLDuration.Width = 60
        '
        'colLInput
        '
        Me.colLInput.DataPropertyName = "InputToken"
        Me.colLInput.HeaderText = "Tok. in"
        Me.colLInput.Name = "colLInput"
        Me.colLInput.ReadOnly = True
        Me.colLInput.Width = 60
        '
        'colLOutput
        '
        Me.colLOutput.DataPropertyName = "OutputToken"
        Me.colLOutput.HeaderText = "Tok. out"
        Me.colLOutput.Name = "colLOutput"
        Me.colLOutput.ReadOnly = True
        Me.colLOutput.Width = 60
        '
        'colLCost
        '
        Me.colLCost.DataPropertyName = "EstimatedCostUsd"
        Me.colLCost.HeaderText = "Coût USD"
        Me.colLCost.Name = "colLCost"
        Me.colLCost.ReadOnly = True
        Me.colLCost.Width = 80
        '
        'colLGuid
        '
        Me.colLGuid.DataPropertyName = "imageGUID"
        Me.colLGuid.HeaderText = "imageGUID"
        Me.colLGuid.Name = "colLGuid"
        Me.colLGuid.ReadOnly = True
        Me.colLGuid.Visible = False
        '
        'colLJson
        '
        Me.colLJson.DataPropertyName = "AI_JSON"
        Me.colLJson.HeaderText = "AI_JSON"
        Me.colLJson.Name = "colLJson"
        Me.colLJson.ReadOnly = True
        Me.colLJson.Visible = False
        '
        'txtJson
        '
        Me.txtJson.Dock = System.Windows.Forms.DockStyle.Fill
        Me.txtJson.Font = New System.Drawing.Font("Consolas", 9.0!)
        Me.txtJson.Location = New System.Drawing.Point(0, 30)
        Me.txtJson.Multiline = True
        Me.txtJson.Name = "txtJson"
        Me.txtJson.ReadOnly = True
        Me.txtJson.ScrollBars = System.Windows.Forms.ScrollBars.Both
        Me.txtJson.Size = New System.Drawing.Size(1170, 271)
        Me.txtJson.TabIndex = 1
        Me.txtJson.WordWrap = False
        '
        'pnlResultBottom
        '
        Me.pnlResultBottom.Controls.Add(Me.btnCopyJson)
        Me.pnlResultBottom.Controls.Add(Me.lblJsonCaption)
        Me.pnlResultBottom.Dock = System.Windows.Forms.DockStyle.Top
        Me.pnlResultBottom.Location = New System.Drawing.Point(0, 0)
        Me.pnlResultBottom.Name = "pnlResultBottom"
        Me.pnlResultBottom.Size = New System.Drawing.Size(1170, 30)
        Me.pnlResultBottom.TabIndex = 0
        '
        'lblJsonCaption
        '
        Me.lblJsonCaption.AutoSize = True
        Me.lblJsonCaption.Location = New System.Drawing.Point(6, 8)
        Me.lblJsonCaption.Name = "lblJsonCaption"
        Me.lblJsonCaption.Size = New System.Drawing.Size(200, 13)
        Me.lblJsonCaption.TabIndex = 0
        Me.lblJsonCaption.Text = "JSON de la ligne sélectionnée"
        '
        'btnCopyJson
        '
        Me.btnCopyJson.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnCopyJson.Location = New System.Drawing.Point(1040, 3)
        Me.btnCopyJson.Name = "btnCopyJson"
        Me.btnCopyJson.Size = New System.Drawing.Size(120, 24)
        Me.btnCopyJson.TabIndex = 1
        Me.btnCopyJson.Text = "Copier le JSON"
        Me.btnCopyJson.UseVisualStyleBackColor = True
        '
        'tabJournal
        '
        Me.tabJournal.Controls.Add(Me.txtLog)
        Me.tabJournal.Controls.Add(Me.pnlJournalTop)
        Me.tabJournal.Location = New System.Drawing.Point(4, 22)
        Me.tabJournal.Name = "tabJournal"
        Me.tabJournal.Padding = New System.Windows.Forms.Padding(3)
        Me.tabJournal.Size = New System.Drawing.Size(1176, 631)
        Me.tabJournal.TabIndex = 2
        Me.tabJournal.Text = "Journal"
        Me.tabJournal.UseVisualStyleBackColor = True
        '
        'txtLog
        '
        Me.txtLog.Dock = System.Windows.Forms.DockStyle.Fill
        Me.txtLog.Font = New System.Drawing.Font("Consolas", 9.0!)
        Me.txtLog.Location = New System.Drawing.Point(3, 39)
        Me.txtLog.Multiline = True
        Me.txtLog.Name = "txtLog"
        Me.txtLog.ReadOnly = True
        Me.txtLog.ScrollBars = System.Windows.Forms.ScrollBars.Both
        Me.txtLog.Size = New System.Drawing.Size(1170, 589)
        Me.txtLog.TabIndex = 1
        Me.txtLog.WordWrap = False
        '
        'pnlJournalTop
        '
        Me.pnlJournalTop.Controls.Add(Me.btnClearLog)
        Me.pnlJournalTop.Controls.Add(Me.rbError)
        Me.pnlJournalTop.Controls.Add(Me.rbEvent)
        Me.pnlJournalTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.pnlJournalTop.Location = New System.Drawing.Point(3, 3)
        Me.pnlJournalTop.Name = "pnlJournalTop"
        Me.pnlJournalTop.Size = New System.Drawing.Size(1170, 36)
        Me.pnlJournalTop.TabIndex = 0
        '
        'rbEvent
        '
        Me.rbEvent.AutoSize = True
        Me.rbEvent.Checked = True
        Me.rbEvent.Location = New System.Drawing.Point(8, 10)
        Me.rbEvent.Name = "rbEvent"
        Me.rbEvent.Size = New System.Drawing.Size(80, 17)
        Me.rbEvent.TabIndex = 0
        Me.rbEvent.TabStop = True
        Me.rbEvent.Text = "Traitement"
        Me.rbEvent.UseVisualStyleBackColor = True
        '
        'rbError
        '
        Me.rbError.AutoSize = True
        Me.rbError.Location = New System.Drawing.Point(110, 10)
        Me.rbError.Name = "rbError"
        Me.rbError.Size = New System.Drawing.Size(60, 17)
        Me.rbError.TabIndex = 1
        Me.rbError.Text = "Erreurs"
        Me.rbError.UseVisualStyleBackColor = True
        '
        'btnClearLog
        '
        Me.btnClearLog.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnClearLog.Location = New System.Drawing.Point(1030, 5)
        Me.btnClearLog.Name = "btnClearLog"
        Me.btnClearLog.Size = New System.Drawing.Size(130, 26)
        Me.btnClearLog.TabIndex = 2
        Me.btnClearLog.Text = "Vider ce journal"
        Me.btnClearLog.UseVisualStyleBackColor = True
        '
        'Timer1
        '
        Me.Timer1.Interval = 15000
        '
        'Form1
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(1184, 761)
        Me.Controls.Add(Me.tabMain)
        Me.Controls.Add(Me.pnlTop)
        Me.MinimumSize = New System.Drawing.Size(900, 560)
        Me.Name = "Form1"
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
        Me.Text = "Traitement des reçus"
        Me.pnlTop.ResumeLayout(False)
        Me.pnlTop.PerformLayout()
        Me.tabMain.ResumeLayout(False)
        Me.tabQueue.ResumeLayout(False)
        CType(Me.dvQueue, System.ComponentModel.ISupportInitialize).EndInit()
        Me.pnlQueueBottom.ResumeLayout(False)
        Me.pnlQueueBottom.PerformLayout()
        Me.tabResult.ResumeLayout(False)
        Me.splitResult.Panel1.ResumeLayout(False)
        Me.splitResult.Panel2.ResumeLayout(False)
        Me.splitResult.Panel2.PerformLayout()
        CType(Me.splitResult, System.ComponentModel.ISupportInitialize).EndInit()
        Me.splitResult.ResumeLayout(False)
        CType(Me.dvLog, System.ComponentModel.ISupportInitialize).EndInit()
        Me.pnlResultBottom.ResumeLayout(False)
        Me.pnlResultBottom.PerformLayout()
        Me.tabJournal.ResumeLayout(False)
        Me.pnlJournalTop.ResumeLayout(False)
        Me.pnlJournalTop.PerformLayout()
        Me.ResumeLayout(False)
    End Sub

    Friend WithEvents pnlTop As System.Windows.Forms.Panel
    Friend WithEvents lblTitre As System.Windows.Forms.Label
    Friend WithEvents lblEtatCaption As System.Windows.Forms.Label
    Friend WithEvents lblEtat As System.Windows.Forms.Label
    Friend WithEvents lblDernierPassageCaption As System.Windows.Forms.Label
    Friend WithEvents lblDernierPassage As System.Windows.Forms.Label
    Friend WithEvents lblFileCaption As System.Windows.Forms.Label
    Friend WithEvents lblFile As System.Windows.Forms.Label
    Friend WithEvents lblTraitesCaption As System.Windows.Forms.Label
    Friend WithEvents lblTraites As System.Windows.Forms.Label
    Friend WithEvents lblErreursCaption As System.Windows.Forms.Label
    Friend WithEvents lblErreurs As System.Windows.Forms.Label
    Friend WithEvents btnTraiterMaintenant As System.Windows.Forms.Button
    Friend WithEvents btnRefresh As System.Windows.Forms.Button
    Friend WithEvents btnSetting As System.Windows.Forms.Button
    Friend WithEvents tabMain As System.Windows.Forms.TabControl
    Friend WithEvents tabQueue As System.Windows.Forms.TabPage
    Friend WithEvents dvQueue As System.Windows.Forms.DataGridView
    Friend WithEvents colQReceiptId As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colQCreated As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colQFileName As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colQContentType As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colQType As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colQEtat As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colQProchaine As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colQTentatives As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colQErreur As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colQGuid As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents pnlQueueBottom As System.Windows.Forms.Panel
    Friend WithEvents chkOnlyPending As System.Windows.Forms.CheckBox
    Friend WithEvents btnRefaireTout As System.Windows.Forms.Button
    Friend WithEvents btnRefaireJson As System.Windows.Forms.Button
    Friend WithEvents btnVoirJsonQueue As System.Windows.Forms.Button
    Friend WithEvents tabResult As System.Windows.Forms.TabPage
    Friend WithEvents splitResult As System.Windows.Forms.SplitContainer
    Friend WithEvents dvLog As System.Windows.Forms.DataGridView
    Friend WithEvents colLId As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colLCreated As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colLFileName As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colLStep As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colLResultat As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colLMessage As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colLDuration As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colLInput As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colLOutput As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colLCost As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colLGuid As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colLJson As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents txtJson As System.Windows.Forms.TextBox
    Friend WithEvents pnlResultBottom As System.Windows.Forms.Panel
    Friend WithEvents btnCopyJson As System.Windows.Forms.Button
    Friend WithEvents lblJsonCaption As System.Windows.Forms.Label
    Friend WithEvents tabJournal As System.Windows.Forms.TabPage
    Friend WithEvents txtLog As System.Windows.Forms.TextBox
    Friend WithEvents pnlJournalTop As System.Windows.Forms.Panel
    Friend WithEvents rbEvent As System.Windows.Forms.RadioButton
    Friend WithEvents rbError As System.Windows.Forms.RadioButton
    Friend WithEvents btnClearLog As System.Windows.Forms.Button
    Friend WithEvents Timer1 As System.Windows.Forms.Timer

End Class
