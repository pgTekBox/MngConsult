Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports Paie60Sec.Calcul

''' <summary>
''' Paie d'un employé de l'Ontario : formules du guide T4127 (122e édition, 1er janvier 2026), option 1.
''' Les montants attendus ont été calculés à la main à partir du guide ; le détail figure dans chaque test.
''' À comparer aussi, avant la production, avec le calculateur en ligne de l'ARC (PDOC).
''' </summary>
<TestClass>
Public Class OntarioTests

    Private Shared Function Entree(periodes As Integer) As EntreePaie
        Dim e As New EntreePaie()
        e.Province = Province.Ontario
        e.Annee = 2026
        e.PeriodesParAnnee = periodes
        e.DatePaie = New Date(2026, 3, 5)
        e.Employeur.TauxCNESST = 0D
        e.Employeur.TauxFSS = 0D
        Return e
    End Function

    Private Shared Sub Ajouter(e As EntreePaie, code As String, montant As Decimal, Optional surForfaitaire As Boolean = False)
        e.Lignes.Add(New LignePaie With {.CodeCategorie = code, .Montant = montant, .SurForfaitaire = surForfaitaire})
    End Sub

    Private Shared Function Salaire(periodes As Integer, montant As Decimal) As EntreePaie
        Dim e = Entree(periodes)
        Ajouter(e, "SALAIRE", montant)
        Return e
    End Function

    ''' <summary>
    ''' 2 000 $ aux 2 semaines, demandes de base.
    '''   C  = 0,0595 × (2 000 – 134,61) = 110,99 ; AE = 0,0163 × 2 000 = 32,60
    '''   F5 = 110,99 × (0,01 ÷ 0,0595) = 18,65 ; A = 26 × (2 000 – 18,65) = 51 515,10
    '''   Crédits : RPC de base 26 × 110,99 × (0,0495 ÷ 0,0595) = 2 400,74 ; AE 26 × 32,60 = 847,60
    '''   Fédéral : 7 212,11 – 2 303,28 (K1) – 454,77 (K2) – 210,14 (K4) = 4 243,92 → 163,23 par paie
    '''   Ontario : T4 = 2 601,51 – 655,94 (K1P) – 164,04 (K2P) = 1 781,53 ; V1 = 0 ; V2 = 600 ; S = 0
    '''             T2 = 2 381,53 → 91,60 par paie
    ''' </summary>
    <TestMethod>
    Public Sub Salaire2000Aux2Semaines()
        Dim r = MoteurPaie.Calculer(Salaire(26, 2000D))
        Assert.AreEqual(Province.Ontario, r.Province)
        Assert.AreEqual(110.99D, r.RRQ, "RPC")
        Assert.AreEqual(110.99D, r.EmployeurRRQ, "RPC de l'employeur")
        Assert.AreEqual(0D, r.RRQ2)
        Assert.AreEqual(32.6D, r.AE)
        Assert.AreEqual(45.64D, r.EmployeurAE, "AE de l'employeur : 1,4 fois")
        Assert.AreEqual(163.23D, r.ImpotFederal)
        Assert.AreEqual(91.6D, r.ImpotQuebec, "impôt de l'Ontario")
        Assert.AreEqual(2000D - 110.99D - 32.6D - 163.23D - 91.6D, r.Net)
    End Sub

    ''' <summary>Ce qui n'existe qu'au Québec reste à zéro : RQAP et normes du travail (CNT).</summary>
    <TestMethod>
    Public Sub NiRQAPNiCNT()
        Dim e = Salaire(26, 2000D)
        e.Employeur.TauxCNESST = 1.5D
        e.Employeur.AssujettiCNT = True
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(0D, r.RQAP)
        Assert.AreEqual(0D, r.EmployeurRQAP)
        Assert.AreEqual(0D, r.GainsRQAP)
        Assert.AreEqual(0D, r.EmployeurCNT)
        Assert.AreEqual(30D, r.EmployeurCNESST, "WSIB : 1,50 $ par 100 $ sur 2 000 $")
    End Sub

    ''' <summary>
    ''' Même salaire, deux provinces : le fédéral n'a pas d'abattement en Ontario, l'AE y est
    ''' plus chère, et le régime de pension n'a pas le même taux.
    ''' </summary>
    <TestMethod>
    Public Sub OntarioNEstPasLeQuebec()
        Dim on_ = MoteurPaie.Calculer(Salaire(26, 2000D))
        Dim qcEntree = Salaire(26, 2000D)
        qcEntree.Province = Province.Quebec
        Dim qc = MoteurPaie.Calculer(qcEntree)

        Assert.AreEqual(117.52D, qc.RRQ)
        Assert.AreEqual(110.99D, on_.RRQ)
        Assert.AreEqual(26D, qc.AE)
        Assert.AreEqual(32.6D, on_.AE)
        Assert.AreEqual(135.3D, qc.ImpotFederal)
        Assert.IsTrue(on_.ImpotFederal > qc.ImpotFederal, "sans abattement de 16,5 %, l'impôt fédéral est plus élevé")
        Assert.IsTrue(qc.RQAP > 0D)
    End Sub

    ''' <summary>
    ''' 600 $ par semaine : A = 30 922,84 ; contribution-santé = le moindre de 300 et 0,06 × (A – 20 000) = 300.
    ''' Fédéral 29,86 ; Ontario (810,72 + 300) ÷ 52 = 21,36.
    ''' </summary>
    <TestMethod>
    Public Sub PetitSalaireHebdomadaire()
        Dim r = MoteurPaie.Calculer(Salaire(52, 600D))
        Assert.AreEqual(31.7D, r.RRQ)
        Assert.AreEqual(9.78D, r.AE)
        Assert.AreEqual(29.86D, r.ImpotFederal)
        Assert.AreEqual(21.36D, r.ImpotQuebec)
    End Sub

    ''' <summary>
    ''' 4 000 $ aux 2 semaines : A = 102 995,10, deuxième tranche de l'Ontario, première marche de la surtaxe.
    '''   T4 = 0,0915 × A – 2 210 – 655,94 – 198,29 = 6 323,66 ; V1 = 0,20 × (6 323,66 – 5 818) = 101,13 ; V2 = 750
    '''   T2 = 7 174,79 → 275,95 ; fédéral 544,10.
    ''' </summary>
    <TestMethod>
    Public Sub Surtaxe_PremierPalier()
        Dim r = MoteurPaie.Calculer(Salaire(26, 4000D))
        Assert.AreEqual(229.99D, r.RRQ)
        Assert.AreEqual(65.2D, r.AE)
        Assert.AreEqual(544.1D, r.ImpotFederal)
        Assert.AreEqual(275.95D, r.ImpotQuebec)
    End Sub

    ''' <summary>
    ''' 20 000 $ par mois : dernière tranche des deux barèmes, les deux marches de la surtaxe
    ''' (20 % au-delà de 5 818 $ et 36 % au-delà de 7 446 $) et contribution-santé maximale de 900 $.
    ''' </summary>
    <TestMethod>
    Public Sub HautSalaire_SurtaxeEtContributionMaximales()
        Dim r = MoteurPaie.Calculer(Salaire(12, 20000D))
        Assert.AreEqual(1172.65D, r.RRQ)
        Assert.AreEqual(326D, r.AE)
        Assert.AreEqual(4172.15D, r.ImpotFederal)
        Assert.AreEqual(2654.48D, r.ImpotQuebec)
    End Sub

    <TestMethod>
    Public Sub ContributionSante_ParPalier()
        Dim prm = ParametresAnnee.Pour(2026)
        Assert.AreEqual(0D, MoteurPaie.ContributionSanteOntario(prm, 20000D))
        Assert.AreEqual(60D, MoteurPaie.ContributionSanteOntario(prm, 21000D))
        Assert.AreEqual(300D, MoteurPaie.ContributionSanteOntario(prm, 30000D))
        Assert.AreEqual(360D, MoteurPaie.ContributionSanteOntario(prm, 37000D))
        Assert.AreEqual(450D, MoteurPaie.ContributionSanteOntario(prm, 48000D))
        Assert.AreEqual(500D, MoteurPaie.ContributionSanteOntario(prm, 48200D))
        Assert.AreEqual(600D, MoteurPaie.ContributionSanteOntario(prm, 72000D))
        Assert.AreEqual(725D, MoteurPaie.ContributionSanteOntario(prm, 72500D))
        Assert.AreEqual(750D, MoteurPaie.ContributionSanteOntario(prm, 200000D))
        Assert.AreEqual(900D, MoteurPaie.ContributionSanteOntario(prm, 300000D))
    End Sub

    ''' <summary>
    ''' Réduction d'impôt de l'Ontario, 1 000 $ aux 2 semaines et deux enfants à charge :
    '''   T4 = 568,05 ; S = le moindre de 568,05 et de 2 × (300 + 2 × 554) – 568,05 = 568,05 : l'impôt de base est effacé.
    '''   Il reste la contribution-santé : 300 $ → 11,54 par paie.
    ''' Sans personne à charge : S = 2 × 300 – 568,05 = 31,95 → (568,05 – 31,95 + 300) ÷ 26 = 32,16.
    ''' </summary>
    <TestMethod>
    Public Sub ReductionDImpot_PersonnesACharge()
        Dim avec = Salaire(26, 1000D)
        avec.Employe.TD1ProvPersonnesACharge = 2
        Assert.AreEqual(11.54D, MoteurPaie.Calculer(avec).ImpotQuebec)
        Assert.AreEqual(33.84D, MoteurPaie.Calculer(avec).ImpotFederal)

        Assert.AreEqual(32.16D, MoteurPaie.Calculer(Salaire(26, 1000D)).ImpotQuebec)
    End Sub

    ''' <summary>
    ''' Gratification de 3 000 $ versée avec un salaire de 2 000 $ aux 2 semaines : l'impôt sur la
    ''' gratification est l'écart entre l'impôt de l'année avec et sans elle.
    '''   C = 0,0595 × (5 000 – 134,61) = 289,49 ; F5 = 48,65, dont 19,46 au régulier et 29,19 à la gratification.
    ''' </summary>
    <TestMethod>
    Public Sub Gratification_MethodeDesGratifications()
        Dim e = Salaire(26, 2000D)
        Ajouter(e, "BONUS", 3000D)
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(289.49D, r.RRQ)
        Assert.AreEqual(81.5D, r.AE)
        Assert.AreEqual(29.19D, r.CSBForfaitaires)
        Assert.AreEqual(579.02D, r.ImpotFederal)
        Assert.AreEqual(264.64D, r.ImpotQuebec)
    End Sub

    ''' <summary>Rémunération de l'année de 5 000 $ ou moins : 15 % en tout, soit 10 % au fédéral et 5 % à l'Ontario.</summary>
    <TestMethod>
    Public Sub PetiteGratification_TauxFixeDe15PourCent()
        Dim e = Entree(52)
        Ajouter(e, "BONUS", 1000D)
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(100D, r.ImpotFederal)
        Assert.AreEqual(50D, r.ImpotQuebec)
        Assert.AreEqual(55.5D, r.RRQ)
    End Sub

    ''' <summary>
    ''' Maximums annuels. 70 000 $ de gains et 3 956,75 $ de RPC déjà cotisés : il ne reste que 273,70 $
    ''' avant le maximum de 4 230,45 $. La paie fait dépasser le MGAP (74 600 $) : la deuxième cotisation
    ''' est de 4 % de l'excédent, plafonnée à 416 $. AE : 1 123,07 – 1 100 = 23,07.
    ''' </summary>
    <TestMethod>
    Public Sub Maximums_RPC_RPC2_AE()
        Dim e = Salaire(12, 20000D)
        e.Cumul.GainsRRQ = 70000D
        e.Cumul.RRQ = 3956.75D
        e.Cumul.AE = 1100D
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(273.7D, r.RRQ)
        Assert.AreEqual(416D, r.RRQ2)
        Assert.AreEqual(416D, r.EmployeurRRQ2)
        Assert.AreEqual(23.07D, r.AE)
        Assert.AreEqual(4095.32D, r.ImpotFederal)
        Assert.AreEqual(2600.1D, r.ImpotQuebec)
    End Sub

    <TestMethod>
    Public Sub DeuxiemeCotisation_ResteAvantLePlafond()
        Dim e = Salaire(26, 4000D)
        e.Cumul.GainsRRQ = 84000D
        e.Cumul.RRQ = 4230.45D
        e.Cumul.RRQ2 = 376D
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(0D, r.RRQ)
        Assert.AreEqual(40D, r.RRQ2)
        Assert.AreEqual(543.82D, r.ImpotFederal)
        Assert.AreEqual(275.81D, r.ImpotQuebec)
    End Sub

    ''' <summary>Une cotisation à un RPA réduit le revenu imposable aux deux paliers : A = 48 915,10.</summary>
    <TestMethod>
    Public Sub CotisationRPA_ReduitLesDeuxImpots()
        Dim e = Salaire(26, 2000D)
        Ajouter(e, "DED_RPA", 100D)
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(149.23D, r.ImpotFederal)
        Assert.AreEqual(86.55D, r.ImpotQuebec)
        Assert.AreEqual(100D, r.AutresDeductions)
    End Sub

    ''' <summary>
    ''' Demi-cent exact. 1 115,87 $ par semaine : l'impôt fédéral de l'année vaut 5 023,46 $ tout rond,
    ''' soit 96,605 $ par paie — 96,61 $ une fois arrondi, comme le veut le guide (le demi-cent monte).
    ''' Les fractions qui ne tombent pas juste (0,0495 ÷ 0,0595) ne doivent pas le faire descendre à 96,60 $.
    ''' </summary>
    <TestMethod>
    Public Sub DemiCentExact_ArrondiVersLeHaut()
        Dim r = MoteurPaie.Calculer(Salaire(52, 1115.87D))
        Assert.AreEqual(62.39D, r.RRQ)
        Assert.AreEqual(18.19D, r.AE)
        Assert.AreEqual(96.61D, r.ImpotFederal)
        Assert.AreEqual(54.03D, r.ImpotQuebec)

        ' 2 076,60 $ par mois, trois personnes à charge : la réduction efface l'impôt de base, il reste la
        ' contribution-santé, 282,30 $ pour l'année, soit 23,525 $ par paie → 23,53 $.
        Dim e = Salaire(12, 2076.6D)
        e.Employe.TD1ProvPersonnesACharge = 3
        Assert.AreEqual(23.53D, MoteurPaie.Calculer(e).ImpotQuebec)
        Assert.AreEqual(96.61D, Arrondi.CentsExacts(96.60499999999999999999D))
        Assert.AreEqual(96.6D, Arrondi.CentsExacts(96.6049D))
    End Sub

    ''' <summary>RPC : du mois qui suit le 18e anniversaire jusqu'au mois du 70e anniversaire.</summary>
    <TestMethod>
    Public Sub AgeDuRPC()
        Dim jeune = Salaire(26, 1000D)
        jeune.Employe.DateNaissance = New Date(2008, 3, 20)       ' 18 ans le 20 mars 2026 : cotise à compter d'avril
        Assert.AreEqual(0D, MoteurPaie.Calculer(jeune).RRQ)
        jeune.DatePaie = New Date(2026, 4, 2)
        Assert.AreEqual(51.49D, MoteurPaie.Calculer(jeune).RRQ)

        Dim aine = Salaire(26, 1000D)
        aine.Employe.DateNaissance = New Date(1956, 3, 1)         ' 70 ans le 1er mars 2026 : cotise jusqu'à la fin de mars
        Assert.AreEqual(51.49D, MoteurPaie.Calculer(aine).RRQ)
        aine.DatePaie = New Date(2026, 4, 2)
        Dim r = MoteurPaie.Calculer(aine)
        Assert.AreEqual(0D, r.RRQ)
        Assert.AreEqual(0D, r.EmployeurRRQ)
        StringAssert.Contains(String.Join(" ", r.Avertissements), "70 ans")
    End Sub

    <TestMethod>
    Public Sub Exemptions_AucuneRetenue()
        Dim e = Salaire(26, 2000D)
        e.Employeur.TauxCNESST = 1.5D
        e.Employeur.TauxFSS = 1.95D
        With e.Employe
            .ExemptImpotFederal = True : .ExemptImpotQuebec = True : .ExemptRRQ = True
            .ExemptAE = True : .ExemptFSS = True : .ExemptCNESST = True
        End With
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(0D, r.TotalRetenues)
        Assert.AreEqual(0D, r.TotalPartsEmployeur)
        StringAssert.Contains(r.Avertissements(0), "impôt de l'Ontario")
        StringAssert.Contains(r.Avertissements(0), "RPC")
        Assert.AreEqual(2000D, r.Net)
    End Sub

    ''' <summary>WSIB : la prime s'arrête au plafond des gains assurables de l'année (121 700 $ en 2026).</summary>
    <TestMethod>
    Public Sub WSIB_PlafondDesGainsAssurables()
        Dim e = Salaire(12, 10000D)
        e.Employeur.TauxCNESST = 2D
        e.Cumul.GainsCNESST = 120000D
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(1700D, r.GainsCNESST)
        Assert.AreEqual(34D, r.EmployeurCNESST)
    End Sub

    ''' <summary>
    ''' Impôt-santé des employeurs : le taux de la tranche, ramené sur toute la masse salariale
    ''' une fois l'exemption de 1 000 000 $ retranchée.
    ''' </summary>
    <TestMethod>
    Public Sub TauxISE_SelonMasseSalarialeEtExemption()
        Dim prm = ParametresAnnee.Pour(2026)
        Assert.AreEqual(0D, prm.TauxISE(500000D, True), "sous l'exemption")
        Assert.AreEqual(0D, prm.TauxISE(1000000D, True))
        Assert.AreEqual(0.975D, prm.TauxISE(2000000D, True), "1,95 % sur la moitié de la masse")
        Assert.AreEqual(1.95D, prm.TauxISE(6000000D, True), "au-delà de 5 000 000 $, plus d'exemption")
        Assert.AreEqual(0.98D, prm.TauxISE(150000D, False))
        Assert.AreEqual(1.101D, prm.TauxISE(210000D, False))
        Assert.AreEqual(1.829D, prm.TauxISE(390000D, False))
        Assert.AreEqual(1.95D, prm.TauxISE(500000D, False))

        Dim e = Salaire(26, 2000D)
        e.Employeur.TauxFSS = prm.TauxISE(2000000D, True)
        Assert.AreEqual(19.5D, MoteurPaie.Calculer(e).EmployeurFSS)
    End Sub

    ''' <summary>La paie de vacances ne compte pas dans le salaire qui donne droit à l'indemnité de vacances (Ontario).</summary>
    <TestMethod>
    Public Sub Vacances_SurLeSalaireSansLaPaieDeVacances()
        Dim e = Salaire(26, 2000D)
        Ajouter(e, "VACANCES", 500D)
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(80D, r.VacancesAccumulees)
        Assert.AreEqual(500D, r.VacancesPayees)
    End Sub

    ''' <summary>La part de l'employeur à une assurance maladie privée n'est un avantage imposable qu'au Québec.</summary>
    <TestMethod>
    Public Sub AvantageQuebecois_IgnoreEnOntario()
        Dim sans = MoteurPaie.Calculer(Salaire(26, 2000D))
        Dim e = Salaire(26, 2000D)
        Ajouter(e, "AV_ASSURANCE_MALADIE", 50D)
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(sans.ImpotFederal, r.ImpotFederal)
        Assert.AreEqual(sans.ImpotQuebec, r.ImpotQuebec)
        Assert.AreEqual(sans.RRQ, r.RRQ)
        Assert.AreEqual(0D, r.AvantagesNonMonetaires)
        Assert.AreEqual(1, r.Avertissements.Count)
    End Sub

    ''' <summary>Une année dont les taux de l'Ontario ne sont pas définis est refusée, pas calculée avec ceux du Québec.</summary>
    <TestMethod>
    Public Sub AnneeSansTauxOntario_Refusee()
        Dim prm = ParametresAnnee.DuCode(2026)
        prm.OnTranches = Nothing
        Assert.IsFalse(prm.EstDefinie(Province.Ontario))
        Assert.IsTrue(prm.EstDefinie(Province.Quebec))
        Assert.ThrowsException(Of NotSupportedException)(Sub() MoteurPaie.Calculer(Salaire(26, 2000D), prm))
        Assert.IsTrue(ParametresAnnee.EstDisponible(2026, Province.Ontario))
        Assert.IsFalse(ParametresAnnee.EstDisponible(2019, Province.Ontario))
    End Sub

    ''' <summary>
    ''' Une année à moitié saisie est refusée elle aussi. Avec un maximum resté à zéro, le RPC ou l'AE
    ''' sortiraient à 0 $ sans aucun message : mieux vaut ne pas calculer du tout.
    ''' </summary>
    <TestMethod>
    Public Sub AnneeOntarioIncomplete_Refusee()
        Dim sansMaximumRPC = ParametresAnnee.DuCode(2026)
        sansMaximumRPC.RPCMaxEmploye = 0D
        Assert.IsFalse(sansMaximumRPC.EstDefinie(Province.Ontario))
        Assert.ThrowsException(Of NotSupportedException)(Sub() MoteurPaie.Calculer(Salaire(26, 2000D), sansMaximumRPC))

        Dim sansMaximumAE = ParametresAnnee.DuCode(2026)
        sansMaximumAE.AEMaxEmployeHorsQuebec = 0D
        Assert.IsFalse(sansMaximumAE.EstDefinie(Province.Ontario))

        Dim sansPlafondWSIB = ParametresAnnee.DuCode(2026)
        sansPlafondWSIB.WSIBMaxAssurable = 0D
        Assert.IsFalse(sansPlafondWSIB.EstDefinie(Province.Ontario))

        ' Le Québec de la même année, lui, reste calculable.
        Dim qc = Salaire(26, 2000D)
        qc.Province = Province.Quebec
        Assert.AreEqual(117.52D, MoteurPaie.Calculer(qc, sansMaximumRPC).RRQ)
    End Sub

    <TestMethod>
    Public Sub Provinces_Codes()
        Assert.AreEqual(Province.Ontario, Provinces.DeCode("on"))
        Assert.AreEqual(Province.Quebec, Provinces.DeCode("QC"))
        Assert.AreEqual(Province.Quebec, Provinces.DeCode(Nothing), "les paies d'avant l'Ontario n'ont pas de province")
        Assert.AreEqual(Province.Alberta, Provinces.DeCode("AB"))
        Assert.ThrowsException(Of NotSupportedException)(Sub() Provinces.DeCode("ZZ"))
        Assert.AreEqual("ON", Provinces.Code(Province.Ontario))
        Assert.AreEqual("RPC", LibellesProvince.Pour("ON").Pension)
        Assert.AreEqual("RRQ", LibellesProvince.Pour("QC").Pension)
    End Sub

    ''' <summary>Les paliers de la contribution-santé s'échangent en texte avec la base, comme les tranches.</summary>
    <TestMethod>
    Public Sub PaliersSante_AllerRetourTexte()
        Dim prm = ParametresAnnee.Pour(2026)
        Dim texte = ParametresAnnee.EcrirePaliersSante(prm.OnContributionSante)
        Assert.AreEqual("20000|0|0.06|300;36000|300|0.06|450;48000|450|0.25|600;72000|600|0.25|750;200000|750|0.25|900", texte)
        Assert.AreEqual(5, ParametresAnnee.LirePaliersSante(texte).Length)
        Assert.AreEqual("53891|0.0505|0;107785|0.0915|2210;150000|0.1116|4376;220000|0.1216|5876;*|0.1316|8076", ParametresAnnee.EcrireTranches(prm.OnTranches))
    End Sub

End Class
