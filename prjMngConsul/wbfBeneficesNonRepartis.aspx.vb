Imports System.Text

Public Class wbfBeneficesNonRepartis
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            dpDateDebut.SelectedDate = New DateTime(DateTime.Now.Year, 1, 1)
            dpDateFin.SelectedDate = New DateTime(DateTime.Now.Year, 12, 31)
            BuildReport()
        End If
    End Sub

    Protected Sub btnGenerate_Click(sender As Object, e As EventArgs) Handles btnGenerate.Click
        BuildReport()
    End Sub

    Private Sub BuildReport()

        Dim dateDebut As DateTime = If(dpDateDebut.SelectedDate.HasValue, dpDateDebut.SelectedDate.Value, New DateTime(DateTime.Now.Year, 1, 1))
        Dim dateFin As DateTime = If(dpDateFin.SelectedDate.HasValue, dpDateFin.SelectedDate.Value, New DateTime(DateTime.Now.Year, 12, 31))

        lblPeriodeFin.Text = dateFin.ToString("yyyy-MM-dd")

        ' Récupérer les données
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@DateDebut", dateDebut))
        p.Add(New SqlClient.SqlParameter("@DateFin", dateFin))
        Dim ds As DataSet = ExecuteSQLds("s0088GetBeneficesNonRepartis", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            litReport.Text = "<p style='padding:20px; color:#64748b;'>Aucune donnée disponible.</p>"
            Return
        End If

        Dim dt As DataTable = ds.Tables(0)
        Dim row As DataRow = dt.Rows(0)

        ' Lire les montants
        Dim bnrOuverture As Decimal = GetVal(row, "BNR_Ouverture")
        Dim beneficeNet As Decimal = GetVal(row, "BeneficeNet")
        Dim dividendes As Decimal = GetVal(row, "Dividendes")
        Dim retraits As Decimal = GetVal(row, "Retraits")
        Dim correctionExAnt As Decimal = GetVal(row, "CorrectionExerciceAnterieur")
        Dim ajustementAutre As Decimal = GetVal(row, "AjustementAutre")

        ' Calculs
        Dim totalDistributions As Decimal = dividendes + retraits
        Dim totalAjustements As Decimal = correctionExAnt + ajustementAutre
        Dim bnrAvantAjust As Decimal = bnrOuverture + beneficeNet - totalDistributions
        Dim bnrCloture As Decimal = bnrAvantAjust + totalAjustements

        ' Vérification avec le solde réel du compte BNR
        Dim bnrSoldeReel As Decimal = GetVal(row, "BNR_SoldeReel")

        ' Construire le HTML
        Dim sb As New StringBuilder()
        sb.AppendLine("<table class=""bnr-table"">")

        ' ══════════════════════════════════════════
        ' BNR AU DÉBUT DE L'EXERCICE
        ' ══════════════════════════════════════════
        sb.AppendLine("<tr class=""bnr-open"">")
        sb.AppendFormat("  <td>Bénéfices non répartis au début de l'exercice ({0})</td>", dateDebut.ToString("yyyy-MM-dd")).AppendLine()
        sb.AppendFormat("  <td class=""bnr-amount"">{0}</td>", FormatMontant(bnrOuverture)).AppendLine()
        sb.AppendLine("</tr>")

        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' BÉNÉFICE NET DE L'EXERCICE
        ' ══════════════════════════════════════════
        If beneficeNet >= 0 Then
            sb.AppendLine("<tr class=""bnr-add"">")
            sb.AppendLine("  <td class=""item-label"">Ajouter : Bénéfice net de l'exercice</td>")
        Else
            sb.AppendLine("<tr class=""bnr-sub"">")
            sb.AppendLine("  <td class=""item-label"">Moins : Perte nette de l'exercice</td>")
        End If
        sb.AppendFormat("  <td class=""bnr-amount"">{0}</td>", FormatMontant(beneficeNet)).AppendLine()
        sb.AppendLine("</tr>")

        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' DISTRIBUTIONS
        ' ══════════════════════════════════════════
        If dividendes <> 0 OrElse retraits <> 0 Then

            sb.AppendLine("<tr class=""bnr-sub"">")
            sb.AppendLine("  <td class=""item-label"">Moins : Distributions aux propriétaires / actionnaires</td>")
            sb.AppendLine("  <td></td>")
            sb.AppendLine("</tr>")

            If dividendes <> 0 Then
                sb.AppendLine("<tr class=""bnr-detail"">")
                sb.AppendLine("  <td class=""item-label"">Dividendes déclarés</td>")
                sb.AppendFormat("  <td class=""bnr-amount"">{0}</td>", FormatMontantNegatif(dividendes)).AppendLine()
                sb.AppendLine("</tr>")
            End If

            If retraits <> 0 Then
                sb.AppendLine("<tr class=""bnr-detail"">")
                sb.AppendLine("  <td class=""item-label"">Retraits du propriétaire</td>")
                sb.AppendFormat("  <td class=""bnr-amount"">{0}</td>", FormatMontantNegatif(retraits)).AppendLine()
                sb.AppendLine("</tr>")
            End If

            ' Sous-total distributions
            sb.AppendLine("<tr class=""bnr-subtotal"">")
            sb.AppendLine("  <td>Total des distributions</td>")
            sb.AppendFormat("  <td class=""bnr-amount amt-negative"">{0}</td>", FormatMontantNegatif(totalDistributions)).AppendLine()
            sb.AppendLine("</tr>")

            RenderSpacer(sb)
        End If

        ' ══════════════════════════════════════════
        ' SOUS-TOTAL AVANT AJUSTEMENTS
        ' ══════════════════════════════════════════
        sb.AppendLine("<tr class=""bnr-subtotal"">")
        sb.AppendLine("  <td>Bénéfices non répartis avant ajustements</td>")
        sb.AppendFormat("  <td class=""bnr-amount {0}"">{1}</td>", GetAmountClass(bnrAvantAjust), FormatMontant(bnrAvantAjust)).AppendLine()
        sb.AppendLine("</tr>")

        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' AJUSTEMENTS (si applicables)
        ' ══════════════════════════════════════════
        If totalAjustements <> 0 Then

            sb.AppendLine("<tr class=""bnr-adj-header"">")
            sb.AppendLine("  <td colspan=""2"">Ajustements</td>")
            sb.AppendLine("</tr>")

            If correctionExAnt <> 0 Then
                sb.AppendLine("<tr class=""bnr-line"">")
                sb.AppendLine("  <td class=""item-label"">Correction d'exercice antérieur</td>")
                sb.AppendFormat("  <td class=""bnr-amount {0}"">{1}</td>", GetAmountClass(correctionExAnt), FormatMontant(correctionExAnt)).AppendLine()
                sb.AppendLine("</tr>")
            End If

            If ajustementAutre <> 0 Then
                sb.AppendLine("<tr class=""bnr-line"">")
                sb.AppendLine("  <td class=""item-label"">Autres ajustements</td>")
                sb.AppendFormat("  <td class=""bnr-amount {0}"">{1}</td>", GetAmountClass(ajustementAutre), FormatMontant(ajustementAutre)).AppendLine()
                sb.AppendLine("</tr>")
            End If

            sb.AppendLine("<tr class=""bnr-subtotal"">")
            sb.AppendLine("  <td>Total des ajustements</td>")
            sb.AppendFormat("  <td class=""bnr-amount {0}"">{1}</td>", GetAmountClass(totalAjustements), FormatMontant(totalAjustements)).AppendLine()
            sb.AppendLine("</tr>")

            RenderSpacer(sb)
        End If

        ' ══════════════════════════════════════════
        ' BNR À LA FIN DE L'EXERCICE
        ' ══════════════════════════════════════════
        sb.AppendLine("<tr class=""bnr-close"">")
        sb.AppendFormat("  <td>Bénéfices non répartis à la fin de l'exercice ({0})</td>", dateFin.ToString("yyyy-MM-dd")).AppendLine()
        sb.AppendFormat("  <td class=""bnr-amount"">{0}</td>", FormatMontant(bnrCloture)).AppendLine()
        sb.AppendLine("</tr>")

        ' ══════════════════════════════════════════
        ' VÉRIFICATION
        ' ══════════════════════════════════════════
        If bnrSoldeReel <> 0 Then
            Dim ecart As Decimal = bnrCloture - bnrSoldeReel
            Dim checkClass As String = If(ecart = 0, "bnr-check-ok", "bnr-check-err")
            Dim checkMsg As String

            If ecart = 0 Then
                checkMsg = "✓ Le solde calculé correspond au solde du compte 3300 Bénéfices non répartis"
            Else
                checkMsg = String.Format("✗ Écart de {0} avec le solde du compte 3300 — Vérifier les écritures", FormatMontant(ecart))
            End If

            sb.AppendLine("<tr class=""bnr-spacer""><td colspan=""2""></td></tr>")
            sb.AppendFormat("<tr class=""bnr-check {0}""><td colspan=""2"">{1}</td></tr>", checkClass, checkMsg).AppendLine()
        End If

        sb.AppendLine("</table>")

        litReport.Text = sb.ToString()
        lblInfo.Text = String.Format("Exercice terminé le {0}", dateFin.ToString("yyyy-MM-dd"))
    End Sub

    ' ── Helpers ──

    Private Function GetVal(row As DataRow, col As String) As Decimal
        If Not row.Table.Columns.Contains(col) Then Return 0D
        If IsDBNull(row(col)) Then Return 0D
        Return CDec(row(col))
    End Function

    Private Sub RenderSpacer(sb As StringBuilder)
        sb.AppendLine("<tr class=""bnr-spacer""><td colspan=""2""></td></tr>")
    End Sub

    Private Function FormatMontant(montant As Decimal) As String
        If montant = 0 Then Return "—"
        If montant < 0 Then Return "(" & Math.Abs(montant).ToString("N2") & " $)"
        Return montant.ToString("N2") & " $"
    End Function

    Private Function FormatMontantNegatif(montant As Decimal) As String
        ' Affiche toujours entre parenthèses (convention pour les distributions)
        If montant = 0 Then Return "—"
        Return "(" & Math.Abs(montant).ToString("N2") & " $)"
    End Function

    Private Function GetAmountClass(montant As Decimal) As String
        If montant > 0 Then Return "amt-positive"
        If montant < 0 Then Return "amt-negative"
        Return "amt-zero"
    End Function

End Class
