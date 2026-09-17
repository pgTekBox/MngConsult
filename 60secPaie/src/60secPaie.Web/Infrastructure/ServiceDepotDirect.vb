Imports System.Globalization
Imports System.Text

''' <summary>
''' Fichier de dépôt direct au format de la norme 005 de Paiements Canada (enregistrements logiques de 1 464 caractères),
''' accepté par la plupart des institutions financières canadiennes pour les transferts automatisés de fonds.
''' Les paramètres (numéro d'émetteur, centre de traitement...) sont fournis par l'institution lors de l'adhésion au service.
''' À VALIDER avec un fichier d'essai auprès de l'institution avant le premier dépôt réel.
''' </summary>
Public NotInheritable Class ServiceDepotDirect

    Private Const LongueurEnregistrement As Integer = 1464
    Private Const LongueurSegment As Integer = 240
    Private Const SegmentsParEnregistrement As Integer = 6
    Private Const TypeTransactionPaie As String = "200"   ' dépôt de paie

    Private Sub New()
    End Sub

    Public Class Resultat
        Public Property NomFichier As String
        Public Property Contenu As Byte()
        Public Property NbDepots As Integer
        Public Property Total As Decimal
    End Class

    ''' <summary>Vérifie ce qui manque pour produire le fichier du lot ; liste vide si tout est prêt.</summary>
    Public Shared Function Problemes(lotId As Integer) As List(Of String)
        Dim p As New List(Of String)()
        Dim c = Db.Ligne("SELECT * FROM paie.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId))
        If c.Txt("DDNumeroEmetteur").Length = 0 OrElse c.Txt("DDCentreTraitement").Length <> 5 OrElse c.Txt("DDNomCourt").Length = 0 OrElse
           c.Txt("DDInstitution").Length <> 3 OrElse c.Txt("DDTransit").Length <> 5 OrElse c.Txt("DDCompteChiffre").Length = 0 Then
            p.Add("Les paramètres de dépôt direct de la compagnie sont incomplets (Configuration → Dépôt direct).")
        End If
        For Each e As DataRow In Depots(lotId).Rows
            If e.Txt("Institution").Length <> 3 OrElse e.Txt("Transit").Length <> 5 OrElse Secret.Reveler(e.Txt("CompteChiffre")).Length = 0 Then
                p.Add("Coordonnées bancaires incomplètes pour " & e.Txt("Prenom") & " " & e.Txt("Nom") & ".")
            End If
        Next
        Return p
    End Function

    ''' <summary>Paies du lot à verser par dépôt direct.</summary>
    Public Shared Function Depots(lotId As Integer) As DataTable
        Return Db.Table(
            "SELECT p.Id AS PaieId, p.Net, e.Id AS EmployeId, e.Code, e.Prenom, e.Nom, e.Institution, e.Transit, e.CompteChiffre " &
            "FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId JOIN paie.Employe e ON e.Id = p.EmployeId " &
            "WHERE l.Id = @l AND l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND e.DepotDirect = 1 AND p.Net > 0 ORDER BY e.Nom, e.Prenom",
            Db.P("@l", lotId), Db.P("@c", Contexte.CompagnieId))
    End Function

    Public Shared Function Generer(lotId As Integer) As Resultat
        Dim lot = Db.Ligne("SELECT * FROM paie.LotPaie WHERE Id = @l AND CompagnieId = @c AND Statut = 'C'", Db.P("@l", lotId), Db.P("@c", Contexte.CompagnieId))
        If lot Is Nothing Then Throw New SaisieInvalideException("Le fichier de dépôt direct se produit à partir d'une paie confirmée.")
        Dim depots = ServiceDepotDirect.Depots(lotId)
        If depots.Rows.Count = 0 Then Throw New SaisieInvalideException("Aucun employé de cette paie n'est payé par dépôt direct.")
        Dim manques = Problemes(lotId)
        If manques.Count > 0 Then Throw New SaisieInvalideException(String.Join(" ", manques))

        Dim c = Db.Ligne("SELECT * FROM paie.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId))
        Dim emetteur = Gauche(c.Txt("DDNumeroEmetteur"), 10)
        Dim numeroFichier = c.Ent("DDProchainNumeroFichier")
        If numeroFichier < 1 OrElse numeroFichier > 9999 Then numeroFichier = 1
        Dim controle = emetteur & numeroFichier.ToString("0000")
        Dim datePaie = lot.DtN("DatePaie").Value
        Dim retourInstitution = "0" & c.Txt("DDInstitution") & c.Txt("DDTransit")
        Dim retourCompte = Gauche(Secret.Reveler(c.Txt("DDCompteChiffre")), 12)

        Dim sb As New StringBuilder()
        Dim compteur = 1

        ' --- Enregistrement A : en-tête
        sb.Append(Completer("A" & compteur.ToString("000000000") & controle & Julien(Date.Today) & c.Txt("DDCentreTraitement") & New String(" "c, 20) & "CAD")).Append(vbCrLf)

        ' --- Enregistrements C : crédits, six segments par enregistrement
        Dim total As Decimal = 0D
        Dim segments As New List(Of String)()
        Dim sequence = 0
        For Each d As DataRow In depots.Rows
            sequence += 1
            total += d.Dcm("Net")
            Dim s As New StringBuilder()
            s.Append(TypeTransactionPaie)
            s.Append(CLng(d.Dcm("Net") * 100D).ToString("0000000000"))
            s.Append(Julien(datePaie))
            s.Append("0").Append(d.Txt("Institution")).Append(d.Txt("Transit"))
            s.Append(Gauche(Secret.Reveler(d.Txt("CompteChiffre")), 12))
            s.Append(retourInstitution).Append(numeroFichier.ToString("0000")).Append(sequence.ToString("000000000"))   ' numéro de repérage (22)
            s.Append("000")                                                     ' type de transaction stocké
            s.Append(Gauche(c.Txt("DDNomCourt"), 15))
            s.Append(Gauche(d.Txt("Nom") & " " & d.Txt("Prenom"), 30))
            s.Append(Gauche(If(c.Txt("DDNomLong").Length > 0, c.Txt("DDNomLong"), c.Txt("Nom")), 30))
            s.Append(emetteur)
            s.Append(Gauche(If(d.Txt("Code").Length > 0, d.Txt("Code"), "EMP" & d.Ent("EmployeId").ToString()), 19))   ' référence de l'émetteur
            s.Append(retourInstitution)
            s.Append(retourCompte)
            s.Append(Gauche("PAIE " & TexteDate(datePaie), 15))
            s.Append(New String(" "c, 22))
            s.Append(New String(" "c, 2))
            s.Append(New String("0"c, 11))
            If s.Length <> LongueurSegment Then Throw New InvalidOperationException("Segment de dépôt direct de longueur invalide : " & s.Length.ToString())
            segments.Add(s.ToString())
        Next

        For i = 0 To segments.Count - 1 Step SegmentsParEnregistrement
            compteur += 1
            Dim groupe = String.Concat(segments.Skip(i).Take(SegmentsParEnregistrement))
            sb.Append(Completer("C" & compteur.ToString("000000000") & controle & groupe)).Append(vbCrLf)
        Next

        ' --- Enregistrement Z : totaux de contrôle
        compteur += 1
        sb.Append(Completer("Z" & compteur.ToString("000000000") & controle &
                            New String("0"c, 14) & New String("0"c, 8) &
                            CLng(total * 100D).ToString("00000000000000") & segments.Count.ToString("00000000") &
                            New String("0"c, 14) & New String("0"c, 8) & New String("0"c, 14) & New String("0"c, 8))).Append(vbCrLf)

        Dim suivant = If(numeroFichier >= 9999, 1, numeroFichier + 1)
        Db.Exec("UPDATE paie.Compagnie SET DDProchainNumeroFichier = @n WHERE Id = @c; " &
                "UPDATE paie.LotPaie SET DepotDirectNumeroFichier = @f, DepotDirectGenereLe = sysdatetime() WHERE Id = @l",
                Db.P("@n", suivant), Db.P("@c", Contexte.CompagnieId), Db.P("@f", numeroFichier), Db.P("@l", lotId))
        Contexte.Journaliser("Fichier de dépôt direct n° " & numeroFichier.ToString("0000") & " produit : " & segments.Count.ToString() & " dépôt(s), " & Argent(total) & ".",
                             "~/Paie/Detail.aspx?lot=" & lotId.ToString())

        Return New Resultat With {
            .NomFichier = "depot-direct-" & TexteDate(datePaie) & "-" & numeroFichier.ToString("0000") & ".txt",
            .Contenu = Encoding.ASCII.GetBytes(sb.ToString()), .NbDepots = segments.Count, .Total = total}
    End Function

    ''' <summary>Date au format 0AAJJJ (année sur 2 chiffres et quantième).</summary>
    Public Shared Function Julien(d As Date) As String
        Return "0" & d.ToString("yy", CultureInfo.InvariantCulture) & d.DayOfYear.ToString("000")
    End Function

    Private Shared Function Completer(enregistrement As String) As String
        If enregistrement.Length > LongueurEnregistrement Then Throw New InvalidOperationException("Enregistrement de dépôt direct trop long.")
        Return enregistrement.PadRight(LongueurEnregistrement)
    End Function

    ''' <summary>Texte en majuscules sans accents, cadré à gauche sur la longueur demandée.</summary>
    Public Shared Function Gauche(texte As String, longueur As Integer) As String
        Dim sb As New StringBuilder()
        For Each ch In If(texte, "").Normalize(NormalizationForm.FormD)
            If CharUnicodeInfo.GetUnicodeCategory(ch) = UnicodeCategory.NonSpacingMark Then Continue For
            Dim u = Char.ToUpperInvariant(ch)
            sb.Append(If(AscW(u) >= 32 AndAlso AscW(u) < 127, u, " "c))
        Next
        Dim s = sb.ToString()
        Return If(s.Length > longueur, s.Substring(0, longueur), s.PadRight(longueur))
    End Function

End Class
