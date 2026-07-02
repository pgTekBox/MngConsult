Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net

Public Class wbfResetPassword
    Inherits clsData

    Private ReadOnly Property TokenString() As String
        Get
            Return If(ViewState("rpToken"), "").ToString()
        End Get
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Dim token As String = If(Request.QueryString("token"), "").Trim()
            Dim g As Guid
            If Not Guid.TryParse(token, g) OrElse Not IsTokenValid(g) Then
                pnlForm.Visible = False
                ShowMsg("Ce lien de réinitialisation est invalide ou a expiré.", True)
                Return
            End If
            ViewState("rpToken") = g.ToString()
        End If
    End Sub

    Private Function IsTokenValid(token As Guid) As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Token", token))
            Dim ds As DataSet = ExecuteSQLds("s0651GetAdminByResetToken", p)
            Return ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0
        Catch
            Return False
        End Try
    End Function

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click

        Dim g As Guid
        If Not Guid.TryParse(TokenString, g) Then
            pnlForm.Visible = False
            ShowMsg("Ce lien de réinitialisation est invalide ou a expiré.", True)
            Return
        End If

        Dim password As String = txtPassword.Text
        Dim confirm As String = txtPasswordConfirm.Text

        If password.Length < 8 Then
            ShowMsg("Le mot de passe doit contenir au moins 8 caractères.", True) : Return
        End If
        If password <> confirm Then
            ShowMsg("Les mots de passe ne correspondent pas.", True) : Return
        End If

        Try
            Dim hash As String = BCrypt.Net.BCrypt.HashPassword(password, 11)
            Dim p As New Collection
            p.Add(New SqlParameter("@Token", g))
            p.Add(New SqlParameter("@PasswordHash", hash))
            Dim ds As DataSet = ExecuteSQLds("s0652ResetAdminPasswordByToken", p)

            Dim affected As Integer = 0
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Integer.TryParse(ds.Tables(0).Rows(0)("Affected").ToString(), affected)
            End If

            If affected > 0 Then
                pnlForm.Visible = False
                ShowMsg("Votre mot de passe a été réinitialisé. Vous pouvez maintenant vous connecter.", False)
            Else
                pnlForm.Visible = False
                ShowMsg("Ce lien de réinitialisation est invalide ou a expiré.", True)
            End If

        Catch ex As Exception
            ShowMsg("Erreur : " & ex.Message, True)
        End Try
    End Sub

    Private Sub ShowMsg(text As String, isError As Boolean)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = "msg " & If(isError, "", "ok")
    End Sub

End Class
