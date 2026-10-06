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
        ' Hors Québec : mêmes colonnes, mais c'est la commission de la province (WSIB, WCB…) — son plafond de gains
        ' assurables, ses classes, ses primes. Le plafond est celui en vigueur à la fin de l'année ; 0 = aucun plafond connu.
        Dim horsQuebec = Contexte.HorsQuebec
        Dim noms = Contexte.Libelles
        Dim prm = ParametresAnnee.Pour(AnneeChoisie)
        Dim prmProvince = If(horsQuebec, prm.PourProvince(Contexte.Province, New Date(AnneeChoisie, 12, 31)), Nothing)
        Dim maximum = If(Not horsQuebec, prm.CNESSTMaxAssurable, If(prmProvince Is Nothing, 0D, prmProvince.AccidentsMaxAssurable))
        Dim taux = Convert.ToDecimal(Db.Scalaire("SELECT TauxCNESST FROM paie.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId)))

        If horsQuebec Then Title = "Gains assurables " & noms.Accidents
        Dim sb As New StringBuilder("<div class=""carte table-defilante""><table class=""liste""><thead><tr><th>Employé</th><th>")
        sb.Append(If(horsQuebec, "Classe", "Unité")).Append("</th>")
        sb.Append("<th class=""num"">Salaire brut</th><th class=""num"">Excédent du maximum")
        If maximum > 0D Then sb.Append(" (").Append(Argent(maximum)).Append(")")
        sb.Append("</th>")
        sb.Append("<th class=""num"">Salaire assurable</th><th class=""num"">").Append(If(horsQuebec, "Prime calculée", "Cotisation calculée")).Append("</th></tr></thead><tbody>")
        Dim tBrut, tExcedent, tAssurable, tCotisation As Decimal
        For Each r As DataRow In employes.Rows
            tBrut += r.Dcm("Brut") : tExcedent += r.Dcm("Excedent") : tAssurable += r.Dcm("Assurable") : tCotisation += r.Dcm("Cotisation")
            sb.Append("<tr><td>").Append(HttpUtility.HtmlEncode(r.Txt("Nom") & ", " & r.Txt("Prenom")))
            If r.Bln("ExemptCNESST") Then sb.Append("<div class=""note"">").Append(If(horsQuebec, "exclu de la couverture des accidents du travail (fiche de l'employé)", "exclu de la CNESST (fiche de l'employé)")).Append("</div>")
            sb.Append("</td><td>").Append(HttpUtility.HtmlEncode(If(r.Txt("Unite").Length = 0, "—", r.Txt("Unite"))))
            sb.Append("</td><td class=""num"">").Append(Argent(r("Brut"))).Append("</td><td class=""num"">").Append(Argent(r("Excedent")))
            sb.Append("</td><td class=""num"">").Append(Argent(r("Assurable"))).Append("</td><td class=""num"">").Append(Argent(r("Cotisation"))).Append("</td></tr>")
        Next
        sb.Append("</tbody><tfoot><tr><td>Total</td><td></td><td class=""num"">").Append(Argent(tBrut)).Append("</td><td class=""num"">").Append(Argent(tExcedent))
        sb.Append("</td><td class=""num"">").Append(Argent(tAssurable)).Append("</td><td class=""num"">").Append(Argent(tCotisation)).Append("</td></tr></tfoot></table></div>")

        ' Par unité de classification : ce que la Déclaration des salaires demande.
        Dim unites = ServiceCNESST.ParUnite(AnneeChoisie)
        If unites.Rows.Count > 1 OrElse (unites.Rows.Count = 1 AndAlso unites.Rows(0).Txt("Code").Length > 0) Then
            sb.Append("<div class=""carte table-defilante""><h2>").Append(If(horsQuebec, "Par classe", "Par unité de classification")).Append("</h2><table class=""liste""><thead><tr><th>").Append(If(horsQuebec, "Classe", "Unité")).Append("</th><th>Description</th>")
            sb.Append("<th class=""num"">Taux ($ / 100 $)</th><th class=""num"">Employés</th><th class=""num"">Salaire assurable</th><th class=""num"">").Append(If(horsQuebec, "Prime", "Cotisation")).Append("</th></tr></thead><tbody>")
            For Each u As DataRow In unites.Rows
                sb.Append("<tr><td>").Append(HttpUtility.HtmlEncode(If(u.Txt("Code").Length = 0, "—", u.Txt("Code")))).Append("</td><td>").Append(HttpUtility.HtmlEncode(u.Txt("Description")))
                sb.Append("</td><td class=""num"">").Append(If(u.IsNull("Taux"), "", u.Dcm("Taux").ToString("0.00##", FrCa))).Append("</td><td class=""num"">").Append(u.Ent("NbEmployes"))
                sb.Append("</td><td class=""num"">").Append(Argent(u("Assurable"))).Append("</td><td class=""num"">").Append(Argent(u("Cotisation"))).Append("</td></tr>")
            Next
            If horsQuebec Then
                sb.Append("</tbody></table><p class=""note"">Une ligne par classe ; « — » regroupe les paies calculées au taux de la compagnie. ")
                sb.Append("Un employé qui a changé de classe en cours d'année compte dans chacune, pour la période correspondante.</p></div>")
            Else
                sb.Append("</tbody></table><p class=""note"">Une ligne par unité de votre décision de classification ; « — » regroupe les paies calculées au taux de la compagnie. ")
                sb.Append("Un employé qui a changé d'unité en cours d'année compte dans chacune, pour la période correspondante.</p></div>")
            End If
        End If

        sb.Append("<div class=""grille-cartes""><div class=""carte""><h2>Par mois</h2><table class=""liste""><thead><tr><th>Mois</th>")
        sb.Append("<th class=""num"">Salaire assurable</th><th class=""num"">").Append(If(horsQuebec, "Prime", "Cotisation")).Append("</th></tr></thead><tbody>")
        For Each m As DataRow In ServiceCNESST.ParMois(AnneeChoisie).Rows
            sb.Append("<tr><td>").Append(FrCa.DateTimeFormat.GetMonthName(m.Ent("Mois"))).Append("</td><td class=""num"">").Append(Argent(m("Assurable")))
            sb.Append("</td><td class=""num"">").Append(Argent(m("Cotisation"))).Append("</td></tr>")
        Next
        sb.Append("</tbody></table></div>")

        If horsQuebec Then
            ' La prime se paie directement à la commission : aucune remise n'est enregistrée ici, il n'y a donc rien à concilier.
            sb.Append("<div class=""carte""><h2>").Append(HttpUtility.HtmlEncode("Prime " & noms.Accidents)).Append("</h2><table class=""liste""><tbody>")
            sb.Append("<tr><td>Taux de prime de la compagnie</td><td class=""num"">").Append(taux.ToString("0.00##", FrCa)).Append(" $ / 100 $</td></tr>")
            sb.Append("<tr><td>Gains assurables de l'année</td><td class=""num"">").Append(Argent(tAssurable)).Append("</td></tr>")
            sb.Append("<tr><td><strong>Prime calculée sur les paies</strong></td><td class=""num""><strong>").Append(Argent(tCotisation)).Append("</strong></td></tr></tbody></table>")
            sb.Append("<p class=""note"">Les gains assurables se déclarent et la prime se paie à la commission des accidents du travail de la province, selon la fréquence qu'elle vous a attribuée ")
            sb.Append("(mensuelle, trimestrielle ou annuelle), puis se concilient une fois l'an. La prime ne fait pas partie des remises au Receveur général. ")
            sb.Append("Les gains des travailleurs non couverts doivent être exclus selon les règles de la commission.</p></div></div>")
            litRapport.Text = sb.ToString()
            Return
        End If

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
        Dim lignes As New List(Of String()) From {New String() {"Nom", "Prénom", If(Contexte.HorsQuebec, "Classe", "Unité"), "Salaire brut", "Excédent", "Salaire assurable",
                                                                If(Contexte.HorsQuebec, "Prime calculée", "Cotisation calculée")}}
        For Each r As DataRow In ServiceCNESST.ParEmploye(AnneeChoisie).Rows
            lignes.Add({r.Txt("Nom"), r.Txt("Prenom"), r.Txt("Unite"), Nb(r, "Brut"), Nb(r, "Excedent"), Nb(r, "Assurable"), Nb(r, "Cotisation")})
        Next
        ' « wsib-2026.csv » en Ontario (nom d'origine), « accidents-ab-2026.csv » dans les autres provinces.
        Dim prefixe = If(Contexte.EnOntario, "wsib-", If(Contexte.HorsQuebec, "accidents-" & Provinces.Code(Contexte.Province).ToLowerInvariant() & "-", "cnesst-"))
        EnvoyerCsv(prefixe & AnneeChoisie.ToString() & ".csv", lignes)
    End Sub

    Private Shared Function Nb(r As DataRow, colonne As String) As String
        Return r.Dcm(colonne).ToString("0.00", FrCa)
    End Function

End Class
