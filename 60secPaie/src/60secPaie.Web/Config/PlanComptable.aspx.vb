Public Class PagePlanComptable
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then Charger()
    End Sub

    Private Sub Charger()
        Dim comptes = ServiceGL.Comptes()
        Dim t As New DataTable()
        t.Columns.Add("Cle") : t.Columns.Add("Libelle") : t.Columns.Add("Groupe") : t.Columns.Add("Compte")
        For Each k In ServiceGL.ClesAffichees()
            Dim v As String = Nothing
            comptes.TryGetValue(k.Cle, v)
            t.Rows.Add(k.Cle, k.Libelle, k.Groupe, If(v, ""))
        Next
        rptComptes.DataSource = t
        rptComptes.DataBind()

        rptElements.DataSource = Db.Table("paie.spElementPaie_ListeActifs",
                                          Db.P("@c", Contexte.CompagnieId))
        rptElements.DataBind()
    End Sub

    Private Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        Try
            For Each item As RepeaterItem In rptComptes.Items
                ServiceGL.EnregistrerCompte(DirectCast(item.FindControl("hidCle"), HiddenField).Value, DirectCast(item.FindControl("txtCompte"), TextBox).Text)
            Next
            For Each item As RepeaterItem In rptElements.Items
                Dim id As Integer
                If Integer.TryParse(DirectCast(item.FindControl("hidId"), HiddenField).Value, id) Then
                    Db.Exec("paie.spElementPaie_UpdateCompteGL",
                            Db.P("@v", DirectCast(item.FindControl("txtCompte"), TextBox).Text.Trim()), Db.P("@id", id), Db.P("@c", Contexte.CompagnieId))
                End If
            Next
            Charger()
            Succes("Plan comptable enregistré.")
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

End Class
