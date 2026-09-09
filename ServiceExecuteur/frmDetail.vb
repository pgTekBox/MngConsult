Imports System.Windows.Forms

''' <summary>Affichage plein écran du détail d'une exécution (double-clic dans la grille).</summary>
Public Class frmDetail

    Public Sub ShowDetail(texte As String)
        txtDetail.Text = If(texte, "")
        txtDetail.SelectionStart = 0
        txtDetail.SelectionLength = 0
    End Sub

    Private Sub btnCopy_Click(sender As Object, e As EventArgs) Handles btnCopy.Click
        If String.IsNullOrEmpty(txtDetail.Text) Then Return
        Clipboard.SetText(txtDetail.Text)
    End Sub

    Private Sub btnClose_Click(sender As Object, e As EventArgs) Handles btnClose.Click
        Me.Close()
    End Sub

End Class
