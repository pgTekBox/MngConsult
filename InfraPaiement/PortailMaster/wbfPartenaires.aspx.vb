Imports System.Data
Imports System.Data.SqlClient
Imports System.Security.Cryptography
Imports System.Text
Imports BCrypt.Net

''' <summary>
''' Console staff des partenaires (Modèle B). Réservée au super-admin.
''' Permet de créer un partenaire (canal de revente, ex. Dentitek), de
''' gérer ses utilisateurs du portail (T046, login BCrypt), d'émettre/révoquer
''' ses clés d'API (pk_…) et de consulter les abonnés qu'il a provisionnés.
''' </summary>
Public Class wbfPartenaires
    Inherits clsData

    Protected WithEvents litHead As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litSub As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents lnkBack As Global.System.Web.UI.WebControls.HyperLink
    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlOk As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litOk As Global.System.Web.UI.WebControls.Literal

    ' Liste
    Protected WithEvents pnlList As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents tbNom As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbNomAff As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbCourriel As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbTel As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbNotes As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnCreatePartner As Global.System.Web.UI.WebControls.Button
    Protected WithEvents rptPartenaires As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlEmpty As Global.System.Web.UI.WebControls.Panel

    ' Detail
    Protected WithEvents pnlDetail As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litStatutBadge As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litPMeta As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents btnToggleStatut As Global.System.Web.UI.WebControls.Button
    Protected WithEvents rptUsers As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlNoUsers As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents tbUserEmail As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbUserPwd As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbUserFirst As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbUserLast As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents cbUserAdmin As Global.System.Web.UI.WebControls.CheckBox
    Protected WithEvents btnCreateUser As Global.System.Web.UI.WebControls.Button
    Protected WithEvents pnlNewKey As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litNewKey As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents rptKeys As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlNoKeys As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents ddlEnv As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents tbKeyLabel As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnGenKey As Global.System.Web.UI.WebControls.Button
    Protected WithEvents litNbAbonnes As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents rptTenants As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlNoTenants As Global.System.Web.UI.WebControls.Panel

    Private ReadOnly Property SelectedId() As Integer
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
            If SelectedId > 0 Then BindDetail() Else BindListMode()
        End If
    End Sub

    ' ================= Liste =================

    Private Sub BindListMode()
        pnlList.Visible = True
        litHead.Text = "Partenaires"
        litSub.Text = "Canaux de distribution / revente (Modèle B)"
        Try
            Dim ds As DataTable = ExecuteSQLds("s0108ListPartenaires", Params(New SqlParameter("@Search", DBNull.Value))).Tables(0)
            rptPartenaires.DataSource = ds
            rptPartenaires.DataBind()
            rptPartenaires.Visible = (ds.Rows.Count > 0)
            pnlEmpty.Visible = (ds.Rows.Count = 0)
        Catch ex As Exception
            ShowErr("Impossible de charger les partenaires. Vérifiez que les scripts 42/43 ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("Partenaires list: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnCreatePartner_Click(sender As Object, e As EventArgs)
        Dim nom As String = If(tbNom.Text, "").Trim()
        If nom.Length = 0 Then
            BindListMode() : ShowErr("La raison sociale est requise.") : Return
        End If
        Try
            Dim outId As New SqlParameter("@Id", SqlDbType.Int) With {.Direction = ParameterDirection.InputOutput, .Value = 0}
            ExecuteSQLds("s0110SavePartenaire", Params(
                outId,
                New SqlParameter("@RaisonSociale", nom),
                New SqlParameter("@NomAffichage", Nz(tbNomAff.Text)),
                New SqlParameter("@CourrielContact", Nz(tbCourriel.Text)),
                New SqlParameter("@Telephone", Nz(tbTel.Text)),
                New SqlParameter("@Statut", "Actif"),
                New SqlParameter("@Notes", Nz(tbNotes.Text)),
                New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId))))
            Dim newId As Integer = CInt(outId.Value)
            clsAudit.Write(AdminId, AdminEmail, "PartnerCreate", "Partenaire", newId, nom, Nothing, Request.UserHostAddress)
            Response.Redirect("wbfPartenaires.aspx?id=" & newId)
        Catch ex As Exception
            BindListMode() : ShowErr("Création impossible : " & ex.Message)
        End Try
    End Sub

    ' ================= Détail =================

    Private m_statut As String = ""

    Private Sub BindDetail()
        Dim t As DataTable = ExecuteSQLds("s0109GetPartenaire", Params(New SqlParameter("@Id", SelectedId))).Tables(0)
        If t.Rows.Count = 0 Then
            Response.Redirect("~/wbfPartenaires.aspx")
            Return
        End If
        Dim r As DataRow = t.Rows(0)
        m_statut = r("Statut").ToString()

        pnlDetail.Visible = True
        lnkBack.Visible = True
        litHead.Text = Server.HtmlEncode(r("RaisonSociale").ToString())
        litSub.Text = "Partenaire — canal de revente"
        litStatutBadge.Text = StatutBadge(r("Statut"))
        litPMeta.Text = "Courriel : " & Enc(r("CourrielContact")) & " · Tél : " & Enc(r("Telephone")) &
                        " · GUID : <span class='mono'>" & Enc(r("PartnerGUID")) & "</span>"

        btnToggleStatut.Text = If(m_statut = "Actif", "Suspendre l'accès", "Réactiver l'accès")

        BindUsers()
        BindKeys()
        BindTenants()
    End Sub

    Private Sub BindUsers()
        Dim t As DataTable = ExecuteSQLds("s0119ListPartnerUsers", Params(New SqlParameter("@PartenaireId", SelectedId))).Tables(0)
        rptUsers.DataSource = t : rptUsers.DataBind()
        rptUsers.Visible = (t.Rows.Count > 0)
        pnlNoUsers.Visible = (t.Rows.Count = 0)
    End Sub

    Private Sub BindKeys()
        Dim t As DataTable = ExecuteSQLds("s0113ListPartnerApiKeys", Params(New SqlParameter("@PartenaireId", SelectedId))).Tables(0)
        rptKeys.DataSource = t : rptKeys.DataBind()
        rptKeys.Visible = (t.Rows.Count > 0)
        pnlNoKeys.Visible = (t.Rows.Count = 0)
    End Sub

    Private Sub BindTenants()
        Dim t As DataTable = ExecuteSQLds("s0116ListAbonnesForPartner", Params(
            New SqlParameter("@PartenaireId", SelectedId),
            New SqlParameter("@Search", DBNull.Value),
            New SqlParameter("@Limit", 500),
            New SqlParameter("@Offset", 0))).Tables(0)
        rptTenants.DataSource = t : rptTenants.DataBind()
        rptTenants.Visible = (t.Rows.Count > 0)
        pnlNoTenants.Visible = (t.Rows.Count = 0)
        litNbAbonnes.Text = t.Rows.Count.ToString()
    End Sub

    Protected Sub btnToggleStatut_Click(sender As Object, e As EventArgs)
        Dim cur As DataTable = ExecuteSQLds("s0109GetPartenaire", Params(New SqlParameter("@Id", SelectedId))).Tables(0)
        If cur.Rows.Count = 0 Then Response.Redirect("~/wbfPartenaires.aspx") : Return
        Dim now As String = cur.Rows(0)("Statut").ToString()
        Dim [next] As String = If(now = "Actif", "Suspendu", "Actif")
        ExecuteSQL("s0111SetPartenaireStatut", Params(
            New SqlParameter("@Id", SelectedId), New SqlParameter("@Statut", [next]),
            New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId))))
        clsAudit.Write(AdminId, AdminEmail, "PartnerStatusChange", "Partenaire", SelectedId,
                       cur.Rows(0)("RaisonSociale").ToString(), now & " -> " & [next], Request.UserHostAddress)
        ShowOk("Statut mis à jour : " & [next] & ".")
        BindDetail()
    End Sub

    Protected Sub btnCreateUser_Click(sender As Object, e As EventArgs)
        Dim email As String = If(tbUserEmail.Text, "").Trim().ToLowerInvariant()
        Dim pwd As String = If(tbUserPwd.Text, "")
        If email.Length = 0 OrElse pwd.Length < 6 Then
            BindDetail() : ShowErr("Courriel requis et mot de passe d'au moins 6 caractères.") : Return
        End If
        Try
            Dim hash As String = BCrypt.Net.BCrypt.HashPassword(pwd, 11)
            Dim outId As New SqlParameter("@Id", SqlDbType.Int) With {.Direction = ParameterDirection.InputOutput, .Value = 0}
            ExecuteSQLds("s0107SavePartnerUser", Params(
                outId,
                New SqlParameter("@PartenaireId", SelectedId),
                New SqlParameter("@Email", email),
                New SqlParameter("@PasswordHash", hash),
                New SqlParameter("@FirstName", Nz(tbUserFirst.Text)),
                New SqlParameter("@LastName", Nz(tbUserLast.Text)),
                New SqlParameter("@IsAdmin", cbUserAdmin.Checked),
                New SqlParameter("@IsActive", True)))
            clsAudit.Write(AdminId, AdminEmail, "PartnerUserCreate", "Partenaire", SelectedId, email, Nothing, Request.UserHostAddress)
            tbUserEmail.Text = "" : tbUserPwd.Text = "" : tbUserFirst.Text = "" : tbUserLast.Text = ""
            ShowOk("Utilisateur ajouté.")
            BindDetail()
        Catch ex As SqlException
            BindDetail()
            If ex.Number = 2627 OrElse ex.Number = 2601 Then
                ShowErr("Ce courriel est déjà utilisé.")
            Else
                ShowErr("Ajout impossible : " & ex.Message)
            End If
        Catch ex As Exception
            BindDetail() : ShowErr("Ajout impossible.")
            System.Diagnostics.Debug.WriteLine("Partner user create: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnGenKey_Click(sender As Object, e As EventArgs)
        Try
            Dim env As String = If(ddlEnv.SelectedValue = "live", "live", "test")
            Dim rawKey As String = "pk_" & env & "_" & RandomHex(24)
            Dim prefix As String = rawKey.Substring(0, 16)
            Dim outId As New SqlParameter("@Id", SqlDbType.Int) With {.Direction = ParameterDirection.InputOutput, .Value = 0}
            ExecuteSQLds("s0112CreatePartnerApiKey", Params(
                New SqlParameter("@PartenaireId", SelectedId),
                New SqlParameter("@KeyHash", Sha256Hex(rawKey)),
                New SqlParameter("@Prefix", prefix),
                New SqlParameter("@Label", If(String.IsNullOrEmpty(tbKeyLabel.Text.Trim()), CObj(DBNull.Value), tbKeyLabel.Text.Trim())),
                New SqlParameter("@Environment", env),
                New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)),
                outId))
            clsAudit.Write(AdminId, AdminEmail, "ApiKeyCreate", "Partenaire", SelectedId, litHead.Text, "prefix=" & prefix & " env=" & env, Request.UserHostAddress)
            pnlNewKey.Visible = True
            litNewKey.Text = Server.HtmlEncode(rawKey)
            tbKeyLabel.Text = ""
            BindDetail()
            pnlNewKey.Visible = True   ' rétabli après BindDetail
        Catch ex As Exception
            BindDetail() : ShowErr("Génération impossible : " & ex.Message)
        End Try
    End Sub

    Protected Sub rptKeys_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName <> "revoke" Then Return
        Dim id As Integer
        If Not Integer.TryParse(TryCast(e.CommandArgument, String), id) Then Return
        ExecuteSQL("s0114RevokePartnerApiKey", Params(
            New SqlParameter("@Id", id), New SqlParameter("@PartenaireId", SelectedId)))
        clsAudit.Write(AdminId, AdminEmail, "ApiKeyRevoke", "Partenaire", SelectedId, litHead.Text, "keyId=" & id, Request.UserHostAddress)
        ShowOk("Clé révoquée.")
        BindDetail()
    End Sub

    ' ================= Helpers =================

    Private Function Params(ParamArray ps As SqlParameter()) As Collection
        Dim c As New Collection
        For Each p As SqlParameter In ps
            c.Add(p)
        Next
        Return c
    End Function

    Private Function Nz(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

    Private Function RandomHex(nbBytes As Integer) As String
        Dim bytes(nbBytes - 1) As Byte
        Using rng As RandomNumberGenerator = RandomNumberGenerator.Create()
            rng.GetBytes(bytes)
        End Using
        Dim sb As New StringBuilder(nbBytes * 2)
        For Each b As Byte In bytes
            sb.Append(b.ToString("x2"))
        Next
        Return sb.ToString()
    End Function

    Private Function Sha256Hex(value As String) As String
        Using sha As SHA256 = SHA256.Create()
            Dim bytes As Byte() = sha.ComputeHash(Encoding.UTF8.GetBytes(value))
            Dim sb As New StringBuilder(bytes.Length * 2)
            For Each b As Byte In bytes
                sb.Append(b.ToString("x2"))
            Next
            Return sb.ToString()
        End Using
    End Function

    Protected Function Enc(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return "—"
        Dim s As String = o.ToString()
        Return If(s.Length = 0, "—", Server.HtmlEncode(s))
    End Function

    Protected Function FormatDate(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return "—"
        Return CDate(o).ToString("yyyy-MM-dd")
    End Function

    Protected Function StatutBadge(o As Object) As String
        Dim s As String = If(o Is Nothing OrElse IsDBNull(o), "", o.ToString())
        Dim cls As String
        Select Case s
            Case "Actif" : cls = "badge-actif"
            Case "Prospect" : cls = "badge-prospect"
            Case "Suspendu" : cls = "badge-suspendu"
            Case Else : cls = "badge-ferme"
        End Select
        Return "<span class='badge " & cls & "'>" & Server.HtmlEncode(s) & "</span>"
    End Function

    Protected Function KybBadge(o As Object) As String
        Dim s As String = If(o Is Nothing OrElse IsDBNull(o), "", o.ToString())
        Dim cls As String, txt As String
        Select Case s
            Case "Verifie" : cls = "badge-verifie" : txt = "Vérifié"
            Case "EnCours" : cls = "badge-encours" : txt = "En cours"
            Case "Rejete" : cls = "badge-rejete" : txt = "Rejeté"
            Case Else : cls = "badge-nondebute" : txt = "Non débuté"
        End Select
        Return "<span class='badge " & cls & "'>" & txt & "</span>"
    End Function

    Private Sub ShowErr(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

    Private Sub ShowOk(msg As String)
        pnlOk.Visible = True
        litOk.Text = Server.HtmlEncode(msg)
    End Sub

End Class
