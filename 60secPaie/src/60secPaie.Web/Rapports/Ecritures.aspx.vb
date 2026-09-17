Imports System.Text

Public Class PageEcritures
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return

        ddlLot.Items.Add(New ListItem("Toutes les paies de la période", "0"))
        For Each l As DataRow In Db.Table("SELECT TOP 60 Id, DatePaie, DateFinPeriode FROM dbo.LotPaie WHERE CompagnieId = @c AND Statut = 'C' ORDER BY DatePaie DESC, Id DESC",
                                          Db.P("@c", Contexte.CompagnieId)).Rows
            ddlLot.Items.Add(New ListItem("Paie du " & TexteDate(l("DatePaie")) & " (période au " & TexteDate(l("DateFinPeriode")) & ")", l.Ent("Id").ToString()))
        Next

        Dim lot = IdRequete("lot")
        If lot > 0 AndAlso ddlLot.Items.FindByValue(lot.ToString()) IsNot Nothing Then
            ddlLot.SelectedValue = lot.ToString()
        ElseIf ddlLot.Items.Count > 1 Then
            ddlLot.SelectedIndex = 1
        End If
        Dim debutMois = New Date(Date.Today.Year, Date.Today.Month, 1)
        txtDu.Text = TexteDate(debutMois)
        txtAu.Text = TexteDate(debutMois.AddMonths(1).AddDays(-1))
    End Sub

    Private Function Calculer(ByRef titre As String) As List(Of LigneGL)
        Dim lotId = Integer.Parse(ddlLot.SelectedValue)
        If lotId > 0 Then
            titre = ddlLot.SelectedItem.Text
            Return ServiceGL.EcrituresDuLot(lotId)
        End If
        Dim du = DateN(txtDu.Text, "Du")
        Dim au = DateN(txtAu.Text, "Au")
        If Not du.HasValue OrElse Not au.HasValue OrElse au.Value < du.Value Then Throw New SaisieInvalideException("La période est invalide.")
        titre = "Paies payées du " & TexteDate(du.Value) & " au " & TexteDate(au.Value)
        Return ServiceGL.EcrituresDeLaPeriode(du.Value, au.Value)
    End Function

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        Try
            Dim titre As String = ""
            Dim lignes = Calculer(titre)
            litTitre.Text = Server.HtmlEncode(titre)

            If lignes.Count = 0 Then
                litEcritures.Text = "<p class=""note"">Aucune paie confirmée pour cette sélection.</p>"
                Return
            End If

            Dim sb As New StringBuilder("<table class=""liste""><thead><tr><th>Compte</th><th>Description</th><th class=""num"">Débit</th><th class=""num"">Crédit</th></tr></thead><tbody>")
            Dim debit, credit As Decimal
            Dim manquants = 0
            For Each l In lignes
                debit += l.Debit : credit += l.Credit
                If l.Compte.Length = 0 Then manquants += 1
                sb.Append("<tr><td>").Append(If(l.Compte.Length = 0, "<span class=""note"">à définir</span>", HttpUtility.HtmlEncode(l.Compte))).Append("</td><td>")
                sb.Append(HttpUtility.HtmlEncode(l.Libelle)).Append("</td><td class=""num"">").Append(If(l.Debit <> 0D, Argent(l.Debit), ""))
                sb.Append("</td><td class=""num"">").Append(If(l.Credit <> 0D, Argent(l.Credit), "")).Append("</td></tr>")
            Next
            sb.Append("</tbody><tfoot><tr><td></td><td>Total</td><td class=""num"">").Append(Argent(debit)).Append("</td><td class=""num"">").Append(Argent(credit)).Append("</td></tr></tfoot></table>")
            If debit <> credit Then sb.Append("<div class=""message erreur"">L'écriture n'est pas équilibrée : écart de ").Append(Argent(debit - credit)).Append(".</div>")
            If manquants > 0 Then sb.Append("<p class=""note"">").Append(manquants).Append(" ligne(s) sans numéro de compte : définissez-les dans Configuration → Plan comptable.</p>")
            litEcritures.Text = sb.ToString()
        Catch ex As SaisieInvalideException
            litEcritures.Text = ""
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub btnCsv_Click(sender As Object, e As EventArgs) Handles btnCsv.Click
        Try
            Dim titre As String = ""
            Dim lignes As New List(Of String()) From {New String() {"Compte", "Description", "Débit", "Crédit"}}
            For Each l In Calculer(titre)
                lignes.Add({l.Compte, l.Libelle, l.Debit.ToString("0.00", FrCa), l.Credit.ToString("0.00", FrCa)})
            Next
            EnvoyerCsv("ecritures-paie.csv", lignes)
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

End Class
