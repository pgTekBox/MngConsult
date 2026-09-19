''' <summary>
''' Le contenu d'un talon de paie, sans mise en forme.
'''
''' Le talon se rend de deux façons — en HTML dans l'écran et le courriel, en PDF
''' dans la pièce jointe. Les deux lisent CE modèle. Recalculer les mêmes chiffres
''' dans deux rendus, c'est accepter qu'ils finissent par différer, et personne ne
''' s'en apercevrait avant qu'un employé compare son écran et son fichier.
'''
''' Les libellés sont en français : ils sont traduits au moment du rendu, chacun
''' dans la langue de son destinataire.
''' </summary>
Public Class DonneesTalon

    Public Property Trouve As Boolean
    Public Property Statut As String            ' B brouillon, C confirmée, A annulée

    ' --- L'employeur ---
    Public Property CompagnieNom As String = ""
    Public Property CompagnieAdresse As String = ""
    Public Property CompagnieLieu As String = ""

    ' --- L'employé ---
    Public Property EmployeNom As String = ""
    Public Property EmployeCode As String = ""
    Public Property EmployeAdresse1 As String = ""
    Public Property EmployeAdresse2 As String = ""
    Public Property EmployeLieu As String = ""

    ' --- La période ---
    Public Property DateDebut As Date
    Public Property DateFin As Date
    Public Property DatePaie As Date
    Public Property DepotDirect As Boolean
    Public Property NumeroCheque As Integer?

    ' --- Ce qui est gagné ---
    Public Property Revenus As New List(Of LigneTalon)()
    Public Property Heures As Decimal
    Public Property BrutVerse As Decimal
    Public Property AvantagesNonMonetaires As Decimal

    ' --- Ce qui est retenu ---
    Public Property Retenues As New List(Of RetenueTalon)()
    Public Property TotalRetenues As Decimal

    Public Property Net As Decimal

    ' --- Depuis le début de l'année ---
    Public Property CumulBrut As Decimal
    Public Property CumulNet As Decimal
    Public Property TauxVacances As Decimal
    Public Property VacancesAccumulees As Decimal
    Public Property SoldeVacances As Decimal

    ''' <summary>« Chèque n° 412 », « Dépôt direct », ou rien si la paie n'est pas encore confirmée.</summary>
    Public ReadOnly Property ModePaiement As String
        Get
            If DepotDirect Then Return "Dépôt direct"
            If NumeroCheque.HasValue Then Return "Chèque n° " & NumeroCheque.Value.ToString()
            Return ""
        End Get
    End Property

End Class

''' <summary>Une ligne de revenu ou d'avantage.</summary>
Public Class LigneTalon
    Public Property Description As String = ""
    Public Property Heures As Decimal
    Public Property Taux As Decimal
    Public Property Montant As Decimal
End Class

''' <summary>
''' Une retenue. Les déductions propres à l'employeur n'ont pas de cumulatif :
''' d'où AvecCumulatif, qui distingue « zéro » de « rien à afficher ».
''' </summary>
Public Class RetenueTalon
    Public Property Libelle As String = ""
    Public Property Courant As Decimal
    Public Property Cumulatif As Decimal
    Public Property AvecCumulatif As Boolean
End Class
