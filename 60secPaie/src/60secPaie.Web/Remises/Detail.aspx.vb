Imports System.Text

Public Class PageDetailRemise
    Inherits PageBase

    Private ReadOnly Property RemiseId As Integer
        Get
            Return IdRequete("id")
        End Get
    End Property

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        Dim r = Db.Ligne("SELECT r.*, c.NumeroEntrepriseFederal, c.NumeroIdentificationRQ FROM dbo.Remise r JOIN dbo.Compagnie c ON c.Id = r.CompagnieId " &
                         "WHERE r.Id = @id AND r.CompagnieId = @c", Db.P("@id", RemiseId), Db.P("@c", Contexte.CompagnieId))
        If r Is Nothing Then Response.Redirect("~/Remises/Historique.aspx", True)

        Dim g = r.Txt("Gouvernement")
        Dim annulee = r.Txt("Statut") = "A"
        litStatut.Text = "<span class=""etiquette " & If(annulee, "A", "C") & """>" & If(annulee, "Annulé", "Payé") & "</span>"
        litEntete.Text = Server.HtmlEncode(
            ServiceRemise.NomGouvernement(g) & " · retenues accumulées au " & TexteDate(r("DateFinPeriode")) & " · payé le " & TexteDate(r("DatePaiement")) &
            " · " & PageHistoriqueRemises.LibelleMode(r("ModePaiement"), r("NumeroCheque"), r("Reference")) & " · enregistré par " & r.Txt("CreePar"))

        Dim lignes = Db.Table("SELECT Libelle, Montant FROM dbo.RemiseLigne WHERE RemiseId = @id ORDER BY Ordre", Db.P("@id", RemiseId))
        litDetail.Text = ServiceRemise.Rendu(lignes, ServiceRemise.LotsDeLaRemise(RemiseId, g))

        Dim sb As New StringBuilder("<table class=""liste""><tbody>")
        If g = ServiceRemise.Federal Then
            Ajouter(sb, "Numéro de compte de retenues (RP)", r.Txt("NumeroEntrepriseFederal"))
            Ajouter(sb, "Rémunération brute de la période", Argent(r("RemunerationBrute")))
            Ajouter(sb, "Nombre d'employés à la dernière période de paie", r.Ent("NbEmployesDernierePaie").ToString())
        Else
            Ajouter(sb, "Numéro d'identification (RS)", r.Txt("NumeroIdentificationRQ"))
            Ajouter(sb, "Rémunération brute de la période", Argent(r("RemunerationBrute")))
        End If
        Ajouter(sb, "Période se terminant le", TexteDate(r("DateFinPeriode")))
        Ajouter(sb, "Montant du paiement", Argent(r("Total")))
        litFormulaire.Text = sb.Append("</tbody></table>").ToString()

        pnlAnnuler.Visible = Not annulee
    End Sub

    Private Shared Sub Ajouter(sb As StringBuilder, libelle As String, valeur As String)
        sb.Append("<tr><td>").Append(HttpUtility.HtmlEncode(libelle)).Append("</td><td class=""num""><strong>")
        sb.Append(HttpUtility.HtmlEncode(If(valeur.Length = 0, "—", valeur))).Append("</strong></td></tr>")
    End Sub

    Private Sub btnAnnuler_Click(sender As Object, e As EventArgs) Handles btnAnnuler.Click
        Try
            ServiceRemise.Annuler(RemiseId)
            Succes("Le paiement a été annulé. Les retenues sont de nouveau à payer.")
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

End Class
