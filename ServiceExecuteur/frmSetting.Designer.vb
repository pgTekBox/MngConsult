<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class frmSetting
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
        Me.lblConnectionString = New System.Windows.Forms.Label()
        Me.txtConnectionString = New System.Windows.Forms.TextBox()
        Me.lblAdminUrl = New System.Windows.Forms.Label()
        Me.txtAdminUrl = New System.Windows.Forms.TextBox()
        Me.lblInterval = New System.Windows.Forms.Label()
        Me.txtInterval = New System.Windows.Forms.TextBox()
        Me.lblBatch = New System.Windows.Forms.Label()
        Me.txtBatch = New System.Windows.Forms.TextBox()
        Me.lblLock = New System.Windows.Forms.Label()
        Me.txtLock = New System.Windows.Forms.TextBox()
        Me.lblAdminKey = New System.Windows.Forms.Label()
        Me.txtAdminKey = New System.Windows.Forms.TextBox()
        Me.lblPlanning = New System.Windows.Forms.Label()
        Me.txtPlanning = New System.Windows.Forms.TextBox()
        Me.lblPlanningUnite = New System.Windows.Forms.Label()
        Me.chkActif = New System.Windows.Forms.CheckBox()
        Me.btnTester = New System.Windows.Forms.Button()
        Me.btnOk = New System.Windows.Forms.Button()
        Me.btnCancel = New System.Windows.Forms.Button()
        Me.SuspendLayout()
        '
        'lblConnectionString
        '
        Me.lblConnectionString.AutoSize = True
        Me.lblConnectionString.Location = New System.Drawing.Point(14, 18)
        Me.lblConnectionString.Name = "lblConnectionString"
        Me.lblConnectionString.Size = New System.Drawing.Size(120, 13)
        Me.lblConnectionString.TabIndex = 0
        Me.lblConnectionString.Text = "Connexion MngConsul :"
        '
        'txtConnectionString
        '
        Me.txtConnectionString.Location = New System.Drawing.Point(180, 15)
        Me.txtConnectionString.Name = "txtConnectionString"
        Me.txtConnectionString.Size = New System.Drawing.Size(420, 20)
        Me.txtConnectionString.TabIndex = 1
        '
        'lblAdminUrl
        '
        Me.lblAdminUrl.AutoSize = True
        Me.lblAdminUrl.Location = New System.Drawing.Point(14, 46)
        Me.lblAdminUrl.Name = "lblAdminUrl"
        Me.lblAdminUrl.Size = New System.Drawing.Size(122, 13)
        Me.lblAdminUrl.TabIndex = 2
        Me.lblAdminUrl.Text = "Console 60secadmin :"
        '
        'txtAdminUrl
        '
        Me.txtAdminUrl.Location = New System.Drawing.Point(180, 43)
        Me.txtAdminUrl.Name = "txtAdminUrl"
        Me.txtAdminUrl.Size = New System.Drawing.Size(420, 20)
        Me.txtAdminUrl.TabIndex = 3
        '
        'lblInterval
        '
        Me.lblInterval.AutoSize = True
        Me.lblInterval.Location = New System.Drawing.Point(14, 84)
        Me.lblInterval.Name = "lblInterval"
        Me.lblInterval.Size = New System.Drawing.Size(126, 13)
        Me.lblInterval.TabIndex = 4
        Me.lblInterval.Text = "Intervalle (secondes) :"
        '
        'txtInterval
        '
        Me.txtInterval.Location = New System.Drawing.Point(180, 81)
        Me.txtInterval.Name = "txtInterval"
        Me.txtInterval.Size = New System.Drawing.Size(80, 20)
        Me.txtInterval.TabIndex = 5
        '
        'lblBatch
        '
        Me.lblBatch.AutoSize = True
        Me.lblBatch.Location = New System.Drawing.Point(14, 112)
        Me.lblBatch.Name = "lblBatch"
        Me.lblBatch.Size = New System.Drawing.Size(140, 13)
        Me.lblBatch.TabIndex = 6
        Me.lblBatch.Text = "Tâches par passage :"
        '
        'txtBatch
        '
        Me.txtBatch.Location = New System.Drawing.Point(180, 109)
        Me.txtBatch.Name = "txtBatch"
        Me.txtBatch.Size = New System.Drawing.Size(80, 20)
        Me.txtBatch.TabIndex = 7
        '
        'lblLock
        '
        Me.lblLock.AutoSize = True
        Me.lblLock.Location = New System.Drawing.Point(14, 140)
        Me.lblLock.Name = "lblLock"
        Me.lblLock.Size = New System.Drawing.Size(140, 13)
        Me.lblLock.TabIndex = 8
        Me.lblLock.Text = "Verrou (secondes) :"
        '
        'txtLock
        '
        Me.txtLock.Location = New System.Drawing.Point(180, 137)
        Me.txtLock.Name = "txtLock"
        Me.txtLock.Size = New System.Drawing.Size(80, 20)
        Me.txtLock.TabIndex = 9
        '
        'lblAdminKey
        '
        Me.lblAdminKey.AutoSize = True
        Me.lblAdminKey.Location = New System.Drawing.Point(14, 178)
        Me.lblAdminKey.Name = "lblAdminKey"
        Me.lblAdminKey.Size = New System.Drawing.Size(140, 13)
        Me.lblAdminKey.TabIndex = 10
        Me.lblAdminKey.Text = "Clé partagée :"
        '
        'txtAdminKey
        '
        Me.txtAdminKey.Location = New System.Drawing.Point(180, 175)
        Me.txtAdminKey.Name = "txtAdminKey"
        Me.txtAdminKey.Size = New System.Drawing.Size(240, 20)
        Me.txtAdminKey.TabIndex = 11
        '
        'lblPlanning
        '
        Me.lblPlanning.AutoSize = True
        Me.lblPlanning.Location = New System.Drawing.Point(14, 206)
        Me.lblPlanning.Name = "lblPlanning"
        Me.lblPlanning.Size = New System.Drawing.Size(150, 13)
        Me.lblPlanning.TabIndex = 12
        Me.lblPlanning.Text = "Planning : rafraîchir (min) :"
        '
        'txtPlanning
        '
        Me.txtPlanning.Location = New System.Drawing.Point(180, 203)
        Me.txtPlanning.Name = "txtPlanning"
        Me.txtPlanning.Size = New System.Drawing.Size(60, 20)
        Me.txtPlanning.TabIndex = 13
        '
        'lblPlanningUnite
        '
        Me.lblPlanningUnite.AutoSize = True
        Me.lblPlanningUnite.Location = New System.Drawing.Point(248, 206)
        Me.lblPlanningUnite.Name = "lblPlanningUnite"
        Me.lblPlanningUnite.Size = New System.Drawing.Size(80, 13)
        Me.lblPlanningUnite.TabIndex = 14
        Me.lblPlanningUnite.Text = "0 = jamais"
        '
        '
        '
        'chkActif
        '
        Me.chkActif.AutoSize = True
        Me.chkActif.Location = New System.Drawing.Point(180, 240)
        Me.chkActif.Name = "chkActif"
        Me.chkActif.Size = New System.Drawing.Size(220, 17)
        Me.chkActif.TabIndex = 16
        Me.chkActif.Text = "Le service exécute les tâches"
        Me.chkActif.UseVisualStyleBackColor = True
        '
        'btnTester
        '
        Me.btnTester.Location = New System.Drawing.Point(17, 280)
        Me.btnTester.Name = "btnTester"
        Me.btnTester.Size = New System.Drawing.Size(160, 28)
        Me.btnTester.TabIndex = 17
        Me.btnTester.Text = "Tester la connexion"
        Me.btnTester.UseVisualStyleBackColor = True
        '
        'btnOk
        '
        Me.btnOk.Location = New System.Drawing.Point(370, 280)
        Me.btnOk.Name = "btnOk"
        Me.btnOk.Size = New System.Drawing.Size(110, 28)
        Me.btnOk.TabIndex = 18
        Me.btnOk.Text = "Enregistrer"
        Me.btnOk.UseVisualStyleBackColor = True
        '
        'btnCancel
        '
        Me.btnCancel.Location = New System.Drawing.Point(490, 280)
        Me.btnCancel.Name = "btnCancel"
        Me.btnCancel.Size = New System.Drawing.Size(110, 28)
        Me.btnCancel.TabIndex = 19
        Me.btnCancel.Text = "Annuler"
        Me.btnCancel.UseVisualStyleBackColor = True
        '
        'frmSetting
        '
        Me.AcceptButton = Me.btnOk
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.CancelButton = Me.btnCancel
        Me.ClientSize = New System.Drawing.Size(620, 328)
        Me.Controls.Add(Me.lblConnectionString)
        Me.Controls.Add(Me.txtConnectionString)
        Me.Controls.Add(Me.lblAdminUrl)
        Me.Controls.Add(Me.txtAdminUrl)
        Me.Controls.Add(Me.lblInterval)
        Me.Controls.Add(Me.txtInterval)
        Me.Controls.Add(Me.lblBatch)
        Me.Controls.Add(Me.txtBatch)
        Me.Controls.Add(Me.lblLock)
        Me.Controls.Add(Me.txtLock)
        Me.Controls.Add(Me.lblAdminKey)
        Me.Controls.Add(Me.txtAdminKey)
        Me.Controls.Add(Me.lblPlanning)
        Me.Controls.Add(Me.txtPlanning)
        Me.Controls.Add(Me.lblPlanningUnite)
        Me.Controls.Add(Me.chkActif)
        Me.Controls.Add(Me.btnTester)
        Me.Controls.Add(Me.btnOk)
        Me.Controls.Add(Me.btnCancel)
        Me.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog
        Me.MaximizeBox = False
        Me.MinimizeBox = False
        Me.Name = "frmSetting"
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent
        Me.Text = "Paramètres du service"
        Me.ResumeLayout(False)
        Me.PerformLayout()
    End Sub

    Friend WithEvents lblConnectionString As System.Windows.Forms.Label
    Friend WithEvents txtConnectionString As System.Windows.Forms.TextBox
    Friend WithEvents lblAdminUrl As System.Windows.Forms.Label
    Friend WithEvents txtAdminUrl As System.Windows.Forms.TextBox
    Friend WithEvents lblInterval As System.Windows.Forms.Label
    Friend WithEvents txtInterval As System.Windows.Forms.TextBox
    Friend WithEvents lblBatch As System.Windows.Forms.Label
    Friend WithEvents txtBatch As System.Windows.Forms.TextBox
    Friend WithEvents lblLock As System.Windows.Forms.Label
    Friend WithEvents txtLock As System.Windows.Forms.TextBox
    Friend WithEvents lblAdminKey As System.Windows.Forms.Label
    Friend WithEvents txtAdminKey As System.Windows.Forms.TextBox
    Friend WithEvents lblPlanning As System.Windows.Forms.Label
    Friend WithEvents txtPlanning As System.Windows.Forms.TextBox
    Friend WithEvents lblPlanningUnite As System.Windows.Forms.Label
    Friend WithEvents chkActif As System.Windows.Forms.CheckBox
    Friend WithEvents btnTester As System.Windows.Forms.Button
    Friend WithEvents btnOk As System.Windows.Forms.Button
    Friend WithEvents btnCancel As System.Windows.Forms.Button

End Class
