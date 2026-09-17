Imports Paie60Sec.Calcul

''' <summary>Cycle de vie d'un lot de paie : brouillon, calcul, confirmation, annulation.</summary>
Public NotInheritable Class ServicePaie

    Private Sub New()
    End Sub

    Public Shared Function DebutPeriode(fin As Date, periodes As Integer) As Date
        Select Case periodes
            Case 52, 53 : Return fin.AddDays(-6)
            Case 26, 27 : Return fin.AddDays(-13)
            Case 13 : Return fin.AddDays(-27)
            Case 24 : Return New Date(fin.Year, fin.Month, If(fin.Day <= 15, 1, 16))
            Case 12 : Return New Date(fin.Year, fin.Month, 1)
            Case 1 : Return New Date(fin.Year, 1, 1)
            Case Else : Return fin.AddDays(-CInt(Math.Round(365D / periodes)) + 1)
        End Select
    End Function

    Public Shared Function LotBrouillon() As DataRow
        Return Db.Ligne("SELECT TOP 1 * FROM dbo.LotPaie WHERE CompagnieId = @c AND Statut = 'B' ORDER BY Id DESC",
                        Db.P("@c", Contexte.CompagnieId))
    End Function

    ''' <summary>Crée le lot en brouillon et prépare la paie de chaque employé actif à partir de son gabarit.</summary>
    Public Shared Function CreerLot(periodes As Integer, finPeriode As Date, datePaie As Date) As Integer
        If Not ParametresAnnee.EstDisponible(datePaie.Year) Then
            Throw New SaisieInvalideException("Les taux gouvernementaux de " & datePaie.Year.ToString() & " ne sont pas encore définis dans le logiciel.")
        End If
        If LotBrouillon() IsNot Nothing Then
            Throw New SaisieInvalideException("Une paie est déjà en préparation. Terminez-la ou supprimez-la d'abord.")
        End If

        Dim compagnie = Db.Ligne("SELECT * FROM dbo.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId))
        Dim debut = DebutPeriode(finPeriode, periodes)

        Dim employes = Db.Table(
            "SELECT * FROM dbo.Employe WHERE CompagnieId = @c AND Actif = 1 AND ISNULL(PeriodesParAnnee, @pDefaut) = @p " &
            "AND (DateEmbauche IS NULL OR DateEmbauche <= @fin) AND (DateFinEmploi IS NULL OR DateFinEmploi >= @debut) ORDER BY Nom, Prenom",
            Db.P("@c", Contexte.CompagnieId), Db.P("@pDefaut", compagnie.Ent("PeriodesParAnnee")), Db.P("@p", periodes),
            Db.P("@fin", finPeriode), Db.P("@debut", debut))
        If employes.Rows.Count = 0 Then
            Throw New SaisieInvalideException("Aucun employé actif n'est payé à cette fréquence pour cette période.")
        End If

        Dim lotId = Db.Inserer(
            "INSERT INTO dbo.LotPaie (CompagnieId, PeriodesParAnnee, DateDebutPeriode, DateFinPeriode, DatePaie, CreePar) VALUES (@c, @p, @debut, @fin, @paie, @u)",
            Db.P("@c", Contexte.CompagnieId), Db.P("@p", periodes), Db.P("@debut", debut), Db.P("@fin", finPeriode),
            Db.P("@paie", datePaie), Db.P("@u", Contexte.Utilisateur))

        For Each emp As DataRow In employes.Rows
            Dim tauxVacances = If(emp.DcmN("TauxVacances"), compagnie.Dcm("TauxVacancesDefaut"))
            Dim paieId = Db.Inserer("INSERT INTO dbo.Paie (LotPaieId, EmployeId, TauxVacances) VALUES (@l, @e, @v)",
                                    Db.P("@l", lotId), Db.P("@e", emp.Ent("Id")), Db.P("@v", tauxVacances))

            Dim copiees = Db.Exec(
                "INSERT INTO dbo.PaieLigne (PaieId, ElementPaieId, Description, CategorieCode, Heures, Taux, Montant, MasquerSurTalon) " &
                "SELECT @paie, el.Id, el.Description, el.CategorieCode, ee.Heures, ee.Taux, ee.Montant, el.MasquerSurTalon " &
                "FROM dbo.EmployeElement ee JOIN dbo.ElementPaie el ON el.Id = ee.ElementPaieId WHERE ee.EmployeId = @e AND el.Actif = 1",
                Db.P("@paie", paieId), Db.P("@e", emp.Ent("Id")))

            If copiees = 0 Then AjouterLigneParDefaut(paieId, emp, periodes)
        Next

        Return lotId
    End Function

    ''' <summary>Sans gabarit : salaire horaire (heures/semaine) ou salaire annuel réparti sur les périodes.</summary>
    Private Shared Sub AjouterLigneParDefaut(paieId As Integer, emp As DataRow, periodes As Integer)
        Dim taux = emp.Dcm("TauxHoraire")
        Dim heuresSemaine = emp.Dcm("HeuresSemaine")
        If taux > 0D AndAlso heuresSemaine > 0D Then
            Dim heures = Math.Round(heuresSemaine * 52D / periodes, 2, MidpointRounding.AwayFromZero)
            AjouterLigne(paieId, ElementPourCategorie("SALAIRE"), heures, taux, 0D)
        ElseIf emp.Dcm("SalaireAnnuel") > 0D Then
            AjouterLigne(paieId, ElementPourCategorie("SALAIRE_FIXE"), 0D, 0D, Arrondi.Cents(emp.Dcm("SalaireAnnuel") / periodes))
        End If
    End Sub

    Private Shared Function ElementPourCategorie(code As String) As Integer
        Dim id = Db.ScalaireEntier("SELECT TOP 1 Id FROM dbo.ElementPaie WHERE CompagnieId = @c AND CategorieCode = @code AND Actif = 1 ORDER BY Id",
                                   Db.P("@c", Contexte.CompagnieId), Db.P("@code", code))
        If id > 0 Then Return id
        Return Db.Inserer("INSERT INTO dbo.ElementPaie (CompagnieId, Description, CategorieCode) VALUES (@c, @d, @code)",
                          Db.P("@c", Contexte.CompagnieId), Db.P("@d", CategoriePaie.ParCode(code).Libelle), Db.P("@code", code))
    End Function

    ''' <summary>Ajoute une ligne à une paie. Le montant est heures × taux × multiplicateur lorsque des heures sont saisies.</summary>
    Public Shared Sub AjouterLigne(paieId As Integer, elementId As Integer, heures As Decimal, taux As Decimal, montant As Decimal)
        Dim element = Db.Ligne("SELECT * FROM dbo.ElementPaie WHERE Id = @id AND CompagnieId = @c", Db.P("@id", elementId), Db.P("@c", Contexte.CompagnieId))
        If element Is Nothing Then Throw New SaisieInvalideException("Élément de paie introuvable.")

        Dim total = MontantLigne(element.Txt("CategorieCode"), heures, taux, montant)
        If total <= 0D Then Throw New SaisieInvalideException("Le montant de la ligne doit être supérieur à 0 (heures × taux, ou montant).")

        Db.Exec("INSERT INTO dbo.PaieLigne (PaieId, ElementPaieId, Description, CategorieCode, Heures, Taux, Montant, MasquerSurTalon) " &
                "VALUES (@p, @e, @d, @c, @h, @t, @m, @masquer)",
                Db.P("@p", paieId), Db.P("@e", elementId), Db.P("@d", element.Txt("Description")), Db.P("@c", element.Txt("CategorieCode")),
                Db.P("@h", heures), Db.P("@t", taux), Db.P("@m", total), Db.P("@masquer", element.Bln("MasquerSurTalon")))
        MarquerNonCalcule(paieId)
    End Sub

    Public Shared Function MontantLigne(categorieCode As String, heures As Decimal, taux As Decimal, montant As Decimal) As Decimal
        If heures > 0D AndAlso taux > 0D Then
            Return Arrondi.Cents(heures * taux * CategoriePaie.ParCode(categorieCode).Multiplicateur)
        End If
        Return Arrondi.Cents(montant)
    End Function

    Public Shared Sub MarquerNonCalcule(paieId As Integer)
        Db.Exec("UPDATE l SET Calcule = 0 FROM dbo.LotPaie l JOIN dbo.Paie p ON p.LotPaieId = l.Id WHERE p.Id = @p AND l.Statut = 'B'", Db.P("@p", paieId))
    End Sub

    ''' <summary>Cumulatifs de l'année : paies confirmées (sauf le lot en cours) et soldes de départ.</summary>
    Public Shared Function CumulatifsEmploye(employeId As Integer, annee As Integer, lotExclu As Integer) As Cumulatifs
        Dim r = Db.Ligne(
            "SELECT ISNULL(SUM(p.RRQ),0) RRQ, ISNULL(SUM(p.RRQ2),0) RRQ2, ISNULL(SUM(p.GainsRRQ),0) GainsRRQ, ISNULL(SUM(p.AE),0) AE, " &
            "ISNULL(SUM(p.RQAP),0) RQAP, ISNULL(SUM(p.EmployeurRQAP),0) RQAPEmployeur, ISNULL(SUM(p.GainsCNESST),0) GainsCNESST, " &
            "ISNULL(SUM(p.ForfaitairesFederal),0) ForfFed, ISNULL(SUM(p.ForfaitairesQuebec),0) ForfQc, ISNULL(SUM(p.CSBForfaitaires),0) CSB " &
            "FROM dbo.Paie p JOIN dbo.LotPaie l ON l.Id = p.LotPaieId " &
            "WHERE p.EmployeId = @e AND p.Inclus = 1 AND l.Statut = 'C' AND YEAR(l.DatePaie) = @a AND l.Id <> @lot",
            Db.P("@e", employeId), Db.P("@a", annee), Db.P("@lot", lotExclu))

        Dim c As New Cumulatifs With {
            .RRQ = r.Dcm("RRQ"), .RRQ2 = r.Dcm("RRQ2"), .GainsRRQ = r.Dcm("GainsRRQ"), .AE = r.Dcm("AE"), .RQAP = r.Dcm("RQAP"),
            .RQAPEmployeur = r.Dcm("RQAPEmployeur"), .GainsCNESST = r.Dcm("GainsCNESST"),
            .ForfaitairesFederal = r.Dcm("ForfFed"), .ForfaitairesQuebec = r.Dcm("ForfQc"), .CSBForfaitaires = r.Dcm("CSB")}

        Dim depart = Db.Ligne("SELECT * FROM dbo.CumulatifDepart WHERE EmployeId = @e AND Annee = @a", Db.P("@e", employeId), Db.P("@a", annee))
        If depart IsNot Nothing Then
            c.RRQ += depart.Dcm("RRQ")
            c.RRQ2 += depart.Dcm("RRQ2")
            c.GainsRRQ += depart.Dcm("GainsRRQ")
            c.AE += depart.Dcm("AE")
            c.RQAP += depart.Dcm("RQAP")
            c.RQAPEmployeur += depart.Dcm("RQAPEmployeur")
            c.GainsCNESST += depart.Dcm("GainsCNESST")
        End If
        Return c
    End Function

    ''' <summary>Calcule toutes les paies incluses du lot en brouillon.</summary>
    Public Shared Sub CalculerLot(lotId As Integer)
        Dim lot = LotModifiable(lotId)
        Dim compagnie = Db.Ligne("SELECT * FROM dbo.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId))
        Dim datePaie = lot.DtN("DatePaie").Value

        Dim employeur As New ProfilEmployeur With {
            .FacteurAE = compagnie.Dcm("FacteurAE"),
            .TauxFSS = ParametresAnnee.TauxFSS(compagnie.Dcm("MasseSalarialeEstimee"), CType(compagnie.Ent("SecteurFSS"), SecteurFSS)),
            .TauxCNESST = compagnie.Dcm("TauxCNESST"),
            .AssujettiCNT = compagnie.Bln("AssujettiCNT")}

        Dim paies = Db.Table("SELECT p.Id AS PaieId, p.TauxVacances AS TauxVacancesPaie, e.* FROM dbo.Paie p JOIN dbo.Employe e ON e.Id = p.EmployeId " &
                             "WHERE p.LotPaieId = @l AND p.Inclus = 1", Db.P("@l", lotId))
        For Each row As DataRow In paies.Rows
            Dim entree As New EntreePaie With {
                .Annee = datePaie.Year, .PeriodesParAnnee = lot.Ent("PeriodesParAnnee"), .DatePaie = datePaie,
                .Employeur = employeur, .TauxVacances = row.Dcm("TauxVacancesPaie"),
                .Cumul = CumulatifsEmploye(row.Ent("Id"), datePaie.Year, lotId),
                .Employe = ProfilDe(row)}

            For Each ligne As DataRow In Db.Table("SELECT * FROM dbo.PaieLigne WHERE PaieId = @p", Db.P("@p", row.Ent("PaieId"))).Rows
                entree.Lignes.Add(New LignePaie With {
                    .CodeCategorie = ligne.Txt("CategorieCode"), .Description = ligne.Txt("Description"),
                    .Heures = ligne.Dcm("Heures"), .Taux = ligne.Dcm("Taux"), .Montant = ligne.Dcm("Montant")})
            Next

            Enregistrer(row.Ent("PaieId"), MoteurPaie.Calculer(entree))
        Next

        Db.Exec("UPDATE dbo.LotPaie SET Calcule = 1 WHERE Id = @l", Db.P("@l", lotId))
    End Sub

    Private Shared Function ProfilDe(e As DataRow) As ProfilEmploye
        Return New ProfilEmploye With {
            .DateNaissance = e.DtN("DateNaissance"),
            .ExemptImpotFederal = e.Bln("ExemptImpotFederal"), .ExemptImpotQuebec = e.Bln("ExemptImpotQuebec"),
            .ExemptRRQ = e.Bln("ExemptRRQ"), .ExemptRQAP = e.Bln("ExemptRQAP"), .ExemptAE = e.Bln("ExemptAE"),
            .ExemptFSS = e.Bln("ExemptFSS"), .ExemptCNESST = e.Bln("ExemptCNESST"),
            .TD1MontantDemande = e.DcmN("TD1MontantDemande"), .TD1ImpotAdditionnel = e.Dcm("TD1ImpotAdditionnel"),
            .TD1DeductionZone = e.Dcm("TD1DeductionZone"), .TD1DeductionsAnnuelles = e.Dcm("TD1DeductionsAnnuelles"),
            .TD1AutresCredits = e.Dcm("TD1AutresCredits"),
            .TP1015Montant = e.DcmN("TP1015Montant"), .TP1015ImpotAdditionnel = e.Dcm("TP1015ImpotAdditionnel"),
            .TP1015DeductionsLigne19 = e.Dcm("TP1015DeductionsLigne19"), .TP1016Deductions = e.Dcm("TP1016Deductions"),
            .TP1016Credits = e.Dcm("TP1016Credits")}
    End Function

    Private Shared Sub Enregistrer(paieId As Integer, r As ResultatPaie)
        Db.Exec(
            "UPDATE dbo.Paie SET Heures=@Heures, BrutVerse=@BrutVerse, AvantagesNonMonetaires=@Avantages, ImpotFederal=@ImpotFederal, ImpotQuebec=@ImpotQuebec, " &
            "RRQ=@RRQ, RRQ2=@RRQ2, AE=@AE, RQAP=@RQAP, AutresDeductions=@Autres, Net=@Net, " &
            "EmployeurRRQ=@ERRQ, EmployeurRRQ2=@ERRQ2, EmployeurAE=@EAE, EmployeurRQAP=@ERQAP, EmployeurFSS=@EFSS, EmployeurCNESST=@ECNESST, EmployeurCNT=@ECNT, " &
            "GainsRRQ=@GRRQ, GainsAE=@GAE, GainsRQAP=@GRQAP, GainsFSS=@GFSS, GainsCNESST=@GCNESST, BrutImposableFederal=@BFed, BrutImposableQuebec=@BQc, " &
            "ForfaitairesFederal=@FFed, ForfaitairesQuebec=@FQc, CSBForfaitaires=@CSB, VacancesAccumulees=@VacAcc, VacancesPayees=@VacPay, " &
            "Verification=@Verif, Avertissements=@Avert WHERE Id=@Id",
            Db.P("@Heures", r.Heures), Db.P("@BrutVerse", r.BrutVerse), Db.P("@Avantages", r.AvantagesNonMonetaires),
            Db.P("@ImpotFederal", r.ImpotFederal), Db.P("@ImpotQuebec", r.ImpotQuebec), Db.P("@RRQ", r.RRQ), Db.P("@RRQ2", r.RRQ2),
            Db.P("@AE", r.AE), Db.P("@RQAP", r.RQAP), Db.P("@Autres", r.AutresDeductions), Db.P("@Net", r.Net),
            Db.P("@ERRQ", r.EmployeurRRQ), Db.P("@ERRQ2", r.EmployeurRRQ2), Db.P("@EAE", r.EmployeurAE), Db.P("@ERQAP", r.EmployeurRQAP),
            Db.P("@EFSS", r.EmployeurFSS), Db.P("@ECNESST", r.EmployeurCNESST), Db.P("@ECNT", r.EmployeurCNT),
            Db.P("@GRRQ", r.GainsRRQ), Db.P("@GAE", r.GainsAE), Db.P("@GRQAP", r.GainsRQAP), Db.P("@GFSS", r.GainsFSS), Db.P("@GCNESST", r.GainsCNESST),
            Db.P("@BFed", r.BrutImposableFederal), Db.P("@BQc", r.BrutImposableQuebec), Db.P("@FFed", r.ForfaitairesFederal),
            Db.P("@FQc", r.ForfaitairesQuebec), Db.P("@CSB", r.CSBForfaitaires), Db.P("@VacAcc", r.VacancesAccumulees), Db.P("@VacPay", r.VacancesPayees),
            Db.P("@Verif", String.Join(vbCrLf, r.Verification)), Db.P("@Avert", String.Join(vbCrLf, r.Avertissements)), Db.P("@Id", paieId))
    End Sub

    ''' <summary>Confirme le lot : retire les employés exclus, numérote les chèques, fige la paie.</summary>
    Public Shared Sub ConfirmerLot(lotId As Integer)
        Dim lot = LotModifiable(lotId)
        If Not lot.Bln("Calcule") Then Throw New SaisieInvalideException("La paie doit être calculée avant d'être confirmée.")
        If Db.ScalaireEntier("SELECT COUNT(*) FROM dbo.Paie WHERE LotPaieId = @l AND Inclus = 1", Db.P("@l", lotId)) = 0 Then
            Throw New SaisieInvalideException("Aucun employé n'est inclus dans cette paie.")
        End If
        If Db.ScalaireEntier("SELECT COUNT(*) FROM dbo.Paie WHERE LotPaieId = @l AND Inclus = 1 AND Net < 0", Db.P("@l", lotId)) > 0 Then
            Throw New SaisieInvalideException("Au moins une paie nette est négative. Corrigez les lignes avant de confirmer.")
        End If

        Db.Exec(
            "SET XACT_ABORT ON; BEGIN TRAN; " &
            "DELETE FROM dbo.Paie WHERE LotPaieId = @l AND Inclus = 0; " &
            "DECLARE @prochain int = (SELECT ProchainNumeroCheque FROM dbo.Compagnie WHERE Id = @c); " &
            "WITH x AS (SELECT p.Id, ROW_NUMBER() OVER (ORDER BY e.Nom, e.Prenom) AS rn FROM dbo.Paie p JOIN dbo.Employe e ON e.Id = p.EmployeId " &
            "           WHERE p.LotPaieId = @l AND e.DepotDirect = 0) " &
            "UPDATE p SET NumeroCheque = @prochain + x.rn - 1 FROM dbo.Paie p JOIN x ON x.Id = p.Id; " &
            "UPDATE dbo.Compagnie SET ProchainNumeroCheque = @prochain + (SELECT COUNT(*) FROM dbo.Paie WHERE LotPaieId = @l AND NumeroCheque IS NOT NULL) WHERE Id = @c; " &
            "UPDATE dbo.LotPaie SET Statut = 'C', DateConfirmation = sysdatetime() WHERE Id = @l AND Statut = 'B'; " &
            "COMMIT;",
            Db.P("@l", lotId), Db.P("@c", Contexte.CompagnieId))

        Contexte.Journaliser("Paie du " & TexteDate(lot("DatePaie")) & " confirmée.", "~/Paie/Detail.aspx?lot=" & lotId.ToString())
    End Sub

    Public Shared Sub SupprimerBrouillon(lotId As Integer)
        LotModifiable(lotId)
        Db.Exec("DELETE FROM dbo.LotPaie WHERE Id = @l AND Statut = 'B'", Db.P("@l", lotId))
    End Sub

    ''' <summary>Seule la paie confirmée la plus récente peut être annulée, pour garder des cumulatifs cohérents.</summary>
    Public Shared Function PeutAnnuler(lotId As Integer) As Boolean
        Dim dernier = Db.ScalaireEntier("SELECT TOP 1 Id FROM dbo.LotPaie WHERE CompagnieId = @c AND Statut = 'C' ORDER BY DatePaie DESC, Id DESC",
                                        Db.P("@c", Contexte.CompagnieId))
        If dernier <> lotId Then Return False
        Return Not RetenuesPayees(lotId)
    End Function

    ''' <summary>Vrai si les retenues d'au moins une paie du lot ont déjà été payées à un gouvernement.</summary>
    Public Shared Function RetenuesPayees(lotId As Integer) As Boolean
        Return Db.ScalaireEntier("SELECT COUNT(*) FROM dbo.Paie WHERE LotPaieId = @l AND (RemiseFederaleId IS NOT NULL OR RemiseQuebecId IS NOT NULL)",
                                 Db.P("@l", lotId)) > 0
    End Function

    Public Shared Sub AnnulerLot(lotId As Integer)
        If RetenuesPayees(lotId) Then
            Throw New SaisieInvalideException("Les retenues de cette paie ont déjà été payées. Annulez d'abord le paiement des retenues.")
        End If
        If Not PeutAnnuler(lotId) Then Throw New SaisieInvalideException("Seule la paie confirmée la plus récente peut être annulée.")
        Dim lot = Db.Ligne("SELECT * FROM dbo.LotPaie WHERE Id = @l", Db.P("@l", lotId))
        Db.Exec("UPDATE dbo.LotPaie SET Statut = 'A' WHERE Id = @l AND Statut = 'C' AND CompagnieId = @c", Db.P("@l", lotId), Db.P("@c", Contexte.CompagnieId))
        Contexte.Journaliser("Paie du " & TexteDate(lot("DatePaie")) & " annulée.", "~/Paie/Detail.aspx?lot=" & lotId.ToString())
    End Sub

    Private Shared Function LotModifiable(lotId As Integer) As DataRow
        Dim lot = Db.Ligne("SELECT * FROM dbo.LotPaie WHERE Id = @l AND CompagnieId = @c", Db.P("@l", lotId), Db.P("@c", Contexte.CompagnieId))
        If lot Is Nothing Then Throw New SaisieInvalideException("Lot de paie introuvable.")
        If lot.Txt("Statut") <> "B" Then Throw New SaisieInvalideException("Cette paie n'est plus modifiable.")
        Return lot
    End Function

End Class
