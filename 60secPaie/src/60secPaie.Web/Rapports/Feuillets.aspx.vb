Imports System.Text
Imports Paie60Sec.Calcul

Public Class PageFeuillets
    Inherits PageBase

    ' Cases du tableau. Le régime de pension occupe les cases 16 et 16A (RPC, hors Québec) ou 17 et 17A
    ' (RRQ, Québec) ; les cases 55 et 56 (RQAP) et le Relevé 1 n'existent qu'au Québec.
    Private Shared ReadOnly CasesT4 As String() = {"14", "22", "16", "16A", "17", "17A", "18", "55", "24", "26", "56"}
    Private Shared ReadOnly CasesRPC As String() = {"16", "16A"}
    Private Shared ReadOnly CasesQuebec As String() = {"17", "17A", "55", "56"}
    Private Shared ReadOnly CasesR1 As String() = {"A", "E"}

    Private _avecQuebec As Boolean = True

    ''' <summary>Vrai si l'année comporte un emploi au Québec : la page parle alors aussi du Relevé 1 et de Revenu Québec.</summary>
    Protected ReadOnly Property AvecQuebec As Boolean
        Get
            Return _avecQuebec
        End Get
    End Property

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            For Each a In ServiceFeuillets.AnneesDisponibles()
                ddlAnnee.Items.Add(a.ToString())
            Next
        End If
        pnlContenu.Visible = ddlAnnee.Items.Count > 0
        btnCsv.Visible = ddlAnnee.Items.Count > 0
        pnlFeuillets.Visible = ddlAnnee.Items.Count > 0
        lblAucun.Visible = ddlAnnee.Items.Count = 0
    End Sub

    Private ReadOnly Property Annee As Integer
        Get
            Return Integer.Parse(ddlAnnee.SelectedValue)
        End Get
    End Property

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        _avecQuebec = Not Contexte.HorsQuebec
        If Contexte.HorsQuebec Then Title = "Feuillets T4"
        If ddlAnnee.Items.Count = 0 Then Return
        Dim feuillets = ServiceFeuillets.Preparer(Annee)
        Dim envois = EnvoisDeLAnnee()

        ' Les colonnes suivent ce que l'année contient : une compagnie hors Québec n'a ni RRQ, ni RQAP, ni Relevé 1.
        Dim avecHorsQuebec = Contexte.HorsQuebec OrElse feuillets.Any(Function(x) CasesRPC.Any(Function(k) x.CaseT4(k) <> 0D))
        Dim quebecAussi = Not Contexte.HorsQuebec OrElse feuillets.Any(Function(x) x.AvecReleve1)
        _avecQuebec = quebecAussi
        Dim ColonnesT4 = CasesT4.Where(Function(k) (avecHorsQuebec OrElse Not CasesRPC.Contains(k)) AndAlso (quebecAussi OrElse Not CasesQuebec.Contains(k))).ToArray()
        Dim ColonnesR1 = If(quebecAussi, CasesR1, New String() {})

        Dim sb As New StringBuilder("<table class=""liste""><thead><tr><th rowspan=""2"">Employé</th>")
        sb.Append("<th colspan=""").Append(ColonnesT4.Length).Append(""">T4 (cases)</th>")
        If ColonnesR1.Length > 0 Then sb.Append("<th colspan=""").Append(ColonnesR1.Length).Append(""">Relevé 1</th>")
        sb.Append("<th rowspan=""2""></th></tr><tr>")
        For Each c In ColonnesT4
            sb.Append("<th class=""num"">").Append(c).Append("</th>")
        Next
        For Each c In ColonnesR1
            sb.Append("<th class=""num"">").Append(c).Append("</th>")
        Next
        sb.Append("</tr></thead><tbody>")

        Dim totaux As New Dictionary(Of String, Decimal)()
        For Each f In feuillets
            sb.Append("<tr><td>").Append(HttpUtility.HtmlEncode(f.NomComplet))
            If f.ContientCumulatifsDepart Then sb.Append("<div class=""note"">inclut des cumulatifs de départ</div>")
            If f.DeuxProvinces Then
                sb.Append("<div class=""note"">").Append(HttpUtility.HtmlEncode(String.Format("payé dans plus d'une province ({0}) : un T4 par province", String.Join(", ", f.ProvincesEmploi)))).Append("</div>")
            End If
            sb.Append("</td>")
            For Each c In ColonnesT4
                Cellule(sb, totaux, "T4" & c, f.CaseT4(c))
            Next
            For Each c In ColonnesR1
                Cellule(sb, totaux, "R1" & c, f.CaseR1(c))
            Next
            sb.Append("<td><a href=""Feuillet.aspx?employe=").Append(f.Employe.Ent("Id")).Append("&amp;annee=").Append(Annee).Append(""">Feuillet</a>")
            Dim envoye As Date
            If envois.TryGetValue(f.Employe.Ent("Id"), envoye) Then sb.Append("<div class=""note"">").Append(HttpUtility.HtmlEncode(Tr("envoyé par courriel le {#0}", TexteDate(envoye)))).Append("</div>")
            sb.Append("</td></tr>")
        Next

        sb.Append("</tbody><tfoot><tr><td>Total (").Append(feuillets.Count).Append(If(feuillets.Count > 1, " feuillets)", " feuillet)")).Append("</td>")
        For Each c In ColonnesT4
            sb.Append("<td class=""num"">").Append(Argent(Total(totaux, "T4" & c))).Append("</td>")
        Next
        For Each c In ColonnesR1
            sb.Append("<td class=""num"">").Append(Argent(Total(totaux, "R1" & c))).Append("</td>")
        Next
        sb.Append("<td></td></tr></tfoot></table>")
        litTableau.Text = sb.ToString()

        litSommaire.Text = Sommaire(Total(totaux, "T417") + Total(totaux, "T417A"), Total(totaux, "T418"), Total(totaux, "T455"),
                                    Total(totaux, "T416") + Total(totaux, "T416A"), avecHorsQuebec, quebecAussi)
    End Sub

    Private Shared Sub Cellule(sb As StringBuilder, totaux As Dictionary(Of String, Decimal), cle As String, montant As Decimal)
        totaux(cle) = Total(totaux, cle) + montant
        sb.Append("<td class=""num"">").Append(If(montant = 0D, "", Argent(montant))).Append("</td>")
    End Sub

    Private Shared Function Total(totaux As Dictionary(Of String, Decimal), cle As String) As Decimal
        Dim v As Decimal
        Return If(totaux.TryGetValue(cle, v), v, 0D)
    End Function

    Private Function Sommaire(rrqEmployes As Decimal, aeEmployes As Decimal, rqapEmployes As Decimal,
                              rpcEmployes As Decimal, avecHorsQuebec As Boolean, quebecAussi As Boolean) As String
        Dim s = ServiceFeuillets.SommaireEmployeur(Annee)
        Dim sb As New StringBuilder("<div class=""grille-cartes"">")

        sb.Append("<div class=""carte""><h2>Sommaire T4 (ARC)</h2><table class=""liste""><tbody>")
        If avecHorsQuebec Then
            Ligne(sb, "Cotisations des employés au RPC (cases 16 et 16A)", rpcEmployes)
            Ligne(sb, "Cotisations de l'employeur au RPC", s.Dcm("EmployeurRPC"))
        End If
        Ligne(sb, "Cotisations des employés à l'AE (case 18)", aeEmployes)
        Ligne(sb, "Cotisations de l'employeur à l'AE (case 19)", s.Dcm("EmployeurAE"))
        Ligne(sb, "Retenues et cotisations de l'année", s.Dcm("DuFederal"))
        Ligne(sb, "Remises enregistrées", s.Dcm("PayeFederal"))
        Ligne(sb, "Solde à payer", s.Dcm("DuFederal") - s.Dcm("PayeFederal"))
        sb.Append("</tbody></table></div>")

        ' Hors Québec, une carte par province : la cotisation santé de l'employeur, la commission des accidents
        ' du travail et, dans un territoire, l'impôt sur la paie. Rien de cela ne passe par l'ARC.
        Dim horsRemise = ServiceRemise.HorsRemiseProvinces(Annee)
        Dim codes = horsRemise.Rows.Cast(Of DataRow)().Select(Function(r) r.Txt("Province")).ToList()
        If Contexte.HorsQuebec AndAlso Annee = Date.Today.Year AndAlso Not codes.Contains(Provinces.Code(Contexte.Province)) Then codes.Add(Provinces.Code(Contexte.Province))
        For Each code In codes
            If Not Provinces.EstGeree(code) Then Continue For
            Dim r = horsRemise.Rows.Cast(Of DataRow)().FirstOrDefault(Function(x) x.Txt("Province") = code)
            Dim noms = LibellesProvince.Pour(code)
            Dim territoire = noms.ARetenueTerritoriale OrElse (r IsNot Nothing AndAlso r.Dcm("ImpotPaie") <> 0D)
            sb.Append("<div class=""carte""><h2>").Append(HttpUtility.HtmlEncode(Provinces.Nom(noms.Province) & " : montants hors remises")).Append("</h2><table class=""liste""><tbody>")
            If territoire Then
                Ligne(sb, "Rémunération assujettie à l'impôt sur la paie", If(r Is Nothing, 0D, r.Dcm("GainsImpotPaie")))
                Ligne(sb, "Impôt sur la paie retenu aux employés", If(r Is Nothing, 0D, r.Dcm("ImpotPaie")))
            End If
            If noms.ASante OrElse (r IsNot Nothing AndAlso r.Dcm("Sante") <> 0D) Then
                Ligne(sb, noms.Sante & " - rémunération assujettie", If(r Is Nothing, 0D, r.Dcm("MasseSante")))
                Ligne(sb, noms.Sante & " - montant calculé sur les paies", If(r Is Nothing, 0D, r.Dcm("Sante")))
            End If
            Ligne(sb, "Gains assurables " & noms.Accidents, If(r Is Nothing, 0D, r.Dcm("AssurableAccidents")))
            Ligne(sb, "Prime " & noms.Accidents & " calculée sur les paies", If(r Is Nothing, 0D, r.Dcm("Accidents")))
            sb.Append("</tbody></table>")
            If territoire Then
                sb.Append("<p class=""note"">L'impôt sur la paie se déclare et se remet au gouvernement du territoire. Il n'est pas compris dans la case 22 du T4.</p>")
            End If
            If noms.ASante Then
                sb.Append("<p class=""note"">La cotisation santé de l'employeur se déclare à l'administration de la province : le taux et l'exemption réels s'établissent sur la rémunération totale de l'année.</p>")
            End If
            sb.Append("<p class=""note"">La prime se déclare à la commission des accidents du travail selon votre fréquence. Rien de cela ne passe par l'ARC.</p></div>")
        Next
        If Not quebecAussi Then Return sb.Append("</div>").ToString()

        sb.Append("<div class=""carte""><h2>Sommaire 1 (Revenu Québec)</h2><table class=""liste""><tbody>")
        Ligne(sb, "RRQ - employés", rrqEmployes)
        Ligne(sb, "RRQ - employeur", s.Dcm("EmployeurRRQ"))
        Ligne(sb, "RQAP - employés", rqapEmployes)
        Ligne(sb, "RQAP - employeur", s.Dcm("EmployeurRQAP"))
        Ligne(sb, "Salaires assujettis au FSS", s.Dcm("MasseFSS"))
        Ligne(sb, "Cotisation au FSS", s.Dcm("FSS"))
        Ligne(sb, "CNESST - versements périodiques calculés", s.Dcm("CNESST"))
        Ligne(sb, "Retenues et cotisations de l'année", s.Dcm("DuQuebec"))
        Ligne(sb, "Remises enregistrées", s.Dcm("PayeQuebec"))
        Ligne(sb, "Solde à payer", s.Dcm("DuQuebec") - s.Dcm("PayeQuebec"))
        Ligne(sb, "Cotisation aux normes du travail (CNT), payable avec le sommaire 1", s.Dcm("CNT"))
        sb.Append("</tbody></table><p class=""note"">Le taux réel du FSS est établi sur la masse salariale totale de l'année : " &
                  "un écart avec le taux estimé utilisé pendant l'année se règle dans le sommaire 1.</p></div>")
        Return sb.Append("</div>").ToString()
    End Function

    Private Shared Sub Ligne(sb As StringBuilder, libelle As String, montant As Decimal)
        sb.Append("<tr><td>").Append(HttpUtility.HtmlEncode(libelle)).Append("</td><td class=""num"">").Append(Argent(montant)).Append("</td></tr>")
    End Sub

    ''' <summary>Date d'envoi des feuillets de l'année par employé (paie.FeuilletEnvoi).</summary>
    Private Function EnvoisDeLAnnee() As Dictionary(Of Integer, Date)
        Dim d As New Dictionary(Of Integer, Date)()
        For Each r As DataRow In Db.Table("paie.spFeuilletEnvoi_Annee", Db.P("@c", Contexte.CompagnieId), Db.P("@a", Annee)).Rows
            d(r.Ent("EmployeId")) = Convert.ToDateTime(r("EnvoyeLe"))
        Next
        Return d
    End Function

    ''' <summary>Tous les feuillets de l'année, copie de l'employeur, en un seul PDF. Le NAS y est complet : le téléchargement est inscrit au journal.</summary>
    Private Sub btnPdfTous_Click(sender As Object, e As EventArgs) Handles btnPdfTous.Click
        Dim feuillets = ServiceFeuillets.Preparer(Annee)
        If feuillets.Count = 0 Then
            Erreur("Aucun feuillet pour cette année.")
            Return
        End If
        Dim compagnie = Db.Ligne("paie.spCompagnie_Get", Db.P("@c", Contexte.CompagnieId))
        Contexte.Journaliser("Feuillets " & Annee.ToString() & " téléchargés en PDF (copie de l'employeur, " & feuillets.Count.ToString() & " employé(s), NAS complet).", "~/Rapports/Feuillets.aspx")
        EnvoyerFichier(FeuilletPdf.NomFichier(Annee), FeuilletPdf.ProduireTous(feuillets, compagnie, Annee, CopieFeuillet.Employeur), "application/pdf")
    End Sub

    ''' <summary>Les copies du gouvernement : T4 et Sommaire T4 (ARC), Relevé 1 et Sommaire 1 (Revenu Québec), en un seul PDF. NAS complet : inscrit au journal.</summary>
    Private Sub btnPdfGouv_Click(sender As Object, e As EventArgs) Handles btnPdfGouv.Click
        Dim feuillets = ServiceFeuillets.Preparer(Annee)
        If feuillets.Count = 0 Then
            Erreur("Aucun feuillet pour cette année.")
            Return
        End If
        Dim compagnie = Db.Ligne("paie.spCompagnie_Get", Db.P("@c", Contexte.CompagnieId))
        Contexte.Journaliser("Feuillets " & Annee.ToString() & " téléchargés en PDF (copies du gouvernement avec les sommaires, " & feuillets.Count.ToString() & " employé(s), NAS complet).", "~/Rapports/Feuillets.aspx")
        EnvoyerFichier(FeuilletPdf.NomFichier(Annee, Nothing, CopieFeuillet.Gouvernement),
                       FeuilletPdf.ProduireGouvernement(feuillets, compagnie, Annee, ServiceFeuillets.SommaireEmployeur(Annee)), "application/pdf")
    End Sub

    Private Sub btnCourriels_Click(sender As Object, e As EventArgs) Handles btnCourriels.Click
        Try
            Dim bilan = ServiceCourriel.EnvoyerFeuillets(Annee, chkRenvoyer.Checked)
            Dim message = bilan.Envoyes.ToString() & " feuillet(s) envoyé(s)"
            If bilan.DejaEnvoyes > 0 Then message &= ", " & bilan.DejaEnvoyes.ToString() & " déjà envoyé(s)"
            If bilan.Erreurs.Count > 0 Then
                Erreur(message & ". Problèmes : " & String.Join(" ", bilan.Erreurs))
            Else
                Succes(message & ".")
            End If
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub btnCsv_Click(sender As Object, e As EventArgs) Handles btnCsv.Click
        Dim lignes As New List(Of String())()
        Dim entete As New List(Of String) From {"Code", "Nom", "Prénom"}
        entete.Add("Province d'emploi")
        entete.AddRange(ServiceFeuillets.LibellesT4.Select(Function(c) "T4 case " & c.Key))
        entete.AddRange(ServiceFeuillets.LibellesR1.Select(Function(c) "R1 case " & c.Key))
        lignes.Add(entete.ToArray())

        ' Le NAS n'est volontairement pas exporté.
        For Each f In ServiceFeuillets.Preparer(Annee)
            Dim ligne As New List(Of String) From {f.Employe.Txt("Code"), f.Employe.Txt("Nom"), f.Employe.Txt("Prenom"), f.Province}
            ligne.AddRange(ServiceFeuillets.LibellesT4.Select(Function(c) f.CaseT4(c.Key).ToString("0.00", FrCa)))
            ligne.AddRange(ServiceFeuillets.LibellesR1.Select(Function(c) f.CaseR1(c.Key).ToString("0.00", FrCa)))
            lignes.Add(ligne.ToArray())
        Next
        EnvoyerCsv("feuillets-" & Annee.ToString() & ".csv", lignes)
    End Sub

End Class
