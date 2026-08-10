Imports System.Data
Imports System.Data.SqlClient
Imports System.Security.Cryptography
Imports System.Text

''' <summary>
''' Configuration libre-service du webhook de l'abonne connecte : URL de
''' notification + secret de signature HMAC + activation. Un seul endpoint
''' par abonne (contrainte UX_T041_Abonne). Reserve aux admins abonne.
''' </summary>
Public Class wbfWebhooks
    Inherits clsData

    Protected WithEvents pnlOk As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litOk As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents tbUrl As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbSecret As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents cbActive As Global.System.Web.UI.WebControls.CheckBox
    Protected WithEvents btnSave As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnGenSecret As Global.System.Web.UI.WebControls.Button

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsAbonneAdmin Then
            Response.Redirect("~/Default.aspx")
            Return
        End If
        If Not IsPostBack Then LoadEndpoint()
    End Sub

    Private Sub LoadEndpoint()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            Dim t As DataTable = ExecuteSQLds("s0031GetWebhookEndpoint", p).Tables(0)
            If t.Rows.Count = 0 Then
                cbActive.Checked = True
                tbSecret.Text = NewSecret()   ' propose un secret pour un premier enregistrement
                Return
            End If
            Dim r As DataRow = t.Rows(0)
            tbUrl.Text = If(IsDBNull(r("Url")), "", r("Url").ToString())
            tbSecret.Text = If(IsDBNull(r("Secret")), "", r("Secret").ToString())
            cbActive.Checked = Not IsDBNull(r("IsActive")) AndAlso CBool(r("IsActive"))
        Catch ex As Exception
            ShowError("Impossible de charger la configuration. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("ABN Hooks load: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnGenSecret_Click(sender As Object, e As EventArgs)
        tbSecret.Text = NewSecret()
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Dim url As String = If(tbUrl.Text, "").Trim()
        Dim secret As String = If(tbSecret.Text, "").Trim()

        If url.Length = 0 Then
            ShowError("L'URL de notification est obligatoire.") : Return
        End If
        If Not (url.StartsWith("http://") OrElse url.StartsWith("https://")) Then
            ShowError("L'URL doit commencer par http:// ou https://.") : Return
        End If
        If secret.Length < 16 Then
            ShowError("Le secret doit compter au moins 16 caractères. Utilisez « Générer un secret ».") : Return
        End If

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Url", url))
            p.Add(New SqlParameter("@Secret", secret))
            p.Add(New SqlParameter("@IsActive", cbActive.Checked))
            ExecuteSQL("s0030SaveWebhookEndpoint", p)

            pnlOk.Visible = True
            litOk.Text = "Configuration du webhook enregistrée."
            LoadEndpoint()
        Catch ex As Exception
            ShowError("Enregistrement impossible : " & ex.Message)
            System.Diagnostics.Debug.WriteLine("ABN Hooks save: " & ex.Message)
        End Try
    End Sub

    Private Function NewSecret() As String
        Dim bytes(23) As Byte
        Using rng As RandomNumberGenerator = RandomNumberGenerator.Create()
            rng.GetBytes(bytes)
        End Using
        Dim sb As New StringBuilder("whsec_")
        For Each b As Byte In bytes
            sb.Append(b.ToString("x2"))
        Next
        Return sb.ToString()
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
