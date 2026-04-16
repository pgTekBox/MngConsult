Public Class frmDomaine
    Private Sub btnOk_Click(sender As Object, e As EventArgs) Handles btnOk.Click
        If txtDomaine.Text.Trim = "" Then
            Me.Close()
        Else
            Dim oXMLconfig As New clsXmlConfig
            oXMLconfig.SaveDomaine(txtDomaine.Text, chkUndefinedUser.Checked)
            oXMLconfig.saveAll()
            Me.Close()
        End If
    End Sub

    Private Sub btnCancel_Click(sender As Object, e As EventArgs) Handles btnCancel.Click
        Me.Close()
    End Sub


End Class