Imports System.ServiceProcess
Imports System.Text
Imports System.Threading
Imports System.Windows.Forms
Imports nspServiceTraitementRecu.clsLog

''' <summary>
''' Contrôleur en zone de notification : une icône dont la couleur suit l'état
''' du service, et un menu pour le démarrer, l'arrêter, le mettre en pause ou
''' ouvrir l'interface. Repris du contrôleur du service SMTP.
''' </summary>
Module modController

    Private mobNotifyIcon As NotifyIcon
    Private WithEvents mobContextMenu As ContextMenu
    Private WithEvents mobTimer As Timers.Timer
    Private mobServiceController As ServiceController

    Public Sub MainGoControleur()
        Try
            ' Laisse au service le temps de s'installer/demarrer avant de
            ' l'interroger : sinon le premier Refresh leve une exception.
            Thread.Sleep(TimeSpan.FromSeconds(5))

            mobServiceController = New ServiceController(tkbService.TkbServiceName)

            mobNotifyIcon = New NotifyIcon()
            mobNotifyIcon.Visible = False
            mobNotifyIcon.Text = tkbService.TkbDisplayName

            mobContextMenu = New ContextMenu()
            CreateMenu()
            mobNotifyIcon.ContextMenu = mobContextMenu

            SetUpTimer()
            mobNotifyIcon.Visible = True

            clsLog.EventWritelog("Démarrage du contrôleur : " & tkbService.TkbDisplayName, LogType.Traitement)

            Application.Run()

        Catch obEx As Exception
            clsLog.ErrorWritelog("1 - Erreur du contrôleur : " & tkbService.TkbDisplayName & vbCrLf & obEx.Message, LogType.Erreur)
            MsgBox(obEx.Message, MsgBoxStyle.Critical)
            End
        End Try
    End Sub

    Private Sub SetUpTimer()
        mobTimer = New Timers.Timer()
        With mobTimer
            .AutoReset = True
            .Interval = 5000
            .Start()
        End With
    End Sub

    Private Sub CreateMenu()
        mobContextMenu.MenuItems.Add(New MenuItem("Arrêter", New EventHandler(AddressOf StopService)))
        mobContextMenu.MenuItems.Add(New MenuItem("Pause", New EventHandler(AddressOf PauseService)))
        mobContextMenu.MenuItems.Add(New MenuItem("Continuer", New EventHandler(AddressOf ContinueService)))
        mobContextMenu.MenuItems.Add(New MenuItem("Démarrer", New EventHandler(AddressOf StartService)))
        mobContextMenu.MenuItems.Add(New MenuItem("Reçus...", New EventHandler(AddressOf ShowForm1)))
        mobContextMenu.MenuItems.Add("-")
        mobContextMenu.MenuItems.Add(New MenuItem("À propos", New EventHandler(AddressOf AboutBox)))
        mobContextMenu.MenuItems.Add(New MenuItem("Quitter", New EventHandler(AddressOf ExitController)))
    End Sub

    Sub ShowForm1()
        Form1.Show()
        Form1.BringToFront()
    End Sub

    Private Sub GetServiceStatus()
        mobServiceController.Refresh()

        Select Case mobServiceController.Status()
            Case ServiceControllerStatus.Paused
                mobNotifyIcon.Icon = My.Resources.Paused
                SetMenu(False, False, True, False)
            Case ServiceControllerStatus.Running
                mobNotifyIcon.Icon = My.Resources.Running
                SetMenu(True, True, False, False)
            Case ServiceControllerStatus.Stopped
                mobNotifyIcon.Icon = My.Resources.Stopped
                SetMenu(False, False, False, True)
            Case Else
                ' Transitions (start/stop/pause pending) : tout est grise.
                mobNotifyIcon.Icon = My.Resources.Paused
                SetMenu(False, False, False, False)
        End Select

        If mobServiceController.CanPauseAndContinue = False Then
            mobContextMenu.MenuItems(1).Enabled = False
            mobContextMenu.MenuItems(2).Enabled = False
        End If
    End Sub

    Private Sub SetMenu(canStop As Boolean, canPause As Boolean, canContinue As Boolean, canStart As Boolean)
        mobContextMenu.MenuItems(0).Enabled = canStop
        mobContextMenu.MenuItems(1).Enabled = canPause
        mobContextMenu.MenuItems(2).Enabled = canContinue
        mobContextMenu.MenuItems(3).Enabled = canStart
    End Sub

    Private Sub StopService(ByVal sender As Object, ByVal e As EventArgs)
        Try
            If mobServiceController.Status = ServiceControllerStatus.Running AndAlso mobServiceController.CanStop Then
                mobServiceController.Stop()
                clsLog.EventWritelog("Demande d'arrêt du service par le contrôleur.", LogType.Traitement)
            End If
        Catch obEx As Exception
            clsLog.ErrorWritelog("Erreur du contrôleur (arrêt) : " & obEx.Message, LogType.Erreur)
        End Try
    End Sub

    Private Sub PauseService(ByVal sender As Object, ByVal e As EventArgs)
        Try
            If mobServiceController.Status <> ServiceControllerStatus.Paused AndAlso mobServiceController.CanPauseAndContinue Then
                mobServiceController.Pause()
                clsLog.EventWritelog("Mise en pause du service par le contrôleur.", LogType.Traitement)
            End If
        Catch obEx As Exception
            clsLog.ErrorWritelog("Erreur du contrôleur (pause) : " & obEx.Message, LogType.Erreur)
        End Try
    End Sub

    Private Sub ContinueService(ByVal sender As Object, ByVal e As EventArgs)
        Try
            If mobServiceController.Status = ServiceControllerStatus.Paused AndAlso mobServiceController.CanPauseAndContinue Then
                mobServiceController.Continue()
                clsLog.EventWritelog("Reprise du service par le contrôleur.", LogType.Traitement)
            End If
        Catch obEx As Exception
            clsLog.ErrorWritelog("Erreur du contrôleur (reprise) : " & obEx.Message, LogType.Erreur)
        End Try
    End Sub

    Private Sub StartService(ByVal sender As Object, ByVal e As EventArgs)
        Try
            If mobServiceController.Status = ServiceControllerStatus.Stopped Then
                mobServiceController.Start()
                clsLog.EventWritelog("Demande de démarrage du service par le contrôleur.", LogType.Traitement)
            End If
        Catch obEx As Exception
            clsLog.ErrorWritelog("Erreur du contrôleur (démarrage) : " & obEx.Message, LogType.Erreur)
        End Try
    End Sub

    Private Sub AboutBox(ByVal sender As Object, ByVal e As EventArgs)
        Dim sb As New StringBuilder()
        sb.AppendLine(tkbService.TkbDisplayName)
        sb.AppendLine(tkbService.TkbServiceDescription)
        sb.AppendLine()
        sb.AppendLine("CLR : " & Environment.Version.ToString())
        MsgBox(sb.ToString(), MsgBoxStyle.Information, "À propos")
    End Sub

    Private Sub ExitController(ByVal sender As Object, ByVal e As EventArgs)
        Try
            mobTimer.Stop()
            mobTimer.Dispose()
            mobNotifyIcon.Visible = False
            mobNotifyIcon.Dispose()
            mobServiceController.Dispose()

            clsLog.EventWritelog("Arrêt du contrôleur.", LogType.Traitement)
            Application.Exit()
        Catch obEx As Exception
            clsLog.ErrorWritelog("Erreur du contrôleur (sortie) : " & obEx.Message, LogType.Erreur)
        End Try
    End Sub

    Public Sub mobTimer_Elapsed(ByVal sender As Object, ByVal e As Timers.ElapsedEventArgs) Handles mobTimer.Elapsed
        Try
            GetServiceStatus()
        Catch obEx As Exception
            clsLog.ErrorWritelog("Le service ne répond plus au contrôleur, le contrôleur s'arrête. " & obEx.Message, LogType.Erreur)
            ExitController(Nothing, Nothing)
        End Try
    End Sub

End Module
