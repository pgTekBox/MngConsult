Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Console d'administration : le plan comptable PAR DÉFAUT, c'est-à-dire celui
''' de la compagnie modèle (00000000-0000-0000-0000-000000000001). C'est lui que
''' s0500InitializeCompanyData copie dans chaque nouvelle compagnie au premier
''' enregistrement de ses Paramètres.
'''
''' La page réutilise telles quelles les procédures du plan comptable de l'ERP
''' (s0048 liste, s0049 fiche, s0051/s0052/s0053 classes, s0054 ajout, s0055
''' modification, s0050 suppression), avec le GUID du modèle en guise de
''' compagnie. Un compte système se corrige mais ne se supprime pas (s0050 le
''' refuse). Rien ici ne touche les compagnies déjà créées.
''' </summary>
Public Class wbfPlanComptableDefaut
    Inherits clsData

    Private Shared ReadOnly ModelGUID As Guid = New Guid("00000000-0000-0000-0000-000000000001")

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ChargerClasses()
            ViderFormulaire()
        Else
            ' Les boutons « Corriger » et « Retirer » du tableau sont des <button>
            ' natifs nommés « act » : ils arrivent ici, avant les asp:Button.
            Dim act As String = If(Request.Form("act"), "")
            If act.StartsWith("edit:") Then
                PreparerEdition(act.Substring(5))
            ElseIf act.StartsWith("del:") Then
                Retirer(act.Substring(4))
            End If
        End If
        Afficher()
    End Sub

    ' =========================================================================
    ' LES CLASSES
    ' =========================================================================

    Private Sub ChargerClasses()
        Dim p As New Collection
        p.Add(New SqlParameter("@Niveau", 1))
        p.Add(New SqlParameter("@CompanyGUID", ModelGUID))
        Remplir(ddlClasseParent, ExecuteSQLds("s0051GetClassesByNiveau", p), True)
        ChargerSousClasses()
    End Sub

    Private Sub ChargerSousClasses()
        ddlClasse.Items.Clear()
        If String.IsNullOrEmpty(ddlClasseParent.SelectedValue) Then Return
        Dim parentId As Integer = CInt(ddlClasseParent.SelectedValue)

        Dim p As New Collection
        p.Add(New SqlParameter("@ParentId", parentId))
        Remplir(ddlClasse, ExecuteSQLds("s0052GetSousClasses", p), False)

        ' Le type de bilan et le sens suivent la classe.
        Dim q As New Collection
        q.Add(New SqlParameter("@Id", parentId))
        Dim ds As DataSet = ExecuteSQLds("s0053GetClasseInfo", q)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
            Dim r As DataRow = ds.Tables(0).Rows(0)
            Choisir(ddlTypeBilan, Txt(r("TypeBilan")))
            Choisir(ddlSens, Txt(r("Sens")))
        End If
    End Sub

    Protected Sub ddlClasseParent_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlClasseParent.SelectedIndexChanged
        ChargerSousClasses()
    End Sub

    Private Shared Sub Remplir(ddl As DropDownList, ds As DataSet, avecVide As Boolean)
        ddl.Items.Clear()
        If avecVide Then ddl.Items.Add(New ListItem("— choisir —", ""))
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return
        For Each r As DataRow In ds.Tables(0).Rows
            ddl.Items.Add(New ListItem(Convert.ToString(r("Name")), Convert.ToString(r("Value"))))
        Next
    End Sub

    Private Shared Sub Choisir(ddl As DropDownList, valeur As String)
        If ddl.Items.FindByValue(valeur) IsNot Nothing Then ddl.SelectedValue = valeur
    End Sub

    ' =========================================================================
    ' LES ACTIONS
    ' =========================================================================

    Private Sub PreparerEdition(idTexte As String)
        Dim id As Integer
        If Not Integer.TryParse(idTexte, id) Then Return

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", ModelGUID))
        p.Add(New SqlParameter("@Id", id))
        Dim ds As DataSet = ExecuteSQLds("s0049GetOneCompte", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Message("Compte introuvable dans le plan modèle.", "err")
            Return
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        hfId.Value = id.ToString()
        Choisir(ddlClasseParent, Txt(r("ClasseParentId")))
        ChargerSousClasses()
        Choisir(ddlClasse, Txt(r("ClasseId")))
        ' s0049 nomme le numéro « Numero » (comme s0048), pas « Compte » comme la table.
        txtNumero.Text = Txt(r("Numero"))
        txtNom.Text = Txt(r("Nom"))
        Choisir(ddlTypeBilan, Txt(r("TypeBilan")))
        Choisir(ddlSens, Txt(r("Sens")))
        chkActif.Checked = Not IsDBNull(r("Actif")) AndAlso Convert.ToBoolean(r("Actif"))
        txtDescription.Text = Txt(r("Description"))
        litTitreForm.Text = "Corriger le compte " & Server.HtmlEncode(Txt(r("Numero")) & " " & Txt(r("Nom")))
        btnAnnuler.Visible = True
    End Sub

    Private Sub Retirer(idTexte As String)
        Dim id As Integer
        If Not Integer.TryParse(idTexte, id) Then Return
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", ModelGUID))
            p.Add(New SqlParameter("@Id", id))
            ExecuteSQL("s0050DeletePlanComptableCompte", p)
            Message("Compte retiré du plan par défaut. Les compagnies existantes le gardent.", "info")
        Catch ex As Exception
            Message("Le retrait a échoué : " & ex.Message, "err")
        End Try
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        Dim numero As String = txtNumero.Text.Trim()
        Dim nom As String = txtNom.Text.Trim()
        If numero = "" OrElse nom = "" Then
            Message("Le numéro et le nom sont obligatoires.", "err")
            Afficher()
            Return
        End If
        If String.IsNullOrEmpty(ddlClasseParent.SelectedValue) OrElse String.IsNullOrEmpty(ddlClasse.SelectedValue) Then
            Message("Choisissez la classe et la sous-classe.", "err")
            Afficher()
            Return
        End If

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", ModelGUID))
            Dim id As Integer
            Dim modif As Boolean = Integer.TryParse(hfId.Value, id)
            If modif Then p.Add(New SqlParameter("@Id", id))
            p.Add(New SqlParameter("@Numero", numero))
            p.Add(New SqlParameter("@Nom", nom))
            p.Add(New SqlParameter("@ClasseId", CInt(ddlClasse.SelectedValue)))
            p.Add(New SqlParameter("@ClasseParentId", CInt(ddlClasseParent.SelectedValue)))
            p.Add(New SqlParameter("@TypeBilan", ddlTypeBilan.SelectedValue))
            p.Add(New SqlParameter("@Sens", ddlSens.SelectedValue))
            p.Add(New SqlParameter("@Actif", chkActif.Checked))
            p.Add(New SqlParameter("@Description", If(txtDescription.Text.Trim() = "", CObj(DBNull.Value), txtDescription.Text.Trim())))

            If modif Then
                ExecuteSQL("s0055UpdatePlanComptableCompte", p)
                Message("Compte " & numero & " corrigé dans le plan par défaut.", "ok")
            Else
                ExecuteSQLds("s0054InsertPlanComptableCompte", p)
                Message("Compte " & numero & " ajouté au plan par défaut : les prochaines compagnies le recevront.", "ok")
            End If
            ViderFormulaire()
        Catch ex As Exception
            Message("L'enregistrement a échoué : " & ex.Message, "err")
        End Try
        Afficher()
    End Sub

    Protected Sub btnAnnuler_Click(sender As Object, e As EventArgs) Handles btnAnnuler.Click
        ViderFormulaire()
        Afficher()
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        Afficher()
    End Sub

    Protected Sub btnTout_Click(sender As Object, e As EventArgs) Handles btnTout.Click
        txtSearch.Text = ""
        Afficher()
    End Sub

    Private Sub ViderFormulaire()
        hfId.Value = ""
        txtNumero.Text = ""
        txtNom.Text = ""
        txtDescription.Text = ""
        chkActif.Checked = True
        If ddlClasseParent.Items.Count > 0 Then ddlClasseParent.SelectedIndex = 0
        ChargerSousClasses()
        litTitreForm.Text = "Ajouter un compte au plan par défaut"
        btnAnnuler.Visible = False
    End Sub

    ' =========================================================================
    ' L'AFFICHAGE
    ' =========================================================================

    Private Sub Afficher()
        Dim dt As DataTable
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", ModelGUID))
            p.Add(New SqlParameter("@Search", txtSearch.Text.Trim()))
            p.Add(New SqlParameter("@Filtre", "ALL"))
            p.Add(New SqlParameter("@Lang", "fr"))
            Dim ds As DataSet = ExecuteSQLds("s0048GetPlanComptable", p)
            dt = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
        Catch ex As Exception
            litTableau.Text = "<div class='msg err'>Le plan modèle n'a pas pu être lu : " & Server.HtmlEncode(ex.Message) & "</div>"
            Return
        End Try

        Dim actifs As Integer = 0, systeme As Integer = 0
        Dim classes As New HashSet(Of String)
        For Each r As DataRow In dt.Rows
            If Bit(r("Actif")) Then actifs += 1
            If Bit(r("Systeme")) Then systeme += 1
            classes.Add(Txt(r("ClasseDescription")))
        Next
        litNbComptes.Text = dt.Rows.Count.ToString()
        litNbActifs.Text = actifs.ToString()
        litNbSysteme.Text = systeme.ToString()
        litNbClasses.Text = classes.Count.ToString()

        If dt.Rows.Count = 0 Then
            litTableau.Text = "<div class='msg info' style='margin:12px'>Aucun compte ne correspond.</div>"
            Return
        End If

        Dim sb As New StringBuilder("<table class='pc-table'><thead><tr>")
        sb.Append("<th>Numéro</th><th>Nom</th><th>Sous-classe</th><th>Type</th><th>Sens</th><th>État</th><th>Description</th><th></th>")
        sb.Append("</tr></thead><tbody>")

        Dim classe As String = Nothing
        For Each r As DataRow In dt.Rows
            Dim c As String = Txt(r("ClasseDescription"))
            If c <> classe Then
                classe = c
                sb.Append("<tr class='classe'><td colspan='8'>").Append(Server.HtmlEncode(If(c = "", "Sans classe", c))).Append("</td></tr>")
            End If

            Dim actif As Boolean = Bit(r("Actif")), sys As Boolean = Bit(r("Systeme"))
            sb.Append("<tr").Append(If(actif, "", " class='inactif'")).Append(">")
            sb.Append("<td class='num'>").Append(Server.HtmlEncode(Txt(r("Numero")))).Append("</td>")
            sb.Append("<td>").Append(Server.HtmlEncode(Txt(r("Nom")))).Append("</td>")
            sb.Append("<td>").Append(Server.HtmlEncode(Txt(r("ClasseCode")))).Append(" <span style='color:#64748b'>").Append(Server.HtmlEncode(Txt(r("SousClasseDescription")))).Append("</span></td>")
            sb.Append("<td>").Append(Server.HtmlEncode(LibelleType(Txt(r("TypeBilan"))))).Append("</td>")
            sb.Append("<td>").Append(If(Txt(r("Sens")) = "D", "Débiteur", "Créditeur")).Append("</td>")
            sb.Append("<td>")
            If sys Then sb.Append("<span class='pill sys'>système</span> ")
            If Not actif Then sb.Append("<span class='pill off'>inactif</span>")
            sb.Append("</td>")
            sb.Append("<td class='desc'>").Append(Server.HtmlEncode(Txt(r("Description")))).Append("</td>")

            Dim id As String = Txt(r("Id"))
            sb.Append("<td style='white-space:nowrap'>")
            sb.Append("<button type='submit' class='btn petit' name='act' value='edit:").Append(id).Append("'>Corriger</button>")
            If Not sys Then
                sb.Append(" <button type='submit' class='btn petit danger' name='act' value='del:").Append(id)
                sb.Append("' onclick=""if (!confirm('Retirer ce compte du plan par défaut ?')) { return false; }"">Retirer</button>")
            End If
            sb.Append("</td></tr>")
        Next

        litTableau.Text = sb.Append("</tbody></table>").ToString()
    End Sub

    Private Shared Function LibelleType(t As String) As String
        Select Case t
            Case "A" : Return "Actif"
            Case "P" : Return "Passif"
            Case "CP" : Return "Capitaux propres"
            Case "R" : Return "Revenus"
            Case "C" : Return "Charges"
            Case Else : Return t
        End Select
    End Function

    Private Sub Message(texte As String, genre As String)
        litMsg.Text = "<div class='msg " & genre & "'>" & Server.HtmlEncode(texte) & "</div>"
    End Sub

    Private Shared Function Txt(v As Object) As String
        Return If(v Is Nothing OrElse IsDBNull(v), "", Convert.ToString(v))
    End Function

    Private Shared Function Bit(v As Object) As Boolean
        Return Not (v Is Nothing OrElse IsDBNull(v)) AndAlso Convert.ToBoolean(v)
    End Function

End Class
