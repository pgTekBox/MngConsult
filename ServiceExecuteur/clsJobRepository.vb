Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Une execution reservee par le service, telle que renvoyee par
''' s0739ClaimNextExecution.
''' </summary>
Public Class JobWorkItem
    Public Property ExecutionId As Integer
    Public Property JobDefinitionId As Integer
    Public Property JobScheduleId As Integer?
    Public Property TentativeNumero As Integer
    Public Property CompanyGUID As Guid
    Public Property TriggerType As String
    Public Property HandlerParams As String
    Public Property JobCode As String
    Public Property JobNom As String
    Public Property HandlerType As String
    Public Property HandlerName As String
    Public Property TimeoutSeconds As Integer
    Public Property MaxRetries As Integer
    Public Property RetryDelayMin As Integer
End Class

''' <summary>
''' Tout l'acces a la base passe par ici, et uniquement par des procedures
''' stockees (meme regle que l'application web : aucun SQL en dur).
'''
''' Une seule connexion : MngConsul, pour la file des taches. Les donnees
''' metier et l'envoi des courriels regardent la console d'administration, pas
''' ce service.
''' </summary>
Public Class clsJobRepository

    Private ReadOnly _connectionString As String

    Public Sub New(connectionString As String)
        _connectionString = connectionString
    End Sub

