Imports System.Data
Imports System.Globalization
Imports System.Text
Imports Newtonsoft.Json.Linq

''' <summary>Issue d'une tâche, telle que le service l'enregistrera.</summary>
Public Class JobResult
    Public Property Succes As Boolean
    Public Property Message As String = ""
    Public Property Detail As String = Nothing
    Public Property LignesTraitees As Integer? = Nothing

    Public Shared Function Ok(message As String,
                              Optional lignes As Integer? = Nothing,
                              Optional detail As String = Nothing) As JobResult
        Return New JobResult With {.Succes = True, .Message = message, .LignesTraitees = lignes, .Detail = detail}
    End Function

    Public Shared Function Ko(message As String, Optional detail As String = Nothing) As JobResult
        Return New JobResult With {.Succes = False, .Message = message, .Detail = detail}
    End Function
End Class

''' <summary>
''' ══════════════════════════════════════════════════════════════════════════
'''  C'EST ICI QUE VIVENT LES TÂCHES PLANIFIÉES.
''' ══════════════════════════════════════════════════════════════════════════
'''
''' ServiceExecuteur ne sait rien d'aucune tâche : il se contente de repérer ce
''' qui est dû, de le réserver, puis d'appeler JobRunner.ashx. Tout ce qu'une
''' tâche fait vraiment est écrit ici. Modifier une tâche, ou en ajouter une, ne
''' demande donc que de redéployer la console d'administration — le service
''' Windows sur le serveur ne rebouge pas.
'''
''' Pour ajouter une tâche :
'''   1. la créer dans « Tâches planifiées » (code, type, calendrier) ;
'''   2. ajouter son cas dans Dispatch ci-dessous ;
'''   3. écrire sa méthode.
'''
''' Une tâche qu'on ne sait pas exécuter échoue explicitement. Jamais de succès
''' silencieux : une tâche en erreur se voit dans le suivi, un faux succès non.
''' </summary>
Public Class clsJobRunner

#Region "Point d'entrée"

    ''' <summary>
    ''' Exécute la tâche portée par une exécution. Le service ne transmet que
    ''' l'identifiant : tout le reste se relit en base, là où les écrans
    ''' d'administration l'écrivent.
    ''' </summary>
    Public Shared Function Run(executionId As Integer) As JobResult

        Dim p As New Collection
        p.Add(clsJobData.P("@ExecutionId", executionId))

        Dim ctx As DataRow = clsJobData.FirstRow(clsJobData.ExecuteSQLds("s0750GetJobExecutionContext", p))
        If ctx Is Nothing Then
            Return JobResult.Ko("Exécution " & executionId & " introuvable.")
        End If

        Return Dispatch(New JobContext(ctx))
    End Function

    ''' <summary>
    ''' Aiguillage. Le code de la tâche prime : c'est lui qu'on lit dans la
    ''' console, et c'est la clé la plus explicite. Le type de handler ne sert
    ''' que de filet pour les tâches génériques.
    ''' </summary>
    Private Shared Function Dispatch(job As JobContext) As JobResult

        Select Case job.JobCode.Trim().ToUpperInvariant()

            Case "TEST_COURRIEL"
                Return CourrielDeTest(job)

            Case "RAPPEL_FACTURES", "INVOICE_REMINDER"
                Return RappelsFactures(job)

        End Select

        ' Pas de cas nommé : une tâche qui désigne une procédure stockée peut
        ' quand même tourner, c'est le cas générique le plus courant.
        If job.HandlerType.ToUpperInvariant() = "SP" AndAlso job.HandlerName <> "" Then
            Return ProcedureStockee(job)
        End If

        Return JobResult.Ko("Aucun traitement défini pour la tâche « " & job.JobCode &
                            " » (" & job.HandlerType & " / " & job.HandlerName & "). " &
                            "Ajoutez son cas dans clsJobRunner.Dispatch.")
    End Function

#End Region

