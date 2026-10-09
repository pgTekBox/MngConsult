Imports System.Data.SqlClient
Imports System.Web
Imports System.Web.Script.Serialization
Imports System.Web.SessionState

''' <summary>
''' L'avancement d'une extraction QuickBooks, en JSON, pour l'écran qui la
''' suit pendant qu'elle tourne en arrière-plan. L'extraction demandée doit
''' être celle de la compagnie de la session : s0895 ne rend rien sinon.
'''
'''   GET ApideckEtat.ashx?run=N   → { statut, debut, fin, demandees, lues,
'''                                    reussies, echecs, total, note,
'''                                    signe, progression, lignes: [...] }
''' </summary>
Public Class ApideckEtatHandler
    Implements IHttpHandler, IReadOnlySessionState

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json; charset=utf-8"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)

        Dim userId As Integer = 0
        Dim company As Guid = Guid.Empty
        Try
            If context.Session("UserId") IsNot Nothing Then userId = Convert.ToInt32(context.Session("UserId"))
            If context.Session("Company") IsNot Nothing Then company = CType(context.Session("Company"), Guid)
        Catch
        End Try

        Dim js As New JavaScriptSerializer()

        If userId = 0 OrElse company = Guid.Empty Then
            context.Response.StatusCode = 401
            context.Response.Write(js.Serialize(New With {.erreur = "Session expirée : reconnectez-vous."}))
            Return
        End If

        Dim runId As Integer = 0
        Integer.TryParse(context.Request.QueryString("run"), runId)

        Try
            Dim hote As New ApideckExtraction.HoteFond(company, userId)
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", company))
            p.Add(New SqlParameter("@RunId", If(runId > 0, CObj(runId), CObj(DBNull.Value))))
            Dim ds As DataSet = hote.ExecuteSQLds("s0895GetConnecteurRun", p)

            If ds Is Nothing OrElse ds.Tables.Count < 2 OrElse ds.Tables(0).Rows.Count = 0 Then
                context.Response.StatusCode = 404
                context.Response.Write(js.Serialize(New With {.erreur = "Extraction introuvable."}))
                Return
            End If

            Dim r As DataRow = ds.Tables(0).Rows(0)
            Dim lignes As New List(Of Object)
            Dim reussies As Integer = 0, echecs As Integer = 0, total As Integer = 0

            For Each l As DataRow In ds.Tables(1).Rows
                Dim cle As String = Convert.ToString(l("Ressource"))
                Dim ok As Boolean = Convert.ToBoolean(l("Reussie"))
                Dim nb As Integer = Convert.ToInt32(l("Nb"))
                Dim ressource As ApideckExtraction.Ressource = ApideckExtraction.Trouver(cle)

                If ok Then reussies += 1 : total += nb Else echecs += 1

                lignes.Add(New With {
                    .cle = cle,
                    .libelle = If(ressource IsNot Nothing, ressource.Libelle, cle),
                    .nb = nb,
                    .reussie = ok,
                    .erreur = If(IsDBNull(l("Erreur")), "", Convert.ToString(l("Erreur")))
                })
            Next

            Dim demandees As Integer = If(IsDBNull(r("NbDemandees")), ApideckExtraction.Catalogue.Count, Convert.ToInt32(r("NbDemandees")))

            context.Response.Write(js.Serialize(New With {
                .run = Convert.ToInt32(r("Id")),
                .statut = Convert.ToString(r("Statut")),
                .debut = Convert.ToDateTime(r("Debut")).ToString("yyyy-MM-dd HH:mm"),
                .fin = If(IsDBNull(r("Fin")), "", Convert.ToDateTime(r("Fin")).ToString("yyyy-MM-dd HH:mm")),
                .demandees = demandees,
                .lues = reussies + echecs,
                .reussies = reussies,
                .echecs = echecs,
                .total = total,
                .note = If(IsDBNull(r("Note")), "", Convert.ToString(r("Note"))),
                .signe = If(IsDBNull(r("Signe")), "", Convert.ToDateTime(r("Signe")).ToString("HH:mm:ss")),
                .progression = If(IsDBNull(r("Progression")), "", Convert.ToString(r("Progression"))),
                .lignes = lignes
            }))

        Catch ex As Exception
            context.Response.StatusCode = 500
            context.Response.Write(js.Serialize(New With {.erreur = ex.Message}))
        End Try
    End Sub

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return True
        End Get
    End Property
End Class
