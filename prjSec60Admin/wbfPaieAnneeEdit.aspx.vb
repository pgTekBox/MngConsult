Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Linq
Imports System.Text
Imports Paie60Sec.Calcul

''' <summary>
''' Paie › Taux de l'année › une année : tous les taux et plafonds d'une année
''' de 60secPaie (paie.ParametresAnnee), à saisir depuis les guides T4127 et
''' TP-1015.F. Un brouillon se vérifie avec un exemple chiffré avant d'être
''' validé ; une année validée sert aux paies dans les cinq minutes.
'''
''' Les nombres se saisissent au point ou à la virgule ; les taux en fraction
''' (0.14 pour 14 %), sauf le FSS, en pourcentage comme dans le guide.
''' </summary>
Public Class wbfPaieAnneeEdit
    Inherits clsData

    Private ReadOnly Property Annee As Integer
        Get
            Dim a As Integer
            Integer.TryParse(Request.QueryString("annee"), a)
            Return a
        End Get
    End Property

    ''' <summary>Nom de colonne → zone de saisie, pour charger et enregistrer sans se répéter.</summary>
    Private ReadOnly Property Champs As Dictionary(Of String, TextBox)
        Get
            Return New Dictionary(Of String, TextBox)(StringComparer.Ordinal) From {
                {"FedMontantPersonnelBase", txtFedMontantPersonnelBase}, {"FedTauxCredits", txtFedTauxCredits},
                {"FedMontantEmploi", txtFedMontantEmploi}, {"FedAbattementQuebec", txtFedAbattementQuebec},
                {"FedCreditFondsTravailleursTaux", txtFedCreditFondsTravailleursTaux}, {"FedCreditFondsTravailleursMax", txtFedCreditFondsTravailleursMax},
                {"FedSeuilForfaitaireTauxFixe", txtFedSeuilForfaitaireTauxFixe}, {"FedTauxFixeForfaitaireQuebec", txtFedTauxFixeForfaitaireQuebec},
                {"AEMaxAssurable", txtAEMaxAssurable}, {"AETaux", txtAETaux}, {"AEMaxEmploye", txtAEMaxEmploye},
                {"QcMontantPersonnelBase", txtQcMontantPersonnelBase}, {"QcTauxCredits", txtQcTauxCredits},
                {"QcDeductionTravailleurTaux", txtQcDeductionTravailleurTaux}, {"QcDeductionTravailleurMax", txtQcDeductionTravailleurMax},
                {"QcCreditFondsTravailleursTaux", txtQcCreditFondsTravailleursTaux}, {"QcFondsTravailleursMaxAnnuel", txtQcFondsTravailleursMaxAnnuel},
                {"QcSeuilForfaitaireTauxFixe", txtQcSeuilForfaitaireTauxFixe}, {"QcTauxFixeForfaitaire", txtQcTauxFixeForfaitaire},
                {"RRQMaxGainsAdmissibles", txtRRQMaxGainsAdmissibles}, {"RRQExemption", txtRRQExemption}, {"RRQTaux", txtRRQTaux},
                {"RRQTauxBase", txtRRQTauxBase}, {"RRQMaxEmploye", txtRRQMaxEmploye}, {"RRQMaxBaseEmploye", txtRRQMaxBaseEmploye},
                {"RRQ2MaxSupplementaire", txtRRQ2MaxSupplementaire}, {"RRQ2Taux", txtRRQ2Taux}, {"RRQ2MaxEmploye", txtRRQ2MaxEmploye},
                {"RQAPMaxAssurable", txtRQAPMaxAssurable}, {"RQAPTauxEmploye", txtRQAPTauxEmploye}, {"RQAPMaxEmploye", txtRQAPMaxEmploye},
                {"RQAPTauxEmployeur", txtRQAPTauxEmployeur}, {"RQAPMaxEmployeur", txtRQAPMaxEmployeur},
                {"FSSTauxSecteurPublic", txtFSSTauxSecteurPublic}, {"FSSMassePlancher", txtFSSMassePlancher}, {"FSSMassePlafond", txtFSSMassePlafond},
                {"FSSGeneralConstante", txtFSSGeneralConstante}, {"FSSGeneralCoefficient", txtFSSGeneralCoefficient},
                {"FSSPrimaireConstante", txtFSSPrimaireConstante}, {"FSSPrimaireCoefficient", txtFSSPrimaireCoefficient},
                {"CNESSTMaxAssurable", txtCNESSTMaxAssurable}, {"CNTTaux", txtCNTTaux}, {"CNTMaxAssujetti", txtCNTMaxAssujetti}}
        End Get
    End Property

    ''' <summary>
    ''' Les taux hors Québec et ceux de l'Ontario (script 05_ontario.sql). Tout ou rien : le moteur ne
    ''' calcule l'Ontario que si chaque valeur est là ; une année sans Ontario laisse la section vide.
    ''' </summary>
    Private ReadOnly Property ChampsOntario As Dictionary(Of String, TextBox)
        Get
            Return New Dictionary(Of String, TextBox)(StringComparer.Ordinal) From {
                {"FedTauxFixeForfaitaireHorsQuebec", txtFedTauxFixeForfaitaireHorsQuebec}, {"AETauxHorsQuebec", txtAETauxHorsQuebec},
                {"AEMaxEmployeHorsQuebec", txtAEMaxEmployeHorsQuebec}, {"RPCMaxGainsAdmissibles", txtRPCMaxGainsAdmissibles},
                {"RPCExemption", txtRPCExemption}, {"RPCTaux", txtRPCTaux},
                {"RPCTauxBase", txtRPCTauxBase}, {"RPCMaxEmploye", txtRPCMaxEmploye},
                {"RPCMaxBaseEmploye", txtRPCMaxBaseEmploye}, {"RPC2MaxSupplementaire", txtRPC2MaxSupplementaire},
                {"RPC2Taux", txtRPC2Taux}, {"RPC2MaxEmploye", txtRPC2MaxEmploye},
                {"OnMontantPersonnelBase", txtOnMontantPersonnelBase}, {"OnTauxCredits", txtOnTauxCredits},
                {"OnSurtaxeSeuil1", txtOnSurtaxeSeuil1}, {"OnSurtaxeTaux1", txtOnSurtaxeTaux1},
                {"OnSurtaxeSeuil2", txtOnSurtaxeSeuil2}, {"OnSurtaxeTaux2", txtOnSurtaxeTaux2},
                {"OnReductionBase", txtOnReductionBase}, {"OnReductionParPersonne", txtOnReductionParPersonne},
                {"ISEExemption", txtISEExemption}, {"ISESeuilSansExemption", txtISESeuilSansExemption},
                {"WSIBMaxAssurable", txtWSIBMaxAssurable}}
        End Get
    End Property

    Private ReadOnly Property TranchesOn As TextBox()()
        Get
            Return {({txtOnS1, txtOnT1, txtOnC1}), ({txtOnS2, txtOnT2, txtOnC2}), ({txtOnS3, txtOnT3, txtOnC3}),
                    ({txtOnS4, txtOnT4, txtOnC4}), ({txtOnS5, txtOnT5, txtOnC5})}
        End Get
    End Property

    Private ReadOnly Property TranchesFed As TextBox()()
        Get
            Return {({txtFedS1, txtFedT1, txtFedC1}), ({txtFedS2, txtFedT2, txtFedC2}), ({txtFedS3, txtFedT3, txtFedC3}),
                    ({txtFedS4, txtFedT4, txtFedC4}), ({txtFedS5, txtFedT5, txtFedC5}), ({txtFedS6, txtFedT6, txtFedC6})}
        End Get
    End Property

    Private ReadOnly Property TranchesQc As TextBox()()
        Get
            Return {({txtQcS1, txtQcT1, txtQcC1}), ({txtQcS2, txtQcT2, txtQcC2}), ({txtQcS3, txtQcT3, txtQcC3}),
                    ({txtQcS4, txtQcT4, txtQcC4}), ({txtQcS5, txtQcT5, txtQcC5})}
        End Get
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Annee = 0 Then Response.Redirect("~/wbfPaieAnnees.aspx", True)
        If Not IsPostBack Then
            Charger()
            If Request.QueryString("nouvelle") = "1" Then
                ShowMsg("Année " & Annee.ToString() & " créée en brouillon à partir de l'année précédente. Remplacez chaque valeur par celles des guides " &
                        Annee.ToString() & ", vérifiez, puis validez.", False)
            End If
        End If
    End Sub

    Private Function Ligne() As DataRow
        Dim p As New Collection
        p.Add(New SqlParameter("@Annee", Annee))
        p.Add(New SqlParameter("@SeulementValide", False))
        Dim ds As DataSet = ExecuteSQLds("paie.spParametresAnnee_Get", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return Nothing
        Return ds.Tables(0).Rows(0)
    End Function

    Private Sub Charger()
        Dim r = Ligne()
        If r Is Nothing Then Response.Redirect("~/wbfPaieAnnees.aspx", True)

        Dim validee = Convert.ToString(r("Statut")) = "V"
        litAnnee.Text = Annee.ToString()
        litBadge.Text = "<span class='pe-badge " & If(validee, "V'>Validée", "B'>Brouillon") & "</span>"
        litEtat.Text = Server.HtmlEncode(Etat(r))
        pnlValidee.Visible = validee
        btnValider.Visible = Not validee
        btnDevalider.Visible = validee
        btnSupprimer.Visible = Not validee

        txtSource.Text = Convert.ToString(r("Source"))
        txtNote.Text = Convert.ToString(r("Note"))
        For Each kv In Champs
            kv.Value.Text = Nombre(r(kv.Key))
        Next
        RemplirTranches(TranchesFed, Convert.ToString(r("FedTranches")))
        RemplirTranches(TranchesQc, Convert.ToString(r("QcTranches")))

        ' Une base où 05_ontario.sql n'a pas encore passé n'a pas ces colonnes : la section reste vide.
        Dim avecOntario = r.Table.Columns.Contains("OnTranches")
        For Each kv In ChampsOntario
            kv.Value.Text = If(avecOntario, Nombre(r(kv.Key)), "")
        Next
        RemplirTranches(TranchesOn, If(avecOntario, Convert.ToString(r("OnTranches")), ""))
        txtOnContributionSante.Text = If(avecOntario, Convert.ToString(r("OnContributionSante")), "")
        txtISETranches.Text = If(avecOntario, Convert.ToString(r("ISETranches")), "")
        ChargerProvinces()
    End Sub

    ' ---------------------------------------------------------------------
    ' Autres provinces et territoires (paie.ParametresProvince, script 06_provinces.sql)
    ' ---------------------------------------------------------------------

    Private Function LignesProvinces() As DataTable
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Annee", Annee))
            Dim ds As DataSet = ExecuteSQLds("paie.spParametresProvince_Liste", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0)
        Catch ex As Exception
            ' La base n'a pas encore reçu 06_provinces.sql : la section reste vide, le reste de la page fonctionne.
        End Try
        Return Nothing
    End Function

    Private Sub ChargerProvinces()
        Dim t = LignesProvinces()
        rptProvinces.Visible = t IsNot Nothing AndAlso t.Rows.Count > 0
        rptProvinces.DataSource = t
        rptProvinces.DataBind()
        litProvincesVide.Text = If(t Is Nothing,
            "<div class='pe-warn'>La table des provinces n'existe pas dans cette base : exécutez le script 06_provinces.sql de 60secPaie.</div>",
            If(t.Rows.Count = 0, "<div class='pe-warn'>Aucune province saisie pour cette année : 60secPaie utilisera les valeurs de son code, s'il en a pour cette année.</div>", ""))
        litAideParticularites.Text = Server.HtmlEncode(ParametresProvince.AideParticularites)

        ddlPNouvelle.Items.Clear()
        For Each prov In Provinces.Gerees
            If prov = Province.Quebec OrElse prov = Province.Ontario Then Continue For
            ddlPNouvelle.Items.Add(New ListItem(Provinces.Code(prov) & " — " & Provinces.Nom(prov), Provinces.Code(prov)))
        Next
        txtPNouvelleDate.Text = ""
    End Sub

    Protected Function NombreChamp(v As Object) As String
        Return Nombre(v)
    End Function

    ''' <summary>
    ''' Les lignes de provinces telles que saisies, validées par le moteur lui-même (tranches et particularités).
    ''' Chaque élément : la ligne lue, et les valeurs à passer à la procédure.
    ''' </summary>
    Private Function ProvincesSaisies() As List(Of ParametresProvince)
        Dim liste As New List(Of ParametresProvince)()
        For Each item As RepeaterItem In rptProvinces.Items
            Dim code = DirectCast(item.FindControl("hfProvince"), HiddenField).Value
            Dim quand = DirectCast(item.FindControl("hfDate"), HiddenField).Value
            Dim ou = "Province " & code & " (" & quand & ") — "
            Dim pp As New ParametresProvince()
            pp.Province = Provinces.DeCode(code)
            pp.EnVigueurLe = Date.ParseExact(quand, "yyyy-MM-dd", CultureInfo.InvariantCulture)
            Dim tranches = DirectCast(item.FindControl("txtPTranches"), TextBox).Text.Replace(" ", "").Replace(vbCr, "").Replace(vbLf, "").Replace(",", ".").Trim(";"c)
            Try
                pp.Tranches = ParametresAnnee.LireTranches(tranches)
                pp.LireParticularites(DirectCast(item.FindControl("txtPParticularites"), TextBox).Text.Replace(vbCr, "").Replace(vbLf, ""))
            Catch ex As Exception
                Throw New FormatException(ou & ex.Message)
            End Try
            If pp.Tranches.Length = 0 Then Throw New FormatException(ou & "les tranches sont requises.")
            pp.MontantPersonnelBase = Dec(DirectCast(item.FindControl("txtPBase"), TextBox).Text, ou & "Montant personnel de base")
            pp.TauxCredits = Dec(DirectCast(item.FindControl("txtPTaux"), TextBox).Text, ou & "Taux des crédits")
            If pp.TauxCredits >= 1D Then Throw New FormatException(ou & "le taux des crédits se saisit en fraction (0.08 pour 8 %).")
            Dim accidents = DirectCast(item.FindControl("txtPAccidents"), TextBox).Text
            If accidents.Trim().Length > 0 Then pp.AccidentsMaxAssurable = Dec(accidents, ou & "Maximum assurable")
            liste.Add(pp)
        Next
        Return liste
    End Function

    Private Sub EnregistrerProvinces(liste As List(Of ParametresProvince))
        For Each pp In liste
            Dim p As New Collection
            p.Add(New SqlParameter("@Annee", Annee))
            p.Add(New SqlParameter("@Province", Provinces.Code(pp.Province)))
            p.Add(New SqlParameter("@EnVigueurLe", pp.EnVigueurLe))
            p.Add(New SqlParameter("@Tranches", ParametresAnnee.EcrireTranches(pp.Tranches)))
            p.Add(New SqlParameter("@MontantPersonnelBase", pp.MontantPersonnelBase))
            p.Add(New SqlParameter("@TauxCredits", pp.TauxCredits))
            Dim particularites = pp.EcrireParticularites()
            p.Add(New SqlParameter("@Particularites", If(particularites.Length = 0, CType(DBNull.Value, Object), particularites)))
            p.Add(New SqlParameter("@AccidentsMaxAssurable", If(pp.AccidentsMaxAssurable = 0D, CType(DBNull.Value, Object), pp.AccidentsMaxAssurable)))
            p.Add(New SqlParameter("@Par", UserEmail))
            ExecuteSQL("paie.spParametresProvince_Save", p)
        Next
    End Sub

    Private Sub btnPAjouter_Click(sender As Object, e As EventArgs) Handles btnPAjouter.Click
        Try
            Dim quand As Date
            If Not Date.TryParseExact(txtPNouvelleDate.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, quand) Then
                Throw New FormatException("Date d'entrée en vigueur : format attendu aaaa-mm-jj.")
            End If
            If quand.Year <> Annee Then Throw New FormatException("La date d'entrée en vigueur doit être dans l'année " & Annee.ToString() & ".")
            Dim prov = Provinces.DeCode(ddlPNouvelle.SelectedValue)

            ' On garde d'abord ce qui est à l'écran, puis on part des dernières valeurs de la province.
            Dim saisies = ProvincesSaisies()
            EnregistrerProvinces(saisies)
            If saisies.Any(Function(x) x.Province = prov AndAlso x.EnVigueurLe = quand) Then Throw New FormatException("Cette ligne existe déjà.")
            Dim modele = saisies.Where(Function(x) x.Province = prov).OrderByDescending(Function(x) x.EnVigueurLe).FirstOrDefault()
            If modele Is Nothing Then
                Dim code = ParametresAnnee.DuCode(Annee)
                If code IsNot Nothing Then modele = code.PourProvince(prov, New Date(Annee, 12, 31))
            End If
            If modele Is Nothing Then
                Throw New FormatException("Aucune valeur de départ pour cette province : créez l'année à partir d'une année qui la contient, ou exécutez 06_provinces.sql.")
            End If
            Dim nouvelle As New ParametresProvince With {
                .Province = prov, .EnVigueurLe = quand, .Tranches = modele.Tranches, .MontantPersonnelBase = modele.MontantPersonnelBase,
                .TauxCredits = modele.TauxCredits, .AccidentsMaxAssurable = modele.AccidentsMaxAssurable}
            nouvelle.LireParticularites(modele.EcrireParticularites())
            EnregistrerProvinces(New List(Of ParametresProvince) From {nouvelle})
            ChargerProvinces()
            ShowMsg("Ligne ajoutée pour " & Provinces.Nom(prov) & ", en vigueur le " & quand.ToString("yyyy-MM-dd") & ". Corrigez ses valeurs, puis enregistrez.", False)
        Catch ex As Exception
            ShowMsg(ex.Message, True)
        End Try
    End Sub

    Private Sub rptProvinces_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptProvinces.ItemCommand
        If e.CommandName <> "supprimer" Then Return
        Try
            Dim c = Convert.ToString(e.CommandArgument).Split("|"c)
            Dim p As New Collection
            p.Add(New SqlParameter("@Annee", Annee))
            p.Add(New SqlParameter("@Province", c(0)))
            p.Add(New SqlParameter("@EnVigueurLe", Date.ParseExact(c(1), "yyyy-MM-dd", CultureInfo.InvariantCulture)))
            ExecuteSQL("paie.spParametresProvince_Supprimer", p)
            ChargerProvinces()
            ShowMsg("Ligne supprimée.", False)
        Catch ex As Exception
            ShowMsg(ex.Message, True)
        End Try
    End Sub

    ''' <summary>
    ''' La section Ontario telle que saisie : nom de colonne → valeur. Nothing si elle est entièrement vide ;
    ''' une exception si elle n'est remplie qu'à moitié ou si une valeur est illisible.
    ''' </summary>
    Private Function OntarioSaisi() As Dictionary(Of String, Object)
        Dim sante = txtOnContributionSante.Text.Trim().Replace(" ", "").Replace(vbCr, "").Replace(vbLf, "")
        Dim ise = txtISETranches.Text.Trim().Replace(" ", "").Replace(vbCr, "").Replace(vbLf, "")
        Dim tranchesVides = TranchesOn.All(Function(rang) rang.All(Function(z) z.Text.Trim().Length = 0))
        Dim remplis = ChampsOntario.Values.Where(Function(z) z.Text.Trim().Length > 0).Count()
        If remplis = 0 AndAlso tranchesVides AndAlso sante.Length = 0 AndAlso ise.Length = 0 Then Return Nothing

        If tranchesVides Then Throw New FormatException("Section Ontario : les tranches d'impôt de l'Ontario sont requises (ou videz toute la section).")
        If sante.Length = 0 Then Throw New FormatException("Section Ontario : les paliers de la contribution-santé sont requis.")
        If ise.Length = 0 Then Throw New FormatException("Section Ontario : le barème de l'ISE est requis.")

        Dim d As New Dictionary(Of String, Object)(StringComparer.Ordinal)
        For Each kv In ChampsOntario
            d(kv.Key) = Dec(kv.Value.Text, Libelle(kv.Value))
        Next
        d("OnTranches") = LireTranches(TranchesOn, "Impôt de l'Ontario, tranche")
        Try
            ParametresAnnee.LirePaliersSante(sante)
        Catch ex As Exception
            Throw New FormatException("Contribution-santé de l'Ontario : " & ex.Message)
        End Try
        Try
            ParametresAnnee.LireTranches(ise)
        Catch ex As Exception
            Throw New FormatException("Barème de l'ISE : " & ex.Message)
        End Try
        d("OnContributionSante") = sante
        d("ISETranches") = ise
        Return d
    End Function

    Private Function Etat(r As DataRow) As String
        Dim parts As New List(Of String)()
        parts.Add("Créée le " & Quand(r("CreeLe")) & Par(r("CreePar")))
        If Not IsDBNull(r("ModifieLe")) Then parts.Add("modifiée le " & Quand(r("ModifieLe")) & Par(r("ModifiePar")))
        If Not IsDBNull(r("ValideLe")) Then parts.Add("validée le " & Quand(r("ValideLe")) & Par(r("ValidePar")))
        Return String.Join(" · ", parts)
    End Function

    Private Shared Sub RemplirTranches(zones As TextBox()(), texte As String)
        For Each rang In zones
            rang(0).Text = "" : rang(1).Text = "" : rang(2).Text = ""
        Next
        Dim i = 0
        For Each morceau In If(texte, "").Split(";"c)
            If morceau.Trim().Length = 0 OrElse i >= zones.Length Then Continue For
            Dim c = morceau.Split("|"c)
            If c.Length = 3 Then
                zones(i)(0).Text = c(0).Trim()
                zones(i)(1).Text = c(1).Trim()
                zones(i)(2).Text = c(2).Trim()
                i += 1
            End If
        Next
    End Sub

    ''' <summary>Les tranches saisies, en texte « seuil|taux|constante;… », validées par le moteur lui-même.</summary>
    Private Function LireTranches(zones As TextBox()(), quoi As String) As String
        Dim parts As New List(Of String)()
        For Each rang In zones
            Dim s = rang(0).Text.Trim()
            If s.Length = 0 AndAlso rang(1).Text.Trim().Length = 0 AndAlso rang(2).Text.Trim().Length = 0 Then Continue For
            If s <> "*" Then s = Dec(rang(0).Text, quoi & " — seuil").ToString("0.##", CultureInfo.InvariantCulture)
            parts.Add(s & "|" & Dec(rang(1).Text, quoi & " — taux").ToString("0.#####", CultureInfo.InvariantCulture) &
                      "|" & Dec(rang(2).Text, quoi & " — constante").ToString("0.##", CultureInfo.InvariantCulture))
        Next
        Dim texte = String.Join(";", parts)
        ParametresAnnee.LireTranches(texte)   ' lève une FormatException claire si la suite est incohérente
        Return texte
    End Function

    ' ---------------------------------------------------------------------
    ' Enregistrer, valider, supprimer
    ' ---------------------------------------------------------------------

    Private Function ParametresSaisis() As Collection
        Dim p As New Collection
        p.Add(New SqlParameter("@Annee", Annee))
        p.Add(New SqlParameter("@Source", If(txtSource.Text.Trim().Length = 0, CType(DBNull.Value, Object), txtSource.Text.Trim())))
        p.Add(New SqlParameter("@Note", If(txtNote.Text.Trim().Length = 0, CType(DBNull.Value, Object), txtNote.Text.Trim())))
        p.Add(New SqlParameter("@FedTranches", LireTranches(TranchesFed, "Impôt fédéral, tranche")))
        p.Add(New SqlParameter("@QcTranches", LireTranches(TranchesQc, "Impôt du Québec, tranche")))
        For Each kv In Champs
            p.Add(New SqlParameter("@" & kv.Key, Dec(kv.Value.Text, Libelle(kv.Value))))
        Next
        ' Section vide : aucun paramètre de l'Ontario n'est envoyé, la procédure garde ce que la base contient.
        Dim ontario = OntarioSaisi()
        If ontario IsNot Nothing Then
            For Each kv In ontario
                p.Add(New SqlParameter("@" & kv.Key, kv.Value))
            Next
        End If
        p.Add(New SqlParameter("@Par", UserEmail))
        Return p
    End Function

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        Try
            Dim lignesProv = ProvincesSaisies()
            ExecuteSQL("paie.spParametresAnnee_Save", ParametresSaisis())
            EnregistrerProvinces(lignesProv)
            Charger()
            ShowMsg("Taux de l'année " & Annee.ToString() & " enregistrés.", False)
        Catch ex As Exception
            ShowMsg(ex.Message, True)
        End Try
    End Sub

    Private Sub btnValider_Click(sender As Object, e As EventArgs) Handles btnValider.Click
        Try
            ' On enregistre d'abord, puis on s'assure que le moteur sait calculer
            ' avec ces valeurs : une année validée mais incalculable bloquerait la paie.
            Dim lignesProv = ProvincesSaisies()
            ExecuteSQL("paie.spParametresAnnee_Save", ParametresSaisis())
            EnregistrerProvinces(lignesProv)
            Dim prm = ParametresAnnee.DepuisLigne(Ligne())
            MoteurPaie.Calculer(Entree(60000D, 26, prm.Annee), prm)
            If prm.EstDefinie(Province.Ontario) Then MoteurPaie.Calculer(Entree(60000D, 26, prm.Annee, Province.Ontario), prm)
            ' Chaque ligne de province doit se calculer à sa date d'entrée en vigueur.
            prm.AutresProvinces = lignesProv
            For Each pp In lignesProv
                Dim essai = Entree(60000D, 26, prm.Annee, pp.Province)
                essai.DatePaie = pp.EnVigueurLe
                MoteurPaie.Calculer(essai, prm)
            Next

            Dim p As New Collection
            p.Add(New SqlParameter("@Annee", Annee))
            p.Add(New SqlParameter("@Par", UserEmail))
            p.Add(New SqlParameter("@Valide", True))
            ExecuteSQL("paie.spParametresAnnee_Valider", p)
            Charger()
            ShowMsg("Année " & Annee.ToString() & " validée : 60secPaie l'utilise pour les paies datées de " & Annee.ToString() & " (dans les cinq minutes).", False)
        Catch ex As Exception
            ShowMsg(ex.Message, True)
        End Try
    End Sub

    Private Sub btnDevalider_Click(sender As Object, e As EventArgs) Handles btnDevalider.Click
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Annee", Annee))
            p.Add(New SqlParameter("@Par", UserEmail))
            p.Add(New SqlParameter("@Valide", False))
            ExecuteSQL("paie.spParametresAnnee_Valider", p)
            Charger()
            ShowMsg("Validation retirée : l'année " & Annee.ToString() & " est de nouveau un brouillon.", False)
        Catch ex As Exception
            ShowMsg(ex.Message, True)
        End Try
    End Sub

    Private Sub btnSupprimer_Click(sender As Object, e As EventArgs) Handles btnSupprimer.Click
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Annee", Annee))
            ExecuteSQL("paie.spParametresAnnee_Supprimer", p)
            Response.Redirect("~/wbfPaieAnnees.aspx", True)
        Catch ex As Exception
            ShowMsg(ex.Message, True)
        End Try
    End Sub

    ' ---------------------------------------------------------------------
    ' Vérifier avec un exemple : les valeurs de l'écran, pas celles de la base
    ' ---------------------------------------------------------------------

    Private Sub btnVerifier_Click(sender As Object, e As EventArgs) Handles btnVerifier.Click
        Try
            Dim brut = Dec(txtVBrut.Text, "Salaire brut annuel")
            Dim periodes = CInt(Dec(txtVPeriodes.Text, "Périodes de paie"))
            If periodes < 1 OrElse periodes > 53 Then Throw New FormatException("Le nombre de périodes doit se situer entre 1 et 53.")

            Dim prm = ParametresDepuisEcran()
            Dim uneParPeriode = MoteurPaie.Calculer(Entree(Math.Round(brut / periodes, 2, MidpointRounding.AwayFromZero), periodes, prm.Annee), prm)
            Dim annuelle = MoteurPaie.Calculer(Entree(brut, 1, prm.Annee), prm)

            Dim sb As New StringBuilder()
            sb.Append("<table class='res'><tr><th>Retenue ou cotisation</th><th>Une paie de ").Append(Argent(brut / periodes)).Append(" (").Append(periodes).Append(" périodes)</th><th>× ").Append(periodes).Append("</th><th>En une seule paie annuelle</th></tr>")
            LigneRes(sb, "Impôt fédéral", uneParPeriode.ImpotFederal, periodes, annuelle.ImpotFederal)
            LigneRes(sb, "Impôt du Québec", uneParPeriode.ImpotQuebec, periodes, annuelle.ImpotQuebec)
            LigneRes(sb, "RRQ (employé)", uneParPeriode.RRQ, periodes, annuelle.RRQ)
            LigneRes(sb, "RRQ 2e cotisation suppl.", uneParPeriode.RRQ2, periodes, annuelle.RRQ2)
            LigneRes(sb, "Assurance-emploi (employé)", uneParPeriode.AE, periodes, annuelle.AE)
            LigneRes(sb, "RQAP (employé)", uneParPeriode.RQAP, periodes, annuelle.RQAP)
            LigneRes(sb, "Paie nette", uneParPeriode.Net, periodes, annuelle.Net)
            sb.Append("</table><div class='f'><div class='hint'>Employé ordinaire : montants personnels de base, aucune déduction, aucune exemption, taux CNESST à 0. " &
                      "Les cotisations annuelles ×N ne tiennent pas compte des plafonds atteints en cours d'année ; la colonne « une seule paie » les applique.</div></div>")

            ' Le même employé en Ontario, si la section Ontario est remplie.
            If prm.EstDefinie(Province.Ontario) Then
                Dim onPeriode = MoteurPaie.Calculer(Entree(Math.Round(brut / periodes, 2, MidpointRounding.AwayFromZero), periodes, prm.Annee, Province.Ontario), prm)
                Dim onAnnuelle = MoteurPaie.Calculer(Entree(brut, 1, prm.Annee, Province.Ontario), prm)
                sb.Append("<table class='res'><tr><th>Ontario — retenue ou cotisation</th><th>Une paie de ").Append(Argent(brut / periodes)).Append(" (").Append(periodes).Append(" périodes)</th><th>× ").Append(periodes).Append("</th><th>En une seule paie annuelle</th></tr>")
                LigneRes(sb, "Impôt fédéral", onPeriode.ImpotFederal, periodes, onAnnuelle.ImpotFederal)
                LigneRes(sb, "Impôt de l'Ontario", onPeriode.ImpotQuebec, periodes, onAnnuelle.ImpotQuebec)
                LigneRes(sb, "RPC (employé)", onPeriode.RRQ, periodes, onAnnuelle.RRQ)
                LigneRes(sb, "RPC 2e cotisation suppl.", onPeriode.RRQ2, periodes, onAnnuelle.RRQ2)
                LigneRes(sb, "Assurance-emploi (employé)", onPeriode.AE, periodes, onAnnuelle.AE)
                LigneRes(sb, "Paie nette", onPeriode.Net, periodes, onAnnuelle.Net)
                sb.Append("</table><div class='f'><div class='hint'>Ontario : même employé, montants personnels de base fédéral et TD1ON. À comparer avec le calculateur PDOC de l'ARC.</div></div>")
            Else
                sb.Append("<div class='f'><div class='hint'>Ontario : section vide ou incomplète, aucun calcul pour cette province.</div></div>")
            End If

            ' Les autres provinces : l'impôt provincial du même employé, pour chaque ligne saisie, à sa date d'entrée en vigueur.
            Dim lignesProv = ProvincesSaisies()
            If lignesProv.Count > 0 Then
                prm.AutresProvinces = lignesProv
                sb.Append("<table class='res'><tr><th>Province</th><th>En vigueur le</th><th>Impôt provincial par paie</th><th>× ").Append(periodes).Append("</th><th>Impôt fédéral par paie</th><th>RPC</th><th>AE</th><th>Impôt sur la paie (territoires)</th><th>Paie nette</th></tr>")
                For Each pp In lignesProv.OrderBy(Function(x) Provinces.Code(x.Province)).ThenBy(Function(x) x.EnVigueurLe)
                    Dim essai = Entree(Math.Round(brut / periodes, 2, MidpointRounding.AwayFromZero), periodes, prm.Annee, pp.Province)
                    essai.DatePaie = pp.EnVigueurLe
                    Dim res = MoteurPaie.Calculer(essai, prm)
                    sb.Append("<tr><td>").Append(Provinces.Code(pp.Province)).Append(" — ").Append(HttpUtility.HtmlEncode(Provinces.Nom(pp.Province))).Append("</td><td>") _
                      .Append(pp.EnVigueurLe.ToString("yyyy-MM-dd")).Append("</td><td>").Append(Argent(res.ImpotQuebec)).Append("</td><td>") _
                      .Append(Argent(res.ImpotQuebec * periodes)).Append("</td><td>").Append(Argent(res.ImpotFederal)).Append("</td><td>") _
                      .Append(Argent(res.RRQ)).Append("</td><td>").Append(Argent(res.AE)).Append("</td><td>").Append(Argent(res.RQAP)).Append("</td><td>") _
                      .Append(Argent(res.Net)).Append("</td></tr>")
                Next
                sb.Append("</table><div class='f'><div class='hint'>Autres provinces : même employé, montants personnels de base. À comparer avec le calculateur PDOC de l'ARC pour une paie datée du même jour.</div></div>")
            End If
            litVerif.Text = sb.ToString()
        Catch ex As Exception
            litVerif.Text = ""
            ShowMsg(ex.Message, True)
        End Try
    End Sub

    Private Shared Sub LigneRes(sb As StringBuilder, libelle As String, parPeriode As Decimal, periodes As Integer, annuelle As Decimal)
        sb.Append("<tr><td>").Append(HttpUtility.HtmlEncode(libelle)).Append("</td><td>").Append(Argent(parPeriode)).Append("</td><td>") _
          .Append(Argent(parPeriode * periodes)).Append("</td><td>").Append(Argent(annuelle)).Append("</td></tr>")
    End Sub

    ''' <summary>Un employé ordinaire payé ce brut, sans déduction ni exemption.</summary>
    Private Shared Function Entree(brut As Decimal, periodes As Integer, annee As Integer, Optional provinceEmploi As Province = Province.Quebec) As EntreePaie
        Dim e As New EntreePaie()
        e.Province = provinceEmploi
        e.Annee = annee
        e.PeriodesParAnnee = periodes
        e.DatePaie = New Date(annee, 6, 15)
        e.Employeur.TauxCNESST = 0D
        e.Lignes.Add(New LignePaie With {.CodeCategorie = "SALAIRE", .Montant = brut})
        Return e
    End Function

    ''' <summary>Les paramètres tels que saisis à l'écran, passés par une ligne de table pour reprendre la lecture du moteur.</summary>
    Private Function ParametresDepuisEcran() As ParametresAnnee
        Dim t As New DataTable()
        t.Columns.Add("Annee", GetType(Integer))
        t.Columns.Add("FedTranches", GetType(String))
        t.Columns.Add("QcTranches", GetType(String))
        For Each kv In Champs
            t.Columns.Add(kv.Key, GetType(Decimal))
        Next
        Dim ontario = OntarioSaisi()
        If ontario IsNot Nothing Then
            For Each kv In ontario
                t.Columns.Add(kv.Key, If(TypeOf kv.Value Is String, GetType(String), GetType(Decimal)))
            Next
        End If
        Dim r = t.NewRow()
        If ontario IsNot Nothing Then
            For Each kv In ontario
                r(kv.Key) = kv.Value
            Next
        End If
        r("Annee") = Annee
        r("FedTranches") = LireTranches(TranchesFed, "Impôt fédéral, tranche")
        r("QcTranches") = LireTranches(TranchesQc, "Impôt du Québec, tranche")
        For Each kv In Champs
            r(kv.Key) = Dec(kv.Value.Text, Libelle(kv.Value))
        Next
        Return ParametresAnnee.DepuisLigne(r)
    End Function

    ' ---------------------------------------------------------------------
    ' Helpers
    ' ---------------------------------------------------------------------

    Private Shared Function Nombre(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value Then Return ""
        Return Convert.ToDecimal(v, CultureInfo.InvariantCulture).ToString("0.#####", CultureInfo.InvariantCulture)
    End Function

    Private Shared Function Dec(texte As String, champ As String) As Decimal
        Dim v As Decimal
        Dim propre = If(texte, "").Trim().Replace(" ", "").Replace("$", "").Replace("%", "").Replace(",", ".")
        If propre.Length = 0 Then Throw New FormatException("« " & champ & " » est requis.")
        If Not Decimal.TryParse(propre, NumberStyles.Any, CultureInfo.InvariantCulture, v) Then Throw New FormatException("« " & champ & " » : nombre invalide.")
        If v < 0D Then Throw New FormatException("« " & champ & " » ne peut pas être négatif.")
        Return v
    End Function

    ''' <summary>Le libellé affiché au-dessus d'une zone, pour un message d'erreur qui parle à l'utilisateur.</summary>
    Private Shared Function Libelle(zone As TextBox) As String
        ' La zone est précédée, dans le même conteneur, du fragment HTML qui porte son <label>.
        Dim parent = zone.Parent
        If parent IsNot Nothing Then
            Dim i = parent.Controls.IndexOf(zone)
            If i > 0 Then
                Dim lit = TryCast(parent.Controls(i - 1), LiteralControl)
                If lit IsNot Nothing Then
                    Dim a = lit.Text.LastIndexOf("<label>", StringComparison.Ordinal)
                    Dim b = If(a < 0, -1, lit.Text.IndexOf("</label>", a, StringComparison.Ordinal))
                    If a >= 0 AndAlso b > a Then Return HttpUtility.HtmlDecode(lit.Text.Substring(a + 7, b - a - 7))
                End If
            End If
        End If
        Return zone.ID.Substring(3)
    End Function

    Private Shared Function Argent(v As Decimal) As String
        Return v.ToString("N2", CultureInfo.GetCultureInfo("fr-CA")) & " $"
    End Function

    Private Shared Function Quand(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value Then Return "?"
        Return Convert.ToDateTime(v).ToString("yyyy-MM-dd HH:mm")
    End Function

    Private Shared Function Par(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value OrElse v.ToString().Length = 0 Then Return ""
        Return " par " & v.ToString()
    End Function

    Private Sub ShowMsg(text As String, isError As Boolean)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = "pe-msg " & If(isError, "bad", "ok")
    End Sub

End Class
