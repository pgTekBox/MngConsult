Public Class PageEmployes
    Inherits PageBase

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        ' paie.Employe est une vue : identité de dbo.T300Employees (MngConsul) + paramètres de paie.EmployePaie.
        Dim t = Db.Table("paie.spEmploye_Liste",
            Db.P("@c", Contexte.CompagnieId), Db.P("@inactifs", chkInactifs.Checked))
        rptEmployes.DataSource = t
        rptEmployes.DataBind()
        rptEmployes.Visible = t.Rows.Count > 0
        lblAucun.Visible = t.Rows.Count = 0
    End Sub

    Protected Function Remuneration(tauxHoraire As Object, salaireAnnuel As Object) As String
        If Not IsDBNull(tauxHoraire) AndAlso Convert.ToDecimal(tauxHoraire) > 0D Then Return Argent(tauxHoraire) & " / h"
        If Not IsDBNull(salaireAnnuel) AndAlso Convert.ToDecimal(salaireAnnuel) > 0D Then Return Argent(salaireAnnuel) & " " & Tr("/ an")
        Return ""
    End Function

End Class
