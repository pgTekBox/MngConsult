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

    <ClassInitialize>
    Public Shared Sub CreerBase(contexte As TestContext)
        ExecuterLots(Maitre,
            "IF DB_ID(N'" & BaseTest & "') IS NOT NULL BEGIN ALTER DATABASE [" & BaseTest & "] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [" & BaseTest & "]; END" & vbCrLf & "GO" & vbCrLf &
            "CREATE DATABASE [" & BaseTest & "];")

        Dim racine = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "..", ".."))
        Dim schema = File.ReadAllText(Path.Combine(racine, "Database", "01_schema.sql")).Replace("60secPaie", BaseTest)
        ExecuterLots(Maitre, schema)
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
        ' --- Données de base
        Dim compagnieId = Db.Inserer("INSERT INTO dbo.Compagnie (Nom, PeriodesParAnnee, TauxCNESST, ProchainNumeroCheque) VALUES (N'Compagnie d''essai', 26, 1.5, 100)")
        Assert.AreEqual(compagnieId, Contexte.CompagnieId)

        Dim horaire = Db.Inserer(
            "INSERT INTO dbo.Employe (CompagnieId, Prenom, Nom, DateNaissance, DateEmbauche, HeuresSemaine, TauxHoraire) VALUES (@c, N'Alice', N'Tremblay <test>', '1990-05-01', '2025-01-01', 40, 30)",
            Db.P("@c", compagnieId))
        Dim annuel = Db.Inserer(
            "INSERT INTO dbo.Employe (CompagnieId, Prenom, Nom, DateEmbauche, SalaireAnnuel, DepotDirect) VALUES (@c, N'Bruno', N'Gagnon', '2025-01-01', 104000, 1)",
            Db.P("@c", compagnieId))
        Db.Exec("INSERT INTO dbo.Employe (CompagnieId, Prenom, Nom, Actif, SalaireAnnuel) VALUES (@c, N'Inactif', N'Exclu', 0, 50000)", Db.P("@c", compagnieId))

        ' --- Étape 1 : création du lot
        Dim lot1 = ServicePaie.CreerLot(26, New Date(2026, 1, 10), New Date(2026, 1, 15))
        Assert.AreEqual(2, Db.ScalaireEntier("SELECT COUNT(*) FROM dbo.Paie WHERE LotPaieId = @l", Db.P("@l", lot1)), "Seuls les employés actifs sont inclus.")
        Assert.AreEqual(New Date(2025, 12, 28), CDate(Db.Scalaire("SELECT DateDebutPeriode FROM dbo.LotPaie WHERE Id = @l", Db.P("@l", lot1))))
        Assert.ThrowsException(Of SaisieInvalideException)(Sub() ServicePaie.CreerLot(26, New Date(2026, 1, 24), New Date(2026, 1, 29)), "Un seul brouillon à la fois.")

        ' --- Étape 2 : ajout d'un bonus à l'employée horaire
        Dim paieAlice = Db.ScalaireEntier("SELECT Id FROM dbo.Paie WHERE LotPaieId = @l AND EmployeId = @e", Db.P("@l", lot1), Db.P("@e", horaire))
        Dim bonus = Db.Inserer("INSERT INTO dbo.ElementPaie (CompagnieId, Description, CategorieCode) VALUES (@c, N'Bonus', 'BONUS')", Db.P("@c", compagnieId))
        ServicePaie.AjouterLigne(paieAlice, bonus, 0D, 0D, 500D)

        ' --- Étape 3 : calcul
        ServicePaie.CalculerLot(lot1)
        Dim alice = Db.Ligne("SELECT * FROM dbo.Paie WHERE Id = @p", Db.P("@p", paieAlice))
        Assert.AreEqual(80D, alice.Dcm("Heures"))
        Assert.AreEqual(2900D, alice.Dcm("BrutVerse"))        ' 80 h × 30 $ + 500 $
        Assert.AreEqual(500D, alice.Dcm("ForfaitairesQuebec"))
        Assert.IsTrue(alice.Dcm("ImpotFederal") > 0D AndAlso alice.Dcm("ImpotQuebec") > 0D)
        Assert.AreEqual(alice.Dcm("BrutVerse") - alice.Dcm("ImpotFederal") - alice.Dcm("ImpotQuebec") - alice.Dcm("RRQ") - alice.Dcm("RRQ2") -
                        alice.Dcm("AE") - alice.Dcm("RQAP") - alice.Dcm("AutresDeductions"), alice.Dcm("Net"))
        Assert.AreEqual(43.5D, alice.Dcm("EmployeurCNESST"))   ' 2 900 $ × 1,5 %
        Assert.AreEqual(116D, alice.Dcm("VacancesAccumulees")) ' 4 %

        Dim bruno = Db.Ligne("SELECT * FROM dbo.Paie WHERE LotPaieId = @l AND EmployeId = @e", Db.P("@l", lot1), Db.P("@e", annuel))
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
        Assert.AreEqual(100, Db.ScalaireEntier("SELECT NumeroCheque FROM dbo.Paie WHERE Id = @p", Db.P("@p", paieAlice)))
        Assert.IsNull(Db.Scalaire("SELECT NumeroCheque FROM dbo.Paie WHERE Id = @p", Db.P("@p", bruno.Ent("Id"))))
        Assert.AreEqual(101, Db.ScalaireEntier("SELECT ProchainNumeroCheque FROM dbo.Compagnie WHERE Id = @c", Db.P("@c", compagnieId)))
        Assert.ThrowsException(Of SaisieInvalideException)(Sub() ServicePaie.CalculerLot(lot1), "Une paie confirmée n'est plus modifiable.")

        ' --- Deuxième paie : les cumulatifs de la première sont repris
        Dim cumul = ServicePaie.CumulatifsEmploye(horaire, 2026, 0)
        Assert.AreEqual(alice.Dcm("RRQ"), cumul.RRQ)
        Assert.AreEqual(500D, cumul.ForfaitairesQuebec)

        Dim lot2 = ServicePaie.CreerLot(26, New Date(2026, 1, 24), New Date(2026, 1, 29))
        Db.Exec("UPDATE dbo.Paie SET Inclus = 0 WHERE LotPaieId = @l AND EmployeId = @e", Db.P("@l", lot2), Db.P("@e", annuel))
        ServicePaie.CalculerLot(lot2)
        ServicePaie.ConfirmerLot(lot2)
        Assert.AreEqual(1, Db.ScalaireEntier("SELECT COUNT(*) FROM dbo.Paie WHERE LotPaieId = @l", Db.P("@l", lot2)), "L'employé exclu est retiré à la confirmation.")
        Assert.AreEqual(101, Db.ScalaireEntier("SELECT NumeroCheque FROM dbo.Paie WHERE LotPaieId = @l", Db.P("@l", lot2)))

        Dim talon2 = RenduPaie.Talon(Db.ScalaireEntier("SELECT Id FROM dbo.Paie WHERE LotPaieId = @l", Db.P("@l", lot2)))
        StringAssert.Contains(talon2, Outils.Argent(2900D + 2400D), "Le brut cumulatif additionne les deux paies.")

        ' --- Remises gouvernementales
        Dim soldeFed = ServiceRemise.Solde(ServiceRemise.Federal)
        Dim attenduFed = CDec(Db.Scalaire("SELECT SUM(p.ImpotFederal + p.AE + p.EmployeurAE) FROM dbo.Paie p JOIN dbo.LotPaie l ON l.Id = p.LotPaieId WHERE l.Statut = 'C'"))
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
        Dim rq = Db.Ligne("SELECT * FROM dbo.Remise WHERE Id = @id", Db.P("@id", remiseQc))
        Assert.AreEqual(102, rq.Ent("NumeroCheque"), "Le chèque de remise suit les chèques de paie 100 et 101.")
        Assert.AreEqual(2, rq.Ent("NbPaies"))
        Assert.AreEqual(2, rq.Ent("NbEmployesDernierePaie"))
        Assert.AreEqual(6900D, rq.Dcm("RemunerationBrute"))   ' 2 900 $ + 4 000 $
        Assert.AreEqual(CDec(lignesQc.Compute("SUM(Montant)", "")), rq.Dcm("Total"))
        Assert.AreEqual(1, ServiceRemise.Solde(ServiceRemise.Quebec).NbPaies, "Il reste la deuxième paie à remettre au Québec.")
        Assert.ThrowsException(Of SaisieInvalideException)(Sub() ServiceRemise.Enregistrer(ServiceRemise.Quebec, finQc, New Date(2026, 2, 10), False, ""), "Rien à payer deux fois.")

        ' Fédéral, tout le mois de janvier : les trois paies.
        Dim remiseFed = ServiceRemise.Enregistrer(ServiceRemise.Federal, New Date(2026, 1, 31), New Date(2026, 2, 12), False, "CONF-123")
        Dim rf = Db.Ligne("SELECT * FROM dbo.Remise WHERE Id = @id", Db.P("@id", remiseFed))
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
        Assert.AreEqual("A", Convert.ToString(Db.Scalaire("SELECT Statut FROM dbo.LotPaie WHERE Id = @l", Db.P("@l", lot2))))
        Assert.AreEqual(alice.Dcm("RRQ"), ServicePaie.CumulatifsEmploye(horaire, 2026, 0).RRQ, "La paie annulée sort des cumulatifs.")
        Assert.IsFalse(ServicePaie.PeutAnnuler(lot1), "Ses retenues sont payées à Revenu Québec.")
        ServiceRemise.Annuler(remiseQc)
        Assert.IsTrue(ServicePaie.PeutAnnuler(lot1))

        Assert.AreEqual(7, Db.ScalaireEntier("SELECT COUNT(*) FROM dbo.JournalActivite"))
    End Sub

    <TestMethod>
    Public Sub Securite_MotsDePasse_et_NAS()
        Dim hache = MotsDePasse.Hacher("un mot de passe solide")
        Assert.IsTrue(MotsDePasse.Verifier("un mot de passe solide", hache))
        Assert.IsFalse(MotsDePasse.Verifier("un autre", hache))
        Assert.AreNotEqual(hache, MotsDePasse.Hacher("un mot de passe solide"), "Le sel est aléatoire.")

        Assert.IsTrue(Outils.NasValide("046454286"))
        Assert.IsFalse(Outils.NasValide("123456789"))
        Assert.AreEqual("••••••286", Secret.Masquer("046454286"))
    End Sub

End Class
