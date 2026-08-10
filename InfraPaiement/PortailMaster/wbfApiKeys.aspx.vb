Imports System.Data
Imports System.Data.SqlClient
Imports System.Security.Cryptography
Imports System.Text

''' <summary>
''' Gestion des clés d'API d'un abonné (staff) : génération (clé affichée
''' une seule fois), liste et révocation. Seul le hash SHA-256 est stocké.
''' Scopé par ?abonneId=N.
''' </summary>
Public Class wbfApiKeys
    Inherits clsData

    Private ReadOnly Property AbonneId() As Integer
        Get
            Dim v As Integer
            Integer.TryParse(Request.QueryString("abonneId"), v)
            Return v
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If AbonneId <= 0 Then
            Response.Redirect("~/wbfAbonnes.aspx")
            Return
        End If
        lnkAbonne.HRef = "wbfAbonne.aspx?id=" & AbonneId

        If Not IsPostBack Then
            If Not LoadAbonneName() Then Return
            BindList()
        End If
    End Sub

    Private Function LoadAbonneName() As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", AbonneId))
            Dim tbl As DataTable = ExecuteSQLds("s0005GetAbonne", p).Tables(0)
            If tbl.Rows.Count = 0 Then
                Response.Redirect("~/wbfAbonnes.aspx")
                Return False
            End If
            Dim nom As String = tbl.Rows(0)("RaisonSociale").ToString()
            litAbonne.Text = Server.HtmlEncode(nom)
            lnkAbonne.InnerText = nom
            Return True
        Catch ex As Exception
            ShowError("Impossible de charger l'abonné. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("Keys LoadAbonneName: " & ex.Message)
            Return False
        End Try
    End Function

    Private Sub BindList()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            Dim tbl As DataTable = ExecuteSQLds("s0028ListApiKeys", p).Tables(0)
            rptKeys.DataSource = tbl
            rptKeys.DataBind()
            rptKeys.Visible = (tbl.Rows.Count > 0)
            pnlEmpty.Visible = (tbl.Rows.Count = 0)
        Catch ex As Exception
            ShowError("Impossible de charger les clés. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("Keys BindList: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnGenerate_Click(sender As Object, e As EventArgs)
        Try
            Dim env As String = If(ddlEnv.SelectedValue = "live", "live", "test")
            Dim rawKey As String = "sk_" & env & "_" & RandomHex(24)   ' 48 hex
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
            p.Add(New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)))
            ExecuteSQLds("s0026CreateApiKey", p)
            AuditKey("ApiKeyCreate", "prefix=" & prefix & " env=" & env)

            pnlNewKey.Visible = True
            litNewKey.Text = Server.HtmlEncode(rawKey)   ' affichée une seule fois
            tbLabel.Text = ""
            BindList()
        Catch ex As Exception
            ShowError("Génération impossible. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("Keys Generate: " & ex.Message)
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
            AuditKey("ApiKeyRevoke", "keyId=" & id)
            BindList()
        Catch ex As Exception
            ShowError("Révocation impossible.")
            System.Diagnostics.Debug.WriteLine("Keys Revoke: " & ex.Message)
        End Try
    End Sub

    ''' <summary>Journalise une action sur une clé d'API (ciblée sur l'abonné,
    ''' pour apparaître aussi dans l'historique d'audit par-abonné).</summary>
    Private Sub AuditKey(action As String, details As String)
        Dim nom As String = Server.HtmlDecode(If(litAbonne.Text, ""))
        clsAudit.Write(AdminId, AdminEmail, action, "Abonne", AbonneId, nom, details, Request.UserHostAddress)
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

    Protected Function FormatDate(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return CDate(d).ToString("yyyy-MM-dd")
    End Function

    Protected Function FormatDateTime2(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return "—"
        Return CDate(d).ToString("yyyy-MM-dd HH:mm")
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
