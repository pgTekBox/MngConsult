Public Class PageTalon
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim paieId = IdRequete("paie")
        Dim lotId = Db.ScalaireEntier(
            "SELECT p.LotPaieId FROM dbo.Paie p JOIN dbo.LotPaie l ON l.Id = p.LotPaieId WHERE p.Id = @p AND l.CompagnieId = @c",
            Db.P("@p", paieId), Db.P("@c", Contexte.CompagnieId))
        If lotId = 0 Then Response.Redirect("~/Paie/Historique.aspx", True)

        lnkRetour.NavigateUrl = "~/Paie/Detail.aspx?lot=" & lotId.ToString()
        litTalon.Text = RenduPaie.Talon(paieId)
    End Sub

End Class
