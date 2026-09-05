Imports System.Data
Imports System.Globalization
Imports System.Text
Imports Newtonsoft.Json.Linq

''' <summary>
''' Ce que l'executeur a fait pendant un passage de la boucle.
''' </summary>
Public Class ExecutionBatchResult
    Public Property Promues As Integer
    Public Property Marquees As Integer
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
''' Le coeur du service : a chaque passage,
'''   1. les occurrences dont la definition exige une approbation passent en
'''      attente de decision (elles n'iront pas plus loin sans l'utilisateur) ;
'''   2. les occurrences echues et approuvees deviennent des executions ;
'''   3. les executions sont prises une a une, verrouillees, et confiees au
'''      handler correspondant a leur type.
'''
''' Quatre types de handlers existent dans T200JobDefinition. SP et EMAIL sont
''' implementes ; CONNECTOR et CUSTOM echouent explicitement plutot que de
''' marquer un succes qui n'a rien execute.
''' </summary>
Public Class clsTaskExecutor

    Private ReadOnly _config As clsXmlConfig
    Private ReadOnly _repo As clsJobRepository

    ''' <summary>Modeles de courriel que le service sait produire.</summary>
    Private Const MODELE_RAPPEL_FACTURE As String = "RAPPEL_FACTURE"

    Public Sub New(config As clsXmlConfig)
        _config = config
        _repo = New clsJobRepository(config.ConnectionString, config.ConnectionStringMail)
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
    ''' Execute une tache reservee et enregistre son issue. Ne leve jamais : une
    ''' tache qui echoue est une tache marquee ECHEC, pas un service qui tombe.
    ''' </summary>
    Private Function ExecuteJob(job As JobWorkItem) As Boolean
        Dim chrono As Stopwatch = Stopwatch.StartNew()

        _repo.LogExecution(job.ExecutionId, "INFO",
                           "Prise en charge par " & Environment.MachineName & " (" & job.HandlerType & " / " & job.HandlerName & ").")

        Try
            Dim issue As HandlerResult = Dispatch(job)
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

#Region "Aiguillage des handlers"

    ''' <summary>Issue d'un handler, telle qu'enregistree sur l'execution.</summary>
    Private Class HandlerResult
        Public Property Succes As Boolean
        Public Property Message As String = ""
        Public Property Detail As String = Nothing
        Public Property LignesTraitees As Integer? = Nothing

        Public Shared Function Ok(message As String, Optional lignes As Integer? = Nothing, Optional detail As String = Nothing) As HandlerResult
            Return New HandlerResult With {.Succes = True, .Message = message, .LignesTraitees = lignes, .Detail = detail}
        End Function

        Public Shared Function Ko(message As String, Optional detail As String = Nothing) As HandlerResult
            Return New HandlerResult With {.Succes = False, .Message = message, .Detail = detail}
        End Function
    End Class

    Private Function Dispatch(job As JobWorkItem) As HandlerResult
        Select Case UCase(If(job.HandlerType, "").Trim())

            Case "SP"
                Return HandlerStoredProcedure(job)

            Case "EMAIL"
                Return HandlerEmail(job)

            Case "CONNECTOR"
                ' Un connecteur parle a un système tiers (flux bancaire, export
                ' comptable) : ce sont des projets à part entière, pas un
                ' fourre-tout du service.
                Return HandlerResult.Ko("Type CONNECTOR non implémenté : « " & job.HandlerName & " » n'a pas de connecteur dans ce service.")

            Case "CUSTOM"
                Return HandlerResult.Ko("Type CUSTOM non implémenté : « " & job.HandlerName & " » désigne une classe .NET que ce service ne charge pas.")

            Case Else
                Return HandlerResult.Ko("Type de handler inconnu : « " & job.HandlerType & " ».")
        End Select
    End Function

#End Region

#Region "Handler SP"

    ''' <summary>
    ''' Lance la procedure stockee nommee par la definition, avec les
    ''' parametres du JSON. Les parametres que la procedure n'attend pas sont
    ''' ignores, et @CompanyGUID est comble par la compagnie de l'execution.
    ''' </summary>
    Private Function HandlerStoredProcedure(job As JobWorkItem) As HandlerResult
        If String.IsNullOrWhiteSpace(job.HandlerName) Then
            Return HandlerResult.Ko("Aucune procédure nommée dans la définition de la tâche.")
        End If

        Dim parametres As Dictionary(Of String, Object) = ParseParams(job.HandlerParams)
        Dim lignes As Integer = _repo.ExecuteStoredProcedure(job.HandlerName, job.CompanyGUID, job.TimeoutSeconds, parametres)

        ' ExecuteNonQuery rend -1 quand SET NOCOUNT ON est actif : ce n'est pas
        ' un compte de lignes, on n'en publie pas un faux.
        Dim lignesPubliees As Integer? = If(lignes >= 0, CType(lignes, Integer?), Nothing)

        Return HandlerResult.Ok(job.HandlerName & " exécutée.", lignesPubliees)
    End Function