#Region "Les tâches"

    ''' <summary>
    ''' Courriel de vérification. Il ne répond qu'à une question — est-ce que
    ''' l'exécuteur tourne — et le nom de la compagnie prouve au passage que le
    ''' contexte a suivi jusqu'au bout de la chaîne.
    '''
    ''' Paramètres : « Destinataires » (tableau JSON) ou « To » (adresses
    ''' séparées par ; ou ,).
    ''' </summary>
    Private Shared Function CourrielDeTest(job As JobContext) As JobResult

        Dim destinataires As List(Of String) = job.Destinataires()
        If destinataires.Count = 0 Then
            Return JobResult.Ko("Aucun destinataire : renseignez « Destinataires » dans les paramètres de la tâche.")
        End If

        Dim nomCompagnie As String = job.NomCompagnieLisible()
        Dim sujet As String = "Test de l'exécuteur de tâches — " & nomCompagnie

        Dim corps As New StringBuilder()
        corps.Append("<div style=""font-family:Segoe UI,Arial,sans-serif;font-size:14px;color:#1f2937;"">")
        corps.Append("<p>Ceci est un courriel de test de l'exécuteur de tâches 60Sec-AI.</p>")
        corps.Append("<p>Compagnie : <strong>" & Encode(nomCompagnie) & "</strong></p>")
        corps.Append("<table style=""font-size:13px;color:#475569;border-collapse:collapse;"">")
        corps.Append(Ligne("Tâche", job.JobCode & " — " & job.JobNom))
        corps.Append(Ligne("Exécution", job.ExecutionId.ToString()))
        corps.Append(Ligne("Déclenchement", job.TriggerType))
        corps.Append(Ligne("Horodatage", Date.Now.ToString("yyyy-MM-dd HH:mm:ss")))
        corps.Append("</table>")
        corps.Append("<p style=""color:#94a3b8;font-size:12px;"">Pour arrêter ces envois, désactivez la tâche ou son calendrier dans la console d'administration.</p>")
        corps.Append("</div>")

        Return DeposerCourriels(job, destinataires, sujet, corps.ToString())
    End Function

    ''' <summary>
    ''' Relance des factures clients échues et non soldées de la compagnie.
    ''' Paramètres : « JoursAvant » (rappel préventif, 0 par défaut) et
    ''' « JoursRetard » ou « JoursApres » (fenêtre de relance, 30 par défaut).
    ''' </summary>
    Private Shared Function RappelsFactures(job As JobContext) As JobResult

        If job.CompanyGUID = Guid.Empty Then
            Return JobResult.Ko("Aucune compagnie sur l'exécution : impossible de savoir quelles factures relancer.")
        End If

        Dim joursAvant As Integer = job.ParamInt("JoursAvant", 0)
        Dim joursApres As Integer = job.ParamInt("JoursRetard", job.ParamInt("JoursApres", 30))

        Dim p As New Collection
        p.Add(clsJobData.P("@CompanyGUID", job.CompanyGUID))
        p.Add(clsJobData.P("@JoursAvant", joursAvant))
        p.Add(clsJobData.P("@JoursApres", joursApres))

        Dim ds As DataSet = clsJobData.ExecuteSQLds("s0746GetFacturesEnRetard", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Return JobResult.Ok("Aucune facture à relancer.", 0)
        End If

        Dim ci As CultureInfo = CultureInfo.GetCultureInfo("fr-CA")
        Dim nomCompagnie As String = job.NomCompagnieLisible()
        Dim envoyes As Integer = 0
        Dim detail As New StringBuilder()

        For Each r As DataRow In ds.Tables(0).Rows
            Dim destinataire As String = clsJobData.Str(r, "Email")
            Dim numero As String = clsJobData.Str(r, "DocumentNumber")

            If destinataire = "" Then
                detail.AppendLine(numero & " : ignorée, aucune adresse courriel.")
                Continue For
            End If

            Dim solde As Decimal = clsJobData.Dec(r, "Solde")
            Dim jours As Integer = clsJobData.Num(r, "JoursDeRetard")
            Dim echeance As String = ""
            If Not IsDBNull(r("DueDate")) Then echeance = Convert.ToDateTime(r("DueDate")).ToString("d MMMM yyyy", ci)

            Dim corps As New StringBuilder()
            corps.Append("<div style=""font-family:Segoe UI,Arial,sans-serif;font-size:14px;color:#1f2937;"">")
            corps.Append("<p>Bonjour " & Encode(clsJobData.Str(r, "Client")) & ",</p>")
            If jours > 0 Then
                corps.Append("<p>Notre facture <strong>" & Encode(numero) & "</strong>, échue le " & Encode(echeance) &
                             ", demeure impayée depuis " & jours & " jour(s).</p>")
            Else
                corps.Append("<p>Notre facture <strong>" & Encode(numero) & "</strong> vient à échéance le " & Encode(echeance) & ".</p>")
            End If
            corps.Append("<p>Solde dû : <strong>" & solde.ToString("C2", ci) & "</strong></p>")
            corps.Append("<p>Si le règlement est déjà parti, merci d'ignorer ce message.</p>")
            corps.Append("<p>" & Encode(nomCompagnie) & "</p>")
            corps.Append("</div>")

            Dim issue As JobResult = DeposerCourriels(job, New List(Of String) From {destinataire},
                                                      "Rappel : facture " & numero & " — " & nomCompagnie,
                                                      corps.ToString())
            If issue.Succes Then
                envoyes += 1
                detail.AppendLine(numero & " : rappel déposé pour " & destinataire & ".")
            Else
                detail.AppendLine(numero & " : " & issue.Message)
            End If
        Next

        Dim message As String = envoyes & " rappel(s) déposé(s) sur " & ds.Tables(0).Rows.Count & " facture(s) échue(s)."
        If envoyes = 0 Then Return JobResult.Ko(message, detail.ToString())
        Return JobResult.Ok(message, envoyes, detail.ToString())
    End Function

    ''' <summary>
    ''' Cas générique : lancer la procédure stockée nommée par la définition,
    ''' avec les paramètres du JSON.
    ''' </summary>
    Private Shared Function ProcedureStockee(job As JobContext) As JobResult
        Dim lignes As Integer = clsJobData.ExecuteProcedureLibre(job.HandlerName, job.CompanyGUID,
                                                                 job.Parametres, job.TimeoutSeconds)

        ' ExecuteNonQuery rend -1 quand SET NOCOUNT ON est actif : ce n'est pas
        ' un compte de lignes, on n'en publie pas un faux.
        Dim publiees As Integer? = If(lignes >= 0, CType(lignes, Integer?), Nothing)
        Return JobResult.Ok(job.HandlerName & " exécutée.", publiees)
    End Function

#End Region

#Region "Outils communs"

    ''' <summary>
    ''' Dépose un courriel dans la file de MailService, une ligne par
    ''' destinataire. SrvAI le prend au prochain cycle ; on ne parle jamais SMTP
    ''' d'ici. Un destinataire qui échoue n'empêche pas les suivants.
    '''
    ''' Le From reste celui du service : SrvAI envoie en direct-to-MX depuis
    ''' notre IP, un From au domaine du client échouerait son SPF. C'est le
    ''' Reply-To qui porte l'adresse de la compagnie, et seulement vérifiée.
    ''' </summary>
    Private Shared Function DeposerCourriels(job As JobContext,
                                             destinataires As List(Of String),
                                             sujet As String,
                                             corpsHtml As String) As JobResult

        Dim expediteur As String = job.Param("Expediteur", ExpediteurParDefaut())
        Dim replyTo As String = job.ReplyToVerifie()

        Dim envoyes As Integer = 0
        Dim detail As New StringBuilder()

        For Each adresse As String In destinataires
            Try
                Dim p As New Collection
                p.Add(clsJobData.P("@To", adresse))
                p.Add(clsJobData.P("@Subject", sujet))
                p.Add(clsJobData.P("@HTMLBody", corpsHtml))
                p.Add(clsJobData.P("@Sender", expediteur))
                p.Add(clsJobData.P("@From", expediteur))
                p.Add(clsJobData.P("@ReplyTo", If(replyTo = "", Nothing, replyTo)))

                clsJobData.ExecuteSQLdsMail("s0610InsertOutboundMail", p)
                envoyes += 1
                detail.AppendLine(adresse & " : déposé.")

            Catch ex As Exception
                detail.AppendLine(adresse & " : échec — " & ex.Message)
            End Try
        Next

        Dim message As String = envoyes & " courriel(s) déposé(s)."
        If envoyes = 0 Then Return JobResult.Ko("Aucun courriel déposé.", detail.ToString())
        Return JobResult.Ok(message, envoyes, detail.ToString())
    End Function

    Private Shared Function ExpediteurParDefaut() As String
        Dim v As String = System.Configuration.ConfigurationManager.AppSettings("JobMailSender")
        If String.IsNullOrWhiteSpace(v) Then Return "noreply@60sec.ca"
        Return v
    End Function

    Private Shared Function Ligne(libelle As String, valeur As String) As String
        Return "<tr><td style=""padding:2px 12px 2px 0;"">" & Encode(libelle) & "</td>" &
               "<td style=""padding:2px 0;""><strong>" & Encode(valeur) & "</strong></td></tr>"
    End Function

    Private Shared Function Encode(value As String) As String
        If value Is Nothing Then Return ""
        Return value.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")
    End Function

#End Region

End Class

''' <summary>
''' Le contexte d'une exécution : ce que la tâche est, pour qui, avec quels
''' paramètres. Construit à partir de s0750GetJobExecutionContext.
''' </summary>
Public Class JobContext

    Public ReadOnly ExecutionId As Integer
    Public ReadOnly JobCode As String
    Public ReadOnly JobNom As String
    Public ReadOnly HandlerType As String
    Public ReadOnly HandlerName As String
    Public ReadOnly TriggerType As String
    Public ReadOnly CompanyGUID As Guid
    Public ReadOnly CompanyName As String
    Public ReadOnly TimeoutSeconds As Integer
    Public ReadOnly Parametres As Dictionary(Of String, Object)

    Public Sub New(r As DataRow)
        ExecutionId = clsJobData.Num(r, "ExecutionId")
        JobCode = clsJobData.Str(r, "JobCode")
        JobNom = clsJobData.Str(r, "JobNom")
        HandlerType = clsJobData.Str(r, "HandlerType")
        HandlerName = clsJobData.Str(r, "HandlerName")
        TriggerType = clsJobData.Str(r, "TriggerType")
        CompanyName = clsJobData.Str(r, "CompanyName")
        TimeoutSeconds = clsJobData.Num(r, "TimeoutSeconds")

        Dim g As Guid = Guid.Empty
        Guid.TryParse(clsJobData.Str(r, "CompanyGUID"), g)
        CompanyGUID = g

        Parametres = ParseParams(clsJobData.Str(r, "HandlerParams"))
    End Sub

    ''' <summary>
    ''' Nom affichable de la compagnie. Sans compagnie, on le dit franchement
    ''' plutôt que d'envoyer un message qui annonce un nom vide.
    ''' </summary>
    Public Function NomCompagnieLisible() As String
        If CompanyName <> "" Then Return CompanyName
        If CompanyGUID = Guid.Empty Then Return "(aucune compagnie sur la tâche)"
        Return "(compagnie " & CompanyGUID.ToString() & " sans nom)"
    End Function

    ''' <summary>Adresse de réponse vérifiée de la compagnie, ou "" si aucune.</summary>
    Public Function ReplyToVerifie() As String
        If CompanyGUID = Guid.Empty Then Return ""
        Try
            Dim p As New Collection
            p.Add(clsJobData.P("@CompanyGUID", CompanyGUID))
            Return clsJobData.Str(clsJobData.FirstRow(clsJobData.ExecuteSQLds("s0694GetCompanyReplyTo", p)), "ReplyTo")
        Catch
            ' Un courriel doit partir même si l'en-tête Reply-To est indisponible.
            Return ""
        End Try
    End Function

#Region "Paramètres"

    Public Function Param(cle As String, defaut As String) As String
        Dim v As Object = Nothing
        If Parametres.TryGetValue(cle, v) AndAlso v IsNot Nothing Then
            Dim s As String = Convert.ToString(v).Trim()
            If s <> "" Then Return s
        End If
        Return defaut
    End Function

    Public Function ParamInt(cle As String, defaut As Integer) As Integer
        Dim n As Integer
        If Integer.TryParse(Param(cle, ""), n) Then Return n
        Return defaut
    End Function

    ''' <summary>
    ''' Destinataires du courriel : « Destinataires » (tableau JSON) ou « To »
    ''' (adresses séparées par ; ou ,). On accepte les deux formes plutôt que
    ''' d'en imposer une.
    ''' </summary>
    Public Function Destinataires() As List(Of String)
        Dim liste As New List(Of String)

        For Each cle As String In New String() {"Destinataires", "To", "Destinataire"}
            Dim brut As String = Param(cle, "")
            If brut = "" Then Continue For

            If brut.StartsWith("[") Then
                Try
                    For Each t As JToken In JArray.Parse(brut)
                        Dim a As String = Convert.ToString(CType(t, JValue).Value)
                        If Not String.IsNullOrWhiteSpace(a) Then liste.Add(a.Trim())
                    Next
                Catch
                End Try
            Else
                For Each a As String In brut.Split(";"c, ","c)
                    If Not String.IsNullOrWhiteSpace(a) Then liste.Add(a.Trim())
                Next
            End If

            If liste.Count > 0 Then Exit For
        Next

        Return liste
    End Function

    ''' <summary>
    ''' Les paramètres d'une tâche sont un objet JSON libre. On accepte aussi
    ''' bien « @DateReference » que « DateReference », et deux jetons pratiques :
    ''' @TODAY et @NOW. Un JSON illisible ne fait pas échouer la tâche : elle
    ''' part sans paramètres, avec ses valeurs par défaut.
    ''' </summary>
    Public Shared Function ParseParams(json As String) As Dictionary(Of String, Object)
        Dim resultat As New Dictionary(Of String, Object)(StringComparer.OrdinalIgnoreCase)
        If String.IsNullOrWhiteSpace(json) Then Return resultat

        Try
            For Each prop As JProperty In JObject.Parse(json).Properties()
                Dim cle As String = prop.Name.TrimStart("@"c)
                Dim valeur As Object

                Select Case prop.Value.Type
                    Case JTokenType.Null, JTokenType.Undefined
                        valeur = Nothing
                    Case JTokenType.Array, JTokenType.Object
                        ' Une liste reste du JSON : la tâche qui la comprend la relit.
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
        Catch
        End Try

        Return resultat
    End Function

#End Region

End Class
