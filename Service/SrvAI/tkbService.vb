Imports System.IO
Imports System.IO.Pipes
Imports System
Imports System.Collections.Generic
Imports System.ComponentModel
Imports System.Configuration.Install
Imports System.Linq
Imports System.ServiceProcess
Imports System.Text
Imports System.Threading
Imports System.Net
Imports System.Net.Sockets
Imports Microsoft.VisualBasic
Imports System.Timers

Public Class tkbService
    Inherits System.ServiceProcess.ServiceBase

    'Important d'ajuster les information dans la fichier AssemblyInfo.vb avec les paramètre de l'application 
    'On doit etre plus specifique car ce nom est enregistré dans la 
    'base de registre. ex: TekBoxControlerReplication ou encore TekBoxControlerBackup
    'Pour voir le programme controleur dans Windows, utiliser msconfig.
    Const ApplcationNameControleur As String = "TekBox SMTP Service"

    Public Shared TkbDisplayName As String = "Tekbox service SMTP"
    Public Shared TkbServiceName As String = "TekBoxSMTP"
    Public Shared TkbServiceDescription As String = "Service de communication SMTP."

    Public Shared TkbLogServiceSource As String = "TekBoxServiceSMTP"
    Public Shared TkbLogControleurSource As String = "TekBoxControleurSMTP"
    Public Shared TkbLogInstallerSource As String = "TekBoxInstalleSMTP"

    Const TitreInstalle As String = "Installation du service SMTP Windows"
    Const MessageInstalle As String = "Le service SMTP Windows a été installé avec succès! Le controleur est démarré mais le service n'est pas démarré. "
    Const MessageDeInstalle As String = "La service SMTP Windows a été désinstallé acec succès!"
    Const ErreurTitreMessage As String = "Erreur d'installation"
    Const ErreurMessageMessage As String = "Une erreur d'installation c'est produite durant l'installation du service SMTP Windows."
    Const ErreurARG As String = "Argument de ligne de commande invalide."

    'Thread de l'application a mettre en service
    Private ServiceListenSMTPThread As Thread  'Service SMTP
    Private ServicePipeThread As Thread  'Service Pipe Server
    Private ServiceIMAPThread As Thread  'Service IMAP Server
    Private ServiceSendMailThread As Thread  'Service send Mail



    'Private ServiceThreadWD As Thread
    Private StopThread As Boolean = False

    Private Const pipeName As String = "\\.\pipe\MyPipe"
    Private Const BUFFSIZE As Short = 10000
    Private Buffer(BUFFSIZE) As Byte
    Private hPipe As Integer


    Dim handler As Socket

    Enum TASKMAILMODE
        RECEIPT_COMMAND = 1
        WAIT_CONNECTION = 2
    End Enum



    Dim HandlerState As TASKMAILMODE = TASKMAILMODE.WAIT_CONNECTION
    Dim HandlerHeat As DateTime = Now()



    '**************************************************************************************************
    'Point d'entrer du logiciels
    '
    '
    '
    '
    '**************************************************************************************************
    <MTAThread()>
    Public Shared Sub Main(args As String())

        ' Code pour auto installation du service
        'Pour compiler le service, dans le properties Windows le Startup Object doit etre a Sub Main, Pour le mode tester doit etre frmTester
        Try
            Dim path As String = System.Reflection.Assembly.GetExecutingAssembly().Location
            Dim commandLine As String() = Nothing
            Dim msgText As String = ""
            If args.Length > 0 Then
                Select Case args(0).ToUpper()

                    Case "-H"
                        MsgBox(MsgHelp(), MsgBoxStyle.Information Or MsgBoxStyle.OkOnly, "Aide démarage")
                        Return


                        'Démmare le controleur de service, se place dans le icon notification Tray
                        'Case "-T"

                        '    MsgBox("Creation du journal du Service avec les Sources.", MsgBoxStyle.Information, "Journal des événements")
                        '    commandLine = New String() {path}
                        '    Dim myThreadApplication As System.Threading.Thread = New Thread(AddressOf MainApp)
                        '    myThreadApplication.Start()
                        '    Return




                        'Case "-L"
                        '    clsTaskMail.EventWritelog("Test de creation du source du journal du service")

                        '    MsgBox("Creation du journal du Service avec les Sources.", MsgBoxStyle.Information, "Journal des événements")


                        '    Return
                        'Case "-R"
                        '    'UnInstallsource()
                        '    Return

                        'Demarage deu controleur ainsi que du menu dans le systeme tray,
                        'le service doit etre installé pour que le controleur fonction.
                    Case "-E"
                        commandLine = New String() {path}
                        Dim myThreadControleur As System.Threading.Thread = New Thread(AddressOf MainGoControleur)
                        myThreadControleur.SetApartmentState(ApartmentState.STA)
                        myThreadControleur.Start()
                        clsTaskMail.EventWritelog("Démarage du controleur avec ARG = E")
                        Return



                        'Démare l'applicarion pour des fin de test
                    Case "-X"
                        commandLine = New String() {path}
                        Dim myThreadApplication As System.Threading.Thread = New Thread(AddressOf MainApp)
                        myThreadApplication.SetApartmentState(ApartmentState.STA)
                        myThreadApplication.Start()
                        Return

                        'Installe le service, inscrit dans la base de registre le path de l'application pour le faire partir 
                        'le controleur. 
                    Case "-I"
                        commandLine = New String() {path}
                        Dim applicationPath As String = path & " -E"
                        Dim regKey As Microsoft.Win32.RegistryKey
                        'Place le controleur de service en mode auto démarage
                        regKey = Microsoft.Win32.Registry.CurrentUser.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Run", True)
                        regKey.SetValue(ApplcationNameControleur, """" & applicationPath & """")
                        regKey.Close()
                        msgText = MessageInstalle
                        Dim myThreadControleur As System.Threading.Thread = New Thread(AddressOf MainGoControleur)

                        myThreadControleur.SetApartmentState(ApartmentState.STA)
                        myThreadControleur.Start() 'Demmare le controleur

                        'Uninstalle le service dans la base de registre
                    Case "-U"
                        commandLine = New String() {"/u", path}
                        Dim regKey As Microsoft.Win32.RegistryKey
                        regKey = Microsoft.Win32.Registry.CurrentUser.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Run", True)
                        regKey.DeleteValue(ApplcationNameControleur, False)
                        regKey.Close()
                        msgText = MessageDeInstalle
                        'UnInstallsource()
                        System.Configuration.Install.ManagedInstallerClass.InstallHelper(commandLine)
                        MsgBox(msgText & vbCrLf & path, MsgBoxStyle.Information Or MsgBoxStyle.OkOnly, TitreInstalle)
                        Return
                    Case Else
                        Throw New ArgumentException(ErreurARG)
                        Return
                End Select
                System.Configuration.Install.ManagedInstallerClass.InstallHelper(commandLine)
                MsgBox(msgText & vbCrLf & path, MsgBoxStyle.Information Or MsgBoxStyle.OkOnly, TitreInstalle)
                clsTaskMail.EventWritelog("1 - Instalation du service: " & TkbDisplayName)

            Else
                'Demarage du service en mode normal, de facon manuel ou c'est window qui demare le service
                '    ' Write an informational entry to the event log.    
                clsTaskMail.EventWritelog("Démarage en arrière plan du service: " & TkbDisplayName)
                Dim MyTk As tkbService = New tkbService
                System.ServiceProcess.ServiceBase.Run(MyTk)

            End If

        Catch ex As Exception
            clsTaskMail.ErrorWritelog("Main:" & vbCrLf & ErreurMessageMessage & vbCrLf & ex.Message)
            MsgBox(ErreurMessageMessage & vbCrLf & ex.Message, MsgBoxStyle.Critical, ErreurTitreMessage)
        End Try




    End Sub

    Public Shared Function MsgHelp() As String
        Dim MyEXE As String = System.Reflection.Assembly.GetExecutingAssembly().ManifestModule.Name
        Dim msg As String = ""
        msg = msg & "Installation du service: " & MyEXE & " -i" & vbCrLf
        msg = msg & "Désinstallation du service: " & MyEXE & " -u" & vbCrLf
        msg = msg & "Démarage du contrôleur: " & MyEXE & " -e" & vbCrLf
        msg = msg & "Message d'aide: " & MyEXE & " -h" & vbCrLf
        Return msg


    End Function






    '*****************************************************************************************************************************
    '* Demarage du server pipe par windows, cette sub fait une boucle a toute les 1 seconde. 
    '* Envoie tout les status au Client (Controleur)
    '*****************************************************************************************************************************
    Private Sub DoTaskPipeServer()


        Dim HaveStatus As Boolean



        Dim AllStringStatus As String = ""
            Do Until StopThread
            Try
                Thread.Sleep(TimeSpan.FromSeconds(1))

                Dim pipeServer As New NamedPipeServerStream("tekboxpipe", PipeDirection.Out)

                'clsLog.EventWritelog("SERVER: Pipe server wait for connection with client.")
                ' Wait for a client to connect
                pipeServer.WaitForConnection()
                'clsLog.EventWritelog("SERVER: Pipe Client connected on server.")

                Try
                    'Read user input and send that to the client process.
                    Dim sw As New StreamWriter(pipeServer)
                    sw.AutoFlush = True
                    If AllStringStatus <> "" Then
                        'Envoie le dernier status si est le cas
                        sw.WriteLine(AllStringStatus)
                    End If

                    'boucle tant que le thread n est pas arreter
                    'Do Until StopThread = True

                    'prend un nouveau statut peut etre
                    SyncLock thisLock
                            HaveStatus = SMTPStatus.HaveNewStatut
                            AllStringStatus = SMTPStatus.GetAllParam
                        End SyncLock

                        'il doit y avoir un status pour le transmettre au client pipe
                        If AllStringStatus <> "" Then
                            If HaveStatus Then
                                'Nous avons un nouveau statut qui a jamais ete transmit
                                clsLog.EventWritelog("SERVER: nouveau statut: " & HaveStatus.ToString & " Contenu:" & AllStringStatus)
                                sw.WriteLine(AllStringStatus)
                            End If
                        End If
                    'clsLog.EventWritelog("SERVER: isConnected: " & pipeServer.IsConnected)
                    'If Not pipeServer.IsConnected Then
                    '    clsLog.EventWritelog("SERVER: Reset Pipe.")
                    '    Exit Do
                    'End If

                    'Loop
                    pipeServer.Close()
                Catch ex As Exception
                    ' Catch the IOException that is raised if the pipe is broken
                    ' or disconnected
                    clsLog.ErrorWritelog("SERVER: Pipe error: " & ex.Message)
                End Try


            Catch ex As Exception
                clsLog.ErrorWritelog("SERVER: Pipe Stream error: " & ex.Message)
            End Try

        Loop

    End Sub




    '*****************************************************************************************************************************
    '*Cette tache est le code qui roule en boucle pour le protocole SMTP
    '*Une fois sortie de la boucle, le Thread s'arrete
    '*****************************************************************************************************************************
    Private Sub DoTaskListerSMTPMail()


        Dim oXMLconfig As New clsXmlConfig


        Dim MyConnectionString As String = oXMLconfig.ConnectionString

        Dim MyIpAdresse As String = oXMLconfig.IpAdresse
        Dim MySocketPort As Integer = CType(oXMLconfig.SocketPort, Integer)




        Dim EtapeSMTP As String = ""

        Dim TimeOutREC_SEN As Integer = 10000
        Dim CounterMailReceive As Integer = 0

        'Reset le systeme de status pour le controleur
        SyncLock thisLock
            SMTPStatus.Reset()
            SMTPStatus.ThreadSMTPInputStarted = Now.ToLongDateString & " " & Now.ToLongTimeString
            SMTPStatus.StatusSMTPStepInput = "Début du Thread du Listen SMTP"
            SMTPStatus.SMTPStep = "1"
        End SyncLock

        'Prend une instance du thread courrant
        Dim thread As Thread = Thread.CurrentThread
        'Crée une instance de stokage dans SQL
        Dim oTaskMail As New clsTaskMail

        ' Data buffer for incoming data.
        Dim data As String = Nothing
        Dim bytes() As Byte = New [Byte](1024) {}
        ' Establish the local endpoint for the socket. 
        ' Dns.GetHostName returns the name of the host running the application. 
        'Dim ipHostInfo As IPHostEntry = Dns.Resolve(Dns.GetHostName())
        'Dim MyIpadress As IPAddress = ipHostInfo.AddressList(0)

        Dim MyIpadress As IPAddress = IPAddress.Parse(MyIpAdresse)

        Dim localEndPoint As New IPEndPoint(MyIpadress, MySocketPort)
        ' Create a TCP/IP socket.
        Dim listener As New Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp)

        clsTaskMail.EventWritelog("Create a TCP/IP socket at " & MyIpadress.ToString & " on port " & MySocketPort.ToString & " , TreadId: " & thread.ManagedThreadId.ToString)
        EtapeSMTP = "1"
        ' Bind the socket to the local endpoint and listen for incoming connections.
        Dim SentTo As String = ""
        Try

            Try
                EtapeSMTP = "2"
                listener.Bind(localEndPoint)
            Catch ex As Exception
                EtapeSMTP = "3"
                clsTaskMail.ErrorWritelog("Étape: " & EtapeSMTP & ", Erreur dans Listener.Bind. Arret du lister et sorti de la TaskMail:" & ex.Message & " " & " " & thread.ManagedThreadId.ToString)
                listener.Dispose()
                SyncLock thisLock
                    SMTPStatus.StatusSMTPStepInput = "Erreur fatale, le Thread SMTP a été arrêté."
                    SMTPStatus.SMTPStep = "2"
                End SyncLock
                EtapeSMTP = "4"
                Return
            End Try

            EtapeSMTP = "5"
            listener.Listen(10)
            EtapeSMTP = "6"
            ' Start listening for connections. 
            'Ici on boucle dans les thread, si on sort de la boucle alors le thread est killer 
            '
            Do Until StopThread
                Try
                    'clsTaskMail.EventWritelog("Waiting for a connection..., TreadId: " & thread.ManagedThreadId.ToString)
                    EtapeSMTP = "7"
                    SyncLock thisLock
                        SMTPStatus.StatusSMTPStepInput = "En attente d'une connection pour la réception d'un courriel..."
                        SMTPStatus.SMTPStep = "3"
                    End SyncLock


                    clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". En attente d'une connection pour la réception d'un courriel..., TreadId: " & thread.ManagedThreadId.ToString)
                    ' Program is suspended while waiting for an incoming connection. 
                    'Attend un connection TCP/IP, mode blocant
                    handler = listener.Accept()
                    EtapeSMTP = "8"

                    handler.ReceiveTimeout = TimeOutREC_SEN
                    handler.SendTimeout = TimeOutREC_SEN

                    SentTo = ""
                    Dim ep As IPEndPoint = DirectCast(handler.RemoteEndPoint, IPEndPoint)
                    EtapeSMTP = "9"
                    Dim clientIp As IPAddress = ep.Address
                    EtapeSMTP = "10"
                    clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". Incoming connection , IP: " & clientIp.ToString & " , TreadId: " & thread.ManagedThreadId.ToString)
                    'Send 220 to show SMTP server is ready 
                    'Bug ici, il y a eu une connection d'établi mais elle a aussitôt été fermé. Donc le send a planté et une execption.
                    handler.Send(Encoding.ASCII.GetBytes("220 Test SMTP Service ready" & vbCrLf))
                    EtapeSMTP = "11"
                    Try
                        'ici on recoit un mail, on boucle dans le protocol
                        While True

                            bytes = New Byte(1024) {}
                            handler.ReceiveTimeout = TimeOutREC_SEN
                            handler.SendTimeout = TimeOutREC_SEN
                            'Reception en mode bloquant
                            Dim bytesRec As Integer = handler.Receive(bytes)
                            EtapeSMTP = "12"
                            SyncLock thisLock
                                SMTPStatus.StatusSMTPStepInput = "Réception d'une commande protocole SMTP."
                                SMTPStatus.SMTPStep = "4"
                            End SyncLock

                            data = Encoding.ASCII.GetString(bytes, 0, bytesRec)
                            EtapeSMTP = "13"
                            ' Show the data on the console. 
                            clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". Text received, TreadId: " & thread.ManagedThreadId.ToString & ", Data: " & data & vbCrLf)
                            'Process Commands 
                            If data.Length < 4 Then
                                'data = "QUIT"
                                EtapeSMTP = "14"
                                clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". La commande n'est pas valide (moin de 4 caractere) alors QUIT, TreadId: " & thread.ManagedThreadId.ToString & ", Data: " & data & vbCrLf)
                                data = "QUIT"
                            End If
                            Dim CMD As String = data.Substring(0, 4).ToUpper
                            Select Case CMD
                                Case "HELO"
                                    EtapeSMTP = "15"
                                    handler.Send(Encoding.ASCII.GetBytes("250 OK" & vbCrLf))
                                    clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". HELO TreadId: " & thread.ManagedThreadId.ToString)
                                Case "EHLO"
                                    EtapeSMTP = "16"
                                    handler.Send(Encoding.ASCII.GetBytes("250 OK" & vbCrLf))
                                    clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". EHLO TreadId: " & thread.ManagedThreadId.ToString)
                                Case "AUTH"
                                    EtapeSMTP = "17"
                                    handler.Send(Encoding.ASCII.GetBytes("504 Unrecognized authentication type." & vbCrLf))
                                    clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". AUTH TreadId: " & thread.ManagedThreadId.ToString)
                                Case "MAIL"
                                    EtapeSMTP = "18"
                                    handler.Send(Encoding.ASCII.GetBytes("250 OK" & vbCrLf))
                                    clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". MAIL TreadId: " & thread.ManagedThreadId.ToString)
                                Case "RCPT"
                                    EtapeSMTP = "19"
                                    SentTo = SentTo & "," & data.Substring(8).Trim
                                    'If SentTo.ToLower <> "<lookup>" Then
                                    '    handler.Send(Encoding.ASCII.GetBytes("550 No such user here" & vbCrLf))
                                    'Else
                                    handler.Send(Encoding.ASCII.GetBytes("250 OK" & vbCrLf))
                                    clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". RCPT TreadId: " & thread.ManagedThreadId.ToString & " RCPT:" & data)
                            'End If
                                Case "DATA"
                                    EtapeSMTP = "20"
                                    handler.Send(Encoding.ASCII.GetBytes("354 Start mail input; end with." & vbCrLf))
                                    clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". DATA TreadId: " & thread.ManagedThreadId.ToString)
                                Case "QUIT"
                                    EtapeSMTP = "21"
                                    handler.Send(Encoding.ASCII.GetBytes("221 Service closing transmission channel" & vbCrLf))
                                    clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". QUIT, alors sort de la boucle et se reposition en mode attendte d'une nouvelle connection: " & thread.ManagedThreadId.ToString)
                                    Exit While
                                Case Else
                                    Dim Message As String = ""
                                    EtapeSMTP = "22"
                                    Dim timestart As DateTime = Now

                                    clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". Debut Message en atente de ""."", ThreadId: " & thread.ManagedThreadId.ToString)
                                    While data <> vbCrLf & "." & vbCrLf
                                        Message += data
                                        If Not Message.Contains(vbCrLf & "." & vbCrLf) Then
                                            handler.ReceiveTimeout = TimeOutREC_SEN
                                            handler.SendTimeout = TimeOutREC_SEN
                                            'sStep = " step 9 "
                                            bytesRec = handler.Receive(bytes)
                                            data = Encoding.ASCII.GetString(bytes, 0, bytesRec)
                                        End If
                                        If Message.Contains(vbCrLf & "." & vbCrLf) Then Exit While


                                        'Dans le cas ou on ne recoit jamais le point, alors apres 5 seconde je considere le mail comme terminé
                                        'J'ai déjà bloquer dans la boucle BUG 1
                                        Dim timeout As TimeSpan = System.DateTime.Now.Subtract(timestart)
                                        If timeout.Seconds > 5 Then
                                            EtapeSMTP = "36"
                                            clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". Jamais recu de ""."", alors time de 5 secondes atteint, ThreadId: " & thread.ManagedThreadId.ToString)
                                            Exit While
                                        End If

                                    End While
                                    EtapeSMTP = "23"
                                    handler.Send(Encoding.ASCII.GetBytes("250 OK" & vbCrLf))
                                    'Process Message Here 
                                    clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". Le message est recu, fin du message: " & data.Length.ToString & ", ThreadId: " & thread.ManagedThreadId.ToString)
                                    clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ". Le message est: " & Message & ", ThreadId: " & thread.ManagedThreadId.ToString)


                                    'Le mail est recu, il est inscrite dans la base de donneer
                                    oTaskMail.StoreToBD(SentTo, Message, clientIp.ToString)





                                    EtapeSMTP = "24"
                                    SyncLock thisLock
                                        CounterMailReceive = CounterMailReceive + 1
                                        SMTPStatus.CounterEmailInput = CounterMailReceive.ToString
                                        SMTPStatus.MailSizeInput = Message.Length.ToString
                                        SMTPStatus.LastRecipient = SentTo.Substring(1)
                                        SMTPStatus.LastDomainName = ExtractDomain(SentTo.Substring(1))

                                        SMTPStatus.SMTPClientIP = clientIp.ToString
                                        SMTPStatus.StatusSMTPStepInput = "Fin de réception d'un courriel..."
                                        SMTPStatus.SMTPStep = "5"
                                        SMTPStatus.ThreadSMTPLastReceived = Now.ToLongDateString & " " & Now.ToLongTimeString




                                    End SyncLock

                                    Exit While
                            End Select
                        End While
                        EtapeSMTP = "25"
                        'Close Connection 
                        handler.Shutdown(SocketShutdown.Both)
                        handler.Close()
                        EtapeSMTP = "26"
                        clsTaskMail.EventWritelog("Étape: " & EtapeSMTP & ", Le connection (handler) a été fermer. ThreadId: " & thread.ManagedThreadId.ToString)

                        'socket.Close La fonction close() permet la fermeture d'un socket en permettant au système d 'envoyer les données restantes (pour TCP) : 
                        'La fonction shutdown() permet la fermeture d'un socket dans un des deux sens (pour une connexion full-duplex)  
                        'close() comme shutdown() retournent -1 en cas d'erreur, 0 si la fermeture se déroule bien.
                        'Lorsque vous utilisez orienté connexion Socket, appelez toujours le Shutdown méthode avant de fermer le Socket. Cela garantit que toutes les données est 
                        'envoyé et reçu sur le socket connecté avant sa fermeture.
                        'Appelez le Close méthode pour libérer toutes les ressources managées et associés à le Socket. Ne tentez pas de réutiliser le Socket après la fermeture.


                    Catch exSocketException As SocketException
                        EtapeSMTP = "27"
                        clsTaskMail.ErrorWritelog("Étape: " & EtapeSMTP & ", Socket Exception: " & exSocketException.Message & ", Socket error code: " & exSocketException.SocketErrorCode & ", ThreadId: " & thread.ManagedThreadId.ToString)
                        'Timeout du socket error
                        If exSocketException.SocketErrorCode = 10060 Then
                            handler.Close()
                            clsTaskMail.ErrorWritelog("Étape: " & EtapeSMTP & ", Socket Exception 10060, le handler a ete close. ThreadId: " & thread.ManagedThreadId.ToString)
                        End If

                    Catch exThreadAbortException As ThreadAbortException
                        EtapeSMTP = "28"
                        clsTaskMail.ErrorWritelog("Étape: " & EtapeSMTP & ", Thread Abort Exception, le thread a ete Abort: " & exThreadAbortException.Message & ",code erreur: " & exThreadAbortException.HResult.ToString & ", TrheadId: " & thread.ManagedThreadId.ToString)
                        Try
                            If Not handler Is Nothing Then
                                If handler.Connected = True Then
                                    handler.Disconnect(True)
                                    handler.Close()
                                    EtapeSMTP = "29"
                                    clsTaskMail.ErrorWritelog("Étape: " & EtapeSMTP & ", Thread Abort Exception, le handler a ete disconnect et close. ThreadId: " & thread.ManagedThreadId.ToString)
                                End If
                            End If
                        Catch exExceptionDisconnect As Exception
                            EtapeSMTP = "30"
                            clsTaskMail.ErrorWritelog("Étape: " & EtapeSMTP & ", Erreur dans la section de fermeture du handler, " & exExceptionDisconnect.Message & ",Code d'erreur: " & exExceptionDisconnect.HResult.ToString & ", ThreadId: " & thread.ManagedThreadId.ToString)
                        End Try

                        Try
                            If Not listener Is Nothing Then
                                EtapeSMTP = "31"
                                listener.Close()
                            End If
                        Catch exExceptionListner As Exception
                            clsTaskMail.ErrorWritelog("Étape: " & EtapeSMTP & ", Erreur dans la section de fermeture du listener, " & exExceptionListner.Message & ",Code d'erreur: " & exExceptionListner.HResult.ToString & ", ThreadId: " & thread.ManagedThreadId.ToString)
                        End Try

                        clsTaskMail.ErrorWritelog("Sortie de la boucle,  ThreadId: " & thread.ManagedThreadId.ToString)
                        SyncLock thisLock
                            SMTPStatus.StatusSMTPStepInput = "Erreur fatale gèré, le Thread SMTP a été arrêté."
                            SMTPStatus.SMTPStep = "6"
                        End SyncLock
                        Return

                    Catch exReceptionMail As Exception
                        EtapeSMTP = "32"
                        clsTaskMail.ErrorWritelog("Étape: " & EtapeSMTP & ", Erreur general dans la boucle de reception, le handler sera shutdown et close. La boucle continue. " & exReceptionMail.Message & " " & exReceptionMail.HResult.ToString & " " & thread.ManagedThreadId.ToString)
                        handler.Close()
                    End Try


                Catch ex As Exception
                    clsTaskMail.ErrorWritelog("Étape: " & EtapeSMTP & ", Erreur dans la boucle, probablement dans le Send à l'étape 10 Message erreur: " & ex.Message & ",ThreadId: " & thread.ManagedThreadId.ToString)
                End Try
            Loop
        Catch exInitSMTP As Exception
            clsTaskMail.ErrorWritelog("Étape: " & EtapeSMTP & ", Entrer en dehors de la boucle, dans l'initialisation, " & exInitSMTP.Message & ", code d'erreur: " & exInitSMTP.HResult.ToString & ",ThreadId: " & thread.ManagedThreadId.ToString)
            Try
                If Not handler Is Nothing Then
                    EtapeSMTP = "33"
                    handler.Close()
                End If
            Catch exhandlerClose As Exception
                clsTaskMail.ErrorWritelog("Étape: " & EtapeSMTP & ", Errer en dehors de la boucle, dans le fermeture du handeler, " & exhandlerClose.Message & ", code d'erreur: " & exhandlerClose.HResult.ToString & ",ThreadId: " & thread.ManagedThreadId.ToString)
            End Try

            Try
                If Not listener Is Nothing Then
                    EtapeSMTP = "34"
                    listener.Close()
                End If
            Catch exlistenerClose As Exception
                clsTaskMail.ErrorWritelog("Étape: " & EtapeSMTP & ", Errer en dehors de la boucle, dans le fermeture du listener, " & exlistenerClose.Message & ", code d'erreur: " & exlistenerClose.HResult.ToString & ",ThreadId: " & thread.ManagedThreadId.ToString)
            End Try
        End Try
        SyncLock thisLock
            SMTPStatus.StatusSMTPStepInput = "Le Thread SMTP a été arrêté."
            SMTPStatus.SMTPStep = "7"
        End SyncLock

        EtapeSMTP = "35"
    End Sub



    '*****************************************************************************************************************************
    '*Cette tache est le code qui roule en boucle pour le protocole d'envoie de courriel
    '*Une fois sortie de la boucle, le Thread s'arrete
    '*****************************************************************************************************************************
    Private Async Sub DoTaskSendMail()

        CounterMailSend = 0
        SyncLock thisLock
            SMTPStatus.ResetSend()
            SMTPStatus.SendStep = "1"
        End SyncLock





        Dim AllStringStatus As String = ""
        Do Until StopThread
            Try
                SyncLock thisLock
                    SMTPStatus.SendStep = "2"
                End SyncLock

                Dim oTaskMail As New clsTaskMail
                SyncLock thisLock
                    SMTPStatus.SendStep = "2.1"
                End SyncLock


                'Bug de LOCK sur SQL, si plusieurs MAIL sont a envoyer alors 
                'Cette tache est asynchrone et permet a l ecran principale de de ne bloquer.
                Dim simpleTask As System.Threading.Tasks.Task = oTaskMail.SendOneMail
                'attend ici que la tache soit terminer avant de continuer
                Await simpleTask

                'Mettre le temps nessessaire avec chaque transmission
                'Pour empecher les LOCK de base de donnees
                'Si le temps est une seconde alors il y a des LOCK
                Thread.Sleep(TimeSpan.FromSeconds(5))

                SyncLock thisLock
                    SMTPStatus.SendStep = "2.2"
                End SyncLock


            Catch ex As Exception
                Dim SendStep As String
                SyncLock thisLock
                    SendStep = SMTPStatus.SendStep
                End SyncLock


                clsLog.ErrorWritelog("SERVER: Send mail task error: " & SendStep & "->" & ex.Message)
            End Try


        Loop


    End Sub

    '*****************************************************************************************************************************
    '*Cette tache est le code qui roule en boucle pour le protocole IMAP de lecture de courriel
    '*Une fois sortie de la boucle, le Thread s'arrete
    '*****************************************************************************************************************************
    Private Sub DoTaskIMAPServer()

        CounterMailSend = 0
        SyncLock thisLock
            SMTPStatus.ResetSend()
            SMTPStatus.SendStep = "1"
            PoolClientsImap = New ArrayList
        End SyncLock

        Dim _imapListener As TcpListener
        Dim localAddr As IPAddress = IPAddress.Parse("192.168.0.142")


        _imapListener = New TcpListener(localAddr, 143)



        Dim AllStringStatus As String = ""
        Do Until StopThread
            Try
                _imapListener.Start()

                While True
                    Dim client As TcpClient = _imapListener.AcceptTcpClient()

                    'le client est connecté, nous créons un thread juste pour lui et repassons en mode ecoute 
                    Dim clientThread As Thread = New Thread(Sub() HandleIMAPClient(client))
                    clientThread.Name = Guid.NewGuid.ToString
                    clientThread.Start()


                    SyncLock thisLock
                        PoolClientsImap.Add(clientThread)
                    End SyncLock



                End While



            Catch ex As Exception
                clsLog.ErrorWritelog("SERVER DoTaskIMAPServer: Send mail task error: " & ex.Message)
            End Try


        Loop


    End Sub

    Private Sub HandleIMAPClient(ByVal client As TcpClient)

        'Dim session = New ImapSession(client)
        ''session.Sent += AddressOf Session_Sent
        ''session.Recieved += AddressOf Session_Recieved
        'session.HandleSession(CancellationToken.None)
    End Sub





