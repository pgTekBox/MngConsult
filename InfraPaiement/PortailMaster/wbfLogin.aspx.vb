Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net

''' <summary>
''' Page de connexion au Portail Maître.
''' Authentifie un administrateur de la plateforme (table T001PortalAdmin)
''' par courriel + mot de passe BCrypt, avec verrouillage temporaire apres
''' plusieurs echecs.
''' </summary>
Public Class wbfLogin
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Deja connecte : aller au tableau de bord.
        If Not IsPostBack AndAlso IsAuthenticated Then
            Response.Redirect("~/Default.aspx")
        End If
    End Sub

    Protected Sub btnLogin_Click(sender As Object, e As EventArgs)

        Dim email As String = If(tbEmail.Text, "").Trim().ToLowerInvariant()
        Dim password As String = If(tbPassword.Text, "")

        If String.IsNullOrEmpty(email) OrElse String.IsNullOrEmpty(password) Then
            ShowError("Veuillez entrer votre courriel et votre mot de passe.")
            Return
        End If

        Dim admin As DataRow = GetAdminByEmail(email)

        ' Message identique quel que soit le motif (ne pas divulguer si le
        ' compte existe).
        Dim genericErr As String = "Courriel ou mot de passe incorrect."

        If admin Is Nothing Then
            AuditLogin("LoginFailed", 0, email, "compte introuvable")
            ShowError(genericErr)
            Return
        End If

        Dim aId As Integer = CInt(admin("Id"))

        ' Compte verrouille ?
        If Not IsDBNull(admin("LockoutUntilUtc")) Then
            Dim until As DateTime = CDate(admin("LockoutUntilUtc"))
            If until > DateTime.UtcNow Then
                AuditLogin("LoginFailed", aId, email, "compte verrouillé")
                ShowError("Compte temporairement verrouillé après plusieurs tentatives. Réessayez dans quelques minutes.")
                Return
            End If
        End If

        ' Verifier le mot de passe (BCrypt).
        Dim isValid As Boolean = False
        Try
            isValid = BCrypt.Net.BCrypt.Verify(password, admin("PasswordHash").ToString())
        Catch
            isValid = False
        End Try

        If Not isValid Then
            RegisterFailedLogin(aId)
            AuditLogin("LoginFailed", aId, email, "mot de passe invalide")
            ShowError(genericErr)
            Return
        End If

        ' Compte actif ?
        If Not CBool(admin("IsActive")) Then
            AuditLogin("LoginFailed", aId, email, "compte désactivé")
            ShowError("Ce compte est désactivé. Contactez un administrateur.")
            Return
        End If

        ' === Connexion reussie ===
        AdminId = CInt(admin("Id"))
        AdminEmail = admin("Email").ToString()
        AdminName = (If(IsDBNull(admin("FirstName")), "", admin("FirstName").ToString()) & " " &
                     If(IsDBNull(admin("LastName")), "", admin("LastName").ToString())).Trim()
        AdminIsSuperAdmin = Not IsDBNull(admin("IsSuperAdmin")) AndAlso CBool(admin("IsSuperAdmin"))

        UpdateLastLogin(AdminId)
        AuditLogin("Login", AdminId, AdminEmail, Nothing)

        Dim returnUrl As String = Request.QueryString("ReturnUrl")
        If Not String.IsNullOrEmpty(returnUrl) AndAlso returnUrl.StartsWith("/") Then
            Response.Redirect(returnUrl)
        Else
            Response.Redirect("~/Default.aspx")
        End If
    End Sub

    ' -----------------------------------------------------------------
    ' Acces BD (procedures stockees)
    ' -----------------------------------------------------------------

    Private Function GetAdminByEmail(email As String) As DataRow
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Email", email))
            Dim ds As DataSet = ExecuteSQLds("s0001GetAdminByEmail", p)
            If ds.Tables(0).Rows.Count > 0 Then Return ds.Tables(0).Rows(0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Login error: " & ex.Message)
        End Try
        Return Nothing
    End Function

    Private Sub UpdateLastLogin(adminId As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", adminId))
            ExecuteSQL("s0002UpdateAdminLastLogin", p)
        Catch
            ' Non-bloquant.
        End Try
    End Sub

    Private Sub RegisterFailedLogin(adminId As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", adminId))
            ExecuteSQL("s0003RegisterFailedLogin", p)
        Catch
            ' Non-bloquant.
        End Try
    End Sub

    ''' <summary>Journalise un évènement de connexion (succès ou échec) au
    ''' journal d'audit. actorAdminId=0 si le compte est inconnu.</summary>
    Private Sub AuditLogin(action As String, adminId As Integer, email As String, details As String)
        clsAudit.Write(adminId, email, action, "PortalAdmin", adminId, email, details, Request.UserHostAddress)
    End Sub

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

End Class
