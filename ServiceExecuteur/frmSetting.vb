Imports System.Data.SqlClient
Imports System.Windows.Forms

''' <summary>
''' Écriture de configExecuteur.xml. Les deux chaînes de connexion y sont
''' chiffrées (clsEncDec), comme dans le service SMTP : le fichier reste posé à
''' côté de l'exécutable sur le serveur.
''' </summary>
Public Class frmSetting

    Private Sub frmSetting_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        Dim config As New clsXmlConfig()

        txtConnectionString.Text = config.ConnectionString
        txtConnectionStringMail.Text = config.ConnectionStringMail
        txtInterval.Text = config.IntervalSeconds
        txtBatch.Text = config.BatchSize
        txtLock.Text = config.LockSeconds
        txtMailSender.Text = config.MailSender
        txtRelanceAvant.Text = config.RelanceJoursAvant
        txtRelanceApres.Text = config.RelanceJoursApres
        chkActif.Checked = (config.Actif = "1")
    End Sub

    Private Sub btnOk_Click(sender As Object, e As EventArgs) Handles btnOk.Click

        If Not Valide() Then Return

        Dim config As New clsXmlConfig()

        config.ConnectionString = txtConnectionString.Text.Trim()
        config.ConnectionStringMail = txtConnectionStringMail.Text.Trim()
        config.IntervalSeconds = txtInterval.Text.Trim()
        config.BatchSize = txtBatch.Text.Trim()
        config.LockSeconds = txtLock.Text.Trim()
        config.MailSender = txtMailSender.Text.Trim()
        config.RelanceJoursAvant = txtRelanceAvant.Text.Trim()
        config.RelanceJoursApres = txtRelanceApres.Text.Trim()
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
            Return Refuse("La chaîne de connexion à MngConsul est obligatoire.", txtConnectionString)
        End If
        If clsXmlConfig.ToInt(txtInterval.Text.Trim(), 0) < 5 Then
            Return Refuse("L'intervalle doit être d'au moins 5 secondes.", txtInterval)
        End If
        If clsXmlConfig.ToInt(txtBatch.Text.Trim(), 0) < 1 Then
            Return Refuse("Il faut exécuter au moins une tâche par passage.", txtBatch)
        End If
        If clsXmlConfig.ToInt(txtLock.Text.Trim(), 0) < 30 Then
            Return Refuse("Le verrou doit durer au moins 30 secondes.", txtLock)
        End If
        If clsXmlConfig.ToInt(txtRelanceAvant.Text.Trim(), -1) < 0 Then
            Return Refuse("Le nombre de jours avant échéance doit être positif ou nul.", txtRelanceAvant)
        End If
        If clsXmlConfig.ToInt(txtRelanceApres.Text.Trim(), 0) < 1 Then
            Return Refuse("La fenêtre de relance doit couvrir au moins un jour.", txtRelanceApres)
        End If

        ' Sans la base MailService, les tâches de type EMAIL échoueront : on le
        ' dit maintenant plutôt que de le découvrir dans le journal.
        If String.IsNullOrWhiteSpace(txtConnectionStringMail.Text) Then
            If MessageBox.Show("La connexion à MailService est vide : les tâches d'envoi de courriel échoueront." & vbCrLf & vbCrLf &
                               "Enregistrer quand même ?",
                               "Paramètres", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) <> DialogResult.Yes Then
                txtConnectionStringMail.Focus()
                Return False
            End If
        End If

        Return True
    End Function

    Private Function Refuse(message As String, focus As Control) As Boolean
        MessageBox.Show(message, "Paramètres", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        focus.Focus()
        Return False
    End Function

    ''' <summary>
    ''' Vérifie les deux connexions : c'est le couple qui manque le plus souvent
    ''' lors d'une première installation.
    ''' </summary>
    Private Sub btnTester_Click(sender As Object, e As EventArgs) Handles btnTester.Click
        Dim cs As String = txtConnectionString.Text.Trim()
        If String.IsNullOrWhiteSpace(cs) Then
            MessageBox.Show("Renseignez d'abord la chaîne de connexion à MngConsul.", "Test",
                            MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return
        End If

        Dim msg As String

        Try
            Using cnn As New SqlConnection(cs)
                cnn.Open()
            End Using

            Dim repo As New clsJobRepository(cs, txtConnectionStringMail.Text.Trim())
            msg = "Connexion à MngConsul réussie."
            msg &= vbCrLf & vbCrLf & "Tâches à faire : " & repo.CountAFaire()
            msg &= vbCrLf & "En attente d'approbation : " & repo.CountAApprouver()

        Catch ex As Exception
            MessageBox.Show("Échec de la connexion à MngConsul :" & vbCrLf & vbCrLf & ex.Message,
                            "Test", MessageBoxButtons.OK, MessageBoxIcon.Error)
            Return
        End Try

        Dim csMail As String = txtConnectionStringMail.Text.Trim()
        If String.IsNullOrWhiteSpace(csMail) Then
            msg &= vbCrLf & vbCrLf & "MailService non configurée : les tâches d'envoi de courriel échoueront."
        Else
            Try
                Using cnn As New SqlConnection(csMail)
                    cnn.Open()
                End Using
                msg &= vbCrLf & vbCrLf & "Connexion à MailService réussie."
            Catch ex As Exception
                msg &= vbCrLf & vbCrLf & "Échec de la connexion à MailService : " & ex.Message
            End Try
        End If

        MessageBox.Show(msg, "Test", MessageBoxButtons.OK, MessageBoxIcon.Information)
    End Sub

    Private Sub btnCancel_Click(sender As Object, e As EventArgs) Handles btnCancel.Click
        Me.Close()
    End Sub

End Class
