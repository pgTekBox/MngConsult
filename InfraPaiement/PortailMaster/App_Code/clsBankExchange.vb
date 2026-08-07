Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Configuration

''' <summary>
''' Transport de fichiers vers/depuis la banque. Le traitement travaille
''' toujours sur des dossiers LOCAUX ; le transport ne fait que la synchro
''' local &lt;-&gt; distant.
''' </summary>
Public Interface IBankTransport
    ''' <summary>Envoie les fichiers du dossier outbox local vers la banque.</summary>
    Sub SyncOutbound(localOutbox As String, archive As String)
    ''' <summary>Recupere les fichiers de la banque dans le dossier inbox local.</summary>
    Sub SyncInbound(localInbox As String)
End Interface

''' <summary>Transport local (dev/simule) : les dossiers locaux SONT le point d'echange.</summary>
Public Class LocalFolderTransport
    Implements IBankTransport
    Public Sub SyncOutbound(localOutbox As String, archive As String) Implements IBankTransport.SyncOutbound
        ' Rien a faire : la "banque" lit directement l'outbox local.
    End Sub
    Public Sub SyncInbound(localInbox As String) Implements IBankTransport.SyncInbound
        ' Rien a faire : la "banque" depose directement dans l'inbox local.
    End Sub
End Class

''' <summary>
''' Transport SFTP reel via WinSCP en ligne de commande (winscp.com).
''' Aucune dependance NuGet : WinSCP doit etre installe sur le serveur.
''' NON teste ici (pas de serveur/WinSCP) : a valider au deploiement.
''' </summary>
Public Class SftpTransport
    Implements IBankTransport

    Private ReadOnly _winscp As String, _host As String, _user As String, _pass As String
    Private ReadOnly _hostKey As String, _remoteOut As String, _remoteIn As String
    Private ReadOnly _port As Integer

    Public Sub New()
        _winscp = Cfg("Bank.Sftp.WinScpPath", "C:\Program Files (x86)\WinSCP\WinSCP.com")
        _host = Cfg("Bank.Sftp.Host", "")
        _port = CInt(Val(Cfg("Bank.Sftp.Port", "22")))
        _user = Cfg("Bank.Sftp.User", "")
        _pass = Cfg("Bank.Sftp.Password", "")
        _hostKey = Cfg("Bank.Sftp.HostKey", "")
        _remoteOut = Cfg("Bank.Sftp.RemoteOut", "/outbox")
        _remoteIn = Cfg("Bank.Sftp.RemoteIn", "/inbox")
    End Sub

    Public Sub SyncOutbound(localOutbox As String, archive As String) Implements IBankTransport.SyncOutbound
        If Not Directory.GetFiles(localOutbox).Any() Then Return
        Dim script As String =
            OpenLine() & vbCrLf &
            "put -nopreservetime -nopermissions """ & localOutbox & "\*"" """ & _remoteOut & "/""" & vbCrLf &
            "exit"
        RunWinScp(script)
        ' Deplacer les fichiers envoyes vers l'archive locale.
        For Each f In Directory.GetFiles(localOutbox)
            Dim dest = Path.Combine(archive, Path.GetFileName(f))
            If File.Exists(dest) Then File.Delete(dest)
            File.Move(f, dest)
        Next
    End Sub

    Public Sub SyncInbound(localInbox As String) Implements IBankTransport.SyncInbound
        Dim script As String =
            OpenLine() & vbCrLf &
            "get -nopreservetime """ & _remoteIn & "/*"" """ & localInbox & "\""" & vbCrLf &
            "rm """ & _remoteIn & "/*""" & vbCrLf &
            "exit"
        RunWinScp(script)
    End Sub

    Private Function OpenLine() As String
        Dim hk As String = If(String.IsNullOrEmpty(_hostKey), "", " -hostkey=""" & _hostKey & """")
        Return "open sftp://" & _user & ":" & _pass & "@" & _host & ":" & _port & "/" & hk
    End Function

    Private Sub RunWinScp(script As String)
        If Not File.Exists(_winscp) Then Throw New Exception("WinSCP introuvable : " & _winscp)
        Dim tmp As String = Path.Combine(Path.GetTempPath(), "winscp_" & Guid.NewGuid().ToString("N") & ".txt")
        File.WriteAllText(tmp, script)
        Try
            Dim psi As New Diagnostics.ProcessStartInfo(_winscp, "/ini=nul /script=""" & tmp & """")
            psi.UseShellExecute = False : psi.CreateNoWindow = True : psi.RedirectStandardOutput = True : psi.RedirectStandardError = True
            Dim p As Diagnostics.Process = Diagnostics.Process.Start(psi)
            Dim outp As String = p.StandardOutput.ReadToEnd()
            p.WaitForExit(120000)
            If p.ExitCode <> 0 Then Throw New Exception("WinSCP a echoue (code " & p.ExitCode & ") : " & outp)
        Finally
            Try : File.Delete(tmp) : Catch : End Try
        End Try
    End Sub

    Private Shared Function Cfg(key As String, dflt As String) As String
        Dim v As String = ConfigurationManager.AppSettings(key)
        Return If(String.IsNullOrEmpty(v), dflt, v)
    End Function
End Class

''' <summary>
''' Orchestrateur d'echange bancaire :
'''   PushOutbound : construit les fichiers .005 des lots a envoyer, les
'''     depose dans l'outbox, marque les lots Submitted, journalise, synchro.
'''   PullInbound : synchro (telecharge), traite chaque fichier de l'inbox
'''     (retour -&gt; contre-passation ; releve -&gt; rapprochement), archive.
''' </summary>
Public Class clsBankExchange

    Public Class ExchangeResult
        Public Sent As Integer
        Public Processed As Integer
        Public Errors As Integer
        Public Lines As New List(Of String)
    End Class

    Private Shared ReadOnly Property ConnStr() As String
        Get
            Return ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    Private Shared Function Cfg(key As String, dflt As String) As String
        Dim v As String = ConfigurationManager.AppSettings(key)
        Return If(String.IsNullOrEmpty(v), dflt, v)
    End Function

    Private Shared ReadOnly Property Root() As String
        Get
            Return Cfg("Bank.RootPath", Path.Combine(Path.GetTempPath(), "60sec_bank"))
        End Get
    End Property
    Private Shared ReadOnly Property Outbox() As String
        Get
            Return Cfg("Bank.OutboxPath", Path.Combine(Root, "outbox"))
        End Get
    End Property
    Private Shared ReadOnly Property Inbox() As String
        Get
            Return Cfg("Bank.InboxPath", Path.Combine(Root, "inbox"))
        End Get
    End Property
    Private Shared ReadOnly Property Archive() As String
        Get
            Return Cfg("Bank.ArchivePath", Path.Combine(Root, "archive"))
        End Get
    End Property

    Public Shared Function CreateTransport() As IBankTransport
        If Cfg("Bank.Transport", "local").ToLowerInvariant() = "sftp" Then Return New SftpTransport()
        Return New LocalFolderTransport()
    End Function

    Private Shared Sub EnsureFolders()
        For Each d In {Outbox, Inbox, Archive}
            If Not Directory.Exists(d) Then Directory.CreateDirectory(d)
        Next
    End Sub

    ''' <summary>Construit et envoie les fichiers des lots a soumettre.</summary>
    Public Shared Function PushOutbound() As ExchangeResult
        EnsureFolders()
        Dim res As New ExchangeResult()
        Dim batches As DataTable = GetTable("s0064ListBatchesToSend")
        For Each b As DataRow In batches.Rows
            Dim batchId As Integer = CInt(b("Id"))
            Try
                Dim built = clsCpa005Builder.BuildFile(batchId)
                Dim filePath As String = Path.Combine(Outbox, built.FileName)
                File.WriteAllText(filePath, built.Content, New UTF8Encoding(False))
                Dim bytes As Integer = New FileInfo(filePath).Length
                Exec("s0063MarkBatchSubmitted", New SqlParameter("@BatchId", batchId), New SqlParameter("@FileName", built.FileName))
                Log("Out", built.FileName, "AFT", batchId, bytes, "Sent", "Lot #" & batchId)
                res.Sent += 1
                res.Lines.Add("Envoye : " & built.FileName & " (lot #" & batchId & ")")
            Catch ex As Exception
                Log("Out", "lot#" & batchId, "AFT", batchId, Nothing, "Error", Truncate(ex.Message, 300))
                res.Errors += 1 : res.Lines.Add("Erreur lot #" & batchId & " : " & ex.Message)
            End Try
        Next
        Try
            CreateTransport().SyncOutbound(Outbox, Archive)
        Catch ex As Exception
            res.Errors += 1 : res.Lines.Add("Synchro sortante : " & ex.Message)
        End Try
        Return res
    End Function

    ''' <summary>Recupere et traite les fichiers recus de la banque.</summary>
    Public Shared Function PullInbound() As ExchangeResult
        EnsureFolders()
        Dim res As New ExchangeResult()
        Try
            CreateTransport().SyncInbound(Inbox)
        Catch ex As Exception
            res.Errors += 1 : res.Lines.Add("Synchro entrante : " & ex.Message)
        End Try

        For Each inFile In Directory.GetFiles(Inbox)
            Dim name As String = Path.GetFileName(inFile)
            Try
                Dim content As String = File.ReadAllText(inFile)
                Dim bytes As Integer = New FileInfo(inFile).Length
                Dim msg As String, ftype As String
                If name.ToLowerInvariant().EndsWith(".csv") Then
                    ftype = "Statement"
                    Dim n As Integer = clsBankRecon.ImportCsv(content, name)
                    msg = n & " ligne(s) de releve"
                Else
                    ftype = "Return"
                    Dim s = clsEft005Returns.ImportReturnFile(content, name)
                    msg = "retours: processed=" & s.Processed & " unmatched=" & s.Unmatched & " errors=" & s.Errors
                End If
                MoveToArchive(inFile)
                Log("In", name, ftype, Nothing, bytes, "Processed", msg)
                res.Processed += 1 : res.Lines.Add(name & " -> " & msg)
            Catch ex As Exception
                Log("In", name, Nothing, Nothing, Nothing, "Error", Truncate(ex.Message, 300))
                res.Errors += 1 : res.Lines.Add(name & " : " & ex.Message)
            End Try
        Next
        Return res
    End Function

    Private Shared Sub MoveToArchive(filePath As String)
        Dim dest As String = Path.Combine(Archive, Path.GetFileName(filePath))
        If File.Exists(dest) Then dest = Path.Combine(Archive, Path.GetFileNameWithoutExtension(filePath) & "_" & Guid.NewGuid().ToString("N").Substring(0, 6) & Path.GetExtension(filePath))
        File.Move(filePath, dest)
    End Sub

    ' --- Acces BD ---
    Private Shared Function GetTable(proc As String) As DataTable
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand(proc, conn)
            cmd.CommandType = CommandType.StoredProcedure
            Dim da As New SqlDataAdapter(cmd) : Dim dt As New DataTable() : da.Fill(dt) : Return dt
        End Using : End Using
    End Function
    Private Shared Sub Exec(proc As String, ParamArray ps As SqlParameter())
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand(proc, conn)
            cmd.CommandType = CommandType.StoredProcedure
            For Each p In ps : cmd.Parameters.Add(p) : Next
            conn.Open() : cmd.ExecuteNonQuery()
        End Using : End Using
    End Sub
    Private Shared Sub Log(dir As String, fileName As String, ftype As String, batchId As Object, bytes As Object, status As String, message As String)
        Exec("s0065SaveExchangeLog",
             New SqlParameter("@Direction", dir),
             New SqlParameter("@FileName", fileName),
             New SqlParameter("@FileType", If(String.IsNullOrEmpty(ftype), CObj(DBNull.Value), ftype)),
             New SqlParameter("@BatchId", If(batchId Is Nothing, CObj(DBNull.Value), batchId)),
             New SqlParameter("@Bytes", If(bytes Is Nothing, CObj(DBNull.Value), bytes)),
             New SqlParameter("@Status", status),
             New SqlParameter("@Message", If(String.IsNullOrEmpty(message), CObj(DBNull.Value), message)))
    End Sub
    Private Shared Function Truncate(s As String, n As Integer) As String
        If String.IsNullOrEmpty(s) OrElse s.Length <= n Then Return s
        Return s.Substring(0, n)
    End Function

End Class
