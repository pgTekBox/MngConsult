Public Class PageCumulatifs
    Inherits PageBase

    Private ReadOnly Property EmployeId As Integer
        Get
            Return IdRequete("id")
        End Get
    End Property

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim emp = Db.Ligne("paie.spEmploye_Nom", Db.P("@id", EmployeId), Db.P("@c", Contexte.CompagnieId))
        If emp Is Nothing Then Response.Redirect("~/Employes/Liste.aspx", True)
        litEmploye.Text = Server.HtmlEncode(emp.Txt("Prenom") & " " & emp.Txt("Nom"))
        lnkFiche.NavigateUrl = "~/Employes/Fiche.aspx?id=" & EmployeId.ToString()

        ' Hors Québec : les mêmes champs reçoivent l'impôt de la province, le RPC et les gains assurables de sa commission
        ' des accidents du travail. Pas de RQAP ; dans un territoire, son champ reçoit l'impôt sur la paie retenu à l'employé.
        If Contexte.HorsQuebec Then
            Dim noms = Contexte.Libelles
            lblImpotQc.Text = noms.ImpotProvincial & " retenu ($)"
            lblGainsRRQ.Text = "Gains ouvrant droit à pension - RPC ($)"
            lblRRQ.Text = "Cotisation au RPC (base + 1re suppl.) ($)"
            lblRRQ2.Text = "2e cotisation supplémentaire au RPC ($)"
            lblGainsCNESST.Text = "Gains assurables " & noms.Accidents & " ($)"
            lblRQAP.Text = "Impôt sur la paie du territoire retenu ($)"
            phRQAP.Visible = noms.ARetenueTerritoriale
            phRQAPEmployeur.Visible = False
        End If

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
        Dim r = Db.Ligne("paie.spCumulatifDepart_Get", Db.P("@e", EmployeId), Db.P("@a", Integer.Parse(ddlAnnee.SelectedValue)))
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
            ' Les champs du RQAP sont masqués hors Québec mais gardent leur valeur : des cumulatifs saisis au Québec
            ' avant un changement de province ne sont pas effacés. La province enregistrée est celle de la compagnie.
            Dim horsQuebec = Contexte.HorsQuebec
            Dim noms = Contexte.Libelles
            Db.Exec("paie.spCumulatifDepart_Enregistrer",
                Db.P("@e", EmployeId), Db.P("@a", annee),
                Db.P("@Brut", Dec(txtBrut.Text, "Rémunération brute")), Db.P("@Fed", Dec(txtImpotFed.Text, "Impôt fédéral")),
                Db.P("@Qc", Dec(txtImpotQc.Text, noms.ImpotProvincial)),
                Db.P("@RRQ", Dec(txtRRQ.Text, noms.Pension)), Db.P("@RRQ2", Dec(txtRRQ2.Text, noms.Pension & " 2")),
                Db.P("@GainsRRQ", Dec(txtGainsRRQ.Text, If(horsQuebec, "Gains ouvrant droit à pension - RPC", "Salaire admissible au RRQ"))),
                Db.P("@AE", Dec(txtAE.Text, "Assurance-emploi")),
                Db.P("@RQAP", Dec(txtRQAP.Text, If(noms.ARetenueTerritoriale, noms.RetenueProvinciale, "RQAP employé"))), Db.P("@RQAPE", Dec(txtRQAPEmployeur.Text, "RQAP employeur")),
                Db.P("@CNESST", Dec(txtGainsCNESST.Text, If(horsQuebec, "Gains assurables " & noms.Accidents, "Salaire assurable CNESST"))),
                Db.P("@Vac", Dec(txtVacances.Text, "Solde de vacances")),
                Db.P("@Province", Paie60Sec.Calcul.Provinces.Code(Contexte.Province)))
            Succes("Cumulatifs de départ " & annee.ToString() & " enregistrés.")
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

End Class
