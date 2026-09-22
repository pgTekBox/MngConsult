Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Les feuilles de temps, lues par la passerelle (entité TimeActivity).
''' Un repère par personne — heures saisies, heures facturables — puis chaque
''' activité. Contrôle seulement.
''' </summary>
Public Class ValiderFeuillesTemps
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
        Dim ds As DataSet = ExecuteSQLds("s0854GetFeuillesTemps", p)

        If ds Is Nothing OrElse ds.Tables.Count < 2 OrElse ds.Tables(1).Rows.Count = 0 Then
            litRepere.Text = "" : litNote.Text = ""
            litTableau.Text = "<div class=""rien"">Aucune feuille de temps en préparation." &
                              "<br />Le bouton <b>Importer depuis QuickBooks</b>, ci-dessus, les rapatrie en direct.</div>"
            Return
        End If

        litRepere.Text = RendreRepere(ds.Tables(0))
        litTableau.Text = RendreTableau(ds.Tables(1))
        litNote.Text = "<div class=""note"">Lues par la <b>passerelle</b> — l'API unifiée d'Apideck ne connaît pas le temps saisi. " &
                       "« Facturable » est l'état chez la source : à facturer, déjà facturé, ou non facturable. Les heures " &
                       "à facturer sont celles qui comptent pour la bascule — ce sont des factures à venir. " &
                       "Une nouvelle extraction remplace le tout.</div>"
    End Sub

    Private Function RendreRepere(t As DataTable) As String
        Dim sb As New StringBuilder()
        sb.Append("<h2 class=""sect"">Par personne <span>ce qui est saisi, ce qui reste à facturer</span></h2>")
        sb.Append("<table class=""lst""><thead><tr><th>Personne</th><th>Genre</th><th style=""text-align:right"">Activités</th>")
        sb.Append("<th style=""text-align:right"">Heures saisies</th><th style=""text-align:right"">À facturer</th><th>Période</th></tr></thead><tbody>")

        Dim totalMin As Long = 0, factMin As Long = 0
        For Each r As DataRow In t.Rows
            Dim m As Long = Convert.ToInt64(r("MinutesTotal"))
            Dim f As Long = Convert.ToInt64(r("MinutesFacturables"))
            totalMin += m : factMin += f
            sb.Append("<tr><td><b>").Append(Montrer(Texte(r, "PersonneNom"))).Append("</b></td>")
            sb.Append("<td>").Append(If(Texte(r, "PersonneType") = "Vendor", "Fournisseur", "Employé")).Append("</td>")
            sb.Append("<td class=""n"">").Append(Convert.ToString(r("Nb"))).Append("</td>")
            sb.Append("<td class=""n"">").Append(Duree(m)).Append("</td>")
            sb.Append("<td class=""n"">").Append(Duree(f)).Append("</td>")
            sb.Append("<td class=""cle"">").Append(DateTexte(r, "Du")).Append(" → ").Append(DateTexte(r, "Au")).Append("</td></tr>")
        Next
        sb.Append("<tr><td colspan=""3""><b>Total</b></td><td class=""n""><b>").Append(Duree(totalMin)).Append("</b></td>")
        sb.Append("<td class=""n""><b>").Append(Duree(factMin)).Append("</b></td><td></td></tr>")
        sb.Append("</tbody></table>")
        Return sb.ToString()
    End Function

    Private Function RendreTableau(t As DataTable) As String
        Dim sb As New StringBuilder()
        sb.Append("<h2 class=""sect"">Les activités <span>").Append(t.Rows.Count).Append("</span></h2>")
        sb.Append("<table class=""lst""><thead><tr><th>Date</th><th>Personne</th><th>Client</th><th>Article</th><th>Classe</th>")
        sb.Append("<th style=""text-align:right"">Durée</th><th style=""text-align:right"">Taux</th><th>Facturable</th><th>Description</th></tr></thead><tbody>")

        For Each r As DataRow In t.Rows
            Dim statut As String = Texte(r, "Statut")
            sb.Append("<tr").Append(If(statut <> "NOUVEAU", " class=""souci""", "")).Append(">")
            sb.Append("<td class=""cle"">").Append(DateTexte(r, "DateActivite")).Append("</td>")
            sb.Append("<td>").Append(Montrer(Texte(r, "PersonneNom"))).Append("</td>")
            sb.Append("<td>").Append(Montrer(Texte(r, "ClientNom"))).Append("</td>")
            sb.Append("<td>").Append(Montrer(Texte(r, "ArticleNom"))).Append("</td>")
            sb.Append("<td>").Append(Montrer(Texte(r, "ClasseNom"))).Append("</td>")

            Dim minutes As Long = 0
            If Not IsDBNull(r("Heures")) Then minutes += Convert.ToInt64(r("Heures")) * 60
            If Not IsDBNull(r("Minutes")) Then minutes += Convert.ToInt64(r("Minutes"))
            If minutes = 0 AndAlso Not IsDBNull(r("HeureDebut")) AndAlso Not IsDBNull(r("HeureFin")) Then
                minutes = CLng(Math.Round((Convert.ToDateTime(r("HeureFin")) - Convert.ToDateTime(r("HeureDebut"))).TotalMinutes))
            End If
            sb.Append("<td class=""n"">").Append(Duree(minutes)).Append("</td>")
            sb.Append("<td class=""n"">").Append(If(IsDBNull(r("TauxHoraire")), "", Convert.ToDecimal(r("TauxHoraire")).ToString("N2", Fr) & " $")).Append("</td>")

            sb.Append("<td>")
            If statut <> "NOUVEAU" Then
                sb.Append("<span class=""pill INVALIDE"">Inutilisable</span>")
            Else
                Dim f As String = Texte(r, "Facturable")
                sb.Append("<span class=""pill ").Append(f).Append(""">").Append(Facturable(f)).Append("</span>")
            End If
            If Texte(r, "Anomalie") <> "" Then sb.Append("<div class=""cle"">").Append(Server.HtmlEncode(Texte(r, "Anomalie"))).Append("</div>")
            sb.Append("</td>")
            sb.Append("<td>").Append(Montrer(Texte(r, "Description"))).Append("</td></tr>")
        Next

        sb.Append("</tbody></table>")
        Return sb.ToString()
    End Function

    Private Shared Function Facturable(f As String) As String
        Select Case f
            Case "Billable" : Return "À facturer"
            Case "HasBeenBilled" : Return "Facturé"
            Case "NotBillable" : Return "Non facturable"
            Case Else : Return If(f = "", "—", f)
        End Select
    End Function

    Private Shared Function Duree(minutes As Long) As String
        If minutes <= 0 Then Return "—"
        Return (minutes \ 60) & " h " & (minutes Mod 60).ToString("00")
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
