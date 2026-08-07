Imports System.Data
Imports System.Data.SqlClient
Imports System.Security.Cryptography

''' <summary>
''' Configuration de l'endpoint webhook d'un abonné (URL + secret) et suivi
''' des livraisons. Bouton « Traiter la file » = déclenche le dispatcher.
''' Scopé par ?abonneId=N.
''' </summary>
Public Class wbfWebhooks
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
            LoadEndpoint()
            BindDeliveries()
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
            ShowError("Impossible de charger l'abonné.")
            System.Diagnostics.Debug.WriteLine("Wh LoadAbonneName: " & ex.Message)
            Return False
        End Try
    End Function

    Private Sub LoadEndpoint()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            Dim tbl As DataTable = ExecuteSQLds("s0031GetWebhookEndpoint", p).Tables(0)
            If tbl.Rows.Count > 0 Then
                Dim r As DataRow = tbl.Rows(0)
                tbUrl.Text = r("Url").ToString()
                tbSecret.Text = r("Secret").ToString()
                cbActive.Checked = CBool(r("IsActive"))
            Else
                tbSecret.Text = NewSecret()
            End If
        Catch ex As Exception
            ShowError("Impossible de charger l'endpoint. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("Wh LoadEndpoint: " & ex.Message)
        End Try
    End Sub

    Private Sub BindDeliveries()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Top", 50))
            Dim tbl As DataTable = ExecuteSQLds("s0034ListDeliveries", p).Tables(0)
            rptDeliveries.DataSource = tbl
            rptDeliveries.DataBind()
            rptDeliveries.Visible = (tbl.Rows.Count > 0)
            pnlEmpty.Visible = (tbl.Rows.Count = 0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Wh BindDeliveries: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Dim url As String = If(tbUrl.Text, "").Trim()
        Dim secret As String = If(tbSecret.Text, "").Trim()
        If url.Length = 0 Then
            ShowError("L'URL est obligatoire.")
            BindDeliveries() : Return
        End If
        If Not (url.StartsWith("http://", StringComparison.OrdinalIgnoreCase) OrElse url.StartsWith("https://", StringComparison.OrdinalIgnoreCase)) Then
            ShowError("L'URL doit commencer par http:// ou https://.")
            BindDeliveries() : Return
        End If
        If secret.Length < 8 Then
            ShowError("Le secret doit contenir au moins 8 caractères.")
            BindDeliveries() : Return
        End If
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Url", url))
            p.Add(New SqlParameter("@Secret", secret))
            p.Add(New SqlParameter("@IsActive", cbActive.Checked))
            ExecuteSQL("s0030SaveWebhookEndpoint", p)
            ShowOk("Endpoint enregistré.")
            BindDeliveries()
        Catch ex As Exception
            ShowError("Enregistrement impossible.")
            System.Diagnostics.Debug.WriteLine("Wh Save: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnGenSecret_Click(sender As Object, e As EventArgs)
        tbSecret.Text = NewSecret()
    End Sub

    Protected Sub btnProcess_Click(sender As Object, e As EventArgs)
        Try
            Dim n As Integer = clsWebhookDispatcher.ProcessDueDeliveries(50)
            ShowOk(n & " livraison(s) traitée(s).")
            BindDeliveries()
        Catch ex As Exception
            ShowError("Traitement impossible : " & ex.Message)
            System.Diagnostics.Debug.WriteLine("Wh Process: " & ex.Message)
        End Try
    End Sub

    ' --- Helpers ---

    Private Function NewSecret() As String
        Dim bytes(23) As Byte
        Using rng As RandomNumberGenerator = RandomNumberGenerator.Create()
            rng.GetBytes(bytes)
        End Using
        Return "whsec_" & Convert.ToBase64String(bytes).Replace("+", "").Replace("/", "").Replace("=", "")
    End Function

    Protected Function BadgeStatut(s As Object) As String
        Select Case If(s, "").ToString()
            Case "Delivered" : Return "badge-actif"
            Case "Pending" : Return "badge-encours"
            Case "Abandoned", "Failed" : Return "badge-rejete"
            Case Else : Return "badge-off"
        End Select
    End Function

    Protected Function FormatDt(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return "—"
        Return CDate(d).ToString("yyyy-MM-dd HH:mm")
    End Function

    Private Sub ShowOk(msg As String)
        pnlOk.Visible = True
        litOk.Text = Server.HtmlEncode(msg)
    End Sub

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
