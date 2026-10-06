Imports System.Globalization

''' <summary>
''' Calcul d'une paie, selon la province d'emploi.
'''
''' QUÉBEC. Impôt du Québec, RRQ, RQAP et FSS : formules du guide TP-1015.F (Revenu Québec).
''' Impôt fédéral et assurance-emploi : formules du guide T4127 (ARC), variante Québec
''' (abattement de 16,5 %, crédit K2Q, taux d'AE réduit).
'''
''' ONTARIO. Tout vient du guide T4127 (ARC), option 1 : impôt fédéral sans abattement,
''' impôt de l'Ontario (surtaxe, contribution-santé et réduction d'impôt comprises), RPC et
''' deuxième cotisation supplémentaire, AE au taux ordinaire. Pas de RQAP ni de CNT.
''' L'employeur paie en plus l'impôt-santé des employeurs (ISE) et la prime de la WSIB.
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
        If e.Province = Province.Quebec Then Return CalculerQuebec(e, prm)

        prm.Exiger(e.Province)
        Dim pp = prm.PourProvince(e.Province, e.DatePaie)
        If pp Is Nothing Then
            Throw New NotSupportedException(
                "Les taux de l'année " & prm.Annee.ToString() & " pour la province « " & Provinces.Nom(e.Province) &
                " » ne sont pas en vigueur à la date de la paie (" & e.DatePaie.ToString("yyyy-MM-dd") & ").")
        End If
        Return CalculerHorsQuebec(e, prm, pp)
    End Function

    ' ======================================================================
    ' QUÉBEC
    ' ======================================================================

    Private Shared Function CalculerQuebec(e As EntreePaie, prm As ParametresAnnee) As ResultatPaie
        Dim P As Decimal = e.PeriodesParAnnee
        Dim emp = e.Employe
        Dim cum = e.Cumul
        Dim r As New ResultatPaie With {.Province = Province.Quebec}

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

    ' ======================================================================
    ' HORS QUÉBEC : Ontario et toutes les autres provinces et territoires (T4127, option 1)
    ' ======================================================================

    Private Shared Function CalculerHorsQuebec(e As EntreePaie, prm As ParametresAnnee, pp As ParametresProvince) As ResultatPaie
        Dim P As Decimal = e.PeriodesParAnnee
        Dim emp = e.Employe
        Dim cum = e.Cumul
        Dim r As New ResultatPaie With {.Province = e.Province}
        Dim noms = LibellesProvince.Pour(e.Province)
        Dim sigle = Provinces.Code(e.Province).PadRight(3)

        ' ------------------------------------------------------------------
        ' 1. Ventilation des lignes selon l'assujettissement de leur catégorie
        ' ------------------------------------------------------------------
        ' Hors Québec, le revenu imposable est le même aux deux paliers : la colonne
        ' « impôt fédéral » de la catégorie vaut aussi pour l'impôt de la province.
        Dim g, b As Decimal                ' rémunération imposable régulière (I) et forfaitaire (B)
        Dim gainsPension, gainsPensionForf As Decimal   ' gains ouvrant droit à pension (PI), dont la part forfaitaire
        Dim f, fForf As Decimal            ' déductions qui réduisent le revenu imposable (F, U1)
        Dim retenuesFonds As Decimal
        Dim ignorees As New List(Of String)()

        For Each l In e.Lignes
            Dim cat = CategoriePaie.ParCode(l.CodeCategorie)
            Dim m = l.Montant

            If cat.Type = TypeCategorie.Deduction Then
                r.AutresDeductions += m
                If cat.ImpotFederal Then
                    If l.SurForfaitaire Then fForf += m Else f += m
                End If
                If cat.Fonds <> FondsTravailleurs.Aucun Then retenuesFonds += m
                Continue For
            End If

            ' Un avantage imposable au Québec seulement (part de l'employeur à un régime privé
            ' d'assurance maladie) n'est pas un avantage ailleurs : il ne compte pour rien.
            If cat.Type = TypeCategorie.Avantage AndAlso Not cat.ImpotFederal Then
                ignorees.Add(If(String.IsNullOrWhiteSpace(l.Description), cat.Libelle, l.Description))
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
                If cat.Forfaitaire Then b += m Else g += m
            End If
            If cat.RRQ Then
                gainsPension += m
                If cat.Forfaitaire Then gainsPensionForf += m
            End If
            If cat.AE Then r.GainsAE += m
            If cat.FSS Then r.GainsFSS += m
            If cat.CNESST Then r.GainsCNESST += m
            ' Hors Québec : l'indemnité de vacances se calcule sur le salaire brut, sans la paie de vacances elle-même.
            If cat.Vacances AndAlso Not cat.PaieVacances Then r.GainsVacances += m
            If cat.PaieVacances Then r.VacancesPayees += m
        Next

        ' Une déduction supérieure à la rémunération régulière réduit le forfaitaire.
        Dim bNet = Plancher0(b - fForf - Plancher0(f - g))
        If f > g Then f = g

        r.GainsRRQ = gainsPension
        r.BrutImposableFederal = g + b
        r.BrutImposableQuebec = g + b
        r.ForfaitairesFederal = bNet
        r.ForfaitairesQuebec = bNet

        ' ------------------------------------------------------------------
        ' 2. RPC et deuxième cotisation supplémentaire (T4127, chapitre 6)
        ' ------------------------------------------------------------------
        Dim assujettiRPC = Not emp.ExemptRRQ AndAlso DansLAgeDuRPC(emp.DateNaissance, e.DatePaie)
        Dim exemptionRPC = Tronquer2(prm.RPCExemption / P)
        Dim c, c2 As Decimal
        If assujettiRPC AndAlso gainsPension > 0D Then
            c = Cents(Plancher0(prm.RPCTaux * (gainsPension - exemptionRPC)))
            c = Plancher0(Math.Min(c, prm.RPCMaxEmploye - cum.RRQ))

            Dim w = Math.Max(cum.GainsRRQ, prm.RPCMaxGainsAdmissibles)
            c2 = Cents(Plancher0(prm.RPC2Taux * (cum.GainsRRQ + gainsPension - w)))
            c2 = Plancher0(Math.Min(c2, prm.RPC2MaxEmploye - cum.RRQ2))
        Else
            r.GainsRRQ = 0D
        End If
        r.RRQ = c
        r.RRQ2 = c2
        r.EmployeurRRQ = c
        r.EmployeurRRQ2 = c2

        ' F5 : les cotisations bonifiées au RPC se déduisent du revenu imposable (les cotisations
        ' de base, elles, donnent un crédit). F5A va au régulier, F5B au forfaitaire.
        Dim f5 = CentsExacts(c * ((prm.RPCTaux - prm.RPCTauxBase) / prm.RPCTaux) + c2)
        Dim f5a As Decimal = f5
        Dim f5b As Decimal = 0D
        If gainsPension > 0D AndAlso gainsPensionForf > 0D Then
            f5a = CentsExacts(f5 * (gainsPension - gainsPensionForf) / gainsPension)
            f5b = f5 - f5a
        End If
        r.CSBForfaitaires = f5b

        ' ------------------------------------------------------------------
        ' 3. Assurance-emploi (taux hors Québec). Pas de RQAP hors Québec.
        ' ------------------------------------------------------------------
        If Not emp.ExemptAE AndAlso r.GainsAE > 0D Then
            r.AE = Plancher0(Math.Min(Cents(prm.AETauxHorsQuebec * r.GainsAE), prm.AEMaxEmployeHorsQuebec - cum.AE))
            r.EmployeurAE = Cents(r.AE * e.Employeur.FacteurAE)
        Else
            r.GainsAE = 0D
        End If

        ' Territoires du Nord-Ouest et Nunavut : impôt de 2 % sur la paie, retenu sur toute la rémunération
        ' imposable et remis au territoire. Il occupe le champ du RQAP, qui n'existe pas hors Québec.
        If pp.TaxePaieEmployeTaux > 0D AndAlso Not emp.ExemptRQAP Then
            r.GainsRQAP = g + b
            r.RQAP = Cents(pp.TaxePaieEmployeTaux * r.GainsRQAP)
        End If

        ' ------------------------------------------------------------------
        ' 4. Impôt fédéral (T1) et impôt de la province (T2)
        ' ------------------------------------------------------------------
        ' A : revenu imposable annuel, commun aux deux paliers.
        Dim aBase = Plancher0(P * (g - f - f5a) - emp.TD1DeductionZone - emp.TD1DeductionsAnnuelles)

        ' K2 et K2P : crédits pour les cotisations de l'année au RPC (partie de base) et à l'AE,
        ' établis sur les cotisations théoriques de la période, annualisées.
        Dim rpcTheorique As Decimal = 0D
        If assujettiRPC Then rpcTheorique = Cents(Plancher0(prm.RPCTaux * ((gainsPension - gainsPensionForf) - exemptionRPC)))
        Dim aeTheorique As Decimal = If(emp.ExemptAE, 0D, Cents(prm.AETauxHorsQuebec * RegulierDe(e, Function(cat) cat.AE)))
        Dim cotisationsCreditees =
            Math.Min(P * rpcTheorique * prm.RPCTauxBase / prm.RPCTaux, prm.RPCMaxBaseEmploye) +
            Math.Min(P * aeTheorique, prm.AEMaxEmployeHorsQuebec)

        Dim tc = If(emp.TD1MontantDemande, prm.FedMontantPersonnelBase)
        Dim k1 = prm.FedTauxCredits * tc
        Dim k2 = prm.FedTauxCredits * cotisationsCreditees
        Dim lcf = Math.Min(prm.FedCreditFondsTravailleursMax, prm.FedCreditFondsTravailleursTaux * P * retenuesFonds)
        Dim creditsFed = k1 + k2 + emp.TD1AutresCredits

        ' L'impôt de la province pour un revenu annuel : le montant de base, quand l'employé n'en demande
        ' pas d'autre, peut dépendre du revenu (Manitoba) — il se recalcule donc pour chaque revenu.
        Dim y = pp.ReductionParPersonne * Math.Max(0, emp.TD1ProvPersonnesACharge)
        Dim impotProvince As Func(Of Decimal, DetailImpotOntario) =
            Function(revenu) ImpotProvincialAnnuel(pp, prm, revenu, emp.TD1ProvMontantDemande, cotisationsCreditees, emp.TD1ProvAutresCredits, y)

        ' Gratification ou rétroactif (T4127, méthode des gratifications) : l'impôt sur le
        ' forfaitaire est l'écart entre l'impôt de l'année avec et sans lui. Si la rémunération
        ' de l'année ne dépasse pas le seuil, le guide prévoit un taux unique de 15 % pour les
        ' deux paliers réunis ; il est réparti ici entre le fédéral (le taux retenu au Québec,
        ' 10 %) et la province (le reste, 5 %).
        Dim tauxFixe = bNet > 0D AndAlso (P * g) + cum.ForfaitairesFederal + b <= prm.FedSeuilForfaitaireTauxFixe
        Dim avant = Plancher0(aBase + cum.ForfaitairesFederal - cum.CSBForfaitaires)
        Dim apres = Plancher0(aBase + cum.ForfaitairesFederal - cum.CSBForfaitaires + bNet - f5b)

        If Not emp.ExemptImpotFederal Then
            ' Les impôts de la période sortent d'une division ou d'une différence : arrondi qui respecte le demi-cent.
            Dim t1 = ImpotFederalAnnuelHorsQuebec(prm, aBase, creditsFed, lcf)
            Dim impotRegulier = If(g > 0D, CentsExacts(t1 / P), 0D)

            Dim impotForfaitaire As Decimal = 0D
            If tauxFixe Then
                impotForfaitaire = Cents(prm.FedTauxFixeForfaitaireQuebec * bNet)
            ElseIf bNet > 0D Then
                impotForfaitaire = CentsExacts(Plancher0(ImpotFederalAnnuelHorsQuebec(prm, apres, creditsFed, lcf) -
                                                         ImpotFederalAnnuelHorsQuebec(prm, avant, creditsFed, lcf)))
            End If

            r.ImpotFederal = Plancher0(impotRegulier + impotForfaitaire + emp.TD1ImpotAdditionnel)

            r.Verification.Add(Ligne("FED TC (montant de la demande TD1)", tc))
            r.Verification.Add(Ligne("FED A (revenu imposable annuel)", aBase))
            r.Verification.Add(Ligne("FED K1", k1))
            r.Verification.Add(Ligne("FED K2 (crédits RPC et AE)", k2))
            r.Verification.Add(Ligne("FED T1 (impôt fédéral annuel)", t1))
            r.Verification.Add(Ligne("FED Impôt sur la rémunération régulière", impotRegulier))
            If bNet > 0D Then r.Verification.Add(Ligne("FED Impôt sur le paiement forfaitaire", impotForfaitaire))
        End If

        If Not emp.ExemptImpotQuebec Then
            Dim d = impotProvince(aBase)
            Dim impotRegulier = If(g > 0D, CentsExacts(d.T2 / P), 0D)

            Dim impotForfaitaire As Decimal = 0D
            If tauxFixe Then
                impotForfaitaire = Cents(Plancher0(prm.FedTauxFixeForfaitaireHorsQuebec - prm.FedTauxFixeForfaitaireQuebec) * bNet)
            ElseIf bNet > 0D Then
                impotForfaitaire = CentsExacts(Plancher0(impotProvince(apres).T2 - impotProvince(avant).T2))
            End If

            r.ImpotQuebec = Plancher0(impotRegulier + impotForfaitaire)

            r.Verification.Add(Ligne(sigle & " TCP (montant de la demande " & noms.FormulaireCredits & ")", d.TCP))
            r.Verification.Add(Ligne(sigle & " K1P", d.K1P))
            r.Verification.Add(Ligne(sigle & " K2P (crédits RPC et AE)", d.K2P))
            If d.K4P <> 0D Then r.Verification.Add(Ligne(sigle & " K4P (crédit pour emploi)", d.K4P))
            If d.K5P <> 0D Then r.Verification.Add(Ligne(sigle & " K5P (crédit supplémentaire)", d.K5P))
            r.Verification.Add(Ligne(sigle & " T4 (impôt de base)", d.T4))
            If d.V1 <> 0D OrElse e.Province = Province.Ontario Then r.Verification.Add(Ligne(sigle & " V1 (surtaxe)", d.V1))
            If d.V2 <> 0D OrElse e.Province = Province.Ontario Then r.Verification.Add(Ligne(sigle & " V2 (contribution-santé)", d.V2))
            If d.S <> 0D OrElse e.Province = Province.Ontario Then r.Verification.Add(Ligne(sigle & " S (réduction d'impôt)", d.S))
            r.Verification.Add(Ligne(sigle & " T2 (impôt annuel " & Provinces.DeNom(e.Province) & ")", d.T2))
            r.Verification.Add(Ligne(sigle & " Impôt sur la rémunération régulière", impotRegulier))
            If bNet > 0D Then r.Verification.Add(Ligne(sigle & " Impôt sur le paiement forfaitaire", impotForfaitaire))
        End If

        ' ------------------------------------------------------------------
        ' 5. Cotisations de l'employeur : cotisation santé (ISE et équivalents) et accidents du travail
        ' ------------------------------------------------------------------
        If Not emp.ExemptFSS Then
            r.EmployeurFSS = Cents(r.GainsFSS * e.Employeur.TauxFSS / 100D)
        Else
            r.GainsFSS = 0D
        End If

        If Not emp.ExemptCNESST Then
            ' Plafond annuel de la commission des accidents du travail ; 0 = aucun plafond connu.
            If pp.AccidentsMaxAssurable > 0D Then r.GainsCNESST = Math.Min(r.GainsCNESST, Plancher0(pp.AccidentsMaxAssurable - cum.GainsCNESST))
            r.EmployeurCNESST = Cents(r.GainsCNESST * e.Employeur.TauxCNESST / 100D)
        Else
            r.GainsCNESST = 0D
        End If

        ' ------------------------------------------------------------------
        ' 6. Vacances et paie nette
        ' ------------------------------------------------------------------
        r.VacancesAccumulees = Cents(r.GainsVacances * e.TauxVacances / 100D)
        r.Net = r.BrutVerse - r.TotalRetenues

        r.Verification.Insert(0, Ligne("RPC PI (gains ouvrant droit à pension)", gainsPension))
        r.Verification.Insert(1, Ligne("RPC exemption par période", exemptionRPC))
        r.Verification.Insert(2, Ligne("RPC F5 (cotisations bonifiées déductibles)", f5))

        Dim exemptions As New List(Of String)()
        If emp.ExemptImpotFederal Then exemptions.Add("impôt fédéral")
        If emp.ExemptImpotQuebec Then exemptions.Add("impôt " & Provinces.DeNom(e.Province))
        If emp.ExemptRRQ Then exemptions.Add("RPC")
        If emp.ExemptAE Then exemptions.Add("assurance-emploi")
        If emp.ExemptRQAP AndAlso pp.TaxePaieEmployeTaux > 0D Then exemptions.Add("impôt sur la paie")
        If emp.ExemptFSS AndAlso noms.ASante Then exemptions.Add(noms.Sante)
        If emp.ExemptCNESST Then exemptions.Add(noms.Accidents)
        If exemptions.Count > 0 Then
            r.Avertissements.Add("Exemptions cochées dans la fiche de l'employé, donc non calculé : " & String.Join(", ", exemptions) & ".")
        End If
        If Not emp.ExemptRRQ AndAlso Not assujettiRPC Then
            Dim n = emp.DateNaissance.Value
            If e.DatePaie < New Date(n.Year, n.Month, 1).AddYears(18).AddMonths(1) Then
                r.Avertissements.Add("Employé de moins de 18 ans : aucune cotisation au RPC avant le mois qui suit son 18e anniversaire.")
            Else
                r.Avertissements.Add("Employé de plus de 70 ans : aucune cotisation au RPC.")
            End If
        End If
        If ignorees.Count > 0 Then
            r.Avertissements.Add("Avantage imposable au Québec seulement, ignoré hors Québec : " & String.Join(", ", ignorees) & ".")
        End If

        If r.Net < 0D Then
            r.Avertissements.Add("La paie nette est négative : les retenues et déductions dépassent la rémunération versée.")
        End If
        Return r
    End Function

    ''' <summary>T1 hors Québec : impôt fédéral annuel après crédits, sans abattement.</summary>
    Private Shared Function ImpotFederalAnnuelHorsQuebec(prm As ParametresAnnee, a As Decimal, creditsFixes As Decimal, lcf As Decimal) As Decimal
        Dim k4 = Math.Min(prm.FedTauxCredits * a, prm.FedTauxCredits * prm.FedMontantEmploi)
        Dim t3 = Plancher0(ImpotSelonTranches(prm.FedTranches, a) - creditsFixes - k4)
        Return Plancher0(t3 - lcf)
    End Function

    ''' <summary>
    ''' Les composantes de l'impôt annuel d'une province, gardées pour le rapport de vérification.
    ''' (Le nom date de l'Ontario, première province ajoutée après le Québec.)
    ''' </summary>
    Public Structure DetailImpotOntario
        ''' <summary>Montant de la demande : celui de l'employé, sinon le montant personnel de base.</summary>
        Public TCP As Decimal
        Public K1P As Decimal
        Public K2P As Decimal
        ''' <summary>Crédit canadien pour emploi au palier territorial (Yukon).</summary>
        Public K4P As Decimal
        ''' <summary>Crédit supplémentaire (Alberta).</summary>
        Public K5P As Decimal
        ''' <summary>Impôt de base, après crédits.</summary>
        Public T4 As Decimal
        ''' <summary>Surtaxe.</summary>
        Public V1 As Decimal
        ''' <summary>Contribution-santé de l'Ontario.</summary>
        Public V2 As Decimal
        ''' <summary>Réduction d'impôt.</summary>
        Public S As Decimal
        ''' <summary>Impôt de l'Ontario pour l'année.</summary>
        Public T2 As Decimal
    End Structure

    ''' <summary>
    ''' T2 = T4 + V1 + V2 – S (T4127, Ontario). <paramref name="credits"/> réunit K1P, K2P et K3P ;
    ''' <paramref name="y"/> est la part de la réduction d'impôt accordée pour les personnes à charge.
    ''' </summary>
    Public Shared Function ImpotOntarioAnnuel(prm As ParametresAnnee, a As Decimal, credits As Decimal, y As Decimal) As DetailImpotOntario
        Return ImpotProvincialSelonCredits(prm.PourProvince(Province.Ontario, New Date(prm.Annee, 1, 1)), a, credits, y)
    End Function

    ''' <summary>
    ''' L'impôt annuel d'une province hors Québec pour un revenu imposable <paramref name="a"/> :
    ''' crédits K1P (montant de la demande), K2P (RPC et AE), K3P (autres crédits autorisés),
    ''' K4P (crédit pour emploi, Yukon) et K5P (crédit supplémentaire, Alberta), puis surtaxe,
    ''' contribution-santé et réduction d'impôt là où elles existent.
    ''' </summary>
    Public Shared Function ImpotProvincialAnnuel(pp As ParametresProvince, prm As ParametresAnnee, a As Decimal, montantDemande As Decimal?,
                                                 cotisationsCreditees As Decimal, autresCredits As Decimal, y As Decimal) As DetailImpotOntario
        Dim tcp = If(montantDemande, pp.MontantBasePour(a))
        Dim k1p = pp.TauxCredits * tcp
        Dim k2p = pp.TauxCredits * cotisationsCreditees
        Dim k4p As Decimal = 0D
        If pp.CreditEmploi Then k4p = Math.Min(pp.TauxCredits * a, pp.TauxCredits * prm.FedMontantEmploi)
        Dim k5p As Decimal = 0D
        If pp.CreditSupplTaux > 0D Then k5p = Plancher0(((k1p + k2p) - pp.CreditSupplSeuil) * pp.CreditSupplTaux)

        Dim d = ImpotProvincialSelonCredits(pp, a, k1p + k2p + autresCredits + k4p + k5p, y)
        d.TCP = tcp
        d.K1P = k1p
        d.K2P = k2p
        d.K4P = k4p
        d.K5P = k5p
        Return d
    End Function

    Private Shared Function ImpotProvincialSelonCredits(pp As ParametresProvince, a As Decimal, credits As Decimal, y As Decimal) As DetailImpotOntario
        Dim d As New DetailImpotOntario()
        d.T4 = Plancher0(ImpotSelonTranches(pp.Tranches, a) - credits)

        ' V1 : surtaxe sur l'impôt de base (Ontario).
        d.V1 = (pp.SurtaxeTaux1 * Plancher0(d.T4 - pp.SurtaxeSeuil1)) + (pp.SurtaxeTaux2 * Plancher0(d.T4 - pp.SurtaxeSeuil2))

        ' V2 : contribution-santé, selon le revenu imposable (Ontario).
        d.V2 = ContributionSante(pp.ContributionSante, a)

        Dim impotAvantReduction = d.T4 + d.V1
        If pp.ReductionBase > 0D OrElse pp.ReductionParPersonne > 0D Then
            ' S (Ontario) : le moindre de (T4 + V1) et de 2 × (montant de base + Y) – (T4 + V1), jamais négatif.
            d.S = Plancher0(Math.Min(impotAvantReduction, (2D * (pp.ReductionBase + y)) - impotAvantReduction))
        ElseIf pp.ReductionRevenuMontant > 0D Then
            ' S (Colombie-Britannique) : montant fixe pour les bas revenus, réduit à mesure que le revenu monte.
            If a <= pp.ReductionRevenuSeuil Then
                d.S = Math.Min(d.T4, pp.ReductionRevenuMontant)
            ElseIf a <= pp.ReductionRevenuFin Then
                d.S = Plancher0(Math.Min(d.T4, pp.ReductionRevenuMontant - ((a - pp.ReductionRevenuSeuil) * pp.ReductionRevenuTaux)))
            End If
        End If

        ' La réduction se retranche AVANT d'ajouter la contribution-santé : quand elle efface tout l'impôt
        ' de base (bas salaire, personnes à charge), la soustraction est exacte et il ne reste que V2.
        ' Dans l'autre ordre, les décimales de T4 feraient perdre un cent sur un montant qui tombe pile au demi-cent.
        d.T2 = Plancher0((impotAvantReduction - d.S) + d.V2)
        Return d
    End Function

    ''' <summary>Contribution-santé de l'Ontario pour un revenu imposable annuel (facteur V2).</summary>
    Public Shared Function ContributionSanteOntario(prm As ParametresAnnee, a As Decimal) As Decimal
        Return ContributionSante(prm.OnContributionSante, a)
    End Function

    Private Shared Function ContributionSante(paliers As PalierContributionSante(), a As Decimal) As Decimal
        Dim v2 As Decimal = 0D
        If paliers Is Nothing Then Return v2
        For Each palier In paliers
            If a <= palier.Seuil Then Exit For
            v2 = Math.Min(palier.Plafond, palier.Base + (palier.Taux * (a - palier.Seuil)))
        Next
        Return v2
    End Function

    ''' <summary>
    ''' RPC : on cotise à compter de la première paie datée du mois qui suit le 18e anniversaire,
    ''' et jusqu'à la dernière paie datée du mois du 70e anniversaire.
    ''' </summary>
    Private Shared Function DansLAgeDuRPC(dateNaissance As Date?, datePaie As Date) As Boolean
        If Not dateNaissance.HasValue Then Return True
        Dim n = dateNaissance.Value
        Dim debut = New Date(n.Year, n.Month, 1).AddYears(18).AddMonths(1)
        Dim fin = New Date(n.Year, n.Month, 1).AddYears(70).AddMonths(1)
        Return datePaie >= debut AndAlso datePaie < fin
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
