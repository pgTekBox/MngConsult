Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Partial Public Class wbfJobExecution
    Inherits clsData

    ' =========================================================
    '  PROPRIÉTÉS
    ' =========================================================

    Public Property ExecutionId As Integer
        Get
            Return If(ViewState("ExecId"), 0)
        End Get
        Set(value As Integer)
            ViewState("ExecId") = value
        End Set
    End Property

    Public Property JobIdContexte As Integer
        Get
            Return If(ViewState("JobIdCtx"), 0)
        End Get
        Set(value As Integer)
            ViewState("JobIdCtx") = value
            If hfJobIdCtx IsNot Nothing Then
                hfJobIdCtx.Value = value.ToString()
            End If
        End Set
    End Property

    Private Property StatutCourant As String
        Get
            Return If(ViewState("Statut"), "").ToString()
        End Get
        Set(value As String)
            ViewState("Statut") = value
        End Set
    End Property

    Private Property NiveauFiltre As String
        Get
            Return If(ViewState("NivFiltre"), "").ToString()
        End Get
        Set(value As String)
            ViewState("NivFiltre") = value
        End Set
    End Property

    ' =========================================================
    '  PAGE LIFECYCLE
    ' =========================================================

    Protected Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Sub ApplyLocalization()
        btnRetour.Text = "← " & T("Retour à l'historique", "Back to history", "Volver al historial")
        btnAnnuler.Text = T("Annuler l'exécution", "Cancel execution", "Cancelar ejecución")
        btnRelancer.Text = T("Réessayer", "Retry", "Reintentar")
        If rblNiveau.Items.Count > 0 Then
            rblNiveau.Items(0).Text = T("Tous", "All", "Todos")
        End If

        ' Libellés HTML statiques (ex-blocs <%= T(...) %>)
        litLoc01.Text = T("Détails de l'exécution", "Execution details", "Detalles de la ejecución")
        litLoc02.Text = T("Job", "Job", "Tarea")
        litLoc03.Text = T("Code", "Code", "Código")
        litLoc04.Text = T("Schedule", "Schedule", "Programación")
        litLoc05.Text = T("Trigger", "Trigger", "Disparador")
        litLoc06.Text = T("Démarré", "Started", "Iniciado")
        litLoc07.Text = T("Terminé", "Completed", "Completado")
        litLoc08.Text = T("Durée", "Duration", "Duración")
        litLoc09.Text = T("Tentative", "Attempt", "Intento")
        litLoc10.Text = T("Worker", "Worker", "Worker")
        litLoc11.Text = T("Lignes traitées", "Rows processed", "Filas procesadas")
        litLoc12.Text = T("Handler", "Handler", "Handler")
        litLoc13.Text = T("Lancée par", "Started by", "Iniciada por")
        litLoc14.Text = T("Message de résultat", "Result message", "Mensaje de resultado")
        litLoc15.Text = T("Détail technique", "Technical detail", "Detalle técnico")
        litLoc16.Text = T("Paramètres utilisés", "Parameters used", "Parámetros utilizados")
        litLoc17.Text = T("Logs détaillés", "Detailed logs", "Registros detallados")
        litLoc18.Text = T("Aucun log à afficher pour ce filtre.", "No logs to display for this filter.", "No hay registros para mostrar con este filtro.")
    End Sub

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ApplyLocalization()
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            Dim id As Integer = 0
            Integer.TryParse(Request.QueryString("Id"), id)

            If id <= 0 Then
                ShowStatus("danger", T("Paramètre Id manquant en URL.", "Missing Id parameter in URL.", "Falta el parámetro Id en la URL."))
                phHeader.Visible = False
                Return
            End If

            ExecutionId = id
            ChargerDetail(id)
            ChargerLogs(id, Nothing)
        End If
    End Sub

    ' =========================================================
    '  ÉVÉNEMENTS
    ' =========================================================

    Protected Sub rblNiveau_Changed(sender As Object, e As EventArgs)
        ' Lecture via le HiddenField (mis à jour par le JS au clic sur les tabs)
        Dim niveau = If(String.IsNullOrEmpty(hfNiveauSelected.Value), Nothing, hfNiveauSelected.Value)
        ' Fallback : lecture du RadioButtonList
        If String.IsNullOrEmpty(niveau) AndAlso Not String.IsNullOrEmpty(rblNiveau.SelectedValue) Then
            niveau = rblNiveau.SelectedValue
        End If

        NiveauFiltre = If(niveau, "")
        ChargerLogs(ExecutionId, niveau)
    End Sub

    Protected Sub btnAnnuler_Click(sender As Object, e As EventArgs)
        Try
            Using cn As New SqlConnection(ConnectionString)
                cn.Open()
                Using cmd As New SqlCommand("dbo.sp_AnnulerJobEnCours", cn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@ExecutionId", ExecutionId)
                    cmd.Parameters.AddWithValue("@UserId", UserId)
                    cmd.ExecuteNonQuery()
                End Using
            End Using

            ShowStatus("success", T("Exécution marquée comme ANNULÉE.", "Execution marked as CANCELLED.", "Ejecución marcada como CANCELADA."))
            ChargerDetail(ExecutionId)
            ChargerLogs(ExecutionId, Nothing)

        Catch sqlex As SqlException
            ShowStatus("danger", T("Erreur SQL : ", "SQL error: ", "Error SQL: ") & sqlex.Message)
        Catch ex As Exception
            ShowStatus("danger", T("Erreur : ", "Error: ", "Error: ") & ex.Message)
        End Try
    End Sub

    Protected Sub btnRelancer_Click(sender As Object, e As EventArgs)
        Try
            Dim newId As Integer = 0

            Using cn As New SqlConnection(ConnectionString)
                cn.Open()
                Using cmd As New SqlCommand("dbo.sp_RelancerJobEnEchec", cn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@ExecutionId", ExecutionId)
                    cmd.Parameters.AddWithValue("@UserId", UserId)

                    Dim outParam As New SqlParameter("@NouvelleExecutionId", SqlDbType.Int) With {
                        .Direction = ParameterDirection.Output
                    }
                    cmd.Parameters.Add(outParam)

                    cmd.ExecuteNonQuery()

                    If outParam.Value IsNot Nothing AndAlso Not Convert.IsDBNull(outParam.Value) Then
                        newId = Convert.ToInt32(outParam.Value)
                    End If
                End Using
            End Using

            If newId > 0 Then
                Response.Redirect("wbfJobExecution.aspx?Id=" & newId & "&relaunched=1")
            End If

        Catch sqlex As SqlException
            ShowStatus("danger", T("Erreur SQL : ", "SQL error: ", "Error SQL: ") & sqlex.Message)
        Catch ex As Exception
            ShowStatus("danger", T("Erreur : ", "Error: ", "Error: ") & ex.Message)
        End Try
    End Sub

    Protected Sub rpLogs_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim row = TryCast(e.Item.DataItem, DataRowView)
        If row Is Nothing Then Return

        Dim litDetail = TryCast(e.Item.FindControl("litDetailBlock"), Literal)
        Dim litToggle = TryCast(e.Item.FindControl("litToggleDetail"), Literal)

        ' Si Detail est non vide, afficher le bouton toggle + le bloc détail
        If Not Convert.IsDBNull(row("Detail")) Then
            Dim detail = row("Detail").ToString()
            If Not String.IsNullOrWhiteSpace(detail) Then
                Dim logId = row("Id").ToString()

                If litToggle IsNot Nothing Then
                    litToggle.Text = String.Format(
                        " <span class='detail-toggle' onclick=""toggleLogDetail({0})"">[{1}]</span>",
                        logId, T("détail", "detail", "detalle"))
                End If
                If litDetail IsNot Nothing Then
                    litDetail.Text = String.Format(
                        "<div class='detail-content'>{0}</div>",
                        Server.HtmlEncode(detail))
                End If
                Return
            End If
        End If

        ' Pas de détail
        If litToggle IsNot Nothing Then litToggle.Text = ""
        If litDetail IsNot Nothing Then litDetail.Text = ""
    End Sub

    ' =========================================================
    '  CHARGEMENT
    ' =========================================================

    Private Sub ChargerDetail(id As Integer)
        Dim dt As New DataTable()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0240GetExecutionDetail", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@ExecutionId", id)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        If dt.Rows.Count = 0 Then
            ShowStatus("danger", T("Exécution introuvable (Id=", "Execution not found (Id=", "Ejecución no encontrada (Id=") & id & ").")
            phHeader.Visible = False
            Return
        End If

        Dim r = dt.Rows(0)

        ' Conserver le contexte pour le bouton retour
        JobIdContexte = Convert.ToInt32(r("JobDefinitionId"))
        StatutCourant = r("Statut").ToString()

        ' ─── Bandeau d'en-tête ───
        Page.Title = T("Exécution #", "Execution #", "Ejecución #") & id & " — " & r("JobNom").ToString()

        Dim icon As String, statutClass As String
        Select Case StatutCourant
            Case "SUCCES" : icon = "✓" : statutClass = "statut-success"
            Case "ECHEC" : icon = "✗" : statutClass = "statut-danger"
            Case "TIMEOUT" : icon = "⏱" : statutClass = "statut-danger"
            Case "EN_COURS" : icon = "⟳" : statutClass = "statut-info"
            Case "ANNULE" : icon = "⊘" : statutClass = "statut-warning"
            Case Else : icon = "?" : statutClass = "statut-info"
        End Select
        litIcon.Text = icon
        divBanner.Attributes("class") = "header-banner " & statutClass

        litTitre.Text = String.Format(
            "{0} <span class='pill pill-large {1}'>{2}</span>",
            Server.HtmlEncode(r("JobNom").ToString()),
            StatutToPillClass(StatutCourant),
            StatutCourant)

        Dim metaParts As New List(Of String)()
        metaParts.Add(T("Exécution #", "Execution #", "Ejecución #") & id)
        If Not Convert.IsDBNull(r("Demarre")) Then
            metaParts.Add(T("Démarrée ", "Started ", "Iniciada ") & Convert.ToDateTime(r("Demarre")).ToString("yyyy-MM-dd HH:mm:ss"))
        End If
        If Not Convert.IsDBNull(r("DureeMs")) Then
            metaParts.Add(T("Durée ", "Duration ", "Duración ") & FormatDureeMs(Convert.ToInt64(r("DureeMs"))))
        End If
        litHeaderMeta.Text = String.Join(" • ", metaParts)

        ' ─── Boutons Annuler / Relancer ───
        btnAnnuler.Visible = (StatutCourant = "EN_COURS")
        btnRelancer.Visible = (StatutCourant = "ECHEC" OrElse StatutCourant = "TIMEOUT" OrElse StatutCourant = "ANNULE")

        ' ─── Métadonnées ───
        Dim sysBadge = ""
        If Not Convert.IsDBNull(r("JobSysteme")) AndAlso Convert.ToBoolean(r("JobSysteme")) Then
            sysBadge = " <span class='badge-systeme'>" & T("SYSTÈME", "SYSTEM", "SISTEMA") & "</span>"
        End If
        litJobNom.Text = Server.HtmlEncode(r("JobNom").ToString()) & sysBadge
        litJobCode.Text = Server.HtmlEncode(r("JobCode").ToString())

        litScheduleNom.Text = If(Convert.IsDBNull(r("ScheduleNom")), "<em style='color:#94a3b8;'>" & T("Aucun (lancement manuel)", "None (manual start)", "Ninguno (inicio manual)") & "</em>",
                                 Server.HtmlEncode(r("ScheduleNom").ToString()))
        litTrigger.Text = String.Format("<span class='pill pill-neutral'>{0}</span>", r("TriggerType"))

        litDemarre.Text = If(Convert.IsDBNull(r("Demarre")), "—",
                             Convert.ToDateTime(r("Demarre")).ToString("yyyy-MM-dd HH:mm:ss"))
        litTermine.Text = If(Convert.IsDBNull(r("Termine")),
                             "<em style='color:#94a3b8;'>" & T("En cours...", "Running...", "En curso...") & "</em>",
                             Convert.ToDateTime(r("Termine")).ToString("yyyy-MM-dd HH:mm:ss"))

        litDuree.Text = If(Convert.IsDBNull(r("DureeMs")), "—", FormatDureeMs(Convert.ToInt64(r("DureeMs"))))
        litTentative.Text = "#" & r("TentativeNumero").ToString()

        litWorker.Text = If(Convert.IsDBNull(r("WorkerName")), "—", r("WorkerName").ToString())
        litLignesTraitees.Text = If(Convert.IsDBNull(r("LignesTraitees")), "—",
                                    Convert.ToInt32(r("LignesTraitees")).ToString("N0"))

        litHandlerType.Text = String.Format("<span class='pill pill-neutral'>{0}</span>", r("HandlerType"))
        litHandlerName.Text = Server.HtmlEncode(r("HandlerName").ToString())

        litLanceePar.Text = If(Convert.IsDBNull(r("LanceePar")), "—",
                               "UserId = " & r("LanceePar").ToString())

        ' ─── Message de résultat ───
        If Not Convert.IsDBNull(r("ResultatMessage")) AndAlso
           Not String.IsNullOrWhiteSpace(r("ResultatMessage").ToString()) Then
            litResultatMessage.Text = Server.HtmlEncode(r("ResultatMessage").ToString())
            phMessage.Visible = True
        Else
            phMessage.Visible = False
        End If

        ' ─── Détail technique (stack trace) ───
        If Not Convert.IsDBNull(r("ResultatDetail")) AndAlso
           Not String.IsNullOrWhiteSpace(r("ResultatDetail").ToString()) Then
            litResultatDetail.Text = Server.HtmlEncode(r("ResultatDetail").ToString())
            divDetailBlock.Attributes("class") =
                If(StatutCourant = "ECHEC" OrElse StatutCourant = "TIMEOUT", "code-block error", "code-block")
            phDetail.Visible = True
        Else
            phDetail.Visible = False
        End If

        ' ─── Paramètres utilisés ───
        If Not Convert.IsDBNull(r("ParamsUtilises")) AndAlso
           Not String.IsNullOrWhiteSpace(r("ParamsUtilises").ToString()) Then
            litParamsUtilises.Text = Server.HtmlEncode(r("ParamsUtilises").ToString())
            phParams.Visible = True
        Else
            phParams.Visible = False
        End If
    End Sub

    Private Sub ChargerLogs(execId As Integer, niveauFiltre As String)
        Dim ds As New DataSet()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0241GetExecutionLogs", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@ExecutionId", execId)
                cmd.Parameters.AddWithValue("@FiltreNiveau",
                    If(String.IsNullOrEmpty(niveauFiltre), CObj(DBNull.Value), niveauFiltre))

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(ds)
                End Using
            End Using
        End Using

        ' Result sets : [0] compteurs, [1] logs
        ' ─── Tabs de filtre ───
        Dim nbDebug = 0, nbInfo = 0, nbWarn = 0, nbError = 0, nbTotal = 0
        If ds.Tables.Count >= 1 AndAlso ds.Tables(0).Rows.Count > 0 Then
            Dim r = ds.Tables(0).Rows(0)
            nbDebug = If(Convert.IsDBNull(r("NbDebug")), 0, Convert.ToInt32(r("NbDebug")))
            nbInfo = If(Convert.IsDBNull(r("NbInfo")), 0, Convert.ToInt32(r("NbInfo")))
            nbWarn = If(Convert.IsDBNull(r("NbWarn")), 0, Convert.ToInt32(r("NbWarn")))
            nbError = If(Convert.IsDBNull(r("NbError")), 0, Convert.ToInt32(r("NbError")))
            nbTotal = If(Convert.IsDBNull(r("NbTotal")), 0, Convert.ToInt32(r("NbTotal")))
        End If

        Dim sb As New System.Text.StringBuilder()
        sb.Append(GenererTab("", T("Tous", "All", "Todos"), nbTotal))
        If nbDebug > 0 Then sb.Append(GenererTab("DEBUG", "DEBUG", nbDebug))
        sb.Append(GenererTab("INFO", "INFO", nbInfo))
        If nbWarn > 0 Then sb.Append(GenererTab("WARN", "WARN", nbWarn))
        If nbError > 0 Then sb.Append(GenererTab("ERROR", "ERROR", nbError))
        litFilterTabs.Text = sb.ToString()

        ' ─── Liste des logs ───
        Dim dtLogs As DataTable = If(ds.Tables.Count >= 2, ds.Tables(1), New DataTable())

        If dtLogs.Rows.Count = 0 Then
            phLogsEmpty.Visible = True
            phLogsList.Visible = False
        Else
            phLogsEmpty.Visible = False
            phLogsList.Visible = True
            rpLogs.DataSource = dtLogs
            rpLogs.DataBind()
        End If
    End Sub

    Private Function GenererTab(value As String, libelle As String, count As Integer) As String
        Dim active = If(value = NiveauFiltre, " active", "")
        Dim cls = "niveau-tab tab-" & libelle & active
        Return String.Format(
            "<a href=""javascript:selectNiveau('{0}')"" class=""{1}"">" &
            "<span>{2}</span><span class=""count"">{3}</span></a>",
            value, cls, libelle, count)
    End Function

    ' =========================================================
    '  HELPERS
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

    Private Function FormatDureeMs(ms As Long) As String
        If ms < 1000 Then Return ms & " ms"
        If ms < 60000 Then Return String.Format("{0:0.#} s", ms / 1000.0)
        If ms < 3600000 Then Return String.Format("{0} min {1} s", ms \ 60000, (ms Mod 60000) \ 1000)
        Return String.Format("{0} h {1} min", ms \ 3600000, (ms Mod 3600000) \ 60000)
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
