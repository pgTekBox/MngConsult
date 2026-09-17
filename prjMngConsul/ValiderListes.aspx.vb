Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Les listes de structure importées : modes de paiement, catégories de suivi,
''' départements, emplacements.
'''
''' Chaque liste a SA table — ModePaiementImport, DepartementImport… — parce
''' qu'un emplacement porte une adresse dont un mode de paiement n'a que faire.
''' L'écran, lui, n'en voit qu'une : s0803GetListesImport les réunit, et
''' [Detail1]/[Detail2] portent ce que chaque liste a en propre.
'''
''' Il y a eu un temps des journaux et des comptes bancaires. Le connecteur
''' QuickBooks d'Apideck ne les rend pas, alors tout est parti : catalogue,
''' tables, procédures. Le jour où une source les donnera, on les écrira sur SA
''' forme réelle plutôt que sur une forme devinée d'avance.
'''
''' Cet écran ne valide rien, et c'est assumé. Les cinq autres écrans d'import
''' mènent quelque part — un tiers, un compte, une facture. Ces listes-ci
''' n'ont aucune table de destination dans 60Sec-AI : il n'existe pas d'écran des
''' modes de paiement, ni des départements. Les faire aboutir n'aurait donc aucun
''' sens aujourd'hui.
'''
''' Ce qu'elles apportent quand même : le client voit ce que sa comptabilité
''' contient — combien de départements, quels emplacements, quels modes de paiement —
''' et la donnée est déjà en préparation le jour où la fonction correspondante
''' existera. C'est le même raisonnement que le dépôt brut des quinze autres
''' ressources, avec une table typée en plus.
'''
''' Le genre choisi passe par la requête (?genre=Departement) : l'écran reste
''' partageable en lien, et le retour arrière du navigateur fonctionne.
''' </summary>
Public Class ValiderListes
    Inherits clsData

    ''' <summary>Les six genres, et de quoi les nommer à l'écran.</summary>
    Private Shared ReadOnly Genres As New Dictionary(Of String, String) From {
        {"ModePaiement", "Modes de paiement"},
        {"CategorieSuivi", "Catégories de suivi"},
        {"Departement", "Départements"},
        {"Emplacement", "Emplacements"}
    }

#Region "Cycle de vie"

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        Afficher()
    End Sub

#End Region

