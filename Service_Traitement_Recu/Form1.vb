Imports System.ComponentModel
Imports System.Data
Imports System.IO
Imports System.IO.Pipes
Imports System.Threading
Imports System.Windows.Forms
Imports nspServiceTraitementRecu.clsLog

''' <summary>
''' Interface de surveillance du service :
'''   - « Reçus à faire »  : la file d'attente, avec l'étape suivante et la
'''      dernière erreur de chaque reçu ;
'''   - « Résultat (JSON) » : le journal de traitement et le JSON produit ;
'''   - « Journal »        : les fichiers texte écrits par le service.
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
    Private repo As clsReceiptRepository

#Region "Ouverture / fermeture"

    Private Sub Form1_Load(sender As Object, e As EventArgs) Handles MyBase.Load

        Dim config As New clsXmlConfig()
        ConnectionString = config.ConnectionString

        Me.Text = "Traitement des reçus — " & Version()
        lblDernierPassage.Text = clsLog.ReadRunningStatus()

        If String.IsNullOrWhiteSpace(ConnectionString) Then
            lblEtat.Text = "Non configuré"
            MessageBox.Show("La chaîne de connexion n'est pas configurée." & vbCrLf &
                            "Ouvrez « Paramètres... » pour la renseigner.",
                            "Configuration", MessageBoxButtons.OK, MessageBoxIcon.Information)
        Else
            repo = New clsReceiptRepository(ConnectionString)
            RefreshAll()
        End If

        ReadLogFile()
        StartPipeThread()

        Timer1.Enabled = True
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
        PipeClientThread.Name = "Recu_Pipe_Client"
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
        Dim status As New clsReceiptStatus()

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
    Private Sub ShowStatus(status As clsReceiptStatus)
        If Me.IsDisposed Then Return
        Try
            If Me.InvokeRequired Then
                Me.Invoke(New Action(Of clsReceiptStatus)(AddressOf ShowStatus), status)
                Return
            End If

            lblEtat.Text = status.StatusText
            lblEtat.ForeColor = If(String.IsNullOrEmpty(status.LastError), Drawing.Color.ForestGreen, Drawing.Color.Firebrick)
            lblDernierPassage.Text = status.LastRun
            lblFile.Text = status.Queue
            lblTraites.Text = status.CounterDone
            lblErreurs.Text = status.CounterError
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

