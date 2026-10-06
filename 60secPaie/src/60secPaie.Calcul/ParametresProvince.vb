Imports System.Globalization

''' <summary>
''' L'impôt d'une province ou d'un territoire autre que le Québec, selon le guide T4127 (ARC), option 1 :
'''   T4 = (V × A) – KP – K1P – K2P – K3P – K4P – K5P
'''   T2 = T4 + V1 + V2 – S
''' Chaque province n'utilise qu'une partie de la formule ; ce qui ne la concerne pas reste à zéro.
'''
''' Une province peut changer ses taux en cours d'année (la 123e édition, au 1er juillet 2026, modifie
''' la Colombie-Britannique, Terre-Neuve-et-Labrador et l'Île-du-Prince-Édouard) : chaque jeu de valeurs
''' porte donc sa date d'entrée en vigueur, et une paie prend celui qui s'applique à sa date.
''' </summary>
Public Class ParametresProvince

    Public Property Province As Province
    ''' <summary>Premier jour où ces valeurs s'appliquent (date de la paie).</summary>
    Public Property EnVigueurLe As Date

    Public Property Tranches As Tranche()
    ''' <summary>Montant personnel de base du formulaire TD1 de la province, quand l'employé n'en demande pas d'autre.</summary>
    Public Property MontantPersonnelBase As Decimal
    ''' <summary>Taux des crédits K1P, K2P et K4P (le taux de la première tranche).</summary>
    Public Property TauxCredits As Decimal

    ''' <summary>Manitoba : le montant de base diminue entre ces deux revenus, jusqu'à zéro. 0 = montant fixe.</summary>
    Public Property BaseReduiteDe As Decimal
    Public Property BaseNulleA As Decimal

    ''' <summary>Yukon : crédit canadien pour emploi au palier territorial (K4P).</summary>
    Public Property CreditEmploi As Boolean

    ''' <summary>Alberta (K5P) : crédit supplémentaire de ce taux sur la part de K1P + K2P qui dépasse le seuil.</summary>
    Public Property CreditSupplSeuil As Decimal
    Public Property CreditSupplTaux As Decimal

    ''' <summary>Ontario (V1) : surtaxe sur l'impôt de base.</summary>
    Public Property SurtaxeSeuil1 As Decimal
    Public Property SurtaxeTaux1 As Decimal
    Public Property SurtaxeSeuil2 As Decimal
    Public Property SurtaxeTaux2 As Decimal

    ''' <summary>Ontario (V2) : contribution-santé selon le revenu imposable.</summary>
    Public Property ContributionSante As PalierContributionSante()

    ''' <summary>Ontario (S) : le moindre de l'impôt et de 2 × (base + par personne × n) – impôt.</summary>
    Public Property ReductionBase As Decimal
    Public Property ReductionParPersonne As Decimal

    ''' <summary>
    ''' Colombie-Britannique (S) : réduction de ce montant jusqu'au revenu « seuil », diminuée du taux
    ''' sur l'excédent, et nulle au-delà du revenu « fin ».
    ''' </summary>
    Public Property ReductionRevenuMontant As Decimal
    Public Property ReductionRevenuSeuil As Decimal
    Public Property ReductionRevenuTaux As Decimal
    Public Property ReductionRevenuFin As Decimal

    ''' <summary>Territoires du Nord-Ouest et Nunavut : impôt sur la paie retenu à l'employé (0.02 = 2 %).</summary>
    Public Property TaxePaieEmployeTaux As Decimal

    ''' <summary>Plafond annuel des gains assurables de la commission des accidents du travail. 0 = sans plafond.</summary>
    Public Property AccidentsMaxAssurable As Decimal

    ''' <summary>Montant personnel de base pour un revenu imposable annuel donné (il ne varie qu'au Manitoba).</summary>
    Public Function MontantBasePour(revenuAnnuel As Decimal) As Decimal
        If BaseNulleA <= BaseReduiteDe OrElse revenuAnnuel <= BaseReduiteDe Then Return MontantPersonnelBase
        If revenuAnnuel >= BaseNulleA Then Return 0D
        Return MontantPersonnelBase - ((revenuAnnuel - BaseReduiteDe) * (MontantPersonnelBase / (BaseNulleA - BaseReduiteDe)))
    End Function

    Public ReadOnly Property EstComplet As Boolean
        Get
            Return Tranches IsNot Nothing AndAlso Tranches.Length > 0 AndAlso TauxCredits > 0D AndAlso MontantPersonnelBase > 0D
        End Get
    End Property

    ' ------------------------------------------------------------------
    ' Particularités : tout ce qui n'est pas commun à toutes les provinces, en « cle=valeur;cle=valeur ».
    ' C'est sous cette forme qu'elles sont gardées dans paie.ParametresProvince et saisies dans Sec60Admin.
    ' ------------------------------------------------------------------

    ''' <summary>Les clés reconnues, avec ce qu'elles veulent dire — affiché tel quel dans la console.</summary>
    Public Const AideParticularites As String =
        "baseReduiteDe, baseNulleA (Manitoba : le montant de base diminue entre ces deux revenus) · " &
        "creditEmploi=1 (Yukon : K4P) · creditSupplSeuil, creditSupplTaux (Alberta : K5P) · " &
        "surtaxeSeuil1, surtaxeTaux1, surtaxeSeuil2, surtaxeTaux2 (surtaxe V1) · " &
        "reductionBase, reductionParPersonne (réduction S de l'Ontario) · " &
        "reductionMontant, reductionSeuil, reductionTaux, reductionFin (réduction S de la Colombie-Britannique) · " &
        "taxePaie (T.N.-O. et Nunavut : 0.02 = 2 % retenus à l'employé)"

    Public Sub LireParticularites(texte As String)
        For Each morceau In If(texte, "").Split(";"c)
            If morceau.Trim().Length = 0 Then Continue For
            Dim i = morceau.IndexOf("="c)
            If i <= 0 Then Throw New FormatException("Particularité illisible : « " & morceau.Trim() & " » (attendu : clé=valeur).")
            Dim cle = morceau.Substring(0, i).Trim()
            Dim v = Nombre(morceau.Substring(i + 1))
            Select Case cle.ToLowerInvariant()
                Case "basereduitede" : BaseReduiteDe = v
                Case "basenullea" : BaseNulleA = v
                Case "creditemploi" : CreditEmploi = v <> 0D
                Case "creditsupplseuil" : CreditSupplSeuil = v
                Case "creditsuppltaux" : CreditSupplTaux = v
                Case "surtaxeseuil1" : SurtaxeSeuil1 = v
                Case "surtaxetaux1" : SurtaxeTaux1 = v
                Case "surtaxeseuil2" : SurtaxeSeuil2 = v
                Case "surtaxetaux2" : SurtaxeTaux2 = v
                Case "reductionbase" : ReductionBase = v
                Case "reductionparpersonne" : ReductionParPersonne = v
                Case "reductionmontant" : ReductionRevenuMontant = v
                Case "reductionseuil" : ReductionRevenuSeuil = v
                Case "reductiontaux" : ReductionRevenuTaux = v
                Case "reductionfin" : ReductionRevenuFin = v
                Case "taxepaie" : TaxePaieEmployeTaux = v
                Case Else
                    Throw New FormatException("Particularité inconnue : « " & cle & " ».")
            End Select
        Next
    End Sub

    Public Function EcrireParticularites() As String
        Dim parts As New List(Of String)()
        Ajouter(parts, "baseReduiteDe", BaseReduiteDe)
        Ajouter(parts, "baseNulleA", BaseNulleA)
        If CreditEmploi Then parts.Add("creditEmploi=1")
        Ajouter(parts, "creditSupplSeuil", CreditSupplSeuil)
        Ajouter(parts, "creditSupplTaux", CreditSupplTaux)
        Ajouter(parts, "surtaxeSeuil1", SurtaxeSeuil1)
        Ajouter(parts, "surtaxeTaux1", SurtaxeTaux1)
        Ajouter(parts, "surtaxeSeuil2", SurtaxeSeuil2)
        Ajouter(parts, "surtaxeTaux2", SurtaxeTaux2)
        Ajouter(parts, "reductionBase", ReductionBase)
        Ajouter(parts, "reductionParPersonne", ReductionParPersonne)
        Ajouter(parts, "reductionMontant", ReductionRevenuMontant)
        Ajouter(parts, "reductionSeuil", ReductionRevenuSeuil)
        Ajouter(parts, "reductionTaux", ReductionRevenuTaux)
        Ajouter(parts, "reductionFin", ReductionRevenuFin)
        Ajouter(parts, "taxePaie", TaxePaieEmployeTaux)
        Return String.Join(";", parts)
    End Function

    Private Shared Sub Ajouter(parts As List(Of String), cle As String, v As Decimal)
        If v <> 0D Then parts.Add(cle & "=" & v.ToString("0.#####", CultureInfo.InvariantCulture))
    End Sub

    Private Shared Function Nombre(texte As String) As Decimal
        Dim v As Decimal
        If Decimal.TryParse(texte.Trim().Replace(" ", "").Replace(",", "."), NumberStyles.Any, CultureInfo.InvariantCulture, v) Then Return v
        Throw New FormatException("Nombre illisible : « " & texte.Trim() & " ».")
    End Function

    ''' <summary>
    ''' Construit depuis une ligne de paie.ParametresProvince : Province, EnVigueurLe, Tranches,
    ''' MontantPersonnelBase, TauxCredits, Particularites, AccidentsMaxAssurable.
    ''' </summary>
    Public Shared Function DepuisLigne(r As DataRow) As ParametresProvince
        Dim p As New ParametresProvince()
        p.Province = Provinces.DeCode(Convert.ToString(r("Province"), CultureInfo.InvariantCulture))
        p.EnVigueurLe = Convert.ToDateTime(r("EnVigueurLe"), CultureInfo.InvariantCulture).Date
        p.Tranches = ParametresAnnee.LireTranches(Convert.ToString(r("Tranches"), CultureInfo.InvariantCulture))
        p.MontantPersonnelBase = Convert.ToDecimal(r("MontantPersonnelBase"), CultureInfo.InvariantCulture)
        p.TauxCredits = Convert.ToDecimal(r("TauxCredits"), CultureInfo.InvariantCulture)
        If r.Table.Columns.Contains("Particularites") AndAlso Not r.IsNull("Particularites") Then
            p.LireParticularites(Convert.ToString(r("Particularites"), CultureInfo.InvariantCulture))
        End If
        If r.Table.Columns.Contains("AccidentsMaxAssurable") AndAlso Not r.IsNull("AccidentsMaxAssurable") Then
            p.AccidentsMaxAssurable = Convert.ToDecimal(r("AccidentsMaxAssurable"), CultureInfo.InvariantCulture)
        End If
        Return p
    End Function

    ' ------------------------------------------------------------------
    ' Les valeurs du code : référence de secours et base des tests
    ' ------------------------------------------------------------------

    Private Shared Function T(ParamArray v As Decimal()) As Tranche()
        ' v : taux et constante de la première tranche, puis (seuil de départ, taux, constante) de chacune des suivantes.
        ' Le tableau 8.1 du guide donne le revenu où chaque tranche COMMENCE ; une Tranche garde celui où elle finit.
        Dim liste As New List(Of Tranche)()
        Dim taux = v(0), constante = v(1)
        Dim i = 2
        While i < v.Length
            liste.Add(New Tranche(v(i), taux, constante))
            taux = v(i + 1) : constante = v(i + 2)
            i += 3
        End While
        liste.Add(New Tranche(Decimal.MaxValue, taux, constante))
        Return liste.ToArray()
    End Function

    Private Shared Function Creer(p As Province, mois As Integer, tranches As Tranche(), baseTD1 As Decimal, accidents As Decimal,
                                  Optional particularites As String = Nothing) As ParametresProvince
        Dim pp As New ParametresProvince With {
            .Province = p, .EnVigueurLe = New Date(2026, mois, 1), .Tranches = tranches,
            .MontantPersonnelBase = baseTD1, .TauxCredits = tranches(0).Taux, .AccidentsMaxAssurable = accidents}
        pp.LireParticularites(particularites)
        Return pp
    End Function

    ''' <summary>
    ''' 2026 : T4127, 122e édition (1er janvier) et 123e édition (1er juillet), tableaux 8.1 et 8.2.
    ''' L'Ontario n'est pas ici : ses valeurs vivent dans ParametresAnnee, d'où elles sont reprises.
    ''' Plafonds des accidents du travail : À VALIDER auprès de chaque commission.
    ''' </summary>
    Friend Shared Function Annee2026() As List(Of ParametresProvince)
        Dim l As New List(Of ParametresProvince)()

        l.Add(Creer(Province.Alberta, 1,
            T(0.08D, 0D, 61200D, 0.1D, 1224D, 154259D, 0.12D, 4309D, 185111D, 0.13D, 6160D, 246813D, 0.14D, 8628D, 370220D, 0.15D, 12331D),
            22769D, 110900D, "creditSupplSeuil=4896;creditSupplTaux=0.25"))

        Dim bc = "reductionSeuil=25570;reductionTaux=0.0356;"
        l.Add(Creer(Province.ColombieBritannique, 1,
            T(0.0506D, 0D, 50363D, 0.077D, 1330D, 100728D, 0.105D, 4150D, 115648D, 0.1229D, 6220D, 140430D, 0.147D, 9604D,
              190405D, 0.168D, 13603D, 265545D, 0.205D, 23428D),
            13216D, 127500D, bc & "reductionMontant=575;reductionFin=41722"))
        ' 1er juillet 2026 : premier taux porté à 5,60 % pour l'année, donc 6,14 % sur les paies de juillet à décembre ;
        ' réduction d'impôt de 690 $ pour l'année, donc 805 $ sur ces paies.
        l.Add(Creer(Province.ColombieBritannique, 7,
            T(0.0614D, 0D, 50363D, 0.077D, 786D, 100728D, 0.105D, 3606D, 115648D, 0.1229D, 5676D, 140430D, 0.147D, 9061D,
              190405D, 0.168D, 13059D, 265545D, 0.205D, 22884D),
            13216D, 127500D, bc & "reductionMontant=805;reductionFin=44952"))

        l.Add(Creer(Province.Manitoba, 1,
            T(0.108D, 0D, 47000D, 0.1275D, 917D, 100000D, 0.174D, 5567D),
            15780D, 171500D, "baseReduiteDe=200000;baseNulleA=400000"))

        l.Add(Creer(Province.NouveauBrunswick, 1,
            T(0.094D, 0D, 52333D, 0.14D, 2407D, 104666D, 0.16D, 4501D, 193861D, 0.195D, 11286D),
            13664D, 85800D))

        Dim nl = T(0.087D, 0D, 44678D, 0.145D, 2591D, 89354D, 0.158D, 3753D, 159528D, 0.178D, 6943D, 223340D, 0.198D, 11410D,
                   285319D, 0.208D, 14263D, 570638D, 0.213D, 17117D, 1141275D, 0.218D, 22823D)
        l.Add(Creer(Province.TerreNeuveEtLabrador, 1, nl, 11188D, 80935D))
        ' 1er juillet 2026 : montant de base porté à 13 094 $ pour l'année, donc 15 000 $ sur les paies de juillet à décembre.
        l.Add(Creer(Province.TerreNeuveEtLabrador, 7, nl, 15000D, 80935D))

        l.Add(Creer(Province.NouvelleEcosse, 1,
            T(0.0879D, 0D, 30995D, 0.1495D, 1909D, 61991D, 0.1667D, 2976D, 97417D, 0.175D, 3784D, 157124D, 0.21D, 9283D),
            11932D, 79900D))

        l.Add(Creer(Province.TerritoiresDuNordOuest, 1,
            T(0.059D, 0D, 53003D, 0.086D, 1431D, 106009D, 0.122D, 5247D, 172346D, 0.1405D, 8436D),
            18198D, 116000D, "taxePaie=0.02"))

        l.Add(Creer(Province.Nunavut, 1,
            T(0.04D, 0D, 55801D, 0.07D, 1674D, 111602D, 0.09D, 3906D, 181439D, 0.115D, 8442D),
            19659D, 117300D, "taxePaie=0.02"))

        l.Add(Creer(Province.IlePrinceEdouard, 1,
            T(0.095D, 0D, 33928D, 0.1347D, 1347D, 65820D, 0.166D, 3407D, 106890D, 0.1762D, 4497D, 142520D, 0.19D, 6464D),
            15000D, 89300D))
        ' 1er juillet 2026 : nouvelle tranche de 20 % au-delà de 200 000 $, donc 21 % sur les paies de juillet à décembre.
        l.Add(Creer(Province.IlePrinceEdouard, 7,
            T(0.095D, 0D, 33928D, 0.1347D, 1347D, 65820D, 0.166D, 3407D, 106890D, 0.1762D, 4497D, 142520D, 0.19D, 6464D,
              200000D, 0.21D, 10464D),
            15000D, 89300D))

        l.Add(Creer(Province.Saskatchewan, 1,
            T(0.105D, 0D, 54532D, 0.125D, 1091D, 155805D, 0.145D, 4207D),
            20381D, 108223D))

        ' Yukon : le montant de base est celui du fédéral.
        l.Add(Creer(Province.Yukon, 1,
            T(0.064D, 0D, 58523D, 0.09D, 1522D, 117045D, 0.109D, 3745D, 181440D, 0.128D, 7193D, 500000D, 0.15D, 18193D),
            16452D, 107599D, "creditEmploi=1"))

        Return l
    End Function

End Class
