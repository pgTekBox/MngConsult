Imports System.Globalization
Imports System.Text
Imports Paie60Sec.Calcul

''' <summary>
''' Le profil d'une compagnie pour l'assistant IA : tout ce que le logiciel sait
''' d'elle, en texte, et rien de ce qui identifie une personne. Les employés
''' sont désignés par un code (E1, E2…) attribué dans un ordre stable ; la
''' correspondance code ↔ nom reste ici, elle est montrée à l'utilisateur mais
''' jamais envoyée. Ni NAS, ni compte bancaire, ni courriel, ni adresse.
'''
''' Le profil généré est conservé (paie.ProfilIA) et refait quand il date de
''' plus d'une heure, quand la liste des employés a changé, ou à la demande.
''' Le comptable y ajoute ses « particularités », qui partent telles quelles.
''' </summary>
Public NotInheritable Class ServiceProfilIA

    Private Sub New()
    End Sub

    Private Const FraicheurMinutes As Integer = 60

    ''' <summary>Code ↔ employé, dans l'ordre du profil. Sert à l'écran seulement.</summary>
    Public Class EntreeLegende
        Public Property Code As String
        Public Property Nom As String
        Public Property Actif As Boolean
    End Class

    ''' <summary>Les employés de la compagnie, actifs d'abord, dans l'ordre qui fixe leurs codes.</summary>
    Private Shared Function Employes() As DataTable
        Return Db.Table(
            "SELECT e.*, ISNULL(e.PeriodesParAnnee, c.PeriodesParAnnee) AS Periodes " &
            "FROM paie.Employe e JOIN paie.Compagnie c ON c.Id = e.CompagnieId " &
            "WHERE e.CompagnieId = @c ORDER BY e.Actif DESC, e.Id", Db.P("@c", Contexte.CompagnieId))
    End Function

    Public Shared Function Legende() As List(Of EntreeLegende)
        Dim l As New List(Of EntreeLegende)()
        Dim i = 0
        For Each e As DataRow In Employes().Rows
            i += 1
            l.Add(New EntreeLegende With {.Code = "E" & i.ToString(), .Nom = e.Txt("Prenom") & " " & e.Txt("Nom"), .Actif = e.Bln("Actif")})
        Next
        Return l
    End Function

    Private Shared Function Empreinte(t As DataTable) As String
        Return String.Join(",", t.Rows.Cast(Of DataRow)().Select(Function(r) r.Ent("Id").ToString() & If(r.Bln("Actif"), "", "-")))
    End Function

    ''' <summary>Le profil à envoyer : celui en base s'il est frais, sinon un neuf.</summary>
    Public Shared Function Obtenir(Optional forcer As Boolean = False) As String
        Dim ligne = Db.Ligne("SELECT * FROM paie.ProfilIA WHERE CompagnieId = @c", Db.P("@c", Contexte.CompagnieId))
        Dim liste = Employes()
        Dim signature = Empreinte(liste)

        Dim frais = ligne IsNot Nothing AndAlso Not ligne.IsNull("GenereLe") AndAlso Not ligne.IsNull("ProfilGenere") AndAlso
                    ligne.Txt("EmpreinteEmployes") = signature AndAlso
                    Convert.ToDateTime(ligne("GenereLe")) > Date.Now.AddMinutes(-FraicheurMinutes)
        If frais AndAlso Not forcer Then Return Assembler(ligne.Txt("ProfilGenere"), ligne.Txt("Particularites"))

        Dim genere = Generer(liste)
        Db.Exec(
            "IF EXISTS (SELECT 1 FROM paie.ProfilIA WHERE CompagnieId = @c) " &
            "UPDATE paie.ProfilIA SET ProfilGenere = @p, EmpreinteEmployes = @e, GenereLe = sysdatetime() WHERE CompagnieId = @c " &
            "ELSE INSERT INTO paie.ProfilIA (CompagnieId, ProfilGenere, EmpreinteEmployes, GenereLe) VALUES (@c, @p, @e, sysdatetime())",
            Db.P("@c", Contexte.CompagnieId), Db.P("@p", genere), Db.P("@e", signature))
        Return Assembler(genere, If(ligne Is Nothing, "", ligne.Txt("Particularites")))
    End Function

    Public Shared Function GenereLe() As Date?
        Dim v = Db.Scalaire("SELECT GenereLe FROM paie.ProfilIA WHERE CompagnieId = @c", Db.P("@c", Contexte.CompagnieId))
        If v Is Nothing Then Return Nothing
        Return Convert.ToDateTime(v)
    End Function

    Public Shared Function Particularites() As String
        Return Convert.ToString(Db.Scalaire("SELECT Particularites FROM paie.ProfilIA WHERE CompagnieId = @c", Db.P("@c", Contexte.CompagnieId)))
    End Function

    Public Shared Sub EnregistrerParticularites(texte As String)
        Db.Exec(
            "IF EXISTS (SELECT 1 FROM paie.ProfilIA WHERE CompagnieId = @c) " &
            "UPDATE paie.ProfilIA SET Particularites = @t, ModifieLe = sysdatetime(), ModifiePar = @u WHERE CompagnieId = @c " &
            "ELSE INSERT INTO paie.ProfilIA (CompagnieId, Particularites, ModifieLe, ModifiePar) VALUES (@c, @t, sysdatetime(), @u)",
            Db.P("@c", Contexte.CompagnieId), Db.P("@t", texte), Db.P("@u", Contexte.Utilisateur))
    End Sub

    Private Shared Function Assembler(genere As String, particularites As String) As String
        Dim sb As New StringBuilder(genere)
        sb.AppendLine()
        sb.AppendLine("## Particularités écrites par le comptable")
        sb.AppendLine(If(String.IsNullOrWhiteSpace(particularites), "(aucune)", particularites.Trim()))
        Return sb.ToString()
    End Function

    ' ------------------------------------------------------------------
    ' La génération
    ' ------------------------------------------------------------------

    Private Shared Function Generer(employes As DataTable) As String
        Dim c = Db.Ligne("SELECT * FROM paie.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId))
        Dim fr = CultureInfo.GetCultureInfo("fr-CA")
        Dim sb As New StringBuilder()

        sb.AppendLine("# Profil de la compagnie (généré le " & Date.Now.ToString("yyyy-MM-dd HH:mm") & ")")
        sb.AppendLine()
        sb.AppendLine("## Configuration de la paie")
        sb.AppendLine("- Fréquence de paie par défaut : " & LibellePeriodes(c("PeriodesParAnnee")))
        sb.AppendLine("- Taux de vacances par défaut : " & Pct(c("TauxVacancesDefaut")))
        Dim secteur = {"Général", "Primaire et manufacturier", "Secteur public"}(Math.Max(0, Math.Min(2, c.Ent("SecteurFSS"))))
        Dim tauxFSS As String = ""
        Try
            tauxFSS = ParametresAnnee.PourAffichage().TauxFSS(c.Dcm("MasseSalarialeEstimee"), CType(c.Ent("SecteurFSS"), SecteurFSS)).ToString("0.00", fr) & " %"
        Catch
        End Try
        sb.AppendLine("- Masse salariale estimée : " & Montant(c("MasseSalarialeEstimee")) & " ; secteur FSS : " & secteur & If(tauxFSS.Length > 0, " ; taux FSS appliqué : " & tauxFSS, ""))
        sb.AppendLine("- Facteur de cotisation de l'employeur à l'AE : " & c.Dcm("FacteurAE").ToString("0.0##", fr))
        sb.AppendLine("- Taux de la CNESST (versement périodique) : " & c.Dcm("TauxCNESST").ToString("0.00##", fr) & " $ par 100 $ ; assujettie à la CNT : " & OuiNon(c.Bln("AssujettiCNT")))
        sb.AppendLine("- Fréquence des remises : fédéral " & Frequence(c, "FrequenceRemiseFederale") & ", Revenu Québec " & Frequence(c, "FrequenceRemiseQuebec"))
        sb.AppendLine("- Numéros : RP " & OuiNon(c.Txt("NumeroEntrepriseFederal").Length > 0, "inscrit", "manquant") & ", RS " & OuiNon(c.Txt("NumeroIdentificationRQ").Length > 0, "inscrit", "manquant"))
        sb.AppendLine("- Dépôt direct : " & OuiNon(c.Txt("DDNumeroEmetteur").Length > 0 AndAlso c.Txt("DDCentreTraitement").Length > 0, "paramètres du fichier configurés", "non configuré"))

        Dim unites = Db.Table("SELECT Code, Description, Taux, Actif FROM paie.UniteCNESST WHERE CompagnieId = @c ORDER BY Code", Db.P("@c", Contexte.CompagnieId))
        If unites.Rows.Count > 0 Then
            sb.AppendLine("- Unités de classification CNESST :")
            For Each u As DataRow In unites.Rows
                sb.AppendLine("  - " & u.Txt("Code") & " " & u.Txt("Description") & " : " & u.Dcm("Taux").ToString("0.00##", fr) & " $ par 100 $" & If(u.Bln("Actif"), "", " (inactive)"))
            Next
        End If

        sb.AppendLine()
        sb.AppendLine("## Éléments de paie de la compagnie")
        For Each el As DataRow In Db.Table("SELECT Description, CategorieCode, Actif, MasquerSurTalon, CompteGL FROM paie.ElementPaie WHERE CompagnieId = @c ORDER BY Actif DESC, Description", Db.P("@c", Contexte.CompagnieId)).Rows
            Dim cat = If(CategoriePaie.Existe(el.Txt("CategorieCode")), CategoriePaie.ParCode(el.Txt("CategorieCode")).LibelleComplet, el.Txt("CategorieCode"))
            sb.AppendLine("- " & el.Txt("Description") & " (" & cat & ")" & If(el.Bln("Actif"), "", " — inactif") & If(el.Bln("MasquerSurTalon"), " — masqué sur le talon", "") & If(el.Txt("CompteGL").Length > 0, " — compte GL " & el.Txt("CompteGL"), ""))
        Next

        sb.AppendLine()
        sb.AppendLine("## Employés (codes E1, E2… ; jamais de nom, de NAS ni de compte)")
        Dim gabarits = Db.Table("SELECT ee.EmployeId, el.Description, el.CategorieCode, ee.Heures, ee.Taux, ee.Montant FROM paie.EmployeElement ee JOIN paie.ElementPaie el ON el.Id = ee.ElementPaieId " &
                                "JOIN paie.Employe e ON e.Id = ee.EmployeId WHERE e.CompagnieId = @c", Db.P("@c", Contexte.CompagnieId))
        Dim i = 0
        For Each e As DataRow In employes.Rows
            i += 1
            Dim code = "E" & i.ToString()
            Dim parts As New List(Of String)()
            parts.Add(If(e.Bln("Actif"), "actif", "inactif"))
            parts.Add(If(e.Bln("PaieConfiguree"), "paie configurée", "paie NON configurée"))
            If Not e.IsNull("DateEmbauche") Then parts.Add("embauché le " & Convert.ToDateTime(e("DateEmbauche")).ToString("yyyy-MM-dd"))
            If Not e.IsNull("DateFinEmploi") Then parts.Add("fin d'emploi le " & Convert.ToDateTime(e("DateFinEmploi")).ToString("yyyy-MM-dd"))
            If e.Txt("Poste").Length > 0 Then parts.Add("poste : " & e.Txt("Poste"))
            parts.Add("fréquence : " & LibellePeriodes(e("Periodes")))
            If e.Dcm("TauxHoraire") > 0D Then parts.Add("taux horaire " & Montant(e("TauxHoraire")) & If(e.Dcm("HeuresSemaine") > 0D, ", " & e.Dcm("HeuresSemaine").ToString("0.##", fr) & " h/semaine", ""))
            If e.Dcm("SalaireAnnuel") > 0D Then parts.Add("salaire annuel " & Montant(e("SalaireAnnuel")))
            If Not e.IsNull("TauxVacances") Then parts.Add("taux de vacances propre " & Pct(e("TauxVacances")))
            If Not e.IsNull("DateNaissance") Then
                Dim age = Date.Today.Year - Convert.ToDateTime(e("DateNaissance")).Year
                If Convert.ToDateTime(e("DateNaissance")).AddYears(age) > Date.Today Then age -= 1
                parts.Add("âge " & age.ToString())
            End If
            parts.Add("langue " & e.Txt("Langue"))
            Dim ex As New List(Of String)()
            If e.Bln("ExemptImpotFederal") Then ex.Add("impôt fédéral")
            If e.Bln("ExemptImpotQuebec") Then ex.Add("impôt du Québec")
            If e.Bln("ExemptRRQ") Then ex.Add("RRQ")
            If e.Bln("ExemptRQAP") Then ex.Add("RQAP")
            If e.Bln("ExemptAE") Then ex.Add("AE")
            If e.Bln("ExemptFSS") Then ex.Add("FSS")
            If e.Bln("ExemptCNESST") Then ex.Add("CNESST/CNT")
            parts.Add(If(ex.Count = 0, "aucune exemption", "exemptions : " & String.Join(", ", ex)))
            If Not e.IsNull("TD1MontantDemande") Then parts.Add("TD1 " & Montant(e("TD1MontantDemande")))
            If e.Dcm("TD1ImpotAdditionnel") > 0D Then parts.Add("impôt fédéral additionnel " & Montant(e("TD1ImpotAdditionnel")) & " par paie")
            If Not e.IsNull("TP1015Montant") Then parts.Add("TP-1015.3 ligne 10 " & Montant(e("TP1015Montant")))
            If e.Dcm("TP1015ImpotAdditionnel") > 0D Then parts.Add("retenue Québec supplémentaire " & Montant(e("TP1015ImpotAdditionnel")) & " par paie")
            parts.Add("case 45 dentaire : code " & e.Ent("CodeDentaireT4").ToString())
            parts.Add(If(e.Txt("UniteCNESSTCode").Length > 0, "unité CNESST " & e.Txt("UniteCNESSTCode"), "unité CNESST : taux de la compagnie"))
            parts.Add(If(e.Bln("DepotDirect"), "dépôt direct", "chèque"))
            parts.Add(If(e.Bln("TalonParCourriel"), "talon par courriel", "talon imprimé"))
            sb.AppendLine("- " & code & " : " & String.Join(" ; ", parts))
            Dim g = gabarits.Select("EmployeId = " & e.Ent("Id").ToString())
            If g.Length > 0 Then
                For Each l In g
                    sb.AppendLine("  - élément récurrent : " & l.Txt("Description") & If(l.Dcm("Heures") > 0D, " " & l.Dcm("Heures").ToString("0.##", fr) & " h × " & Montant(l("Taux")), " " & Montant(l("Montant"))))
                Next
            End If
        Next
        If employes.Rows.Count = 0 Then sb.AppendLine("(aucun employé)")

        sb.AppendLine()
        sb.AppendLine("## État courant")
        Dim derniere = Db.Ligne("SELECT TOP 1 DatePaie, DateDebutPeriode, DateFinPeriode, PeriodesParAnnee FROM paie.LotPaie WHERE CompagnieId = @c AND Statut = 'C' ORDER BY DatePaie DESC, Id DESC", Db.P("@c", Contexte.CompagnieId))
        sb.AppendLine("- Dernière paie confirmée : " & If(derniere Is Nothing, "aucune", Convert.ToDateTime(derniere("DatePaie")).ToString("yyyy-MM-dd") & " (période du " & Convert.ToDateTime(derniere("DateDebutPeriode")).ToString("yyyy-MM-dd") & " au " & Convert.ToDateTime(derniere("DateFinPeriode")).ToString("yyyy-MM-dd") & ", " & LibellePeriodes(derniere("PeriodesParAnnee")) & ")"))
        Dim brouillon = Db.Ligne("SELECT TOP 1 DateFinPeriode, DatePaie FROM paie.LotPaie WHERE CompagnieId = @c AND Statut = 'B' ORDER BY Id DESC", Db.P("@c", Contexte.CompagnieId))
        sb.AppendLine("- Paie en préparation (brouillon) : " & If(brouillon Is Nothing, "aucune", "oui, période se terminant le " & Convert.ToDateTime(brouillon("DateFinPeriode")).ToString("yyyy-MM-dd")))
        Dim annee = Date.Today.Year
        sb.AppendLine("- Paies confirmées en " & annee.ToString() & " : " & Db.ScalaireEntier("SELECT COUNT(*) FROM paie.LotPaie WHERE CompagnieId = @c AND Statut = 'C' AND YEAR(DatePaie) = @a", Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee)).ToString())
        For Each gouv In {"F", "Q"}
            Dim solde = Db.Ligne(
                "SELECT COUNT(*) AS Nb, MIN(l.DatePaie) AS Plus_ancienne FROM paie.LotPaie l JOIN paie.Paie p ON p.LotPaieId = l.Id " &
                "WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND " & If(gouv = "F", "p.RemiseFederaleId IS NULL", "p.RemiseQuebecId IS NULL"),
                Db.P("@c", Contexte.CompagnieId))
            Dim nb = If(solde Is Nothing, 0, solde.Ent("Nb"))
            sb.AppendLine("- Retenues non encore remises " & If(gouv = "F", "au fédéral", "à Revenu Québec") & " : " & If(nb = 0, "aucune", nb.ToString() & " paie(s), la plus ancienne payée le " & Convert.ToDateTime(solde("Plus_ancienne")).ToString("yyyy-MM-dd")))
        Next

        sb.AppendLine()
        sb.AppendLine("## Taux de l'année")
        For Each a In {annee, annee + 1}
            sb.AppendLine("- " & a.ToString() & " : " & If(ParametresAnnee.EstDisponible(a), "taux validés, paies possibles", "taux non validés, paies refusées"))
        Next
        Return sb.ToString()
    End Function

    Private Shared Function Frequence(c As DataRow, colonne As String) As String
        If Not c.Table.Columns.Contains(colonne) Then Return "mensuelle"
        Return If(c.Txt(colonne) = "T", "trimestrielle", "mensuelle")
    End Function

    Private Shared Function Montant(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value Then Return "—"
        Return Convert.ToDecimal(v).ToString("N2", CultureInfo.GetCultureInfo("fr-CA")) & " $"
    End Function

    Private Shared Function Pct(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value Then Return "—"
        Return Convert.ToDecimal(v).ToString("0.##", CultureInfo.GetCultureInfo("fr-CA")) & " %"
    End Function

    Private Shared Function OuiNon(b As Boolean, Optional oui As String = "oui", Optional non As String = "non") As String
        Return If(b, oui, non)
    End Function

End Class
