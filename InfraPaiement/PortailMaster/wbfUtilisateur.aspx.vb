Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net

''' <summary>
''' Création / édition d'un utilisateur du portail (staff plateforme).
'''   wbfUtilisateur.aspx        -> création
'''   wbfUtilisateur.aspx?id=N   -> édition
''' Réservée aux super-administrateurs. Le mot de passe est haché en BCrypt
''' côté application ; le clair n'est jamais stocké.
''' </summary>
Public Class wbfUtilisateur
    Inherits clsData

    Private ReadOnly Property UserId2() As Integer
        Get
            Dim v As Integer
            Integer.TryParse(Request.QueryString("id"), v)
            Return v
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not AdminIsSuperAdmin Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        If Not IsPostBack Then
            If UserId2 > 0 Then
                LoadUser(UserId2)
                ' En édition : mot de passe optionnel.
                litPwdLabel.Text = "Nouveau mot de passe"
                litPwdHint.Text = "Laisser vide pour conserver le mot de passe actuel (minimum 8 caractères sinon)."
            End If
            If Request.QueryString("saved") = "1" Then
                pnlOk.Visible = True
                litOk.Text = "Utilisateur enregistré avec succès."
            End If
        End If
    End Sub

    Private Sub LoadUser(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            Dim tbl As DataTable = ExecuteSQLds("s0009GetAdmin", p).Tables(0)

            If tbl.Rows.Count = 0 Then
                ShowError("Utilisateur introuvable.")
                Return
            End If

            Dim r As DataRow = tbl.Rows(0)
            Dim nom As String = (Val(r, "FirstName") & " " & Val(r, "LastName")).Trim()
            litTitle.Text = Server.HtmlEncode(If(nom.Length = 0, Val(r, "Email"), nom))
            litMeta.Text = "Créé le " & FormatDate(r("CreatedUtc"))

            tbPrenom.Text = Val(r, "FirstName")
            tbNom.Text = Val(r, "LastName")
            tbEmail.Text = Val(r, "Email")
            cbActif.Checked = Not IsDBNull(r("IsActive")) AndAlso CBool(r("IsActive"))
            cbSuperAdmin.Checked = Not IsDBNull(r("IsSuperAdmin")) AndAlso CBool(r("IsSuperAdmin"))
        Catch ex As Exception
            ShowError("Impossible de charger l'utilisateur. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("LoadUser: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)

        Dim email As String = If(tbEmail.Text, "").Trim()
        Dim password As String = If(tbPassword.Text, "")
        Dim isEdit As Boolean = (UserId2 > 0)

        ' --- Validations ---
        If email.Length = 0 Then
            ShowError("Le courriel est obligatoire.")
            Return
        End If

        ' Mot de passe : requis à la création, optionnel en édition.
        If Not isEdit AndAlso password.Length = 0 Then
            ShowError("Un mot de passe est requis pour un nouvel utilisateur.")
            Return
        End If
        If password.Length > 0 AndAlso password.Length < 8 Then
            ShowError("Le mot de passe doit contenir au moins 8 caractères.")
            Return
        End If

        ' Garde anti-verrouillage : on ne peut pas se retirer soi-même l'accès.
        If isEdit AndAlso UserId2 = AdminId Then
            If Not cbActif.Checked Then
                ShowError("Vous ne pouvez pas désactiver votre propre compte.")
                Return
            End If
            If Not cbSuperAdmin.Checked Then
                ShowError("Vous ne pouvez pas retirer votre propre rôle de super-administrateur.")
                Return
            End If
        End If

        Try
            Dim newId As Integer = UserId2

            Dim p As New Collection
            p.Add(New SqlParameter("@Id", newId))
            p.Add(New SqlParameter("@Email", email.ToLowerInvariant()))
            p.Add(New SqlParameter("@FirstName", ParamOrNull(tbPrenom.Text)))
            p.Add(New SqlParameter("@LastName", ParamOrNull(tbNom.Text)))
            p.Add(New SqlParameter("@IsActive", cbActif.Checked))
            p.Add(New SqlParameter("@IsSuperAdmin", cbSuperAdmin.Checked))

            ' Hash BCrypt uniquement si un mot de passe est fourni.
            If password.Length > 0 Then
                p.Add(New SqlParameter("@PasswordHash", BCrypt.Net.BCrypt.HashPassword(password)))
            Else
                p.Add(New SqlParameter("@PasswordHash", DBNull.Value))
            End If

            Dim ds As DataSet = ExecuteSQLds("s0010SaveAdmin", p)
            If ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                newId = CInt(ds.Tables(0).Rows(0)("Id"))
            End If

            Response.Redirect("wbfUtilisateur.aspx?id=" & newId & "&saved=1")

        Catch sqlEx As SqlException When sqlEx.Number = 2601 OrElse sqlEx.Number = 2627
            ShowError("Ce courriel est déjà utilisé par un autre utilisateur.")
        Catch ex As Exception
            ShowError("Enregistrement impossible. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("SaveUser: " & ex.Message)
        End Try
    End Sub

    ' --- Helpers ---

    Private Function Val(r As DataRow, col As String) As String
        If IsDBNull(r(col)) Then Return ""
        Return r(col).ToString()
    End Function

    Private Function ParamOrNull(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

    Private Function FormatDate(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return CDate(d).ToString("yyyy-MM-dd")
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

End Class
