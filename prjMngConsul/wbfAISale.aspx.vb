Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Partial Public Class wbfAISale
    Inherits clsData

    ' =========================================================
    '  PROPRIÉTÉS
    ' =========================================================

    Private Property PeriodeSel As String
        Get
            Return If(ViewState("Periode"), "3MONTHS").ToString()
        End Get
        Set(value As String)
            ViewState("Periode") = value
            If hfPeriodeSel IsNot Nothing Then hfPeriodeSel.Value = value
        End Set
    End Property

    Private Property TabSel As String
        Get
            Return If(ViewState("Tab"), "COLLECTE").ToString()
        End Get
        Set(value As String)
            ViewState("Tab") = value
            If hfTabSel IsNot Nothing Then hfTabSel.Value = value
        End Set
    End Property

    ' =========================================================
    '  PAGE LIFECYCLE
    ' =========================================================

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If


        Dim js As String = "var __dispatchTarget = '" & btnDispatchAction.UniqueID & "';"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "DispatchTarget", js, True)

        If Not IsPostBack Then
            PeriodeSel = "3MONTHS"
            TabSel = "COLLECTE"
            ChargerKpis()
            ChargerListe()
        End If

        ' Toujours rafraîchir le solde bancaire (même au postback)
        ChargerSoldeBancaire()
    End Sub

    ' =========================================================
    '  ÉVÉNEMENTS
    ' =========================================================

    Protected Sub btnDispatchAction_Click(sender As Object, e As EventArgs)
        Dim actionName = hfActionName.Value
        Dim actionArg = hfActionArg.Value

        hfActionName.Value = ""
        hfActionArg.Value = ""

        Try
            Select Case actionName
                Case "ChangePeriode"
                    PeriodeSel = actionArg
                    ChargerKpis()
                    ChargerListe()

                Case "ChangeTab"
                    TabSel = actionArg
                    ChargerListe()
            End Select

        Catch ex As Exception
            ShowStatus("danger", "Erreur : " & ex.Message)
        End Try
    End Sub

    Protected Sub rpItems_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim row = TryCast(e.Item.DataItem, DataRowView)
        If row Is Nothing Then Return

        Dim litHtml = TryCast(e.Item.FindControl("litItemHtml"), Literal)
        If litHtml Is Nothing Then Return

        Dim id = row("Id").ToString()
        Dim client = row("Client").ToString()
        Dim desc = row("Description").ToString()
        Dim dueDate As Date? = If(Convert.IsDBNull(row("DueDate")),
                                  CType(Nothing, Date?),
                                  Convert.ToDateTime(row("DueDate")))
        Dim montant = Convert.ToDecimal(row("Montant"))
        Dim statutPaiement = row("StatutPaiement").ToString()

        ' Déterminer la classe CSS du tab
        Dim tabClass = ResoudreTabClass(statutPaiement)

        ' Choisir l'icône selon la classe
        Dim iconHtml As String
        If tabClass = "collecte" Then
            iconHtml = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' " &
                       "stroke='currentColor' stroke-width='2' stroke-linecap='round' " &
                       "stroke-linejoin='round' class='item-icon collecte'>" &
                       "<path d='M22 11.08V12a10 10 0 1 1-5.93-9.14'/>" &
                       "<path d='m9 11 3 3L22 4'/></svg>"
        ElseIf tabClass = "recevoir" Then
            iconHtml = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' " &
                       "stroke='currentColor' stroke-width='2' stroke-linecap='round' " &
                       "stroke-linejoin='round' class='item-icon recevoir'>" &
                       "<circle cx='12' cy='12' r='10'/>" &
                       "<polyline points='12 6 12 12 16 14'/></svg>"
        Else
            iconHtml = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' " &
                       "stroke='currentColor' stroke-width='2' stroke-linecap='round' " &
                       "stroke-linejoin='round' class='item-icon retard'>" &
                       "<path d='m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z'/>" &
                       "<path d='M12 9v4'/><path d='M12 17h.01'/></svg>"
        End If

        Dim sb As New System.Text.StringBuilder()
        sb.AppendFormat("<div class='item-row {0}'>", tabClass)

        ' Left : icône + client + description
        sb.Append("<div class='item-left'>")
        sb.Append(iconHtml)
        sb.Append("<div class='item-info'>")
        sb.AppendFormat("<p class='client'>{0}</p>", Server.HtmlEncode(client))
        sb.AppendFormat("<p class='desc'>{0}</p>", Server.HtmlEncode(desc))
        sb.Append("</div></div>")

        ' Right : date + ID + montant
        sb.Append("<div class='item-right'>")
        If dueDate.HasValue Then
            sb.AppendFormat("<span class='item-date'>{0}</span>", dueDate.Value.ToString("yyyy-MM-dd"))
        End If
        sb.AppendFormat("<span class='item-id'>INV-{0:D4}</span>", Convert.ToInt32(id))
        sb.AppendFormat("<span class='item-amount {0}'>{1}</span>", tabClass, FormatMontant(montant))
        sb.Append("</div>")

        sb.Append("</div>")
        litHtml.Text = sb.ToString()
    End Sub

    ' =========================================================
    '  CHARGEMENT SOLDE BANCAIRE (header)
    ' =========================================================

    ''' <summary>
    ''' Récupère le BalanceCurrent du compte bancaire choisi dans les paramètres
    ''' (paramètre COMPTE_BANQUE catégorie BANCAIRE).
    ''' Chaîne : T101ParamValues.iVal → T143PlaidAccount.Id → BalanceCurrent
    ''' </summary>
    Private Sub ChargerSoldeBancaire()
        Dim sql As String = "
SELECT TOP 1
    pa.[BalanceCurrent],
    pa.[CurrencyCode],
    pa.[AccountName],
    pa.[BankName]
FROM [dbo].[T101ParamValues] pv
INNER JOIN [dbo].[T100ParamComptable] pc ON pc.[Id] = pv.[T100Id]
INNER JOIN [dbo].[T143PlaidAccount] pa   ON pa.[Id] = pv.[iVal]
WHERE pv.[CompanyGUID] = @CompanyGUID
  AND pc.[ShortName]   = 'COMPTE_BANQUE'
  AND pc.[Categorie]   = 'BANCAIRE'
  AND pa.[Active]      = 1;"

        Try
            Using cn As New SqlConnection(ConnectionString)
                cn.Open()
                Using cmd As New SqlCommand(sql, cn)
                    cmd.Parameters.Add(New SqlParameter("@CompanyGUID", Company))
                    Using rd = cmd.ExecuteReader()
                        If rd.Read() Then
                            Dim solde As Decimal = 0D
                            If Not Convert.IsDBNull(rd("BalanceCurrent")) Then
                                solde = Convert.ToDecimal(rd("BalanceCurrent"))
                            End If

                            Dim devise As String = "$"
                            If Not Convert.IsDBNull(rd("CurrencyCode")) Then
                                Dim cc = rd("CurrencyCode").ToString()
                                If cc = "USD" Then devise = "US$"
                                ' CAD ou autre → "$" reste OK
                            End If

                            litSoldeBancaire.Text = FormatMontantSolde(solde, devise)
                        Else
                            ' Aucun compte configuré
                            litSoldeBancaire.Text = "Non configuré"
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            litSoldeBancaire.Text = "—"
        End Try
    End Sub

    ''' <summary>
    ''' Format avec 2 décimales (style "48 320,55 $") pour le solde bancaire.
    ''' Différent de FormatMontant qui utilise N0 (sans décimales) pour les sous-totaux.
    ''' </summary>
    Private Function FormatMontantSolde(m As Decimal, devise As String) As String
        Return m.ToString("N2", System.Globalization.CultureInfo.GetCultureInfo("fr-CA")) & " " & devise
    End Function

    ''' <summary>
    ''' Une seule requête SQL qui ramène les 4×3 = 12 sous-totaux
    ''' (Today/Week/Month/3Months × Collecté/Recevoir/Retard).
    ''' </summary>
    Private Sub ChargerKpis()
        Dim sql As String = "
DECLARE @T DATE = CAST(GETDATE() AS DATE);

WITH Periodes AS (
    SELECT v.[Id], v.[Montant], v.[StatutPaiement],
           ABS(DATEDIFF(DAY, @T, ISNULL(v.[DueDate], v.[DateExecutionPrevue]))) AS DiffDays
    FROM [dbo].[vwAISales] v
)
SELECT
    -- Compteurs (nombre de ventes par période)
    SUM(CASE WHEN DiffDays <= 1  THEN 1 ELSE 0 END) AS NbToday,
    SUM(CASE WHEN DiffDays <= 7  THEN 1 ELSE 0 END) AS NbWeek,
    SUM(CASE WHEN DiffDays <= 30 THEN 1 ELSE 0 END) AS NbMonth,
    SUM(CASE WHEN DiffDays <= 90 THEN 1 ELSE 0 END) AS Nb3M,

    -- TODAY × 3 statuts
    SUM(CASE WHEN DiffDays <= 1 AND StatutPaiement = 'PAYEE'                                  THEN Montant ELSE 0 END) AS TodayCollecte,
    SUM(CASE WHEN DiffDays <= 1 AND StatutPaiement IN ('OUVERTE','IN_PROGRESS','PARTIELLE')   THEN Montant ELSE 0 END) AS TodayRecevoir,
    SUM(CASE WHEN DiffDays <= 1 AND StatutPaiement = 'EN_RETARD'                              THEN Montant ELSE 0 END) AS TodayRetard,

    -- WEEK × 3 statuts
    SUM(CASE WHEN DiffDays <= 7 AND StatutPaiement = 'PAYEE'                                  THEN Montant ELSE 0 END) AS WeekCollecte,
    SUM(CASE WHEN DiffDays <= 7 AND StatutPaiement IN ('OUVERTE','IN_PROGRESS','PARTIELLE')   THEN Montant ELSE 0 END) AS WeekRecevoir,
    SUM(CASE WHEN DiffDays <= 7 AND StatutPaiement = 'EN_RETARD'                              THEN Montant ELSE 0 END) AS WeekRetard,

    -- MONTH × 3 statuts
    SUM(CASE WHEN DiffDays <= 30 AND StatutPaiement = 'PAYEE'                                 THEN Montant ELSE 0 END) AS MonthCollecte,
    SUM(CASE WHEN DiffDays <= 30 AND StatutPaiement IN ('OUVERTE','IN_PROGRESS','PARTIELLE')  THEN Montant ELSE 0 END) AS MonthRecevoir,
    SUM(CASE WHEN DiffDays <= 30 AND StatutPaiement = 'EN_RETARD'                             THEN Montant ELSE 0 END) AS MonthRetard,

    -- 3 MONTHS × 3 statuts
    SUM(CASE WHEN DiffDays <= 90 AND StatutPaiement = 'PAYEE'                                 THEN Montant ELSE 0 END) AS M3Collecte,
    SUM(CASE WHEN DiffDays <= 90 AND StatutPaiement IN ('OUVERTE','IN_PROGRESS','PARTIELLE')  THEN Montant ELSE 0 END) AS M3Recevoir,
    SUM(CASE WHEN DiffDays <= 90 AND StatutPaiement = 'EN_RETARD'                             THEN Montant ELSE 0 END) AS M3Retard
FROM Periodes;"

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand(sql, cn)
                Using rd = cmd.ExecuteReader()
                    If rd.Read() Then
                        ' Compteurs
                        litTodayCount.Text = GetIntSafe(rd, "NbToday").ToString()
                        litWeekCount.Text = GetIntSafe(rd, "NbWeek").ToString()
                        litMonthCount.Text = GetIntSafe(rd, "NbMonth").ToString()
                        lit3MCount.Text = GetIntSafe(rd, "Nb3M").ToString()

                        ' Today
                        litTodayCollecte.Text = FormatMontant(GetDecSafe(rd, "TodayCollecte"))
                        litTodayRecevoir.Text = FormatMontant(GetDecSafe(rd, "TodayRecevoir"))
                        litTodayRetard.Text = FormatMontant(GetDecSafe(rd, "TodayRetard"))

                        ' Week
                        litWeekCollecte.Text = FormatMontant(GetDecSafe(rd, "WeekCollecte"))
                        litWeekRecevoir.Text = FormatMontant(GetDecSafe(rd, "WeekRecevoir"))
                        litWeekRetard.Text = FormatMontant(GetDecSafe(rd, "WeekRetard"))

                        ' Month
                        litMonthCollecte.Text = FormatMontant(GetDecSafe(rd, "MonthCollecte"))
                        litMonthRecevoir.Text = FormatMontant(GetDecSafe(rd, "MonthRecevoir"))
                        litMonthRetard.Text = FormatMontant(GetDecSafe(rd, "MonthRetard"))

                        ' 3 Months
                        lit3MCollecte.Text = FormatMontant(GetDecSafe(rd, "M3Collecte"))
                        lit3MRecevoir.Text = FormatMontant(GetDecSafe(rd, "M3Recevoir"))
                        lit3MRetard.Text = FormatMontant(GetDecSafe(rd, "M3Retard"))
                    End If
                End Using
            End Using
        End Using

        AppliquerActive()
        litPeriodeLabel.Text = LibellePeriode(PeriodeSel)
    End Sub

    Private Sub AppliquerActive()
        Dim btns = New HtmlControls.HtmlAnchor() {
            btnPeriodToday, btnPeriodWeek, btnPeriodMonth, btnPeriod3M
        }
        For Each b In btns
            b.Attributes("class") = "period-btn"
        Next

        Dim activeBtn As HtmlControls.HtmlAnchor = Nothing
        Select Case PeriodeSel
            Case "TODAY" : activeBtn = btnPeriodToday
            Case "WEEK" : activeBtn = btnPeriodWeek
            Case "MONTH" : activeBtn = btnPeriodMonth
            Case "3MONTHS" : activeBtn = btnPeriod3M
        End Select
        If activeBtn IsNot Nothing Then
            activeBtn.Attributes("class") = "period-btn active"
        End If
    End Sub

    ' =========================================================
    '  CHARGEMENT LISTE (selon Période + Tab)
    ' =========================================================

    Private Sub ChargerListe()
        Dim borneFin As Integer
        Select Case PeriodeSel
            Case "TODAY" : borneFin = 1
            Case "WEEK" : borneFin = 7
            Case "MONTH" : borneFin = 30
            Case Else : borneFin = 90
        End Select

        ' Filtre selon le tab
        Dim filtreStatut As String
        Select Case TabSel
            Case "COLLECTE"
                filtreStatut = "v.[StatutPaiement] = 'PAYEE'"
            Case "RECEVOIR"
                filtreStatut = "v.[StatutPaiement] IN ('OUVERTE','IN_PROGRESS','PARTIELLE')"
            Case Else  ' RETARD
                filtreStatut = "v.[StatutPaiement] = 'EN_RETARD'"
        End Select

        Dim sql As String = "
SELECT
    v.[Id]                                  AS Id,
    ISNULL(v.[Beneficiaire], '')            AS Client,
    ISNULL(v.[Description], v.[Nom])        AS Description,
    v.[DueDate]                             AS DueDate,
    ISNULL(v.[Montant], 0)                  AS Montant,
    ISNULL(v.[StatutPaiement], 'OUVERTE')   AS StatutPaiement
FROM [dbo].[vwAISales] v
WHERE ABS(DATEDIFF(DAY, CAST(GETDATE() AS DATE),
                   ISNULL(v.[DueDate], v.[DateExecutionPrevue]))) <= " & borneFin & "
  AND " & filtreStatut & "
ORDER BY ISNULL(v.[DueDate], v.[DateExecutionPrevue]) DESC;"

        Dim dt As New DataTable()
        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand(sql, cn)
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        rpItems.DataSource = dt
        rpItems.DataBind()
        phEmpty.Visible = (dt.Rows.Count = 0)

        ' Compteurs des tabs (pour la période sélectionnée)
        ChargerCompteursTabs(borneFin)

        ' État visuel actif des tabs
        AppliquerActiveTab()
    End Sub

    Private Sub ChargerCompteursTabs(borneFin As Integer)
        Dim sql As String = "
SELECT
    SUM(CASE WHEN v.[StatutPaiement] = 'PAYEE' THEN 1 ELSE 0 END)                                 AS NbCollecte,
    SUM(CASE WHEN v.[StatutPaiement] IN ('OUVERTE','IN_PROGRESS','PARTIELLE') THEN 1 ELSE 0 END)  AS NbRecevoir,
    SUM(CASE WHEN v.[StatutPaiement] = 'EN_RETARD' THEN 1 ELSE 0 END)                             AS NbRetard
FROM [dbo].[vwAISales] v
WHERE ABS(DATEDIFF(DAY, CAST(GETDATE() AS DATE),
                   ISNULL(v.[DueDate], v.[DateExecutionPrevue]))) <= " & borneFin & ";"

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand(sql, cn)
                Using rd = cmd.ExecuteReader()
                    If rd.Read() Then
                        litTabCollecteCount.Text = GetIntSafe(rd, "NbCollecte").ToString()
                        litTabRecevoirCount.Text = GetIntSafe(rd, "NbRecevoir").ToString()
                        litTabRetardCount.Text = GetIntSafe(rd, "NbRetard").ToString()
                    End If
                End Using
            End Using
        End Using
    End Sub

    Private Sub AppliquerActiveTab()
        Dim tabs = New HtmlControls.HtmlAnchor() {tabCollecte, tabRecevoir, tabRetard}
        Dim baseClasses = New String() {"tab-btn collecte", "tab-btn recevoir", "tab-btn retard"}

        For i = 0 To 2
            tabs(i).Attributes("class") = baseClasses(i)
        Next

        Select Case TabSel
            Case "COLLECTE" : tabCollecte.Attributes("class") = "tab-btn collecte active"
            Case "RECEVOIR" : tabRecevoir.Attributes("class") = "tab-btn recevoir active"
            Case "RETARD" : tabRetard.Attributes("class") = "tab-btn retard active"
        End Select
    End Sub

    ' =========================================================
    '  HELPERS
    ' =========================================================

    Private Function ResoudreTabClass(statutPaiement As String) As String
        Select Case statutPaiement
            Case "PAYEE" : Return "collecte"
            Case "EN_RETARD" : Return "retard"
            Case Else : Return "recevoir"  ' OUVERTE, IN_PROGRESS, PARTIELLE
        End Select
    End Function

    Private Function FormatMontant(m As Decimal) As String
        Return m.ToString("N0", System.Globalization.CultureInfo.GetCultureInfo("fr-CA")) & " $"
    End Function

    Private Function LibellePeriode(periode As String) As String
        Select Case periode
            Case "TODAY" : Return "Today"
            Case "WEEK" : Return "Week"
            Case "MONTH" : Return "Month"
            Case "3MONTHS" : Return "3 Months"
            Case Else : Return periode
        End Select
    End Function

    Private Function GetIntSafe(rd As SqlDataReader, col As String) As Integer
        Dim val = rd(col)
        If Convert.IsDBNull(val) Then Return 0
        Return Convert.ToInt32(val)
    End Function

    Private Function GetDecSafe(rd As SqlDataReader, col As String) As Decimal
        Dim val = rd(col)
        If Convert.IsDBNull(val) Then Return 0D
        Return Convert.ToDecimal(val)
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
