Imports Paie60Sec.Calcul

Public Class PageCompagnie
    Inherits PageBase

    Protected Overrides ReadOnly Property ExigeCompagnie As Boolean
        Get
            Return False
        End Get
    End Property

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return

        Dim c = Db.Ligne("SELECT * FROM dbo.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId))
        If c Is Nothing Then
            txtTauxVacances.Text = "4"
            txtFacteurAE.Text = "1,4"
            txtProchainCheque.Text = "1"
            chkCNT.Checked = True
            litTauxFSS.Text = "1,65 %"
            Return
        End If

        txtNom.Text = c.Txt("Nom")
        txtAdresse1.Text = c.Txt("Adresse1")
        txtAdresse2.Text = c.Txt("Adresse2")
        txtVille.Text = c.Txt("Ville")
        txtCodePostal.Text = c.Txt("CodePostal")
        txtTelephone.Text = c.Txt("Telephone")
        txtCourriel.Text = c.Txt("Courriel")
        ddlPeriodes.SelectedValue = c.Ent("PeriodesParAnnee").ToString()
        txtTauxVacances.Text = Champ(c("TauxVacancesDefaut"))
        txtProchainCheque.Text = c.Ent("ProchainNumeroCheque").ToString()
        txtNEFederal.Text = c.Txt("NumeroEntrepriseFederal")
        txtNIRQ.Text = c.Txt("NumeroIdentificationRQ")
        txtMasse.Text = Champ(c("MasseSalarialeEstimee"))
        ddlSecteur.SelectedValue = c.Ent("SecteurFSS").ToString()
        txtFacteurAE.Text = Champ(c("FacteurAE"))
        txtTauxCNESST.Text = Champ(c("TauxCNESST"))
        chkCNT.Checked = c.Bln("AssujettiCNT")
        AfficherTauxFSS(c.Dcm("MasseSalarialeEstimee"), c.Ent("SecteurFSS"))
    End Sub

    Private Sub AfficherTauxFSS(masse As Decimal, secteur As Integer)
        litTauxFSS.Text = ParametresAnnee.TauxFSS(masse, CType(secteur, SecteurFSS)).ToString("N2", FrCa) & " %"
    End Sub

    Private Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        Try
            Dim facteurAE = Dec(txtFacteurAE.Text, "Facteur AE")
            If facteurAE < 1D OrElse facteurAE > 1.4D Then Throw New SaisieInvalideException("Le facteur de cotisation à l'AE doit se situer entre 1 et 1,4.")
            Dim tauxVacances = Dec(txtTauxVacances.Text, "Taux de vacances")
            If tauxVacances > 20D Then Throw New SaisieInvalideException("Le taux de vacances semble trop élevé.")
            Dim masse = Dec(txtMasse.Text, "Masse salariale")
            Dim secteur = Integer.Parse(ddlSecteur.SelectedValue)

            Dim prms = {
                Db.P("@Nom", Requis(txtNom.Text, "Nom de la compagnie")), Db.P("@Adresse1", txtAdresse1.Text), Db.P("@Adresse2", txtAdresse2.Text),
                Db.P("@Ville", txtVille.Text), Db.P("@CodePostal", txtCodePostal.Text.ToUpperInvariant()), Db.P("@Telephone", txtTelephone.Text),
                Db.P("@Courriel", txtCourriel.Text), Db.P("@Periodes", Integer.Parse(ddlPeriodes.SelectedValue)),
                Db.P("@Masse", masse), Db.P("@Secteur", secteur), Db.P("@FacteurAE", facteurAE), Db.P("@TauxVacances", tauxVacances),
                Db.P("@TauxCNESST", Dec(txtTauxCNESST.Text, "Taux CNESST")), Db.P("@CNT", chkCNT.Checked),
                Db.P("@NEFederal", txtNEFederal.Text.ToUpperInvariant()), Db.P("@NIRQ", txtNIRQ.Text.ToUpperInvariant()),
                Db.P("@Cheque", If(EntierN(txtProchainCheque.Text, "Prochain numéro de chèque"), 1)), Db.P("@Id", Contexte.CompagnieId)}

            If Contexte.CompagnieId = 0 Then
                Dim id = Db.Inserer(
                    "INSERT INTO dbo.Compagnie (Nom, Adresse1, Adresse2, Ville, CodePostal, Telephone, Courriel, PeriodesParAnnee, MasseSalarialeEstimee, SecteurFSS, " &
                    "FacteurAE, TauxVacancesDefaut, TauxCNESST, AssujettiCNT, NumeroEntrepriseFederal, NumeroIdentificationRQ, ProchainNumeroCheque) " &
                    "VALUES (@Nom, @Adresse1, @Adresse2, @Ville, @CodePostal, @Telephone, @Courriel, @Periodes, @Masse, @Secteur, " &
                    "@FacteurAE, @TauxVacances, @TauxCNESST, @CNT, @NEFederal, @NIRQ, @Cheque)", prms)
                CreerElementsDeBase(id)
                Contexte.OublierCompagnie()
                Contexte.Journaliser("Compagnie créée.")
                RedirigerAvecMessage("~/Employes/Liste.aspx", "Compagnie enregistrée. Ajoutez maintenant vos employés.")
            Else
                Db.Exec(
                    "UPDATE dbo.Compagnie SET Nom=@Nom, Adresse1=@Adresse1, Adresse2=@Adresse2, Ville=@Ville, CodePostal=@CodePostal, Telephone=@Telephone, " &
                    "Courriel=@Courriel, PeriodesParAnnee=@Periodes, MasseSalarialeEstimee=@Masse, SecteurFSS=@Secteur, FacteurAE=@FacteurAE, " &
                    "TauxVacancesDefaut=@TauxVacances, TauxCNESST=@TauxCNESST, AssujettiCNT=@CNT, NumeroEntrepriseFederal=@NEFederal, " &
                    "NumeroIdentificationRQ=@NIRQ, ProchainNumeroCheque=@Cheque WHERE Id=@Id", prms)
                AfficherTauxFSS(masse, secteur)
                Succes("Compagnie enregistrée.")
            End If
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    ''' <summary>Éléments de paie de départ, pour pouvoir faire une première paie sans configuration.</summary>
    Private Shared Sub CreerElementsDeBase(compagnieId As Integer)
        For Each code In {"SALAIRE", "SALAIRE_FIXE", "TEMPS_DEMI", "FERIE", "VACANCES", "BONUS"}
            Db.Exec("INSERT INTO dbo.ElementPaie (CompagnieId, Description, CategorieCode) VALUES (@c, @d, @code)",
                    Db.P("@c", compagnieId), Db.P("@d", CategoriePaie.ParCode(code).Libelle), Db.P("@code", code))
        Next
    End Sub

End Class
