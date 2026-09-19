Public Class PageTalon
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim paieId = IdRequete("paie")
        Dim lotId = Db.ScalaireEntier(
            "SELECT p.LotPaieId FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE p.Id = @p AND l.CompagnieId = @c",
            Db.P("@p", paieId), Db.P("@c", Contexte.CompagnieId))
        If lotId = 0 Then Response.Redirect("~/Paie/Historique.aspx", True)

        lnkRetour.NavigateUrl = "~/Paie/Detail.aspx?lot=" & lotId.ToString()
        litTalon.Text = RenduPaie.Talon(paieId)
    End Sub

    ''' <summary>
    ''' Le même document que l'employé reçoit en pièce jointe, mais dans la langue
    ''' de la personne qui le télécharge : ici, c'est elle qui va le lire.
    ''' Page_Load a déjà vérifié que la paie appartient à la compagnie courante.
    ''' </summary>
    Private Sub btnPdf_Click(sender As Object, e As EventArgs) Handles btnPdf.Click
        Dim d = RenduPaie.Lire(IdRequete("paie"))
        If Not d.Trouve Then Return
        EnvoyerFichier(TalonPdf.NomFichier(d), TalonPdf.Produire(d), "application/pdf")
    End Sub

End Class
