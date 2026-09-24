Imports System.Data
Imports System.Globalization

''' <summary>Tranche d'imposition : s'applique au revenu imposable annuel inférieur ou égal à <see cref="SeuilMax"/>.</summary>
Public Structure Tranche
    Public ReadOnly SeuilMax As Decimal
    Public ReadOnly Taux As Decimal
    Public ReadOnly Constante As Decimal

    Public Sub New(seuilMax As Decimal, taux As Decimal, constante As Decimal)
        Me.SeuilMax = seuilMax
        Me.Taux = taux
        Me.Constante = constante
    End Sub
End Structure

Public Enum SecteurFSS
    General = 0
    PrimaireManufacturier = 1
    SecteurPublic = 2
End Enum

''' <summary>
''' Taux et plafonds gouvernementaux d'une année, pour un employé du Québec.
''' Sources 2026 : T4127 (122e et 123e éditions, ARC) et TP-1015.F (2026-01, Revenu Québec).
'''
''' D'OÙ VIENNENT LES TAUX. Deux sources, dans cet ordre :
'''   1. le <see cref="Fournisseur"/>, branché par l'application (table paie.ParametresAnnee,
'''      tenue à jour dans la console Sec60Admin : une ligne par année, validée ou non) ;
'''   2. à défaut, les fonctions Annee20XX() de ce fichier — la référence de secours,
'''      et ce que les tests unitaires exercent.
''' Une année absente des deux n'est pas calculable : Pour() le dit en clair.
'''
''' Les tranches d'imposition s'échangent avec la base en texte
''' « seuil|taux|constante;… », « * » marquant la dernière tranche, sans plafond.
''' </summary>
Public Class ParametresAnnee

    Public Property Annee As Integer

    ' --- Impôt fédéral (T4127) ---
    Public Property FedTranches As Tranche()
    Public Property FedMontantPersonnelBase As Decimal
    Public Property FedTauxCredits As Decimal
    Public Property FedMontantEmploi As Decimal          ' CEA
    Public Property FedAbattementQuebec As Decimal
    Public Property FedCreditFondsTravailleursTaux As Decimal
    Public Property FedCreditFondsTravailleursMax As Decimal
    Public Property FedSeuilForfaitaireTauxFixe As Decimal
    Public Property FedTauxFixeForfaitaireQuebec As Decimal

    ' --- Assurance-emploi, taux du Québec ---
    Public Property AEMaxAssurable As Decimal
    Public Property AETaux As Decimal
    Public Property AEMaxEmploye As Decimal

    ' --- Impôt du Québec (TP-1015.F) ---
    Public Property QcTranches As Tranche()
    Public Property QcMontantPersonnelBase As Decimal
    Public Property QcTauxCredits As Decimal
    Public Property QcDeductionTravailleurTaux As Decimal
    Public Property QcDeductionTravailleurMax As Decimal
    Public Property QcCreditFondsTravailleursTaux As Decimal
    Public Property QcFondsTravailleursMaxAnnuel As Decimal
    Public Property QcSeuilForfaitaireTauxFixe As Decimal
    Public Property QcTauxFixeForfaitaire As Decimal

    ' --- RRQ ---
    Public Property RRQMaxGainsAdmissibles As Decimal    ' MGA
    Public Property RRQExemption As Decimal
    Public Property RRQTaux As Decimal                   ' base + première supplémentaire
    Public Property RRQTauxBase As Decimal
    Public Property RRQMaxEmploye As Decimal
    Public Property RRQMaxBaseEmploye As Decimal         ' partie « base » utilisée dans K2Q
    Public Property RRQ2MaxSupplementaire As Decimal     ' MSGA
    Public Property RRQ2Taux As Decimal
    Public Property RRQ2MaxEmploye As Decimal

    ' --- RQAP ---
    Public Property RQAPMaxAssurable As Decimal
    Public Property RQAPTauxEmploye As Decimal
    Public Property RQAPMaxEmploye As Decimal
    Public Property RQAPTauxEmployeur As Decimal
    Public Property RQAPMaxEmployeur As Decimal

    ' --- Fonds des services de santé, FSS (TP-1015.F, partie 5) ---
    ' Le taux se calcule : constante + coefficient x masse salariale en millions,
    ' la masse étant d'abord ramenée entre le plancher et le plafond. Ces quatre
    ' nombres et ces deux bornes changent d'une année à l'autre comme le reste.
    Public Property FSSTauxSecteurPublic As Decimal
    Public Property FSSMassePlancher As Decimal
    Public Property FSSMassePlafond As Decimal
    Public Property FSSGeneralConstante As Decimal
    Public Property FSSGeneralCoefficient As Decimal
    Public Property FSSPrimaireConstante As Decimal
    Public Property FSSPrimaireCoefficient As Decimal

    ' --- Cotisations de l'employeur ---
    Public Property CNESSTMaxAssurable As Decimal
    Public Property CNTTaux As Decimal
    Public Property CNTMaxAssujetti As Decimal

    ''' <summary>
    ''' La source vivante des taux : une fonction qui rend les paramètres d'une
    ''' année, ou Nothing si elle ne les connaît pas (année absente, non validée,
    ''' base injoignable). L'application web la branche au démarrage sur
    ''' paie.ParametresAnnee ; sans elle, seules les années du code existent.
    ''' </summary>
    Public Shared Property Fournisseur As Func(Of Integer, ParametresAnnee)

    ''' <summary>Les taux de l'année, ou une exception si elle n'est pas encore définie.</summary>
    Public Shared Function Pour(annee As Integer) As ParametresAnnee
        Dim p = Construire(annee)
        If p Is Nothing Then
            Throw New NotSupportedException(
                "Les taux de l'année " & annee.ToString() & " ne sont pas encore définis ni validés. " &
                "Saisissez-les dans Sec60Admin (Paie › Taux de l'année) à partir des guides T4127 (ARC) et TP-1015.F (Revenu Québec).")
        End If
        Return p
    End Function

    ''' <summary>Vrai si les taux de l'année sont connus. Se déduit de Construire : une seule vérité.</summary>
    Public Shared Function EstDisponible(annee As Integer) As Boolean
        Return Construire(annee) IsNot Nothing
    End Function

    ''' <summary>
    ''' L'année courante si ses taux sont connus, sinon la plus récente qui le soit.
    ''' Sert aux écrans qui affichent une valeur de référence (montant personnel de
    ''' base, taux du FSS) : mieux vaut montrer l'année précédente que rien du tout.
    ''' </summary>
    Public Shared Function DerniereAnneeConnue() As Integer
        Dim courante As Integer = Date.Today.Year
        For recul As Integer = 0 To 20
            If EstDisponible(courante - recul) Then Return courante - recul
        Next
        Return courante   ' aucune année connue : l'appel à Pour dira ce qui manque
    End Function

    ''' <summary>Les taux à afficher hors d'un calcul de paie : ceux de DerniereAnneeConnue.</summary>
    Public Shared Function PourAffichage() As ParametresAnnee
        Return Pour(DerniereAnneeConnue())
    End Function

    ''' <summary>
    ''' Le seul endroit où une année existe : le fournisseur d'abord, le code ensuite.
    ''' Retourne Nothing si aucun des deux ne la connaît.
    ''' </summary>
    Private Shared Function Construire(annee As Integer) As ParametresAnnee
        Dim f = Fournisseur
        If f IsNot Nothing Then
            Dim p = f(annee)
            If p IsNot Nothing Then Return p
        End If
        Return DuCode(annee)
    End Function

    ''' <summary>Les années écrites dans le code, référence de secours et base des tests.</summary>
    Public Shared Function DuCode(annee As Integer) As ParametresAnnee
        Select Case annee
            Case 2026
                Return Annee2026()
            Case Else
                Return Nothing
        End Select
    End Function

    ' ------------------------------------------------------------------
    ' Échange avec la base : une ligne de paie.ParametresAnnee <-> l'objet
    ' ------------------------------------------------------------------

    ''' <summary>Construit les paramètres depuis une ligne de paie.ParametresAnnee (mêmes noms de colonnes que les propriétés).</summary>
    Public Shared Function DepuisLigne(r As DataRow) As ParametresAnnee
        If r Is Nothing Then Return Nothing
        Dim p As New ParametresAnnee()
        p.Annee = Convert.ToInt32(r("Annee"), CultureInfo.InvariantCulture)

        p.FedTranches = LireTranches(Convert.ToString(r("FedTranches"), CultureInfo.InvariantCulture))
        p.FedMontantPersonnelBase = D(r, "FedMontantPersonnelBase")
        p.FedTauxCredits = D(r, "FedTauxCredits")
        p.FedMontantEmploi = D(r, "FedMontantEmploi")
        p.FedAbattementQuebec = D(r, "FedAbattementQuebec")
        p.FedCreditFondsTravailleursTaux = D(r, "FedCreditFondsTravailleursTaux")
        p.FedCreditFondsTravailleursMax = D(r, "FedCreditFondsTravailleursMax")
        p.FedSeuilForfaitaireTauxFixe = D(r, "FedSeuilForfaitaireTauxFixe")
        p.FedTauxFixeForfaitaireQuebec = D(r, "FedTauxFixeForfaitaireQuebec")

        p.AEMaxAssurable = D(r, "AEMaxAssurable")
        p.AETaux = D(r, "AETaux")
        p.AEMaxEmploye = D(r, "AEMaxEmploye")

        p.QcTranches = LireTranches(Convert.ToString(r("QcTranches"), CultureInfo.InvariantCulture))
        p.QcMontantPersonnelBase = D(r, "QcMontantPersonnelBase")
        p.QcTauxCredits = D(r, "QcTauxCredits")
        p.QcDeductionTravailleurTaux = D(r, "QcDeductionTravailleurTaux")
        p.QcDeductionTravailleurMax = D(r, "QcDeductionTravailleurMax")
        p.QcCreditFondsTravailleursTaux = D(r, "QcCreditFondsTravailleursTaux")
        p.QcFondsTravailleursMaxAnnuel = D(r, "QcFondsTravailleursMaxAnnuel")
        p.QcSeuilForfaitaireTauxFixe = D(r, "QcSeuilForfaitaireTauxFixe")
        p.QcTauxFixeForfaitaire = D(r, "QcTauxFixeForfaitaire")

        p.RRQMaxGainsAdmissibles = D(r, "RRQMaxGainsAdmissibles")
        p.RRQExemption = D(r, "RRQExemption")
        p.RRQTaux = D(r, "RRQTaux")
        p.RRQTauxBase = D(r, "RRQTauxBase")
        p.RRQMaxEmploye = D(r, "RRQMaxEmploye")
        p.RRQMaxBaseEmploye = D(r, "RRQMaxBaseEmploye")
        p.RRQ2MaxSupplementaire = D(r, "RRQ2MaxSupplementaire")
        p.RRQ2Taux = D(r, "RRQ2Taux")
        p.RRQ2MaxEmploye = D(r, "RRQ2MaxEmploye")

        p.RQAPMaxAssurable = D(r, "RQAPMaxAssurable")
        p.RQAPTauxEmploye = D(r, "RQAPTauxEmploye")
        p.RQAPMaxEmploye = D(r, "RQAPMaxEmploye")
        p.RQAPTauxEmployeur = D(r, "RQAPTauxEmployeur")
        p.RQAPMaxEmployeur = D(r, "RQAPMaxEmployeur")

        p.FSSTauxSecteurPublic = D(r, "FSSTauxSecteurPublic")
        p.FSSMassePlancher = D(r, "FSSMassePlancher")
        p.FSSMassePlafond = D(r, "FSSMassePlafond")
        p.FSSGeneralConstante = D(r, "FSSGeneralConstante")
        p.FSSGeneralCoefficient = D(r, "FSSGeneralCoefficient")
        p.FSSPrimaireConstante = D(r, "FSSPrimaireConstante")
        p.FSSPrimaireCoefficient = D(r, "FSSPrimaireCoefficient")

        p.CNESSTMaxAssurable = D(r, "CNESSTMaxAssurable")
        p.CNTTaux = D(r, "CNTTaux")
        p.CNTMaxAssujetti = D(r, "CNTMaxAssujetti")
        Return p
    End Function

    Private Shared Function D(r As DataRow, colonne As String) As Decimal
        Dim v = r(colonne)
        If v Is Nothing OrElse v Is DBNull.Value Then Return 0D
        Return Convert.ToDecimal(v, CultureInfo.InvariantCulture)
    End Function

    ''' <summary>« 58523|0.14|0;117045|0.205|3804;*|0.33|26024 » → tranches. « * » = sans plafond.</summary>
    Public Shared Function LireTranches(texte As String) As Tranche()
        Dim liste As New List(Of Tranche)()
        If String.IsNullOrWhiteSpace(texte) Then Return liste.ToArray()
        For Each morceau In texte.Split(";"c)
            If morceau.Trim().Length = 0 Then Continue For
            Dim champs = morceau.Split("|"c)
            If champs.Length <> 3 Then Throw New FormatException("Tranche illisible : « " & morceau & " ». Attendu : seuil|taux|constante.")
            Dim seuilTexte = champs(0).Trim()
            Dim seuil As Decimal = If(seuilTexte = "*", Decimal.MaxValue, Nombre(seuilTexte))
            liste.Add(New Tranche(seuil, Nombre(champs(1)), Nombre(champs(2))))
        Next
        If liste.Count = 0 Then Throw New FormatException("Aucune tranche d'imposition.")
        If liste(liste.Count - 1).SeuilMax <> Decimal.MaxValue Then Throw New FormatException("La dernière tranche doit être sans plafond (« * »).")
        For i = 1 To liste.Count - 1
            If liste(i).SeuilMax <= liste(i - 1).SeuilMax Then Throw New FormatException("Les seuils des tranches doivent être croissants.")
        Next
        Return liste.ToArray()
    End Function

    ''' <summary>Tranches → texte « seuil|taux|constante;… », l'inverse de LireTranches.</summary>
    Public Shared Function EcrireTranches(tranches As Tranche()) As String
        If tranches Is Nothing Then Return ""
        Dim parts As New List(Of String)()
        For Each t In tranches
            Dim seuil = If(t.SeuilMax = Decimal.MaxValue, "*", t.SeuilMax.ToString("0.##", CultureInfo.InvariantCulture))
            parts.Add(seuil & "|" & t.Taux.ToString("0.#####", CultureInfo.InvariantCulture) & "|" & t.Constante.ToString("0.##", CultureInfo.InvariantCulture))
        Next
        Return String.Join(";", parts)
    End Function

    Private Shared Function Nombre(texte As String) As Decimal
        Dim v As Decimal
        If Decimal.TryParse(texte.Trim().Replace(" ", "").Replace(",", "."), NumberStyles.Any, CultureInfo.InvariantCulture, v) Then Return v
        Throw New FormatException("Nombre illisible : « " & texte & " ».")
    End Function

    ' ------------------------------------------------------------------
    ' Les années du code
    ' ------------------------------------------------------------------

    Private Shared Function Annee2026() As ParametresAnnee
        Dim p As New ParametresAnnee()
        p.Annee = 2026

        ' T4127, tableau 8.1 (inchangé au 1er juillet 2026 pour le fédéral)
        p.FedTranches = {
            New Tranche(58523D, 0.14D, 0D),
            New Tranche(117045D, 0.205D, 3804D),
            New Tranche(181440D, 0.26D, 10241D),
            New Tranche(258482D, 0.29D, 15685D),
            New Tranche(Decimal.MaxValue, 0.33D, 26024D)}
        p.FedMontantPersonnelBase = 16452D
        p.FedTauxCredits = 0.14D
        p.FedMontantEmploi = 1501D
        p.FedAbattementQuebec = 0.165D
        p.FedCreditFondsTravailleursTaux = 0.15D
        p.FedCreditFondsTravailleursMax = 750D
        p.FedSeuilForfaitaireTauxFixe = 5000D
        p.FedTauxFixeForfaitaireQuebec = 0.1D

        p.AEMaxAssurable = 68900D
        p.AETaux = 0.013D
        p.AEMaxEmploye = 895.7D

        ' TP-1015.F (2026-01)
        p.QcTranches = {
            New Tranche(54345D, 0.14D, 0D),
            New Tranche(108680D, 0.19D, 2717D),
            New Tranche(132245D, 0.24D, 8151D),
            New Tranche(Decimal.MaxValue, 0.2575D, 10465D)}
        p.QcMontantPersonnelBase = 18952D
        p.QcTauxCredits = 0.14D
        p.QcDeductionTravailleurTaux = 0.06D
        p.QcDeductionTravailleurMax = 1450D
        p.QcCreditFondsTravailleursTaux = 0.15D
        p.QcFondsTravailleursMaxAnnuel = 5000D
        p.QcSeuilForfaitaireTauxFixe = 18952D
        p.QcTauxFixeForfaitaire = 0.07D

        p.RRQMaxGainsAdmissibles = 74600D
        p.RRQExemption = 3500D
        p.RRQTaux = 0.063D
        p.RRQTauxBase = 0.053D
        p.RRQMaxEmploye = 4479.3D
        p.RRQMaxBaseEmploye = 3768.3D
        p.RRQ2MaxSupplementaire = 85000D
        p.RRQ2Taux = 0.04D
        p.RRQ2MaxEmploye = 416D

        p.RQAPMaxAssurable = 103000D
        p.RQAPTauxEmploye = 0.0043D
        p.RQAPMaxEmploye = 442.9D
        p.RQAPTauxEmployeur = 0.00602D
        p.RQAPMaxEmployeur = 620.06D

        ' TP-1015.F (2026-01), partie 5 : cotisation au FSS selon la masse salariale
        p.FSSTauxSecteurPublic = 4.26D
        p.FSSMassePlancher = 1000000D
        p.FSSMassePlafond = 7800000D
        p.FSSGeneralConstante = 1.2662D
        p.FSSGeneralCoefficient = 0.3838D
        p.FSSPrimaireConstante = 0.8074D
        p.FSSPrimaireCoefficient = 0.4426D

        ' À VALIDER auprès de la CNESST : salaire maximum assurable et taux de la cotisation
        ' relative aux normes du travail pour 2026.
        p.CNESSTMaxAssurable = 103000D
        p.CNTTaux = 0.0006D
        p.CNTMaxAssujetti = 103000D

        Return p
    End Function

    ''' <summary>Taux de cotisation au FSS (en %), selon la masse salariale totale et le secteur (TP-1015.F, partie 5).</summary>
    Public Function TauxFSS(masseSalarialeTotale As Decimal, secteur As SecteurFSS) As Decimal
        If secteur = SecteurFSS.SecteurPublic Then Return FSSTauxSecteurPublic

        Dim masse As Decimal = masseSalarialeTotale
        If masse < FSSMassePlancher Then masse = FSSMassePlancher
        If masse > FSSMassePlafond Then masse = FSSMassePlafond

        ' La formule du guide s'exprime en millions de dollars.
        Dim s As Decimal = masse / 1000000D

        Dim taux As Decimal
        If secteur = SecteurFSS.PrimaireManufacturier Then
            taux = FSSPrimaireConstante + (FSSPrimaireCoefficient * s)
        Else
            taux = FSSGeneralConstante + (FSSGeneralCoefficient * s)
        End If
        Return Math.Round(taux, 2, MidpointRounding.AwayFromZero)
    End Function

End Class
