Imports System.Data.SqlClient
Imports Paie60Sec.Calcul

Public Class LigneGL
    Public Property Compte As String
    Public Property Libelle As String
    Public Property Debit As Decimal
    Public Property Credit As Decimal
End Class

Public Class CleGL
    Public Property Cle As String
    Public Property Libelle As String
    Public Property Groupe As String
End Class

''' <summary>
''' Écritures comptables de la paie. Les comptes se définissent dans Configuration → Plan comptable ;
''' chaque élément de paie peut avoir son propre compte, sinon le compte par défaut s'applique.
''' </summary>
Public NotInheritable Class ServiceGL

    Private Sub New()
    End Sub

    Public Shared ReadOnly Cles As CleGL() = {
        C("BANQUE", "Compte de banque (paies nettes)", "Actif et passif"),
        C("VACANCES_A_PAYER", "Vacances à payer", "Actif et passif"),
        C("IMPOT_FED_A_PAYER", "Impôt fédéral à payer", "Actif et passif"),
        C("IMPOT_QC_A_PAYER", "Impôt du Québec à payer", "Actif et passif"),
        C("RRQ_A_PAYER", "RRQ à payer (employés et employeur)", "Actif et passif"),
        C("AE_A_PAYER", "Assurance-emploi à payer (employés et employeur)", "Actif et passif"),
        C("RQAP_A_PAYER", "RQAP à payer (employés et employeur)", "Actif et passif"),
        C("FSS_A_PAYER", "FSS à payer", "Actif et passif"),
        C("CNESST_A_PAYER", "CNESST à payer", "Actif et passif"),
        C("CNT_A_PAYER", "Normes du travail (CNT) à payer", "Actif et passif"),
        C("DED_AUTRES_A_PAYER", "Autres déductions à payer (par défaut)", "Actif et passif"),
        C("DEP_SALAIRES", "Salaires (par défaut des éléments de paie)", "Dépenses"),
        C("DEP_VACANCES", "Dépense de vacances", "Dépenses"),
        C("DEP_RRQ", "Dépense - part de l'employeur au RRQ", "Dépenses"),
        C("DEP_AE", "Dépense - part de l'employeur à l'assurance-emploi", "Dépenses"),
        C("DEP_RQAP", "Dépense - part de l'employeur au RQAP", "Dépenses"),
        C("DEP_FSS", "Dépense - FSS", "Dépenses"),
        C("DEP_CNESST", "Dépense - CNESST", "Dépenses"),
        C("DEP_CNT", "Dépense - normes du travail (CNT)", "Dépenses")}

    Private Shared Function C(cle As String, libelle As String, groupe As String) As CleGL
        Return New CleGL With {.Cle = cle, .Libelle = libelle, .Groupe = groupe}
    End Function

    Public Shared Function Comptes() As Dictionary(Of String, String)
        Dim d As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
        For Each r As DataRow In Db.Table("SELECT Cle, Compte FROM dbo.CompteGL WHERE CompagnieId = @c", Db.P("@c", Contexte.CompagnieId)).Rows
            d(r.Txt("Cle")) = r.Txt("Compte")
        Next
        Return d
    End Function

    Public Shared Sub EnregistrerCompte(cle As String, compte As String)
        If Not Cles.Any(Function(k) k.Cle = cle) Then Throw New SaisieInvalideException("Clé de compte invalide.")
        Db.Exec("DELETE FROM dbo.CompteGL WHERE CompagnieId = @c AND Cle = @k", Db.P("@c", Contexte.CompagnieId), Db.P("@k", cle))
        If Not String.IsNullOrWhiteSpace(compte) Then
            Db.Exec("INSERT INTO dbo.CompteGL (CompagnieId, Cle, Compte) VALUES (@c, @k, @v)", Db.P("@c", Contexte.CompagnieId), Db.P("@k", cle), Db.P("@v", compte.Trim()))
        End If
    End Sub

    Public Shared Function EcrituresDuLot(lotId As Integer) As List(Of LigneGL)
        Return Ecritures("l.Id = @lot AND l.Statut <> 'A'", Function() {Db.P("@c", Contexte.CompagnieId), Db.P("@lot", lotId)})
    End Function

    Public Shared Function EcrituresDeLaPeriode(du As Date, au As Date) As List(Of LigneGL)
        Return Ecritures("l.Statut = 'C' AND l.DatePaie BETWEEN @du AND @au", Function() {Db.P("@c", Contexte.CompagnieId), Db.P("@du", du), Db.P("@au", au)})
    End Function

    ''' <summary>Écriture équilibrée : dépenses au débit ; retenues, cotisations à payer et paies nettes au crédit.</summary>
    Private Shared Function Ecritures(filtre As String, prms As Func(Of SqlParameter())) As List(Of LigneGL)
        Dim portee = "FROM dbo.Paie p JOIN dbo.LotPaie l ON l.Id = p.LotPaieId WHERE l.CompagnieId = @c AND p.Inclus = 1 AND " & filtre
        Dim t = Db.Ligne(
            "SELECT ISNULL(SUM(p.ImpotFederal),0) ImpotFederal, ISNULL(SUM(p.ImpotQuebec),0) ImpotQuebec, ISNULL(SUM(p.RRQ + p.RRQ2),0) RRQ, ISNULL(SUM(p.AE),0) AE, " &
            "ISNULL(SUM(p.RQAP),0) RQAP, ISNULL(SUM(p.Net),0) Net, ISNULL(SUM(p.EmployeurRRQ + p.EmployeurRRQ2),0) ERRQ, ISNULL(SUM(p.EmployeurAE),0) EAE, " &
            "ISNULL(SUM(p.EmployeurRQAP),0) ERQAP, ISNULL(SUM(p.EmployeurFSS),0) FSS, ISNULL(SUM(p.EmployeurCNESST),0) CNESST, ISNULL(SUM(p.EmployeurCNT),0) CNT, " &
            "ISNULL(SUM(p.VacancesAccumulees),0) Vacances " & portee, prms())
        Dim lignesPaie = Db.Table(
            "SELECT el.Description, el.CompteGL, pl.CategorieCode, SUM(pl.Montant) AS Montant FROM dbo.PaieLigne pl JOIN dbo.ElementPaie el ON el.Id = pl.ElementPaieId " &
            "JOIN dbo.Paie p ON p.Id = pl.PaieId JOIN dbo.LotPaie l ON l.Id = p.LotPaieId WHERE l.CompagnieId = @c AND p.Inclus = 1 AND " & filtre &
            " GROUP BY el.Description, el.CompteGL, pl.CategorieCode ORDER BY el.Description", prms())

        Dim cpt = Comptes()
        Dim debits As New List(Of LigneGL)()
        Dim credits As New List(Of LigneGL)()

        For Each l As DataRow In lignesPaie.Rows
            If Not CategoriePaie.Existe(l.Txt("CategorieCode")) Then Continue For
            Dim cat = CategoriePaie.ParCode(l.Txt("CategorieCode"))
            Dim propre = l.Txt("CompteGL")
            If cat.Type = TypeCategorie.Deduction Then
                credits.Add(Ligne(If(propre.Length > 0, propre, Compte(cpt, "DED_AUTRES_A_PAYER")), l.Txt("Description") & " à payer", 0D, l.Dcm("Montant")))
            ElseIf cat.Type = TypeCategorie.Avantage AndAlso Not cat.VerseEnArgent Then
                ' Avantage non monétaire : imposé mais non versé, aucune écriture de paie.
            ElseIf cat.PaieVacances Then
                debits.Add(Ligne(Compte(cpt, "VACANCES_A_PAYER"), l.Txt("Description") & " (vacances déjà provisionnées)", l.Dcm("Montant"), 0D))
            Else
                debits.Add(Ligne(If(propre.Length > 0, propre, Compte(cpt, "DEP_SALAIRES")), l.Txt("Description"), l.Dcm("Montant"), 0D))
            End If
        Next

        debits.Add(Ligne(Compte(cpt, "DEP_VACANCES"), "Vacances accumulées", t.Dcm("Vacances"), 0D))
        debits.Add(Ligne(Compte(cpt, "DEP_RRQ"), "RRQ - part de l'employeur", t.Dcm("ERRQ"), 0D))
        debits.Add(Ligne(Compte(cpt, "DEP_AE"), "Assurance-emploi - part de l'employeur", t.Dcm("EAE"), 0D))
        debits.Add(Ligne(Compte(cpt, "DEP_RQAP"), "RQAP - part de l'employeur", t.Dcm("ERQAP"), 0D))
        debits.Add(Ligne(Compte(cpt, "DEP_FSS"), "Fonds des services de santé", t.Dcm("FSS"), 0D))
        debits.Add(Ligne(Compte(cpt, "DEP_CNESST"), "CNESST", t.Dcm("CNESST"), 0D))
        debits.Add(Ligne(Compte(cpt, "DEP_CNT"), "Normes du travail (CNT)", t.Dcm("CNT"), 0D))

        credits.Add(Ligne(Compte(cpt, "IMPOT_FED_A_PAYER"), "Impôt fédéral à payer", 0D, t.Dcm("ImpotFederal")))
        credits.Add(Ligne(Compte(cpt, "IMPOT_QC_A_PAYER"), "Impôt du Québec à payer", 0D, t.Dcm("ImpotQuebec")))
        credits.Add(Ligne(Compte(cpt, "RRQ_A_PAYER"), "RRQ à payer", 0D, t.Dcm("RRQ") + t.Dcm("ERRQ")))
        credits.Add(Ligne(Compte(cpt, "AE_A_PAYER"), "Assurance-emploi à payer", 0D, t.Dcm("AE") + t.Dcm("EAE")))
        credits.Add(Ligne(Compte(cpt, "RQAP_A_PAYER"), "RQAP à payer", 0D, t.Dcm("RQAP") + t.Dcm("ERQAP")))
        credits.Add(Ligne(Compte(cpt, "FSS_A_PAYER"), "FSS à payer", 0D, t.Dcm("FSS")))
        credits.Add(Ligne(Compte(cpt, "CNESST_A_PAYER"), "CNESST à payer", 0D, t.Dcm("CNESST")))
        credits.Add(Ligne(Compte(cpt, "CNT_A_PAYER"), "CNT à payer", 0D, t.Dcm("CNT")))
        credits.Add(Ligne(Compte(cpt, "VACANCES_A_PAYER"), "Vacances à payer", 0D, t.Dcm("Vacances")))
        credits.Add(Ligne(Compte(cpt, "BANQUE"), "Paies nettes", 0D, t.Dcm("Net")))

        Return debits.Concat(credits).Where(Function(x) x.Debit <> 0D OrElse x.Credit <> 0D).ToList()
    End Function

    Private Shared Function Compte(comptes As Dictionary(Of String, String), cle As String) As String
        Dim v As String = Nothing
        Return If(comptes.TryGetValue(cle, v) AndAlso v.Length > 0, v, "")
    End Function

    Private Shared Function Ligne(compte As String, libelle As String, debit As Decimal, credit As Decimal) As LigneGL
        Return New LigneGL With {.Compte = compte, .Libelle = libelle, .Debit = debit, .Credit = credit}
    End Function

End Class

''' <summary>Déclaration annuelle des salaires à la CNESST.</summary>
Public NotInheritable Class ServiceCNESST

    Private Sub New()
    End Sub

    Private Const Filtre As String = "l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND YEAR(l.DatePaie) = @a"

    ''' <summary>Par employé : salaire brut, excédent du maximum assurable, salaire assurable et cotisation calculée.</summary>
    Public Shared Function ParEmploye(annee As Integer) As DataTable
        Dim t = Db.Table(
            "SELECT e.Id, e.Nom, e.Prenom, e.ExemptCNESST, SUM(p.GainsCNESST) AS Assurable, SUM(p.EmployeurCNESST) AS Cotisation, " &
            "CAST(0 AS decimal(14,2)) AS Brut, CAST(0 AS decimal(14,2)) AS Excedent " &
            "FROM dbo.Paie p JOIN dbo.LotPaie l ON l.Id = p.LotPaieId JOIN dbo.Employe e ON e.Id = p.EmployeId WHERE " & Filtre &
            " GROUP BY e.Id, e.Nom, e.Prenom, e.ExemptCNESST ORDER BY e.Nom, e.Prenom", Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee))
        Dim lignes = Db.Table(
            "SELECT p.EmployeId, pl.CategorieCode, SUM(pl.Montant) AS Montant FROM dbo.PaieLigne pl JOIN dbo.Paie p ON p.Id = pl.PaieId " &
            "JOIN dbo.LotPaie l ON l.Id = p.LotPaieId WHERE " & Filtre & " GROUP BY p.EmployeId, pl.CategorieCode", Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee))

        t.Columns("Brut").ReadOnly = False
        t.Columns("Excedent").ReadOnly = False
        For Each e As DataRow In t.Rows
            Dim brut As Decimal = 0D
            For Each l In lignes.Select("EmployeId = " & e.Ent("Id").ToString())
                If CategoriePaie.Existe(l.Txt("CategorieCode")) AndAlso CategoriePaie.ParCode(l.Txt("CategorieCode")).CNESST Then brut += l.Dcm("Montant")
            Next
            e("Brut") = brut
            e("Excedent") = If(e.Bln("ExemptCNESST"), 0D, Math.Max(0D, brut - e.Dcm("Assurable")))
        Next
        Return t
    End Function

    Public Shared Function ParMois(annee As Integer) As DataTable
        Return Db.Table(
            "SELECT MONTH(l.DatePaie) AS Mois, SUM(p.GainsCNESST) AS Assurable, SUM(p.EmployeurCNESST) AS Cotisation " &
            "FROM dbo.Paie p JOIN dbo.LotPaie l ON l.Id = p.LotPaieId WHERE " & Filtre & " GROUP BY MONTH(l.DatePaie) ORDER BY Mois",
            Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee))
    End Function

    ''' <summary>Versements périodiques à la CNESST compris dans les remises à Revenu Québec enregistrées pour l'année.</summary>
    Public Shared Function VersementsPayes(annee As Integer) As Decimal
        Return Convert.ToDecimal(Db.Scalaire(
            "SELECT ISNULL(SUM(rl.Montant), 0) FROM dbo.RemiseLigne rl JOIN dbo.Remise r ON r.Id = rl.RemiseId " &
            "WHERE r.CompagnieId = @c AND r.Statut = 'P' AND rl.Code = 'CNESST' AND YEAR(r.DateFinPeriode) = @a", Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee)))
    End Function

End Class
