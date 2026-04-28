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

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
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
                ShowStatus("danger", "Paramètre JobId manquant en URL.")
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
                ShowStatus("success", "Schedule enregistré.")
                ScheduleId = newId
                ' Recharger pour afficher la ProchaineExec recalculée
                ChargerSchedule(newId)
            End If

        Catch sqlex As SqlException
            ShowStatus("danger", "Erreur SQL : " & sqlex.Message)
        Catch ex As Exception
            ShowStatus("danger", "Erreur : " & ex.Message)
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
            ShowStatus("danger", "Erreur SQL : " & sqlex.Message)
        Catch ex As Exception
            ShowStatus("danger", "Erreur : " & ex.Message)
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
                        litTitre.Text = "Nouveau schedule"
                        litBadgeJob.Text = "<span class='badge-job'>Pour le job : " & Server.HtmlEncode(JobNom) & "</span>"
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
            ShowStatus("danger", "Schedule introuvable (Id=" & id & ").")
            btnEnregistrer.Enabled = False
            Return
        End If

        Dim r = dt.Rows(0)

        JobDefinitionId = Convert.ToInt32(r("JobDefinitionId"))
        JobNom = r("JobNom").ToString()

        litTitre.Text = "Édition : " & Server.HtmlEncode(r("Nom").ToString())
        litBadgeJob.Text = "<span class='badge-job'>Pour le job : " & Server.HtmlEncode(JobNom) & "</span>"

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
            AfficherApercu(Nothing, "Pas encore calculée — sera mise à jour au prochain démarrage du worker.")
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
            AfficherApercu(Nothing, "Le calcul d'une expression CRON est effectué par le service .NET (NCrontab/Cronos).")
            Return
        End If

        ' Récupérer les paramètres saisis selon le type
        Dim intervalMin As Object = DBNull.Value
        Dim heureExec As Object = DBNull.Value
        Dim joursSem As Object = DBNull.Value
        Dim jourMois As Object = DBNull.Value
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
            AfficherApercu(Nothing, "Erreur de calcul : " & ex.Message)
        End Try
    End Sub

    Private Sub AfficherApercu(prochaine As DateTime?, messageErreur As String)
        If prochaine.HasValue Then
            litProchaineExec.Text = prochaine.Value.ToString("yyyy-MM-dd HH:mm:ss")
            litProchaineExecMeta.Text = FormatDateRelative(prochaine.Value)
            divPreview.Attributes("class") = "preview-box"
        Else
            litProchaineExec.Text = "—"
            litProchaineExecMeta.Text = If(String.IsNullOrEmpty(messageErreur), "Saisis les paramètres pour voir l'aperçu.", messageErreur)
            divPreview.Attributes("class") = If(String.IsNullOrEmpty(messageErreur), "preview-box", "preview-box error")
        End If
    End Sub

    ' =========================================================
    '  SAUVEGARDE
    ' =========================================================

    Private Function SauvegarderSchedule() As Integer
        ' Validations
        If String.IsNullOrWhiteSpace(txtNom.Text) Then
            Throw New ApplicationException("Le nom du schedule est obligatoire.")
        End If
        If String.IsNullOrEmpty(ddlScheduleType.SelectedValue) Then
            Throw New ApplicationException("Le type de planification est obligatoire.")
        End If

        Dim scheduleType = ddlScheduleType.SelectedValue

        Dim intervalMin As Object = DBNull.Value
        Dim heureExec As Object = DBNull.Value
        Dim joursSem As Object = DBNull.Value
        Dim jourMois As Object = DBNull.Value
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
                    Throw New ApplicationException("Sélectionne au moins un jour de la semaine.")
                End If
                joursSem = String.Join(",", jours)
            Case "MONTHLY"
                If dpHeureMonthly.SelectedTime.HasValue Then heureExec = dpHeureMonthly.SelectedTime.Value
                If String.IsNullOrEmpty(ddlJourMois.SelectedValue) Then
                    Throw New ApplicationException("Choisis un jour du mois.")
                End If
                jourMois = Convert.ToInt32(ddlJourMois.SelectedValue)
            Case "CRON"
                If String.IsNullOrWhiteSpace(txtCronExpression.Text) Then
                    Throw New ApplicationException("L'expression CRON est obligatoire.")
                End If
                cronExpr = txtCronExpression.Text.Trim()
            Case "ONCE"
                If Not dpDateOnce.SelectedDate.HasValue Then
                    Throw New ApplicationException("Choisis une date d'exécution.")
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

        If diff.TotalSeconds < 0 Then
            Dim minutes = Math.Abs(diff.TotalMinutes)
            If minutes < 60 Then Return "Il y a " & Math.Round(minutes) & " min"
            If diff.TotalHours > -24 Then Return "Il y a " & Math.Round(Math.Abs(diff.TotalHours)) & " h"
            Return "Il y a " & Math.Round(Math.Abs(diff.TotalDays)) & " jours"
        Else
            Dim minutes = diff.TotalMinutes
            If minutes < 1 Then Return "Dans moins d'1 min"
            If minutes < 60 Then Return "Dans " & Math.Round(minutes) & " min"
            If diff.TotalHours < 24 Then
                Return "Dans " & Math.Round(diff.TotalHours, 1) & " h (" &
                    dt.ToString("dddd HH:mm", System.Globalization.CultureInfo.GetCultureInfo("fr-CA")) & ")"
            End If
            If diff.TotalDays < 7 Then
                Return "Dans " & Math.Round(diff.TotalDays) & " j (" &
                    dt.ToString("dddd dd MMM", System.Globalization.CultureInfo.GetCultureInfo("fr-CA")) & ")"
            End If
            Return "Dans " & Math.Round(diff.TotalDays) & " jours"
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
