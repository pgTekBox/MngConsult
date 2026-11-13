Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

''' <summary>
''' Rôles du cabinet (Portail comptable, script T382). Chaque rôle a un nom, une
''' description et un niveau d'accès (admin / employe / technicien) recopié sur
''' les membres qui le portent. Les rôles de base (Administrateur, Comptable,
''' Technicien) ne se suppriment pas ; un rôle utilisé par un membre non plus.
'''   - admin / solo : ajouter, modifier, supprimer ;
'''   - employé : lecture.
''' Procs : s1003 (liste), s1004 (enregistrer), s1005 (supprimer).
''' </summary>
Public Class wbfCabRoles
    Inherits clsData

    Protected WithEvents litData As System.Web.UI.WebControls.Literal
    Protected WithEvents litLabels As System.Web.UI.WebControls.Literal

    Private _role As String = ""

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        _role = RoleCabinet()
        If _role <> "admin" AndAlso _role <> "solo" AndAlso _role <> "employe" Then
            Response.Redirect("~/wbfCabJournee.aspx") : Return
        End If
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        If String.Equals(Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase) Then
            Dim op As String = Convert.ToString(Request.Form("op"))
            If op <> "" Then
                Traiter(op) : Return
            End If
        End If

        If Not IsPostBack Then
            litData.Text = Json(Charger())
            litLabels.Text = Json(Libelles())
        End If
    End Sub

    Private ReadOnly Property PeutGerer As Boolean
        Get
            Return _role = "admin" OrElse _role = "solo"
        End Get
    End Property

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

    Private Shared Function Json(o As Object) As String
        Return New JavaScriptSerializer() With {.MaxJsonLength = Integer.MaxValue}.Serialize(o)
    End Function

    Private Shared Function Txt(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return Convert.ToString(o).Trim()
    End Function

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Function Charger() As Object
        Dim roles As New List(Of Object)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s1003ListRolesCabinet", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    roles.Add(New With {
                        .id = CInt(r("Id")),
                        .nom = Txt(r("Nom")),
                        .description = Txt(r("Description")),
                        .acces = Txt(r("Acces")),
                        .systeme = CBool(r("IsSysteme")),
                        .nb = CInt(r("NbMembres")),
                        .membres = Txt(r("Membres"))})
                Next
            End If
        Catch
        End Try
        Return New With {.gerer = PeutGerer, .roles = roles}
    End Function

    Private Sub Traiter(op As String)
        Dim res As Object
        Try
            If Not PeutGerer Then
                res = New With {.ok = False, .erreur = T("Réservé aux administrateurs du cabinet.", "Reserved to the firm's administrators.", "Reservado a los administradores del despacho.")}
            Else
                Select Case op
                    Case "save" : res = Enregistrer()
                    Case "delete" : res = Supprimer(CInt(Val(Request.Form("id"))))
                    Case Else : res = New With {.ok = False, .erreur = "op"}
                End Select
            End If
        Catch ex As Exception
            res = New With {.ok = False, .erreur = ex.Message}
        End Try
        Response.Clear()
        Response.ContentType = "application/json"
        Response.Write(Json(res))
        Response.End()
    End Sub

    Private Function MessageErreur(err As Integer) As String
        Select Case err
            Case 1 : Return T("Un rôle porte déjà ce nom.", "A role already has this name.", "Ya existe un rol con este nombre.")
            Case 3 : Return T("Le cabinet doit garder au moins un administrateur.", "The firm must keep at least one administrator.", "El despacho debe conservar al menos un administrador.")
            Case 5 : Return T("Rôle introuvable.", "Role not found.", "Rol no encontrado.")
            Case 8 : Return T("Ce rôle est utilisé par au moins un membre : il ne peut pas être supprimé.", "This role is used by at least one member: it cannot be deleted.", "Este rol lo usa al menos un miembro: no se puede eliminar.")
            Case 9 : Return T("Un rôle de base ne peut pas être supprimé.", "A base role cannot be deleted.", "Un rol base no se puede eliminar.")
            Case 11 : Return T("Le nom du rôle est requis.", "The role name is required.", "El nombre del rol es obligatorio.")
            Case Else : Return T("L'opération n'a pas pu être faite.", "The operation could not be completed.", "No se pudo realizar la operación.")
        End Select
    End Function

    Private Function Enregistrer() As Object
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@RoleId", CInt(Val(Request.Form("id")))))
        p.Add(New SqlParameter("@Nom", Txt(Request.Form("nom"))))
        p.Add(New SqlParameter("@Description", Txt(Request.Form("description"))))
        p.Add(New SqlParameter("@Acces", Txt(Request.Form("acces"))))
        Dim outId As New SqlParameter("@NewId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outId) : p.Add(outErr)
        ExecuteSQL("s1004SaveRoleCabinet", p)
        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        Return New With {.ok = (err = 0), .erreur = If(err = 0, "", MessageErreur(err))}
    End Function

    Private Function Supprimer(id As Integer) As Object
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@RoleId", id))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s1005DeleteRoleCabinet", p)
        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        Return New With {.ok = (err = 0), .erreur = If(err = 0, "", MessageErreur(err))}
    End Function

    Private Function Libelles() As Object
        Return New With {
            .titre = T("Rôles", "Roles", "Roles"),
            .sous = If(PeutGerer,
                       T("Les rôles des membres du cabinet. Chaque rôle a un niveau d'accès qui décide des dossiers que voit le membre. Un rôle utilisé ne peut pas être supprimé.",
                         "The roles of the firm's members. Each role has an access level that decides which files the member sees. A role in use cannot be deleted.",
                         "Los roles de los miembros del despacho. Cada rol tiene un nivel de acceso que decide qué expedientes ve el miembro. Un rol en uso no se puede eliminar."),
                       T("Les rôles des membres du cabinet, en lecture.", "The roles of the firm's members, read-only.", "Los roles de los miembros del despacho, en lectura.")),
            .nouveau = T("Nouveau rôle", "New role", "Nuevo rol"),
            .nom = T("Nom du rôle", "Role name", "Nombre del rol"),
            .description = T("Description", "Description", "Descripción"),
            .acces = T("Niveau d'accès", "Access level", "Nivel de acceso"),
            .aAdmin = T("Administrateur — gère le cabinet, voit tous les dossiers", "Administrator — manages the firm, sees all files", "Administrador — gestiona el despacho, ve todos los expedientes"),
            .aEmploye = T("Comptable — ses dossiers et ceux des techniciens qu'il supervise", "Accountant — their files and those of the technicians they supervise", "Contador — sus expedientes y los de los técnicos que supervisa"),
            .aTech = T("Technicien — seulement les dossiers confiés, sous un superviseur", "Technician — only assigned files, under a supervisor", "Técnico — solo los expedientes confiados, bajo un supervisor"),
            .aAdminC = T("Administrateur", "Administrator", "Administrador"),
            .aEmployeC = T("Comptable", "Accountant", "Contador"),
            .aTechC = T("Technicien", "Technician", "Técnico"),
            .base = T("Rôle de base", "Base role", "Rol base"),
            .baseAide = T("Rôle de base : son niveau d'accès ne change pas et il ne peut pas être supprimé.", "Base role: its access level does not change and it cannot be deleted.", "Rol base: su nivel de acceso no cambia y no se puede eliminar."),
            .membres = T("Membres", "Members", "Miembros"),
            .aucun = T("Aucun membre", "No member", "Ningún miembro"),
            .modifier = T("Modifier", "Edit", "Modificar"),
            .supprimer = T("Supprimer", "Delete", "Eliminar"),
            .utilise = T("Utilisé par {0} membre(s) : impossible de le supprimer", "Used by {0} member(s): cannot be deleted", "Usado por {0} miembro(s): no se puede eliminar"),
            .confSupprimer = T("Supprimer le rôle « {0} » ?", "Delete the role ""{0}""?", "¿Eliminar el rol «{0}»?"),
            .titreNouveau = T("Nouveau rôle", "New role", "Nuevo rol"),
            .titreModifier = T("Modifier le rôle « {0} »", "Edit the role ""{0}""", "Modificar el rol «{0}»"),
            .accesAide = T("Changer le niveau d'un rôle utilisé change l'accès de tous ses membres.", "Changing the level of a role in use changes the access of all its members.", "Cambiar el nivel de un rol en uso cambia el acceso de todos sus miembros."),
            .enregistrer = T("Enregistrer", "Save", "Guardar"),
            .fermer = T("Fermer", "Close", "Cerrar"),
            .vide = T("Aucun rôle.", "No role.", "Ningún rol."),
            .erreur = T("Une erreur est survenue.", "An error occurred.", "Se produjo un error.")
        }
    End Function
End Class
