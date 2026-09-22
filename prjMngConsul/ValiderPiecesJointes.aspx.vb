Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Les pièces jointes de toutes les entités, lues par la passerelle.
'''
''' L'API unifiée d'Apideck ne rend les pièces que de quatre types de document,
''' et sans le fichier. L'entité Attachable de QuickBooks, elle, les rend
''' toutes — clients, fournisseurs, articles, dépenses, écritures… — avec une
''' adresse de téléchargement temporaire. L'extraction suit cette adresse
''' pendant qu'elle est valide et garde le fichier dans
''' staging.PieceJointeImport.Contenu.
'''
''' Cet écran montre le résultat par entité porteuse, dit lesquelles sont déjà
''' retrouvées ici (un client créé par l'import, un document en préparation) et
''' sert chaque fichier par PieceJointe.ashx. Il ne crée rien : rattacher une
''' pièce à une fiche de l'application est un geste à part, à écrire quand on
''' saura où l'application range ses fichiers.
'''
''' L'entité choisie passe par la requête (?genre=Customer) : l'écran reste
''' partageable en lien, et le retour arrière du navigateur fonctionne.
''' </summary>
Public Class ValiderPiecesJointes
    Inherits clsData

    ''' <summary>Les types d'entité de QuickBooks, dits en français.</summary>
    Private Shared ReadOnly Genres As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase) From {
        {"Customer", "Clients"},
        {"Vendor", "Fournisseurs"},
        {"Item", "Articles"},
        {"Employee", "Employés"},
        {"Invoice", "Factures clients"},
        {"CreditMemo", "Notes de crédit"},
        {"SalesReceipt", "Reçus de vente"},
        {"Estimate", "Soumissions"},
        {"Payment", "Encaissements"},
        {"RefundReceipt", "Remboursements"},
        {"Bill", "Factures fournisseurs"},
        {"VendorCredit", "Notes de crédit fournisseurs"},
        {"BillPayment", "Décaissements"},
        {"PurchaseOrder", "Bons de commande"},
        {"Purchase", "Dépenses"},
        {"JournalEntry", "Écritures de journal"},
        {"Deposit", "Dépôts"},
        {"Transfer", "Virements"},
        {"TimeActivity", "Feuilles de temps"},
        {"Aucune", "Sans rattachement"}
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
        ' Le genre demandé n'est retenu que s'il est connu du sommaire : une
        ' valeur inventée dans l'adresse ne descend pas jusqu'à la procédure.
        Dim genre As String = If(Request.QueryString("genre"), "").Trim()

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Genre", DBNull.Value))
        Dim sommaire As DataSet = ExecuteSQLds("s0837GetPiecesJointesToutes", p)

        If sommaire Is Nothing OrElse sommaire.Tables.Count < 2 OrElse sommaire.Tables(0).Rows.Count = 0 Then
            litOnglets.Text = ""
            litRepere.Text = ""
            litNote.Text = ""
            litListe.Text =
                "<div class=""rien"">Aucune pièce jointe en préparation." &
                "<br />Le bouton <b>Importer depuis QuickBooks</b>, ci-dessus, les rapatrie toutes — fichiers compris.</div>"
            Return
        End If

        Dim connus As New HashSet(Of String)(StringComparer.OrdinalIgnoreCase)
        For Each r As DataRow In sommaire.Tables(0).Rows
            connus.Add(Convert.ToString(r("Genre")))
        Next
        If Not connus.Contains(genre) Then genre = ""

        Dim lignes As DataTable = sommaire.Tables(1)
        If genre <> "" Then
            Dim p2 As New Collection
            p2.Add(New SqlParameter("@CompanyGUID", Company))
            p2.Add(New SqlParameter("@Genre", genre))
            Dim ds As DataSet = ExecuteSQLds("s0837GetPiecesJointesToutes", p2)
            If ds IsNot Nothing AndAlso ds.Tables.Count >= 2 Then lignes = ds.Tables(1)
        End If

        litOnglets.Text = RendreOnglets(sommaire.Tables(0).Rows, genre)
        litRepere.Text = RendreRepere(sommaire.Tables(0).Rows)
        litListe.Text = RendreListe(lignes.Rows, genre)
        litNote.Text = RendreNote()
    End Sub

    Private Function RendreOnglets(sommaire As DataRowCollection, choisi As String) As String
        Dim sb As New StringBuilder("<div class=""onglets"">")

        Dim total As Integer = 0
        For Each r As DataRow In sommaire
            total += Convert.ToInt32(r("Nb"))
        Next

        sb.Append("<a href=""ValiderPiecesJointes.aspx""")
        If choisi = "" Then sb.Append(" class=""on""")
        sb.Append(">Toutes <span class=""n"">").Append(total).Append("</span></a>")

        For Each r As DataRow In sommaire
            Dim g As String = Convert.ToString(r("Genre"))
            Dim soucis As Integer = Convert.ToInt32(r("NbSoucis"))

            sb.Append("<a href=""ValiderPiecesJointes.aspx?genre=").Append(Server.UrlEncode(g)).Append("""")
            If String.Equals(choisi, g, StringComparison.OrdinalIgnoreCase) Then sb.Append(" class=""on""")
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

    ''' <summary>Trois chiffres qui disent si l'archive est complète : lues, téléchargées, en poids.</summary>
    Private Function RendreRepere(sommaire As DataRowCollection) As String
        Dim nb As Integer = 0, telechargees As Integer = 0
        Dim octets As Long = 0
        For Each r As DataRow In sommaire
            nb += Convert.ToInt32(r("Nb"))
            telechargees += Convert.ToInt32(r("NbTelechargees"))
            octets += Convert.ToInt64(r("Taille"))
        Next

        Dim sb As New StringBuilder("<div class=""repere"">")
        sb.Append("<span><b>").Append(nb).Append("</b> pièce(s) lue(s)</span>")
        sb.Append("<span><b>").Append(telechargees).Append("</b> fichier(s) gardé(s) en préparation</span>")
        If nb - telechargees > 0 Then
            sb.Append("<span><b>").Append(nb - telechargees).Append("</b> sans fichier — le détail dit pourquoi</span>")
        End If
        sb.Append("<span><b>").Append(Server.HtmlEncode(Poids(octets))).Append("</b> annoncés par la source</span>")
        sb.Append("</div>")
        Return sb.ToString()
    End Function

    Private Function RendreListe(lignes As DataRowCollection, genre As String) As String
        If lignes.Count = 0 Then
            Return "<div class=""rien"">Rien pour cette entité.</div>"
        End If

        Dim sb As New StringBuilder()
        sb.Append("<table class=""lst""><thead><tr>")
        If genre = "" Then sb.Append("<th>Entité</th>")
        sb.Append("<th>Attachée à</th><th>Fichier</th><th>Type</th><th style=""text-align:right"">Taille</th>")
        sb.Append("<th>Note</th><th>Date</th><th>État</th>")
        sb.Append("</tr></thead><tbody>")

        For Each r As DataRow In lignes
            Dim statut As String = Texte(r, "Statut")
            Dim souci As Boolean = statut <> "TELECHARGE" AndAlso statut <> "NOUVEAU"

            sb.Append("<tr")
            If souci Then sb.Append(" class=""souci""")
            sb.Append(">")

            If genre = "" Then
                sb.Append("<td>").Append(Server.HtmlEncode(Nommer(Texte(r, "Genre")))).Append("</td>")
            End If

            ' L'entité porteuse : son nom chez la source, et — quand elle a été
            ' retrouvée ici — la mention de ce à quoi elle correspond.
            sb.Append("<td>")
            Dim nomEntite As String = Texte(r, "EntiteNom")
            If nomEntite = "" Then nomEntite = Texte(r, "LieNom")
            sb.Append(Montrer(nomEntite))
            If Texte(r, "LieId") <> "" Then
                sb.Append("<span class=""lie"">")
                sb.Append(If(Texte(r, "LieTable") = "T050Party", "tiers créé ici", "document en préparation"))
                sb.Append("</span>")
            End If
            sb.Append("<span class=""sous"">id source ").Append(Server.HtmlEncode(Texte(r, "EntiteId"))).Append("</span>")
            sb.Append("</td>")

            ' Le fichier : un lien quand on l'a, le nom seul sinon.
            sb.Append("<td>")
            Dim nom As String = Texte(r, "NomFichier")
            If Texte(r, "Octets") <> "" Then
                sb.Append("<a class=""fich"" href=""PieceJointe.ashx?id=").Append(Texte(r, "Id"))
                sb.Append(""" target=""_blank"">").Append(Server.HtmlEncode(If(nom = "", "(sans nom)", nom))).Append("</a>")
            Else
                sb.Append(Montrer(nom))
            End If
            Dim etiquettes As New List(Of String)
            If Texte(r, "Categorie") <> "" Then etiquettes.Add(Texte(r, "Categorie"))
            If Texte(r, "Etiquette") <> "" Then etiquettes.Add(Texte(r, "Etiquette"))
            If etiquettes.Count > 0 Then
                sb.Append("<span class=""sous"">").Append(Server.HtmlEncode(String.Join(" · ", etiquettes))).Append("</span>")
            End If
            sb.Append("</td>")

            sb.Append("<td class=""cle"">").Append(Montrer(Texte(r, "TypeContenu"))).Append("</td>")
            sb.Append("<td class=""n"">")
            If Not IsDBNull(r("Taille")) Then sb.Append(Server.HtmlEncode(Poids(Convert.ToInt64(r("Taille")))))
            sb.Append("</td>")
            sb.Append("<td>").Append(Montrer(Texte(r, "Note"))).Append("</td>")
            sb.Append("<td class=""cle"">")
            If Not IsDBNull(r("DateSource")) Then sb.Append(Convert.ToDateTime(r("DateSource")).ToString("yyyy-MM-dd"))
            sb.Append("</td>")

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
    ''' Ce qu'aucune colonne ne dit : d'où ça vient, pourquoi le fichier est
    ''' là, et ce que l'écran ne fait pas encore.
    ''' </summary>
    Private Function RendreNote() As String
        Dim sb As New StringBuilder("<div class=""note"">")
        sb.Append("Lues par la <b>passerelle</b> — l'entité Attachable de QuickBooks — parce que l'API ")
        sb.Append("unifiée d'Apideck ne rend les pièces que de quatre types de document, sans le fichier. ")
        sb.Append("L'adresse de téléchargement que donne QuickBooks n'est valable que quelques minutes : ")
        sb.Append("le fichier est donc téléchargé pendant l'extraction et gardé ici, jusqu'à 25 Mo par pièce. ")
        sb.Append("Une pièce attachée à plusieurs entités apparaît sous chacune, le fichier n'est ")
        sb.Append("téléchargé qu'une fois.<br /><br />")
        sb.Append("« Tiers créé ici » : le client ou le fournisseur porteur a déjà été créé par l'import, ")
        sb.Append("reconnu à son identifiant source. « Document en préparation » : la facture porteuse est ")
        sb.Append("dans l'écran des factures. Rattacher le fichier à la fiche de l'application reste à ")
        sb.Append("faire : rien n'est copié hors de la préparation. Une nouvelle extraction remplace ")
        sb.Append("toutes les pièces lues par la passerelle, sans toucher à celles de la voie unifiée.")
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
            Case "TELECHARGE" : Return "Fichier gardé"
            Case "NOUVEAU" : Return "Lu"
            Case "SANS_LIEN" : Return "Sans adresse"
            Case "TROP_GROS" : Return "Trop gros"
            Case "ECHEC" : Return "Téléchargement refusé"
            Case Else : Return statut
        End Select
    End Function

    ''' <summary>Un poids lisible : octets, Ko, Mo.</summary>
    Private Shared Function Poids(octets As Long) As String
        If octets < 1024 Then Return octets & " o"
        If octets < 1024 * 1024 Then Return (octets / 1024).ToString("N0") & " Ko"
        Return (octets / (1024 * 1024)).ToString("N1") & " Mo"
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
