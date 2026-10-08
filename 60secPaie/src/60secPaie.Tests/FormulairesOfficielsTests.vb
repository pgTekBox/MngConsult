Imports System.Data
Imports System.IO
Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports Paie60Sec.Web
Imports PdfSharp.Pdf
Imports PdfSharp.Pdf.IO

''' <summary>
''' Les formulaires officiels : préparation (déchiffrement, champs reconstruits) et remplissage du T4 de l'ARC
''' et du Relevé 1 de Revenu Québec. Les formulaires eux-mêmes ne sont pas dans le dépôt : le test est non
''' concluant quand ils manquent sur le poste.
''' </summary>
<TestClass>
Public Class FormulairesOfficielsTests

    Private Shared ReadOnly CheminT4 As String = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Desktop), "t4-fill-25f.pdf")
    Private Shared ReadOnly CheminR1 As String = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Desktop), "RL-1(2025-10)DXI.pdf")

    <TestMethod>
    Public Sub Formulaires_T4EtReleve1_SeRemplissent()
        If Not File.Exists(CheminT4) OrElse Not File.Exists(CheminR1) Then Assert.Inconclusive("Les formulaires officiels 2025 ne sont pas sur ce poste.")

        Dim fo As New FormulairesAnnee With {.Annee = 2025,
            .T4 = FormulaireOfficiel.Preparer(File.ReadAllBytes(CheminT4), FormulaireOfficiel.TypeT4),
            .R1 = FormulaireOfficiel.Preparer(File.ReadAllBytes(CheminR1), FormulaireOfficiel.TypeR1)}
        Assert.IsTrue(fo.T4.Length > 10000 AndAlso fo.R1.Length > 10000, "Les copies préparées sont de vrais fichiers.")
        Assert.ThrowsException(Of SaisieInvalideException)(Sub() FormulaireOfficiel.Preparer(File.ReadAllBytes(CheminR1), FormulaireOfficiel.TypeT4), "Un Relevé 1 n'est pas accepté comme T4.")

        Dim compagnie = CompagnieFactice()
        Dim feuillets As New List(Of Feuillet) From {Employe(1, "Tremblay", "Alice", 52000D), Employe(2, "Gagnon", "Bruno", 61000D), Employe(3, "Roy", "Chloé", 43000D)}

        ' Un employé : une page T4 (feuillet 1 rempli, feuillet 2 vide) et la page du Relevé 1 qui convient à la copie.
        Dim octetsUn = FormulaireOfficiel.Produire(feuillets(0), compagnie, 2025, CopieFeuillet.Employe, fo)
        Dim un = Ouvrir(octetsUn)
        Conserver("un.pdf", octetsUn)
        Assert.AreEqual(2, un.PageCount)
        Dim valeurs = ValeursDe(un)
        Assert.AreEqual("52000.00", valeurs("t4_1_form1[0].Page1[0].Slip1[0].Box14[0].Slip1Box14[0]"), "Case 14 du feuillet 1.")
        Assert.AreEqual("046454286", valeurs("t4_1_form1[0].Page1[0].Slip1[0].Box12[0].Slip1Box12[0]"), "NAS sans espaces.")
        Assert.AreEqual("QC", valeurs("t4_1_form1[0].Page1[0].Slip1[0].Box10[0].Slip1Box10[0]"))
        Assert.AreEqual("2025", valeurs("t4_1_form1[0].Page1[0].Slip1[0].Year[0].Slip1Year[0]"))
        Assert.IsFalse(valeurs.ContainsKey("t4_1_form1[0].Page1[0].Slip2[0].Box14[0].Slip1Box14[0]"), "Le feuillet 2 reste vide.")
        ' Lecture seule : Courier 9 points noir sur les champs de texte, champs verrouillés, document protégé (sans mot de passe d'ouverture).
        Dim champs = ChampsDe(un)
        Dim case14 = champs("t4_1_form1[0].Page1[0].Slip1[0].Box14[0].Slip1Box14[0]")
        Assert.AreEqual("/Cour 9 Tf 0 g", case14.Elements.GetString("/DA"), "Les valeurs sont en Courier 9 points, noir.")
        Assert.AreEqual(1, case14.Elements.GetInteger("/Ff") And 1, "Le champ est en lecture seule.")
        Dim exempt = champs.Keys.First(Function(k) k.Contains("Box28") AndAlso Not champs(k).Elements.ContainsKey("/Kids"))
        Assert.AreNotEqual("/Cour 9 Tf 0 g", champs(exempt).Elements.GetString("/DA"), "Les cases à cocher gardent leur apparence.")
        Assert.AreEqual(1, champs(exempt).Elements.GetInteger("/Ff") And 1, "Les cases à cocher sont verrouillées aussi.")
        StringAssert.Contains(Text.Encoding.ASCII.GetString(octetsUn), "/Encrypt", "Le document est protégé contre la modification.")
        ' Les apparences sont dessinées par 60secPaie (le lecteur n'a rien à régénérer) : Courier 9 sur la case 14, dont le
        ' point décimal est posé contre le trait des cents (champ prolongé jusqu'au bord de la case) ; 10 points dans la
        ' petite case 10 ; le bouton « Effacer » du haut du formulaire est retiré.
        Assert.IsFalse(un.Internals.Catalog.Elements.GetDictionary("/AcroForm").Elements.GetBoolean("/NeedAppearances"))
        Dim apparence14 = ApparenceDe(case14)
        StringAssert.Contains(apparence14, "/Cour 9 Tf 0 g", "Courier 9 points, noir.")
        StringAssert.Contains(apparence14, "(52000.00) Tj", "La valeur est dessinée.")
        StringAssert.Contains(apparence14, " 38.62 5.04 Tm ", "Point décimal contre le trait des cents : 71,4 - 0,3 - 6 x 5,4.")
        Assert.AreEqual(455.0, Math.Round(case14.Elements.GetRectangle("/Rect").X2, 1), "La case du champ est prolongée jusqu'au bord dessiné.")
        StringAssert.Contains(ApparenceDe(champs("t4_1_form1[0].Page1[0].Slip1[0].Box10[0].Slip1Box10[0]")), "/Cour 10 Tf 0 g 1 0 0 1 2 4.76 Tm (QC) Tj", "Petite case en 10 points.")
        Assert.IsFalse(champs.Keys.Any(Function(k) k.Contains("ClearData")), "Le bouton « Effacer les données » est retiré.")
        Dim polices = un.Internals.Catalog.Elements.GetDictionary("/AcroForm").Elements.GetDictionary("/DR").Elements.GetDictionary("/Font")
        Assert.AreEqual("/Courier", polices.Elements.GetDictionary("/Cour").Elements.GetName("/BaseFont"), "Courier est dans les ressources du formulaire.")
        ' La copie 2 (employé) ne porte que les champs « rep_ » : la case A, l'identité, le code du relevé.
        Assert.AreEqual("52000.00", valeurs("r1_1_rep_caseA"), "Case A du Relevé 1, copie de l'employé.")
        StringAssert.Contains(valeurs("r1_1_rep_Identifiant1"), "TREMBLAY")
        Assert.AreEqual("1", valeurs("r1_1_rep_codeReleve"), "Relevé original.")
        Assert.IsFalse(valeurs.ContainsKey("r1_1_caseA"), "La case A de la copie 1 n'est pas sur cette page.")

        ' Tous : deux T4 par page, puis une page de Relevé 1 par employé.
        Dim octetsTous = FormulaireOfficiel.ProduireTous(feuillets, compagnie, 2025, CopieFeuillet.Employeur, fo)
        Conserver("tous.pdf", octetsTous)
        Dim tous = Ouvrir(octetsTous)
        Assert.AreEqual(2 + 3, tous.PageCount)
        valeurs = ValeursDe(tous)
        Assert.AreEqual("61000.00", valeurs("t4_1_form1[0].Page1[0].Slip2[0].Box14[0].Slip1Box14[0]"), "Le deuxième employé est sur le feuillet 2 de la page 1.")
        Assert.AreEqual("43000.00", valeurs("t4_2_form1[0].Page1[0].Slip1[0].Box14[0].Slip1Box14[0]"), "Le troisième ouvre la page 2.")
        Assert.AreEqual(3, valeurs.Keys.Where(Function(k) k.EndsWith("_rep_caseA", StringComparison.Ordinal)).Count(), "Un Relevé 1 par employé.")

        ' Gouvernement : les T4, le Sommaire T4, les Relevés 1, le Sommaire 1.
        Dim sommaire = SommaireFactice()
        Dim octetsGouv = FormulaireOfficiel.ProduireGouvernement(feuillets, compagnie, 2025, sommaire, fo)
        Conserver("gouv.pdf", octetsGouv)
        Dim gouv = Ouvrir(octetsGouv)
        Assert.AreEqual(2 + 1 + 3 + 1, gouv.PageCount)
        valeurs = ValeursDe(gouv)
        Assert.AreEqual("52000.00", valeurs("r1_1000_caseA"), "La copie 1 (Revenu Québec) porte les champs principaux.")
        Assert.AreEqual("TREMBLAY", valeurs("r1_1000_nom1"))
    End Sub

    ''' <summary>Garde une copie des PDF produits dans le dossier P60_FEUILLETS_SORTIE, quand cette variable d'environnement est définie (inspection visuelle).</summary>
    Private Shared Sub Conserver(nom As String, pdf As Byte())
        Dim dossier = Environment.GetEnvironmentVariable("P60_FEUILLETS_SORTIE")
        If Not String.IsNullOrEmpty(dossier) AndAlso Directory.Exists(dossier) Then File.WriteAllBytes(Path.Combine(dossier, nom), pdf)
    End Sub

    Private Shared Function Ouvrir(pdf As Byte()) As PdfDocument
        Assert.AreEqual("%PDF", Text.Encoding.ASCII.GetString(pdf, 0, 4))
        Return PdfReader.Open(New MemoryStream(pdf), PdfDocumentOpenMode.Import)
    End Function

    ''' <summary>Nom complet → valeur, pour chaque champ qui en a une.</summary>
    Private Shared Function ValeursDe(doc As PdfDocument) As Dictionary(Of String, String)
        Dim d As New Dictionary(Of String, String)(StringComparer.Ordinal)
        Dim fields = doc.Internals.Catalog.Elements.GetDictionary("/AcroForm").Elements.GetArray("/Fields")
        For i = 0 To fields.Elements.Count - 1
            Parcourir(fields.Elements.GetDictionary(i), "", d)
        Next
        Return d
    End Function

    Private Shared Sub Parcourir(champ As PdfDictionary, chemin As String, d As Dictionary(Of String, String))
        If champ Is Nothing Then Return
        Dim nom = chemin
        If champ.Elements.ContainsKey("/T") Then nom = If(chemin.Length = 0, "", chemin & ".") & champ.Elements.GetString("/T")
        If champ.Elements.ContainsKey("/V") Then
            Dim v = champ.Elements("/V")
            d(nom) = If(TypeOf v Is PdfString, DirectCast(v, PdfString).Value, v.ToString())
        End If
        Dim kids = champ.Elements.GetArray("/Kids")
        If kids Is Nothing Then Return
        For i = 0 To kids.Elements.Count - 1
            Parcourir(kids.Elements.GetDictionary(i), nom, d)
        Next
    End Sub

    ''' <summary>Le flux de l'apparence normale d'une case.</summary>
    Private Shared Function ApparenceDe(champ As PdfDictionary) As String
        Dim n = champ.Elements.GetDictionary("/AP").Elements.GetDictionary("/N")
        Return Text.Encoding.ASCII.GetString(n.Stream.UnfilteredValue)
    End Function

    ''' <summary>Nom complet → dictionnaire du champ, pour chaque champ nommé.</summary>
    Private Shared Function ChampsDe(doc As PdfDocument) As Dictionary(Of String, PdfDictionary)
        Dim d As New Dictionary(Of String, PdfDictionary)(StringComparer.Ordinal)
        Dim fields = doc.Internals.Catalog.Elements.GetDictionary("/AcroForm").Elements.GetArray("/Fields")
        For i = 0 To fields.Elements.Count - 1
            ParcourirChamps(fields.Elements.GetDictionary(i), "", d)
        Next
        Return d
    End Function

    Private Shared Sub ParcourirChamps(champ As PdfDictionary, chemin As String, d As Dictionary(Of String, PdfDictionary))
        If champ Is Nothing Then Return
        Dim nom = chemin
        If champ.Elements.ContainsKey("/T") Then
            nom = If(chemin.Length = 0, "", chemin & ".") & champ.Elements.GetString("/T")
            d(nom) = champ
        End If
        Dim kids = champ.Elements.GetArray("/Kids")
        If kids Is Nothing Then Return
        For i = 0 To kids.Elements.Count - 1
            ParcourirChamps(kids.Elements.GetDictionary(i), nom, d)
        Next
    End Sub

    Private Shared Function CompagnieFactice() As DataRow
        Dim t As New DataTable()
        For Each c In {"Nom", "Adresse1", "Adresse2", "Ville", "Province", "CodePostal", "NumeroEntrepriseFederal", "NumeroIdentificationRQ", "Courriel"}
            t.Columns.Add(c, GetType(String))
        Next
        Dim r = t.NewRow()
        r("Nom") = "Compagnie d'essai inc." : r("Adresse1") = "100 rue Principale" : r("Adresse2") = "" : r("Ville") = "Longueuil" : r("Province") = "QC"
        r("CodePostal") = "J4K 1A1" : r("NumeroEntrepriseFederal") = "123456789RP0001" : r("NumeroIdentificationRQ") = "1234567890RS0001" : r("Courriel") = ""
        t.Rows.Add(r)
        Return r
    End Function

    Private Shared Function Employe(id As Integer, nom As String, prenom As String, brut As Decimal) As Feuillet
        Dim t As New DataTable()
        t.Columns.Add("Id", GetType(Integer))
        For Each c In {"Nom", "Prenom", "Code", "Adresse1", "Adresse2", "Ville", "Province", "CodePostal", "NASChiffre", "NASMngConsul", "Courriel", "Langue"}
            t.Columns.Add(c, GetType(String))
        Next
        t.Columns.Add("CodeDentaireT4", GetType(Integer))
        For Each c In {"ExemptRRQ", "ExemptAE", "ExemptRQAP", "TalonParCourriel"}
            t.Columns.Add(c, GetType(Boolean))
        Next
        Dim r = t.NewRow()
        r("Id") = id : r("Nom") = nom : r("Prenom") = prenom : r("Code") = "E" & id.ToString() : r("Adresse1") = "12 rue des Érables" : r("Adresse2") = "app. 3"
        r("Ville") = "Montréal" : r("Province") = "QC" : r("CodePostal") = "H2X 1Y4" : r("NASChiffre") = "" : r("NASMngConsul") = "046 454 286"
        r("Courriel") = "" : r("Langue") = "FR" : r("CodeDentaireT4") = 1
        r("ExemptRRQ") = False : r("ExemptAE") = False : r("ExemptRQAP") = False : r("TalonParCourriel") = False
        t.Rows.Add(r)
        Dim f As New Feuillet With {.Employe = r, .Province = "QC", .AvecReleve1 = True}
        f.ProvincesEmploi.Add("QC")
        f.T4("14") = brut : f.T4("22") = Decimal.Round(brut * 0.15D, 2) : f.T4("17") = 2500D : f.T4("18") = 700D : f.T4("24") = brut : f.T4("26") = brut : f.T4("55") = 250D : f.T4("56") = brut
        f.R1("A") = brut : f.R1("B.A") = 2500D : f.R1("C") = 700D : f.R1("E") = Decimal.Round(brut * 0.12D, 2) : f.R1("G") = brut : f.R1("H") = 250D : f.R1("I") = brut
        Return f
    End Function

    Private Shared Function SommaireFactice() As DataRow
        Dim t As New DataTable()
        For Each c In {"EmployeurRRQ", "EmployeurAE", "EmployeurRQAP", "FSS", "MasseFSS", "CNESST", "CNT", "EmployeurRPC", "DuFederal", "DuQuebec", "PayeFederal", "PayeQuebec"}
            t.Columns.Add(c, GetType(Decimal))
        Next
        Dim r = t.NewRow()
        For Each c As DataColumn In t.Columns
            r(c) = 1000D
        Next
        t.Rows.Add(r)
        Return r
    End Function

End Class