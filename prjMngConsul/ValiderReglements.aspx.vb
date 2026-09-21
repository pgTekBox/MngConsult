Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Les acomptes et règlements partiels importés.
'''
''' Cet écran ne valide rien et ne crée rien : les mouvements restent en
''' préparation, comme les factures qu'ils règlent. Rien ne s'applique à la
''' comptabilité tant que la reprise n'est pas lancée.
'''
''' LES DEUX CAS QUE LE POSTE DOIT RENDRE VISIBLES.
'''
'''   L'ACOMPTE — une part du mouvement ne règle RIEN. MontantNonImpute est
'''   positif : l'argent est entré, mais il ne s'applique encore à aucune
'''   facture. C'est lui qui fait diverger la balance âgée du solde des
'''   factures, et c'est pour ça qu'on le veut en évidence.
'''
'''   LE RÈGLEMENT PARTIEL — une imputation plus petite que le document visé.
'''   Il ne se déduit PAS du mouvement seul : il faut savoir ce que le document
'''   vaut. C'est s0826 qui va le chercher, l'écran ne devine rien.
'''
''' UNE IMPUTATION VERS UN DOCUMENT ABSENT RESTE AFFICHÉE, signalée en rouge.
''' L'écarter cacherait exactement ce qu'il faut voir : il manque une facture
''' dans la reprise.
'''
''' Le sens passe par la requête (?sens=Decaissement) : l'écran reste
''' partageable en lien et le retour arrière du navigateur fonctionne.
''' </summary>
Public Class ValiderReglements
    Inherits clsData

    Private Shared ReadOnly Sens As New Dictionary(Of String, String) From {
        {"Encaissement", "Encaissements"},
        {"Decaissement", "Décaissements"}
    }

    Private ReadOnly Property SensChoisi As String
        Get
            Dim s As String = If(Request.QueryString("sens"), "").Trim()
            Return If(Sens.ContainsKey(s), s, "Encaissement")
        End Get
    End Property

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
            p.Add(New SqlParameter("@Sens", DBNull.Value))
            ds = ExecuteSQLds("s0826GetReglementsImport", p)
        Catch ex As Exception
            litTableau.Text = "<div class='rien'>Les règlements n'ont pas pu être lus : " &
                              H(ex.Message) & "</div>"
            Return
        End Try

        If ds Is Nothing OrElse ds.Tables.Count < 3 Then
            litTableau.Text = Vide()
            Return
        End If

        ' Le premier jeu récapitule chaque sens : il sert aux onglets ET au bandeau.
        litOnglets.Text = BatirOnglets(ds.Tables(0))

        Dim sommaire As DataRow = Nothing
        For Each r As DataRow In ds.Tables(0).Rows
            If Txt(r("Sens")) = SensChoisi Then sommaire = r
        Next

        Dim mouvements As DataRow() = ds.Tables(1).Select("Sens = '" & SensChoisi.Replace("'", "''") & "'")
        If sommaire Is Nothing OrElse mouvements.Length = 0 Then
            litTableau.Text = Vide()
            Return
        End If

        litRepere.Text = BatirRepere(sommaire)
        litTableau.Text = BatirTableau(mouvements, ds.Tables(2))
        litNote.Text = BatirNote()
    End Sub

    ' =========================================================================
    ' LE RENDU
    ' =========================================================================

    Private Function BatirOnglets(sommaires As DataTable) As String
        Dim sb As New StringBuilder("<div class='onglets'>")

        For Each s In Sens
            Dim nb As String = ""
            For Each r As DataRow In sommaires.Rows
                If Txt(r("Sens")) = s.Key Then nb = Txt(r("NbMouvements")) & " mouvement(s)"
            Next

            sb.Append("<a href='ValiderReglements.aspx?sens=").Append(s.Key).Append("'")
            If s.Key = SensChoisi Then sb.Append(" class='on'")
            sb.Append(">").Append(H(s.Value))
            sb.Append("<span class='n'>").Append(H(If(nb <> "", nb, "aucun"))).Append("</span>")
            sb.Append("</a>")
        Next

        Return sb.Append("</div>").ToString()
    End Function

    ''' <summary>Ce que le sens totalise, et ce qui ne règle encore rien.</summary>
    Private Function BatirRepere(r As DataRow) As String
        Dim acomptes As Decimal = Dec(r("TotalAcomptes"))

        Dim sb As New StringBuilder("<div class='repere'>")
        sb.Append(BatirBloc("Mouvements", Txt(r("NbMouvements")), False))
        sb.Append(BatirBloc("Total", Somme(r("Total")), False))
        sb.Append(BatirBloc("Imputations", Txt(r("NbImputations")), False))
        sb.Append(BatirBloc("En acompte", Somme(acomptes), acomptes > 0.01D))
        sb.Append(BatirBloc("Dont acomptes", Txt(r("NbAcomptes")), Ent(r("NbAcomptes")) > 0))
        If Ent(r("NbAnomalies")) > 0 Then
            sb.Append(BatirBloc("À corriger", Txt(r("NbAnomalies")), True))
        End If
        Return sb.Append("</div>").ToString()
    End Function

    Private Shared Function BatirBloc(libelle As String, valeur As String, alerte As Boolean) As String
        Return "<div class='bloc'><div class='l'>" & H(libelle) & "</div><div class='v" &
               If(alerte, " alerte", "") & "'>" & H(If(valeur <> "", valeur, "—")) & "</div></div>"
    End Function

    ''' <summary>
    ''' Chaque mouvement, puis ses imputations juste en dessous. Une imputation
    ''' n'a pas de sens détachée de son mouvement — les mettre dans une table à
    ''' part obligerait à faire le rapprochement de tête.
    ''' </summary>
    Private Function BatirTableau(mouvements As DataRow(), imputations As DataTable) As String
        Dim sb As New StringBuilder()
        sb.Append("<div class='tbl-wrap'><table class='rg'><thead><tr>")
        sb.Append("<th>Date</th><th>Référence</th><th>Tiers</th><th>Mode</th>")
        sb.Append("<th class='n'>Montant</th><th class='n'>Imputé</th><th class='n'>Acompte</th>")
        sb.Append("</tr></thead><tbody>")

        Dim totalMontant As Decimal = 0D
        Dim totalImpute As Decimal = 0D
        Dim totalAcompte As Decimal = 0D

        For Each m As DataRow In mouvements
            Dim id As Integer = Ent(m("Id"))
            Dim montant As Decimal = Dec(m("Montant"))
            Dim acompte As Decimal = Dec(m("MontantNonImpute"))

            Dim lignes As DataRow() = imputations.Select("PaiementId = " & id, "Rang")
            Dim impute As Decimal = 0D
            For Each a As DataRow In lignes
                impute += Dec(a("Montant"))
            Next

            totalMontant += montant
            totalImpute += impute
            totalAcompte += acompte

            sb.Append("<tr class='mvt'><td>").Append(H(Jour(m("DatePaiement")))).Append("</td>")
            sb.Append("<td class='ref'>").Append(H(Txt(m("Reference"))))
            If acompte > 0.01D Then sb.Append("<span class='past acompte'>acompte</span>")
            sb.Append("</td>")
            sb.Append("<td>").Append(H(Txt(m("TiersNom")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(m("ModePaiementNom")))).Append("</td>")
            sb.Append("<td class='n'>").Append(Somme(montant)).Append("</td>")
            sb.Append(EcrireMontant(impute))
            sb.Append(EcrireMontant(acompte))
            sb.Append("</tr>")

            If lignes.Length = 0 Then
                sb.Append("<tr class='imput'><td colspan='4' class='doc'>")
                sb.Append("<span class='fil'>N'impute aucun document</span>")
                sb.Append("<span class='past acompte'>acompte entier</span></td>")
                sb.Append("<td colspan='3'></td></tr>")
            End If

            For Each a As DataRow In lignes
                sb.Append(BatirImputation(a))
            Next
        Next

        sb.Append("</tbody><tfoot><tr><td colspan='4'>Total</td>")
        sb.Append("<td class='n'>").Append(Somme(totalMontant)).Append("</td>")
        sb.Append("<td class='n'>").Append(Somme(totalImpute)).Append("</td>")
        sb.Append("<td class='n'>").Append(Somme(totalAcompte)).Append("</td>")
        sb.Append("</tr></tfoot></table></div>")

        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Une imputation, et le verdict qui va avec. Le montant du document vient
    ''' de s0826 : sans lui on ne pourrait pas dire « partiel », seulement
    ''' répéter un chiffre.
    ''' </summary>
    Private Shared Function BatirImputation(a As DataRow) As String
        Dim paye As Decimal = Dec(a("Montant"))
        Dim absent As Boolean = IsDBNull(a("DocumentTotal"))
        Dim total As Decimal = Dec(a("DocumentTotal"))

        Dim sb As New StringBuilder("<tr class='imput'><td colspan='4' class='doc'>")
        sb.Append("<span class='fil'>↳ ").Append(H(NommerType(Txt(a("DocumentType")))))
        sb.Append(" </span>").Append(H(Txt(a("DocumentNumero"))))

        If absent Then
            sb.Append("<span class='past absent'>document absent de la reprise</span>")
        ElseIf paye < total - 0.01D Then
            sb.Append("<span class='past partiel'>partiel sur ").Append(Somme(total)).Append("</span>")
        ElseIf paye >= total - 0.01D Then
            sb.Append("<span class='past solde'>soldé</span>")
        End If

        sb.Append("</td><td class='n'></td>")
        sb.Append("<td class='n'>").Append(Somme(paye)).Append("</td>")
        sb.Append("<td class='n'></td></tr>")
        Return sb.ToString()
    End Function

    ''' <summary>Le type du document, dans la langue de l'écran.</summary>
    Private Shared Function NommerType(t As String) As String
        Select Case t
            Case "Invoice" : Return "facture"
            Case "Bill" : Return "facture fournisseur"
            Case "CreditMemo" : Return "note de crédit"
            Case "" : Return "document"
            Case Else : Return t
        End Select
    End Function

    ''' <summary>
    ''' Un zéro se voit, mais ne se lit pas : il s'efface au gris.
    '''
    ''' Nommée par un VERBE : « Montant » se serait fait avaler par la variable
    ''' locale « montant » de BatirTableau — VB ignore la casse, et avec
    ''' Option Strict Off le compilateur ne dit rien.
    ''' </summary>
    Private Shared Function EcrireMontant(v As Decimal) As String
        Return "<td class='n" & If(v = 0D, " zero", "") & "'>" & Somme(v) & "</td>"
    End Function

    Private Shared Function BatirNote() As String
        Return "<div class='note'>Un <b>acompte</b> est de l'argent qui ne règle encore rien : " &
               "il entre au compte du tiers sans s'appliquer à une facture. C'est lui qui " &
               "explique qu'une balance âgée annonce moins que la somme des factures — et il " &
               "doit être repris, sans quoi le tiers paiera deux fois.<br /><br />" &
               "Un <b>règlement partiel</b> est une imputation plus petite que le document " &
               "visé. Le montant du document vient de la préparation, pas d'une supposition : " &
               "une imputation dont le document n'a pas été repris est signalée en rouge plutôt " &
               "que passée sous silence.<br /><br />" &
               "Rien ici ne s'applique à la comptabilité : les mouvements restent en " &
               "préparation, et une nouvelle extraction remplace la précédente.</div>"
    End Function

    Private Function Vide() As String
        Return "<div class='rien'>Aucun " & H(Sens(SensChoisi).ToLowerInvariant().TrimEnd("s"c)) &
               " en préparation.<br />Rapatriez-les depuis l'écran <b>Import par connecteur</b>." &
               "<br /><br />Si l'extraction revient vide, c'est que la comptabilité source ne " &
               "porte aucun règlement — ce qui arrive quand toutes les factures sont encore dues.</div>"
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
