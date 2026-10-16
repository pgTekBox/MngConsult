Imports System.Data
Imports System.Data.SqlClient
Imports System.Linq
Imports System.Text
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
        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        ApplyLocalization()
        If Not IsPostBack Then rlvEmployees.Rebind()
    End Sub

    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
        SetLiteral(Me, "litRubrique", L("rubrique"))
        SetLiteral(Me, "litSousTitre", L("sousTitre"))
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
        ChargerIndicateurs()
        Dim dt As DataTable = Filtrer(GetData())
        rlvEmployees.DataSource = dt
        SetLiteral(Me, "litPied", Server.HtmlEncode(String.Format(L("pied"), If(dt Is Nothing, 0, dt.Rows.Count), TotalEmployes)))
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
        FiltreCourant = ""
        rlvEmployees.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If If(e.Argument, "").StartsWith("chip|") Then
            ChoisirIndicateur(e.Argument)
            Return
        End If
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

    ' ---- Indicateurs, filtre (en session) et cellules au style « Portail du client » ----
    ' Les décomptes se font sur tous les employés, sans la recherche.

    Private Property FiltreCourant As String
        Get
            Return If(TryCast(Session("Emp.Filtre"), String), "")
        End Get
        Set(value As String)
            Session("Emp.Filtre") = value
        End Set
    End Property

    Private TotalEmployes As Integer

    ''' <summary>Un indicateur cliqué (« chip|kpi|valeur ») : un second clic l'enlève.</summary>
    Private Sub ChoisirIndicateur(arg As String)
        Dim parts As String() = If(arg, "").Split("|"c)
        Dim valeur As String = If(parts.Length >= 3, parts(2), "").Trim().ToLowerInvariant()
        If valeur <> "actifs" AndAlso valeur <> "inactifs" AndAlso valeur <> "avecboite" AndAlso valeur <> "sansboite" Then Return
        FiltreCourant = If(FiltreCourant = valeur, "", valeur)
        rlvEmployees.Rebind()
    End Sub

    Private Shared Function Vrai(o As Object) As Boolean
        If o Is Nothing OrElse IsDBNull(o) Then Return False
        Try
            Return Convert.ToBoolean(o)
        Catch
            Return False
        End Try
    End Function

    Private Function Garde(r As DataRow, cle As String) As Boolean
        Select Case cle
            Case "actifs" : Return Vrai(r("Active"))
            Case "inactifs" : Return Not Vrai(r("Active"))
            Case "avecboite" : Return Vrai(r("HasMailbox"))
            Case "sansboite" : Return Vrai(r("Active")) AndAlso Not Vrai(r("HasMailbox"))
            Case Else : Return True
        End Select
    End Function

    Private Function LireTout() As List(Of DataRow)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Search", ""))
            Dim ds As DataSet = ExecuteSQLds("s0719GetEmployees", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0).Rows.Cast(Of DataRow)().ToList()
        Catch
        End Try
        Return New List(Of DataRow)
    End Function

    Private Sub ChargerIndicateurs()
        Dim rows As List(Of DataRow) = LireTout()
        TotalEmployes = rows.Count
        Dim actifs As Integer = rows.Where(Function(r) Garde(r, "actifs")).Count()
        Dim avec As Integer = rows.Where(Function(r) Garde(r, "avecboite")).Count()
        Dim sans As Integer = rows.Where(Function(r) Garde(r, "sansboite")).Count()
        Dim sb As New StringBuilder()
        sb.Append(Kpi("actifs", L("kpiActifs"), actifs & " / " & rows.Count, L("kpiActifsSub"), "#43B47A"))
        sb.Append(Kpi("inactifs", L("kpiInactifs"), (rows.Count - actifs).ToString(), L("kpiInactifsSub"), "#AEBBCD"))
        sb.Append(Kpi("avecboite", L("kpiAvec"), avec.ToString(), L("kpiAvecSub"), "#1B4F9C"))
        sb.Append(Kpi("sansboite", L("kpiSans"), sans.ToString(), L("kpiSansSub"), If(sans > 0, "#E3B341", "#43B47A")))
        SetLiteral(Me, "litKpis", sb.ToString())
    End Sub

    Private Function Kpi(valeur As String, lab As String, val As String, sub_ As String, point As String) As String
        Dim actif As Boolean = (FiltreCourant = valeur)
        Return "<button type=""button"" class=""fc-kpi" & If(actif, " on", "") & """ aria-pressed=""" & If(actif, "true", "false") &
               """ onclick=""fcChip('kpi','" & valeur & "')"">" &
               "<span class=""lab""><i style=""background:" & point & """></i>" & Server.HtmlEncode(lab) & "</span>" &
               "<span class=""val"">" & Server.HtmlEncode(val) & "</span>" &
               "<span class=""sub"">" & Server.HtmlEncode(sub_) & "</span></button>"
    End Function

    Private Function Filtrer(dt As DataTable) As DataTable
        If dt Is Nothing OrElse FiltreCourant = "" Then Return dt
        Dim copie As DataTable = dt.Clone()
        For Each r As DataRow In dt.Rows
            If Garde(r, FiltreCourant) Then copie.ImportRow(r)
        Next
        Return copie
    End Function

    ''' <summary>Le rond de couleur, le nom en gras, puis « numéro · poste ».</summary>
    Public Function EmpCell(couleur As Object, nom As Object, numero As Object, poste As Object) As String
        Dim meta As String = Val_(numero)
        If Val_(poste) <> "" Then meta = If(meta = "", "", meta & " · ") & Val_(poste)
        Return "<span class=""emp-dot"" style=""background:" & Server.HtmlEncode(Val_(couleur)) & """></span><span>" &
               "<span class=""emp-name"">" & Server.HtmlEncode(Val_(nom)) & "</span><br />" &
               "<span class=""emp-meta"">" & Server.HtmlEncode(meta) & "</span></span>"
    End Function

    Public Function ExtCell(courriel As Object) As String
        Dim c As String = Val_(courriel)
        Return If(c = "", "—", Server.HtmlEncode(c))
    End Function

    ''' <summary>L'adresse @60sec.ca (ou « aucune »), et la clé quand le mot de passe est défini.</summary>
    Public Function BoiteCell(aBoite As Object, adresse As Object, motDePasse As Object) As String
        Dim ok As Boolean = Vrai(aBoite)
        Dim s As String = "<span class=""" & If(ok, "emp-mail", "emp-mail emp-none") & """>" & If(ok, Server.HtmlEncode(Val_(adresse)), Server.HtmlEncode(L("noBox"))) & "</span>"
        If Vrai(motDePasse) Then s &= "<span class=""pw-key"" title=""" & Server.HtmlEncode(L("pwdSet")) & """><i class='ic ic-key' aria-hidden='true'></i></span>"
        Return s
    End Function

    ''' <summary>Un point vert « Actif » ou gris « Inactif ».</summary>
    Public Function EtatCell(actif As Object) As String
        Dim ok As Boolean = Vrai(actif)
        Return "<span class=""fc-etat"" style=""color:" & If(ok, "#0F5A3A", "#5B6B86") & """><i class=""pt"" style=""background:" & If(ok, "#43B47A", "#AEBBCD") & """></i>" &
               Server.HtmlEncode(If(ok, L("stActive"), L("stInactive"))) & "</span>"
    End Function

    ' ---- Helpers ------------------------------------------------------------

    ' radalert leve « Cannot read properties of undefined (reading 'radalert') »
    ' quand il part d'un script de demarrage : voir clsData.ShowMessageBox.
    Private Sub Alert(msg As String)
        ShowMessageBox(msg, L("winTitle"))
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
            Case "add" : Return Choose3(lang, "+ Ajouter un employé", "+ Add an employee", "+ Agregar un empleado")
            Case "searchPh" : Return Choose3(lang, "Chercher un nom, un numéro ou un courriel", "Search a name, a number or an email", "Buscar un nombre, un número o un correo")
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
            Case "empty" : Return Choose3(lang, "Aucun employé ne correspond.", "No employee matches.", "Ningún empleado coincide.")
            Case "rubrique" : Return Choose3(lang, "Mon entreprise", "My business", "Mi empresa")
            Case "sousTitre" : Return Choose3(lang, "Vos employés, leur courriel et leur boîte @60sec.ca ; ce sont aussi les ressources de l'agenda.", "Your employees, their email and their @60sec.ca mailbox; they are also the agenda's resources.", "Sus empleados, su correo y su buzón @60sec.ca; también son los recursos de la agenda.")
            Case "kpiActifs" : Return Choose3(lang, "Employés actifs", "Active employees", "Empleados activos")
            Case "kpiActifsSub" : Return Choose3(lang, "dans l'agenda", "in the agenda", "en la agenda")
            Case "kpiInactifs" : Return Choose3(lang, "Inactifs", "Inactive", "Inactivos")
            Case "kpiInactifsSub" : Return Choose3(lang, "dossiers conservés", "records kept", "fichas conservadas")
            Case "kpiAvec" : Return Choose3(lang, "Avec boîte @60sec.ca", "With @60sec.ca mailbox", "Con buzón @60sec.ca")
            Case "kpiAvecSub" : Return Choose3(lang, "courriel personnel", "personal mailbox", "buzón personal")
            Case "kpiSans" : Return Choose3(lang, "Sans boîte", "Without mailbox", "Sin buzón")
            Case "kpiSansSub" : Return Choose3(lang, "actifs à équiper", "active, to equip", "activos por equipar")
            Case "noBox" : Return Choose3(lang, "aucune", "none", "ninguno")
            Case "pwdSet" : Return Choose3(lang, "Mot de passe défini", "Password set", "Contraseña definida")
            Case "pied" : Return Choose3(lang, "{0} sur {1} employés", "{0} of {1} employees", "{0} de {1} empleados")
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