#Region "Helpers"

    Private Function Exec(procName As String, ParamArray parameters As SqlParameter()) As DataSet
        Return ExecOn(_connectionString, procName, 120, parameters)
    End Function

    ''' <summary>
    ''' Variante avec delai d'attente explicite : une procedure metier lancee
    ''' comme tache peut legitimement durer plus longtemps que nos requetes de
    ''' service, et c'est TimeoutSeconds de la definition qui fait foi.
    ''' </summary>
    Private Function ExecOn(connectionString As String, procName As String, timeoutSeconds As Integer, parameters As SqlParameter()) As DataSet
        Using cnn As New SqlConnection(connectionString)
            Using cmd As New SqlCommand(procName, cnn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.CommandTimeout = timeoutSeconds
                If parameters IsNot Nothing Then
                    For Each p As SqlParameter In parameters
                        If p IsNot Nothing Then cmd.Parameters.Add(p)
                    Next
                End If

                Dim ds As New DataSet()
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(ds)
                End Using
                Return ds
            End Using
        End Using
    End Function

    Private Sub ExecNonQuery(procName As String, ParamArray parameters As SqlParameter())
        Using cnn As New SqlConnection(_connectionString)
            Using cmd As New SqlCommand(procName, cnn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.CommandTimeout = 120
                If parameters IsNot Nothing Then
                    For Each p As SqlParameter In parameters
                        If p IsNot Nothing Then cmd.Parameters.Add(p)
                    Next
                End If
                cnn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Private Shared Function P(name As String, value As Object) As SqlParameter
        Return New SqlParameter(name, If(value, DBNull.Value))
    End Function

    Public Shared Function Str(row As DataRow, col As String) As String
        If row Is Nothing Then Return ""
        If Not row.Table.Columns.Contains(col) Then Return ""
        If IsDBNull(row(col)) Then Return ""
        Return Convert.ToString(row(col))
    End Function

    Public Shared Function Num(row As DataRow, col As String) As Integer
        If row Is Nothing Then Return 0
        If Not row.Table.Columns.Contains(col) Then Return 0
        If IsDBNull(row(col)) Then Return 0
        Return Convert.ToInt32(row(col))
    End Function

    Public Shared Function Dec(row As DataRow, col As String) As Decimal
        If row Is Nothing Then Return 0D
        If Not row.Table.Columns.Contains(col) Then Return 0D
        If IsDBNull(row(col)) Then Return 0D
        Return Convert.ToDecimal(row(col))
    End Function

    Private Shared Function HasRow(ds As DataSet) As Boolean
        Return ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0
    End Function

#End Region

#Region "File des taches"

    ''' <summary>
    ''' Transforme en executions les occurrences arrivees a echeance. Renvoie
    ''' combien ont ete promues.
    ''' </summary>
    Public Function PromouvoirPlanningEchu() As Integer
        Dim ds As DataSet = Exec("s0738PromouvoirPlanningEchu")
        If Not HasRow(ds) Then Return 0
        Return Num(ds.Tables(0).Rows(0), "Promues")
    End Function

    ''' <summary>
    ''' Met en attente d'approbation les occurrences dont la definition l'exige.
    ''' Appelee a chaque tour : une occurrence creee par le planificateur apres
    ''' coup est ainsi rattrapee.
    ''' </summary>
    Public Function MarquerAApprouver() As Integer
        Dim ds As DataSet = Exec("s0742MarquerAApprouver")
        If Not HasRow(ds) Then Return 0
        Return Num(ds.Tables(0).Rows(0), "Marquees")
    End Function

    ''' <summary>
    ''' Regarnit le planning a partir des calendriers (sp_GenererPlanningJobs).
    ''' Renvoie le nombre d'occurrences ajoutees.
    '''
    ''' A n'appeler qu'APRES la promotion : la procedure passe en EXPIRE toute
    ''' occurrence PLANIFIE dont l'heure est deja passee. Ce qui vient d'etre
    ''' promu n'est plus PLANIFIE et survit donc ; l'inverse effacerait le
    ''' travail du tour.
    ''' </summary>
    Public Function GenererPlanning() As Integer
        Dim ds As DataSet = ExecOn(_connectionString, "sp_GenererPlanningJobs", 300, Nothing)
        If ds Is Nothing Then Return 0

        For Each t As DataTable In ds.Tables
            If t.Columns.Contains("Delta") AndAlso t.Rows.Count > 0 Then
                Return Num(t.Rows(0), "Delta")
            End If
        Next
        Return 0
    End Function

    ''' <summary>
    ''' Reserve la prochaine execution a faire et pose un verrou dessus.
    ''' Renvoie Nothing quand il n'y a plus rien a faire.
    ''' </summary>
    Public Function ClaimNextExecution(lockSeconds As Integer) As JobWorkItem
        Dim ds As DataSet = Exec("s0739ClaimNextExecution",
                                 P("@LockSeconds", lockSeconds),
                                 P("@WorkerName", Environment.MachineName))

        If Not HasRow(ds) Then Return Nothing

        Dim r As DataRow = ds.Tables(0).Rows(0)

        Dim companyGuid As Guid = Guid.Empty
        If r.Table.Columns.Contains("CompanyGUID") AndAlso Not IsDBNull(r("CompanyGUID")) Then
            Guid.TryParse(Convert.ToString(r("CompanyGUID")), companyGuid)
        End If

        Dim scheduleId As Integer? = Nothing
        If r.Table.Columns.Contains("JobScheduleId") AndAlso Not IsDBNull(r("JobScheduleId")) Then
            scheduleId = Convert.ToInt32(r("JobScheduleId"))
        End If

        Return New JobWorkItem With {
            .ExecutionId = Num(r, "ExecutionId"),
            .JobDefinitionId = Num(r, "JobDefinitionId"),
            .JobScheduleId = scheduleId,
            .TentativeNumero = Num(r, "TentativeNumero"),
            .CompanyGUID = companyGuid,
            .TriggerType = Str(r, "TriggerType"),
            .HandlerParams = Str(r, "HandlerParams"),
            .JobCode = Str(r, "JobCode"),
            .JobNom = Str(r, "JobNom"),
            .HandlerType = Str(r, "HandlerType"),
            .HandlerName = Str(r, "HandlerName"),
            .TimeoutSeconds = Num(r, "TimeoutSeconds"),
            .MaxRetries = Num(r, "MaxRetries"),
            .RetryDelayMin = Num(r, "RetryDelayMin")
        }
    End Function

    ''' <summary>Issue d'une execution : SUCCES, ECHEC ou TIMEOUT.</summary>
    Public Sub SaveExecutionResult(executionId As Integer,
                                   statut As String,
                                   message As String,
                                   Optional detail As String = Nothing,
                                   Optional lignesTraitees As Integer? = Nothing,
                                   Optional dureeMs As Integer? = Nothing)

        ExecNonQuery("s0740SaveExecutionResult",
                     P("@ExecutionId", executionId),
                     P("@Statut", statut),
                     P("@ResultatMessage", If(message, "")),
                     P("@ResultatDetail", detail),
                     P("@LignesTraitees", If(lignesTraitees.HasValue, CObj(lignesTraitees.Value), Nothing)),
                     P("@DureeMs", If(dureeMs.HasValue, CObj(dureeMs.Value), Nothing)))
    End Sub

    ''' <summary>Ajoute une ligne au journal d'une execution (T203JobLog).</summary>
    Public Sub LogExecution(executionId As Integer, niveau As String, message As String, Optional detail As String = Nothing)
        Try
            ExecNonQuery("s0741LogExecution",
                         P("@JobExecutionId", executionId),
                         P("@Niveau", niveau),
                         P("@Message", If(message, "")),
                         P("@Detail", detail))
        Catch ex As Exception
            ' Le journal en base ne doit jamais faire echouer la tache elle-meme.
            clsLog.ErrorWritelog("LogExecution : " & ex.Message, clsLog.LogType.Erreur)
        End Try
    End Sub

    ''' <summary>Etat courant affiche par l'interface du service.</summary>
    Public Function GetExecutionsEnCours(top As Integer) As DataTable
        Dim ds As DataSet = Exec("s0747GetExecutionsEnCours", P("@Top", top))
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    ''' <summary>Nombre d'executions encore a prendre (aucune reservation en cours).</summary>
    Public Function CountAFaire() As Integer
        Dim t As DataTable = GetExecutionsEnCours(500)
        If t Is Nothing Then Return 0

        Dim n As Integer = 0
        For Each r As DataRow In t.Rows
            If Str(r, "Statut") = "EN_COURS" AndAlso Num(r, "Reservee") = 0 Then n += 1
        Next
        Return n
    End Function

    ''' <summary>Occurrences en attente d'une decision, toutes compagnies confondues.</summary>
    Public Function CountAApprouver() As Integer
        Dim ds As DataSet = Exec("s0749GetApprobationsCountGlobal")
        If Not HasRow(ds) Then Return 0
        Return Num(ds.Tables(0).Rows(0), "AApprouver")
    End Function

#End Region

End Class
