Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Partial Public Class wbfJobEdit
    Inherits clsData

    ' =========================================================
    '  PROPRIÉTÉS
    ' =========================================================

    Public Property JobDefinitionId As Integer
        Get
            Return If(ViewState("JobId"), 0)
        End Get
        Set(value As Integer)
            ViewState("JobId") = value
            If hfJobId IsNot Nothing Then
                hfJobId.Value = value.ToString()
            End If
        End Set
    End Property

    Private Property EstSysteme As Boolean
        Get
            Return If(ViewState("Sys"), False)
        End Get
        Set(value As Boolean)
            ViewState("Sys") = value
        End Set
    End Property

    ' =========================================================
    '  PAGE LIFECYCLE
    ' =========================================================

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ' Lire l'Id depuis QueryString
            Dim idStr = Request.QueryString("Id")
            Dim id As Integer = 0
            Integer.TryParse(idStr, id)
            JobDefinitionId = id

            If id > 0 Then
                ChargerJob(id)
                ChargerSchedules(id)
                ChargerHistorique(id)
                phSchedSection.Visible = True
                lnkVoirHistorique.NavigateUrl = "wbfJobMonitoring.aspx?JobId=" & id
            Else
                ' Mode création
                litTitre.Text = "Nouveau job"
                litSousTitre.Text = "Définir une nouvelle tâche planifiée."
                phSchedSection.Visible = False  ' on ne peut pas créer de schedules avant d'avoir le job
                btnSupprimer.Visible = False
                MajHandlerHint("")
            End If
        End If
    End Sub

    ' =========================================================
    '  ÉVÉNEMENTS UI
    ' =========================================================

    Protected Sub ddlHandlerType_SelectedIndexChanged(sender As Object, e As EventArgs)
        MajHandlerHint(ddlHandlerType.SelectedValue)
    End Sub

    Protected Sub btnEnregistrer_Click(sender As Object, e As EventArgs)
        Try
            Dim newId = SauvegarderJob()

            If newId > 0 Then
                ShowStatus("success", "Job enregistré.")

                If JobDefinitionId = 0 Then
                    ' Création : rediriger vers le mode édition pour permettre d'ajouter des schedules
                    Response.Redirect("wbfJobEdit.aspx?Id=" & newId & "&saved=1")
                Else
                    ' Édition : recharger
                    JobDefinitionId = newId
                    ChargerJob(newId)
                    ChargerSchedules(newId)
                End If
            End If

        Catch sqlex As SqlException
            ShowStatus("danger", "Erreur SQL : " & sqlex.Message)
        Catch ex As Exception
            ShowStatus("danger", "Erreur : " & ex.Message)
        End Try
    End Sub

    Protected Sub btnSupprimer_Click(sender As Object, e As EventArgs)
        If JobDefinitionId = 0 Then Return

        Try
            Using cn As New SqlConnection(ConnectionString)
                cn.Open()
                Using cmd As New SqlCommand("dbo.sp_SupprimerJob", cn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@JobDefinitionId", JobDefinitionId)
                    cmd.Parameters.AddWithValue("@UserId", UserId)
                    cmd.ExecuteNonQuery()
                End Using
            End Using

            Response.Redirect("wbfJobs.aspx?deleted=1")

        Catch sqlex As SqlException
            ShowStatus("danger", "Erreur SQL : " & sqlex.Message)
        Catch ex As Exception
            ShowStatus("danger", "Erreur : " & ex.Message)
        End Try
    End Sub

    Protected Sub rpSchedules_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        Dim schedId = Convert.ToInt32(e.CommandArgument)

        Try
            Select Case e.CommandName
                Case "EditSched"
                    Response.Redirect("wbfJobSchedule.aspx?JobId=" & JobDefinitionId & "&Id=" & schedId)
                    Return

                Case "TogglePause"
                    Using cn As New SqlConnection(ConnectionString)
                        cn.Open()
                        Using cmd As New SqlCommand("dbo.sp_TogglePauseSchedule", cn)
                            cmd.CommandType = CommandType.StoredProcedure
                            cmd.Parameters.AddWithValue("@ScheduleId", schedId)
                            cmd.Parameters.AddWithValue("@UserId", UserId)
                            cmd.ExecuteNonQuery()
                        End Using
                    End Using
                    ShowStatus("info", "État du schedule mis à jour.")

                Case "SupprSched"
                    Using cn As New SqlConnection(ConnectionString)
                        cn.Open()
                        ' Pas de SP dédiée — DELETE direct (ou tu peux en créer une)
                        Using cmd As New SqlCommand(
                            "DELETE FROM [dbo].[T201JobSchedule] WHERE [Id] = @Id", cn)
                            cmd.Parameters.AddWithValue("@Id", schedId)
                            cmd.ExecuteNonQuery()
                        End Using
                    End Using
                    ShowStatus("success", "Schedule supprimé.")
            End Select

            ChargerSchedules(JobDefinitionId)

        Catch ex As Exception
            ShowStatus("danger", "Erreur : " & ex.Message)
        End Try
    End Sub

    ' =========================================================
    '  CHARGEMENT
    ' =========================================================

    Private Sub ChargerJob(id As Integer)
        Dim dt As New DataTable()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0210GetJobDefinition", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@JobDefinitionId", id)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        If dt.Rows.Count = 0 Then
            ShowStatus("danger", "Job introuvable (Id=" & id & ").")
            Return
        End If

        Dim r = dt.Rows(0)

        EstSysteme = Convert.ToBoolean(r("Systeme"))

        litTitre.Text = "Édition : " & Server.HtmlEncode(r("Nom").ToString())
        litSousTitre.Text = "Code : " & r("JobCode").ToString()

        If EstSysteme Then
            litBadgeSysteme.Text = "<span class='badge-systeme'>SYSTÈME</span>"
            btnSupprimer.Visible = False
        Else
            litBadgeSysteme.Text = ""
            btnSupprimer.Visible = True
        End If

        ' Remplir les champs
        txtJobCode.Text = r("JobCode").ToString()
        txtJobCode.Enabled = Not EstSysteme  ' code immutable pour les jobs système

        txtNom.Text = r("Nom").ToString()
        txtNom.Enabled = Not EstSysteme

        txtDescription.Text = If(Convert.IsDBNull(r("Description")), "", r("Description").ToString())
        txtDescription.Enabled = Not EstSysteme

        ddlActif.SelectedValue = If(Convert.ToBoolean(r("Actif")), "1", "0")

        ddlHandlerType.SelectedValue = r("HandlerType").ToString()
        ddlHandlerType.Enabled = Not EstSysteme

        txtHandlerName.Text = r("HandlerName").ToString()
        txtHandlerName.Enabled = Not EstSysteme

        txtHandlerParams.Text = If(Convert.IsDBNull(r("HandlerParams")), "", r("HandlerParams").ToString())

        txtTimeoutSeconds.Value = Convert.ToInt32(r("TimeoutSeconds"))
        txtMaxRetries.Value = Convert.ToInt32(r("MaxRetries"))
        txtRetryDelayMin.Value = Convert.ToInt32(r("RetryDelayMin"))

        MajHandlerHint(r("HandlerType").ToString())
    End Sub

    Private Sub ChargerSchedules(jobId As Integer)
        Dim dt As New DataTable()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0201GetJobSchedules", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@JobDefinitionId", jobId)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        If dt.Rows.Count = 0 Then
            phSchedEmpty.Visible = True
            phSchedTable.Visible = False
        Else
            phSchedEmpty.Visible = False
            phSchedTable.Visible = True
            rpSchedules.DataSource = dt
            rpSchedules.DataBind()
        End If
    End Sub

    Private Sub ChargerHistorique(jobId As Integer)
        Dim dt As New DataTable()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0211GetJobExecutionsRecentes", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@JobDefinitionId", jobId)
                cmd.Parameters.AddWithValue("@NbResultats", 5)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        If dt.Rows.Count = 0 Then
            phHistEmpty.Visible = True
            phHistTable.Visible = False
        Else
            phHistEmpty.Visible = False
            phHistTable.Visible = True
            rpHistorique.DataSource = dt
            rpHistorique.DataBind()
        End If
    End Sub

    ' =========================================================
    '  SAUVEGARDE
    ' =========================================================

    Private Function SauvegarderJob() As Integer
        ' Validations côté serveur
        If String.IsNullOrWhiteSpace(txtJobCode.Text) Then
            Throw New ApplicationException("Le code du job est obligatoire.")
        End If
        If String.IsNullOrWhiteSpace(txtNom.Text) Then
            Throw New ApplicationException("Le nom du job est obligatoire.")
        End If
        If String.IsNullOrEmpty(ddlHandlerType.SelectedValue) Then
            Throw New ApplicationException("Sélectionne un type de handler.")
        End If
        If String.IsNullOrWhiteSpace(txtHandlerName.Text) Then
            Throw New ApplicationException("Le nom du handler est obligatoire.")
        End If

        Dim newId As Integer

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.sp_SaveJobDefinition", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@JobDefinitionId", JobDefinitionId)
                cmd.Parameters.AddWithValue("@JobCode", txtJobCode.Text.Trim().ToUpper())
                cmd.Parameters.AddWithValue("@Nom", txtNom.Text.Trim())
                cmd.Parameters.AddWithValue("@Description",
                    If(String.IsNullOrWhiteSpace(txtDescription.Text), CObj(DBNull.Value), txtDescription.Text.Trim()))
                cmd.Parameters.AddWithValue("@HandlerType", ddlHandlerType.SelectedValue)
                cmd.Parameters.AddWithValue("@HandlerName", txtHandlerName.Text.Trim())
                cmd.Parameters.AddWithValue("@HandlerParams",
                    If(String.IsNullOrWhiteSpace(txtHandlerParams.Text), CObj(DBNull.Value), txtHandlerParams.Text.Trim()))
                cmd.Parameters.AddWithValue("@TimeoutSeconds", Convert.ToInt32(txtTimeoutSeconds.Value))
                cmd.Parameters.AddWithValue("@MaxRetries", Convert.ToInt32(txtMaxRetries.Value))
                cmd.Parameters.AddWithValue("@RetryDelayMin", Convert.ToInt32(txtRetryDelayMin.Value))
                cmd.Parameters.AddWithValue("@Actif", ddlActif.SelectedValue = "1")
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@UserId", UserId)

                Dim res = cmd.ExecuteScalar()
                newId = If(res Is Nothing OrElse Convert.IsDBNull(res), 0, Convert.ToInt32(res))
            End Using
        End Using

        Return newId
    End Function

    ' =========================================================
    '  EVENT HANDLER REPEATER
    ' =========================================================

    Protected Sub rpHistorique_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim row = TryCast(e.Item.DataItem, DataRowView)
        If row Is Nothing Then Return

        Dim litPill = TryCast(e.Item.FindControl("litStatutPill"), Literal)
        If litPill Is Nothing Then Return

        Dim statut = If(Convert.IsDBNull(row("Statut")), "", row("Statut").ToString())
        litPill.Text = String.Format(
            "<span class='pill {0}'>{1}</span>",
            StatutPill(statut),
            Server.HtmlEncode(statut))
    End Sub

    ' =========================================================
    '  HELPERS
    ' =========================================================

    Private Function StatutPill(statut As Object) As String
        If statut Is Nothing OrElse Convert.IsDBNull(statut) Then Return "pill-neutral"
        Select Case statut.ToString()
            Case "SUCCES" : Return "pill-success"
            Case "ECHEC" : Return "pill-danger"
            Case "TIMEOUT" : Return "pill-danger"
            Case "EN_COURS" : Return "pill-info"
            Case "ANNULE" : Return "pill-warning"
            Case Else : Return "pill-neutral"
        End Select
    End Function

    Private Sub MajHandlerHint(handlerType As String)
        Select Case handlerType
            Case "SP"
                litHandlerNameLabel.Text = "Nom de la procédure stockée"
                litHandlerHint.Text = "Ex: sp_GenererRapportTaxe — la SP doit accepter @CompanyGUID et @UserId."
            Case "CONNECTOR"
                litHandlerNameLabel.Text = "Nom du connecteur"
                litHandlerHint.Text = "Ex: BankFeedConnector — référence une classe enregistrée dans le worker."
            Case "EMAIL"
                litHandlerNameLabel.Text = "Procédure de génération du courriel"
                litHandlerHint.Text = "Ex: sp_GenererRappelsFactures — doit retourner les destinataires + corps du courriel."
            Case "CUSTOM"
                litHandlerNameLabel.Text = "Nom complet de la classe .NET"
                litHandlerHint.Text = "Ex: MngConsul.Jobs.BackupParametersJob — la classe doit implémenter IJobHandler."
            Case Else
                litHandlerNameLabel.Text = "Nom du handler"
                litHandlerHint.Text = "Sélectionne d'abord un type de handler."
        End Select
    End Sub

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
