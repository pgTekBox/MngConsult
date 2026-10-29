Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports BCrypt.Net

''' <summary>
''' Membres et sécurité du cabinet (Portail comptable, admin/solo). Inviter un
''' membre (compte comptable créé IsActive=0 + jeton ; courriel d'invitation via
''' MailService + lien copiable), modifier son rôle/équipe, le désactiver,
''' renvoyer l'invitation. Procs s0922/s0923/s0924/s0927 + s0928 (équipes).
''' </summary>
Public Class wbfCabMembres
    Inherits clsData

    Protected WithEvents pnlForm As System.Web.UI.WebControls.Panel
    Protected WithEvents litTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents litFormTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblFirst As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblLast As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblEmail As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblRole As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblActive As System.Web.UI.WebControls.Literal
    Protected WithEvents txtFirst As System.Web.UI.WebControls.TextBox
    Protected WithEvents txtLast As System.Web.UI.WebControls.TextBox
    Protected WithEvents txtEmail As System.Web.UI.WebControls.TextBox
    Protected WithEvents ddlRole As System.Web.UI.WebControls.DropDownList
    Protected WithEvents pnlActive As System.Web.UI.WebControls.Panel
    Protected WithEvents cbActive As System.Web.UI.WebControls.CheckBox
    Protected WithEvents btnSave As System.Web.UI.WebControls.Button
    Protected WithEvents btnCancel As System.Web.UI.WebControls.Button
    Protected WithEvents litMsg As System.Web.UI.WebControls.Literal
    Protected WithEvents litListeTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents rptMembres As System.Web.UI.WebControls.Repeater
    Protected WithEvents litVide As System.Web.UI.WebControls.Literal

    Private Property EditMembreId As Integer
        Get
            Return CInt(If(ViewState("EditMembreId"), 0))
        End Get
        Set(value As Integer)
            ViewState("EditMembreId") = value
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
            BindRoleDropdown()
            ResetForm()
            BindMembres()
        End If
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    ''' <summary>Le rôle du comptable connecté dans son cabinet (s0919).</summary>
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
        litTitre.Text = Server.HtmlEncode(T("Membres et sécurité", "Members and security", "Miembros y seguridad"))
        litSous.Text = Server.HtmlEncode(T("Invitez des collègues à votre cabinet et gérez leur rôle.",
                                           "Invite colleagues to your firm and manage their role.",
                                           "Invite a colegas a su despacho y gestione su rol."))
        litLblFirst.Text = Server.HtmlEncode(T("Prénom", "First name", "Nombre"))
        litLblLast.Text = Server.HtmlEncode(T("Nom", "Last name", "Apellido"))
        litLblEmail.Text = Server.HtmlEncode(T("Courriel", "Email", "Correo"))
        litLblRole.Text = Server.HtmlEncode(T("Rôle", "Role", "Rol"))
        litLblActive.Text = Server.HtmlEncode(T("Compte actif", "Active account", "Cuenta activa"))
        litListeTitre.Text = Server.HtmlEncode(T("Membres du cabinet", "Firm members", "Miembros del despacho"))
    End Sub

    Private Sub BindRoleDropdown()
        ddlRole.Items.Clear()
        ddlRole.Items.Add(New ListItem(T("Employé", "Employee", "Empleado"), "employe"))
        ddlRole.Items.Add(New ListItem(T("Administrateur", "Administrator", "Administrador"), "admin"))
    End Sub

    Private Sub BindMembres()
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0922ListCabinetMembres", p)
        Dim dt As DataTable = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
        rptMembres.DataSource = dt
        rptMembres.DataBind()
        litVide.Text = If(dt.Rows.Count = 0, "<div class=""em"" style=""color:#44536E"">" & Server.HtmlEncode(T("Aucun membre.", "No member.", "Ningún miembro.")) & "</div>", "")
    End Sub

    ''' <summary>Remet le formulaire en mode « inviter ».</summary>
    Private Sub ResetForm()
        EditMembreId = 0
        litFormTitre.Text = Server.HtmlEncode(T("Inviter un membre", "Invite a member", "Invitar a un miembro"))
        txtFirst.Text = "" : txtLast.Text = "" : txtEmail.Text = ""
        txtEmail.Enabled = True
        ddlRole.SelectedValue = "employe"
        pnlActive.Visible = False
        cbActive.Checked = True
        btnSave.Text = T("Inviter", "Invite", "Invitar")
        btnCancel.Visible = False
    End Sub

    Private Function GetMembre(membreId As Integer) As DataRow
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0922ListCabinetMembres", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                If Convert.ToInt32(r("MembreId")) = membreId Then Return r
            Next
        End If
        Return Nothing
    End Function

    Private Sub ChargerPourEdition(membreId As Integer)
        Dim r As DataRow = GetMembre(membreId)
        If r Is Nothing Then Return
        EditMembreId = membreId
        litFormTitre.Text = Server.HtmlEncode(T("Modifier le membre", "Edit member", "Editar miembro"))
        txtFirst.Text = Convert.ToString(r("FirstName"))
        txtLast.Text = Convert.ToString(r("LastName"))
        txtEmail.Text = Convert.ToString(r("Email"))
        txtEmail.Enabled = False
        SelectValue(ddlRole, Convert.ToString(r("Role")))
        pnlActive.Visible = True
        cbActive.Checked = Convert.ToBoolean(r("IsActive"))
        btnSave.Text = T("Enregistrer", "Save", "Guardar")
        btnCancel.Visible = True
    End Sub

    Private Shared Sub SelectValue(ddl As DropDownList, value As String)
        ddl.ClearSelection()
        Dim it As ListItem = ddl.Items.FindByValue(If(value, ""))
        If it IsNot Nothing Then it.Selected = True
    End Sub

    Protected Sub rptMembres_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptMembres.ItemCommand
        Dim membreId As Integer = CInt(e.CommandArgument)
        Select Case e.CommandName
            Case "edit"
                ChargerPourEdition(membreId)
            Case "resend"
                RenvoyerInvitation(membreId)
                BindMembres()
            Case "toggle"
                BasculerActif(membreId)
                BindMembres()
        End Select
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs) Handles btnCancel.Click
        ResetForm()
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        If EditMembreId > 0 Then
            Enregistrer(EditMembreId)
        Else
            Inviter()
        End If
    End Sub

    ''' <summary>Invitation d'un nouveau membre : création du compte + courriel + lien.</summary>
    Private Sub Inviter()
        Dim email As String = txtEmail.Text.Trim()
        If email = "" OrElse Not email.Contains("@") Then
            Msg("err", T("Courriel invalide.", "Invalid email.", "Correo no válido.")) : Return
        End If

        Dim placeholder As String = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString(), 11)

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@Email", email))
        p.Add(New SqlParameter("@FirstName", Nz(txtFirst.Text.Trim())))
        p.Add(New SqlParameter("@LastName", Nz(txtLast.Text.Trim())))
        p.Add(New SqlParameter("@Role", ddlRole.SelectedValue))
        p.Add(New SqlParameter("@EquipeId", DBNull.Value))
        ' Pas de compagnie maison réelle : un membre accède aux dossiers par le
        ' périmètre du cabinet, jamais via une compagnie maison.
        p.Add(New SqlParameter("@HomeCompanyGUID", Guid.Empty))
        p.Add(New SqlParameter("@PlaceholderHash", placeholder))
        Dim outTok As New SqlParameter("@Token", SqlDbType.UniqueIdentifier) With {.Direction = ParameterDirection.Output}
        Dim outUid As New SqlParameter("@NewUserId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outTok) : p.Add(outUid) : p.Add(outErr)
        ExecuteSQL("s0923InviteCabinetMembre", p)

        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        If err = 1 Then
            Msg("err", T("Ce courriel est déjà utilisé.", "This email is already in use.", "Este correo ya está en uso.")) : Return
        ElseIf err <> 0 OrElse outTok.Value Is Nothing OrElse IsDBNull(outTok.Value) Then
            Msg("err", T("L'invitation n'a pas pu être créée.", "The invitation could not be created.", "No se pudo crear la invitación.")) : Return
        End If

        Dim token As Guid = CType(outTok.Value, Guid)
        Dim lien As String = LienInvitation(token)
        EnvoyerCourrielInvitation(email, lien)   ' best-effort

        ResetForm()
        BindMembres()

        ' Confirmation + lien copiable
        Dim sb As New StringBuilder()
        sb.Append("<div class=""msg ok"">")
        sb.Append(Server.HtmlEncode(T("Invitation envoyée à ", "Invitation sent to ", "Invitación enviada a ") & email & "."))
        sb.Append("<div class=""invlink""><input type=""text"" readonly value=""").Append(Server.HtmlEncode(lien)).Append(""" onclick=""this.select()"" />")
        sb.Append("<button type=""button"" class=""btn sec"" onclick=""navigator.clipboard.writeText('").Append(HttpUtility.JavaScriptStringEncode(lien)).Append("')"">")
        sb.Append(Server.HtmlEncode(T("Copier le lien", "Copy link", "Copiar enlace"))).Append("</button></div></div>")
        litMsg.Text = sb.ToString()
    End Sub

    Private Sub Enregistrer(membreId As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@MembreId", membreId))
        p.Add(New SqlParameter("@Role", ddlRole.SelectedValue))
        p.Add(New SqlParameter("@EquipeId", DBNull.Value))
        p.Add(New SqlParameter("@IsActive", cbActive.Checked))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s0924UpdateCabinetMembre", p)

        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        Select Case err
            Case 0
                ResetForm() : BindMembres()
                Msg("ok", T("Membre mis à jour.", "Member updated.", "Miembro actualizado."))
            Case 3
                Msg("err", T("Impossible : c'est le dernier administrateur.", "Not allowed: this is the last administrator.", "No permitido: es el último administrador."))
            Case 4
                Msg("err", T("Vous ne pouvez pas vous désactiver vous-même.", "You cannot deactivate yourself.", "No puede desactivarse a sí mismo."))
            Case Else
                Msg("err", T("La mise à jour a échoué.", "The update failed.", "La actualización falló."))
        End Select
    End Sub

    Private Sub BasculerActif(membreId As Integer)
        Dim r As DataRow = GetMembre(membreId)
        If r Is Nothing Then Return
        Dim nouvelEtat As Boolean = Not Convert.ToBoolean(r("IsActive"))

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@MembreId", membreId))
        p.Add(New SqlParameter("@Role", Convert.ToString(r("Role"))))
        p.Add(New SqlParameter("@EquipeId", If(IsDBNull(r("EquipeId")), CType(DBNull.Value, Object), Convert.ToInt32(r("EquipeId")))))
        p.Add(New SqlParameter("@IsActive", nouvelEtat))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s0924UpdateCabinetMembre", p)

        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        If err = 3 Then
            Msg("err", T("Impossible : c'est le dernier administrateur.", "Not allowed: this is the last administrator.", "No permitido: es el último administrador."))
        ElseIf err = 4 Then
            Msg("err", T("Vous ne pouvez pas vous désactiver vous-même.", "You cannot deactivate yourself.", "No puede desactivarse a sí mismo."))
        End If
    End Sub

    Private Sub RenvoyerInvitation(membreId As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@MembreId", membreId))
        Dim outTok As New SqlParameter("@Token", SqlDbType.UniqueIdentifier) With {.Direction = ParameterDirection.Output}
        Dim outMail As New SqlParameter("@Email", SqlDbType.NVarChar, 200) With {.Direction = ParameterDirection.Output}
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outTok) : p.Add(outMail) : p.Add(outErr)
        ExecuteSQL("s0927ResendInvite", p)

        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        If err <> 0 OrElse outTok.Value Is Nothing OrElse IsDBNull(outTok.Value) Then
            Msg("err", T("Le renvoi a échoué.", "Resend failed.", "El reenvío falló.")) : Return
        End If
        Dim email As String = Convert.ToString(outMail.Value)
        Dim lien As String = LienInvitation(CType(outTok.Value, Guid))
        EnvoyerCourrielInvitation(email, lien)

        Dim sb As New StringBuilder()
        sb.Append("<div class=""msg ok"">").Append(Server.HtmlEncode(T("Invitation renvoyée à ", "Invitation resent to ", "Invitación reenviada a ") & email & "."))
        sb.Append("<div class=""invlink""><input type=""text"" readonly value=""").Append(Server.HtmlEncode(lien)).Append(""" onclick=""this.select()"" />")
        sb.Append("<button type=""button"" class=""btn sec"" onclick=""navigator.clipboard.writeText('").Append(HttpUtility.JavaScriptStringEncode(lien)).Append("')"">")
        sb.Append(Server.HtmlEncode(T("Copier le lien", "Copy link", "Copiar enlace"))).Append("</button></div></div>")
        litMsg.Text = sb.ToString()
    End Sub

    Private Function LienInvitation(token As Guid) As String
        Dim rel As String = ResolveUrl("~/wbfCabInvitation.aspx?token=" & token.ToString())
        Return Request.Url.GetLeftPart(UriPartial.Authority) & rel
    End Function

    ''' <summary>Dépose le courriel d'invitation dans MailService (best-effort).</summary>
    Private Sub EnvoyerCourrielInvitation(email As String, lien As String)
        Try
            Dim sujet As String = T("Invitation à rejoindre un cabinet sur 60Sec-AI", "Invitation to join a firm on 60Sec-AI", "Invitación para unirse a un despacho en 60Sec-AI")
            Dim corps As String = T("Vous avez été invité à rejoindre un cabinet comptable sur 60Sec-AI. Cliquez sur le lien pour activer votre compte :",
                                     "You have been invited to join an accounting firm on 60Sec-AI. Click the link to activate your account:",
                                     "Se le ha invitado a unirse a un despacho contable en 60Sec-AI. Haga clic en el enlace para activar su cuenta:")
            Dim html As String = "<p>" & Server.HtmlEncode(corps) & "</p><p><a href=""" & lien & """>" & Server.HtmlEncode(lien) & "</a></p>"
            Dim txt As String = corps & vbCrLf & lien

            Dim p As New Collection
            p.Add(New SqlParameter("@To", email))
            p.Add(New SqlParameter("@Subject", sujet))
            p.Add(New SqlParameter("@HTMLBody", html))
            p.Add(New SqlParameter("@TextBody", txt))
            ExecuteSQLMail("s0610InsertOutboundMail", p)
        Catch
            ' La livraison du courriel ne doit jamais bloquer l'invitation : le lien copiable reste disponible.
        End Try
    End Sub

    Private Shared Function Nz(s As String) As Object
        Return If(String.IsNullOrEmpty(s), CType(DBNull.Value, Object), s)
    End Function

    Private Sub Msg(kind As String, txt As String)
        litMsg.Text = "<div class=""msg " & kind & """>" & Server.HtmlEncode(txt) & "</div>"
    End Sub

    ' ---- Helpers de rendu pour le Repeater ----

    Protected Function Initiales(first As Object, last As Object, email As Object) As String
        Dim f As String = Convert.ToString(first).Trim()
        Dim l As String = Convert.ToString(last).Trim()
        If f.Length > 0 AndAlso l.Length > 0 Then Return (f.Substring(0, 1) & l.Substring(0, 1)).ToUpperInvariant()
        If f.Length > 0 Then Return f.Substring(0, 1).ToUpperInvariant()
        Dim em As String = Convert.ToString(email).Trim()
        If em.Length > 0 Then Return em.Substring(0, 1).ToUpperInvariant()
        Return "?"
    End Function

    Protected Function NomAffiche(first As Object, last As Object, email As Object) As String
        Dim nom As String = (Convert.ToString(first) & " " & Convert.ToString(last)).Trim()
        If nom = "" Then nom = Convert.ToString(email)
        Return Server.HtmlEncode(nom)
    End Function

    Protected Function MoiTag(isMe As Object) As String
        If Convert.ToBoolean(isMe) Then Return " <span class=""tag role"">" & Server.HtmlEncode(T("vous", "you", "usted")) & "</span>"
        Return ""
    End Function

    Protected Function RoleLabel(role As Object) As String
        Select Case Convert.ToString(role).ToLowerInvariant()
            Case "admin" : Return Server.HtmlEncode(T("Administrateur", "Administrator", "Administrador"))
            Case "responsable" : Return Server.HtmlEncode(T("Responsable", "Team lead", "Responsable"))
            Case "solo" : Return Server.HtmlEncode(T("Solo", "Solo", "Solo"))
            Case Else : Return Server.HtmlEncode(T("Employé", "Employee", "Empleado"))
        End Select
    End Function

    Protected Function TeamTag(nom As Object) As String
        If nom Is Nothing OrElse IsDBNull(nom) OrElse Convert.ToString(nom) = "" Then Return ""
        Return "<span class=""tag team"">" & Server.HtmlEncode(Convert.ToString(nom)) & "</span>"
    End Function

    Protected Function StatutTag(pending As Object, isActive As Object) As String
        If Convert.ToBoolean(pending) Then
            Return "<span class=""tag pending"">" & Server.HtmlEncode(T("Invitation en attente", "Invitation pending", "Invitación pendiente")) & "</span>"
        ElseIf Not Convert.ToBoolean(isActive) Then
            Return "<span class=""tag off"">" & Server.HtmlEncode(T("Désactivé", "Deactivated", "Desactivado")) & "</span>"
        End If
        Return ""
    End Function

    Protected Function ConfirmJs() As String
        Dim msg As String = T("Changer l'accès de ce membre ?", "Change this member's access?", "¿Cambiar el acceso de este miembro?")
        Return "if(!confirm('" & HttpUtility.JavaScriptStringEncode(msg) & "')){return false;}"
    End Function

    Protected ReadOnly Property LblModifier As String
        Get
            Return T("Modifier", "Edit", "Editar")
        End Get
    End Property
    Protected ReadOnly Property LblRenvoyer As String
        Get
            Return T("Renvoyer l'invitation", "Resend invitation", "Reenviar invitación")
        End Get
    End Property
    Protected ReadOnly Property LblDesactiver As String
        Get
            Return T("Désactiver", "Deactivate", "Desactivar")
        End Get
    End Property
    Protected ReadOnly Property LblActiver As String
        Get
            Return T("Activer", "Activate", "Activar")
        End Get
    End Property

End Class
