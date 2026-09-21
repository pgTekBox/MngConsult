Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Le grand livre importé.
'''
''' Cet écran ne valide rien et ne crée rien, comme la balance âgée : le grand
''' livre est une PIÈCE DE CONTRÔLE. On s'en sert pour confronter une reprise à
''' sa source, jamais pour alimenter la comptabilité — les écritures, les
''' factures et les paiements arrivent par leurs propres imports.
'''
''' LA FORME. QuickBooks rend le grand livre en sections, une par compte, et une
''' même opération y figure sous chacun des comptes qu'elle touche : la facture
''' 1002 apparaît au débit des comptes clients et au crédit des services. C'est
''' la partie double vue compte par compte. La table garde cette forme et
''' l'écran la restitue telle quelle — un grand livre sert à vérifier, pas à
''' réinterpréter.
'''
''' D'où une conséquence à ne pas perdre de vue : le total des débits égale le
''' total des crédits, mais la somme des lignes ne vaut PAS le chiffre
''' d'affaires. Chaque opération est comptée deux fois, une fois de chaque côté.
'''
''' LE FILTRE. Le grand livre est long. Un sélecteur de compte le ramène à ce
''' qu'on cherche ; il passe par un postback ordinaire, la sélection survit dans
''' le ViewState et la page se redessine sur la même extraction.
''' </summary>
Public Class ValiderGrandLivre
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ' Sur postback aussi : la liste déroulante a déjà repris sa nouvelle
        ' valeur quand Load s'exécute, le tableau se refait avec.
        Afficher()
    End Sub

    Private Sub Afficher()
        Dim ds As DataSet
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            ds = ExecuteSQLds("s0821GetGrandLivre", p)
        Catch ex As Exception
            litTableau.Text = "<div class='rien'>Le grand livre n'a pas pu être lu : " &
                              H(ex.Message) & "</div>"
            Return
        End Try

        If ds Is Nothing OrElse ds.Tables.Count < 2 OrElse ds.Tables(1).Rows.Count = 0 Then
            litTableau.Text = Vide()
            Return
        End If

        Dim entete As DataRow = ds.Tables(0).Rows(0)
        Dim lignes As DataTable = ds.Tables(1)

        If Not IsPostBack Then RemplirComptes(lignes)
        pnlFiltre.Visible = True

        litRepere.Text = Repere(entete)
        litTableau.Text = Tableau(lignes)
        litNote.Text = Note()
    End Sub

    ' =========================================================================
    ' LE RENDU
    ' =========================================================================

    ''' <summary>
    ''' Les comptes dans l'ordre où la source les a écrits, pas dans l'ordre
    ''' alphabétique : c'est l'ordre du rapport, et il a un sens comptable.
    ''' </summary>
    Private Sub RemplirComptes(lignes As DataTable)
        ddlCompte.Items.Clear()
        ddlCompte.Items.Add(New ListItem("Tous les comptes", ""))

        Dim vus As New HashSet(Of String)
        For Each r As DataRow In lignes.Rows
            Dim nom As String = Txt(r("CompteNom"))
            If nom = "" OrElse vus.Contains(nom) Then Continue For
            vus.Add(nom)
            ddlCompte.Items.Add(New ListItem(nom, nom))
        Next
    End Sub

    ''' <summary>La période réellement retenue par la source, et ses totaux.</summary>
    Private Function Repere(r As DataRow) As String
        Dim debit As Decimal = Dec(r("TotalDebit"))
        Dim credit As Decimal = Dec(r("TotalCredit"))

        Dim sb As New StringBuilder("<div class='repere'>")
        sb.Append(Bloc("Période", Jour(r("PeriodeDebut")) & " → " & Jour(r("PeriodeFin"))))
        sb.Append(Bloc("Comptes", Txt(r("NbComptes"))))
        sb.Append(Bloc("Écritures", Txt(r("NbLignes"))))
        sb.Append(Bloc("Total débit", Somme(debit)))
        sb.Append(Bloc("Total crédit", Somme(credit)))

        ' L'équilibre est LE contrôle du grand livre : s'il manque, c'est
        ' l'extraction qui est incomplète, pas la comptabilité.
        If Math.Abs(debit - credit) <= 0.01D Then
            sb.Append("<div class='verdict ok'>⚖️ Débits et crédits s'équilibrent</div>")
        Else
            sb.Append("<div class='verdict ko'>⚠️ Écart de ")
            sb.Append(Somme(Math.Abs(debit - credit)))
            sb.Append(" entre débits et crédits</div>")
        End If

        Return sb.Append("</div>").ToString()
    End Function

    Private Shared Function Bloc(libelle As String, valeur As String) As String
        Return "<div class='bloc'><div class='l'>" & H(libelle) & "</div><div class='v'>" &
               H(valeur) & "</div></div>"
    End Function

    ''' <summary>
    ''' Une section par compte, ses opérations, son sous-total. Les lignes
    ''' arrivent déjà ordonnées par la procédure — l'écran ne retrie rien, il
    ''' ouvre une section à chaque changement de compte.
    ''' </summary>
    Private Function Tableau(lignes As DataTable) As String
        Dim voulu As String = If(ddlCompte.SelectedValue, "")

        Dim sb As New StringBuilder()
        sb.Append("<div class='gl-wrap'><table class='gl'><thead><tr>")
        sb.Append("<th>Date</th><th>Type</th><th>N°</th><th>Tiers</th>")
        sb.Append("<th>Mémo</th><th>Contrepartie</th>")
        sb.Append("<th class='n'>Débit</th><th class='n'>Crédit</th>")
        sb.Append("</tr></thead><tbody>")

        Dim compteCourant As String = Nothing
        Dim sdDebit As Decimal = 0D, sdCredit As Decimal = 0D
        Dim totDebit As Decimal = 0D, totCredit As Decimal = 0D
        Dim nbLignes As Integer = 0
        Dim nbComptes As Integer = 0

        For Each r As DataRow In lignes.Rows
            Dim compte As String = Txt(r("CompteNom"))
            If voulu <> "" AndAlso compte <> voulu Then Continue For

            If compte <> compteCourant Then
                If compteCourant IsNot Nothing Then sb.Append(SousTotal(sdDebit, sdCredit))
                compteCourant = compte
                sdDebit = 0D : sdCredit = 0D
                nbComptes += 1
                sb.Append("<tr class='compte'><td colspan='8'>")
                sb.Append(H(If(compte <> "", compte, "(compte sans nom)")))
                sb.Append("</td></tr>")
            End If

            Dim d As Decimal = Dec(r("Debit"))
            Dim c As Decimal = Dec(r("Credit"))
            sdDebit += d : sdCredit += c
            totDebit += d : totCredit += c
            nbLignes += 1

            sb.Append("<tr><td>").Append(H(Jour(r("DateOperation")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(r("TypeOperation")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(r("Numero")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(r("TiersNom")))).Append("</td>")
            sb.Append("<td class='memo'>").Append(H(Txt(r("Memo")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(r("Contrepartie")))).Append("</td>")
            sb.Append(Montant(d)).Append(Montant(c)).Append("</tr>")
        Next

        If compteCourant IsNot Nothing Then sb.Append(SousTotal(sdDebit, sdCredit))

        If nbLignes = 0 Then
            Return "<div class='rien'>Aucune écriture pour ce compte dans l'extraction en cours.</div>"
        End If

        sb.Append("</tbody><tfoot><tr><td colspan='6'>Total</td>")
        sb.Append(Montant(totDebit)).Append(Montant(totCredit))
        sb.Append("</tr></tfoot></table></div>")

        litCompteur.Text = "<span>" & nbLignes & " écriture(s) sur " & nbComptes & " compte(s)</span>"
        Return sb.ToString()
    End Function

    Private Shared Function SousTotal(debit As Decimal, credit As Decimal) As String
        Return "<tr class='soustotal'><td colspan='6'>Sous-total du compte</td>" &
               Montant(debit) & Montant(credit) & "</tr>"
    End Function

    ''' <summary>Un zéro se voit, mais ne se lit pas : il s'efface au gris.</summary>
    Private Shared Function Montant(v As Decimal) As String
        Return "<td class='n" & If(v = 0D, " zero", "") & "'>" & Somme(v) & "</td>"
    End Function

    Private Shared Function Note() As String
        Return "<div class='note'>Le grand livre est <b>redondant par nature</b> : chaque " &
               "opération y figure sous chacun des comptes qu'elle touche, une fois au débit " &
               "et une fois au crédit. C'est pourquoi les deux totaux s'équilibrent — et " &
               "pourquoi ils ne représentent aucun chiffre d'affaires.<br /><br />" &
               "Il porte sur une <b>période</b>, alors que la balance de vérification donne " &
               "des soldes à une <b>date</b>. Les deux n'ont donc pas à coïncider compte par " &
               "compte : les soldes d'ouverture, venus des exercices antérieurs, sont dans la " &
               "balance et pas dans le grand livre de la période. Rien ici ne s'applique à la " &
               "comptabilité — une nouvelle extraction remplace simplement la précédente.</div>"
    End Function

    Private Shared Function Vide() As String
        Return "<div class='rien'>Aucun grand livre en préparation.<br />" &
               "Rapatriez-le depuis l'écran <b>Import par connecteur</b>, en indiquant la " &
               "date d'arrêt — le grand livre se lit du 1<sup>er</sup> janvier à cette date.</div>"
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
