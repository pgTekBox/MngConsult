Imports System.Data
Imports System.Data.SqlClient
Imports System.Security.Cryptography
Imports System.Text

''' <summary>
''' Gestion libre-service des cles d'API de l'abonne connecte : generation
''' (cle affichee une seule fois), liste et revocation. Seul le hash SHA-256
''' est stocke. Scope a l'AbonneId de la session ; reserve aux admins abonne.
''' </summary>
Public Class wbfApiKeys
    Inherits clsData

    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlNewKey As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litNewKey As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents tbLabel As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents ddlEnv As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents btnGenerate As Global.System.Web.UI.WebControls.Button
    Protected WithEvents rptKeys As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlEmpty As Global.System.Web.UI.WebControls.Panel

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsAbonneAdmin Then
            Response.Redirect("~/Default.aspx")
            Return
        End If
        If Not IsPostBack Then BindList()
    End Sub

    Private Sub BindList()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            Dim t As DataTable = ExecuteSQLds("s0028ListApiKeys", p).Tables(0)
            rptKeys.DataSource = t
            rptKeys.DataBind()
            rptKeys.Visible = (t.Rows.Count > 0)
            pnlEmpty.Visible = (t.Rows.Count = 0)
        Catch ex As Exception
            ShowError("Impossible de charger les clés. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("ABN Keys bind: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnGenerate_Click(sender As Object, e As EventArgs)
        Try
            Dim env As String = If(ddlEnv.SelectedValue = "live", "live", "test")
            Dim rawKey As String = "sk_" & env & "_" & RandomHex(24)
            Dim prefix As String = rawKey.Substring(0, 16)
            Dim hash As String = Sha256Hex(rawKey)

            Dim p As New Collection
            Dim outId As New SqlParameter("@Id", SqlDbType.Int) With {.Direction = ParameterDirection.InputOutput, .Value = 0}
            p.Add(outId)
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@KeyHash", hash))
            p.Add(New SqlParameter("@Prefix", prefix))
            p.Add(New SqlParameter("@Label", If(String.IsNullOrEmpty(tbLabel.Text.Trim()), CObj(DBNull.Value), tbLabel.Text.Trim())))
            p.Add(New SqlParameter("@Environment", env))
            p.Add(New SqlParameter("@AdminId", DBNull.Value))
            ExecuteSQLds("s0026CreateApiKey", p)

            pnlNewKey.Visible = True
            litNewKey.Text = Server.HtmlEncode(rawKey)
            tbLabel.Text = ""
            BindList()
        Catch ex As Exception
            ShowError("Génération impossible. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("ABN Keys gen: " & ex.Message)
        End Try
    End Sub

    Protected Sub rptKeys_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName <> "revoke" Then Return
        Dim id As Integer
        If Not Integer.TryParse(TryCast(e.CommandArgument, String), id) Then Return
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            ExecuteSQL("s0029RevokeApiKey", p)
            BindList()
        Catch ex As Exception
            ShowError("Révocation impossible.")
            System.Diagnostics.Debug.WriteLine("ABN Keys revoke: " & ex.Message)
        End Try
    End Sub

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
