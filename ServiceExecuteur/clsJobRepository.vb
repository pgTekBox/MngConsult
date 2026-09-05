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

''' <summary>Identite d'une compagnie pour la mise en forme d'un courriel.</summary>
Public Class CompanyMailInfo
    Public Property CompanyName As String
    Public Property ReplyTo As String
End Class

''' <summary>
''' Tout l'acces aux bases passe par ici, et uniquement par des procedures
''' stockees (meme regle que l'application web : aucun SQL en dur).
'''
''' Deux connexions : MngConsul pour les taches et les donnees metier,
''' MailService pour deposer les courriels dans T400Mails.
''' </summary>
Public Class clsJobRepository

    Private ReadOnly _connectionString As String
    Private ReadOnly _connectionStringMail As String

    Public Sub New(connectionString As String, Optional connectionStringMail As String = "")
        _connectionString = connectionString
        _connectionStringMail = connectionStringMail
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

#Region "Handlers"

    ''' <summary>
    ''' Lance une procedure stockee metier. Les parametres reconnus par la
    ''' procedure sont decouverts par SqlCommandBuilder.DeriveParameters : on ne
    ''' passe @CompanyGUID et @UserId que si elle les attend, ce qui permet a
    ''' une definition de tache de pointer vers n'importe quelle procedure
    ''' existante sans l'adapter.
    ''' </summary>
    Public Function ExecuteStoredProcedure(procName As String,
                                           companyGuid As Guid,
                                           timeoutSeconds As Integer,
                                           parametres As Dictionary(Of String, Object)) As Integer

        Using cnn As New SqlConnection(_connectionString)
            Using cmd As New SqlCommand(procName, cnn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.CommandTimeout = If(timeoutSeconds > 0, timeoutSeconds, 300)

                cnn.Open()
                SqlCommandBuilder.DeriveParameters(cmd)

                For Each p As SqlParameter In cmd.Parameters
                    If p.Direction = ParameterDirection.ReturnValue Then Continue For

                    Dim nom As String = p.ParameterName.TrimStart("@"c)
                    Dim valeur As Object = Nothing

                    If parametres IsNot Nothing Then
                        For Each kv As KeyValuePair(Of String, Object) In parametres
                            If String.Equals(kv.Key.TrimStart("@"c), nom, StringComparison.OrdinalIgnoreCase) Then
                                valeur = kv.Value
                                Exit For
                            End If
                        Next
                    End If

                    ' La compagnie de l'execution comble le parametre attendu
                    ' quand les parametres JSON ne le fournissent pas.
                    If valeur Is Nothing AndAlso
                       String.Equals(nom, "CompanyGUID", StringComparison.OrdinalIgnoreCase) AndAlso
                       companyGuid <> Guid.Empty Then
                        valeur = companyGuid
                    End If

                    p.Value = If(valeur, DBNull.Value)
                Next

                Return cmd.ExecuteNonQuery()
            End Using
        End Using
    End Function

    ''' <summary>Factures clients impayees a relancer pour une compagnie.</summary>
    Public Function GetFacturesEnRetard(companyGuid As Guid, joursAvant As Integer, joursApres As Integer) As DataTable
        Dim ds As DataSet = Exec("s0746GetFacturesEnRetard",
                                 P("@CompanyGUID", companyGuid),
                                 P("@JoursAvant", joursAvant),
                                 P("@JoursApres", joursApres))
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    ''' <summary>
    ''' Nom de la compagnie et adresse de reponse verifiee. Le From reste
    ''' celui du service : SrvAI envoie en direct-to-MX depuis notre IP, un From
    ''' au domaine du client echouerait son SPF.
    ''' </summary>
    Public Function GetCompanyMailInfo(companyGuid As Guid) As CompanyMailInfo
        Dim info As New CompanyMailInfo With {.CompanyName = "", .ReplyTo = ""}
        If companyGuid = Guid.Empty Then Return info

        Try
            Dim ds As DataSet = Exec("s0748GetCompanyMailInfo", P("@CompanyGUID", companyGuid))
            If HasRow(ds) Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                info.CompanyName = Str(r, "CompanyName")
                info.ReplyTo = Str(r, "ReplyTo")
            End If
        Catch ex As Exception
            ' Un courriel doit partir meme si l'entete Reply-To est indisponible.
            clsLog.ErrorWritelog("GetCompanyMailInfo : " & ex.Message, clsLog.LogType.Erreur)
        End Try

        Return info
    End Function

    ''' <summary>
    ''' Depose un courriel dans la file de MailService. SrvAI le prend au
    ''' prochain cycle ; le service ne parle jamais SMTP lui-meme.
    ''' </summary>
    Public Function QueueMail(destinataire As String,
                              sujet As String,
                              htmlBody As String,
                              sender As String,
                              replyTo As String) As Integer

        If String.IsNullOrWhiteSpace(_connectionStringMail) Then
            Throw New InvalidOperationException("La connexion à la base MailService n'est pas configurée.")
        End If

        Dim parametres As SqlParameter() = {
            P("@To", destinataire),
            P("@Subject", sujet),
            P("@HTMLBody", htmlBody),
            P("@Sender", If(String.IsNullOrWhiteSpace(sender), "noreply@60sec.ca", sender)),
            P("@From", If(String.IsNullOrWhiteSpace(sender), "noreply@60sec.ca", sender)),
            P("@ReplyTo", If(String.IsNullOrWhiteSpace(replyTo), Nothing, replyTo))
        }

        Dim ds As DataSet = ExecOn(_connectionStringMail, "s0610InsertOutboundMail", 120, parametres)
        If Not HasRow(ds) Then Return 0
        Return Num(ds.Tables(0).Rows(0), "Id")
    End Function

#End Region

End Class
