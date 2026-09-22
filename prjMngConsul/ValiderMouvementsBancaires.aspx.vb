Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Les dépôts et les virements bancaires, lus par la passerelle (entités
''' Deposit et Transfer de QuickBooks), avec les lignes des dépôts.
'''
''' Contrôle seulement : ni T140Reglement ni T142ReleveBancaire ne sont
''' touchées. Le genre choisi passe par la requête (?genre=Depot).
''' </summary>
Public Class ValiderMouvementsBancaires
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
        Dim genre As String = If(Request.QueryString("genre"), "").Trim()
        If genre <> "Depot" AndAlso genre <> "Virement" Then genre = ""

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Genre", If(genre = "", CObj(DBNull.Value), CObj(genre))))
        Dim ds As DataSet = ExecuteSQLds("s0848GetMouvementsBancaires", p)

        If ds Is Nothing OrElse ds.Tables.Count < 3 OrElse ds.Tables(0).Rows.Count = 0 Then
            litOnglets.Text = "" : litRepere.Text = "" : litNote.Text = ""
            litTableau.Text = "<div class=""rien"">Aucun dépôt ni virement en préparation." &
                              "<br />Le bouton <b>Importer depuis QuickBooks</b>, ci-dessus, les rapatrie en direct.</div>"
            Return
        End If

        litOnglets.Text = RendreOnglets(ds.Tables(0).Rows, genre)
        litRepere.Text = RendreRepere(ds.Tables(0).Rows)
        litTableau.Text = RendreTableau(ds.Tables(1), ds.Tables(2), genre)
        litNote.Text = "<div class=""note"">Lus par la <b>passerelle</b> — l'API unifiée d'Apideck ne connaît ni les " &
                       "dépôts ni les virements. Un dépôt porte ses lignes : chaque montant qui le compose, son compte de " &
                       "contrepartie, le tiers, le mode de paiement, et l'encaissement d'origine quand il y en a un. " &
                       "Une nouvelle extraction remplace le tout. Rien ne s'applique à la comptabilité.</div>"
    End Sub

    Private Function RendreOnglets(sommaire As DataRowCollection, choisi As String) As String
        Dim sb As New StringBuilder("<div class=""onglets"">")
        Dim total As Integer = 0
        For Each r As DataRow In sommaire
            total += Convert.ToInt32(r("Nb"))
        Next
        sb.Append("<a href=""ValiderMouvementsBancaires.aspx""").Append(If(choisi = "", " class=""on""", ""))
        sb.Append(">Tous <span class=""n"">").Append(total).Append("</span></a>")
        For Each r As DataRow In sommaire
            Dim g As String = Convert.ToString(r("Genre"))
            sb.Append("<a href=""ValiderMouvementsBancaires.aspx?genre=").Append(g).Append("""")
            If choisi = g Then sb.Append(" class=""on""")
            sb.Append(">").Append(Nommer(g)).Append(" <span class=""n"">").Append(Convert.ToString(r("Nb"))).Append("</span>")
            If Convert.ToInt32(r("NbSoucis")) > 0 Then sb.Append(" <span class=""souci"">").Append(r("NbSoucis")).Append(" ?</span>")
            sb.Append("</a>")
        Next
        sb.Append("</div>")
        Return sb.ToString()
    End Function

    Private Function RendreRepere(sommaire As DataRowCollection) As String
        Dim sb As New StringBuilder("<div class=""repere"">")
        Dim du As Object = Nothing, au As Object = Nothing
        For Each r As DataRow In sommaire
            sb.Append("<span><b>").Append(Convert.ToString(r("Nb"))).Append("</b> ").Append(Nommer(Convert.ToString(r("Genre"))).ToLowerInvariant())
            sb.Append(" pour <b>").Append(Convert.ToDecimal(r("Total")).ToString("N2", Fr)).Append(" $</b></span>")
            If Not IsDBNull(r("Du")) AndAlso (du Is Nothing OrElse Convert.ToDateTime(r("Du")) < Convert.ToDateTime(du)) Then du = r("Du")
            If Not IsDBNull(r("Au")) AndAlso (au Is Nothing OrElse Convert.ToDateTime(r("Au")) > Convert.ToDateTime(au)) Then au = r("Au")
        Next
        If du IsNot Nothing AndAlso au IsNot Nothing Then
            sb.Append("<span>du <b>").Append(Convert.ToDateTime(du).ToString("yyyy-MM-dd")).Append("</b> au <b>")
            sb.Append(Convert.ToDateTime(au).ToString("yyyy-MM-dd")).Append("</b></span>")
        End If
        sb.Append("</div>")
        Return sb.ToString()
    End Function

    Private Function RendreTableau(entetes As DataTable, lignes As DataTable, genre As String) As String
        If entetes.Rows.Count = 0 Then Return "<div class=""rien"">Rien pour ce genre.</div>"

        ' Les lignes par entête, pour les glisser sous chaque dépôt.
        Dim parEntete As New Dictionary(Of Integer, List(Of DataRow))
        For Each l As DataRow In lignes.Rows
            Dim id As Integer = Convert.ToInt32(l("EnteteId"))
            If Not parEntete.ContainsKey(id) Then parEntete(id) = New List(Of DataRow)
            parEntete(id).Add(l)
        Next

        Dim sb As New StringBuilder()
        sb.Append("<table class=""lst""><thead><tr><th>Date</th><th>Genre</th><th style=""text-align:right"">Montant</th>")
        sb.Append("<th>Vers</th><th>Depuis</th><th>Note</th><th>Identifiant source</th><th>État</th></tr></thead><tbody>")

        For Each r As DataRow In entetes.Rows
            Dim statut As String = Texte(r, "Statut")
            Dim g As String = Texte(r, "Genre")
            sb.Append("<tr").Append(If(statut <> "NOUVEAU", " class=""souci""", "")).Append(">")
            sb.Append("<td class=""cle"">").Append(If(IsDBNull(r("DateMouvement")), "", Convert.ToDateTime(r("DateMouvement")).ToString("yyyy-MM-dd"))).Append("</td>")
            sb.Append("<td><span class=""genre ").Append(g).Append(""">").Append(Nommer(g)).Append("</span></td>")
            sb.Append("<td class=""n"">").Append(If(IsDBNull(r("Montant")), "", Convert.ToDecimal(r("Montant")).ToString("N2", Fr) & " $"))
            If Texte(r, "Devise") <> "" AndAlso Texte(r, "Devise") <> "CAD" Then sb.Append(" ").Append(Server.HtmlEncode(Texte(r, "Devise")))
            sb.Append("</td>")
            sb.Append("<td>").Append(Montrer(Texte(r, "CompteVersNom"))).Append("</td>")
            sb.Append("<td>").Append(Montrer(Texte(r, "CompteDepuisNom"))).Append("</td>")
            sb.Append("<td>").Append(Montrer(Texte(r, "Note"))).Append("</td>")
            sb.Append("<td class=""cle"">").Append(Montrer(Texte(r, "ExterneId"))).Append("</td>")
            sb.Append("<td><span class=""verdict ").Append(statut).Append(""">").Append(If(statut = "NOUVEAU", "Lu", "Inutilisable")).Append("</span>")
            If Texte(r, "Anomalie") <> "" Then sb.Append("<div class=""cle"">").Append(Server.HtmlEncode(Texte(r, "Anomalie"))).Append("</div>")
            sb.Append("</td></tr>")

            Dim id As Integer = Convert.ToInt32(r("Id"))
            If parEntete.ContainsKey(id) Then
                For Each l As DataRow In parEntete(id)
                    sb.Append("<tr class=""ligne""><td colspan=""2"">↳ ").Append(Montrer(Texte(l, "TiersNom")))
                    If Texte(l, "Description") <> "" Then sb.Append(" — ").Append(Server.HtmlEncode(Texte(l, "Description")))
                    sb.Append("</td>")
                    sb.Append("<td class=""n"">").Append(If(IsDBNull(l("Montant")), "", Convert.ToDecimal(l("Montant")).ToString("N2", Fr) & " $")).Append("</td>")
                    sb.Append("<td colspan=""2"">").Append(Montrer(Texte(l, "CompteNom"))).Append("</td>")
                    Dim details As New List(Of String)
                    If Texte(l, "ModePaiement") <> "" Then details.Add(Texte(l, "ModePaiement"))
                    If Texte(l, "NumeroCheque") <> "" Then details.Add("chèque " & Texte(l, "NumeroCheque"))
                    If Texte(l, "PaiementLieExterneId") <> "" Then details.Add("encaissement " & Texte(l, "PaiementLieExterneId"))
                    sb.Append("<td colspan=""3"">").Append(If(details.Count = 0, "<span class=""vide"">—</span>", Server.HtmlEncode(String.Join(" · ", details)))).Append("</td>")
                    sb.Append("</tr>")
                Next
            End If
        Next

        sb.Append("</tbody></table>")
        Return sb.ToString()
    End Function

    Private Shared Function Nommer(genre As String) As String
        Return If(genre = "Virement", "Virements", "Dépôts")
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
