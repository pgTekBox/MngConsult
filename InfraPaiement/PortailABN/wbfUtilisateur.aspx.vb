Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net

''' <summary>
''' Creation / edition d'un utilisateur de l'abonne connecte.
'''   wbfUtilisateur.aspx        -> creation
'''   wbfUtilisateur.aspx?id=N   -> edition
''' Reservee aux administrateurs de l'abonne. Isolation : on ne peut editer
''' qu'un utilisateur de SON abonne. Le mot de passe est hache en BCrypt cote
''' application ; le clair n'est jamais stocke.
''' </summary>
Public Class wbfUtilisateur
    Inherits clsData

    Protected WithEvents litTitle As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litMeta As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlOk As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litOk As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents tbPrenom As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbNom As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbEmail As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbPassword As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents litPwdLabel As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litPwdHint As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents cbAdmin As Global.System.Web.UI.WebControls.CheckBox
    Protected WithEvents cbActif As Global.System.Web.UI.WebControls.CheckBox
    Protected WithEvents btnSave As Global.System.Web.UI.WebControls.Button

    ''' <summary>Id de l'utilisateur edite (0 = creation). Nomme EditId pour
    ''' eviter la collision avec Control.ClientID / la prop de session UserId.</summary>
    Private ReadOnly Property EditId() As Integer
        Get
            Dim v As Integer
            Integer.TryParse(Request.QueryString("id"), v)
            Return v
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsAbonneAdmin Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        If Not IsPostBack Then
            If EditId > 0 Then
                If Not LoadUser(EditId) Then Return
                litPwdLabel.Text = "Nouveau mot de passe"
                litPwdHint.Text = "Laisser vide pour conserver le mot de passe actuel (minimum 8 caractères sinon)."
            End If
        End If
    End Sub

    Private Function LoadUser(id As Integer) As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            Dim t As DataTable = ExecuteSQLds("s0072GetAbonneUser", p).Tables(0)
            If t.Rows.Count = 0 Then
                ShowError("Utilisateur introuvable.")
                Return False
            End If
            Dim r As DataRow = t.Rows(0)

            ' Garde d'isolation : l'utilisateur doit appartenir a l'abonne courant.
            If IsDBNull(r("AbonneId")) OrElse CInt(r("AbonneId")) <> AbonneId Then
                Response.Redirect("~/wbfUtilisateurs.aspx")
                Return False
            End If

            Dim nom As String = (V(r, "FirstName") & " " & V(r, "LastName")).Trim()
            litTitle.Text = Server.HtmlEncode(If(nom.Length = 0, V(r, "Email"), nom))
            litMeta.Text = "Créé le " & FormatDate(r("CreatedUtc"))

            tbPrenom.Text = V(r, "FirstName")
            tbNom.Text = V(r, "LastName")
            tbEmail.Text = V(r, "Email")
            cbAdmin.Checked = Not IsDBNull(r("IsAdmin")) AndAlso CBool(r("IsAdmin"))
            cbActif.Checked = Not IsDBNull(r("IsActive")) AndAlso CBool(r("IsActive"))
            Return True
        Catch ex As Exception
            ShowError("Impossible de charger l'utilisateur. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("ABN User load: " & ex.Message)
            Return False
        End Try
    End Function

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Dim email As String = If(tbEmail.Text, "").Trim()
        Dim password As String = If(tbPassword.Text, "")
        Dim isEdit As Boolean = (EditId > 0)

        If email.Length = 0 Then
            ShowError("Le courriel est obligatoire.") : Return
        End If
        If Not isEdit AndAlso password.Length = 0 Then
            ShowError("Un mot de passe est requis pour un nouvel utilisateur.") : Return
        End If
        If password.Length > 0 AndAlso password.Length < 8 Then
            ShowError("Le mot de passe doit contenir au moins 8 caractères.") : Return
        End If

        ' Isolation en edition : recharger la fiche et verifier l'appartenance.
        If isEdit Then
            If Not BelongsToAbonne(EditId) Then
                Response.Redirect("~/wbfUtilisateurs.aspx") : Return
            End If
            ' Garde anti-verrouillage : on ne peut pas se retirer soi-meme l'acces.
            If EditId = UserId Then
                If Not cbActif.Checked Then
                    ShowError("Vous ne pouvez pas désactiver votre propre compte.") : Return
                End If
                If Not cbAdmin.Checked Then
                    ShowError("Vous ne pouvez pas retirer votre propre rôle d'administrateur.") : Return
                End If
            End If
        End If

        Try
            Dim p As New Collection
            Dim outId As New SqlParameter("@Id", SqlDbType.Int) With {.Direction = ParameterDirection.InputOutput, .Value = EditId}
            p.Add(outId)
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Email", email.ToLowerInvariant()))
            If password.Length > 0 Then
                p.Add(New SqlParameter("@PasswordHash", BCrypt.Net.BCrypt.HashPassword(password)))
            Else
                p.Add(New SqlParameter("@PasswordHash", DBNull.Value))
            End If
            p.Add(New SqlParameter("@FirstName", NzOrNull(tbPrenom.Text)))
            p.Add(New SqlParameter("@LastName", NzOrNull(tbNom.Text)))
            p.Add(New SqlParameter("@IsAdmin", cbAdmin.Checked))
            p.Add(New SqlParameter("@IsActive", cbActif.Checked))
            ExecuteSQLds("s0070SaveAbonneUser", p)

            Response.Redirect("~/wbfUtilisateurs.aspx?saved=1")
        Catch sqlEx As SqlException When sqlEx.Number = 2601 OrElse sqlEx.Number = 2627
            ShowError("Ce courriel est déjà utilisé par un autre utilisateur.")
        Catch ex As Exception
            ShowError("Enregistrement impossible. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("ABN User save: " & ex.Message)
        End Try
    End Sub

    ''' <summary>Verifie que l'utilisateur cible appartient a l'abonne courant.</summary>
    Private Function BelongsToAbonne(id As Integer) As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            Dim t As DataTable = ExecuteSQLds("s0072GetAbonneUser", p).Tables(0)
            If t.Rows.Count = 0 Then Return False
            Return Not IsDBNull(t.Rows(0)("AbonneId")) AndAlso CInt(t.Rows(0)("AbonneId")) = AbonneId
        Catch
            Return False
        End Try
    End Function

    Private Function V(r As DataRow, col As String) As String
        If IsDBNull(r(col)) Then Return ""
        Return r(col).ToString()
    End Function

    Private Function NzOrNull(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