#Region "Grilles"

    Private Sub RefreshAll()
        BindStats()
        BindQueue()
        BindLog()
    End Sub

    Private Sub BindStats()
        If repo Is Nothing Then Return
        Try
            Dim r As DataRow = repo.GetStats()
            If r Is Nothing Then Return

            lblFile.Text = Convert.ToString(r("AFaire"))
            lblErreurs.Text = Convert.ToString(r("EnErreur"))
            lblTraites.Text = Convert.ToString(r("Termines"))
        Catch ex As Exception
            ShowDbError("les compteurs", ex)
        End Try
    End Sub

    Private Sub BindQueue()
        If repo Is Nothing Then Return
        Try
            Dim dt As DataTable = repo.GetQueue(chkOnlyPending.Checked, 500)
            dvQueue.DataSource = dt
            If dvQueue.Columns.Contains("colQCreated") Then
                dvQueue.Columns("colQCreated").DefaultCellStyle.Format = "yyyy-MM-dd HH:mm"
            End If
        Catch ex As Exception
            ShowDbError("la liste des reçus", ex)
        End Try
    End Sub

    Private Sub BindLog()
        If repo Is Nothing Then Return
        Try
            Dim dt As DataTable = repo.GetProcessLog(500)
            dvLog.DataSource = dt
            If dvLog.Columns.Contains("colLCreated") Then
                dvLog.Columns("colLCreated").DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"
            End If
            If dvLog.Columns.Contains("colLCost") Then
                dvLog.Columns("colLCost").DefaultCellStyle.Format = "N6"
            End If
        Catch ex As Exception
            ShowDbError("le journal de traitement", ex)
        End Try
    End Sub

    ''' <summary>Colore les lignes selon l'état, pour repérer les erreurs d'un coup d'œil.</summary>
    Private Sub dvQueue_RowPrePaint(sender As Object, e As DataGridViewRowPrePaintEventArgs) Handles dvQueue.RowPrePaint
        If e.RowIndex < 0 OrElse e.RowIndex >= dvQueue.Rows.Count Then Return
        Dim row As DataGridViewRow = dvQueue.Rows(e.RowIndex)

        Dim erreur As Object = row.Cells("colQErreur").Value
        Dim etat As Object = row.Cells("colQEtat").Value

        If erreur IsNot Nothing AndAlso Not IsDBNull(erreur) AndAlso Convert.ToString(erreur) <> "" Then
            row.DefaultCellStyle.BackColor = Drawing.Color.MistyRose
        ElseIf Convert.ToString(etat) = "Terminé" Then
            row.DefaultCellStyle.BackColor = Drawing.Color.Honeydew
        Else
            row.DefaultCellStyle.BackColor = Drawing.Color.White
        End If
    End Sub

    Private Sub dvLog_RowPrePaint(sender As Object, e As DataGridViewRowPrePaintEventArgs) Handles dvLog.RowPrePaint
        If e.RowIndex < 0 OrElse e.RowIndex >= dvLog.Rows.Count Then Return
        Dim row As DataGridViewRow = dvLog.Rows(e.RowIndex)

        Dim resultat As String = Convert.ToString(row.Cells("colLResultat").Value)
        If resultat = "Erreur" Then
            row.DefaultCellStyle.BackColor = Drawing.Color.MistyRose
        Else
            row.DefaultCellStyle.BackColor = Drawing.Color.White
        End If
    End Sub

    ''' <summary>Affiche le JSON de la ligne sélectionnée sous la grille.</summary>
    Private Sub dvLog_SelectionChanged(sender As Object, e As EventArgs) Handles dvLog.SelectionChanged
        txtJson.Text = PrettyJson(SelectedLogJson())
    End Sub

    Private Function SelectedLogJson() As String
        If dvLog.CurrentRow Is Nothing Then Return ""
        Dim v As Object = dvLog.CurrentRow.Cells("colLJson").Value
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Return Convert.ToString(v)
    End Function

    ''' <summary>Réindente le JSON pour qu'il soit lisible dans la zone de texte.</summary>
    Private Shared Function PrettyJson(raw As String) As String
        If String.IsNullOrWhiteSpace(raw) Then Return ""
        Try
            Dim parsed = Newtonsoft.Json.JsonConvert.DeserializeObject(raw)
            Return Newtonsoft.Json.JsonConvert.SerializeObject(parsed, Newtonsoft.Json.Formatting.Indented)
        Catch
            ' Pas du JSON valide (message d'erreur, texte brut) : on l'affiche tel quel.
            Return raw
        End Try
    End Function

    Private Function SelectedQueueGuid() As Guid?
        If dvQueue.CurrentRow Is Nothing Then Return Nothing
        Dim v As Object = dvQueue.CurrentRow.Cells("colQGuid").Value
        If v Is Nothing OrElse IsDBNull(v) Then Return Nothing

        Dim g As Guid
        If Guid.TryParse(Convert.ToString(v), g) Then Return g
        Return Nothing
    End Function

#End Region

#Region "Boutons"

    Private Sub btnRefresh_Click(sender As Object, e As EventArgs) Handles btnRefresh.Click
        RefreshAll()
        ReadLogFile()
    End Sub

    Private Sub chkOnlyPending_CheckedChanged(sender As Object, e As EventArgs) Handles chkOnlyPending.CheckedChanged
        BindQueue()
    End Sub

    ''' <summary>
    ''' Traite un lot tout de suite, depuis l'interface.
    '''
    ''' Le service peut tourner en même temps : la réservation se fait en base
    ''' (s0730ClaimNextReceipt pose un verrou), donc le même reçu ne peut pas
    ''' être pris deux fois. On réveille aussi la boucle du service au cas où
    ''' l'interface tourne dans le même processus.
    ''' </summary>
    Private Async Sub btnTraiterMaintenant_Click(sender As Object, e As EventArgs) Handles btnTraiterMaintenant.Click

        If repo Is Nothing Then
            MessageBox.Show("Configurez d'abord la chaîne de connexion.", "Traitement",
                            MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return
        End If

        Dim config As New clsXmlConfig()

        If MessageBox.Show("Traiter maintenant jusqu'à " & config.BatchSize & " reçu(s) ?" & vbCrLf & vbCrLf &
                           "Les reçus sans JSON seront envoyés à ChatGPT : ces appels sont facturés.",
                           "Traiter maintenant", MessageBoxButtons.YesNo, MessageBoxIcon.Question) <> DialogResult.Yes Then
            Return
        End If

        tkbService.RequestRunNow()

        btnTraiterMaintenant.Enabled = False
        Me.Cursor = Cursors.WaitCursor
        lblEtat.Text = "Traitement en cours..."
        lblEtat.ForeColor = Drawing.Color.DarkOrange

        Try
            Dim task As New clsTaskReceipt(config)
            Dim n As Integer = Await task.ProcessBatchAsync()

            lblEtat.Text = If(n > 0, n.ToString() & " reçu(s) traité(s)", "Rien à traiter")
            lblEtat.ForeColor = Drawing.Color.ForestGreen
            clsLog.EventWritelog(n.ToString() & " reçu(s) traité(s) depuis l'interface.", LogType.Traitement)

        Catch ex As Exception
            lblEtat.Text = "Erreur : " & ex.Message
            lblEtat.ForeColor = Drawing.Color.Firebrick
            clsLog.ErrorWritelog("Traitement depuis l'interface : " & ex.Message, LogType.Erreur)
            MessageBox.Show(ex.Message, "Traitement", MessageBoxButtons.OK, MessageBoxIcon.Error)

        Finally
            Me.Cursor = Cursors.Default
            btnTraiterMaintenant.Enabled = True
            RefreshAll()
            ReadLogFile()
        End Try
    End Sub

    Private Sub btnSetting_Click(sender As Object, e As EventArgs) Handles btnSetting.Click
        Dim f As New frmSetting()
        f.ShowDialog(Me)

        ' La configuration peut avoir change de base : on repart de zero.
        Dim config As New clsXmlConfig()
        ConnectionString = config.ConnectionString
        If Not String.IsNullOrWhiteSpace(ConnectionString) Then
            repo = New clsReceiptRepository(ConnectionString)
            RefreshAll()
        End If
    End Sub

    Private Sub btnRefaireTout_Click(sender As Object, e As EventArgs) Handles btnRefaireTout.Click
        Dim g As Guid? = SelectedQueueGuid()
        If Not g.HasValue Then Return

        If MessageBox.Show("Tout refaire pour ce reçu ?" & vbCrLf & vbCrLf &
                           "Le JSON actuel sera effacé et redemandé à ChatGPT : cet appel est facturé.",
                           "Refaire", MessageBoxButtons.YesNo, MessageBoxIcon.Question) <> DialogResult.Yes Then Return

        Try
            repo.ResetForRetry(g.Value, 0)
            RefreshAll()
        Catch ex As Exception
            ShowDbError("la remise en file du reçu", ex)
        End Try
    End Sub

    Private Sub btnRefaireJson_Click(sender As Object, e As EventArgs) Handles btnRefaireJson.Click
        Dim g As Guid? = SelectedQueueGuid()
        If Not g.HasValue Then Return

        Try
            ' On garde le JSON déjà payé : seule sa transformation est rejouée.
            repo.ResetForRetry(g.Value, 3)
            RefreshAll()
        Catch ex As Exception
            ShowDbError("la remise en file du reçu", ex)
        End Try
    End Sub

    Private Sub btnVoirJsonQueue_Click(sender As Object, e As EventArgs) Handles btnVoirJsonQueue.Click
        Dim g As Guid? = SelectedQueueGuid()
        If Not g.HasValue Then Return

        Try
            Dim json As String = repo.GetJson(g.Value)
            If String.IsNullOrWhiteSpace(json) Then
                MessageBox.Show("Ce reçu n'a pas encore de JSON.", "JSON", MessageBoxButtons.OK, MessageBoxIcon.Information)
                Return
            End If

            Dim f As New frmJsonDetail()
            f.ShowJson(PrettyJson(json))
            f.ShowDialog(Me)
        Catch ex As Exception
            ShowDbError("la lecture du JSON", ex)
        End Try
    End Sub

    Private Sub btnCopyJson_Click(sender As Object, e As EventArgs) Handles btnCopyJson.Click
        If String.IsNullOrEmpty(txtJson.Text) Then Return
        Clipboard.SetText(txtJson.Text)
    End Sub

    Private Sub dvLog_CellDoubleClick(sender As Object, e As DataGridViewCellEventArgs) Handles dvLog.CellDoubleClick
        If e.RowIndex < 0 Then Return
        Dim f As New frmJsonDetail()
        f.ShowJson(PrettyJson(SelectedLogJson()))
        f.ShowDialog(Me)
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
        ' Rafraîchissement périodique : la file bouge même quand rien ne
        ' transite par le pipe (reçus ajoutés par l'application web).
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
