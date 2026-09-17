Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Comparer la fiche d'entreprise — le seul import qui ne crée rien.
'''
''' Les autres écrans de validation demandent « faut-il créer ceci ? ». Celui-ci
''' demande autre chose : « laquelle des deux valeurs est la bonne ? ». Le nom
''' légal, l'adresse et le téléphone existent déjà dans 60Sec-AI — non pas dans
''' une table, mais dans les paramètres de la compagnie (T100ParamComptable /
''' T101ParamValues), ceux que dbo.fCompanyName relit pour afficher le nom.
'''
''' D'où la forme : une ligne par champ, la valeur en place à gauche, celle de la
''' source à droite, et une case à cocher quand il y a un choix à faire. Rien ne
''' s'applique sans ce geste. Écraser l'adresse d'une entreprise parce qu'un
''' autre logiciel en connaît une différente ne peut pas être automatique.
'''
''' Trois sortes de lignes ne se cochent pas :
'''
'''   · celles que la source ne renseigne pas — il n'y a rien à prendre ;
'''   · celles déjà identiques — il n'y a rien à changer ;
'''   · celles sans nom de paramètre : la devise, la méthode comptable, le mois
'''     de début d'exercice. 60Sec-AI ne les range nulle part, alors on les
'''     montre sans prétendre pouvoir les appliquer.
''' </summary>
Public Class ValiderSociete
    Inherits clsData

#Region "Cycle de vie"

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If IsPostBack Then Return
        Afficher()
    End Sub

#End Region

