Imports System.Text

Public Class PageDetailLot
    Inherits PageBase

    Private ReadOnly Property LotId As Integer
        Get
            Return IdRequete("lot")
        End Get
    End Property

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        Dim lot = Db.Ligne("SELECT * FROM dbo.LotPaie WHERE Id = @l AND CompagnieId = @c", Db.P("@l", LotId), Db.P("@c", Contexte.CompagnieId))
        If lot Is Nothing Then Response.Redirect("~/Paie/Historique.aspx", True)
        If lot.Txt("Statut") = "B" Then Response.Redirect("~/Paie/Calculer.aspx?lot=" & LotId.ToString(), True)

        litStatut.Text = "<span class=""etiquette " & lot.Txt("Statut") & """>" & Server.HtmlEncode(LibelleStatut(lot("Statut"))) & "</span>"
        litPeriode.Text = Server.HtmlEncode(
            "Période du " & TexteDate(lot("DateDebutPeriode")) & " au " & TexteDate(lot("DateFinPeriode")) &
            " · payée le " & TexteDate(lot("DatePaie")) & " · " & LibellePeriodes(lot("PeriodesParAnnee")) &
            " · préparée par " & lot.Txt("CreePar"))
        litTableau.Text = RenduPaie.TableauLot(LotId, True, True)
        litSommaire.Text = RenduPaie.SommaireLot(LotId)
        pnlAnnuler.Visible = lot.Txt("Statut") = "C" AndAlso ServicePaie.PeutAnnuler(LotId)

        pnlSuites.Visible = lot.Txt("Statut") = "C"
        If pnlSuites.Visible Then AfficherSuites(lot)
    End Sub

    Private Sub AfficherSuites(lot As DataRow)
        Dim sb As New StringBuilder("<table class=""liste""><tbody>")

        Dim depots = ServiceDepotDirect.Depots(LotId)
        btnDepotDirect.Visible = depots.Rows.Count > 0
        If depots.Rows.Count > 0 Then
            Dim total = depots.Rows.Cast(Of DataRow)().Sum(Function(d) d.Dcm("Net"))
            sb.Append("<tr><td>Dépôt direct</td><td>").Append(depots.Rows.Count).Append(" employé(s), ").Append(Argent(total))
            If lot.IsNull("DepotDirectNumeroFichier") Then
                sb.Append(" - fichier pas encore produit")
            Else
                sb.Append(" - fichier n° ").Append(lot.Ent("DepotDirectNumeroFichier").ToString("0000")).Append(" produit le ").Append(TexteDate(lot("DepotDirectGenereLe")))
            End If
            For Each probleme In ServiceDepotDirect.Problemes(LotId)
                sb.Append("<div class=""note"">").Append(Server.HtmlEncode(probleme)).Append("</div>")
            Next
            sb.Append("</td></tr>")
        End If

        Dim destinataires = ServiceCourriel.Destinataires(LotId)
        btnTalons.Visible = destinataires.Rows.Count > 0
        chkRenvoyer.Visible = destinataires.Rows.Count > 0
        If destinataires.Rows.Count > 0 Then
            Dim envoyes = destinataires.Rows.Cast(Of DataRow)().Count(Function(d) Not d.IsNull("TalonEnvoyeLe"))
            sb.Append("<tr><td>Talons par courriel</td><td>").Append(envoyes).Append(" envoyé(s) sur ").Append(destinataires.Rows.Count)
            If ServiceCourriel.ModeTest Then sb.Append("<div class=""note"">Mode test : les courriels sont écrits dans le dossier App_Data\courriels au lieu d'être envoyés.</div>")
            sb.Append("</td></tr>")
        Else
            sb.Append("<tr><td>Talons par courriel</td><td class=""note"">Aucun employé de cette paie n'a demandé son talon par courriel (fiche de l'employé).</td></tr>")
        End If

        litSuites.Text = sb.Append("</tbody></table>").ToString()
        lnkEcritures.NavigateUrl = "~/Rapports/Ecritures.aspx?lot=" & LotId.ToString()
    End Sub

    Private Sub btnDepotDirect_Click(sender As Object, e As EventArgs) Handles btnDepotDirect.Click
        Try
            Dim fichier = ServiceDepotDirect.Generer(LotId)
            EnvoyerFichier(fichier.NomFichier, fichier.Contenu, "text/plain")
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub btnTalons_Click(sender As Object, e As EventArgs) Handles btnTalons.Click
        Try
            Dim bilan = ServiceCourriel.EnvoyerTalons(LotId, chkRenvoyer.Checked)
            Dim message = bilan.Envoyes.ToString() & " talon(s) envoyé(s)"
            If bilan.DejaEnvoyes > 0 Then message &= ", " & bilan.DejaEnvoyes.ToString() & " déjà envoyé(s)"
            If bilan.Erreurs.Count > 0 Then
                Erreur(message & ". Problèmes : " & String.Join(" ", bilan.Erreurs))
            Else
                Succes(message & ".")
            End If
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub btnAnnuler_Click(sender As Object, e As EventArgs) Handles btnAnnuler.Click
        Try
            ServicePaie.AnnulerLot(LotId)
            Succes("La paie a été annulée.")
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

End Class