#Region "L'affichage"

    Private Sub Afficher()
        ' Le genre demandé n'est retenu que s'il en est un : une valeur inventée
        ' dans l'adresse ne doit pas descendre jusqu'à la procédure.
        Dim genre As String = If(Request.QueryString("genre"), "")
        If Not Genres.ContainsKey(genre) Then genre = ""

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Genre", If(genre = "", CObj(DBNull.Value), CObj(genre))))

        Dim ds As DataSet = ExecuteSQLds("s0803GetListesImport", p)

        If ds Is Nothing OrElse ds.Tables.Count < 2 OrElse ds.Tables(0).Rows.Count = 0 Then
            litOnglets.Text = ""
            litNote.Text = ""
            litListe.Text =
                "<div class=""rien"">Aucune liste de structure en préparation." &
                "<br />Lancez une importation QuickBooks en cochant les ressources du groupe " &
                "<b>Structure</b>, puis revenez ici.</div>"
            Return
        End If

        litOnglets.Text = RendreOnglets(ds.Tables(0).Rows, genre)
        litListe.Text = RendreListe(ds.Tables(1).Rows, genre)
        litNote.Text = RendreNote(genre)
    End Sub

    Private Function RendreOnglets(sommaire As DataRowCollection, choisi As String) As String
        Dim sb As New StringBuilder("<div class=""onglets"">")

        Dim total As Integer = 0
        For Each r As DataRow In sommaire
            total += Convert.ToInt32(r("Nb"))
        Next

        sb.Append("<a href=""ValiderListes.aspx""")
        If choisi = "" Then sb.Append(" class=""on""")
        sb.Append(">Toutes <span class=""n"">").Append(total).Append("</span></a>")

        For Each r As DataRow In sommaire
            Dim g As String = Convert.ToString(r("Genre"))
            Dim soucis As Integer = Convert.ToInt32(r("NbSoucis"))

            sb.Append("<a href=""ValiderListes.aspx?genre=").Append(Server.UrlEncode(g)).Append("""")
            If choisi = g Then sb.Append(" class=""on""")
            sb.Append(">").Append(Server.HtmlEncode(Nommer(g)))
            sb.Append(" <span class=""n"">").Append(Convert.ToString(r("Nb"))).Append("</span>")
            If soucis > 0 Then
                sb.Append(" <span class=""souci"">").Append(soucis).Append(" ?</span>")
            End If
            sb.Append("</a>")
        Next

        sb.Append("</div>")
        Return sb.ToString()
    End Function

    Private Function RendreListe(lignes As DataRowCollection, genre As String) As String
        If lignes.Count = 0 Then
            Return "<div class=""rien"">Rien dans cette liste.</div>"
        End If

        ' Chaque liste a ses colonnes propres ; s0803 les fait passer par
        ' Detail1 et Detail2. On ne montre la colonne que si elle porte
        ' quelque chose — un en-tête vide n'apprend rien.
        Dim detail As Boolean = False
        For Each r As DataRow In lignes
            If Texte(r, "Detail1") <> "" OrElse Texte(r, "Detail2") <> "" Then
                detail = True
                Exit For
            End If
        Next

        Dim sb As New StringBuilder()
        sb.Append("<table class=""lst""><thead><tr>")
        If genre = "" Then sb.Append("<th>Liste</th>")
        sb.Append("<th>Nom</th><th>Code</th><th>Type</th>")
        If detail Then sb.Append("<th>Détail</th>")
        sb.Append("<th>Parent</th><th>Identifiant source</th><th>État</th>")
        sb.Append("</tr></thead><tbody>")

        For Each r As DataRow In lignes
            Dim statut As String = Convert.ToString(r("Statut"))

            sb.Append("<tr")
            If statut <> "NOUVEAU" Then sb.Append(" class=""souci""")
            sb.Append(">")

            If genre = "" Then
                sb.Append("<td>").Append(Server.HtmlEncode(Nommer(Texte(r, "Genre")))).Append("</td>")
            End If

            sb.Append("<td>").Append(Montrer(Texte(r, "Nom"))).Append("</td>")
            sb.Append("<td>").Append(Montrer(Texte(r, "Code"))).Append("</td>")
            sb.Append("<td>").Append(Montrer(Texte(r, "TypeSource"))).Append("</td>")

            If detail Then
                Dim bouts As New List(Of String)
                If Texte(r, "Detail1") <> "" Then bouts.Add(Server.HtmlEncode(Texte(r, "Detail1")))
                If Texte(r, "Detail2") <> "" Then bouts.Add(Server.HtmlEncode(Texte(r, "Detail2")))
                sb.Append("<td>")
                If bouts.Count = 0 Then
                    sb.Append("<span class=""vide"">—</span>")
                Else
                    sb.Append(String.Join(" · ", bouts.ToArray()))
                End If
                sb.Append("</td>")
            End If

            sb.Append("<td class=""cle"">").Append(Montrer(Texte(r, "ParentExterneId"))).Append("</td>")
            sb.Append("<td class=""cle"">").Append(Montrer(Texte(r, "ExterneId"))).Append("</td>")

            sb.Append("<td><span class=""verdict ").Append(statut).Append(""">")
            sb.Append(Dire(statut)).Append("</span>")
            Dim anomalie As String = Texte(r, "Anomalie")
            If anomalie <> "" Then
                sb.Append("<div class=""cle"">").Append(Server.HtmlEncode(anomalie)).Append("</div>")
            End If
            sb.Append("</td>")

            sb.Append("</tr>")
        Next

        sb.Append("</tbody></table>")
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Ce qu'aucune colonne ne dit : ces listes ne mènent nulle part, et une
    ''' relecture remplace la précédente.
    ''' </summary>
    Private Function RendreNote(genre As String) As String
        Dim sb As New StringBuilder("<div class=""note"">")
        sb.Append("Ces listes s'arrêtent à la préparation : 60Sec-AI n'a pas encore ")
        sb.Append("d'écran où les appliquer. Une nouvelle extraction remplace la liste ")
        sb.Append("du même genre, sans toucher aux autres.")

        sb.Append("</div>")
        Return sb.ToString()
    End Function

#End Region

#Region "Petits secours"

    Private Shared Function Nommer(genre As String) As String
        Dim nom As String = Nothing
        If Genres.TryGetValue(If(genre, ""), nom) Then Return nom
        Return genre
    End Function

    Private Shared Function Dire(statut As String) As String
        Select Case statut
            Case "NOUVEAU" : Return "Lu"
            Case "DOUBLON" : Return "En double"
            Case Else : Return "Inutilisable"
        End Select
    End Function

    Private Function Montrer(valeur As String) As String
        If valeur = "" Then Return "<span class=""vide"">—</span>"
        Return Server.HtmlEncode(valeur)
    End Function

    Private Shared Function Texte(r As DataRow, champ As String) As String
        If IsDBNull(r(champ)) Then Return ""
        Return Convert.ToString(r(champ))
    End Function

#End Region

End Class