#End Region

#Region "Handler EMAIL"

    ''' <summary>
    ''' Le modele de courriel se lit dans les parametres (« Template »), a
    ''' defaut dans le nom du handler ou le code de la tache. Un modele inconnu
    ''' est un echec explicite : mieux vaut une tache en erreur qu'un succes
    ''' sans courriel.
    ''' </summary>
    Private Function HandlerEmail(job As JobWorkItem) As HandlerResult
        Dim parametres As Dictionary(Of String, Object) = ParseParams(job.HandlerParams)

        Dim modele As String = ""
        For Each cle As String In New String() {"Template", "Modele", "Modèle"}
            Dim v As Object = Lookup(parametres, cle)
            If v IsNot Nothing Then
                modele = Convert.ToString(v)
                Exit For
            End If
        Next

        Dim candidats As New List(Of String) From {modele, job.HandlerName, job.JobCode}

        For Each c As String In candidats
            If EstRappelFacture(c) Then Return EnvoyerRappelsFactures(job, parametres)
        Next

        Return HandlerResult.Ko("Modèle de courriel inconnu : « " &
                                If(String.IsNullOrWhiteSpace(modele), job.HandlerName, modele) &
                                " ». Modèle supporté : " & MODELE_RAPPEL_FACTURE & ".")
    End Function

    ''' <summary>
    ''' Reconnait les designations du rappel de facture, quelle que soit la
    ''' facon dont la definition l'a nommee (modele, procedure, code de tache).
    ''' </summary>
    Private Shared Function EstRappelFacture(valeur As String) As Boolean
        If String.IsNullOrWhiteSpace(valeur) Then Return False

        Dim v As String = valeur.ToUpperInvariant()
        Return v.Contains("RAPPEL_FACTURE") OrElse
               v.Contains("RAPPELSFACTURES") OrElse
               v.Contains("RAPPEL_FACTURES") OrElse
               v.Contains("INVOICE_REMINDER")
    End Function

    ''' <summary>
    ''' Depose un rappel dans la file d'envoi pour chaque facture client echue
    ''' et non soldee de la compagnie. Un destinataire qui echoue n'empeche pas
    ''' les suivants : on compte, et on rend compte.
    ''' </summary>
    Private Function EnvoyerRappelsFactures(job As JobWorkItem, parametres As Dictionary(Of String, Object)) As HandlerResult
        If job.CompanyGUID = Guid.Empty Then
            Return HandlerResult.Ko("Aucune compagnie sur l'exécution : impossible de savoir quelles factures relancer.")
        End If

        Dim joursAvant As Integer = ToInt(Lookup(parametres, "JoursAvant"), clsXmlConfig.ToInt(_config.RelanceJoursAvant, 0))
        Dim joursApres As Integer = ToInt(Lookup(parametres, "JoursRetard"), -1)
        If joursApres < 0 Then joursApres = ToInt(Lookup(parametres, "JoursApres"), clsXmlConfig.ToInt(_config.RelanceJoursApres, 30))

        Dim factures As DataTable = _repo.GetFacturesEnRetard(job.CompanyGUID, joursAvant, joursApres)
        If factures Is Nothing OrElse factures.Rows.Count = 0 Then
            Return HandlerResult.Ok("Aucune facture à relancer.", 0)
        End If

        Dim info As CompanyMailInfo = _repo.GetCompanyMailInfo(job.CompanyGUID)
        Dim envoyes As Integer = 0
        Dim detail As New StringBuilder()

        For Each r As DataRow In factures.Rows
            Dim destinataire As String = clsJobRepository.Str(r, "Email")
            Dim numero As String = clsJobRepository.Str(r, "DocumentNumber")

            If String.IsNullOrWhiteSpace(destinataire) Then
                detail.AppendLine(numero & " : ignorée, aucune adresse courriel.")
                Continue For
            End If

            Try
                Dim sujet As String = "Rappel : facture " & numero &
                                      If(String.IsNullOrWhiteSpace(info.CompanyName), "", " — " & info.CompanyName)

                _repo.QueueMail(destinataire, sujet, CorpsRappel(r, info), _config.MailSender, info.ReplyTo)

                envoyes += 1
                detail.AppendLine(numero & " : rappel déposé pour " & destinataire & ".")

            Catch ex As Exception
                detail.AppendLine(numero & " : échec — " & ex.Message)
                clsLog.ErrorWritelog("Rappel de la facture " & numero & " : " & ex.Message, clsLog.LogType.Erreur)
            End Try
        Next

        Dim message As String = envoyes & " rappel(s) déposé(s) sur " & factures.Rows.Count & " facture(s) échue(s)."
        If envoyes = 0 Then Return HandlerResult.Ko(message, detail.ToString())
        Return HandlerResult.Ok(message, envoyes, detail.ToString())
    End Function

    ''' <summary>Corps HTML du rappel, volontairement sobre et sans image externe.</summary>
    Private Shared Function CorpsRappel(r As DataRow, info As CompanyMailInfo) As String
        Dim ci As CultureInfo = CultureInfo.GetCultureInfo("fr-CA")

        Dim client As String = clsJobRepository.Str(r, "Client")
        Dim numero As String = clsJobRepository.Str(r, "DocumentNumber")
        Dim solde As Decimal = clsJobRepository.Dec(r, "Solde")
        Dim jours As Integer = clsJobRepository.Num(r, "JoursDeRetard")

        Dim echeance As String = ""
        If Not IsDBNull(r("DueDate")) Then echeance = Convert.ToDateTime(r("DueDate")).ToString("d MMMM yyyy", ci)

        Dim sb As New StringBuilder()
        sb.Append("<div style=""font-family:Segoe UI,Arial,sans-serif;font-size:14px;color:#1f2937;"">")
        sb.Append("<p>Bonjour " & Encode(client) & ",</p>")

        If jours > 0 Then
            sb.Append("<p>Notre facture <strong>" & Encode(numero) & "</strong>, échue le " & Encode(echeance) &
                      ", demeure impayée depuis " & jours & " jour(s).</p>")
        Else
            sb.Append("<p>Notre facture <strong>" & Encode(numero) & "</strong> vient à échéance le " & Encode(echeance) & ".</p>")
        End If

        sb.Append("<p>Solde dû : <strong>" & solde.ToString("C2", ci) & "</strong></p>")
        sb.Append("<p>Si le règlement est déjà parti, merci d'ignorer ce message.</p>")

        If Not String.IsNullOrWhiteSpace(info.CompanyName) Then
            sb.Append("<p>" & Encode(info.CompanyName) & "</p>")
        End If

        sb.Append("</div>")
        Return sb.ToString()
    End Function

    Private Shared Function Encode(value As String) As String
        If value Is Nothing Then Return ""
        Return value.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")
    End Function

