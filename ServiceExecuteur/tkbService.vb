Imports System.ComponentModel
Imports System.IO
Imports System.IO.Pipes
Imports System.ServiceProcess
Imports System.Threading
Imports System.Windows.Forms
Imports nspServiceExecuteur.clsLog

''' <summary>
''' Service Windows « ServiceExecuteur ».
'''
''' Deux threads d'arriere-plan :
'''   - DoTaskExecuteur  : la boucle d'execution, qui repasse sur la file des
'''     taches a intervalle regulier (configExecuteur.xml).
'''   - DoTaskPipeServer : publie l'etat courant sur un pipe nomme, lu par
'''     l'interface (Form1) quand on l'ouvre.
'''
''' Le programme est aussi son propre installeur et son propre controleur, selon
''' l'argument de ligne de commande (-i, -u, -e, -x, -r, -h), comme le service
''' SMTP dont il reprend la structure.
''' </summary>
Public Class tkbService
    Inherits System.ServiceProcess.ServiceBase

    ' Nom sous lequel le controleur s'inscrit au demarrage de Windows.
    Const ApplcationNameControleur As String = "Executeur de taches Service"

    Public Shared TkbDisplayName As String = "60Sec exécuteur de tâches"
    Public Shared TkbServiceName As String = "ServiceExecuteur"
    Public Shared TkbServiceDescription As String = "Exécution des tâches planifiées : procédures SQL, rappels de factures et traitements à venir."

    Const TitreInstalle As String = "Installation du service d'exécution des tâches"
    Const MessageInstalle As String = "Le service d'exécution des tâches a été installé. Le contrôleur est démarré, le service ne l'est pas encore."
    Const MessageDeInstalle As String = "Le service d'exécution des tâches a été désinstallé."
    Const ErreurTitreMessage As String = "Erreur d'installation"
    Const ErreurMessageMessage As String = "Une erreur s'est produite durant l'installation du service."
    Const ErreurARG As String = "Argument de ligne de commande invalide."

    Public Const PipeName As String = "tekboxpipeexecuteur"

    Private ServiceExecuteurThread As Thread
    Private ServicePipeThread As Thread

    ''' <summary>Sortie cooperative des deux boucles.</summary>
    Private StopThread As Boolean = False

    ''' <summary>Reveille immediatement la boucle d'attente (bouton « Exécuter maintenant »).</summary>
    Private Shared ReadOnly WakeUp As New AutoResetEvent(False)

    Public Shared Sub RequestRunNow()
        WakeUp.Set()
    End Sub

    ''' <summary>
    ''' Le nom doit correspondre a celui pose par l'installeur, sinon le
    ''' gestionnaire de services refuse de demarrer le processus.
    ''' </summary>
    Public Sub New()
        Me.ServiceName = TkbServiceName
        Me.CanPauseAndContinue = True
        Me.CanStop = True
        Me.AutoLog = False
    End Sub

    '**************************************************************************
    ' Point d'entree du programme
    '**************************************************************************
    <MTAThread()>
    Public Shared Sub Main(args As String())

        Try
            Dim path As String = System.Reflection.Assembly.GetExecutingAssembly().Location
            Dim commandLine As String() = Nothing
            Dim msgText As String = ""

            If args.Length > 0 Then
                Select Case args(0).ToUpper()

                    Case "-H"
                        MsgBox(MsgHelp(), MsgBoxStyle.Information Or MsgBoxStyle.OkOnly, "Aide démarrage")
                        Return

                        ' Demarrage du controleur (icone dans la zone de notification).
                    Case "-E"
                        Dim myThreadControleur As New Thread(AddressOf MainGoControleur)
                        myThreadControleur.SetApartmentState(ApartmentState.STA)
                        myThreadControleur.Start()
                        clsLog.EventWritelog("Démarrage du contrôleur avec ARG = E", LogType.Traitement)
                        Return

                        ' Demarrage de l'interface seule (mode test / consultation).
                    Case "-X"
                        Dim myThreadApplication As New Thread(AddressOf MainApp)
                        myThreadApplication.SetApartmentState(ApartmentState.STA)
                        myThreadApplication.Start()
                        Return

                        ' Boucle d'execution en avant-plan, sans passer par le
                        ' gestionnaire de services : c'est le mode qui sert a
                        ' verifier une configuration avant de l'installer.
                    Case "-R"
                        RunForeground()
                        Return

                        ' Installation du service + auto-demarrage du controleur.
                    Case "-I"
                        commandLine = New String() {path}
                        Dim applicationPath As String = path & " -E"
                        Dim regKey As Microsoft.Win32.RegistryKey
                        regKey = Microsoft.Win32.Registry.CurrentUser.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Run", True)
                        regKey.SetValue(ApplcationNameControleur, """" & applicationPath & """")
                        regKey.Close()
                        msgText = MessageInstalle

                        Dim myThreadControleur As New Thread(AddressOf MainGoControleur)
                        myThreadControleur.SetApartmentState(ApartmentState.STA)
                        myThreadControleur.Start()

                        ' Desinstallation.
                    Case "-U"
                        commandLine = New String() {"/u", path}
                        Dim regKey As Microsoft.Win32.RegistryKey
                        regKey = Microsoft.Win32.Registry.CurrentUser.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Run", True)
                        regKey.DeleteValue(ApplcationNameControleur, False)
                        regKey.Close()
                        msgText = MessageDeInstalle
                        System.Configuration.Install.ManagedInstallerClass.InstallHelper(commandLine)
                        MsgBox(msgText & vbCrLf & path, MsgBoxStyle.Information Or MsgBoxStyle.OkOnly, TitreInstalle)
                        Return

                    Case Else
                        Throw New ArgumentException(ErreurARG)
                End Select

                System.Configuration.Install.ManagedInstallerClass.InstallHelper(commandLine)
                MsgBox(msgText & vbCrLf & path, MsgBoxStyle.Information Or MsgBoxStyle.OkOnly, TitreInstalle)
                clsLog.EventWritelog("Installation du service : " & TkbDisplayName, LogType.Traitement)

            Else
                ' Aucun argument : c'est Windows qui demarre le service.
                clsLog.EventWritelog("Démarrage en arrière-plan du service : " & TkbDisplayName, LogType.Traitement)
                System.ServiceProcess.ServiceBase.Run(New tkbService())
            End If

        Catch ex As Exception
            clsLog.ErrorWritelog("Main : " & ErreurMessageMessage & vbCrLf & ex.Message, LogType.Erreur)
            MsgBox(ErreurMessageMessage & vbCrLf & ex.Message, MsgBoxStyle.Critical, ErreurTitreMessage)
        End Try

    End Sub

    Public Shared Function MsgHelp() As String
        Dim myExe As String = System.Reflection.Assembly.GetExecutingAssembly().ManifestModule.Name
        Dim msg As String = ""
        msg &= "Installation du service : " & myExe & " -i" & vbCrLf
        msg &= "Désinstallation du service : " & myExe & " -u" & vbCrLf
        msg &= "Démarrage du contrôleur : " & myExe & " -e" & vbCrLf
        msg &= "Ouverture de l'interface : " & myExe & " -x" & vbCrLf
        msg &= "Exécution en avant-plan : " & myExe & " -r" & vbCrLf
        msg &= "Message d'aide : " & myExe & " -h" & vbCrLf
        Return msg
    End Function

    ''' <summary>
    ''' Le programme est un WinExe : sans cet appel, tout ce qu'il ecrit sur la
    ''' sortie standard en mode -r part dans le vide au lieu d'apparaitre dans
    ''' la console qui l'a lance.
    ''' </summary>
    <Runtime.InteropServices.DllImport("kernel32.dll")>
    Private Shared Function AttachConsole(dwProcessId As Integer) As Boolean
    End Function

    ''' <summary>
    ''' Mode console : la meme boucle, mais dans le processus courant et sans
    ''' service installe. On sort avec Ctrl+C.
    ''' </summary>
    Private Shared Sub RunForeground()
        Try : AttachConsole(-1) : Catch : End Try

        Dim svc As New tkbService()
        Console.WriteLine(TkbDisplayName & " — exécution en avant-plan. Ctrl+C pour arrêter.")

        AddHandler Console.CancelKeyPress,
            Sub(sender As Object, e As ConsoleCancelEventArgs)
                e.Cancel = True
                svc.StopThreadExecuteur()
            End Sub

        svc.StopThread = False
        svc.DoTaskExecuteur()
    End Sub

