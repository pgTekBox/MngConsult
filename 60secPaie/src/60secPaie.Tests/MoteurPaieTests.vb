Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports Paie60Sec.Calcul

''' <summary>
''' Les cas « Annexe » reproduisent les exemples chiffrés du guide TP-1015.F (2026-01) de Revenu Québec.
''' </summary>
<TestClass>
Public Class MoteurPaieTests

    Private Shared Function Entree(periodes As Integer) As EntreePaie
        Dim e As New EntreePaie()
        e.Annee = 2026
        e.PeriodesParAnnee = periodes
        e.DatePaie = New Date(2026, 3, 5)
        e.Employeur.TauxCNESST = 0D
        Return e
    End Function

    Private Shared Sub Ajouter(e As EntreePaie, code As String, montant As Decimal, Optional surForfaitaire As Boolean = False)
        e.Lignes.Add(New LignePaie With {.CodeCategorie = code, .Montant = montant, .SurForfaitaire = surForfaitaire})
    End Sub

    ''' <summary>Annexe 1 : 4 000 $ aux 2 semaines, RPA 200 $, E = 21 830 $, FTQ 100 $ et Fondaction 150 $ par paie.</summary>
    Private Shared Function Annexe1(avecFonds As Boolean) As EntreePaie
        Dim e = Entree(26)
        e.Employe.TP1015Montant = 21830D
        Ajouter(e, "SALAIRE", 4000D)
        Ajouter(e, "DED_RPA", 200D)
        If avecFonds Then
            Ajouter(e, "DED_FTQ", 100D)
            Ajouter(e, "DED_FONDACTION", 150D)
        End If
        Return e
    End Function

    <TestMethod>
    Public Sub Annexe1_Periodes1a18_ImpotQuebec()
        Dim r = MoteurPaie.Calculer(Annexe1(True))
        Assert.AreEqual(243.52D, r.RRQ)
        Assert.AreEqual(0D, r.RRQ2)
        Assert.AreEqual(444.51D, r.ImpotQuebec)
    End Sub

    <TestMethod>
    Public Sub Annexe1et3_Periode19_MaximumRRQAtteint()
        Dim e = Annexe1(True)
        e.Cumul.RRQ = 4383.36D
        e.Cumul.GainsRRQ = 72000D
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(95.94D, r.RRQ)
        Assert.AreEqual(56D, r.RRQ2)
        Assert.AreEqual(438.32D, r.ImpotQuebec)
    End Sub

    <TestMethod>
    Public Sub Annexe1et3_Periode20_DeuxiemeCotisationSupplementaire()
        Dim e = Annexe1(True)
        e.Cumul.RRQ = 4479.3D
        e.Cumul.RRQ2 = 56D
        e.Cumul.GainsRRQ = 76000D
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(0D, r.RRQ)
        Assert.AreEqual(160D, r.RRQ2)
        Assert.AreEqual(421.46D, r.ImpotQuebec)
    End Sub

    <TestMethod>
    Public Sub Annexe1et3_Periode22_FinDesFondsDeTravailleurs()
        Dim e = Annexe1(False)
        e.Cumul.RRQ = 4479.3D
        e.Cumul.RRQ2 = 376D
        e.Cumul.GainsRRQ = 84000D
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(40D, r.RRQ2)
        Assert.AreEqual(481.76D, r.ImpotQuebec)
    End Sub

    <TestMethod>
    Public Sub Annexe1_DernieresPeriodes_AucuneCotisationRRQ()
        Dim e = Annexe1(False)
        e.Cumul.RRQ = 4479.3D
        e.Cumul.RRQ2 = 416D
        e.Cumul.GainsRRQ = 88000D
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(0D, r.RRQ)
        Assert.AreEqual(0D, r.RRQ2)
        Assert.AreEqual(489.36D, r.ImpotQuebec)
    End Sub

    ''' <summary>Annexe 2 : rétroactif de 4 000 $ (dont 400 $ de RPA) versé avec un salaire hebdomadaire de 1 500 $.</summary>
    <TestMethod>
    Public Sub Annexe2_PaiementRetroactif()
        Dim sansRetro = Entree(52)
        Ajouter(sansRetro, "SALAIRE", 1500D)
        Ajouter(sansRetro, "DED_RPA", 100D)

        Dim avecRetro = Entree(52)
        Ajouter(avecRetro, "SALAIRE", 1500D)
        Ajouter(avecRetro, "DED_RPA", 100D)
        Ajouter(avecRetro, "RETRO", 4000D)
        Ajouter(avecRetro, "DED_RPA", 400D, surForfaitaire:=True)

        Dim r = MoteurPaie.Calculer(avecRetro)
        Assert.AreEqual(342.26D, r.RRQ)
        Assert.AreEqual(39.51D, r.CSBForfaitaires)

        ' Impôt sur le rétroactif seul = T × (B2 – CSB) = 0,19 × (3 600 – 39,51) = 676,49 $.
        ' L'impôt sur la partie régulière change légèrement parce que CSA passe de 14,33 $ à 14,82 $.
        Dim h = 27.88D
        Dim iRegulier = 52D * (1500D - 100D - h - 14.82D)
        Dim impotRegulier = Arrondi.Cents((MoteurPaie.ImpotSelonTranches(ParametresAnnee.Pour(2026).QcTranches, iRegulier) - (0.14D * 18952D)) / 52D)
        Assert.AreEqual(impotRegulier + 676.49D, r.ImpotQuebec)
        Assert.IsTrue(r.ImpotQuebec > MoteurPaie.Calculer(sansRetro).ImpotQuebec)
    End Sub

    <TestMethod>
    Public Sub PetitForfaitaire_TauxFixe()
        ' Salaire annuel + forfaitaire <= 18 952 $ : 7 % au Québec ; <= 5 000 $ au fédéral : 10 %.
        Dim e = Entree(52)
        Ajouter(e, "BONUS", 1000D)
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(70D, r.ImpotQuebec)
        Assert.AreEqual(100D, r.ImpotFederal)
    End Sub

    <TestMethod>
    Public Sub AE_et_RQAP_TauxQuebec()
        Dim e = Entree(26)
        Ajouter(e, "SALAIRE", 1000D)
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(13D, r.AE)
        Assert.AreEqual(18.2D, r.EmployeurAE)
        Assert.AreEqual(4.3D, r.RQAP)
        Assert.AreEqual(6.02D, r.EmployeurRQAP)
        Assert.AreEqual(16.5D, r.EmployeurFSS)
    End Sub

    <TestMethod>
    Public Sub Maximums_Annuels_Respectes()
        Dim e = Entree(12)
        Ajouter(e, "SALAIRE", 20000D)
        e.Cumul.AE = 890D
        e.Cumul.RQAP = 440D
        e.Cumul.RQAPEmployeur = 620D
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(5.7D, r.AE)
        Assert.AreEqual(2.9D, r.RQAP)
        Assert.AreEqual(0.06D, r.EmployeurRQAP)
    End Sub

    <TestMethod>
    Public Sub ImpotFederal_EmployeDuQuebec()
        ' Calcul manuel selon T4127 : 2 000 $ aux 2 semaines, TD1 de base.
        '   C = 0,063 × (2 000 – 134,61) = 117,52 ; F5 = 18,65 ; A = 26 × (2 000 – 18,65) = 51 515,10
        '   K1 = 2 303,28 ; K2Q = 0,14 × (2 570,52 + 676,00 + 223,60) = 485,82 ; K4 = 210,14
        '   T3 = 7 212,11 – 2 999,24 = 4 212,88 ; T1 = T3 × (1 – 0,165) = 3 517,75 ; T = 135,30
        Dim e = Entree(26)
        Ajouter(e, "SALAIRE", 2000D)
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(117.52D, r.RRQ)
        Assert.AreEqual(26D, r.AE)
        Assert.AreEqual(8.6D, r.RQAP)
        Assert.AreEqual(135.3D, r.ImpotFederal)
        Assert.AreEqual(2000D - r.TotalRetenues, r.Net)
    End Sub

    <TestMethod>
    Public Sub AvantageNonMonetaire_ImposeMaisNonVerse()
        Dim sans = Entree(26)
        Ajouter(sans, "SALAIRE", 2000D)
        Dim avec = Entree(26)
        Ajouter(avec, "SALAIRE", 2000D)
        Ajouter(avec, "AV_ASSURANCE_MALADIE", 50D)

        Dim r0 = MoteurPaie.Calculer(sans)
        Dim r1 = MoteurPaie.Calculer(avec)
        Assert.AreEqual(2000D, r1.BrutVerse)
        Assert.AreEqual(50D, r1.AvantagesNonMonetaires)
        Assert.AreEqual(r0.AE, r1.AE)
        Assert.AreEqual(r0.RQAP, r1.RQAP)
        Assert.IsTrue(r1.ImpotQuebec > r0.ImpotQuebec)
        Assert.IsTrue(r1.RRQ > r0.RRQ)
    End Sub

    <TestMethod>
    Public Sub Exemptions_AucuneRetenue()
        Dim e = Entree(26)
        Ajouter(e, "SALAIRE", 2000D)
        With e.Employe
            .ExemptImpotFederal = True : .ExemptImpotQuebec = True : .ExemptRRQ = True
            .ExemptRQAP = True : .ExemptAE = True : .ExemptFSS = True : .ExemptCNESST = True
        End With
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(0D, r.TotalRetenues)
        Assert.AreEqual(0D, r.TotalPartsEmployeur)
        Assert.AreEqual(1, r.Avertissements.Count, "Les exemptions doivent être signalées à la révision.")
        StringAssert.Contains(r.Avertissements(0), "impôt fédéral")
        Assert.AreEqual(2000D, r.Net)
    End Sub

    <TestMethod>
    Public Sub MoinsDe18Ans_PasDeRRQ()
        Dim e = Entree(26)
        e.Employe.DateNaissance = New Date(2010, 1, 1)
        Ajouter(e, "SALAIRE", 1000D)
        Assert.AreEqual(0D, MoteurPaie.Calculer(e).RRQ)
    End Sub

    <TestMethod>
    Public Sub Vacances_et_CNESST()
        Dim e = Entree(26)
        e.TauxVacances = 6D
        e.Employeur.TauxCNESST = 1.5D
        Ajouter(e, "SALAIRE", 2000D)
        Ajouter(e, "VACANCES_PAR_PAIE", 100D)
        Dim r = MoteurPaie.Calculer(e)
        Assert.AreEqual(120D, r.VacancesAccumulees)
        Assert.AreEqual(31.5D, r.EmployeurCNESST)
        Assert.AreEqual(1.26D, r.EmployeurCNT)
    End Sub

    <TestMethod>
    Public Sub TauxFSS_SelonMasseSalariale()
        Assert.AreEqual(1.65D, ParametresAnnee.Pour(2026).TauxFSS(500000D, SecteurFSS.General))
        Assert.AreEqual(1.25D, ParametresAnnee.Pour(2026).TauxFSS(500000D, SecteurFSS.PrimaireManufacturier))
        Assert.AreEqual(4.26D, ParametresAnnee.Pour(2026).TauxFSS(9000000D, SecteurFSS.General))
        Assert.AreEqual(4.26D, ParametresAnnee.Pour(2026).TauxFSS(100000D, SecteurFSS.SecteurPublic))
        Assert.AreEqual(2.42D, ParametresAnnee.Pour(2026).TauxFSS(3000000D, SecteurFSS.General))
    End Sub

    ''' <summary>
    ''' EstDisponible et Pour doivent dire la même chose : c'est tout l'intérêt
    ''' de les faire découler d'une seule table. Une année acceptée par l'une et
    ''' refusée par l'autre donnerait un écran qui propose une paie que le moteur
    ''' refusera ensuite de calculer.
    ''' </summary>
    <TestMethod>
    Public Sub AnneesDisponibles_EstDisponibleEtPourSaccordent()
        For annee As Integer = 2020 To 2035
            Dim a As Integer = annee   ' copie locale : une lambda ne doit pas capturer la variable de boucle
            If ParametresAnnee.EstDisponible(a) Then
                Assert.AreEqual(a, ParametresAnnee.Pour(a).Annee, "Pour doit rendre l'année demandée.")
            Else
                Assert.ThrowsException(Of NotSupportedException)(
                    Sub() ParametresAnnee.Pour(a),
                    "Une année indisponible doit être refusée, pas calculée avec les taux d'une autre.")
            End If
        Next
    End Sub

    ''' <summary>L'année de référence affichée doit toujours être une année que l'on sait calculer.</summary>
    <TestMethod>
    Public Sub DerniereAnneeConnue_EstToujoursDisponible()
        Assert.IsTrue(ParametresAnnee.EstDisponible(ParametresAnnee.DerniereAnneeConnue()))
        Assert.AreEqual(ParametresAnnee.DerniereAnneeConnue(), ParametresAnnee.PourAffichage().Annee)
    End Sub

End Class
