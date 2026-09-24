Imports System.Globalization

''' <summary>
''' Calcul d'une paie pour un employé du Québec.
''' Impôt du Québec, RRQ, RQAP et FSS : formules du guide TP-1015.F (Revenu Québec).
''' Impôt fédéral et assurance-emploi : formules du guide T4127 (ARC), variante Québec
''' (abattement de 16,5 %, crédit K2Q, taux d'AE réduit).
''' </summary>
Public NotInheritable Class MoteurPaie

    Private Sub New()
    End Sub

    ''' <summary>
    ''' Calcule une paie. Les taux sont ceux de l'année de la paie (ParametresAnnee.Pour),
    ''' sauf si <paramref name="parametres"/> en fournit d'autres — c'est ainsi que la
    ''' console vérifie une année encore en brouillon sans l'activer.
    ''' </summary>
    Public Shared Function Calculer(e As EntreePaie, Optional parametres As ParametresAnnee = Nothing) As ResultatPaie
        If e Is Nothing Then Throw New ArgumentNullException(NameOf(e))
        If e.PeriodesParAnnee <= 0 Then Throw New ArgumentException("Le nombre de périodes de paie par année doit être supérieur à 0.")

        Dim prm = If(parametres, ParametresAnnee.Pour(e.Annee))
        Dim P As Decimal = e.PeriodesParAnnee
        Dim emp = e.Employe
        Dim cum = e.Cumul
        Dim r As New ResultatPaie()

        ' ------------------------------------------------------------------
        ' 1. Ventilation des lignes selon l'assujettissement de leur catégorie
        ' ------------------------------------------------------------------
        Dim gFed, bFed, gQc, bQc As Decimal            ' rémunération régulière (G) et forfaitaire (B2)
        Dim s3, s3Forf As Decimal                      ' salaire admissible au RRQ
        Dim fFed, fFedForf, fQc, fQcForf As Decimal    ' déductions qui réduisent le revenu imposable (F, U1)
        Dim retenuesFonds As Decimal               ' Q + Q1

        For Each l In e.Lignes
            Dim cat = CategoriePaie.ParCode(l.CodeCategorie)
            Dim m = l.Montant

            If cat.Type = TypeCategorie.Deduction Then
                r.AutresDeductions += m
                If cat.ImpotFederal Then
                    If l.SurForfaitaire Then fFedForf += m Else fFed += m
                End If
                If cat.ImpotQuebec Then
                    If l.SurForfaitaire Then fQcForf += m Else fQc += m
                End If
                If cat.Fonds <> FondsTravailleurs.Aucun Then retenuesFonds += m
                Continue For
            End If

            If cat.Type = TypeCategorie.Revenu Then
                r.BrutVerse += m
                r.Heures += l.Heures
            ElseIf cat.VerseEnArgent Then
                r.BrutVerse += m
            Else
                r.AvantagesNonMonetaires += m
            End If

            If cat.ImpotFederal Then
                If cat.Forfaitaire Then bFed += m Else gFed += m
            End If
            If cat.ImpotQuebec Then
                If cat.Forfaitaire Then bQc += m Else gQc += m
            End If
            If cat.RRQ Then
                s3 += m
                If cat.Forfaitaire Then s3Forf += m
            End If
            If cat.AE Then r.GainsAE += m
            If cat.RQAP Then r.GainsRQAP += m
            If cat.FSS Then r.GainsFSS += m
            If cat.CNESST Then r.GainsCNESST += m
            If cat.Vacances Then r.GainsVacances += m
            If cat.PaieVacances Then r.VacancesPayees += m
        Next

        ' Une déduction supérieure à la rémunération régulière réduit le forfaitaire.
        Dim bFedNet = Plancher0(bFed - fFedForf - Plancher0(fFed - gFed))
        Dim bQcNet = Plancher0(bQc - fQcForf - Plancher0(fQc - gQc))
        If fFed > gFed Then fFed = gFed
        If fQc > gQc Then fQc = gQc

        r.GainsRRQ = s3
        r.BrutImposableFederal = gFed + bFed
        r.BrutImposableQuebec = gQc + bQc
        r.ForfaitairesFederal = bFedNet
        r.ForfaitairesQuebec = bQcNet

        ' ------------------------------------------------------------------
        ' 2. RRQ (TP-1015.F, partie 3)
        ' ------------------------------------------------------------------
        Dim assujettiRRQ = Not emp.ExemptRRQ AndAlso A18AnsOuPlus(emp.DateNaissance, e.DatePaie)
        Dim exemptionRRQ = Tronquer2(prm.RRQExemption / P)
        Dim c, c2 As Decimal
        If assujettiRRQ AndAlso s3 > 0D Then
            c = Cents(Plancher0(prm.RRQTaux * (s3 - exemptionRRQ)))
            c = Plancher0(Math.Min(c, prm.RRQMaxEmploye - cum.RRQ))

            Dim w = Math.Max(cum.GainsRRQ, prm.RRQMaxGainsAdmissibles)
            c2 = Cents(Plancher0(prm.RRQ2Taux * (cum.GainsRRQ + s3 - w)))
            c2 = Plancher0(Math.Min(c2, prm.RRQ2MaxEmploye - cum.RRQ2))
        Else
            r.GainsRRQ = 0D
        End If
        r.RRQ = c
        r.RRQ2 = c2
        r.EmployeurRRQ = c
        r.EmployeurRRQ2 = c2

        ' Déduction des cotisations supplémentaires au RRQ (CS), répartie entre régulier (CSA) et forfaitaire (CSB)
        Dim cs = Cents(c * (0.01D / prm.RRQTaux) + c2)
        Dim csa As Decimal = cs
        Dim csb As Decimal = 0D
        If s3 > 0D AndAlso s3Forf > 0D Then
            csa = Cents(cs * ((s3 - s3Forf) / s3))
            csb = cs - csa
        End If
        r.CSBForfaitaires = csb

        ' ------------------------------------------------------------------
        ' 3. Assurance-emploi (taux du Québec) et RQAP
        ' ------------------------------------------------------------------
        If Not emp.ExemptAE AndAlso r.GainsAE > 0D Then
            r.AE = Plancher0(Math.Min(Cents(prm.AETaux * r.GainsAE), prm.AEMaxEmploye - cum.AE))
            r.EmployeurAE = Cents(r.AE * e.Employeur.FacteurAE)
        Else
            r.GainsAE = 0D
        End If

        If Not emp.ExemptRQAP AndAlso r.GainsRQAP > 0D Then
            r.RQAP = Plancher0(Math.Min(Cents(prm.RQAPTauxEmploye * r.GainsRQAP), prm.RQAPMaxEmploye - cum.RQAP))
            r.EmployeurRQAP = Plancher0(Math.Min(Cents(prm.RQAPTauxEmployeur * r.GainsRQAP), prm.RQAPMaxEmployeur - cum.RQAPEmployeur))
        Else
            r.GainsRQAP = 0D
        End If

        ' ------------------------------------------------------------------
        ' 4. Impôt du Québec (TP-1015.F, partie 2.1)
        ' ------------------------------------------------------------------
        ' Le crédit pour fonds de travailleurs est annualisé tel quel (0,15 × P × Q) : c'est le total
        ' réellement retenu dans l'année qui ne doit pas dépasser 5 000 $ (voir l'annexe 1 du guide).
        Dim fondsAnnuel = P * retenuesFonds
        If Not emp.ExemptImpotQuebec Then
            Dim eQc = Math.Round(If(emp.TP1015Montant, prm.QcMontantPersonnelBase), 0, MidpointRounding.AwayFromZero)
            Dim h = Math.Min(Cents(prm.QcDeductionTravailleurTaux * gQc), Cents(prm.QcDeductionTravailleurMax / P))
            Dim iBase = Plancher0(P * (gQc - fQc - h - csa) - emp.TP1015DeductionsLigne19 - emp.TP1016Deductions)
            Dim creditsQc = emp.TP1016Credits + (prm.QcTauxCredits * eQc) + (prm.QcCreditFondsTravailleursTaux * fondsAnnuel)

            Dim y = Plancher0(ImpotSelonTranches(prm.QcTranches, iBase) - creditsQc)
            Dim impotRegulier = If(gQc > 0D, Cents(y / P), 0D)

            Dim impotForfaitaire As Decimal = 0D
            If bQcNet > 0D Then
                If (P * gQc) + cum.ForfaitairesQuebec + bQc <= prm.QcSeuilForfaitaireTauxFixe Then
                    impotForfaitaire = Cents(prm.QcTauxFixeForfaitaire * bQcNet)
                Else
                    Dim avant = iBase + cum.ForfaitairesQuebec - cum.CSBForfaitaires
                    Dim y1 = Plancher0(ImpotSelonTranches(prm.QcTranches, Plancher0(avant)) - creditsQc)
                    Dim y2 = Plancher0(ImpotSelonTranches(prm.QcTranches, Plancher0(avant + bQcNet - csb)) - creditsQc)
                    impotForfaitaire = Cents(y2 - y1)
                End If
            End If

            r.ImpotQuebec = Plancher0(impotRegulier + impotForfaitaire + emp.TP1015ImpotAdditionnel)

            r.Verification.Add(Ligne("QC  E (crédits personnels)", eQc))
            r.Verification.Add(Ligne("QC  H (déduction pour travailleur)", h))
            r.Verification.Add(Ligne("QC  CSA (cot. suppl. RRQ, régulier)", csa))
            r.Verification.Add(Ligne("QC  I (revenu imposable annuel)", iBase))
            r.Verification.Add(Ligne("QC  Y (impôt pour l'année)", y))
            r.Verification.Add(Ligne("QC  Impôt sur la rémunération régulière", impotRegulier))
            If bQcNet > 0D Then r.Verification.Add(Ligne("QC  Impôt sur le paiement forfaitaire", impotForfaitaire))
        End If

        ' ------------------------------------------------------------------
        ' 5. Impôt fédéral (T4127, option 1, employé du Québec)
        ' ------------------------------------------------------------------
        If Not emp.ExemptImpotFederal Then
            Dim tc = If(emp.TD1MontantDemande, prm.FedMontantPersonnelBase)
            Dim aBase = Plancher0(P * (gFed - fFed - csa) - emp.TD1DeductionZone - emp.TD1DeductionsAnnuelles)

            ' K2Q : crédits pour les cotisations de l'année au RRQ (partie de base), à l'AE et au RQAP
            Dim rrqTheorique As Decimal = 0D
            If assujettiRRQ Then rrqTheorique = Cents(Plancher0(prm.RRQTaux * ((s3 - s3Forf) - exemptionRRQ)))
            Dim aeTheorique As Decimal = If(emp.ExemptAE, 0D, Cents(prm.AETaux * RegulierDe(e, Function(cat) cat.AE)))
            Dim rqapTheorique As Decimal = If(emp.ExemptRQAP, 0D, prm.RQAPTauxEmploye * RegulierDe(e, Function(cat) cat.RQAP))
            Dim k2q = prm.FedTauxCredits * (
                Math.Min(P * rrqTheorique * (prm.RRQTauxBase / prm.RRQTaux), prm.RRQMaxBaseEmploye) +
                Math.Min(P * aeTheorique, prm.AEMaxEmploye) +
                Math.Min(P * rqapTheorique, prm.RQAPMaxEmploye))

            Dim k1 = prm.FedTauxCredits * tc
            Dim lcf = Math.Min(prm.FedCreditFondsTravailleursMax, prm.FedCreditFondsTravailleursTaux * P * retenuesFonds)
            Dim creditsFixes = k1 + k2q + emp.TD1AutresCredits

            Dim t1 = ImpotFederalAnnuel(prm, aBase, creditsFixes, lcf)
            Dim impotRegulier = If(gFed > 0D, Cents(t1 / P), 0D)

            Dim impotForfaitaire As Decimal = 0D
            If bFedNet > 0D Then
                If (P * gFed) + cum.ForfaitairesFederal + bFed <= prm.FedSeuilForfaitaireTauxFixe Then
                    impotForfaitaire = Cents(prm.FedTauxFixeForfaitaireQuebec * bFedNet)
                Else
                    Dim avant = aBase + cum.ForfaitairesFederal - cum.CSBForfaitaires
                    Dim tAvant = ImpotFederalAnnuel(prm, Plancher0(avant), creditsFixes, lcf)
                    Dim tApres = ImpotFederalAnnuel(prm, Plancher0(avant + bFedNet - csb), creditsFixes, lcf)
                    impotForfaitaire = Cents(Plancher0(tApres - tAvant))
                End If
            End If

            r.ImpotFederal = Plancher0(impotRegulier + impotForfaitaire + emp.TD1ImpotAdditionnel)

            r.Verification.Add(Ligne("FED TC (montant de la demande TD1)", tc))
            r.Verification.Add(Ligne("FED A (revenu imposable annuel)", aBase))
            r.Verification.Add(Ligne("FED K1", k1))
            r.Verification.Add(Ligne("FED K2Q", k2q))
            r.Verification.Add(Ligne("FED T1 (impôt fédéral annuel après abattement)", t1))
            r.Verification.Add(Ligne("FED Impôt sur la rémunération régulière", impotRegulier))
            If bFedNet > 0D Then r.Verification.Add(Ligne("FED Impôt sur le paiement forfaitaire", impotForfaitaire))
        End If

        ' ------------------------------------------------------------------
        ' 6. Cotisations de l'employeur : FSS, CNESST, CNT
        ' ------------------------------------------------------------------
        If Not emp.ExemptFSS Then
            r.EmployeurFSS = Cents(r.GainsFSS * e.Employeur.TauxFSS / 100D)
        Else
            r.GainsFSS = 0D
        End If

        If Not emp.ExemptCNESST Then
            r.GainsCNESST = Math.Min(r.GainsCNESST, Plancher0(prm.CNESSTMaxAssurable - cum.GainsCNESST))
            r.EmployeurCNESST = Cents(r.GainsCNESST * e.Employeur.TauxCNESST / 100D)
            If e.Employeur.AssujettiCNT Then r.EmployeurCNT = Cents(r.GainsCNESST * prm.CNTTaux)
        Else
            r.GainsCNESST = 0D
        End If

        ' ------------------------------------------------------------------
        ' 7. Vacances et paie nette
        ' ------------------------------------------------------------------
        r.VacancesAccumulees = Cents(r.GainsVacances * e.TauxVacances / 100D)
        r.Net = r.BrutVerse - r.TotalRetenues

        r.Verification.Insert(0, Ligne("RRQ S3 (salaire admissible)", s3))
        r.Verification.Insert(1, Ligne("RRQ exemption par période", exemptionRRQ))
        r.Verification.Insert(2, Ligne("RRQ CS (cotisations supplémentaires déductibles)", cs))

        Dim exemptions As New List(Of String)()
        If emp.ExemptImpotFederal Then exemptions.Add("impôt fédéral")
        If emp.ExemptImpotQuebec Then exemptions.Add("impôt du Québec")
        If emp.ExemptRRQ Then exemptions.Add("RRQ")
        If emp.ExemptRQAP Then exemptions.Add("RQAP")
        If emp.ExemptAE Then exemptions.Add("assurance-emploi")
        If emp.ExemptFSS Then exemptions.Add("FSS")
        If emp.ExemptCNESST Then exemptions.Add("CNESST / CNT")
        If exemptions.Count > 0 Then
            r.Avertissements.Add("Exemptions cochées dans la fiche de l'employé, donc non calculé : " & String.Join(", ", exemptions) & ".")
        End If
        If assujettiRRQ = False AndAlso Not emp.ExemptRRQ Then
            r.Avertissements.Add("Employé de moins de 18 ans : aucune cotisation au RRQ.")
        End If

        If r.Net < 0D Then
            r.Avertissements.Add("La paie nette est négative : les retenues et déductions dépassent la rémunération versée.")
        End If
        Return r
    End Function

    ''' <summary>T1 : impôt fédéral annuel d'un employé du Québec, après crédits et abattement de 16,5 %.</summary>
    Private Shared Function ImpotFederalAnnuel(prm As ParametresAnnee, a As Decimal, creditsFixes As Decimal, lcf As Decimal) As Decimal
        Dim k4 = Math.Min(prm.FedTauxCredits * a, prm.FedTauxCredits * prm.FedMontantEmploi)
        Dim t3 = Plancher0(ImpotSelonTranches(prm.FedTranches, a) - creditsFixes - k4)
        Return Plancher0(Plancher0(t3 - lcf) - (prm.FedAbattementQuebec * t3))
    End Function

    ''' <summary>(T × I) – K pour la tranche applicable.</summary>
    Public Shared Function ImpotSelonTranches(tranches As Tranche(), revenu As Decimal) As Decimal
        For Each t In tranches
            If revenu <= t.SeuilMax Then Return (t.Taux * revenu) - t.Constante
        Next
        Dim derniere = tranches(tranches.Length - 1)
        Return (derniere.Taux * revenu) - derniere.Constante
    End Function

    Private Shared Function RegulierDe(e As EntreePaie, assujetti As Func(Of CategoriePaie, Boolean)) As Decimal
        Dim total As Decimal = 0D
        For Each l In e.Lignes
            Dim cat = CategoriePaie.ParCode(l.CodeCategorie)
            If cat.Type <> TypeCategorie.Deduction AndAlso Not cat.Forfaitaire AndAlso assujetti(cat) Then total += l.Montant
        Next
        Return total
    End Function

    Private Shared Function A18AnsOuPlus(dateNaissance As Date?, datePaie As Date) As Boolean
        If Not dateNaissance.HasValue Then Return True
        Return dateNaissance.Value.AddYears(18) <= datePaie
    End Function

    Private Shared Function Ligne(libelle As String, valeur As Decimal) As String
        Return libelle.PadRight(52) & valeur.ToString("N2", CultureInfo.GetCultureInfo("fr-CA")).PadLeft(14)
    End Function

End Class
