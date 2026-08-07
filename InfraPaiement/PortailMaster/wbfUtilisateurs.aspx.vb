Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Liste des utilisateurs du portail (staff plateforme).
''' Réservée aux super-administrateurs.
''' </summary>
Public Class wbfUtilisateurs
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Le master redirige les non-authentifiés ; ici on restreint aux super-admins.
        If Not IsAuthenticated Then Return
        If Not AdminIsSuperAdmin Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        If Not IsPostBack Then BindList()
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        BindList()
    End Sub

    Private Sub BindList()
        Try
            Dim p As New Collection
            Dim s As String = If(tbSearch.Text, "").Trim()
            p.Add(New SqlParameter("@Search", If(s.Length = 0, CObj(DBNull.Value), s)))

            Dim tbl As DataTable = ExecuteSQLds("s0008ListAdmins", p).Tables(0)
            rptUsers.DataSource = tbl
            rptUsers.DataBind()

            Dim n As Integer = tbl.Rows.Count
            rptUsers.Visible = (n > 0)
            pnlEmpty.Visible = (n = 0)
            litCount.Text = n & If(n = 1, " utilisateur", " utilisateurs")
        Catch ex As Exception
            pnlError.Visible = True
            litError.Text = "Impossible de charger la liste des utilisateurs. Vérifiez que les scripts de base de données ont été exécutés."
            System.Diagnostics.Debug.WriteLine("BindList users: " & ex.Message)
            rptUsers.Visible = False
            pnlEmpty.Visible = False
        End Try
    End Sub

    ' --- Helpers d'affichage ---

    Protected Function NomComplet(prenom As Object, nom As Object) As String
        Dim p As String = If(prenom Is Nothing OrElse IsDBNull(prenom), "", prenom.ToString())
        Dim n As String = If(nom Is Nothing OrElse IsDBNull(nom), "", nom.ToString())
        Dim full As String = (p & " " & n).Trim()
        Return If(full.Length = 0, "(sans nom)", full)
    End Function

    Protected Function BadgeRole(isSuper As Object) As String
        Return If(ToBool(isSuper), "badge-super", "badge-role")
    End Function

    Protected Function LabelRole(isSuper As Object) As String
        Return If(ToBool(isSuper), "Super-admin", "Administrateur")
    End Function

    Protected Function BadgeActif(isActive As Object) As String
        Return If(ToBool(isActive), "badge-actif", "badge-inactif")
    End Function

    Protected Function LabelActif(isActive As Object) As String
        Return If(ToBool(isActive), "Actif", "Inactif")
    End Function

    Protected Function FormatDate(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return CDate(d).ToString("yyyy-MM-dd")
    End Function

    Protected Function FormatDateTime2(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return "—"
        Return CDate(d).ToString("yyyy-MM-dd HH:mm")
    End Function

    Private Function ToBool(o As Object) As Boolean
        If o Is Nothing OrElse IsDBNull(o) Then Return False
        Return CBool(o)
    End Function

End Class
