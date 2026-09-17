Public Class PageAccueil
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim c = Db.P("@c", Contexte.CompagnieId)
        Dim nbEmployes = Db.ScalaireEntier("SELECT COUNT(*) FROM paie.Employe WHERE CompagnieId = @c AND Actif = 1", c)
        Dim derniere = Db.Scalaire("SELECT MAX(DatePaie) FROM paie.LotPaie WHERE CompagnieId = @c AND Statut = 'C'", Db.P("@c", Contexte.CompagnieId))

        litResume.Text = Server.HtmlEncode(
            nbEmployes.ToString() & If(nbEmployes > 1, " employés actifs", " employé actif") & " · " &
            If(derniere Is Nothing, "aucune paie confirmée", "dernière paie : " & TexteDate(derniere)))

        Dim brouillon = ServicePaie.LotBrouillon()
        If brouillon IsNot Nothing Then
            pnlBrouillon.Visible = True
            litBrouillon.Text = Server.HtmlEncode("période se terminant le " & TexteDate(brouillon("DateFinPeriode")))
            lnkBrouillon.NavigateUrl = "~/Paie/Calculer.aspx?lot=" & brouillon.Ent("Id").ToString()
        End If

        litRetenues.Text = LigneSolde(ServiceRemise.Federal, "Fédéral") & LigneSolde(ServiceRemise.Quebec, "Revenu Québec")

        Dim activites = Db.Table("SELECT TOP 8 * FROM paie.JournalActivite WHERE CompagnieId = @c ORDER BY Id DESC", Db.P("@c", Contexte.CompagnieId))
        rptActivites.DataSource = activites
        rptActivites.DataBind()
        rptActivites.Visible = activites.Rows.Count > 0
        lblAucuneActivite.Visible = activites.Rows.Count = 0
    End Sub

    Private Function LigneSolde(gouvernement As String, nom As String) As String
        Dim s = ServiceRemise.Solde(gouvernement)
        If s.NbPaies = 0 Then Return "<p>" & nom & " : rien à payer.</p>"
        Return "<p" & If(s.EnRetard, " class=""message erreur""", "") & ">" & nom & " : <strong>" & Argent(s.Montant) & "</strong> à payer, " &
               If(s.EnRetard, "en retard depuis le ", "échéance le ") & TexteDate(s.Echeance.Value) & ".</p>"
    End Function

End Class
