Public Class PageCumulatifs
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
            For annee = Date.Today.Year To Date.Today.Year - 1 Step -1
                ddlAnnee.Items.Add(annee.ToString())
            Next
            Charger()
        End If
    End Sub

    Private Sub ddlAnnee_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlAnnee.SelectedIndexChanged
        Charger()
    End Sub

    Private Sub Charger()
        Dim r = Db.Ligne("SELECT * FROM dbo.CumulatifDepart WHERE EmployeId = @e AND Annee = @a", Db.P("@e", EmployeId), Db.P("@a", Integer.Parse(ddlAnnee.SelectedValue)))
        txtBrut.Text = Valeur(r, "Brut")
        txtImpotFed.Text = Valeur(r, "ImpotFederal")
        txtImpotQc.Text = Valeur(r, "ImpotQuebec")
        txtGainsRRQ.Text = Valeur(r, "GainsRRQ")
        txtRRQ.Text = Valeur(r, "RRQ")
        txtRRQ2.Text = Valeur(r, "RRQ2")
        txtAE.Text = Valeur(r, "AE")
        txtRQAP.Text = Valeur(r, "RQAP")
        txtRQAPEmployeur.Text = Valeur(r, "RQAPEmployeur")
        txtGainsCNESST.Text = Valeur(r, "GainsCNESST")
        txtVacances.Text = Valeur(r, "VacancesSolde")
    End Sub

    Private Shared Function Valeur(r As DataRow, colonne As String) As String
        If r Is Nothing OrElse r.Dcm(colonne) = 0D Then Return ""
        Return Champ(r(colonne))
    End Function

    Private Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        Try
            Dim annee = Integer.Parse(ddlAnnee.SelectedValue)
            Db.Exec(
                "DELETE FROM dbo.CumulatifDepart WHERE EmployeId = @e AND Annee = @a; " &
                "INSERT INTO dbo.CumulatifDepart (EmployeId, Annee, Brut, ImpotFederal, ImpotQuebec, RRQ, RRQ2, GainsRRQ, AE, RQAP, RQAPEmployeur, GainsCNESST, VacancesSolde) " &
                "VALUES (@e, @a, @Brut, @Fed, @Qc, @RRQ, @RRQ2, @GainsRRQ, @AE, @RQAP, @RQAPE, @CNESST, @Vac)",
                Db.P("@e", EmployeId), Db.P("@a", annee),
                Db.P("@Brut", Dec(txtBrut.Text, "Rémunération brute")), Db.P("@Fed", Dec(txtImpotFed.Text, "Impôt fédéral")),
                Db.P("@Qc", Dec(txtImpotQc.Text, "Impôt du Québec")), Db.P("@RRQ", Dec(txtRRQ.Text, "RRQ")), Db.P("@RRQ2", Dec(txtRRQ2.Text, "RRQ 2")),
                Db.P("@GainsRRQ", Dec(txtGainsRRQ.Text, "Salaire admissible au RRQ")), Db.P("@AE", Dec(txtAE.Text, "Assurance-emploi")),
                Db.P("@RQAP", Dec(txtRQAP.Text, "RQAP employé")), Db.P("@RQAPE", Dec(txtRQAPEmployeur.Text, "RQAP employeur")),
                Db.P("@CNESST", Dec(txtGainsCNESST.Text, "Salaire assurable CNESST")), Db.P("@Vac", Dec(txtVacances.Text, "Solde de vacances")))
            Succes("Cumulatifs de départ " & annee.ToString() & " enregistrés.")
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

End Class
