Imports System.ComponentModel
Imports System.Data
Imports System.IO
Imports System.IO.Pipes
Imports System.Threading
Imports System.Windows.Forms
Imports nspServiceExecuteur.clsLog

''' <summary>
''' Interface de surveillance du service :
'''   - « Exécutions » : les exécutions de tâches, la plus récente en haut, avec
'''      leur verrou, leur durée et leur message de résultat ;
'''   - « Journal »    : les fichiers texte écrits par le service.
'''
''' L'état du service arrive par un pipe nommé, comme dans le service SMTP :
''' le thread de lecture reste connecté et met les libellés à jour à chaque
''' changement, sans interroger la base.
''' </summary>
Public Class Form1

    Private PipeClientThread As Thread
    Private ReadOnly oThreadState As New clsThreadState
    Private pipeClient As NamedPipeClientStream

    Private ConnectionString As String = ""
    Private repo As clsJobRepository

#Region "Ouverture / fermeture"

    Private Sub Form1_Load(sender As Object, e As EventArgs) Handles MyBase.Load

        AppliquerIcone()

        Dim config As New clsXmlConfig()
        ConnectionString = config.ConnectionString

        Me.Text = "Exécuteur de tâches — " & Version()
        lblDernierPassage.Text = clsLog.ReadRunningStatus()

        If String.IsNullOrWhiteSpace(ConnectionString) Then
            lblEtat.Text = "Non configuré"
            MessageBox.Show("La chaîne de connexion n'est pas configurée." & vbCrLf &
                            "Ouvrez « Paramètres... » pour la renseigner.",
                            "Configuration", MessageBoxButtons.OK, MessageBoxIcon.Information)
        Else
            repo = New clsJobRepository(ConnectionString, config.ConnectionStringMail)
            RefreshAll()
        End If

        ReadLogFile()
        StartPipeThread()

        Timer1.Enabled = True
    End Sub

    ''' <summary>
    ''' Icône de la fenêtre, prise sur l'exécutable lui-même.
    '''
    ''' Le concepteur, lui, la recopie dans Form1.resx : l'icône se retrouve
    ''' alors deux fois dans l'assembly (une fois en ressource Win32, une fois
    ''' en ressource .NET), soit un demi-mégaoctet pour rien. ServiceExecuteur.ico
    ''' est déjà dans le fichier — on la relit de là.
    '''
    ''' Sans icône la fenêtre garde celle de Windows par défaut : ça n'a jamais
    ''' à faire échouer l'ouverture de l'interface.
    ''' </summary>
    Private Sub AppliquerIcone()
        Try
            Me.Icon = Drawing.Icon.ExtractAssociatedIcon(Application.ExecutablePath)
        Catch ex As Exception
            clsLog.ErrorWritelog("Icône de la fenêtre : " & ex.Message, LogType.Erreur)
        End Try
    End Sub

    Private Function Version() As String
        Return "1.0"
    End Function

    Private Sub Form1_Closing(sender As Object, e As CancelEventArgs) Handles Me.Closing
        StopPipeThread()
    End Sub

#End Region

#Region "Pipe de statut"

    Private Sub StartPipeThread()
        PipeClientThread = New Thread(AddressOf DoTaskPipeClient)
        PipeClientThread.Name = "Executeur_Pipe_Client"
        PipeClientThread.IsBackground = True
        PipeClientThread.Start()
    End Sub

    Private Sub StopPipeThread()
        Try
            Monitor.Enter(oThreadState)
            oThreadState.StateStop = True
            Monitor.Exit(oThreadState)

            If pipeClient IsNot Nothing Then
                Try : pipeClient.Close() : Catch : End Try
            End If
        Catch
        End Try
    End Sub

    ''' <summary>
    ''' Se connecte au pipe du service et lit les lignes de statut en continu.
    ''' Si le service n'est pas démarré, la connexion échoue : on réessaie
    ''' toutes les 5 secondes plutôt que d'afficher une erreur bloquante.
    ''' </summary>
    Private Sub DoTaskPipeClient()

        Dim toClose As Boolean = False
        Dim status As New clsExecutorStatus()

        Do Until toClose
            Monitor.Enter(oThreadState)
            toClose = oThreadState.StateStop
            Monitor.Exit(oThreadState)
            If toClose Then Exit Do

            pipeClient = New NamedPipeClientStream(".", tkbService.PipeName, PipeDirection.In, PipeOptions.None)

            Try
                pipeClient.Connect(5000)
                Dim sr As New StreamReader(pipeClient)

                Do
                    Monitor.Enter(oThreadState)
                    toClose = oThreadState.StateStop
                    Monitor.Exit(oThreadState)
                    If toClose Then Exit Do

                    Dim line As String = sr.ReadLine()
                    If line Is Nothing Then Exit Do   ' pipe fermé côté service

                    status.RestoreParam(line)
                    ShowStatus(status)
                Loop

            Catch ex As TimeoutException
                ShowServiceOffline()
            Catch ex As Exception
                ShowServiceOffline()
            Finally
                Try : pipeClient.Close() : Catch : End Try
            End Try

            If Not toClose Then Thread.Sleep(TimeSpan.FromSeconds(5))
        Loop
    End Sub

    ''' <summary>Le thread du pipe n'est pas celui de l'interface : on repasse par Invoke.</summary>
    Private Sub ShowStatus(status As clsExecutorStatus)
        If Me.IsDisposed Then Return
        Try
            If Me.InvokeRequired Then
                Me.Invoke(New Action(Of clsExecutorStatus)(AddressOf ShowStatus), status)
                Return
            End If

            lblEtat.Text = status.StatusText
            lblEtat.ForeColor = If(String.IsNullOrEmpty(status.LastError), Drawing.Color.ForestGreen, Drawing.Color.Firebrick)
            lblDernierPassage.Text = status.LastRun
            lblFile.Text = status.Queue
            lblAApprouver.Text = status.AApprouver
            lblSucces.Text = status.CounterDone
            lblEchecs.Text = status.CounterError
        Catch
            ' La fenêtre peut se fermer pendant l'Invoke : sans intérêt à signaler.
        End Try
    End Sub

    Private Sub ShowServiceOffline()
        If Me.IsDisposed Then Return
        Try
            If Me.InvokeRequired Then
                Me.Invoke(New Action(AddressOf ShowServiceOffline))
                Return
            End If
            lblEtat.Text = "Service arrêté"
            lblEtat.ForeColor = Drawing.Color.DimGray
        Catch
        End Try
    End Sub

#End Region

#Region "Grille"

    Private Sub RefreshAll()
        If repo Is Nothing Then Return
        Try
            Dim dt As DataTable = repo.GetExecutionsEnCours(500)
            dvExecutions.DataSource = dt

            If dvExecutions.Columns.Contains("colXDemarre") Then
                dvExecutions.Columns("colXDemarre").DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"
            End If
            If dvExecutions.Columns.Contains("colXTermine") Then
                dvExecutions.Columns("colXTermine").DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"
            End If

            ' Le pipe ne parle que quand le service tourne : sans lui, ces deux
            ' compteurs resteraient à zéro alors que la file bouge.
            lblFile.Text = repo.CountAFaire().ToString()
            lblAApprouver.Text = repo.CountAApprouver().ToString()

        Catch ex As Exception
            ShowDbError("la liste des exécutions", ex)
        End Try
    End Sub

    ''' <summary>Colore les lignes selon le statut, pour repérer les échecs d'un coup d'œil.</summary>
    Private Sub dvExecutions_RowPrePaint(sender As Object, e As DataGridViewRowPrePaintEventArgs) Handles dvExecutions.RowPrePaint
        If e.RowIndex < 0 OrElse e.RowIndex >= dvExecutions.Rows.Count Then Return
        Dim row As DataGridViewRow = dvExecutions.Rows(e.RowIndex)

        Select Case Convert.ToString(row.Cells("colXStatut").Value)
            Case "SUCCES"
                row.DefaultCellStyle.BackColor = Drawing.Color.Honeydew
            Case "ECHEC", "TIMEOUT"
                row.DefaultCellStyle.BackColor = Drawing.Color.MistyRose
            Case "EN_COURS"
                row.DefaultCellStyle.BackColor = Drawing.Color.LightYellow
            Case Else
                row.DefaultCellStyle.BackColor = Drawing.Color.White
        End Select
    End Sub

    Private Sub dvExecutions_CellDoubleClick(sender As Object, e As DataGridViewCellEventArgs) Handles dvExecutions.CellDoubleClick
        If e.RowIndex < 0 Then Return
        ShowDetail()
    End Sub

    ''' <summary>Ouvre le message de résultat complet, souvent trop long pour la cellule.</summary>
    Private Sub ShowDetail()
        If dvExecutions.CurrentRow Is Nothing Then Return

        Dim sb As New Text.StringBuilder()
        For Each c As DataGridViewColumn In dvExecutions.Columns
            Dim v As Object = dvExecutions.CurrentRow.Cells(c.Index).Value
            sb.AppendLine(c.HeaderText & " : " & If(v Is Nothing OrElse IsDBNull(v), "", Convert.ToString(v)))
        Next

        Dim f As New frmDetail()
        f.ShowDetail(sb.ToString())
        f.ShowDialog(Me)
    End Sub

#End Region

#Region "Boutons"

    Private Sub btnRefresh_Click(sender As Object, e As EventArgs) Handles btnRefresh.Click
        RefreshAll()
        ReadLogFile()
    End Sub

    Private Sub btnVoirDetail_Click(sender As Object, e As EventArgs) Handles btnVoirDetail.Click
        ShowDetail()
    End Sub

    ''' <summary>
    ''' Exécute un lot tout de suite, depuis l'interface.
    '''
    ''' Le service peut tourner en même temps : la réservation se fait en base
    ''' (s0739ClaimNextExecution pose un verrou), donc la même exécution ne peut
    ''' pas être prise deux fois. On réveille aussi la boucle du service au cas
    ''' où l'interface tourne dans le même processus.
    ''' </summary>
    Private Sub btnExecuterMaintenant_Click(sender As Object, e As EventArgs) Handles btnExecuterMaintenant.Click

        If repo Is Nothing Then
            MessageBox.Show("Configurez d'abord la chaîne de connexion.", "Exécution",
                            MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return
        End If

        Dim config As New clsXmlConfig()

        If MessageBox.Show("Exécuter maintenant jusqu'à " & config.BatchSize & " tâche(s) ?" & vbCrLf & vbCrLf &
                           "Les tâches lancent de vrais traitements : procédures comptables, envois de courriels.",
                           "Exécuter maintenant", MessageBoxButtons.YesNo, MessageBoxIcon.Question) <> DialogResult.Yes Then
            Return
        End If

        tkbService.RequestRunNow()

        btnExecuterMaintenant.Enabled = False
        Me.Cursor = Cursors.WaitCursor
        lblEtat.Text = "Exécution en cours..."
        lblEtat.ForeColor = Drawing.Color.DarkOrange

        Try
            Dim task As New clsTaskExecutor(config)
            Dim lot As ExecutionBatchResult = task.ProcessBatch()

            lblEtat.Text = If(lot.Traitees > 0,
                              lot.Succes & " succès, " & lot.Echecs & " échec(s)",
                              "Rien à exécuter")
            lblEtat.ForeColor = If(lot.Echecs > 0, Drawing.Color.Firebrick, Drawing.Color.ForestGreen)

            clsLog.EventWritelog(lot.Traitees & " tâche(s) exécutée(s) depuis l'interface.", LogType.Traitement)

        Catch ex As Exception
            lblEtat.Text = "Erreur : " & ex.Message
            lblEtat.ForeColor = Drawing.Color.Firebrick
            clsLog.ErrorWritelog("Exécution depuis l'interface : " & ex.Message, LogType.Erreur)
            MessageBox.Show(ex.Message, "Exécution", MessageBoxButtons.OK, MessageBoxIcon.Error)

        Finally
            Me.Cursor = Cursors.Default
            btnExecuterMaintenant.Enabled = True
            RefreshAll()
            ReadLogFile()
        End Try
    End Sub

    Private Sub btnSetting_Click(sender As Object, e As EventArgs) Handles btnSetting.Click
        Dim f As New frmSetting()
        f.ShowDialog(Me)

        ' La configuration peut avoir changé de base : on repart de zéro.
        Dim config As New clsXmlConfig()
        ConnectionString = config.ConnectionString
        If Not String.IsNullOrWhiteSpace(ConnectionString) Then
            repo = New clsJobRepository(ConnectionString, config.ConnectionStringMail)
            RefreshAll()
        End If
    End Sub

#End Region

#Region "Journal fichier"

    Private Sub ReadLogFile()
        Dim theLog As LogType = If(rbError.Checked, LogType.Erreur, LogType.Traitement)
        txtLog.Text = clsLog.EventReadlog(theLog)
        txtLog.SelectionStart = txtLog.TextLength
        txtLog.ScrollToCaret()
    End Sub

    Private Sub rbEvent_CheckedChanged(sender As Object, e As EventArgs) Handles rbEvent.CheckedChanged
        ReadLogFile()
    End Sub

    Private Sub rbError_CheckedChanged(sender As Object, e As EventArgs) Handles rbError.CheckedChanged
        ReadLogFile()
    End Sub

    Private Sub btnClearLog_Click(sender As Object, e As EventArgs) Handles btnClearLog.Click
        clsLog.ClearLog(If(rbError.Checked, LogType.Erreur, LogType.Traitement))
        ReadLogFile()
    End Sub

#End Region

    Private Sub Timer1_Tick(sender As Object, e As EventArgs) Handles Timer1.Tick
        ' Rafraîchissement périodique : la file bouge même quand rien ne transite
        ' par le pipe (tâches planifiées par l'application web).
        RefreshAll()
    End Sub

    Private Sub ShowDbError(quoi As String, ex As Exception)
        clsLog.ErrorWritelog("Interface — " & quoi & " : " & ex.Message, LogType.Erreur)
        lblEtat.Text = "Erreur base de données"
        lblEtat.ForeColor = Drawing.Color.Firebrick
        MessageBox.Show("Impossible de lire " & quoi & " :" & vbCrLf & vbCrLf & ex.Message,
                        "Base de données", MessageBoxButtons.OK, MessageBoxIcon.Warning)
    End Sub

End Class
