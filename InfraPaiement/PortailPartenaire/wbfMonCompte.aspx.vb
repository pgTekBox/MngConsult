Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net

''' <summary>
''' « Mon compte » : fiche de l'utilisateur partenaire connecté et changement
''' de son mot de passe. L'utilisateur doit fournir son mot de passe actuel ;
''' le nouveau est haché avec BCrypt côté application (la base ne voit jamais
''' le mot de passe en clair) puis enregistré par s0123. Le changement est
''' tracé au journal d'audit (PartnerPasswordChange).
''' </summary>
Public Class wbfMonCompte
    Inherits clsData

    Protected WithEvents pnlOk As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litOk As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litEmail As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litNom As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litPartenaire As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litRole As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litLastLogin As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litCreated As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents tbCurrent As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbNew As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbConfirm As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnChange As Global.System.Web.UI.WebControls.Button

    Private Const MinLength As Integer = 8

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then BindInfo()
    End Sub

    ' -----------------------------------------------------------------
    ' Fiche
    ' -----------------------------------------------------------------

    Private Sub BindInfo()
        Dim r As DataRow = GetUser()
        If r Is Nothing Then
            ShowError("Impossible de charger votre compte. Vérifiez que le script de base de données 46 a été exécuté.")
            Return
        End If

        litEmail.Text = Enc(V(r, "Email"))
        Dim nom As String = (V(r, "FirstName") & " " & V(r, "LastName")).Trim()
        litNom.Text = Enc(If(nom.Length = 0, "—", nom))

        Dim org As String = V(r, "NomAffichage")
        If org.Length = 0 Then org = V(r, "RaisonSociale")
        litPartenaire.Text = Enc(org)

        litRole.Text = If(Not IsDBNull(r("IsAdmin")) AndAlso CBool(r("IsAdmin")),
                          "Administrateur du partenaire", "Utilisateur")
        litLastLogin.Text = FormatDt(r("LastLoginUtc"))
        litCreated.Text = FormatDt(r("CreatedUtc"))
    End Sub

    ' -----------------------------------------------------------------
    ' Changement de mot de passe
    ' -----------------------------------------------------------------

    Protected Sub btnChange_Click(sender As Object, e As EventArgs)
        pnlOk.Visible = False
        pnlError.Visible = False

        Dim current As String = If(tbCurrent.Text, "")
        Dim nouveau As String = If(tbNew.Text, "")
        Dim confirm As String = If(tbConfirm.Text, "")

        If current.Length = 0 OrElse nouveau.Length = 0 OrElse confirm.Length = 0 Then
            ShowError("Remplissez les trois champs.")
            BindInfo() : Return
        End If

        If nouveau.Length < MinLength Then
            ShowError("Le nouveau mot de passe doit contenir au moins " & MinLength & " caractères.")
            BindInfo() : Return
        End If

        If nouveau <> confirm Then
            ShowError("Le nouveau mot de passe et sa confirmation ne correspondent pas.")
            BindInfo() : Return
        End If

        If nouveau = current Then
            ShowError("Le nouveau mot de passe doit être différent de l'actuel.")
            BindInfo() : Return
        End If

        Dim r As DataRow = GetUser()
        If r Is Nothing Then
            ShowError("Impossible de vérifier votre compte. Réessayez.")
            Return
        End If

        ' Vérification du mot de passe actuel (BCrypt).
        Dim ok As Boolean = False
        Try
            ok = BCrypt.Net.BCrypt.Verify(current, V(r, "PasswordHash"))
        Catch
            ok = False
        End Try

        If Not ok Then
            ShowError("Le mot de passe actuel est incorrect.")
            BindInfo() : Return
        End If

        Try
            Dim hash As String = BCrypt.Net.BCrypt.HashPassword(nouveau)

            Dim p As New Collection
            p.Add(New SqlParameter("@Id", UserId))
            p.Add(New SqlParameter("@PasswordHash", hash))
            ExecuteSQL("s0123ChangePartnerUserPassword", p)

            clsAudit.Write(0, UserEmail, "PartnerPasswordChange", "Partenaire", PartenaireId,
                           UserEmail, "Changement de mot de passe par l'utilisateur lui-même.",
                           Request.UserHostAddress)

            tbCurrent.Text = "" : tbNew.Text = "" : tbConfirm.Text = ""
            pnlOk.Visible = True
            litOk.Text = "Mot de passe changé. Utilisez le nouveau à votre prochaine connexion."

        Catch ex As SqlException
            ShowError(ex.Message)
            System.Diagnostics.Debug.WriteLine("PTN ChangePwd: " & ex.Message)
        Catch ex As Exception
            ShowError("Changement impossible. Réessayez.")
            System.Diagnostics.Debug.WriteLine("PTN ChangePwd: " & ex.Message)
        End Try

        BindInfo()
    End Sub

    ' -----------------------------------------------------------------
    ' Accès BD et helpers  (Enc() et FormatDt() viennent de clsData)
    ' -----------------------------------------------------------------

    Private Function GetUser() As DataRow
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", UserId))
            Dim ds As DataSet = ExecuteSQLds("s0124GetPartnerUserById", p)
            If ds.Tables(0).Rows.Count > 0 Then Return ds.Tables(0).Rows(0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("PTN MonCompte GetUser: " & ex.Message)
        End Try
        Return Nothing
    End Function

    Private Function V(r As DataRow, col As String) As String
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return ""
        Return r(col).ToString()
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
