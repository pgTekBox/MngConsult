Imports System.Text

Public Class wbfRapportPlanComptable
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            ViewState("Filter") = "ALL"
            lblDate.Text = DateTime.Now.ToString("yyyy-MM-dd HH:mm")
            BuildReport()
        End If
    End Sub

    ' ── Filtres ──

    Protected Sub btnFilterAll_Click(sender As Object, e As EventArgs) Handles btnFilterAll.Click
        ViewState("Filter") = "ALL"
        BuildReport()
    End Sub

    Protected Sub btnFilterBilan_Click(sender As Object, e As EventArgs) Handles btnFilterBilan.Click
        ViewState("Filter") = "BILAN"
        BuildReport()
    End Sub

    Protected Sub btnFilterResultat_Click(sender As Object, e As EventArgs) Handles btnFilterResultat.Click
        ViewState("Filter") = "RESULTAT"
        BuildReport()
    End Sub

    ' ── Construction du rapport ──

    Private Sub BuildReport()
        Dim filtre As String = If(ViewState("Filter") IsNot Nothing, ViewState("Filter").ToString(), "ALL")

        ' 1. Récupérer les classes (Niveau 1)
        Dim dsClasses As DataSet = GetClasses(filtre)
        If dsClasses Is Nothing OrElse dsClasses.Tables.Count = 0 Then Return
        Dim dtClasses As DataTable = dsClasses.Tables(0)

        ' 2. Récupérer les sous-classes (Niveau 2)
        Dim dsSousClasses As DataSet = GetSousClasses()
        Dim dtSousClasses As DataTable = Nothing
        If dsSousClasses IsNot Nothing AndAlso dsSousClasses.Tables.Count > 0 Then
            dtSousClasses = dsSousClasses.Tables(0)
        End If

        ' 3. Récupérer tous les comptes
        Dim dsComptes As DataSet = GetComptes(filtre)
        Dim dtComptes As DataTable = Nothing
        If dsComptes IsNot Nothing AndAlso dsComptes.Tables.Count > 0 Then
            dtComptes = dsComptes.Tables(0)
        End If

        Dim sb As New StringBuilder()
        Dim totalComptes As Integer = 0
        Dim summaryRows As New List(Of String)

        ' 4. Boucler par classe
        For Each rowClasse As DataRow In dtClasses.Rows

            Dim classeId As Integer = CInt(rowClasse("Id"))
            Dim classeDesc As String = rowClasse("Description").ToString()
            Dim classeCode As String = rowClasse("Code").ToString()
            Dim numDebut As String = If(IsDBNull(rowClasse("NumeroDebut")), "", rowClasse("NumeroDebut").ToString())
            Dim numFin As String = If(IsDBNull(rowClasse("NumeroFin")), "", rowClasse("NumeroFin").ToString())
            Dim groupe As String = If(IsDBNull(rowClasse("GroupeEtatFinancier")), "", rowClasse("GroupeEtatFinancier").ToString())
            Dim typeBilan As String = If(IsDBNull(rowClasse("TypeBilan")), "", rowClasse("TypeBilan").ToString())
            Dim sens As String = If(IsDBNull(rowClasse("Sens")), "", rowClasse("Sens").ToString())

            Dim badgeEtat As String = If(groupe = "BILAN", "badge-bilan", "badge-resultat")
            Dim comptesClasse As Integer = 0

            sb.AppendLine("<div class=""classe-group"">")

            ' En-tête de classe
            sb.AppendLine("  <div class=""classe-header"">")
            sb.AppendLine("    <div>")
            sb.AppendFormat("      {0} — {1}", classeCode, classeDesc).AppendLine()
            If numDebut <> "" AndAlso numFin <> "" Then
                sb.AppendFormat("      <span class=""plage"">({0} à {1})</span>", numDebut, numFin).AppendLine()
            End If
            sb.AppendLine("    </div>")
            sb.AppendFormat("    <span class=""badge-etat {0}"">{1}</span>", badgeEtat, groupe).AppendLine()
            sb.AppendLine("  </div>")

            ' Sous-classes de cette classe
            If dtSousClasses IsNot Nothing Then
                Dim sousClasses = dtSousClasses.Select("ParentId = " & classeId, "Ordre ASC")

                For Each rowSC As DataRow In sousClasses
                    Dim scId As Integer = CInt(rowSC("Id"))
                    Dim scCode As String = rowSC("Code").ToString()
                    Dim scDesc As String = rowSC("Description").ToString()
                    Dim scDebut As String = If(IsDBNull(rowSC("NumeroDebut")), "", rowSC("NumeroDebut").ToString())
                    Dim scFin As String = If(IsDBNull(rowSC("NumeroFin")), "", rowSC("NumeroFin").ToString())

                    ' En-tête sous-classe
                    sb.AppendLine("  <div class=""sous-classe-header"">")
                    sb.AppendFormat("    <span class=""sc-code"">{0}</span>", scCode).AppendLine()
                    sb.AppendFormat("    <span>{0}</span>", scDesc).AppendLine()
                    If scDebut <> "" AndAlso scFin <> "" Then
                        sb.AppendFormat("    <span class=""sc-plage"">{0} – {1}</span>", scDebut, scFin).AppendLine()
                    End If
                    sb.AppendLine("  </div>")

                    ' Comptes de cette sous-classe
                    If dtComptes IsNot Nothing Then
                        Dim comptes = dtComptes.Select("ClasseId = " & scId, "Ordre ASC")

                        If comptes.Length > 0 Then
                            sb.AppendLine("  <table class=""comptes-table"">")
                            sb.AppendLine("    <thead><tr>")
                            sb.AppendLine("      <th>Numéro</th>")
                            sb.AppendLine("      <th>Nom du compte</th>")
                            sb.AppendLine("      <th>Description</th>")
                            sb.AppendLine("      <th class=""col-type"">Type</th>")
                            sb.AppendLine("      <th class=""col-sens"">Sens</th>")
                            sb.AppendLine("      <th class=""col-actif"">Actif</th>")
                            sb.AppendLine("    </tr></thead>")
                            sb.AppendLine("    <tbody>")

                            For Each rowC As DataRow In comptes
                                Dim cNumero As String = rowC("Numero").ToString()
                                Dim cNom As String = rowC("Nom").ToString()
                                Dim cDesc As String = If(IsDBNull(rowC("Description")), "", rowC("Description").ToString())
                                Dim [cType] As String = If(IsDBNull(rowC("TypeBilan")), "", rowC("TypeBilan").ToString())
                                Dim cSens As String = If(IsDBNull(rowC("Sens")), "", rowC("Sens").ToString())
                                Dim cActif As Boolean = (Not IsDBNull(rowC("Actif")) AndAlso CBool(rowC("Actif")))

                                Dim sensBadge As String = If(cSens = "D", "badge-d", "badge-c")
                                Dim sensLabel As String = If(cSens = "D", "D", "C")
                                Dim dotClass As String = If(cActif, "dot-oui", "dot-non")

                                sb.AppendLine("    <tr>")
                                sb.AppendFormat("      <td class=""col-numero"">{0}</td>", cNumero).AppendLine()
                                sb.AppendFormat("      <td class=""col-nom"">{0}</td>", cNom).AppendLine()
                                sb.AppendFormat("      <td class=""col-desc"">{0}</td>", cDesc).AppendLine()
                                sb.AppendFormat("      <td class=""col-type"">{0}</td>", [cType]).AppendLine()
                                sb.AppendFormat("      <td class=""col-sens""><span class=""badge-sm {0}"">{1}</span></td>", sensBadge, sensLabel).AppendLine()
                                sb.AppendFormat("      <td class=""col-actif""><span class=""dot-actif {0}""></span></td>", dotClass).AppendLine()
                                sb.AppendLine("    </tr>")

                                comptesClasse += 1
                            Next

                            sb.AppendLine("    </tbody>")
                            sb.AppendLine("  </table>")
                        End If
                    End If
                Next
            End If

            ' Footer avec compteur
            sb.AppendFormat("  <div class=""classe-footer"">{0} compte(s)</div>", comptesClasse).AppendLine()
            sb.AppendLine("</div>")

            totalComptes += comptesClasse
            summaryRows.Add(String.Format("<tr><td>{0} — {1}</td><td class=""num"">{2}</td></tr>",
                classeCode, classeDesc, comptesClasse))
        Next

        ' Sommaire
        summaryRows.Add(String.Format("<tr><td>Total</td><td class=""num"">{0}</td></tr>", totalComptes))

        Dim sbSummary As New StringBuilder()
        sbSummary.AppendLine("<table class=""summary-table"">")
        For Each row As String In summaryRows
            sbSummary.AppendLine(row)
        Next
        sbSummary.AppendLine("</table>")

        litSummary.Text = sbSummary.ToString()
        phReport.Controls.Add(New LiteralControl(sb.ToString()))

        lblInfo.Text = String.Format("{0} classe(s) · {1} compte(s)", dtClasses.Rows.Count, totalComptes)
    End Sub

    ' ── Accès aux données ──

    Private Function GetClasses(filtre As String) As DataSet
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@Filtre", filtre))

        Return ExecuteSQLds("s0082GetClassesForReport", p)
    End Function

    Private Function GetSousClasses() As DataSet
        Return ExecuteSQLds("s0083GetSousClassesForReport")
    End Function

    Private Function GetComptes(filtre As String) As DataSet
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Filtre", filtre))

        Return ExecuteSQLds("s0084GetComptesForReport", p)
    End Function

End Class
