Imports System.Text

Public Class wbfBilan
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            dpDateBilan.SelectedDate = DateTime.Now
            BuildReport()
        End If
    End Sub

    Protected Sub btnGenerate_Click(sender As Object, e As EventArgs) Handles btnGenerate.Click
        BuildReport()
    End Sub

    Private Sub BuildReport()

        Dim dateBilan As DateTime = If(dpDateBilan.SelectedDate.HasValue, dpDateBilan.SelectedDate.Value, DateTime.Now)
        lblDateBilan.Text = dateBilan.ToString("yyyy-MM-dd")

        ' La proc retourne 2 resultsets :
        '   Table 0 = comptes du bilan
        '   Table 1 = bénéfice net de l'exercice (1 ligne, 1 colonne)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@DateBilan", dateBilan))
        Dim ds As DataSet = ExecuteSQLds("s0086GetBilan", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 Then
            litReport.Text = "<p style='padding:20px; color:#64748b;'>Aucune donnée disponible.</p>"
            Return
        End If

        Dim dt As DataTable = ds.Tables(0)

        ' Récupérer le bénéfice net (resultset 2)
        Dim beneficeNet As Decimal = 0
        If ds.Tables.Count > 1 AndAlso ds.Tables(1).Rows.Count > 0 Then
            If Not IsDBNull(ds.Tables(1).Rows(0)("BeneficeNet")) Then
                beneficeNet = CDec(ds.Tables(1).Rows(0)("BeneficeNet"))
            End If
        End If

        Dim sb As New StringBuilder()
        sb.AppendLine("<table class=""bi-table"">")

        ' ══════════════════════════════════════════
        ' ACTIF
        ' ══════════════════════════════════════════
        RenderSectionHeader(sb, "ACTIF")

        Dim totalActifCT As Decimal = RenderClasse(sb, dt, 1, "Actif à court terme", "1000 – 1499")
        RenderTotalRow(sb, "Total de l'actif à court terme", totalActifCT)
        RenderSpacer(sb)

        Dim totalActifLT As Decimal = RenderClasse(sb, dt, 2, "Actif à long terme", "1500 – 1999")
        RenderTotalRow(sb, "Total de l'actif à long terme", totalActifLT)
        RenderSpacer(sb)

        Dim totalActif As Decimal = totalActifCT + totalActifLT
        RenderGrandTotal(sb, "TOTAL DE L'ACTIF", totalActif)

        sb.AppendLine("<tr class=""bi-divider""><td colspan=""3""><hr/></td></tr>")

        ' ══════════════════════════════════════════
        ' PASSIF
        ' ══════════════════════════════════════════
        RenderSectionHeader(sb, "PASSIF")

        Dim totalPassifCT As Decimal = RenderClasse(sb, dt, 3, "Passif à court terme", "2000 – 2499")
        RenderTotalRow(sb, "Total du passif à court terme", totalPassifCT)
        RenderSpacer(sb)

        Dim totalPassifLT As Decimal = RenderClasse(sb, dt, 4, "Passif à long terme", "2500 – 2999")
        RenderTotalRow(sb, "Total du passif à long terme", totalPassifLT)
        RenderSpacer(sb)

        Dim totalPassif As Decimal = totalPassifCT + totalPassifLT
        RenderGrandTotal(sb, "TOTAL DU PASSIF", totalPassif)
        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' CAPITAUX PROPRES
        ' ══════════════════════════════════════════
        RenderSectionHeader(sb, "CAPITAUX PROPRES")

        ' Comptes de capitaux propres du bilan (3000-3999)
        Dim totalCP As Decimal = RenderClasse(sb, dt, 5, "Capitaux propres", "3000 – 3999")

        ' ── Bénéfice net de l'exercice courant ──
        ' Calculé à partir des comptes de résultats (revenus − charges)
        ' Intégré ici pour équilibrer le bilan
        If beneficeNet <> 0 Then
            sb.AppendLine("<tr class=""bi-sub-header"">")
            sb.AppendLine("  <td colspan=""2"">Résultat de l'exercice courant</td>")
            sb.AppendLine("  <td></td>")
            sb.AppendLine("</tr>")

            Dim labelBN As String = If(beneficeNet >= 0,
                "Bénéfice net de l'exercice",
                "Perte nette de l'exercice")

            sb.AppendLine("<tr class=""bi-line"">")
            sb.AppendLine("  <td class=""account-num"" style=""color:#2563eb; font-style:italic;"">—</td>")
            sb.AppendFormat("  <td class=""account-name"" style=""color:#2563eb; font-style:italic;"">{0}</td>", labelBN).AppendLine()
            sb.AppendFormat("  <td class=""bi-amount {0}"" style=""font-style:italic;"">{1}</td>",
                GetAmountClass(beneficeNet), FormatMontant(beneficeNet)).AppendLine()
            sb.AppendLine("</tr>")

            sb.AppendLine("<tr class=""bi-sub-total"">")
            sb.AppendLine("  <td></td>")
            sb.AppendLine("  <td>Total — Résultat de l'exercice</td>")
            sb.AppendFormat("  <td class=""bi-amount {0}"">{1}</td>",
                GetAmountClass(beneficeNet), FormatMontant(beneficeNet)).AppendLine()
            sb.AppendLine("</tr>")
        End If

        RenderSpacer(sb)

        ' Total CP incluant le bénéfice net
        Dim totalCPAvecBN As Decimal = totalCP + beneficeNet
        RenderGrandTotal(sb, "TOTAL DES CAPITAUX PROPRES", totalCPAvecBN)
        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' TOTAL PASSIF + CAPITAUX PROPRES
        ' ══════════════════════════════════════════
        Dim totalPassifCP As Decimal = totalPassif + totalCPAvecBN
        RenderGrandTotal(sb, "TOTAL DU PASSIF ET DES CAPITAUX PROPRES", totalPassifCP)

        ' ══════════════════════════════════════════
        ' VÉRIFICATION
        ' ══════════════════════════════════════════
        Dim ecart As Decimal = totalActif - totalPassifCP
        Dim checkClass As String = If(Math.Abs(ecart) < 0.01D, "bi-check-ok", "bi-check-err")
        Dim checkMsg As String

        If Math.Abs(ecart) < 0.01D Then
            checkMsg = "✓ Le bilan est en équilibre"
        Else
            checkMsg = String.Format("✗ Écart de {0} — Le bilan n'est pas en équilibre", FormatMontant(ecart))
        End If

        sb.AppendLine("<tr class=""bi-spacer""><td colspan=""3""></td></tr>")
        sb.AppendFormat("<tr class=""bi-check {0}""><td colspan=""3"">{1}</td></tr>", checkClass, checkMsg).AppendLine()

        If beneficeNet <> 0 Then
            sb.AppendLine("<tr class=""bi-spacer""><td colspan=""3""></td></tr>")
            sb.AppendFormat("<tr><td colspan=""3"" style=""font-size:12px; color:#64748b; padding:8px 14px; font-style:italic;"">Note : Le bénéfice net de l'exercice ({0}) est calculé automatiquement à partir des comptes de résultats et intégré aux capitaux propres.</td></tr>", FormatMontant(beneficeNet)).AppendLine()
        End If

        sb.AppendLine("</table>")

        litReport.Text = sb.ToString()
        lblInfo.Text = "Au " & dateBilan.ToString("yyyy-MM-dd")
    End Sub

    ' ── Rendu d'une classe complète ──

    Private Function RenderClasse(sb As StringBuilder, dt As DataTable, classeParentId As Integer, titre As String, plage As String) As Decimal

        sb.AppendLine("<tr class=""bi-classe"">")
        sb.AppendFormat("  <td colspan=""2"">{0} <span class=""plage"">({1})</span></td>", titre, plage).AppendLine()
        sb.AppendLine("  <td></td>")
        sb.AppendLine("</tr>")

        Dim totalClasse As Decimal = 0

        Dim sousClasses = (From r In dt.AsEnumerable()
                           Where CInt(r("ClasseParentId")) = classeParentId
                           Group r By scId = CInt(r("ClasseId")),
                                       scNom = r("SousClasseDescription").ToString()
                           Into grp = Group
                           Order By grp.First()("ClasseOrdre")
                           Select New With {.Id = scId, .Nom = scNom, .Comptes = grp}).ToList()

        For Each sc In sousClasses
            sb.AppendLine("<tr class=""bi-sub-header"">")
            sb.AppendFormat("  <td colspan=""2"">{0}</td>", sc.Nom).AppendLine()
            sb.AppendLine("  <td></td>")
            sb.AppendLine("</tr>")

            Dim subTotal As Decimal = 0

            For Each row In sc.Comptes
                Dim numero As String = row("Numero").ToString()
                Dim nom As String = row("Nom").ToString()
                Dim solde As Decimal = If(IsDBNull(row("Solde")), 0D, CDec(row("Solde")))
                subTotal += solde

                sb.AppendLine("<tr class=""bi-line"">")
                sb.AppendFormat("  <td class=""account-num"">{0}</td>", numero).AppendLine()
                sb.AppendFormat("  <td class=""account-name"">{0}</td>", nom).AppendLine()
                sb.AppendFormat("  <td class=""bi-amount {0}"">{1}</td>", GetAmountClass(solde), FormatMontant(solde)).AppendLine()
                sb.AppendLine("</tr>")
            Next

            sb.AppendLine("<tr class=""bi-sub-total"">")
            sb.AppendLine("  <td></td>")
            sb.AppendFormat("  <td>Total — {0}</td>", sc.Nom).AppendLine()
            sb.AppendFormat("  <td class=""bi-amount {0}"">{1}</td>", GetAmountClass(subTotal), FormatMontant(subTotal)).AppendLine()
            sb.AppendLine("</tr>")

            totalClasse += subTotal
        Next

        Return totalClasse
    End Function

    Private Sub RenderSectionHeader(sb As StringBuilder, titre As String)
        sb.AppendLine("<tr class=""bi-section"">")
        sb.AppendFormat("  <td colspan=""3"">{0}</td>", titre).AppendLine()
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderTotalRow(sb As StringBuilder, label As String, montant As Decimal)
        sb.AppendLine("<tr class=""bi-total"">")
        sb.AppendLine("  <td></td>")
        sb.AppendFormat("  <td>{0}</td>", label).AppendLine()
        sb.AppendFormat("  <td class=""bi-amount {0}"">{1}</td>", GetAmountClass(montant), FormatMontant(montant)).AppendLine()
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderGrandTotal(sb As StringBuilder, label As String, montant As Decimal)
        sb.AppendLine("<tr class=""bi-grand-total"">")
        sb.AppendLine("  <td></td>")
        sb.AppendFormat("  <td>{0}</td>", label).AppendLine()
        sb.AppendFormat("  <td class=""bi-amount"">{0}</td>", FormatMontant(montant)).AppendLine()
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderSpacer(sb As StringBuilder)
        sb.AppendLine("<tr class=""bi-spacer""><td colspan=""3""></td></tr>")
    End Sub

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
