<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class frmDomaine
    Inherits System.Windows.Forms.Form

    'Form remplace la méthode Dispose pour nettoyer la liste des composants.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Requise par le Concepteur Windows Form
    Private components As System.ComponentModel.IContainer

    'REMARQUE : la procédure suivante est requise par le Concepteur Windows Form
    'Elle peut être modifiée à l'aide du Concepteur Windows Form.  
    'Ne la modifiez pas à l'aide de l'éditeur de code.
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        Me.btnOk = New System.Windows.Forms.Button()
        Me.txtDomaine = New System.Windows.Forms.TextBox()
        Me.Label1 = New System.Windows.Forms.Label()
        Me.btnCancel = New System.Windows.Forms.Button()
        Me.chkUndefinedUser = New System.Windows.Forms.CheckBox()
        Me.SuspendLayout()
        '
        'btnOk
        '
        Me.btnOk.Location = New System.Drawing.Point(196, 71)
        Me.btnOk.Name = "btnOk"
        Me.btnOk.Size = New System.Drawing.Size(82, 29)
        Me.btnOk.TabIndex = 0
        Me.btnOk.Text = "Ok"
        Me.btnOk.UseVisualStyleBackColor = True
        '
        'txtDomaine
        '
        Me.txtDomaine.Location = New System.Drawing.Point(44, 18)
        Me.txtDomaine.Name = "txtDomaine"
        Me.txtDomaine.Size = New System.Drawing.Size(230, 20)
        Me.txtDomaine.TabIndex = 1
        '
        'Label1
        '
        Me.Label1.AutoSize = True
        Me.Label1.Location = New System.Drawing.Point(6, 21)
        Me.Label1.Name = "Label1"
        Me.Label1.Size = New System.Drawing.Size(32, 13)
        Me.Label1.TabIndex = 2
        Me.Label1.Text = "Nom:"
        '
        'btnCancel
        '
        Me.btnCancel.Location = New System.Drawing.Point(108, 71)
        Me.btnCancel.Name = "btnCancel"
        Me.btnCancel.Size = New System.Drawing.Size(82, 29)
        Me.btnCancel.TabIndex = 3
        Me.btnCancel.Text = "Cancel"
        Me.btnCancel.UseVisualStyleBackColor = True
        '
        'chkUndefinedUser
        '
        Me.chkUndefinedUser.AutoSize = True
        Me.chkUndefinedUser.CheckAlign = System.Drawing.ContentAlignment.MiddleRight
        Me.chkUndefinedUser.Location = New System.Drawing.Point(9, 44)
        Me.chkUndefinedUser.Name = "chkUndefinedUser"
        Me.chkUndefinedUser.Size = New System.Drawing.Size(140, 17)
        Me.chkUndefinedUser.TabIndex = 4
        Me.chkUndefinedUser.Text = "Use with undefined user"
        Me.chkUndefinedUser.UseVisualStyleBackColor = True
        '
        'frmDomaine
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(290, 110)
        Me.Controls.Add(Me.chkUndefinedUser)
        Me.Controls.Add(Me.btnCancel)
        Me.Controls.Add(Me.Label1)
        Me.Controls.Add(Me.txtDomaine)
        Me.Controls.Add(Me.btnOk)
        Me.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow
        Me.Name = "frmDomaine"
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent
        Me.Text = "Domaine"
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub

    Friend WithEvents btnOk As Windows.Forms.Button
    Friend WithEvents txtDomaine As Windows.Forms.TextBox
    Friend WithEvents Label1 As Windows.Forms.Label
    Friend WithEvents btnCancel As Windows.Forms.Button
    Friend WithEvents chkUndefinedUser As Windows.Forms.CheckBox
End Class
