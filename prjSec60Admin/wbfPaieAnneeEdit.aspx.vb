Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
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
    End Sub

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
        p.Add(New SqlParameter("@Par", UserEmail))
        Return p
    End Function

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        Try
            ExecuteSQL("paie.spParametresAnnee_Save", ParametresSaisis())
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
            ExecuteSQL("paie.spParametresAnnee_Save", ParametresSaisis())
            Dim prm = ParametresAnnee.DepuisLigne(Ligne())
            MoteurPaie.Calculer(Entree(60000D, 26, prm.Annee), prm)

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
    Private Shared Function Entree(brut As Decimal, periodes As Integer, annee As Integer) As EntreePaie
        Dim e As New EntreePaie()
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
        Dim r = t.NewRow()
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
