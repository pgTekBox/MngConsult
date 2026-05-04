Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net

Public Class wbfLogin
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Si déjà connecté, rediriger vers la page d'accueil
        If Not IsPostBack AndAlso Not String.IsNullOrEmpty(UserId) Then
            Response.Redirect("~/Default.aspx")
        End If
    End Sub

    Protected Sub btnLogin_Click(sender As Object, e As EventArgs) Handles btnLogin.Click

        Dim email As String = If(tbEmail.Text, "").Trim().ToLower()
        Dim password As String = If(tbPassword.Text, "")

        ' Validation basique
        If String.IsNullOrEmpty(email) OrElse String.IsNullOrEmpty(password) Then
            ShowError("Veuillez entrer votre courriel et votre mot de passe.")
            Return
        End If

        ' Récupérer l'utilisateur
        Dim userRow As DataRow = GetUserByEmail(email)
        If userRow Is Nothing Then
            ShowError("Courriel ou mot de passe incorrect.")
            Return
        End If

        ' Vérifier qu'il est actif
        If Not CBool(userRow("IsActive")) Then
            ShowError("Ce compte est désactivé. Contactez votre administrateur.")
            Return
        End If

        ' Vérifier le mot de passe avec bcrypt
        Dim hash As String = userRow("PasswordHash").ToString()
        Dim isValid As Boolean = False
        Try
            isValid = BCrypt.Net.BCrypt.Verify(password, hash)
        Catch
            isValid = False
        End Try

        If Not isValid Then
            ShowError("Courriel ou mot de passe incorrect.")

            Return
        End If

        ' === Login OK ===

        Company = CType(userRow("CompanyGUID"), Guid)
        UserId = userRow("Email").ToString()


        ' Mettre à jour la dernière connexion
        UpdateLastLogin(userId)

        ' Redirection
        Dim returnUrl As String = Request.QueryString("ReturnUrl")
        If Not String.IsNullOrEmpty(returnUrl) AndAlso returnUrl.StartsWith("/") Then
            Response.Redirect(returnUrl)
        Else
            Response.Redirect("~/Default.aspx")
        End If
    End Sub

    Private Function GetUserByEmail(email As String) As DataRow
        Try


            Dim p As New Collection
            p.Add(New SqlParameter("@Email", email))


            Dim ds As DataSet = ExecuteSQLds("s0200GetUserByEmail", p)
            If ds.Tables(0).Rows.Count > 0 Then Return ds.Tables(0).Rows(0)


        Catch ex As Exception
            ' Ne pas révéler les détails au user
            System.Diagnostics.Debug.WriteLine("Login error: " & ex.Message)
        End Try
        Return Nothing
    End Function

    Private Sub UpdateLastLogin(userId As String)
        Try

            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", userId))


            ExecuteSQL("s0201UpdateLastLogin", p)

        Catch
            ' Non-bloquant
        End Try
    End Sub

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

End Class
