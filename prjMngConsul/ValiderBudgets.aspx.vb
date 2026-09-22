Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Les budgets, lus par la passerelle (entité Budget). Le budget choisi passe
''' par la requête (?budget=Id) : ses lignes s'affichent sous la liste,
''' groupées par compte. Contrôle seulement.
''' </summary>
Public Class ValiderBudgets
    Inherits clsData

    Private Shared ReadOnly Fr As Globalization.CultureInfo = Globalization.CultureInfo.GetCultureInfo("fr-CA")

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If
        Afficher()
    End Sub

    Private Sub Afficher()
        Dim choisi As Integer = 0
        Integer.TryParse(If(Request.QueryString("budget"), ""), choisi)

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@BudgetId", If(choisi > 0, CObj(choisi), CObj(DBNull.Value))))
        Dim ds As DataSet = ExecuteSQLds("s0852GetBudgets", p)

        If ds Is Nothing OrElse ds.Tables.Count < 2 OrElse ds.Tables(0).Rows.Count = 0 Then
            litLignes.Text = "" : litNote.Text = ""
            litListe.Text = "<div class=""rien"">Aucun budget en préparation." &
                            "<br />Le bouton <b>Importer depuis QuickBooks</b>, ci-dessus, les rapatrie en direct.</div>"
            Return
        End If

        ' Un seul budget : on le montre d'emblée, il n'y a rien à choisir.
        If choisi = 0 AndAlso ds.Tables(0).Rows.Count = 1 Then
            choisi = Convert.ToInt32(ds.Tables(0).Rows(0)("Id"))
            Dim p2 As New Collection
            p2.Add(New SqlParameter("@CompanyGUID", Company))
            p2.Add(New SqlParameter("@BudgetId", CObj(choisi)))
            ds = ExecuteSQLds("s0852GetBudgets", p2)
        End If

        litListe.Text = RendreListe(ds.Tables(0), choisi)
        litLignes.Text = If(choisi > 0, RendreLignes(ds.Tables(0), ds.Tables(1), choisi), "")
        litNote.Text = "<div class=""note"">Lus par la <b>passerelle</b> — l'API unifiée d'Apideck ne connaît pas les budgets. " &
                       "Chaque ligne porte le compte, la période et le montant ; quand la source ventile par client, " &
                       "classe ou département, c'est indiqué. Les comptes sont des noms : la correspondance avec le plan " &
                       "d'ici se fait à l'écran du plan comptable. Une nouvelle extraction remplace le tout.</div>"
    End Sub

    Private Function RendreListe(t As DataTable, choisi As Integer) As String
        Dim sb As New StringBuilder()
        sb.Append("<h2 class=""sect"">Les budgets <span>cliquez pour voir les lignes</span></h2>")
        sb.Append("<table class=""lst""><thead><tr><th>Nom</th><th>Type</th><th>Période</th><th>Saisie</th>")
        sb.Append("<th style=""text-align:right"">Lignes</th><th style=""text-align:right"">Total</th><th>État</th></tr></thead><tbody>")

        For Each r As DataRow In t.Rows
            Dim id As Integer = Convert.ToInt32(r("Id"))
            Dim statut As String = Texte(r, "Statut")
            Dim actif As Boolean = IsDBNull(r("Actif")) OrElse Convert.ToBoolean(r("Actif"))
            sb.Append("<tr")
            If statut <> "NOUVEAU" Then
                sb.Append(" class=""souci""")
            ElseIf id = choisi Then
                sb.Append(" class=""on""")
            End If
            sb.Append(">")
            sb.Append("<td><a href=""ValiderBudgets.aspx?budget=").Append(id).Append(""">").Append(Server.HtmlEncode(Texte(r, "Nom"))).Append("</a></td>")
            sb.Append("<td>").Append(Server.HtmlEncode(TypeBudget(Texte(r, "TypeBudget")))).Append("</td>")
            sb.Append("<td class=""cle"">").Append(DateTexte(r, "DateDebut")).Append(" → ").Append(DateTexte(r, "DateFin")).Append("</td>")
            sb.Append("<td>").Append(Server.HtmlEncode(Saisie(Texte(r, "TypeSaisie")))).Append("</td>")
            sb.Append("<td class=""n"">").Append(Convert.ToString(r("NbLignes"))).Append("</td>")
            sb.Append("<td class=""n"">").Append(If(IsDBNull(r("Total")), "", Convert.ToDecimal(r("Total")).ToString("N2", Fr) & " $")).Append("</td>")
            sb.Append("<td>")
            If statut <> "NOUVEAU" Then
                sb.Append("<span class=""verdict INVALIDE"">Inutilisable</span>")
            Else
                sb.Append("<span class=""verdict ").Append(If(actif, "on", "off")).Append(""">").Append(If(actif, "Actif", "Inactif")).Append("</span>")
            End If
            If Texte(r, "Anomalie") <> "" Then sb.Append("<div class=""cle"">").Append(Server.HtmlEncode(Texte(r, "Anomalie"))).Append("</div>")
            sb.Append("</td></tr>")
        Next

        sb.Append("</tbody></table>")
        Return sb.ToString()
    End Function

    ''' <summary>Les lignes du budget choisi, par compte, avec le total de chaque compte.</summary>
    Private Function RendreLignes(entetes As DataTable, lignes As DataTable, choisi As Integer) As String
        Dim nom As String = ""
        For Each r As DataRow In entetes.Rows
            If Convert.ToInt32(r("Id")) = choisi Then nom = Texte(r, "Nom")
        Next

        Dim sb As New StringBuilder()
        sb.Append("<h2 class=""sect"">").Append(Server.HtmlEncode(nom)).Append(" <span>").Append(lignes.Rows.Count).Append(" ligne(s)</span></h2>")

        If lignes.Rows.Count = 0 Then
            sb.Append("<div class=""rien"">Ce budget n'a aucune ligne.</div>")
            Return sb.ToString()
        End If

        Dim ventile As Boolean = False
        For Each l As DataRow In lignes.Rows
            If Texte(l, "TiersNom") <> "" OrElse Texte(l, "ClasseNom") <> "" OrElse Texte(l, "DepartementNom") <> "" Then
                ventile = True : Exit For
            End If
        Next

        sb.Append("<table class=""lst""><thead><tr><th>Compte</th>")
        If ventile Then sb.Append("<th>Ventilation</th>")
        sb.Append("<th>Période</th><th style=""text-align:right"">Montant</th></tr></thead><tbody>")

        Dim compteCourant As String = Nothing
        Dim sousTotal As Decimal = 0, total As Decimal = 0

        For Each l As DataRow In lignes.Rows
            Dim compte As String = Texte(l, "CompteNom")
            If compteCourant IsNot Nothing AndAlso compte <> compteCourant Then
                sb.Append("<tr class=""total""><td colspan=""").Append(If(ventile, 3, 2)).Append(""">").Append(Server.HtmlEncode(compteCourant)).Append("</td>")
                sb.Append("<td class=""n"">").Append(sousTotal.ToString("N2", Fr)).Append(" $</td></tr>")
                sousTotal = 0
            End If
            compteCourant = compte

            Dim montant As Decimal = If(IsDBNull(l("Montant")), 0D, Convert.ToDecimal(l("Montant")))
            sousTotal += montant : total += montant

            sb.Append("<tr><td>").Append(Montrer(compte)).Append("</td>")
            If ventile Then
                Dim bouts As New List(Of String)
                If Texte(l, "TiersNom") <> "" Then bouts.Add(Texte(l, "TiersNom"))
                If Texte(l, "ClasseNom") <> "" Then bouts.Add("classe " & Texte(l, "ClasseNom"))
                If Texte(l, "DepartementNom") <> "" Then bouts.Add(Texte(l, "DepartementNom"))
                sb.Append("<td>").Append(If(bouts.Count = 0, "<span class=""vide"">—</span>", Server.HtmlEncode(String.Join(" · ", bouts)))).Append("</td>")
            End If
            sb.Append("<td class=""cle"">").Append(DateTexte(l, "DateLigne")).Append("</td>")
            sb.Append("<td class=""n"">").Append(montant.ToString("N2", Fr)).Append(" $</td></tr>")
        Next

        If compteCourant IsNot Nothing Then
            sb.Append("<tr class=""total""><td colspan=""").Append(If(ventile, 3, 2)).Append(""">").Append(Server.HtmlEncode(compteCourant)).Append("</td>")
            sb.Append("<td class=""n"">").Append(sousTotal.ToString("N2", Fr)).Append(" $</td></tr>")
        End If
        sb.Append("<tr class=""total""><td colspan=""").Append(If(ventile, 3, 2)).Append(""">Total du budget</td>")
        sb.Append("<td class=""n"">").Append(total.ToString("N2", Fr)).Append(" $</td></tr>")
        sb.Append("</tbody></table>")
        Return sb.ToString()
    End Function

    Private Shared Function TypeBudget(t As String) As String
        Select Case t
            Case "ProfitAndLoss" : Return "Résultats"
            Case "BalanceSheet" : Return "Bilan"
            Case Else : Return t
        End Select
    End Function

    Private Shared Function Saisie(t As String) As String
        Select Case t
            Case "Monthly" : Return "par mois"
            Case "Quarterly" : Return "par trimestre"
            Case "Yearly" : Return "par année"
            Case Else : Return t
        End Select
    End Function

    Private Shared Function DateTexte(r As DataRow, champ As String) As String
        If IsDBNull(r(champ)) Then Return "<span class=""vide"">—</span>"
        Return Convert.ToDateTime(r(champ)).ToString("yyyy-MM-dd")
    End Function

    Private Function Montrer(valeur As String) As String
        If valeur = "" Then Return "<span class=""vide"">—</span>"
        Return Server.HtmlEncode(valeur)
    End Function

    Private Shared Function Texte(r As DataRow, champ As String) As String
        If IsDBNull(r(champ)) Then Return ""
        Return Convert.ToString(r(champ))
    End Function

End Class
