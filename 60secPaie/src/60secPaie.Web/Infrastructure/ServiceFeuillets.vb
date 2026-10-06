Imports Paie60Sec.Calcul

''' <summary>Montants des cases du T4 et du Relevé 1 d'un employé pour une année.</summary>
Public Class Feuillet
    Public Property Employe As DataRow
    Public Property T4 As New Dictionary(Of String, Decimal)()
    Public Property R1 As New Dictionary(Of String, Decimal)()
    Public Property ContientCumulatifsDepart As Boolean
    ''' <summary>Province d'emploi (case 10 du T4) : celle des paies de l'année, sinon celle de la compagnie.</summary>
    Public Property Province As String = "QC"
    ''' <summary>Un Relevé 1 n'est produit que pour un emploi au Québec.</summary>
    Public Property AvecReleve1 As Boolean = True
    ''' <summary>
    ''' L'employé a été payé dans plus d'une province pendant l'année : l'ARC veut un T4 par
    ''' province d'emploi. Les montants sont ici réunis ; la répartition reste à faire à la main.
    ''' </summary>
    Public Property DeuxProvinces As Boolean
    ''' <summary>Codes des provinces où l'employé a été payé dans l'année (paies et cumulatifs de départ), en ordre alphabétique.</summary>
    Public Property ProvincesEmploi As New List(Of String)()

    Public ReadOnly Property NomComplet As String
        Get
            Return Employe.Txt("Nom") & ", " & Employe.Txt("Prenom")
        End Get
    End Property

    Public Function CaseT4(code As String) As Decimal
        Dim v As Decimal
        Return If(T4.TryGetValue(code, v), v, 0D)
    End Function

    Public Function CaseR1(code As String) As Decimal
        Dim v As Decimal
        Return If(R1.TryGetValue(code, v), v, 0D)
    End Function
End Class

