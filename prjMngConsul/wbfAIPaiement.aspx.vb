Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Partial Public Class wbfAIPaiement
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

    ' Note : CategorieOuverte n'est plus géré côté serveur — c'est purement JS via hfCategorieOpen

    ' =========================================================
    '  PAGE LIFECYCLE
    ' =========================================================

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Injecter le UniqueID du dispatcher pour le JS
        Dim js As String = "var __dispatchTarget = '" & btnDispatchAction.UniqueID & "';"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "DispatchTarget", js, True)

        If Not IsPostBack Then
            PeriodeSel = "3MONTHS"
            ' La catégorie ouverte par défaut (Fournisseur) est gérée côté client via hfCategorieOpen
            ChargerKpis()
            ChargerCategories()
        End If
    End Sub

    ' =========================================================
    '  ÉVÉNEMENTS
    ' =========================================================

    Protected Sub rblPeriode_Changed(sender As Object, e As EventArgs)
        PeriodeSel = rblPeriode.SelectedValue
        ChargerKpis()
        ChargerCategories()
    End Sub

    Protected Sub btnDispatchAction_Click(sender As Object, e As EventArgs)
        Dim actionName = hfActionName.Value
        Dim actionArg = hfActionArg.Value

        ' Reset pour éviter rejouer si autre postback
        hfActionName.Value = ""
        hfActionArg.Value = ""

        Try
            Select Case actionName
                Case "PayerTout"
                    ShowStatus("success",
                        "Paiement groupé déclenché pour la catégorie " & actionArg &
                        ". (Action à brancher au backend.)")
                    ChargerKpis()
                    ChargerCategories()

                Case "PayerLigne"
                    ShowStatus("success",
                        "Paiement déclenché pour la transaction Id=" & actionArg &
                        ". (Action à brancher au backend.)")
                    ChargerKpis()
                    ChargerCategories()
            End Select

        Catch ex As Exception
            ShowStatus("danger", "Erreur : " & ex.Message)
        End Try
    End Sub

    Protected Sub rpCategories_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim row = TryCast(e.Item.DataItem, DataRowView)
        If row Is Nothing Then Return

        Dim litHtml = TryCast(e.Item.FindControl("litCategorieHtml"), Literal)
        If litHtml Is Nothing Then Return

        Dim categorieNom = row("CategorieNom").ToString()
        Dim nbPaiements = Convert.ToInt32(row("NbPaiements"))
        Dim totalMontant = Convert.ToDecimal(row("TotalMontant"))
        Dim transactions = TryCast(row("Transactions"), DataTable)

        Dim catKey = ResoudreCleCategorie(categorieNom)
        ' L'état "expanded" est appliqué par le JS au chargement, pas côté serveur
        Dim cardClass = "category-card cat-" & catKey

        Dim sb As New System.Text.StringBuilder()
        sb.Append("<div class='" & cardClass & "'>")

        ' ─── Header (clic = toggle JS pur, sans postback) ───
        sb.Append("<div class='category-header' onclick=""toggleCategory(this); return false;"" style='cursor:pointer;'>")

        sb.Append("<div class='category-header-left'>")
        sb.AppendFormat("<div class='category-icon cat-{0}'>{1}</div>", catKey, GetIconCategorie(catKey))
        sb.Append("<div class='category-info'>")
        sb.AppendFormat("<h4>{0}</h4>", Server.HtmlEncode(categorieNom))
        sb.AppendFormat("<p>{0} paiement{1} en attente</p>", nbPaiements, If(nbPaiements > 1, "s", ""))
        sb.Append("</div></div>")

        sb.Append("<div class='category-header-right'>")
        sb.Append("<div class='category-total'>")
        sb.Append("<p class='label'>Total à payer</p>")
        sb.AppendFormat("<p class='value'>{0}</p>", FormatMontant(totalMontant))
        sb.Append("</div>")
        sb.AppendFormat("<span class='category-badge cat-{0}'>{1} à traiter</span>", catKey, nbPaiements)
        sb.Append("<svg xmlns='http://www.w3.org/2000/svg' class='chevron' " &
                  "viewBox='0 0 24 24' fill='none' stroke='currentColor' " &
                  "stroke-width='2' stroke-linecap='round' stroke-linejoin='round'>" &
                  "<path d='m6 9 6 6 6-6'/></svg>")
        sb.Append("</div>")  ' /header-right
        sb.Append("</div>")  ' /header

        ' ─── Body TOUJOURS rendu (CSS gère l'affichage selon la classe expanded) ───
        If transactions IsNot Nothing AndAlso transactions.Rows.Count > 0 Then
            sb.Append("<div class='category-body'>")

            ' Bar avec bouton "Payer tout"
            sb.Append("<div class='category-bar'>")
            sb.AppendFormat("<p class='info'>{0} transaction{1} — {2}</p>",
                            transactions.Rows.Count,
                            If(transactions.Rows.Count > 1, "s", ""),
                            LibellePeriode(PeriodeSel))

            Dim safeArg = categorieNom.Replace("\", "\\").Replace("'", "\'")
            Dim safeMontant = FormatMontant(totalMontant).Replace("'", "\'")
            Dim confirmJs = String.Format(
                "if (confirmPayerTout('{0}')) {{ dispatchAction('PayerTout','{1}'); }} return false;",
                safeMontant, safeArg)
            sb.AppendFormat("<button type='button' class='pay-all-btn cat-{0}' onclick=""{1}"">",
                            catKey, confirmJs)
            sb.Append("<svg xmlns='http://www.w3.org/2000/svg' width='14' height='14' " &
                      "viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' " &
                      "stroke-linecap='round' stroke-linejoin='round'>" &
                      "<path d='M20 6 9 17l-5-5'/></svg>")
            sb.Append("Payer tout</button>")
            sb.Append("</div>")  ' /bar

            ' Tableau
            sb.Append("<div style='overflow-x:auto;'>")
            sb.Append("<table class='pay-table'>")
            sb.Append("<thead><tr>" &
                      "<th>ID</th>" &
                      "<th>Description</th>" &
                      "<th>Bénéficiaire</th>" &
                      "<th>Échéance</th>" &
                      "<th class='right'>Montant</th>" &
                      "<th class='center'>Action</th>" &
                      "</tr></thead><tbody>")

            For Each t As DataRow In transactions.Rows
                Dim id = t("Id").ToString()
                Dim desc = If(Convert.IsDBNull(t("Description")), t("Nom").ToString(),
                              If(String.IsNullOrEmpty(t("Description").ToString()), t("Nom").ToString(), t("Description").ToString()))
                Dim benef = If(Convert.IsDBNull(t("Beneficiaire")), "—", t("Beneficiaire").ToString())
                Dim dateEch = If(Convert.IsDBNull(t("DateExecutionPrevue")), "—",
                                 Convert.ToDateTime(t("DateExecutionPrevue")).ToString("yyyy-MM-dd"))
                Dim montant = If(Convert.IsDBNull(t("Montant")), 0D, Convert.ToDecimal(t("Montant")))

                Dim payJs = BuildDispatchJs("PayerLigne", id)

                sb.Append("<tr>")
                sb.AppendFormat("<td><span class='id-badge'>{0}-{1:D3}</span></td>", catKey.ToUpper(), Convert.ToInt32(id))
                sb.AppendFormat("<td><span class='desc'>{0}</span></td>", Server.HtmlEncode(desc))
                sb.AppendFormat("<td>{0}</td>", Server.HtmlEncode(benef))
                sb.AppendFormat("<td>{0}</td>", dateEch)
                sb.AppendFormat("<td class='amount'>{0}</td>", FormatMontant(montant))
                sb.AppendFormat("<td class='action-cell'>" &
                                "<button type='button' class='pay-btn cat-{0}' onclick=""{1}"">" &
                                "<svg xmlns='http://www.w3.org/2000/svg' width='14' height='14' " &
                                "viewBox='0 0 24 24' fill='none' stroke='currentColor' " &
                                "stroke-width='2' stroke-linecap='round' stroke-linejoin='round'>" &
                                "<line x1='12' x2='12' y1='2' y2='22'/>" &
                                "<path d='M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6'/>" &
                                "</svg>Payer</button></td>",
                                catKey, payJs)
                sb.Append("</tr>")
            Next

            sb.Append("</tbody></table>")
            sb.Append("</div>")  ' /overflow
            sb.Append("</div>")  ' /body
        End If

        sb.Append("</div>")  ' /category-card
        litHtml.Text = sb.ToString()
    End Sub

    ' =========================================================
    '  CHARGEMENT DES DONNÉES
    ' =========================================================

    Private Sub ChargerKpis()
        Dim sql As String = "
SELECT
    [Period]      = CASE
                        WHEN v.[DateExecutionPrevue] >= CAST(GETDATE() AS DATE)
                         AND v.[DateExecutionPrevue] <  DATEADD(DAY, 1, CAST(GETDATE() AS DATE))
                            THEN 'TODAY'
                        WHEN v.[DateExecutionPrevue] >= CAST(GETDATE() AS DATE)
                         AND v.[DateExecutionPrevue] <  DATEADD(DAY, 7, CAST(GETDATE() AS DATE))
                            THEN 'WEEK'
                        WHEN v.[DateExecutionPrevue] >= CAST(GETDATE() AS DATE)
                         AND v.[DateExecutionPrevue] <  DATEADD(MONTH, 1, CAST(GETDATE() AS DATE))
                            THEN 'MONTH'
                        WHEN v.[DateExecutionPrevue] >= CAST(GETDATE() AS DATE)
                         AND v.[DateExecutionPrevue] <  DATEADD(MONTH, 3, CAST(GETDATE() AS DATE))
                            THEN '3MONTHS'
                        ELSE 'OTHER'
                    END,
    v.[Category]  AS CategorieNom,
    COUNT(*)      AS NbPaiements,
    SUM(ISNULL(v.[Montant], 0)) AS Total
FROM [dbo].[vwAiPaiement] v
WHERE v.[DateExecutionPrevue] >= CAST(GETDATE() AS DATE)
GROUP BY
    CASE
        WHEN v.[DateExecutionPrevue] >= CAST(GETDATE() AS DATE)
         AND v.[DateExecutionPrevue] <  DATEADD(DAY, 1, CAST(GETDATE() AS DATE))
            THEN 'TODAY'
        WHEN v.[DateExecutionPrevue] >= CAST(GETDATE() AS DATE)
         AND v.[DateExecutionPrevue] <  DATEADD(DAY, 7, CAST(GETDATE() AS DATE))
            THEN 'WEEK'
        WHEN v.[DateExecutionPrevue] >= CAST(GETDATE() AS DATE)
         AND v.[DateExecutionPrevue] <  DATEADD(MONTH, 1, CAST(GETDATE() AS DATE))
            THEN 'MONTH'
        WHEN v.[DateExecutionPrevue] >= CAST(GETDATE() AS DATE)
         AND v.[DateExecutionPrevue] <  DATEADD(MONTH, 3, CAST(GETDATE() AS DATE))
            THEN '3MONTHS'
        ELSE 'OTHER'
    END,
    v.[Category];"

        Dim dt As New DataTable()
        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand(sql, cn)
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        ' Initialiser tous les compteurs à 0
        Dim compteurs As New Dictionary(Of String, Integer)
        Dim totaux As New Dictionary(Of String, Decimal)
        For Each periode In {"TODAY", "WEEK", "MONTH", "3MONTHS"}
            For Each cat In {"Gouvernemental", "Fournisseur", "Employé"}
                compteurs(periode & "_" & cat) = 0
                totaux(periode & "_" & cat) = 0D
            Next
        Next

        ' Périodes cumulatives (Today ⊆ Week ⊆ Month ⊆ 3Months)
        For Each r As DataRow In dt.Rows
            Dim periode = r("Period").ToString()
            Dim cat = r("CategorieNom").ToString()
            Dim nb = Convert.ToInt32(r("NbPaiements"))
            Dim tot = Convert.ToDecimal(r("Total"))

            Dim periodes = New List(Of String)
            Select Case periode
                Case "TODAY" : periodes.AddRange({"TODAY", "WEEK", "MONTH", "3MONTHS"})
                Case "WEEK" : periodes.AddRange({"WEEK", "MONTH", "3MONTHS"})
                Case "MONTH" : periodes.AddRange({"MONTH", "3MONTHS"})
                Case "3MONTHS" : periodes.AddRange({"3MONTHS"})
            End Select

            For Each p In periodes
                Dim cle = p & "_" & cat
                If compteurs.ContainsKey(cle) Then
                    compteurs(cle) += nb
                    totaux(cle) += tot
                End If
            Next
        Next

        ' Afficher les compteurs
        litTodayGov.Text = compteurs("TODAY_Gouvernemental").ToString()
        litTodayFrn.Text = compteurs("TODAY_Fournisseur").ToString()
        litTodayEmp.Text = compteurs("TODAY_Employé").ToString()

        litWeekGov.Text = compteurs("WEEK_Gouvernemental").ToString()
        litWeekFrn.Text = compteurs("WEEK_Fournisseur").ToString()
        litWeekEmp.Text = compteurs("WEEK_Employé").ToString()

        litMonthGov.Text = compteurs("MONTH_Gouvernemental").ToString()
        litMonthFrn.Text = compteurs("MONTH_Fournisseur").ToString()
        litMonthEmp.Text = compteurs("MONTH_Employé").ToString()

        lit3MGov.Text = compteurs("3MONTHS_Gouvernemental").ToString()
        lit3MFrn.Text = compteurs("3MONTHS_Fournisseur").ToString()
        lit3MEmp.Text = compteurs("3MONTHS_Employé").ToString()

        ' Total global pour la période sélectionnée
        Dim totalNb = compteurs(PeriodeSel & "_Gouvernemental") +
                      compteurs(PeriodeSel & "_Fournisseur") +
                      compteurs(PeriodeSel & "_Employé")
        Dim totalMt = totaux(PeriodeSel & "_Gouvernemental") +
                      totaux(PeriodeSel & "_Fournisseur") +
                      totaux(PeriodeSel & "_Employé")

        litTotalTrans.Text = totalNb.ToString()
        litTotalMontant.Text = FormatMontant(totalMt)

        AppliquerActive()
    End Sub

    Private Sub AppliquerActive()
        ' Retire "active" partout
        Dim btns = New HtmlControls.HtmlAnchor() {
            btnPeriodToday, btnPeriodWeek, btnPeriodMonth, btnPeriod3M
        }
        For Each b In btns
            b.Attributes("class") = "period-btn"
        Next

        ' Active le bon
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

    Private Sub ChargerCategories()
        Dim borneFin As String
        Select Case PeriodeSel
            Case "TODAY" : borneFin = "DATEADD(DAY, 1, CAST(GETDATE() AS DATE))"
            Case "WEEK" : borneFin = "DATEADD(DAY, 7, CAST(GETDATE() AS DATE))"
            Case "MONTH" : borneFin = "DATEADD(MONTH, 1, CAST(GETDATE() AS DATE))"
            Case Else : borneFin = "DATEADD(MONTH, 3, CAST(GETDATE() AS DATE))"
        End Select

        Dim sql As String = "
SELECT
    v.[Category]            AS CategorieNom,
    v.[Id],
    v.[Beneficiaire],
    v.[Montant],
    v.[Nom],
    v.[Description],
    v.[DateExecutionPrevue]
FROM [dbo].[vwAiPaiement] v
WHERE v.[DateExecutionPrevue] >= CAST(GETDATE() AS DATE)
  AND v.[DateExecutionPrevue] <  " & borneFin & "
ORDER BY v.[Category], v.[DateExecutionPrevue];"

        Dim dt As New DataTable()
        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand(sql, cn)
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        ' Grouper par catégorie en mémoire
        Dim ordreCategorie = {"Gouvernemental", "Fournisseur", "Employé"}
        Dim resultat As New DataTable()
        resultat.Columns.Add("CategorieNom", GetType(String))
        resultat.Columns.Add("NbPaiements", GetType(Integer))
        resultat.Columns.Add("TotalMontant", GetType(Decimal))
        resultat.Columns.Add("Transactions", GetType(DataTable))

        For Each catNom In ordreCategorie
            Dim rows = dt.Select("CategorieNom = '" & catNom.Replace("'", "''") & "'")
            Dim subTable As DataTable
            If rows.Length > 0 Then
                subTable = rows.CopyToDataTable()
            Else
                subTable = dt.Clone()
            End If

            Dim totMontant = 0D
            Dim nb = 0
            For Each r In rows
                nb += 1
                If Not Convert.IsDBNull(r("Montant")) Then
                    totMontant += Convert.ToDecimal(r("Montant"))
                End If
            Next

            Dim newRow = resultat.NewRow()
            newRow("CategorieNom") = catNom
            newRow("NbPaiements") = nb
            newRow("TotalMontant") = totMontant
            newRow("Transactions") = subTable
            resultat.Rows.Add(newRow)
        Next

        rpCategories.DataSource = resultat
        rpCategories.DataBind()
    End Sub

    ' =========================================================
    '  HELPERS
    ' =========================================================

    Private Function ResoudreCleCategorie(nom As String) As String
        Select Case nom
            Case "Gouvernemental" : Return "gov"
            Case "Fournisseur" : Return "frn"
            Case "Employé" : Return "emp"
            Case Else : Return "gov"
        End Select
    End Function

    Private Function GetIconCategorie(catKey As String) As String
        Select Case catKey
            Case "gov"
                Return "<svg xmlns='http://www.w3.org/2000/svg' width='20' height='20' viewBox='0 0 24 24' " &
                       "fill='none' stroke='currentColor' stroke-width='2' " &
                       "stroke-linecap='round' stroke-linejoin='round'>" &
                       "<path d='M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z'/>" &
                       "<path d='M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2'/>" &
                       "<path d='M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2'/></svg>"
            Case "frn"
                Return "<svg xmlns='http://www.w3.org/2000/svg' width='20' height='20' viewBox='0 0 24 24' " &
                       "fill='none' stroke='currentColor' stroke-width='2' " &
                       "stroke-linecap='round' stroke-linejoin='round'>" &
                       "<path d='M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2'/>" &
                       "<path d='M15 18H9'/>" &
                       "<path d='M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14'/>" &
                       "<circle cx='17' cy='18' r='2'/>" &
                       "<circle cx='7' cy='18' r='2'/></svg>"
            Case "emp"
                Return "<svg xmlns='http://www.w3.org/2000/svg' width='20' height='20' viewBox='0 0 24 24' " &
                       "fill='none' stroke='currentColor' stroke-width='2' " &
                       "stroke-linecap='round' stroke-linejoin='round'>" &
                       "<path d='M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2'/>" &
                       "<circle cx='9' cy='7' r='4'/>" &
                       "<path d='M22 21v-2a4 4 0 0 0-3-3.87'/>" &
                       "<path d='M16 3.13a4 4 0 0 1 0 7.75'/></svg>"
            Case Else : Return ""
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

    ''' <summary>
    ''' Génère le code JS qui appelle le dispatcher central pour une action de paiement.
    ''' </summary>
    Private Function BuildDispatchJs(actionName As String, actionArg As String) As String
        Dim safeArg = actionArg.Replace("\", "\\").Replace("'", "\'")
        Return String.Format("dispatchAction('{0}','{1}'); return false;",
                             actionName, safeArg)
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
