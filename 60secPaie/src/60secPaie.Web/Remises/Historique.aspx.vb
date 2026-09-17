Public Class PageHistoriqueRemises
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim t = Db.Table("SELECT * FROM paie.Remise WHERE CompagnieId = @c ORDER BY DatePaiement DESC, Id DESC", Db.P("@c", Contexte.CompagnieId))
        rptRemises.DataSource = t
        rptRemises.DataBind()
        rptRemises.Visible = t.Rows.Count > 0
        lblAucun.Visible = t.Rows.Count = 0
    End Sub

    Protected Function ModePaiement(mode As Object, numeroCheque As Object, reference As Object) As String
        Return LibelleMode(mode, numeroCheque, reference)
    End Function

    Public Shared Function LibelleMode(mode As Object, numeroCheque As Object, reference As Object) As String
        If Convert.ToString(mode) = "C" Then Return "Chèque n° " & Convert.ToString(numeroCheque)
        Dim r = If(IsDBNull(reference), "", Convert.ToString(reference))
        Return "En ligne" & If(r.Length > 0, " - " & r, "")
    End Function

End Class