#Region "Boucle d'exécution"

    ''' <summary>
    ''' Boucle principale : a chaque tour, on demande a clsTaskExecutor de
    ''' traiter un lot de taches, puis on attend l'intervalle configure. Tant
    ''' qu'il reste des taches a faire, on enchaine sans attendre : c'est ce qui
    ''' permet de rattraper un arriere sans dependre de l'intervalle.
    ''' </summary>
    Private Sub DoTaskExecuteur()

        SyncLock thisLock
            ExecStatus.Reset()
            ExecStatus.ThreadStarted = Now.ToString("yyyy-MM-dd HH:mm:ss")
            ExecStatus.Etape = "1"
            ExecStatus.StatusText = "Démarrage"
        End SyncLock

        Do Until StopThread

            Dim intervalSeconds As Integer = 60
            Dim traitees As Integer = 0

            Try
                ' La configuration est relue a chaque tour : changer l'intervalle
                ' ou desactiver l'execution ne demande pas de redemarrage.
                Dim config As New clsXmlConfig()
                intervalSeconds = clsXmlConfig.ToInt(config.IntervalSeconds, 60)

                If String.IsNullOrWhiteSpace(config.ConnectionString) Then
                    SyncLock thisLock
                        ExecStatus.Etape = "2"
                        ExecStatus.StatusText = "Non configuré (chaîne de connexion vide)"
                    End SyncLock

                ElseIf config.Actif <> "1" Then
                    SyncLock thisLock
                        ExecStatus.Etape = "2"
                        ExecStatus.StatusText = "Désactivé dans la configuration"
                    End SyncLock

                Else
                    SyncLock thisLock
                        ExecStatus.Etape = "3"
                        ExecStatus.StatusText = "Exécution en cours"
                    End SyncLock

                    Dim task As New clsTaskExecutor(config)
                    Dim lot As ExecutionBatchResult = task.ProcessBatch()
                    traitees = lot.Traitees

                    CounterSucces += lot.Succes
                    CounterEchec += lot.Echecs

                    Dim repo As New clsJobRepository(config.ConnectionString, config.ConnectionStringMail)
                    Dim reste As Integer = repo.CountAFaire()
                    Dim attente As Integer = repo.CountAApprouver()

                    clsLog.RunningStatus(Now.ToString("yyyy-MM-dd HH:mm:ss"))

                    SyncLock thisLock
                        ExecStatus.Etape = "2"
                        ExecStatus.Queue = reste.ToString()
                        ExecStatus.AApprouver = attente.ToString()
                        ExecStatus.CounterDone = CounterSucces.ToString()
                        ExecStatus.CounterError = CounterEchec.ToString()
                        ExecStatus.LastRun = Now.ToString("yyyy-MM-dd HH:mm:ss")
                        If Not String.IsNullOrEmpty(lot.DernierJob) Then ExecStatus.LastJob = lot.DernierJob
                        ExecStatus.StatusText = If(traitees > 0,
                                                   traitees.ToString() & " tâche(s) exécutée(s), " & reste.ToString() & " en attente",
                                                   "En attente — " & reste.ToString() & " tâche(s) dans la file")
                    End SyncLock

                    If traitees > 0 OrElse lot.Promues > 0 Then
                        clsLog.EventWritelog(lot.Promues & " occurrence(s) promue(s), " &
                                             lot.Succes & " succès, " & lot.Echecs & " échec(s), " &
                                             reste & " restante(s).", LogType.Traitement)
                    End If
                End If

            Catch ex As Exception
                clsLog.ErrorWritelog("Boucle d'exécution : " & ex.Message, LogType.Erreur)
                SyncLock thisLock
                    ExecStatus.LastError = ex.Message
                    ExecStatus.StatusText = "Erreur : " & ex.Message
                End SyncLock
            End Try

            If StopThread Then Exit Do

            ' Un lot plein signifie qu'il reste probablement du travail : on
            ' repart tout de suite plutot que d'attendre le prochain intervalle.
            If traitees > 0 Then
                WakeUp.WaitOne(TimeSpan.FromSeconds(2))
            Else
                WakeUp.WaitOne(TimeSpan.FromSeconds(intervalSeconds))
            End If
        Loop

        SyncLock thisLock
            ExecStatus.Etape = "0"
            ExecStatus.StatusText = "Arrêté"
        End SyncLock
    End Sub

