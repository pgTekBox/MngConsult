Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net
Imports Telerik.Web.UI

Public Class wbfUserEdit
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        ' Vérification : connecté + admin
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If
        If Not isAdmin Then
            Response.Redirect("~/Default.aspx?err=admin_required")
            Return
        End If

        If Not IsPostBack Then
            Dim id As Integer = 0
            Integer.TryParse(Request.QueryString("id"), id)
            hfId.Value = id.ToString()

            If id > 0 Then
                LoadUser(id)
                litTitle.Text = "Modifier un utilisateur"
                btnDelete.Visible = True

                ' En édition, le mot de passe est optionnel
                litPasswordLabel.Text = "Nouveau mot de passe"
                litPasswordHint.Text = "Laissez vide pour conserver le mot de passe actuel. Minimum 8 caractères si modifié."
            Else
                litTitle.Text = "Nouvel utilisateur"
            End If
        End If
    End Sub

    Private Sub LoadUser(id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Id", id))

        Dim ds As DataSet = ExecuteSQLds("s0203GetUserById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ShowMsg("Utilisateur introuvable.", isError:=True)
            Return
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        txtEmail.Text = If(r("Email") Is DBNull.Value, "", r("Email").ToString())
        txtFirstName.Text = If(r("FirstName") Is DBNull.Value, "", r("FirstName").ToString())
        txtLastName.Text = If(r("LastName") Is DBNull.Value, "", r("LastName").ToString())
        cbAdmin.Checked = (Not r("IsAdmin") Is DBNull.Value) AndAlso CBool(r("IsAdmin"))
        cbActive.Checked = (Not r("IsActive") Is DBNull.Value) AndAlso CBool(r("IsActive"))
    End Sub

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click

        Dim id As Integer = 0
        Integer.TryParse(hfId.Value, id)
        Dim isCreate As Boolean = (id = 0)

        ' === Validations ===
        Dim email As String = txtEmail.Text.Trim().ToLower()
        If String.IsNullOrEmpty(email) Then
            ShowMsg("Le courriel est obligatoire.", isError:=True)
            Return
        End If
        If Not email.Contains("@") OrElse Not email.Contains(".") Then
            ShowMsg("Le courriel n'est pas valide.", isError:=True)
            Return
        End If

        Dim password As String = txtPassword.Text
        Dim passwordConfirm As String = txtPasswordConfirm.Text
        Dim passwordHash As Object = DBNull.Value

        ' Création : mot de passe obligatoire
        ' Édition : optionnel — laissé vide = on garde l'ancien
        Dim passwordChanged As Boolean = Not String.IsNullOrEmpty(password)

        If isCreate AndAlso Not passwordChanged Then
            ShowMsg("Le mot de passe est obligatoire à la création.", isError:=True)
            Return
        End If

        If passwordChanged Then
            If password.Length < 8 Then
                ShowMsg("Le mot de passe doit contenir au moins 8 caractères.", isError:=True)
                Return
            End If
            If password <> passwordConfirm Then
                ShowMsg("Les mots de passe ne correspondent pas.", isError:=True)
                Return
            End If

            ' Hash bcrypt (work factor 11 = bon compromis sécurité/performance)
            passwordHash = BCrypt.Net.BCrypt.HashPassword(password, 11)
        End If

        ' Empêcher l'admin de se retirer ses propres droits admin
        If Not isCreate AndAlso Session("UserId") IsNot Nothing AndAlso CInt(Session("UserId")) = id Then
            If Not cbAdmin.Checked Then
                ShowMsg("Vous ne pouvez pas retirer vos propres droits d'administrateur.", isError:=True)
                cbAdmin.Checked = True
                Return
            End If
            If Not cbActive.Checked Then
                ShowMsg("Vous ne pouvez pas désactiver votre propre compte.", isError:=True)
                cbActive.Checked = True
                Return
            End If
        End If

        ' === Sauvegarde ===
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Email", email))
            p.Add(New SqlParameter("@PasswordHash", passwordHash))
            p.Add(New SqlParameter("@FirstName", If(String.IsNullOrEmpty(txtFirstName.Text), CObj(DBNull.Value), txtFirstName.Text.Trim())))
            p.Add(New SqlParameter("@LastName", If(String.IsNullOrEmpty(txtLastName.Text), CObj(DBNull.Value), txtLastName.Text.Trim())))
            p.Add(New SqlParameter("@IsAdmin", cbAdmin.Checked))
            p.Add(New SqlParameter("@IsActive", cbActive.Checked))
            p.Add(New SqlParameter("@ModifiedBy", If(Session("UserEmail"), "")))

            Dim outNew As New SqlParameter("@NewId", SqlDbType.Int)
            outNew.Direction = ParameterDirection.Output
            p.Add(outNew)

            ExecuteSQL("s0204SaveUser", p)

            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
                "if (typeof closeWin === 'function') closeWin();", True)

        Catch ex As SqlException When ex.Number = 2601 OrElse ex.Number = 2627
            ' Violation d'index unique = email déjà utilisé
            ShowMsg("Ce courriel est déjà utilisé par un autre utilisateur.", isError:=True)
        Catch ex As Exception
            ShowMsg("Erreur : " & ex.Message, isError:=True)
        End Try
    End Sub

    Private Sub btnDelete_Click(sender As Object, e As EventArgs) Handles btnDelete.Click
        Dim id As Integer = 0
        Integer.TryParse(hfId.Value, id)
        If id <= 0 Then Return

        ' Empêcher de se supprimer soi-même
        If Session("UserId") IsNot Nothing AndAlso CInt(Session("UserId")) = id Then
            ShowMsg("Vous ne pouvez pas supprimer votre propre compte.", isError:=True)
            Return
        End If

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@ModifiedBy", If(Session("UserEmail"), "")))
        ExecuteSQL("s0205DeleteUser", p)

        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
            "if (typeof closeWin === 'function') closeWin();", True)
    End Sub

    Private Sub ShowMsg(text As String, Optional isError As Boolean = False)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = "msg " & If(isError, "bad", "ok")
    End Sub

End Class
