Imports System.Text

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
''' Remises gouvernementales d'un employeur du Québec.
''' Fédéral (Receveur général) : impôt fédéral + assurance-emploi (employés et employeur).
''' Revenu Québec : impôt du Québec + RRQ + RQAP (employés et employeur) + FSS + CNESST.
''' La cotisation relative aux normes du travail (CNT) se paie une fois l'an avec le sommaire 1 : elle n'en fait pas partie.
''' </summary>
Public NotInheritable Class ServiceRemise

    Public Const Federal As String = "F"
    Public Const Quebec As String = "Q"

    Private Sub New()
    End Sub

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
            Return "('IMPOT_FED', N'Impôt fédéral', 1, p.ImpotFederal), " &
                   "('AE_EMPLOYE', N'Assurance-emploi - cotisations des employés', 2, p.AE), " &
                   "('AE_EMPLOYEUR', N'Assurance-emploi - cotisation de l''employeur', 3, p.EmployeurAE)"
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
               " GROUP BY v.Code, v.Libelle, v.Ordre"
    End Function

    ''' <summary>Paies confirmées dont les retenues ne sont pas encore payées à ce gouvernement.</summary>
    Private Shared Function FiltreNonPaye(gouvernement As String) As String
        Return "l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND l.DatePaie <= @fin AND p." & ColonnePaie(gouvernement) & " IS NULL"
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
        Dim total = If(gouvernement = Federal,
            "p.ImpotFederal + p.AE + p.EmployeurAE",
            "p.ImpotQuebec + p.RRQ + p.RRQ2 + p.EmployeurRRQ + p.EmployeurRRQ2 + p.RQAP + p.EmployeurRQAP + p.EmployeurFSS + p.EmployeurCNESST")
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
