Imports System.Text
Imports Paie60Sec.Calcul

''' <summary>
''' Paramètres de paie de la compagnie courante. La compagnie elle-même (nom, adresse) appartient à MngConsul ;
''' 60secPaie n'ajoute que ce qui est propre à la paie, dans paie.Compagnie, relié par le CompanyGUID.
'''
''' La province ou le territoire d'emploi se choisit ici, parmi les treize que le moteur sait calculer. Les champs
''' propres à une province sont masqués pour les autres ; le taux de la CNESST et celui de la commission des
''' accidents du travail d'une autre province (WSIB, WCB…) partagent la colonne TauxCNESST, comme leurs montants.
'''
''' Cotisation santé de l'employeur : le FSS (Québec) et l'ISE (Ontario) se calculent d'après la masse salariale.
''' Ailleurs où il en existe une (Colombie-Britannique, Manitoba, Terre-Neuve-et-Labrador), l'employeur saisit
''' lui-même son taux effectif, gardé dans TauxSanteEmployeur ; voir ServicePaie.TauxSanteEmployeur.
''' </summary>
Public Class PageCompagnie
    Inherits PageBase

    Protected Overrides ReadOnly Property ExigeCompagnie As Boolean
        Get
            Return False
        End Get
    End Property

    ''' <summary>Les treize provinces et territoires, dans l'ordre du moteur. Remplie à chaque requête, avant la relecture de la saisie.</summary>
    Private Sub Page_Init(sender As Object, e As EventArgs) Handles Me.Init
        ddlProvince.Items.Clear()
        For Each p In Provinces.Gerees
            ddlProvince.Items.Add(New ListItem(Provinces.Nom(p), Provinces.Code(p)))
        Next
        ddlProvince.SelectedValue = "QC"
    End Sub

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        AfficherIdentite()
        If IsPostBack Then Return

        Dim c = Db.Ligne("SELECT * FROM paie.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId))
        If c Is Nothing Then
            txtTauxVacances.Text = "4"
            txtFacteurAE.Text = Champ(1.4D)
            txtProchainCheque.Text = "1"
            chkCNT.Checked = True
            AfficherProvince()
            AfficherTaux(0D, 0)
            Return
        End If

        ddlProvince.SelectedValue = If(Provinces.EstGeree(c.Txt("Province")), c.Txt("Province").Trim().ToUpperInvariant(), "QC")
        ddlISE.SelectedValue = If(c.Bln("ISEExemptionAdmissible"), "1", "0")
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
        txtTauxAccidents.Text = Champ(c("TauxCNESST"))
        txtTauxSante.Text = Champ(c("TauxSanteEmployeur"))
        chkCNT.Checked = c.Bln("AssujettiCNT")
        AfficherProvince()
        AfficherTaux(c.Dcm("MasseSalarialeEstimee"), c.Ent("SecteurFSS"))
    End Sub

    Private ReadOnly Property ProvinceChoisie As Province
        Get
            Return Provinces.DeCode(ddlProvince.SelectedValue)
        End Get
    End Property

    ''' <summary>Vrai si le taux de la cotisation santé de l'employeur se saisit : il y en a une, et 60secPaie n'en a pas le barème.</summary>
    Private Shared Function SanteSaisie(p As Province) As Boolean
        Return p <> Province.Quebec AndAlso p <> Province.Ontario AndAlso LibellesProvince.Pour(p).ASante
    End Function

    ''' <summary>Montre les champs de la province choisie et masque ceux des autres.</summary>
    Private Sub AfficherProvince()
        Dim p = ProvinceChoisie
        Dim noms = LibellesProvince.Pour(p)
        Dim quebec = p = Province.Quebec
        Dim ontario = p = Province.Ontario
        phQuebecRemise.Visible = quebec
        phQuebecNumero.Visible = quebec
        phQuebecMasse.Visible = quebec
        phQuebecSecteur.Visible = quebec
        phQuebecCNESST.Visible = quebec
        phQuebecCNT.Visible = quebec
        phHorsQuebecNote.Visible = Not quebec
        phTerritoireNote.Visible = noms.ARetenueTerritoriale
        ' La masse salariale ne sert qu'aux barèmes du FSS et de l'ISE de l'Ontario.
        phMasse.Visible = quebec OrElse ontario
        phOntarioMasse.Visible = ontario
        phOntarioISE.Visible = ontario
        phSante.Visible = SanteSaisie(p)
        phAccidents.Visible = Not quebec
        If quebec Then Return

        lblTauxSante.Text = String.Format("Taux effectif : {0} (%)", noms.SanteLong)
        lblTauxAccidents.Text = String.Format("Taux de prime {0} ($ par 100 $ assurables)", noms.Accidents)
        litAideAccidents.Text = String.Format("Inscrit sur votre relevé de primes. Avec plusieurs classes, définissez-les dans « {0} » et affectez chaque employé à la sienne.",
                                              "Classes " & noms.Accidents)
    End Sub

    Private Sub ddlProvince_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlProvince.SelectedIndexChanged
        ' Le taux saisi suit la province : celui de la CNESST devient le point de départ de celui de l'autre commission, et inversement.
        ' Entre deux provinces hors Québec, le champ est le même : le taux reste, à vérifier par l'utilisateur.
        If ProvinceChoisie = Province.Quebec Then
            If phAccidents.Visible Then txtTauxCNESST.Text = txtTauxAccidents.Text
        ElseIf phQuebecCNESST.Visible Then
            txtTauxAccidents.Text = txtTauxCNESST.Text
        End If
        AfficherProvince()
        Dim masse As Decimal = 0D
        Try
            masse = Dec(txtMasse.Text, "Masse salariale")
        Catch ex As SaisieInvalideException
            ' Saisie en cours : le taux s'affichera à l'enregistrement.
        End Try
        AfficherTaux(masse, Integer.Parse(ddlSecteur.SelectedValue))
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

    ''' <summary>Le taux de la cotisation santé de l'employeur qui sera appliqué : FSS au Québec, ISE (taux effectif) en Ontario. Ailleurs il est saisi, ou il n'y en a pas.</summary>
    Private Sub AfficherTaux(masse As Decimal, secteur As Integer)
        Dim prm = ParametresAnnee.PourAffichage()
        litTauxFSS.Text = prm.TauxFSS(masse, CType(secteur, SecteurFSS)).ToString("N2", I18n.Culture) & " %"
        litTauxISE.Text = If(prm.EstDefinie(Province.Ontario),
                             prm.TauxISE(masse, ddlISE.SelectedValue = "1").ToString("0.00##", I18n.Culture) & " %", "—")
    End Sub

    Private Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        Try
            Dim facteurAE = Dec(txtFacteurAE.Text, "Facteur AE")
            If facteurAE < 1D OrElse facteurAE > 1.4D Then Throw New SaisieInvalideException(Tr("Le facteur de cotisation à l'AE doit se situer entre 1 et 1,4."))
            Dim tauxVacances = Dec(txtTauxVacances.Text, "Taux de vacances")
            If tauxVacances > 20D Then Throw New SaisieInvalideException(Tr("Le taux de vacances semble trop élevé."))
            Dim masse = Dec(txtMasse.Text, "Masse salariale")
            Dim secteur = Integer.Parse(ddlSecteur.SelectedValue)
            Dim provinceChoisie = Me.ProvinceChoisie
            Dim province = Provinces.Code(provinceChoisie)
            Dim tauxAccidents = If(provinceChoisie = Calcul.Province.Quebec, Dec(txtTauxCNESST.Text, "Taux CNESST"), Dec(txtTauxAccidents.Text, "Taux de prime"))
            ' Le taux saisi de la cotisation santé reste au dossier même si la province choisie n'en a pas : il n'y sert pas.
            Dim tauxSante = Dec(txtTauxSante.Text, "Taux de la cotisation santé")
            If SanteSaisie(provinceChoisie) AndAlso tauxSante > 5D Then Throw New SaisieInvalideException(Tr("Le taux de la cotisation santé de l'employeur semble trop élevé : inscrivez un pourcentage (par exemple 1,95)."))

            Dim prms = {
                Db.P("@Periodes", Integer.Parse(ddlPeriodes.SelectedValue)),
                Db.P("@Province", province), Db.P("@ISE", ddlISE.SelectedValue = "1"),
                Db.P("@Masse", masse), Db.P("@Secteur", secteur), Db.P("@FacteurAE", facteurAE), Db.P("@TauxVacances", tauxVacances),
                Db.P("@TauxCNESST", tauxAccidents), Db.P("@TauxSante", tauxSante), Db.P("@CNT", chkCNT.Checked),
                Db.P("@NEFederal", txtNEFederal.Text.ToUpperInvariant()), Db.P("@NIRQ", txtNIRQ.Text.ToUpperInvariant()),
                Db.P("@Cheque", If(EntierN(txtProchainCheque.Text, "Prochain numéro de chèque"), 1)), Db.P("@Id", Contexte.CompagnieId),
                Db.P("@FreqFed", If(ddlFreqFederale.SelectedValue = "T", "T", "M")), Db.P("@FreqQc", If(ddlFreqQuebec.SelectedValue = "T", "T", "M")),
                Db.P("@Guid", Contexte.CompanyGuid), Db.P("@Nom", If(Contexte.NomCompagnie.Length = 0, "(sans nom)", Contexte.NomCompagnie))}

            If Contexte.CompagnieId = 0 Then
                ' Première configuration de la paie pour cette compagnie de MngConsul.
                Dim id = Db.Inserer(
                    "INSERT INTO paie.Compagnie (CompanyGUID, Nom, PeriodesParAnnee, MasseSalarialeEstimee, SecteurFSS, FacteurAE, TauxVacancesDefaut, TauxCNESST, " &
                    "AssujettiCNT, NumeroEntrepriseFederal, NumeroIdentificationRQ, ProchainNumeroCheque, FrequenceRemiseFederale, FrequenceRemiseQuebec, " &
                    "Province, ISEExemptionAdmissible, TauxSanteEmployeur) " &
                    "VALUES (@Guid, @Nom, @Periodes, @Masse, @Secteur, @FacteurAE, @TauxVacances, @TauxCNESST, @CNT, @NEFederal, @NIRQ, @Cheque, @FreqFed, @FreqQc, " &
                    "@Province, @ISE, @TauxSante)", prms)
                CreerElementsDeBase(id)
                Contexte.OublierCompagnie()
                Contexte.SynchroniserCompagnie()
                Contexte.Journaliser("Paie configurée pour la compagnie.")
                RedirigerAvecMessage("~/Employes/Liste.aspx", Tr("Paramètres de paie enregistrés. Configurez maintenant la paie de vos employés."))
            Else
                Dim provinceAvant = Provinces.Code(Contexte.Province)
                Dim compagnieId = Contexte.CompagnieId
                Db.Exec(
                    "UPDATE paie.Compagnie SET PeriodesParAnnee=@Periodes, MasseSalarialeEstimee=@Masse, SecteurFSS=@Secteur, FacteurAE=@FacteurAE, " &
                    "TauxVacancesDefaut=@TauxVacances, TauxCNESST=@TauxCNESST, AssujettiCNT=@CNT, NumeroEntrepriseFederal=@NEFederal, " &
                    "NumeroIdentificationRQ=@NIRQ, ProchainNumeroCheque=@Cheque, FrequenceRemiseFederale=@FreqFed, FrequenceRemiseQuebec=@FreqQc, " &
                    "Province=@Province, ISEExemptionAdmissible=@ISE, TauxSanteEmployeur=@TauxSante " &
                    "WHERE Id=@Id AND CompanyGUID=@Guid", prms)
                Contexte.OublierCompagnie()
                AfficherProvince()
                AfficherTaux(masse, secteur)
                If provinceAvant <> province Then
                    ' Une paie en préparation a été calculée avec l'ancienne province : elle est à recalculer.
                    Db.Exec("UPDATE paie.LotPaie SET Calcule = 0 WHERE CompagnieId = @c AND Statut = 'B'; " &
                            "UPDATE p SET Province = @prov FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE l.CompagnieId = @c AND l.Statut = 'B'",
                            Db.P("@c", compagnieId), Db.P("@prov", province))
                    Contexte.Journaliser("Province d'emploi de la compagnie changée : " & provinceAvant & " → " & province & ".")
                    Dim dejaPayee = Db.ScalaireEntier("SELECT COUNT(*) FROM paie.LotPaie WHERE CompagnieId = @c AND Statut = 'C' AND YEAR(DatePaie) = @a",
                                                      Db.P("@c", compagnieId), Db.P("@a", Date.Today.Year)) > 0
                    If dejaPayee Then
                        Succes("Paramètres de paie enregistrés. La province d'emploi a changé en cours d'année : les paies déjà confirmées gardent la leur. Vérifiez les taux de l'employeur, les unités de classification et les formulaires de crédits des employés, qui étaient ceux de l'autre province, et prévoyez un T4 par province pour les employés payés dans les deux.")
                    Else
                        Succes("Paramètres de paie enregistrés. La province d'emploi a changé : les prochaines paies seront calculées selon ses règles ; les paies déjà confirmées gardent la leur. Vérifiez les taux de l'employeur et les formulaires de crédits des employés, qui étaient ceux de l'autre province.")
                    End If
                Else
                    Succes("Paramètres de paie enregistrés.")
                End If
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
