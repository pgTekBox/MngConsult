Imports System.Globalization
Imports System.Text
Imports Paie60Sec.Calcul

Public Class PageCNESST
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            For Each a In ServiceFeuillets.AnneesDisponibles()
                ddlAnnee.Items.Add(a.ToString())
            Next
        End If
        btnCsv.Visible = ddlAnnee.Items.Count > 0
        lblAucun.Visible = ddlAnnee.Items.Count = 0
    End Sub

    Private ReadOnly Property AnneeChoisie As Integer
        Get
            Return Integer.Parse(ddlAnnee.SelectedValue)
        End Get
    End Property

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        If ddlAnnee.Items.Count = 0 Then Return
        Dim employes = ServiceCNESST.ParEmploye(AnneeChoisie)
        Dim maximum = ParametresAnnee.Pour(AnneeChoisie).CNESSTMaxAssurable
        Dim taux = Convert.ToDecimal(Db.Scalaire("SELECT TauxCNESST FROM paie.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId)))

        Dim sb As New StringBuilder("<div class=""carte table-defilante""><table class=""liste""><thead><tr><th>Employé</th>")
        sb.Append("<th class=""num"">Salaire brut</th><th class=""num"">Excédent du maximum (").Append(Argent(maximum)).Append(")</th>")
        sb.Append("<th class=""num"">Salaire assurable</th><th class=""num"">Cotisation calculée</th></tr></thead><tbody>")
        Dim tBrut, tExcedent, tAssurable, tCotisation As Decimal
        For Each r As DataRow In employes.Rows
            tBrut += r.Dcm("Brut") : tExcedent += r.Dcm("Excedent") : tAssurable += r.Dcm("Assurable") : tCotisation += r.Dcm("Cotisation")
            sb.Append("<tr><td>").Append(HttpUtility.HtmlEncode(r.Txt("Nom") & ", " & r.Txt("Prenom")))
            If r.Bln("ExemptCNESST") Then sb.Append("<div class=""note"">exclu de la CNESST (fiche de l'employé)</div>")
            sb.Append("</td><td class=""num"">").Append(Argent(r("Brut"))).Append("</td><td class=""num"">").Append(Argent(r("Excedent")))
            sb.Append("</td><td class=""num"">").Append(Argent(r("Assurable"))).Append("</td><td class=""num"">").Append(Argent(r("Cotisation"))).Append("</td></tr>")
        Next
        sb.Append("</tbody><tfoot><tr><td>Total</td><td class=""num"">").Append(Argent(tBrut)).Append("</td><td class=""num"">").Append(Argent(tExcedent))
        sb.Append("</td><td class=""num"">").Append(Argent(tAssurable)).Append("</td><td class=""num"">").Append(Argent(tCotisation)).Append("</td></tr></tfoot></table></div>")

        sb.Append("<div class=""grille-cartes""><div class=""carte""><h2>Par mois</h2><table class=""liste""><thead><tr><th>Mois</th>")
        sb.Append("<th class=""num"">Salaire assurable</th><th class=""num"">Cotisation</th></tr></thead><tbody>")
        For Each m As DataRow In ServiceCNESST.ParMois(AnneeChoisie).Rows
            sb.Append("<tr><td>").Append(FrCa.DateTimeFormat.GetMonthName(m.Ent("Mois"))).Append("</td><td class=""num"">").Append(Argent(m("Assurable")))
            sb.Append("</td><td class=""num"">").Append(Argent(m("Cotisation"))).Append("</td></tr>")
        Next
        sb.Append("</tbody></table></div>")

        Dim payes = ServiceCNESST.VersementsPayes(AnneeChoisie)
        sb.Append("<div class=""carte""><h2>Conciliation</h2><table class=""liste""><tbody>")
        sb.Append("<tr><td>Taux de versement périodique</td><td class=""num"">").Append(taux.ToString("0.00##", FrCa)).Append(" $ / 100 $</td></tr>")
        sb.Append("<tr><td>Cotisation calculée sur les paies</td><td class=""num"">").Append(Argent(tCotisation)).Append("</td></tr>")
        sb.Append("<tr><td>Versements périodiques enregistrés (remises à Revenu Québec)</td><td class=""num"">").Append(Argent(payes)).Append("</td></tr>")
        sb.Append("<tr><td><strong>Écart</strong></td><td class=""num""><strong>").Append(Argent(tCotisation - payes)).Append("</strong></td></tr></tbody></table>")
        sb.Append("<p class=""note"">La Déclaration des salaires se produit dans Mon Espace CNESST avant le 15 mars. La CNESST établit ensuite la prime réelle ")
        sb.Append("et l'ajuste par rapport aux versements périodiques. Les salaires des travailleurs non couverts doivent être exclus selon les règles de la CNESST.</p></div></div>")
        litRapport.Text = sb.ToString()
    End Sub

    Private Sub btnCsv_Click(sender As Object, e As EventArgs) Handles btnCsv.Click
        Dim lignes As New List(Of String()) From {New String() {"Nom", "Prénom", "Salaire brut", "Excédent", "Salaire assurable", "Cotisation calculée"}}
        For Each r As DataRow In ServiceCNESST.ParEmploye(AnneeChoisie).Rows
            lignes.Add({r.Txt("Nom"), r.Txt("Prenom"), Nb(r, "Brut"), Nb(r, "Excedent"), Nb(r, "Assurable"), Nb(r, "Cotisation")})
        Next
        EnvoyerCsv("cnesst-" & AnneeChoisie.ToString() & ".csv", lignes)
    End Sub

    Private Shared Function Nb(r As DataRow, colonne As String) As String
        Return r.Dcm(colonne).ToString("0.00", FrCa)
    End Function

End Class
