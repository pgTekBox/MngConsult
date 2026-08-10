Imports System.Data
Imports System.Data.SqlClient
Imports System.Security.Cryptography
Imports System.Text

''' <summary>
''' Gestion des clés d'API partenaire (pk_…). Génération (clé affichée une
''' seule fois), liste et révocation. Seul le hash SHA-256 est stocké. Scopé
''' au PartenaireId de la session ; réservé aux administrateurs du partenaire.
''' </summary>
Public Class wbfApiKeys
    Inherits clsData

    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents ddlEnv As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents tbLabel As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnGenerate As Global.System.Web.UI.WebControls.Button
    Protected WithEvents pnlNewKey As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litNewKey As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents rptKeys As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlEmpty As Global.System.Web.UI.WebControls.Panel

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        ' Reserve aux administrateurs du partenaire.
        If Not IsPartnerAdmin Then
            Response.Redirect("~/Default.aspx")
            Return
        End If
        If Not IsPostBack Then BindList()
    End Sub

    Private Sub BindList()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@PartenaireId", PartenaireId))
            Dim t As DataTable = ExecuteSQLds("s0113ListPartnerApiKeys", p).Tables(0)
            rptKeys.DataSource = t
            rptKeys.DataBind()
            rptKeys.Visible = (t.Rows.Count > 0)
            pnlEmpty.Visible = (t.Rows.Count = 0)
        Catch ex As Exception
            ShowError("Impossible de charger les clés. Vérifiez que le script de base de données 42 a été exécuté.")
            System.Diagnostics.Debug.WriteLine("PTN Keys BindList: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnGenerate_Click(sender As Object, e As EventArgs)
        Try
            Dim env As String = If(ddlEnv.SelectedValue = "live", "live", "test")
            Dim rawKey As String = "pk_" & env & "_" & RandomHex(24)   ' 48 hex
            Dim prefix As String = rawKey.Substring(0, 16)
            Dim hash As String = Sha256Hex(rawKey)

            Dim p As New Collection
            p.Add(New SqlParameter("@PartenaireId", PartenaireId))
            p.Add(New SqlParameter("@KeyHash", hash))
            p.Add(New SqlParameter("@Prefix", prefix))
            p.Add(New SqlParameter("@Label", If(String.IsNullOrEmpty(tbLabel.Text.Trim()), CObj(DBNull.Value), tbLabel.Text.Trim())))
            p.Add(New SqlParameter("@Environment", env))
            p.Add(New SqlParameter("@AdminId", DBNull.Value))
            Dim outId As New SqlParameter("@Id", SqlDbType.Int) With {.Direction = ParameterDirection.InputOutput, .Value = 0}
            p.Add(outId)
            ExecuteSQLds("s0112CreatePartnerApiKey", p)

            clsAudit.Write(0, "partner:" & UserEmail, "ApiKeyCreate", "Partenaire", PartenaireId, PartenaireName,
                           "prefix=" & prefix & " env=" & env, Request.UserHostAddress)

            pnlNewKey.Visible = True
            litNewKey.Text = Server.HtmlEncode(rawKey)
            tbLabel.Text = ""
            BindList()
        Catch ex As Exception
            ShowError("Génération impossible. Vérifiez que le script de base de données 42 a été exécuté.")
            System.Diagnostics.Debug.WriteLine("PTN Keys Generate: " & ex.Message)
        End Try
    End Sub

    Protected Sub rptKeys_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName <> "revoke" Then Return
        Dim id As Integer
        If Not Integer.TryParse(TryCast(e.CommandArgument, String), id) Then Return
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            p.Add(New SqlParameter("@PartenaireId", PartenaireId))
            ExecuteSQL("s0114RevokePartnerApiKey", p)
            clsAudit.Write(0, "partner:" & UserEmail, "ApiKeyRevoke", "Partenaire", PartenaireId, PartenaireName,
                           "keyId=" & id, Request.UserHostAddress)
            BindList()
        Catch ex As Exception
            ShowError("Révocation impossible.")
            System.Diagnostics.Debug.WriteLine("PTN Keys Revoke: " & ex.Message)
        End Try
    End Sub

    ' --- Helpers crypto ---

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

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
