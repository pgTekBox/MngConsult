<%@ WebHandler Language="VB" Class="PieceJointeHandler" %>

Imports System
Imports System.Web
Imports System.Web.SessionState
Imports System.Data
Imports System.Data.SqlClient

' Sert un fichier, deux provenances :
'   ?id=N   une pièce jointe encore en préparation (staging.PieceJointeImport) ;
'   ?doc=N  une pièce rattachée à une fiche (dbo.T057PartyDocument).
' La session dit la compagnie : une pièce d'une autre compagnie, ou un visiteur
' sans session, ne reçoivent rien.
'
' Ce handler est compilé au runtime : il peut référencer MngConsul.clsData de
' l'assembly principal, comme InvoicePdf.ashx le fait.
Public Class PieceJointeHandler
    Implements IHttpHandler, IReadOnlySessionState

    Public Sub ProcessRequest(ByVal ctx As HttpContext) Implements IHttpHandler.ProcessRequest
        Dim compagnie As Guid = Guid.Empty
        If ctx.Session IsNot Nothing AndAlso ctx.Session("Company") IsNot Nothing Then
            Guid.TryParse(ctx.Session("Company").ToString(), compagnie)
        End If
        If compagnie = Guid.Empty Then
            ctx.Response.StatusCode = 401
            Return
        End If

        Dim id As Integer
        Dim procedure As String

        If Integer.TryParse(ctx.Request.QueryString("doc"), id) AndAlso id > 0 Then
            procedure = "s0841GetPartyDocumentContenu"
        ElseIf Integer.TryParse(ctx.Request.QueryString("id"), id) AndAlso id > 0 Then
            procedure = "s0838GetPieceJointeContenu"
        Else
            ctx.Response.StatusCode = 400
            Return
        End If

        Dim d As New MngConsul.clsData()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", compagnie))
        p.Add(New SqlParameter("@Id", id))
        Dim ds As DataSet = d.ExecuteSQLds(procedure, p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ctx.Response.StatusCode = 404
            Return
        End If

        Dim row As DataRow = ds.Tables(0).Rows(0)
        If IsDBNull(row("Contenu")) Then
            ctx.Response.StatusCode = 404
            ctx.Response.ContentType = "text/plain; charset=utf-8"
            ctx.Response.Write("Cette pièce n'a pas de fichier.")
            Return
        End If

        Dim octets As Byte() = CType(row("Contenu"), Byte())
        Dim nom As String = If(IsDBNull(row("NomFichier")), "piece-" & id, Convert.ToString(row("NomFichier")))
        Dim type As String = If(IsDBNull(row("TypeContenu")), "", Convert.ToString(row("TypeContenu")))
        If type = "" Then type = "application/octet-stream"

        ' Les images et les PDF s'ouvrent dans l'onglet ; le reste se télécharge.
        Dim enLigne As Boolean = type.StartsWith("image/") OrElse type = "application/pdf"

        ctx.Response.Clear()
        ctx.Response.ContentType = type
        ctx.Response.AddHeader("Content-Disposition",
            If(enLigne, "inline", "attachment") & "; filename*=UTF-8''" & Uri.EscapeDataString(nom))
        ctx.Response.AddHeader("Content-Length", octets.Length.ToString())
        ctx.Response.Cache.SetCacheability(HttpCacheability.Private)
        ctx.Response.BinaryWrite(octets)
        ctx.Response.Flush()
        ctx.ApplicationInstance.CompleteRequest()
    End Sub

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
