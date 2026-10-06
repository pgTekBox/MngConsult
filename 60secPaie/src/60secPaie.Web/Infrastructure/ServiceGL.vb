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

    ' Hors Québec, les mêmes clés désignent l'équivalent de la province : le plan comptable d'une compagnie
    ' ne change pas de structure, seulement de vocabulaire. Le RQAP et la CNT n'y existent pas ; le compte
    ' du RQAP à payer reçoit, dans un territoire, l'impôt sur la paie retenu aux employés.
    Private Shared Function LibelleHorsQuebec(cle As String, noms As LibellesProvince) As String
        Select Case cle
            Case "IMPOT_QC_A_PAYER" : Return noms.ImpotProvincial & " à payer"
            Case "RRQ_A_PAYER" : Return "RPC à payer (employés et employeur)"
            Case "RQAP_A_PAYER" : Return noms.RetenueProvinciale & " à payer"
            Case "FSS_A_PAYER" : Return noms.Sante & " à payer"
            Case "CNESST_A_PAYER" : Return noms.Accidents & " à payer"
            Case "DEP_RRQ" : Return "Dépense - part de l'employeur au RPC"
            Case "DEP_FSS" : Return "Dépense - " & noms.SanteLong
            Case "DEP_CNESST" : Return "Dépense - " & noms.Accidents
            Case Else : Return Nothing
        End Select
    End Function

    ''' <summary>Les clés du plan comptable telles qu'elles se présentent dans la province de la compagnie courante.</summary>
    Public Shared Function ClesAffichees() As List(Of CleGL)
        If Not Contexte.HorsQuebec Then Return Cles.ToList()
        Dim noms = Contexte.Libelles
        Dim absentes As New List(Of String) From {"CNT_A_PAYER", "DEP_RQAP", "DEP_CNT"}
        If Not noms.ARetenueTerritoriale Then absentes.Add("RQAP_A_PAYER")
        If Not noms.ASante Then absentes.AddRange({"FSS_A_PAYER", "DEP_FSS"})
        Dim liste As New List(Of CleGL)()
        For Each k In Cles
            If absentes.Contains(k.Cle) Then Continue For
            liste.Add(C(k.Cle, If(LibelleHorsQuebec(k.Cle, noms), k.Libelle), k.Groupe))
        Next
        Return liste
    End Function

    Public Shared Function Comptes() As Dictionary(Of String, String)
        Dim d As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
        For Each r As DataRow In Db.Table("paie.spCompteGL_Liste", Db.P("@c", Contexte.CompagnieId)).Rows
            d(r.Txt("Cle")) = r.Txt("Compte")
        Next
        Return d
    End Function

    Public Shared Sub EnregistrerCompte(cle As String, compte As String)
        If Not Cles.Any(Function(k) k.Cle = cle) Then Throw New SaisieInvalideException("Clé de compte invalide.")
        Db.Exec("paie.spCompteGL_Supprimer", Db.P("@c", Contexte.CompagnieId), Db.P("@k", cle))
        If Not String.IsNullOrWhiteSpace(compte) Then
            Db.Exec("paie.spCompteGL_Inserer", Db.P("@c", Contexte.CompagnieId), Db.P("@k", cle), Db.P("@v", compte.Trim()))
        End If
    End Sub

    Public Shared Function EcrituresDuLot(lotId As Integer) As List(Of LigneGL)
        Return Ecritures(Function() {Db.P("@c", Contexte.CompagnieId), Db.P("@lot", lotId)})
    End Function

    Public Shared Function EcrituresDeLaPeriode(du As Date, au As Date) As List(Of LigneGL)
        Return Ecritures(Function() {Db.P("@c", Contexte.CompagnieId), Db.P("@du", du), Db.P("@au", au)})
    End Function

    ''' <summary>
    ''' Écriture équilibrée : dépenses au débit ; retenues, cotisations à payer et paies nettes au crédit.
    ''' Les paies visées sont celles du lot (@lot, non annulé) ou de la période (@du..@au, confirmées) : procédures paie.spGL_Totaux et paie.spGL_Lignes.
    ''' </summary>
    Private Shared Function Ecritures(prms As Func(Of SqlParameter())) As List(Of LigneGL)
        Dim t = Db.Ligne("paie.spGL_Totaux", prms())
        Dim lignesPaie = Db.Table("paie.spGL_Lignes", prms())

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

        ' Les libellés suivent la province de la compagnie : les mêmes comptes reçoivent le RRQ ou le RPC, le FSS ou l'ISE…
        Dim noms = Contexte.Libelles
        debits.Add(Ligne(Compte(cpt, "DEP_VACANCES"), "Vacances accumulées", t.Dcm("Vacances"), 0D))
        debits.Add(Ligne(Compte(cpt, "DEP_RRQ"), noms.Pension & " - part de l'employeur", t.Dcm("ERRQ"), 0D))
        debits.Add(Ligne(Compte(cpt, "DEP_AE"), "Assurance-emploi - part de l'employeur", t.Dcm("EAE"), 0D))
        debits.Add(Ligne(Compte(cpt, "DEP_RQAP"), "RQAP - part de l'employeur", t.Dcm("ERQAP"), 0D))
        debits.Add(Ligne(Compte(cpt, "DEP_FSS"), If(Contexte.HorsQuebec, noms.SanteLong, "Fonds des services de santé"), t.Dcm("FSS"), 0D))
        debits.Add(Ligne(Compte(cpt, "DEP_CNESST"), noms.Accidents, t.Dcm("CNESST"), 0D))
        debits.Add(Ligne(Compte(cpt, "DEP_CNT"), "Normes du travail (CNT)", t.Dcm("CNT"), 0D))

        credits.Add(Ligne(Compte(cpt, "IMPOT_FED_A_PAYER"), "Impôt fédéral à payer", 0D, t.Dcm("ImpotFederal")))
        credits.Add(Ligne(Compte(cpt, "IMPOT_QC_A_PAYER"), noms.ImpotProvincial & " à payer", 0D, t.Dcm("ImpotQuebec")))
        credits.Add(Ligne(Compte(cpt, "RRQ_A_PAYER"), noms.Pension & " à payer", 0D, t.Dcm("RRQ") + t.Dcm("ERRQ")))
        credits.Add(Ligne(Compte(cpt, "AE_A_PAYER"), "Assurance-emploi à payer", 0D, t.Dcm("AE") + t.Dcm("EAE")))
        ' Dans un territoire, la colonne du RQAP porte l'impôt sur la paie retenu aux employés.
        credits.Add(Ligne(Compte(cpt, "RQAP_A_PAYER"), If(noms.ARetenueTerritoriale, noms.RetenueProvinciale, "RQAP") & " à payer", 0D, t.Dcm("RQAP") + t.Dcm("ERQAP")))
        credits.Add(Ligne(Compte(cpt, "FSS_A_PAYER"), noms.Sante & " à payer", 0D, t.Dcm("FSS")))
        credits.Add(Ligne(Compte(cpt, "CNESST_A_PAYER"), noms.Accidents & " à payer", 0D, t.Dcm("CNESST")))
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

''' <summary>
''' Déclaration annuelle des salaires à la CNESST — ou, pour une compagnie hors Québec, gains assurables
''' et primes de la commission des accidents du travail de la province (WSIB, WCB…) : mêmes colonnes (GainsCNESST, EmployeurCNESST), mêmes unités de classification.
''' </summary>
Public NotInheritable Class ServiceCNESST

    Private Sub New()
    End Sub

    ' Le rapport est celui de l'organisme de la province de la compagnie (@prov) : seules les paies de cette
    ' province y entrent. Une compagnie qui a changé de province en cours d'année a donc deux rapports
    ' distincts, celui de la CNESST avant et celui de l'autre commission après (ou l'inverse).

    Private Shared Function Prms(annee As Integer) As SqlParameter()
        Return {Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee), Db.P("@prov", Provinces.Code(Contexte.Province))}
    End Function

    ''' <summary>
    ''' Par employé et par unité de classification : salaire brut, excédent du maximum
    ''' assurable, salaire assurable et cotisation calculée. Un employé qui a changé
    ''' d'unité en cours d'année a une ligne par unité — c'est ainsi que la CNESST
    ''' veut la Déclaration des salaires. L'unité est celle figée sur chaque paie.
    ''' </summary>
    Public Shared Function ParEmploye(annee As Integer) As DataTable
        Dim t = Db.Table("paie.spCNESST_ParEmploye", Prms(annee))
        Dim lignes = Db.Table("paie.spCNESST_LignesParEmploye", Prms(annee))

        t.Columns("Brut").ReadOnly = False
        t.Columns("Excedent").ReadOnly = False
        For Each e As DataRow In t.Rows
            Dim brut As Decimal = 0D
            For Each l In lignes.Select("EmployeId = " & e.Ent("Id").ToString() & " AND UniteId = " & e.Ent("UniteId").ToString())
                If CategoriePaie.Existe(l.Txt("CategorieCode")) AndAlso CategoriePaie.ParCode(l.Txt("CategorieCode")).CNESST Then brut += l.Dcm("Montant")
            Next
            e("Brut") = brut
            e("Excedent") = If(e.Bln("ExemptCNESST"), 0D, Math.Max(0D, brut - e.Dcm("Assurable")))
        Next
        Return t
    End Function

    ''' <summary>
    ''' Par unité de classification : le taux appliqué, le nombre d'employés, le salaire
    ''' assurable et la cotisation. Les paies sans unité forment la ligne « Taux de la
    ''' compagnie ». C'est le tableau à recopier dans la Déclaration des salaires.
    ''' </summary>
    Public Shared Function ParUnite(annee As Integer) As DataTable
        Return Db.Table("paie.spCNESST_ParUnite", Prms(annee))
    End Function

    Public Shared Function ParMois(annee As Integer) As DataTable
        Return Db.Table("paie.spCNESST_ParMois", Prms(annee))
    End Function

    ''' <summary>Versements périodiques à la CNESST compris dans les remises à Revenu Québec enregistrées pour l'année.</summary>
    Public Shared Function VersementsPayes(annee As Integer) As Decimal
        Return Convert.ToDecimal(Db.Scalaire("paie.spCNESST_VersementsPayes", Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee)))
    End Function

End Class
