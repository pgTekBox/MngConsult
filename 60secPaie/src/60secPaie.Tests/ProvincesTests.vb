Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports Paie60Sec.Calcul

''' <summary>
''' Paie d'un employé des provinces et territoires autres que le Québec et l'Ontario : formules du guide
''' T4127, option 1 — 122e édition (1er janvier 2026) et 123e édition (1er juillet 2026), qui change la
''' Colombie-Britannique, Terre-Neuve-et-Labrador et l'Île-du-Prince-Édouard en cours d'année.
''' Les montants attendus viennent d'un calcul indépendant fait à partir des tableaux du guide.
''' À comparer aussi, avant la production, avec le calculateur en ligne de l'ARC (PDOC).
''' </summary>
<TestClass>
Public Class ProvincesTests

    Private Shared Function Salaire(codeProvince As String, mois As Integer, periodes As Integer, montant As Decimal) As EntreePaie
        Dim e As New EntreePaie()
        e.Province = Provinces.DeCode(codeProvince)
        e.Annee = 2026
        e.PeriodesParAnnee = periodes
        e.DatePaie = New Date(2026, mois, 15)
        e.Employeur.TauxCNESST = 0D
        e.Employeur.TauxFSS = 0D
        e.Lignes.Add(New LignePaie With {.CodeCategorie = "SALAIRE", .Montant = montant})
        Return e
    End Function

    Private Shared Sub Verifier(codeProvince As String, mois As Integer, impotAux2Semaines As Decimal, impotMensuel As Decimal)
        ' 2 500 $ aux 2 semaines : RPC 140,74 ; AE 40,75 ; impôt fédéral 242,58 — les mêmes partout hors Québec.
        Dim r = MoteurPaie.Calculer(Salaire(codeProvince, mois, 26, 2500D))
        Assert.AreEqual(140.74D, r.RRQ, codeProvince & " RPC")
        Assert.AreEqual(40.75D, r.AE, codeProvince & " AE")
        Assert.AreEqual(242.58D, r.ImpotFederal, codeProvince & " impôt fédéral")
        Assert.AreEqual(impotAux2Semaines, r.ImpotQuebec, codeProvince & " impôt provincial, 2 500 $ aux 2 semaines")
        Assert.AreEqual(0D, r.EmployeurRQAP, codeProvince & " pas de RQAP")
        Assert.AreEqual(0D, r.EmployeurCNT, codeProvince & " pas de CNT")

        ' 25 000 $ par mois : les tranches supérieures.
        Dim haut = MoteurPaie.Calculer(Salaire(codeProvince, mois, 12, 25000D))
        Assert.AreEqual(5736.18D, haut.ImpotFederal, codeProvince & " impôt fédéral, 25 000 $ par mois")
        Assert.AreEqual(impotMensuel, haut.ImpotQuebec, codeProvince & " impôt provincial, 25 000 $ par mois")
    End Sub

    ''' <summary>
    ''' Alberta, 2 500 $ aux 2 semaines : A = 26 × (2 500 – 23,65) = 64 385,10
    '''   0,10 × A – 1 224 = 5 214,51 ; K1P = 0,08 × 22 769 = 1 821,52 ; K2P = 0,08 × 4 103,74 = 328,30
    '''   K5P = 0 (K1P + K2P sous 4 896 $) ; T4 = 3 064,69 → 117,87 par paie
    ''' </summary>
    <TestMethod>
    Public Sub Alberta()
        Verifier("AB", 3, 117.87D, 2563.67D)
    End Sub

    ''' <summary>Alberta : un montant demandé élevé donne le crédit supplémentaire K5P, 25 % de l'excédent de 4 896 $.</summary>
    <TestMethod>
    Public Sub Alberta_CreditSupplementaire()
        Dim pp = ParametresAnnee.Pour(2026).PourProvince(Province.Alberta, New Date(2026, 3, 15))
        Dim d = MoteurPaie.ImpotProvincialAnnuel(pp, ParametresAnnee.Pour(2026), 100000D, 70000D, 0D, 0D, 0D)
        Assert.AreEqual(5600D, d.K1P)
        Assert.AreEqual(176D, d.K5P, "(5 600 – 4 896) × 25 %")
        Assert.AreEqual(3000D, d.T4, "0,10 × 100 000 – 1 224 – 5 600 – 176")
    End Sub

    <TestMethod>
    Public Sub ColombieBritannique_AvantEtApresLe1erJuillet()
        Verifier("BC", 3, 105.82D, 3046.71D)
        Verifier("BC", 9, 119.55D, 3075.97D)
    End Sub

    ''' <summary>Colombie-Britannique : la réduction d'impôt efface l'impôt des bas revenus et s'éteint au-delà du seuil.</summary>
    <TestMethod>
    Public Sub ColombieBritannique_ReductionDImpot()
        Dim prm = ParametresAnnee.Pour(2026)
        Dim janvier = prm.PourProvince(Province.ColombieBritannique, New Date(2026, 3, 15))
        Dim juillet = prm.PourProvince(Province.ColombieBritannique, New Date(2026, 7, 1))

        Dim bas = MoteurPaie.ImpotProvincialAnnuel(janvier, prm, 24000D, Nothing, 0D, 0D, 0D)
        Assert.AreEqual(545.6704D, bas.T4, "0,0506 × (24 000 – 13 216)")
        Assert.AreEqual(545.6704D, bas.S, "le moindre de T4 et de 575 $")
        Assert.AreEqual(0D, bas.T2)

        Dim milieu = MoteurPaie.ImpotProvincialAnnuel(janvier, prm, 30000D, Nothing, 0D, 0D, 0D)
        Assert.AreEqual(417.292D, milieu.S, "575 – (30 000 – 25 570) × 3,56 %")

        Assert.AreEqual(0D, MoteurPaie.ImpotProvincialAnnuel(janvier, prm, 41723D, Nothing, 0D, 0D, 0D).S)
        Assert.AreEqual(805D, juillet.ReductionRevenuMontant)
        Assert.AreEqual(0.0614D, juillet.TauxCredits)
    End Sub

    <TestMethod>
    Public Sub Manitoba()
        Verifier("MB", 3, 197.87D, 3728.19D)
    End Sub

    ''' <summary>Manitoba : le montant personnel de base diminue de 200 000 $ à 400 000 $ de revenu, jusqu'à zéro.</summary>
    <TestMethod>
    Public Sub Manitoba_MontantDeBaseSelonLeRevenu()
        Dim pp = ParametresAnnee.Pour(2026).PourProvince(Province.Manitoba, New Date(2026, 3, 15))
        Assert.AreEqual(15780D, pp.MontantBasePour(200000D))
        Assert.AreEqual(7890D, pp.MontantBasePour(300000D))
        Assert.AreEqual(0D, pp.MontantBasePour(400000D))
        Assert.AreEqual(0D, pp.MontantBasePour(900000D))
    End Sub

    <TestMethod>
    Public Sub NouveauBrunswick()
        Verifier("NB", 3, 189.87D, 3742.92D)
    End Sub

    <TestMethod>
    Public Sub TerreNeuveEtLabrador_AvantEtApresLe1erJuillet()
        Verifier("NL", 3, 208.25D, 3845.25D)
        Verifier("NL", 9, 195.49D, 3817.62D)
    End Sub

    <TestMethod>
    Public Sub NouvelleEcosse()
        Verifier("NS", 3, 244.13D, 4303.12D)
    End Sub

    <TestMethod>
    Public Sub IleDuPrinceEdouard_AvantEtApresLe1erJuillet()
        Verifier("PE", 3, 211.95D, 4008.88D)
        Verifier("PE", 9, 211.95D, 4170.61D)   ' nouvelle tranche au-delà de 200 000 $
    End Sub

    <TestMethod>
    Public Sub Saskatchewan()
        Verifier("SK", 3, 168.7D, 3019.63D)
    End Sub

    ''' <summary>Yukon : le crédit canadien pour emploi s'applique aussi à l'impôt du territoire (K4P).</summary>
    <TestMethod>
    Public Sub Yukon()
        Verifier("YT", 3, 110.04D, 2448.45D)
    End Sub

    ''' <summary>
    ''' Territoires du Nord-Ouest et Nunavut : en plus de l'impôt, 2 % de la paie sont retenus à l'employé
    ''' et remis au territoire. Le montant occupe le champ du RQAP.
    ''' </summary>
    <TestMethod>
    Public Sub TerritoiresDuNordOuestEtNunavut_ImpotSurLaPaie()
        Verifier("NT", 3, 107.32D, 2662.49D)
        Verifier("NU", 3, 72.4D, 2062.08D)

        Dim r = MoteurPaie.Calculer(Salaire("NT", 3, 26, 2500D))
        Assert.AreEqual(50D, r.RQAP, "2 % de 2 500 $")
        Assert.AreEqual(2500D - r.ImpotFederal - r.ImpotQuebec - r.RRQ - r.AE - 50D, r.Net)

        Dim exempte = Salaire("NU", 3, 26, 2500D)
        exempte.Employe.ExemptRQAP = True
        Assert.AreEqual(0D, MoteurPaie.Calculer(exempte).RQAP)

        Assert.AreEqual(0D, MoteurPaie.Calculer(Salaire("AB", 3, 26, 2500D)).RQAP, "aucune retenue de ce genre ailleurs")
    End Sub

    ''' <summary>Le plafond annuel des accidents du travail est celui de la commission de la province.</summary>
    <TestMethod>
    Public Sub AccidentsDuTravail_PlafondDeLaProvince()
        Dim e = Salaire("NS", 3, 12, 10000D)
        e.Employeur.TauxCNESST = 2D
        e.Cumul.GainsCNESST = 75000D
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(4900D, r.GainsCNESST, "79 900 – 75 000")
        Assert.AreEqual(98D, r.EmployeurCNESST)
    End Sub

    <TestMethod>
    Public Sub ToutesLesProvinces_SontDefiniesEn2026()
        For Each p In Provinces.Gerees
            Assert.IsTrue(ParametresAnnee.EstDisponible(2026, p), Provinces.Nom(p))
            Assert.AreEqual(p, Provinces.DeCode(Provinces.Code(p)))
            Assert.IsTrue(LibellesProvince.Pour(p).ImpotProvincial.StartsWith("Impôt "), Provinces.Nom(p))
        Next
        Assert.AreEqual("Impôt du Manitoba", LibellesProvince.Pour("MB").ImpotProvincial)
        Assert.AreEqual("TD1BC", LibellesProvince.Pour("BC").FormulaireCredits)
        Assert.AreEqual("Impôt sur la paie", LibellesProvince.Pour("NU").RetenueProvinciale)
    End Sub

    ''' <summary>Les particularités d'une province s'échangent en texte avec la base.</summary>
    <TestMethod>
    Public Sub Particularites_AllerRetour()
        Dim pp As New ParametresProvince()
        pp.LireParticularites("creditSupplSeuil=4896; creditSupplTaux=0,25;creditEmploi=1")
        Assert.AreEqual(4896D, pp.CreditSupplSeuil)
        Assert.AreEqual(0.25D, pp.CreditSupplTaux)
        Assert.IsTrue(pp.CreditEmploi)
        Assert.AreEqual("creditEmploi=1;creditSupplSeuil=4896;creditSupplTaux=0.25", pp.EcrireParticularites())
        Assert.ThrowsException(Of FormatException)(Sub() pp.LireParticularites("inconnu=1"))
    End Sub

End Class
