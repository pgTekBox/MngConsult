Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Les rapports de taxes importés.
'''
''' Cet écran ne valide rien et ne crée rien — comme le grand livre et la
''' balance âgée. Les déclarations restent en PRÉPARATION : aucune écriture,
''' aucun compte de taxe, aucune déclaration produite. La comptabilité de
''' l'application n'en sait rien.
'''
''' DEUX AXES, PARCE QU'UN ABONNÉ A PLUSIEURS DÉCLARATIONS. Un trimestriel
''' québécois arrivé en septembre en a trois. Les périodes deviennent les
''' COLONNES du tableau, les lignes du formulaire en sont les RANGÉES : on lit
''' la ligne 217 des trois trimestres d'un seul regard, comme au centre de taxes
''' de la source.
'''
''' LA LIGNE SE RECONNAÎT À SON CODE, PAS À SON RANG. « Ligne 106 » est la même
''' d'un trimestre à l'autre ; son ordre d'apparition, lui, ne se répète pas
''' d'un rapport au suivant. C'est s0823 qui bâtit cette clé — par code quand la
''' source en donne un, par libellé sinon.
'''
''' POURQUOI L'ÉCRAN REPIVOTE. staging.TaxeRapportImport garde UNE LIGNE PAR
''' CELLULE, chacune portant le titre que la source donne à sa colonne. C'est le
''' prix payé pour ne rien présumer : les colonnes changent avec le régime de
''' taxes du pays et de la province. L'écran fait le chemin inverse et affiche ce
''' que la source a nommé, pas ce qu'on aurait deviné.
''' </summary>
Public Class ValiderRapportTaxes
    Inherits clsData

    ''' <summary>Une colonne du tableau : une période, et une colonne du rapport.</summary>
    Private Class Colonne
        Public Property Periode As Integer
        Public Property Ordre As Integer
        Public Property Debut As Object
        Public Property Fin As Object
        Public Property Titre As String

        Public ReadOnly Property Cle As String
            Get
                Return Periode & "|" & Ordre
            End Get
        End Property
    End Class

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
            ds = ExecuteSQLds("s0823GetRapportTaxes", p)
        Catch ex As Exception
            litTableau.Text = "<div class='rien'>Le rapport de taxes n'a pas pu être lu : " &
                              H(ex.Message) & "</div>"
            Return
        End Try

        If ds Is Nothing OrElse ds.Tables.Count < 4 OrElse ds.Tables(2).Rows.Count = 0 Then
            litTableau.Text = Vide()
            Return
        End If

        litRepere.Text = Repere(ds.Tables(0).Rows(0))
        litTableau.Text = Tableau(ds.Tables(1), ds.Tables(2), ds.Tables(3))
        litNote.Text = Note()
    End Sub

    ' =========================================================================
    ' LE RENDU
    ' =========================================================================

    Private Function Repere(r As DataRow) As String
        Dim sb As New StringBuilder("<div class='repere'>")
        sb.Append(Bloc("Exercice", Jour(r("PeriodeDebut")) & " → " & Jour(r("PeriodeFin"))))
        sb.Append(Bloc("Déclarations", Txt(r("NbPeriodes"))))
        sb.Append(Bloc("Administrations", Txt(r("NbAgences"))))
        sb.Append(Bloc("Lignes", Txt(r("NbLignes"))))
        sb.Append(Bloc("Devise", Txt(r("Devise"))))
        sb.Append(Bloc("Déposé", Jour(r("Depose"))))
        Return sb.Append("</div>").ToString()
    End Function

    Private Shared Function Bloc(libelle As String, valeur As String) As String
        Return "<div class='bloc'><div class='l'>" & H(libelle) & "</div><div class='v'>" &
               H(If(valeur <> "", valeur, "—")) & "</div></div>"
    End Function

    ''' <summary>
    ''' Le tableau. Les colonnes viennent du deuxième jeu, les rangées du
    ''' troisième, et le quatrième les croise — rien n'est décidé ici.
    ''' </summary>
    Private Function Tableau(colonnes As DataTable, lignes As DataTable, cellules As DataTable) As String
        Dim cols As New List(Of Colonne)
        For Each c As DataRow In colonnes.Rows
            cols.Add(New Colonne With {
                .Periode = Ent(c("PeriodeOrdre")),
                .Ordre = Ent(c("ColonneOrdre")),
                .Debut = c("PeriodeDebut"),
                .Fin = c("PeriodeFin"),
                .Titre = Txt(c("ColonneTitre"))
            })
        Next
        If cols.Count = 0 Then Return Vide()

        ' Le rapport a-t-il plus d'une colonne par période ? Quand oui, son titre
        ' s'ajoute sous les dates ; quand non, les dates suffisent et le mot
        ' « Total » n'apprendrait rien.
        Dim nbPeriodes As Integer = cols.Select(Function(x) x.Periode).Distinct().Count()
        Dim plusieurs As Boolean = (cols.Count > nbPeriodes)

        ' Les valeurs, rangées par (ligne, colonne).
        Dim valeurs As New Dictionary(Of String, String)
        For Each c As DataRow In cellules.Rows
            Dim cle As String = Txt(c("CleLigne")) & "§" & Txt(c("AgenceId")) & "§" &
                                Ent(c("PeriodeOrdre")) & "|" & Ent(c("ColonneOrdre"))
            valeurs(cle) = Cellule(c)
        Next

        Dim sb As New StringBuilder()
        sb.Append("<div class='tx-wrap'><table class='tx'><thead><tr><th>Poste</th>")
        For Each c As Colonne In cols
            sb.Append("<th class='n'>").Append(H(Entete(c)))
            If plusieurs AndAlso c.Titre <> "" Then
                sb.Append("<div class='st'>").Append(H(c.Titre)).Append("</div>")
            End If
            sb.Append("</th>")
        Next
        sb.Append("</tr></thead><tbody>")

        Dim agence As String = Nothing
        For Each l As DataRow In lignes.Rows
            ' Une déclaration par administration fiscale : on annonce laquelle
            ' avant ses lignes, sans quoi deux déclarations se confondraient.
            Dim a As String = Txt(l("AgenceNom"))
            If a <> agence Then
                agence = a
                sb.Append("<tr class='agence'><td colspan='").Append(cols.Count + 1).Append("'>")
                sb.Append(H(If(a <> "", a, "Sans administration fiscale"))).Append("</td></tr>")
            End If

            Dim estTotal As Boolean = (Ent(l("EstTotal")) = 1)
            Dim prefixe As String = Txt(l("CleLigne")) & "§" & Txt(l("AgenceId")) & "§"

            sb.Append("<tr").Append(If(estTotal, " class='total'", "")).Append(">")
            sb.Append("<td class='lib' style='padding-left:").Append(10 + Ent(l("Niveau")) * 18).Append("px'>")
            sb.Append(H(Libelle(l))).Append("</td>")

            For Each c As Colonne In cols
                Dim v As String = ""
                valeurs.TryGetValue(prefixe & c.Cle, v)
                sb.Append("<td class='n").Append(If(v = "", " zero", "")).Append("'>")
                sb.Append(H(If(v <> "", v, "—"))).Append("</td>")
            Next
            sb.Append("</tr>")
        Next

        Return sb.Append("</tbody></table></div>").ToString()
    End Function

    ''' <summary>
    ''' L'entête d'une colonne : les dates de la déclaration. C'est ce qui la
    ''' distingue des autres, et c'est le repère que l'utilisateur cherche.
    ''' </summary>
    Private Shared Function Entete(c As Colonne) As String
        If IsDBNull(c.Debut) OrElse IsDBNull(c.Fin) Then Return "Période " & c.Periode
        Return Convert.ToDateTime(c.Debut).ToString("d MMM", FrCa) & " – " &
               Convert.ToDateTime(c.Fin).ToString("d MMM yyyy", FrCa)
    End Function

    ''' <summary>
    ''' Le libellé de la ligne, à défaut son code : « Ligne 106 Crédit de taxe
    ''' sur les intrants » porte déjà le sien, on ne le remet pas.
    ''' </summary>
    Private Shared Function Libelle(l As DataRow) As String
        Dim texte As String = Txt(l("Libelle"))
        If texte <> "" Then Return texte

        Dim code As String = Txt(l("LigneCode"))
        Return If(code <> "", code, "—")
    End Function

    ''' <summary>
    ''' La valeur affichée. Le montant quand la cellule se lit comme un nombre,
    ''' la valeur brute sinon : une cellule que la source écrit en toutes
    ''' lettres reste lisible plutôt que de disparaître.
    ''' </summary>
    Private Shared Function Cellule(r As DataRow) As String
        If Not IsDBNull(r("Montant")) Then Return Somme(r("Montant"))
        Return Txt(r("Valeur"))
    End Function

    Private Shared Function Note() As String
        Return "<div class='note'>Chaque colonne est une <b>déclaration</b> : la période telle " &
               "que la source l'a retenue. La fréquence — mensuelle, trimestrielle, annuelle — " &
               "est celle choisie à l'import, parce que QuickBooks ne la déclare nulle part.<br /><br />" &
               "Les colonnes du rapport viennent de la <b>source</b>, avec leur titre d'origine : " &
               "elles changent avec le régime de taxes du pays et de la province. Rien n'est " &
               "présumé ici de leur nombre ni de leur ordre.<br /><br />" &
               "Tout reste en préparation : une nouvelle extraction remplace simplement la " &
               "précédente, et <b>rien ne s'applique à la comptabilité</b>.</div>"
    End Function

    Private Shared Function Vide() As String
        Return "<div class='rien'>Aucun rapport de taxes en préparation.<br />" &
               "Rapatriez-les depuis l'écran <b>Import par connecteur</b>, en indiquant la date " &
               "d'arrêt et la fréquence de vos déclarations.<br /><br />Si l'extraction revient " &
               "vide, c'est que la source ne déclare aucune opération taxée sur l'exercice.</div>"
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

    Private Shared Function Somme(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Return Convert.ToDecimal(v).ToString("N2", FrCa) & " $"
    End Function

    Private Shared Function Jour(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "—"
        Return Convert.ToDateTime(v).ToString("d MMM yyyy", FrCa)
    End Function

End Class
