Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Les transactions récurrentes, lues par la passerelle (entité
''' RecurringTransaction). Contrôle seulement : on montre les modèles, leur
''' cadence et leur prochaine échéance ; rien n'est recréé ici.
''' </summary>
Public Class ValiderRecurrentes
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
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0850GetTransactionsRecurrentes", p)

        If ds Is Nothing OrElse ds.Tables.Count < 2 OrElse ds.Tables(1).Rows.Count = 0 Then
            litRepere.Text = "" : litNote.Text = ""
            litTableau.Text = "<div class=""rien"">Aucune transaction récurrente en préparation." &
                              "<br />Le bouton <b>Importer depuis QuickBooks</b>, ci-dessus, les rapatrie en direct.</div>"
            Return
        End If

        Dim s As DataRow = ds.Tables(0).Rows(0)
        Dim sb As New StringBuilder("<div class=""repere"">")
        sb.Append("<span><b>").Append(Convert.ToString(s("Nb"))).Append("</b> modèle(s)</span>")
        sb.Append("<span><b>").Append(Convert.ToString(s("NbActives"))).Append("</b> actif(s)</span>")
        If Not IsDBNull(s("Prochaine")) Then
            sb.Append("<span>prochaine échéance <b>").Append(Convert.ToDateTime(s("Prochaine")).ToString("yyyy-MM-dd")).Append("</b></span>")
        End If
        sb.Append("</div>")
        litRepere.Text = sb.ToString()

        litTableau.Text = RendreTableau(ds.Tables(1))
        litNote.Text = "<div class=""note"">Lues par la <b>passerelle</b> — l'API unifiée d'Apideck ne connaît pas les modèles " &
                       "récurrents. Le modèle complet (lignes, comptes, taxes) est gardé en préparation avec chaque ligne. " &
                       "60Sec-AI n'a pas encore de transactions récurrentes : cette liste dit ce qu'il faudra recréer, et quand. " &
                       "Une nouvelle extraction remplace le tout.</div>"
    End Sub

    Private Function RendreTableau(t As DataTable) As String
        Dim sb As New StringBuilder()
        sb.Append("<table class=""lst""><thead><tr><th>Nom</th><th>Type</th><th>Cadence</th><th>Tiers</th>")
        sb.Append("<th style=""text-align:right"">Montant</th><th>Début</th><th>Prochaine</th><th>Fin</th><th>État</th></tr></thead><tbody>")

        For Each r As DataRow In t.Rows
            Dim statut As String = Texte(r, "Statut")
            Dim actif As Boolean = Not IsDBNull(r("Actif")) AndAlso Convert.ToBoolean(r("Actif"))
            sb.Append("<tr")
            If statut <> "NOUVEAU" Then
                sb.Append(" class=""souci""")
            ElseIf Not actif Then
                sb.Append(" class=""inactif""")
            End If
            sb.Append(">")
            sb.Append("<td><b>").Append(Server.HtmlEncode(Texte(r, "Nom"))).Append("</b></td>")
            sb.Append("<td>").Append(Server.HtmlEncode(TypeTxn(Texte(r, "TypeTxn")))).Append("</td>")
            sb.Append("<td>").Append(Server.HtmlEncode(Cadence(r))).Append("</td>")
            sb.Append("<td>").Append(Montrer(Texte(r, "TiersNom"))).Append("</td>")
            sb.Append("<td class=""n"">").Append(If(IsDBNull(r("Montant")), "", Convert.ToDecimal(r("Montant")).ToString("N2", Fr) & " $"))
            If Texte(r, "Devise") <> "" AndAlso Texte(r, "Devise") <> "CAD" Then sb.Append(" ").Append(Server.HtmlEncode(Texte(r, "Devise")))
            sb.Append("</td>")
            sb.Append("<td class=""cle"">").Append(DateTexte(r, "DateDebut")).Append("</td>")
            sb.Append("<td class=""cle"">").Append(DateTexte(r, "DateProchaine")).Append("</td>")
            sb.Append("<td class=""cle"">").Append(DateTexte(r, "DateFin")).Append("</td>")
            sb.Append("<td>")
            If statut <> "NOUVEAU" Then
                sb.Append("<span class=""verdict INVALIDE"">Inutilisable</span>")
            Else
                sb.Append("<span class=""verdict ").Append(If(actif, "on", "off")).Append(""">").Append(If(actif, "Actif", "Suspendu")).Append("</span>")
            End If
            If Texte(r, "Anomalie") <> "" Then sb.Append("<div class=""cle"">").Append(Server.HtmlEncode(Texte(r, "Anomalie"))).Append("</div>")
            sb.Append("</td></tr>")
        Next

        sb.Append("</tbody></table>")
        Return sb.ToString()
    End Function

    ''' <summary>« tous les mois, le 15 » — la cadence dite comme on la dirait.</summary>
    Private Shared Function Cadence(r As DataRow) As String
        Dim genre As String = Texte(r, "TypeRecurrence")
        Dim intervalle As String = Texte(r, "IntervalleType")
        Dim n As Integer = If(IsDBNull(r("NumIntervalle")), 1, Convert.ToInt32(r("NumIntervalle")))

        Dim base As String
        Select Case intervalle.ToLowerInvariant()
            Case "daily" : base = If(n <= 1, "chaque jour", "tous les " & n & " jours")
            Case "weekly" : base = If(n <= 1, "chaque semaine", "toutes les " & n & " semaines")
            Case "monthly" : base = If(n <= 1, "chaque mois", "tous les " & n & " mois")
            Case "yearly" : base = If(n <= 1, "chaque année", "tous les " & n & " ans")
            Case "" : base = ""
            Case Else : base = intervalle
        End Select

        If Texte(r, "JourDuMois") <> "" Then base &= ", le " & Texte(r, "JourDuMois")
        If Texte(r, "JourSemaine") <> "" Then base &= ", le " & Texte(r, "JourSemaine")

        Select Case genre.ToLowerInvariant()
            Case "automated" : Return If(base = "", "automatique", base & " (automatique)")
            Case "reminded" : Return If(base = "", "sur rappel", base & " (sur rappel)")
            Case "unscheduled" : Return "sans calendrier"
            Case Else : Return base
        End Select
    End Function

    Private Shared Function TypeTxn(t As String) As String
        Select Case t
            Case "Invoice" : Return "Facture client"
            Case "Bill" : Return "Facture fournisseur"
            Case "JournalEntry" : Return "Écriture de journal"
            Case "Purchase" : Return "Dépense"
            Case "SalesReceipt" : Return "Reçu de vente"
            Case "Estimate" : Return "Soumission"
            Case "CreditMemo" : Return "Note de crédit"
            Case "Deposit" : Return "Dépôt"
            Case "Transfer" : Return "Virement"
            Case "Payment" : Return "Encaissement"
            Case "BillPayment" : Return "Décaissement"
            Case "PurchaseOrder" : Return "Bon de commande"
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
