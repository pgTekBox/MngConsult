Imports System.IO
Imports PdfSharp.Pdf
Imports PdfSharp.Pdf.Advanced
Imports PdfSharp.Pdf.IO

''' <summary>
''' Prépare un formulaire officiel de fin d'année (T4 à remplir de l'ARC, Relevé 1 à remplir de
''' Revenu Québec) pour 60secPaie : le même traitement que FormulaireOfficiel.Preparer dans l'application
''' de paie, porté ici parce que la console téléverse les formulaires pour toutes les compagnies.
'''
''' Ces PDF sont chiffrés (AES-128) et leurs champs vivent dans des flux d'objets : PDFsharp (MIT, dans
''' 60secPaie\lib) les ouvre en lecture ; on en fait une copie sans chiffrement dont la liste des champs
''' est reconstruite à partir des cases de chaque page, sans les scripts du formulaire. C'est cette copie
''' que 60secPaie remplit.
''' </summary>
Public NotInheritable Class clsFormulairePdf

    Public Const TypeT4 As String = "T4"
    Public Const TypeR1 As String = "R1"

    Private Sub New()
    End Sub

    ''' <summary>Vérifie et prépare le fichier ; ArgumentException si ce n'est pas le formulaire attendu.</summary>
    Public Shared Function Preparer(contenu As Byte(), type As String) As Byte()
        Dim doc As PdfDocument
        Try
            doc = PdfReader.Open(New MemoryStream(contenu), PdfDocumentOpenMode.Import)
        Catch ex As Exception
            Throw New ArgumentException("Ce fichier n'est pas un PDF lisible : " & ex.Message)
        End Try
        If Not doc.Internals.Catalog.Elements.ContainsKey("/AcroForm") Then
            Throw New ArgumentException("Ce PDF n'est pas un formulaire à remplir (aucun champ).")
        End If

        Dim copie As New PdfDocument()
        For Each page In doc.Pages
            copie.AddPage(page)
        Next
        Dim da = If(doc.AcroForm.Elements.ContainsKey("/DA"), doc.AcroForm.Elements.GetString("/DA"), "/Helv 0 Tf 0 g")
        Dim acro As New PdfDictionary(copie)
        copie.Internals.AddObject(acro)
        acro.Elements.SetString("/DA", da)
        copie.Internals.Catalog.Elements.SetReference("/AcroForm", acro)
        copie.Internals.Catalog.Elements.Remove("/OpenAction")
        copie.Internals.Catalog.Elements.Remove("/AA")
        copie.Internals.Catalog.Elements.Remove("/Names")
        AssurerFormulaire(copie)

        Dim racines = RacinesDuDocument(copie)
        If type = TypeT4 Then
            If Trouver(racines, "form1[0]", "Page1[0]", "Slip1[0]", "Box14[0]", "Slip1Box14[0]") Is Nothing Then
                Throw New ArgumentException("Ce PDF n'est pas le formulaire T4 à remplir de l'ARC (t4-fill) : la case 14 du feuillet 1 est introuvable.")
            End If
        ElseIf type = TypeR1 Then
            If Racine(racines, "caseA") Is Nothing OrElse copie.PageCount < 3 Then
                Throw New ArgumentException("Ce PDF n'est pas le formulaire Relevé 1 à remplir de Revenu Québec : la case A est introuvable.")
            End If
        Else
            Throw New ArgumentException("Type de formulaire inconnu.")
        End If

        Using sortie As New MemoryStream()
            copie.Save(sortie, False)
            Return sortie.ToArray()
        End Using
    End Function

    ''' <summary>La liste des champs du document, reconstruite à partir des cases de ses pages, sans scripts ni renvoi de page.</summary>
    Private Shared Sub AssurerFormulaire(doc As PdfDocument)
        Dim acro = doc.Internals.Catalog.Elements.GetDictionary("/AcroForm")
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
                an.Elements.Remove("/P")
            Next
            page.Elements.Remove("/AA")
        Next
        acro.Elements("/Fields") = fields
        acro.Elements.SetBoolean("/NeedAppearances", True)
    End Sub

    Private Shared Function RacinesDeLaPage(page As PdfPage) As List(Of PdfDictionary)
        Dim racines As New List(Of PdfDictionary)()
        For i = 0 To page.Annotations.Count - 1
            Dim cur As PdfDictionary = page.Annotations(i)
            While cur.Elements.ContainsKey("/Parent")
                cur = cur.Elements.GetDictionary("/Parent")
            End While
            Dim deja = False
            For Each r In racines
                If Object.ReferenceEquals(r, cur) Then deja = True : Exit For
            Next
            If Not deja Then racines.Add(cur)
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

    Private Shared Function Racine(champs As IEnumerable(Of PdfDictionary), nom As String) As PdfDictionary
        For Each c In champs
            If c.Elements.ContainsKey("/T") AndAlso c.Elements.GetString("/T") = nom Then Return c
        Next
        Return Nothing
    End Function

    Private Shared Function Trouver(racines As IEnumerable(Of PdfDictionary), ParamArray chemin As String()) As PdfDictionary
        Dim courant = Racine(racines, chemin(0))
        For i = 1 To chemin.Length - 1
            If courant Is Nothing Then Return Nothing
            courant = Racine(Enfants(courant), chemin(i))
        Next
        Return courant
    End Function

End Class