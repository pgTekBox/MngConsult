Imports System.Globalization
Imports System.IO
Imports System.Text
Imports PdfSharp.Pdf
Imports PdfSharp.Pdf.Advanced
Imports PdfSharp.Pdf.IO

''' <summary>Les formulaires officiels d'une année, tels que la compagnie les a téléversés (Configuration › Formulaires officiels).</summary>
Public Class FormulairesAnnee
    Public Property Annee As Integer
    ''' <summary>Le T4 à remplir de l'ARC (t4-fill), déchiffré et prêt ; Nothing s'il n'a pas été téléversé.</summary>
    Public Property T4 As Byte()
    ''' <summary>Le Relevé 1 à remplir de Revenu Québec, déchiffré et prêt ; Nothing s'il n'a pas été téléversé.</summary>
    Public Property R1 As Byte()

    Public ReadOnly Property Disponible As Boolean
        Get
            Return T4 IsNot Nothing
        End Get
    End Property
End Class

''' <summary>
''' Les feuillets sur les formulaires officiels : le T4 à remplir de l'ARC (deux feuillets par page)
''' et le Relevé 1 à remplir de Revenu Québec (trois pages : copie 1 pour Revenu Québec, copie 2
''' pour l'employé, copie 3 pour l'employeur). La compagnie téléverse les formulaires de l'année
''' dans Configuration › Formulaires officiels ; dès qu'ils sont là, les feuillets sortent dessus
''' — copie de l'employé, de l'employeur, du gouvernement et pièce jointe des courriels — à la
''' place de la mise en page maison de FeuilletPdf.
'''
''' POURQUOI UNE BIBLIOTHÈQUE ICI : ces formulaires sont chiffrés (AES-128) et leurs champs vivent
''' dans des flux d'objets compressés. Les lire et y écrire à la main n'est pas raisonnable ;
''' PDFsharp (licence MIT, dans lib\) s'en charge. Elle ne sert qu'à cela : le reste des documents
''' de 60secPaie continue d'être écrit par PdfSimple.
'''
''' CE QU'ON FAIT DU FORMULAIRE : au téléversement, on en fait une copie sans chiffrement dont la
''' liste des champs est reconstruite à partir des cases de chaque page ; c'est cette copie qui est
''' conservée. Au moment de produire, on importe les pages voulues autant de fois qu'il y a
''' d'employés, on renomme les champs de chaque copie pour qu'ils restent distincts, on pose les
''' valeurs, et on laisse au lecteur PDF le soin de dessiner le texte dans les cases
''' (NeedAppearances). Les scripts du formulaire (boutons, calculs) sont retirés : ils ne servent
''' qu'à la saisie manuelle et gêneraient un lecteur qui ne les exécute pas.
''' </summary>
Public NotInheritable Class FormulaireOfficiel

    Public Const TypeT4 As String = "T4"
    Public Const TypeR1 As String = "R1"

    ''' <summary>Pages du Relevé 1 : copie 1 Revenu Québec, copie 2 employé, copie 3 employeur.</summary>
    Private Const PageR1Gouvernement As Integer = 0
    Private Const PageR1Employe As Integer = 1
    Private Const PageR1Employeur As Integer = 2

    Private Sub New()
    End Sub

    ' ------------------------------------------------------------------ chargement

    ''' <summary>Les formulaires de la plateforme (console d'administration) sont rangés sous la compagnie 0.</summary>
    Public Const Plateforme As Integer = 0

    ''' <summary>
    ''' Les formulaires de l'année : ceux de la compagnie courante, et à défaut de chacun, ceux de la plateforme
    ''' (téléversés dans la console Sec60Admin pour toutes les compagnies). Disponible = False s'il n'y a pas de T4.
    ''' </summary>
    Public Shared Function Charger(annee As Integer) As FormulairesAnnee
        Dim f As New FormulairesAnnee With {.Annee = annee}
        For Each c In {Contexte.CompagnieId, Plateforme}
            For Each r As DataRow In Db.Table("paie.spFormulaireFeuillet_Annee", Db.P("@c", c), Db.P("@a", annee)).Rows
                Dim contenu = TryCast(r("Contenu"), Byte())
                If contenu Is Nothing OrElse contenu.Length = 0 Then Continue For
                If r.Txt("Type") = TypeT4 AndAlso f.T4 Is Nothing Then f.T4 = contenu
                If r.Txt("Type") = TypeR1 AndAlso f.R1 Is Nothing Then f.R1 = contenu
            Next
        Next
        Return f
    End Function

    ''' <summary>
    ''' Vérifie un formulaire téléversé et en rend la copie prête à servir (sans chiffrement, champs
    ''' reconstruits, scripts retirés). Refuse ce qui n'est pas le formulaire attendu.
    ''' </summary>
    Public Shared Function Preparer(contenu As Byte(), type As String) As Byte()
        Dim doc As PdfDocument
        Try
            doc = PdfReader.Open(New MemoryStream(contenu), PdfDocumentOpenMode.Import)
        Catch ex As Exception
            Throw New SaisieInvalideException("Ce fichier n'est pas un PDF lisible : " & ex.Message)
        End Try
        If Not doc.Internals.Catalog.Elements.ContainsKey("/AcroForm") Then
            Throw New SaisieInvalideException("Ce PDF n'est pas un formulaire à remplir (aucun champ).")
        End If

        Dim copie As New PdfDocument()
        For Each page In doc.Pages
            copie.AddPage(page)
        Next
        Dim da = If(doc.AcroForm.Elements.ContainsKey("/DA"), doc.AcroForm.Elements.GetString("/DA"), "/Helv 0 Tf 0 g")
        ReconstruireFormulaire(copie, da)

        Dim racines = RacinesDuDocument(copie)
        If type = TypeT4 Then
            If Trouver(racines, "form1[0]", "Page1[0]", "Slip1[0]", "Box14[0]", "Slip1Box14[0]") Is Nothing Then
                Throw New SaisieInvalideException("Ce PDF n'est pas le formulaire T4 à remplir de l'ARC (t4-fill) : la case 14 du feuillet 1 est introuvable.")
            End If
        ElseIf type = TypeR1 Then
            If Racine(racines, "caseA") Is Nothing OrElse copie.PageCount < 3 Then
                Throw New SaisieInvalideException("Ce PDF n'est pas le formulaire Relevé 1 à remplir de Revenu Québec : la case A est introuvable.")
            End If
        Else
            Throw New SaisieInvalideException("Type de formulaire inconnu.")
        End If

        Using sortie As New MemoryStream()
            copie.Save(sortie, False)
            Return sortie.ToArray()
        End Using
    End Function

    ' ------------------------------------------------------------------ production

    ''' <summary>Le T4 d'un employé (copie quelconque : le formulaire de l'ARC est le même pour toutes) et, pour un emploi au Québec, la page du Relevé 1 qui convient à la copie.</summary>
    Public Shared Function Produire(f As Feuillet, compagnie As DataRow, annee As Integer, copie As CopieFeuillet, formulaires As FormulairesAnnee) As Byte()
        Dim sortie As New PdfDocument()
        AjouterT4(sortie, formulaires.T4, {f}, compagnie, annee, 1)
        If f.AvecReleve1 AndAlso formulaires.R1 IsNot Nothing Then AjouterR1(sortie, formulaires.R1, {f}, compagnie, PageR1(copie), 1)
        Return Octets(sortie)
    End Function

    ''' <summary>Tous les feuillets de l'année : les T4 deux par page, puis la page du Relevé 1 de chaque employé du Québec.</summary>
    Public Shared Function ProduireTous(feuillets As IList(Of Feuillet), compagnie As DataRow, annee As Integer, copie As CopieFeuillet, formulaires As FormulairesAnnee) As Byte()
        Dim sortie As New PdfDocument()
        AjouterT4(sortie, formulaires.T4, feuillets, compagnie, annee, 1)
        Dim quebec = feuillets.Where(Function(x) x.AvecReleve1).ToList()
        If quebec.Count > 0 AndAlso formulaires.R1 IsNot Nothing Then AjouterR1(sortie, formulaires.R1, quebec, compagnie, PageR1(copie), 1000)
        Return Octets(sortie)
    End Function

    ''' <summary>Ce qui va aux gouvernements : T4 (ARC) puis Sommaire T4, Relevés 1 copie 1 puis Sommaire 1.</summary>
    Public Shared Function ProduireGouvernement(feuillets As IList(Of Feuillet), compagnie As DataRow, annee As Integer, sommaire As DataRow, formulaires As FormulairesAnnee) As Byte()
        Dim sortie As New PdfDocument()
        AjouterT4(sortie, formulaires.T4, feuillets, compagnie, annee, 1)
        AjouterPages(sortie, FeuilletPdf.ProduireSommaireT4(feuillets, compagnie, annee, sommaire))
        Dim quebec = feuillets.Where(Function(x) x.AvecReleve1).ToList()
        If quebec.Count > 0 Then
            If formulaires.R1 IsNot Nothing Then
                AjouterR1(sortie, formulaires.R1, quebec, compagnie, PageR1Gouvernement, 1000)
            Else
                AjouterPages(sortie, FeuilletPdf.ProduireTous(quebec, compagnie, annee, CopieFeuillet.Gouvernement, True))
            End If
            AjouterPages(sortie, FeuilletPdf.ProduireSommaire1(quebec, compagnie, annee, sommaire))
        End If
        Return Octets(sortie)
    End Function

    Private Shared Function PageR1(copie As CopieFeuillet) As Integer
        Select Case copie
            Case CopieFeuillet.Employe : Return PageR1Employe
            Case CopieFeuillet.Employeur : Return PageR1Employeur
            Case Else : Return PageR1Gouvernement
        End Select
    End Function

    Private Shared Function Octets(doc As PdfDocument) As Byte()
        Using m As New MemoryStream()
            doc.Save(m, False)
            Return m.ToArray()
        End Using
    End Function

    ''' <summary>Ajoute à la sortie les pages d'un PDF produit par PdfSimple (sommaires).</summary>
    Private Shared Sub AjouterPages(sortie As PdfDocument, pdf As Byte())
        Dim doc = PdfReader.Open(New MemoryStream(pdf), PdfDocumentOpenMode.Import)
        For Each page In doc.Pages
            sortie.AddPage(page)
        Next
    End Sub

    ' ------------------------------------------------------------------ T4 (ARC)

    ''' <summary>Deux feuillets par page : la page 1 du formulaire est importée autant de fois que nécessaire, ses champs renommés par copie.</summary>
    Private Shared Sub AjouterT4(sortie As PdfDocument, modele As Byte(), feuillets As IList(Of Feuillet), compagnie As DataRow, annee As Integer, depart As Integer)
        If modele Is Nothing Then Throw New SaisieInvalideException("Le formulaire T4 de l'année n'a pas été téléversé.")
        Dim k = depart
        For i = 0 To feuillets.Count - 1 Step 2
            Dim doc = PdfReader.Open(New MemoryStream(modele), PdfDocumentOpenMode.Import)
            Dim page = sortie.AddPage(doc.Pages(0))
            Dim racines = RacinesDeLaPage(page)
            For Each r In racines
                r.Elements.SetString("/T", "t4_" & k.ToString(CultureInfo.InvariantCulture) & "_" & r.Elements.GetString("/T"))
            Next
            Dim formulaire = racines.FirstOrDefault()
            If formulaire Is Nothing Then Throw New SaisieInvalideException("Le formulaire T4 téléversé n'a pas de champs.")
            RemplirT4(formulaire, "Slip1[0]", feuillets(i), compagnie, annee)
            If i + 1 < feuillets.Count Then RemplirT4(formulaire, "Slip2[0]", feuillets(i + 1), compagnie, annee)
            k += 1
        Next
        AssurerFormulaire(sortie)
    End Sub

    Private Shared Sub RemplirT4(formulaire As PdfDictionary, feuillet As String, f As Feuillet, compagnie As DataRow, annee As Integer)
        Dim emp = f.Employe
        Dim slip = Trouver({formulaire}, formulaire.Elements.GetString("/T"), "Page1[0]", feuillet)
        If slip Is Nothing Then Return

        Dim employeur = compagnie.Txt("Nom") & vbLf & compagnie.Txt("Adresse1") & vbLf & Lieu(compagnie.Txt("Ville"), compagnie.Txt("Province"), compagnie.Txt("CodePostal"))
        Texte(slip, "EmployersName[0]", "Slip1EmployersName[0]", Gauche(employeur, 336))
        Texte(slip, "Year[0]", "Slip1Year[0]", annee.ToString(CultureInfo.InvariantCulture))
        Texte(slip, "EmployersAccount[0]", "Slip1Box54[0]", Gauche(compagnie.Txt("NumeroEntrepriseFederal"), 15))
        Texte(slip, "Box12[0]", "Slip1Box12[0]", Gauche(Chiffres(NasDe(emp)), 9))
        Texte(slip, "Box10[0]", "Slip1Box10[0]", If(f.DeuxProvinces, "", f.Province))
        Texte(slip, "Box45[0]", "DropDownList[0]", Math.Max(1, Math.Min(5, emp.Ent("CodeDentaireT4"))).ToString(CultureInfo.InvariantCulture))

        Dim exemptions = Trouver({slip}, slip.Elements.GetString("/T"), "Box28[0]")
        If exemptions IsNot Nothing Then
            Cocher(exemptions, "CPP_CheckBox[0]", "Slip1CPP[0]", emp.Bln("ExemptRRQ"))
            Cocher(exemptions, "EI_CheckBox[0]", "Slip1EI[0]", emp.Bln("ExemptAE"))
            Cocher(exemptions, "PPIP_CheckBox[0]", "Slip1PPIP[0]", emp.Bln("ExemptRQAP") AndAlso f.Province = "QC")
        End If

        For Each c In {"14", "22", "16", "17", "16A", "17A", "24", "26", "18", "44", "20", "46", "55", "56"}
            Texte(slip, "Box" & c & "[0]", "Slip1Box" & c & "[0]", Montant(f.CaseT4(c), c = "14" OrElse c = "22"))
        Next

        Dim employe = Trouver({slip}, slip.Elements.GetString("/T"), "Employee[0]")
        If employe IsNot Nothing Then
            Texte(employe, "LastName[0]", "Slip1LastName[0]", Gauche(emp.Txt("Nom").ToUpperInvariant(), 20))
            Texte(employe, "FirstName[0]", "Slip1FirstName[0]", Gauche(emp.Txt("Prenom"), 12))
            Dim adresse = emp.Txt("Adresse1")
            If emp.Txt("Adresse2").Length > 0 Then adresse &= vbLf & emp.Txt("Adresse2")
            adresse &= vbLf & Lieu(emp.Txt("Ville"), emp.Txt("Province"), emp.Txt("CodePostal"))
            Valeur(Racine(Enfants(employe), "Slip1Address[0]"), adresse)
        End If

        ' Autres renseignements : les cases qui n'ont pas de place fixe sur le feuillet.
        Dim autres = Trouver({slip}, slip.Elements.GetString("/T"), "OtherInformation[0]")
        If autres IsNot Nothing Then
            Dim n = 0
            For Each c In {"34", "40", "42", "85"}
                If f.CaseT4(c) = 0D OrElse n >= 6 Then Continue For
                n += 1
                Texte(autres, "Box" & n.ToString(CultureInfo.InvariantCulture) & "[0]", "Slip1Box" & n.ToString(CultureInfo.InvariantCulture) & "[0]", c)
                Texte(autres, "Amount" & n.ToString(CultureInfo.InvariantCulture) & "[0]", "Slip1Amount" & n.ToString(CultureInfo.InvariantCulture) & "[0]", Montant(f.CaseT4(c), True))
            Next
        End If
    End Sub

    ' ------------------------------------------------------------------ Relevé 1 (Revenu Québec)

    ''' <summary>Une page du formulaire par employé (la copie demandée), champs renommés par employé ; les champs « rep_ » reçoivent la même valeur que l'original.</summary>
    Private Shared Sub AjouterR1(sortie As PdfDocument, modele As Byte(), feuillets As IList(Of Feuillet), compagnie As DataRow, pageVoulue As Integer, depart As Integer)
        Dim k = depart
        For Each f In feuillets
            Dim doc = PdfReader.Open(New MemoryStream(modele), PdfDocumentOpenMode.Import)
            Dim page = sortie.AddPage(doc.Pages(Math.Min(pageVoulue, doc.PageCount - 1)))
            Dim racines = RacinesDeLaPage(page)
            Dim parNom As New Dictionary(Of String, PdfDictionary)(StringComparer.Ordinal)
            For Each r In racines
                Dim nom = r.Elements.GetString("/T")
                parNom(nom) = r
                r.Elements.SetString("/T", "r1_" & k.ToString(CultureInfo.InvariantCulture) & "_" & nom)
            Next
            RemplirR1(parNom, f, compagnie)
            k += 1
        Next
        AssurerFormulaire(sortie)
    End Sub

    Private Shared Sub RemplirR1(champs As Dictionary(Of String, PdfDictionary), f As Feuillet, compagnie As DataRow)
        Dim emp = f.Employe
        Dim poser = Sub(nom As String, texte As String)
                        Dim d As PdfDictionary = Nothing
                        If champs.TryGetValue(nom, d) Then Valeur(d, texte)
                        If champs.TryGetValue("rep_" & nom, d) Then Valeur(d, texte)
                    End Sub

        poser("codeReleve", "1")                                  ' R : relevé original
        poser("nas", Gauche(Chiffres(NasDe(emp)), 9))
        poser("ref", Gauche(emp.Txt("Code"), 18))
        For Each c In {"A", "B.A", "B.B", "C", "D", "E", "F", "G", "H", "I", "J", "L", "M", "N", "W"}
            poser("case" & c.Replace("."c, "-"c), Montant(f.CaseR1(c), c = "A" OrElse c = "E"))
        Next
        If f.CaseR1("235") <> 0D Then
            poser("codeRenseignement1", "235")
            poser("infoRenseignement1", Montant(f.CaseR1("235"), True))
        End If

        poser("nom1", emp.Txt("Nom").ToUpperInvariant())
        poser("prenom1", emp.Txt("Prenom"))
        Dim numero = "", rue = ""
        Adresse(emp.Txt("Adresse1"), numero, rue)
        If emp.Txt("Adresse2").Length > 0 Then rue = (rue & " " & emp.Txt("Adresse2")).Trim()
        poser("app1", "")
        poser("numero1", numero)
        poser("rue1", rue)
        poser("ville1", emp.Txt("Ville"))
        poser("province1", Gauche(emp.Txt("Province").Trim(), 2))
        poser("cp1", Gauche(emp.Txt("CodePostal").Replace(" ", "").ToUpperInvariant(), 6))

        poser("nom2", compagnie.Txt("Nom"))
        poser("prenom2", "")
        Adresse(compagnie.Txt("Adresse1"), numero, rue)
        If compagnie.Txt("Adresse2").Length > 0 Then rue = (rue & " " & compagnie.Txt("Adresse2")).Trim()
        poser("numero2", numero)
        poser("rue2", rue)
        poser("ville2", compagnie.Txt("Ville"))
        poser("province2", Gauche(compagnie.Txt("Province").Trim(), 2))
        poser("cp2", Gauche(compagnie.Txt("CodePostal").Replace(" ", "").ToUpperInvariant(), 6))
        ' Copies 2 et 3 : l'identité de l'employé et celle de l'employeur tiennent dans un seul champ chacune.
        poser("Identifiant1", emp.Txt("Nom").ToUpperInvariant() & ", " & emp.Txt("Prenom") & vbLf & emp.Txt("Adresse1") & If(emp.Txt("Adresse2").Length > 0, vbLf & emp.Txt("Adresse2"), "") & vbLf & Lieu(emp.Txt("Ville"), emp.Txt("Province"), emp.Txt("CodePostal")))
        poser("payeur", compagnie.Txt("Nom") & vbLf & compagnie.Txt("Adresse1") & vbLf & Lieu(compagnie.Txt("Ville"), compagnie.Txt("Province"), compagnie.Txt("CodePostal")))
    End Sub

    ' ------------------------------------------------------------------ la mécanique des champs

    ''' <summary>Un AcroForm neuf pour la copie : les champs racines sont retrouvés par les cases de chaque page, les scripts du formulaire sont retirés.</summary>
    Private Shared Sub ReconstruireFormulaire(copie As PdfDocument, da As String)
        Dim acro As New PdfDictionary(copie)
        copie.Internals.AddObject(acro)
        acro.Elements("/Fields") = New PdfArray(copie)
        acro.Elements.SetString("/DA", da)
        acro.Elements.SetBoolean("/NeedAppearances", True)
        copie.Internals.Catalog.Elements.SetReference("/AcroForm", acro)
        copie.Internals.Catalog.Elements.Remove("/OpenAction")
        copie.Internals.Catalog.Elements.Remove("/AA")
        copie.Internals.Catalog.Elements.Remove("/Names")
        AssurerFormulaire(copie)
    End Sub

    ''' <summary>Met la liste des champs du document en accord avec les cases de ses pages (après des imports), sans scripts.</summary>
    Private Shared Sub AssurerFormulaire(doc As PdfDocument)
        Dim acro As PdfDictionary
        If doc.Internals.Catalog.Elements.ContainsKey("/AcroForm") Then
            acro = doc.Internals.Catalog.Elements.GetDictionary("/AcroForm")
        Else
            acro = New PdfDictionary(doc)
            doc.Internals.AddObject(acro)
            acro.Elements.SetString("/DA", "/Helv 0 Tf 0 g")
            acro.Elements.SetBoolean("/NeedAppearances", True)
            doc.Internals.Catalog.Elements.SetReference("/AcroForm", acro)
        End If
        Dim fields As New PdfArray(doc)
        Dim vus As New HashSet(Of PdfReference)()
        For Each page In doc.Pages
            For Each r In RacinesDeLaPage(page)
                If r.Reference IsNot Nothing AndAlso vus.Add(r.Reference) Then fields.Elements.Add(r.Reference)
            Next
            For i = 0 To page.Annotations.Count - 1
                Dim an = page.Annotations(i)
                an.Elements.Remove("/AA")
                an.Elements.Remove("/A")
                ' Sans /P, l'import d'une page n'entraîne pas les autres pages du formulaire (les cases d'un même champ
                ' se renvoient l'une à l'autre par leur page) : le document produit reste léger.
                an.Elements.Remove("/P")
            Next
            page.Elements.Remove("/AA")
        Next
        acro.Elements("/Fields") = fields
        acro.Elements.SetBoolean("/NeedAppearances", True)
    End Sub

    ''' <summary>Les champs racines dont une case se trouve sur la page, dans l'ordre des cases.</summary>
    Private Shared Function RacinesDeLaPage(page As PdfPage) As List(Of PdfDictionary)
        Dim racines As New List(Of PdfDictionary)()
        Dim vus As New HashSet(Of PdfReference)()
        For i = 0 To page.Annotations.Count - 1
            Dim cur As PdfDictionary = page.Annotations(i)
            While cur.Elements.ContainsKey("/Parent")
                cur = cur.Elements.GetDictionary("/Parent")
            End While
            If cur.Reference Is Nothing OrElse vus.Add(cur.Reference) Then
                For Each r In racines
                    If Object.ReferenceEquals(r, cur) Then cur = Nothing : Exit For
                Next
                If cur IsNot Nothing Then racines.Add(cur)
            End If
        Next
        Return racines
    End Function

    Private Shared Function RacinesDuDocument(doc As PdfDocument) As List(Of PdfDictionary)
        Dim l As New List(Of PdfDictionary)()
        For Each page In doc.Pages
            l.AddRange(RacinesDeLaPage(page))
        Next
        Return l
    End Function

    Private Shared Function Enfants(champ As PdfDictionary) As List(Of PdfDictionary)
        Dim l As New List(Of PdfDictionary)()
        Dim kids = champ.Elements.GetArray("/Kids")
        If kids Is Nothing Then Return l
        For i = 0 To kids.Elements.Count - 1
            Dim d = kids.Elements.GetDictionary(i)
            If d IsNot Nothing Then l.Add(d)
        Next
        Return l
    End Function

    ''' <summary>Le champ nommé parmi ceux-ci, ou Nothing.</summary>
    Private Shared Function Racine(champs As IEnumerable(Of PdfDictionary), nom As String) As PdfDictionary
        For Each c In champs
            If c.Elements.ContainsKey("/T") AndAlso c.Elements.GetString("/T") = nom Then Return c
        Next
        Return Nothing
    End Function

    ''' <summary>Descend l'arbre des champs en suivant les noms (le premier est celui d'une racine).</summary>
    Private Shared Function Trouver(racines As IEnumerable(Of PdfDictionary), ParamArray chemin As String()) As PdfDictionary
        Dim courant = Racine(racines, chemin(0))
        For i = 1 To chemin.Length - 1
            If courant Is Nothing Then Return Nothing
            courant = Racine(Enfants(courant), chemin(i))
        Next
        Return courant
    End Function

    Private Shared Sub Texte(parent As PdfDictionary, groupe As String, champ As String, texte As String)
        Dim g = Racine(Enfants(parent), groupe)
        If g Is Nothing Then Return
        Valeur(Racine(Enfants(g), champ), texte)
    End Sub

    Private Shared Sub Valeur(champ As PdfDictionary, texte As String)
        If champ Is Nothing Then Return
        If String.IsNullOrEmpty(texte) Then
            champ.Elements.Remove("/V")
        Else
            champ.Elements("/V") = New PdfString(texte, PdfStringEncoding.Unicode)
        End If
    End Sub

    Private Shared Sub Cocher(parent As PdfDictionary, groupe As String, champ As String, oui As Boolean)
        Dim g = Racine(Enfants(parent), groupe)
        If g Is Nothing Then Return
        Dim c = Racine(Enfants(g), champ)
        If c Is Nothing Then Return
        Dim etat = If(oui, "/1", "/Off")
        c.Elements.SetName("/V", etat)
        c.Elements.SetName("/AS", etat)
    End Sub

    ' ------------------------------------------------------------------ outils

    Private Shared Function Montant(valeur As Decimal, toujours As Boolean) As String
        If valeur = 0D AndAlso Not toujours Then Return ""
        Return valeur.ToString("0.00", CultureInfo.InvariantCulture)
    End Function

    Private Shared Function Gauche(texte As String, longueur As Integer) As String
        Dim t = If(texte, "")
        Return If(t.Length > longueur, t.Substring(0, longueur), t)
    End Function

    Private Shared Function Chiffres(texte As String) As String
        Dim sb As New StringBuilder()
        For Each c In If(texte, "")
            If Char.IsDigit(c) Then sb.Append(c)
        Next
        Return sb.ToString()
    End Function

    Private Shared Function Lieu(ville As String, province As String, codePostal As String) As String
        Dim s = ville
        If province.Trim().Length > 0 Then s &= " (" & province.Trim() & ")"
        If codePostal.Length > 0 Then s &= "  " & codePostal
        Return s.Trim()
    End Function

    ''' <summary>« 123 rue Principale » → numéro 123, rue « rue Principale » ; sans numéro en tête, tout va dans la rue.</summary>
    Private Shared Sub Adresse(ligne As String, ByRef numero As String, ByRef rue As String)
        numero = "" : rue = If(ligne, "").Trim()
        Dim i = 0
        While i < rue.Length AndAlso (Char.IsDigit(rue(i)) OrElse (i > 0 AndAlso (rue(i) = "-"c OrElse Char.IsLetter(rue(i))) AndAlso i < 8))
            i += 1
        End While
        If i > 0 AndAlso i < rue.Length AndAlso rue(i) = " "c AndAlso Char.IsDigit(rue(0)) Then
            numero = rue.Substring(0, i)
            rue = rue.Substring(i + 1).Trim()
        End If
    End Sub

End Class