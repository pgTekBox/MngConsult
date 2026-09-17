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
