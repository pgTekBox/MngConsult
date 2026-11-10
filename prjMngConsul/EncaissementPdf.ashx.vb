Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Web.SessionState

''' <summary>
''' Le reçu PDF d'un encaissement (GET ?id=ReglementId), affiché en ligne pour
''' être imprimé ou enregistré. L'usager doit être authentifié (Session UserId)
''' et l'encaissement appartenir à la compagnie de session (s0988, T369).
''' Le PDF est généré à chaque demande (EncaissementPdfBuilder) : rien n'est stocké.
''' </summary>
Public Class EncaissementPdfHandler
    Implements IHttpHandler, IRequiresSessionState

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        Dim userId As Integer = 0
        Dim company As Guid = Guid.Empty
        Try
            If context.Session("UserId") IsNot Nothing Then userId = Convert.ToInt32(context.Session("UserId"))
            If context.Session("Company") IsNot Nothing Then company = CType(context.Session("Company"), Guid)
        Catch
        End Try
        If userId = 0 OrElse company = Guid.Empty Then
            context.Response.StatusCode = 403
            Return
        End If

        Dim id As Integer
        If Not Integer.TryParse(context.Request.QueryString("id"), id) OrElse id <= 0 Then
            context.Response.StatusCode = 400
            Return
        End If

        Dim ds As New DataSet()
        Try
            Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand("s0988GetEncaissementPdf", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.Add(New SqlParameter("@CompanyGUID", company))
                    cmd.Parameters.Add(New SqlParameter("@ReglementId", id))
                    Using da As New SqlDataAdapter(cmd)
                        da.Fill(ds)
                    End Using
                End Using
            End Using
        Catch ex As SqlException
            context.Response.StatusCode = 404
            Return
        End Try
        If ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            context.Response.StatusCode = 404
            Return
        End If

        Dim lang As String = Convert.ToString(context.Session("Lang"))
        Dim pdf As Byte() = EncaissementPdfBuilder.Build(ds, lang)
        Dim nom As String = EncaissementPdfBuilder.Numero(ds.Tables(0).Rows(0)) & ".pdf"

        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        context.Response.ContentType = "application/pdf"
        context.Response.AppendHeader("Content-Disposition", "inline; filename=" & nom)
        context.Response.BinaryWrite(pdf)
    End Sub
End Class
