Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Partial Public Class wbfJobs
    Inherits clsData

    ' =========================================================
    '  PAGE LIFECYCLE
    ' =========================================================

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            ChargerKpis()
            ChargerJobs()
        End If
    End Sub

    ' =========================================================
    '  ÉVÉNEMENTS UI
    ' =========================================================

    Protected Sub Filtre_Changed(sender As Object, e As EventArgs)
        ChargerJobs()
    End Sub

    Protected Sub btnRefresh_Click(sender As Object, e As EventArgs)
        ChargerKpis()
        ChargerJobs()
    End Sub

    Protected Sub rpJobs_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim row = TryCast(e.Item.DataItem, DataRowView)
        If row Is Nothing Then Return

        Dim jobId = Convert.ToInt32(row("JobDefinitionId"))

        ' ─── Schedules : compteur + liste dépliée ───
        Dim litSchedules = TryCast(e.Item.FindControl("litSchedules"), Literal)
        Dim nbActifs = If(Convert.IsDBNull(row("NbSchedActifs")), 0, Convert.ToInt32(row("NbSchedActifs")))
        Dim nbPause = If(Convert.IsDBNull(row("NbSchedEnPause")), 0, Convert.ToInt32(row("NbSchedEnPause")))
        Dim nbTotal = If(Convert.IsDBNull(row("NbSchedules")), 0, Convert.ToInt32(row("NbSchedules")))

        If nbTotal = 0 Then
            litSchedules.Text = "<span class='pill pill-neutral'>Aucun</span>"
        ElseIf nbPause > 0 Then
            litSchedules.Text = String.Format(
                "<span class='pill pill-warning'>{0} actifs / {1} en pause</span>", nbActifs, nbPause)
        Else
            litSchedules.Text = String.Format(
                "<span class='pill pill-info'>{0} actif{1}</span>",
                nbActifs, If(nbActifs > 1, "s", ""))
        End If

        ' ─── Prochaine exécution ───
        Dim litProchaine = TryCast(e.Item.FindControl("litProchaineExec"), Literal)
        If Convert.IsDBNull(row("ProchaineExec")) Then
            litProchaine.Text = "<span style='color:#94a3b8;'>—</span>"
        Else
            Dim dt = Convert.ToDateTime(row("ProchaineExec"))
            litProchaine.Text = FormatDateRelative(dt) & "<div class='meta-line'>" &
                dt.ToString("yyyy-MM-dd HH:mm") & "</div>"
        End If

        ' ─── Dernière exécution ───
        Dim litDerniere = TryCast(e.Item.FindControl("litDerniereExec"), Literal)
        If Convert.IsDBNull(row("DerniereExecDemarre")) Then
            litDerniere.Text = "<span style='color:#94a3b8;'>Jamais</span>"
        Else
            Dim statut = row("DerniereExecStatut").ToString()
            Dim dt = Convert.ToDateTime(row("DerniereExecDemarre"))
            Dim pillClass = StatutToPillClass(statut)
            litDerniere.Text = String.Format(
                "<span class='pill {0}'>{1}</span><div class='meta-line'>{2}</div>",
                pillClass, statut, dt.ToString("yyyy-MM-dd HH:mm"))
        End If

        ' ─── Volet déplié : schedules détaillés ───
        Dim phSchedules = TryCast(e.Item.FindControl("phSchedules"), PlaceHolder)
        If nbTotal > 0 Then
            ChargerSchedules(jobId, phSchedules)
        End If

        ' Job inactif : griser la ligne
        If Not Convert.ToBoolean(row("Actif")) Then
            Dim mainRow = TryCast(e.Item.Controls(1), HtmlControls.HtmlTableRow)
            ' Pas évident en Repeater — on applique via style sur la ligne
            ' Utilisation simple : ajout d'une classe dans le Render serait plus propre
        End If
    End Sub

    Protected Sub rpJobs_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        Dim jobId = Convert.ToInt32(e.CommandArgument)

        Try
            Select Case e.CommandName
                Case "Editer"
                    Response.Redirect("wbfJobEdit.aspx?Id=" & jobId)
                    Return

                Case "RunNow"
                    Dim execId = LancerJobMaintenant(jobId)
                    ShowStatus("success",
                        "Job lancé manuellement. ExecutionId=" & execId &
                        ". Le worker prendra le relais à son prochain cycle.")

                Case "ToggleActif"
                    BasculerActifJob(jobId)
                    ShowStatus("info", "Statut du job mis à jour.")

                Case "Supprimer"
                    SupprimerJob(jobId)
                    ShowStatus("success", "Job supprimé avec succès.")

                Case "Historique"
                    Response.Redirect("wbfJobMonitoring.aspx?JobId=" & jobId)
                    Return
            End Select

            ChargerKpis()
            ChargerJobs()

        Catch sqlex As SqlException
            ShowStatus("danger", "Erreur SQL : " & sqlex.Message)
        Catch ex As Exception
            ShowStatus("danger", "Erreur : " & ex.Message)
        End Try
    End Sub

    ' =========================================================
    '  CHARGEMENT DES DONNÉES (via SP)
    ' =========================================================

    Private Sub ChargerJobs()
        Dim filtreActif As Object = DBNull.Value
        If Not String.IsNullOrEmpty(ddlFiltreActif.SelectedValue) Then
            filtreActif = (ddlFiltreActif.SelectedValue = "1")
        End If

        Dim filtreType As Object = DBNull.Value
        If Not String.IsNullOrEmpty(ddlFiltreType.SelectedValue) Then
            filtreType = ddlFiltreType.SelectedValue
        End If

        Dim recherche As Object = DBNull.Value
        If Not String.IsNullOrEmpty(txtRecherche.Text) Then
            recherche = txtRecherche.Text.Trim()
        End If

        Dim dt As New DataTable()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0200GetJobsListe", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@FiltreActif", filtreActif)
                cmd.Parameters.AddWithValue("@FiltreType", filtreType)
                cmd.Parameters.AddWithValue("@Recherche", recherche)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        If dt.Rows.Count = 0 Then
            phEmpty.Visible = True
            phTable.Visible = False
        Else
            phEmpty.Visible = False
            phTable.Visible = True
            rpJobs.DataSource = dt
            rpJobs.DataBind()
        End If
    End Sub

    Private Sub ChargerSchedules(jobId As Integer, ph As PlaceHolder)
        ph.Controls.Clear()

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

        If dt.Rows.Count = 0 Then Return

        Dim sb As New System.Text.StringBuilder()
        sb.AppendLine("<div class='schedule-list'>")

        For Each r As DataRow In dt.Rows
            Dim nom = Server.HtmlEncode(r("Nom").ToString())
            Dim desc = Server.HtmlEncode(r("DescriptionLisible").ToString())

            Dim badgeEtat = ""
            If Convert.ToBoolean(r("Pause")) Then
                badgeEtat = "<span class='pill pill-warning'>EN PAUSE</span>"
            ElseIf Not Convert.ToBoolean(r("Actif")) Then
                badgeEtat = "<span class='pill pill-neutral'>INACTIF</span>"
            Else
                badgeEtat = "<span class='pill pill-success'>ACTIF</span>"
            End If

            Dim prochaine As String
            If Convert.IsDBNull(r("ProchaineExec")) Then
                prochaine = "<span style='color:#94a3b8;'>—</span>"
            Else
                Dim dt2 = Convert.ToDateTime(r("ProchaineExec"))
                prochaine = FormatDateRelative(dt2)
            End If

            sb.AppendFormat(
                "<div class='schedule-item'>" &
                "<span class='sched-name'>{0}</span>" &
                "<span class='sched-desc'>{1}</span>" &
                "<span class='sched-next'>Prochaine : {2}</span>" &
                "<span>{3}</span>" &
                "</div>",
                nom, desc, prochaine, badgeEtat)
        Next

        sb.AppendLine("</div>")
        ph.Controls.Add(New LiteralControl(sb.ToString()))
    End Sub

    Private Sub ChargerKpis()
        Dim dt As New DataTable()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0202GetJobsKpis", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        If dt.Rows.Count > 0 Then
            Dim r = dt.Rows(0)
            litKpiActifs.Text = r("NbJobsActifs").ToString()
            litKpiSucces.Text = r("NbSucces24h").ToString()
            litKpiEchecs.Text = r("NbEchecs24h").ToString()
            litKpiEnCours.Text = r("NbEnCours").ToString()
        End If
    End Sub

    ' =========================================================
    '  ACTIONS (via SP)
    ' =========================================================

    Private Function LancerJobMaintenant(jobId As Integer) As Integer
        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.sp_LancerJobMaintenant", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@JobDefinitionId", jobId)
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@LanceePar", UserId)

                Dim execIdParam As New SqlParameter("@ExecutionId", SqlDbType.Int) With {
                    .Direction = ParameterDirection.Output
                }
                cmd.Parameters.Add(execIdParam)

                cmd.ExecuteNonQuery()

                Return If(execIdParam.Value Is Nothing OrElse Convert.IsDBNull(execIdParam.Value),
                          0, Convert.ToInt32(execIdParam.Value))
            End Using
        End Using
    End Function

    Private Sub BasculerActifJob(jobId As Integer)
        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.sp_ToggleActifJob", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@JobDefinitionId", jobId)
                cmd.Parameters.AddWithValue("@UserId", UserId)
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Private Sub SupprimerJob(jobId As Integer)
        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.sp_SupprimerJob", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@JobDefinitionId", jobId)
                cmd.Parameters.AddWithValue("@UserId", UserId)
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    ' =========================================================
    '  HELPERS DE PRÉSENTATION
    ' =========================================================

    Private Function StatutToPillClass(statut As String) As String
        Select Case statut
            Case "SUCCES" : Return "pill-success"
            Case "ECHEC" : Return "pill-danger"
            Case "TIMEOUT" : Return "pill-danger"
            Case "EN_COURS" : Return "pill-running"
            Case "ANNULE" : Return "pill-warning"
            Case Else : Return "pill-neutral"
        End Select
    End Function

    Private Function FormatDateRelative(dt As DateTime) As String
        Dim diff = dt - DateTime.Now
        Dim minutes = Math.Abs(diff.TotalMinutes)

        If diff.TotalSeconds < 0 Then
            ' Date passée
            If minutes < 1 Then Return "À l'instant"
            If minutes < 60 Then Return "Il y a " & Math.Round(minutes) & " min"
            If diff.TotalHours > -24 Then Return "Il y a " & Math.Round(Math.Abs(diff.TotalHours)) & " h"
            Return "Il y a " & Math.Round(Math.Abs(diff.TotalDays)) & " j"
        Else
            ' Date future
            If minutes < 1 Then Return "Dans moins d'1 min"
            If minutes < 60 Then Return "Dans " & Math.Round(minutes) & " min"
            If diff.TotalHours < 24 Then Return "Dans " & Math.Round(diff.TotalHours) & " h"
            Return "Dans " & Math.Round(diff.TotalDays) & " j"
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
