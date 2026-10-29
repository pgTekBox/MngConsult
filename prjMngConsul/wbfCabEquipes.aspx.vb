Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Équipes du cabinet (Portail comptable, admin/solo). Créer/renommer une équipe,
''' choisir son responsable (un membre), désactiver. Procs s0928/s0929 + s0922.
''' </summary>
Public Class wbfCabEquipes
    Inherits clsData

    Protected WithEvents litTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents litFormTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblNom As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblResp As System.Web.UI.WebControls.Literal
    Protected WithEvents txtNom As System.Web.UI.WebControls.TextBox
    Protected WithEvents ddlResp As System.Web.UI.WebControls.DropDownList
    Protected WithEvents btnSave As System.Web.UI.WebControls.Button
    Protected WithEvents btnCancel As System.Web.UI.WebControls.Button
    Protected WithEvents litMsg As System.Web.UI.WebControls.Literal
    Protected WithEvents litListeTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents rptEquipes As System.Web.UI.WebControls.Repeater
    Protected WithEvents litVide As System.Web.UI.WebControls.Literal

    Private Property EditId As Integer
        Get
            Return CInt(If(ViewState("EditId"), 0))
        End Get
        Set(value As Integer)
            ViewState("EditId") = value
        End Set
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        Dim role As String = RoleCabinet()
        If role <> "admin" AndAlso role <> "solo" Then
            Response.Redirect("~/wbfCabTableauBord.aspx") : Return
        End If

        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        If Not IsPostBack Then
            Textes()
            BindResp()
            ResetForm()
            BindEquipes()
        End If
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Function RoleCabinet() As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0919GetUserCabinet", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return Convert.ToString(ds.Tables(0).Rows(0)("Role")).Trim().ToLowerInvariant()
            End If
        Catch
        End Try
        Return ""
    End Function

    Private Sub Textes()
        litTitre.Text = Server.HtmlEncode(T("Équipes", "Teams", "Equipos"))
        litSous.Text = Server.HtmlEncode(T("Organisez votre cabinet en équipes et nommez un responsable.",
                                           "Organize your firm into teams and name a lead.",
                                           "Organice su despacho en equipos y nombre un responsable."))
        litLblNom.Text = Server.HtmlEncode(T("Nom de l'équipe", "Team name", "Nombre del equipo"))
        litLblResp.Text = Server.HtmlEncode(T("Responsable", "Team lead", "Responsable"))
        litListeTitre.Text = Server.HtmlEncode(T("Équipes du cabinet", "Firm teams", "Equipos del despacho"))
    End Sub

    Private Sub BindResp()
        ddlResp.Items.Clear()
        ddlResp.Items.Add(New ListItem(T("— Aucun —", "— None —", "— Ninguno —"), ""))
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0922ListCabinetMembres", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    Dim nom As String = (Convert.ToString(r("FirstName")) & " " & Convert.ToString(r("LastName"))).Trim()
                    If nom = "" Then nom = Convert.ToString(r("Email"))
                    ddlResp.Items.Add(New ListItem(nom, Convert.ToString(r("UserGUID"))))
                Next
            End If
        Catch
        End Try
    End Sub

    Private Sub BindEquipes()
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0928ListEquipes", p)
        Dim dt As DataTable = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
        rptEquipes.DataSource = dt
        rptEquipes.DataBind()
        litVide.Text = If(dt.Rows.Count = 0, "<div class=""em"" style=""color:#44536E"">" & Server.HtmlEncode(T("Aucune équipe pour l'instant.", "No team yet.", "Aún no hay equipos.")) & "</div>", "")
    End Sub

    Private Sub ResetForm()
        EditId = 0
        litFormTitre.Text = Server.HtmlEncode(T("Nouvelle équipe", "New team", "Nuevo equipo"))
        txtNom.Text = ""
        ddlResp.SelectedIndex = 0
        btnSave.Text = T("Créer", "Create", "Crear")
        btnCancel.Visible = False
    End Sub

    Protected Sub rptEquipes_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptEquipes.ItemCommand
        Dim id As Integer = CInt(e.CommandArgument)
        Select Case e.CommandName
            Case "edit"
                ChargerPourEdition(id)
            Case "del"
                Supprimer(id)
                BindEquipes()
        End Select
    End Sub

    Private Sub ChargerPourEdition(id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0928ListEquipes", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return
        For Each r As DataRow In ds.Tables(0).Rows
            If Convert.ToInt32(r("Id")) = id Then
                EditId = id
                litFormTitre.Text = Server.HtmlEncode(T("Modifier l'équipe", "Edit team", "Editar equipo"))
                txtNom.Text = Convert.ToString(r("Nom"))
                ddlResp.ClearSelection()
                Dim rg As String = If(IsDBNull(r("ResponsableUserGUID")), "", Convert.ToString(r("ResponsableUserGUID")))
                Dim it As ListItem = ddlResp.Items.FindByValue(rg)
                If it IsNot Nothing Then it.Selected = True
                btnSave.Text = T("Enregistrer", "Save", "Guardar")
                btnCancel.Visible = True
                Exit For
            End If
        Next
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs) Handles btnCancel.Click
        ResetForm()
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        Dim nom As String = txtNom.Text.Trim()
        If nom = "" Then
            litMsg.Text = "<div class=""msg err"">" & Server.HtmlEncode(T("Donnez un nom à l'équipe.", "Give the team a name.", "Dé un nombre al equipo.")) & "</div>"
            Return
        End If

        Dim resp As Object = DBNull.Value
        If Not String.IsNullOrEmpty(ddlResp.SelectedValue) Then resp = New Guid(ddlResp.SelectedValue)

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@Id", EditId))
        p.Add(New SqlParameter("@Nom", nom))
        p.Add(New SqlParameter("@ResponsableUserGUID", resp))
        p.Add(New SqlParameter("@IsActive", True))
        Dim outNew As New SqlParameter("@NewId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outNew) : p.Add(outErr)
        ExecuteSQL("s0929SaveEquipe", p)

        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        If err <> 0 Then
            litMsg.Text = "<div class=""msg err"">" & Server.HtmlEncode(T("L'enregistrement a échoué.", "Save failed.", "El guardado falló.")) & "</div>"
            Return
        End If

        ResetForm()
        BindEquipes()
        litMsg.Text = "<div class=""msg ok"">" & Server.HtmlEncode(T("Équipe enregistrée.", "Team saved.", "Equipo guardado.")) & "</div>"
    End Sub

    Private Sub Supprimer(id As Integer)
        ' Désactivation logique via s0929 (IsActive=0). Il faut renvoyer le nom courant.
        Dim nom As String = ""
        Dim resp As Object = DBNull.Value
        Dim p0 As New Collection
        p0.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0928ListEquipes", p0)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                If Convert.ToInt32(r("Id")) = id Then
                    nom = Convert.ToString(r("Nom"))
                    If Not IsDBNull(r("ResponsableUserGUID")) Then resp = New Guid(Convert.ToString(r("ResponsableUserGUID")))
                    Exit For
                End If
            Next
        End If
        If nom = "" Then Return

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@Nom", nom))
        p.Add(New SqlParameter("@ResponsableUserGUID", resp))
        p.Add(New SqlParameter("@IsActive", False))
        Dim outNew As New SqlParameter("@NewId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outNew) : p.Add(outErr)
        ExecuteSQL("s0929SaveEquipe", p)
        litMsg.Text = "<div class=""msg ok"">" & Server.HtmlEncode(T("Équipe supprimée.", "Team removed.", "Equipo eliminado.")) & "</div>"
    End Sub

    ' ---- Helpers de rendu ----
    Protected Function RespText(nom As Object) As String
        If nom Is Nothing OrElse IsDBNull(nom) OrElse Convert.ToString(nom).Trim() = "" Then
            Return Server.HtmlEncode(T("Sans responsable", "No lead", "Sin responsable"))
        End If
        Return Server.HtmlEncode(T("Responsable : ", "Lead: ", "Responsable: ") & Convert.ToString(nom))
    End Function

    Protected Function NbText(n As Object) As String
        Dim nb As Integer = Convert.ToInt32(n)
        If nb = 1 Then Return Server.HtmlEncode(T("1 membre", "1 member", "1 miembro"))
        Return Server.HtmlEncode(nb.ToString() & T(" membres", " members", " miembros"))
    End Function

    Protected Function ConfirmJs() As String
        Dim msg As String = T("Supprimer cette équipe ?", "Remove this team?", "¿Eliminar este equipo?")
        Return "if(!confirm('" & HttpUtility.JavaScriptStringEncode(msg) & "')){return false;}"
    End Function

    Protected ReadOnly Property LblModifier As String
        Get
            Return T("Modifier", "Edit", "Editar")
        End Get
    End Property
    Protected ReadOnly Property LblSupprimer As String
        Get
            Return T("Supprimer", "Remove", "Eliminar")
        End Get
    End Property

End Class
