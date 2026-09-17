''' <summary>Ligne saisie pour une paie : un revenu, un avantage ou une déduction.</summary>
Public Class LignePaie
    Public Property CodeCategorie As String
    Public Property Description As String
    Public Property Heures As Decimal
    Public Property Taux As Decimal
    Public Property Montant As Decimal
    ''' <summary>Pour une déduction : elle se rapporte au paiement forfaitaire (ex. cotisation au RPA sur un rétroactif).</summary>
    Public Property SurForfaitaire As Boolean
End Class

''' <summary>Renseignements fiscaux de l'employé (formulaires TD1, TP-1015.3, TP-1016...).</summary>
Public Class ProfilEmploye
    Public Property DateNaissance As Date?

    Public Property ExemptImpotFederal As Boolean
    Public Property ExemptImpotQuebec As Boolean
    Public Property ExemptRRQ As Boolean
    Public Property ExemptRQAP As Boolean
    Public Property ExemptAE As Boolean
    Public Property ExemptFSS As Boolean
    Public Property ExemptCNESST As Boolean

    ''' <summary>TD1 : montant total de la demande (TC). Nothing = montant personnel de base.</summary>
    Public Property TD1MontantDemande As Decimal?
    ''' <summary>TD1 : impôt additionnel à retenir par période (L).</summary>
    Public Property TD1ImpotAdditionnel As Decimal
    ''' <summary>TD1 : déduction annuelle pour les habitants de zones visées (HD).</summary>
    Public Property TD1DeductionZone As Decimal
    ''' <summary>T1213 : déductions annuelles autorisées (F1).</summary>
    Public Property TD1DeductionsAnnuelles As Decimal
    ''' <summary>Autres crédits d'impôt fédéraux autorisés pour l'année (K3).</summary>
    Public Property TD1AutresCredits As Decimal

    ''' <summary>TP-1015.3 : montant de la ligne 10 (E). Nothing = montant personnel de base.</summary>
    Public Property TP1015Montant As Decimal?
    ''' <summary>TP-1015.3 / TP-1017 : retenue supplémentaire par période (L).</summary>
    Public Property TP1015ImpotAdditionnel As Decimal
    ''' <summary>TP-1015.3 : déductions de la ligne 19 (J).</summary>
    Public Property TP1015DeductionsLigne19 As Decimal
    ''' <summary>TP-1016 : déductions annuelles autorisées (J1).</summary>
    Public Property TP1016Deductions As Decimal
    ''' <summary>TP-1016 : crédits d'impôt non remboursables autorisés (K1).</summary>
    Public Property TP1016Credits As Decimal
End Class

Public Class ProfilEmployeur
    ''' <summary>Facteur de cotisation de l'employeur à l'AE (1,4 sauf taux réduit).</summary>
    Public Property FacteurAE As Decimal = 1.4D
    ''' <summary>Taux de cotisation au FSS, en %.</summary>
    Public Property TauxFSS As Decimal = 1.65D
    ''' <summary>Taux de la CNESST, en $ par tranche de 100 $ de salaire assurable.</summary>
    Public Property TauxCNESST As Decimal
    Public Property AssujettiCNT As Boolean = True
End Class

''' <summary>Cumulatifs de l'année avant la paie courante.</summary>
Public Class Cumulatifs
    Public Property RRQ As Decimal
    Public Property RRQ2 As Decimal
    Public Property GainsRRQ As Decimal
    Public Property AE As Decimal
    Public Property RQAP As Decimal
    Public Property RQAPEmployeur As Decimal
    Public Property GainsCNESST As Decimal
    ''' <summary>Paiements forfaitaires imposables déjà versés dans l'année (B1), au fédéral.</summary>
    Public Property ForfaitairesFederal As Decimal
    ''' <summary>Paiements forfaitaires imposables déjà versés dans l'année (B1), au Québec.</summary>
    Public Property ForfaitairesQuebec As Decimal
    ''' <summary>Cotisations supplémentaires au RRQ relatives aux forfaitaires déjà versés (CSB1).</summary>
    Public Property CSBForfaitaires As Decimal
End Class

Public Class EntreePaie
    Public Property Annee As Integer
    Public Property PeriodesParAnnee As Integer
    Public Property DatePaie As Date
    Public Property Lignes As New List(Of LignePaie)()
    Public Property Employe As New ProfilEmploye()
    Public Property Employeur As New ProfilEmployeur()
    Public Property Cumul As New Cumulatifs()
    ''' <summary>Taux de l'indemnité de vacances, en % (4, 6...).</summary>
    Public Property TauxVacances As Decimal = 4D
End Class

Public Class ResultatPaie
    Public Property Heures As Decimal
    ''' <summary>Revenus et avantages versés en argent.</summary>
    Public Property BrutVerse As Decimal
    ''' <summary>Avantages imposables non monétaires (imposés mais non versés).</summary>
    Public Property AvantagesNonMonetaires As Decimal

    Public Property ImpotFederal As Decimal
    Public Property ImpotQuebec As Decimal
    Public Property RRQ As Decimal
    Public Property RRQ2 As Decimal
    Public Property AE As Decimal
    Public Property RQAP As Decimal
    Public Property AutresDeductions As Decimal
    Public Property Net As Decimal

    Public Property EmployeurRRQ As Decimal
    Public Property EmployeurRRQ2 As Decimal
    Public Property EmployeurAE As Decimal
    Public Property EmployeurRQAP As Decimal
    Public Property EmployeurFSS As Decimal
    Public Property EmployeurCNESST As Decimal
    Public Property EmployeurCNT As Decimal

    Public Property GainsRRQ As Decimal
    Public Property GainsAE As Decimal
    Public Property GainsRQAP As Decimal
    Public Property GainsFSS As Decimal
    Public Property GainsCNESST As Decimal
    Public Property GainsVacances As Decimal
    Public Property BrutImposableFederal As Decimal
    Public Property BrutImposableQuebec As Decimal
    Public Property ForfaitairesFederal As Decimal
    Public Property ForfaitairesQuebec As Decimal
    Public Property CSBForfaitaires As Decimal

    Public Property VacancesAccumulees As Decimal
    Public Property VacancesPayees As Decimal

    Public ReadOnly Property TotalRetenues As Decimal
        Get
            Return ImpotFederal + ImpotQuebec + RRQ + RRQ2 + AE + RQAP + AutresDeductions
        End Get
    End Property

    Public ReadOnly Property TotalPartsEmployeur As Decimal
        Get
            Return EmployeurRRQ + EmployeurRRQ2 + EmployeurAE + EmployeurRQAP + EmployeurFSS + EmployeurCNESST + EmployeurCNT
        End Get
    End Property

    ''' <summary>Rapport de vérification : valeurs intermédiaires des formules.</summary>
    Public Property Verification As New List(Of String)()
    Public Property Avertissements As New List(Of String)()
End Class
