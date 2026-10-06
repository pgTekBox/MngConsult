Imports System.Text
Imports Paie60Sec.Calcul

Public Class PagePayerRemise
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ' Une compagnie hors Québec ne remet rien à Revenu Québec : tout va au Receveur général.
            If Not ServiceRemise.QuebecConcerne() Then
                Dim quebec = ddlGouvernement.Items.FindByValue(ServiceRemise.Quebec)
                If quebec IsNot Nothing Then ddlGouvernement.Items.Remove(quebec)
            End If
            Dim g = Request.QueryString("g")
            If ddlGouvernement.Items.FindByValue(If(g, "")) IsNot Nothing Then ddlGouvernement.SelectedValue = g
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
        sb.Append(CarteSolde(ServiceRemise.Federal))
        If ServiceRemise.QuebecConcerne() Then sb.Append(CarteSolde(ServiceRemise.Quebec))

        ' Hors Québec : la cotisation santé de l'employeur, la prime de la commission des accidents du travail et
        ' l'impôt sur la paie d'un territoire se paient à part ; on en donne le cumul de l'année, par province.
        Dim horsRemise = ServiceRemise.HorsRemiseProvinces(Date.Today.Year)
        Dim courante = Provinces.Code(Contexte.Province)
        Dim codes = horsRemise.Rows.Cast(Of DataRow)().Select(Function(r) r.Txt("Province").Trim()).ToList()
        If Contexte.HorsQuebec AndAlso Not codes.Contains(courante) Then codes.Add(courante)
        For Each code In codes
            Dim r = horsRemise.Rows.Cast(Of DataRow)().FirstOrDefault(Function(x) x.Txt("Province").Trim() = code)
            sb.Append(CarteHorsRemise(code, r, code = courante))
        Next

        Dim cnt = ServiceRemise.CntAccumulee(Date.Today.Year)
        If cnt > 0D Then
            sb.Append("<div class=""carte""><h2>Normes du travail (CNT)</h2><p>Accumulée en ").Append(Date.Today.Year).Append(" : <strong>").Append(Argent(cnt))
            sb.Append("</strong></p><p class=""note"">Payable une fois l'an à Revenu Québec, avec le sommaire 1. Elle ne fait pas partie des remises périodiques.</p></div>")
        End If
        litSoldes.Text = sb.Append("</div>").ToString()
    End Sub

    ''' <summary>La carte d'une province ; <paramref name="r"/> est Nothing si rien n'y a encore été payé cette année.</summary>
    Private Shared Function CarteHorsRemise(code As String, r As DataRow, courante As Boolean) As String
        If Not Provinces.EstGeree(code) Then Return ""
        Dim noms = LibellesProvince.Pour(code)
        Dim sante = If(r Is Nothing, 0D, r.Dcm("Sante"))
        Dim accidents = If(r Is Nothing, 0D, r.Dcm("Accidents"))
        Dim impotPaie = If(r Is Nothing, 0D, r.Dcm("ImpotPaie"))
        If Not courante AndAlso sante = 0D AndAlso accidents = 0D AndAlso impotPaie = 0D Then Return ""

        Dim annee = Date.Today.Year
        Dim sb As New StringBuilder("<div class=""carte""><h2>")
        sb.Append(HttpUtility.HtmlEncode(Provinces.Nom(noms.Province) & " : montants hors remises")).Append("</h2>")
        If noms.ARetenueTerritoriale OrElse impotPaie > 0D Then
            sb.Append("<p>Impôt sur la paie retenu aux employés, cumul de ").Append(annee).Append(" : <strong>").Append(Argent(impotPaie)).Append("</strong></p>")
        End If
        If noms.ASante OrElse sante > 0D Then
            sb.Append("<p>").Append(HttpUtility.HtmlEncode(noms.SanteLong)).Append(", cumul de ").Append(annee).Append(" : <strong>").Append(Argent(sante)).Append("</strong></p>")
        End If
        sb.Append("<p>").Append(HttpUtility.HtmlEncode("Prime " & noms.Accidents)).Append(", cumul de ").Append(annee).Append(" : <strong>").Append(Argent(accidents)).Append("</strong></p>")
        If noms.ARetenueTerritoriale OrElse impotPaie > 0D Then
            sb.Append("<p class=""note"">L'impôt sur la paie se remet au gouvernement du territoire, selon la fréquence qu'il vous a attribuée.</p>")
        End If
        sb.Append("<p class=""note"">Ces montants se paient à part, à l'administration de la province ou du territoire et à sa commission des accidents du travail. Ils ne font pas partie des remises au Receveur général.</p></div>")
        Return sb.ToString()
    End Function

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
