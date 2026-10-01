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
            ChargerCompagnies()
            ChargerCompagniesResync()
        Else
            ' Les boutons « Corriger » et « Retirer » du tableau sont des <button>
            ' natifs nommés « act » : ils arrivent ici, avant les asp:Button.
            Dim act As String = If(Request.Form("act"), "")
            If act.StartsWith("edit:") Then
                PreparerEdition(act.Substring(5))
            ElseIf act.StartsWith("del:") Then
                Retirer(act.Substring(4))
            ElseIf act.StartsWith("delalias:") Then
                RetirerAlias(act.Substring(9))
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
        AfficherAliases(Txt(r("Numero")))
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

    ' =========================================================================
    ' LES ALIAS QUICKBOOKS D'UN COMPTE (T122, T298)
    ' =========================================================================

    ''' <summary>Les alias du compte en cours de correction, avec un bouton pour en retirer un.</summary>
    Private Sub AfficherAliases(compte As String)
        pnlAlias.Visible = True
        Dim ds As DataSet
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", ModelGUID))
            p.Add(New SqlParameter("@Compte", compte))
            ds = ExecuteSQLds("s0878GetAliasPlanComptable", p)
        Catch ex As Exception
            litAliases.Text = "<div class='msg err'>Les alias n'ont pas pu être lus : " & Server.HtmlEncode(ex.Message) & "</div>"
            Return
        End Try
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            litAliases.Text = "<p class='aide' style='margin:0'>Aucun alias : ce compte n'est reconnu que par son propre nom.</p>"
            Return
        End If
        Dim sb As New StringBuilder("<table class='pc-table' style='max-width:900px'><thead><tr><th>Langue</th><th>Nom chez QuickBooks</th><th>Sous-type</th><th>Depuis</th><th></th></tr></thead><tbody>")
        For Each r As DataRow In ds.Tables(0).Rows
            sb.Append("<tr><td>").Append(Server.HtmlEncode(If(Txt(r("Langue")) = "", "—", Txt(r("Langue")).ToLowerInvariant()))).Append("</td>")
            sb.Append("<td class='num' style='white-space:normal'>").Append(Server.HtmlEncode(Txt(r("NomSource")))).Append("</td>")
            sb.Append("<td class='desc'>").Append(Server.HtmlEncode(Txt(r("SousType")))).Append("</td>")
            sb.Append("<td class='desc'>").Append(Server.HtmlEncode(Txt(r("CreatedBy")))).Append("</td>")
            sb.Append("<td><button type='submit' class='btn petit danger' name='act' value='delalias:").Append(Txt(r("Id")))
            sb.Append("' onclick=""if (!confirm('Retirer cet alias ?')) { return false; }"">Retirer</button></td></tr>")
        Next
        litAliases.Text = sb.Append("</tbody></table>").ToString()
    End Sub

    Protected Sub btnAjouterAlias_Click(sender As Object, e As EventArgs) Handles btnAjouterAlias.Click
        Dim id As Integer
        If Not Integer.TryParse(hfId.Value, id) Then
            Message("Enregistrez d'abord le compte : un alias se pose sur un compte existant.", "err")
            Afficher()
            Return
        End If
        If txtAliasNom.Text.Trim() = "" Then
            Message("Le nom chez QuickBooks est obligatoire.", "err")
            PreparerEdition(hfId.Value)
            Afficher()
            Return
        End If
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", ModelGUID))
            p.Add(New SqlParameter("@Compte", txtNumero.Text.Trim()))
            p.Add(New SqlParameter("@SystemeSource", "QBO"))
            p.Add(New SqlParameter("@Langue", If(ddlAliasLangue.SelectedValue = "", CObj(DBNull.Value), ddlAliasLangue.SelectedValue)))
            p.Add(New SqlParameter("@NomSource", txtAliasNom.Text.Trim()))
            p.Add(New SqlParameter("@SousType", Vide(txtAliasSousType.Text)))
            p.Add(New SqlParameter("@CreatedBy", If(Convert.ToString(Session("AdminEmail")) = "", "sec60admin", Convert.ToString(Session("AdminEmail")))))
            Dim ds As DataSet = ExecuteSQLds("s0879SaveAliasPlanComptable", p)
            Dim r As DataRow = ds.Tables(0).Rows(0)
            Message(Txt(r("Message")), If(Txt(r("Action")) = "REFUSE", "err", "ok"))
            If Txt(r("Action")) <> "REFUSE" Then
                txtAliasNom.Text = ""
                txtAliasSousType.Text = ""
            End If
        Catch ex As Exception
            Message("L'alias n'a pas pu être enregistré : " & ex.Message, "err")
        End Try
        PreparerEdition(hfId.Value)
        Afficher()
    End Sub

    Private Sub RetirerAlias(idTexte As String)
        Dim id As Integer
        If Not Integer.TryParse(idTexte, id) Then Return
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", ModelGUID))
            p.Add(New SqlParameter("@Id", id))
            ExecuteSQL("s0880DeleteAliasPlanComptable", p)
            Message("Alias retiré.", "info")
        Catch ex As Exception
            Message("Le retrait de l'alias a échoué : " & ex.Message, "err")
        End Try
        ' On reste sur le compte en cours de correction.
        If hfId.Value <> "" Then PreparerEdition(hfId.Value)
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
        pnlAlias.Visible = False
        litAliases.Text = ""
        txtAliasNom.Text = ""
        txtAliasSousType.Text = ""
        chkActif.Checked = True
        If ddlClasseParent.Items.Count > 0 Then ddlClasseParent.SelectedIndex = 0
        ChargerSousClasses()
        litTitreForm.Text = "Ajouter un compte au plan par défaut"
        btnAnnuler.Visible = False
    End Sub

    ' =========================================================================
    ' AJOUTER DEPUIS UN IMPORT QUICKBOOKS (T293)
    ' =========================================================================

    ''' <summary>Les compagnies qui ont des comptes QBO décidés « Créer », avec leur nom.</summary>
    Private Sub ChargerCompagnies()
        ddlCompagnie.Items.Clear()
        ddlCompagnie.Items.Add(New ListItem("— choisir —", ""))

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", DBNull.Value))
        Dim ds As DataSet = ExecuteSQLds("s0875GetCandidatsPlanDefaut", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

        ' Les noms viennent de la liste des compagnies de la console.
        Dim noms As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
        Try
            Dim q As New Collection
            q.Add(New SqlParameter("@Search", ""))
            Dim dc As DataSet = ExecuteSQLds("s0653GetCompaniesList", q)
            If dc IsNot Nothing AndAlso dc.Tables.Count > 0 Then
                For Each r As DataRow In dc.Tables(0).Rows
                    noms(Txt(r("CompanyGUID"))) = Txt(r("Name")) & If(Txt(r("CompanyCode")) <> "", " (" & Txt(r("CompanyCode")) & ")", "")
                Next
            End If
        Catch
        End Try

        ' Toutes les compagnies qui ont un plan QuickBooks en préparation (T295), même
        ' sans candidat : on voit alors combien de comptes restent à décider à l'étape 2.
        For Each r As DataRow In ds.Tables(0).Rows
            Dim guid As String = Txt(r("CompanyGUID"))
            Dim nom As String = If(noms.ContainsKey(guid), noms(guid), guid)
            Dim libelle As String = nom & " — " & Txt(r("NbCandidats")) & " candidat(s) « Créer »"
            If Ent(r("NbADecider")) > 0 Then libelle &= ", " & Txt(r("NbADecider")) & " à décider"
            libelle &= " sur " & Txt(r("NbEnPreparation")) & " en préparation"
            ddlCompagnie.Items.Add(New ListItem(libelle, guid))
        Next
    End Sub

    Protected Sub btnVoir_Click(sender As Object, e As EventArgs) Handles btnVoir.Click
        AfficherCandidats()
    End Sub

    ''' <summary>
    ''' Les candidats de la compagnie choisie : une case, le nom QBO, son sous-type,
    ''' sa nature, son origine, ce que le modèle en sait déjà, et la sous-classe
    ''' du modèle à choisir (proposée quand le compte a déjà été créé chez le client).
    ''' </summary>
    Private Sub AfficherCandidats()
        btnAjouterModele.Visible = False
        If String.IsNullOrEmpty(ddlCompagnie.SelectedValue) Then
            litCandidats.Text = ""
            Return
        End If

        Dim ds As DataSet
        Dim filtre As String = ddlFiltreCandidats.SelectedValue
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", New Guid(ddlCompagnie.SelectedValue)))
            p.Add(New SqlParameter("@Filtre", filtre))
            ds = ExecuteSQLds("s0875GetCandidatsPlanDefaut", p)
        Catch ex As Exception
            litCandidats.Text = "<div class='msg err'>Les comptes n'ont pas pu être lus : " & Server.HtmlEncode(ex.Message) & "</div>"
            Return
        End Try
        If ds Is Nothing OrElse ds.Tables.Count < 2 OrElse ds.Tables(0).Rows.Count = 0 Then
            If filtre = "CREER" Then
                litCandidats.Text = "<div class='msg info'>Aucun compte décidé « Créer » pour cette compagnie. " &
                                    "Les candidats viennent de l'étape 2 de sa reprise (Correspondance des comptes) : un compte QuickBooks " &
                                    "sans équivalent y est décidé « Créer », et il apparaît ici. Un rechargement du plan remet ces décisions à zéro. " &
                                    "Choisissez « tout le plan QuickBooks en préparation » pour voir tous ses comptes.</div>"
            Else
                litCandidats.Text = "<div class='msg info'>Aucun compte à montrer pour cette compagnie avec ce filtre.</div>"
            End If
            Return
        End If

        ' Les sous-classes du modèle, en options HTML réutilisées sur chaque ligne.
        Dim options As New StringBuilder("<option value=''>— sous-classe —</option>")
        Dim parent As String = Nothing
        For Each c As DataRow In ds.Tables(1).Rows
            If Txt(c("ParentCode")) <> parent Then
                If parent IsNot Nothing Then options.Append("</optgroup>")
                parent = Txt(c("ParentCode"))
                options.Append("<optgroup label='").Append(Server.HtmlEncode(parent & " — " & Txt(c("ParentDescription")))).Append("'>")
            End If
            options.Append("<option value='").Append(Txt(c("Id"))).Append("' data-type='").Append(Txt(c("TypeBilan"))).Append("'>")
            options.Append(Server.HtmlEncode(Txt(c("Code")) & " — " & Txt(c("Description")) & " (" & Txt(c("NumeroDebut")) & "-" & Txt(c("NumeroFin")) & ")")).Append("</option>")
        Next
        If parent IsNot Nothing Then options.Append("</optgroup>")

        Dim sb As New StringBuilder("<table class='pc-table'><thead><tr>")
        sb.Append("<th><input type='checkbox' onclick=""var c=document.querySelectorAll('input[name=cand]');for(var i=0;i<c.length;i++){if(!c[i].disabled)c[i].checked=this.checked;}"" title='Tout cocher' /></th>")
        sb.Append("<th>Compte QuickBooks</th><th>Sous-type</th><th>Nature</th><th>Origine</th><th>Chez la compagnie</th><th>Au modèle</th><th>Sous-classe du modèle</th>")
        sb.Append("</tr></thead><tbody>")

        For Each r As DataRow In ds.Tables(0).Rows
            Dim id As String = Txt(r("StagingId"))
            Dim deja As String = Txt(r("DejaModeleCompte"))
            sb.Append("<tr").Append(If(deja <> "", " class='inactif'", "")).Append(">")
            sb.Append("<td><input type='checkbox' name='cand' value='").Append(id).Append("'").Append(If(deja <> "", " disabled", "")).Append(" /></td>")
            sb.Append("<td class='num' style='white-space:normal'>").Append(Server.HtmlEncode(Txt(r("NomSource"))))
            ' L'assistant IA : ce que ce compte QuickBooks représente, et s'il mérite le plan par défaut.
            sb.Append(" <button type='button' class='ia-cpt' data-id='").Append(id).Append("' data-cie='").Append(Server.HtmlEncode(ddlCompagnie.SelectedValue))
            sb.Append("' data-nom='").Append(Server.HtmlEncode(Txt(r("NomSource")))).Append("' title='Demander à l&#39;IA d&#39;expliquer ce compte et de dire s&#39;il doit entrer dans le plan par défaut'>✨ Assistant</button>")
            If Txt(r("NomCible")) <> "" AndAlso Txt(r("NomCible")) <> Txt(r("NomSource")) Then
                sb.Append("<span class='desc' style='display:block;font-weight:400'>chez nous : ").Append(Server.HtmlEncode(Txt(r("NomCible")))).Append("</span>")
            End If
            If Txt(r("CreeChezClientCompte")) <> "" Then
                sb.Append("<span class='desc' style='display:block;font-weight:400'>créé chez le client : ").Append(Server.HtmlEncode(Txt(r("CreeChezClientCompte")) & " (" & Txt(r("ClasseCodeClient")) & ")")).Append("</span>")
            End If
            sb.Append("</td>")
            sb.Append("<td class='desc'>").Append(Server.HtmlEncode(Txt(r("SousTypeSource")))).Append("</td>")
            sb.Append("<td>").Append(Server.HtmlEncode(LibelleType(Txt(r("TypeBilan"))))).Append("</td>")
            sb.Append("<td>").Append(If(Txt(r("Origine")) = "DEFAUT", "<span class='pill'>par défaut QBO</span>", "<span class='pill off'>ajouté par le client</span>")).Append("</td>")
            ' Ce que la compagnie en a fait : reconnu (par numéro, nom ou alias) et sa décision.
            sb.Append("<td>")
            Dim reconnu As String = Txt(r("ReconnuCompte"))
            If reconnu <> "" Then
                sb.Append("reconnu → ").Append(Server.HtmlEncode(reconnu & " " & Txt(r("ReconnuNom"))))
                If Bit(r("ParAlias")) Then sb.Append(" <span class='pill' title='Reconnu par son nom ou son sous-type QuickBooks (alias)'>alias</span>")
                sb.Append("<br />")
            Else
                sb.Append("<span class='desc'>sans jumeau</span><br />")
            End If
            Select Case Txt(r("Decision"))
                Case "LIER" : sb.Append("<span class='pill'>lié</span>")
                Case "CREER" : sb.Append("<span class='pill sys'>à créer chez elle</span>")
                Case "IGNORER" : sb.Append("<span class='pill off'>ignoré</span>")
                Case Else : sb.Append("<span class='desc'>à décider</span>")
            End Select
            sb.Append("</td>")
            sb.Append("<td>")
            If deja <> "" Then
                sb.Append("<span class='pill sys'>déjà là</span> ").Append(Server.HtmlEncode(deja & " " & Txt(r("DejaModeleNom")))).Append("<span class='desc' style='display:block'>").Append(Server.HtmlEncode(Txt(r("DejaModeleMotif")))).Append("</span>")
            Else
                sb.Append("<span class='desc'>absent</span>")
            End If
            sb.Append("</td>")
            sb.Append("<td>")
            If deja = "" Then
                ' La sous-classe proposée : celle du compte créé chez le client, si elle existe au modèle.
                Dim sel As String = Txt(r("ModelClasseIdSuggere"))
                Dim opts As String = options.ToString()
                If sel <> "" Then opts = opts.Replace("<option value='" & sel & "'", "<option value='" & sel & "' selected")
                sb.Append("<select name='cls_").Append(id).Append("' style='max-width:320px;padding:5px 7px;border:1px solid #cbd5e1;border-radius:8px;font-size:12.5px'>").Append(opts).Append("</select>")
            End If
            sb.Append("</td></tr>")
        Next
        sb.Append("</tbody></table>")
        sb.Append("<p class='aide' style='margin:8px 0 0'>Un compte « ajouté par le client » porte souvent un nom qui n'appartient qu'à lui : n'en faites un compte par défaut que s'il est vraiment générique.</p>")
        litCandidats.Text = sb.ToString()
        btnAjouterModele.Visible = True
    End Sub

    Protected Sub btnAjouterModele_Click(sender As Object, e As EventArgs) Handles btnAjouterModele.Click
        Dim coches As String() = Request.Form.GetValues("cand")
        If coches Is Nothing OrElse coches.Length = 0 OrElse String.IsNullOrEmpty(ddlCompagnie.SelectedValue) Then
            Message("Cochez au moins un compte à ajouter.", "err")
            AfficherCandidats()
            Return
        End If

        Dim crees As Integer = 0, existants As Integer = 0, refuses As Integer = 0
        Dim details As New List(Of String)
        For Each idTexte As String In coches
            Dim id As Integer
            If Not Integer.TryParse(idTexte, id) Then Continue For
            Dim classe As Integer
            If Not Integer.TryParse(If(Request.Form("cls_" & id), ""), classe) Then
                refuses += 1
                details.Add("compte " & id & " : aucune sous-classe choisie")
                Continue For
            End If
            Try
                Dim p As New Collection
                p.Add(New SqlParameter("@CompanyGUID", New Guid(ddlCompagnie.SelectedValue)))
                p.Add(New SqlParameter("@StagingId", id))
                p.Add(New SqlParameter("@ClasseId", classe))
                Dim ds As DataSet = ExecuteSQLds("s0876AjouterCandidatAuPlanDefaut", p)
                Dim r As DataRow = ds.Tables(0).Rows(0)
                Select Case Txt(r("Action"))
                    Case "CREE" : crees += 1
                    Case "EXISTE" : existants += 1
                    Case Else : refuses += 1
                End Select
                details.Add(Txt(r("Message")))
            Catch ex As Exception
                refuses += 1
                details.Add("compte " & id & " : " & ex.Message)
            End Try
        Next

        Dim texte As New StringBuilder()
        texte.Append(crees).Append(" compte(s) ajouté(s) au plan par défaut")
        If existants > 0 Then texte.Append(", ").Append(existants).Append(" déjà présent(s)")
        If refuses > 0 Then texte.Append(", ").Append(refuses).Append(" refusé(s)")
        texte.Append(". ").Append(String.Join(" · ", details.Take(12)))
        Message(texte.ToString(), If(crees > 0, "ok", If(refuses > 0, "err", "info")))

        ' La liste des compagnies se recharge (les compteurs de candidats bougent) :
        ' on retient la compagnie AVANT, sinon la sélection se perd avec les items.
        Dim cie As String = ddlCompagnie.SelectedValue
        ChargerCompagnies()
        Choisir(ddlCompagnie, cie)
        AfficherCandidats()
        ' Le tableau du modèle et ses compteurs ont été rendus avant l'ajout : on les refait.
        Afficher()
    End Sub

    ' =========================================================================
    ' RESYNCHRONISER UNE COMPAGNIE AVEC LE PLAN PAR DÉFAUT (T294)
    ' =========================================================================

    ''' <summary>Toutes les compagnies de la console, sauf le modèle lui-même.</summary>
    Private Sub ChargerCompagniesResync()
        ddlCieResync.Items.Clear()
        ddlCieResync.Items.Add(New ListItem("— choisir —", ""))
        Try
            Dim q As New Collection
            q.Add(New SqlParameter("@Search", ""))
            Dim dc As DataSet = ExecuteSQLds("s0653GetCompaniesList", q)
            If dc Is Nothing OrElse dc.Tables.Count = 0 Then Return
            For Each r As DataRow In dc.Tables(0).Rows
                Dim guid As String = Txt(r("CompanyGUID"))
                If String.Equals(guid, ModelGUID.ToString(), StringComparison.OrdinalIgnoreCase) Then Continue For
                ddlCieResync.Items.Add(New ListItem(Txt(r("Name")) & If(Txt(r("CompanyCode")) <> "", " (" & Txt(r("CompanyCode")) & ")", ""), guid))
            Next
        Catch ex As Exception
            Message("La liste des compagnies n'a pas pu être lue : " & ex.Message, "err")
        End Try
    End Sub

    Protected Sub btnSimulerResync_Click(sender As Object, e As EventArgs) Handles btnSimulerResync.Click
        Resynchroniser(True)
    End Sub

    Protected Sub btnAppliquerResync_Click(sender As Object, e As EventArgs) Handles btnAppliquerResync.Click
        Resynchroniser(False)
        Afficher()
    End Sub

    ''' <summary>s0877 : le bilan et le détail, en simulation (ROLLBACK côté SQL) ou pour de vrai.</summary>
    Private Sub Resynchroniser(simuler As Boolean)
        If String.IsNullOrEmpty(ddlCieResync.SelectedValue) Then
            litResync.Text = "<div class='msg err'>Choisissez une compagnie.</div>"
            Return
        End If

        Dim ds As DataSet
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", New Guid(ddlCieResync.SelectedValue)))
            p.Add(New SqlParameter("@SupprimerEnTrop", chkSupprimerEnTrop.Checked))
            p.Add(New SqlParameter("@Simuler", simuler))
            ds = ExecuteSQLds("s0877ResyncPlanComptableDepuisModele", p)
        Catch ex As Exception
            litResync.Text = "<div class='msg err'>La resynchronisation a échoué : " & Server.HtmlEncode(ex.Message) & "</div>"
            Return
        End Try
        If ds Is Nothing OrElse ds.Tables.Count < 2 OrElse ds.Tables(0).Rows.Count = 0 Then
            litResync.Text = "<div class='msg err'>Aucun résultat.</div>"
            Return
        End If

        Dim b As DataRow = ds.Tables(0).Rows(0)
        Dim sb As New StringBuilder()
        sb.Append("<div class='msg ").Append(If(simuler, "info", "ok")).Append("'>")
        sb.Append(If(simuler, "<b>Simulation</b> — rien n'a été écrit. ", "<b>Appliqué.</b> "))
        sb.Append(Ent(b("NbAjoutes"))).Append(" compte(s) ajouté(s), ").Append(Ent(b("NbMisAJour"))).Append(" aligné(s), ")
        sb.Append(Ent(b("NbSupprimes"))).Append(" retiré(s), ").Append(Ent(b("NbGardes"))).Append(" gardé(s) bien qu'absents du modèle")
        If Ent(b("NbRefuses")) > 0 Then sb.Append(", ").Append(Ent(b("NbRefuses"))).Append(" refusé(s)")
        sb.Append(".</div>")

        If ds.Tables(1).Rows.Count > 0 Then
            sb.Append("<div class='pc-tbl-wrap' style='max-height:50vh'><table class='pc-table'><thead><tr><th>Action</th><th>Numéro</th><th>Nom</th><th>Motif</th></tr></thead><tbody>")
            For Each r As DataRow In ds.Tables(1).Rows
                Dim act As String = Txt(r("Action"))
                Dim pill As String = "pill"
                If act = "SUPPRIME" OrElse act = "REFUSE" Then
                    pill = "pill off"
                ElseIf act = "GARDE" Then
                    pill = "pill sys"
                End If
                sb.Append("<tr><td><span class='").Append(pill).Append("'>").Append(Server.HtmlEncode(LibelleResync(act))).Append("</span></td>")
                sb.Append("<td class='num'>").Append(Server.HtmlEncode(Txt(r("Compte")))).Append("</td>")
                sb.Append("<td>").Append(Server.HtmlEncode(Txt(r("Nom")))).Append("</td>")
                sb.Append("<td class='desc'>").Append(Server.HtmlEncode(Txt(r("Motif")))).Append("</td></tr>")
            Next
            sb.Append("</tbody></table></div>")
        End If
        litResync.Text = sb.ToString()
    End Sub

    Private Shared Function LibelleResync(action As String) As String
        Select Case action
            Case "AJOUTE" : Return "ajouté"
            Case "MIS_A_JOUR" : Return "aligné"
            Case "SUPPRIME" : Return "retiré"
            Case "GARDE" : Return "gardé"
            Case "REFUSE" : Return "refusé"
            Case Else : Return action
        End Select
    End Function

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
            sb.Append("<td>").Append(Server.HtmlEncode(Txt(r("Nom"))))
            ' Les alias QuickBooks (T122), sous le nom : ce que la reprise d'un plan QBO reconnaît d'office.
            Dim qbo As String = Txt(r("QBOAlias"))
            If qbo <> "" Then sb.Append("<span class='desc' style='display:block;color:#64748b;font-size:11.5px' title='Alias QuickBooks'>QBO : ").Append(Server.HtmlEncode(qbo)).Append("</span>")
            sb.Append("</td>")
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

    ''' <summary>Un champ vide devient NULL : l'alias absent n'est pas une chaîne vide.</summary>
    Private Shared Function Vide(texte As String) As Object
        Dim t As String = If(texte, "").Trim()
        Return If(t = "", CObj(DBNull.Value), t)
    End Function

    Private Shared Function Ent(v As Object) As Integer
        Return If(v Is Nothing OrElse IsDBNull(v), 0, Convert.ToInt32(v))
    End Function

    Private Shared Function Bit(v As Object) As Boolean
        Return Not (v Is Nothing OrElse IsDBNull(v)) AndAlso Convert.ToBoolean(v)
    End Function

End Class