#Region "Outils"
    Function ExtractDomain(emailadresse As String) As String


        Dim smail As String = Replace(emailadresse.Split("@")(1), ">", "")

        Return smail
    End Function
#End Region


#Region "Evénement du service"

    Protected Overrides Sub OnStart(ByVal args() As String)
        Try
            ' Ajoutez ici le code pour démarrer votre service. Cette méthode doit
            ' démarrer votre service.
            'StartMyListenThread("Le service SMTP de reception est démaré.")


            StartSMTP_Send("Le service SMTP de transmistion est démaré.")
            'StartIMAPServer("Le service IMAP Server est démaré.")
            StartPipeServer("Le service Pipe Server est démaré.")

        Catch ex As Exception
            clsTaskMail.ErrorWritelog("OnStart error:" & ex.Message)
        End Try

    End Sub

    Protected Overrides Sub OnStop()
        Try
            StopThreadSendMail()
            'StopThreadSMTPListener()
            StopThreadPipeServer()
            'StopThreadIMAPServer()
        Catch ex As Exception
            clsTaskMail.ErrorWritelog("OnStop error:" & ex.Message)
        End Try

    End Sub
#End Region


#Region "Destruction des threads "


    Sub StopThreadIMAPServer()
        Try

            SyncLock thisLock
                StopThread = True
            End SyncLock

            ' Ajoutez ici le code pour effectuer les destructions nécessaires à l'arrêt de votre service.
            ' Try to signal the thread to end nicely,
            ' (and wait up to 10 seconds).

            ServiceIMAPThread.Join(TimeSpan.FromSeconds(10))

            ' If the thread is still running, abort it.
            If (ServiceIMAPThread.ThreadState And ThreadState.Running) = ThreadState.Running Then
                ServiceIMAPThread.Abort()
                clsTaskMail.EventWritelog("Server IMAP Abort thread.")
            End If

        Catch ex As Exception
            clsTaskMail.ErrorWritelog("Server IMAP error, in stop thread :" & ex.Message)
        End Try

    End Sub



    Sub StopThreadPipeServer()
        Try

            SyncLock thisLock
                StopThread = True
            End SyncLock

            ' Ajoutez ici le code pour effectuer les destructions nécessaires à l'arrêt de votre service.
            ' Try to signal the thread to end nicely,
            ' (and wait up to 10 seconds).

            ServicePipeThread.Join(TimeSpan.FromSeconds(10))

            ' If the thread is still running, abort it.
            If (ServicePipeThread.ThreadState And ThreadState.Running) = ThreadState.Running Then
                ServicePipeThread.Abort()
                clsTaskMail.EventWritelog("Server Pipe Abort thread.")
            End If

        Catch ex As Exception
            clsTaskMail.ErrorWritelog("Server Pipe error, in stop thread :" & ex.Message)
        End Try

    End Sub

    Sub StopThreadSendMail()
        Try

            SyncLock thisLock
                StopThread = True
            End SyncLock

            ' Ajoutez ici le code pour effectuer les destructions nécessaires à l'arrêt de votre service.
            ' Try to signal the thread to end nicely,
            ' (and wait up to 10 seconds).

            ServiceSendMailThread.Join(TimeSpan.FromSeconds(10))

            ' If the thread is still running, abort it.
            If (ServiceSendMailThread.ThreadState And ThreadState.Running) = ThreadState.Running Then
                ServiceSendMailThread.Abort()
                clsTaskMail.EventWritelog("Server Send mail Abort thread.")
            End If

        Catch ex As Exception
            clsTaskMail.ErrorWritelog("Server Send mail error, in stop thread :" & ex.Message)
        End Try

    End Sub

    Sub StopThreadSMTPListener()
        Try
            SyncLock thisLock
                StopThread = True
            End SyncLock

            ' Ajoutez ici le code pour effectuer les destructions nécessaires à l'arrêt de votre service.
            ' Try to signal the thread to end nicely,
            ' (and wait up to 10 seconds).

            ServiceListenSMTPThread.Join(TimeSpan.FromSeconds(10))

            ' If the thread is still running, abort it.
            If (ServiceListenSMTPThread.ThreadState And ThreadState.Running) = ThreadState.Running Then
                ServiceListenSMTPThread.Abort()
                clsTaskMail.EventWritelog("Server SMTP Abort thread.")
            End If

        Catch ex As Exception
            clsTaskMail.ErrorWritelog("Server SMTP error, in stop thread :" & ex.Message)
        End Try


    End Sub
