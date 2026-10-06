Imports System.Text
Imports Paie60Sec.Calcul

''' <summary>Solde des retenues à payer à un gouvernement.</summary>
Public Class SoldeRemise
    Public Property Montant As Decimal
    Public Property NbPaies As Integer
    ''' <summary>Date de la plus ancienne paie dont les retenues ne sont pas payées.</summary>
    Public Property PlusAnciennePaie As Date?
    ''' <summary>Fin de la période de remise qui contient cette paie.</summary>
    Public Property FinPeriode As Date?
    ''' <summary>Date limite du paiement pour cette période.</summary>
    Public Property Echeance As Date?

    Public ReadOnly Property EnRetard As Boolean
        Get
            Return Echeance.HasValue AndAlso Echeance.Value < Date.Today
        End Get
    End Property
End Class

''' <summary>
''' Remises gouvernementales. Ce qui est dû dépend de la province de chaque paie (paie.Paie.Province).
'''
''' QUÉBEC
'''   Fédéral (Receveur général) : impôt fédéral + assurance-emploi (employés et employeur).
'''   Revenu Québec : impôt du Québec + RRQ + RQAP (employés et employeur) + FSS + CNESST.
'''   La cotisation relative aux normes du travail (CNT) se paie une fois l'an avec le sommaire 1 : elle n'en fait pas partie.
'''
''' HORS QUÉBEC (toutes les autres provinces et les territoires)
'''   Fédéral (Receveur général) : impôt fédéral + impôt de la province + RPC (employés et employeur) + assurance-emploi.
'''   L'ARC perçoit l'impôt de la province : il n'y a aucune remise provinciale, et rien ne va à Revenu Québec.
'''   La cotisation santé de l'employeur (ISE de l'Ontario, de la Colombie-Britannique…) et la prime de la commission
'''   des accidents du travail (WSIB, WCB…) se paient à part : elles sont calculées et affichées, mais ne font
'''   partie d'aucune remise. Il en va de même de l'impôt de 2 % sur la paie des Territoires du Nord-Ouest et du
'''   Nunavut, retenu à l'employé et remis au territoire (colonne RQAP de paie.Paie).
'''
''' Rappel : hors Québec, l'impôt provincial et le RPC occupent les colonnes ImpotQuebec et RRQ de paie.Paie.
''' </summary>
Public NotInheritable Class ServiceRemise

    Public Const Federal As String = "F"
    Public Const Quebec As String = "Q"

    Private Sub New()
    End Sub

    ''' <summary>Ce qu'une paie doit au Receveur général. Hors Québec s'y ajoutent l'impôt provincial et le RPC.</summary>
    Public Const SqlDuFederal As String =
        "p.ImpotFederal + p.AE + p.EmployeurAE + " &
        "CASE WHEN p.Province <> N'QC' THEN p.ImpotQuebec + p.RRQ + p.RRQ2 + p.EmployeurRRQ + p.EmployeurRRQ2 ELSE 0 END"

    ''' <summary>
    ''' Ce qu'une paie doit à Revenu Québec : rien pour une paie d'une autre province. (L'impôt sur la paie
    ''' d'un territoire occupe la colonne RQAP : il ne doit surtout pas s'y retrouver.)
    ''' </summary>
    Public Const SqlDuQuebec As String =
        "CASE WHEN p.Province <> N'QC' THEN 0 ELSE p.ImpotQuebec + p.RRQ + p.RRQ2 + p.EmployeurRRQ + p.EmployeurRRQ2 + " &
        "p.RQAP + p.EmployeurRQAP + p.EmployeurFSS + p.EmployeurCNESST END"

    Private Const SiHorsQuebec As String = "CASE WHEN p.Province <> N'QC' THEN "

    ''' <summary>
    ''' Code de la ligne de l'impôt provincial d'une remise fédérale : « IMPOT_ON », « IMPOT_AB »… Une ligne par
    ''' province, parce qu'une compagnie qui a changé de province peut en remettre deux à la fois.
    ''' Une paie du Québec donne « IMPOT_PROV », toujours à zéro, que SqlLignes retire.
    ''' </summary>
    Private Const SqlCodeImpotProvincial As String = "CASE WHEN p.Province = N'QC' THEN 'IMPOT_PROV' ELSE 'IMPOT_' + p.Province END"

    ''' <summary>« Impôt de l'Ontario », « Impôt de l'Alberta »… selon la province de la paie. Les libellés viennent du code, jamais d'une saisie.</summary>
    Private Shared Function SqlLibelleImpotProvincial() As String
        Dim sb As New StringBuilder("CASE p.Province")
        For Each prov In Provinces.Gerees
            If prov = Province.Quebec Then Continue For
            sb.Append(" WHEN N'").Append(Provinces.Code(prov)).Append("' THEN N'").Append(LibellesProvince.Pour(prov).ImpotProvincial.Replace("'", "''")).Append("'")
        Next
        Return sb.Append(" ELSE N'Impôt provincial' END").ToString()
    End Function

    Public Shared Function NomGouvernement(gouvernement As Object) As String
        Return If(Convert.ToString(gouvernement) = Federal, "Receveur général du Canada", "Revenu Québec")
    End Function

    ' Les noms de colonnes proviennent de constantes, jamais d'une saisie.
    Private Shared Function ColonnePaie(gouvernement As String) As String
        Select Case gouvernement
            Case Federal : Return "RemiseFederaleId"
            Case Quebec : Return "RemiseQuebecId"
            Case Else : Throw New SaisieInvalideException("Gouvernement invalide.")
        End Select
    End Function

    Private Shared Function ValeursLignes(gouvernement As String) As String
        If gouvernement = Federal Then
            ' Les trois lignes hors Québec valent 0 pour une paie du Québec ; SqlLignes les retire alors de la liste.
            Return "('IMPOT_FED', N'Impôt fédéral', 1, p.ImpotFederal), " &
                   "(" & SqlCodeImpotProvincial & ", " & SqlLibelleImpotProvincial() & ", 2, " & SiHorsQuebec & "p.ImpotQuebec ELSE 0 END), " &
                   "('RPC_EMPLOYE', N'RPC - cotisations des employés', 3, " & SiHorsQuebec & "p.RRQ + p.RRQ2 ELSE 0 END), " &
                   "('RPC_EMPLOYEUR', N'RPC - cotisation de l''employeur', 4, " & SiHorsQuebec & "p.EmployeurRRQ + p.EmployeurRRQ2 ELSE 0 END), " &
                   "('AE_EMPLOYE', N'Assurance-emploi - cotisations des employés', 5, p.AE), " &
                   "('AE_EMPLOYEUR', N'Assurance-emploi - cotisation de l''employeur', 6, p.EmployeurAE)"
        End If
        Return "('IMPOT_QC', N'Impôt du Québec', 1, p.ImpotQuebec), " &
               "('RRQ_EMPLOYE', N'RRQ - cotisations des employés', 2, p.RRQ + p.RRQ2), " &
               "('RRQ_EMPLOYEUR', N'RRQ - cotisation de l''employeur', 3, p.EmployeurRRQ + p.EmployeurRRQ2), " &
               "('RQAP_EMPLOYE', N'RQAP - cotisations des employés', 4, p.RQAP), " &
               "('RQAP_EMPLOYEUR', N'RQAP - cotisation de l''employeur', 5, p.EmployeurRQAP), " &
               "('FSS', N'Fonds des services de santé (FSS)', 6, p.EmployeurFSS), " &
               "('CNESST', N'CNESST - versement périodique', 7, p.EmployeurCNESST)"
    End Function

    Private Shared Function SqlLignes(gouvernement As String, filtre As String) As String
        Return "SELECT v.Code, v.Libelle, v.Ordre, SUM(v.Montant) AS Montant FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId " &
               "CROSS APPLY (VALUES " & ValeursLignes(gouvernement) & ") v(Code, Libelle, Ordre, Montant) WHERE " & filtre &
               " GROUP BY v.Code, v.Libelle, v.Ordre" &
               If(gouvernement = Federal,
                  " HAVING NOT ((v.Code IN ('IMPOT_PROV', 'RPC_EMPLOYE', 'RPC_EMPLOYEUR') OR v.Code LIKE 'IMPOT[_]__') AND SUM(v.Montant) = 0)", "")
    End Function

    ''' <summary>
    ''' Paies confirmées dont les retenues ne sont pas encore payées à ce gouvernement.
    ''' Une paie d'une autre province ne doit rien à Revenu Québec : elle n'y est jamais « à payer ».
    ''' </summary>
    Private Shared Function FiltreNonPaye(gouvernement As String) As String
        Return "l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND l.DatePaie <= @fin AND p." & ColonnePaie(gouvernement) & " IS NULL" &
               If(gouvernement = Quebec, " AND p.Province = N'QC'", "")
    End Function

    ''' <summary>
    ''' Vrai si la compagnie a affaire à Revenu Québec : elle est au Québec, ou il lui reste des
    ''' retenues à y payer (compagnie passée du Québec à une autre province).
    ''' </summary>
    Public Shared Function QuebecConcerne() As Boolean
        If Not Contexte.HorsQuebec Then Return True
        Return Solde(Quebec).NbPaies > 0
    End Function

    ' ---------- Échéances ----------

    Public Shared Function Frequence(gouvernement As String) As String
        Dim colonne = If(gouvernement = Federal, "FrequenceRemiseFederale", "FrequenceRemiseQuebec")
        Return Convert.ToString(Db.Scalaire("SELECT " & colonne & " FROM paie.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId)))
    End Function

    ''' <summary>Dernier jour du mois (remise mensuelle) ou du trimestre (remise trimestrielle) de la paie.</summary>
    Public Shared Function FinPeriodeRemise(datePaie As Date, frequence As String) As Date
        Dim mois = If(frequence = "T", ((datePaie.Month - 1) \ 3 + 1) * 3, datePaie.Month)
        Return New Date(datePaie.Year, mois, 1).AddMonths(1).AddDays(-1)
    End Function

    ''' <summary>Le paiement est dû le 15 du mois qui suit la période.</summary>
    Public Shared Function Echeance(datePaie As Date, frequence As String) As Date
        Return FinPeriodeRemise(datePaie, frequence).AddDays(15)
    End Function

    Public Shared Function Solde(gouvernement As String) As SoldeRemise
        Dim total = If(gouvernement = Federal, SqlDuFederal, SqlDuQuebec)
        Dim r = Db.Ligne("SELECT ISNULL(SUM(" & total & "), 0) AS Montant, COUNT(*) AS NbPaies, MIN(l.DatePaie) AS PlusAncienne " &
                         "FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE " & FiltreNonPaye(gouvernement),
                         Db.P("@c", Contexte.CompagnieId), Db.P("@fin", New Date(9999, 12, 31)))
        Dim s As New SoldeRemise With {.Montant = r.Dcm("Montant"), .NbPaies = r.Ent("NbPaies"), .PlusAnciennePaie = r.DtN("PlusAncienne")}
        If s.PlusAnciennePaie.HasValue Then
            Dim f = Frequence(gouvernement)
            s.FinPeriode = FinPeriodeRemise(s.PlusAnciennePaie.Value, f)
            s.Echeance = Echeance(s.PlusAnciennePaie.Value, f)
        End If
        Return s
    End Function

    ''' <summary>CNT accumulée dans l'année (payable une fois l'an, à titre indicatif).</summary>
    Public Shared Function CntAccumulee(annee As Integer) As Decimal
        Return Convert.ToDecimal(Db.Scalaire(
            "SELECT ISNULL(SUM(p.EmployeurCNT), 0) FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId " &
            "WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND YEAR(l.DatePaie) = @a", Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee)))
    End Function

    ''' <summary>
    ''' Hors Québec : ce qui s'accumule dans l'année sans faire partie des remises au Receveur général, une
    ''' ligne par province (une compagnie peut en avoir changé). Colonnes : Province, Sante et MasseSante
    ''' (cotisation santé de l'employeur), Accidents et AssurableAccidents (commission des accidents du
    ''' travail), ImpotPaie et GainsImpotPaie (impôt sur la paie des T.N.-O. et du Nunavut, retenu aux
    ''' employés et à remettre au territoire). Les montants sont donnés à titre indicatif.
    ''' </summary>
    Public Shared Function HorsRemiseProvinces(annee As Integer) As DataTable
        Return Db.Table(
            "SELECT p.Province, ISNULL(SUM(p.EmployeurFSS), 0) AS Sante, ISNULL(SUM(p.GainsFSS), 0) AS MasseSante, " &
            "ISNULL(SUM(p.EmployeurCNESST), 0) AS Accidents, ISNULL(SUM(p.GainsCNESST), 0) AS AssurableAccidents, " &
            "ISNULL(SUM(p.RQAP), 0) AS ImpotPaie, ISNULL(SUM(p.GainsRQAP), 0) AS GainsImpotPaie " &
            "FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId " &
            "WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND p.Province <> N'QC' AND YEAR(l.DatePaie) = @a " &
            "GROUP BY p.Province ORDER BY p.Province",
            Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee))
    End Function

    ' ---------- Calcul et enregistrement ----------

    ''' <summary>Détail des montants à payer pour les retenues accumulées jusqu'à la date donnée (rien n'est enregistré).</summary>
    Public Shared Function LignesAPayer(gouvernement As String, finPeriode As Date) As DataTable
        Return Db.Table(SqlLignes(gouvernement, FiltreNonPaye(gouvernement)) & " ORDER BY v.Ordre", Db.P("@c", Contexte.CompagnieId), Db.P("@fin", finPeriode))
    End Function

    Public Shared Function LotsAPayer(gouvernement As String, finPeriode As Date) As DataTable
        Return Db.Table(SqlLots(FiltreNonPaye(gouvernement)), Db.P("@c", Contexte.CompagnieId), Db.P("@fin", finPeriode))
    End Function

    Private Shared Function SqlLots(filtre As String) As String
        Return "SELECT l.Id, l.DatePaie, l.DateDebutPeriode, l.DateFinPeriode, COUNT(*) AS NbEmployes, SUM(p.BrutVerse + p.AvantagesNonMonetaires) AS Brut " &
               "FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE " & filtre &
               " GROUP BY l.Id, l.DatePaie, l.DateDebutPeriode, l.DateFinPeriode ORDER BY l.DatePaie, l.Id"
    End Function

    ''' <summary>Enregistre le paiement : rattache les paies à la remise et fige les montants, en une seule transaction.</summary>
    Public Shared Function Enregistrer(gouvernement As String, finPeriode As Date, datePaiement As Date, parCheque As Boolean, reference As String) As Integer
        Dim col = ColonnePaie(gouvernement)
        Dim marquees = "p." & col & " = @id"

        Dim id = Db.ScalaireEntier(
            "SET XACT_ABORT ON; BEGIN TRAN; " &
            "DECLARE @cheque int = NULL; " &
            "IF @parCheque = 1 BEGIN " &
            "  SELECT @cheque = ProchainNumeroCheque FROM paie.Compagnie WHERE Id = @c; " &
            "  UPDATE paie.Compagnie SET ProchainNumeroCheque = ProchainNumeroCheque + 1 WHERE Id = @c; END; " &
            "INSERT INTO paie.Remise (CompagnieId, Gouvernement, DateFinPeriode, DatePaiement, ModePaiement, NumeroCheque, Reference, CreePar) " &
            "VALUES (@c, @g, @fin, @paiement, CASE WHEN @parCheque = 1 THEN 'C' ELSE 'E' END, @cheque, @ref, @u); " &
            "DECLARE @id int = SCOPE_IDENTITY(); " &
            "UPDATE p SET " & col & " = @id FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE " & FiltreNonPaye(gouvernement) & "; " &
            "IF @@ROWCOUNT = 0 BEGIN ROLLBACK; SELECT 0; RETURN; END; " &
            "INSERT INTO paie.RemiseLigne (RemiseId, Code, Libelle, Ordre, Montant) SELECT @id, x.Code, x.Libelle, x.Ordre, x.Montant FROM (" &
                SqlLignes(gouvernement, marquees) & ") x; " &
            "UPDATE paie.Remise SET " &
            "  Total = (SELECT ISNULL(SUM(Montant), 0) FROM paie.RemiseLigne WHERE RemiseId = @id), " &
            "  RemunerationBrute = (SELECT ISNULL(SUM(p.BrutVerse + p.AvantagesNonMonetaires), 0) FROM paie.Paie p WHERE " & marquees & "), " &
            "  NbPaies = (SELECT COUNT(*) FROM paie.Paie p WHERE " & marquees & "), " &
            "  NbEmployesDernierePaie = (SELECT COUNT(*) FROM paie.Paie p WHERE " & marquees & " AND p.LotPaieId = " &
            "     (SELECT TOP 1 l.Id FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE " & marquees & " ORDER BY l.DatePaie DESC, l.Id DESC)) " &
            "WHERE Id = @id; " &
            "COMMIT; SELECT @id;",
            Db.P("@c", Contexte.CompagnieId), Db.P("@g", gouvernement), Db.P("@fin", finPeriode), Db.P("@paiement", datePaiement),
            Db.P("@parCheque", parCheque), Db.P("@ref", reference), Db.P("@u", Contexte.Utilisateur))

        If id = 0 Then Throw New SaisieInvalideException("Aucune retenue à payer à " & NomGouvernement(gouvernement) & " pour cette période.")

        Dim total = Convert.ToDecimal(Db.Scalaire("SELECT Total FROM paie.Remise WHERE Id = @id", Db.P("@id", id)))
        Contexte.Journaliser("Paiement des retenues à " & NomGouvernement(gouvernement) & " : " & ArgentFr(total) & ".", "~/Remises/Detail.aspx?id=" & id.ToString())
        Return id
    End Function

    ''' <summary>Annule une remise : les paies redeviennent « à payer ». Le numéro de chèque n'est pas réutilisé.</summary>
    Public Shared Sub Annuler(remiseId As Integer)
        Dim r = Db.Ligne("SELECT * FROM paie.Remise WHERE Id = @id AND CompagnieId = @c", Db.P("@id", remiseId), Db.P("@c", Contexte.CompagnieId))
        If r Is Nothing Then Throw New SaisieInvalideException("Remise introuvable.")
        If r.Txt("Statut") <> "P" Then Throw New SaisieInvalideException("Cette remise est déjà annulée.")

        Db.Exec("SET XACT_ABORT ON; BEGIN TRAN; " &
                "UPDATE paie.Paie SET RemiseFederaleId = NULL WHERE RemiseFederaleId = @id; " &
                "UPDATE paie.Paie SET RemiseQuebecId = NULL WHERE RemiseQuebecId = @id; " &
                "UPDATE paie.Remise SET Statut = 'A' WHERE Id = @id; COMMIT;", Db.P("@id", remiseId))
        Contexte.Journaliser("Paiement des retenues à " & NomGouvernement(r("Gouvernement")) & " du " & TexteDate(r("DatePaiement")) & " annulé.",
                             "~/Remises/Detail.aspx?id=" & remiseId.ToString())
    End Sub

    ''' <summary>Lots de paie couverts par une remise enregistrée (vide si elle est annulée).</summary>
    Public Shared Function LotsDeLaRemise(remiseId As Integer, gouvernement As String) As DataTable
        Return Db.Table(SqlLots("l.CompagnieId = @c AND p." & ColonnePaie(gouvernement) & " = @id"), Db.P("@c", Contexte.CompagnieId), Db.P("@id", remiseId))
    End Function

    ' ---------- Rendu ----------

    ''' <summary>Tableau des montants (lignes avec colonnes Libelle et Montant) suivi des paies couvertes.</summary>
    Public Shared Function Rendu(lignes As DataTable, lots As DataTable) As String
        Dim sb As New StringBuilder()
        Dim total As Decimal = 0D
        sb.Append("<table class=""liste""><thead><tr><th>Retenue ou cotisation</th><th class=""num"">Montant</th></tr></thead><tbody>")
        For Each l As DataRow In lignes.Rows
            total += l.Dcm("Montant")
            sb.Append("<tr><td>").Append(HttpUtility.HtmlEncode(l.Txt("Libelle"))).Append("</td><td class=""num"">").Append(Argent(l("Montant"))).Append("</td></tr>")
        Next
        sb.Append("</tbody><tfoot><tr><td>Total à payer</td><td class=""num"">").Append(Argent(total)).Append("</td></tr></tfoot></table>")

        If lots.Rows.Count > 0 Then
            sb.Append("<h2 style=""margin-top:20px"">Paies couvertes</h2><table class=""liste""><thead><tr><th>Date de paie</th><th>Période</th>")
            sb.Append("<th class=""num"">Employés</th><th class=""num"">Rémunération brute</th></tr></thead><tbody>")
            For Each lot As DataRow In lots.Rows
                sb.Append("<tr><td><a href=""../Paie/Detail.aspx?lot=").Append(lot.Ent("Id")).Append(""">").Append(TexteDate(lot("DatePaie"))).Append("</a></td><td>")
                sb.Append(TexteDate(lot("DateDebutPeriode"))).Append(" au ").Append(TexteDate(lot("DateFinPeriode"))).Append("</td><td class=""num"">")
                sb.Append(lot.Ent("NbEmployes")).Append("</td><td class=""num"">").Append(Argent(lot("Brut"))).Append("</td></tr>")
            Next
            sb.Append("</tbody></table>")
        End If
        Return sb.ToString()
    End Function

End Class
