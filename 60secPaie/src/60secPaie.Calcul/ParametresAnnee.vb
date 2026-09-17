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

    ' --- Cotisations de l'employeur ---
    Public Property CNESSTMaxAssurable As Decimal
    Public Property CNTTaux As Decimal
    Public Property CNTMaxAssujetti As Decimal

    Public Shared Function Pour(annee As Integer) As ParametresAnnee
        Select Case annee
            Case 2026
                Return Annee2026()
            Case Else
                Throw New NotSupportedException(
                    "Les taux de l'année " & annee.ToString() & " ne sont pas encore définis dans ParametresAnnee. " &
                    "Ajoutez-les à partir des guides T4127 (ARC) et TP-1015.F (Revenu Québec).")
        End Select
    End Function

    Public Shared Function EstDisponible(annee As Integer) As Boolean
        Return annee = 2026
    End Function

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

        ' À VALIDER auprès de la CNESST : salaire maximum assurable et taux de la cotisation
        ' relative aux normes du travail pour 2026.
        p.CNESSTMaxAssurable = 103000D
        p.CNTTaux = 0.0006D
        p.CNTMaxAssujetti = 103000D

        Return p
    End Function

    ''' <summary>Taux de cotisation au FSS (en %), selon la masse salariale totale et le secteur (TP-1015.F, partie 5).</summary>
    Public Shared Function TauxFSS(masseSalarialeTotale As Decimal, secteur As SecteurFSS) As Decimal
        If secteur = SecteurFSS.SecteurPublic Then Return 4.26D

        Dim s As Decimal = masseSalarialeTotale / 1000000D
        If s < 1D Then s = 1D
        If s > 7.8D Then s = 7.8D

        Dim taux As Decimal
        If secteur = SecteurFSS.PrimaireManufacturier Then
            taux = 0.8074D + (0.4426D * s)
        Else
            taux = 1.2662D + (0.3838D * s)
        End If
        Return Math.Round(taux, 2, MidpointRounding.AwayFromZero)
    End Function

End Class
