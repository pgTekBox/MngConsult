Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Web.SessionState

''' <summary>
''' Télécharge le fichier joint d'une « Demande à Claude » (console Admin).
'''   ?id=&lt;T026ClaudePrompt.Id&gt;
''' Le contenu est lu par s0968GetClaudePromptFichier (base MngConsul).
''' Accès réservé à un administrateur connecté (Session AdminId).
''' </summary>
Public Class ClaudePromptFichierHandler
    Implements IHttpHandler, IReadOnlySessionState

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        ' --- Sécurité : administrateur connecté ---
        Dim adminId As Integer = 0
        If context.Session IsNot Nothing AndAlso context.Session("AdminId") IsNot Nothing Then
            Integer.TryParse(context.Session("AdminId").ToString(), adminId)
        End If
        If adminId <= 0 Then
            context.Response.StatusCode = 403 : Return
        End If

        Dim id As Integer = 0
        Integer.TryParse(context.Request("id"), id)
        If id <= 0 Then
            context.Response.StatusCode = 400 : Return
        End If

        Dim content As Byte() = Nothing
        Dim fileName As String = "piece-jointe"
        Dim contentType As String = "application/octet-stream"

        Try
            Dim cs As String = ConfigurationManager.AppSettings("ConnectionString")
            Using cn As New SqlConnection(cs)
                cn.Open()
                Using cmd As New SqlCommand("dbo.s0968GetClaudePromptFichier", cn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@Id", id)
                    Using rd = cmd.ExecuteReader()
                        If rd.Read() AndAlso Not IsDBNull(rd("FichierData")) Then
                            content = CType(rd("FichierData"), Byte())
                            fileName = SafeStr(rd("FichierNom"), "piece-jointe")
                            contentType = SafeStr(rd("FichierType"), "application/octet-stream")
                        End If
                    End Using
                End Using
            End Using
        Catch
        End Try

        If content Is Nothing Then
            context.Response.StatusCode = 404 : Return
        End If

        context.Response.Clear()
        context.Response.ContentType = contentType
        context.Response.AddHeader("Content-Disposition", "attachment; filename=""" & SanitizeFn(fileName) & """")
        context.Response.BinaryWrite(content)
    End Sub

    Private Shared Function SafeStr(o As Object, def As String) As String
        If o Is Nothing OrElse o Is DBNull.Value Then Return def
        Dim s As String = o.ToString()
        Return If(s = "", def, s)
    End Function

    Private Shared Function SanitizeFn(fn As String) As String
        Return fn.Replace(ChrW(34), "'").Replace(vbCr, "").Replace(vbLf, "")
    End Function

End Class
