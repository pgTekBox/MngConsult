Imports Telerik.Web.UI

Public Class wbfPlanComptableEdit
    Inherits clsData

    Property CompteId() As Integer
        Get
            Try
                If ViewState("CompteId") Is Nothing Then ViewState("CompteId") = 0
                Return CInt(ViewState("CompteId"))
            Catch ex As Exception
                Return 0
            End Try
        End Get
        Set(ByVal Value As Integer)
            ViewState("CompteId") = Value
        End Set
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            BindDDL()
            CompteId = CInt(Request.QueryString("Id"))
            BindData()
        End If
    End Sub

    ' ── Chargement des listes déroulantes ──

    Sub BindDDL()
        ' Classes parentes (Niveau 1)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@Niveau", 1))
        SetDDL(rddlClasseParent, "Name", "Value", "s0051GetClassesByNiveau", p)
    End Sub

    ''' <summary>
    ''' Quand on sélectionne une classe parente, on charge les sous-classes correspondantes
    ''' </summary>
    Protected Sub rddlClasseParent_SelectedIndexChanged(sender As Object, e As DropDownListEventArgs) Handles rddlClasseParent.SelectedIndexChanged
        LoadSousClasses()
        AutoFillFromClasse()
    End Sub

    Private Sub LoadSousClasses()
        If String.IsNullOrEmpty(rddlClasseParent.SelectedValue) Then Return

        Dim parentId As Integer = CInt(rddlClasseParent.SelectedValue)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@ParentId", parentId))
        SetDDL(rddlClasse, "Name", "Value", "s0052GetSousClasses", p)
    End Sub

    ''' <summary>
    ''' Auto-remplit TypeBilan et Sens selon la classe parente sélectionnée
    ''' </summary>
    Private Sub AutoFillFromClasse()
        If String.IsNullOrEmpty(rddlClasseParent.SelectedValue) Then Return

        Dim parentId As Integer = CInt(rddlClasseParent.SelectedValue)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@Id", parentId))
        Dim ds As DataSet = ExecuteSQLds("s0053GetClasseInfo", p)

        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
            Dim row As DataRow = ds.Tables(0).Rows(0)
            rddlTypeBilan.SelectedValue = row("TypeBilan").ToString()
            rddlSens.SelectedValue = row("Sens").ToString()
        End If
    End Sub

    ' ── Chargement des données ──

    Sub BindData()
        If CompteId = 0 Then
            ' Nouveau compte
            lblTitle.Text = "Nouveau compte"
            lblSub.Text = "Remplissez les informations du compte"
            txtNumero.Text = ""
            txtNom.Text = ""
            txtDescription.Text = ""
            chkActif.Checked = True
            chkSysteme.Checked = False
            pnlInfo.Visible = False
        Else
            ' Compte existant
            lblTitle.Text = "Modifier le compte"

            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Id", CompteId))
            Dim ds As DataSet = ExecuteSQLds("s0049GetOneCompte", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

            Dim row As DataRow = ds.Tables(0).Rows(0)

            txtNumero.Text = row("Numero").ToString()
            txtNom.Text = row("Nom").ToString()
            txtDescription.Text = row("Description").ToString()
            chkActif.Checked = CBool(row("Actif"))
            chkSysteme.Checked = CBool(row("Systeme"))

            ' Sélectionner la classe parente puis charger les sous-classes
            rddlClasseParent.SelectedValue = row("ClasseParentId").ToString()
            LoadSousClasses()
            rddlClasse.SelectedValue = row("ClasseId").ToString()

            rddlTypeBilan.SelectedValue = row("TypeBilan").ToString()
            rddlSens.SelectedValue = row("Sens").ToString()

            lblSub.Text = "Numéro : " & row("Numero").ToString()

            ' Info
            pnlInfo.Visible = True
            tlblId.Text = row("Id").ToString()
            If Not IsDBNull(row("Created")) Then
                tlblCreated.Text = CDate(row("Created")).ToString("yyyy-MM-dd HH:mm")
            End If

            ' Empêcher la suppression d'un compte système
            If chkSysteme.Checked Then
                chkSysteme.Enabled = False
            End If
        End If
    End Sub

    ' ── Sauvegarde ──

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click

        ' Validation basique
        If String.IsNullOrWhiteSpace(txtNumero.Text) Then
            ShowMsg("Le numéro de compte est obligatoire.", False)
            Return
        End If
        If String.IsNullOrWhiteSpace(txtNom.Text) Then
            ShowMsg("Le nom du compte est obligatoire.", False)
            Return
        End If
        If String.IsNullOrEmpty(rddlClasse.SelectedValue) Then
            ShowMsg("Veuillez sélectionner une sous-classe.", False)
            Return
        End If

        If CompteId = 0 Then
            InsertCompte()
        Else
            UpdateCompte()
        End If

        ' Fermer la fenêtre
        Dim script As String = "function fw(){closeWin(); Sys.Application.remove_load(fw);}Sys.Application.add_load(fw);"
        ScriptManager.RegisterStartupScript(Page, Page.GetType(), "close", script, True)
    End Sub

    Private Sub InsertCompte()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Numero", txtNumero.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Nom", txtNom.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@ClasseId", CInt(rddlClasse.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@ClasseParentId", CInt(rddlClasseParent.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@TypeBilan", rddlTypeBilan.SelectedValue))
        p.Add(New SqlClient.SqlParameter("@Sens", rddlSens.SelectedValue))
        p.Add(New SqlClient.SqlParameter("@Actif", chkActif.Checked))
        p.Add(New SqlClient.SqlParameter("@Description", DbNullIfEmpty(txtDescription.Text)))

        Dim ds As DataSet = ExecuteSQLds("s0054InsertPlanComptableCompte", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            CompteId = CInt(ds.Tables(0).Rows(0)(0))
        End If
    End Sub

    Private Sub UpdateCompte()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Id", CompteId))
        p.Add(New SqlClient.SqlParameter("@Numero", txtNumero.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Nom", txtNom.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@ClasseId", CInt(rddlClasse.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@ClasseParentId", CInt(rddlClasseParent.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@TypeBilan", rddlTypeBilan.SelectedValue))
        p.Add(New SqlClient.SqlParameter("@Sens", rddlSens.SelectedValue))
        p.Add(New SqlClient.SqlParameter("@Actif", chkActif.Checked))
        p.Add(New SqlClient.SqlParameter("@Description", DbNullIfEmpty(txtDescription.Text)))

        ExecuteSQL("s0055UpdatePlanComptableCompte", p)
    End Sub

    ' ── Utilitaires ──

    Private Sub ShowMsg(msg As String, success As Boolean)
        lblMsg.Visible = True
        lblMsg.CssClass = If(success, "msg msg-ok", "msg msg-err")
        lblMsg.Text = msg
    End Sub

    Private Function DbNullIfEmpty(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Return s.Trim()
    End Function

End Class