#End Region

#Region "Pipe de statut vers l'interface"

    ''' <summary>
    ''' Publie l'etat courant sur un pipe nomme. Meme protocole que le service
    ''' SMTP : une ligne '|'-separee poussee des qu'un changement est detecte.
    ''' </summary>
    Private Sub DoTaskPipeServer()

        Do Until StopThread
            Dim pipeServer As NamedPipeServerStream = Nothing
            Try
                pipeServer = New NamedPipeServerStream(PipeName, PipeDirection.Out)
                pipeServer.WaitForConnection()

                Try
                    Dim sw As New StreamWriter(pipeServer)
                    sw.AutoFlush = True

                    ' Premier envoi immediat : l'interface affiche quelque chose
                    ' des la connexion, sans attendre un changement d'etat.
                    Dim allStringStatus As String
                    SyncLock thisLock
                        allStringStatus = ExecStatus.GetAllParam()
                    End SyncLock
                    If pipeServer.IsConnected Then sw.WriteLine(allStringStatus)

                    Do Until StopThread OrElse Not pipeServer.IsConnected
                        Thread.Sleep(TimeSpan.FromMilliseconds(300))

                        Dim haveStatus As Boolean = False
                        SyncLock thisLock
                            haveStatus = ExecStatus.HaveNewStatut
                            If haveStatus Then allStringStatus = ExecStatus.GetAllParam()
                        End SyncLock

                        If haveStatus AndAlso pipeServer.IsConnected Then
                            Try
                                sw.WriteLine(allStringStatus)
                            Catch ex As IOException
                                Exit Do   ' l'interface a ete fermee
                            End Try
                        End If
                    Loop

                Catch ex As Exception
                    clsLog.ErrorWritelog("SERVER: Pipe error: " & ex.Message, LogType.Erreur)
                End Try

            Catch ex As Exception
                clsLog.ErrorWritelog("SERVER: Pipe Stream error: " & ex.Message, LogType.Erreur)
            Finally
                If pipeServer IsNot Nothing Then
                    Try : pipeServer.Close() : Catch : End Try
                    Try : pipeServer.Dispose() : Catch : End Try
                End If
            End Try
        Loop
    End Sub

