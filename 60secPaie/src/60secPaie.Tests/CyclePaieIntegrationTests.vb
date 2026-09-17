Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Security.Principal
Imports System.Text.RegularExpressions
Imports System.Web
Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports Paie60Sec.Web

''' <summary>
''' Cycle de paie complet contre SQL Server LocalDB, dans la base jetable 60secPaie_Test :
''' création du lot, calcul, révision, confirmation, cumulatifs de la paie suivante, annulation.
''' </summary>
<TestClass>
Public Class CyclePaieIntegrationTests

    Private Const BaseTest As String = "60secPaie_Test"
    Private Const Maitre As String = "Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=master;Integrated Security=True"

    <AssemblyInitialize>
    Public Shared Sub CreerBase(contexte As TestContext)
        ExecuterLots(Maitre,
            "IF DB_ID(N'" & BaseTest & "') IS NOT NULL BEGIN ALTER DATABASE [" & BaseTest & "] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [" & BaseTest & "]; END" & vbCrLf & "GO" & vbCrLf &
            "CREATE DATABASE [" & BaseTest & "];")

        Dim racine = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "..", ".."))
        For Each script In {Path.Combine("tests", "00_stubs_mngconsul.sql"), "01_schema.sql"}
            ExecuterLots(Maitre, File.ReadAllText(Path.Combine(racine, "Database", script)).Replace("$(Base)", BaseTest))
        Next
    End Sub

    Private Shared Sub ExecuterLots(chaine As String, script As String)
        Using cn As New SqlConnection(chaine)
            cn.Open()
            For Each lot In Regex.Split(script, "^\s*GO\s*$", RegexOptions.Multiline Or RegexOptions.IgnoreCase)
                If lot.Trim().Length = 0 Then Continue For
                Using cmd As New SqlCommand(lot, cn)
                    cmd.ExecuteNonQuery()
                End Using
            Next
        End Using
    End Sub

    <TestInitialize>
    Public Sub SimulerRequete()
        HttpContext.Current = New HttpContext(New HttpRequest("", "http://localhost/", ""), New HttpResponse(New StringWriter()))
        HttpContext.Current.User = New GenericPrincipal(New GenericIdentity("test@exemple.ca"), New String() {})
    End Sub

    <TestMethod>
    Public Sub CycleComplet_DeuxPaies_PuisAnnulation()
        ' --- Données de base. Côté MngConsul (répliques) : une compagnie, ses employés. Côté 60secPaie : les paramètres de paie.
        Dim guidCompagnie = Guid.NewGuid()
        Db.Exec("INSERT INTO dbo.T010Company (CompanyGUID, CompanyCode) VALUES (@g, 'ESSAI'); " &
                "INSERT INTO dbo.StubParam (CompanyGUID, ShortName, sVal) VALUES (@g, 'LEGAL_NAME', 'Compagnie d''essai inc.'), (@g, 'CITY', 'Longueuil');", Db.P("@g", guidCompagnie))
        HttpContext.Current.Items("CompanyGuid") = guidCompagnie

        Dim compagnieId = Db.Inserer("INSERT INTO paie.Compagnie (CompanyGUID, Nom, PeriodesParAnnee, TauxCNESST, ProchainNumeroCheque) VALUES (@g, N'Compagnie d''essai', 26, 1.5, 100)",
                                     Db.P("@g", guidCompagnie))
        Assert.AreEqual(compagnieId, Contexte.CompagnieId)
        Contexte.SynchroniserCompagnie()
        Assert.AreEqual("Compagnie d'essai inc.", Convert.ToString(Db.Scalaire("SELECT Nom FROM paie.Compagnie WHERE Id = @c", Db.P("@c", compagnieId))), "Le nom vient de MngConsul.")

        Dim horaire = Db.Inserer(
            "INSERT INTO dbo.T300Employees (CompanyGUID, FirstName, LastName, DateOfBirth, HireDate, HourlyRate, PayFrequency, StateId, Active) " &
            "VALUES (@g, 'Alice', 'Tremblay <test>', '1990-05-01', '2025-01-01', 30, 'BiWeekly', 2, 1)", Db.P("@g", guidCompagnie))
        Dim annuel = Db.Inserer(
            "INSERT INTO dbo.T300Employees (CompanyGUID, FirstName, LastName, HireDate, AnnualSalary, PayFrequency, Active, [SIN], BankAccount) " &
            "VALUES (@g, 'Bruno', 'Gagnon', '2025-01-01', 104000, 'BiWeekly', 1, '046 454 286', '7654321')", Db.P("@g", guidCompagnie))
        Db.Exec("INSERT INTO dbo.T300Employees (CompanyGUID, FirstName, LastName, AnnualSalary, PayFrequency, Active) VALUES (@g, 'Inactif', 'Exclu', 50000, 'BiWeekly', 0)", Db.P("@g", guidCompagnie))
        Dim nonConfigure = Db.Inserer("INSERT INTO dbo.T300Employees (CompanyGUID, FirstName, LastName, AnnualSalary, PayFrequency, Active) VALUES (@g, 'Carl', 'Sans-Paie', 60000, 'BiWeekly', 1)",
                                      Db.P("@g", guidCompagnie))
        ' Employé d'une AUTRE compagnie : ne doit jamais apparaître.
        Db.Exec("INSERT INTO dbo.T300Employees (CompanyGUID, FirstName, LastName, AnnualSalary, Active) VALUES (NEWID(), 'Autre', 'Compagnie', 70000, 1)")

        ' La paie est configurée pour Alice (40 h/semaine) et Bruno (dépôt direct) ; pas pour Carl.
        Db.Exec("INSERT INTO paie.EmployePaie (EmployeId, HeuresSemaine) VALUES (@e, 40)", Db.P("@e", horaire))
        Db.Exec("INSERT INTO paie.EmployePaie (EmployeId, DepotDirect) VALUES (@e, 1)", Db.P("@e", annuel))

        Dim vue = Db.Table("SELECT * FROM paie.Employe WHERE CompagnieId = @c ORDER BY Id", Db.P("@c", compagnieId))
        Assert.AreEqual(4, vue.Rows.Count, "La vue ne montre que les employés de la compagnie.")
        Dim vueAlice = vue.Select("Id = " & horaire.ToString())(0)
        Assert.AreEqual(30D, vueAlice.Dcm("TauxHoraire"), "Le taux horaire de MngConsul sert de valeur par défaut.")
        Assert.AreEqual(26, vueAlice.Ent("PeriodesParAnnee"), "BiWeekly = 26 périodes.")
        Assert.AreEqual("QC", vueAlice.Txt("Province"))
        Assert.AreEqual("046454286", Outils.NasDe(vue.Select("Id = " & annuel.ToString())(0)), "À défaut de NAS chiffré, celui de MngConsul est repris.")
        Assert.IsFalse(vue.Select("Id = " & nonConfigure.ToString())(0).Bln("PaieConfiguree"))

        ' --- Étape 1 : création du lot
        Dim lot1 = ServicePaie.CreerLot(26, New Date(2026, 1, 10), New Date(2026, 1, 15))
        Assert.AreEqual(2, Db.ScalaireEntier("SELECT COUNT(*) FROM paie.Paie WHERE LotPaieId = @l", Db.P("@l", lot1)), "Seuls les employés actifs sont inclus.")
        Assert.AreEqual(New Date(2025, 12, 28), CDate(Db.Scalaire("SELECT DateDebutPeriode FROM paie.LotPaie WHERE Id = @l", Db.P("@l", lot1))))
        Assert.ThrowsException(Of SaisieInvalideException)(Sub() ServicePaie.CreerLot(26, New Date(2026, 1, 24), New Date(2026, 1, 29)), "Un seul brouillon à la fois.")

        ' --- Étape 2 : ajout d'un bonus à l'employée horaire
        Dim paieAlice = Db.ScalaireEntier("SELECT Id FROM paie.Paie WHERE LotPaieId = @l AND EmployeId = @e", Db.P("@l", lot1), Db.P("@e", horaire))
        Dim bonus = Db.Inserer("INSERT INTO paie.ElementPaie (CompagnieId, Description, CategorieCode) VALUES (@c, N'Bonus', 'BONUS')", Db.P("@c", compagnieId))
        ServicePaie.AjouterLigne(paieAlice, bonus, 0D, 0D, 500D)

        ' --- Étape 3 : calcul
        ServicePaie.CalculerLot(lot1)
        Dim alice = Db.Ligne("SELECT * FROM paie.Paie WHERE Id = @p", Db.P("@p", paieAlice))
        Assert.AreEqual(80D, alice.Dcm("Heures"))
        Assert.AreEqual(2900D, alice.Dcm("BrutVerse"))        ' 80 h × 30 $ + 500 $
        Assert.AreEqual(500D, alice.Dcm("ForfaitairesQuebec"))
        Assert.IsTrue(alice.Dcm("ImpotFederal") > 0D AndAlso alice.Dcm("ImpotQuebec") > 0D)
        Assert.AreEqual(alice.Dcm("BrutVerse") - alice.Dcm("ImpotFederal") - alice.Dcm("ImpotQuebec") - alice.Dcm("RRQ") - alice.Dcm("RRQ2") -
                        alice.Dcm("AE") - alice.Dcm("RQAP") - alice.Dcm("AutresDeductions"), alice.Dcm("Net"))
        Assert.AreEqual(43.5D, alice.Dcm("EmployeurCNESST"))   ' 2 900 $ × 1,5 %
        Assert.AreEqual(116D, alice.Dcm("VacancesAccumulees")) ' 4 %

        Dim bruno = Db.Ligne("SELECT * FROM paie.Paie WHERE LotPaieId = @l AND EmployeId = @e", Db.P("@l", lot1), Db.P("@e", annuel))
        Assert.AreEqual(4000D, bruno.Dcm("BrutVerse"))
        Assert.AreEqual(243.52D, bruno.Dcm("RRQ"))

        ' --- Rendu HTML (révision, sommaire, talon) : le texte de la base est encodé
        Dim tableau = RenduPaie.TableauLot(lot1, True, True)
        StringAssert.Contains(tableau, "Tremblay &lt;test&gt;")
        Assert.IsFalse(tableau.Contains("<test>"))
        StringAssert.Contains(RenduPaie.SommaireLot(lot1), "Bonus")
        StringAssert.Contains(RenduPaie.Talon(paieAlice), "Paie nette")

        ' --- Étape 4 : confirmation et numérotation des chèques (Bruno est en dépôt direct)
        ServicePaie.ConfirmerLot(lot1)
        Assert.AreEqual(100, Db.ScalaireEntier("SELECT NumeroCheque FROM paie.Paie WHERE Id = @p", Db.P("@p", paieAlice)))
        Assert.IsNull(Db.Scalaire("SELECT NumeroCheque FROM paie.Paie WHERE Id = @p", Db.P("@p", bruno.Ent("Id"))))
        Assert.AreEqual(101, Db.ScalaireEntier("SELECT ProchainNumeroCheque FROM paie.Compagnie WHERE Id = @c", Db.P("@c", compagnieId)))
        Assert.ThrowsException(Of SaisieInvalideException)(Sub() ServicePaie.CalculerLot(lot1), "Une paie confirmée n'est plus modifiable.")

        ' --- Deuxième paie : les cumulatifs de la première sont repris
        Dim cumul = ServicePaie.CumulatifsEmploye(horaire, 2026, 0)
        Assert.AreEqual(alice.Dcm("RRQ"), cumul.RRQ)
        Assert.AreEqual(500D, cumul.ForfaitairesQuebec)

        Dim lot2 = ServicePaie.CreerLot(26, New Date(2026, 1, 24), New Date(2026, 1, 29))
        Db.Exec("UPDATE paie.Paie SET Inclus = 0 WHERE LotPaieId = @l AND EmployeId = @e", Db.P("@l", lot2), Db.P("@e", annuel))
        ' Cotisation de 100 $ à un RPA, avec son propre compte de grand livre.
        Dim rpa = Db.Inserer("INSERT INTO paie.ElementPaie (CompagnieId, Description, CategorieCode, CompteGL) VALUES (@c, N'RPA', 'DED_RPA', N'2350')", Db.P("@c", compagnieId))
        ServicePaie.AjouterLigne(Db.ScalaireEntier("SELECT Id FROM paie.Paie WHERE LotPaieId = @l AND EmployeId = @e", Db.P("@l", lot2), Db.P("@e", horaire)), rpa, 0D, 0D, 100D)
        ServicePaie.CalculerLot(lot2)
        ServicePaie.ConfirmerLot(lot2)
        Assert.AreEqual(1, Db.ScalaireEntier("SELECT COUNT(*) FROM paie.Paie WHERE LotPaieId = @l", Db.P("@l", lot2)), "L'employé exclu est retiré à la confirmation.")
        Assert.AreEqual(101, Db.ScalaireEntier("SELECT NumeroCheque FROM paie.Paie WHERE LotPaieId = @l", Db.P("@l", lot2)))

        Dim talon2 = RenduPaie.Talon(Db.ScalaireEntier("SELECT Id FROM paie.Paie WHERE LotPaieId = @l", Db.P("@l", lot2)))
        StringAssert.Contains(talon2, Outils.Argent(2900D + 2400D), "Le brut cumulatif additionne les deux paies.")

        ' --- Feuillets T4 et Relevés 1
        Dim feuillets = ServiceFeuillets.Preparer(2026)
        Assert.AreEqual(2, feuillets.Count)
        Dim fa = feuillets.First(Function(f) f.Employe.Ent("Id") = horaire)
        Dim sommeAlice = Db.Ligne("SELECT SUM(p.ImpotFederal) Fed, SUM(p.ImpotQuebec) Qc, SUM(p.RRQ) RRQ FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId " &
                                  "WHERE p.EmployeId = @e AND l.Statut = 'C'", Db.P("@e", horaire))
        Assert.AreEqual(5300D, fa.CaseT4("14"))
        Assert.AreEqual(5300D, fa.CaseR1("A"))
        Assert.AreEqual(sommeAlice.Dcm("Fed"), fa.CaseT4("22"))
        Assert.AreEqual(sommeAlice.Dcm("Qc"), fa.CaseR1("E"))
        Assert.AreEqual(sommeAlice.Dcm("RRQ"), fa.CaseT4("17"))
        Assert.AreEqual(fa.CaseT4("17"), fa.CaseR1("B.A"))
        Assert.AreEqual(5300D, fa.CaseT4("24"))
        Assert.AreEqual(100D, fa.CaseT4("20"), "La cotisation au RPA va à la case 20 du T4...")
        Assert.AreEqual(100D, fa.CaseR1("D"), "...et à la case D du Relevé 1.")
        Assert.AreEqual(0D, fa.CaseT4("44"))
        Dim sommaire = ServiceFeuillets.SommaireEmployeur(2026)
        Assert.AreEqual(sommaire.Dcm("DuFederal"), CDec(Db.Scalaire("SELECT SUM(p.ImpotFederal + p.AE + p.EmployeurAE) FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE l.Statut = 'C'")))

        ' --- Déclaration des salaires CNESST
        Dim cnesst = ServiceCNESST.ParEmploye(2026).Select("Id = " & horaire.ToString())(0)
        Assert.AreEqual(5300D, cnesst.Dcm("Brut"))
        Assert.AreEqual(5300D, cnesst.Dcm("Assurable"))
        Assert.AreEqual(0D, cnesst.Dcm("Excedent"))
        Assert.AreEqual(79.5D, cnesst.Dcm("Cotisation"))      ' 5 300 $ × 1,5 %
        Assert.AreEqual(1, ServiceCNESST.ParMois(2026).Rows.Count)

        ' --- Écritures comptables : équilibrées, avec les comptes configurés
        ServiceGL.EnregistrerCompte("BANQUE", "1010")
        Dim ecritures = ServiceGL.EcrituresDuLot(lot2)
        Assert.AreEqual(ecritures.Sum(Function(x) x.Debit), ecritures.Sum(Function(x) x.Credit), "L'écriture doit être équilibrée.")
        Assert.AreEqual(100D, ecritures.Single(Function(x) x.Compte = "2350").Credit)
        Assert.AreEqual(CDec(Db.Scalaire("SELECT SUM(Net) FROM paie.Paie WHERE LotPaieId = @l", Db.P("@l", lot2))), ecritures.Single(Function(x) x.Compte = "1010").Credit)
        Dim ecrituresMois = ServiceGL.EcrituresDeLaPeriode(New Date(2026, 1, 1), New Date(2026, 1, 31))
        Assert.AreEqual(ecrituresMois.Sum(Function(x) x.Debit), ecrituresMois.Sum(Function(x) x.Credit))
        Assert.IsTrue(ecrituresMois.Sum(Function(x) x.Debit) > ecritures.Sum(Function(x) x.Debit), "Le mois couvre les deux paies.")

        ' --- Fichier de dépôt direct (Bruno est payé par dépôt direct dans la première paie)
        Assert.IsTrue(ServiceDepotDirect.Problemes(lot1).Count > 0, "Paramètres et coordonnées bancaires manquants.")
        Assert.ThrowsException(Of SaisieInvalideException)(Sub() ServiceDepotDirect.Generer(lot1))
        Db.Exec("UPDATE paie.Compagnie SET DDNumeroEmetteur = 'ABC1234567', DDCentreTraitement = '86900', DDNomCourt = N'Essai inc', DDInstitution = '815', " &
                "DDTransit = '30000', DDCompteChiffre = @cpt, Courriel = N'paie@exemple.ca' WHERE Id = @c", Db.P("@cpt", Secret.Proteger("1234567")), Db.P("@c", compagnieId))
        Db.Exec("UPDATE paie.EmployePaie SET Institution = '006', Transit = '12345' WHERE EmployeId = @e", Db.P("@e", annuel))   ' le compte vient de MngConsul
        Assert.AreEqual(0, ServiceDepotDirect.Problemes(lot1).Count)

        Dim fichier = ServiceDepotDirect.Generer(lot1)
        Dim enregistrements = System.Text.Encoding.ASCII.GetString(fichier.Contenu).Split({vbCrLf}, StringSplitOptions.RemoveEmptyEntries)
        Assert.AreEqual(3, enregistrements.Length, "Un en-tête A, un enregistrement C et un total Z.")
        Assert.IsTrue(enregistrements.All(Function(x) x.Length = 1464))
        Assert.IsTrue(enregistrements(0).StartsWith("A000000001ABC12345670001"))
        Dim netBruno = bruno.Dcm("Net")
        StringAssert.StartsWith(enregistrements(1), "C000000002ABC12345670001200" & CLng(netBruno * 100D).ToString("0000000000") & ServiceDepotDirect.Julien(New Date(2026, 1, 15)) & "0006123457654321")
        StringAssert.Contains(enregistrements(1), "GAGNON BRUNO")
        StringAssert.StartsWith(enregistrements(2), "Z000000003ABC12345670001" & New String("0"c, 22) & CLng(netBruno * 100D).ToString("00000000000000") & "00000001")
        Assert.AreEqual(1, fichier.NbDepots)
        Assert.AreEqual(2, Db.ScalaireEntier("SELECT DDProchainNumeroFichier FROM paie.Compagnie WHERE Id = @c", Db.P("@c", compagnieId)))

        ' --- Talons par courriel (écrits dans un dossier au lieu d'être envoyés)
        Dim dossier = Path.Combine(Path.GetTempPath(), "60secPaie-tests-" & Guid.NewGuid().ToString("N"))
        Directory.CreateDirectory(dossier)
        ServiceCourriel.FabriqueClient = Function() New Net.Mail.SmtpClient With {
            .DeliveryMethod = Net.Mail.SmtpDeliveryMethod.SpecifiedPickupDirectory, .PickupDirectoryLocation = dossier}
        Assert.ThrowsException(Of SaisieInvalideException)(Sub() ServiceCourriel.EnvoyerTalons(lot1, False), "Personne n'a demandé son talon par courriel.")
        Db.Exec("UPDATE paie.EmployePaie SET TalonParCourriel = 1 WHERE EmployeId = @e; UPDATE dbo.T300Employees SET Email = 'alice@exemple.ca' WHERE Id = @e", Db.P("@e", horaire))
        Dim bilan = ServiceCourriel.EnvoyerTalons(lot1, False)
        Assert.AreEqual(1, bilan.Envoyes)
        Assert.AreEqual(0, bilan.Erreurs.Count)
        Dim courriel = File.ReadAllText(Directory.GetFiles(dossier, "*.eml").Single())
        StringAssert.Contains(courriel, "alice@exemple.ca")
        bilan = ServiceCourriel.EnvoyerTalons(lot1, False)
        Assert.AreEqual(0, bilan.Envoyes)
        Assert.AreEqual(1, bilan.DejaEnvoyes, "Un talon déjà envoyé n'est pas renvoyé sans le demander.")

        ' Le talon part dans la langue de l'employé, même si la personne qui fait la paie travaille en français.
        I18n.CheminFichier = IntegrationMngConsulTests.DictionnaireDuSite()
        Db.Exec("UPDATE paie.EmployePaie SET Langue = 'EN' WHERE EmployeId = @e", Db.P("@e", horaire))
        For Each ancien In Directory.GetFiles(dossier, "*.eml") : File.Delete(ancien) : Next
        Assert.AreEqual(1, ServiceCourriel.EnvoyerTalons(lot1, True).Envoyes)
        StringAssert.Contains(File.ReadAllText(Directory.GetFiles(dossier, "*.eml").Single()), "Subject: Pay stub for ")
        Assert.AreEqual("fr", I18n.Langue)
        I18n.CheminFichier = Nothing
        Directory.Delete(dossier, True)

        ' --- Remises gouvernementales
        Dim soldeFed = ServiceRemise.Solde(ServiceRemise.Federal)
        Dim attenduFed = CDec(Db.Scalaire("SELECT SUM(p.ImpotFederal + p.AE + p.EmployeurAE) FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE l.Statut = 'C'"))
        Assert.AreEqual(3, soldeFed.NbPaies)
        Assert.AreEqual(attenduFed, soldeFed.Montant)
        Assert.AreEqual(New Date(2026, 1, 31), soldeFed.FinPeriode.Value)
        Assert.AreEqual(New Date(2026, 2, 15), soldeFed.Echeance.Value)
        Assert.AreEqual(New Date(2026, 4, 15), ServiceRemise.Echeance(New Date(2026, 1, 15), "T"), "Remise trimestrielle : le 15 suivant la fin du trimestre.")

        ' Revenu Québec, retenues accumulées au 20 janvier : seule la première paie (payée le 15) est couverte.
        Dim finQc = New Date(2026, 1, 20)
        Dim lignesQc = ServiceRemise.LignesAPayer(ServiceRemise.Quebec, finQc)
        Assert.AreEqual(7, lignesQc.Rows.Count)
        Assert.AreEqual(lignesQc.Select("Code = 'RRQ_EMPLOYE'")(0).Dcm("Montant"), lignesQc.Select("Code = 'RRQ_EMPLOYEUR'")(0).Dcm("Montant"))
        StringAssert.Contains(ServiceRemise.Rendu(lignesQc, ServiceRemise.LotsAPayer(ServiceRemise.Quebec, finQc)), "Total à payer")

        Dim remiseQc = ServiceRemise.Enregistrer(ServiceRemise.Quebec, finQc, New Date(2026, 2, 10), True, "")
        Dim rq = Db.Ligne("SELECT * FROM paie.Remise WHERE Id = @id", Db.P("@id", remiseQc))
        Assert.AreEqual(102, rq.Ent("NumeroCheque"), "Le chèque de remise suit les chèques de paie 100 et 101.")
        Assert.AreEqual(2, rq.Ent("NbPaies"))
        Assert.AreEqual(2, rq.Ent("NbEmployesDernierePaie"))
        Assert.AreEqual(6900D, rq.Dcm("RemunerationBrute"))   ' 2 900 $ + 4 000 $
        Assert.AreEqual(CDec(lignesQc.Compute("SUM(Montant)", "")), rq.Dcm("Total"))
        Assert.AreEqual(1, ServiceRemise.Solde(ServiceRemise.Quebec).NbPaies, "Il reste la deuxième paie à remettre au Québec.")
        Assert.ThrowsException(Of SaisieInvalideException)(Sub() ServiceRemise.Enregistrer(ServiceRemise.Quebec, finQc, New Date(2026, 2, 10), False, ""), "Rien à payer deux fois.")

        ' Fédéral, tout le mois de janvier : les trois paies.
        Dim remiseFed = ServiceRemise.Enregistrer(ServiceRemise.Federal, New Date(2026, 1, 31), New Date(2026, 2, 12), False, "CONF-123")
        Dim rf = Db.Ligne("SELECT * FROM paie.Remise WHERE Id = @id", Db.P("@id", remiseFed))
        Assert.AreEqual(attenduFed, rf.Dcm("Total"))
        Assert.AreEqual(1, rf.Ent("NbEmployesDernierePaie"))
        Assert.IsTrue(rf.IsNull("NumeroCheque"))
        Assert.AreEqual(0, ServiceRemise.Solde(ServiceRemise.Federal).NbPaies)

        ' Une paie dont les retenues sont payées ne peut plus être annulée...
        Assert.IsFalse(ServicePaie.PeutAnnuler(lot2))
        Assert.ThrowsException(Of SaisieInvalideException)(Sub() ServicePaie.AnnulerLot(lot2))
        ' ...tant que le paiement des retenues n'est pas lui-même annulé.
        ServiceRemise.Annuler(remiseFed)
        Assert.AreEqual(3, ServiceRemise.Solde(ServiceRemise.Federal).NbPaies)
        Assert.AreEqual(2, ServiceRemise.LotsDeLaRemise(remiseQc, ServiceRemise.Quebec).Rows(0).Ent("NbEmployes"))
        Assert.IsTrue(ServicePaie.PeutAnnuler(lot2))

        ' --- Annulation : seulement la paie la plus récente
        Assert.IsFalse(ServicePaie.PeutAnnuler(lot1))
        Assert.ThrowsException(Of SaisieInvalideException)(Sub() ServicePaie.AnnulerLot(lot1))
        ServicePaie.AnnulerLot(lot2)
        Assert.AreEqual("A", Convert.ToString(Db.Scalaire("SELECT Statut FROM paie.LotPaie WHERE Id = @l", Db.P("@l", lot2))))
        Assert.AreEqual(alice.Dcm("RRQ"), ServicePaie.CumulatifsEmploye(horaire, 2026, 0).RRQ, "La paie annulée sort des cumulatifs.")
        Assert.IsFalse(ServicePaie.PeutAnnuler(lot1), "Ses retenues sont payées à Revenu Québec.")
        ServiceRemise.Annuler(remiseQc)
        Assert.IsTrue(ServicePaie.PeutAnnuler(lot1))

        ' 2 confirmations, 1 dépôt direct, 2 envois de talons (français, puis anglais), 2 remises, 2 annulations de remise, 1 annulation de paie
        Assert.AreEqual(10, Db.ScalaireEntier("SELECT COUNT(*) FROM paie.JournalActivite"))
    End Sub

    <TestMethod>
    Public Sub Securite_NAS()
        Assert.IsTrue(Outils.NasValide("046454286"))
        Assert.IsFalse(Outils.NasValide("123456789"))
        Assert.AreEqual("••••••286", Secret.Masquer("046454286"))
    End Sub

End Class
