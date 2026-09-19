Imports System.Text

''' <summary>Rendu HTML des résultats de paie (révision, détail d'un lot, talon). Tout texte issu de la base est encodé.</summary>
Public NotInheritable Class RenduPaie

    Private Sub New()
    End Sub

    Private Shared Function H(texte As String) As String
        Return HttpUtility.HtmlEncode(texte)
    End Function

    Private Shared Function PaiesDuLot(lotId As Integer) As DataTable
        Return Db.Table(
            "SELECT p.*, e.Prenom, e.Nom, e.DepotDirect FROM paie.Paie p JOIN paie.Employe e ON e.Id = p.EmployeId " &
            "JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE p.LotPaieId = @l AND p.Inclus = 1 AND l.CompagnieId = @c ORDER BY e.Nom, e.Prenom",
            Db.P("@l", lotId), Db.P("@c", Contexte.CompagnieId))
    End Function

    Private Shared Function PartsEmployeur(p As DataRow) As Decimal
        Return p.Dcm("EmployeurRRQ") + p.Dcm("EmployeurRRQ2") + p.Dcm("EmployeurAE") + p.Dcm("EmployeurRQAP") +
               p.Dcm("EmployeurFSS") + p.Dcm("EmployeurCNESST") + p.Dcm("EmployeurCNT")
    End Function

    ''' <summary>Tableau des paies d'un lot, avec le grand total et, sur demande, le détail de vérification par employé.</summary>
    Public Shared Function TableauLot(lotId As Integer, avecVerification As Boolean, avecTalons As Boolean) As String
        Dim paies = PaiesDuLot(lotId)
        If paies.Rows.Count = 0 Then Return "<p class=""note"">Aucun employé inclus dans cette paie.</p>"

        Dim sb As New StringBuilder()
        sb.Append("<div class=""table-defilante""><table class=""liste""><thead><tr><th>Employé</th><th class=""num"">Heures</th><th class=""num"">Brut</th>")
        sb.Append("<th class=""num"">Impôt féd.</th><th class=""num"">Impôt Qc</th><th class=""num"">RRQ</th><th class=""num"">AE</th><th class=""num"">RQAP</th>")
        sb.Append("<th class=""num"">Autres déd.</th><th class=""num"">Net</th><th class=""num"">Parts employeur</th><th class=""num"">Vacances</th>")
        If avecTalons Then sb.Append("<th></th>")
        sb.Append("</tr></thead><tbody>")

        Dim colonnes = {"Heures", "BrutVerse", "ImpotFederal", "ImpotQuebec", "RRQTotal", "AE", "RQAP", "AutresDeductions", "Net", "Employeur", "VacancesAccumulees"}
        Dim totaux As New Dictionary(Of String, Decimal)()
        For Each col In colonnes
            totaux(col) = 0D
        Next

        For Each p As DataRow In paies.Rows
            Dim valeurs As New Dictionary(Of String, Decimal) From {
                {"Heures", p.Dcm("Heures")}, {"BrutVerse", p.Dcm("BrutVerse")}, {"ImpotFederal", p.Dcm("ImpotFederal")},
                {"ImpotQuebec", p.Dcm("ImpotQuebec")}, {"RRQTotal", p.Dcm("RRQ") + p.Dcm("RRQ2")}, {"AE", p.Dcm("AE")}, {"RQAP", p.Dcm("RQAP")},
                {"AutresDeductions", p.Dcm("AutresDeductions")}, {"Net", p.Dcm("Net")}, {"Employeur", PartsEmployeur(p)},
                {"VacancesAccumulees", p.Dcm("VacancesAccumulees")}}

            sb.Append("<tr><td>").Append(H(p.Txt("Nom") & ", " & p.Txt("Prenom")))
            If Not p.IsNull("NumeroCheque") Then sb.Append("<div class=""note"">Chèque n° ").Append(p.Ent("NumeroCheque")).Append("</div>")
            If p.Bln("DepotDirect") Then sb.Append("<div class=""note"">Dépôt direct</div>")
            sb.Append("</td>")
            For Each col In colonnes
                totaux(col) += valeurs(col)
                sb.Append("<td class=""num"">").Append(If(col = "Heures", Nombre(valeurs(col)), Argent(valeurs(col)))).Append("</td>")
            Next
            If avecTalons Then sb.Append("<td><a href=""Talon.aspx?paie=").Append(p.Ent("Id")).Append(""">Talon</a></td>")
            sb.Append("</tr>")
        Next

        sb.Append("</tbody><tfoot><tr><td>Grand total</td>")
        For Each col In colonnes
            sb.Append("<td class=""num"">").Append(If(col = "Heures", Nombre(totaux(col)), Argent(totaux(col)))).Append("</td>")
        Next
        If avecTalons Then sb.Append("<td></td>")
        sb.Append("</tr></tfoot></table></div>")

        If avecVerification Then
            For Each p As DataRow In paies.Rows
                sb.Append(DetailEmploye(p))
            Next
        End If
        Return sb.ToString()
    End Function

    Private Shared Function DetailEmploye(p As DataRow) As String
        Dim sb As New StringBuilder()
        If p.Txt("Avertissements").Length > 0 Then
            sb.Append("<div class=""avertissement""><strong>").Append(H(p.Txt("Prenom") & " " & p.Txt("Nom"))).Append(" :</strong> ")
            sb.Append(H(p.Txt("Avertissements"))).Append("</div>")
        End If

        sb.Append("<details><summary>Détail et vérification des calculs - ").Append(H(p.Txt("Prenom") & " " & p.Txt("Nom"))).Append("</summary>")
        sb.Append("<table class=""liste""><thead><tr><th>Ligne</th><th class=""num"">Heures</th><th class=""num"">Taux</th><th class=""num"">Montant</th></tr></thead><tbody>")
        For Each l As DataRow In Db.Table("SELECT * FROM paie.PaieLigne WHERE PaieId = @p ORDER BY Id", Db.P("@p", p.Ent("Id"))).Rows
            sb.Append("<tr><td>").Append(H(l.Txt("Description"))).Append("</td><td class=""num"">").Append(If(l.Dcm("Heures") > 0D, Nombre(l("Heures")), ""))
            sb.Append("</td><td class=""num"">").Append(If(l.Dcm("Taux") > 0D, Argent(l("Taux")), "")).Append("</td><td class=""num"">").Append(Argent(l("Montant"))).Append("</td></tr>")
        Next
        sb.Append("</tbody></table>")
        sb.Append("<pre class=""verification"">").Append(H(p.Txt("Verification"))).Append("</pre>")

        sb.Append("<table class=""matrice""><tr><th>RRQ</th><th>RRQ 2</th><th>AE</th><th>RQAP</th><th>FSS</th><th>CNESST</th><th>CNT</th></tr><tr>")
        For Each col In {"EmployeurRRQ", "EmployeurRRQ2", "EmployeurAE", "EmployeurRQAP", "EmployeurFSS", "EmployeurCNESST", "EmployeurCNT"}
            sb.Append("<td>").Append(Argent(p(col))).Append("</td>")
        Next
        sb.Append("</tr></table><p class=""note"">Parts de l'employeur pour cette paie.</p></details>")
        Return sb.ToString()
    End Function

    ''' <summary>Grand total du lot en trois colonnes : revenus et avantages, déductions, parts de l'employeur.</summary>
    Public Shared Function SommaireLot(lotId As Integer) As String
        Dim totaux = Db.Ligne(
            "SELECT ISNULL(SUM(ImpotFederal),0) ImpotFederal, ISNULL(SUM(ImpotQuebec),0) ImpotQuebec, ISNULL(SUM(RRQ),0) RRQ, ISNULL(SUM(RRQ2),0) RRQ2, " &
            "ISNULL(SUM(AE),0) AE, ISNULL(SUM(RQAP),0) RQAP, ISNULL(SUM(EmployeurRRQ),0) EmployeurRRQ, ISNULL(SUM(EmployeurRRQ2),0) EmployeurRRQ2, " &
            "ISNULL(SUM(EmployeurAE),0) EmployeurAE, ISNULL(SUM(EmployeurRQAP),0) EmployeurRQAP, ISNULL(SUM(EmployeurFSS),0) EmployeurFSS, " &
            "ISNULL(SUM(EmployeurCNESST),0) EmployeurCNESST, ISNULL(SUM(EmployeurCNT),0) EmployeurCNT " &
            "FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE p.LotPaieId = @l AND p.Inclus = 1 AND l.CompagnieId = @c",
            Db.P("@l", lotId), Db.P("@c", Contexte.CompagnieId))

        Dim lignes = Db.Table(
            "SELECT pl.Description, CASE WHEN pl.CategorieCode LIKE 'DED[_]%' THEN 1 ELSE 0 END AS EstDeduction, SUM(pl.Montant) AS Montant " &
            "FROM paie.PaieLigne pl JOIN paie.Paie p ON p.Id = pl.PaieId JOIN paie.LotPaie l ON l.Id = p.LotPaieId " &
            "WHERE p.LotPaieId = @l AND p.Inclus = 1 AND l.CompagnieId = @c " &
            "GROUP BY pl.Description, CASE WHEN pl.CategorieCode LIKE 'DED[_]%' THEN 1 ELSE 0 END ORDER BY pl.Description",
            Db.P("@l", lotId), Db.P("@c", Contexte.CompagnieId))

        Dim revenus As New List(Of KeyValuePair(Of String, Decimal))()
        Dim deductions As New List(Of KeyValuePair(Of String, Decimal)) From {
            Paire("Impôt fédéral", totaux.Dcm("ImpotFederal")), Paire("Impôt du Québec", totaux.Dcm("ImpotQuebec")),
            Paire("RRQ", totaux.Dcm("RRQ")), Paire("RRQ - 2e cotisation suppl.", totaux.Dcm("RRQ2")),
            Paire("Assurance-emploi", totaux.Dcm("AE")), Paire("RQAP", totaux.Dcm("RQAP"))}
        For Each l As DataRow In lignes.Rows
            If l.Ent("EstDeduction") = 1 Then deductions.Add(Paire(l.Txt("Description"), l.Dcm("Montant"))) Else revenus.Add(Paire(l.Txt("Description"), l.Dcm("Montant")))
        Next
        Dim employeur As New List(Of KeyValuePair(Of String, Decimal)) From {
            Paire("RRQ", totaux.Dcm("EmployeurRRQ")), Paire("RRQ - 2e cotisation suppl.", totaux.Dcm("EmployeurRRQ2")),
            Paire("Assurance-emploi", totaux.Dcm("EmployeurAE")), Paire("RQAP", totaux.Dcm("EmployeurRQAP")),
            Paire("FSS", totaux.Dcm("EmployeurFSS")), Paire("CNESST", totaux.Dcm("EmployeurCNESST")), Paire("CNT (normes du travail)", totaux.Dcm("EmployeurCNT"))}

        Return "<div class=""grille-cartes"">" & Colonne("Revenus et avantages", revenus) & Colonne("Déductions", deductions) &
               Colonne("Parts de l'employeur", employeur) & "</div>"
    End Function

    Private Shared Function Paire(libelle As String, montant As Decimal) As KeyValuePair(Of String, Decimal)
        Return New KeyValuePair(Of String, Decimal)(libelle, montant)
    End Function

    Private Shared Function Colonne(titre As String, lignes As List(Of KeyValuePair(Of String, Decimal))) As String
        Dim sb As New StringBuilder()
        Dim total As Decimal = 0D
        sb.Append("<div class=""carte""><h2>").Append(H(titre)).Append("</h2><table class=""liste""><tbody>")
        For Each l In lignes
            If l.Value = 0D Then Continue For
            total += l.Value
            sb.Append("<tr><td>").Append(H(l.Key)).Append("</td><td class=""num"">").Append(Argent(l.Value)).Append("</td></tr>")
        Next
        sb.Append("</tbody><tfoot><tr><td>Total</td><td class=""num"">").Append(Argent(total)).Append("</td></tr></tfoot></table></div>")
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Le contenu du talon, lu une seule fois et rendu deux fois : en HTML pour
    ''' l'écran et le corps du courriel, en PDF pour la pièce jointe. Les deux
    ''' rendus partent d'ici, sinon ils finiraient par ne plus dire la même chose.
    ''' </summary>
    Public Shared Function Lire(paieId As Integer) As DonneesTalon
        Dim d As New DonneesTalon()
        Dim p = Db.Ligne(
            "SELECT p.*, l.DateDebutPeriode, l.DateFinPeriode, l.DatePaie, l.Statut, l.Id AS LotId, " &
            "e.Prenom, e.Nom, e.Code, e.Adresse1, e.Adresse2, e.Ville, e.Province, e.CodePostal, e.DepotDirect, " &
            "c.Nom AS CompagnieNom, c.Adresse1 AS CAdresse1, c.Ville AS CVille, c.Province AS CProvince, c.CodePostal AS CCodePostal " &
            "FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId JOIN paie.Employe e ON e.Id = p.EmployeId JOIN paie.Compagnie c ON c.Id = l.CompagnieId " &
            "WHERE p.Id = @p AND l.CompagnieId = @c", Db.P("@p", paieId), Db.P("@c", Contexte.CompagnieId))
        If p Is Nothing Then Return d

        Dim datePaie = p.DtN("DatePaie").Value
        Dim cumul = Db.Ligne(
            "SELECT ISNULL(SUM(x.BrutVerse),0) Brut, ISNULL(SUM(x.ImpotFederal),0) ImpotFederal, ISNULL(SUM(x.ImpotQuebec),0) ImpotQuebec, " &
            "ISNULL(SUM(x.RRQ + x.RRQ2),0) RRQ, ISNULL(SUM(x.AE),0) AE, ISNULL(SUM(x.RQAP),0) RQAP, ISNULL(SUM(x.AutresDeductions),0) Autres, ISNULL(SUM(x.Net),0) Net " &
            "FROM paie.Paie x JOIN paie.LotPaie lx ON lx.Id = x.LotPaieId " &
            "WHERE x.EmployeId = @e AND x.Inclus = 1 AND YEAR(lx.DatePaie) = @a AND (x.Id = @p OR (lx.Statut = 'C' AND (lx.DatePaie < @d OR (lx.DatePaie = @d AND lx.Id < @lot))))",
            Db.P("@e", p.Ent("EmployeId")), Db.P("@a", datePaie.Year), Db.P("@p", paieId), Db.P("@d", datePaie), Db.P("@lot", p.Ent("LotId")))
        Dim depart = Db.Ligne("SELECT * FROM paie.CumulatifDepart WHERE EmployeId = @e AND Annee = @a", Db.P("@e", p.Ent("EmployeId")), Db.P("@a", datePaie.Year))
        Dim soldeVacances = Convert.ToDecimal(Db.Scalaire(
            "SELECT ISNULL((SELECT SUM(VacancesSolde) FROM paie.CumulatifDepart WHERE EmployeId = @e), 0) + " &
            "ISNULL((SELECT SUM(x.VacancesAccumulees - x.VacancesPayees) FROM paie.Paie x JOIN paie.LotPaie lx ON lx.Id = x.LotPaieId " &
            "        WHERE x.EmployeId = @e AND x.Inclus = 1 AND (x.Id = @p OR (lx.Statut = 'C' AND (lx.DatePaie < @d OR (lx.DatePaie = @d AND lx.Id < @lot))))), 0)",
            Db.P("@e", p.Ent("EmployeId")), Db.P("@p", paieId), Db.P("@d", datePaie), Db.P("@lot", p.Ent("LotId"))))

        d.Trouve = True
        d.Statut = p.Txt("Statut")

        d.CompagnieNom = p.Txt("CompagnieNom")
        d.CompagnieAdresse = p.Txt("CAdresse1")
        d.CompagnieLieu = Lieu(p.Txt("CVille"), p.Txt("CProvince"), p.Txt("CCodePostal"))

        d.EmployeNom = p.Txt("Prenom") & " " & p.Txt("Nom")
        d.EmployeCode = p.Txt("Code")
        d.EmployeAdresse1 = p.Txt("Adresse1")
        d.EmployeAdresse2 = p.Txt("Adresse2")
        d.EmployeLieu = Lieu(p.Txt("Ville"), p.Txt("Province"), p.Txt("CodePostal"))

        d.DateDebut = p.DtN("DateDebutPeriode").Value
        d.DateFin = p.DtN("DateFinPeriode").Value
        d.DatePaie = datePaie
        d.DepotDirect = p.Bln("DepotDirect")
        If Not p.IsNull("NumeroCheque") Then d.NumeroCheque = p.Ent("NumeroCheque")

        Dim lignes = Db.Table("SELECT * FROM paie.PaieLigne WHERE PaieId = @p AND MasquerSurTalon = 0 ORDER BY Id", Db.P("@p", paieId))
        For Each l As DataRow In lignes.Select("CategorieCode NOT LIKE 'DED_%'")
            d.Revenus.Add(New LigneTalon With {
                .Description = l.Txt("Description"), .Heures = l.Dcm("Heures"), .Taux = l.Dcm("Taux"), .Montant = l.Dcm("Montant")})
        Next
        d.Heures = p.Dcm("Heures")
        d.BrutVerse = p.Dcm("BrutVerse")
        d.AvantagesNonMonetaires = p.Dcm("AvantagesNonMonetaires")

        AjouterRetenue(d, "Impôt fédéral", p.Dcm("ImpotFederal"), cumul.Dcm("ImpotFederal") + DepartDe(depart, "ImpotFederal"))
        AjouterRetenue(d, "Impôt du Québec", p.Dcm("ImpotQuebec"), cumul.Dcm("ImpotQuebec") + DepartDe(depart, "ImpotQuebec"))
        AjouterRetenue(d, "RRQ", p.Dcm("RRQ") + p.Dcm("RRQ2"), cumul.Dcm("RRQ") + DepartDe(depart, "RRQ") + DepartDe(depart, "RRQ2"))
        AjouterRetenue(d, "Assurance-emploi", p.Dcm("AE"), cumul.Dcm("AE") + DepartDe(depart, "AE"))
        AjouterRetenue(d, "RQAP", p.Dcm("RQAP"), cumul.Dcm("RQAP") + DepartDe(depart, "RQAP"))
        For Each l As DataRow In lignes.Select("CategorieCode LIKE 'DED_%'")
            d.Retenues.Add(New RetenueTalon With {.Libelle = l.Txt("Description"), .Courant = l.Dcm("Montant"), .AvecCumulatif = False})
        Next
        d.TotalRetenues = p.Dcm("ImpotFederal") + p.Dcm("ImpotQuebec") + p.Dcm("RRQ") + p.Dcm("RRQ2") + p.Dcm("AE") + p.Dcm("RQAP") + p.Dcm("AutresDeductions")

        d.Net = p.Dcm("Net")
        d.CumulBrut = cumul.Dcm("Brut") + DepartDe(depart, "Brut")
        d.CumulNet = cumul.Dcm("Net")
        d.TauxVacances = p.Dcm("TauxVacances")
        d.VacancesAccumulees = p.Dcm("VacancesAccumulees")
        d.SoldeVacances = soldeVacances
        Return d
    End Function

    ''' <summary>Une retenue à zéro qui n'a rien accumulé ne dit rien : on ne l'affiche pas.</summary>
    Private Shared Sub AjouterRetenue(d As DonneesTalon, libelle As String, courant As Decimal, cumulatif As Decimal)
        If courant = 0D AndAlso cumulatif = 0D Then Return
        d.Retenues.Add(New RetenueTalon With {.Libelle = libelle, .Courant = courant, .Cumulatif = cumulatif, .AvecCumulatif = True})
    End Sub

    ''' <summary>Talon de paie d'un employé, avec les cumulatifs de l'année.</summary>
    Public Shared Function Talon(paieId As Integer) As String
        Dim d = Lire(paieId)
        If Not d.Trouve Then Return "<p class=""note"">Talon introuvable.</p>"

        Dim sb As New StringBuilder()
        sb.Append("<div class=""talon"">")
        If d.Statut = "B" Then sb.Append("<div class=""avertissement"">Aperçu : cette paie n'est pas encore confirmée.</div>")
        If d.Statut = "A" Then sb.Append("<div class=""message erreur"">Cette paie a été annulée.</div>")

        sb.Append("<div class=""talon-entete""><div><strong>").Append(H(d.CompagnieNom)).Append("</strong>")
        Lignes(sb, d.CompagnieAdresse, d.CompagnieLieu)
        sb.Append("</div>")
        sb.Append("<div><strong>Talon de paie</strong><br/>Période : ").Append(TexteDate(d.DateDebut)).Append(" au ").Append(TexteDate(d.DateFin))
        sb.Append("<br/>Date de paie : ").Append(TexteDate(d.DatePaie)).Append("<br/>")
        sb.Append(H(d.ModePaiement))
        sb.Append("</div></div>")

        sb.Append("<p><strong>").Append(H(d.EmployeNom)).Append("</strong>")
        If d.EmployeCode.Length > 0 Then sb.Append(" (").Append(H(d.EmployeCode)).Append(")")
        Lignes(sb, d.EmployeAdresse1, d.EmployeAdresse2, d.EmployeLieu)
        sb.Append("</p>")

        sb.Append("<div class=""talon-colonnes""><div><table><thead><tr><th>Revenus et avantages</th><th class=""num"">Heures</th><th class=""num"">Taux</th><th class=""num"">Montant</th></tr></thead><tbody>")
        For Each l In d.Revenus
            sb.Append("<tr><td>").Append(H(l.Description)).Append("</td><td class=""num"">").Append(If(l.Heures > 0D, Nombre(l.Heures), ""))
            sb.Append("</td><td class=""num"">").Append(If(l.Taux > 0D, Argent(l.Taux), "")).Append("</td><td class=""num"">").Append(Argent(l.Montant)).Append("</td></tr>")
        Next
        sb.Append("<tr><td><strong>Paie brute</strong></td><td class=""num"">").Append(Nombre(d.Heures)).Append("</td><td></td><td class=""num""><strong>")
        sb.Append(Argent(d.BrutVerse)).Append("</strong></td></tr>")
        If d.AvantagesNonMonetaires > 0D Then
            sb.Append("<tr><td colspan=""3"" class=""note"">dont avantages imposables non versés en argent</td><td class=""num note"">").Append(Argent(d.AvantagesNonMonetaires)).Append("</td></tr>")
        End If
        sb.Append("</tbody></table></div>")

        sb.Append("<div><table><thead><tr><th>Retenues et déductions</th><th class=""num"">Courant</th><th class=""num"">Cumulatif</th></tr></thead><tbody>")
        For Each r In d.Retenues
            sb.Append("<tr><td>").Append(H(r.Libelle)).Append("</td><td class=""num"">").Append(Argent(r.Courant)).Append("</td><td class=""num"">")
            If r.AvecCumulatif Then sb.Append(Argent(r.Cumulatif))
            sb.Append("</td></tr>")
        Next
        sb.Append("<tr><td><strong>Total</strong></td><td class=""num""><strong>").Append(Argent(d.TotalRetenues)).Append("</strong></td><td></td></tr>")
        sb.Append("</tbody></table></div></div>")

        sb.Append("<div class=""talon-net""><span>Paie nette</span><span>").Append(Argent(d.Net)).Append("</span></div>")

        sb.Append("<table style=""margin-top:16px""><thead><tr><th>Cumulatifs de l'année</th><th class=""num"">Brut</th><th class=""num"">Net</th>")
        sb.Append("<th class=""num"">Vacances accumulées (").Append(Nombre(d.TauxVacances)).Append(" %)</th><th class=""num"">Solde de vacances</th></tr></thead><tbody><tr><td></td>")
        sb.Append("<td class=""num"">").Append(Argent(d.CumulBrut)).Append("</td>")
        sb.Append("<td class=""num"">").Append(Argent(d.CumulNet)).Append("</td>")
        sb.Append("<td class=""num"">").Append(Argent(d.VacancesAccumulees)).Append("</td>")
        sb.Append("<td class=""num"">").Append(Argent(d.SoldeVacances)).Append("</td></tr></tbody></table>")
        sb.Append("</div>")
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Les lignes d'une adresse, sautées quand elles sont vides. Une compagnie sans
    ''' rue ou un employé sans adresse laissaient sinon une ligne blanche au milieu
    ''' du bloc — le talon avait l'air inachevé alors qu'il ne manquait rien.
    ''' </summary>
    Private Shared Sub Lignes(sb As StringBuilder, ParamArray textes As String())
        For Each texte In textes
            If Not String.IsNullOrWhiteSpace(texte) Then sb.Append("<br/>").Append(H(texte))
        Next
    End Sub

    Private Shared Function DepartDe(depart As DataRow, colonne As String) As Decimal
        Return If(depart Is Nothing, 0D, depart.Dcm(colonne))
    End Function

    Private Shared Function Lieu(ville As String, province As String, codePostal As String) As String
        Dim s = ville
        If province.Length > 0 Then s &= If(s.Length > 0, " (", "(") & province & ")"
        If codePostal.Length > 0 Then s &= "  " & codePostal
        Return s.Trim()
    End Function

End Class
