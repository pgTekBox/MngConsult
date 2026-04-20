Imports System.Text

Public Class wbfFluxTresorerie
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            dpDateDebut.SelectedDate = New DateTime(DateTime.Now.Year, 1, 1)
            dpDateFin.SelectedDate = DateTime.Now
            BuildReport()
        End If
    End Sub

    Protected Sub btnGenerate_Click(sender As Object, e As EventArgs) Handles btnGenerate.Click
        BuildReport()
    End Sub

    Private Sub BuildReport()

        Dim dateDebut As DateTime = If(dpDateDebut.SelectedDate.HasValue, dpDateDebut.SelectedDate.Value, New DateTime(DateTime.Now.Year, 1, 1))
        Dim dateFin As DateTime = If(dpDateFin.SelectedDate.HasValue, dpDateFin.SelectedDate.Value, DateTime.Now)

        lblPeriodeDebut.Text = dateDebut.ToString("yyyy-MM-dd")
        lblPeriodeFin.Text = dateFin.ToString("yyyy-MM-dd")

        ' Récupérer les données
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@DateDebut", dateDebut))
        p.Add(New SqlClient.SqlParameter("@DateFin", dateFin))
        Dim ds As DataSet = ExecuteSQLds("s0087GetFluxTresorerie", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 Then
            litReport.Text = "<p style='padding:20px; color:#64748b;'>Aucune donnée pour cette période.</p>"
            Return
        End If

        ' Table 0 : Données des flux
        ' Table 1 : Encaisse début et fin (2 lignes)
        Dim dtFlux As DataTable = ds.Tables(0)
        Dim dtEncaisse As DataTable = If(ds.Tables.Count > 1, ds.Tables(1), Nothing)

        Dim encaisseDebut As Decimal = 0
        Dim encaisseFin As Decimal = 0

        If dtEncaisse IsNot Nothing AndAlso dtEncaisse.Rows.Count >= 2 Then
            encaisseDebut = If(IsDBNull(dtEncaisse.Rows(0)("Solde")), 0D, CDec(dtEncaisse.Rows(0)("Solde")))
            encaisseFin = If(IsDBNull(dtEncaisse.Rows(1)("Solde")), 0D, CDec(dtEncaisse.Rows(1)("Solde")))
        End If

        Dim sb As New StringBuilder()
        sb.AppendLine("<table class=""ft-table"">")

        ' ══════════════════════════════════════════
        ' A. ACTIVITÉS D'EXPLOITATION
        ' ══════════════════════════════════════════
        RenderSectionHeader(sb, "Activités d'exploitation", "ico-exploit")

        ' Bénéfice net
        Dim beneficeNet As Decimal = GetMontant(dtFlux, "BeneficeNet")
        RenderLine(sb, "", "Bénéfice net", beneficeNet)
        RenderSpacer(sb)

        ' Ajustements pour éléments sans effet sur la trésorerie
        RenderSubHeader(sb, "Ajustements pour éléments sans effet sur la trésorerie")
        Dim amortissement As Decimal = GetMontant(dtFlux, "Amortissement")
        Dim creancesDouteuses As Decimal = GetMontant(dtFlux, "CreancesDouteuses")
        Dim gainDispActif As Decimal = GetMontant(dtFlux, "GainPerteDispositionActif")
        Dim impotsDifferes As Decimal = GetMontant(dtFlux, "ImpotsDifferes")

        RenderLine(sb, "", "Amortissement", amortissement)
        RenderLine(sb, "", "Créances douteuses", creancesDouteuses)
        RenderLine(sb, "", "Gain/Perte sur disposition d'actifs", gainDispActif)
        RenderLine(sb, "", "Impôts différés", impotsDifferes)

        Dim totalAjustements As Decimal = amortissement + creancesDouteuses + gainDispActif + impotsDifferes
        RenderSubTotal(sb, "Total des ajustements", totalAjustements)
        RenderSpacer(sb)

        ' Variation du fonds de roulement
        RenderSubHeader(sb, "Variation des éléments du fonds de roulement")
        Dim varClients As Decimal = GetMontant(dtFlux, "VarComptesClients")
        Dim varStocks As Decimal = GetMontant(dtFlux, "VarStocks")
        Dim varFraisPayes As Decimal = GetMontant(dtFlux, "VarFraisPayesAvance")
        Dim varTaxesRecevoir As Decimal = GetMontant(dtFlux, "VarTaxesRecevoir")
        Dim varFournisseurs As Decimal = GetMontant(dtFlux, "VarComptesFournisseurs")
        Dim varChargesPayer As Decimal = GetMontant(dtFlux, "VarChargesAPayer")
        Dim varTaxesPayer As Decimal = GetMontant(dtFlux, "VarTaxesAPayer")
        Dim varRetenuesSal As Decimal = GetMontant(dtFlux, "VarRetenuesSalariales")
        Dim varRevenusRep As Decimal = GetMontant(dtFlux, "VarRevenusReportes")

        RenderLine(sb, "", "Comptes clients", varClients)
        RenderLine(sb, "", "Stocks", varStocks)
        RenderLine(sb, "", "Frais payés d'avance", varFraisPayes)
        RenderLine(sb, "", "Taxes à recevoir", varTaxesRecevoir)
        RenderLine(sb, "", "Comptes fournisseurs", varFournisseurs)
        RenderLine(sb, "", "Charges à payer", varChargesPayer)
        RenderLine(sb, "", "Taxes à payer", varTaxesPayer)
        RenderLine(sb, "", "Retenues salariales", varRetenuesSal)
        RenderLine(sb, "", "Revenus reportés", varRevenusRep)

        Dim totalVarFR As Decimal = varClients + varStocks + varFraisPayes + varTaxesRecevoir +
                                     varFournisseurs + varChargesPayer + varTaxesPayer +
                                     varRetenuesSal + varRevenusRep
        RenderSubTotal(sb, "Variation nette du fonds de roulement", totalVarFR)

        ' Total exploitation
        Dim totalExploit As Decimal = beneficeNet + totalAjustements + totalVarFR
        RenderTotalRow(sb, "Flux de trésorerie liés aux activités d'exploitation", totalExploit)
        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' B. ACTIVITÉS D'INVESTISSEMENT
        ' ══════════════════════════════════════════
        RenderSectionHeader(sb, "Activités d'investissement", "ico-invest")

        Dim acqImmoCorpo As Decimal = GetMontant(dtFlux, "AcquisitionImmoCorpo")
        Dim dispImmoCorpo As Decimal = GetMontant(dtFlux, "DispositionImmoCorpo")
        Dim acqImmoIncorpo As Decimal = GetMontant(dtFlux, "AcquisitionImmoIncorpo")
        Dim acqPlacements As Decimal = GetMontant(dtFlux, "AcquisitionPlacements")
        Dim dispPlacements As Decimal = GetMontant(dtFlux, "DispositionPlacements")

        RenderLine(sb, "", "Acquisition d'immobilisations corporelles", acqImmoCorpo)
        RenderLine(sb, "", "Disposition d'immobilisations corporelles", dispImmoCorpo)
        RenderLine(sb, "", "Acquisition d'immobilisations incorporelles", acqImmoIncorpo)
        RenderLine(sb, "", "Acquisition de placements", acqPlacements)
        RenderLine(sb, "", "Disposition de placements", dispPlacements)

        Dim totalInvest As Decimal = acqImmoCorpo + dispImmoCorpo + acqImmoIncorpo + acqPlacements + dispPlacements
        RenderTotalRow(sb, "Flux de trésorerie liés aux activités d'investissement", totalInvest)
        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' C. ACTIVITÉS DE FINANCEMENT
        ' ══════════════════════════════════════════
        RenderSectionHeader(sb, "Activités de financement", "ico-finance")

        Dim empruntsNouveaux As Decimal = GetMontant(dtFlux, "EmpruntsNouveaux")
        Dim remboursEmprunts As Decimal = GetMontant(dtFlux, "RemboursementEmprunts")
        Dim emissionActions As Decimal = GetMontant(dtFlux, "EmissionActions")
        Dim dividendesVerses As Decimal = GetMontant(dtFlux, "DividendesVerses")
        Dim apportsProprio As Decimal = GetMontant(dtFlux, "ApportsProprietaire")
        Dim retraitsProprio As Decimal = GetMontant(dtFlux, "RetraitsProprietaire")

        RenderLine(sb, "", "Nouveaux emprunts", empruntsNouveaux)
        RenderLine(sb, "", "Remboursement d'emprunts", remboursEmprunts)
        RenderLine(sb, "", "Émission d'actions", emissionActions)
        RenderLine(sb, "", "Dividendes versés", dividendesVerses)
        RenderLine(sb, "", "Apports du propriétaire", apportsProprio)
        RenderLine(sb, "", "Retraits du propriétaire", retraitsProprio)

        Dim totalFinance As Decimal = empruntsNouveaux + remboursEmprunts + emissionActions +
                                       dividendesVerses + apportsProprio + retraitsProprio
        RenderTotalRow(sb, "Flux de trésorerie liés aux activités de financement", totalFinance)
        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' VARIATION NETTE DE TRÉSORERIE
        ' ══════════════════════════════════════════
        Dim variationNette As Decimal = totalExploit + totalInvest + totalFinance
        RenderCalcRow(sb, "Variation nette de la trésorerie", variationNette)
        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' ENCAISSE
        ' ══════════════════════════════════════════
        RenderEncaisseRow(sb, "Trésorerie au début de la période", encaisseDebut)
        RenderEncaisseFinRow(sb, "Trésorerie à la fin de la période", encaisseDebut + variationNette)

        sb.AppendLine("</table>")

        litReport.Text = sb.ToString()
        lblInfo.Text = String.Format("Période : {0} au {1}", dateDebut.ToString("yyyy-MM-dd"), dateFin.ToString("yyyy-MM-dd"))
    End Sub

    ' ── Helpers de lecture ──

    Private Function GetMontant(dt As DataTable, code As String) As Decimal
        Dim rows = dt.Select("Code = '" & code & "'")
        If rows.Length > 0 AndAlso Not IsDBNull(rows(0)("Montant")) Then
            Return CDec(rows(0)("Montant"))
        End If
        Return 0D
    End Function

    ' ── Rendu HTML ──

    Private Sub RenderSectionHeader(sb As StringBuilder, titre As String, icoClass As String)
        sb.AppendLine("<tr class=""ft-section"">")
        sb.AppendFormat("  <td colspan=""2""><span class=""ft-section-icon {0}""></span>{1}</td>", icoClass, titre).AppendLine()
        sb.AppendLine("  <td></td>")
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderSubHeader(sb As StringBuilder, titre As String)
        sb.AppendLine("<tr class=""ft-sub-header"">")
        sb.AppendFormat("  <td colspan=""2"">{0}</td>", titre).AppendLine()
        sb.AppendLine("  <td></td>")
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderLine(sb As StringBuilder, numero As String, nom As String, montant As Decimal)
        sb.AppendLine("<tr class=""ft-line"">")
        sb.AppendFormat("  <td class=""item-num"">{0}</td>", numero).AppendLine()
        sb.AppendFormat("  <td class=""item-name"">{0}</td>", nom).AppendLine()
        sb.AppendFormat("  <td class=""ft-amount {0}"">{1}</td>", GetAmountClass(montant), FormatMontant(montant)).AppendLine()
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderSubTotal(sb As StringBuilder, label As String, montant As Decimal)
        sb.AppendLine("<tr class=""ft-sub-total"">")
        sb.AppendLine("  <td></td>")
        sb.AppendFormat("  <td>{0}</td>", label).AppendLine()
        sb.AppendFormat("  <td class=""ft-amount {0}"">{1}</td>", GetAmountClass(montant), FormatMontant(montant)).AppendLine()
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderTotalRow(sb As StringBuilder, label As String, montant As Decimal)
        sb.AppendLine("<tr class=""ft-total"">")
        sb.AppendLine("  <td></td>")
        sb.AppendFormat("  <td>{0}</td>", label).AppendLine()
        sb.AppendFormat("  <td class=""ft-amount {0}"">{1}</td>", GetAmountClass(montant), FormatMontant(montant)).AppendLine()
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderCalcRow(sb As StringBuilder, label As String, montant As Decimal)
        sb.AppendLine("<tr class=""ft-calc"">")
        sb.AppendLine("  <td></td>")
        sb.AppendFormat("  <td>{0}</td>", label).AppendLine()
        sb.AppendFormat("  <td class=""ft-amount {0}"">{1}</td>", GetAmountClass(montant), FormatMontant(montant)).AppendLine()
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderEncaisseRow(sb As StringBuilder, label As String, montant As Decimal)
        sb.AppendLine("<tr class=""ft-encaisse"">")
        sb.AppendLine("  <td></td>")
        sb.AppendFormat("  <td>{0}</td>", label).AppendLine()
        sb.AppendFormat("  <td class=""ft-amount"">{0}</td>", FormatMontant(montant)).AppendLine()
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderEncaisseFinRow(sb As StringBuilder, label As String, montant As Decimal)
        sb.AppendLine("<tr class=""ft-encaisse-fin"">")
        sb.AppendLine("  <td></td>")
        sb.AppendFormat("  <td>{0}</td>", label).AppendLine()
        sb.AppendFormat("  <td class=""ft-amount"">{0}</td>", FormatMontant(montant)).AppendLine()
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderSpacer(sb As StringBuilder)
        sb.AppendLine("<tr class=""ft-spacer""><td colspan=""3""></td></tr>")
    End Sub

    ' ── Formatage ──

    Private Function FormatMontant(montant As Decimal) As String
        If montant = 0 Then Return "—"
        If montant < 0 Then Return "(" & Math.Abs(montant).ToString("N2") & " $)"
        Return montant.ToString("N2") & " $"
    End Function

    Private Function GetAmountClass(montant As Decimal) As String
        If montant > 0 Then Return "amt-positive"
        If montant < 0 Then Return "amt-negative"
        Return "amt-zero"
    End Function

End Class
