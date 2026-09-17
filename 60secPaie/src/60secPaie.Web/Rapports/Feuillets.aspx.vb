Imports System.Text

Public Class PageFeuillets
    Inherits PageBase

    Private Shared ReadOnly ColonnesT4 As String() = {"14", "22", "17", "17A", "18", "55", "24", "26", "56"}
    Private Shared ReadOnly ColonnesR1 As String() = {"A", "E"}

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            For Each a In ServiceFeuillets.AnneesDisponibles()
                ddlAnnee.Items.Add(a.ToString())
            Next
        End If
        pnlContenu.Visible = ddlAnnee.Items.Count > 0
        btnCsv.Visible = ddlAnnee.Items.Count > 0
        lblAucun.Visible = ddlAnnee.Items.Count = 0
    End Sub

    Private ReadOnly Property Annee As Integer
        Get
            Return Integer.Parse(ddlAnnee.SelectedValue)
        End Get
    End Property

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        If ddlAnnee.Items.Count = 0 Then Return
        Dim feuillets = ServiceFeuillets.Preparer(Annee)

        Dim sb As New StringBuilder("<table class=""liste""><thead><tr><th rowspan=""2"">Employé</th>")
        sb.Append("<th colspan=""").Append(ColonnesT4.Length).Append(""">T4 (cases)</th><th colspan=""").Append(ColonnesR1.Length).Append(""">Relevé 1</th><th rowspan=""2""></th></tr><tr>")
        For Each c In ColonnesT4
            sb.Append("<th class=""num"">").Append(c).Append("</th>")
        Next
        For Each c In ColonnesR1
            sb.Append("<th class=""num"">").Append(c).Append("</th>")
        Next
        sb.Append("</tr></thead><tbody>")

        Dim totaux As New Dictionary(Of String, Decimal)()
        For Each f In feuillets
            sb.Append("<tr><td>").Append(HttpUtility.HtmlEncode(f.NomComplet))
            If f.ContientCumulatifsDepart Then sb.Append("<div class=""note"">inclut des cumulatifs de départ</div>")
            sb.Append("</td>")
            For Each c In ColonnesT4
                Cellule(sb, totaux, "T4" & c, f.CaseT4(c))
            Next
            For Each c In ColonnesR1
                Cellule(sb, totaux, "R1" & c, f.CaseR1(c))
            Next
            sb.Append("<td><a href=""Feuillet.aspx?employe=").Append(f.Employe.Ent("Id")).Append("&amp;annee=").Append(Annee).Append(""">Feuillet</a></td></tr>")
        Next

        sb.Append("</tbody><tfoot><tr><td>Total (").Append(feuillets.Count).Append(If(feuillets.Count > 1, " feuillets)", " feuillet)")).Append("</td>")
        For Each c In ColonnesT4
            sb.Append("<td class=""num"">").Append(Argent(Total(totaux, "T4" & c))).Append("</td>")
        Next
        For Each c In ColonnesR1
            sb.Append("<td class=""num"">").Append(Argent(Total(totaux, "R1" & c))).Append("</td>")
        Next
        sb.Append("<td></td></tr></tfoot></table>")
        litTableau.Text = sb.ToString()

        litSommaire.Text = Sommaire(Total(totaux, "T417") + Total(totaux, "T417A"), Total(totaux, "T418"), Total(totaux, "T455"))
    End Sub

    Private Shared Sub Cellule(sb As StringBuilder, totaux As Dictionary(Of String, Decimal), cle As String, montant As Decimal)
        totaux(cle) = Total(totaux, cle) + montant
        sb.Append("<td class=""num"">").Append(If(montant = 0D, "", Argent(montant))).Append("</td>")
    End Sub

    Private Shared Function Total(totaux As Dictionary(Of String, Decimal), cle As String) As Decimal
        Dim v As Decimal
        Return If(totaux.TryGetValue(cle, v), v, 0D)
    End Function

    Private Function Sommaire(rrqEmployes As Decimal, aeEmployes As Decimal, rqapEmployes As Decimal) As String
        Dim s = ServiceFeuillets.SommaireEmployeur(Annee)
        Dim sb As New StringBuilder("<div class=""grille-cartes"">")

        sb.Append("<div class=""carte""><h2>Sommaire T4 (ARC)</h2><table class=""liste""><tbody>")
        Ligne(sb, "Cotisations des employés à l'AE (case 18)", aeEmployes)
        Ligne(sb, "Cotisations de l'employeur à l'AE (case 19)", s.Dcm("EmployeurAE"))
        Ligne(sb, "Retenues et cotisations de l'année", s.Dcm("DuFederal"))
        Ligne(sb, "Remises enregistrées", s.Dcm("PayeFederal"))
        Ligne(sb, "Solde à payer", s.Dcm("DuFederal") - s.Dcm("PayeFederal"))
        sb.Append("</tbody></table></div>")

        sb.Append("<div class=""carte""><h2>Sommaire 1 (Revenu Québec)</h2><table class=""liste""><tbody>")
        Ligne(sb, "RRQ - employés", rrqEmployes)
        Ligne(sb, "RRQ - employeur", s.Dcm("EmployeurRRQ"))
        Ligne(sb, "RQAP - employés", rqapEmployes)
        Ligne(sb, "RQAP - employeur", s.Dcm("EmployeurRQAP"))
        Ligne(sb, "Salaires assujettis au FSS", s.Dcm("MasseFSS"))
        Ligne(sb, "Cotisation au FSS", s.Dcm("FSS"))
        Ligne(sb, "CNESST - versements périodiques calculés", s.Dcm("CNESST"))
        Ligne(sb, "Retenues et cotisations de l'année", s.Dcm("DuQuebec"))
        Ligne(sb, "Remises enregistrées", s.Dcm("PayeQuebec"))
        Ligne(sb, "Solde à payer", s.Dcm("DuQuebec") - s.Dcm("PayeQuebec"))
        Ligne(sb, "Cotisation aux normes du travail (CNT), payable avec le sommaire 1", s.Dcm("CNT"))
        sb.Append("</tbody></table><p class=""note"">Le taux réel du FSS est établi sur la masse salariale totale de l'année : " &
                  "un écart avec le taux estimé utilisé pendant l'année se règle dans le sommaire 1.</p></div>")
        Return sb.Append("</div>").ToString()
    End Function

    Private Shared Sub Ligne(sb As StringBuilder, libelle As String, montant As Decimal)
        sb.Append("<tr><td>").Append(HttpUtility.HtmlEncode(libelle)).Append("</td><td class=""num"">").Append(Argent(montant)).Append("</td></tr>")
    End Sub

    Private Sub btnCsv_Click(sender As Object, e As EventArgs) Handles btnCsv.Click
        Dim lignes As New List(Of String())()
        Dim entete As New List(Of String) From {"Code", "Nom", "Prénom"}
        entete.AddRange(ServiceFeuillets.LibellesT4.Select(Function(c) "T4 case " & c.Key))
        entete.AddRange(ServiceFeuillets.LibellesR1.Select(Function(c) "R1 case " & c.Key))
        lignes.Add(entete.ToArray())

        ' Le NAS n'est volontairement pas exporté.
        For Each f In ServiceFeuillets.Preparer(Annee)
            Dim ligne As New List(Of String) From {f.Employe.Txt("Code"), f.Employe.Txt("Nom"), f.Employe.Txt("Prenom")}
            ligne.AddRange(ServiceFeuillets.LibellesT4.Select(Function(c) f.CaseT4(c.Key).ToString("0.00", FrCa)))
            ligne.AddRange(ServiceFeuillets.LibellesR1.Select(Function(c) f.CaseR1(c.Key).ToString("0.00", FrCa)))
            lignes.Add(ligne.ToArray())
        Next
        EnvoyerCsv("feuillets-" & Annee.ToString() & ".csv", lignes)
    End Sub

End Class
