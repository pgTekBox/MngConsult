Imports System.Web
Imports System.Web.SessionState
Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Export CSV du journal d'audit (pour un auditeur). Réservé aux
''' super-administrateurs connectés. Honore les mêmes filtres que wbfAudit
''' (query action / search). L'export est lui-même journalisé (Action=AuditExport).
''' CSV RFC 4180 + BOM UTF-8 (accents corrects dans Excel).
''' </summary>
Public Class AuditExport
    Implements IHttpHandler, IRequiresSessionState

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        Dim ctx As HttpContext = context

        ' Authentification : staff super-administrateur.
        Dim adminId As Integer = 0
        If ctx.Session IsNot Nothing AndAlso ctx.Session("AdminId") IsNot Nothing Then adminId = CInt(ctx.Session("AdminId"))
        Dim isSuper As Boolean = ctx.Session IsNot Nothing AndAlso ctx.Session("AdminIsSuperAdmin") IsNot Nothing AndAlso CBool(ctx.Session("AdminIsSuperAdmin"))
        If adminId = 0 OrElse Not isSuper Then
            ctx.Response.StatusCode = 403
            ctx.Response.Write("Non autorisé.")
            Return
        End If

        Dim actionFilter As String = If(ctx.Request.QueryString("action"), "")
        Dim search As String = If(ctx.Request.QueryString("search"), "")

        Try
            Dim t As DataTable = LoadAudit(actionFilter, search)

            ' Journalise l'export du journal (traçabilité de qui consulte l'audit).
            Dim actorEmail As String = If(ctx.Session("AdminEmail") Is Nothing, "", ctx.Session("AdminEmail").ToString())
            Dim details As String = "rows=" & t.Rows.Count &
                                    If(actionFilter.Length > 0, " action=" & actionFilter, "") &
                                    If(search.Length > 0, " search=" & search, "")
            clsAudit.Write(adminId, actorEmail, "AuditExport", "AuditLog", 0, Nothing, details, ctx.Request.UserHostAddress)

            Dim sb As New StringBuilder()
            sb.Append("Id,Utc,ActorAdminId,ActorEmail,Action,TargetType,TargetId,TargetName,Details,IpAddress").Append(vbCrLf)
            For Each r As DataRow In t.Rows
                sb.Append(Csv(r("Id"))).Append(",")
                sb.Append(Csv(FmtDt(r("Utc")))).Append(",")
                sb.Append(Csv(r("ActorAdminId"))).Append(",")
                sb.Append(Csv(r("ActorEmail"))).Append(",")
                sb.Append(Csv(r("Action"))).Append(",")
                sb.Append(Csv(r("TargetType"))).Append(",")
                sb.Append(Csv(r("TargetId"))).Append(",")
                sb.Append(Csv(r("TargetName"))).Append(",")
                sb.Append(Csv(r("Details"))).Append(",")
                sb.Append(Csv(r("IpAddress"))).Append(vbCrLf)
            Next

            Dim fileName As String = "audit_log_" & DateTime.UtcNow.ToString("yyyyMMdd_HHmmss") & ".csv"
            ctx.Response.ContentType = "text/csv; charset=utf-8"
            ctx.Response.ContentEncoding = New UTF8Encoding(False)
            ctx.Response.AddHeader("Content-Disposition", "attachment; filename=""" & fileName & """")
            ' BOM UTF-8 (U+FEFF) pour qu'Excel interprète correctement les accents.
            ctx.Response.Write(ChrW(&HFEFF) & sb.ToString())
        Catch ex As Exception
            ctx.Response.StatusCode = 500
            ctx.Response.Write("Erreur d'export.")
            System.Diagnostics.Debug.WriteLine("AuditExport: " & ex.ToString())
        End Try
    End Sub

    Private Function LoadAudit(actionFilter As String, search As String) As DataTable
        Dim cs As String = System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
        Using conn As New SqlConnection(cs)
            Using cmd As New SqlCommand("s0093ListAuditLog", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@TargetType", DBNull.Value)
                cmd.Parameters.AddWithValue("@TargetId", DBNull.Value)
                cmd.Parameters.AddWithValue("@Action", NzOrNull(actionFilter))
                cmd.Parameters.AddWithValue("@Search", NzOrNull(search))
                cmd.Parameters.AddWithValue("@Top", 100000)
                Dim da As New SqlDataAdapter(cmd)
                Dim dt As New DataTable()
                da.Fill(dt)
                Return dt
            End Using
        End Using
    End Function

    ''' <summary>Échappe un champ CSV (RFC 4180) : guillemets si virgule /
    ''' guillemet / saut de ligne, guillemets internes doublés.</summary>
    Private Function Csv(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Dim s As String = v.ToString()
        If s.IndexOf(""""c) >= 0 OrElse s.IndexOf(","c) >= 0 OrElse s.IndexOf(ChrW(10)) >= 0 OrElse s.IndexOf(ChrW(13)) >= 0 Then
            Return """" & s.Replace("""", """""") & """"
        End If
        Return s
    End Function

    Private Function FmtDt(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Return CDate(v).ToString("yyyy-MM-ddTHH:mm:ss")
    End Function

    Private Function NzOrNull(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
