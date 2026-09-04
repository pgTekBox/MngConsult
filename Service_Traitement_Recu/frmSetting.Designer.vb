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
        Me.lblInterval = New System.Windows.Forms.Label()
        Me.txtInterval = New System.Windows.Forms.TextBox()
        Me.lblBatch = New System.Windows.Forms.Label()
        Me.txtBatch = New System.Windows.Forms.TextBox()
        Me.lblMaxAttempts = New System.Windows.Forms.Label()
        Me.txtMaxAttempts = New System.Windows.Forms.TextBox()
        Me.lblLock = New System.Windows.Forms.Label()
        Me.txtLock = New System.Windows.Forms.TextBox()
        Me.lblImageWidth = New System.Windows.Forms.Label()
        Me.txtImageWidth = New System.Windows.Forms.TextBox()
        Me.lblJpegQuality = New System.Windows.Forms.Label()
        Me.txtJpegQuality = New System.Windows.Forms.TextBox()
        Me.chkActif = New System.Windows.Forms.CheckBox()
        Me.btnTester = New System.Windows.Forms.Button()
        Me.btnOk = New System.Windows.Forms.Button()
        Me.btnCancel = New System.Windows.Forms.Button()
        Me.lblAide = New System.Windows.Forms.Label()
        Me.SuspendLayout()
        '
        'lblConnectionString
        '
        Me.lblConnectionString.AutoSize = True
        Me.lblConnectionString.Location = New System.Drawing.Point(16, 18)
        Me.lblConnectionString.Name = "lblConnectionString"
        Me.lblConnectionString.Size = New System.Drawing.Size(150, 13)
        Me.lblConnectionString.TabIndex = 0
        Me.lblConnectionString.Text = "Chaîne de connexion (MngConsul)"
        '
        'txtConnectionString
        '
        Me.txtConnectionString.Anchor = CType(((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Left) Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.txtConnectionString.Location = New System.Drawing.Point(19, 36)
        Me.txtConnectionString.Multiline = True
        Me.txtConnectionString.Name = "txtConnectionString"
        Me.txtConnectionString.Size = New System.Drawing.Size(590, 48)
        Me.txtConnectionString.TabIndex = 1
        '
        'lblInterval
        '
        Me.lblInterval.AutoSize = True
        Me.lblInterval.Location = New System.Drawing.Point(16, 102)
        Me.lblInterval.Name = "lblInterval"
        Me.lblInterval.Size = New System.Drawing.Size(160, 13)
        Me.lblInterval.TabIndex = 2
        Me.lblInterval.Text = "Intervalle entre deux passages (s)"
        '
        'txtInterval
        '
        Me.txtInterval.Location = New System.Drawing.Point(240, 99)
        Me.txtInterval.Name = "txtInterval"
        Me.txtInterval.Size = New System.Drawing.Size(80, 20)
        Me.txtInterval.TabIndex = 3
        '
        'lblBatch
        '
        Me.lblBatch.AutoSize = True
        Me.lblBatch.Location = New System.Drawing.Point(16, 132)
        Me.lblBatch.Name = "lblBatch"
        Me.lblBatch.Size = New System.Drawing.Size(180, 13)
        Me.lblBatch.TabIndex = 4
        Me.lblBatch.Text = "Reçus traités par passage"
        '
        'txtBatch
        '
        Me.txtBatch.Location = New System.Drawing.Point(240, 129)
        Me.txtBatch.Name = "txtBatch"
        Me.txtBatch.Size = New System.Drawing.Size(80, 20)
        Me.txtBatch.TabIndex = 5
        '
        'lblMaxAttempts
        '
        Me.lblMaxAttempts.AutoSize = True
        Me.lblMaxAttempts.Location = New System.Drawing.Point(16, 162)
        Me.lblMaxAttempts.Name = "lblMaxAttempts"
        Me.lblMaxAttempts.Size = New System.Drawing.Size(180, 13)
        Me.lblMaxAttempts.TabIndex = 6
        Me.lblMaxAttempts.Text = "Tentatives avant abandon"
        '
        'txtMaxAttempts
        '
        Me.txtMaxAttempts.Location = New System.Drawing.Point(240, 159)
        Me.txtMaxAttempts.Name = "txtMaxAttempts"
        Me.txtMaxAttempts.Size = New System.Drawing.Size(80, 20)
        Me.txtMaxAttempts.TabIndex = 7
        '
        'lblLock
        '
        Me.lblLock.AutoSize = True
        Me.lblLock.Location = New System.Drawing.Point(16, 192)
        Me.lblLock.Name = "lblLock"
        Me.lblLock.Size = New System.Drawing.Size(180, 13)
        Me.lblLock.TabIndex = 8
        Me.lblLock.Text = "Durée du verrou par reçu (s)"
        '
        'txtLock
        '
        Me.txtLock.Location = New System.Drawing.Point(240, 189)
        Me.txtLock.Name = "txtLock"
        Me.txtLock.Size = New System.Drawing.Size(80, 20)
        Me.txtLock.TabIndex = 9
        '
        'lblImageWidth
        '
        Me.lblImageWidth.AutoSize = True
        Me.lblImageWidth.Location = New System.Drawing.Point(360, 132)
        Me.lblImageWidth.Name = "lblImageWidth"
        Me.lblImageWidth.Size = New System.Drawing.Size(140, 13)
        Me.lblImageWidth.TabIndex = 10
        Me.lblImageWidth.Text = "Largeur max. image (px)"
        '
        'txtImageWidth
        '
        Me.txtImageWidth.Location = New System.Drawing.Point(529, 129)
        Me.txtImageWidth.Name = "txtImageWidth"
        Me.txtImageWidth.Size = New System.Drawing.Size(80, 20)
        Me.txtImageWidth.TabIndex = 11
        '
        'lblJpegQuality
        '
        Me.lblJpegQuality.AutoSize = True
        Me.lblJpegQuality.Location = New System.Drawing.Point(360, 162)
        Me.lblJpegQuality.Name = "lblJpegQuality"
        Me.lblJpegQuality.Size = New System.Drawing.Size(140, 13)
        Me.lblJpegQuality.TabIndex = 12
        Me.lblJpegQuality.Text = "Qualité JPEG (20-95)"
        '
        'txtJpegQuality
        '
        Me.txtJpegQuality.Location = New System.Drawing.Point(529, 159)
        Me.txtJpegQuality.Name = "txtJpegQuality"
        Me.txtJpegQuality.Size = New System.Drawing.Size(80, 20)
        Me.txtJpegQuality.TabIndex = 13
        '
        'chkActif
        '
        Me.chkActif.AutoSize = True
        Me.chkActif.Location = New System.Drawing.Point(363, 101)
        Me.chkActif.Name = "chkActif"
        Me.chkActif.Size = New System.Drawing.Size(200, 17)
        Me.chkActif.TabIndex = 14
        Me.chkActif.Text = "Traitement actif"
        Me.chkActif.UseVisualStyleBackColor = True
        '
        'lblAide
        '
        Me.lblAide.ForeColor = System.Drawing.Color.DimGray
        Me.lblAide.Location = New System.Drawing.Point(16, 222)
        Me.lblAide.Name = "lblAide"
        Me.lblAide.Size = New System.Drawing.Size(593, 46)
        Me.lblAide.TabIndex = 15
        Me.lblAide.Text = "La clé OpenAI et le prompt ne sont pas ici : le service les lit dans la base (paramètres CHATGPT et PROMPT_RECEIPT), comme le fait l'application web."
        '
        'btnTester
        '
        Me.btnTester.Location = New System.Drawing.Point(19, 278)
        Me.btnTester.Name = "btnTester"
        Me.btnTester.Size = New System.Drawing.Size(160, 30)
        Me.btnTester.TabIndex = 16
        Me.btnTester.Text = "Tester la connexion"
        Me.btnTester.UseVisualStyleBackColor = True
        '
        'btnOk
        '
        Me.btnOk.Location = New System.Drawing.Point(409, 278)
        Me.btnOk.Name = "btnOk"
        Me.btnOk.Size = New System.Drawing.Size(90, 30)
        Me.btnOk.TabIndex = 17
        Me.btnOk.Text = "Enregistrer"
        Me.btnOk.UseVisualStyleBackColor = True
        '
        'btnCancel
        '
        Me.btnCancel.Location = New System.Drawing.Point(519, 278)
        Me.btnCancel.Name = "btnCancel"
        Me.btnCancel.Size = New System.Drawing.Size(90, 30)
        Me.btnCancel.TabIndex = 18
        Me.btnCancel.Text = "Annuler"
        Me.btnCancel.UseVisualStyleBackColor = True
        '
        'frmSetting
        '
        Me.AcceptButton = Me.btnOk
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.CancelButton = Me.btnCancel
        Me.ClientSize = New System.Drawing.Size(628, 326)
        Me.Controls.Add(Me.btnCancel)
        Me.Controls.Add(Me.btnOk)
        Me.Controls.Add(Me.btnTester)
        Me.Controls.Add(Me.lblAide)
        Me.Controls.Add(Me.chkActif)
        Me.Controls.Add(Me.txtJpegQuality)
        Me.Controls.Add(Me.lblJpegQuality)
        Me.Controls.Add(Me.txtImageWidth)
        Me.Controls.Add(Me.lblImageWidth)
        Me.Controls.Add(Me.txtLock)
        Me.Controls.Add(Me.lblLock)
        Me.Controls.Add(Me.txtMaxAttempts)
        Me.Controls.Add(Me.lblMaxAttempts)
        Me.Controls.Add(Me.txtBatch)
        Me.Controls.Add(Me.lblBatch)
        Me.Controls.Add(Me.txtInterval)
        Me.Controls.Add(Me.lblInterval)
        Me.Controls.Add(Me.txtConnectionString)
        Me.Controls.Add(Me.lblConnectionString)
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
    Friend WithEvents lblInterval As System.Windows.Forms.Label
    Friend WithEvents txtInterval As System.Windows.Forms.TextBox
    Friend WithEvents lblBatch As System.Windows.Forms.Label
    Friend WithEvents txtBatch As System.Windows.Forms.TextBox
    Friend WithEvents lblMaxAttempts As System.Windows.Forms.Label
    Friend WithEvents txtMaxAttempts As System.Windows.Forms.TextBox
    Friend WithEvents lblLock As System.Windows.Forms.Label
    Friend WithEvents txtLock As System.Windows.Forms.TextBox
    Friend WithEvents lblImageWidth As System.Windows.Forms.Label
    Friend WithEvents txtImageWidth As System.Windows.Forms.TextBox
    Friend WithEvents lblJpegQuality As System.Windows.Forms.Label
    Friend WithEvents txtJpegQuality As System.Windows.Forms.TextBox
    Friend WithEvents chkActif As System.Windows.Forms.CheckBox
    Friend WithEvents lblAide As System.Windows.Forms.Label
    Friend WithEvents btnTester As System.Windows.Forms.Button
    Friend WithEvents btnOk As System.Windows.Forms.Button
    Friend WithEvents btnCancel As System.Windows.Forms.Button

End Class
