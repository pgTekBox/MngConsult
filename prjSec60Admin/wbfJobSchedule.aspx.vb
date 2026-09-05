Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Partial Public Class wbfJobSchedule
    Inherits clsData

    ' =========================================================
    '  PROPRIÉTÉS
    ' =========================================================

    Public Property ScheduleId As Integer
        Get
            Return If(ViewState("SchedId"), 0)
        End Get
        Set(value As Integer)
            ViewState("SchedId") = value
        End Set
    End Property

    Public Property JobDefinitionId As Integer
        Get
            Return If(ViewState("JobId"), 0)
        End Get
        Set(value As Integer)
            ViewState("JobId") = value
            ' Synchroniser le HiddenField pour le JavaScript
            If hfJobId IsNot Nothing Then
                hfJobId.Value = value.ToString()
            End If
        End Set
    End Property

    Private Property JobNom As String
        Get
            Return If(ViewState("JobNom"), "").ToString()
        End Get
        Set(value As String)
            ViewState("JobNom") = value
        End Set
    End Property

    ' =========================================================
    '  PAGE LIFECYCLE
    ' =========================================================

    ' =========================================================
    '  LOCALISATION
    ' =========================================================

    Protected Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Sub ApplyLocalization()
        Page.Title = T("Édition d'un schedule", "Edit schedule", "Editar programación")

        ' Libellés HTML (anciens blocs <%= T(...) %> convertis en Literals)
        litLoc01.Text = T("Prochaine exécution prévue", "Next scheduled run", "Próxima ejecución prevista")
        litLoc02.Text = T("Informations de base", "Basic information", "Información básica")
        litLoc03.Text = T("Nom du schedule", "Schedule name", "Nombre de la programación")
        litLoc04.Text = T("Type de planification", "Schedule type", "Tipo de programación")
        litLoc05.Text = T("Toutes les ... minutes", "Every ... minutes", "Cada ... minutos")
        litLoc06.Text = T("Ex: 30 = toutes les 30 min, 1440 = 1 fois par jour.", "Ex: 30 = every 30 min, 1440 = once a day.", "Ej: 30 = cada 30 min, 1440 = una vez al día.")
        litLoc07.Text = T("Heure d'exécution", "Run time", "Hora de ejecución")
        litLoc08.Text = T("Heure d'exécution", "Run time", "Hora de ejecución")
        litLoc09.Text = T("Jours de la semaine", "Days of the week", "Días de la semana")
        litLoc10.Text = T("Lun", "Mon", "Lun")
        litLoc11.Text = T("Mar", "Tue", "Mar")
        litLoc12.Text = T("Mer", "Wed", "Mié")
        litLoc13.Text = T("Jeu", "Thu", "Jue")
        litLoc14.Text = T("Ven", "Fri", "Vie")
        litLoc15.Text = T("Sam", "Sat", "Sáb")
        litLoc16.Text = T("Dim", "Sun", "Dom")
        litLoc17.Text = T("Cliquez sur les pilules pour sélectionner les jours actifs.", "Click the pills to select the active days.", "Haga clic en las píldoras para seleccionar los días activos.")
        litLoc18.Text = T("Périodicité", "Periodicity", "Periodicidad")
        litLoc19.Text = T("Ex : trimestriel = remise des taxes ; annuel = T4 ou rapport fin d'exercice.", "Ex: quarterly = tax remittance; yearly = T4 or year-end report.", "Ej: trimestral = remesa de impuestos; anual = T4 o informe de fin de ejercicio.")
        litLoc20.Text = T("Heure d'exécution", "Run time", "Hora de ejecución")
        litLoc21.Text = T("Jour du mois", "Day of the month", "Día del mes")
        litLoc22.Text = T("Ex: 15 = le 15 de chaque mois, -1 = dernier jour (28/30/31 selon le mois).", "Ex: 15 = the 15th of each month, -1 = last day (28/30/31 depending on the month).", "Ej: 15 = el 15 de cada mes, -1 = último día (28/30/31 según el mes).")
        litLoc23.Text = T("Expression CRON", "CRON expression", "Expresión CRON")
        litLoc24.Text = T("Format :", "Format:", "Formato:")
        litLoc25.Text = T("Tous les jours à 8h00", "Every day at 8:00", "Todos los días a las 8:00")
        litLoc26.Text = T("Toutes les 30 min, 8h-18h, Lun-Ven", "Every 30 min, 8am-6pm, Mon-Fri", "Cada 30 min, 8h-18h, Lun-Vie")
        litLoc27.Text = T("Le 1er du mois à minuit", "The 1st of the month at midnight", "El 1.º del mes a medianoche")
        litLoc28.Text = T("Tous les dimanches midi", "Every Sunday at noon", "Todos los domingos al mediodía")
        litLoc29.Text = T("Lun-Ven 22h00", "Mon-Fri 10pm", "Lun-Vie 22:00")
        litLoc30.Text = T("La prochaine exécution sera calculée par le service .NET au prochain cycle.", "The next run will be calculated by the .NET service on the next cycle.", "La próxima ejecución será calculada por el servicio .NET en el próximo ciclo.")
        litLoc31.Text = T("Date et heure d'exécution", "Run date and time", "Fecha y hora de ejecución")
        litLoc32.Text = T("Le schedule sera désactivé après cette unique exécution.", "The schedule will be disabled after this single run.", "La programación se desactivará después de esta única ejecución.")
        litLoc33.Text = T("Période de validité et état", "Validity period and status", "Período de validez y estado")
        litLoc34.Text = T("Date de début", "Start date", "Fecha de inicio")
        litLoc35.Text = T("Avant cette date, le schedule ne s'exécute pas. (Défaut : aujourd'hui)", "Before this date, the schedule does not run. (Default: today)", "Antes de esta fecha, la programación no se ejecuta. (Predeterminado: hoy)")
        litLoc36.Text = T("Date de fin", "End date", "Fecha de fin")
        litLoc37.Text = T("Optionnel. Vide = pas de fin.", "Optional. Empty = no end.", "Opcional. Vacío = sin fin.")
        litLoc38.Text = T("État", "Status", "Estado")
        litLoc39.Text = T("Pause = arrêt temporaire (réactivable rapidement). Inactif = désactivation longue durée.", "Pause = temporary stop (quickly re-enabled). Inactive = long-term deactivation.", "Pausa = detención temporal (reactivable rápidamente). Inactivo = desactivación de larga duración.")
        litLoc40.Text = T("Paramètres spécifiques (override)", "Specific parameters (override)", "Parámetros específicos (override)")
        litLoc41.Text = T("Optionnel. Si renseigné, ces paramètres remplacent ceux par défaut du job pour ce schedule.", "Optional. If provided, these parameters override the job's defaults for this schedule.", "Opcional. Si se completa, estos parámetros reemplazan los predeterminados del job para esta programación.")

        txtNom.EmptyMessage = T("Ex: Quotidien 7h, Fin de mois, ...", "Ex: Daily 7am, End of month, ...", "Ej: Diario 7h, Fin de mes, ...")

        ' Type de planification
        SetComboItemText(ddlScheduleType, "INTERVAL", T("Toutes les N minutes (INTERVAL)", "Every N minutes (INTERVAL)", "Cada N minutos (INTERVAL)"))
        SetComboItemText(ddlScheduleType, "DAILY", T("Quotidien (DAILY)", "Daily (DAILY)", "Diario (DAILY)"))
        SetComboItemText(ddlScheduleType, "WEEKLY", T("Hebdomadaire (WEEKLY)", "Weekly (WEEKLY)", "Semanal (WEEKLY)"))
        SetComboItemText(ddlScheduleType, "MONTHLY", T("Mensuel / Trimestriel / Semestriel / Annuel (MONTHLY)", "Monthly / Quarterly / Half-yearly / Yearly (MONTHLY)", "Mensual / Trimestral / Semestral / Anual (MONTHLY)"))
        SetComboItemText(ddlScheduleType, "CRON", T("Expression CRON (avancé)", "CRON expression (advanced)", "Expresión CRON (avanzado)"))
        SetComboItemText(ddlScheduleType, "ONCE", T("Une seule fois (ONCE)", "Once (ONCE)", "Una sola vez (ONCE)"))

        ' Périodicité (mensuel)
        SetComboItemText(ddlIntervalleMois, "1", T("Tous les mois", "Every month", "Todos los meses"))
        SetComboItemText(ddlIntervalleMois, "3", T("Tous les 3 mois (trimestriel)", "Every 3 months (quarterly)", "Cada 3 meses (trimestral)"))
        SetComboItemText(ddlIntervalleMois, "6", T("Tous les 6 mois (semestriel)", "Every 6 months (half-yearly)", "Cada 6 meses (semestral)"))
        SetComboItemText(ddlIntervalleMois, "12", T("Tous les 12 mois (annuel)", "Every 12 months (yearly)", "Cada 12 meses (anual)"))

        ' Jour du mois : premier item (dernier jour)
        SetComboItemText(ddlJourMois, "-1", T("-1 — Dernier jour du mois", "-1 — Last day of the month", "-1 — Último día del mes"))

        ' État
        SetComboItemText(ddlEtat, "ACTIF", T("Actif", "Active", "Activo"))
        SetComboItemText(ddlEtat, "PAUSE", T("En pause (temporaire)", "Paused (temporary)", "En pausa (temporal)"))
        SetComboItemText(ddlEtat, "INACTIF", T("Inactif", "Inactive", "Inactivo"))

        ' Boutons
        btnApercu.Text = T("Calculer aperçu", "Calculate preview", "Calcular vista previa")
        btnSupprimer.Text = T("Supprimer ce schedule", "Delete this schedule", "Eliminar esta programación")
        btnAnnuler.Text = T("Annuler", "Cancel", "Cancelar")
        btnEnregistrer.Text = T("Enregistrer", "Save", "Guardar")
    End Sub

    Private Sub SetComboItemText(combo As RadComboBox, value As String, text As String)
        Dim it = combo.FindItemByValue(value)
        If it IsNot Nothing Then it.Text = text
    End Sub

    Private Function CultureLang() As System.Globalization.CultureInfo
        Select Case CurrentLang
            Case "en" : Return System.Globalization.CultureInfo.GetCultureInfo("en-CA")
            Case "es" : Return System.Globalization.CultureInfo.GetCultureInfo("es-ES")
            Case Else : Return System.Globalization.CultureInfo.GetCultureInfo("fr-CA")
        End Select
    End Function

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ApplyLocalization()

        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If

            ' Lire les paramètres de QueryString
            Dim id As Integer = 0, jobId As Integer = 0
            Integer.TryParse(Request.QueryString("Id"), id)
            Integer.TryParse(Request.QueryString("JobId"), jobId)
            ScheduleId = id
            JobDefinitionId = jobId

            If id > 0 Then
                ChargerSchedule(id)
            ElseIf jobId > 0 Then
                ' Mode création : on a besoin du nom du job pour l'afficher
                ChargerJobInfo(jobId)
                ' Valeurs par défaut sensibles
                ddlScheduleType.SelectedValue = "DAILY"
                dpDateDebut.SelectedDate = Date.Today
                dpHeureDaily.SelectedTime = New TimeSpan(8, 0, 0)
                AfficherChampsSelonType("DAILY")
                CalculerEtAfficherApercu()
            Else
                ShowStatus("danger", T("Paramètre JobId manquant en URL.", "Missing JobId parameter in URL.", "Falta el parámetro JobId en la URL."))
                btnEnregistrer.Enabled = False
                Return
            End If

            RemplirComboJourMois()
        End If
    End Sub

    Private Sub RemplirComboJourMois()
        ' Le combo pré-rempli a juste -1, on ajoute les jours 1-31
        If ddlJourMois.Items.Count <= 1 Then
            For i As Integer = 1 To 31
                ddlJourMois.Items.Add(New RadComboBoxItem(i.ToString(), i.ToString()))
            Next
        End If
    End Sub

    ' =========================================================
    '  ÉVÉNEMENTS
    ' =========================================================

    Protected Sub ddlScheduleType_Changed(sender As Object, e As EventArgs)
        AfficherChampsSelonType(ddlScheduleType.SelectedValue)
        CalculerEtAfficherApercu()
    End Sub

    Protected Sub btnApercu_Click(sender As Object, e As EventArgs)
        CalculerEtAfficherApercu()
    End Sub

    Protected Sub btnEnregistrer_Click(sender As Object, e As EventArgs)
        Try
            Dim newId = SauvegarderSchedule()

            If newId > 0 Then
                ShowStatus("success", T("Schedule enregistré.", "Schedule saved.", "Programación guardada."))
                ScheduleId = newId
                ' Recharger pour afficher la ProchaineExec recalculée
                ChargerSchedule(newId)
            End If

        Catch sqlex As SqlException
            ShowStatus("danger", T("Erreur SQL : ", "SQL error: ", "Error SQL: ") & sqlex.Message)
        Catch ex As Exception
            ShowStatus("danger", T("Erreur : ", "Error: ", "Error: ") & ex.Message)
        End Try
    End Sub

    Protected Sub btnSupprimer_Click(sender As Object, e As EventArgs)
        If ScheduleId = 0 Then Return

        Try
            Using cn As New SqlConnection(ConnectionString)
                cn.Open()
                Using cmd As New SqlCommand("dbo.sp_SupprimerSchedule", cn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@ScheduleId", ScheduleId)
                    cmd.Parameters.AddWithValue("@UserId", UserId)
                    cmd.ExecuteNonQuery()
                End Using
            End Using

            ' Retour à l'écran d'édition du job
            Response.Redirect("wbfJobEdit.aspx?Id=" & JobDefinitionId & "&schedDeleted=1")

        Catch sqlex As SqlException
            ShowStatus("danger", T("Erreur SQL : ", "SQL error: ", "Error SQL: ") & sqlex.Message)
        Catch ex As Exception
            ShowStatus("danger", T("Erreur : ", "Error: ", "Error: ") & ex.Message)
        End Try
    End Sub

    ' =========================================================
    '  CHARGEMENT
    ' =========================================================

    Private Sub ChargerJobInfo(jobId As Integer)
        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0210GetJobDefinition", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@JobDefinitionId", jobId)

                Using rdr = cmd.ExecuteReader()
                    If rdr.Read() Then
                        JobNom = rdr("Nom").ToString()
                        litTitre.Text = T("Nouveau schedule", "New schedule", "Nueva programación")
                        litBadgeJob.Text = "<span class='badge-job'>" & T("Pour le job : ", "For job: ", "Para el job: ") & Server.HtmlEncode(JobNom) & "</span>"
                    End If
                End Using
            End Using
        End Using
    End Sub

    Private Sub ChargerSchedule(id As Integer)
        Dim dt As New DataTable()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0220GetSchedule", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@ScheduleId", id)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        If dt.Rows.Count = 0 Then
            ShowStatus("danger", T("Schedule introuvable (Id=", "Schedule not found (Id=", "Programación no encontrada (Id=") & id & ").")
            btnEnregistrer.Enabled = False
            Return
        End If

        Dim r = dt.Rows(0)

        JobDefinitionId = Convert.ToInt32(r("JobDefinitionId"))
        JobNom = r("JobNom").ToString()

        litTitre.Text = T("Édition : ", "Edit: ", "Edición: ") & Server.HtmlEncode(r("Nom").ToString())
        litBadgeJob.Text = "<span class='badge-job'>" & T("Pour le job : ", "For job: ", "Para el job: ") & Server.HtmlEncode(JobNom) & "</span>"

        btnSupprimer.Visible = True

        ' Champs communs
        txtNom.Text = r("Nom").ToString()
        Dim scheduleType = r("ScheduleType").ToString()
        ddlScheduleType.SelectedValue = scheduleType

        ' Dates de validité
        If Not Convert.IsDBNull(r("DateDebut")) Then
            dpDateDebut.SelectedDate = Convert.ToDateTime(r("DateDebut"))
        End If
        If Not Convert.IsDBNull(r("DateFin")) Then
            dpDateFin.SelectedDate = Convert.ToDateTime(r("DateFin"))
        End If

        ' État
        If Convert.ToBoolean(r("Pause")) Then
            ddlEtat.SelectedValue = "PAUSE"
        ElseIf Not Convert.ToBoolean(r("Actif")) Then
            ddlEtat.SelectedValue = "INACTIF"
        Else
            ddlEtat.SelectedValue = "ACTIF"
        End If

        ' Champs spécifiques au type
        Select Case scheduleType
            Case "INTERVAL"
                If Not Convert.IsDBNull(r("IntervalMinutes")) Then
                    txtIntervalMinutes.Value = Convert.ToInt32(r("IntervalMinutes"))
                End If
            Case "DAILY"
                If Not Convert.IsDBNull(r("HeureExecution")) Then
                    dpHeureDaily.SelectedTime = TimeSpan.Parse(r("HeureExecution").ToString())
                End If
            Case "WEEKLY"
                If Not Convert.IsDBNull(r("HeureExecution")) Then
                    dpHeureWeekly.SelectedTime = TimeSpan.Parse(r("HeureExecution").ToString())
                End If
                ' Cocher les jours
                If Not Convert.IsDBNull(r("JoursSemaine")) Then
                    Dim jours = r("JoursSemaine").ToString().Split(","c)
                    cbLun.Checked = jours.Contains("1")
                    cbMar.Checked = jours.Contains("2")
                    cbMer.Checked = jours.Contains("3")
                    cbJeu.Checked = jours.Contains("4")
                    cbVen.Checked = jours.Contains("5")
                    cbSam.Checked = jours.Contains("6")
                    cbDim.Checked = jours.Contains("7")
                End If
            Case "MONTHLY"
                If Not Convert.IsDBNull(r("HeureExecution")) Then
                    dpHeureMonthly.SelectedTime = TimeSpan.Parse(r("HeureExecution").ToString())
                End If
                If Not Convert.IsDBNull(r("JourMois")) Then
                    ddlJourMois.SelectedValue = r("JourMois").ToString()
                End If
                ' Lire IntervalleMois (défaut = 1 si NULL ou colonne absente)
                Dim intervMois = 1
                If r.Table.Columns.Contains("IntervalleMois") AndAlso Not Convert.IsDBNull(r("IntervalleMois")) Then
                    intervMois = Convert.ToInt32(r("IntervalleMois"))
                End If
                Dim itIntervMois = ddlIntervalleMois.FindItemByValue(intervMois.ToString())
                If itIntervMois IsNot Nothing Then itIntervMois.Selected = True
            Case "CRON"
                If Not Convert.IsDBNull(r("CronExpression")) Then
                    txtCronExpression.Text = r("CronExpression").ToString()
                End If
            Case "ONCE"
                If Not Convert.IsDBNull(r("DateOnce")) Then
                    dpDateOnce.SelectedDate = Convert.ToDateTime(r("DateOnce"))
                End If
        End Select

        ' Handler params override
        txtHandlerParams.Text = If(Convert.IsDBNull(r("HandlerParams")), "", r("HandlerParams").ToString())

        ' Affichage des panels
        AfficherChampsSelonType(scheduleType)

        ' Aperçu de la prochaine exécution (depuis la BD)
        If Not Convert.IsDBNull(r("ProchaineExec")) Then
            AfficherApercu(Convert.ToDateTime(r("ProchaineExec")), Nothing)
        Else
            AfficherApercu(Nothing, T("Pas encore calculée — sera mise à jour au prochain démarrage du worker.", "Not yet calculated — will be updated at the next worker startup.", "Aún no calculada — se actualizará en el próximo inicio del worker."))
        End If
    End Sub

    Private Sub AfficherChampsSelonType(scheduleType As String)
        pnlInterval.Visible = (scheduleType = "INTERVAL")
        pnlDaily.Visible = (scheduleType = "DAILY")
        pnlWeekly.Visible = (scheduleType = "WEEKLY")
        pnlMonthly.Visible = (scheduleType = "MONTHLY")
        pnlCron.Visible = (scheduleType = "CRON")
        pnlOnce.Visible = (scheduleType = "ONCE")
    End Sub

    ' =========================================================
    '  APERÇU DE LA PROCHAINE EXÉCUTION
    ' =========================================================

    Private Sub CalculerEtAfficherApercu()
        Dim scheduleType = ddlScheduleType.SelectedValue

        If scheduleType = "CRON" Then
            AfficherApercu(Nothing, T("Le calcul d'une expression CRON est effectué par le service .NET (NCrontab/Cronos).", "CRON expression calculation is performed by the .NET service (NCrontab/Cronos).", "El cálculo de una expresión CRON lo realiza el servicio .NET (NCrontab/Cronos)."))
            Return
        End If

        ' Récupérer les paramètres saisis selon le type
        Dim intervalMin As Object = DBNull.Value
        Dim heureExec As Object = DBNull.Value
        Dim joursSem As Object = DBNull.Value
        Dim jourMois As Object = DBNull.Value
        Dim intervalleMois As Integer = 1                      ' ← NOUVEAU
        Dim dateOnce As Object = DBNull.Value
        Dim dateDebut As Object = DBNull.Value
        Dim dateFin As Object = DBNull.Value

        Select Case scheduleType
            Case "INTERVAL"
                intervalMin = Convert.ToInt32(txtIntervalMinutes.Value)
            Case "DAILY"
                If dpHeureDaily.SelectedTime.HasValue Then heureExec = dpHeureDaily.SelectedTime.Value
            Case "WEEKLY"
                If dpHeureWeekly.SelectedTime.HasValue Then heureExec = dpHeureWeekly.SelectedTime.Value
                Dim jours = New List(Of String)()
                If cbLun.Checked Then jours.Add("1")
                If cbMar.Checked Then jours.Add("2")
                If cbMer.Checked Then jours.Add("3")
                If cbJeu.Checked Then jours.Add("4")
                If cbVen.Checked Then jours.Add("5")
                If cbSam.Checked Then jours.Add("6")
                If cbDim.Checked Then jours.Add("7")
                If jours.Count > 0 Then joursSem = String.Join(",", jours)
            Case "MONTHLY"
                If dpHeureMonthly.SelectedTime.HasValue Then heureExec = dpHeureMonthly.SelectedTime.Value
                If Not String.IsNullOrEmpty(ddlJourMois.SelectedValue) Then
                    jourMois = Convert.ToInt32(ddlJourMois.SelectedValue)
                End If
                ' ← NOUVEAU : récupérer la périodicité
                If Not String.IsNullOrEmpty(ddlIntervalleMois.SelectedValue) Then
                    intervalleMois = Convert.ToInt32(ddlIntervalleMois.SelectedValue)
                End If
            Case "ONCE"
                If dpDateOnce.SelectedDate.HasValue Then dateOnce = dpDateOnce.SelectedDate.Value
        End Select

        If dpDateDebut.SelectedDate.HasValue Then dateDebut = dpDateDebut.SelectedDate.Value
        If dpDateFin.SelectedDate.HasValue Then dateFin = dpDateFin.SelectedDate.Value

        ' Appel à s0221ApercuProchaineExec
        Try
            Using cn As New SqlConnection(ConnectionString)
                cn.Open()
                Using cmd As New SqlCommand("dbo.s0221ApercuProchaineExec", cn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@ScheduleType", scheduleType)
                    cmd.Parameters.AddWithValue("@IntervalMinutes", intervalMin)
                    cmd.Parameters.AddWithValue("@HeureExecution", heureExec)
                    cmd.Parameters.AddWithValue("@JoursSemaine", joursSem)
                    cmd.Parameters.AddWithValue("@JourMois", jourMois)
                    cmd.Parameters.AddWithValue("@IntervalleMois", intervalleMois)
                    cmd.Parameters.AddWithValue("@DateOnce", dateOnce)
                    cmd.Parameters.AddWithValue("@DateDebut", dateDebut)
                    cmd.Parameters.AddWithValue("@DateFin", dateFin)
                    cmd.Parameters.AddWithValue("@ApresDate", DBNull.Value)

                    Using rdr = cmd.ExecuteReader()
                        If rdr.Read() Then
                            Dim prochaine As DateTime? = Nothing
                            If Not Convert.IsDBNull(rdr("ProchaineExec")) Then
                                prochaine = Convert.ToDateTime(rdr("ProchaineExec"))
                            End If
                            Dim msg As String = Nothing
                            If Not Convert.IsDBNull(rdr("MessageErreur")) Then
                                msg = rdr("MessageErreur").ToString()
                            End If
                            AfficherApercu(prochaine, msg)
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            AfficherApercu(Nothing, T("Erreur de calcul : ", "Calculation error: ", "Error de cálculo: ") & ex.Message)
        End Try
    End Sub

    Private Sub AfficherApercu(prochaine As DateTime?, messageErreur As String)
        If prochaine.HasValue Then
            litProchaineExec.Text = prochaine.Value.ToString("yyyy-MM-dd HH:mm:ss")
            litProchaineExecMeta.Text = FormatDateRelative(prochaine.Value)
            divPreview.Attributes("class") = "preview-box"
        Else
            litProchaineExec.Text = "—"
            litProchaineExecMeta.Text = If(String.IsNullOrEmpty(messageErreur), T("Saisis les paramètres pour voir l'aperçu.", "Enter the parameters to see the preview.", "Ingrese los parámetros para ver la vista previa."), messageErreur)
            divPreview.Attributes("class") = If(String.IsNullOrEmpty(messageErreur), "preview-box", "preview-box error")
        End If
    End Sub

    ' =========================================================
    '  SAUVEGARDE
    ' =========================================================

    Private Function SauvegarderSchedule() As Integer
        ' Validations
        If String.IsNullOrWhiteSpace(txtNom.Text) Then
            Throw New ApplicationException(T("Le nom du schedule est obligatoire.", "The schedule name is required.", "El nombre de la programación es obligatorio."))
        End If
        If String.IsNullOrEmpty(ddlScheduleType.SelectedValue) Then
            Throw New ApplicationException(T("Le type de planification est obligatoire.", "The schedule type is required.", "El tipo de programación es obligatorio."))
        End If

        Dim scheduleType = ddlScheduleType.SelectedValue

        Dim intervalMin As Object = DBNull.Value
        Dim heureExec As Object = DBNull.Value
        Dim joursSem As Object = DBNull.Value
        Dim jourMois As Object = DBNull.Value
        Dim intervalleMois As Integer = 1                      ' ← NOUVEAU
        Dim cronExpr As Object = DBNull.Value
        Dim dateOnce As Object = DBNull.Value

        Select Case scheduleType
            Case "INTERVAL"
                intervalMin = Convert.ToInt32(txtIntervalMinutes.Value)
            Case "DAILY"
                If dpHeureDaily.SelectedTime.HasValue Then heureExec = dpHeureDaily.SelectedTime.Value
            Case "WEEKLY"
                If dpHeureWeekly.SelectedTime.HasValue Then heureExec = dpHeureWeekly.SelectedTime.Value
                Dim jours = New List(Of String)()
                If cbLun.Checked Then jours.Add("1")
                If cbMar.Checked Then jours.Add("2")
                If cbMer.Checked Then jours.Add("3")
                If cbJeu.Checked Then jours.Add("4")
                If cbVen.Checked Then jours.Add("5")
                If cbSam.Checked Then jours.Add("6")
                If cbDim.Checked Then jours.Add("7")
                If jours.Count = 0 Then
                    Throw New ApplicationException(T("Sélectionne au moins un jour de la semaine.", "Select at least one day of the week.", "Seleccione al menos un día de la semana."))
                End If
                joursSem = String.Join(",", jours)
            Case "MONTHLY"
                If dpHeureMonthly.SelectedTime.HasValue Then heureExec = dpHeureMonthly.SelectedTime.Value
                If String.IsNullOrEmpty(ddlJourMois.SelectedValue) Then
                    Throw New ApplicationException(T("Choisis un jour du mois.", "Choose a day of the month.", "Elija un día del mes."))
                End If
                jourMois = Convert.ToInt32(ddlJourMois.SelectedValue)
                ' ← NOUVEAU : récupérer la périodicité
                If Not String.IsNullOrEmpty(ddlIntervalleMois.SelectedValue) Then
                    intervalleMois = Convert.ToInt32(ddlIntervalleMois.SelectedValue)
                End If
            Case "CRON"
                If String.IsNullOrWhiteSpace(txtCronExpression.Text) Then
                    Throw New ApplicationException(T("L'expression CRON est obligatoire.", "The CRON expression is required.", "La expresión CRON es obligatoria."))
                End If
                cronExpr = txtCronExpression.Text.Trim()
            Case "ONCE"
                If Not dpDateOnce.SelectedDate.HasValue Then
                    Throw New ApplicationException(T("Choisis une date d'exécution.", "Choose a run date.", "Elija una fecha de ejecución."))
                End If
                dateOnce = dpDateOnce.SelectedDate.Value
        End Select

        Dim dateDebut As Object = If(dpDateDebut.SelectedDate.HasValue, CObj(dpDateDebut.SelectedDate.Value), DBNull.Value)
        Dim dateFin As Object = If(dpDateFin.SelectedDate.HasValue, CObj(dpDateFin.SelectedDate.Value), DBNull.Value)

        Dim actif = (ddlEtat.SelectedValue <> "INACTIF")
        Dim pause = (ddlEtat.SelectedValue = "PAUSE")

        Dim newId As Integer

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.sp_SaveJobSchedule", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@ScheduleId", ScheduleId)
                cmd.Parameters.AddWithValue("@JobDefinitionId", JobDefinitionId)
                cmd.Parameters.AddWithValue("@Nom", txtNom.Text.Trim())
                cmd.Parameters.AddWithValue("@ScheduleType", scheduleType)
                cmd.Parameters.AddWithValue("@IntervalMinutes", intervalMin)
                cmd.Parameters.AddWithValue("@HeureExecution", heureExec)
                cmd.Parameters.AddWithValue("@JoursSemaine", joursSem)
                cmd.Parameters.AddWithValue("@JourMois", jourMois)
                cmd.Parameters.AddWithValue("@IntervalleMois", intervalleMois)
                cmd.Parameters.AddWithValue("@CronExpression", cronExpr)
                cmd.Parameters.AddWithValue("@DateOnce", dateOnce)
                cmd.Parameters.AddWithValue("@DateDebut", dateDebut)
                cmd.Parameters.AddWithValue("@DateFin", dateFin)
                cmd.Parameters.AddWithValue("@HandlerParams",
                    If(String.IsNullOrWhiteSpace(txtHandlerParams.Text), CObj(DBNull.Value), txtHandlerParams.Text.Trim()))
                cmd.Parameters.AddWithValue("@Actif", actif)
                cmd.Parameters.AddWithValue("@Pause", pause)
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@UserId", UserId)

                Using rdr = cmd.ExecuteReader()
                    If rdr.Read() Then
                        newId = Convert.ToInt32(rdr("ScheduleId"))
                    End If
                End Using
            End Using
        End Using

        Return newId
    End Function

    ' =========================================================
    '  HELPERS
    ' =========================================================

    Private Function FormatDateRelative(dt As DateTime) As String
        Dim diff = dt - DateTime.Now
        Dim cult = CultureLang()

        If diff.TotalSeconds < 0 Then
            Dim minutes = Math.Abs(diff.TotalMinutes)
            If minutes < 60 Then Return T("Il y a " & Math.Round(minutes) & " min", Math.Round(minutes) & " min ago", "hace " & Math.Round(minutes) & " min")
            If diff.TotalHours > -24 Then Return T("Il y a " & Math.Round(Math.Abs(diff.TotalHours)) & " h", Math.Round(Math.Abs(diff.TotalHours)) & " h ago", "hace " & Math.Round(Math.Abs(diff.TotalHours)) & " h")
            Return T("Il y a " & Math.Round(Math.Abs(diff.TotalDays)) & " jours", Math.Round(Math.Abs(diff.TotalDays)) & " days ago", "hace " & Math.Round(Math.Abs(diff.TotalDays)) & " días")
        Else
            Dim minutes = diff.TotalMinutes
            If minutes < 1 Then Return T("Dans moins d'1 min", "In less than 1 min", "En menos de 1 min")
            If minutes < 60 Then Return T("Dans " & Math.Round(minutes) & " min", "In " & Math.Round(minutes) & " min", "En " & Math.Round(minutes) & " min")
            If diff.TotalHours < 24 Then
                Dim h = Math.Round(diff.TotalHours, 1)
                Dim d = dt.ToString("dddd HH:mm", cult)
                Return T("Dans " & h & " h (" & d & ")", "In " & h & " h (" & d & ")", "En " & h & " h (" & d & ")")
            End If
            If diff.TotalDays < 7 Then
                Dim j = Math.Round(diff.TotalDays)
                Dim d = dt.ToString("dddd dd MMM", cult)
                Return T("Dans " & j & " j (" & d & ")", "In " & j & " d (" & d & ")", "En " & j & " d (" & d & ")")
            End If
            Return T("Dans " & Math.Round(diff.TotalDays) & " jours", "In " & Math.Round(diff.TotalDays) & " days", "En " & Math.Round(diff.TotalDays) & " días")
        End If
    End Function

    Private Sub ShowStatus(level As String, message As String)
        Dim bg As String, color As String, border As String
        Select Case level
            Case "success"
                bg = "#dcfce7" : color = "#166534" : border = "#16a34a"
            Case "warning"
                bg = "#fef3c7" : color = "#92400e" : border = "#f59e0b"
            Case "danger"
                bg = "#fee2e2" : color = "#991b1b" : border = "#dc2626"
            Case Else
                bg = "#dbeafe" : color = "#1e40af" : border = "#3b82f6"
        End Select

        divStatus.Style("background") = bg
        divStatus.Style("color") = color
        divStatus.Style("border-color") = border
        litStatus.Text = message
        phStatus.Visible = True
    End Sub

End Class
