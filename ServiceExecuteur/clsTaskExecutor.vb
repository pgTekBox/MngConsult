''' <summary>
''' Ce que l'executeur a fait pendant un passage de la boucle.
''' </summary>
Public Class ExecutionBatchResult
    Public Property Promues As Integer
    Public Property Marquees As Integer
    Public Property Planifiees As Integer
    Public Property Succes As Integer
    Public Property Echecs As Integer
    Public Property DernierJob As String = ""

    Public ReadOnly Property Traitees As Integer
        Get
            Return Succes + Echecs
        End Get
    End Property
End Class

''' <summary>
''' L'ordonnanceur. A chaque passage :
'''   1. les occurrences dont la definition exige une approbation passent en
'''      attente de decision (elles n'iront pas plus loin sans l'utilisateur) ;
'''   2. les occurrences echues et approuvees deviennent des executions ;
'''   3. le planning se regarnit a partir des calendriers ;
'''   4. les executions sont prises une a une, verrouillees, et confiees a la
'''      console d'administration.
'''
''' Ce service ne sait rien d'aucune tache en particulier — ni ce qu'elle fait,
''' ni a qui elle ecrit, ni quelles procedures elle appelle. Tout cela vit dans
''' clsJobRunner, cote console : une tache se modifie donc en redeployant
''' l'application web, jamais ce service.
'''
''' Ce qui reste ici, c'est le cycle de vie : le verrou, le statut, le journal,
''' la duree. La console fait le travail et rend un compte rendu.
''' </summary>
Public Class clsTaskExecutor

    Private ReadOnly _config As clsXmlConfig
    Private ReadOnly _repo As clsJobRepository
    Private ReadOnly _console As clsAdminGateway

    Public Sub New(config As clsXmlConfig)
        _config = config
        _repo = New clsJobRepository(config.ConnectionString)
        _console = New clsAdminGateway(config.AdminBaseUrl, config.AdminApiKey)
    End Sub

#Region "Boucle de traitement"

    ''' <summary>
    ''' Un passage complet. Traite au plus BatchSize executions pour rendre la
    ''' main regulierement (arret du service, relecture de la configuration).
    ''' </summary>
    Public Function ProcessBatch() As ExecutionBatchResult
        Dim result As New ExecutionBatchResult()

        result.Marquees = _repo.MarquerAApprouver()
        result.Promues = _repo.PromouvoirPlanningEchu()
        result.Planifiees = RegarnirPlanning()

        Dim batchSize As Integer = clsXmlConfig.ToInt(_config.BatchSize, 5)
        Dim lockSeconds As Integer = clsXmlConfig.ToInt(_config.LockSeconds, 900)

        For i As Integer = 1 To batchSize
            Dim job As JobWorkItem = _repo.ClaimNextExecution(lockSeconds)
            If job Is Nothing Then Exit For

            result.DernierJob = job.JobCode

            If ExecuteJob(job) Then
                result.Succes += 1
            Else
                result.Echecs += 1
            End If
        Next

        Return result
    End Function

    ''' <summary>
    ''' Regarnit le planning, mais pas a chaque tour : sp_GenererPlanningJobs
    ''' parcourt tous les calendriers au curseur, la faire tourner toutes les
    ''' minutes serait du gaspillage. Sans elle, un calendrier « toutes les
    ''' 10 minutes » s'arrete au bout des 500 occurrences que la procedure
    ''' genere d'avance, soit trois jours et demi.
    '''
    ''' Un echec ici n'arrete pas le tour : les occurrences deja planifiees
    ''' continuent de s'executer.
    ''' </summary>
    Private Function RegarnirPlanning() As Integer
        Dim minutes As Integer = clsXmlConfig.ToInt(_config.PlanningRefreshMinutes, 15)
        If minutes <= 0 Then Return 0   ' 0 = jamais, le planning est gere ailleurs

        SyncLock thisLock
            If DernierPlanning <> Date.MinValue AndAlso Date.UtcNow < DernierPlanning.AddMinutes(minutes) Then
                Return 0
            End If
            DernierPlanning = Date.UtcNow
        End SyncLock

        Try
            Return _repo.GenererPlanning()
        Catch ex As Exception
            clsLog.ErrorWritelog("Génération du planning : " & ex.Message, clsLog.LogType.Erreur)
            Return 0
        End Try
    End Function

#End Region

#Region "Une exécution"

    ''' <summary>
    ''' Confie une tache reservee a la console et enregistre son issue. Ne leve
    ''' jamais : une tache qui echoue est une tache marquee ECHEC, pas un service
    ''' qui tombe.
    ''' </summary>
    Private Function ExecuteJob(job As JobWorkItem) As Boolean
        Dim chrono As Stopwatch = Stopwatch.StartNew()

        _repo.LogExecution(job.ExecutionId, "INFO",
                           "Prise en charge par " & Environment.MachineName &
                           " — confiée à " & _console.UrlRunner & ".")

        Try
            Dim issue As AdminJobResult = _console.ExecuterTache(job.ExecutionId, job.TimeoutSeconds)
            chrono.Stop()

            _repo.SaveExecutionResult(job.ExecutionId,
                                      If(issue.Succes, "SUCCES", "ECHEC"),
                                      issue.Message,
                                      issue.Detail,
                                      issue.LignesTraitees,
                                      CInt(chrono.ElapsedMilliseconds))

            _repo.LogExecution(job.ExecutionId, If(issue.Succes, "INFO", "ERROR"), issue.Message, issue.Detail)

            clsLog.EventWritelog(job.JobCode & " : " & issue.Message, clsLog.LogType.Traitement)
            Return issue.Succes

        Catch ex As Exception
            chrono.Stop()

            ' Console injoignable, delai depasse, reponse illisible : la tache
            ' n'a pas tourne. On l'enregistre en echec avec de quoi comprendre.
            Dim message As String = "Échec : " & ex.Message
            Try
                _repo.SaveExecutionResult(job.ExecutionId, "ECHEC", message, ex.ToString(), Nothing, CInt(chrono.ElapsedMilliseconds))
                _repo.LogExecution(job.ExecutionId, "ERROR", message, ex.ToString())
            Catch exSave As Exception
                clsLog.ErrorWritelog("Impossible d'enregistrer l'échec de l'exécution " & job.ExecutionId & " : " & exSave.Message, clsLog.LogType.Erreur)
            End Try

            clsLog.ErrorWritelog(job.JobCode & " : " & ex.Message, clsLog.LogType.Erreur)
            Return False
        End Try
    End Function

#End Region

End Class
