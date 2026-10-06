''' <summary>
''' Province ou territoire d'emploi : celui de l'établissement de l'employeur où l'employé se présente
''' au travail. Il décide de tout ce qui n'est pas fédéral — l'impôt provincial, le régime de pension
''' (RRQ au Québec, RPC ailleurs), le RQAP, les cotisations de l'employeur.
''' </summary>
Public Enum Province
    Quebec = 0
    Ontario = 1
    Alberta = 2
    ColombieBritannique = 3
    Manitoba = 4
    NouveauBrunswick = 5
    TerreNeuveEtLabrador = 6
    NouvelleEcosse = 7
    TerritoiresDuNordOuest = 8
    Nunavut = 9
    IlePrinceEdouard = 10
    Saskatchewan = 11
    Yukon = 12
End Enum

''' <summary>Codes à deux lettres (ceux de la base et de la case 10 du T4) et provinces que le moteur sait calculer.</summary>
Public NotInheritable Class Provinces

    Private Sub New()
    End Sub

    ''' <summary>Dans l'ordre d'affichage : le Québec et l'Ontario d'abord, puis l'ordre alphabétique français.</summary>
    Public Shared ReadOnly Gerees As Province() = {
        Province.Quebec, Province.Ontario, Province.Alberta, Province.ColombieBritannique, Province.IlePrinceEdouard,
        Province.Manitoba, Province.NouveauBrunswick, Province.NouvelleEcosse, Province.Nunavut, Province.Saskatchewan,
        Province.TerreNeuveEtLabrador, Province.TerritoiresDuNordOuest, Province.Yukon}

    Private Shared ReadOnly _codes As String() = {"QC", "ON", "AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "PE", "SK", "YT"}

    Private Shared ReadOnly _noms As String() = {
        "Québec", "Ontario", "Alberta", "Colombie-Britannique", "Manitoba", "Nouveau-Brunswick", "Terre-Neuve-et-Labrador",
        "Nouvelle-Écosse", "Territoires du Nord-Ouest", "Nunavut", "Île-du-Prince-Édouard", "Saskatchewan", "Yukon"}

    ''' <summary>Le nom précédé de « de », accordé : « de l'Ontario », « du Manitoba », « des Territoires du Nord-Ouest ».</summary>
    Private Shared ReadOnly _de As String() = {
        "du Québec", "de l'Ontario", "de l'Alberta", "de la Colombie-Britannique", "du Manitoba", "du Nouveau-Brunswick",
        "de Terre-Neuve-et-Labrador", "de la Nouvelle-Écosse", "des Territoires du Nord-Ouest", "du Nunavut",
        "de l'Île-du-Prince-Édouard", "de la Saskatchewan", "du Yukon"}

    Public Shared Function Code(p As Province) As String
        Return _codes(CInt(p))
    End Function

    Public Shared Function Nom(p As Province) As String
        Return _noms(CInt(p))
    End Function

    ''' <summary>« de l'Ontario », « du Manitoba »… pour composer « Impôt de l'Ontario ».</summary>
    Public Shared Function DeNom(p As Province) As String
        Return _de(CInt(p))
    End Function

    Public Shared Function EstGeree(codeProvince As String) As Boolean
        Return Array.IndexOf(_codes, If(codeProvince, "").Trim().ToUpperInvariant()) >= 0
    End Function

    ''' <summary>
    ''' « ON » → Ontario, « QC » ou vide → Québec (toutes les paies d'avant les autres provinces sont du Québec).
    ''' Un code inconnu est refusé : le calculer avec les règles d'une voisine donnerait
    ''' des retenues fausses sans que rien ne le signale.
    ''' </summary>
    Public Shared Function DeCode(codeProvince As String) As Province
        Dim c = If(codeProvince, "").Trim().ToUpperInvariant()
        If c.Length = 0 Then Return Province.Quebec
        Dim i = Array.IndexOf(_codes, c)
        If i >= 0 Then Return CType(i, Province)
        Throw New NotSupportedException("La paie de la province « " & c & " » n'est pas prise en charge.")
    End Function

End Class

