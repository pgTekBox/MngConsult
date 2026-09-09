Imports System.Data.SqlClient
Imports System.Windows.Forms

''' <summary>
''' Écriture de configExecuteur.xml. La chaîne de connexion et la clé partagée
''' y sont chiffrées (clsEncDec), comme dans le service SMTP : le fichier reste
''' posé à côté de l'exécutable sur le serveur.
'''
''' On ne règle plus ici ce que font les tâches — expéditeur, fenêtre de
''' relance, destinataires : tout cela vit dans la console d'administration.
''' Ce service n'a besoin que de savoir où est la console et comment s'y
''' authentifier.
''' </summary>
Public Class frmSetting

    Private Sub frmSetting_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        Dim config As New clsXmlConfig()

        txtConnectionString.Text = config.ConnectionString
        txtAdminUrl.Text = config.AdminBaseUrl
        txtAdminKey.Text = config.AdminApiKey
        txtInterval.Text = config.IntervalSeconds
        txtBatch.Text = config.BatchSize
        txtLock.Text = config.LockSeconds
        txtPlanning.Text = config.PlanningRefreshMinutes
        chkActif.Checked = (config.Actif = "1")
    End Sub

    Private Sub btnOk_Click(sender As Object, e As EventArgs) Handles btnOk.Click

        If Not Valide() Then Return

        Dim config As New clsXmlConfig()

        config.ConnectionString = txtConnectionString.Text.Trim()
        config.AdminBaseUrl = txtAdminUrl.Text.Trim()
        config.AdminApiKey = txtAdminKey.Text.Trim()
        config.IntervalSeconds = txtInterval.Text.Trim()
        config.BatchSize = txtBatch.Text.Trim()
        config.LockSeconds = txtLock.Text.Trim()
        config.PlanningRefreshMinutes = txtPlanning.Text.Trim()
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
        If clsXmlConfig.ToInt(txtPlanning.Text.Trim(), -1) < 0 Then
            Return Refuse("Le rafraîchissement du planning doit être positif ou nul.", txtPlanning)
        End If

        ' Sans la console, aucune tâche ne peut s'exécuter : c'est elle qui les
        ' fait. On le dit maintenant plutôt que de le découvrir dans le journal.
        If String.IsNullOrWhiteSpace(txtAdminUrl.Text) OrElse String.IsNullOrWhiteSpace(txtAdminKey.Text) Then
            If MessageBox.Show("L'adresse ou la clé de la console est vide : aucune tâche ne pourra s'exécuter." & vbCrLf & vbCrLf &
                               "Enregistrer quand même ?",
                               "Paramètres", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) <> DialogResult.Yes Then
                If String.IsNullOrWhiteSpace(txtAdminUrl.Text) Then txtAdminUrl.Focus() Else txtAdminKey.Focus()
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
    ''' Vérifie la base ET la console : ce sont les deux dépendances du service,
    ''' et celles qui manquent le plus souvent lors d'une première installation.
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

            Dim repo As New clsJobRepository(cs)
            msg = "Connexion à MngConsul réussie."
            msg &= vbCrLf & vbCrLf & "Tâches à faire : " & repo.CountAFaire()
            msg &= vbCrLf & "En attente d'approbation : " & repo.CountAApprouver()

        Catch ex As Exception
            MessageBox.Show("Échec de la connexion à MngConsul :" & vbCrLf & vbCrLf & ex.Message,
                            "Test", MessageBoxButtons.OK, MessageBoxIcon.Error)
            Return
        End Try

        ' On appelle la console avec un identifiant d'exécution qui n'existe
        ' pas : rien ne s'exécute, mais la réponse prouve que l'adresse répond
        ' et que la clé est acceptée.
        Dim console As New clsAdminGateway(txtAdminUrl.Text.Trim(), txtAdminKey.Text.Trim())
        If Not console.EstConfigure Then
            msg &= vbCrLf & vbCrLf & "Console non configurée : aucune tâche ne pourra s'exécuter."
        Else
            Try
                Dim essai As AdminJobResult = console.ExecuterTache(0, 20)
                If essai.Message.IndexOf("clé", StringComparison.OrdinalIgnoreCase) >= 0 OrElse
                   essai.Message.IndexOf("cle", StringComparison.OrdinalIgnoreCase) >= 0 Then
                    msg &= vbCrLf & vbCrLf & "Console joignable, mais la clé est refusée : " & essai.Message
                Else
                    msg &= vbCrLf & vbCrLf & "Console joignable et clé acceptée." &
                           vbCrLf & console.UrlRunner
                End If
            Catch ex As Exception
                msg &= vbCrLf & vbCrLf & "Console injoignable : " & ex.Message
            End Try
        End If

        MessageBox.Show(msg, "Test", MessageBoxButtons.OK, MessageBoxIcon.Information)
    End Sub

    Private Sub btnCancel_Click(sender As Object, e As EventArgs) Handles btnCancel.Click
        Me.Close()
    End Sub

End Class