#Region "Appliquer"

    ''' <summary>
    ''' Les champs cochés remplacent la valeur en place. La procédure fait le tri
    ''' de ce qui est réellement applicable et rend le compte des deux : on le
    ''' répète tel quel plutôt que d'annoncer un succès qu'on n'a pas vérifié.
    ''' </summary>
    Protected Sub btnAppliquer_Click(sender As Object, e As EventArgs) Handles btnAppliquer.Click
        Dim cochees As String() = Request.Form.GetValues("sel")

        If cochees Is Nothing OrElse cochees.Length = 0 Then
            litMsg.Text = "<div class=""msg no"">Aucun champ coché : rien n'a été modifié.</div>"
            Afficher()
            Return
        End If

        Try
            Dim ids As New StringBuilder("[")
            For i As Integer = 0 To cochees.Length - 1
                If i > 0 Then ids.Append(",")
                ids.Append(Convert.ToInt32(cochees(i)))
            Next
            ids.Append("]")

            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Ids", ids.ToString()))
            p.Add(New SqlParameter("@UserId", CObj(UserId)))

            Dim ds As DataSet = ExecuteSQLds("s0791AppliquerSocieteImport", p)
            litMsg.Text = Resumer(ds)

        Catch ex As Exception
            litMsg.Text = "<div class=""msg no"">L'application a échoué : " &
                          Server.HtmlEncode(ex.Message) & "</div>"
        End Try

        Afficher()
    End Sub

    Private Function Resumer(ds As DataSet) As String
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Return "<div class=""msg ok"">Fiche appliquée.</div>"
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim faits As Integer = Convert.ToInt32(r("NbAppliques"))
        Dim refuses As Integer = Convert.ToInt32(r("NbRefuses"))

        If faits = 0 Then
            Return "<div class=""msg no"">Aucun des champs cochés n'était applicable " &
                   "(paramètre inexistant pour cette compagnie, ou valeur absente à la source).</div>"
        End If

        Dim sb As New StringBuilder("<div class=""msg ok"">")
        sb.Append(faits).Append(" champ(s) appliqué(s) à la fiche de la compagnie.")
        If refuses > 0 Then
            sb.Append(" ").Append(refuses).Append(" écarté(s) : le paramètre correspondant ")
            sb.Append("n'existe pas pour cette compagnie, ou la source ne donne rien.")
        End If
        sb.Append("</div>")
        Return sb.ToString()
    End Function

#End Region

#Region "L'affichage"

    Private Sub Afficher()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))

        Dim ds As DataSet = ExecuteSQLds("s0789GetSocieteImport", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            litChamps.Text =
                "<div class=""rien"">Aucune fiche d'entreprise en préparation." &
                "<br />Lancez une importation QuickBooks en cochant " &
                "<b>Informations de la société</b>, puis revenez ici.</div>"
            litEcarts.Text = "0"
            litNouveaux.Text = "0"
            litIdentiques.Text = "0"
            litManquants.Text = "0"
            Return
        End If

        Dim lignes As DataRowCollection = ds.Tables(0).Rows
        Compter(lignes)
        litChamps.Text = Rendre(lignes)
    End Sub

    Private Sub Compter(lignes As DataRowCollection)
        Dim ecarts = 0, nouveaux = 0, identiques = 0, manquants = 0

        For Each r As DataRow In lignes
            Select Case Convert.ToString(r("Statut"))
                Case "DIFFERENT" : ecarts += 1
                Case "ABSENT_ICI" : nouveaux += 1
                Case "IDENTIQUE" : identiques += 1
                Case Else : manquants += 1
            End Select
        Next

        litEcarts.Text = ecarts.ToString()
        litNouveaux.Text = nouveaux.ToString()
        litIdentiques.Text = identiques.ToString()
        litManquants.Text = manquants.ToString()
    End Sub

    Private Function Rendre(lignes As DataRowCollection) As String
        Dim sb As New StringBuilder()
        sb.Append("<table class=""champs""><thead><tr>")
        sb.Append("<th></th><th>Champ</th><th>Valeur actuelle</th>")
        sb.Append("<th>Valeur chez la source</th><th>État</th>")
        sb.Append("</tr></thead><tbody>")

        For Each r As DataRow In lignes
            Dim id As Integer = Convert.ToInt32(r("Id"))
            Dim statut As String = Convert.ToString(r("Statut"))
            Dim cle As String = Texte(r, "Champ")
            Dim source As String = Texte(r, "ValeurSource")
            Dim actuelle As String = Texte(r, "ValeurActuelle")

            ' Cochable seulement s'il y a quelque chose à prendre, un endroit où
            ' le mettre, et une différence à combler.
            Dim choisissable As Boolean =
                (cle <> "") AndAlso (source <> "") AndAlso
                (statut = "DIFFERENT" OrElse statut = "ABSENT_ICI")

            Dim classe As String = ""
            If cle = "" Then
                classe = " class=""info"""
            ElseIf statut = "DIFFERENT" Then
                classe = " class=""ecart"""
            End If

            sb.Append("<tr").Append(classe).Append(">")

            sb.Append("<td class=""c"">")
            If choisissable Then
                sb.Append("<input type=""checkbox"" class=""sel"" name=""sel"" value=""")
                sb.Append(id).Append(""" ")
                If statut = "DIFFERENT" Then sb.Append("checked=""checked"" ")
                sb.Append("/>")
            End If
            sb.Append("</td>")

            sb.Append("<td><div class=""lib"">").Append(Server.HtmlEncode(Texte(r, "Libelle")))
            sb.Append("</div>")
            If cle <> "" Then
                sb.Append("<div class=""cle"">").Append(Server.HtmlEncode(cle)).Append("</div>")
            End If
            sb.Append("</td>")

            sb.Append("<td>").Append(Montrer(actuelle)).Append("</td>")
            sb.Append("<td class=""src"">").Append(Montrer(source)).Append("</td>")

            sb.Append("<td><span class=""verdict ").Append(statut).Append(""">")
            sb.Append(Dire(statut)).Append("</span>")
            If Not IsDBNull(r("AppliqueLe")) Then
                sb.Append("<div class=""cle"">appliqué le ")
                sb.Append(Convert.ToDateTime(r("AppliqueLe")).ToString("yyyy-MM-dd HH:mm"))
                sb.Append("</div>")
            End If
            sb.Append("</td>")

            sb.Append("</tr>")
        Next

        sb.Append("</tbody></table>")
        Return sb.ToString()
    End Function

    ''' <summary>Une case vide se voit mieux dite qu'absente.</summary>
    Private Function Montrer(valeur As String) As String
        If valeur = "" Then Return "<span class=""vide"">— rien —</span>"
        Return Server.HtmlEncode(valeur)
    End Function

    Private Shared Function Dire(statut As String) As String
        Select Case statut
            Case "DIFFERENT" : Return "Écart"
            Case "ABSENT_ICI" : Return "Absent ici"
            Case "IDENTIQUE" : Return "Identique"
            Case Else : Return "Absent à la source"
        End Select
    End Function

    Private Shared Function Texte(r As DataRow, champ As String) As String
        If IsDBNull(r(champ)) Then Return ""
        Return Convert.ToString(r(champ))
    End Function

#End Region

End Class
