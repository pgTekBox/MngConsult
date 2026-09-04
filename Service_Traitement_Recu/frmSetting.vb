Imports System.Data.SqlClient
Imports System.Windows.Forms

''' <summary>
''' Écriture de configTraitementRecu.xml. La chaîne de connexion y est chiffrée
''' (clsEncDec), comme dans le service SMTP : le fichier reste posé à côté de
''' l'exécutable sur le serveur.
''' </summary>
Public Class frmSetting

    Private Sub frmSetting_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        Dim config As New clsXmlConfig()

        txtConnectionString.Text = config.ConnectionString
        txtInterval.Text = config.IntervalSeconds
        txtBatch.Text = config.BatchSize
        txtMaxAttempts.Text = config.MaxAttempts
        txtLock.Text = config.LockSeconds
        txtImageWidth.Text = config.ImageMaxWidth
        txtJpegQuality.Text = config.ImageJpegQuality
        chkActif.Checked = (config.Actif = "1")
    End Sub

    Private Sub btnOk_Click(sender As Object, e As EventArgs) Handles btnOk.Click

        If Not Valide() Then Return

        Dim config As New clsXmlConfig()

        config.ConnectionString = txtConnectionString.Text.Trim()
        config.IntervalSeconds = txtInterval.Text.Trim()
        config.BatchSize = txtBatch.Text.Trim()
        config.MaxAttempts = txtMaxAttempts.Text.Trim()
        config.LockSeconds = txtLock.Text.Trim()
        config.ImageMaxWidth = txtImageWidth.Text.Trim()
        config.ImageJpegQuality = txtJpegQuality.Text.Trim()
        config.Actif = If(chkActif.Checked, "1", "0")

        Try
            config.saveAll()
        Catch ex As Exception
            MessageBox.Show("Impossible d'enregistrer la configuration :" & vbCrLf & vbCrLf & ex.Message,
                            "Paramètres", MessageBoxButtons.OK, MessageBoxIcon.Error)
            Return
        End Try

        Me.Close()
    End Sub

    ''' <summary>Contrôle des valeurs avant écriture : un fichier invalide bloquerait le service.</summary>
    Private Function Valide() As Boolean
        If String.IsNullOrWhiteSpace(txtConnectionString.Text) Then
            Return Refuse("La chaîne de connexion est obligatoire.", txtConnectionString)
        End If
        If clsXmlConfig.ToInt(txtInterval.Text.Trim(), 0) < 5 Then
            Return Refuse("L'intervalle doit être d'au moins 5 secondes.", txtInterval)
        End If
        If clsXmlConfig.ToInt(txtBatch.Text.Trim(), 0) < 1 Then
            Return Refuse("Il faut traiter au moins un reçu par passage.", txtBatch)
        End If
        If clsXmlConfig.ToInt(txtMaxAttempts.Text.Trim(), 0) < 1 Then
            Return Refuse("Il faut au moins une tentative.", txtMaxAttempts)
        End If
        If clsXmlConfig.ToInt(txtLock.Text.Trim(), 0) < 30 Then
            Return Refuse("Le verrou doit durer au moins 30 secondes.", txtLock)
        End If
        If clsXmlConfig.ToInt(txtImageWidth.Text.Trim(), 0) < 200 Then
            Return Refuse("La largeur d'image doit être d'au moins 200 pixels.", txtImageWidth)
        End If

        Dim q As Integer = clsXmlConfig.ToInt(txtJpegQuality.Text.Trim(), 0)
        If q < 20 OrElse q > 95 Then
            Return Refuse("La qualité JPEG doit être comprise entre 20 et 95.", txtJpegQuality)
        End If

        Return True
    End Function

    Private Function Refuse(message As String, focus As Control) As Boolean
        MessageBox.Show(message, "Paramètres", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        focus.Focus()
        Return False
    End Function

    ''' <summary>
    ''' Vérifie la connexion ET la présence de la clé OpenAI : c'est le couple
    ''' qui manque le plus souvent lors d'une première installation.
    ''' </summary>
    Private Sub btnTester_Click(sender As Object, e As EventArgs) Handles btnTester.Click
        Dim cs As String = txtConnectionString.Text.Trim()
        If String.IsNullOrWhiteSpace(cs) Then
            MessageBox.Show("Renseignez d'abord la chaîne de connexion.", "Test",
                            MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return
        End If

        Try
            Using cnn As New SqlConnection(cs)
                cnn.Open()
            End Using

            Dim repo As New clsReceiptRepository(cs)
            Dim stats = repo.GetStats()
            Dim key As String = repo.GetOpenAiKey()

            Dim msg As String = "Connexion réussie."
            If stats IsNot Nothing Then
                msg &= vbCrLf & vbCrLf & "Reçus à faire : " & Convert.ToString(stats("AFaire"))
                msg &= vbCrLf & "Reçus terminés : " & Convert.ToString(stats("Termines"))
            End If
            msg &= vbCrLf & vbCrLf & If(String.IsNullOrWhiteSpace(key),
                                        "⚠ Clé OpenAI absente (paramètre CHATGPT) : le service ne pourra pas lire les reçus.",
                                        "Clé OpenAI trouvée.")

            MessageBox.Show(msg, "Test", MessageBoxButtons.OK, MessageBoxIcon.Information)

        Catch ex As Exception
            MessageBox.Show("Échec de la connexion :" & vbCrLf & vbCrLf & ex.Message,
                            "Test", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub btnCancel_Click(sender As Object, e As EventArgs) Handles btnCancel.Click
        Me.Close()
    End Sub

End Class
