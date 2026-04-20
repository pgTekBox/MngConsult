Imports System.Text

Public Class wbfBalanceVerification
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            dpDate.SelectedDate = DateTime.Now
            BuildReport()
        End If
    End Sub

    Protected Sub btnGenerate_Click(sender As Object, e As EventArgs) Handles btnGenerate.Click
        BuildReport()
    End Sub

    Protected Sub chkHideZero_CheckedChanged(sender As Object, e As EventArgs)
        BuildReport()
    End Sub

    Private Sub BuildReport()

        Dim dateBV As DateTime = If(dpDate.SelectedDate.HasValue, dpDate.SelectedDate.Value, DateTime.Now)
        Dim hideZero As Boolean = chkHideZero.Checked

        lblDate.Text = dateBV.ToString("yyyy-MM-dd")

        ' Récupérer les données
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@DateBV", dateBV))
        Dim ds As DataSet = ExecuteSQLds("s0089GetBalanceVerification", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 Then
            litReport.Text = "<p style='padding:20px; color:#64748b;'>Aucune donnée disponible.</p>"
            Return
        End If

        Dim dt As DataTable = ds.Tables(0)

        Dim sb As New StringBuilder()
        Dim grandTotalDebit As Decimal = 0
        Dim grandTotalCredit As Decimal = 0
        Dim nbComptes As Integer = 0
        Dim nbComptesAffichés As Integer = 0

        ' Grouper par classe parente
        Dim classes = (From r In dt.AsEnumerable()
                       Group r By cpId = CInt(r("ClasseParentId")),
                                  cpDesc = r("ClasseDescription").ToString(),
                                  cpOrdre = CInt(r("ClasseParentOrdre"))
                       Into grp = Group
                       Order By cpOrdre
                       Select New With {.Id = cpId, .Description = cpDesc, .Comptes = grp}).ToList()

        sb.AppendLine("<table class=""bv-table"">")

        ' En-tête
        sb.AppendLine("<thead><tr>")
        sb.AppendLine("  <th>Numéro</th>")
        sb.AppendLine("  <th>Nom du compte</th>")
        sb.AppendLine("  <th class=""col-classe"">Classe</th>")
        sb.AppendLine("  <th class=""col-amount"">Débit</th>")
        sb.AppendLine("  <th class=""col-amount"">Crédit</th>")
        sb.AppendLine("</tr></thead>")
        sb.AppendLine("<tbody>")

        For Each classe In classes

            Dim sectionDebit As Decimal = 0
            Dim sectionCredit As Decimal = 0
            Dim sectionLines As New StringBuilder()
            Dim sectionCount As Integer = 0

            For Each row In classe.Comptes
                Dim soldeDebit As Decimal = If(IsDBNull(row("SoldeDebit")), 0D, CDec(row("SoldeDebit")))
                Dim soldeCredit As Decimal = If(IsDBNull(row("SoldeCredit")), 0D, CDec(row("SoldeCredit")))

                nbComptes += 1

                ' Masquer les comptes à solde zéro si coché
                If hideZero AndAlso soldeDebit = 0 AndAlso soldeCredit = 0 Then Continue For

                Dim numero As String = row("Numero").ToString()
                Dim nom As String = row("Nom").ToString()
                Dim sousClasse As String = row("SousClasseDescription").ToString()

                Dim debitClass As String = If(soldeDebit > 0, "has-value", "no-value")
                Dim creditClass As String = If(soldeCredit > 0, "has-value", "no-value")

                sectionLines.AppendLine("<tr>")
                sectionLines.AppendFormat("  <td class=""col-num"">{0}</td>", numero).AppendLine()
                sectionLines.AppendFormat("  <td class=""col-nom"">{0}</td>", nom).AppendLine()
                sectionLines.AppendFormat("  <td class=""col-classe"">{0}</td>", sousClasse).AppendLine()
                sectionLines.AppendFormat("  <td class=""col-debit {0}"">{1}</td>", debitClass, FormatMontantBV(soldeDebit)).AppendLine()
                sectionLines.AppendFormat("  <td class=""col-credit {0}"">{1}</td>", creditClass, FormatMontantBV(soldeCredit)).AppendLine()
                sectionLines.AppendLine("</tr>")

                sectionDebit += soldeDebit
                sectionCredit += soldeCredit
                sectionCount += 1
            Next

            ' N'afficher la section que si elle a des lignes
            If sectionCount > 0 Then

                ' En-tête de section
                sb.AppendLine("<tr class=""bv-section"">")
                sb.AppendFormat("  <td colspan=""3"">{0}</td>", classe.Description).AppendLine()
                sb.AppendLine("  <td></td><td></td>")
                sb.AppendLine("</tr>")

                ' Lignes de comptes
                sb.Append(sectionLines.ToString())

                ' Sous-total de section
                sb.AppendLine("<tr class=""bv-sub-total"">")
                sb.AppendLine("  <td></td>")
                sb.AppendFormat("  <td colspan=""2"">Total — {0}</td>", classe.Description).AppendLine()
                sb.AppendFormat("  <td class=""col-debit"">{0}</td>", FormatMontantBV(sectionDebit)).AppendLine()
                sb.AppendFormat("  <td class=""col-credit"">{0}</td>", FormatMontantBV(sectionCredit)).AppendLine()
                sb.AppendLine("</tr>")

                sb.AppendLine("<tr class=""bv-spacer""><td colspan=""5""></td></tr>")

                nbComptesAffichés += sectionCount
            End If

            grandTotalDebit += sectionDebit
            grandTotalCredit += sectionCredit
        Next

        ' Grand total
        sb.AppendLine("<tr class=""bv-grand-total"">")
        sb.AppendLine("  <td></td>")
        sb.AppendLine("  <td colspan=""2"">TOTAL</td>")
        sb.AppendFormat("  <td class=""col-debit"">{0}</td>", FormatMontantBV(grandTotalDebit)).AppendLine()
        sb.AppendFormat("  <td class=""col-credit"">{0}</td>", FormatMontantBV(grandTotalCredit)).AppendLine()
        sb.AppendLine("</tr>")

        ' Vérification
        Dim ecart As Decimal = grandTotalDebit - grandTotalCredit
        Dim checkClass As String = If(ecart = 0, "bv-check-ok", "bv-check-err")
        Dim checkMsg As String

        If ecart = 0 Then
            checkMsg = "✓ La balance est en équilibre — Total débits = Total crédits"
        Else
            checkMsg = String.Format("✗ Écart de {0} — La balance n'est PAS en équilibre", FormatMontant(ecart))
        End If

        sb.AppendLine("<tr class=""bv-spacer""><td colspan=""5""></td></tr>")
        sb.AppendFormat("<tr class=""bv-check {0}""><td colspan=""5"">{1}</td></tr>", checkClass, checkMsg).AppendLine()

        sb.AppendLine("</tbody></table>")

        litReport.Text = sb.ToString()

        ' Stats
        lblTotalDebit.Text = FormatMontant(grandTotalDebit)
        lblTotalCredit.Text = FormatMontant(grandTotalCredit)

        Dim ecartClass As String = If(ecart = 0, "balanced", "unbalanced")
        lblEcart.CssClass = "bv-stat-value " & ecartClass
        lblEcart.Text = FormatMontant(ecart)

        lblNbComptes.Text = If(hideZero, nbComptesAffichés & " / " & nbComptes, nbComptes.ToString())

        lblInfo.Text = String.Format("Au {0} · {1} compte(s)", dateBV.ToString("yyyy-MM-dd"), nbComptesAffichés)
    End Sub

    ' ── Formatage ──

    Private Function FormatMontantBV(montant As Decimal) As String
        If montant = 0 Then Return "—"
        Return montant.ToString("N2") & " $"
    End Function

    Private Function FormatMontant(montant As Decimal) As String
        If montant = 0 Then Return "0,00 $"
        If montant < 0 Then Return "(" & Math.Abs(montant).ToString("N2") & " $)"
        Return montant.ToString("N2") & " $"
    End Function

End Class
