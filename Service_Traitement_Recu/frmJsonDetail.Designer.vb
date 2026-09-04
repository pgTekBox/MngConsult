<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class frmJsonDetail
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
        Me.txtJson = New System.Windows.Forms.TextBox()
        Me.pnlBottom = New System.Windows.Forms.Panel()
        Me.btnCopy = New System.Windows.Forms.Button()
        Me.btnClose = New System.Windows.Forms.Button()
        Me.pnlBottom.SuspendLayout()
        Me.SuspendLayout()
        '
        'txtJson
        '
        Me.txtJson.Dock = System.Windows.Forms.DockStyle.Fill
        Me.txtJson.Font = New System.Drawing.Font("Consolas", 9.5!)
        Me.txtJson.Location = New System.Drawing.Point(0, 0)
        Me.txtJson.Multiline = True
        Me.txtJson.Name = "txtJson"
        Me.txtJson.ReadOnly = True
        Me.txtJson.ScrollBars = System.Windows.Forms.ScrollBars.Both
        Me.txtJson.Size = New System.Drawing.Size(760, 494)
        Me.txtJson.TabIndex = 0
        Me.txtJson.WordWrap = False
        '
        'pnlBottom
        '
        Me.pnlBottom.Controls.Add(Me.btnClose)
        Me.pnlBottom.Controls.Add(Me.btnCopy)
        Me.pnlBottom.Dock = System.Windows.Forms.DockStyle.Bottom
        Me.pnlBottom.Location = New System.Drawing.Point(0, 494)
        Me.pnlBottom.Name = "pnlBottom"
        Me.pnlBottom.Size = New System.Drawing.Size(760, 46)
        Me.pnlBottom.TabIndex = 1
        '
        'btnCopy
        '
        Me.btnCopy.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnCopy.Location = New System.Drawing.Point(520, 8)
        Me.btnCopy.Name = "btnCopy"
        Me.btnCopy.Size = New System.Drawing.Size(110, 28)
        Me.btnCopy.TabIndex = 0
        Me.btnCopy.Text = "Copier"
        Me.btnCopy.UseVisualStyleBackColor = True
        '
        'btnClose
        '
        Me.btnClose.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnClose.Location = New System.Drawing.Point(638, 8)
        Me.btnClose.Name = "btnClose"
        Me.btnClose.Size = New System.Drawing.Size(110, 28)
        Me.btnClose.TabIndex = 1
        Me.btnClose.Text = "Fermer"
        Me.btnClose.UseVisualStyleBackColor = True
        '
        'frmJsonDetail
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.CancelButton = Me.btnClose
        Me.ClientSize = New System.Drawing.Size(760, 540)
        Me.Controls.Add(Me.txtJson)
        Me.Controls.Add(Me.pnlBottom)
        Me.Name = "frmJsonDetail"
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent
        Me.Text = "JSON du reçu"
        Me.pnlBottom.ResumeLayout(False)
        Me.ResumeLayout(False)
        Me.PerformLayout()
    End Sub

    Friend WithEvents txtJson As System.Windows.Forms.TextBox
    Friend WithEvents pnlBottom As System.Windows.Forms.Panel
    Friend WithEvents btnCopy As System.Windows.Forms.Button
    Friend WithEvents btnClose As System.Windows.Forms.Button

End Class
