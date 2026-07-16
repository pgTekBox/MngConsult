Imports System
Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Web

''' <summary>
''' Handler PUBLIC : sert le logo d'une compagnie (T010Company.Logo) par CompanyGUID.
''' URL : /CompanyLogo.ashx?c={CompanyGUID}
''' Utilisé par la page de remerciement Square (merci.aspx) — donc AUCUNE authentification
''' (c'est le navigateur du client payeur qui charge l'image).
''' 404 si aucun logo → merci.aspx retombe alors sur le monogramme (initiale).
''' Accès BD direct (un .ashx n'hérite pas de Page/clsData), via s0690GetCompanyLogo.
''' </summary>
Public Class CompanyLogo
    Implements IHttpHandler

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        Dim raw As String = If(context.Request.QueryString("c"), "").Trim()
        Dim g As Guid
        If Not Guid.TryParse(raw, g) Then
            context.Response.StatusCode = 400
            Return
        End If

        Dim bytes As Byte() = Nothing
        Dim contentType As String = "image/png"
        Try
            Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand("s0690GetCompanyLogo", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@CompanyGUID", g)
                    conn.Open()
                    Using rd As SqlDataReader = cmd.ExecuteReader()
                        If rd.Read() Then
                            If Not rd.IsDBNull(0) Then bytes = CType(rd(0), Byte())
                            If Not rd.IsDBNull(1) AndAlso Not String.IsNullOrEmpty(rd(1).ToString()) Then
                                contentType = rd(1).ToString()
                            End If
                        End If
                    End Using
                End Using
            End Using
        Catch
            context.Response.StatusCode = 500
            Return
        End Try

        If bytes Is Nothing OrElse bytes.Length = 0 Then
            context.Response.StatusCode = 404
            Return
        End If

        context.Response.ContentType = contentType
        context.Response.Cache.SetCacheability(HttpCacheability.Public)
        context.Response.Cache.SetMaxAge(TimeSpan.FromHours(1))
        context.Response.OutputStream.Write(bytes, 0, bytes.Length)
    End Sub
End Class
