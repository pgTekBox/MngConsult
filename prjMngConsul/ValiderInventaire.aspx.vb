Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' L'inventaire importé.
'''
''' Cet écran ne valide rien et ne crée rien : aucun article n'est créé, aucune
''' écriture de stock n'est passée. Pièce de contrôle, remplacée à chaque
''' extraction.
'''
''' SON INTÉRÊT EST LE CONTRÔLE CROISÉ. La somme des valeurs d'articles doit
''' égaler le solde du compte d'actif de stock au grand livre. Les deux
''' viennent de la même comptabilité : un écart ne dit pas lequel a tort, il
''' dit qu'un article a bougé sans passer par le stock — ou l'inverse. C'est la
''' seule vérification qui attrape une reprise d'inventaire silencieusement
''' fausse, et elle est en haut de l'écran plutôt qu'en bas.
'''
''' DEUX ANOMALIES SONT NOMMÉES, PAS DEVINÉES. Une quantité NÉGATIVE est
''' physiquement impossible : la source a laissé sortir plus qu'il n'y en avait,
''' et le coût des ventes est faux d'autant. Une quantité SANS COÛT laisse
''' savoir combien il en reste mais pas ce que ça vaut — reprendre zéro
''' écraserait un actif réel. Les deux remontent en tête de liste.
'''
''' LA VALEUR EST CALCULÉE, quantité × coût, parce que la source ne la rend pas
''' sur l'article. Les deux facteurs restent affichés à côté du produit : une
''' valeur calculée doit pouvoir être refaite à la main.
''' </summary>
Public Class ValiderInventaire
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then Afficher()
    End Sub

    Private Sub Afficher()
        Dim ds As DataSet
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            ds = ExecuteSQLds("s0834GetInventaire", p)
        Catch ex As Exception
            litTableau.Text = "<div class='rien'>L'inventaire n'a pas pu être lu : " &
                              H(ex.Message) & "</div>"
            Return
        End Try

        If ds Is Nothing OrElse ds.Tables.Count < 3 OrElse ds.Tables(0).Rows.Count = 0 Then
            litTableau.Text = Vide()
            Return
        End If

        Dim entete As DataRow = ds.Tables(0).Rows(0)
        If Ent(entete("NbArticles")) = 0 Then
            litTableau.Text = Vide()
            Return
        End If

        litRepere.Text = BatirRepere(entete)
        litControle.Text = BatirControle(ds.Tables(2))
        litTableau.Text = BatirTableau(ds.Tables(1))
        litNote.Text = BatirNote()
    End Sub

    ' =========================================================================
    ' LE RENDU
    ' =========================================================================

    Private Function BatirRepere(r As DataRow) As String
        Dim anomalies As Integer = Ent(r("NbAnomalies"))

        Dim sb As New StringBuilder("<div class='repere'>")
        sb.Append(BatirBloc("Articles", Txt(r("NbArticles")), False))
        sb.Append(BatirBloc("Actifs", Txt(r("NbActifs")), False))
        sb.Append(BatirBloc("Quantité totale", Quantite(r("QuantiteTotale")), False))
        sb.Append(BatirBloc("Valeur du stock", Somme(r("ValeurTotale")), False))
        If anomalies > 0 Then sb.Append(BatirBloc("À vérifier", Txt(anomalies), True))
        sb.Append(BatirBloc("Arrêté au", Jour(r("DateArrete")), False))
        sb.Append(BatirBloc("Déposé", Jour(r("Depose")), False))
        Return sb.Append("</div>").ToString()
    End Function

    Private Shared Function BatirBloc(libelle As String, valeur As String, alerte As Boolean) As String
        Return "<div class='bloc'><div class='l'>" & H(libelle) & "</div><div class='v" &
               If(alerte, " alerte", "") & "'>" & H(If(valeur <> "", valeur, "—")) & "</div></div>"
    End Function

    ''' <summary>
    ''' Le contrôle croisé, compte de stock par compte de stock. C'est la raison
    ''' d'être de l'écran, alors il passe avant le détail.
    ''' </summary>
    Private Function BatirControle(comptes As DataTable) As String
        Dim sb As New StringBuilder("<div class='ctrl'><h2>La valeur du stock contre le grand livre</h2>")
        sb.Append("<p class='desc'>La somme des articles devrait égaler le solde du compte d'actif ")
        sb.Append("de stock. Les deux viennent de la même comptabilité : un écart ne dit pas lequel ")
        sb.Append("a tort, il dit qu'un article a bougé sans passer par le stock — ou l'inverse.</p>")

        If comptes.Rows.Count = 0 Then
            sb.Append("<div class='verdict rien'>Aucun compte de stock sur les articles repris.</div>")
            Return sb.Append("</div>").ToString()
        End If

        For Each r As DataRow In comptes.Rows
            Dim compte As String = Txt(r("CompteActifNom"))
            If compte = "" Then compte = "Sans compte de stock déclaré"

            Dim calculee As Decimal = Dec(r("ValeurCalculee"))
            Dim sansSolde As Boolean = (Ent(r("SansSolde")) = 1)

            If sansSolde Then
                sb.Append("<div class='verdict rien'>").Append(H(compte)).Append(" — ")
                sb.Append(Somme(calculee)).Append(" en articles. La balance de vérification ")
                sb.Append("n'a pas ce compte : importez-la pour que la comparaison soit possible.</div>")
                Continue For
            End If

            Dim livre As Decimal = Dec(r("SoldeLivre"))
            Dim ecart As Decimal = Dec(r("Ecart"))

            If Math.Abs(ecart) <= 0.01D Then
                sb.Append("<div class='verdict ok'>⚖️ ").Append(H(compte)).Append(" — les deux concordent à ")
                sb.Append(Somme(calculee)).Append(", sur ").Append(Txt(r("NbArticles"))).Append(" article(s).</div>")
            Else
                sb.Append("<div class='verdict ko'>⚠️ ").Append(H(compte)).Append(" — écart de ")
                sb.Append(Somme(Math.Abs(ecart))).Append(" : les articles totalisent ")
                sb.Append(Somme(calculee)).Append(", le grand livre porte ").Append(Somme(livre))
                sb.Append(".</div>")
            End If
        Next

        Return sb.Append("</div>").ToString()
    End Function

    ''' <summary>Les articles. Ce qui cloche est déjà remonté en tête par s0834.</summary>
    Private Function BatirTableau(articles As DataTable) As String
        Dim sb As New StringBuilder()
        sb.Append("<div class='tbl-wrap'><table class='iv'><thead><tr>")
        sb.Append("<th>Article</th><th>SKU</th><th>Compte de stock</th>")
        sb.Append("<th class='n'>Quantité</th><th class='n'>Coût unitaire</th>")
        sb.Append("<th class='n'>Valeur</th><th class='n'>Prix de vente</th>")
        sb.Append("</tr></thead><tbody>")

        Dim total As Decimal = 0D

        For Each a As DataRow In articles.Rows
            Dim statut As String = Txt(a("Statut"))
            Dim actif As Boolean = (Not IsDBNull(a("Actif"))) AndAlso Convert.ToBoolean(a("Actif"))
            Dim qte As Decimal = Dec(a("QuantiteEnMain"))
            total += Dec(a("ValeurTotale"))

            ' Une anomalie prime sur un article inactif : c'est elle qu'on veut voir.
            Dim classe As String = ""
            If statut <> "OK" Then
                classe = " class='ko'"
            ElseIf Not actif Then
                classe = " class='inactif'"
            End If
            sb.Append("<tr").Append(classe).Append(">")

            sb.Append("<td class='nom'>").Append(H(Txt(a("Nom"))))
            If statut = "ANOMALIE" Then sb.Append("<span class='past ko'>à corriger</span>")
            If statut = "A_VERIFIER" Then sb.Append("<span class='past warn'>valeur inconnue</span>")
            If Not actif Then sb.Append("<span class='past off'>inactif</span>")
            If SousLeSeuil(a) Then sb.Append("<span class='past bas'>sous le point de commande</span>")

            Dim anomalie As String = Txt(a("Anomalie"))
            If anomalie <> "" Then sb.Append("<div class='fil'>").Append(H(anomalie)).Append("</div>")
            sb.Append("</td>")

            sb.Append("<td>").Append(H(Txt(a("Sku")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(a("CompteActifNom")))).Append("</td>")

            sb.Append("<td class='n").Append(If(qte < 0D, " neg", "")).Append("'>")
            sb.Append(H(Quantite(qte))).Append("</td>")

            sb.Append(EcrireMontant(a("CoutUnitaire")))
            sb.Append(EcrireMontant(a("ValeurTotale")))
            sb.Append(EcrireMontant(a("PrixVente")))
            sb.Append("</tr>")
        Next

        sb.Append("</tbody><tfoot><tr><td colspan='5'>Valeur du stock</td>")
        sb.Append("<td class='n'>").Append(Somme(total)).Append("</td><td></td>")
        sb.Append("</tr></tfoot></table></div>")

        Return sb.ToString()
    End Function

    ''' <summary>
    ''' L'article est-il sous son point de commande ? Un stock à zéro sur un
    ''' article inactif n'est pas un manque : on ne le signale que s'il est
    ''' encore au catalogue.
    ''' </summary>
    Private Shared Function SousLeSeuil(a As DataRow) As Boolean
        If IsDBNull(a("PointCommande")) Then Return False
        Dim seuil As Decimal = Dec(a("PointCommande"))
        If seuil <= 0D Then Return False

        Dim actif As Boolean = (Not IsDBNull(a("Actif"))) AndAlso Convert.ToBoolean(a("Actif"))
        If Not actif Then Return False

        Return Dec(a("QuantiteEnMain")) < seuil
    End Function

    ''' <summary>Un zéro se voit, mais ne se lit pas : il s'efface au gris.</summary>
    Private Shared Function EcrireMontant(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "<td class='n zero'>—</td>"
        Dim d As Decimal = Convert.ToDecimal(v)
        Return "<td class='n" & If(d = 0D, " zero", "") & "'>" & Somme(d) & "</td>"
    End Function

    Private Shared Function BatirNote() As String
        Return "<div class='note'>La quantité vient de l'entité <b>Item</b> de la source, pas du " &
               "rapport d'inventaire : ce dernier ne rend que deux colonnes et rien que l'article " &
               "ne porte déjà. La lecture est paginée — QuickBooks rend cent articles et s'arrête " &
               "sans le dire, et cette compagnie en a 214.<br /><br />" &
               "<b>La valeur est calculée</b>, quantité × coût, parce que la source ne la rend " &
               "pas sur l'article. Les deux facteurs restent affichés à côté pour qu'on puisse " &
               "refaire la multiplication.<br /><br />" &
               "La quantité est celle du <b>jour de l'extraction</b> : QuickBooks ne rend pas " &
               "« le stock au 30 juin ». Rien ne s'applique à la comptabilité — aucun article " &
               "créé, aucune écriture de stock, et une nouvelle extraction remplace la " &
               "précédente.</div>"
    End Function

    Private Shared Function Vide() As String
        Return "<div class='rien'>Aucun inventaire en préparation.<br />" &
               "Rapatriez-le depuis l'écran <b>Import par connecteur</b>.<br /><br />" &
               "Si l'extraction revient vide, c'est que la source ne tient aucun article de type " &
               "inventaire — ce qui est le cas quand on ne suit pas de stock permanent.</div>"
    End Function

    ' =========================================================================
    ' PETITS OUTILS
    ' =========================================================================

    Private Shared ReadOnly FrCa As Globalization.CultureInfo =
        Globalization.CultureInfo.GetCultureInfo("fr-CA")

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

    Private Shared Function Somme(v As Object) As String
        Return Dec(v).ToString("N2", FrCa) & " $"
    End Function

    ''' <summary>Une quantité : sans unité, et sans décimales quand elle est ronde.</summary>
    Private Shared Function Quantite(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "—"
        Return Convert.ToDecimal(v).ToString("0.####", FrCa)
    End Function

    Private Shared Function Jour(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "—"
        Return Convert.ToDateTime(v).ToString("d MMM yyyy", FrCa)
    End Function

End Class