''' <summary>
''' Préparation des feuillets de fin d'année à partir des paies confirmées (et des cumulatifs de départ).
''' Les montants servent à remplir les feuillets dans les services en ligne de l'ARC et de Revenu Québec ;
''' 60secPaie ne produit pas le fichier XML de transmission.
'''
''' Québec : T4 (cases 17, 17A, 55 et 56 pour le RRQ et le RQAP) et Relevé 1.
''' Hors Québec : T4 seulement (case 10 = code de la province ; cases 16 et 16A pour le RPC ; la case 22 réunit
''' l'impôt fédéral et celui de la province). L'impôt sur la paie des Territoires du Nord-Ouest et du Nunavut,
''' qui occupe la colonne RQAP, n'est ni un impôt sur le revenu ni une cotisation au RPAP : il ne va dans aucune case.
''' </summary>
Public NotInheritable Class ServiceFeuillets

    Private Sub New()
    End Sub

    ''' <summary>Cases du T4, dans l'ordre d'affichage.</summary>
    Public Shared ReadOnly LibellesT4 As KeyValuePair(Of String, String)() = {
        P("14", "Revenus d'emploi"),
        P("16", "Cotisations de l'employé au RPC"),
        P("16A", "Deuxièmes cotisations supplémentaires de l'employé au RPC"),
        P("17", "Cotisations de l'employé au RRQ"),
        P("17A", "Deuxièmes cotisations supplémentaires de l'employé au RRQ"),
        P("18", "Cotisations de l'employé à l'AE"),
        P("20", "Cotisations à un RPA"),
        P("22", "Impôt sur le revenu retenu"),
        P("24", "Gains assurables d'AE"),
        P("26", "Gains ouvrant droit à pension - RPC/RRQ"),
        P("34", "Usage personnel d'une automobile de l'employeur"),
        P("40", "Autres allocations et avantages imposables"),
        P("42", "Commissions d'emploi"),
        P("44", "Cotisations syndicales"),
        P("46", "Dons de bienfaisance"),
        P("55", "Cotisations de l'employé au RPAP (RQAP)"),
        P("56", "Gains assurables du RPAP (RQAP)"),
        P("85", "Primes versées par l'employé à un régime privé d'assurance-maladie")}

    ''' <summary>Cases du Relevé 1, dans l'ordre d'affichage.</summary>
    Public Shared ReadOnly LibellesR1 As KeyValuePair(Of String, String)() = {
        P("A", "Revenus d'emploi"),
        P("B.A", "Cotisation au RRQ"),
        P("B.B", "Cotisation supplémentaire au RRQ (deuxième)"),
        P("C", "Cotisation à l'assurance emploi"),
        P("D", "Cotisation à un RPA"),
        P("E", "Impôt du Québec retenu"),
        P("F", "Cotisation syndicale"),
        P("G", "Salaire admissible au RRQ"),
        P("H", "Cotisation au RQAP"),
        P("I", "Salaire admissible au RQAP"),
        P("J", "Régime privé d'assurance maladie"),
        P("L", "Autres avantages"),
        P("M", "Commissions"),
        P("N", "Dons de bienfaisance"),
        P("W", "Véhicule à moteur"),
        P("235", "Cotisation à un régime privé d'assurance maladie (renseignement complémentaire)")}

    Private Shared Function P(code As String, libelle As String) As KeyValuePair(Of String, String)
        Return New KeyValuePair(Of String, String)(code, libelle)
    End Function

    Public Shared ReadOnly CodesDentaires As String() = {
        "", "1 - Aucun accès à une assurance ou à des soins dentaires", "2 - Accès : payeur seulement",
        "3 - Accès : payeur, époux ou conjoint de fait et enfants à charge", "4 - Accès : payeur et époux ou conjoint de fait",
        "5 - Accès : payeur et enfants à charge"}

    ''' <summary>Années pour lesquelles des paies confirmées existent et dont les taux sont définis.</summary>
    Public Shared Function AnneesDisponibles() As List(Of Integer)
        Dim annees As New List(Of Integer)()
        For Each r As DataRow In Db.Table("SELECT DISTINCT YEAR(DatePaie) AS Annee FROM paie.LotPaie WHERE CompagnieId = @c AND Statut = 'C' ORDER BY Annee DESC",
                                          Db.P("@c", Contexte.CompagnieId)).Rows
            If ParametresAnnee.EstDisponible(r.Ent("Annee")) Then annees.Add(r.Ent("Annee"))
        Next
        Return annees
    End Function

    Private Const FiltreAnnee As String = "l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND YEAR(l.DatePaie) = @a"

    Public Shared Function Preparer(annee As Integer) As List(Of Feuillet)
        Dim prm = ParametresAnnee.Pour(annee)
        Dim c = Contexte.CompagnieId

        ' Les colonnes ImpotQuebec et RRQ portent l'impôt provincial et le régime de pension de la
        ' province de la paie : on les sépare ici, parce que le T4 ne les met pas dans les mêmes cases.
        ' Le RQAP aussi : hors Québec, sa colonne est vide ou porte l'impôt sur la paie d'un territoire,
        ' qui n'a pas sa place dans les cases 55 et 56.
        Const SiHq As String = "SUM(CASE WHEN p.Province <> N'QC' THEN "
        Const SiQc As String = "SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE "
        Dim totaux = Db.Table(
            "SELECT p.EmployeId, SUM(p.BrutImposableFederal) BrutFed, SUM(p.ImpotFederal) ImpotFederal, SUM(p.AE) AE, " &
            "SUM(p.GainsAE) GainsAE, " & SiQc & "p.RQAP END) RQAP, " & SiQc & "p.GainsRQAP END) GainsRQAP, " &
            SiQc & "p.BrutImposableQuebec END) BrutQc, " & SiQc & "p.ImpotQuebec END) ImpotQuebec, " & SiQc & "p.AE END) AEQc, " &
            SiQc & "p.RRQ END) RRQ, " & SiQc & "p.RRQ2 END) RRQ2, " & SiQc & "p.GainsRRQ END) GainsRRQ, " &
            SiHq & "p.ImpotQuebec ELSE 0 END) ImpotProvince, " &
            SiHq & "p.RRQ ELSE 0 END) RPC, " & SiHq & "p.RRQ2 ELSE 0 END) RPC2, " & SiHq & "p.GainsRRQ ELSE 0 END) GainsRPC " &
            "FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE " & FiltreAnnee & " GROUP BY p.EmployeId", Db.P("@c", c), Db.P("@a", annee))
        Dim provincesPayees = Db.Table(
            "SELECT DISTINCT p.EmployeId, p.Province FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE " & FiltreAnnee,
            Db.P("@c", c), Db.P("@a", annee))
        Dim provinceCompagnie = Provinces.Code(Contexte.Province)
        Dim lignes = Db.Table(
            "SELECT p.EmployeId, p.Province, pl.CategorieCode, SUM(pl.Montant) AS Montant FROM paie.PaieLigne pl JOIN paie.Paie p ON p.Id = pl.PaieId " &
            "JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE " & FiltreAnnee & " GROUP BY p.EmployeId, p.Province, pl.CategorieCode", Db.P("@c", c), Db.P("@a", annee))
        Dim departs = Db.Table(
            "SELECT d.* FROM paie.CumulatifDepart d JOIN paie.Employe e ON e.Id = d.EmployeId WHERE e.CompagnieId = @c AND d.Annee = @a", Db.P("@c", c), Db.P("@a", annee))
        Dim employes = Db.Table("SELECT * FROM paie.Employe WHERE CompagnieId = @c ORDER BY Nom, Prenom", Db.P("@c", c))

        Dim feuillets As New List(Of Feuillet)()
        For Each e As DataRow In employes.Rows
            Dim id = e.Ent("Id")
            Dim t = totaux.Select("EmployeId = " & id.ToString())
            Dim d = departs.Select("EmployeId = " & id.ToString())
            If t.Length = 0 AndAlso d.Length = 0 Then Continue For

            Dim f As New Feuillet With {.Employe = e, .ContientCumulatifsDepart = d.Length > 0, .Province = provinceCompagnie}
            Dim brutFed, brutQc, impotFed, impotQc, impotProv, rrq, rrq2, rpc, rpc2, ae, aeQc, rqap, gainsRRQ, gainsRPC, gainsAE, gainsRQAP As Decimal
            ' Les provinces de l'année : celles des paies, plus celle des cumulatifs de départ.
            Dim provs As New SortedSet(Of String)(StringComparer.Ordinal)
            For Each pp In provincesPayees.Select("EmployeId = " & id.ToString())
                provs.Add(If(pp.Txt("Province").Length = 0, "QC", pp.Txt("Province")))
            Next
            If d.Length > 0 Then provs.Add(If(d(0).Txt("Province").Length = 0, "QC", d(0).Txt("Province")))
            f.ProvincesEmploi.AddRange(provs)
            f.DeuxProvinces = provs.Count > 1
            If provs.Count = 1 Then f.Province = provs.Min
            Dim aDesPaiesQuebec = provs.Contains("QC")
            If t.Length > 0 Then
                brutFed = t(0).Dcm("BrutFed") : brutQc = t(0).Dcm("BrutQc") : impotFed = t(0).Dcm("ImpotFederal") : impotQc = t(0).Dcm("ImpotQuebec")
                rrq = t(0).Dcm("RRQ") : rrq2 = t(0).Dcm("RRQ2") : ae = t(0).Dcm("AE") : rqap = t(0).Dcm("RQAP")
                gainsRRQ = t(0).Dcm("GainsRRQ") : gainsAE = t(0).Dcm("GainsAE") : gainsRQAP = t(0).Dcm("GainsRQAP")
                impotProv = t(0).Dcm("ImpotProvince") : rpc = t(0).Dcm("RPC") : rpc2 = t(0).Dcm("RPC2") : gainsRPC = t(0).Dcm("GainsRPC")
                aeQc = t(0).Dcm("AEQc")
            End If
            If d.Length > 0 Then
                ' Les cumulatifs de départ ne détaillent pas les gains assurables : la rémunération brute est utilisée.
                ' Ils appartiennent à la province pour laquelle ils ont été saisis (paie.CumulatifDepart.Province).
                Dim brutDepart = d(0).Dcm("Brut")
                brutFed += brutDepart : impotFed += d(0).Dcm("ImpotFederal") : ae += d(0).Dcm("AE")
                If Not e.Bln("ExemptAE") Then gainsAE += brutDepart
                Dim gainsPensionDepart = If(d(0).Dcm("GainsRRQ") > 0D, d(0).Dcm("GainsRRQ"), brutDepart)
                If d(0).Txt("Province").Length > 0 AndAlso d(0).Txt("Province") <> "QC" Then
                    ' Hors Québec. (Le « RQAP » de départ d'un territoire est son impôt sur la paie : il ne va dans aucune case.)
                    impotProv += d(0).Dcm("ImpotQuebec") : rpc += d(0).Dcm("RRQ") : rpc2 += d(0).Dcm("RRQ2")
                    gainsRPC += gainsPensionDepart
                Else
                    aeQc += d(0).Dcm("AE")
                    brutQc += brutDepart : impotQc += d(0).Dcm("ImpotQuebec")
                    rrq += d(0).Dcm("RRQ") : rrq2 += d(0).Dcm("RRQ2") : rqap += d(0).Dcm("RQAP")
                    gainsRRQ += gainsPensionDepart
                    If Not e.Bln("ExemptRQAP") Then gainsRQAP += brutDepart
                End If
            End If
            f.AvecReleve1 = aDesPaiesQuebec

            ' Case 22 : tout l'impôt remis à l'ARC — le fédéral et, hors Québec, celui de la province.
            f.T4("14") = brutFed : f.T4("16") = rpc : f.T4("16A") = rpc2 : f.T4("17") = rrq : f.T4("17A") = rrq2
            f.T4("18") = ae : f.T4("22") = impotFed + impotProv
            f.T4("24") = Math.Min(gainsAE, prm.AEMaxAssurable)
            f.T4("26") = Math.Min(gainsRRQ + gainsRPC, If(gainsRPC > 0D AndAlso prm.RPC2MaxSupplementaire > 0D, prm.RPC2MaxSupplementaire, prm.RRQ2MaxSupplementaire))
            f.T4("55") = rqap
            f.T4("56") = Math.Min(gainsRQAP, prm.RQAPMaxAssurable)

            If f.AvecReleve1 Then
                ' Le Relevé 1 ne porte que l'emploi au Québec : l'AE retenue sur des paies d'une autre province n'y figure pas.
                f.R1("A") = brutQc : f.R1("B.A") = rrq : f.R1("B.B") = rrq2 : f.R1("C") = aeQc : f.R1("E") = impotQc
                f.R1("G") = Math.Min(gainsRRQ, prm.RRQ2MaxSupplementaire)
                f.R1("H") = rqap
                f.R1("I") = Math.Min(gainsRQAP, prm.RQAPMaxAssurable)
            End If

            ' Cases particulières, selon la catégorie système de chaque ligne de paie.
            For Each l In lignes.Select("EmployeId = " & id.ToString())
                If Not CategoriePaie.Existe(l.Txt("CategorieCode")) Then Continue For
                Dim cat = CategoriePaie.ParCode(l.Txt("CategorieCode"))
                Ajouter(f.T4, cat.CaseT4, "14", l.Dcm("Montant"))
                If f.AvecReleve1 AndAlso l.Txt("Province") = "QC" Then Ajouter(f.R1, cat.CaseR1, "A", l.Dcm("Montant"))
            Next
            feuillets.Add(f)
        Next
        Return feuillets
    End Function

    ''' <summary>« 14 &amp; 40 » : la ligne s'ajoute à la case 40 (la case principale est déjà calculée à partir des totaux).</summary>
    Private Shared Sub Ajouter(cases As Dictionary(Of String, Decimal), codes As String, casePrincipale As String, montant As Decimal)
        If String.IsNullOrEmpty(codes) Then Return
        For Each code In codes.Split("&"c)
            Dim c = code.Trim()
            If c.Length = 0 OrElse c = casePrincipale Then Continue For
            If c = "B" Then c = "B.A"
            Dim actuel As Decimal
            cases.TryGetValue(c, actuel)
            cases(c) = actuel + montant
        Next
    End Sub

    ''' <summary>Case 28 du T4 : exemptions RPC/RRQ, AE et RPAP (le RPAP ne concerne que le Québec).</summary>
    Public Shared Function Exemptions(e As DataRow, Optional province As String = "QC") As String
        Dim x As New List(Of String)()
        If e.Bln("ExemptRRQ") Then x.Add("RPC/RRQ")
        If e.Bln("ExemptAE") Then x.Add("AE")
        If e.Bln("ExemptRQAP") AndAlso province = "QC" Then x.Add("RPAP")
        Return If(x.Count = 0, "Aucune", String.Join(", ", x))
    End Function

    ''' <summary>
    ''' Sommaire de l'année : parts de l'employeur et conciliation avec les remises enregistrées.
    ''' Les colonnes partagées sont séparées : RRQ, FSS et CNESST pour les paies du Québec ; RPC pour celles
    ''' des autres provinces. La cotisation santé de l'employeur et la commission des accidents du travail
    ''' hors Québec se lisent par province dans ServiceRemise.HorsRemiseProvinces.
    ''' </summary>
    Public Shared Function SommaireEmployeur(annee As Integer) As DataRow
        Const SiHq As String = "ISNULL(SUM(CASE WHEN p.Province <> N'QC' THEN "
        Const SiQc As String = "ISNULL(SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE "
        Return Db.Ligne(
            "SELECT " & SiQc & "p.EmployeurRRQ + p.EmployeurRRQ2 END),0) EmployeurRRQ, ISNULL(SUM(p.EmployeurAE),0) EmployeurAE, ISNULL(SUM(p.EmployeurRQAP),0) EmployeurRQAP, " &
            SiQc & "p.EmployeurFSS END),0) FSS, " & SiQc & "p.GainsFSS END),0) MasseFSS, " & SiQc & "p.EmployeurCNESST END),0) CNESST, ISNULL(SUM(p.EmployeurCNT),0) CNT, " &
            SiHq & "p.EmployeurRRQ + p.EmployeurRRQ2 ELSE 0 END),0) EmployeurRPC, " &
            "ISNULL(SUM(" & ServiceRemise.SqlDuFederal & "),0) DuFederal, " &
            "ISNULL(SUM(" & ServiceRemise.SqlDuQuebec & "),0) DuQuebec, " &
            "(SELECT ISNULL(SUM(Total),0) FROM paie.Remise WHERE CompagnieId = @c AND Statut = 'P' AND Gouvernement = 'F' AND YEAR(DateFinPeriode) = @a) PayeFederal, " &
            "(SELECT ISNULL(SUM(Total),0) FROM paie.Remise WHERE CompagnieId = @c AND Statut = 'P' AND Gouvernement = 'Q' AND YEAR(DateFinPeriode) = @a) PayeQuebec " &
            "FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE " & FiltreAnnee, Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee))
    End Function

End Class
