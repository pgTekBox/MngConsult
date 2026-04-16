<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class frmSetting
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
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

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.components = New System.ComponentModel.Container()
        Me.btnCancel = New System.Windows.Forms.Button()
        Me.btnOk = New System.Windows.Forms.Button()
        Me.Label12 = New System.Windows.Forms.Label()
        Me.txtConnectionString = New System.Windows.Forms.TextBox()
        Me.TabControl1 = New System.Windows.Forms.TabControl()
        Me.TabPage1 = New System.Windows.Forms.TabPage()
        Me.chkUseDatabase = New System.Windows.Forms.CheckBox()
        Me.txtPort = New System.Windows.Forms.TextBox()
        Me.Label2 = New System.Windows.Forms.Label()
        Me.Label1 = New System.Windows.Forms.Label()
        Me.txtAddress = New System.Windows.Forms.TextBox()
        Me.TabPage2 = New System.Windows.Forms.TabPage()
        Me.dvListDomain = New System.Windows.Forms.DataGridView()
        Me.DomaineName = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.UseUndefinedUser = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.btnRemoveDomaine = New System.Windows.Forms.Button()
        Me.btnAddDomaine = New System.Windows.Forms.Button()
        Me.ToolTip1 = New System.Windows.Forms.ToolTip(Me.components)
        Me.TabControl1.SuspendLayout()
        Me.TabPage1.SuspendLayout()
        Me.TabPage2.SuspendLayout()
        CType(Me.dvListDomain, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.SuspendLayout()
        '
        'btnCancel
        '
        Me.btnCancel.Location = New System.Drawing.Point(484, 257)
        Me.btnCancel.Name = "btnCancel"
        Me.btnCancel.Size = New System.Drawing.Size(75, 23)
        Me.btnCancel.TabIndex = 3
        Me.btnCancel.Text = "Cancel"
        Me.btnCancel.UseVisualStyleBackColor = True
        '
        'btnOk
        '
        Me.btnOk.Location = New System.Drawing.Point(390, 257)
        Me.btnOk.Name = "btnOk"
        Me.btnOk.Size = New System.Drawing.Size(75, 23)
        Me.btnOk.TabIndex = 4
        Me.btnOk.Text = "Ok"
        Me.btnOk.UseVisualStyleBackColor = True
        '
        'Label12
        '
        Me.Label12.AutoSize = True
        Me.Label12.Location = New System.Drawing.Point(6, 16)
        Me.Label12.Name = "Label12"
        Me.Label12.Size = New System.Drawing.Size(109, 13)
        Me.Label12.TabIndex = 23
        Me.Label12.Text = "Database connection"
        '
        'txtConnectionString
        '
        Me.txtConnectionString.Location = New System.Drawing.Point(6, 32)
        Me.txtConnectionString.Name = "txtConnectionString"
        Me.txtConnectionString.Size = New System.Drawing.Size(519, 20)
        Me.txtConnectionString.TabIndex = 24
        Me.txtConnectionString.WordWrap = False
        '
        'TabControl1
        '
        Me.TabControl1.Controls.Add(Me.TabPage1)
        Me.TabControl1.Controls.Add(Me.TabPage2)
        Me.TabControl1.Location = New System.Drawing.Point(9, 12)
        Me.TabControl1.Name = "TabControl1"
        Me.TabControl1.SelectedIndex = 0
        Me.TabControl1.Size = New System.Drawing.Size(550, 239)
        Me.TabControl1.TabIndex = 30
        '
        'TabPage1
        '
        Me.TabPage1.Controls.Add(Me.chkUseDatabase)
        Me.TabPage1.Controls.Add(Me.txtPort)
        Me.TabPage1.Controls.Add(Me.Label2)
        Me.TabPage1.Controls.Add(Me.Label1)
        Me.TabPage1.Controls.Add(Me.txtAddress)
        Me.TabPage1.Controls.Add(Me.Label12)
        Me.TabPage1.Controls.Add(Me.txtConnectionString)
        Me.TabPage1.Location = New System.Drawing.Point(4, 22)
        Me.TabPage1.Name = "TabPage1"
        Me.TabPage1.Padding = New System.Windows.Forms.Padding(3)
        Me.TabPage1.Size = New System.Drawing.Size(542, 213)
        Me.TabPage1.TabIndex = 0
        Me.TabPage1.Text = "Configuration"
        Me.TabPage1.UseVisualStyleBackColor = True
        '
        'chkUseDatabase
        '
        Me.chkUseDatabase.AutoSize = True
        Me.chkUseDatabase.Location = New System.Drawing.Point(394, 71)
        Me.chkUseDatabase.Name = "chkUseDatabase"
        Me.chkUseDatabase.Size = New System.Drawing.Size(86, 17)
        Me.chkUseDatabase.TabIndex = 29
        Me.chkUseDatabase.Text = "Use databse"
        Me.chkUseDatabase.UseVisualStyleBackColor = True
        '
        'txtPort
        '
        Me.txtPort.Location = New System.Drawing.Point(126, 100)
        Me.txtPort.Name = "txtPort"
        Me.txtPort.Size = New System.Drawing.Size(73, 20)
        Me.txtPort.TabIndex = 28
        '
        'Label2
        '
        Me.Label2.AutoSize = True
        Me.Label2.Location = New System.Drawing.Point(6, 103)
        Me.Label2.Name = "Label2"
        Me.Label2.Size = New System.Drawing.Size(83, 13)
        Me.Label2.TabIndex = 27
        Me.Label2.Text = "Numéro du port:"
        '
        'Label1
        '
        Me.Label1.AutoSize = True
        Me.Label1.Location = New System.Drawing.Point(6, 71)
        Me.Label1.Name = "Label1"
        Me.Label1.Size = New System.Drawing.Size(114, 13)
        Me.Label1.TabIndex = 26
        Me.Label1.Text = "Adresse IP du serveur:"
        '
        'txtAddress
        '
        Me.txtAddress.Location = New System.Drawing.Point(126, 68)
        Me.txtAddress.Name = "txtAddress"
        Me.txtAddress.Size = New System.Drawing.Size(228, 20)
        Me.txtAddress.TabIndex = 25
        '
        'TabPage2
        '
        Me.TabPage2.Controls.Add(Me.dvListDomain)
        Me.TabPage2.Controls.Add(Me.btnRemoveDomaine)
        Me.TabPage2.Controls.Add(Me.btnAddDomaine)
        Me.TabPage2.Location = New System.Drawing.Point(4, 22)
        Me.TabPage2.Name = "TabPage2"
        Me.TabPage2.Padding = New System.Windows.Forms.Padding(3)
        Me.TabPage2.Size = New System.Drawing.Size(542, 213)
        Me.TabPage2.TabIndex = 1
        Me.TabPage2.Text = "Domaine"
        Me.TabPage2.UseVisualStyleBackColor = True
        '
        'dvListDomain
        '
        Me.dvListDomain.AllowUserToAddRows = False
        Me.dvListDomain.AllowUserToDeleteRows = False
        Me.dvListDomain.AllowUserToResizeRows = False
        Me.dvListDomain.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.dvListDomain.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
        Me.dvListDomain.Columns.AddRange(New System.Windows.Forms.DataGridViewColumn() {Me.DomaineName, Me.UseUndefinedUser})
        Me.dvListDomain.Location = New System.Drawing.Point(6, 6)
        Me.dvListDomain.MultiSelect = False
        Me.dvListDomain.Name = "dvListDomain"
        Me.dvListDomain.ReadOnly = True
        Me.dvListDomain.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect
        Me.dvListDomain.ShowEditingIcon = False
        Me.dvListDomain.Size = New System.Drawing.Size(309, 201)
        Me.dvListDomain.TabIndex = 64
        '
        'DomaineName
        '
        Me.DomaineName.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill
        Me.DomaineName.DataPropertyName = "DomaineName"
        Me.DomaineName.HeaderText = "Name"
        Me.DomaineName.Name = "DomaineName"
        Me.DomaineName.ReadOnly = True
        '
        'UseUndefinedUser
        '
        Me.UseUndefinedUser.DataPropertyName = "UseUndefinedUser"
        Me.UseUndefinedUser.HeaderText = "Use Undefined User"
        Me.UseUndefinedUser.Name = "UseUndefinedUser"
        Me.UseUndefinedUser.ReadOnly = True
        Me.UseUndefinedUser.Width = 140
        '
        'btnRemoveDomaine
        '
        Me.btnRemoveDomaine.Location = New System.Drawing.Point(460, 180)
        Me.btnRemoveDomaine.Name = "btnRemoveDomaine"
        Me.btnRemoveDomaine.Size = New System.Drawing.Size(76, 27)
        Me.btnRemoveDomaine.TabIndex = 2
        Me.btnRemoveDomaine.Text = "Enlever"
        Me.btnRemoveDomaine.UseVisualStyleBackColor = True
        '
        'btnAddDomaine
        '
        Me.btnAddDomaine.Location = New System.Drawing.Point(460, 147)
        Me.btnAddDomaine.Name = "btnAddDomaine"
        Me.btnAddDomaine.Size = New System.Drawing.Size(76, 27)
        Me.btnAddDomaine.TabIndex = 1
        Me.btnAddDomaine.Text = "Ajouter"
        Me.btnAddDomaine.UseVisualStyleBackColor = True
        '
        'frmSetting
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(571, 293)
        Me.Controls.Add(Me.TabControl1)
        Me.Controls.Add(Me.btnOk)
        Me.Controls.Add(Me.btnCancel)
        Me.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow
        Me.Name = "frmSetting"
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent
        Me.Text = "Ajustement"
        Me.TopMost = True
        Me.TabControl1.ResumeLayout(False)
        Me.TabPage1.ResumeLayout(False)
        Me.TabPage1.PerformLayout()
        Me.TabPage2.ResumeLayout(False)
        CType(Me.dvListDomain, System.ComponentModel.ISupportInitialize).EndInit()
        Me.ResumeLayout(False)

    End Sub
    Friend WithEvents btnCancel As System.Windows.Forms.Button
    Friend WithEvents btnOk As System.Windows.Forms.Button
    Friend WithEvents Label12 As System.Windows.Forms.Label
    Friend WithEvents txtConnectionString As System.Windows.Forms.TextBox
    Friend WithEvents TabControl1 As System.Windows.Forms.TabControl
    Friend WithEvents TabPage1 As System.Windows.Forms.TabPage
    Friend WithEvents ToolTip1 As System.Windows.Forms.ToolTip
    Friend WithEvents Label2 As Windows.Forms.Label
    Friend WithEvents Label1 As Windows.Forms.Label
    Friend WithEvents txtAddress As Windows.Forms.TextBox
    Friend WithEvents txtPort As Windows.Forms.TextBox
    Friend WithEvents TabPage2 As Windows.Forms.TabPage
    Friend WithEvents btnRemoveDomaine As Windows.Forms.Button
    Friend WithEvents btnAddDomaine As Windows.Forms.Button
    Friend WithEvents dvListDomain As Windows.Forms.DataGridView
    Friend WithEvents DomaineName As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents UseUndefinedUser As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents chkUseDatabase As Windows.Forms.CheckBox
End Class
