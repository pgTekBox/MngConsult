Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Les comptes et soldes bancaires importés.
'''
''' Cet écran ne valide rien et ne crée rien — comme le grand livre et les
''' déclarations de taxes. Tout reste en PRÉPARATION : aucune écriture, aucun
''' compte créé, aucun relevé posé. La comptabilité de l'application n'en sait
''' rien.
'''
''' CE N'EST PAS LE RAPPROCHEMENT. QuickBooks n'expose ni le rapport de
''' rapprochement ni l'état « pointé » d'une opération — la colonne est
''' silencieusement retirée quand on la demande. Et un relevé bancaire vient de
''' LA BANQUE : le fabriquer à partir des mouvements comptables de la source
''' reviendrait à rapprocher les livres d'eux-mêmes.
'''
''' DEUX SOLDES, ET ON NE LES ADDITIONNE PAS PAREIL. « Solde » est celui du
''' compte seul ; « avec sous-comptes » y ajoute ses enfants. Le total du bas
''' somme la PREMIÈRE colonne sur les comptes actifs : additionner la seconde
''' compterait deux fois l'argent d'une hiérarchie.
''' </summary>
Public Class ValiderSoldesBancaires
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
            ds = ExecuteSQLds("s0825GetComptesBancaires", p)
        Catch ex As Exception
            litTableau.Text = "<div class='rien'>Les soldes bancaires n'ont pas pu être lus : " &
                              H(ex.Message) & "</div>"
            Return
        End Try

        If ds Is Nothing OrElse ds.Tables.Count < 2 OrElse ds.Tables(1).Rows.Count = 0 Then
            litTableau.Text = Vide()
            Return
        End If

        litRepere.Text = Repere(ds.Tables(0).Rows(0))
        litTableau.Text = Tableau(ds.Tables(1))
        litNote.Text = Note()
    End Sub

    ' =========================================================================
    ' LE RENDU
    ' =========================================================================

    Private Function Repere(r As DataRow) As String
        Dim sb As New StringBuilder("<div class='repere'>")
        sb.Append(Bloc("Comptes", Txt(r("NbComptes"))))
        sb.Append(Bloc("Actifs", Txt(r("NbActifs"))))
        If Ent(r("NbCartes")) > 0 Then sb.Append(Bloc("Cartes de crédit", Txt(r("NbCartes"))))
        sb.Append(Bloc("Total des actifs", Somme(r("TotalSoldes"))))
        sb.Append(Bloc("Arrêté le", Instant(r("ArreteLe"))))
        Return sb.Append("</div>").ToString()
    End Function

    Private Shared Function Bloc(libelle As String, valeur As String) As String
        Return "<div class='bloc'><div class='l'>" & H(libelle) & "</div><div class='v'>" &
               H(If(valeur <> "", valeur, "—")) & "</div></div>"
    End Function

    ''' <summary>
    ''' Les comptes, groupés par genre — la banque et la carte de crédit ne se
    ''' lisent pas de la même façon : sur l'une un solde positif est de
    ''' l'argent, sur l'autre c'est une dette.
    ''' </summary>
    Private Function Tableau(comptes As DataTable) As String
        Dim sb As New StringBuilder("<table class='sb'><thead><tr>")
        sb.Append("<th>Compte</th><th>Nº</th><th>Nature</th><th>Devise</th>")
        sb.Append("<th class='n'>Solde</th><th class='n'>Avec sous-comptes</th>")
        sb.Append("</tr></thead><tbody>")

        Dim genre As String = Nothing
        Dim total As Decimal = 0D

        For Each r As DataRow In comptes.Rows
            Dim g As String = Txt(r("TypeCompte"))
            If g <> genre Then
                genre = g
                sb.Append("<tr class='genre'><td colspan='6'>").Append(H(NommerGenre(g))).Append("</td></tr>")
            End If

            Dim actif As Boolean = (Not IsDBNull(r("Actif"))) AndAlso Convert.ToBoolean(r("Actif"))
            If actif Then total += Dec(r("SoldeCourant"))

            sb.Append("<tr").Append(If(actif, "", " class='inactif'")).Append(">")

            ' Un sous-compte se lit sous son parent : l'indentation le dit mieux
            ' qu'une colonne de plus.
            Dim sous As Boolean = (Not IsDBNull(r("EstSousCompte"))) AndAlso Convert.ToBoolean(r("EstSousCompte"))
            sb.Append("<td class='nom'").Append(If(sous, " style='padding-left:28px'", "")).Append(">")
            If sous Then sb.Append("<span class='fil'>↳ </span>")
            sb.Append(H(Txt(r("Nom"))))
            If Not actif Then sb.Append("<span class='pastille off'>inactif</span>")
            Dim desc As String = Txt(r("Description"))
            If desc <> "" Then sb.Append("<div class='fil'>").Append(H(desc)).Append("</div>")
            sb.Append("</td>")

            sb.Append("<td>").Append(H(Txt(r("Numero")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(r("SousType")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(r("Devise")))).Append("</td>")
            sb.Append(Montant(r("SoldeCourant")))
            sb.Append(Montant(r("SoldeAvecSous")))
            sb.Append("</tr>")
        Next

        sb.Append("</tbody><tfoot><tr><td colspan='4'>Total des comptes actifs</td>")
        sb.Append("<td class='n'>").Append(Somme(total)).Append("</td><td></td></tr></tfoot></table>")
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Le genre, dans la langue de l'écran.
    '''
    ''' Nommée par un VERBE, et pas « Genre » : VB ignore la casse, et une
    ''' fonction homonyme d'une variable locale se fait avaler par elle. Avec
    ''' Option Strict Off le compilateur ne dit rien — « Genre(g) » devient une
    ''' indexation de chaîne, et l'écran tombe à l'exécution sur une conversion
    ''' de « Bank » en entier. C'est arrivé ici.
    ''' </summary>
    Private Shared Function NommerGenre(g As String) As String
        Select Case g
            Case "Bank" : Return "Comptes de banque"
            Case "Credit Card" : Return "Cartes de crédit"
            Case "" : Return "Sans nature déclarée"
            Case Else : Return g
        End Select
    End Function

    ''' <summary>Un zéro se voit, mais ne se lit pas : il s'efface au gris.</summary>
    Private Shared Function Montant(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "<td class='n zero'>—</td>"
        Dim d As Decimal = Convert.ToDecimal(v)
        Return "<td class='n" & If(d = 0D, " zero", "") & "'>" & Somme(d) & "</td>"
    End Function

    Private Shared Function Note() As String
        Return "<div class='note'>Le solde est celui de <b>l'instant de l'extraction</b>, pas " &
               "celui de la date de bascule : QuickBooks rend le solde d'aujourd'hui sur le " &
               "compte, jamais celui d'une date passée. Pour un solde arrêté, c'est la balance " &
               "de vérification qu'il faut lire.<br /><br />" &
               "Ce relevé <b>n'est pas un rapprochement</b> et ne peut pas le devenir : la " &
               "source n'expose ni son rapport de rapprochement ni l'état « pointé » de ses " &
               "opérations. Et un relevé bancaire vient de la banque — le fabriquer à partir " &
               "des mouvements comptables reviendrait à rapprocher les livres d'eux-mêmes.<br /><br />" &
               "Le total ne somme que la colonne <b>Solde</b>, sur les comptes actifs : " &
               "additionner « avec sous-comptes » compterait deux fois l'argent d'une " &
               "hiérarchie. Rien ici ne s'applique à la comptabilité — une nouvelle extraction " &
               "remplace simplement la précédente.</div>"
    End Function

    Private Shared Function Vide() As String
        Return "<div class='rien'>Aucun compte bancaire en préparation.<br />" &
               "Rapatriez-les depuis l'écran <b>Import par connecteur</b>.<br /><br />" &
               "Si l'extraction revient vide, c'est que la comptabilité source ne tient aucun " &
               "compte de banque ni de carte de crédit — ce qui arrive sur une compagnie neuve, " &
               "où les paiements sont encore portés à un compte d'attente.</div>"
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

    Private Shared Function Instant(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "—"
        Return Convert.ToDateTime(v).ToString("d MMM yyyy 'à' HH:mm", FrCa)
    End Function

End Class
