Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net

''' <summary>
''' Page de connexion au portail des partenaires (PortailPartenaire).
''' Authentifie un utilisateur partenaire (table T046PartenaireUser) par
''' courriel + mot de passe BCrypt, avec verrouillage temporaire apres
''' plusieurs echecs. A la connexion, le PartenaireId de l'utilisateur est
''' place en session et scope toutes les operations du portail.
''' </summary>
Public Class wbfLogin
    Inherits clsData

    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents tbEmail As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbPassword As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnLogin As Global.System.Web.UI.WebControls.Button

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
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

        Dim usr As DataRow = GetUserByEmail(email)
        Dim genericErr As String = "Courriel ou mot de passe incorrect."

        If usr Is Nothing Then
            ShowError(genericErr)
            Return
        End If

        ' Compte verrouille ?
        If Not IsDBNull(usr("LockoutUntilUtc")) Then
            Dim until As DateTime = CDate(usr("LockoutUntilUtc"))
            If until > DateTime.UtcNow Then
                ShowError("Compte temporairement verrouillé après plusieurs tentatives. Réessayez dans quelques minutes.")
                Return
            End If
        End If

        ' Verifier le mot de passe (BCrypt).
        Dim isValid As Boolean = False
        Try
            isValid = BCrypt.Net.BCrypt.Verify(password, usr("PasswordHash").ToString())
        Catch
            isValid = False
        End Try

        If Not isValid Then
            RegisterFailedLogin(CInt(usr("Id")))
            ShowError(genericErr)
            Return
        End If

        ' Compte utilisateur actif ?
        If Not CBool(usr("IsActive")) Then
            ShowError("Ce compte est désactivé. Contactez l'administrateur de votre organisation.")
            Return
        End If

        ' Partenaire actif ? (pas suspendu / ferme)
        Dim statut As String = If(IsDBNull(usr("PartenaireStatut")), "", usr("PartenaireStatut").ToString())
        If statut = "Suspendu" OrElse statut = "Ferme" OrElse statut = "Fermé" Then
            ShowError("L'accès de votre organisation est actuellement suspendu. Contactez 60secPaiement.")
            Return
        End If

        ' === Connexion reussie ===
        UserId = CInt(usr("Id"))
        PartenaireId = CInt(usr("PartenaireId"))
        UserEmail = usr("Email").ToString()
        UserName = (If(IsDBNull(usr("FirstName")), "", usr("FirstName").ToString()) & " " &
                    If(IsDBNull(usr("LastName")), "", usr("LastName").ToString())).Trim()
        PartenaireName = If(IsDBNull(usr("NomAffichage")) OrElse String.IsNullOrEmpty(usr("NomAffichage").ToString()),
                            usr("RaisonSociale").ToString(), usr("NomAffichage").ToString())
        IsPartnerAdmin = Not IsDBNull(usr("IsAdmin")) AndAlso CBool(usr("IsAdmin"))

        UpdateLastLogin(UserId)

        Dim returnUrl As String = Request.QueryString("ReturnUrl")
        If Not String.IsNullOrEmpty(returnUrl) AndAlso returnUrl.StartsWith("/") Then
            Response.Redirect(returnUrl)
        Else
            Response.Redirect("~/Default.aspx")
        End If
    End Sub

    ' -----------------------------------------------------------------
    ' Acces BD
    ' -----------------------------------------------------------------

    Private Function GetUserByEmail(email As String) As DataRow
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Email", email))
            Dim ds As DataSet = ExecuteSQLds("s0104GetPartnerUserByEmail", p)
            If ds.Tables(0).Rows.Count > 0 Then Return ds.Tables(0).Rows(0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("PTN Login error: " & ex.Message)
        End Try
        Return Nothing
    End Function

    Private Sub UpdateLastLogin(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            ExecuteSQL("s0105UpdatePartnerUserLastLogin", p)
        Catch
        End Try
    End Sub

    Private Sub RegisterFailedLogin(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            ExecuteSQL("s0106RegisterPartnerUserFailedLogin", p)
        Catch
        End Try
    End Sub

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

End Class
