Imports System.Globalization
Imports System.IO
Imports System.Text

''' <summary>
''' Écrit un PDF à la main, sans bibliothèque.
'''
''' POURQUOI PAS UNE BIBLIOTHÈQUE : le seul document que 60secPaie doit produire
''' est un talon de paie — du texte placé dans une grille. Une bibliothèque de
''' rendu apporterait ici une partie native (Skia), une question de licence et
''' une mise à jour de plus à suivre, pour une page qui ne changera pas de forme.
'''
''' CE QUE CE MOTEUR SAIT FAIRE : du texte en Helvetica (normal et gras), des
''' traits, des rectangles pleins, plusieurs pages. Rien d'autre : ni image, ni
''' couleur autre que les gris, ni retour à la ligne automatique. C'est assez
''' pour un talon, et c'est délibérément peu — un moteur qu'on n'étend pas est un
''' moteur qui ne se met pas à mentir.
'''
''' LES POLICES sont les Helvetica « de base » du format PDF : tout lecteur les
''' possède, rien n'est incorporé au fichier. L'encodage WinAnsi couvre le
''' français et l'espagnol (é, à, ô, ñ, í, ¿) ; un caractère hors de cette table
''' devient un point d'interrogation plutôt que de casser le fichier.
'''
''' LES COORDONNÉES sont comptées EN POINTS DEPUIS LE HAUT de la page, parce que
''' c'est ainsi qu'on pense une mise en page. Le PDF, lui, compte depuis le bas :
''' la conversion se fait ici, une seule fois.
''' </summary>
Public NotInheritable Class PdfSimple

    Private ReadOnly largeurPage As Double
    Private ReadOnly hauteurPage As Double
    Private ReadOnly pages As New List(Of StringBuilder)()
    Private courante As StringBuilder

    Public Sub New(Optional largeur As Double = 612D, Optional hauteur As Double = 792D)
        largeurPage = largeur
        hauteurPage = hauteur
        NouvellePage()
    End Sub

    Public ReadOnly Property LargeurPapier As Double
        Get
            Return largeurPage
        End Get
    End Property

    Public ReadOnly Property HauteurPapier As Double
        Get
            Return hauteurPage
        End Get
    End Property

    Public ReadOnly Property NombrePages As Integer
        Get
            Return pages.Count
        End Get
    End Property

    Public Sub NouvellePage()
        courante = New StringBuilder()
        pages.Add(courante)
    End Sub

    ''' <summary>Revenir sur une page déjà écrite, pour y poser un pied de page une fois le nombre de pages connu.</summary>
    Public Sub AllerALaPage(index As Integer)
        courante = pages(index)
    End Sub

    ''' <summary>Texte dont le coin gauche de la ligne de base est à (x, y), y compté depuis le haut.</summary>
    Public Sub Ecrire(x As Double, y As Double, texte As String,
                     Optional gras As Boolean = False, Optional taille As Double = 9D, Optional gris As Double = 0D)
        If String.IsNullOrEmpty(texte) Then Return
        courante.Append(PdfNb(gris)).Append(" g BT /").Append(If(gras, "F2", "F1")).Append(" ").Append(PdfNb(taille))
        courante.Append(" Tf 1 0 0 1 ").Append(PdfNb(x)).Append(" ").Append(PdfNb(hauteurPage - y))
        courante.Append(" Tm (").Append(Echapper(texte)).Append(") Tj ET 0 g").Append(vbLf)
    End Sub

    ''' <summary>Texte aligné à droite : c'est ainsi que se lisent des montants.</summary>
    Public Sub EcrireADroite(xDroite As Double, y As Double, texte As String,
                            Optional gras As Boolean = False, Optional taille As Double = 9D, Optional gris As Double = 0D)
        If String.IsNullOrEmpty(texte) Then Return
        Ecrire(xDroite - LargeurTexte(texte, gras, taille), y, texte, gras, taille, gris)
    End Sub

    Public Sub Trait(x1 As Double, y1 As Double, x2 As Double, y2 As Double,
                     Optional epaisseur As Double = 0.5D, Optional gris As Double = 0.75D)
        courante.Append(PdfNb(gris)).Append(" G ").Append(PdfNb(epaisseur)).Append(" w ")
        courante.Append(PdfNb(x1)).Append(" ").Append(PdfNb(hauteurPage - y1)).Append(" m ")
        courante.Append(PdfNb(x2)).Append(" ").Append(PdfNb(hauteurPage - y2)).Append(" l S").Append(vbLf)
    End Sub

    ''' <summary>Rectangle plein ; y est son bord SUPÉRIEUR.</summary>
    Public Sub Rectangle(x As Double, y As Double, largeur As Double, hauteur As Double, gris As Double)
        courante.Append(PdfNb(gris)).Append(" g ").Append(PdfNb(x)).Append(" ").Append(PdfNb(hauteurPage - y - hauteur)).Append(" ")
        courante.Append(PdfNb(largeur)).Append(" ").Append(PdfNb(hauteur)).Append(" re f 0 g").Append(vbLf)
    End Sub

    ' ------------------------------------------------------------------ mesure

    ' Chasses officielles des polices Helvetica du format PDF, pour les codes 32 à
    ' 126, en millièmes de point. Elles servent à aligner à droite : sans elles,
    ' les montants ne tomberaient pas les uns sous les autres.
    Private Shared ReadOnly LargeursNormal As Integer() = LireTable(
        "278 278 355 556 556 889 667 191 333 333 389 584 278 333 278 278 " &
        "556 556 556 556 556 556 556 556 556 556 278 278 584 584 584 556 " &
        "1015 667 667 722 722 667 611 778 722 278 500 667 556 833 722 778 " &
        "667 778 722 667 611 722 667 944 667 667 611 278 278 278 469 556 " &
        "333 556 556 500 556 556 278 556 556 222 222 500 222 833 556 556 " &
        "556 556 333 500 278 556 500 722 500 500 500 334 260 334 584")

    Private Shared ReadOnly LargeursGras As Integer() = LireTable(
        "278 333 474 556 556 889 722 238 333 333 389 584 278 333 278 278 " &
        "556 556 556 556 556 556 556 556 556 556 333 333 584 584 584 611 " &
        "975 722 722 722 722 667 611 778 722 278 556 722 611 833 722 778 " &
        "667 778 722 667 611 722 667 944 667 667 611 333 278 333 584 556 " &
        "333 556 611 556 611 556 333 611 611 278 278 556 278 889 611 611 " &
        "611 611 389 556 333 611 556 778 556 556 500 389 280 389 584")

    Private Shared Function LireTable(valeurs As String) As Integer()
        Dim morceaux = valeurs.Split(" "c)
        Dim t(morceaux.Length - 1) As Integer
        For i = 0 To morceaux.Length - 1
            t(i) = Integer.Parse(morceaux(i), CultureInfo.InvariantCulture)
        Next
        Return t
    End Function

    Public Shared Function LargeurTexte(texte As String, gras As Boolean, taille As Double) As Double
        If String.IsNullOrEmpty(texte) Then Return 0D
        Dim table = If(gras, LargeursGras, LargeursNormal)
        Dim millieme As Integer = 0
        For Each c In texte
            millieme += LargeurCar(c, table)
        Next
        Return millieme * taille / 1000D
    End Function

    Private Shared Function LargeurCar(c As Char, table As Integer()) As Integer
        Dim code = AscW(c)
        ' Espaces insécables : ils séparent les milliers en français.
        If code = 160 OrElse code = 8239 OrElse code = 8201 Then code = 32
        If code >= 32 AndAlso code <= 126 Then Return table(code - 32)

        ' Une lettre accentuée a la chasse de sa lettre de base : é comme e.
        Dim decompose = c.ToString().Normalize(NormalizationForm.FormD)
        Dim codeBase = AscW(decompose(0))
        If codeBase >= 32 AndAlso codeBase <= 126 Then Return table(codeBase - 32)
        Return 556
    End Function

    ' ------------------------------------------------------------------ sortie

    ''' <summary>Assemble le fichier. Les objets sont numérotés puis repérés par leur position : c'est ce que réclame la table xref.</summary>
    Public Function Terminer(titre As String) As Byte()
        Dim ansi = Encoding.GetEncoding(1252)
        Dim nbPages = pages.Count
        Dim premierePage = 5                    ' 1 catalogue, 2 pages, 3 et 4 polices
        Dim premierContenu = premierePage + nbPages
        Dim objInfo = premierContenu + nbPages
        Dim nbObjets = objInfo

        Using flux As New MemoryStream()
            Dim positions(nbObjets) As Integer  ' positions(n) = position de l'objet n

            Octets(flux, ansi, "%PDF-1.4" & vbLf & "%âãÏÓ" & vbLf)

            positions(1) = CInt(flux.Length)
            Octets(flux, ansi, "1 0 obj" & vbLf & "<</Type/Catalog/Pages 2 0 R>>" & vbLf & "endobj" & vbLf)

            Dim enfants As New StringBuilder()
            For i = 0 To nbPages - 1
                enfants.Append(premierePage + i).Append(" 0 R ")
            Next
            positions(2) = CInt(flux.Length)
            Octets(flux, ansi, "2 0 obj" & vbLf & "<</Type/Pages/Kids[" & enfants.ToString().Trim() & "]/Count " & nbPages.ToString(CultureInfo.InvariantCulture) & ">>" & vbLf & "endobj" & vbLf)

            positions(3) = CInt(flux.Length)
            Octets(flux, ansi, "3 0 obj" & vbLf & "<</Type/Font/Subtype/Type1/BaseFont/Helvetica/Encoding/WinAnsiEncoding>>" & vbLf & "endobj" & vbLf)
            positions(4) = CInt(flux.Length)
            Octets(flux, ansi, "4 0 obj" & vbLf & "<</Type/Font/Subtype/Type1/BaseFont/Helvetica-Bold/Encoding/WinAnsiEncoding>>" & vbLf & "endobj" & vbLf)

            Dim boite = "[0 0 " & PdfNb(largeurPage) & " " & PdfNb(hauteurPage) & "]"
            For i = 0 To nbPages - 1
                positions(premierePage + i) = CInt(flux.Length)
                Octets(flux, ansi, (premierePage + i).ToString(CultureInfo.InvariantCulture) & " 0 obj" & vbLf &
                       "<</Type/Page/Parent 2 0 R/MediaBox" & boite &
                       "/Resources<</Font<</F1 3 0 R/F2 4 0 R>>>>/Contents " & (premierContenu + i).ToString(CultureInfo.InvariantCulture) & " 0 R>>" & vbLf & "endobj" & vbLf)
            Next

            For i = 0 To nbPages - 1
                Dim contenu = ansi.GetBytes(pages(i).ToString())
                positions(premierContenu + i) = CInt(flux.Length)
                Octets(flux, ansi, (premierContenu + i).ToString(CultureInfo.InvariantCulture) & " 0 obj" & vbLf &
                       "<</Length " & contenu.Length.ToString(CultureInfo.InvariantCulture) & ">>" & vbLf & "stream" & vbLf)
                flux.Write(contenu, 0, contenu.Length)
                Octets(flux, ansi, vbLf & "endstream" & vbLf & "endobj" & vbLf)
            Next

            positions(objInfo) = CInt(flux.Length)
            Octets(flux, ansi, objInfo.ToString(CultureInfo.InvariantCulture) & " 0 obj" & vbLf &
                   "<</Producer(60secPaie)/Title" & HexUtf16(titre) & "/CreationDate(D:" & Date.Now.ToString("yyyyMMddHHmmss", CultureInfo.InvariantCulture) & ")>>" & vbLf & "endobj" & vbLf)

            Dim depart = CInt(flux.Length)
            Dim x As New StringBuilder()
            x.Append("xref").Append(vbLf).Append("0 ").Append(nbObjets + 1).Append(vbLf)
            x.Append("0000000000 65535 f ").Append(vbLf)
            For n = 1 To nbObjets
                x.Append(positions(n).ToString("0000000000", CultureInfo.InvariantCulture)).Append(" 00000 n ").Append(vbLf)
            Next
            x.Append("trailer").Append(vbLf).Append("<</Size ").Append(nbObjets + 1).Append("/Root 1 0 R/Info ").Append(objInfo).Append(" 0 R>>").Append(vbLf)
            x.Append("startxref").Append(vbLf).Append(depart).Append(vbLf).Append("%%EOF").Append(vbLf)
            Octets(flux, ansi, x.ToString())

            Return flux.ToArray()
        End Using
    End Function

    Private Shared Sub Octets(flux As MemoryStream, ansi As Encoding, texte As String)
        Dim octets = ansi.GetBytes(texte)
        flux.Write(octets, 0, octets.Length)
    End Sub

    ''' <summary>Le titre peut porter des accents : le format veut alors de l'UTF-16 en hexadécimal.</summary>
    Private Shared Function HexUtf16(texte As String) As String
        Dim sb As New StringBuilder("<FEFF")
        For Each c In If(texte, "")
            sb.Append(AscW(c).ToString("X4", CultureInfo.InvariantCulture))
        Next
        Return sb.Append(">").ToString()
    End Function

    ''' <summary>Les nombres du PDF s'écrivent toujours avec un point : la culture de l'utilisateur n'a pas son mot à dire.</summary>
    Private Shared Function PdfNb(v As Double) As String
        Return v.ToString("0.###", CultureInfo.InvariantCulture)
    End Function

    ''' <summary>Dans une chaîne PDF, la parenthèse et la barre oblique inverse doivent être annoncées.</summary>
    Private Shared Function Echapper(texte As String) As String
        Dim sb As New StringBuilder(texte.Length + 8)
        For Each c In texte
            Select Case c
                Case "\"c
                    sb.Append("\\")
                Case "("c
                    sb.Append("\(")
                Case ")"c
                    sb.Append("\)")
                Case ChrW(13), ChrW(10)
                    sb.Append(" "c)
                Case Else
                    sb.Append(c)
            End Select
        Next
        Return sb.ToString()
    End Function

End Class
