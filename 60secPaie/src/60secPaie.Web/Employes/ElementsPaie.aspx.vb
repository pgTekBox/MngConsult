Imports Paie60Sec.Calcul

Public Class PageEmployeElements
    Inherits PageBase

    Private ReadOnly Property EmployeId As Integer
        Get
            Return IdRequete("id")
        End Get
    End Property

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim emp = Db.Ligne("SELECT Prenom, Nom FROM dbo.Employe WHERE Id = @id AND CompagnieId = @c", Db.P("@id", EmployeId), Db.P("@c", Contexte.CompagnieId))
        If emp Is Nothing Then Response.Redirect("~/Employes/Liste.aspx", True)
        litEmploye.Text = Server.HtmlEncode(emp.Txt("Prenom") & " " & emp.Txt("Nom"))
        lnkFiche.NavigateUrl = "~/Employes/Fiche.aspx?id=" & EmployeId.ToString()

        If Not IsPostBack Then
            Dim elements = Db.Table("SELECT Id, Description, CategorieCode FROM dbo.ElementPaie WHERE CompagnieId = @c AND Actif = 1 ORDER BY Description",
                                    Db.P("@c", Contexte.CompagnieId))
            For Each el As DataRow In elements.Rows
                ddlElement.Items.Add(New ListItem(el.Txt("Description") & "  (" & LibelleCategorie(el("CategorieCode")) & ")", el.Ent("Id").ToString()))
            Next
        End If
    End Sub

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        Dim t = Db.Table(
            "SELECT ee.Id, el.Description, el.CategorieCode, ee.Heures, ee.Taux, ee.Montant, ee.Montant AS Total " &
            "FROM dbo.EmployeElement ee JOIN dbo.ElementPaie el ON el.Id = ee.ElementPaieId WHERE ee.EmployeId = @e ORDER BY ee.Id",
            Db.P("@e", EmployeId))
        rptLignes.DataSource = t
        rptLignes.DataBind()
        rptLignes.Visible = t.Rows.Count > 0
        lblAucune.Visible = t.Rows.Count = 0
    End Sub

    Protected Function LibelleCategorie(code As Object) As String
        Dim c = Convert.ToString(code)
        Return If(CategoriePaie.Existe(c), CategoriePaie.ParCode(c).LibelleComplet, c)
    End Function

    Private Sub btnAjouter_Click(sender As Object, e As EventArgs) Handles btnAjouter.Click
        Try
            Dim elementId As Integer
            If Not Integer.TryParse(ddlElement.SelectedValue, elementId) Then Throw New SaisieInvalideException("Choisissez un élément de paie.")
            Dim element = Db.Ligne("SELECT CategorieCode FROM dbo.ElementPaie WHERE Id = @id AND CompagnieId = @c", Db.P("@id", elementId), Db.P("@c", Contexte.CompagnieId))
            If element Is Nothing Then Throw New SaisieInvalideException("Élément de paie introuvable.")

            Dim heures = Dec(txtHeures.Text, "Heures")
            Dim taux = Dec(txtTaux.Text, "Taux horaire")
            Dim total = ServicePaie.MontantLigne(element.Txt("CategorieCode"), heures, taux, Dec(txtMontant.Text, "Montant"))
            If total <= 0D Then Throw New SaisieInvalideException("Inscrivez des heures et un taux, ou un montant.")

            Db.Exec("INSERT INTO dbo.EmployeElement (EmployeId, ElementPaieId, Heures, Taux, Montant) VALUES (@e, @el, @h, @t, @m)",
                    Db.P("@e", EmployeId), Db.P("@el", elementId), Db.P("@h", heures), Db.P("@t", taux), Db.P("@m", total))
            txtHeures.Text = "" : txtTaux.Text = "" : txtMontant.Text = ""
            Succes("Élément ajouté.")
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub rptLignes_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptLignes.ItemCommand
        If e.CommandName = "Supprimer" Then
            Db.Exec("DELETE FROM dbo.EmployeElement WHERE Id = @id AND EmployeId = @e", Db.P("@id", Convert.ToInt32(e.CommandArgument)), Db.P("@e", EmployeId))
            Succes("Élément retiré.")
        End If
    End Sub

End Class
