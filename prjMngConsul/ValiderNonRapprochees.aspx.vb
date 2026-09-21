Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' L'état de pointage importé — ce que la source n'avait pas rapproché.
'''
''' Cet écran ne valide rien et ne crée rien. T142ReleveBancaire, qui porte le
''' relevé de la banque, n'est pas touchée : ce qui est montré ici dit ce que la
''' comptabilité SOURCE tenait pour pointé au moment de la bascule.
'''
''' POURQUOI CE POSTE COMPTE. À la bascule, la base de l'ERP est vide. Le
''' premier rapprochement bancaire confrontera le relevé de la banque à des
''' mouvements qui n'existent pas encore — et sera faux de tous les chèques
''' émis avant la bascule et encaissés après. Savoir lesquels la source tenait
''' pour non pointés, c'est savoir de combien.
'''
''' LA LETTRE EST GARDÉE, PAS SEULEMENT LE OUI/NON. QuickBooks écrit « C » pour
''' une opération compensée et « R » pour une opération rapprochée dans un
''' rapprochement clos. Les deux comptent comme pointées, mais elles ne se
''' valent pas — la nuance est affichée telle quelle.
''' </summary>
Public Class ValiderNonRapprochees
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ' Sur postback aussi : la case a déjà repris sa valeur quand Load
        ' s'exécute, le tableau se refait avec.
        Afficher()
    End Sub

    Private Sub Afficher()
        Dim toutes As Boolean = (chkToutes IsNot Nothing AndAlso chkToutes.Checked)

        Dim ds As DataSet
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@NonPointeesSeulement", CObj(If(toutes, 0, 1))))
            ds = ExecuteSQLds("s0828GetOperationsRapprochement", p)
        Catch ex As Exception
            litTableau.Text = "<div class='rien'>L'état de pointage n'a pas pu être lu : " &
                              H(ex.Message) & "</div>"
            Return
        End Try

        If ds Is Nothing OrElse ds.Tables.Count < 2 OrElse ds.Tables(0).Rows.Count = 0 Then
            litTableau.Text = Vide()
            Return
        End If

        Dim entete As DataRow = ds.Tables(0).Rows(0)
        If Ent(entete("NbOperations")) = 0 Then
            litTableau.Text = Vide()
            Return
        End If

        pnlFiltre.Visible = True
        litRepere.Text = BatirRepere(entete)
        litTableau.Text = BatirTableau(ds.Tables(1), toutes)
        litNote.Text = BatirNote()
    End Sub

    ' =========================================================================
    ' LE RENDU
    ' =========================================================================

    Private Function BatirRepere(r As DataRow) As String
        Dim nonPointees As Integer = Ent(r("NbNonPointees"))

        Dim sb As New StringBuilder("<div class='repere'>")
        sb.Append(BatirBloc("Période", Jour(r("PeriodeDebut")) & " → " & Jour(r("PeriodeFin")), False))
        sb.Append(BatirBloc("Opérations", Txt(r("NbOperations")), False))
        sb.Append(BatirBloc("Non pointées", Txt(nonPointees), nonPointees > 0))
        sb.Append(BatirBloc("Montant en suspens", Somme(r("MontantNonPointe")), nonPointees > 0))
        sb.Append(BatirBloc("Comptes", Txt(r("NbComptes")), False))
        sb.Append(BatirBloc("Déposé", Jour(r("Depose")), False))
        Return sb.Append("</div>").ToString()
    End Function

    Private Shared Function BatirBloc(libelle As String, valeur As String, alerte As Boolean) As String
        Return "<div class='bloc'><div class='l'>" & H(libelle) & "</div><div class='v" &
               If(alerte, " alerte", "") & "'>" & H(If(valeur <> "", valeur, "—")) & "</div></div>"
    End Function

    ''' <summary>
    ''' Les opérations, groupées par compte — c'est compte par compte qu'un
    ''' rapprochement se fait, et un total tous comptes confondus n'aiderait
    ''' personne.
    ''' </summary>
    Private Function BatirTableau(operations As DataTable, toutes As Boolean) As String
        If operations.Rows.Count = 0 Then
            Return "<div class='rien'>Tout est pointé sur la période : rien ne traîne au moment " &
                   "de la bascule.</div>"
        End If

        Dim sb As New StringBuilder()
        sb.Append("<div class='tbl-wrap'><table class='nr'><thead><tr>")
        sb.Append("<th>Date</th><th>Type</th><th>N°</th><th>Tiers</th><th>Mémo</th>")
        sb.Append("<th>Pointage</th><th class='n'>Montant</th>")
        sb.Append("</tr></thead><tbody>")

        Dim compte As String = Nothing
        Dim total As Decimal = 0D
        Dim nb As Integer = 0

        For Each r As DataRow In operations.Rows
            Dim c As String = Txt(r("CompteNom"))
            If c <> compte Then
                compte = c
                sb.Append("<tr class='compte'><td colspan='7'>")
                sb.Append(H(If(c <> "", c, "Sans compte déclaré"))).Append("</td></tr>")
            End If

            Dim pointee As Boolean = (Not IsDBNull(r("EstPointee"))) AndAlso Convert.ToBoolean(r("EstPointee"))
            If Not pointee Then total += Dec(r("Montant"))
            nb += 1

            sb.Append("<tr><td>").Append(H(Jour(r("DateOperation")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(r("TypeOperation")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(r("Numero")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(r("TiersNom")))).Append("</td>")
            sb.Append("<td class='memo'>").Append(H(Txt(r("Memo")))).Append("</td>")
            sb.Append("<td>").Append(NommerPointage(Txt(r("EtatPointage")), pointee)).Append("</td>")
            sb.Append(EcrireMontant(r("Montant")))
            sb.Append("</tr>")
        Next

        sb.Append("</tbody><tfoot><tr><td colspan='6'>Total des non pointées</td>")
        sb.Append("<td class='n'>").Append(Somme(total)).Append("</td></tr></tfoot></table></div>")

        litCompteur.Text = "<span>" & nb & " opération(s) affichée(s)" &
                           If(toutes, "", " — les pointées sont masquées") & "</span>"
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' L'état de pointage, en toutes lettres. La source écrit « C » pour
    ''' compensée et « R » pour rapprochée ; un code d'une lettre ne se lit pas,
    ''' mais il est gardé entre parenthèses pour qui veut vérifier.
    ''' </summary>
    Private Shared Function NommerPointage(lettre As String, pointee As Boolean) As String
        If Not pointee Then Return "<span class='past non'>non pointée</span>"

        Dim mot As String
        Select Case lettre.Trim().ToUpperInvariant()
            Case "R" : mot = "rapprochée"
            Case "C" : mot = "compensée"
            Case Else : mot = "pointée"
        End Select

        Return "<span class='past oui'>" & H(mot) & "</span>"
    End Function

    ''' <summary>Un montant absent ne vaut pas zéro : il s'affiche comme absent.</summary>
    Private Shared Function EcrireMontant(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "<td class='n zero'>—</td>"
        Return "<td class='n'>" & Somme(v) & "</td>"
    End Function

    Private Shared Function BatirNote() As String
        Return "<div class='note'>QuickBooks n'expose pas de rapport « opérations non " &
               "rapprochées » — il expose une <b>colonne</b>, <code>is_cleared</code>, sur la " &
               "liste des opérations. Demandée sous un autre nom, elle est retirée de la " &
               "réponse sans un mot : le lecteur repère donc les colonnes par leur clé et " &
               "s'arrête si celle-ci manque, plutôt que de lire la colonne d'à côté.<br /><br />" &
               "Une opération sans compte bancaire ne peut pas être pointée : elle ressort " &
               "ici comme non pointée, ce qui est exact mais sans conséquence pour le " &
               "rapprochement.<br /><br />" &
               "Rien ne s'applique à la comptabilité : <b>T142ReleveBancaire</b>, qui porte le " &
               "relevé de la banque, n'est pas touchée. Une nouvelle extraction remplace " &
               "simplement la précédente.</div>"
    End Function

    Private Shared Function Vide() As String
        Return "<div class='rien'>Aucun état de pointage en préparation.<br />" &
               "Rapatriez-le depuis l'écran <b>Import par connecteur</b>, en indiquant la date " &
               "d'arrêt — le pointage se lit du 1<sup>er</sup> janvier à cette date.</div>"
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
