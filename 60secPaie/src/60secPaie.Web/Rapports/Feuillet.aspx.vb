Imports System.Text
Imports Paie60Sec.Calcul

''' <summary>Feuillet de travail d'un employé : toutes les cases du T4 et du Relevé 1, à reporter dans les services en ligne.</summary>
Public Class PageFeuillet
    Inherits PageBase

    Private _nasComplet As Boolean

    Private Sub btnNas_Click(sender As Object, e As EventArgs) Handles btnNas.Click
        _nasComplet = True
        Contexte.Journaliser("NAS complet affiché pour le feuillet de l'employé n° " & IdRequete("employe").ToString() & ".")
    End Sub

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        Dim annee = IdRequete("annee")
        lnkRetour.NavigateUrl = "~/Rapports/Feuillets.aspx"
        If Contexte.HorsQuebec Then Title = "Feuillet T4"
        If Not ParametresAnnee.EstDisponible(annee) Then Response.Redirect("~/Rapports/Feuillets.aspx", True)

        Dim f = ServiceFeuillets.Preparer(annee).FirstOrDefault(Function(x) x.Employe.Ent("Id") = IdRequete("employe"))
        If f Is Nothing Then Response.Redirect("~/Rapports/Feuillets.aspx", True)

        Dim compagnie = Db.Ligne("paie.spCompagnie_Get", Db.P("@c", Contexte.CompagnieId))
        Dim emp = f.Employe
        Dim nas = NasDe(emp)
        Dim nasAffiche = If(nas.Length = 0, "NAS manquant dans la fiche", If(_nasComplet, nas, Secret.Masquer(nas)))
        btnNas.Visible = nas.Length > 0 AndAlso Not _nasComplet

        Dim sb As New StringBuilder("<div class=""talon"">")
        sb.Append("<div class=""talon-entete""><div><strong>").Append(H(compagnie.Txt("Nom"))).Append("</strong><br/>")
        sb.Append("N° de compte RP : ").Append(H(compagnie.Txt("NumeroEntrepriseFederal")))
        If f.AvecReleve1 Then sb.Append("<br/>N° d'identification RS : ").Append(H(compagnie.Txt("NumeroIdentificationRQ")))
        sb.Append("</div>")
        sb.Append("<div><strong>Feuillets ").Append(annee).Append("</strong><br/>").Append(H(emp.Txt("Prenom") & " " & emp.Txt("Nom"))).Append("<br/>")
        sb.Append(H(emp.Txt("Adresse1"))).Append("<br/>").Append(H(emp.Txt("Ville") & " (" & emp.Txt("Province") & ")  " & emp.Txt("CodePostal"))).Append("<br/>")
        sb.Append("NAS : ").Append(H(nasAffiche)).Append("</div></div>")

        If f.ContientCumulatifsDepart Then
            sb.Append("<div class=""avertissement"">Ces montants incluent des cumulatifs de départ saisis à la main. Les gains assurables " &
                      "(cases 24, 26, 56, G et I) ont été estimés à partir de la rémunération brute : vérifiez-les avec votre ancien système.</div>")
        End If
        If f.DeuxProvinces Then
            sb.Append("<div class=""avertissement"">").Append(H(String.Format(
                      "Cet employé a été payé dans plus d'une province pendant l'année ({0}). L'ARC demande un T4 par province d'emploi : " &
                      "les montants ci-dessous les réunissent et sont à répartir entre les feuillets.", String.Join(", ", f.ProvincesEmploi)))).Append("</div>")
        End If

        sb.Append("<div class=""talon-colonnes""><div><table><thead><tr><th colspan=""2"">T4 - État de la rémunération payée</th><th class=""num"">Montant</th></tr></thead><tbody>")
        Texte(sb, "10", "Province d'emploi", If(f.DeuxProvinces, String.Join(", ", f.ProvincesEmploi), f.Province))
        For Each c In ServiceFeuillets.LibellesT4
            Montant(sb, c.Key, c.Value, f.CaseT4(c.Key), c.Key = "14" OrElse c.Key = "22")
        Next
        Texte(sb, "28", "Exemptions", ServiceFeuillets.Exemptions(emp, f.Province))
        Dim dentaire = Math.Max(1, Math.Min(5, emp.Ent("CodeDentaireT4")))
        Texte(sb, "45", "Soins dentaires offerts par l'employeur", ServiceFeuillets.CodesDentaires(dentaire))
        sb.Append("</tbody></table></div>")

        If f.AvecReleve1 Then
            sb.Append("<div><table><thead><tr><th colspan=""2"">Relevé 1 - Revenus d'emploi et revenus divers</th><th class=""num"">Montant</th></tr></thead><tbody>")
            For Each c In ServiceFeuillets.LibellesR1
                Montant(sb, c.Key, c.Value, f.CaseR1(c.Key), c.Key = "A" OrElse c.Key = "E")
            Next
            sb.Append("</tbody></table><p class=""note"">Les cases J, L, M et W sont déjà comprises dans la case A.</p></div>")
        Else
            sb.Append("<div><p class=""note"">Emploi hors Québec : aucun relevé provincial. La case 22 du T4 réunit l'impôt fédéral et l'impôt de la province ou du territoire.</p>")
            If f.ProvincesEmploi.Any(Function(code) Provinces.EstGeree(code) AndAlso LibellesProvince.Pour(code).ARetenueTerritoriale) Then
                sb.Append("<p class=""note"">L'impôt sur la paie du territoire n'est pas compris dans la case 22 : il se déclare et se remet au gouvernement du territoire.</p>")
            End If
            sb.Append("</div>")
        End If
        sb.Append("</div></div>")
        litFeuillet.Text = sb.ToString()
    End Sub

    Private Shared Function H(texte As String) As String
        Return HttpUtility.HtmlEncode(texte)
    End Function

    Private Shared Sub Montant(sb As StringBuilder, code As String, libelle As String, valeur As Decimal, toujours As Boolean)
        If valeur = 0D AndAlso Not toujours Then Return
        sb.Append("<tr><td><strong>").Append(H(code)).Append("</strong></td><td>").Append(H(libelle)).Append("</td><td class=""num"">").Append(Argent(valeur)).Append("</td></tr>")
    End Sub

    Private Shared Sub Texte(sb As StringBuilder, code As String, libelle As String, valeur As String)
        sb.Append("<tr><td><strong>").Append(H(code)).Append("</strong></td><td>").Append(H(libelle)).Append("</td><td class=""num"">").Append(H(valeur)).Append("</td></tr>")
    End Sub

End Class
