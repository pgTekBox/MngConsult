Imports System.Data.SqlClient
Imports System.Globalization
Imports System.IO
Imports System.Text

''' <summary>
''' Les codes et taux de taxe de la reprise (staging.TaxeImport).
'''
''' Chaque ligne de facture reprise porte un CODE de taxe de l'ancien logiciel
''' (« 8 », « TPS », « NON »…), jamais le montant. La répartition (s0794) coupe
''' les taxes ligne par ligne d'après ce que ce tableau dit du code : tant de
''' TPS, tant de TVQ. Sans taux connu, elle retombe sur les taux du Québec quand
''' le document entier s'y prête, et laisse le reste vide.
'''
''' L'écran montre ce qui a été rapatrié, compte les lignes qui s'en servent,
''' signale les codes que les lignes portent sans qu'aucun taux ne les décrive,
''' et permet d'ajouter ou de corriger un taux à la main ou par fichier. Ce que
''' l'utilisateur saisit survit au prochain rapatriement QuickBooks (T291).
'''
''' Rien ici ne touche les taxes de la comptabilité de l'application.
''' </summary>
Public Class ValiderTaxes
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ' Les boutons « Modifier » et « Retirer » du tableau sont des <button>
        ' natifs nommés « act » : ils reviennent ici, avant les gestionnaires
        ' des asp:Button.
        If IsPostBack Then
            Dim act As String = If(Request.Form("act"), "")
            If act.StartsWith("edit:") Then
                PreparerEdition(act.Substring(5))
            ElseIf act.StartsWith("del:") Then
                Retirer(act.Substring(4))
            ElseIf act.StartsWith("add:") Then
                PreparerAjout(act.Substring(4))
            End If
        End If

        Afficher()
    End Sub

    ' =========================================================================
    ' LES ACTIONS
    ' =========================================================================

    ''' <summary>Le tableau demande à corriger un taux : le formulaire se remplit.</summary>
    Private Sub PreparerEdition(idTexte As String)
        Dim id As Integer
        If Not Integer.TryParse(idTexte, id) Then Return

        Dim ds As DataSet = Lire()
        If ds Is Nothing OrElse ds.Tables.Count < 2 Then Return
        For Each r As DataRow In ds.Tables(1).Rows
            If Convert.ToInt32(r("Id")) = id Then
                hfId.Value = id.ToString()
                txtCode.Text = Txt(r("Code"))
                txtNom.Text = Txt(r("Nom"))
                txtTPS.Text = Pct(r("TauxTPS"))
                txtTVQ.Text = Pct(r("TauxTVQ"))
                litTitreForm.Text = "Corriger le taux « " & H(Txt(r("Nom"))) & " »"
                btnAnnuler.Visible = True
                Exit For
            End If
        Next
    End Sub

    ''' <summary>Un code inconnu demande à être décrit : le formulaire se prépare avec lui.</summary>
    Private Sub PreparerAjout(code As String)
        hfId.Value = ""
        txtCode.Text = code
        txtNom.Text = ""
        txtTPS.Text = "5"
        txtTVQ.Text = "9,975"
        litTitreForm.Text = "Décrire le code « " & H(code) & " »"
        btnAnnuler.Visible = True
    End Sub

    Private Sub Retirer(idTexte As String)
        Dim id As Integer
        If Not Integer.TryParse(idTexte, id) Then Return
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Id", CObj(id)))
            ExecuteSQL("s0873DeleteTaxeImport", p)
            Message("Taux retiré. Les lignes qui portaient son code ne se répartiront plus ligne par ligne tant qu'un autre taux ne le décrit pas.", "info")
        Catch ex As Exception
            Message("Le retrait a échoué : " & ex.Message, "err")
        End Try
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        Dim tps As Decimal, tvq As Decimal
        If Not LirePct(txtTPS.Text, tps) OrElse Not LirePct(txtTVQ.Text, tvq) Then
            Message("Les taux doivent être des pourcentages entre 0 et 100 (par exemple 5 et 9,975).", "err")
            Afficher()
            Return
        End If

        Try
            Dim r As DataRow = Enregistrer(hfId.Value, txtCode.Text, txtNom.Text, tps, tvq, "MANUEL")
            Dim action As String = If(r Is Nothing, "", Txt(r("Action")))
            Message(If(action = "CREE", "Taux ajouté : « ", "Taux corrigé : « ") & txtCode.Text.Trim() & " » = TPS " &
                    Pct(tps) & " % + TVQ " & Pct(tvq) & " %. Cliquez « Répartir les taxes des factures maintenant » pour l'appliquer aux factures en préparation.", "ok")
            ViderFormulaire()
        Catch ex As Exception
            Message("L'enregistrement a échoué : " & ex.Message, "err")
        End Try
        Afficher()
    End Sub

    Protected Sub btnAnnuler_Click(sender As Object, e As EventArgs) Handles btnAnnuler.Click
        ViderFormulaire()
        Afficher()
    End Sub

    ''' <summary>
    ''' Un fichier texte, une taxe par ligne : code ; nom ; TPS % ; TVQ %.
    ''' Séparateur point-virgule, virgule ou tabulation ; l'en-tête est ignoré.
    ''' </summary>
    Protected Sub btnImporter_Click(sender As Object, e As EventArgs) Handles btnImporter.Click
        If Not fuFichier.HasFile Then
            Message("Choisissez d'abord un fichier .csv ou .txt.", "err")
            Afficher()
            Return
        End If

        Dim crees As Integer = 0, corriges As Integer = 0, ignorees As Integer = 0
        Dim erreurs As New List(Of String)
        Try
            Dim texte As String
            Using lecteur As New StreamReader(fuFichier.FileContent, Encoding.UTF8, True)
                texte = lecteur.ReadToEnd()
            End Using

            Dim noLigne As Integer = 0
            For Each brute As String In texte.Split(New String() {vbCrLf, vbLf, vbCr}, StringSplitOptions.RemoveEmptyEntries)
                noLigne += 1
                Dim ligne As String = brute.Trim()
                If ligne = "" Then Continue For

                Dim sep As Char = If(ligne.Contains(";"), ";"c, If(ligne.Contains(vbTab), vbTab(0), ","c))
                Dim cols As String() = ligne.Split(sep).Select(Function(c) c.Trim().Trim(""""c)).ToArray()
                If cols.Length < 3 Then
                    ignorees += 1
                    Continue For
                End If

                Dim tps As Decimal, tvq As Decimal
                Dim tvqTexte As String = If(cols.Length > 3, cols(3), "0")
                If Not LirePct(cols(2), tps) OrElse Not LirePct(tvqTexte, tvq) Then
                    ' La ligne d'en-tête tombe ici, sans bruit.
                    If noLigne > 1 Then erreurs.Add("ligne " & noLigne & " : taux illisibles")
                    ignorees += 1
                    Continue For
                End If

                Dim r As DataRow = Enregistrer("", cols(0), cols(1), tps, tvq, "FICHIER")
                If r IsNot Nothing AndAlso Txt(r("Action")) = "CREE" Then crees += 1 Else corriges += 1
            Next
        Catch ex As Exception
            Message("Le chargement a échoué : " & ex.Message, "err")
            Afficher()
            Return
        End Try

        Dim sb As New StringBuilder()
        sb.Append(crees).Append(" taux ajouté(s), ").Append(corriges).Append(" corrigé(s)")
        If ignorees > 0 Then sb.Append(", ").Append(ignorees).Append(" ligne(s) ignorée(s)")
        sb.Append(".")
        If erreurs.Count > 0 Then sb.Append(" ").Append(String.Join(" · ", erreurs.Take(5)))
        Message(sb.ToString(), If(crees + corriges > 0, "ok", "err"))
        Afficher()
    End Sub

    ''' <summary>La répartition des factures, ici même : la même s0794 que l'écran Factures.</summary>
    Protected Sub btnRepartir_Click(sender As Object, e As EventArgs) Handles btnRepartir.Click
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0794RepartirTaxesImport", p)

            Dim coupes As Integer = 0, defaut As Integer = 0, restants As Integer = 0
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                coupes = Ent(r("NbLignesCoupees")) + Ent(r("NbLignesParCode")) + Ent(r("NbDocumentsParTotal"))
                defaut = Ent(r("NbParDefaut")) + Ent(r("NbLignesParDefaut"))
                restants = Ent(r("NbSansRepartition"))
            End If

            Dim sb As New StringBuilder()
            If coupes + defaut = 0 Then
                sb.Append("Rien à répartir : les taxes des factures sont déjà réparties, ou aucun document ne porte de taxes.")
            Else
                sb.Append("Taxes réparties sur ").Append(coupes + defaut).Append(" élément(s)")
                If defaut > 0 Then sb.Append(", dont ").Append(defaut).Append(" aux taux du Québec faute de taux connu")
                sb.Append(".")
            End If
            If restants > 0 Then sb.Append(" ").Append(restants).Append(" document(s) restent sans répartition : décrivez leurs codes ci-dessous, ou saisissez TPS et TVQ dans l'écran Factures.")
            Message(sb.ToString(), If(restants > 0, "info", "ok"))
        Catch ex As Exception
            Message("La répartition a échoué : " & ex.Message, "err")
        End Try
        Afficher()
    End Sub

    Private Function Enregistrer(idTexte As String, code As String, nom As String, tps As Decimal, tvq As Decimal, origine As String) As DataRow
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim id As Integer
        p.Add(New SqlParameter("@Id", If(Integer.TryParse(idTexte, id), CObj(id), DBNull.Value)))
        p.Add(New SqlParameter("@Code", code.Trim()))
        p.Add(New SqlParameter("@Nom", If(nom.Trim() = "", CObj(DBNull.Value), nom.Trim())))
        p.Add(New SqlParameter("@TauxTPS", tps))
        p.Add(New SqlParameter("@TauxTVQ", tvq))
        p.Add(New SqlParameter("@Origine", origine))
        Dim ds As DataSet = ExecuteSQLds("s0872SaveTaxeImport", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return Nothing
        Return ds.Tables(0).Rows(0)
    End Function

    Private Sub ViderFormulaire()
        hfId.Value = ""
        txtCode.Text = ""
        txtNom.Text = ""
        txtTPS.Text = "5"
        txtTVQ.Text = "9,975"
        litTitreForm.Text = "Ajouter ou corriger un taux"
        btnAnnuler.Visible = False
    End Sub

    ' =========================================================================
    ' L'AFFICHAGE
    ' =========================================================================

    Private Function Lire() As DataSet
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Return ExecuteSQLds("s0871GetTaxesImportEcran", p)
    End Function

    Private Sub Afficher()
        Dim ds As DataSet
        Try
            ds = Lire()
        Catch ex As Exception
            litTableau.Text = "<div class='rien'>Les taux n'ont pas pu être lus : " & H(ex.Message) & "</div>"
            Return
        End Try

        If ds Is Nothing OrElse ds.Tables.Count < 3 Then
            litTableau.Text = Vide()
            Return
        End If

        litRepere.Text = Repere(ds.Tables(0).Rows(0))
        litInconnus.Text = Inconnus(ds.Tables(2))
        litTableau.Text = If(ds.Tables(1).Rows.Count = 0, Vide(), Tableau(ds.Tables(1)))
        litNote.Text = Note()
    End Sub

    Private Function Repere(r As DataRow) As String
        Dim sb As New StringBuilder("<div class='repere'>")
        sb.Append(Bloc("Taux connus", Txt(r("NbTaux")), ""))
        sb.Append(Bloc("Répartissables", Txt(r("NbReconnues")), ""))
        sb.Append(Bloc("À vérifier", Txt(r("NbAVerifier")), If(Ent(r("NbAVerifier")) > 0, "mi", "")))
        sb.Append(Bloc("Saisis ici", Txt(r("NbManuels")), ""))
        sb.Append(Bloc("Codes inconnus", Txt(r("NbCodesInconnus")), If(Ent(r("NbCodesInconnus")) > 0, "no", "")))
        sb.Append(Bloc("Dernier rapatriement", Instant(r("DerniereExtraction")), ""))
        Return sb.Append("</div>").ToString()
    End Function

    Private Shared Function Bloc(libelle As String, valeur As String, genre As String) As String
        Return "<div class='bloc " & genre & "'><div class='l'>" & H(libelle) & "</div><div class='v'>" &
               H(If(valeur <> "", valeur, "—")) & "</div></div>"
    End Function

    ''' <summary>
    ''' Les codes que les lignes de factures portent sans qu'aucun taux ne les
    ''' décrive : c'est la première chose à régler, et un bouton prépare la saisie.
    ''' </summary>
    Private Function Inconnus(codes As DataTable) As String
        If codes.Rows.Count = 0 Then Return ""
        Dim sb As New StringBuilder("<table class='tx'><thead><tr>")
        sb.Append("<th>Code inconnu des taux</th><th class='n'>Lignes de factures</th><th class='n'>Dont sans taxes</th><th></th>")
        sb.Append("</tr></thead><tbody>")
        For Each r As DataRow In codes.Rows
            Dim code As String = Txt(r("Code"))
            sb.Append("<tr class='inconnu'><td class='nom'><span class='etiq inconnu'>inconnu</span> ").Append(H(code))
            sb.Append("<span class='fil' style='display:block'>Aucun taux ne décrit ce code : ses lignes ne se répartissent pas ligne par ligne.</span></td>")
            sb.Append("<td class='n'>").Append(Txt(r("NbLignes"))).Append("</td>")
            sb.Append("<td class='n'>").Append(Txt(r("NbSansTaxes"))).Append("</td>")
            sb.Append("<td><button type='submit' class='btn petit' name='act' value='add:").Append(H(code)).Append("'>Décrire ce code</button></td></tr>")
        Next
        Return sb.Append("</tbody></table>").ToString()
    End Function

    ''' <summary>
    ''' Le paramètre ne s'appelle pas « taux » : VB ignore la casse, et un
    ''' paramètre homonyme de la fonction CelluleTaux l'avalerait (les cellules
    ''' de taux disparaissaient sans erreur — c'est arrivé ici).
    ''' </summary>
    Private Function Tableau(listeTaux As DataTable) As String
        Dim sb As New StringBuilder("<table class='tx'><thead><tr>")
        sb.Append("<th>Code</th><th>Nom</th><th class='n'>Taux total</th><th class='n'>TPS %</th><th class='n'>TVQ %</th>")
        sb.Append("<th class='n'>Autre %</th><th>Composantes</th><th class='n'>Lignes</th><th>Origine</th><th>État</th><th></th>")
        sb.Append("</tr></thead><tbody>")

        For Each r As DataRow In listeTaux.Rows
            Dim statut As String = Txt(r("Statut"))
            Dim origine As String = Txt(r("Origine"))
            sb.Append("<tr").Append(If(statut = "A_VERIFIER", " class='verif'", "")).Append(">")

            Dim code As String = Txt(r("Code")), externe As String = Txt(r("ExterneId"))
            sb.Append("<td class='nom'>").Append(H(code))
            If externe <> "" AndAlso externe <> code Then sb.Append("<span class='fil' style='display:block'>id source : ").Append(H(externe)).Append("</span>")
            sb.Append("</td>")

            sb.Append("<td>").Append(H(Txt(r("Nom"))))
            Dim desc As String = Txt(r("Description"))
            If desc <> "" Then sb.Append("<span class='fil' style='display:block'>").Append(H(desc)).Append("</span>")
            sb.Append("</td>")

            sb.Append(CelluleTaux(r("TauxTotal"))).Append(CelluleTaux(r("TauxTPS"))).Append(CelluleTaux(r("TauxTVQ"))).Append(CelluleTaux(r("TauxAutre")))
            sb.Append("<td class='fil'>").Append(H(Composantes(Txt(r("Composantes"))))).Append("</td>")

            Dim nb As Integer = Ent(r("NbLignes"))
            sb.Append("<td class='n").Append(If(nb = 0, " zero", "")).Append("'>").Append(nb).Append("</td>")

            sb.Append("<td>")
            Select Case origine
                Case "MANUEL" : sb.Append("<span class='etiq man'>saisi ici</span>")
                Case "FICHIER" : sb.Append("<span class='etiq man'>fichier</span>")
                Case Else : sb.Append("<span class='etiq src'>QuickBooks</span>")
            End Select
            sb.Append("</td>")

            sb.Append("<td>")
            If statut = "A_VERIFIER" Then
                sb.Append("<span class='etiq verif'>à vérifier</span>")
            ElseIf Dec(r("TauxTPS")) + Dec(r("TauxTVQ")) > 0 Then
                sb.Append("<span class='etiq ok'>répartissable</span>")
            Else
                sb.Append("<span class='etiq ok'>sans taxe</span>")
            End If
            Dim anom As String = Txt(r("Anomalie"))
            If anom <> "" Then sb.Append("<span class='anom'>").Append(H(anom)).Append("</span>")
            sb.Append("</td>")

            Dim id As String = Txt(r("Id"))
            sb.Append("<td style='white-space:nowrap'>")
            sb.Append("<button type='submit' class='btn petit' name='act' value='edit:").Append(id).Append("'>Corriger</button> ")
            sb.Append("<button type='submit' class='btn petit danger' name='act' value='del:").Append(id)
            sb.Append("' onclick=""if (!confirm('Retirer ce taux ?')) { return false; }"">Retirer</button>")
            sb.Append("</td></tr>")
        Next

        Return sb.Append("</tbody></table>").ToString()
    End Function

    ''' <summary>Les composantes brutes, lisibles : « TPS 5 % + TVQ 9,975 % ».</summary>
    Private Shared Function Composantes(json As String) As String
        If json = "" OrElse json = "[]" Then Return "—"
        Try
            Dim liste As New List(Of String)
            For Each m As Text.RegularExpressions.Match In Text.RegularExpressions.Regex.Matches(json, """(?:nom|name)""\s*:\s*""([^""]*)""[^}]*?""(?:taux|rate)""\s*:\s*""?([0-9.,\-]+)""?")
                liste.Add(m.Groups(1).Value & " " & Pct(Decimal.Parse(m.Groups(2).Value.Replace(",", "."), CultureInfo.InvariantCulture)) & " %")
            Next
            Return If(liste.Count = 0, json, String.Join(" + ", liste))
        Catch
            Return json
        End Try
    End Function

    Private Shared Function CelluleTaux(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "<td class='n zero'>—</td>"
        Dim d As Decimal = Convert.ToDecimal(v)
        Return "<td class='n" & If(d = 0D, " zero", "") & "'>" & Pct(d) & "</td>"
    End Function

    Private Shared Function Note() As String
        Return "<div class='note'>Ces taux ne servent qu'à <b>répartir les factures en préparation</b> : " &
               "ils ne créent ni ne modifient les taxes de votre comptabilité. Un nouveau rapatriement " &
               "QuickBooks remplace les taux venus de QuickBooks et <b>garde</b> ceux saisis ici ou " &
               "chargés par fichier. Après un ajout ou une correction, cliquez « Répartir les taxes " &
               "des factures maintenant », ou le bouton du même nom dans l'écran Factures.</div>"
    End Function

    Private Shared Function Vide() As String
        Return "<div class='rien'>Aucun taux de taxe en préparation.<br />" &
               "Rapatriez-les avec le bouton QuickBooks ci-dessus (il ne rapatrie que les taxes), " &
               "ou saisissez-les ci-dessous : pour le Québec, un code « TPS/TVQ » vaut TPS 5 et TVQ 9,975.</div>"
    End Function

    Private Sub Message(texte As String, genre As String)
        litMsg.Text = "<div class='msg " & genre & "'>" & H(texte) & "</div>"
    End Sub

    ' =========================================================================
    ' PETITS OUTILS
    ' =========================================================================

    Private Shared ReadOnly FrCa As CultureInfo = CultureInfo.GetCultureInfo("fr-CA")

    Private Shared Function H(texte As String) As String
        Return HttpUtility.HtmlEncode(If(texte, ""))
    End Function

    Private Shared Function Txt(v As Object) As String
        Return If(v Is Nothing OrElse IsDBNull(v), "", Convert.ToString(v))
    End Function

    Private Shared Function Ent(v As Object) As Integer
        Return If(v Is Nothing OrElse IsDBNull(v), 0, Convert.ToInt32(v))
    End Function

    Private Shared Function Dec(v As Object) As Decimal
        Return If(v Is Nothing OrElse IsDBNull(v), 0D, Convert.ToDecimal(v))
    End Function

    ''' <summary>Un pourcentage sans zéros inutiles : 5, 9,975, 14,975.</summary>
    Private Shared Function Pct(v As Object) As String
        Dim d As Decimal = Dec(v)
        Return d.ToString("0.####", FrCa)
    End Function

    ''' <summary>« 9,975 », « 9.975 », « 9,975 % » : tout se lit.</summary>
    Private Shared Function LirePct(texte As String, ByRef valeur As Decimal) As Boolean
        Dim t As String = If(texte, "").Replace("%", "").Replace(" ", "").Trim()
        If t = "" Then valeur = 0D : Return True
        If Decimal.TryParse(t.Replace(",", "."), NumberStyles.Number, CultureInfo.InvariantCulture, valeur) Then
            Return valeur >= 0D AndAlso valeur <= 100D
        End If
        Return False
    End Function

    Private Shared Function Instant(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "—"
        Return Convert.ToDateTime(v).ToString("d MMM yyyy 'à' HH:mm", FrCa)
    End Function

End Class
