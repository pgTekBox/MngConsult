Public Class PageHistorique
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim t = Db.Table("paie.spLotPaie_Historique",
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
