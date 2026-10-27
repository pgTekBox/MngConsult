Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' La fiche d'un métier (T330Metier, T330MetierProfil), en fenêtre depuis wbfMetiers.aspx :
''' nom, famille (choisie parmi T332FamilleMetier), secteur d'activité facultatif (parmi
''' T333SecteurActivite), actif, et les profils où il existe (TA, Cie 0, Cie 1-4) avec leur
''' groupe et leurs taxes. s0914 lit, s0915 enregistre (nom unique ; renommer met à jour le
''' paramètre METIER des compagnies) puis s0934 pose le secteur, s0916 supprime (refusé si
''' des compagnies l'ont choisi), s0917 donne les familles (wbfFamillesMetier.aspx), s0930
''' les secteurs (wbfSecteursActivite.aspx).
''' </summary>
Public Class wbfMetierEdit
    Inherits clsData

    Private Shared ReadOnly Groupes As String() = {"—", "Sociétés"}
    Private Shared ReadOnly Taxes As String() = {"Taxable", "Exonéré", "Détaxé", "Mixte", "À valider"}

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            RemplirListes()
            Dim id As Integer = 0
            Integer.TryParse(Request.QueryString("id"), id)
            hfId.Value = id.ToString()

            If id > 0 Then
                LoadMetier(id)
                litTitle.Text = "Modifier un métier"
                btnDelete.Visible = True
            Else
                litTitle.Text = "Nouveau métier"
                ' Par défaut : les trois profils, au groupe et aux taxes habituels.
                For Each pr In LignesProfils()
                    pr.Coche.Checked = True
                    SetDdl(pr.Groupe, If(pr.Code = "TA", "—", "Sociétés"))
                    SetDdl(pr.Taxes, "Taxable")
                Next
            End If
        End If
    End Sub

    ''' <summary>Une ligne de profil de la fiche : code, case, groupe, taxes.</summary>
    Private Class LigneProfil
        Public Code As String
        Public Coche As CheckBox
        Public Groupe As DropDownList
        Public Taxes As DropDownList
    End Class

    Private Function LignesProfils() As LigneProfil()
        Return New LigneProfil() {
            New LigneProfil With {.Code = "TA", .Coche = cbTA, .Groupe = ddlGroupeTA, .Taxes = ddlTaxesTA},
            New LigneProfil With {.Code = "Cie 0", .Coche = cbCie0, .Groupe = ddlGroupeCie0, .Taxes = ddlTaxesCie0},
            New LigneProfil With {.Code = "Cie 1-4", .Coche = cbCie14, .Groupe = ddlGroupeCie14, .Taxes = ddlTaxesCie14}
        }
    End Function

    Private Sub RemplirListes()
        ddlFamille.Items.Clear()
        ddlFamille.Items.Add(New ListItem("— Choisir —", ""))
        Dim ds As DataSet = ExecuteSQLds("s0917GetFamillesMetier")
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                ddlFamille.Items.Add(New ListItem(S(r("Famille")), S(r("Famille"))))
            Next
        End If
        ddlSecteur.Items.Clear()
        ddlSecteur.Items.Add(New ListItem("— Aucun —", ""))
        Dim dsS As DataSet = ExecuteSQLds("s0930GetSecteursActiviteAdminList")
        If dsS IsNot Nothing AndAlso dsS.Tables.Count > 0 Then
            For Each r As DataRow In dsS.Tables(0).Rows
                ddlSecteur.Items.Add(New ListItem(S(r("Nom")), S(r("Id"))))
            Next
        End If
        For Each pr In LignesProfils()
            pr.Groupe.Items.Clear()
            For Each g In Groupes : pr.Groupe.Items.Add(New ListItem(g, g)) : Next
            pr.Taxes.Items.Clear()
            For Each t In Taxes : pr.Taxes.Items.Add(New ListItem(t, t)) : Next
        Next
    End Sub

    Private Sub LoadMetier(id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        Dim ds As DataSet = ExecuteSQLds("s0914GetMetierById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ShowMsg("Métier introuvable.", isError:=True)
            Return
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        txtNom.Text = S(r("Nom"))
        Dim famille As String = S(r("Famille"))
        If ddlFamille.Items.FindByValue(famille) Is Nothing Then ddlFamille.Items.Add(New ListItem(famille, famille))
        SetDdl(ddlFamille, famille)
        SetDdl(ddlSecteur, S(r("SecteurId")))
        cbActive.Checked = CBool(r("IsActive"))

        Dim lignes = LignesProfils()
        If ds.Tables.Count > 1 Then
            For Each rp As DataRow In ds.Tables(1).Rows
                For Each pr In lignes
                    If pr.Code = S(rp("Profil")) Then
                        pr.Coche.Checked = True
                        AjouterSiAbsent(pr.Groupe, S(rp("Groupe")))
                        AjouterSiAbsent(pr.Taxes, S(rp("Taxes")))
                    End If
                Next
            Next
        End If
        ' Les profils non cochés gardent un groupe et des taxes plausibles s'ils sont cochés plus tard.
        For Each pr In lignes
            If Not pr.Coche.Checked Then
                SetDdl(pr.Groupe, If(pr.Code = "TA", "—", "Sociétés"))
                SetDdl(pr.Taxes, "Taxable")
            End If
        Next
    End Sub

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        Dim id As Integer = 0
        Integer.TryParse(hfId.Value, id)

        ' === Validations ===
        Dim nom As String = txtNom.Text.Trim()
        If nom = "" Then
            ShowMsg("Le nom du métier est obligatoire.", isError:=True)
            Return
        End If
        Dim famille As String = ddlFamille.SelectedValue
        If String.IsNullOrWhiteSpace(famille) Then
            ShowMsg("Choisissez une famille.", isError:=True)
            Return
        End If
        Dim profils As New List(Of String)
        For Each pr In LignesProfils()
            If pr.Coche.Checked Then profils.Add(pr.Code & "|" & pr.Groupe.SelectedValue & "|" & pr.Taxes.SelectedValue)
        Next
        If profils.Count = 0 Then
            ShowMsg("Cochez au moins un profil.", isError:=True)
            Return
        End If

        ' === Sauvegarde ===
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            p.Add(New SqlParameter("@Nom", nom))
            p.Add(New SqlParameter("@Famille", famille))
            p.Add(New SqlParameter("@IsActive", cbActive.Checked))
            p.Add(New SqlParameter("@Profils", String.Join(";", profils)))
            Dim outNew As New SqlParameter("@NewId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
            p.Add(outNew)
            Dim outRen As New SqlParameter("@NbRenommes", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
            p.Add(outRen)

            ExecuteSQL("s0915SaveMetier", p)

            ' Le secteur (facultatif) : vide = aucun.
            Dim pS As New Collection
            pS.Add(New SqlParameter("@MetierId", CInt(outNew.Value)))
            pS.Add(New SqlParameter("@SecteurId", If(ddlSecteur.SelectedValue = "", CObj(DBNull.Value), CObj(CInt(ddlSecteur.SelectedValue)))))
            ExecuteSQL("s0934SetMetierSecteur", pS)

            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
                "if (typeof closeWin === 'function') closeWin();", True)

        Catch ex As SqlException
            ShowMsg(ex.Message, isError:=True)
        Catch ex As Exception
            ShowMsg("Erreur : " & ex.Message, isError:=True)
        End Try
    End Sub

    Private Sub btnDelete_Click(sender As Object, e As EventArgs) Handles btnDelete.Click
        Dim id As Integer = 0
        Integer.TryParse(hfId.Value, id)
        If id <= 0 Then Return

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            ExecuteSQL("s0916DeleteMetier", p)
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
                "if (typeof closeWin === 'function') closeWin();", True)
        Catch ex As SqlException
            ShowMsg(ex.Message, isError:=True)
        End Try
    End Sub

    ' ---------------------------------------------------------------------
    ' Helpers
    ' ---------------------------------------------------------------------
    Private Function S(o As Object) As String
        If o Is Nothing OrElse o Is DBNull.Value Then Return ""
        Return o.ToString()
    End Function

    Private Sub SetDdl(ddl As DropDownList, value As String)
        ddl.ClearSelection()
        Dim item As ListItem = ddl.Items.FindByValue(value)
        If item IsNot Nothing Then item.Selected = True
    End Sub

    ''' <summary>Choisit la valeur, en l'ajoutant à la liste si elle n'y est pas (valeur venue de la base).</summary>
    Private Sub AjouterSiAbsent(ddl As DropDownList, value As String)
        If value <> "" AndAlso ddl.Items.FindByValue(value) Is Nothing Then ddl.Items.Add(New ListItem(value, value))
        SetDdl(ddl, value)
    End Sub

    Private Sub ShowMsg(text As String, Optional isError As Boolean = False)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = "msg " & If(isError, "bad", "ok")
    End Sub

End Class
