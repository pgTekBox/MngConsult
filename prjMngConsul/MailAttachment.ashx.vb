Imports System
Imports System.Web
Imports System.Web.SessionState
Imports System.Data
Imports System.Data.SqlClient
Imports System.Configuration

''' <summary>
''' Télécharge une pièce jointe d'un courriel ENTRANT de la boîte @60sec.ca de la
''' compagnie courante (webmail wbfMailbox de l'application 60sec).
'''   ?mid=&lt;Id du message entrant&gt;&amp;ix=&lt;index de la pièce jointe&gt;
''' Sécurité : la compagnie vient de Session("Company") ; le message n'est lu que
''' via s0617GetInboxForAddress scopé sur l'adresse de la compagnie → impossible de
''' télécharger la PJ d'une autre compagnie.
''' </summary>
Public Class MailAttachmentHandler
    Implements IHttpHandler, IRequiresSessionState

    Public Sub ProcessRequest(ByVal ctx As HttpContext) Implements IHttpHandler.ProcessRequest

        ' --- Compagnie courante (session) ---
        Dim company As Guid = Guid.Empty
        If ctx.Session IsNot Nothing AndAlso ctx.Session("Company") IsNot Nothing Then
            Guid.TryParse(ctx.Session("Company").ToString(), company)
        End If
        If company = Guid.Empty Then
            ctx.Response.StatusCode = 403 : Return
        End If

        Dim csMain As String = ConfigurationManager.AppSettings("ConnectionString")
        Dim csMail As String = ConfigurationManager.AppSettings("ConnectionStringMail")

        ' --- Adresse @60sec.ca de la compagnie ---
        Dim addr As String = ""
        Using cn As New SqlConnection(csMain)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0713GetCompanyMailbox", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", company)
                Dim o = cmd.ExecuteScalar()
                If o IsNot Nothing AndAlso o IsNot DBNull.Value Then addr = o.ToString()
            End Using
        End Using
        If addr = "" Then
            ctx.Response.StatusCode = 404 : Return
        End If

        ' --- Paramètres ---
        Dim mid As Long = 0 : Long.TryParse(ctx.Request("mid"), mid)
        Dim ix As Integer = 0 : Integer.TryParse(ctx.Request("ix"), ix)

        ' --- MIME brut du message (scopé sur l'adresse de la compagnie) ---
        Dim raw As Byte() = Nothing
        Using cn As New SqlConnection(csMail)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0617GetInboxForAddress", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@Id", mid)
                cmd.Parameters.AddWithValue("@Addr", addr)
                Using rd = cmd.ExecuteReader()
                    If rd.Read() Then
                        Dim i As Integer = rd.GetOrdinal("RawMessage")
                        If Not rd.IsDBNull(i) Then raw = CType(rd(i), Byte())
                    End If
                End Using
            End Using
        End Using
        If raw Is Nothing Then
            ctx.Response.StatusCode = 404 : Return
        End If

        ' --- Extraction et envoi de la Nième pièce jointe ---
        Dim atts = clsMime.ExtractAttachments(raw)
        If ix < 0 OrElse ix >= atts.Count Then
            ctx.Response.StatusCode = 404 : Return
        End If

        Dim att = atts(ix)
        Dim fn As String = If(String.IsNullOrEmpty(att.FileName), "piece-jointe", att.FileName)
        fn = fn.Replace(ChrW(34), "'").Replace(vbCr, "").Replace(vbLf, "")
        Dim ctVal As String = If(String.IsNullOrEmpty(att.ContentType), "application/octet-stream", att.ContentType)

        ctx.Response.Clear()
        ctx.Response.ContentType = ctVal
        ctx.Response.AddHeader("Content-Disposition", "attachment; filename=""" & fn & """")
        ctx.Response.BinaryWrite(att.Content)
        ctx.Response.End()
    End Sub

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
