Imports System.Text
Imports Paie60Sec.Calcul

''' <summary>
''' Paramètres de paie de la compagnie courante. La compagnie elle-même (nom, adresse) appartient à MngConsul ;
''' 60secPaie n'ajoute que ce qui est propre à la paie, dans paie.Compagnie, relié par le CompanyGUID.
''' </summary>
Public Class PageCompagnie
    Inherits PageBase

    Protected Overrides ReadOnly Property ExigeCompagnie As Boolean
        Get
            Return False
        End Get
    End Property

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        AfficherIdentite()
        If IsPostBack Then Return

        Dim c = Db.Ligne("SELECT * FROM paie.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId))
        If c Is Nothing Then
            txtTauxVacances.Text = "4"
            txtFacteurAE.Text = Champ(1.4D)
            txtProchainCheque.Text = "1"
            chkCNT.Checked = True
            litTauxFSS.Text = ParametresAnnee.PourAffichage().TauxFSS(0D, SecteurFSS.General).ToString("N2", I18n.Culture) & " %"
            Return
        End If

        ddlPeriodes.SelectedValue = c.Ent("PeriodesParAnnee").ToString()
        txtTauxVacances.Text = Champ(c("TauxVacancesDefaut"))
        txtProchainCheque.Text = c.Ent("ProchainNumeroCheque").ToString()
        ddlFreqFederale.SelectedValue = If(c.Txt("FrequenceRemiseFederale") = "T", "T", "M")
        ddlFreqQuebec.SelectedValue = If(c.Txt("FrequenceRemiseQuebec") = "T", "T", "M")
        txtNEFederal.Text = c.Txt("NumeroEntrepriseFederal")
        txtNIRQ.Text = c.Txt("NumeroIdentificationRQ")
        txtMasse.Text = Champ(c("MasseSalarialeEstimee"))
        ddlSecteur.SelectedValue = c.Ent("SecteurFSS").ToString()
        txtFacteurAE.Text = Champ(c("FacteurAE"))
        txtTauxCNESST.Text = Champ(c("TauxCNESST"))
        chkCNT.Checked = c.Bln("AssujettiCNT")
        AfficherTauxFSS(c.Dcm("MasseSalarialeEstimee"), c.Ent("SecteurFSS"))
    End Sub

    ''' <summary>Nom et coordonnées tels que définis dans MngConsul, en lecture seule.</summary>
    Private Sub AfficherIdentite()
        Dim i = Contexte.IdentiteCompagnie()
        Dim sb As New StringBuilder("<div class=""identite"">")
        Ajouter(sb, "Nom", If(i.Txt("Nom").Length > 0, i.Txt("Nom"), Contexte.NomCompagnie))
        Ajouter(sb, "Adresse", (i.Txt("Adresse1") & " " & i.Txt("Adresse2")).Trim())
        Ajouter(sb, "Ville", (i.Txt("Ville") & "  " & i.Txt("CodePostal")).Trim())
        Ajouter(sb, "Téléphone", i.Txt("Telephone"))
        Ajouter(sb, "Numéro d'entreprise (NE)", i.Txt("NumeroEntreprise"))
        litIdentite.Text = sb.Append("</div>").ToString()
    End Sub

    Private Shared Sub Ajouter(sb As StringBuilder, libelle As String, valeur As String)
        sb.Append("<div><span>").Append(HttpUtility.HtmlEncode(libelle)).Append("</span>")
        sb.Append(HttpUtility.HtmlEncode(If(valeur.Length = 0, "—", valeur))).Append("</div>")
    End Sub

    Private Sub AfficherTauxFSS(masse As Decimal, secteur As Integer)
        litTauxFSS.Text = ParametresAnnee.PourAffichage().TauxFSS(masse, CType(secteur, SecteurFSS)).ToString("N2", I18n.Culture) & " %"
    End Sub

    Private Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        Try
            Dim facteurAE = Dec(txtFacteurAE.Text, "Facteur AE")
            If facteurAE < 1D OrElse facteurAE > 1.4D Then Throw New SaisieInvalideException(Tr("Le facteur de cotisation à l'AE doit se situer entre 1 et 1,4."))
            Dim tauxVacances = Dec(txtTauxVacances.Text, "Taux de vacances")
            If tauxVacances > 20D Then Throw New SaisieInvalideException(Tr("Le taux de vacances semble trop élevé."))
            Dim masse = Dec(txtMasse.Text, "Masse salariale")
            Dim secteur = Integer.Parse(ddlSecteur.SelectedValue)

            Dim prms = {
                Db.P("@Periodes", Integer.Parse(ddlPeriodes.SelectedValue)),
                Db.P("@Masse", masse), Db.P("@Secteur", secteur), Db.P("@FacteurAE", facteurAE), Db.P("@TauxVacances", tauxVacances),
                Db.P("@TauxCNESST", Dec(txtTauxCNESST.Text, "Taux CNESST")), Db.P("@CNT", chkCNT.Checked),
                Db.P("@NEFederal", txtNEFederal.Text.ToUpperInvariant()), Db.P("@NIRQ", txtNIRQ.Text.ToUpperInvariant()),
                Db.P("@Cheque", If(EntierN(txtProchainCheque.Text, "Prochain numéro de chèque"), 1)), Db.P("@Id", Contexte.CompagnieId),
                Db.P("@FreqFed", If(ddlFreqFederale.SelectedValue = "T", "T", "M")), Db.P("@FreqQc", If(ddlFreqQuebec.SelectedValue = "T", "T", "M")),
                Db.P("@Guid", Contexte.CompanyGuid), Db.P("@Nom", If(Contexte.NomCompagnie.Length = 0, "(sans nom)", Contexte.NomCompagnie))}

            If Contexte.CompagnieId = 0 Then
                ' Première configuration de la paie pour cette compagnie de MngConsul.
                Dim id = Db.Inserer(
                    "INSERT INTO paie.Compagnie (CompanyGUID, Nom, PeriodesParAnnee, MasseSalarialeEstimee, SecteurFSS, FacteurAE, TauxVacancesDefaut, TauxCNESST, " &
                    "AssujettiCNT, NumeroEntrepriseFederal, NumeroIdentificationRQ, ProchainNumeroCheque, FrequenceRemiseFederale, FrequenceRemiseQuebec) " &
                    "VALUES (@Guid, @Nom, @Periodes, @Masse, @Secteur, @FacteurAE, @TauxVacances, @TauxCNESST, @CNT, @NEFederal, @NIRQ, @Cheque, @FreqFed, @FreqQc)", prms)
                CreerElementsDeBase(id)
                Contexte.OublierCompagnie()
                Contexte.SynchroniserCompagnie()
                Contexte.Journaliser("Paie configurée pour la compagnie.")
                RedirigerAvecMessage("~/Employes/Liste.aspx", Tr("Paramètres de paie enregistrés. Configurez maintenant la paie de vos employés."))
            Else
                Db.Exec(
                    "UPDATE paie.Compagnie SET PeriodesParAnnee=@Periodes, MasseSalarialeEstimee=@Masse, SecteurFSS=@Secteur, FacteurAE=@FacteurAE, " &
                    "TauxVacancesDefaut=@TauxVacances, TauxCNESST=@TauxCNESST, AssujettiCNT=@CNT, NumeroEntrepriseFederal=@NEFederal, " &
                    "NumeroIdentificationRQ=@NIRQ, ProchainNumeroCheque=@Cheque, FrequenceRemiseFederale=@FreqFed, FrequenceRemiseQuebec=@FreqQc " &
                    "WHERE Id=@Id AND CompanyGUID=@Guid", prms)
                AfficherTauxFSS(masse, secteur)
                Succes("Paramètres de paie enregistrés.")
            End If
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    ''' <summary>Éléments de paie de départ, pour pouvoir faire une première paie sans configuration.</summary>
    Private Shared Sub CreerElementsDeBase(compagnieId As Integer)
        For Each code In {"SALAIRE", "SALAIRE_FIXE", "TEMPS_DEMI", "FERIE", "VACANCES", "BONUS"}
            Db.Exec("INSERT INTO paie.ElementPaie (CompagnieId, Description, CategorieCode) VALUES (@c, @d, @code)",
                    Db.P("@c", compagnieId), Db.P("@d", CategoriePaie.ParCode(code).Libelle), Db.P("@code", code))
        Next
    End Sub

End Class
