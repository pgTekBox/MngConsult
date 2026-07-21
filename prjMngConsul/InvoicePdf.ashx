<%@ WebHandler Language="VB" Class="InvoicePdfHandler" %>

Imports System
Imports System.Web
Imports System.Data
Imports System.Data.SqlClient

' Sert le PDF d'une facture client par DocumentGUID (?g=...).
' Genere le PDF a la demande (et le stocke) s'il n'existe pas encore :
' couvre les anciennes factures et celles importees de Square, en plus
' de la generation faite a la sauvegarde.
' Ce handler est compile au runtime : il peut donc referencer le type
' MngConsul.clsGenerateInvoicePDF de l'assembly principal (contrairement
' au code de App_Code).
Public Class InvoicePdfHandler
    Implements IHttpHandler

    Public Sub ProcessRequest(ByVal ctx As HttpContext) Implements IHttpHandler.ProcessRequest
        Dim g As String = ctx.Request.QueryString("g")
        Dim guid As Guid
        If String.IsNullOrEmpty(g) OrElse Not Guid.TryParse(g, guid) Then
            ctx.Response.StatusCode = 400
            Return
        End If

        Dim gen As New MngConsul.clsGenerateInvoicePDF()

        Dim p As New Collection
        p.Add(New SqlParameter("@imageGUID", guid))
        Dim ds As DataSet = gen.ExecuteSQLds("s0255GetInvoice", p)
        If ds Is Nothing OrElse ds.Tables(0).Rows.Count = 0 Then
            ctx.Response.StatusCode = 404
            Return
        End If

        Dim row As DataRow = ds.Tables(0).Rows(0)

        ' Generation a la demande si le PDF n'existe pas encore.
        If IsDBNull(row("PdfData")) Then
            gen.GenerateAndDownloadPdf(CInt(row("Id")))
            Dim p2 As New Collection
            p2.Add(New SqlParameter("@imageGUID", guid))
            ds = gen.ExecuteSQLds("s0255GetInvoice", p2)
            If ds Is Nothing OrElse ds.Tables(0).Rows.Count = 0 Then
                ctx.Response.StatusCode = 404
                Return
            End If
            row = ds.Tables(0).Rows(0)
        End If

        If IsDBNull(row("PdfData")) Then
            ctx.Response.StatusCode = 404
            Return
        End If

        ctx.Response.ContentType = row("PDFContentType").ToString()
        ctx.Response.AppendHeader("content-disposition", "inline; filename=" & row("PDFFileName").ToString())
        ctx.Response.BinaryWrite(CType(row("PdfData"), Byte()))
        ctx.Response.End()
    End Sub

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
