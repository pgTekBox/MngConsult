Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Web.SessionState

''' <summary>
''' Télécharge une pièce jointe d'un courriel (console Admin).
'''   ?src=sent&id=&lt;T402.Id&gt;                -> pièce jointe d'un envoyé (T402Attachments)
'''   ?src=inbound&mid=&lt;msgId&gt;&ix=&lt;index&gt;  -> pièce jointe d'un entrant (parsée du MIME brut)
''' Accès réservé à un administrateur connecté (Session AdminId).
''' </summary>
Public Class MailAttachment
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

        Dim cs As String = ConfigurationManager.AppSettings("ConnectionStringMail")
        Dim src As String = If(context.Request("src"), "").ToLowerInvariant()
        Dim content As Byte() = Nothing
        Dim fileName As String = "piece-jointe"
        Dim contentType As String = "application/octet-stream"

        Try
            If src = "sent" Then
                Dim attId As Integer = 0 : Integer.TryParse(context.Request("id"), attId)
                Using cn As New SqlConnection(cs)
                    cn.Open()
                    Using cmd As New SqlCommand("dbo.s0627GetSentAttachment", cn)
                        cmd.CommandType = CommandType.StoredProcedure
                        cmd.Parameters.AddWithValue("@AttId", attId)
                        Using rd = cmd.ExecuteReader()
                            If rd.Read() AndAlso Not IsDBNull(rd("Content")) Then
                                content = CType(rd("Content"), Byte())
                                fileName = SafeStr(rd("FileName"), "piece-jointe")
                                contentType = SafeStr(rd("ContentType"), "application/octet-stream")
                            End If
                        End Using
                    End Using
                End Using
            Else
                ' entrant : on parse le MIME brut et on prend la Nième pièce jointe
                Dim mid As Long = 0 : Long.TryParse(context.Request("mid"), mid)
                Dim ix As Integer = 0 : Integer.TryParse(context.Request("ix"), ix)
                Dim raw As Byte() = Nothing
                Using cn As New SqlConnection(cs)
                    cn.Open()
                    Using cmd As New SqlCommand("dbo.s0612GetInboundMail", cn)
                        cmd.CommandType = CommandType.StoredProcedure
                        cmd.Parameters.AddWithValue("@Id", mid)
                        Using rd = cmd.ExecuteReader()
                            If rd.Read() AndAlso Not IsDBNull(rd("RawMessage")) Then raw = CType(rd("RawMessage"), Byte())
                        End Using
                    End Using
                End Using
                If raw IsNot Nothing Then
                    Dim atts = clsMime.ExtractAttachments(raw)
                    If ix >= 0 AndAlso ix < atts.Count Then
                        content = atts(ix).Content
                        fileName = If(String.IsNullOrEmpty(atts(ix).FileName), "piece-jointe", atts(ix).FileName)
                        contentType = If(String.IsNullOrEmpty(atts(ix).ContentType), "application/octet-stream", atts(ix).ContentType)
                    End If
                End If
            End If
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
