Imports System.Data
Imports System.Data.SqlClient
Imports System.Linq
Imports System.Text
Imports Telerik.Web.UI

Public Class wbfUsers
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        ' Vérifier que l'utilisateur est connecté ET admin
        ' (UserId est un entier : 0 = non authentifié)
        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If





        If Not isAdmin Then
            Response.Redirect("~/Default.aspx?err=admin_required")
            Return
        End If

        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        ApplyLocalization()

        If Not IsPostBack Then
            rlvUsers.Rebind()
        End If
    End Sub

    Private Sub rlvUsers_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvUsers.NeedDataSource
        ChargerIndicateurs()
        Dim dt As DataTable = Filtrer(GetData())
        rlvUsers.DataSource = dt
        SetLiteral(Me, "litPied", Server.HtmlEncode(String.Format(T("{0} sur {1} utilisateurs", "{0} of {1} users", "{0} de {1} usuarios"), If(dt Is Nothing, 0, dt.Rows.Count), TotalUtilisateurs)))
    End Sub

    Private Sub rlvUsers_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvUsers.ItemCommand
        Select Case e.CommandName
            Case "DeleteUser"
                Dim id As String = ""
                Integer.TryParse(e.CommandArgument.ToString(), id)
                If id > 0 Then
                    ' Empêcher de se supprimer soi-même
                    If UserId <> id Then
                        DeleteUser(id)
                        rlvUsers.Rebind()
                    Else
                        ' Suppression de son propre compte interdite : ne rien faire
                    End If
                End If
        End Select
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvUsers.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        FiltreCourant = ""
        rlvUsers.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If If(e.Argument, "").StartsWith("chip|") Then
            ChoisirIndicateur(e.Argument)
            Return
        End If
        If e.Argument = "refreshgrid" Then
            rlvUsers.Rebind()
        End If
    End Sub

    Private Function GetData() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Search", tbSearch.Text.Trim()))
        Dim ds As DataSet = ExecuteSQLds("s0202GetUsersList", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Sub DeleteUser(id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@ModifiedBy", If(Session("UserEmail"), "")))
        ExecuteSQL("s0205DeleteUser", p)
    End Sub

    ' =====================================================================
    ' La tête, les libellés (fr/en/es), les indicateurs (actifs / inactifs /
    ' administrateurs / connectés depuis 30 jours), le filtre en session et
    ' les cellules au style du gabarit « Portail du client ».
    ' =====================================================================

    Private Sub ApplyLocalization()
        SetLiteral(Me, "litRubrique", T("Administration", "Administration", "Administración"))
        SetLiteral(Me, "litTitre", T("Utilisateurs", "Users", "Usuarios"))
        SetLiteral(Me, "litSousTitre", T("Les personnes qui se connectent à votre entreprise, leur rôle et leur accès.", "The people who sign in to your company, their role and their access.", "Las personas que se conectan a su empresa, su rol y su acceso."))
        btnAddUser.Text = "+ " & T("Ajouter un utilisateur", "Add a user", "Agregar un usuario")
        tbSearch.Attributes("placeholder") = T("Chercher un nom ou un courriel", "Search a name or an email", "Buscar un nombre o un correo")
        btnClear.ToolTip = T("Effacer", "Clear", "Borrar")
        ' Le texte de confirmation passe par un Literal : pas de <%= %> dans une page à RadAjaxManager.
        SetLiteral(Me, "litDelConfirm", JsText(L("delConfirm")))
    End Sub

    Private Sub rlvUsers_PreRender(sender As Object, e As EventArgs) Handles rlvUsers.PreRender
        SetLiteral(rlvUsers, "litColNom", T("Nom", "Name", "Nombre"))
        SetLiteral(rlvUsers, "litColCourriel", T("Courriel", "Email", "Correo"))
        SetLiteral(rlvUsers, "litColRole", T("Rôle", "Role", "Rol"))
        SetLiteral(rlvUsers, "litColStatut", T("Statut", "Status", "Estado"))
        SetLiteral(rlvUsers, "litColConn", T("Dernière conn.", "Last sign-in", "Última conexión"))
        SetLiteral(rlvUsers, "litColActions", T("Actions", "Actions", "Acciones"))
        SetLiteral(rlvUsers, "litEmpty", T("Aucun utilisateur ne correspond.", "No user matches.", "Ningún usuario coincide."))
    End Sub

    ''' <summary>Sélecteur de langue simple (fr/en/es) pour les libellés de la page.</summary>
    Protected Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Protected Function L(key As String) As String
        Select Case key
            Case "delConfirm" : Return T("Supprimer cet utilisateur ?", "Delete this user?", "¿Eliminar este usuario?")
            Case Else : Return ""
        End Select
    End Function

    Protected Shared Function JsText(s As String) As String
        Return If(s, "").Replace("\", "\\").Replace("""", "\""")
    End Function

    Private Property FiltreCourant As String
        Get
            Return If(TryCast(Session("Users.Filtre"), String), "")
        End Get
        Set(value As String)
            Session("Users.Filtre") = value
        End Set
    End Property

    Private TotalUtilisateurs As Integer

    ''' <summary>Un indicateur cliqué (« chip|kpi|valeur ») : un second clic l'enlève.</summary>
    Private Sub ChoisirIndicateur(arg As String)
        Dim parts As String() = If(arg, "").Split("|"c)
        Dim valeur As String = If(parts.Length >= 3, parts(2), "").Trim().ToLowerInvariant()
        If valeur <> "actifs" AndAlso valeur <> "inactifs" AndAlso valeur <> "admins" AndAlso valeur <> "recents" Then Return
        FiltreCourant = If(FiltreCourant = valeur, "", valeur)
        rlvUsers.Rebind()
    End Sub

    Private Shared Function Vrai(o As Object) As Boolean
        If o Is Nothing OrElse IsDBNull(o) Then Return False
        Try
            Return Convert.ToBoolean(o)
        Catch
            Return False
        End Try
    End Function

    Private Shared Function Recent(o As Object) As Boolean
        If o Is Nothing OrElse IsDBNull(o) Then Return False
        Dim d As DateTime
        Return DateTime.TryParse(o.ToString(), d) AndAlso d >= Date.Today.AddDays(-30)
    End Function

    Private Function Garde(r As DataRow, cle As String) As Boolean
        Select Case cle
            Case "actifs" : Return Vrai(r("IsActive"))
            Case "inactifs" : Return Not Vrai(r("IsActive"))
            Case "admins" : Return Vrai(r("IsAdmin"))
            Case "recents" : Return Recent(r("LastLoginOn"))
            Case Else : Return True
        End Select
    End Function

    Private Function LireTout() As List(Of DataRow)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Search", ""))
            Dim ds As DataSet = ExecuteSQLds("s0202GetUsersList", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0).Rows.Cast(Of DataRow)().ToList()
        Catch
        End Try
        Return New List(Of DataRow)
    End Function

    Private Sub ChargerIndicateurs()
        Dim rows As List(Of DataRow) = LireTout()
        TotalUtilisateurs = rows.Count
        Dim actifs As Integer = rows.Where(Function(r) Garde(r, "actifs")).Count()
        Dim admins As Integer = rows.Where(Function(r) Garde(r, "admins")).Count()
        Dim recents As Integer = rows.Where(Function(r) Garde(r, "recents")).Count()
        Dim sb As New StringBuilder()
        sb.Append(Kpi("actifs", T("Utilisateurs actifs", "Active users", "Usuarios activos"), actifs & " / " & rows.Count, T("peuvent se connecter", "can sign in", "pueden conectarse"), "#43B47A"))
        sb.Append(Kpi("inactifs", T("Inactifs", "Inactive", "Inactivos"), (rows.Count - actifs).ToString(), T("accès suspendu", "access suspended", "acceso suspendido"), "#AEBBCD"))
        sb.Append(Kpi("admins", T("Administrateurs", "Administrators", "Administradores"), admins.ToString(), T("gèrent la compagnie", "manage the company", "gestionan la compañía"), "#1B4F9C"))
        sb.Append(Kpi("recents", T("Connectés (30 jours)", "Signed in (30 days)", "Conectados (30 días)"), recents.ToString(), T("au moins une connexion", "at least one sign-in", "al menos una conexión"), "#E3B341"))
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

    ''' <summary>Le nom en gras (le courriel à défaut), l'identifiant dessous.</summary>
    Public Function NomCell(nom As Object, courriel As Object, id As Object) As String
        Dim n As String = Convert.ToString(nom).Trim()
        If n = "" Then n = Convert.ToString(courriel)
        Return "<b>" & Server.HtmlEncode(n) & "</b><span>ID: " & Server.HtmlEncode(Convert.ToString(id)) & "</span>"
    End Function

    Public Function RolePill(estAdmin As Object) As String
        If Vrai(estAdmin) Then Return "<span class=""fc-pay"" style=""background:#E3EBF7;color:#143A73"">" & Server.HtmlEncode(T("Admin", "Admin", "Admin")) & "</span>"
        Return "<span class=""fc-pay"" style=""background:#F2F5F9;color:#5B6B86"">" & Server.HtmlEncode(T("Utilisateur", "User", "Usuario")) & "</span>"
    End Function

    ''' <summary>Un point vert « Actif » ou gris « Inactif ».</summary>
    Public Function EtatCell(actif As Object) As String
        Dim ok As Boolean = Vrai(actif)
        Return "<span class=""fc-etat"" style=""color:" & If(ok, "#0F5A3A", "#5B6B86") & """><i class=""pt"" style=""background:" & If(ok, "#43B47A", "#AEBBCD") & """></i>" &
               Server.HtmlEncode(If(ok, T("Actif", "Active", "Activo"), T("Inactif", "Inactive", "Inactivo"))) & "</span>"
    End Function

    Public Function DateCell(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return "—"
        Return CDate(o).ToString("yyyy-MM-dd HH:mm")
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

    ''' <summary>
    ''' Génère les initiales pour l'avatar.
    ''' Utilisé depuis le markup avec Eval.
    ''' </summary>
    Public Function GetInitials(firstName As Object, lastName As Object, email As Object) As String
        Dim fn As String = If(firstName Is Nothing OrElse firstName Is DBNull.Value, "", firstName.ToString().Trim())
        Dim ln As String = If(lastName Is Nothing OrElse lastName Is DBNull.Value, "", lastName.ToString().Trim())

        If fn.Length > 0 AndAlso ln.Length > 0 Then
            Return (fn.Substring(0, 1) & ln.Substring(0, 1)).ToUpper()
        ElseIf fn.Length > 0 Then
            Return fn.Substring(0, 1).ToUpper()
        End If

        Dim em As String = If(email Is Nothing OrElse email Is DBNull.Value, "?", email.ToString())
        If em.Length > 0 Then Return em.Substring(0, 1).ToUpper()
        Return "?"
    End Function

End Class
