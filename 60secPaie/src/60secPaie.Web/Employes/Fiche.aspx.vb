Imports System.Text
Imports Paie60Sec.Calcul

''' <summary>
''' Paramètres de paie d'un employé de MngConsul. L'identité (dbo.T300Employees) est affichée en lecture seule ;
''' tout ce qui est saisi ici va dans paie.EmployePaie. 60secPaie n'écrit jamais dans les tables de MngConsul.
''' </summary>
Public Class PageFicheEmploye
    Inherits PageBase

    Private ReadOnly Property EmployeId As Integer
        Get
            Return IdRequete("id")
        End Get
    End Property

    Private Function Employe() As DataRow
        Dim r = Db.Ligne("SELECT * FROM paie.Employe WHERE Id = @id AND CompagnieId = @c", Db.P("@id", EmployeId), Db.P("@c", Contexte.CompagnieId))
        If r Is Nothing Then Response.Redirect("~/Employes/Liste.aspx", True)
        Return r
    End Function

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim r = Employe()
        litTitre.Text = Server.HtmlEncode(r.Txt("Prenom") & " " & r.Txt("Nom"))
        AfficherIdentite(r)
        pnlLiens.Visible = True
        lnkElements.NavigateUrl = "~/Employes/ElementsPaie.aspx?id=" & EmployeId.ToString()
        lnkCumulatifs.NavigateUrl = "~/Employes/Cumulatifs.aspx?id=" & EmployeId.ToString()
        If IsPostBack Then Return

        Dim prm = ParametresAnnee.PourAffichage()
        litBaseFed.Text = Argent(prm.FedMontantPersonnelBase)
        litBaseQc.Text = Argent(prm.QcMontantPersonnelBase)

        If Not r.Bln("PaieConfiguree") Then
            Erreur(Tr("La paie de cet employé n'est pas encore configurée. Vérifiez les valeurs proposées, puis enregistrez."))
        End If

        txtDateNaissance.Text = TexteDate(r("DateNaissance"))
        ddlLangue.SelectedValue = If(ddlLangue.Items.FindByValue(r.Txt("Langue")) Is Nothing, "FR", r.Txt("Langue"))

        ' Le NAS et le compte bancaire ne sont jamais renvoyés au navigateur : on n'affiche que la fin.
        Dim nas = NasDe(r)
        litNasActuel.Text = If(nas.Length = 0, Tr("Aucun NAS au dossier."),
                               Server.HtmlEncode(Tr("NAS au dossier : {0}. Laissez vide pour le conserver.", Secret.Masquer(nas))))
        Dim compte = CompteDe(r)
        litCompteActuel.Text = If(compte.Length = 0, "", Server.HtmlEncode(Tr("Compte au dossier : {0}. Laissez vide pour le conserver.", Secret.Masquer(compte))))

        ddlPeriodes.SelectedValue = ""
        Dim periodesPropres = Db.Scalaire("SELECT PeriodesParAnnee FROM paie.EmployePaie WHERE EmployeId = @e", Db.P("@e", EmployeId))
        If periodesPropres IsNot Nothing AndAlso ddlPeriodes.Items.FindByValue(Convert.ToString(periodesPropres)) IsNot Nothing Then
            ddlPeriodes.SelectedValue = Convert.ToString(periodesPropres)
        End If
        txtHeuresSemaine.Text = Champ(r("HeuresSemaine"))
        txtTauxHoraire.Text = Champ(r("TauxHoraire"))
        txtSalaireAnnuel.Text = Champ(r("SalaireAnnuel"))
        txtTauxVacances.Text = Champ(r("TauxVacances"))

        ' L'unité de classification CNESST : celles de la compagnie, actives — plus
        ' celle de l'employé si elle a été désactivée depuis, pour ne pas la perdre
        ' en silence à l'enregistrement.
        Dim tauxCompagnie = Convert.ToDecimal(Db.Scalaire("SELECT TauxCNESST FROM paie.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId)))
        ddlUniteCNESST.Items.Clear()
        ddlUniteCNESST.Items.Add(New ListItem(Tr("Taux de la compagnie ({0} $ / 100 $)", tauxCompagnie.ToString("0.00##", Globalization.CultureInfo.GetCultureInfo("fr-CA"))), ""))
        For Each u As DataRow In Db.Table("SELECT Id, Code, Description, Taux, Actif FROM paie.UniteCNESST WHERE CompagnieId = @c AND (Actif = 1 OR Id = @u) ORDER BY Code",
                                          Db.P("@c", Contexte.CompagnieId), Db.P("@u", If(r.IsNull("UniteCNESSTId"), 0, r.Ent("UniteCNESSTId")))).Rows
            ddlUniteCNESST.Items.Add(New ListItem(u.Txt("Code") & " — " & u.Txt("Description") & " (" & u.Dcm("Taux").ToString("0.00##", Globalization.CultureInfo.GetCultureInfo("fr-CA")) & " $ / 100 $)" &
                                                  If(u.Bln("Actif"), "", " — " & Tr("inactive")), u.Ent("Id").ToString()))
        Next
        If Not r.IsNull("UniteCNESSTId") AndAlso ddlUniteCNESST.Items.FindByValue(r.Ent("UniteCNESSTId").ToString()) IsNot Nothing Then
            ddlUniteCNESST.SelectedValue = r.Ent("UniteCNESSTId").ToString()
        End If

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
        ddlDentaire.SelectedValue = Math.Max(1, Math.Min(5, r.Ent("CodeDentaireT4"))).ToString()

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

    Private Sub AfficherIdentite(r As DataRow)
        Dim sb As New StringBuilder("<div class=""identite"">")
        Ajouter(sb, "Nom", r.Txt("Prenom") & " " & r.Txt("Nom"))
        Ajouter(sb, "Code employé", r.Txt("Code"))
        Ajouter(sb, "Poste", r.Txt("Poste"))
        Ajouter(sb, "Adresse", (r.Txt("Adresse1") & " " & r.Txt("Adresse2")).Trim())
        Ajouter(sb, "Ville", (r.Txt("Ville") & "  " & r.Txt("CodePostal")).Trim())
        Ajouter(sb, "Courriel", r.Txt("Courriel"))
        Ajouter(sb, "Téléphone", r.Txt("Telephone"))
        Ajouter(sb, "Date d'embauche", TexteDate(r("DateEmbauche")))
        Ajouter(sb, "Date de fin d'emploi", TexteDate(r("DateFinEmploi")))
        Ajouter(sb, "Statut", If(r.Bln("Actif"), "Actif", "Inactif"))
        litIdentite.Text = sb.Append("</div>").ToString()
    End Sub

    Private Shared Sub Ajouter(sb As StringBuilder, libelle As String, valeur As String)
        sb.Append("<div><span>").Append(HttpUtility.HtmlEncode(libelle)).Append("</span>")
        sb.Append(HttpUtility.HtmlEncode(If(valeur.Length = 0, "—", valeur))).Append("</div>")
    End Sub

    Private Function RappelExemptions() As String
        Dim nb = {chkExFed, chkExQc, chkExRRQ, chkExRQAP, chkExAE, chkExFSS, chkExCNESST}.Where(Function(c) c.Checked).Count()
        If nb = 0 Then Return ""
        Return " " & Tr("Attention : {0} exemption(s) cochée(s), ces retenues ou cotisations ne seront pas calculées pour cet employé.", nb)
    End Function

    Private Shared Function ChampNonNul(valeur As Object) As String
        If IsDBNull(valeur) OrElse Convert.ToDecimal(valeur) = 0D Then Return ""
        Return Champ(valeur)
    End Function

    Private Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        Try
            Dim actuel = Employe()

            ' NAS : vide = conserver celui au dossier (le nôtre, sinon celui de MngConsul, qui est alors chiffré chez nous).
            Dim nas = Chiffres(txtNAS.Text)
            If nas.Length = 0 Then nas = NasDe(actuel)
            If nas.Length > 0 AndAlso Not NasValide(nas) Then Throw New SaisieInvalideException(Tr("Le numéro d'assurance sociale est invalide."))

            Dim compte = Chiffres(txtCompte.Text)
            If compte.Length = 0 Then compte = CompteDe(actuel)

            Dim transit = Chiffres(txtTransit.Text)
            Dim institution = Chiffres(txtInstitution.Text)
            If chkDepot.Checked AndAlso (transit.Length <> 5 OrElse institution.Length <> 3 OrElse compte.Length = 0) Then
                Throw New SaisieInvalideException(Tr("Dépôt direct : inscrivez le transit (5 chiffres), l'institution (3 chiffres) et le numéro de compte."))
            End If

            Dim naissance = DateN(txtDateNaissance.Text, "Date de naissance")
            If naissance.HasValue AndAlso naissance.Value > Date.Today Then Throw New SaisieInvalideException(Tr("La date de naissance est dans le futur."))
            Dim tauxVacances = DecN(txtTauxVacances.Text, "Taux de vacances")
            If tauxVacances.HasValue AndAlso tauxVacances.Value > 20D Then Throw New SaisieInvalideException(Tr("Le taux de vacances semble trop élevé."))

            Db.Exec(
                "SET XACT_ABORT ON; BEGIN TRAN; " &
                "IF NOT EXISTS (SELECT 1 FROM paie.EmployePaie WHERE EmployeId = @Id) INSERT INTO paie.EmployePaie (EmployeId) VALUES (@Id); " &
                "UPDATE paie.EmployePaie SET Langue=@Langue, DateNaissance=@DateNaissance, NASChiffre=@NAS, PeriodesParAnnee=@Periodes, HeuresSemaine=@HeuresSemaine, " &
                "TauxHoraire=@TauxHoraire, SalaireAnnuel=@SalaireAnnuel, TauxVacances=@TauxVacances, UniteCNESSTId=@Unite, " &
                "ExemptImpotFederal=@ExFed, ExemptImpotQuebec=@ExQc, ExemptRRQ=@ExRRQ, ExemptRQAP=@ExRQAP, ExemptAE=@ExAE, ExemptFSS=@ExFSS, ExemptCNESST=@ExCNESST, " &
                "TD1MontantDemande=@TD1Montant, TD1ImpotAdditionnel=@TD1L, TD1DeductionZone=@TD1HD, TD1DeductionsAnnuelles=@TD1F1, TD1AutresCredits=@TD1K3, " &
                "CodeDentaireT4=@Dentaire, TP1015Montant=@TPMontant, TP1015ImpotAdditionnel=@TPL, TP1015DeductionsLigne19=@TPJ, TP1016Deductions=@TPJ1, " &
                "TP1016Credits=@TPK1, DepotDirect=@Depot, Transit=@Transit, Institution=@Institution, CompteChiffre=@Compte, TalonParCourriel=@TalonCourriel, " &
                "Note=@Note, ModifiePar=@Par, ModifieLe=sysdatetime() WHERE EmployeId=@Id; COMMIT;",
                Db.P("@Id", EmployeId), Db.P("@Langue", ddlLangue.SelectedValue), Db.P("@DateNaissance", naissance), Db.P("@NAS", Secret.Proteger(nas)),
                Db.P("@Periodes", EntierN(ddlPeriodes.SelectedValue, "Période de paie")),
                Db.P("@HeuresSemaine", DecN(txtHeuresSemaine.Text, "Heures par semaine")),
                Db.P("@TauxHoraire", DecN(txtTauxHoraire.Text, "Taux horaire")),
                Db.P("@SalaireAnnuel", DecN(txtSalaireAnnuel.Text, "Salaire annuel")),
                Db.P("@TauxVacances", tauxVacances),
                Db.P("@Unite", EntierN(ddlUniteCNESST.SelectedValue, "Unité de classification CNESST")),
                Db.P("@ExFed", chkExFed.Checked), Db.P("@ExQc", chkExQc.Checked), Db.P("@ExRRQ", chkExRRQ.Checked), Db.P("@ExRQAP", chkExRQAP.Checked),
                Db.P("@ExAE", chkExAE.Checked), Db.P("@ExFSS", chkExFSS.Checked), Db.P("@ExCNESST", chkExCNESST.Checked),
                Db.P("@TD1Montant", DecN(txtTD1Montant.Text, "TD1 - Montant de la demande")),
                Db.P("@TD1L", Dec(txtTD1Additionnel.Text, "TD1 - Impôt additionnel")),
                Db.P("@TD1HD", Dec(txtTD1Zone.Text, "TD1 - Déduction pour zone visée")),
                Db.P("@TD1F1", Dec(txtTD1Deductions.Text, "T1213 - Déductions annuelles")),
                Db.P("@TD1K3", Dec(txtTD1Credits.Text, "Autres crédits fédéraux")),
                Db.P("@Dentaire", Math.Max(1, Math.Min(5, Integer.Parse(ddlDentaire.SelectedValue)))),
                Db.P("@TPMontant", DecN(txtTPMontant.Text, "TP-1015.3 - Ligne 10")),
                Db.P("@TPL", Dec(txtTPAdditionnel.Text, "Retenue supplémentaire")),
                Db.P("@TPJ", Dec(txtTPLigne19.Text, "TP-1015.3 - Ligne 19")),
                Db.P("@TPJ1", Dec(txtTP1016Deductions.Text, "TP-1016 - Déductions")),
                Db.P("@TPK1", Dec(txtTP1016Credits.Text, "TP-1016 - Crédits")),
                Db.P("@Depot", chkDepot.Checked), Db.P("@Transit", transit), Db.P("@Institution", institution),
                Db.P("@Compte", Secret.Proteger(compte)), Db.P("@TalonCourriel", chkTalonCourriel.Checked), Db.P("@Note", txtNote.Text),
                Db.P("@Par", Contexte.Utilisateur))

            Dim premiereFois = Not actuel.Bln("PaieConfiguree")
            If premiereFois Then
                Contexte.Journaliser("Paie configurée pour " & actuel.Txt("Prenom") & " " & actuel.Txt("Nom") & ".", "~/Employes/Fiche.aspx?id=" & EmployeId.ToString())
                RedirigerAvecMessage("~/Employes/ElementsPaie.aspx?id=" & EmployeId.ToString(),
                                     Tr("Paramètres de paie enregistrés. Vous pouvez maintenant définir ses éléments de paie récurrents.") & RappelExemptions())
            Else
                RedirigerAvecMessage("~/Employes/Liste.aspx", Tr("Paramètres de paie enregistrés.") & RappelExemptions())
            End If
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

End Class