#End Region

#Region "Evénements du service"

    Protected Overrides Sub OnStart(ByVal args() As String)
        Try
            StopThread = False
            StartExecuteur("Le service d'exécution des tâches est démarré.")
            StartPipeServer("Le serveur de statut (pipe) est démarré.")
        Catch ex As Exception
            clsLog.ErrorWritelog("OnStart error: " & ex.Message, LogType.Erreur)
        End Try
    End Sub

    Protected Overrides Sub OnStop()
        Try
            StopThreadExecuteur()
            StopThreadPipeServer()
        Catch ex As Exception
            clsLog.ErrorWritelog("OnStop error: " & ex.Message, LogType.Erreur)
        End Try
    End Sub

    Protected Overrides Sub OnPause()
        StopThreadExecuteur()
    End Sub

    Protected Overrides Sub OnContinue()
        StopThread = False
        StartExecuteur("Reprise de l'exécution des tâches.")
    End Sub

#End Region

#Region "Démarrage et arrêt des threads"

    Sub StartExecuteur(myMessage As String)
        Try
            ServiceExecuteurThread = New Thread(AddressOf DoTaskExecuteur)
            ServiceExecuteurThread.Name = "Executeur_Taches"
            ServiceExecuteurThread.IsBackground = True
            ServiceExecuteurThread.Start()
            clsLog.EventWritelog(myMessage, LogType.Traitement)
        Catch ex As Exception
            clsLog.ErrorWritelog("Error in service StartExecuteur: " & ex.Message, LogType.Erreur)
        End Try
    End Sub

    Sub StartPipeServer(myMessage As String)
        Try
            ServicePipeThread = New Thread(AddressOf DoTaskPipeServer)
            ServicePipeThread.Name = "Executeur_Pipe_Server"
            ServicePipeThread.IsBackground = True
            ServicePipeThread.Start()
            clsLog.EventWritelog(myMessage, LogType.Traitement)
        Catch ex As Exception
            clsLog.ErrorWritelog("Error in service StartPipeServer: " & ex.Message, LogType.Erreur)
        End Try
    End Sub

    Sub StopThreadExecuteur()
        Try
            StopThread = True
            WakeUp.Set()   ' sort tout de suite de l'attente

            If ServiceExecuteurThread IsNot Nothing Then
                ServiceExecuteurThread.Join(TimeSpan.FromSeconds(20))
                If (ServiceExecuteurThread.ThreadState And ThreadState.Running) = ThreadState.Running Then
                    ServiceExecuteurThread.Abort()
                    clsLog.EventWritelog("Thread d'exécution interrompu.", LogType.Traitement)
                End If
            End If
        Catch ex As Exception
            clsLog.ErrorWritelog("Erreur à l'arrêt du thread d'exécution : " & ex.Message, LogType.Erreur)
        End Try
    End Sub

    Sub StopThreadPipeServer()
        Try
            StopThread = True

            If ServicePipeThread IsNot Nothing Then
                ServicePipeThread.Join(TimeSpan.FromSeconds(5))
                If (ServicePipeThread.ThreadState And ThreadState.Running) = ThreadState.Running Then
                    ServicePipeThread.Abort()
                    clsLog.EventWritelog("Thread du pipe interrompu.", LogType.Traitement)
                End If
            End If
        Catch ex As Exception
            clsLog.ErrorWritelog("Erreur à l'arrêt du pipe : " & ex.Message, LogType.Erreur)
        End Try
    End Sub

#End Region

End Class

<RunInstaller(True)>
Public Class MyWindowsServiceInstaller
    Inherits System.Configuration.Install.Installer

    Dim processInstaller As New ServiceProcessInstaller()
    Dim serviceInstaller As New ServiceInstaller()

    Public Sub New()
        Try
            processInstaller.Account = ServiceAccount.LocalSystem
            serviceInstaller.StartType = ServiceStartMode.Automatic

            serviceInstaller.DisplayName = tkbService.TkbDisplayName
            serviceInstaller.ServiceName = tkbService.TkbServiceName
            serviceInstaller.Description = tkbService.TkbServiceDescription

            Me.Installers.Add(processInstaller)
            Me.Installers.Add(serviceInstaller)
        Catch ex As Exception
            clsLog.ErrorWritelog("MyWindowsServiceInstaller error: " & ex.Message, clsLog.LogType.Erreur)
        End Try
    End Sub

End Class
