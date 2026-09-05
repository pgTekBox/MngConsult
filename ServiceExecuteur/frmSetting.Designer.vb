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
        Me.lblConnectionStringMail = New System.Windows.Forms.Label()
        Me.txtConnectionStringMail = New System.Windows.Forms.TextBox()
        Me.lblInterval = New System.Windows.Forms.Label()
        Me.txtInterval = New System.Windows.Forms.TextBox()
        Me.lblBatch = New System.Windows.Forms.Label()
        Me.txtBatch = New System.Windows.Forms.TextBox()
        Me.lblLock = New System.Windows.Forms.Label()
        Me.txtLock = New System.Windows.Forms.TextBox()
        Me.lblMailSender = New System.Windows.Forms.Label()
        Me.txtMailSender = New System.Windows.Forms.TextBox()
        Me.lblRelance = New System.Windows.Forms.Label()
        Me.txtRelanceAvant = New System.Windows.Forms.TextBox()
        Me.lblRelanceEntre = New System.Windows.Forms.Label()
        Me.txtRelanceApres = New System.Windows.Forms.TextBox()
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
        'lblConnectionStringMail
        '
        Me.lblConnectionStringMail.AutoSize = True
        Me.lblConnectionStringMail.Location = New System.Drawing.Point(14, 46)
        Me.lblConnectionStringMail.Name = "lblConnectionStringMail"
        Me.lblConnectionStringMail.Size = New System.Drawing.Size(122, 13)
        Me.lblConnectionStringMail.TabIndex = 2
        Me.lblConnectionStringMail.Text = "Connexion MailService :"
        '
        'txtConnectionStringMail
        '
        Me.txtConnectionStringMail.Location = New System.Drawing.Point(180, 43)
        Me.txtConnectionStringMail.Name = "txtConnectionStringMail"
        Me.txtConnectionStringMail.Size = New System.Drawing.Size(420, 20)
        Me.txtConnectionStringMail.TabIndex = 3
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
        'lblMailSender
        '
        Me.lblMailSender.AutoSize = True
        Me.lblMailSender.Location = New System.Drawing.Point(14, 178)
        Me.lblMailSender.Name = "lblMailSender"
        Me.lblMailSender.Size = New System.Drawing.Size(140, 13)
        Me.lblMailSender.TabIndex = 10
        Me.lblMailSender.Text = "Expéditeur des courriels :"
        '
        'txtMailSender
        '
        Me.txtMailSender.Location = New System.Drawing.Point(180, 175)
        Me.txtMailSender.Name = "txtMailSender"
        Me.txtMailSender.Size = New System.Drawing.Size(240, 20)
        Me.txtMailSender.TabIndex = 11
        '
        'lblRelance
        '
        Me.lblRelance.AutoSize = True
        Me.lblRelance.Location = New System.Drawing.Point(14, 206)
        Me.lblRelance.Name = "lblRelance"
        Me.lblRelance.Size = New System.Drawing.Size(150, 13)
        Me.lblRelance.TabIndex = 12
        Me.lblRelance.Text = "Relance : jours avant / après :"
        '
        'txtRelanceAvant
        '
        Me.txtRelanceAvant.Location = New System.Drawing.Point(180, 203)
        Me.txtRelanceAvant.Name = "txtRelanceAvant"
        Me.txtRelanceAvant.Size = New System.Drawing.Size(60, 20)
        Me.txtRelanceAvant.TabIndex = 13
        '
        'lblRelanceEntre
        '
        Me.lblRelanceEntre.AutoSize = True
        Me.lblRelanceEntre.Location = New System.Drawing.Point(248, 206)
        Me.lblRelanceEntre.Name = "lblRelanceEntre"
        Me.lblRelanceEntre.Size = New System.Drawing.Size(10, 13)
        Me.lblRelanceEntre.TabIndex = 14
        Me.lblRelanceEntre.Text = "/"
        '
        'txtRelanceApres
        '
        Me.txtRelanceApres.Location = New System.Drawing.Point(266, 203)
        Me.txtRelanceApres.Name = "txtRelanceApres"
        Me.txtRelanceApres.Size = New System.Drawing.Size(60, 20)
        Me.txtRelanceApres.TabIndex = 15
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
        Me.Controls.Add(Me.lblConnectionStringMail)
        Me.Controls.Add(Me.txtConnectionStringMail)
        Me.Controls.Add(Me.lblInterval)
        Me.Controls.Add(Me.txtInterval)
        Me.Controls.Add(Me.lblBatch)
        Me.Controls.Add(Me.txtBatch)
        Me.Controls.Add(Me.lblLock)
        Me.Controls.Add(Me.txtLock)
        Me.Controls.Add(Me.lblMailSender)
        Me.Controls.Add(Me.txtMailSender)
        Me.Controls.Add(Me.lblRelance)
        Me.Controls.Add(Me.txtRelanceAvant)
        Me.Controls.Add(Me.lblRelanceEntre)
        Me.Controls.Add(Me.txtRelanceApres)
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
    Friend WithEvents lblConnectionStringMail As System.Windows.Forms.Label
    Friend WithEvents txtConnectionStringMail As System.Windows.Forms.TextBox
    Friend WithEvents lblInterval As System.Windows.Forms.Label
    Friend WithEvents txtInterval As System.Windows.Forms.TextBox
    Friend WithEvents lblBatch As System.Windows.Forms.Label
    Friend WithEvents txtBatch As System.Windows.Forms.TextBox
    Friend WithEvents lblLock As System.Windows.Forms.Label
    Friend WithEvents txtLock As System.Windows.Forms.TextBox
    Friend WithEvents lblMailSender As System.Windows.Forms.Label
    Friend WithEvents txtMailSender As System.Windows.Forms.TextBox
    Friend WithEvents lblRelance As System.Windows.Forms.Label
    Friend WithEvents txtRelanceAvant As System.Windows.Forms.TextBox
    Friend WithEvents lblRelanceEntre As System.Windows.Forms.Label
    Friend WithEvents txtRelanceApres As System.Windows.Forms.TextBox
    Friend WithEvents chkActif As System.Windows.Forms.CheckBox
    Friend WithEvents btnTester As System.Windows.Forms.Button
    Friend WithEvents btnOk As System.Windows.Forms.Button
    Friend WithEvents btnCancel As System.Windows.Forms.Button

End Class
