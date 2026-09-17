Imports System.IO
Imports System.Security.Principal
Imports System.Web
Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports Paie60Sec.Web

''' <summary>
''' Connexion avec les comptes de MngConsul, accès multi-compagnie et traduction.
''' Utilise la base jetable créée par CyclePaieIntegrationTests (répliques des tables de MngConsul).
''' </summary>
<TestClass>
Public Class IntegrationMngConsulTests

    Private Shared Sub Requete(courriel As String, Optional requeteUrl As String = "")
        HttpContext.Current = New HttpContext(New HttpRequest("", "http://localhost/", requeteUrl), New HttpResponse(New StringWriter()))
        HttpContext.Current.User = New GenericPrincipal(New GenericIdentity(courriel), New String() {})
    End Sub

    <TestMethod>
    Public Sub Connexion_AvecLesComptesMngConsul()
        Requete("")
        Dim cieA = Guid.NewGuid(), cieB = Guid.NewGuid(), comptable = Guid.NewGuid()
        ' Coût BCrypt de 4 pour des tests rapides ; MngConsul utilise 11, la vérification est identique.
        Dim hachage = BCrypt.Net.BCrypt.HashPassword("Un-Bon-MotDePasse", 4)
        Db.Exec("INSERT INTO dbo.T010Company (CompanyGUID, ComptableGUID) VALUES (@a, @k), (@b, @k); " &
                "INSERT INTO dbo.StubParam (CompanyGUID, ShortName, sVal) VALUES (@a, 'LEGAL_NAME', 'Alpha inc.'), (@b, 'TRADE_NAME', 'Bravo');",
                Db.P("@a", cieA), Db.P("@b", cieB), Db.P("@k", comptable))
        Db.Exec("INSERT INTO dbo.T015User (CompanyGUID, UserGUID, Email, PasswordHash, FirstName, LastName, IsAdmin, isAccountant) VALUES " &
                "(@a, NEWID(), 'usager@alpha.ca', @h, 'Ursule', 'Usager', 0, 0), " &
                "(@a, @k, 'comptable@cabinet.ca', @h, 'Claude', 'Comptable', 1, 1), " &
                "(NEWID(), NEWID(), 'orphelin@nulle-part.ca', @h, 'Oscar', 'Orphelin', 0, 0); " &
                "INSERT INTO dbo.T015User (CompanyGUID, Email, PasswordHash, IsActive) VALUES (@a, 'inactif@alpha.ca', @h, 0); " &
                "INSERT INTO dbo.T015User (CompanyGUID, Email, PasswordHash, IsDeleted) VALUES (@a, 'supprime@alpha.ca', @h, 1);",
                Db.P("@a", cieA), Db.P("@k", comptable), Db.P("@h", hachage))

        Assert.AreEqual(ServiceConnexion.Issue.Reussie, ServiceConnexion.Authentifier("  USAGER@alpha.ca ", "Un-Bon-MotDePasse"), "Le courriel est normalisé comme dans MngConsul.")
        Assert.AreEqual(ServiceConnexion.Issue.Refusee, ServiceConnexion.Authentifier("usager@alpha.ca", "mauvais"))
        Assert.AreEqual(ServiceConnexion.Issue.Refusee, ServiceConnexion.Authentifier("inconnu@alpha.ca", "Un-Bon-MotDePasse"))
        Assert.AreEqual(ServiceConnexion.Issue.Refusee, ServiceConnexion.Authentifier("inactif@alpha.ca", "Un-Bon-MotDePasse"))
        Assert.AreEqual(ServiceConnexion.Issue.Refusee, ServiceConnexion.Authentifier("supprime@alpha.ca", "Un-Bon-MotDePasse"))
        Assert.AreEqual(ServiceConnexion.Issue.AucuneCompagnie, ServiceConnexion.Authentifier("orphelin@nulle-part.ca", "Un-Bon-MotDePasse"))

        ' Un utilisateur normal n'a que sa compagnie ; un comptable a toutes celles dont il est le ComptableGUID.
        Assert.AreEqual(1, ServiceConnexion.CompagniesDe("usager@alpha.ca").Rows.Count)
        Assert.AreEqual(2, ServiceConnexion.CompagniesDe("comptable@cabinet.ca").Rows.Count)

        Requete("comptable@cabinet.ca")
        Assert.IsTrue(Contexte.EstAdmin)
        Assert.AreEqual("Claude Comptable", Contexte.Compte.Txt("NomComplet"))
        Assert.AreEqual(cieA, Contexte.CompanyGuid, "Par défaut : la première compagnie (ordre alphabétique : Alpha).")
        Assert.AreEqual("Alpha inc.", Contexte.NomCompagnie)
        Assert.AreEqual(0, Contexte.CompagnieId, "La paie n'est pas encore configurée pour cette compagnie.")

        Requete("usager@alpha.ca")
        Assert.IsFalse(Contexte.EstAdmin)
        HttpContext.Current.Items("Compagnies") = ServiceConnexion.CompagniesDe("usager@alpha.ca")
        Assert.AreEqual(cieA, Contexte.CompanyGuid)

        ' Verrouillage après 5 échecs, même avec le bon mot de passe ensuite.
        For i = 1 To ServiceConnexion.EchecsMaximum
            ServiceConnexion.Authentifier("comptable@cabinet.ca", "essai " & i.ToString())
        Next
        Assert.AreEqual(ServiceConnexion.Issue.Verrouillee, ServiceConnexion.Authentifier("comptable@cabinet.ca", "Un-Bon-MotDePasse"))
    End Sub

    <TestMethod>
    Public Sub Traduction_DuHtmlProduit()
        Dim fichier = Path.Combine(Path.GetTempPath(), "traductions-test-" & Guid.NewGuid().ToString("N") & ".txt")
        File.WriteAllLines(fichier, {
            "# commentaire", "fr: Employés", "en: Employees", "es: Empleados", "",
            "fr: Enregistrer", "en: Save", "es: Guardar", "",
            "fr: Supprimer cet élément de paie ?", "en: Delete this pay item?", "es: ¿Eliminar este elemento de nómina?", "",
            "fr: L'impôt du Québec", "en: Québec income tax", "",
            "fr: {0} employés actifs", "en: {0} active employees", "es: {0} empleados activos"})
        I18n.CheminFichier = fichier
        Try
            Dim html = "<h1>  Employés </h1><input type=""submit"" value=""Enregistrer"" onclick=""return confirm(&#39;Supprimer cet élément de paie ?&#39;);"" />" &
                       "<td>L&#39;impôt du Québec</td><td>Tremblay, Alice</td><input type=""text"" value=""Enregistrer"" /><script>var x = 'Employés';</script><b translate=""no"">Employés</b>"

            Requete("x@y.ca", "lang=en")
            Dim en = I18n.TraduireHtml(html)
            StringAssert.Contains(en, "<h1>  Employees </h1>", "Les espaces autour du texte sont conservés.")
            StringAssert.Contains(en, "type=""submit"" value=""Save""")
            StringAssert.Contains(en, "confirm(&#39;Delete this pay item?&#39;)")
            StringAssert.Contains(en, "<td>Québec income tax</td>", "Le texte encodé (&#39;) est reconnu.")
            StringAssert.Contains(en, "<td>Tremblay, Alice</td>", "Les données ne sont pas touchées.")
            StringAssert.Contains(en, "type=""text"" value=""Enregistrer""", "La valeur d'un champ de saisie n'est jamais traduite.")
            StringAssert.Contains(en, "var x = 'Employés';", "Les scripts ne sont pas traduits.")
            StringAssert.Contains(en, "<b translate=""no"">Employés</b>", "translate=""no"" protège un texte (nom du produit).")
            Assert.AreEqual("3 active employees", I18n.T("{0} employés actifs", 3))
            Assert.AreEqual("$1,234.50", Outils.Argent(1234.5D))

            Requete("x@y.ca", "lang=es")
            StringAssert.Contains(I18n.TraduireHtml(html), "<h1>  Empleados </h1>")
            StringAssert.Contains(I18n.TraduireHtml(html), "L&#39;impôt du Québec", "Sans traduction espagnole, le français reste.")

            Requete("x@y.ca")
            Assert.AreSame(html, I18n.TraduireHtml(html), "En français, rien n'est transformé.")
            Assert.AreEqual("1 234,50 $", Outils.Argent(1234.5D).Replace(ChrW(160), " "c))
        Finally
            I18n.CheminFichier = Nothing
            File.Delete(fichier)
        End Try
    End Sub

    Friend Shared Function DictionnaireDuSite() As String
        Dim dossier = AppDomain.CurrentDomain.BaseDirectory
        Return Path.GetFullPath(Path.Combine(dossier, "..\..\..\..\60secPaie.Web\Langues\traductions.txt"))
    End Function

    <TestMethod>
    Public Sub Traduction_DictionnaireDuSiteComplet()
        Dim en = I18n.Charger(DictionnaireDuSite(), "en")
        Dim es = I18n.Charger(DictionnaireDuSite(), "es")
        Assert.IsTrue(en.Count > 500, "Le dictionnaire du site est chargé.")
        CollectionAssert.AreEquivalent(en.Keys.ToList(), es.Keys.ToList(), "Chaque texte a sa traduction anglaise et espagnole.")

        ' Une traduction doit reprendre exactement les jetons ({0}, {#1}…) de son modèle français.
        Dim jetons As New System.Text.RegularExpressions.Regex("\{#?\d\}")
        Dim jetonsDe = Function(t As String) String.Join(" ", jetons.Matches(t).Cast(Of System.Text.RegularExpressions.Match)().Select(Function(m) m.Value).OrderBy(Function(v) v, StringComparer.Ordinal))
        For Each d In {en, es}
            For Each paire In d
                Assert.AreEqual(jetonsDe(paire.Key), jetonsDe(paire.Value), "Jetons différents : " & paire.Key)
            Next
        Next
    End Sub

    <TestMethod>
    Public Sub Traduction_TextesAvecDonnees()
        I18n.CheminFichier = DictionnaireDuSite()
        Try
            Requete("x@y.ca", "lang=en")
            Assert.AreEqual("Pay run of 2026-01-15 confirmed.", I18n.Traduire("Paie du 2026-01-15 confirmée.", "en"))
            Assert.AreEqual("Remittance paid to Revenu Québec: $1,234.50.", I18n.Traduire("Paiement des retenues à Revenu Québec : 1 234,50 $.", "en"),
                            "Le journal est enregistré en français ; le montant suit la langue d'affichage.")
            Assert.AreEqual("Remittance paid to Receiver General for Canada: $80.00.", I18n.Traduire("Paiement des retenues à Receveur général du Canada : 80,00 $.", "en"))
            Assert.AreEqual("«Tarifa por hora»: número no válido.", I18n.Traduire("« Taux horaire » : nombre invalide.", "es"), "Le nom du champ est traduit à son tour.")
            StringAssert.Contains(I18n.Traduire("Receveur général du Canada · retenues accumulées au 2026-01-31 · payé le 2026-02-10 · Chèque n° 12 · enregistré par x@y.ca", "en"),
                                  "· Cheque no. 12 · recorded by x@y.ca")
            Assert.AreEqual("Earnings - Wages", I18n.Traduire("Revenu - Salaire", "en"))
            Assert.AreEqual("3 active employees · last pay run: 2026-01-15", I18n.Traduire("3 employés actifs · dernière paie : 2026-01-15", "en"))
            Assert.AreEqual("Tremblay, Alice", I18n.Traduire("Tremblay, Alice", "en"), "Une donnée sans traduction reste telle quelle.")

            ' Rendu dans la langue de l'employé (courriel), sans changer celle de l'utilisateur.
            Assert.AreEqual("es|Talón de pago", I18n.DansLaLangue("ES", Function() I18n.Langue & "|" & I18n.T("Talon de paie")))
            Assert.AreEqual("en", I18n.Langue)
        Finally
            I18n.CheminFichier = Nothing
        End Try
    End Sub

    <TestMethod>
    Public Sub Saisie_NombresSelonLaLangue()
        Assert.AreEqual(1234.56D, Outils.Dec("1 234,56 $", "x"))
        Assert.AreEqual(1234.56D, Outils.Dec("1,234.56", "x"), "Format anglais.")
        Assert.AreEqual(1234.56D, Outils.Dec("1.234,56", "x"), "Format espagnol.")
        Assert.AreEqual(12.5D, Outils.Dec("12.5", "x"))
        Assert.AreEqual(12.5D, Outils.Dec("12,5", "x"))
    End Sub

End Class
