Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

''' <summary>
''' Gestion des employés (= ressources de l'agenda, table T300Employees).
''' Liste + recherche + édition (RadWindow), attribution d'une boîte @60sec.ca,
''' et envoi d'un lien de réinitialisation du mot de passe au courriel externe.
''' </summary>
Public Class wbfEmployees
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If
        ApplyLocalization()
        If Not IsPostBack Then rlvEmployees.Rebind()
    End Sub

    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
        btnAddEmployee.Text = L("add")
        tbSearch.Attributes("placeholder") = L("searchPh")
        btnClear.ToolTip = L("clear")
        rwEmployee.Title = L("winTitle")
    End Sub

    Private Sub rlvEmployees_PreRender(sender As Object, e As EventArgs) Handles rlvEmployees.PreRender
        SetLiteral(rlvEmployees, "litColName", L("colName"))
        SetLiteral(rlvEmployees, "litColExt", L("colExt"))
        SetLiteral(rlvEmployees, "litColBox", L("colBox"))
        SetLiteral(rlvEmployees, "litColState", L("colState"))
        SetLiteral(rlvEmployees, "litColAction", L("colAction"))
        SetLiteral(rlvEmployees, "litEmpty", L("empty"))
    End Sub

    Private Sub rlvEmployees_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvEmployees.NeedDataSource
        rlvEmployees.DataSource = GetData()
    End Sub

    Private Function GetData() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Search", tbSearch.Text.Trim()))
        Dim ds As DataSet = ExecuteSQLds("s0719GetEmployees", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvEmployees.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvEmployees.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If e.Argument = "refreshgrid" Then rlvEmployees.Rebind()
    End Sub

    ' ---- Commandes de ligne ------------------------------------------------

    Private Sub rlvEmployees_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvEmployees.ItemCommand
        If e.CommandArgument Is Nothing Then Return
        Dim id As Integer = CInt(e.CommandArgument)
        Select Case e.CommandName
            Case "DeleteEmployee"
                Dim p As New Collection
                p.Add(New SqlParameter("@CompanyGUID", Company))
                p.Add(New SqlParameter("@Id", id))
                ExecuteSQL("s0722DeleteEmployee", p)
                rlvEmployees.Rebind()
            Case "AssignMailbox"
                AssignMailbox(id)
                rlvEmployees.Rebind()
            Case "ResetPwd"
                SendReset(id)
                rlvEmployees.Rebind()
        End Select
    End Sub

    Private Sub AssignMailbox(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Id", id))
            Dim ds As DataSet = ExecuteSQLds("s0723AssignEmployeeMailbox", p)
            Dim email As String = ""
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                email = Val_(ds.Tables(0).Rows(0)("Email"))
            End If
            Alert(String.Format(L("boxAssigned"), email))
        Catch ex As Exception
            Alert(L("boxError") & ex.Message)
        End Try
    End Sub

    ' ---- Réinitialisation du mot de passe (lien au courriel externe) -------

    Private Sub SendReset(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Id", id))
            Dim ds As DataSet = ExecuteSQLds("s0724CreateEmployeeMailReset", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                Alert(L("resetFail")) : Return
            End If
            Dim r = ds.Tables(0).Rows(0)
            If IsDBNull(r("Ok")) OrElse Not CBool(r("Ok")) Then
                Alert(If(IsDBNull(r("Msg")), L("resetFail"), r("Msg").ToString())) : Return
            End If

            Dim token As String = r("Token").ToString()
            Dim ext As String = Val_(r("ExternalEmail"))
            Dim box As String = Val_(r("Sec60Email"))
            Dim fullName As String = Val_(r("FullName"))
            Dim companyName As String = Val_(r("CompanyName"))

            Dim link As String = ResetLink(token)
            SendResetEmail(ext, fullName, companyName, box, link)
            Alert(String.Format(L("resetSent"), ext))
        Catch ex As Exception
            Alert(L("resetFail") & " " & ex.Message)
        End Try
    End Sub

    ''' <summary>URL absolue de la page publique de réinitialisation.</summary>
    Private Function ResetLink(token As String) As String
        Dim authority As String = Request.Url.GetLeftPart(UriPartial.Authority)
        Dim path As String = ResolveUrl("~/wbfMailboxReset.aspx")
        Return authority & path & "?token=" & token
    End Function

    Private Sub SendResetEmail(toAddr As String, fullName As String, companyName As String, box As String, link As String)
        Dim safeLink As String = Server.HtmlEncode(link)
        Dim html As String =
            "<div style=""font-family:system-ui,-apple-system,Segoe UI,Arial,sans-serif;font-size:14px;color:#0f172a;line-height:1.6;"">" &
            "<p>" & Server.HtmlEncode(L("mailHello")) & " " & Server.HtmlEncode(fullName) & ",</p>" &
            "<p>" & String.Format(Server.HtmlEncode(L("mailIntro")), Server.HtmlEncode(box), Server.HtmlEncode(companyName)) & "</p>" &
            "<p><a href=""" & safeLink & """ style=""display:inline-block;padding:11px 20px;background:#2563eb;color:#fff;text-decoration:none;border-radius:8px;font-weight:700;"">" &
            Server.HtmlEncode(L("mailButton")) & "</a></p>" &
            "<p style=""font-size:12px;color:#64748b;"">" & Server.HtmlEncode(L("mailExpiry")) & "<br>" & safeLink & "</p>" &
            "</div>"
        Dim text As String = L("mailHello") & " " & fullName & vbCrLf & vbCrLf &
                             String.Format(L("mailIntro"), box, companyName) & vbCrLf & vbCrLf &
                             link & vbCrLf & vbCrLf & L("mailExpiry")

        Dim p As New Collection
        p.Add(New SqlParameter("@To", toAddr))
        p.Add(New SqlParameter("@Subject", L("mailSubject")))
        p.Add(New SqlParameter("@HTMLBody", html))
        p.Add(New SqlParameter("@TextBody", text))
        p.Add(New SqlParameter("@Sender", "noreply@60sec.ca"))
        p.Add(New SqlParameter("@From", "noreply@60sec.ca"))
        ExecuteSQLMail("s0610InsertOutboundMail", p)
    End Sub

    ' ---- Helpers ------------------------------------------------------------

    Private Sub Alert(msg As String)
        Dim safe As String = msg.Replace("\", "\\").Replace("'", "\'").Replace(vbCr, " ").Replace(vbLf, " ")
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "empMsg", "radalert('" & safe & "', 420, 200, '" & L("winTitle").Replace("'", "\'") & "');", True)
    End Sub

    Protected Function Val_(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return o.ToString()
    End Function

    Private Shared Sub SetLiteral(root As Control, id As String, text As String)
        Dim lit = TryCast(FindDeep(root, id), Literal)
        If lit IsNot Nothing Then lit.Text = text
    End Sub

    Private Shared Function FindDeep(root As Control, id As String) As Control
        If root Is Nothing Then Return Nothing
        Dim direct As Control = root.FindControl(id)
        If direct IsNot Nothing Then Return direct
        For Each ch As Control In root.Controls
            Dim r As Control = FindDeep(ch, id)
            If r IsNot Nothing Then Return r
        Next
        Return Nothing
    End Function

    ''' <summary>Traductions (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Employés — 60Sec-AI", "Employees — 60Sec-AI", "Empleados — 60Sec-AI")
            Case "pageTitleShort" : Return Choose3(lang, "Employés", "Employees", "Empleados")
            Case "add" : Return Choose3(lang, "Ajouter", "Add", "Agregar")
            Case "searchPh" : Return Choose3(lang, "Rechercher (nom, courriel…)", "Search (name, email…)", "Buscar (nombre, correo…)")
            Case "clear" : Return Choose3(lang, "Effacer", "Clear", "Borrar")
            Case "edit" : Return Choose3(lang, "Modifier", "Edit", "Editar")
            Case "delete" : Return Choose3(lang, "Supprimer", "Delete", "Eliminar")
            Case "colName" : Return Choose3(lang, "Employé", "Employee", "Empleado")
            Case "colExt" : Return Choose3(lang, "Courriel externe", "External email", "Correo externo")
            Case "colBox" : Return Choose3(lang, "Boîte @60sec.ca", "@60sec.ca mailbox", "Buzón @60sec.ca")
            Case "colState" : Return Choose3(lang, "Actif", "Active", "Activo")
            Case "colAction" : Return Choose3(lang, "Actions", "Actions", "Acciones")
            Case "stActive" : Return Choose3(lang, "Actif", "Active", "Activo")
            Case "stInactive" : Return Choose3(lang, "Inactif", "Inactive", "Inactivo")
            Case "assignBox" : Return Choose3(lang, "Attribuer boîte", "Assign mailbox", "Asignar buzón")
            Case "resetPwd" : Return Choose3(lang, "Réinit. mot de passe", "Reset password", "Restablecer contraseña")
            Case "empty" : Return Choose3(lang, "Aucun employé trouvé.", "No employee found.", "Ningún empleado encontrado.")
            Case "winTitle" : Return Choose3(lang, "Employé", "Employee", "Empleado")
            Case "addEmpWin" : Return Choose3(lang, "Ajouter un employé", "Add an employee", "Agregar un empleado")
            Case "editEmpWin" : Return Choose3(lang, "Modifier un employé", "Edit an employee", "Editar un empleado")
            Case "delConfirm" : Return Choose3(lang, "Supprimer cet employé ? Sa boîte @60sec.ca sera aussi libérée.", "Delete this employee? Their @60sec.ca mailbox will also be released.", "¿Eliminar este empleado? Su buzón @60sec.ca también será liberado.")
            Case "boxAssigned" : Return Choose3(lang, "Boîte attribuée : {0}", "Mailbox assigned: {0}", "Buzón asignado: {0}")
            Case "boxError" : Return Choose3(lang, "Erreur lors de l'attribution : ", "Error assigning mailbox: ", "Error al asignar el buzón: ")
            Case "resetSent" : Return Choose3(lang, "Lien de réinitialisation envoyé à {0}.", "Reset link sent to {0}.", "Enlace de restablecimiento enviado a {0}.")
            Case "resetFail" : Return Choose3(lang, "Impossible d'envoyer le lien.", "Unable to send the link.", "No se pudo enviar el enlace.")
            Case "mailSubject" : Return Choose3(lang, "Réinitialisation du mot de passe de votre boîte 60sec.ca", "Reset your 60sec.ca mailbox password", "Restablecer la contraseña de su buzón 60sec.ca")
            Case "mailHello" : Return Choose3(lang, "Bonjour", "Hello", "Hola")
            Case "mailIntro" : Return Choose3(lang, "Vous pouvez définir le mot de passe de votre boîte de courriel {0} ({1}) en cliquant sur le bouton ci-dessous.", "You can set the password for your mailbox {0} ({1}) by clicking the button below.", "Puede establecer la contraseña de su buzón {0} ({1}) haciendo clic en el botón de abajo.")
            Case "mailButton" : Return Choose3(lang, "Définir mon mot de passe", "Set my password", "Establecer mi contraseña")
            Case "mailExpiry" : Return Choose3(lang, "Ce lien expire dans 24 heures. Si le bouton ne fonctionne pas, copiez ce lien :", "This link expires in 24 hours. If the button does not work, copy this link:", "Este enlace expira en 24 horas. Si el botón no funciona, copie este enlace:")
            Case Else : Return ""
        End Select
    End Function

    Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

End Class
