Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' La paie importée — employés, lots, paies et leurs talons.
'''
''' Cet écran ne valide rien et ne crée rien. paie.Employe_V1, paie.LotPaie,
''' paie.Paie et paie.PaieLigne ne sont pas touchées : une paie reprise doit
''' être relue avant d'exister, parce qu'un net mal repris, c'est un employé
''' mal payé et un relevé d'emploi faux.
'''
''' ON NE RECALCULE RIEN. Les montants sont affichés tels que la source les a
''' donnés. Recalculer une paie déjà versée la ferait diverger du T4 et du
''' relevé 1 déjà produits — et ce sont eux qui font foi auprès des deux
''' gouvernements. L'équilibre est vérifié à l'arrivée par s0829 : un écart est
''' SIGNALÉ, jamais corrigé, et la paie fautive remonte en tête de liste.
'''
''' DEUX CHOSES NE SONT PAS REPRISES, ET C'EST VOULU : le NAS et le numéro de
''' compte bancaire. Seuls un indicateur et le couple institution-transit sont
''' gardés — de quoi savoir ce qu'il restera à saisir, sans détenir ce qu'on
''' n'a pas besoin de détenir.
'''
''' La vue passe par la requête (?vue=employes) : l'écran reste partageable en
''' lien et le retour arrière du navigateur fonctionne.
''' </summary>
Public Class ValiderPaie
    Inherits clsData

    Private Shared ReadOnly Vues As New Dictionary(Of String, String) From {
        {"paies", "Paies"},
        {"employes", "Employés"}
    }

    Private ReadOnly Property VueChoisie As String
        Get
            Dim v As String = If(Request.QueryString("vue"), "").Trim().ToLowerInvariant()
            Return If(Vues.ContainsKey(v), v, "paies")
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
            ds = ExecuteSQLds("s0830GetPaie", p)
        Catch ex As Exception
            litTableau.Text = "<div class='rien'>La paie n'a pas pu être lue : " &
                              H(ex.Message) & "</div>"
            Return
        End Try

        If ds Is Nothing OrElse ds.Tables.Count < 5 OrElse ds.Tables(0).Rows.Count = 0 Then
            litTableau.Text = Vide()
            Return
        End If

        Dim entete As DataRow = ds.Tables(0).Rows(0)
        If Ent(entete("NbPaies")) = 0 AndAlso Ent(entete("NbEmployes")) = 0 Then
            litTableau.Text = Vide()
            Return
        End If

        litOnglets.Text = BatirOnglets(entete)
        litRepere.Text = BatirRepere(entete)

        If VueChoisie = "employes" Then
            litTableau.Text = BatirEmployes(ds.Tables(1))
        Else
            litTableau.Text = BatirPaies(ds.Tables(2), ds.Tables(3), ds.Tables(4))
        End If

        litNote.Text = BatirNote()
    End Sub

    ' =========================================================================
    ' LE RENDU
    ' =========================================================================

    Private Function BatirOnglets(entete As DataRow) As String
        Dim compte As New Dictionary(Of String, String) From {
            {"paies", Txt(entete("NbPaies")) & " paie(s)"},
            {"employes", Txt(entete("NbEmployes")) & " employé(s)"}
        }

        Dim sb As New StringBuilder("<div class='onglets'>")
        For Each v In Vues
            sb.Append("<a href='ValiderPaie.aspx?vue=").Append(v.Key).Append("'")
            If v.Key = VueChoisie Then sb.Append(" class='on'")
            sb.Append(">").Append(H(v.Value))
            sb.Append("<span class='n'>").Append(H(compte(v.Key))).Append("</span></a>")
        Next
        Return sb.Append("</div>").ToString()
    End Function

    Private Function BatirRepere(r As DataRow) As String
        Dim anomalies As Integer = Ent(r("NbAnomalies"))

        Dim sb As New StringBuilder("<div class='repere'>")
        sb.Append(BatirBloc("Employés", Txt(r("NbEmployes")), False))
        sb.Append(BatirBloc("Lots", Txt(r("NbLots")), False))
        sb.Append(BatirBloc("Paies", Txt(r("NbPaies")), False))
        sb.Append(BatirBloc("Brut versé", Somme(r("TotalBrut")), False))
        sb.Append(BatirBloc("Net versé", Somme(r("TotalNet")), False))
        sb.Append(BatirBloc("Charges patronales", Somme(r("TotalCharges")), False))
        If anomalies > 0 Then sb.Append(BatirBloc("À corriger", Txt(anomalies), True))
        sb.Append(BatirBloc("Déposé", Jour(r("Depose")), False))
        Return sb.Append("</div>").ToString()
    End Function

    Private Shared Function BatirBloc(libelle As String, valeur As String, alerte As Boolean) As String
        Return "<div class='bloc'><div class='l'>" & H(libelle) & "</div><div class='v" &
               If(alerte, " alerte", "") & "'>" & H(If(valeur <> "", valeur, "—")) & "</div></div>"
    End Function

    ''' <summary>
    ''' Les paies, groupées par lot, avec le talon de chacune juste en dessous.
    ''' Un talon détaché de sa paie obligerait à faire le rapprochement de tête.
    ''' </summary>
    Private Function BatirPaies(lots As DataTable, paies As DataTable, lignes As DataTable) As String
        If paies.Rows.Count = 0 Then
            Return "<div class='rien'>Aucune paie en préparation.</div>"
        End If

        Dim sb As New StringBuilder()
        sb.Append("<div class='tbl-wrap'><table class='pa'><thead><tr>")
        sb.Append("<th>Employé</th><th class='n'>Heures</th><th class='n'>Brut</th>")
        sb.Append("<th class='n'>Féd.</th><th class='n'>Québec</th><th class='n'>RRQ</th>")
        sb.Append("<th class='n'>AE</th><th class='n'>RQAP</th><th class='n'>Net</th>")
        sb.Append("<th class='n'>Charges</th>")
        sb.Append("</tr></thead><tbody>")

        Dim lot As String = Nothing
        Dim tBrut As Decimal = 0D, tNet As Decimal = 0D, tCharges As Decimal = 0D

        For Each p As DataRow In paies.Rows
            Dim cle As String = Txt(p("LotExterneId"))
            If cle <> lot Then
                lot = cle
                sb.Append("<tr class='lot'><td colspan='10'>").Append(H(NommerLot(lots, cle))).Append("</td></tr>")
            End If

            Dim mauvaise As Boolean = (Txt(p("Statut")) <> "OK")
            tBrut += Dec(p("BrutVerse"))
            tNet += Dec(p("Net"))
            tCharges += Dec(p("ChargesEmployeur"))

            sb.Append("<tr class='paie").Append(If(mauvaise, " ko", "")).Append("'>")
            sb.Append("<td class='nom'>").Append(H(Txt(p("EmployeNom"))))
            If mauvaise Then sb.Append("<span class='past ko'>écart de ").Append(Somme(p("EcartNet"))).Append("</span>")
            Dim cheque As String = Txt(p("NumeroCheque"))
            If cheque <> "" Then sb.Append("<div class='fil'>chèque ").Append(H(cheque)).Append("</div>")
            sb.Append("</td>")

            sb.Append(EcrireNombre(p("Heures")))
            sb.Append(EcrireMontant(p("BrutVerse")))
            sb.Append(EcrireMontant(p("ImpotFederal")))
            sb.Append(EcrireMontant(p("ImpotQuebec")))
            sb.Append(EcrireMontant(p("RRQ")))
            sb.Append(EcrireMontant(p("AE")))
            sb.Append(EcrireMontant(p("RQAP")))
            sb.Append(EcrireMontant(p("Net")))
            sb.Append(EcrireMontant(p("ChargesEmployeur")))
            sb.Append("</tr>")

            If mauvaise Then
                sb.Append("<tr class='ligne'><td colspan='10' class='el'><span class='neg'>")
                sb.Append(H(Txt(p("Anomalie")))).Append("</span></td></tr>")
            End If

            For Each l As DataRow In lignes.Select("PaieExterneId = '" & Txt(p("ExterneId")).Replace("'", "''") & "'", "Rang")
                sb.Append(BatirLigne(l))
            Next
        Next

        sb.Append("</tbody><tfoot><tr><td colspan='2'>Total</td>")
        sb.Append("<td class='n'>").Append(Somme(tBrut)).Append("</td>")
        sb.Append("<td colspan='5'></td>")
        sb.Append("<td class='n'>").Append(Somme(tNet)).Append("</td>")
        sb.Append("<td class='n'>").Append(Somme(tCharges)).Append("</td>")
        sb.Append("</tr></tfoot></table></div>")

        Return sb.ToString()
    End Function

    ''' <summary>Une ligne de talon : son libellé, ses heures, son taux, son montant.</summary>
    Private Shared Function BatirLigne(l As DataRow) As String
        Dim sb As New StringBuilder("<tr class='ligne'><td colspan='2' class='el'>")
        sb.Append("<span class='fil'>↳ </span>").Append(H(Txt(l("Description"))))
        Dim code As String = Txt(l("ElementCode"))
        If code <> "" Then sb.Append(" <span class='fil'>(").Append(H(code)).Append(")</span>")

        Dim heures As String = Nombre(l("Heures"))
        Dim taux As String = Nombre(l("Taux"))
        If heures <> "" AndAlso taux <> "" Then
            sb.Append(" <span class='fil'>").Append(H(heures)).Append(" h × ").Append(H(taux)).Append(" $</span>")
        End If

        sb.Append("</td><td class='n'>").Append(Somme(l("Montant"))).Append("</td>")
        sb.Append("<td colspan='7'></td></tr>")
        Return sb.ToString()
    End Function

    ''' <summary>Le lot, nommé par sa date de paie et sa période.</summary>
    Private Shared Function NommerLot(lots As DataTable, cle As String) As String
        For Each l As DataRow In lots.Rows
            If Txt(l("ExterneId")) <> cle Then Continue For
            Return "Paie du " & Jour(l("DatePaie")) &
                   "  —  période du " & Jour(l("DateDebutPeriode")) & " au " & Jour(l("DateFinPeriode")) &
                   "  —  " & Txt(l("NbPaies")) & " paie(s)"
        Next
        Return If(cle <> "", "Lot " & cle, "Sans lot")
    End Function

    ''' <summary>
    ''' Les employés et leurs paramètres. Le NAS et le compte bancaire ne sont
    ''' pas repris : la colonne dit seulement si la source en avait un, pour
    ''' qu'on sache ce qu'il restera à saisir.
    ''' </summary>
    Private Function BatirEmployes(employes As DataTable) As String
        If employes.Rows.Count = 0 Then
            Return "<div class='rien'>Aucun employé en préparation.</div>"
        End If

        Dim sb As New StringBuilder()
        sb.Append("<div class='tbl-wrap'><table class='pa'><thead><tr>")
        sb.Append("<th>Employé</th><th>Code</th><th>Poste</th><th>Embauche</th>")
        sb.Append("<th class='n'>Rémunération</th><th class='n'>Vacances</th>")
        sb.Append("<th>Paiement</th><th>NAS</th>")
        sb.Append("</tr></thead><tbody>")

        For Each e As DataRow In employes.Rows
            Dim actif As Boolean = (Not IsDBNull(e("Actif"))) AndAlso Convert.ToBoolean(e("Actif"))
            sb.Append("<tr").Append(If(actif, "", " class='inactif'")).Append(">")

            sb.Append("<td class='nom'>").Append(H(Txt(e("Prenom")) & " " & Txt(e("Nom"))))
            If Not actif Then
                sb.Append("<span class='past off'>parti le ").Append(H(Jour(e("DateFinEmploi")))).Append("</span>")
            End If
            If Txt(e("Statut")) <> "OK" Then
                sb.Append("<span class='past ko'>à corriger</span>")
            End If
            Dim courriel As String = Txt(e("Courriel"))
            If courriel <> "" Then sb.Append("<div class='fil'>").Append(H(courriel)).Append("</div>")
            sb.Append("</td>")

            sb.Append("<td>").Append(H(Txt(e("Code")))).Append("</td>")
            sb.Append("<td>").Append(H(Txt(e("Poste")))).Append("</td>")
            sb.Append("<td>").Append(H(Jour(e("DateEmbauche")))).Append("</td>")
            sb.Append("<td class='n'>").Append(H(NommerRemuneration(e))).Append("</td>")
            sb.Append("<td class='n'>").Append(H(Pourcent(e("TauxVacances")))).Append("</td>")

            sb.Append("<td>")
            If (Not IsDBNull(e("DepotDirect"))) AndAlso Convert.ToBoolean(e("DepotDirect")) Then
                sb.Append("<span class='past dd'>dépôt direct</span>")
                sb.Append("<div class='fil'>").Append(H(Txt(e("Institution")) & " — " & Txt(e("Transit"))))
                sb.Append("</div>")
            Else
                sb.Append("<span class='fil'>chèque</span>")
            End If
            sb.Append("</td>")

            Dim nas As Boolean = (Not IsDBNull(e("NASFourni"))) AndAlso Convert.ToBoolean(e("NASFourni"))
            sb.Append("<td>").Append(If(nas, "<span class='fil'>fourni</span>",
                                        "<span class='past ko'>à saisir</span>")).Append("</td>")
            sb.Append("</tr>")
        Next

        Return sb.Append("</tbody></table></div>").ToString()
    End Function

    ''' <summary>Taux horaire ou salaire annuel, selon ce que la source porte.</summary>
    Private Shared Function NommerRemuneration(e As DataRow) As String
        If Not IsDBNull(e("SalaireAnnuel")) AndAlso Dec(e("SalaireAnnuel")) > 0D Then
            Return Somme(e("SalaireAnnuel")) & " / an"
        End If
        If Not IsDBNull(e("TauxHoraire")) AndAlso Dec(e("TauxHoraire")) > 0D Then
            Return Somme(e("TauxHoraire")) & " / h"
        End If
        Return "—"
    End Function

    ''' <summary>Un zéro se voit, mais ne se lit pas : il s'efface au gris.</summary>
    Private Shared Function EcrireMontant(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "<td class='n zero'>—</td>"
        Dim d As Decimal = Convert.ToDecimal(v)
        Return "<td class='n" & If(d = 0D, " zero", "") & "'>" & Somme(d) & "</td>"
    End Function

    Private Shared Function EcrireNombre(v As Object) As String
        Dim texte As String = Nombre(v)
        Return "<td class='n" & If(texte = "", " zero", "") & "'>" & H(If(texte <> "", texte, "—")) & "</td>"
    End Function

    Private Shared Function BatirNote() As String
        Return "<div class='note'>La source n'expose pas la paie : QuickBooks rend l'entité " &
               "Employee vide, <code>/accounting/employees</code> répond 404 pour ce connecteur, " &
               "et l'API HRIS d'Apideck répond 401. La paie de QBO est un produit séparé. Ce qui " &
               "est en préparation vient donc d'un dépôt simulé ou d'un fichier — le registre des " &
               "imports dit lequel.<br /><br />" &
               "<b>Le NAS et le numéro de compte ne sont pas repris.</b> Seuls un indicateur et " &
               "le couple institution-transit sont gardés : de quoi savoir ce qu'il restera à " &
               "saisir, sans détenir ce qu'on n'a pas besoin de détenir.<br /><br />" &
               "Rien ne s'applique à la comptabilité ni à la paie de l'application : " &
               "<b>paie.Employe_V1</b>, <b>paie.LotPaie</b>, <b>paie.Paie</b> et " &
               "<b>paie.PaieLigne</b> ne sont pas touchées.</div>"
    End Function

    Private Shared Function Vide() As String
        Return "<div class='rien'>Aucune paie en préparation.<br />" &
               "La source ne l'expose pas : elle arrivera par un fichier ou un autre " &
               "connecteur.<br /><br />Les quatre tables l'attendent — employés, lots, paies " &
               "et lignes de talon.</div>"
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

    ''' <summary>Un nombre sans unité — les heures, un taux. Vide si absent.</summary>
    Private Shared Function Nombre(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Return Convert.ToDecimal(v).ToString("0.##", FrCa)
    End Function

    Private Shared Function Pourcent(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "—"
        Return (Dec(v) * 100D).ToString("0.##", FrCa) & " %"
    End Function

    Private Shared Function Jour(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "—"
        Return Convert.ToDateTime(v).ToString("d MMM yyyy", FrCa)
    End Function

End Class
