Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Les remises de DAS importées.
'''
''' Cet écran ne valide rien et ne crée rien : ni écriture comptable, ni ligne
''' dans paie.Paie. C'est une pièce de contrôle, remplacée à chaque extraction.
'''
''' CE QU'IL SERT À VOIR. Les déductions à la source s'accumulent au CRÉDIT d'un
''' compte de passif à chaque paie, et s'éteignent au DÉBIT à chaque remise. La
''' différence est une dette envers le fédéral et le Québec — et c'est elle que
''' la bascule doit reprendre. L'oublier, c'est une première remise fausse dans
''' l'application, et deux gouvernements qui le remarquent.
'''
''' POURQUOI ÇA VIENT DE LA COMPTABILITÉ. La paie de QuickBooks est un produit
''' séparé : l'API HRIS d'Apideck répond 401 et le compte n'a qu'une connexion,
''' « accounting / quickbooks ». Mais une remise est aussi un PAIEMENT, et les
''' paiements sont dans le grand livre. C'est par là qu'on passe.
'''
''' « AUTRE » N'EST PAS UNE ERREUR, C'EST UN AVEU. L'autorité est devinée au nom
''' du compte. Un compte qui ne tranche pas — « Retenues à la source », sans
''' plus — ressort en « Autre » et s'affiche à part, en ambre. Le ranger de
''' force du mauvais côté ferait deux déclarations fausses ; le montrer à
''' classer n'en fait aucune.
''' </summary>
Public Class ValiderRemisesDas
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
            ds = ExecuteSQLds("s0832GetRemisesDas", p)
        Catch ex As Exception
            litTableau.Text = "<div class='rien'>Les remises n'ont pas pu être lues : " &
                              H(ex.Message) & "</div>"
            Return
        End Try

        If ds Is Nothing OrElse ds.Tables.Count < 3 OrElse ds.Tables(0).Rows.Count = 0 Then
            litTableau.Text = Vide()
            Return
        End If

        Dim entete As DataRow = ds.Tables(0).Rows(0)
        If Ent(entete("NbMouvements")) = 0 Then
            litTableau.Text = Vide()
            Return
        End If

        litRepere.Text = BatirRepere(entete)
        litDus.Text = BatirDus(ds.Tables(1))
        litTableau.Text = BatirTableau(ds.Tables(2))
        litNote.Text = BatirNote()
    End Sub

    ' =========================================================================
    ' LE RENDU
    ' =========================================================================

    Private Function BatirRepere(r As DataRow) As String
        Dim aClasser As Integer = Ent(r("NbAClasser"))

        Dim sb As New StringBuilder("<div class='repere'>")
        sb.Append(BatirBloc("Période", Jour(r("PeriodeDebut")) & " → " & Jour(r("PeriodeFin")), False))
        sb.Append(BatirBloc("Mouvements", Txt(r("NbMouvements")), False))
        sb.Append(BatirBloc("Retenu", Somme(r("TotalRetenu")), False))
        sb.Append(BatirBloc("Remis", Somme(r("TotalRemis")), False))
        sb.Append(BatirBloc("Reste dû", Somme(r("ResteDu")), Dec(r("ResteDu")) > 0.01D))
        If aClasser > 0 Then sb.Append(BatirBloc("À classer", Txt(aClasser), True))
        sb.Append(BatirBloc("Déposé", Jour(r("Depose")), False))
        Return sb.Append("</div>").ToString()
    End Function

    Private Shared Function BatirBloc(libelle As String, valeur As String, alerte As Boolean) As String
        Return "<div class='bloc'><div class='l'>" & H(libelle) & "</div><div class='v" &
               If(alerte, " alerte", "") & "'>" & H(If(valeur <> "", valeur, "—")) & "</div></div>"
    End Function

    ''' <summary>
    ''' Une carte par autorité : retenu, remis, et ce qui reste. C'est le
    ''' résumé qu'on vient chercher — le détail est en dessous pour qui veut
    ''' vérifier.
    ''' </summary>
    Private Function BatirDus(soldes As DataTable) As String
        If soldes.Rows.Count = 0 Then Return ""

        Dim sb As New StringBuilder("<div class='dus'>")
        For Each r As DataRow In soldes.Rows
            Dim code As String = Txt(r("Autorite"))
            sb.Append("<div class='du ").Append(ClasseAutorite(code)).Append("'>")
            sb.Append("<h2>").Append(H(NommerAutorite(code))).Append("</h2>")

            sb.Append(BatirLigneCarte("Retenu sur la paie", Somme(r("Retenu"))))
            sb.Append(BatirLigneCarte("Déjà remis", Somme(r("Remis"))))
            sb.Append(BatirLigneCarte(Txt(r("NbRemises")) & " remise(s), dernier mouvement",
                                      Jour(r("DerniereOperation"))))

            sb.Append("<div class='reste'><span>Reste dû</span>")
            sb.Append("<span class='m'>").Append(Somme(r("ResteDu"))).Append("</span></div>")
            sb.Append("</div>")
        Next
        Return sb.Append("</div>").ToString()
    End Function

    Private Shared Function BatirLigneCarte(libelle As String, valeur As String) As String
        Return "<div class='l2'><span>" & H(libelle) & "</span><b>" & H(valeur) & "</b></div>"
    End Function

    ''' <summary>
    ''' Le détail, groupé par autorité. Le crédit accumule, le débit éteint :
    ''' les deux colonnes sont gardées séparées plutôt qu'un montant signé, le
    ''' signe d'un passif se lisant à l'envers assez souvent pour qu'on ne s'y
    ''' fie pas.
    ''' </summary>
    Private Function BatirTableau(mouvements As DataTable) As String
        If mouvements.Rows.Count = 0 Then
            Return "<div class='rien'>Aucun mouvement de retenues sur la période.</div>"
        End If

        Dim sb As New StringBuilder()
        sb.Append("<div class='tbl-wrap'><table class='ds'><thead><tr>")
        sb.Append("<th>Date</th><th>Type</th><th>N°</th><th>Bénéficiaire</th><th>Mémo</th>")
        sb.Append("<th></th><th class='n'>Retenu</th><th class='n'>Remis</th>")
        sb.Append("</tr></thead><tbody>")

        Dim autorite As String = Nothing
        Dim tRetenu As Decimal = 0D, tRemis As Decimal = 0D

        For Each r As DataRow In mouvements.Rows
            Dim a As String = Txt(r("Autorite"))
            If a <> autorite Then
                autorite = a
                sb.Append("<tr class='aut ").Append(ClasseAutorite(a)).Append("'><td colspan='8'>")
                sb.Append(H(NommerAutorite(a)))
                sb.Append(" <span class='fil'>— ").Append(H(Txt(r("CompteNom")))).Append("</span>")
                sb.Append("</td></tr>")
            End If

            Dim remise As Boolean = (Not IsDBNull(r("EstRemise"))) AndAlso Convert.ToBoolean(r("EstRemise"))
            tRetenu += Dec(r("Credit"))
            tRemis += Dec(r("Debit"))

            sb.Append("<tr><td>").Append(H(Jour(r("DateOperation")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(r("TypeOperation")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(r("Numero")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(r("TiersNom")))).Append("</td>")
            sb.Append("<td class='memo'>").Append(H(Txt(r("Memo")))).Append("</td>")
            sb.Append("<td>").Append(If(remise, "<span class='past remise'>remise</span>",
                                        "<span class='past retenue'>retenue</span>")).Append("</td>")
            sb.Append(EcrireMontant(r("Credit")))
            sb.Append(EcrireMontant(r("Debit")))
            sb.Append("</tr>")
        Next

        sb.Append("</tbody><tfoot><tr><td colspan='6'>Total — reste dû ")
        sb.Append(Somme(tRetenu - tRemis)).Append("</td>")
        sb.Append("<td class='n'>").Append(Somme(tRetenu)).Append("</td>")
        sb.Append("<td class='n'>").Append(Somme(tRemis)).Append("</td>")
        sb.Append("</tr></tfoot></table></div>")

        Return sb.ToString()
    End Function

    ''' <summary>L'autorité, en toutes lettres.</summary>
    Private Shared Function NommerAutorite(code As String) As String
        Select Case code
            Case "Federal" : Return "Fédéral — Receveur général du Canada"
            Case "Quebec" : Return "Québec — Revenu Québec"
            Case Else : Return "À classer — l'autorité ne se devine pas au nom du compte"
        End Select
    End Function

    Private Shared Function ClasseAutorite(code As String) As String
        Select Case code
            Case "Federal" : Return "federal"
            Case "Quebec" : Return "quebec"
            Case Else : Return "autre"
        End Select
    End Function

    ''' <summary>Un zéro se voit, mais ne se lit pas : il s'efface au gris.</summary>
    Private Shared Function EcrireMontant(v As Object) As String
        Dim d As Decimal = Dec(v)
        If d = 0D Then Return "<td class='n zero'>—</td>"
        Return "<td class='n'>" & Somme(d) & "</td>"
    End Function

    Private Shared Function BatirNote() As String
        Return "<div class='note'>Ces mouvements viennent du <b>grand livre</b>, pas de la paie : " &
               "QuickBooks n'expose pas ses remises comme objets de paie — l'API HRIS d'Apideck " &
               "répond 401 et le compte n'a qu'une connexion comptable. Mais une remise est un " &
               "paiement, et les paiements sont au grand livre.<br /><br />" &
               "Les comptes de retenues sont reconnus à leur nom, et l'autorité déduite de la " &
               "même façon. Ce qui ne tranche pas ressort <b>« À classer »</b> plutôt que d'être " &
               "rangé de force : une remise fédérale comptée au Québec, c'est deux déclarations " &
               "fausses.<br /><br />" &
               "Rien ne s'applique — ni à la comptabilité, ni à <b>paie.Paie</b>. Une nouvelle " &
               "extraction remplace simplement la précédente.</div>"
    End Function

    Private Shared Function Vide() As String
        Return "<div class='rien'>Aucune remise de DAS en préparation.<br />" &
               "Rapatriez-les depuis l'écran <b>Import par connecteur</b>, en indiquant la date " &
               "d'arrêt.<br /><br />Si l'extraction revient vide, c'est que la comptabilité " &
               "source ne tient aucun compte de retenues à la source — ce qui arrive quand la " &
               "paie est tenue ailleurs.</div>"
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

    Private Shared Function Jour(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "—"
        Return Convert.ToDateTime(v).ToString("d MMM yyyy", FrCa)
    End Function

End Class
