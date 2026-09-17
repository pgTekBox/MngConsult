Public Enum TypeCategorie
    Revenu = 0
    Avantage = 1
    Deduction = 2
End Enum

Public Enum FondsTravailleurs
    Aucun = 0
    FTQ = 1
    Fondaction = 2
End Enum

''' <summary>
''' Catégorie système d'un élément de paie. L'utilisateur ne configure jamais l'imposition :
''' chaque élément de paie pointe vers une catégorie qui porte l'assujettissement aux retenues,
''' aux cotisations de l'employeur et les cases des feuillets T4 / Relevé 1.
''' Pour une déduction, ImpotFederal / ImpotQuebec signifient « réduit le revenu imposable ».
''' </summary>
Public Class CategoriePaie

    Public Property Code As String
    Public Property Libelle As String
    Public Property Type As TypeCategorie
    Public Property ImpotFederal As Boolean
    Public Property ImpotQuebec As Boolean
    Public Property AE As Boolean
    Public Property RRQ As Boolean
    Public Property RQAP As Boolean
    Public Property FSS As Boolean
    Public Property CNESST As Boolean
    ''' <summary>Gains ouvrant droit à l'indemnité de vacances (Québec).</summary>
    Public Property Vacances As Boolean
    Public Property CaseT4 As String
    Public Property CaseR1 As String
    ''' <summary>Gratification, paiement rétroactif ou autre paiement forfaitaire (méthode de calcul particulière).</summary>
    Public Property Forfaitaire As Boolean
    ''' <summary>Pour un avantage : versé en argent (s'ajoute au net). Sinon l'avantage est seulement imposé.</summary>
    Public Property VerseEnArgent As Boolean
    ''' <summary>Multiplicateur du taux horaire (1,5 pour temps et demi, 2 pour temps double).</summary>
    Public Property Multiplicateur As Decimal = 1D
    ''' <summary>Paiement qui réduit le solde de vacances accumulées.</summary>
    Public Property PaieVacances As Boolean
    Public Property Fonds As FondsTravailleurs = FondsTravailleurs.Aucun

    Public ReadOnly Property LibelleComplet As String
        Get
            Dim prefixe As String
            Select Case Type
                Case TypeCategorie.Revenu : prefixe = "Revenu"
                Case TypeCategorie.Avantage : prefixe = "Avantage"
                Case Else : prefixe = "Déduction"
            End Select
            Return prefixe & " - " & Libelle
        End Get
    End Property

    Private Shared ReadOnly _toutes As List(Of CategoriePaie) = Construire()

    Public Shared ReadOnly Property Toutes As IReadOnlyList(Of CategoriePaie)
        Get
            Return _toutes
        End Get
    End Property

    Public Shared Function ParCode(code As String) As CategoriePaie
        For Each c In _toutes
            If String.Equals(c.Code, code, StringComparison.OrdinalIgnoreCase) Then Return c
        Next
        Throw New ArgumentException("Catégorie de paie inconnue : " & code)
    End Function

    Public Shared Function Existe(code As String) As Boolean
        For Each c In _toutes
            If String.Equals(c.Code, code, StringComparison.OrdinalIgnoreCase) Then Return True
        Next
        Return False
    End Function

    Private Shared Function Revenu(code As String, libelle As String, vacances As Boolean,
                                   Optional caseT4 As String = "14", Optional caseR1 As String = "A") As CategoriePaie
        Return New CategoriePaie With {
            .Code = code, .Libelle = libelle, .Type = TypeCategorie.Revenu,
            .ImpotFederal = True, .ImpotQuebec = True, .AE = True, .RRQ = True, .RQAP = True,
            .FSS = True, .CNESST = True, .Vacances = vacances, .CaseT4 = caseT4, .CaseR1 = caseR1}
    End Function

    Private Shared Function Deduction(code As String, libelle As String, reduitFederal As Boolean, reduitQuebec As Boolean,
                                      Optional caseT4 As String = "", Optional caseR1 As String = "") As CategoriePaie
        Return New CategoriePaie With {
            .Code = code, .Libelle = libelle, .Type = TypeCategorie.Deduction,
            .ImpotFederal = reduitFederal, .ImpotQuebec = reduitQuebec, .CaseT4 = caseT4, .CaseR1 = caseR1}
    End Function

    Private Shared Function Construire() As List(Of CategoriePaie)
        Dim l As New List(Of CategoriePaie)()

        ' ---------- Revenus ----------
        l.Add(Revenu("SALAIRE", "Salaire", True))
        l.Add(Revenu("SALAIRE_FIXE", "Salaire fixe", True))
        Dim demi = Revenu("TEMPS_DEMI", "Temps et demi", True) : demi.Multiplicateur = 1.5D : l.Add(demi)
        Dim dbl = Revenu("TEMPS_DOUBLE", "Temps double", True) : dbl.Multiplicateur = 2D : l.Add(dbl)
        l.Add(Revenu("FERIE", "Jours fériés", True))
        l.Add(Revenu("MALADIE", "Congé de maladie", True))
        l.Add(Revenu("COMMISSION", "Commission", True, "14 & 42", "A & M"))
        l.Add(Revenu("AUTRE_REVENU", "Autre type de revenu imposable", True))

        Dim vac = Revenu("VACANCES", "Paie de vacances", True) : vac.PaieVacances = True : l.Add(vac)
        l.Add(Revenu("VACANCES_PAR_PAIE", "Vacances versées à chaque paie", False))

        Dim bonus = Revenu("BONUS", "Gratification (bonus)", True) : bonus.Forfaitaire = True : l.Add(bonus)
        Dim retro = Revenu("RETRO", "Salaire rétroactif", True) : retro.Forfaitaire = True : l.Add(retro)

        l.Add(New CategoriePaie With {
            .Code = "REMBOURSEMENT", .Libelle = "Remboursement de dépenses (non imposable)",
            .Type = TypeCategorie.Revenu, .CaseT4 = "", .CaseR1 = ""})

        ' ---------- Avantages imposables ----------
        l.Add(New CategoriePaie With {
            .Code = "AV_MONETAIRE", .Libelle = "Autre avantage imposable (monétaire)", .Type = TypeCategorie.Avantage,
            .ImpotFederal = True, .ImpotQuebec = True, .AE = True, .RRQ = True, .RQAP = True, .FSS = True, .CNESST = True,
            .VerseEnArgent = True, .CaseT4 = "14 & 40", .CaseR1 = "A & L"})
        l.Add(New CategoriePaie With {
            .Code = "AV_NON_MONETAIRE", .Libelle = "Autre avantage imposable (non monétaire)", .Type = TypeCategorie.Avantage,
            .ImpotFederal = True, .ImpotQuebec = True, .AE = False, .RRQ = True, .RQAP = False, .FSS = True, .CNESST = True,
            .CaseT4 = "14 & 40", .CaseR1 = "A & L"})
        l.Add(New CategoriePaie With {
            .Code = "AV_VEHICULE", .Libelle = "Véhicule à moteur (non monétaire)", .Type = TypeCategorie.Avantage,
            .ImpotFederal = True, .ImpotQuebec = True, .AE = False, .RRQ = True, .RQAP = False, .FSS = True, .CNESST = True,
            .CaseT4 = "14 & 34", .CaseR1 = "A & W"})
        ' La part de l'employeur à un régime privé d'assurance maladie est imposable au Québec seulement.
        l.Add(New CategoriePaie With {
            .Code = "AV_ASSURANCE_MALADIE", .Libelle = "Régime privé d'assurance maladie - part de l'employeur", .Type = TypeCategorie.Avantage,
            .ImpotFederal = False, .ImpotQuebec = True, .AE = False, .RRQ = True, .RQAP = False, .FSS = True, .CNESST = True,
            .CaseT4 = "", .CaseR1 = "A & J"})

        ' ---------- Déductions ----------
        l.Add(Deduction("DED_REER", "REER", True, True))
        l.Add(Deduction("DED_RPA", "Régime de pension agréé (RPA)", True, True, "20 & 52", "D"))
        l.Add(Deduction("DED_RVER", "RVER / RPAC", True, True))
        ' Cotisation syndicale : déduction au fédéral, crédit d'impôt au Québec (pas de réduction à la source).
        l.Add(Deduction("DED_SYNDICAT", "Cotisation syndicale", True, False, "44", "F"))
        Dim ftq = Deduction("DED_FTQ", "Fonds de solidarité FTQ", False, False) : ftq.Fonds = FondsTravailleurs.FTQ : l.Add(ftq)
        Dim fa = Deduction("DED_FONDACTION", "Fondaction CSN", False, False) : fa.Fonds = FondsTravailleurs.Fondaction : l.Add(fa)
        ' Primes payées par l'employé à un régime privé d'assurance maladie : T4 case 85, Relevé 1 code 235.
        l.Add(Deduction("DED_ASSURANCE", "Assurance collective - part de l'employé", False, False, "85", "235"))
        l.Add(Deduction("DED_DON", "Don de bienfaisance", False, False, "46", "N"))
        l.Add(Deduction("DED_AUTRE", "Autre déduction (après impôt)", False, False))

        Return l
    End Function

End Class
