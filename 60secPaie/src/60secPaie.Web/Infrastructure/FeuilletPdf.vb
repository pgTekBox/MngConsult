Imports System.Text
Imports Paie60Sec.Calcul

''' <summary>À qui le feuillet est destiné : le texte de l'entête le dit, rien d'autre ne change.</summary>
Public Enum CopieFeuillet
    Employe
    Employeur
End Enum

''' <summary>
''' Les feuillets de fin d'année d'un employé en PDF : le T4 et, pour un emploi au
''' Québec, le Relevé 1 — une page chacun.
'''
''' Il lit le même <see cref="Feuillet"/> que l'écran Rapports › Feuillet d'un
''' employé : mêmes cases, mêmes montants. Le document reproduit les montants que
''' 60secPaie a calculés ; les feuillets officiels, eux, se saisissent dans les
''' services en ligne de l'ARC et de Revenu Québec, et le PDF le rappelle en pied
''' de page. Il sert à l'employé (sa copie, jointe au courriel) et à l'employeur
''' (sa copie, à classer avec les sommaires).
'''
''' Le NAS y figure en entier : un feuillet sans NAS ne sert à rien à celui qui
''' le reçoit. C'est pourquoi la copie de l'employeur se télécharge sur demande,
''' et que ce téléchargement est inscrit au journal.
'''
''' Les libellés passent par Tr() : appelé dans I18n.DansLaLangue, le document
''' sort dans la langue de l'employé.
''' </summary>
Public NotInheritable Class FeuilletPdf

    Private Const Gauche As Double = 54D
    Private Const Droite As Double = 558D
    Private Const HautPage As Double = 62D
    Private Const ColCase As Double = Gauche
    Private Const ColLibelle As Double = 110D
    Private Const ColMontant As Double = Droite

    Private Sub New()
    End Sub

    Public Shared Function Produire(f As Feuillet, compagnie As DataRow, annee As Integer, copie As CopieFeuillet) As Byte()
        Dim p As New PdfSimple()
        Dessiner(p, f, compagnie, annee, copie, True)
        Return p.Terminer(TitreDocument(f, annee))
    End Function

    ''' <summary>Tous les feuillets de l'année dans un seul document, un employé après l'autre.</summary>
    Public Shared Function ProduireTous(feuillets As IEnumerable(Of Feuillet), compagnie As DataRow, annee As Integer, copie As CopieFeuillet) As Byte()
        Dim p As New PdfSimple()
        Dim premier = True
        For Each f In feuillets
            Dessiner(p, f, compagnie, annee, copie, premier)
            premier = False
        Next
        Return p.Terminer(Tr("Feuillets {#0}", annee))
    End Function

    ''' <summary>« Feuillets-2026-Tremblay-Alice.pdf » ; sans employé, « Feuillets-2026-employeur.pdf ».</summary>
    Public Shared Function NomFichier(annee As Integer, Optional f As Feuillet = Nothing) As String
        Dim base = Tr("Feuillets") & "-" & annee.ToString()
        If f Is Nothing Then
            base &= "-" & Tr("employeur")
        Else
            base &= "-" & f.Employe.Txt("Nom") & "-" & f.Employe.Txt("Prenom")
        End If
        Dim sb As New StringBuilder()
        For Each c In base.Normalize(NormalizationForm.FormD)
            If Globalization.CharUnicodeInfo.GetUnicodeCategory(c) = Globalization.UnicodeCategory.NonSpacingMark Then Continue For
            If Char.IsLetterOrDigit(c) OrElse c = "-"c Then sb.Append(c) Else If c = " "c Then sb.Append("-"c)
        Next
        Return sb.ToString() & ".pdf"
    End Function

    Private Shared Function TitreDocument(f As Feuillet, annee As Integer) As String
        Return If(f.AvecReleve1, Tr("Feuillets T4 et Relevé 1 de {#0}", annee), Tr("Feuillet T4 de {#0}", annee))
    End Function

    ' ------------------------------------------------------------------ les pages

    Private Shared Sub Dessiner(p As PdfSimple, f As Feuillet, compagnie As DataRow, annee As Integer, copie As CopieFeuillet, premierePage As Boolean)
        If Not premierePage Then p.NouvellePage()
        Dim emp = f.Employe

        ' ---------- T4 ----------
        Dim y = Entete(p, f, compagnie, annee, copie, Tr("T4 - État de la rémunération payée"),
                       Tr("N° de compte RP : {0}", compagnie.Txt("NumeroEntrepriseFederal")))
        y = EnteteTableau(p, y)
        y = Texte(p, y, "10", Tr("Province d'emploi"), If(f.DeuxProvinces, String.Join(", ", f.ProvincesEmploi), f.Province))
        For Each c In ServiceFeuillets.LibellesT4
            y = Montant(p, y, c.Key, Tr(c.Value), f.CaseT4(c.Key), c.Key = "14" OrElse c.Key = "22")
        Next
        y = Texte(p, y, "28", Tr("Exemptions"), Tr(ServiceFeuillets.Exemptions(emp, f.Province)))
        Dim dentaire = Math.Max(1, Math.Min(5, emp.Ent("CodeDentaireT4")))
        y = Texte(p, y, "45", Tr("Soins dentaires offerts par l'employeur"), Tr(ServiceFeuillets.CodesDentaires(dentaire)))
        y += 10D
        If f.ContientCumulatifsDepart Then y = Note(p, y, Tr("Ces montants incluent des cumulatifs de départ saisis à la main : les gains assurables ont été estimés à partir de la rémunération brute."))
        If f.DeuxProvinces Then y = Note(p, y, Tr("Payé dans plus d'une province ({0}) : l'ARC demande un T4 par province d'emploi, les montants ci-dessus les réunissent.", String.Join(", ", f.ProvincesEmploi)))
        If Not f.AvecReleve1 Then
            y = Note(p, y, Tr("Emploi hors Québec : aucun relevé provincial. La case 22 du T4 réunit l'impôt fédéral et l'impôt de la province ou du territoire."))
            If f.ProvincesEmploi.Any(Function(code) Provinces.EstGeree(code) AndAlso LibellesProvince.Pour(code).ARetenueTerritoriale) Then
                y = Note(p, y, Tr("L'impôt sur la paie du territoire n'est pas compris dans la case 22 : il se déclare et se remet au gouvernement du territoire."))
            End If
        End If
        Pied(p, Tr("Montants calculés par 60secPaie à partir des paies confirmées. Ce document ne remplace pas le feuillet transmis à l'ARC."))

        ' ---------- Relevé 1 ----------
        If Not f.AvecReleve1 Then Return
        p.NouvellePage()
        y = Entete(p, f, compagnie, annee, copie, Tr("Relevé 1 - Revenus d'emploi et revenus divers"),
                   Tr("N° d'identification RS : {0}", compagnie.Txt("NumeroIdentificationRQ")))
        y = EnteteTableau(p, y)
        For Each c In ServiceFeuillets.LibellesR1
            y = Montant(p, y, c.Key, Tr(c.Value), f.CaseR1(c.Key), c.Key = "A" OrElse c.Key = "E")
        Next
        y += 10D
        y = Note(p, y, Tr("Les cases J, L, M et W sont déjà comprises dans la case A."))
        Pied(p, Tr("Montants calculés par 60secPaie à partir des paies confirmées. Ce document ne remplace pas le relevé transmis à Revenu Québec."))
    End Sub

    ''' <summary>L'employeur à gauche, le feuillet et l'année à droite, puis l'employé avec son NAS.</summary>
    Private Shared Function Entete(p As PdfSimple, f As Feuillet, compagnie As DataRow, annee As Integer, copie As CopieFeuillet,
                                   titre As String, numero As String) As Double
        Dim y As Double = HautPage
        p.Ecrire(Gauche, y, compagnie.Txt("Nom"), True, 13D)
        p.EcrireADroite(Droite, y, titre, True, 12D)
        y += 16D
        p.Ecrire(Gauche, y, compagnie.Txt("Adresse1"), False, 9D, 0.35D)
        p.EcrireADroite(Droite, y, Tr("Année d'imposition {#0}", annee), False, 10D)
        y += 12D
        p.Ecrire(Gauche, y, Lieu(compagnie.Txt("Ville"), compagnie.Txt("Province"), compagnie.Txt("CodePostal")), False, 9D, 0.35D)
        p.EcrireADroite(Droite, y, If(copie = CopieFeuillet.Employe, Tr("Copie de l'employé"), Tr("Copie de l'employeur")), True, 9D)
        y += 12D
        p.Ecrire(Gauche, y, numero, False, 9D, 0.35D)
        y += 10D
        p.Trait(Gauche, y, Droite, y, 1D, 0.15D)
        y += 20D

        Dim emp = f.Employe
        Dim nom = emp.Txt("Prenom") & " " & emp.Txt("Nom")
        If emp.Txt("Code").Length > 0 Then nom &= " (" & emp.Txt("Code") & ")"
        p.Ecrire(Gauche, y, nom, True, 10.5D)
        Dim nas = NasDe(emp)
        p.EcrireADroite(Droite, y, If(nas.Length = 0, Tr("NAS manquant dans la fiche"), Tr("NAS : {0}", nas)), True, 9D)
        y += 13D
        For Each ligne In {emp.Txt("Adresse1"), emp.Txt("Adresse2"), Lieu(emp.Txt("Ville"), emp.Txt("Province"), emp.Txt("CodePostal"))}
            If ligne.Length > 0 Then
                p.Ecrire(Gauche, y, ligne, False, 9D, 0.35D)
                y += 11D
            End If
        Next
        Return y + 14D
    End Function

    Private Shared Function Lieu(ville As String, province As String, codePostal As String) As String
        Dim s = ville
        If province.Trim().Length > 0 Then s &= " (" & province.Trim() & ")"
        If codePostal.Length > 0 Then s &= "  " & codePostal
        Return s.Trim()
    End Function

    Private Shared Function EnteteTableau(p As PdfSimple, y As Double) As Double
        p.Rectangle(Gauche, y - 10D, Droite - Gauche, 15D, 0.92D)
        p.Ecrire(ColCase + 4D, y, Tr("Case"), True, 9D)
        p.Ecrire(ColLibelle, y, Tr("Libellé"), True, 9D)
        p.EcrireADroite(ColMontant, y, Tr("Montant"), True, 9D)
        Return y + 16D
    End Function

    Private Shared Function Montant(p As PdfSimple, y As Double, code As String, libelle As String, valeur As Decimal, toujours As Boolean) As Double
        If valeur = 0D AndAlso Not toujours Then Return y
        p.Ecrire(ColCase + 4D, y, code, True, 9D)
        p.Ecrire(ColLibelle, y, libelle, False, 9D)
        p.EcrireADroite(ColMontant, y, Argent(valeur), False, 9D)
        p.Trait(Gauche, y + 4D, Droite, y + 4D, 0.3D, 0.85D)
        Return y + 13D
    End Function

    Private Shared Function Texte(p As PdfSimple, y As Double, code As String, libelle As String, valeur As String) As Double
        p.Ecrire(ColCase + 4D, y, code, True, 9D)
        p.Ecrire(ColLibelle, y, libelle, False, 9D)
        p.EcrireADroite(ColMontant, y, valeur, False, 9D)
        p.Trait(Gauche, y + 4D, Droite, y + 4D, 0.3D, 0.85D)
        Return y + 13D
    End Function

    ''' <summary>Une remarque sous le tableau ; une phrase trop longue pour la page est coupée aux mots.</summary>
    Private Shared Function Note(p As PdfSimple, y As Double, texte As String) As Double
        For Each ligne In Couper(texte, Droite - Gauche, 8.5D)
            p.Ecrire(Gauche, y, ligne, False, 8.5D, 0.35D)
            y += 11D
        Next
        Return y + 4D
    End Function

    Private Shared Function Couper(texte As String, largeur As Double, taille As Double) As List(Of String)
        Dim lignes As New List(Of String)()
        Dim courante As New StringBuilder()
        For Each mot In texte.Split(" "c)
            Dim essai = If(courante.Length = 0, mot, courante.ToString() & " " & mot)
            If PdfSimple.LargeurTexte(essai, False, taille) > largeur AndAlso courante.Length > 0 Then
                lignes.Add(courante.ToString())
                courante.Clear().Append(mot)
            Else
                courante.Clear().Append(essai)
            End If
        Next
        If courante.Length > 0 Then lignes.Add(courante.ToString())
        Return lignes
    End Function

    Private Shared Sub Pied(p As PdfSimple, texte As String)
        p.Trait(Gauche, 762D, Droite, 762D, 0.5D, 0.85D)
        p.Ecrire(Gauche, 774D, texte, False, 7.5D, 0.45D)
        p.EcrireADroite(Droite, 774D, "60secPaie", False, 8D, 0.6D)
    End Sub

End Class