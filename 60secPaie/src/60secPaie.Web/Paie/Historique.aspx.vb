Public Class PageHistorique
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim t = Db.Table(
            "SELECT l.Id, l.DatePaie, l.DateDebutPeriode, l.DateFinPeriode, l.PeriodesParAnnee, l.Statut, " &
            "COUNT(p.Id) AS NbEmployes, ISNULL(SUM(p.BrutVerse),0) AS Brut, ISNULL(SUM(p.Net),0) AS Net, " &
            "ISNULL(SUM(p.EmployeurRRQ + p.EmployeurRRQ2 + p.EmployeurAE + p.EmployeurRQAP + p.EmployeurFSS + p.EmployeurCNESST + p.EmployeurCNT),0) AS Employeur " &
            "FROM dbo.LotPaie l LEFT JOIN dbo.Paie p ON p.LotPaieId = l.Id AND p.Inclus = 1 WHERE l.CompagnieId = @c " &
            "GROUP BY l.Id, l.DatePaie, l.DateDebutPeriode, l.DateFinPeriode, l.PeriodesParAnnee, l.Statut ORDER BY l.DatePaie DESC, l.Id DESC",
            Db.P("@c", Contexte.CompagnieId))
        rptLots.DataSource = t
        rptLots.DataBind()
        rptLots.Visible = t.Rows.Count > 0
        lblAucun.Visible = t.Rows.Count = 0
    End Sub

    Protected Function LienLot(id As Object, statut As Object) As String
        Return If(Convert.ToString(statut) = "B", "Calculer.aspx?lot=", "Detail.aspx?lot=") & Convert.ToString(id)
    End Function

End Class
