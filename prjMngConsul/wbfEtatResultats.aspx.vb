Imports System.Text

Public Class wbfEtatResultats
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            ' Par défaut : exercice courant (1er janvier au aujourd'hui)
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

        ' Récupérer les soldes par compte pour la période
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@DateDebut", dateDebut))
        p.Add(New SqlClient.SqlParameter("@DateFin", dateFin))
        Dim ds As DataSet = ExecuteSQLds("s0085GetEtatResultats", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 Then
            litReport.Text = "<p style='padding:20px; color:#64748b;'>Aucune donnée pour cette période.</p>"
            Return
        End If

        Dim dt As DataTable = ds.Tables(0)

        Dim sb As New StringBuilder()
        sb.AppendLine("<table class=""er-table"">")

        ' ══════════════════════════════════════════
        ' REVENUS (ClasseParentId = 6)
        ' ══════════════════════════════════════════
        Dim totalRevenus As Decimal = 0
        totalRevenus = RenderSection(sb, dt, 6, "Revenus", totalRevenus)

        ' Total Revenus
        RenderTotalRow(sb, "Total des revenus", totalRevenus)
        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' COÛT DES VENTES (ClasseParentId = 7)
        ' ══════════════════════════════════════════
        Dim totalCDV As Decimal = 0
        totalCDV = RenderSection(sb, dt, 7, "Coût des ventes", totalCDV)

        ' Total CDV
        RenderTotalRow(sb, "Total du coût des ventes", totalCDV)
        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' BÉNÉFICE BRUT
        ' ══════════════════════════════════════════
        Dim beneficeBrut As Decimal = totalRevenus - totalCDV
        RenderCalcRow(sb, "Bénéfice brut", beneficeBrut)
        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' CHARGES D'EXPLOITATION (ClasseParentId = 8)
        ' ══════════════════════════════════════════
        Dim totalCharges As Decimal = 0
        totalCharges = RenderSection(sb, dt, 8, "Charges d'exploitation", totalCharges)

        ' Total Charges
        RenderTotalRow(sb, "Total des charges d'exploitation", totalCharges)
        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' BÉNÉFICE AVANT IMPÔTS (BAII)
        ' ══════════════════════════════════════════
        Dim baii As Decimal = beneficeBrut - totalCharges
        RenderCalcRow(sb, "Bénéfice avant impôts et éléments extraordinaires", baii)
        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' IMPÔTS ET ÉLÉMENTS EXTRAORDINAIRES (ClasseParentId = 9)
        ' ══════════════════════════════════════════
        Dim totalImpots As Decimal = 0
        totalImpots = RenderSection(sb, dt, 9, "Impôts et éléments extraordinaires", totalImpots)

        ' Total Impôts
        RenderTotalRow(sb, "Total des impôts et éléments extraordinaires", totalImpots)
        RenderSpacer(sb)

        ' ══════════════════════════════════════════
        ' BÉNÉFICE NET
        ' ══════════════════════════════════════════
        Dim beneficeNet As Decimal = baii - totalImpots
        RenderNetRow(sb, "Bénéfice net", beneficeNet)

        sb.AppendLine("</table>")

        litReport.Text = sb.ToString()
        lblInfo.Text = String.Format("Période : {0} au {1}", dateDebut.ToString("yyyy-MM-dd"), dateFin.ToString("yyyy-MM-dd"))
    End Sub

    ' ── Rendu d'une section complète (classe + sous-classes + comptes) ──

    Private Function RenderSection(sb As StringBuilder, dt As DataTable, classeParentId As Integer, sectionTitle As String, runningTotal As Decimal) As Decimal

        ' En-tête de section
        sb.AppendLine("<tr class=""er-section"">")
        sb.AppendFormat("  <td colspan=""2"">{0}</td>", sectionTitle).AppendLine()
        sb.AppendLine("  <td></td>")
        sb.AppendLine("</tr>")

        ' Grouper par sous-classe
        Dim sousClasses = (From r In dt.AsEnumerable()
                           Where CInt(r("ClasseParentId")) = classeParentId
                           Group r By scId = CInt(r("ClasseId")),
                                       scNom = r("SousClasseDescription").ToString()
                           Into grp = Group
                           Order By grp.First()("ClasseOrdre")
                           Select New With {.Id = scId, .Nom = scNom, .Comptes = grp}).ToList()

        For Each sc In sousClasses

            ' En-tête sous-classe
            sb.AppendLine("<tr class=""er-sub-header"">")
            sb.AppendFormat("  <td colspan=""2"">{0}</td>", sc.Nom).AppendLine()
            sb.AppendLine("  <td></td>")
            sb.AppendLine("</tr>")

            Dim subTotal As Decimal = 0

            ' Comptes
            For Each row In sc.Comptes
                Dim numero As String = row("Numero").ToString()
                Dim nom As String = row("Nom").ToString()
                Dim solde As Decimal = If(IsDBNull(row("Solde")), 0D, CDec(row("Solde")))

                subTotal += solde

                sb.AppendLine("<tr class=""er-line"">")
                sb.AppendFormat("  <td class=""account-num"">{0}</td>", numero).AppendLine()
                sb.AppendFormat("  <td class=""account-name"">{0}</td>", nom).AppendLine()
                sb.AppendFormat("  <td class=""er-amount {0}"">{1}</td>", GetAmountClass(solde), FormatMontant(solde)).AppendLine()
                sb.AppendLine("</tr>")
            Next

            ' Sous-total de sous-classe
            sb.AppendLine("<tr class=""er-sub-total"">")
            sb.AppendFormat("  <td></td>").AppendLine()
            sb.AppendFormat("  <td>Total — {0}</td>", sc.Nom).AppendLine()
            sb.AppendFormat("  <td class=""er-amount {0}"">{1}</td>", GetAmountClass(subTotal), FormatMontant(subTotal)).AppendLine()
            sb.AppendLine("</tr>")

            runningTotal += subTotal
        Next

        Return runningTotal
    End Function

    ' ── Lignes spéciales ──

    Private Sub RenderTotalRow(sb As StringBuilder, label As String, montant As Decimal)
        sb.AppendLine("<tr class=""er-total"">")
        sb.AppendFormat("  <td></td>").AppendLine()
        sb.AppendFormat("  <td>{0}</td>", label).AppendLine()
        sb.AppendFormat("  <td class=""er-amount {0}"">{1}</td>", GetAmountClass(montant), FormatMontant(montant)).AppendLine()
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderCalcRow(sb As StringBuilder, label As String, montant As Decimal)
        sb.AppendLine("<tr class=""er-calc"">")
        sb.AppendFormat("  <td></td>").AppendLine()
        sb.AppendFormat("  <td>{0}</td>", label).AppendLine()
        sb.AppendFormat("  <td class=""er-amount {0}"">{1}</td>", GetAmountClass(montant), FormatMontant(montant)).AppendLine()
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderNetRow(sb As StringBuilder, label As String, montant As Decimal)
        sb.AppendLine("<tr class=""er-net"">")
        sb.AppendFormat("  <td></td>").AppendLine()
        sb.AppendFormat("  <td>{0}</td>", label).AppendLine()
        sb.AppendFormat("  <td class=""er-amount"">{0}</td>", FormatMontant(montant)).AppendLine()
        sb.AppendLine("</tr>")
    End Sub

    Private Sub RenderSpacer(sb As StringBuilder)
        sb.AppendLine("<tr class=""er-spacer""><td colspan=""3""></td></tr>")
    End Sub

    ' ── Formatage ──

    Private Function FormatMontant(montant As Decimal) As String
        If montant = 0 Then Return "—"
        If montant < 0 Then
            Return "(" & Math.Abs(montant).ToString("N2") & " $)"
        End If
        Return montant.ToString("N2") & " $"
    End Function

    Private Function GetAmountClass(montant As Decimal) As String
        If montant > 0 Then Return "amt-positive"
        If montant < 0 Then Return "amt-negative"
        Return "amt-zero"
    End Function

End Class
