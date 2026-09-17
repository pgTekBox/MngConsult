Imports Paie60Sec.Calcul

Public Class PageFicheEmploye
    Inherits PageBase

    Private ReadOnly Property EmployeId As Integer
        Get
            Return IdRequete("id")
        End Get
    End Property

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return

        Dim annee = If(ParametresAnnee.EstDisponible(Date.Today.Year), Date.Today.Year, 2026)
        Dim prm = ParametresAnnee.Pour(annee)
        litBaseFed.Text = Argent(prm.FedMontantPersonnelBase)
        litBaseQc.Text = Argent(prm.QcMontantPersonnelBase)

        If EmployeId = 0 Then
            litTitre.Text = "Nouvel employé"
            txtDateEmbauche.Text = TexteDate(Date.Today)
            Return
        End If

        Dim r = Db.Ligne("SELECT * FROM dbo.Employe WHERE Id = @id AND CompagnieId = @c", Db.P("@id", EmployeId), Db.P("@c", Contexte.CompagnieId))
        If r Is Nothing Then Response.Redirect("~/Employes/Liste.aspx", True)

        litTitre.Text = Server.HtmlEncode(r.Txt("Prenom") & " " & r.Txt("Nom"))
        pnlLiens.Visible = True
        lnkElements.NavigateUrl = "~/Employes/ElementsPaie.aspx?id=" & EmployeId.ToString()
        lnkCumulatifs.NavigateUrl = "~/Employes/Cumulatifs.aspx?id=" & EmployeId.ToString()

        chkActif.Checked = r.Bln("Actif")
        txtPrenom.Text = r.Txt("Prenom")
        txtNom.Text = r.Txt("Nom")
        txtCode.Text = r.Txt("Code")
        txtDateNaissance.Text = TexteDate(r("DateNaissance"))
        txtAdresse1.Text = r.Txt("Adresse1")
        txtAdresse2.Text = r.Txt("Adresse2")
        txtVille.Text = r.Txt("Ville")
        txtCodePostal.Text = r.Txt("CodePostal")
        txtCourriel.Text = r.Txt("Courriel")
        txtTelephone.Text = r.Txt("Telephone")
        ddlLangue.SelectedValue = r.Txt("Langue")

        ' Le NAS et le compte bancaire ne sont jamais renvoyés au navigateur : on n'affiche que la fin.
        Dim nas = Secret.Reveler(r.Txt("NASChiffre"))
        litNasActuel.Text = If(nas.Length = 0, "Aucun NAS au dossier.", "NAS au dossier : " & Server.HtmlEncode(Secret.Masquer(nas)) & ". Laissez vide pour le conserver.")
        Dim compte = Secret.Reveler(r.Txt("CompteChiffre"))
        litCompteActuel.Text = If(compte.Length = 0, "", "Compte au dossier : " & Server.HtmlEncode(Secret.Masquer(compte)) & ". Laissez vide pour le conserver.")

        txtPoste.Text = r.Txt("Poste")
        txtDateEmbauche.Text = TexteDate(r("DateEmbauche"))
        txtDateFin.Text = TexteDate(r("DateFinEmploi"))
        ddlPeriodes.SelectedValue = If(r.IsNull("PeriodesParAnnee"), "", r.Ent("PeriodesParAnnee").ToString())
        txtHeuresSemaine.Text = Champ(r("HeuresSemaine"))
        txtTauxHoraire.Text = Champ(r("TauxHoraire"))
        txtSalaireAnnuel.Text = Champ(r("SalaireAnnuel"))
        txtTauxVacances.Text = Champ(r("TauxVacances"))

        chkExFed.Checked = r.Bln("ExemptImpotFederal")
        chkExQc.Checked = r.Bln("ExemptImpotQuebec")
        chkExRRQ.Checked = r.Bln("ExemptRRQ")
        chkExRQAP.Checked = r.Bln("ExemptRQAP")
        chkExAE.Checked = r.Bln("ExemptAE")
        chkExFSS.Checked = r.Bln("ExemptFSS")
        chkExCNESST.Checked = r.Bln("ExemptCNESST")

        txtTD1Montant.Text = Champ(r("TD1MontantDemande"))
        txtTD1Additionnel.Text = ChampNonNul(r("TD1ImpotAdditionnel"))
        txtTD1Zone.Text = ChampNonNul(r("TD1DeductionZone"))
        txtTD1Deductions.Text = ChampNonNul(r("TD1DeductionsAnnuelles"))
        txtTD1Credits.Text = ChampNonNul(r("TD1AutresCredits"))

        txtTPMontant.Text = Champ(r("TP1015Montant"))
        txtTPAdditionnel.Text = ChampNonNul(r("TP1015ImpotAdditionnel"))
        txtTPLigne19.Text = ChampNonNul(r("TP1015DeductionsLigne19"))
        txtTP1016Deductions.Text = ChampNonNul(r("TP1016Deductions"))
        txtTP1016Credits.Text = ChampNonNul(r("TP1016Credits"))

        chkDepot.Checked = r.Bln("DepotDirect")
        chkTalonCourriel.Checked = r.Bln("TalonParCourriel")
        txtTransit.Text = r.Txt("Transit")
        txtInstitution.Text = r.Txt("Institution")
        txtNote.Text = r.Txt("Note")
    End Sub

    Private Function RappelExemptions() As String
        Dim nb = {chkExFed, chkExQc, chkExRRQ, chkExRQAP, chkExAE, chkExFSS, chkExCNESST}.Where(Function(c) c.Checked).Count()
        If nb = 0 Then Return ""
        Return " Attention : " & nb.ToString() & " exemption(s) cochée(s), ces retenues ou cotisations ne seront pas calculées pour cet employé."
    End Function

    Private Shared Function ChampNonNul(valeur As Object) As String
        If IsDBNull(valeur) OrElse Convert.ToDecimal(valeur) = 0D Then Return ""
        Return Champ(valeur)
    End Function

    Private Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        Try
            Dim actuel As DataRow = Nothing
            If EmployeId > 0 Then
                actuel = Db.Ligne("SELECT NASChiffre, CompteChiffre FROM dbo.Employe WHERE Id = @id AND CompagnieId = @c",
                                  Db.P("@id", EmployeId), Db.P("@c", Contexte.CompagnieId))
                If actuel Is Nothing Then Throw New SaisieInvalideException("Employé introuvable.")
            End If

            ' NAS : vide = conserver la valeur au dossier
            Dim nasChiffre As String = If(actuel Is Nothing, Nothing, actuel.Txt("NASChiffre"))
            Dim nas = Chiffres(txtNAS.Text)
            If nas.Length > 0 Then
                If Not NasValide(nas) Then Throw New SaisieInvalideException("Le numéro d'assurance sociale est invalide.")
                nasChiffre = Secret.Proteger(nas)
            End If

            Dim compteChiffre As String = If(actuel Is Nothing, Nothing, actuel.Txt("CompteChiffre"))
            Dim compte = Chiffres(txtCompte.Text)
            If compte.Length > 0 Then compteChiffre = Secret.Proteger(compte)

            Dim transit = Chiffres(txtTransit.Text)
            Dim institution = Chiffres(txtInstitution.Text)
            If chkDepot.Checked Then
                If transit.Length <> 5 OrElse institution.Length <> 3 OrElse String.IsNullOrEmpty(compteChiffre) Then
                    Throw New SaisieInvalideException("Dépôt direct : inscrivez le transit (5 chiffres), l'institution (3 chiffres) et le numéro de compte.")
                End If
            End If

            Dim naissance = DateN(txtDateNaissance.Text, "Date de naissance")
            If naissance.HasValue AndAlso naissance.Value > Date.Today Then Throw New SaisieInvalideException("La date de naissance est dans le futur.")
            Dim embauche = DateN(txtDateEmbauche.Text, "Date d'embauche")
            Dim fin = DateN(txtDateFin.Text, "Date de fin d'emploi")
            If embauche.HasValue AndAlso fin.HasValue AndAlso fin.Value < embauche.Value Then
                Throw New SaisieInvalideException("La date de fin d'emploi précède la date d'embauche.")
            End If
            Dim tauxVacances = DecN(txtTauxVacances.Text, "Taux de vacances")
            If tauxVacances.HasValue AndAlso tauxVacances.Value > 20D Then Throw New SaisieInvalideException("Le taux de vacances semble trop élevé.")

            Dim prms = {
                Db.P("@Actif", chkActif.Checked), Db.P("@Code", txtCode.Text),
                Db.P("@Prenom", Requis(txtPrenom.Text, "Prénom")), Db.P("@Nom", Requis(txtNom.Text, "Nom")),
                Db.P("@Adresse1", txtAdresse1.Text), Db.P("@Adresse2", txtAdresse2.Text), Db.P("@Ville", txtVille.Text),
                Db.P("@CodePostal", txtCodePostal.Text.ToUpperInvariant()), Db.P("@Courriel", txtCourriel.Text), Db.P("@Telephone", txtTelephone.Text),
                Db.P("@DateNaissance", naissance), Db.P("@Langue", ddlLangue.SelectedValue), Db.P("@NAS", nasChiffre),
                Db.P("@Poste", txtPoste.Text), Db.P("@DateEmbauche", embauche), Db.P("@DateFin", fin),
                Db.P("@Periodes", EntierN(ddlPeriodes.SelectedValue, "Période de paie")),
                Db.P("@HeuresSemaine", DecN(txtHeuresSemaine.Text, "Heures par semaine")),
                Db.P("@TauxHoraire", DecN(txtTauxHoraire.Text, "Taux horaire")),
                Db.P("@SalaireAnnuel", DecN(txtSalaireAnnuel.Text, "Salaire annuel")),
                Db.P("@TauxVacances", tauxVacances),
                Db.P("@ExFed", chkExFed.Checked), Db.P("@ExQc", chkExQc.Checked), Db.P("@ExRRQ", chkExRRQ.Checked), Db.P("@ExRQAP", chkExRQAP.Checked),
                Db.P("@ExAE", chkExAE.Checked), Db.P("@ExFSS", chkExFSS.Checked), Db.P("@ExCNESST", chkExCNESST.Checked),
                Db.P("@TD1Montant", DecN(txtTD1Montant.Text, "TD1 - Montant de la demande")),
                Db.P("@TD1L", Dec(txtTD1Additionnel.Text, "TD1 - Impôt additionnel")),
                Db.P("@TD1HD", Dec(txtTD1Zone.Text, "TD1 - Déduction pour zone visée")),
                Db.P("@TD1F1", Dec(txtTD1Deductions.Text, "T1213 - Déductions annuelles")),
                Db.P("@TD1K3", Dec(txtTD1Credits.Text, "Autres crédits fédéraux")),
                Db.P("@TPMontant", DecN(txtTPMontant.Text, "TP-1015.3 - Ligne 10")),
                Db.P("@TPL", Dec(txtTPAdditionnel.Text, "Retenue supplémentaire")),
                Db.P("@TPJ", Dec(txtTPLigne19.Text, "TP-1015.3 - Ligne 19")),
                Db.P("@TPJ1", Dec(txtTP1016Deductions.Text, "TP-1016 - Déductions")),
                Db.P("@TPK1", Dec(txtTP1016Credits.Text, "TP-1016 - Crédits")),
                Db.P("@Depot", chkDepot.Checked), Db.P("@Transit", transit), Db.P("@Institution", institution),
                Db.P("@Compte", compteChiffre), Db.P("@TalonCourriel", chkTalonCourriel.Checked), Db.P("@Note", txtNote.Text),
                Db.P("@Id", EmployeId), Db.P("@c", Contexte.CompagnieId)}

            If EmployeId = 0 Then
                Dim id = Db.Inserer(
                    "INSERT INTO dbo.Employe (CompagnieId, Actif, Code, Prenom, Nom, Adresse1, Adresse2, Ville, CodePostal, Courriel, Telephone, DateNaissance, Langue, " &
                    "NASChiffre, Poste, DateEmbauche, DateFinEmploi, PeriodesParAnnee, HeuresSemaine, TauxHoraire, SalaireAnnuel, TauxVacances, " &
                    "ExemptImpotFederal, ExemptImpotQuebec, ExemptRRQ, ExemptRQAP, ExemptAE, ExemptFSS, ExemptCNESST, " &
                    "TD1MontantDemande, TD1ImpotAdditionnel, TD1DeductionZone, TD1DeductionsAnnuelles, TD1AutresCredits, " &
                    "TP1015Montant, TP1015ImpotAdditionnel, TP1015DeductionsLigne19, TP1016Deductions, TP1016Credits, " &
                    "DepotDirect, Transit, Institution, CompteChiffre, TalonParCourriel, Note) VALUES (" &
                    "@c, @Actif, @Code, @Prenom, @Nom, @Adresse1, @Adresse2, @Ville, @CodePostal, @Courriel, @Telephone, @DateNaissance, @Langue, " &
                    "@NAS, @Poste, @DateEmbauche, @DateFin, @Periodes, @HeuresSemaine, @TauxHoraire, @SalaireAnnuel, @TauxVacances, " &
                    "@ExFed, @ExQc, @ExRRQ, @ExRQAP, @ExAE, @ExFSS, @ExCNESST, @TD1Montant, @TD1L, @TD1HD, @TD1F1, @TD1K3, " &
                    "@TPMontant, @TPL, @TPJ, @TPJ1, @TPK1, @Depot, @Transit, @Institution, @Compte, @TalonCourriel, @Note)", prms)
                Contexte.Journaliser("Employé ajouté : " & txtPrenom.Text.Trim() & " " & txtNom.Text.Trim() & ".", "~/Employes/Fiche.aspx?id=" & id.ToString())
                RedirigerAvecMessage("~/Employes/ElementsPaie.aspx?id=" & id.ToString(),
                                     "Employé enregistré. Vous pouvez maintenant définir ses éléments de paie récurrents." & RappelExemptions())
            Else
                Db.Exec(
                    "UPDATE dbo.Employe SET Actif=@Actif, Code=@Code, Prenom=@Prenom, Nom=@Nom, Adresse1=@Adresse1, Adresse2=@Adresse2, Ville=@Ville, " &
                    "CodePostal=@CodePostal, Courriel=@Courriel, Telephone=@Telephone, DateNaissance=@DateNaissance, Langue=@Langue, NASChiffre=@NAS, " &
                    "Poste=@Poste, DateEmbauche=@DateEmbauche, DateFinEmploi=@DateFin, PeriodesParAnnee=@Periodes, HeuresSemaine=@HeuresSemaine, " &
                    "TauxHoraire=@TauxHoraire, SalaireAnnuel=@SalaireAnnuel, TauxVacances=@TauxVacances, " &
                    "ExemptImpotFederal=@ExFed, ExemptImpotQuebec=@ExQc, ExemptRRQ=@ExRRQ, ExemptRQAP=@ExRQAP, ExemptAE=@ExAE, ExemptFSS=@ExFSS, ExemptCNESST=@ExCNESST, " &
                    "TD1MontantDemande=@TD1Montant, TD1ImpotAdditionnel=@TD1L, TD1DeductionZone=@TD1HD, TD1DeductionsAnnuelles=@TD1F1, TD1AutresCredits=@TD1K3, " &
                    "TP1015Montant=@TPMontant, TP1015ImpotAdditionnel=@TPL, TP1015DeductionsLigne19=@TPJ, TP1016Deductions=@TPJ1, TP1016Credits=@TPK1, " &
                    "DepotDirect=@Depot, Transit=@Transit, Institution=@Institution, CompteChiffre=@Compte, TalonParCourriel=@TalonCourriel, Note=@Note " &
                    "WHERE Id=@Id AND CompagnieId=@c", prms)
                RedirigerAvecMessage("~/Employes/Liste.aspx", "Employé enregistré." & RappelExemptions())
            End If
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

End Class
