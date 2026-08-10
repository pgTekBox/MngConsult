Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Page globale du journal d'audit (actions sensibles). Réservée aux
''' super-administrateurs. Liste filtrable par action + recherche.
''' </summary>
Public Class wbfAudit
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not AdminIsSuperAdmin Then
            Response.Redirect("~/Default.aspx")
            Return
        End If
        If Not IsPostBack Then Bind()
    End Sub

    Protected Sub btnFilter_Click(sender As Object, e As EventArgs)
        Bind()
    End Sub

    Private Sub Bind()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@TargetType", DBNull.Value))
            p.Add(New SqlParameter("@TargetId", DBNull.Value))
            p.Add(New SqlParameter("@Action", NzOrNull(ddlAction.SelectedValue)))
            p.Add(New SqlParameter("@Search", NzOrNull(tbSearch.Text)))
            p.Add(New SqlParameter("@Top", 500))
            Dim t As DataTable = ExecuteSQLds("s0093ListAuditLog", p).Tables(0)
            rpt.DataSource = t
            rpt.DataBind()
            rpt.Visible = (t.Rows.Count > 0)
            pnlEmpty.Visible = (t.Rows.Count = 0)

            ' Le lien d'export CSV reflète le filtre courant.
            lnkExportCsv.NavigateUrl = "AuditExport.ashx?action=" & Server.UrlEncode(ddlAction.SelectedValue) &
                                       "&search=" & Server.UrlEncode(If(tbSearch.Text, "").Trim())
        Catch ex As Exception
            ShowError("Impossible de charger le journal d'audit. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("Audit list: " & ex.Message)
        End Try
    End Sub

    Protected Function CibleHtml(item As Object) As String
        Dim r As DataRowView = TryCast(item, DataRowView)
        If r Is Nothing Then Return ""
        Dim tt As String = If(IsDBNull(r("TargetType")), "", r("TargetType").ToString())
        Dim tid As String = If(IsDBNull(r("TargetId")), "", r("TargetId").ToString())
        Dim tn As String = If(IsDBNull(r("TargetName")), "", r("TargetName").ToString())
        Dim label As String = (tt & " #" & tid).Trim()
        Dim html As String = "<span class=""mono muted"">" & Server.HtmlEncode(label) & "</span>"
        If tn.Length > 0 Then html &= " " & Server.HtmlEncode(tn)
        If tt = "Abonne" AndAlso tid.Length > 0 Then
            html = "<a href=""wbfAbonne.aspx?id=" & Server.UrlEncode(tid) & """>" & html & "</a>"
        End If
        Return html
    End Function

    ''' <summary>Classe CSS du badge d'action (rouge pour les échecs).</summary>
    Protected Function ActionBadge(a As Object) As String
        Select Case If(a, "").ToString()
            Case "LoginFailed" : Return "badge-rejete"
            Case "Anonymize", "Offboard", "ApiKeyRevoke" : Return "badge-suspendu"
            Case "KybStatusChange" : Return "badge-verifie"
            Case Else : Return "badge-audit"
        End Select
    End Function

    Protected Function FormatDt(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return "—"
        Return CDate(d).ToString("yyyy-MM-dd HH:mm:ss")
    End Function

    Protected Function Enc(o As Object) As String
        Return Server.HtmlEncode(If(o, "").ToString())
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
