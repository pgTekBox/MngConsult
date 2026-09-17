Imports System.Text

Public Class PagePayerRemise
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Dim g = Request.QueryString("g")
            If g = ServiceRemise.Federal OrElse g = ServiceRemise.Quebec Then ddlGouvernement.SelectedValue = g
            ProposerDates()
        End If
    End Sub

    Private Sub ddlGouvernement_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlGouvernement.SelectedIndexChanged
        pnlApercu.Visible = False
        ProposerDates()
    End Sub

    ''' <summary>Propose la fin de la période de remise de la plus ancienne paie non payée.</summary>
    Private Sub ProposerDates()
        Dim solde = ServiceRemise.Solde(ddlGouvernement.SelectedValue)
        txtFinPeriode.Text = TexteDate(If(solde.FinPeriode, Date.Today))
        txtDatePaiement.Text = TexteDate(Date.Today)
    End Sub

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        Dim sb As New StringBuilder("<div class=""grille-cartes"">")
        sb.Append(CarteSolde(ServiceRemise.Federal)).Append(CarteSolde(ServiceRemise.Quebec))

        Dim cnt = ServiceRemise.CntAccumulee(Date.Today.Year)
        If cnt > 0D Then
            sb.Append("<div class=""carte""><h2>Normes du travail (CNT)</h2><p>Accumulée en ").Append(Date.Today.Year).Append(" : <strong>").Append(Argent(cnt))
            sb.Append("</strong></p><p class=""note"">Payable une fois l'an à Revenu Québec, avec le sommaire 1. Elle ne fait pas partie des remises périodiques.</p></div>")
        End If
        litSoldes.Text = sb.Append("</div>").ToString()
    End Sub

    Private Shared Function CarteSolde(gouvernement As String) As String
        Dim s = ServiceRemise.Solde(gouvernement)
        Dim sb As New StringBuilder("<div class=""carte""><h2>")
        sb.Append(HttpUtility.HtmlEncode(ServiceRemise.NomGouvernement(gouvernement))).Append("</h2>")
        If s.NbPaies = 0 Then
            sb.Append("<p>Aucune retenue à payer.</p>")
        Else
            sb.Append("<p>À payer : <strong>").Append(Argent(s.Montant)).Append("</strong> (").Append(s.NbPaies).Append(If(s.NbPaies > 1, " paies)", " paie)")).Append("</p>")
            sb.Append("<div class=""").Append(If(s.EnRetard, "message erreur", "note")).Append(""">")
            sb.Append(If(s.EnRetard, "En retard : échéance du ", "Prochaine échéance : ")).Append(TexteDate(s.Echeance.Value))
            sb.Append(" pour la période se terminant le ").Append(TexteDate(s.FinPeriode.Value)).Append(".</div>")
        End If
        Return sb.Append("</div>").ToString()
    End Function

    Private Sub LireSaisie(ByRef fin As Date, ByRef paiement As Date)
        Dim f = DateN(txtFinPeriode.Text, "Retenues accumulées au")
        Dim p = DateN(txtDatePaiement.Text, "Date du paiement")
        If Not f.HasValue OrElse Not p.HasValue Then Throw New SaisieInvalideException("Inscrivez les deux dates.")
        If p.Value > Date.Today.AddDays(31) Then Throw New SaisieInvalideException("La date du paiement est trop éloignée.")
        fin = f.Value
        paiement = p.Value
    End Sub

    Private Sub btnCalculer_Click(sender As Object, e As EventArgs) Handles btnCalculer.Click
        Try
            Dim fin, paiement As Date
            LireSaisie(fin, paiement)

            Dim g = ddlGouvernement.SelectedValue
            Dim lots = ServiceRemise.LotsAPayer(g, fin)
            If lots.Rows.Count = 0 Then
                pnlApercu.Visible = False
                Erreur("Aucune retenue à payer à " & ServiceRemise.NomGouvernement(g) & " pour les paies jusqu'au " & TexteDate(fin) & ".")
                Return
            End If

            pnlApercu.Visible = True
            litTitreApercu.Text = Server.HtmlEncode("Montant à payer à " & ServiceRemise.NomGouvernement(g) & " - retenues accumulées au " & TexteDate(fin))
            litApercu.Text = ServiceRemise.Rendu(ServiceRemise.LignesAPayer(g, fin), lots)
        Catch ex As SaisieInvalideException
            pnlApercu.Visible = False
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        Try
            Dim fin, paiement As Date
            LireSaisie(fin, paiement)
            Dim id = ServiceRemise.Enregistrer(ddlGouvernement.SelectedValue, fin, paiement, ddlMode.SelectedValue = "C", txtReference.Text.Trim())
            RedirigerAvecMessage("~/Remises/Detail.aspx?id=" & id.ToString(), "Paiement enregistré.")
        Catch ex As SaisieInvalideException
            pnlApercu.Visible = False
            Erreur(ex.Message)
        End Try
    End Sub

End Class
