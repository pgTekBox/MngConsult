<%@ WebHandler Language="VB" Class="InvoicePhotoHandler" %>

Imports System
Imports System.Web
Imports System.Web.SessionState
Imports System.Data
Imports System.Data.SqlClient

' Sert une photo de facture (T063DocumentPhoto) prise par l'app mobile 60SecAI.
' Appele depuis la grille des factures clients : InvoicePhoto.ashx?d=<DocId>&p=<PhotoId>
'
' Contrairement a InvoicePdf.ashx (public, adresse par GUID car les liens partent
' par courriel), ce handler est INTERNE : il exige une session authentifiee et
' filtre sur la compagnie de la session via s0728GetInvoicePhotoContent. Sans ce
' filtre, un utilisateur connecte pourrait lire les photos d'une autre compagnie
' en devinant un DocumentId.
'
' Ce handler est compile au runtime : il peut referencer les types de l'assembly
' principal (MngConsul.clsGenerateInvoicePDF sert ici d'acces BD, meme astuce que
' InvoicePdf.ashx).
Public Class InvoicePhotoHandler
    Implements IHttpHandler
    Implements IRequiresSessionState

    Public Sub ProcessRequest(ByVal ctx As HttpContext) Implements IHttpHandler.ProcessRequest

        ' --- Session authentifiee ? (meme convention que clsData : Session("Company")) ---
        If ctx.Session Is Nothing OrElse ctx.Session("Company") Is Nothing Then
            ctx.Response.StatusCode = 401
            Return
        End If
        Dim company As Guid
        If Not Guid.TryParse(ctx.Session("Company").ToString(), company) OrElse company = Guid.Empty Then
            ctx.Response.StatusCode = 401
            Return
        End If

        ' --- Parametres ---
        Dim docId As Integer, photoId As Integer
        If Not Integer.TryParse(ctx.Request.QueryString("d"), docId) OrElse docId <= 0 _
           OrElse Not Integer.TryParse(ctx.Request.QueryString("p"), photoId) OrElse photoId <= 0 Then
            ctx.Response.StatusCode = 400
            Return
        End If

        ' --- Lecture scopee compagnie ---
        Dim db As New MngConsul.clsGenerateInvoicePDF()
        Dim prm As New Collection
        prm.Add(New SqlParameter("@CompanyGUID", company))
        prm.Add(New SqlParameter("@DocumentId", docId))
        prm.Add(New SqlParameter("@PhotoId", photoId))

        Dim ds As DataSet = db.ExecuteSQLds("s0728GetInvoicePhotoContent", prm)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ' Inexistante OU appartenant a une autre compagnie : meme reponse,
            ' pour ne pas reveler l'existence de la ressource.
            ctx.Response.StatusCode = 404
            Return
        End If

        Dim row As DataRow = ds.Tables(0).Rows(0)
        If IsDBNull(row("ImageSource")) Then
            ctx.Response.StatusCode = 404
            Return
        End If

        Dim ct As String = If(IsDBNull(row("ContentType")), "", row("ContentType").ToString().Trim())
        If ct = "" Then ct = "image/jpeg"

        ctx.Response.ContentType = ct
        ' Cache prive : la photo ne change jamais (blob immuable), mais elle ne doit
        ' pas etre mise en cache par un proxy partage.
        ctx.Response.Cache.SetCacheability(HttpCacheability.Private)
        ctx.Response.Cache.SetMaxAge(TimeSpan.FromHours(1))
        ctx.Response.BinaryWrite(CType(row("ImageSource"), Byte()))
        ctx.Response.End()
    End Sub

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
