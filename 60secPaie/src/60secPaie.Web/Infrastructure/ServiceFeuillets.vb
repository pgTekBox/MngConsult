Imports Paie60Sec.Calcul

''' <summary>Montants des cases du T4 et du Relevé 1 d'un employé pour une année.</summary>
Public Class Feuillet
    Public Property Employe As DataRow
    Public Property T4 As New Dictionary(Of String, Decimal)()
    Public Property R1 As New Dictionary(Of String, Decimal)()
    Public Property ContientCumulatifsDepart As Boolean

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
''' </summary>
Public NotInheritable Class ServiceFeuillets

    Private Sub New()
    End Sub

    ''' <summary>Cases du T4, dans l'ordre d'affichage.</summary>
    Public Shared ReadOnly LibellesT4 As KeyValuePair(Of String, String)() = {
        P("14", "Revenus d'emploi"),
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

        Dim totaux = Db.Table(
            "SELECT p.EmployeId, SUM(p.BrutImposableFederal) BrutFed, SUM(p.BrutImposableQuebec) BrutQc, SUM(p.ImpotFederal) ImpotFederal, " &
            "SUM(p.ImpotQuebec) ImpotQuebec, SUM(p.RRQ) RRQ, SUM(p.RRQ2) RRQ2, SUM(p.AE) AE, SUM(p.RQAP) RQAP, " &
            "SUM(p.GainsRRQ) GainsRRQ, SUM(p.GainsAE) GainsAE, SUM(p.GainsRQAP) GainsRQAP " &
            "FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE " & FiltreAnnee & " GROUP BY p.EmployeId", Db.P("@c", c), Db.P("@a", annee))
        Dim lignes = Db.Table(
            "SELECT p.EmployeId, pl.CategorieCode, SUM(pl.Montant) AS Montant FROM paie.PaieLigne pl JOIN paie.Paie p ON p.Id = pl.PaieId " &
            "JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE " & FiltreAnnee & " GROUP BY p.EmployeId, pl.CategorieCode", Db.P("@c", c), Db.P("@a", annee))
        Dim departs = Db.Table(
            "SELECT d.* FROM paie.CumulatifDepart d JOIN paie.Employe e ON e.Id = d.EmployeId WHERE e.CompagnieId = @c AND d.Annee = @a", Db.P("@c", c), Db.P("@a", annee))
        Dim employes = Db.Table("SELECT * FROM paie.Employe WHERE CompagnieId = @c ORDER BY Nom, Prenom", Db.P("@c", c))

        Dim feuillets As New List(Of Feuillet)()
        For Each e As DataRow In employes.Rows
            Dim id = e.Ent("Id")
            Dim t = totaux.Select("EmployeId = " & id.ToString())
            Dim d = departs.Select("EmployeId = " & id.ToString())
            If t.Length = 0 AndAlso d.Length = 0 Then Continue For

            Dim f As New Feuillet With {.Employe = e, .ContientCumulatifsDepart = d.Length > 0}
            Dim brutFed, brutQc, impotFed, impotQc, rrq, rrq2, ae, rqap, gainsRRQ, gainsAE, gainsRQAP As Decimal
            If t.Length > 0 Then
                brutFed = t(0).Dcm("BrutFed") : brutQc = t(0).Dcm("BrutQc") : impotFed = t(0).Dcm("ImpotFederal") : impotQc = t(0).Dcm("ImpotQuebec")
                rrq = t(0).Dcm("RRQ") : rrq2 = t(0).Dcm("RRQ2") : ae = t(0).Dcm("AE") : rqap = t(0).Dcm("RQAP")
                gainsRRQ = t(0).Dcm("GainsRRQ") : gainsAE = t(0).Dcm("GainsAE") : gainsRQAP = t(0).Dcm("GainsRQAP")
            End If
            If d.Length > 0 Then
                ' Les cumulatifs de départ ne détaillent pas les gains assurables : la rémunération brute est utilisée.
                Dim brutDepart = d(0).Dcm("Brut")
                brutFed += brutDepart : brutQc += brutDepart : impotFed += d(0).Dcm("ImpotFederal") : impotQc += d(0).Dcm("ImpotQuebec")
                rrq += d(0).Dcm("RRQ") : rrq2 += d(0).Dcm("RRQ2") : ae += d(0).Dcm("AE") : rqap += d(0).Dcm("RQAP")
                gainsRRQ += If(d(0).Dcm("GainsRRQ") > 0D, d(0).Dcm("GainsRRQ"), brutDepart)
                If Not e.Bln("ExemptAE") Then gainsAE += brutDepart
                If Not e.Bln("ExemptRQAP") Then gainsRQAP += brutDepart
            End If

            f.T4("14") = brutFed : f.T4("17") = rrq : f.T4("17A") = rrq2 : f.T4("18") = ae : f.T4("22") = impotFed
            f.T4("24") = Math.Min(gainsAE, prm.AEMaxAssurable)
            f.T4("26") = Math.Min(gainsRRQ, prm.RRQ2MaxSupplementaire)
            f.T4("55") = rqap
            f.T4("56") = Math.Min(gainsRQAP, prm.RQAPMaxAssurable)

            f.R1("A") = brutQc : f.R1("B.A") = rrq : f.R1("B.B") = rrq2 : f.R1("C") = ae : f.R1("E") = impotQc
            f.R1("G") = Math.Min(gainsRRQ, prm.RRQ2MaxSupplementaire)
            f.R1("H") = rqap
            f.R1("I") = Math.Min(gainsRQAP, prm.RQAPMaxAssurable)

            ' Cases particulières, selon la catégorie système de chaque ligne de paie.
            For Each l In lignes.Select("EmployeId = " & id.ToString())
                If Not CategoriePaie.Existe(l.Txt("CategorieCode")) Then Continue For
                Dim cat = CategoriePaie.ParCode(l.Txt("CategorieCode"))
                Ajouter(f.T4, cat.CaseT4, "14", l.Dcm("Montant"))
                Ajouter(f.R1, cat.CaseR1, "A", l.Dcm("Montant"))
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

    ''' <summary>Case 28 du T4 : exemptions RPC/RRQ, AE et RPAP.</summary>
    Public Shared Function Exemptions(e As DataRow) As String
        Dim x As New List(Of String)()
        If e.Bln("ExemptRRQ") Then x.Add("RPC/RRQ")
        If e.Bln("ExemptAE") Then x.Add("AE")
        If e.Bln("ExemptRQAP") Then x.Add("RPAP")
        Return If(x.Count = 0, "Aucune", String.Join(", ", x))
    End Function

    ''' <summary>Sommaire de l'année : parts de l'employeur et conciliation avec les remises enregistrées.</summary>
    Public Shared Function SommaireEmployeur(annee As Integer) As DataRow
        Return Db.Ligne(
            "SELECT ISNULL(SUM(p.EmployeurRRQ + p.EmployeurRRQ2),0) EmployeurRRQ, ISNULL(SUM(p.EmployeurAE),0) EmployeurAE, ISNULL(SUM(p.EmployeurRQAP),0) EmployeurRQAP, " &
            "ISNULL(SUM(p.EmployeurFSS),0) FSS, ISNULL(SUM(p.GainsFSS),0) MasseFSS, ISNULL(SUM(p.EmployeurCNESST),0) CNESST, ISNULL(SUM(p.EmployeurCNT),0) CNT, " &
            "ISNULL(SUM(p.ImpotFederal + p.AE + p.EmployeurAE),0) DuFederal, " &
            "ISNULL(SUM(p.ImpotQuebec + p.RRQ + p.RRQ2 + p.EmployeurRRQ + p.EmployeurRRQ2 + p.RQAP + p.EmployeurRQAP + p.EmployeurFSS + p.EmployeurCNESST),0) DuQuebec, " &
            "(SELECT ISNULL(SUM(Total),0) FROM paie.Remise WHERE CompagnieId = @c AND Statut = 'P' AND Gouvernement = 'F' AND YEAR(DateFinPeriode) = @a) PayeFederal, " &
            "(SELECT ISNULL(SUM(Total),0) FROM paie.Remise WHERE CompagnieId = @c AND Statut = 'P' AND Gouvernement = 'Q' AND YEAR(DateFinPeriode) = @a) PayeQuebec " &
            "FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE " & FiltreAnnee, Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee))
    End Function

End Class