#End Region

#Region "Paramètres JSON"

    ''' <summary>
    ''' Les parametres d'une tache sont un objet JSON libre. On accepte aussi
    ''' bien « @DateReference » que « DateReference », et deux jetons pratiques :
    ''' @TODAY (la date du jour) et @NOW (l'instant present).
    ''' Un JSON illisible ne fait pas echouer la tache : elle part sans
    ''' parametres, avec ses valeurs par defaut.
    ''' </summary>
    Public Shared Function ParseParams(json As String) As Dictionary(Of String, Object)
        Dim resultat As New Dictionary(Of String, Object)(StringComparer.OrdinalIgnoreCase)
        If String.IsNullOrWhiteSpace(json) Then Return resultat

        Try
            Dim o As JObject = JObject.Parse(json)

            For Each prop As JProperty In o.Properties()
                Dim cle As String = prop.Name.TrimStart("@"c)
                Dim valeur As Object = Nothing

                Select Case prop.Value.Type
                    Case JTokenType.Null, JTokenType.Undefined
                        valeur = Nothing
                    Case JTokenType.Array, JTokenType.Object
                        ' Une liste (destinataires, options) reste du JSON : le
                        ' handler qui la comprend la relira lui-meme.
                        valeur = prop.Value.ToString(Newtonsoft.Json.Formatting.None)
                    Case Else
                        valeur = CType(prop.Value, JValue).Value
                End Select

                Dim texte As String = TryCast(valeur, String)
                If texte IsNot Nothing Then
                    Select Case texte.Trim().ToUpperInvariant()
                        Case "@TODAY" : valeur = Date.Today
                        Case "@NOW" : valeur = Date.Now
                    End Select
                End If

                resultat(cle) = valeur
            Next

        Catch ex As Exception
            clsLog.ErrorWritelog("Paramètres JSON illisibles, ignorés : " & ex.Message, clsLog.LogType.Erreur)
        End Try

        Return resultat
    End Function

    Private Shared Function Lookup(parametres As Dictionary(Of String, Object), cle As String) As Object
        If parametres Is Nothing Then Return Nothing
        Dim v As Object = Nothing
        If parametres.TryGetValue(cle, v) Then Return v
        Return Nothing
    End Function

    Private Shared Function ToInt(valeur As Object, fallback As Integer) As Integer
        If valeur Is Nothing Then Return fallback
        Dim n As Integer
        If Integer.TryParse(Convert.ToString(valeur), n) Then Return n
        Return fallback
    End Function

#End Region

End Class
