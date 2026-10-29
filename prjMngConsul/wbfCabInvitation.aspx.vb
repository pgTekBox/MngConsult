Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net

''' <summary>
''' Acceptation d'une invitation de membre de cabinet (Portail comptable).
''' Page publique (hors auth) atteinte par le lien ?token=GUID du courriel
''' d'invitation. Le membre pose son mot de passe → compte activé (s0926), puis
''' redirection vers la connexion. Jeton lu via s0925GetMembreByInviteToken.
''' </summary>
Public Class wbfCabInvitation
    Inherits clsData

    Protected WithEvents pnlForm As System.Web.UI.WebControls.Panel
    Protected WithEvents litTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblEmail As System.Web.UI.WebControls.Literal
    Protected WithEvents litEmail As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblPwd As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblPwd2 As System.Web.UI.WebControls.Literal
    Protected WithEvents txtPwd As System.Web.UI.WebControls.TextBox
    Protected WithEvents txtPwd2 As System.Web.UI.WebControls.TextBox
    Protected WithEvents btnActivate As System.Web.UI.WebControls.Button
    Protected WithEvents litMsg As System.Web.UI.WebControls.Literal
    Protected WithEvents litFoot As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Textes()
        If Not IsPostBack Then LireInvitation()
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Sub Textes()
        litLblEmail.Text = Server.HtmlEncode(T("Courriel", "Email", "Correo"))
        litLblPwd.Text = Server.HtmlEncode(T("Mot de passe", "Password", "Contraseña"))
        litLblPwd2.Text = Server.HtmlEncode(T("Confirmer le mot de passe", "Confirm password", "Confirmar contraseña"))
        btnActivate.Text = T("Activer mon compte", "Activate my account", "Activar mi cuenta")
        litFoot.Text = "&copy; 2026 60Sec-AI"
    End Sub

    Private Function Jeton() As Guid?
        Dim g As Guid
        If Guid.TryParse(If(Request.QueryString("token"), ""), g) Then Return g
        Return Nothing
    End Function

    Private Sub LireInvitation()
        Dim tok As Guid? = Jeton()
        If tok Is Nothing Then
            Invalide()
            Return
        End If

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Token", tok.Value))
            Dim ds As DataSet = ExecuteSQLds("s0925GetMembreByInviteToken", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                Invalide()
                Return
            End If
            Dim r As DataRow = ds.Tables(0).Rows(0)
            Dim cab As String = Convert.ToString(r("CabinetNom"))
            litTitre.Text = Server.HtmlEncode(T("Rejoignez votre cabinet", "Join your firm", "Únase a su despacho"))
            litSous.Text = Server.HtmlEncode(
                If(String.IsNullOrEmpty(cab),
                   T("Choisissez un mot de passe pour activer votre compte.", "Choose a password to activate your account.", "Elija una contraseña para activar su cuenta."),
                   T("Vous rejoignez ", "You are joining ", "Se une a ") & cab & T(". Choisissez un mot de passe.", ". Choose a password.", ". Elija una contraseña.")))
            litEmail.Text = Server.HtmlEncode(Convert.ToString(r("Email")))
        Catch
            Invalide()
        End Try
    End Sub

    Private Sub Invalide()
        pnlForm.Visible = False
        litMsg.Text = "<div class=""msg err"">" & Server.HtmlEncode(
            T("Cette invitation est invalide ou expirée. Demandez à votre cabinet de vous la renvoyer.",
              "This invitation is invalid or expired. Ask your firm to resend it.",
              "Esta invitación no es válida o ha expirado. Pida a su despacho que la reenvíe.")) & "</div>"
    End Sub

    Private Sub btnActivate_Click(sender As Object, e As EventArgs) Handles btnActivate.Click
        Dim tok As Guid? = Jeton()
        If tok Is Nothing Then
            Invalide()
            Return
        End If

        Dim pwd As String = txtPwd.Text
        Dim pwd2 As String = txtPwd2.Text
        If String.IsNullOrEmpty(pwd) OrElse pwd.Length < 8 Then
            Erreur(T("Le mot de passe doit faire au moins 8 caractères.", "The password must be at least 8 characters.", "La contraseña debe tener al menos 8 caracteres."))
            Return
        End If
        If pwd <> pwd2 Then
            Erreur(T("Les deux mots de passe ne correspondent pas.", "The two passwords do not match.", "Las dos contraseñas no coinciden."))
            Return
        End If

        Try
            Dim hash As String = BCrypt.Net.BCrypt.HashPassword(pwd, 11)

            Dim p As New Collection
            p.Add(New SqlParameter("@Token", tok.Value))
            p.Add(New SqlParameter("@PasswordHash", hash))
            p.Add(New SqlParameter("@FirstName", DBNull.Value))
            p.Add(New SqlParameter("@LastName", DBNull.Value))
            Dim outRes As New SqlParameter("@Result", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
            Dim outUid As New SqlParameter("@UserId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
            Dim outMail As New SqlParameter("@Email", SqlDbType.NVarChar, 200) With {.Direction = ParameterDirection.Output}
            p.Add(outRes) : p.Add(outUid) : p.Add(outMail)
            ExecuteSQL("s0926AcceptInvitation", p)

            Dim res As Integer = If(outRes.Value Is Nothing OrElse IsDBNull(outRes.Value), 0, CInt(outRes.Value))
            Select Case res
                Case 1
                    Response.Redirect("~/wbfLogin.aspx?invited=1")
                Case -1
                    Invalide()
                Case -2
                    pnlForm.Visible = False
                    litMsg.Text = "<div class=""msg ok"">" & Server.HtmlEncode(
                        T("Ce compte est déjà activé. Vous pouvez vous connecter.", "This account is already active. You can sign in.", "Esta cuenta ya está activa. Puede iniciar sesión.")) &
                        " <a href=""" & ResolveUrl("~/wbfLogin.aspx") & """>" & Server.HtmlEncode(T("Se connecter", "Sign in", "Iniciar sesión")) & "</a></div>"
                Case Else
                    Invalide()
            End Select
        Catch
            Erreur(T("Une erreur est survenue. Réessayez.", "An error occurred. Please try again.", "Se produjo un error. Inténtelo de nuevo."))
        End Try
    End Sub

    Private Sub Erreur(txt As String)
        litMsg.Text = "<div class=""msg err"">" & Server.HtmlEncode(txt) & "</div>"
    End Sub

End Class