''' <summary>
''' Les noms qui changent d'une province à l'autre. Les montants, eux, vivent dans les mêmes
''' champs (voir ResultatPaie) : le régime de pension est le RRQ au Québec et le RPC ailleurs,
''' la cotisation santé de l'employeur est le FSS, l'ISE de l'Ontario ou son équivalent, la
''' couverture des accidents du travail est la CNESST, la WSIB ou la commission de la province.
''' Les libellés sont en français ; ils sont traduits à l'affichage comme tous les autres.
''' </summary>
Public Class LibellesProvince

    Public Property Province As Province
    Public Property ImpotProvincial As String
    ''' <summary>Pour les entêtes de colonnes étroites.</summary>
    Public Property ImpotProvincialCourt As String
    Public Property Pension As String
    Public Property Pension2 As String
    ''' <summary>Cotisation santé à la charge de l'employeur : FSS, ISE… Vide s'il n'y en a pas dans la province.</summary>
    Public Property Sante As String
    Public Property SanteLong As String
    ''' <summary>Vrai si la province perçoit une cotisation de l'employeur sur la masse salariale (FSS, ISE, etc.).</summary>
    Public Property ASante As Boolean
    ''' <summary>Accidents du travail : CNESST, WSIB, WCB…</summary>
    Public Property Accidents As String
    ''' <summary>Formulaire de crédits d'impôt personnels de la province : TP-1015.3, TD1ON, TD1AB…</summary>
    Public Property FormulaireCredits As String
    Public Property AMaternite As Boolean
    Public Property ANormesDuTravail As Boolean
    ''' <summary>
    ''' Territoires du Nord-Ouest et Nunavut : impôt de 2 % sur la paie, retenu à l'employé et remis
    ''' au territoire. Son montant occupe le champ du RQAP, qui n'existe pas hors Québec.
    ''' </summary>
    Public Property ARetenueTerritoriale As Boolean
    ''' <summary>Nom de la retenue qui occupe le champ du RQAP : « RQAP », « Impôt sur la paie » ou vide.</summary>
    Public Property RetenueProvinciale As String
    ''' <summary>Vrai si le formulaire de la province compte les personnes à charge pour une réduction d'impôt (Ontario).</summary>
    Public Property APersonnesACharge As Boolean

    Private Shared ReadOnly _tous As LibellesProvince() = Construire()

    Private Shared Function Construire() As LibellesProvince()
        Dim liste(12) As LibellesProvince
        liste(CInt(Province.Quebec)) = New LibellesProvince With {
            .Province = Province.Quebec,
            .ImpotProvincial = "Impôt du Québec", .ImpotProvincialCourt = "Impôt Qc",
            .Pension = "RRQ", .Pension2 = "RRQ - 2e cotisation suppl.",
            .Sante = "FSS", .SanteLong = "Fonds des services de santé (FSS)", .ASante = True,
            .Accidents = "CNESST", .FormulaireCredits = "TP-1015.3", .AMaternite = True, .ANormesDuTravail = True,
            .RetenueProvinciale = "RQAP"}

        ' Hors Québec : sigle de la cotisation santé de l'employeur (vide s'il n'y en a pas), son nom long,
        ' et le nom de la commission des accidents du travail.
        Ajouter(liste, Province.Ontario, "ISE", "Impôt-santé des employeurs (ISE)", "WSIB")
        Ajouter(liste, Province.Alberta, "", "", "WCB")
        Ajouter(liste, Province.ColombieBritannique, "ISE", "Impôt-santé des employeurs (ISE)", "WorkSafeBC")
        Ajouter(liste, Province.Manitoba, "ISFP", "Impôt pour la santé et l'enseignement postsecondaire (ISFP)", "WCB")
        Ajouter(liste, Province.NouveauBrunswick, "", "", "Travail sécuritaire NB")
        Ajouter(liste, Province.TerreNeuveEtLabrador, "ISEPS", "Impôt pour la santé et l'éducation postsecondaire (ISEPS)", "WorkplaceNL")
        Ajouter(liste, Province.NouvelleEcosse, "", "", "WCB")
        Ajouter(liste, Province.TerritoiresDuNordOuest, "", "", "WSCC")
        Ajouter(liste, Province.Nunavut, "", "", "WSCC")
        Ajouter(liste, Province.IlePrinceEdouard, "", "", "WCB")
        Ajouter(liste, Province.Saskatchewan, "", "", "WCB")
        Ajouter(liste, Province.Yukon, "", "", "WSCB")
        Return liste
    End Function

    Private Shared Sub Ajouter(liste As LibellesProvince(), p As Province, sante As String, santeLong As String, accidents As String)
        Dim territoire = p = Province.TerritoiresDuNordOuest OrElse p = Province.Nunavut
        liste(CInt(p)) = New LibellesProvince With {
            .Province = p,
            .ImpotProvincial = "Impôt " & Provinces.DeNom(p), .ImpotProvincialCourt = If(p = Province.Ontario, "Impôt Ont.", "Impôt " & Provinces.Code(p)),
            .Pension = "RPC", .Pension2 = "RPC - 2e cotisation suppl.",
            .Sante = If(sante.Length = 0, "Cotisation santé", sante),
            .SanteLong = If(sante.Length = 0, "Cotisation santé de l'employeur", santeLong), .ASante = sante.Length > 0,
            .Accidents = accidents, .FormulaireCredits = "TD1" & Provinces.Code(p),
            .AMaternite = False, .ANormesDuTravail = False,
            .ARetenueTerritoriale = territoire, .RetenueProvinciale = If(territoire, "Impôt sur la paie", ""),
            .APersonnesACharge = p = Province.Ontario}
    End Sub

    Public Shared Function Pour(p As Province) As LibellesProvince
        Return _tous(CInt(p))
    End Function

    Public Shared Function Pour(codeProvince As String) As LibellesProvince
        Return Pour(Provinces.DeCode(codeProvince))
    End Function

End Class
