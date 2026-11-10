Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Net
Imports System.Text
Imports System.Web.Hosting
Imports Newtonsoft.Json.Linq

''' <summary>
''' Le cycle du service exécuteur (ServiceExecuteur.clsTaskExecutor), lancé depuis
''' l'ERP à l'affichage du tableau de bord, EN ARRIÈRE-PLAN : la page n'attend pas.
'''
''' Mesure temporaire (2026-11-10) : le service déployé sur le serveur ne regarnit
''' plus son planning depuis le 2026-09-07, si bien que les tâches à calendrier
''' (SYNC_ACTIVITES…) ne sont jamais planifiées.
'''
''' Un passage fait exactement ce que fait le service :
'''   1. s0742MarquerAApprouver      — occurrences qui exigent une approbation ;
'''   2. s0738PromouvoirPlanningEchu — occurrences échues → exécutions ;
'''   3. sp_GenererPlanningJobs      — au plus une fois par 15 minutes, APRÈS la
'''                                    promotion (elle expire ce qui est échu) ;
'''   4. jusqu'à 5 exécutions : s0739ClaimNextExecution (verrou, aucun doublon avec
'''      le service), puis JobRunner.ashx de la console d'administration (clé
'''      partagée X-Job-Key), puis s0740SaveExecutionResult + s0741LogExecution.
'''
''' Au plus un passage par minute pour tout le site, jamais deux en même temps.
''' Web.config (non versionné) : JobAdminBaseUrl (ex. http://localhost:8082) et
''' JobRunnerKey (la même clé que la console). Sans eux, les étapes 1 à 3 tournent
''' quand même ; les exécutions restent pour le service du serveur.
''' </summary>
Public NotInheritable Class clsExecuteurTaches

    Private Const BatchSize As Integer = 5
    Private Const LockSeconds As Integer = 900
    Private Shared ReadOnly IntervalleCycle As TimeSpan = TimeSpan.FromMinutes(1)
    Private Shared ReadOnly IntervallePlanning As TimeSpan = TimeSpan.FromMinutes(15)

    Private Shared ReadOnly Verrou As New Object()
    Private Shared _enCours As Boolean
    Private Shared _dernierCycle As Date = Date.MinValue
    Private Shared _dernierPlanning As Date = Date.MinValue

    Private Sub New()
    End Sub

    ''' <summary>Lance un passage en arrière-plan, si le précédent date d'au moins une minute.</summary>
    Public Shared Sub Lancer()
        SyncLock Verrou
            If _enCours Then Return
            If Date.UtcNow < _dernierCycle.Add(IntervalleCycle) Then Return
            _enCours = True
            _dernierCycle = Date.UtcNow
        End SyncLock

        Try
            HostingEnvironment.QueueBackgroundWorkItem(Sub(ct) Cycle())
        Catch ex As Exception
            ' Hors d'un hôte ASP.NET (ou arrêt en cours) : on n'insiste pas.
            Journal("Lancement : " & ex.Message)
            SyncLock Verrou : _enCours = False : End SyncLock
        End Try
    End Sub

    Private Shared Sub Cycle()
        Try
            ExecSql("s0742MarquerAApprouver", 120)
            ExecSql("s0738PromouvoirPlanningEchu", 120)

            Dim regarnir As Boolean
            SyncLock Verrou
                regarnir = Date.UtcNow >= _dernierPlanning.Add(IntervallePlanning)
                If regarnir Then _dernierPlanning = Date.UtcNow
            End SyncLock
            If regarnir Then
                Try
                    ExecSql("sp_GenererPlanningJobs", 300)
                Catch ex As Exception
                    Journal("Génération du planning : " & ex.Message)
                End Try
            End If

            If UrlRunner() = "" OrElse Cle() = "" Then Return   ' le service du serveur exécutera

            For i As Integer = 1 To BatchSize
                Dim travail As DataRow = Reserver()
                If travail Is Nothing Then Exit For
                Executer(travail)
            Next
        Catch ex As Exception
            Journal("Cycle : " & ex.Message)
        Finally
            SyncLock Verrou : _enCours = False : End SyncLock
        End Try
    End Sub

    ' ---------------------------------------------------------------------
    ' Une exécution
    ' ---------------------------------------------------------------------

    Private Shared Function Reserver() As DataRow
        Dim ds As DataSet = ExecSql("s0739ClaimNextExecution", 120,
                                    New SqlParameter("@LockSeconds", LockSeconds),
                                    New SqlParameter("@WorkerName", "ERP/" & Environment.MachineName))
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return Nothing
        Return ds.Tables(0).Rows(0)
    End Function

    ''' <summary>Confie la tâche à la console et enregistre son issue. Ne lève jamais.</summary>
    Private Shared Sub Executer(r As DataRow)
        Dim executionId As Integer = Num(r, "ExecutionId")
        Dim timeout As Integer = Num(r, "TimeoutSeconds")
        Dim chrono As Stopwatch = Stopwatch.StartNew()

        Log(executionId, "INFO", "Prise en charge par l'ERP (" & Environment.MachineName & ") — confiée à " & UrlRunner() & ".", Nothing)
        Try
            Dim issue As JObject = AppelerConsole(executionId, timeout)
            chrono.Stop()
            Dim succes As Boolean = issue("success") IsNot Nothing AndAlso issue("success").Value(Of Boolean)()
            Dim message As String = If(issue("message") Is Nothing, "", issue("message").Value(Of String)())
            Dim detail As String = If(issue("detail") Is Nothing, Nothing, issue("detail").Value(Of String)())
            Dim lignes As Object = Nothing
            If issue("rows") IsNot Nothing AndAlso issue("rows").Type <> JTokenType.Null Then lignes = issue("rows").Value(Of Integer)()

            Sauver(executionId, If(succes, "SUCCES", "ECHEC"), message, detail, lignes, CInt(chrono.ElapsedMilliseconds))
            Log(executionId, If(succes, "INFO", "ERROR"), message, detail)
        Catch ex As Exception
            chrono.Stop()
            Dim message As String = "Échec : " & ex.Message
            Try
                Sauver(executionId, "ECHEC", message, ex.ToString(), Nothing, CInt(chrono.ElapsedMilliseconds))
                Log(executionId, "ERROR", message, ex.ToString())
            Catch exSave As Exception
                Journal("Exécution " & executionId & " : " & exSave.Message)
            End Try
        End Try
    End Sub

    ''' <summary>POST executionId=… sur JobRunner.ashx ; renvoie le compte rendu JSON.</summary>
    Private Shared Function AppelerConsole(executionId As Integer, timeoutSeconds As Integer) As JObject
        Dim corps As Byte() = Encoding.UTF8.GetBytes("executionId=" & executionId.ToString())
        Dim req As HttpWebRequest = CType(WebRequest.Create(UrlRunner()), HttpWebRequest)
        req.Method = "POST"
        req.ContentType = "application/x-www-form-urlencoded"
        req.ContentLength = corps.Length
        req.Headers("X-Job-Key") = Cle()
        req.UserAgent = "ERP-Executeur/" & Environment.MachineName
        Dim ms As Integer = (If(timeoutSeconds > 0, timeoutSeconds, 300) + 30) * 1000
        req.Timeout = ms
        req.ReadWriteTimeout = ms

        Using flux As Stream = req.GetRequestStream()
            flux.Write(corps, 0, corps.Length)
        End Using

        Dim brut As String
        Try
            Using rep As HttpWebResponse = CType(req.GetResponse(), HttpWebResponse)
                brut = Lire(rep)
            End Using
        Catch ex As WebException When ex.Response IsNot Nothing
            Using rep As HttpWebResponse = CType(ex.Response, HttpWebResponse)
                brut = Lire(rep)
            End Using
            Try
                Dim o As JObject = JObject.Parse(brut)
                o("success") = False
                Return o
            Catch
                Throw New InvalidOperationException("HTTP " & CInt(CType(ex.Response, HttpWebResponse).StatusCode) & " sur " & UrlRunner())
            End Try
        End Try

        Try
            Return JObject.Parse(brut)
        Catch
            Dim extrait As String = If(brut, "").Replace(vbCr, " ").Replace(vbLf, " ")
            If extrait.Length > 300 Then extrait = extrait.Substring(0, 300) & "…"
            Throw New InvalidOperationException("Réponse illisible de la console d'administration (" & UrlRunner() & ") : " & extrait)
        End Try
    End Function

    ' ---------------------------------------------------------------------
    ' Base de données (procédures stockées seulement)
    ' ---------------------------------------------------------------------

    Private Shared Sub Sauver(executionId As Integer, statut As String, message As String, detail As String, lignes As Object, dureeMs As Integer)
        ExecSql("s0740SaveExecutionResult", 120,
                New SqlParameter("@ExecutionId", executionId),
                New SqlParameter("@Statut", statut),
                New SqlParameter("@ResultatMessage", If(message, "")),
                New SqlParameter("@ResultatDetail", If(detail, CObj(DBNull.Value))),
                New SqlParameter("@LignesTraitees", If(lignes, DBNull.Value)),
                New SqlParameter("@DureeMs", dureeMs))
    End Sub

    Private Shared Sub Log(executionId As Integer, niveau As String, message As String, detail As String)
        Try
            ExecSql("s0741LogExecution", 120,
                    New SqlParameter("@JobExecutionId", executionId),
                    New SqlParameter("@Niveau", niveau),
                    New SqlParameter("@Message", If(message, "")),
                    New SqlParameter("@Detail", If(detail, CObj(DBNull.Value))))
        Catch ex As Exception
            Journal("Journal de l'exécution " & executionId & " : " & ex.Message)
        End Try
    End Sub

    Private Shared Function ExecSql(proc As String, timeoutSeconds As Integer, ParamArray parametres As SqlParameter()) As DataSet
        Using cnn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
            Using cmd As New SqlCommand(proc, cnn) With {.CommandType = CommandType.StoredProcedure, .CommandTimeout = timeoutSeconds}
                If parametres IsNot Nothing Then
                    For Each p As SqlParameter In parametres : cmd.Parameters.Add(p) : Next
                End If
                Dim ds As New DataSet()
                Using da As New SqlDataAdapter(cmd) : da.Fill(ds) : End Using
                Return ds
            End Using
        End Using
    End Function

    ' ---------------------------------------------------------------------
    ' Petits outils
    ' ---------------------------------------------------------------------

    Private Shared Function UrlRunner() As String
        Dim b As String = If(ConfigurationManager.AppSettings("JobAdminBaseUrl"), "").Trim()
        If b = "" Then Return ""
        b = b.TrimEnd("/"c)
        If b.EndsWith("JobRunner.ashx", StringComparison.OrdinalIgnoreCase) Then Return b
        Return b & "/JobRunner.ashx"
    End Function

    Private Shared Function Cle() As String
        Return If(ConfigurationManager.AppSettings("JobRunnerKey"), "").Trim()
    End Function

    Private Shared Function Lire(rep As HttpWebResponse) As String
        Using flux As Stream = rep.GetResponseStream()
            If flux Is Nothing Then Return ""
            Using sr As New StreamReader(flux, Encoding.UTF8)
                Return sr.ReadToEnd()
            End Using
        End Using
    End Function

    Private Shared Function Num(r As DataRow, col As String) As Integer
        If r Is Nothing OrElse Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return 0
        Return Convert.ToInt32(r(col))
    End Function

    Private Shared Sub Journal(message As String)
        System.Diagnostics.Debug.WriteLine("Exécuteur ERP — " & message)
        System.Diagnostics.Trace.TraceWarning("Exécuteur ERP — " & message)
    End Sub

End Class
