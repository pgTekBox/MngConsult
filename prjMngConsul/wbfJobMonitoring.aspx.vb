Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Partial Public Class wbfJobMonitoring
    Inherits clsData

    Private Const PAGE_SIZE As Integer = 25

    ' =========================================================
    '  ÉTAT (ViewState)
    ' =========================================================

    Private Property PageNumber As Integer
        Get
            Return If(ViewState("PageNum"), 1)
        End Get
        Set(value As Integer)
            ViewState("PageNum") = Math.Max(1, value)
        End Set
    End Property

    Private Property TotalLignes As Integer
        Get
            Return If(ViewState("TotLignes"), 0)
        End Get
        Set(value As Integer)
            ViewState("TotLignes") = value
        End Set
    End Property

    ' =========================================================
    '  PAGE LIFECYCLE
    ' =========================================================

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then

            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If

            ChargerJobsCombo()

            ' Filtre pré-rempli depuis QueryString si ?JobId=N
            Dim jobIdStr = Request.QueryString("JobId")
            If Not String.IsNullOrEmpty(jobIdStr) Then
                Dim it = ddlJob.FindItemByValue(jobIdStr)
                If it IsNot Nothing Then it.Selected = True
            End If

            ' Période par défaut : 30 derniers jours
            dpDateDebut.SelectedDate = Date.Today.AddDays(-30)
            dpDateFin.SelectedDate = Date.Today

            ChargerKpis()
            ChargerExecutions()
        End If
    End Sub

    ' =========================================================
    '  ÉVÉNEMENTS
    ' =========================================================

    Protected Sub Filtre_Changed(sender As Object, e As EventArgs)
        PageNumber = 1
        ChargerKpis()
        ChargerExecutions()
    End Sub

    Protected Sub btnFiltrer_Click(sender As Object, e As EventArgs)
        PageNumber = 1
        ChargerKpis()
        ChargerExecutions()
    End Sub

    Protected Sub btnReset_Click(sender As Object, e As EventArgs)
        ddlJob.ClearSelection()
        ddlStatut.SelectedValue = ""
        ddlTrigger.SelectedValue = ""
        dpDateDebut.SelectedDate = Date.Today.AddDays(-30)
        dpDateFin.SelectedDate = Date.Today
        PageNumber = 1
        ChargerKpis()
        ChargerExecutions()
    End Sub

    Protected Sub btnPagPrev_Click(sender As Object, e As EventArgs)
        If PageNumber > 1 Then
            PageNumber -= 1
            ChargerExecutions()
        End If
    End Sub

    Protected Sub btnPagNext_Click(sender As Object, e As EventArgs)
        Dim totalPages = NbPagesTotal()
        If PageNumber < totalPages Then
            PageNumber += 1
            ChargerExecutions()
        End If
    End Sub

    Protected Sub rpExecutions_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim row = TryCast(e.Item.DataItem, DataRowView)
        If row Is Nothing Then Return

        ' ─── Pill de statut ───
        Dim litPill = TryCast(e.Item.FindControl("litStatutPill"), Literal)
        If litPill IsNot Nothing Then
            Dim statut = If(Convert.IsDBNull(row("Statut")), "", row("Statut").ToString())
            litPill.Text = String.Format("<span class='pill {0}'>{1}</span>",
                StatutToPillClass(statut), Server.HtmlEncode(statut))
        End If

        ' ─── Trigger badge ───
        Dim litTrig = TryCast(e.Item.FindControl("litTriggerBadge"), Literal)
        If litTrig IsNot Nothing Then
            Dim trig = If(Convert.IsDBNull(row("TriggerType")), "", row("TriggerType").ToString())
            litTrig.Text = String.Format("<span class='trigger-badge trigger-{0}'>{0}</span>", trig)
        End If

        ' ─── Durée formatée ───
        Dim litDuree = TryCast(e.Item.FindControl("litDuree"), Literal)
        If litDuree IsNot Nothing Then
            litDuree.Text = FormatDuree(row("DureeMs"))
        End If

        ' ─── Format relatif de la date démarrage ───
        Dim litRel = TryCast(e.Item.FindControl("litRelative"), Literal)
        If litRel IsNot Nothing Then
            If Not Convert.IsDBNull(row("Demarre")) Then
                Dim dt = Convert.ToDateTime(row("Demarre"))
                litRel.Text = FormatDateRelative(dt)
            End If
        End If
    End Sub

    Protected Sub rpExecutions_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName = "Detail" Then
            Response.Redirect("wbfJobExecution.aspx?Id=" & e.CommandArgument.ToString())
        End If
    End Sub

    ' =========================================================
    '  CHARGEMENT
    ' =========================================================

    Private Sub ChargerJobsCombo()
        ddlJob.Items.Clear()
        ddlJob.Items.Add(New RadComboBoxItem("Tous les jobs", ""))

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0232GetJobsCombo", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)

                Using rdr = cmd.ExecuteReader()
                    While rdr.Read()
                        ddlJob.Items.Add(New RadComboBoxItem(
                            rdr("Nom").ToString() & " (" & rdr("JobCode").ToString() & ")",
                            rdr("Id").ToString()))
                    End While
                End Using
            End Using
        End Using
    End Sub

    Private Sub ChargerKpis()
        Dim dt As New DataTable()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0231GetMonitoringKpis", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@JobId", FiltreJobId())
                cmd.Parameters.AddWithValue("@DateDebut", FiltreDateDebut())
                cmd.Parameters.AddWithValue("@DateFin", FiltreDateFin())
                cmd.Parameters.AddWithValue("@WorkerName", DBNull.Value)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        If dt.Rows.Count = 0 Then Return

        Dim r = dt.Rows(0)
        Dim total = If(Convert.IsDBNull(r("TotalExecutions")), 0, Convert.ToInt32(r("TotalExecutions")))
        Dim succes = If(Convert.IsDBNull(r("NbSucces")), 0, Convert.ToInt32(r("NbSucces")))
        Dim echecs = If(Convert.IsDBNull(r("NbEchecs")), 0, Convert.ToInt32(r("NbEchecs")))
        Dim timeouts = If(Convert.IsDBNull(r("NbTimeouts")), 0, Convert.ToInt32(r("NbTimeouts")))
        Dim enCours = If(Convert.IsDBNull(r("NbEnCours")), 0, Convert.ToInt32(r("NbEnCours")))
        Dim dureeMoy = If(Convert.IsDBNull(r("DureeMoyMs")), 0, Convert.ToInt64(r("DureeMoyMs")))

        litKpiTotal.Text = total.ToString("N0")
        litKpiSucces.Text = succes.ToString("N0")
        litKpiEchecs.Text = (echecs + timeouts).ToString("N0")
        litKpiEnCours.Text = enCours.ToString("N0")
        litKpiDureeMoy.Text = If(dureeMoy = 0, "—", FormatDureeMs(dureeMoy))

        If total > 0 Then
            litKpiSuccesPct.Text = String.Format("{0:0.#}%", (succes * 100.0) / total)
            litKpiEchecsPct.Text = String.Format("{0:0.#}%", ((echecs + timeouts) * 100.0) / total)
        Else
            litKpiSuccesPct.Text = ""
            litKpiEchecsPct.Text = ""
        End If
    End Sub

    Private Sub ChargerExecutions()
        Dim ds As New DataSet()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0230GetExecutionsHistorique", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@JobId", FiltreJobId())
                cmd.Parameters.AddWithValue("@Statut", FiltreStatut())
                cmd.Parameters.AddWithValue("@TriggerType", FiltreTrigger())
                cmd.Parameters.AddWithValue("@DateDebut", FiltreDateDebut())
                cmd.Parameters.AddWithValue("@DateFin", FiltreDateFin())
                cmd.Parameters.AddWithValue("@WorkerName", DBNull.Value)
                cmd.Parameters.AddWithValue("@PageSize", PAGE_SIZE)
                cmd.Parameters.AddWithValue("@PageNumber", PageNumber)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(ds)
                End Using
            End Using
        End Using

        ' Result sets : [0] Total, [1] Page de résultats
        If ds.Tables.Count >= 1 AndAlso ds.Tables(0).Rows.Count > 0 Then
            TotalLignes = Convert.ToInt32(ds.Tables(0).Rows(0)("TotalLignes"))
        Else
            TotalLignes = 0
        End If

        Dim dtPage As DataTable = If(ds.Tables.Count >= 2, ds.Tables(1), New DataTable())

        If dtPage.Rows.Count = 0 Then
            phEmpty.Visible = True
            phTable.Visible = False
        Else
            phEmpty.Visible = False
            phTable.Visible = True
            rpExecutions.DataSource = dtPage
            rpExecutions.DataBind()
            MajPagination()
        End If
    End Sub

    Private Sub MajPagination()
        Dim totalPages = NbPagesTotal()
        Dim pageStart = ((PageNumber - 1) * PAGE_SIZE) + 1
        Dim pageEnd = Math.Min(PageNumber * PAGE_SIZE, TotalLignes)

        litPagInfo.Text = String.Format(
            "Affichage {0:N0} – {1:N0} sur {2:N0} exécutions",
            pageStart, pageEnd, TotalLignes)

        ' Boutons Prev/Next
        btnPagPrev.Enabled = (PageNumber > 1)
        btnPagPrev.Style("opacity") = If(PageNumber > 1, "1", "0.4")
        btnPagPrev.Style("pointer-events") = If(PageNumber > 1, "auto", "none")

        btnPagNext.Enabled = (PageNumber < totalPages)
        btnPagNext.Style("opacity") = If(PageNumber < totalPages, "1", "0.4")
        btnPagNext.Style("pointer-events") = If(PageNumber < totalPages, "auto", "none")

        ' Indicateur de page courante (entre les boutons Prev/Next)
        litPagPages.Text = String.Format(
            "<span class='page-btn active'>Page {0} / {1}</span>",
            PageNumber, totalPages)
    End Sub

    Private Function NbPagesTotal() As Integer
        If TotalLignes = 0 Then Return 1
        Return CInt(Math.Ceiling(TotalLignes / CDbl(PAGE_SIZE)))
    End Function

    ' =========================================================
    '  HELPERS DE FILTRES
    ' =========================================================

    Private Function FiltreJobId() As Object
        If String.IsNullOrEmpty(ddlJob.SelectedValue) Then Return DBNull.Value
        Return Convert.ToInt32(ddlJob.SelectedValue)
    End Function

    Private Function FiltreStatut() As Object
        If String.IsNullOrEmpty(ddlStatut.SelectedValue) Then Return DBNull.Value
        Return ddlStatut.SelectedValue
    End Function

    Private Function FiltreTrigger() As Object
        If String.IsNullOrEmpty(ddlTrigger.SelectedValue) Then Return DBNull.Value
        Return ddlTrigger.SelectedValue
    End Function

    Private Function FiltreDateDebut() As Object
        If Not dpDateDebut.SelectedDate.HasValue Then Return DBNull.Value
        Return dpDateDebut.SelectedDate.Value
    End Function

    Private Function FiltreDateFin() As Object
        If Not dpDateFin.SelectedDate.HasValue Then Return DBNull.Value
        ' Inclure toute la journée
        Return dpDateFin.SelectedDate.Value.AddDays(1).AddSeconds(-1)
    End Function

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

    Private Function FormatDuree(ms As Object) As String
        If ms Is Nothing OrElse Convert.IsDBNull(ms) Then Return "—"
        Return FormatDureeMs(Convert.ToInt64(ms))
    End Function

    Private Function FormatDureeMs(ms As Long) As String
        If ms < 1000 Then Return ms & " ms"
        If ms < 60000 Then Return String.Format("{0:0.#} s", ms / 1000.0)
        If ms < 3600000 Then Return String.Format("{0} min {1} s", ms \ 60000, (ms Mod 60000) \ 1000)
        Return String.Format("{0} h {1} min", ms \ 3600000, (ms Mod 3600000) \ 60000)
    End Function

    Private Function FormatDateRelative(dt As DateTime) As String
        Dim diff = DateTime.Now - dt
        If diff.TotalSeconds < 60 Then Return "À l'instant"
        If diff.TotalMinutes < 60 Then Return String.Format("Il y a {0} min", Math.Round(diff.TotalMinutes))
        If diff.TotalHours < 24 Then Return String.Format("Il y a {0} h", Math.Round(diff.TotalHours))
        If diff.TotalDays < 7 Then Return String.Format("Il y a {0} j", Math.Round(diff.TotalDays))
        Return dt.ToString("yyyy-MM-dd")
    End Function

End Class
