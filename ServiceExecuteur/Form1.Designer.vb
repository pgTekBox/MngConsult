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
        Me.lblEtatTitre = New System.Windows.Forms.Label()
        Me.lblEtat = New System.Windows.Forms.Label()
        Me.lblDernierPassageTitre = New System.Windows.Forms.Label()
        Me.lblDernierPassage = New System.Windows.Forms.Label()
        Me.lblFileTitre = New System.Windows.Forms.Label()
        Me.lblFile = New System.Windows.Forms.Label()
        Me.lblAApprouverTitre = New System.Windows.Forms.Label()
        Me.lblAApprouver = New System.Windows.Forms.Label()
        Me.lblSuccesTitre = New System.Windows.Forms.Label()
        Me.lblSucces = New System.Windows.Forms.Label()
        Me.lblEchecsTitre = New System.Windows.Forms.Label()
        Me.lblEchecs = New System.Windows.Forms.Label()
        Me.btnRefresh = New System.Windows.Forms.Button()
        Me.btnExecuterMaintenant = New System.Windows.Forms.Button()
        Me.btnSetting = New System.Windows.Forms.Button()
        Me.tabMain = New System.Windows.Forms.TabControl()
        Me.tabExecutions = New System.Windows.Forms.TabPage()
        Me.dvExecutions = New System.Windows.Forms.DataGridView()
        Me.colXId = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colXJobCode = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colXJobNom = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colXType = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colXStatut = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colXDemarre = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colXTermine = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colXDuree = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colXLignes = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colXWorker = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colXReservee = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.colXMessage = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.pnlExecutionsBas = New System.Windows.Forms.Panel()
        Me.btnVoirDetail = New System.Windows.Forms.Button()
        Me.tabJournal = New System.Windows.Forms.TabPage()
        Me.txtLog = New System.Windows.Forms.TextBox()
        Me.pnlJournalBas = New System.Windows.Forms.Panel()
        Me.rbEvent = New System.Windows.Forms.RadioButton()
        Me.rbError = New System.Windows.Forms.RadioButton()
        Me.btnClearLog = New System.Windows.Forms.Button()
        Me.Timer1 = New System.Windows.Forms.Timer(Me.components)
        Me.pnlTop.SuspendLayout()
        Me.tabMain.SuspendLayout()
        Me.tabExecutions.SuspendLayout()
        CType(Me.dvExecutions, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.pnlExecutionsBas.SuspendLayout()
        Me.tabJournal.SuspendLayout()
        Me.pnlJournalBas.SuspendLayout()
        Me.SuspendLayout()
        '
        'pnlTop
        '
        Me.pnlTop.BackColor = System.Drawing.Color.WhiteSmoke
        Me.pnlTop.Controls.Add(Me.lblEtatTitre)
        Me.pnlTop.Controls.Add(Me.lblEtat)
        Me.pnlTop.Controls.Add(Me.lblDernierPassageTitre)
        Me.pnlTop.Controls.Add(Me.lblDernierPassage)
        Me.pnlTop.Controls.Add(Me.lblFileTitre)
        Me.pnlTop.Controls.Add(Me.lblFile)
        Me.pnlTop.Controls.Add(Me.lblAApprouverTitre)
        Me.pnlTop.Controls.Add(Me.lblAApprouver)
        Me.pnlTop.Controls.Add(Me.lblSuccesTitre)
        Me.pnlTop.Controls.Add(Me.lblSucces)
        Me.pnlTop.Controls.Add(Me.lblEchecsTitre)
        Me.pnlTop.Controls.Add(Me.lblEchecs)
        Me.pnlTop.Controls.Add(Me.btnRefresh)
        Me.pnlTop.Controls.Add(Me.btnExecuterMaintenant)
        Me.pnlTop.Controls.Add(Me.btnSetting)
        Me.pnlTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.pnlTop.Location = New System.Drawing.Point(0, 0)
        Me.pnlTop.Name = "pnlTop"
        Me.pnlTop.Size = New System.Drawing.Size(1084, 96)
        Me.pnlTop.TabIndex = 0
        '
        'lblEtatTitre
        '
        Me.lblEtatTitre.AutoSize = True
        Me.lblEtatTitre.Location = New System.Drawing.Point(12, 14)
        Me.lblEtatTitre.Name = "lblEtatTitre"
        Me.lblEtatTitre.Size = New System.Drawing.Size(32, 13)
        Me.lblEtatTitre.TabIndex = 0
        Me.lblEtatTitre.Text = "État :"
        '
        'lblEtat
        '
        Me.lblEtat.AutoSize = True
        Me.lblEtat.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Bold)
        Me.lblEtat.ForeColor = System.Drawing.Color.DimGray
        Me.lblEtat.Location = New System.Drawing.Point(110, 14)
        Me.lblEtat.Name = "lblEtat"
        Me.lblEtat.Size = New System.Drawing.Size(80, 13)
        Me.lblEtat.TabIndex = 1
        Me.lblEtat.Text = "Service arrêté"
        '
        'lblDernierPassageTitre
        '
        Me.lblDernierPassageTitre.AutoSize = True
        Me.lblDernierPassageTitre.Location = New System.Drawing.Point(12, 38)
        Me.lblDernierPassageTitre.Name = "lblDernierPassageTitre"
        Me.lblDernierPassageTitre.Size = New System.Drawing.Size(92, 13)
        Me.lblDernierPassageTitre.TabIndex = 2
        Me.lblDernierPassageTitre.Text = "Dernier passage :"
        '
        'lblDernierPassage
        '
        Me.lblDernierPassage.AutoSize = True
        Me.lblDernierPassage.Location = New System.Drawing.Point(110, 38)
        Me.lblDernierPassage.Name = "lblDernierPassage"
        Me.lblDernierPassage.Size = New System.Drawing.Size(40, 13)
        Me.lblDernierPassage.TabIndex = 3
        Me.lblDernierPassage.Text = "Jamais"
        '
        'lblFileTitre
        '
        Me.lblFileTitre.AutoSize = True
        Me.lblFileTitre.Location = New System.Drawing.Point(12, 62)
        Me.lblFileTitre.Name = "lblFileTitre"
        Me.lblFileTitre.Size = New System.Drawing.Size(88, 13)
        Me.lblFileTitre.TabIndex = 4
        Me.lblFileTitre.Text = "Tâches à faire :"
        '
        'lblFile
        '
        Me.lblFile.AutoSize = True
        Me.lblFile.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Bold)
        Me.lblFile.Location = New System.Drawing.Point(110, 62)
        Me.lblFile.Name = "lblFile"
        Me.lblFile.Size = New System.Drawing.Size(13, 13)
        Me.lblFile.TabIndex = 5
        Me.lblFile.Text = "0"
        '
        'lblAApprouverTitre
        '
        Me.lblAApprouverTitre.AutoSize = True
        Me.lblAApprouverTitre.Location = New System.Drawing.Point(260, 62)
        Me.lblAApprouverTitre.Name = "lblAApprouverTitre"
        Me.lblAApprouverTitre.Size = New System.Drawing.Size(75, 13)
        Me.lblAApprouverTitre.TabIndex = 6
        Me.lblAApprouverTitre.Text = "À approuver :"
        '
        'lblAApprouver
        '
        Me.lblAApprouver.AutoSize = True
        Me.lblAApprouver.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Bold)
        Me.lblAApprouver.ForeColor = System.Drawing.Color.DarkOrange
        Me.lblAApprouver.Location = New System.Drawing.Point(345, 62)
        Me.lblAApprouver.Name = "lblAApprouver"
        Me.lblAApprouver.Size = New System.Drawing.Size(13, 13)
        Me.lblAApprouver.TabIndex = 7
        Me.lblAApprouver.Text = "0"
        '
        'lblSuccesTitre
        '
        Me.lblSuccesTitre.AutoSize = True
        Me.lblSuccesTitre.Location = New System.Drawing.Point(430, 62)
        Me.lblSuccesTitre.Name = "lblSuccesTitre"
        Me.lblSuccesTitre.Size = New System.Drawing.Size(48, 13)
        Me.lblSuccesTitre.TabIndex = 8
        Me.lblSuccesTitre.Text = "Succès :"
        '
        'lblSucces
        '
        Me.lblSucces.AutoSize = True
        Me.lblSucces.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Bold)
        Me.lblSucces.ForeColor = System.Drawing.Color.ForestGreen
        Me.lblSucces.Location = New System.Drawing.Point(490, 62)
        Me.lblSucces.Name = "lblSucces"
        Me.lblSucces.Size = New System.Drawing.Size(13, 13)
        Me.lblSucces.TabIndex = 9
        Me.lblSucces.Text = "0"
        '
        'lblEchecsTitre
        '
        Me.lblEchecsTitre.AutoSize = True
        Me.lblEchecsTitre.Location = New System.Drawing.Point(560, 62)
        Me.lblEchecsTitre.Name = "lblEchecsTitre"
        Me.lblEchecsTitre.Size = New System.Drawing.Size(48, 13)
        Me.lblEchecsTitre.TabIndex = 10
        Me.lblEchecsTitre.Text = "Échecs :"
        '
        'lblEchecs
        '
        Me.lblEchecs.AutoSize = True
        Me.lblEchecs.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Bold)
        Me.lblEchecs.ForeColor = System.Drawing.Color.Firebrick
        Me.lblEchecs.Location = New System.Drawing.Point(620, 62)
        Me.lblEchecs.Name = "lblEchecs"
        Me.lblEchecs.Size = New System.Drawing.Size(13, 13)
        Me.lblEchecs.TabIndex = 11
        Me.lblEchecs.Text = "0"
        '
        'btnRefresh
        '
        Me.btnRefresh.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnRefresh.Location = New System.Drawing.Point(775, 12)
        Me.btnRefresh.Name = "btnRefresh"
        Me.btnRefresh.Size = New System.Drawing.Size(140, 26)
        Me.btnRefresh.TabIndex = 12
        Me.btnRefresh.Text = "Rafraîchir"
        Me.btnRefresh.UseVisualStyleBackColor = True
        '
        'btnExecuterMaintenant
        '
        Me.btnExecuterMaintenant.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnExecuterMaintenant.Location = New System.Drawing.Point(775, 44)
        Me.btnExecuterMaintenant.Name = "btnExecuterMaintenant"
        Me.btnExecuterMaintenant.Size = New System.Drawing.Size(140, 26)
        Me.btnExecuterMaintenant.TabIndex = 13
        Me.btnExecuterMaintenant.Text = "Exécuter maintenant"
        Me.btnExecuterMaintenant.UseVisualStyleBackColor = True
        '
        'btnSetting
        '
        Me.btnSetting.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnSetting.Location = New System.Drawing.Point(929, 12)
        Me.btnSetting.Name = "btnSetting"
        Me.btnSetting.Size = New System.Drawing.Size(140, 26)
        Me.btnSetting.TabIndex = 14
        Me.btnSetting.Text = "Paramètres..."
        Me.btnSetting.UseVisualStyleBackColor = True
        '
        'tabMain
        '
        Me.tabMain.Controls.Add(Me.tabExecutions)
        Me.tabMain.Controls.Add(Me.tabJournal)
        Me.tabMain.Dock = System.Windows.Forms.DockStyle.Fill
        Me.tabMain.Location = New System.Drawing.Point(0, 96)
        Me.tabMain.Name = "tabMain"
        Me.tabMain.SelectedIndex = 0
        Me.tabMain.Size = New System.Drawing.Size(1084, 465)
        Me.tabMain.TabIndex = 1
        '
        'tabExecutions
        '
        Me.tabExecutions.Controls.Add(Me.dvExecutions)
        Me.tabExecutions.Controls.Add(Me.pnlExecutionsBas)
        Me.tabExecutions.Location = New System.Drawing.Point(4, 22)
        Me.tabExecutions.Name = "tabExecutions"
        Me.tabExecutions.Padding = New System.Windows.Forms.Padding(3)
        Me.tabExecutions.Size = New System.Drawing.Size(1076, 439)
        Me.tabExecutions.TabIndex = 0
        Me.tabExecutions.Text = "Exécutions"
        Me.tabExecutions.UseVisualStyleBackColor = True
        '
        'dvExecutions
        '
        Me.dvExecutions.AllowUserToAddRows = False
        Me.dvExecutions.AllowUserToDeleteRows = False
        Me.dvExecutions.AutoGenerateColumns = False
        Me.dvExecutions.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
        Me.dvExecutions.Columns.AddRange(New System.Windows.Forms.DataGridViewColumn() {Me.colXId, Me.colXJobCode, Me.colXJobNom, Me.colXType, Me.colXStatut, Me.colXDemarre, Me.colXTermine, Me.colXDuree, Me.colXLignes, Me.colXWorker, Me.colXReservee, Me.colXMessage})
        Me.dvExecutions.Dock = System.Windows.Forms.DockStyle.Fill
        Me.dvExecutions.Location = New System.Drawing.Point(3, 3)
        Me.dvExecutions.MultiSelect = False
        Me.dvExecutions.Name = "dvExecutions"
        Me.dvExecutions.ReadOnly = True
        Me.dvExecutions.RowHeadersVisible = False
        Me.dvExecutions.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect
        Me.dvExecutions.Size = New System.Drawing.Size(1070, 397)
        Me.dvExecutions.TabIndex = 0
        '
        'colXId
        '
        Me.colXId.DataPropertyName = "ExecutionId"
        Me.colXId.HeaderText = "#"
        Me.colXId.Name = "colXId"
        Me.colXId.ReadOnly = True
        Me.colXId.Width = 55
        '
        'colXJobCode
        '
        Me.colXJobCode.DataPropertyName = "JobCode"
        Me.colXJobCode.HeaderText = "Code"
        Me.colXJobCode.Name = "colXJobCode"
        Me.colXJobCode.ReadOnly = True
        Me.colXJobCode.Width = 150
        '
        'colXJobNom
        '
        Me.colXJobNom.DataPropertyName = "JobNom"
        Me.colXJobNom.HeaderText = "Tâche"
        Me.colXJobNom.Name = "colXJobNom"
        Me.colXJobNom.ReadOnly = True
        Me.colXJobNom.Width = 180
        '
        'colXType
        '
        Me.colXType.DataPropertyName = "HandlerType"
        Me.colXType.HeaderText = "Type"
        Me.colXType.Name = "colXType"
        Me.colXType.ReadOnly = True
        Me.colXType.Width = 80
        '
        'colXStatut
        '
        Me.colXStatut.DataPropertyName = "Statut"
        Me.colXStatut.HeaderText = "Statut"
        Me.colXStatut.Name = "colXStatut"
        Me.colXStatut.ReadOnly = True
        Me.colXStatut.Width = 90
        '
        'colXDemarre
        '
        Me.colXDemarre.DataPropertyName = "Demarre"
        Me.colXDemarre.HeaderText = "Démarrée"
        Me.colXDemarre.Name = "colXDemarre"
        Me.colXDemarre.ReadOnly = True
        Me.colXDemarre.Width = 130
        '
        'colXTermine
        '
        Me.colXTermine.DataPropertyName = "Termine"
        Me.colXTermine.HeaderText = "Terminée"
        Me.colXTermine.Name = "colXTermine"
        Me.colXTermine.ReadOnly = True
        Me.colXTermine.Width = 130
        '
        'colXDuree
        '
        Me.colXDuree.DataPropertyName = "DureeMs"
        Me.colXDuree.HeaderText = "ms"
        Me.colXDuree.Name = "colXDuree"
        Me.colXDuree.ReadOnly = True
        Me.colXDuree.Width = 70
        '
        'colXLignes
        '
        Me.colXLignes.DataPropertyName = "LignesTraitees"
        Me.colXLignes.HeaderText = "Lignes"
        Me.colXLignes.Name = "colXLignes"
        Me.colXLignes.ReadOnly = True
        Me.colXLignes.Width = 60
        '
        'colXWorker
        '
        Me.colXWorker.DataPropertyName = "WorkerName"
        Me.colXWorker.HeaderText = "Exécuteur"
        Me.colXWorker.Name = "colXWorker"
        Me.colXWorker.ReadOnly = True
        Me.colXWorker.Width = 110
        '
        'colXReservee
        '
        Me.colXReservee.DataPropertyName = "Reservee"
        Me.colXReservee.HeaderText = "Verrou"
        Me.colXReservee.Name = "colXReservee"
        Me.colXReservee.ReadOnly = True
        Me.colXReservee.Width = 55
        '
        'colXMessage
        '
        Me.colXMessage.DataPropertyName = "ResultatMessage"
        Me.colXMessage.HeaderText = "Résultat"
        Me.colXMessage.Name = "colXMessage"
        Me.colXMessage.ReadOnly = True
        Me.colXMessage.Width = 320
        '
        'pnlExecutionsBas
        '
        Me.pnlExecutionsBas.Controls.Add(Me.btnVoirDetail)
        Me.pnlExecutionsBas.Dock = System.Windows.Forms.DockStyle.Bottom
        Me.pnlExecutionsBas.Location = New System.Drawing.Point(3, 400)
        Me.pnlExecutionsBas.Name = "pnlExecutionsBas"
        Me.pnlExecutionsBas.Size = New System.Drawing.Size(1070, 36)
        Me.pnlExecutionsBas.TabIndex = 1
        '
        'btnVoirDetail
        '
        Me.btnVoirDetail.Location = New System.Drawing.Point(3, 5)
        Me.btnVoirDetail.Name = "btnVoirDetail"
        Me.btnVoirDetail.Size = New System.Drawing.Size(160, 26)
        Me.btnVoirDetail.TabIndex = 0
        Me.btnVoirDetail.Text = "Voir le détail..."
        Me.btnVoirDetail.UseVisualStyleBackColor = True
        '
        'tabJournal
        '
        Me.tabJournal.Controls.Add(Me.txtLog)
        Me.tabJournal.Controls.Add(Me.pnlJournalBas)
        Me.tabJournal.Location = New System.Drawing.Point(4, 22)
        Me.tabJournal.Name = "tabJournal"
        Me.tabJournal.Padding = New System.Windows.Forms.Padding(3)
        Me.tabJournal.Size = New System.Drawing.Size(1076, 439)
        Me.tabJournal.TabIndex = 1
        Me.tabJournal.Text = "Journal"
        Me.tabJournal.UseVisualStyleBackColor = True
        '
        'txtLog
        '
        Me.txtLog.Dock = System.Windows.Forms.DockStyle.Fill
        Me.txtLog.Font = New System.Drawing.Font("Consolas", 8.25!)
        Me.txtLog.Location = New System.Drawing.Point(3, 3)
        Me.txtLog.Multiline = True
        Me.txtLog.Name = "txtLog"
        Me.txtLog.ReadOnly = True
        Me.txtLog.ScrollBars = System.Windows.Forms.ScrollBars.Both
        Me.txtLog.Size = New System.Drawing.Size(1070, 397)
        Me.txtLog.TabIndex = 0
        Me.txtLog.WordWrap = False
        '
        'pnlJournalBas
        '
        Me.pnlJournalBas.Controls.Add(Me.rbEvent)
        Me.pnlJournalBas.Controls.Add(Me.rbError)
        Me.pnlJournalBas.Controls.Add(Me.btnClearLog)
        Me.pnlJournalBas.Dock = System.Windows.Forms.DockStyle.Bottom
        Me.pnlJournalBas.Location = New System.Drawing.Point(3, 400)
        Me.pnlJournalBas.Name = "pnlJournalBas"
        Me.pnlJournalBas.Size = New System.Drawing.Size(1070, 36)
        Me.pnlJournalBas.TabIndex = 1
        '
        'rbEvent
        '
        Me.rbEvent.AutoSize = True
        Me.rbEvent.Checked = True
        Me.rbEvent.Location = New System.Drawing.Point(6, 9)
        Me.rbEvent.Name = "rbEvent"
        Me.rbEvent.Size = New System.Drawing.Size(80, 17)
        Me.rbEvent.TabIndex = 0
        Me.rbEvent.TabStop = True
        Me.rbEvent.Text = "Exécutions"
        Me.rbEvent.UseVisualStyleBackColor = True
        '
        'rbError
        '
        Me.rbError.AutoSize = True
        Me.rbError.Location = New System.Drawing.Point(100, 9)
        Me.rbError.Name = "rbError"
        Me.rbError.Size = New System.Drawing.Size(63, 17)
        Me.rbError.TabIndex = 1
        Me.rbError.Text = "Erreurs"
        Me.rbError.UseVisualStyleBackColor = True
        '
        'btnClearLog
        '
        Me.btnClearLog.Location = New System.Drawing.Point(200, 5)
        Me.btnClearLog.Name = "btnClearLog"
        Me.btnClearLog.Size = New System.Drawing.Size(160, 26)
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
        Me.ClientSize = New System.Drawing.Size(1084, 561)
        Me.Controls.Add(Me.tabMain)
        Me.Controls.Add(Me.pnlTop)
        Me.MinimumSize = New System.Drawing.Size(900, 480)
        Me.Name = "Form1"
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
        Me.Text = "Exécuteur de tâches"
        Me.pnlTop.ResumeLayout(False)
        Me.pnlTop.PerformLayout()
        Me.tabMain.ResumeLayout(False)
        Me.tabExecutions.ResumeLayout(False)
        CType(Me.dvExecutions, System.ComponentModel.ISupportInitialize).EndInit()
        Me.pnlExecutionsBas.ResumeLayout(False)
        Me.tabJournal.ResumeLayout(False)
        Me.tabJournal.PerformLayout()
        Me.pnlJournalBas.ResumeLayout(False)
        Me.pnlJournalBas.PerformLayout()
        Me.ResumeLayout(False)
    End Sub

    Friend WithEvents pnlTop As System.Windows.Forms.Panel
    Friend WithEvents lblEtatTitre As System.Windows.Forms.Label
    Friend WithEvents lblEtat As System.Windows.Forms.Label
    Friend WithEvents lblDernierPassageTitre As System.Windows.Forms.Label
    Friend WithEvents lblDernierPassage As System.Windows.Forms.Label
    Friend WithEvents lblFileTitre As System.Windows.Forms.Label
    Friend WithEvents lblFile As System.Windows.Forms.Label
    Friend WithEvents lblAApprouverTitre As System.Windows.Forms.Label
    Friend WithEvents lblAApprouver As System.Windows.Forms.Label
    Friend WithEvents lblSuccesTitre As System.Windows.Forms.Label
    Friend WithEvents lblSucces As System.Windows.Forms.Label
    Friend WithEvents lblEchecsTitre As System.Windows.Forms.Label
    Friend WithEvents lblEchecs As System.Windows.Forms.Label
    Friend WithEvents btnRefresh As System.Windows.Forms.Button
    Friend WithEvents btnExecuterMaintenant As System.Windows.Forms.Button
    Friend WithEvents btnSetting As System.Windows.Forms.Button
    Friend WithEvents tabMain As System.Windows.Forms.TabControl
    Friend WithEvents tabExecutions As System.Windows.Forms.TabPage
    Friend WithEvents dvExecutions As System.Windows.Forms.DataGridView
    Friend WithEvents colXId As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colXJobCode As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colXJobNom As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colXType As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colXStatut As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colXDemarre As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colXTermine As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colXDuree As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colXLignes As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colXWorker As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colXReservee As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents colXMessage As System.Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents pnlExecutionsBas As System.Windows.Forms.Panel
    Friend WithEvents btnVoirDetail As System.Windows.Forms.Button
    Friend WithEvents tabJournal As System.Windows.Forms.TabPage
    Friend WithEvents txtLog As System.Windows.Forms.TextBox
    Friend WithEvents pnlJournalBas As System.Windows.Forms.Panel
    Friend WithEvents rbEvent As System.Windows.Forms.RadioButton
    Friend WithEvents rbError As System.Windows.Forms.RadioButton
    Friend WithEvents btnClearLog As System.Windows.Forms.Button
    Friend WithEvents Timer1 As System.Windows.Forms.Timer

End Class
