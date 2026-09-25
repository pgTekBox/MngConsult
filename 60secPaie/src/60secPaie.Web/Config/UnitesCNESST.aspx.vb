''' <summary>
''' Configuration › Unités CNESST : les unités de classification de la compagnie,
''' avec leur taux. L'employé en choisit une dans sa fiche ; sans unité, le taux
''' de la compagnie s'applique, comme avant. Une unité utilisée par un employé
''' ou par une paie confirmée ne se supprime pas : on la désactive.
''' </summary>
Public Class PageConfigUnitesCNESST
    Inherits PageBase

    Private ReadOnly Property UniteId As Integer
        Get
            Return IdRequete("id")
        End Get
    End Property

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return
        ChargerListe()
        If UniteId > 0 Then ChargerUnite()
    End Sub

    Private Sub ChargerListe()
        Dim t = Db.Table(
            "SELECT u.Id, u.Code, u.Description, u.Taux, u.Actif, " &
            "(SELECT COUNT(*) FROM paie.EmployePaie ep WHERE ep.UniteCNESSTId = u.Id) AS NbEmployes " &
            "FROM paie.UniteCNESST u WHERE u.CompagnieId = @c ORDER BY u.Actif DESC, u.Code", Db.P("@c", Contexte.CompagnieId))
        rptUnites.DataSource = t
        rptUnites.DataBind()
        rptUnites.Visible = t.Rows.Count > 0
        lblAucune.Visible = t.Rows.Count = 0
    End Sub

    Private Sub ChargerUnite()
        Dim u = Db.Ligne("SELECT * FROM paie.UniteCNESST WHERE Id = @id AND CompagnieId = @c", Db.P("@id", UniteId), Db.P("@c", Contexte.CompagnieId))
        If u Is Nothing Then Response.Redirect("~/Config/UnitesCNESST.aspx", True)
        litTitreForm.Text = "Modifier l'unité " & Server.HtmlEncode(u.Txt("Code"))
        txtCode.Text = u.Txt("Code")
        txtDescription.Text = u.Txt("Description")
        txtTaux.Text = Champ(u("Taux"))
        chkActif.Checked = u.Bln("Actif")
        btnSupprimer.Visible = True
    End Sub

    Protected Function Taux(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value Then Return ""
        Return Convert.ToDecimal(v).ToString("0.00##", Globalization.CultureInfo.GetCultureInfo("fr-CA"))
    End Function

    Private Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        Try
            Dim code = Requis(txtCode.Text, "Code de l'unité").ToUpperInvariant()
            Dim description = Requis(txtDescription.Text, "Description")
            Dim taux = Dec(txtTaux.Text, "Taux")
            If taux > 20D Then Throw New SaisieInvalideException(Tr("Le taux semble trop élevé : il s'exprime en dollars par 100 $ de salaire."))

            Dim doublon = Db.ScalaireEntier(
                "SELECT COUNT(*) FROM paie.UniteCNESST WHERE CompagnieId = @c AND Code = @code AND Id <> @id",
                Db.P("@c", Contexte.CompagnieId), Db.P("@code", code), Db.P("@id", UniteId))
            If doublon > 0 Then Throw New SaisieInvalideException(Tr("L'unité {0} existe déjà.", code))

            If UniteId > 0 Then
                Db.Exec("UPDATE paie.UniteCNESST SET Code = @code, Description = @d, Taux = @t, Actif = @a WHERE Id = @id AND CompagnieId = @c",
                        Db.P("@code", code), Db.P("@d", description), Db.P("@t", taux), Db.P("@a", chkActif.Checked),
                        Db.P("@id", UniteId), Db.P("@c", Contexte.CompagnieId))
            Else
                Db.Exec("INSERT INTO paie.UniteCNESST (CompagnieId, Code, Description, Taux, Actif) VALUES (@c, @code, @d, @t, @a)",
                        Db.P("@c", Contexte.CompagnieId), Db.P("@code", code), Db.P("@d", description), Db.P("@t", taux), Db.P("@a", chkActif.Checked))
            End If
            RedirigerAvecMessage("~/Config/UnitesCNESST.aspx", Tr("Unité {0} enregistrée.", code))
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub btnSupprimer_Click(sender As Object, e As EventArgs) Handles btnSupprimer.Click
        Dim utilisee = Db.ScalaireEntier(
            "SELECT (SELECT COUNT(*) FROM paie.EmployePaie WHERE UniteCNESSTId = @id) + (SELECT COUNT(*) FROM paie.Paie WHERE UniteCNESSTId = @id)",
            Db.P("@id", UniteId))
        If utilisee > 0 Then
            Erreur(Tr("Cette unité est utilisée par des employés ou des paies. Rendez-la inactive plutôt que de la supprimer."))
            Return
        End If
        Db.Exec("DELETE FROM paie.UniteCNESST WHERE Id = @id AND CompagnieId = @c", Db.P("@id", UniteId), Db.P("@c", Contexte.CompagnieId))
        RedirigerAvecMessage("~/Config/UnitesCNESST.aspx", Tr("Unité supprimée."))
    End Sub

End Class
