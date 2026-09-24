Imports System.Text
Imports Paie60Sec.Calcul

''' <summary>Assistant de paie en 4 étapes. L'état est conservé en base (lot en brouillon) et dans l'URL : ?lot=&amp;etape=&amp;paie=.</summary>
Public Class PageCalculerPaie
    Inherits PageBase

    Private _lot As DataRow

    Private ReadOnly Property LotId As Integer
        Get
            Return IdRequete("lot")
        End Get
    End Property

    Private ReadOnly Property PaieId As Integer
        Get
            Return IdRequete("paie")
        End Get
    End Property

    Private Function UrlLot(Optional etape As Integer = 0) As String
        Return "~/Paie/Calculer.aspx?lot=" & LotId.ToString() & If(etape > 0, "&etape=" & etape.ToString(), "")
    End Function

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim etape = 1

        If LotId > 0 Then
            _lot = Db.Ligne("SELECT * FROM paie.LotPaie WHERE Id = @l AND CompagnieId = @c", Db.P("@l", LotId), Db.P("@c", Contexte.CompagnieId))
            If _lot Is Nothing Then Response.Redirect("~/Paie/Calculer.aspx", True)

            litPeriode.Text = Server.HtmlEncode(
                "Période du " & TexteDate(_lot("DateDebutPeriode")) & " au " & TexteDate(_lot("DateFinPeriode")) &
                " · payée le " & TexteDate(_lot("DatePaie")) & " · " & LibellePeriodes(_lot("PeriodesParAnnee")))

            Select Case _lot.Txt("Statut")
                Case "C"
                    etape = 4
                    mvEtapes.SetActiveView(vwConfirmation)
                Case "A"
                    Response.Redirect("~/Paie/Detail.aspx?lot=" & LotId.ToString(), True)
                Case Else
                    If PaieId > 0 Then
                        etape = 2
                        mvEtapes.SetActiveView(vwLignes)
                        PreparerLignes()
                    ElseIf IdRequete("etape") = 3 Then
                        etape = 3
                        If Not _lot.Bln("Calcule") Then ServicePaie.CalculerLot(LotId)
                        mvEtapes.SetActiveView(vwRevision)
                    Else
                        etape = 2
                        mvEtapes.SetActiveView(vwSaisie)
                    End If
            End Select
        Else
            mvEtapes.SetActiveView(vwPeriode)
            PreparerPeriode()
        End If

        litEtapes.Text = BarreEtapes(etape)
    End Sub

    Private Shared Function BarreEtapes(courante As Integer) As String
        Dim titres = {"1. Période de paie", "2. Employés et rémunération", "3. Révision des calculs", "4. Confirmation"}
        Dim sb As New StringBuilder("<ol class=""etapes"">")
        For i = 1 To 4
            sb.Append("<li class=""").Append(If(i = courante, "courante", If(i < courante, "faite", ""))).Append(""">").Append(titres(i - 1)).Append("</li>")
        Next
        Return sb.Append("</ol>").ToString()
    End Function

    ' ------------------------------------------------------------------ Étape 1

    Private Sub PreparerPeriode()
        Dim brouillon = ServicePaie.LotBrouillon()
        pnlBrouillon.Visible = brouillon IsNot Nothing
        pnlNouvelle.Visible = brouillon Is Nothing
        If brouillon IsNot Nothing Then
            litBrouillon.Text = Server.HtmlEncode("Période se terminant le " & TexteDate(brouillon("DateFinPeriode")) & ", payée le " & TexteDate(brouillon("DatePaie")) & ".")
            lnkReprendre.NavigateUrl = "~/Paie/Calculer.aspx?lot=" & brouillon.Ent("Id").ToString()
            Return
        End If
        If IsPostBack Then Return

        Dim defaut = Db.ScalaireEntier("SELECT PeriodesParAnnee FROM paie.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId))
        If ddlPeriodes.Items.FindByValue(defaut.ToString()) IsNot Nothing Then ddlPeriodes.SelectedValue = defaut.ToString()

        ' Propose la période qui suit la dernière paie confirmée.
        Dim derniere = Db.Ligne("SELECT TOP 1 * FROM paie.LotPaie WHERE CompagnieId = @c AND Statut = 'C' ORDER BY DatePaie DESC, Id DESC", Db.P("@c", Contexte.CompagnieId))
        If derniere IsNot Nothing Then
            Dim p = derniere.Ent("PeriodesParAnnee")
            If ddlPeriodes.Items.FindByValue(p.ToString()) IsNot Nothing Then ddlPeriodes.SelectedValue = p.ToString()
            Dim fin = derniere.DtN("DateFinPeriode").Value
            Dim paie = derniere.DtN("DatePaie").Value
            Select Case p
                Case 52 : fin = fin.AddDays(7) : paie = paie.AddDays(7)
                Case 26 : fin = fin.AddDays(14) : paie = paie.AddDays(14)
                Case 12 : fin = fin.AddDays(1).AddMonths(1).AddDays(-1) : paie = paie.AddMonths(1)
                Case 1 : fin = fin.AddYears(1) : paie = paie.AddYears(1)
                Case Else : fin = Nothing : paie = Nothing
            End Select
            If fin <> Nothing Then
                txtFinPeriode.Text = TexteDate(fin)
                txtDatePaie.Text = TexteDate(paie)
            End If
        End If
    End Sub

    Private Sub btnCreer_Click(sender As Object, e As EventArgs) Handles btnCreer.Click
        Try
            Dim fin = DateN(txtFinPeriode.Text, "Heures travaillées jusqu'au")
            Dim paie = DateN(txtDatePaie.Text, "Payer le")
            If Not fin.HasValue OrElse Not paie.HasValue Then Throw New SaisieInvalideException("Inscrivez la fin de la période et la date de paie.")
            If paie.Value < fin.Value.AddDays(-31) OrElse paie.Value > fin.Value.AddDays(45) Then
                Throw New SaisieInvalideException("La date de paie est trop éloignée de la fin de la période.")
            End If

            Dim id = ServicePaie.CreerLot(Integer.Parse(ddlPeriodes.SelectedValue), fin.Value, paie.Value)
            Response.Redirect("~/Paie/Calculer.aspx?lot=" & id.ToString(), False)
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub btnSupprimerBrouillon_Click(sender As Object, e As EventArgs) Handles btnSupprimerBrouillon.Click
        Dim brouillon = ServicePaie.LotBrouillon()
        If brouillon IsNot Nothing Then ServicePaie.SupprimerBrouillon(brouillon.Ent("Id"))
        RedirigerAvecMessage("~/Paie/Calculer.aspx", "Le brouillon a été supprimé.")
    End Sub

    ' ------------------------------------------------------------------ Étape 2

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        If mvEtapes.GetActiveView() Is vwSaisie Then
            rptPaies.DataSource = Db.Table(
                "SELECT p.Id, p.LotPaieId, p.Inclus, e.Nom, e.Prenom, " &
                "ISNULL((SELECT SUM(pl.Montant) FROM paie.PaieLigne pl WHERE pl.PaieId = p.Id AND pl.CategorieCode NOT LIKE 'DED[_]%' AND pl.CategorieCode NOT LIKE 'AV[_]%'), 0) AS BrutPrevu, " &
                "ISNULL(STUFF((SELECT ', ' + pl.Description FROM paie.PaieLigne pl WHERE pl.PaieId = p.Id ORDER BY pl.Id FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 2, ''), N'Aucune ligne') AS Resume " &
                "FROM paie.Paie p JOIN paie.Employe e ON e.Id = p.EmployeId WHERE p.LotPaieId = @l ORDER BY e.Nom, e.Prenom", Db.P("@l", LotId))
            rptPaies.DataBind()

        ElseIf mvEtapes.GetActiveView() Is vwLignes Then
            Dim t = Db.Table("SELECT * FROM paie.PaieLigne WHERE PaieId = @p ORDER BY Id", Db.P("@p", PaieId))
            rptLignes.DataSource = t
            rptLignes.DataBind()
            rptLignes.Visible = t.Rows.Count > 0
            lblAucuneLigne.Visible = t.Rows.Count = 0

        ElseIf mvEtapes.GetActiveView() Is vwRevision Then
            litRevision.Text = RenduPaie.TableauLot(LotId, True, False)
            litSommaire.Text = RenduPaie.SommaireLot(LotId)
            lnkModifier.NavigateUrl = UrlLot()

        ElseIf mvEtapes.GetActiveView() Is vwConfirmation Then
            litConfirmation.Text = RenduPaie.TableauLot(LotId, False, False)
            lnkDetail.NavigateUrl = "~/Paie/Detail.aspx?lot=" & LotId.ToString()
        End If
    End Sub

    Private Sub btnCalculer_Click(sender As Object, e As EventArgs) Handles btnCalculer.Click
        Try
            For Each item As RepeaterItem In rptPaies.Items
                Dim inclus = DirectCast(item.FindControl("chkInclus"), CheckBox).Checked
                Dim id As Integer
                If Integer.TryParse(DirectCast(item.FindControl("hidPaieId"), HiddenField).Value, id) Then
                    Db.Exec("UPDATE p SET Inclus = @i FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId " &
                            "WHERE p.Id = @p AND p.LotPaieId = @l AND l.Statut = 'B' AND l.CompagnieId = @c",
                            Db.P("@i", inclus), Db.P("@p", id), Db.P("@l", LotId), Db.P("@c", Contexte.CompagnieId))
                End If
            Next
            ServicePaie.CalculerLot(LotId)
            Response.Redirect(UrlLot(3), False)
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        Catch ex As NotSupportedException
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub btnSupprimerLot_Click(sender As Object, e As EventArgs) Handles btnSupprimerLot.Click
        Try
            ServicePaie.SupprimerBrouillon(LotId)
            RedirigerAvecMessage("~/Paie/Calculer.aspx", "La paie en préparation a été supprimée.")
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    ' ------------------------------------------------------------------ Lignes d'un employé

    Private Function PaieDuLot() As DataRow
        Return Db.Ligne("SELECT p.Id, e.Prenom, e.Nom FROM paie.Paie p JOIN paie.Employe e ON e.Id = p.EmployeId WHERE p.Id = @p AND p.LotPaieId = @l",
                        Db.P("@p", PaieId), Db.P("@l", LotId))
    End Function

    Private Sub PreparerLignes()
        Dim paie = PaieDuLot()
        If paie Is Nothing Then Response.Redirect(UrlLot(), True)
        litEmployeLignes.Text = Server.HtmlEncode(paie.Txt("Prenom") & " " & paie.Txt("Nom"))
        lnkRetourSaisie.NavigateUrl = UrlLot()

        If Not IsPostBack Then
            For Each el As DataRow In Db.Table("SELECT Id, Description, CategorieCode FROM paie.ElementPaie WHERE CompagnieId = @c AND Actif = 1 ORDER BY Description",
                                               Db.P("@c", Contexte.CompagnieId)).Rows
                Dim code = el.Txt("CategorieCode")
                Dim libelle = If(CategoriePaie.Existe(code), CategoriePaie.ParCode(code).LibelleComplet, code)
                ddlElement.Items.Add(New ListItem(el.Txt("Description") & "  (" & libelle & ")", el.Ent("Id").ToString()))
            Next
        End If
    End Sub

    Private Sub btnAjouterLigne_Click(sender As Object, e As EventArgs) Handles btnAjouterLigne.Click
        Try
            If PaieDuLot() Is Nothing OrElse _lot.Txt("Statut") <> "B" Then Throw New SaisieInvalideException("Cette paie n'est plus modifiable.")
            Dim elementId As Integer
            If Not Integer.TryParse(ddlElement.SelectedValue, elementId) Then Throw New SaisieInvalideException("Choisissez un élément de paie.")

            ServicePaie.AjouterLigne(PaieId, elementId, Dec(txtHeures.Text, "Heures"), Dec(txtTaux.Text, "Taux horaire"), Dec(txtMontant.Text, "Montant"))
            txtHeures.Text = "" : txtTaux.Text = "" : txtMontant.Text = ""
            Succes("Ligne ajoutée.")
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub rptLignes_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptLignes.ItemCommand
        If e.CommandName <> "Supprimer" OrElse PaieDuLot() Is Nothing OrElse _lot.Txt("Statut") <> "B" Then Return
        Db.Exec("DELETE FROM paie.PaieLigne WHERE Id = @id AND PaieId = @p", Db.P("@id", Convert.ToInt32(e.CommandArgument)), Db.P("@p", PaieId))
        ServicePaie.MarquerNonCalcule(PaieId)
        Succes("Ligne retirée.")
    End Sub

    ' ------------------------------------------------------------------ Étape 3

    Private Sub btnConfirmer_Click(sender As Object, e As EventArgs) Handles btnConfirmer.Click
        Try
            ServicePaie.ConfirmerLot(LotId)
            Response.Redirect(UrlLot(), False)
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

End Class
