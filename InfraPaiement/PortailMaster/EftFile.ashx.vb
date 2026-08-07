Imports System.Web
Imports System.Web.SessionState
Imports System.Data.SqlClient

''' <summary>
''' Télécharge le fichier CPA-005 d'un lot (?batchId=N) et marque le lot
''' comme « Généré ». Réservé au staff connecté (session).
''' </summary>
Public Class EftFile
    Implements IHttpHandler, IRequiresSessionState

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        Dim ctx As HttpContext = context

        ' Authentification (session staff)
        Dim adminId As Integer = 0
        If ctx.Session IsNot Nothing AndAlso ctx.Session("AdminId") IsNot Nothing Then adminId = CInt(ctx.Session("AdminId"))
        If adminId = 0 Then
            ctx.Response.StatusCode = 403
            ctx.Response.Write("Non autorisé.")
            Return
        End If

        Dim batchId As Integer
        If Not Integer.TryParse(ctx.Request.QueryString("batchId"), batchId) OrElse batchId <= 0 Then
            ctx.Response.StatusCode = 400
            ctx.Response.Write("batchId requis.")
            Return
        End If

        Try
            Dim res As clsCpa005Builder.Cpa005Result = clsCpa005Builder.BuildFile(batchId)
            MarkGenerated(batchId, res.FileName)

            ctx.Response.ContentType = "text/plain; charset=utf-8"
            ctx.Response.AddHeader("Content-Disposition", "attachment; filename=""" & res.FileName & """")
            ctx.Response.Write(res.Content)
        Catch ex As Exception
            ctx.Response.StatusCode = 500
            ctx.Response.Write("Erreur de génération : " & ex.Message)
            System.Diagnostics.Debug.WriteLine("EftFile: " & ex.ToString())
        End Try
    End Sub

    Private Sub MarkGenerated(batchId As Integer, fileName As String)
        Dim cs As String = System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
        Using conn As New SqlConnection(cs)
            Using cmd As New SqlCommand("s0047MarkBatchGenerated", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@BatchId", batchId)
                cmd.Parameters.AddWithValue("@FileName", fileName)
                conn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
