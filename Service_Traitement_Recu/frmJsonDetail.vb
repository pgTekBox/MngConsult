Imports System.Windows.Forms

''' <summary>Affichage plein écran du JSON d'un reçu (double-clic dans la grille).</summary>
Public Class frmJsonDetail

    Public Sub ShowJson(json As String)
        txtJson.Text = If(json, "")
        txtJson.SelectionStart = 0
        txtJson.SelectionLength = 0
    End Sub

    Private Sub btnCopy_Click(sender As Object, e As EventArgs) Handles btnCopy.Click
        If String.IsNullOrEmpty(txtJson.Text) Then Return
        Clipboard.SetText(txtJson.Text)
    End Sub

    Private Sub btnClose_Click(sender As Object, e As EventArgs) Handles btnClose.Click
        Me.Close()
    End Sub

End Class
