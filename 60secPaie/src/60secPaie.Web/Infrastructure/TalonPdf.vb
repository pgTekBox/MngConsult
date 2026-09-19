''' <summary>
''' Le talon de paie en PDF, pour la pièce jointe du courriel.
'''
''' Il lit le même <see cref="DonneesTalon"/> que le rendu HTML : mêmes chiffres,
''' mêmes lignes, même ordre. Seule la mise en page diffère, parce qu'une page de
''' papier n'est pas un écran.
'''
''' Les libellés passent par Tr() : appelé dans I18n.DansLaLangue, le document
''' sort dans la langue de l'employé, montants et dates compris.
''' </summary>
Public NotInheritable Class TalonPdf

    Private Const Gauche As Double = 54D
    Private Const Droite As Double = 558D
    Private Const HautPage As Double = 62D
    Private Const BasPage As Double = 735D

    ' Colonnes des tableaux, repérées par leur bord DROIT : les montants s'alignent à droite.
    Private Const ColHeures As Double = 348D
    Private Const ColTaux As Double = 450D
    Private Const ColMontant As Double = Droite

    Private Sub New()
    End Sub

    Public Shared Function Produire(paieId As Integer) As Byte()
        Dim d = RenduPaie.Lire(paieId)
        If Not d.Trouve Then Return Nothing
        Return Produire(d)
    End Function

    Public Shared Function Produire(d As DonneesTalon) As Byte()
        Dim p As New PdfSimple()
        Dim y As Double = HautPage

        ' ---------- Entête : l'employeur à gauche, la paie à droite ----------
        p.Ecrire(Gauche, y, d.CompagnieNom, True, 13D)
        p.EcrireADroite(Droite, y, Tr("Talon de paie"), True, 13D)
        y += 16D
        p.Ecrire(Gauche, y, d.CompagnieAdresse, False, 9D, 0.35D)
        p.EcrireADroite(Droite, y, Tr("Période : {#0} au {#1}", TexteDate(d.DateDebut), TexteDate(d.DateFin)), False, 9D)
        y += 12D
        p.Ecrire(Gauche, y, d.CompagnieLieu, False, 9D, 0.35D)
        p.EcrireADroite(Droite, y, Tr("Date de paie : {#0}", TexteDate(d.DatePaie)), False, 9D)
        y += 12D
        Dim mode = ModePaiement(d)
        If mode.Length > 0 Then
            p.EcrireADroite(Droite, y, mode, False, 9D)
            y += 12D
        End If

        y += 6D
        p.Trait(Gauche, y, Droite, y, 1D, 0.15D)
        y += 20D

        ' Une paie non confirmée peut encore changer : le document doit le dire,
        ' sinon il circule comme s'il était définitif.
        If d.Statut = "B" Then y = Bandeau(p, y, Tr("Aperçu : cette paie n'est pas encore confirmée."))
        If d.Statut = "A" Then y = Bandeau(p, y, Tr("Cette paie a été annulée."))

        ' ---------- L'employé ----------
        Dim nom = d.EmployeNom
        If d.EmployeCode.Length > 0 Then nom &= " (" & d.EmployeCode & ")"
        p.Ecrire(Gauche, y, nom, True, 10.5D)
        y += 13D
        For Each ligne In {d.EmployeAdresse1, d.EmployeAdresse2, d.EmployeLieu}
            If ligne.Length > 0 Then
                p.Ecrire(Gauche, y, ligne, False, 9D, 0.35D)
                y += 11D
            End If
        Next
        y += 14D

        ' ---------- Revenus et avantages ----------
        y = EnteteTableau(p, y, Tr("Revenus et avantages"),
                          New String() {Tr("Heures"), Tr("Taux"), Tr("Montant")},
                          New Double() {ColHeures, ColTaux, ColMontant})
        For Each l In d.Revenus
            y = Sauter(p, y)
            p.Ecrire(Gauche, y, l.Description, False, 9D)
            If l.Heures > 0D Then p.EcrireADroite(ColHeures, y, Nombre(l.Heures), False, 9D)
            If l.Taux > 0D Then p.EcrireADroite(ColTaux, y, Argent(l.Taux), False, 9D)
            p.EcrireADroite(ColMontant, y, Argent(l.Montant), False, 9D)
            y += 13D
        Next
        y = Sauter(p, y)
        p.Trait(Gauche, y - 9D, Droite, y - 9D, 0.5D, 0.75D)
        p.Ecrire(Gauche, y, Tr("Paie brute"), True, 9D)
        p.EcrireADroite(ColHeures, y, Nombre(d.Heures), True, 9D)
        p.EcrireADroite(ColMontant, y, Argent(d.BrutVerse), True, 9D)
        y += 13D
        If d.AvantagesNonMonetaires > 0D Then
            p.Ecrire(Gauche, y, Tr("dont avantages imposables non versés en argent"), False, 8D, 0.4D)
            p.EcrireADroite(ColMontant, y, Argent(d.AvantagesNonMonetaires), False, 8D, 0.4D)
            y += 12D
        End If
        y += 12D

        ' ---------- Retenues et déductions ----------
        y = EnteteTableau(p, y, Tr("Retenues et déductions"),
                          New String() {Tr("Courant"), Tr("Cumulatif")},
                          New Double() {ColTaux, ColMontant})
        For Each r In d.Retenues
            y = Sauter(p, y)
            p.Ecrire(Gauche, y, Tr(r.Libelle), False, 9D)
            p.EcrireADroite(ColTaux, y, Argent(r.Courant), False, 9D)
            If r.AvecCumulatif Then p.EcrireADroite(ColMontant, y, Argent(r.Cumulatif), False, 9D)
            y += 13D
        Next
        y = Sauter(p, y)
        p.Trait(Gauche, y - 9D, Droite, y - 9D, 0.5D, 0.75D)
        p.Ecrire(Gauche, y, Tr("Total"), True, 9D)
        p.EcrireADroite(ColTaux, y, Argent(d.TotalRetenues), True, 9D)
        y += 20D

        ' ---------- Ce que l'employé reçoit ----------
        y = Sauter(p, y, 30D)
        p.Rectangle(Gauche, y - 12D, Droite - Gauche, 24D, 0.93D)
        p.Ecrire(Gauche + 10D, y + 2D, Tr("Paie nette"), True, 12D)
        p.EcrireADroite(Droite - 10D, y + 2D, Argent(d.Net), True, 12D)
        y += 34D

        ' ---------- Depuis le début de l'année ----------
        y = Sauter(p, y, 40D)
        ' Ces quatre bords sont écartés pour les entêtes, pas pour les montants :
        ' « Vacaciones acumuladas (4 %) » mesure près de deux fois « Brut », et
        ' deux entêtes qui se chevauchent rendent le tableau illisible.
        Dim colonnes = New Double() {240D, 318D, 456D, ColMontant}
        y = EnteteTableau(p, y, Tr("Cumulatifs de l'année"),
                          New String() {Tr("Brut"), Tr("Net"),
                                        Tr("Vacances accumulées ({#0} %)", Nombre(d.TauxVacances)), Tr("Solde de vacances")},
                          colonnes, 8D)
        y = Sauter(p, y)
        p.EcrireADroite(colonnes(0), y, Argent(d.CumulBrut), False, 9D)
        p.EcrireADroite(colonnes(1), y, Argent(d.CumulNet), False, 9D)
        p.EcrireADroite(colonnes(2), y, Argent(d.VacancesAccumulees), False, 9D)
        p.EcrireADroite(colonnes(3), y, Argent(d.SoldeVacances), False, 9D)

        ' ---------- Pied de page ----------
        ' Posé à la fin, sur chaque page : avant d'avoir tout écrit, on ne sait
        ' pas combien il y en aura.
        Dim pied = Tr("Document confidentiel remis à {0}.", SansPointFinal(d.CompagnieNom))
        For i = 0 To p.NombrePages - 1
            p.AllerALaPage(i)
            p.Trait(Gauche, 762D, Droite, 762D, 0.5D, 0.85D)
            p.Ecrire(Gauche, 774D, pied, False, 8D, 0.45D)
            Dim signature = "60secPaie"
            If p.NombrePages > 1 Then signature &= " · " & Tr("Page {#0} de {#1}", i + 1, p.NombrePages)
            p.EcrireADroite(Droite, 774D, signature, False, 8D, 0.6D)
        Next

        Return p.Terminer(Tr("Talon de paie") & " " & TexteDate(d.DatePaie))
    End Function

    ''' <summary>Le nom du fichier joint, dans la langue de l'employé : « Talon-de-paie-2026-01-15.pdf ».</summary>
    Public Shared Function NomFichier(d As DonneesTalon) As String
        Dim base = Tr("Talon de paie").Replace(" "c, "-"c)
        Dim sb As New Text.StringBuilder()
        For Each c In base.Normalize(Text.NormalizationForm.FormD)
            If Globalization.CharUnicodeInfo.GetUnicodeCategory(c) = Globalization.UnicodeCategory.NonSpacingMark Then Continue For
            If Char.IsLetterOrDigit(c) OrElse c = "-"c Then sb.Append(c)
        Next
        Return sb.ToString() & "-" & TexteDate(d.DatePaie) & ".pdf"
    End Function

    ' ------------------------------------------------------------------ outils

    Private Shared Function ModePaiement(d As DonneesTalon) As String
        If d.DepotDirect Then Return Tr("Dépôt direct")
        If d.NumeroCheque.HasValue Then Return Tr("Chèque n° {#0}", d.NumeroCheque.Value)
        Return ""
    End Function

    ''' <summary>Entête d'un tableau : un titre à gauche, des colonnes chiffrées à droite, sur fond gris.</summary>
    Private Shared Function EnteteTableau(p As PdfSimple, y As Double, titre As String,
                                          colonnes As String(), bords As Double(),
                                          Optional taille As Double = 9D) As Double
        y = Sauter(p, y, 40D)
        p.Rectangle(Gauche, y - 10D, Droite - Gauche, 15D, 0.92D)
        p.Ecrire(Gauche + 4D, y, titre, True, taille)
        For i = 0 To colonnes.Length - 1
            p.EcrireADroite(bords(i), y, colonnes(i), True, taille)
        Next
        Return y + 16D
    End Function

    ''' <summary>Bandeau d'avertissement, pour ce qui doit être lu avant les chiffres.</summary>
    Private Shared Function Bandeau(p As PdfSimple, y As Double, texte As String) As Double
        p.Rectangle(Gauche, y - 11D, Droite - Gauche, 18D, 0.88D)
        p.Ecrire(Gauche + 6D, y, texte, True, 9D)
        Return y + 26D
    End Function

    ''' <summary>Passe à la page suivante s'il ne reste pas la place demandée. Un talon coupé en deux ne se lit plus.</summary>
    Private Shared Function Sauter(p As PdfSimple, y As Double, Optional place As Double = 13D) As Double
        If y + place <= BasPage Then Return y
        p.NouvellePage()
        Return HautPage
    End Function

End Class
