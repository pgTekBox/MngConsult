Imports System.Text
Imports Paie60Sec.Calcul

Public Class PageElementsPaie
    Inherits PageBase

    Private ReadOnly Property ElementId As Integer
        Get
            Return IdRequete("id")
        End Get
    End Property

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            For Each cat In CategoriePaie.Toutes
                ddlCategorie.Items.Add(New ListItem(cat.LibelleComplet, cat.Code))
            Next

            litTitreFormulaire.Text = "Nouvel élément de paie"
            If ElementId > 0 Then
                Dim el = Db.Ligne("paie.spElementPaie_Get", Db.P("@id", ElementId), Db.P("@c", Contexte.CompagnieId))
                If el Is Nothing Then Response.Redirect("~/Config/ElementsPaie.aspx", True)
                litTitreFormulaire.Text = "Modifier l'élément de paie"
                txtDescription.Text = el.Txt("Description")
                ddlCategorie.SelectedValue = el.Txt("CategorieCode")
                txtCompteGL.Text = el.Txt("CompteGL")
                chkActif.Checked = el.Bln("Actif")
                chkMasquer.Checked = el.Bln("MasquerSurTalon")
                btnSupprimer.Visible = True
            End If
        End If
    End Sub

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        rptElements.DataSource = Db.Table("paie.spElementPaie_Liste", Db.P("@c", Contexte.CompagnieId))
        rptElements.DataBind()
        litMatrice.Text = Matrice(CategoriePaie.ParCode(ddlCategorie.SelectedValue))
    End Sub

    Protected Function LibelleCategorie(code As Object) As String
        Dim c = Convert.ToString(code)
        Return If(CategoriePaie.Existe(c), CategoriePaie.ParCode(c).LibelleComplet, c)
    End Function

    Private Shared Function OuiNon(valeur As Boolean) As String
        Return If(valeur, "Oui", "Non")
    End Function

    Private Shared Function Matrice(cat As CategoriePaie) As String
        Dim sb As New StringBuilder()
        If Contexte.HorsQuebec Then Return MatriceHorsQuebec(cat)
        If cat.Type = TypeCategorie.Deduction Then
            sb.Append("<table class=""matrice""><tr><th>Réduit l'impôt fédéral</th><th>Réduit l'impôt du Québec</th><th>Crédit fonds de travailleurs</th><th>Case T4</th><th>Case R1</th></tr><tr>")
            sb.Append("<td>").Append(OuiNon(cat.ImpotFederal)).Append("</td><td>").Append(OuiNon(cat.ImpotQuebec)).Append("</td><td>")
            sb.Append(OuiNon(cat.Fonds <> FondsTravailleurs.Aucun)).Append("</td>")
        Else
            sb.Append("<table class=""matrice""><tr><th>Impôt fédéral</th><th>Impôt du Québec</th><th>AE</th><th>RRQ</th><th>RQAP</th><th>FSS</th><th>CNESST</th><th>Vacances</th><th>Case T4</th><th>Case R1</th></tr><tr>")
            For Each v In {cat.ImpotFederal, cat.ImpotQuebec, cat.AE, cat.RRQ, cat.RQAP, cat.FSS, cat.CNESST, cat.Vacances}
                sb.Append("<td>").Append(OuiNon(v)).Append("</td>")
            Next
        End If
        sb.Append("<td>").Append(HttpUtility.HtmlEncode(If(String.IsNullOrEmpty(cat.CaseT4), "—", cat.CaseT4))).Append("</td>")
        sb.Append("<td>").Append(HttpUtility.HtmlEncode(If(String.IsNullOrEmpty(cat.CaseR1), "—", cat.CaseR1))).Append("</td></tr></table>")
        sb.Append(NotesCategorie(cat))
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' La même matrice pour une compagnie d'une autre province, avec ses libellés. Hors Québec, le revenu imposable est le même aux deux
    ''' paliers ; un avantage imposable au Québec seulement n'y est assujetti à rien. Ni RQAP, ni Relevé 1.
    ''' La colonne de la cotisation santé de l'employeur n'existe que dans les provinces qui en ont une.
    ''' </summary>
    Private Shared Function MatriceHorsQuebec(cat As CategoriePaie) As String
        Dim sb As New StringBuilder()
        Dim noms = Contexte.Libelles
        Dim deLaProvince = Provinces.DeNom(noms.Province)
        Dim quebecSeulement = cat.Type = TypeCategorie.Avantage AndAlso Not cat.ImpotFederal
        If cat.Type = TypeCategorie.Deduction Then
            sb.Append("<table class=""matrice""><tr><th>").Append(HttpUtility.HtmlEncode("Réduit l'impôt fédéral et l'impôt " & deLaProvince))
            sb.Append("</th><th>Crédit fonds de travailleurs (fédéral)</th><th>Case T4</th></tr><tr>")
            sb.Append("<td>").Append(OuiNon(cat.ImpotFederal)).Append("</td><td>").Append(OuiNon(cat.Fonds <> FondsTravailleurs.Aucun)).Append("</td>")
        Else
            sb.Append("<table class=""matrice""><tr><th>").Append(HttpUtility.HtmlEncode("Impôt fédéral et impôt " & deLaProvince)).Append("</th><th>AE</th><th>RPC</th>")
            If noms.ASante Then sb.Append("<th>").Append(HttpUtility.HtmlEncode(noms.Sante)).Append("</th>")
            sb.Append("<th>").Append(HttpUtility.HtmlEncode(noms.Accidents)).Append("</th><th>Vacances</th><th>Case T4</th></tr><tr>")
            Dim valeurs As New List(Of Boolean) From {cat.ImpotFederal, cat.AE, cat.RRQ}
            If noms.ASante Then valeurs.Add(cat.FSS)
            valeurs.AddRange({cat.CNESST, cat.Vacances AndAlso Not cat.PaieVacances})
            For Each v In valeurs
                sb.Append("<td>").Append(OuiNon(v AndAlso Not quebecSeulement)).Append("</td>")
            Next
        End If
        sb.Append("<td>").Append(HttpUtility.HtmlEncode(If(String.IsNullOrEmpty(cat.CaseT4), "—", cat.CaseT4))).Append("</td></tr></table>")
        If quebecSeulement Then sb.Append("<p class=""note"">Cet avantage n'est imposable qu'au Québec : il est ignoré dans une paie d'une autre province.</p>")
        sb.Append(NotesCategorie(cat))
        Return sb.ToString()
    End Function

    Private Shared Function NotesCategorie(cat As CategoriePaie) As String
        Dim sb As New StringBuilder()
        If cat.Forfaitaire Then sb.Append("<p class=""note"">Paiement forfaitaire : l'impôt est calculé selon la méthode des gratifications et paiements rétroactifs.</p>")
        If cat.Type = TypeCategorie.Avantage AndAlso Not cat.VerseEnArgent Then sb.Append("<p class=""note"">Avantage non monétaire : il est imposé mais ne s'ajoute pas à la paie nette.</p>")
        Return sb.ToString()
    End Function

    Private Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        Try
            Dim description = Requis(txtDescription.Text, "Description")
            If Not CategoriePaie.Existe(ddlCategorie.SelectedValue) Then Throw New SaisieInvalideException("Catégorie invalide.")

            If ElementId = 0 Then
                Db.Exec("paie.spElementPaie_InsererComplet",
                        Db.P("@c", Contexte.CompagnieId), Db.P("@d", description), Db.P("@cat", ddlCategorie.SelectedValue),
                        Db.P("@a", chkActif.Checked), Db.P("@m", chkMasquer.Checked), Db.P("@gl", txtCompteGL.Text))
            Else
                Dim utilise = Db.ScalaireEntier("paie.spPaieLigne_NbParElement", Db.P("@id", ElementId)) > 0
                Dim actuelle = Convert.ToString(Db.Scalaire("paie.spElementPaie_Categorie", Db.P("@id", ElementId)))
                If utilise AndAlso actuelle <> ddlCategorie.SelectedValue Then
                    Throw New SaisieInvalideException("Cet élément a déjà servi dans une paie : sa catégorie ne peut plus changer. Créez plutôt un nouvel élément.")
                End If
                Db.Exec("paie.spElementPaie_Update",
                        Db.P("@d", description), Db.P("@cat", ddlCategorie.SelectedValue), Db.P("@a", chkActif.Checked),
                        Db.P("@m", chkMasquer.Checked), Db.P("@gl", txtCompteGL.Text), Db.P("@id", ElementId), Db.P("@c", Contexte.CompagnieId))
            End If
            RedirigerAvecMessage("~/Config/ElementsPaie.aspx", "Élément de paie enregistré.")
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub btnSupprimer_Click(sender As Object, e As EventArgs) Handles btnSupprimer.Click
        Dim utilise = Db.ScalaireEntier("paie.spElementPaie_NbUtilisations",
            Db.P("@id", ElementId)) > 0
        If utilise Then
            Erreur("Cet élément est utilisé par des employés ou des paies. Rendez-le inactif plutôt que de le supprimer.")
            Return
        End If
        Db.Exec("paie.spElementPaie_Supprimer", Db.P("@id", ElementId), Db.P("@c", Contexte.CompagnieId))
        RedirigerAvecMessage("~/Config/ElementsPaie.aspx", "Élément de paie supprimé.")
    End Sub

End Class
