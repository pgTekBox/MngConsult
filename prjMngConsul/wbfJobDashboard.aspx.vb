Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Partial Public Class wbfJobDashboard
    Inherits clsData

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
        Page.Title = T("Tableau de bord — Orchestrateur", "Dashboard — Orchestrator", "Panel de control — Orquestador")
        btnRefresh.Text = T("Rafraîchir", "Refresh", "Actualizar")

        litLoc01.Text = T("Tableau de bord — Orchestrateur", "Dashboard — Orchestrator", "Panel de control — Orquestador")
        litLoc02.Text = T("Vue d'ensemble en temps réel des jobs planifiés.", "Real-time overview of scheduled jobs.", "Vista general en tiempo real de las tareas programadas.")
        litLoc03.Text = T("Dernière actualisation :", "Last refresh:", "Última actualización:")
        litLoc04.Text = T("Auto-refresh 30s", "Auto-refresh 30s", "Auto-actualización 30s")
        litLoc05.Text = T("Jobs actifs", "Active jobs", "Tareas activas")
        litLoc06.Text = T("inactifs", "inactive", "inactivas")
        litLoc07.Text = T("Succès 24 h", "Success 24 h", "Éxitos 24 h")
        litLoc08.Text = T("Taux 7j :", "7-day rate:", "Tasa 7 días:")
        litLoc09.Text = T("Échecs 24 h", "Failures 24 h", "Fallos 24 h")
        litLoc10.Text = T("Sur 7 jours :", "Over 7 days:", "En 7 días:")
        litLoc11.Text = T("exéc.", "runs", "ejec.")
        litLoc12.Text = T("En cours actuellement", "Currently running", "En curso actualmente")
        litLoc13.Text = T("Durée moyenne :", "Average duration:", "Duración media:")
        litLoc14.Text = T("Tendance des 7 derniers jours", "Trend over the last 7 days", "Tendencia de los últimos 7 días")
        litLoc15.Text = T("Jobs en alerte", "Jobs in alert", "Tareas en alerta")
        litLoc16.Text = T("Aucun job en alerte. Tout roule.", "No jobs in alert. All running smoothly.", "Ninguna tarea en alerta. Todo funciona.")
        litLoc17.Text = T("Prochaines exécutions (24 h)", "Upcoming runs (24 h)", "Próximas ejecuciones (24 h)")
        litLoc18.Text = T("Aucune exécution prévue dans les 24 prochaines heures.", "No runs scheduled in the next 24 hours.", "Ninguna ejecución prevista en las próximas 24 horas.")
        litLoc19.Text = T("Activité récente", "Recent activity", "Actividad reciente")
        litLoc20.Text = T("10 dernières", "Last 10", "Últimas 10")
        litLoc21.Text = T("Aucune exécution récente.", "No recent runs.", "Ninguna ejecución reciente.")
    End Sub

    ' =========================================================
    '  PAGE LIFECYCLE
    ' =========================================================

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ApplyLocalization()

        ' On peut rafraîchir aussi sur le premier load
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If

            ChargerTout()
        End If
    End Sub

    ' =========================================================
    '  ÉVÉNEMENTS
    ' =========================================================

    Protected Sub btnRefresh_Click(sender As Object, e As EventArgs)
        ChargerTout()
    End Sub

    Protected Sub tmrAutoRefresh_Tick(sender As Object, e As EventArgs)
        ChargerTout()
    End Sub

    Protected Sub rpAlertes_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName = "VoirExec" Then
            Response.Redirect("wbfJobExecution.aspx?Id=" & e.CommandArgument.ToString())
        End If
    End Sub

    Protected Sub rpActivite_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName = "VoirExec" Then
            Response.Redirect("wbfJobExecution.aspx?Id=" & e.CommandArgument.ToString())
        End If
    End Sub

    Protected Sub rpAlertes_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim row = TryCast(e.Item.DataItem, DataRowView)
        If row Is Nothing Then Return

        Dim litRow = TryCast(e.Item.FindControl("litRow"), Literal)
        If litRow Is Nothing Then Return

        Dim nbEchecs = If(Convert.IsDBNull(row("NbEchecsRecents")), 0, Convert.ToInt32(row("NbEchecsRecents")))
        Dim statut = If(Convert.IsDBNull(row("DerniereStatut")), "", row("DerniereStatut").ToString())
        Dim jobNom = Server.HtmlEncode(row("JobNom").ToString())
        Dim jobCode = Server.HtmlEncode(row("JobCode").ToString())
        Dim msg = If(Convert.IsDBNull(row("DernierMessage")), "",
                     Server.HtmlEncode(row("DernierMessage").ToString()))
        Dim quand = If(Convert.IsDBNull(row("DerniereDate")), "",
                       FormatDateRelative(Convert.ToDateTime(row("DerniereDate"))))

        Dim ico = If(nbEchecs >= 2, "🔴", "⚠")
        Dim rowClass = If(nbEchecs >= 2, "item-row row-danger", "item-row row-warning")

        Dim sb As New System.Text.StringBuilder()
        sb.AppendFormat("<div class='{0}'>", rowClass)
        sb.AppendFormat("<div class='ico'>{0}</div>", ico)
        sb.Append("<div class='body'>")
        sb.AppendFormat("<div class='title'>{0}</div>", jobNom)
        Dim plur = If(nbEchecs > 1, "s", "")
        Dim echecTxt = T(nbEchecs & " échec" & plur & " récent" & plur,
                         nbEchecs & " recent failure" & plur,
                         nbEchecs & " fallo" & plur & " reciente" & plur)
        sb.AppendFormat("<div class='meta'><code>{0}</code> • {1} • {2}</div>",
                        jobCode, echecTxt, msg)
        sb.Append("</div>")
        sb.AppendFormat("<div class='when'>{0}</div>", quand)
        sb.Append("</div>")
        litRow.Text = sb.ToString()
    End Sub

    Protected Sub rpProchaines_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim row = TryCast(e.Item.DataItem, DataRowView)
        If row Is Nothing Then Return

        Dim litRel = TryCast(e.Item.FindControl("litRelative"), Literal)
        If litRel IsNot Nothing AndAlso Not Convert.IsDBNull(row("ProchaineExec")) Then
            Dim dt = Convert.ToDateTime(row("ProchaineExec"))
            litRel.Text = FormatDateRelativeFutur(dt)
        End If
    End Sub

    Protected Sub rpActivite_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim row = TryCast(e.Item.DataItem, DataRowView)
        If row Is Nothing Then Return

        Dim litRow = TryCast(e.Item.FindControl("litRow"), Literal)
        If litRow Is Nothing Then Return

        Dim statut = If(Convert.IsDBNull(row("Statut")), "", row("Statut").ToString())
        Dim jobNom = Server.HtmlEncode(row("JobNom").ToString())
        Dim jobCode = Server.HtmlEncode(row("JobCode").ToString())
        Dim trigger = row("TriggerType").ToString()
        Dim msg = If(Convert.IsDBNull(row("ResultatMessage")), "",
                     Server.HtmlEncode(row("ResultatMessage").ToString()))
        Dim duree As String = "—"
        If Not Convert.IsDBNull(row("DureeMs")) Then
            duree = FormatDureeMs(Convert.ToInt64(row("DureeMs")))
        End If
        Dim quand = If(Convert.IsDBNull(row("Demarre")), "",
                       FormatDateRelative(Convert.ToDateTime(row("Demarre"))))

        Dim ico As String, rowClass As String, pillCls As String
        Select Case statut
            Case "SUCCES" : ico = "✓" : rowClass = "row-success" : pillCls = "pill-success"
            Case "ECHEC" : ico = "✗" : rowClass = "row-danger" : pillCls = "pill-danger"
            Case "TIMEOUT" : ico = "⏱" : rowClass = "row-danger" : pillCls = "pill-danger"
            Case "EN_COURS" : ico = "⟳" : rowClass = "row-info" : pillCls = "pill-running"
            Case "ANNULE" : ico = "⊘" : rowClass = "row-warning" : pillCls = "pill-warning"
            Case Else : ico = "○" : rowClass = "" : pillCls = "pill-neutral"
        End Select

        Dim sb As New System.Text.StringBuilder()
        sb.AppendFormat("<div class='item-row {0}'>", rowClass)
        sb.AppendFormat("<div class='ico'>{0}</div>", ico)
        sb.Append("<div class='body'>")
        sb.AppendFormat("<div class='title'>{0} <span class='pill {1}'>{2}</span></div>",
                        jobNom, pillCls, statut)
        sb.AppendFormat("<div class='meta'><code>{0}</code> • {1} • {2}</div>",
                        jobCode, trigger, msg)
        sb.Append("</div>")
        sb.AppendFormat("<div class='when'><strong>{0}</strong>{1}</div>", quand, duree)
        sb.Append("</div>")
        litRow.Text = sb.ToString()
    End Sub

    ' =========================================================
    '  CHARGEMENT
    ' =========================================================

    Private Sub ChargerTout()
        ChargerKpis()
        ChargerTendance()
        ChargerAlertes()
        ChargerProchaines()
        ChargerActivite()

        litLastRefresh.Text = DateTime.Now.ToString("HH:mm:ss")
    End Sub

    Private Sub ChargerKpis()
        Dim dt As New DataTable()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0250GetDashboardKpis", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        If dt.Rows.Count = 0 Then Return

        Dim r = dt.Rows(0)
        litKpiJobsActifs.Text = r("NbJobsActifs").ToString()
        litKpiJobsInactifs.Text = r("NbJobsInactifs").ToString()
        litKpiSucces24h.Text = r("NbSucces24h").ToString()
        litKpiEchecs24h.Text = r("NbEchecs24h").ToString()
        litKpiEnCours.Text = r("NbEnCours").ToString()
        litKpiTotal7j.Text = Convert.ToInt32(r("NbExec7j")).ToString("N0")

        ' Taux de succès 7 jours
        Dim total7j = Convert.ToInt32(r("NbExec7j"))
        Dim succes7j = Convert.ToInt32(r("NbSucces7j"))
        If total7j > 0 Then
            Dim taux = (succes7j * 100.0) / total7j
            litKpiTaux7j.Text = String.Format("{0:0.#}%", taux)
        Else
            litKpiTaux7j.Text = "—"
        End If

        ' Durée moyenne
        If Convert.IsDBNull(r("DureeMoy7jMs")) Then
            litKpiDureeMoy.Text = "—"
        Else
            litKpiDureeMoy.Text = FormatDureeMs(Convert.ToInt64(r("DureeMoy7jMs")))
        End If
    End Sub

    Private Sub ChargerTendance()
        Dim dt As New DataTable()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0254GetTendance7Jours", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        ' Trouver le max pour normaliser les hauteurs des barres
        Dim maxTotal As Integer = 1
        For Each row As DataRow In dt.Rows
            Dim total = Convert.ToInt32(row("NbTotal"))
            If total > maxTotal Then maxTotal = total
        Next

        Dim sb As New System.Text.StringBuilder()
        Dim ci = System.Globalization.CultureInfo.GetCultureInfo(
            If(CurrentLang = "en", "en-CA", If(CurrentLang = "es", "es-ES", "fr-CA")))

        For Each row As DataRow In dt.Rows
            Dim jour = Convert.ToDateTime(row("Jour"))
            Dim succes = Convert.ToInt32(row("NbSucces"))
            Dim echecs = Convert.ToInt32(row("NbEchecs")) + Convert.ToInt32(row("NbTimeouts"))
            Dim total = Convert.ToInt32(row("NbTotal"))

            ' Hauteurs en pourcentage (normalisé sur max)
            Dim hSucces = If(maxTotal > 0, (succes * 100.0) / maxTotal, 0)
            Dim hEchecs = If(maxTotal > 0, (echecs * 100.0) / maxTotal, 0)

            Dim labelJour = jour.ToString("ddd", ci)
            Dim labelDate = jour.ToString("dd MMM", ci)

            sb.Append("<div class='tendance-jour'>")
            sb.Append("<div class='tendance-bar-wrap'>")
            sb.AppendFormat("<div class='tendance-total'>{0}</div>", If(total > 0, total.ToString(), ""))
            If echecs > 0 Then
                sb.AppendFormat("<div class='tendance-bar-echec' style='height:{0}%'></div>", hEchecs.ToString("0.#", System.Globalization.CultureInfo.InvariantCulture))
            End If
            If succes > 0 Then
                sb.AppendFormat("<div class='tendance-bar-success' style='height:{0}%'></div>", hSucces.ToString("0.#", System.Globalization.CultureInfo.InvariantCulture))
            End If
            sb.Append("</div>")
            sb.AppendFormat("<div class='date'>{0}</div>", labelDate)
            sb.AppendFormat("<div class='label'>{0}</div>", labelJour)
            sb.Append("</div>")
        Next

        litTendance.Text = sb.ToString()
    End Sub

    Private Sub ChargerAlertes()
        Dim dt As New DataTable()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0251GetJobsEnAlerte", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        badgeAlertes.InnerText = dt.Rows.Count.ToString()
        If dt.Rows.Count > 0 Then
            badgeAlertes.Attributes("class") = "badge-count danger"
        Else
            badgeAlertes.Attributes("class") = "badge-count"
        End If

        If dt.Rows.Count = 0 Then
            phAlertesEmpty.Visible = True
            rpAlertes.Visible = False
        Else
            phAlertesEmpty.Visible = False
            rpAlertes.Visible = True
            rpAlertes.DataSource = dt
            rpAlertes.DataBind()
        End If
    End Sub

    Private Sub ChargerProchaines()
        Dim dt As New DataTable()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0252GetProchainesExecutions", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@Limite", 10)
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        litNbProchaines.Text = dt.Rows.Count.ToString()

        If dt.Rows.Count = 0 Then
            phProchainesEmpty.Visible = True
            rpProchaines.Visible = False
        Else
            phProchainesEmpty.Visible = False
            rpProchaines.Visible = True
            rpProchaines.DataSource = dt
            rpProchaines.DataBind()
        End If
    End Sub

    Private Sub ChargerActivite()
        Dim dt As New DataTable()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0253GetActiviteRecente", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@Limite", 10)
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        If dt.Rows.Count = 0 Then
            phActiviteEmpty.Visible = True
            rpActivite.Visible = False
        Else
            phActiviteEmpty.Visible = False
            rpActivite.Visible = True
            rpActivite.DataSource = dt
            rpActivite.DataBind()
        End If
    End Sub

    ' =========================================================
    '  HELPERS
    ' =========================================================

    Private Function FormatDateRelative(dt As DateTime) As String
        Dim diff = DateTime.Now - dt
        If diff.TotalSeconds < 60 Then Return T("À l'instant", "Just now", "Ahora mismo")
        If diff.TotalMinutes < 60 Then Return String.Format(T("Il y a {0} min", "{0} min ago", "hace {0} min"), Math.Round(diff.TotalMinutes))
        If diff.TotalHours < 24 Then Return String.Format(T("Il y a {0} h", "{0} h ago", "hace {0} h"), Math.Round(diff.TotalHours))
        If diff.TotalDays < 7 Then Return String.Format(T("Il y a {0} j", "{0} d ago", "hace {0} d"), Math.Round(diff.TotalDays))
        Return dt.ToString("yyyy-MM-dd")
    End Function

    Private Function FormatDateRelativeFutur(dt As DateTime) As String
        Dim diff = dt - DateTime.Now
        If diff.TotalMinutes < 1 Then Return T("Imminent", "Imminent", "Inminente")
        If diff.TotalMinutes < 60 Then Return String.Format(T("Dans {0} min", "In {0} min", "En {0} min"), Math.Round(diff.TotalMinutes))
        If diff.TotalHours < 24 Then Return String.Format(T("Dans {0} h", "In {0} h", "En {0} h"), Math.Round(diff.TotalHours, 1))
        Return String.Format(T("Dans {0} j", "In {0} d", "En {0} d"), Math.Round(diff.TotalDays))
    End Function

    Private Function FormatDureeMs(ms As Long) As String
        If ms < 1000 Then Return ms & " ms"
        If ms < 60000 Then Return String.Format("{0:0.#} s", ms / 1000.0)
        If ms < 3600000 Then Return String.Format("{0} min {1} s", ms \ 60000, (ms Mod 60000) \ 1000)
        Return String.Format("{0} h {1} min", ms \ 3600000, (ms Mod 3600000) \ 60000)
    End Function

End Class
