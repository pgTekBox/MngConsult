Public Class PageAccueil
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim c = Db.P("@c", Contexte.CompagnieId)
        Dim nbEmployes = Db.ScalaireEntier("SELECT COUNT(*) FROM dbo.Employe WHERE CompagnieId = @c AND Actif = 1", c)
        Dim derniere = Db.Scalaire("SELECT MAX(DatePaie) FROM dbo.LotPaie WHERE CompagnieId = @c AND Statut = 'C'", Db.P("@c", Contexte.CompagnieId))

        litResume.Text = Server.HtmlEncode(
            nbEmployes.ToString() & If(nbEmployes > 1, " employés actifs", " employé actif") & " · " &
            If(derniere Is Nothing, "aucune paie confirmée", "dernière paie : " & TexteDate(derniere)))

        Dim brouillon = ServicePaie.LotBrouillon()
        If brouillon IsNot Nothing Then
            pnlBrouillon.Visible = True
            litBrouillon.Text = Server.HtmlEncode("période se terminant le " & TexteDate(brouillon("DateFinPeriode")))
            lnkBrouillon.NavigateUrl = "~/Paie/Calculer.aspx?lot=" & brouillon.Ent("Id").ToString()
        End If

        Dim activites = Db.Table("SELECT TOP 8 * FROM dbo.JournalActivite ORDER BY Id DESC")
        rptActivites.DataSource = activites
        rptActivites.DataBind()
        rptActivites.Visible = activites.Rows.Count > 0
        lblAucuneActivite.Visible = activites.Rows.Count = 0
    End Sub

End Class
