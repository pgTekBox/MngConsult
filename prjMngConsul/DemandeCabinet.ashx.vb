Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Web
Imports System.Web.Script.Serialization
Imports System.Web.SessionState

''' <summary>
''' Flux entrant : une entreprise demande un cabinet depuis l'annuaire
''' (CabinetsCertifies). Toujours la compagnie de la session ; réservé aux
''' administrateurs de la compagnie (comme MonCabinet.ashx).
'''
'''   POST DemandeCabinet.ashx  (corps JSON { cabinetId: N })  → { ok: true } | { erreur, code }
'''   GET  DemandeCabinet.ashx  → { statut: "EnAttente|Acceptee|Refusee"|null, cabinet: "…"|null }
''' </summary>
Public Class DemandeCabinetHandler
    Implements IHttpHandler, IReadOnlySessionState

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json; charset=utf-8"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Dim js As New JavaScriptSerializer()

        Dim userId As Integer = 0
        Dim company As Guid = Guid.Empty
        Try
            If context.Session("UserId") IsNot Nothing Then userId = Convert.ToInt32(context.Session("UserId"))
            If context.Session("Company") IsNot Nothing Then company = CType(context.Session("Company"), Guid)
        Catch
        End Try
        If userId = 0 OrElse company = Guid.Empty Then
            context.Response.StatusCode = 401
            context.Response.Write(js.Serialize(New With {.erreur = "Session expirée : reconnectez-vous."}))
            Return
        End If

        Dim hote As New ApideckExtraction.HoteFond(company, userId)
        Try
            If context.Request.HttpMethod = "POST" Then
                Demander(context, js, hote, company, userId)
            Else
                Statut(context, js, hote, company)
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("DemandeCabinet : " & ex.Message)
            context.Response.StatusCode = 500
            context.Response.Write(js.Serialize(New With {.erreur = "Demande impossible pour l'instant."}))
        End Try
    End Sub

    Private Shared Function EstAdmin(hote As ApideckExtraction.HoteFond, userId As Integer) As Boolean
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", userId))
        Dim ds As DataSet = hote.ExecuteSQLds("s0314GetUserByUserId", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return False
        Dim r As DataRow = ds.Tables(0).Rows(0)
        Return Not IsDBNull(r("IsAdmin")) AndAlso CBool(r("IsAdmin")) AndAlso
               Not IsDBNull(r("IsActive")) AndAlso CBool(r("IsActive"))
    End Function

    Private Sub Demander(context As HttpContext, js As JavaScriptSerializer, hote As ApideckExtraction.HoteFond, company As Guid, userId As Integer)
        If Not EstAdmin(hote, userId) Then
            context.Response.StatusCode = 403
            context.Response.Write(js.Serialize(New With {.erreur = "Seul un administrateur peut demander un cabinet."}))
            Return
        End If

        ' Même origine seulement
        Dim origine As String = context.Request.Headers("Origin")
        If Not String.IsNullOrEmpty(origine) Then
            Dim o As Uri = Nothing
            If Not Uri.TryCreate(origine, UriKind.Absolute, o) OrElse
               Not String.Equals(o.Authority, context.Request.Url.Authority, StringComparison.OrdinalIgnoreCase) Then
                context.Response.StatusCode = 403
                context.Response.Write(js.Serialize(New With {.erreur = "Origine refusée."}))
                Return
            End If
        End If

        Dim corps As String
        Using lecteur As New StreamReader(context.Request.InputStream, Encoding.UTF8)
            corps = lecteur.ReadToEnd()
        End Using
        Dim data As Dictionary(Of String, Object) = Nothing
        Try
            data = js.Deserialize(Of Dictionary(Of String, Object))(corps)
        Catch
        End Try
        Dim cabinetId As Integer = 0
        If data IsNot Nothing AndAlso data.ContainsKey("cabinetId") Then Integer.TryParse(Convert.ToString(data("cabinetId")), cabinetId)
        If cabinetId <= 0 Then
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.erreur = "Cabinet invalide."}))
            Return
        End If

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", company))
        p.Add(New SqlParameter("@CabinetCertifieId", cabinetId))
        p.Add(New SqlParameter("@Message", DBNull.Value))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        hote.ExecuteSQL("s0938CreerDemandeCabinet", p)

        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        If err = 0 Then
            context.Response.Write(js.Serialize(New With {.ok = True}))
        ElseIf err = 1 Then
            context.Response.StatusCode = 409
            context.Response.Write(js.Serialize(New With {.erreur = "Demande déjà en attente.", .code = 1}))
        Else
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.erreur = "Demande impossible.", .code = err}))
        End If
    End Sub

    Private Sub Statut(context As HttpContext, js As JavaScriptSerializer, hote As ApideckExtraction.HoteFond, company As Guid)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", company))
        Dim ds As DataSet = hote.ExecuteSQLds("s0941GetMaDemande", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            context.Response.Write(js.Serialize(New With {.statut = CType(Nothing, String), .cabinet = CType(Nothing, String)}))
            Return
        End If
        Dim r As DataRow = ds.Tables(0).Rows(0)
        context.Response.Write(js.Serialize(New With {.statut = Convert.ToString(r("Statut")), .cabinet = Convert.ToString(r("CabinetNom"))}))
    End Sub

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property
End Class