#End Region

#Region "Creation et démarage des threads principals "
    Sub StartMyListenThread(MyMessage As String)
        Try
            ServiceListenSMTPThread = New Thread(AddressOf DoTaskListerSMTPMail)
            ServiceListenSMTPThread.Name = "SMTP_Listener_Mail_Server"
            ServiceListenSMTPThread.IsBackground = True
            ServiceListenSMTPThread.Start()
            clsTaskMail.EventWritelog(MyMessage)

        Catch ex As Exception
            clsTaskMail.ErrorWritelog("Erreur dans le demarage d'un nouveau trhead. " & ex.Message)
        End Try

    End Sub

    Sub StartSMTP_Send(MyMessage As String)
        Try
            ServiceSendMailThread = New Thread(AddressOf DoTaskSendMail)
            ServiceSendMailThread.Name = "Send_Mail_Server"
            ServiceSendMailThread.IsBackground = True
            ServiceSendMailThread.Start()
            clsTaskMail.EventWritelog(MyMessage)

        Catch obEx As Exception

            clsTaskMail.ErrorWritelog("Error in service StartSMTP_Send:" & obEx.Message)
        End Try
    End Sub

    Sub StartPipeServer(MyMessage As String)
        Try

            ServicePipeThread = New Thread(AddressOf DoTaskPipeServer)
            ServicePipeThread.Name = "SMTP_Pipe_Server"
            ServicePipeThread.IsBackground = True
            ServicePipeThread.Start()
            clsTaskMail.EventWritelog(MyMessage)

        Catch obEx As Exception
            clsTaskMail.ErrorWritelog("Error in service StartPipeServer:" & obEx.Message)

        End Try
    End Sub

    Sub StartIMAPServer(MyMessage As String)
        Try

            ServiceIMAPThread = New Thread(AddressOf DoTaskIMAPServer)
            ServiceIMAPThread.Name = "SMTP_Pipe_Server"
            ServiceIMAPThread.IsBackground = True
            ServiceIMAPThread.Start()
            clsTaskMail.EventWritelog(MyMessage)

        Catch obEx As Exception
            clsTaskMail.ErrorWritelog("Error in service StartIMAPServer:" & obEx.Message)

        End Try
    End Sub


#End Region




End Class

<RunInstaller(True)> Public Class MyWindowsServiceInstaller
    Inherits System.Configuration.Install.Installer
    Dim processInstaller = New ServiceProcessInstaller()
    Dim serviceInstaller = New ServiceInstaller()
    Public Sub New()
        Try

        
        'set the privileges
        processInstaller.Account = ServiceAccount.LocalSystem
        serviceInstaller.StartType = ServiceStartMode.Automatic


        serviceInstaller.DisplayName = tkbService.TkbDisplayName
        serviceInstaller.ServiceName = tkbService.TkbServiceName
        serviceInstaller.Description = tkbService.TkbServiceDescription

        'must be the same as what was set in Program's constructor
        Me.Installers.Add(processInstaller)
        Me.Installers.Add(serviceInstaller)
         Catch ex As Exception
            clsTaskMail.ErrorWritelog("MyWindowsServiceInstaller error:" & ex.Message)
        End Try
    End Sub

End Class