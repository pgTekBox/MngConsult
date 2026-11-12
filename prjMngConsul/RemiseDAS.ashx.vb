Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Web
Imports System.Web.SessionState
Imports System.Web.Script.Serialization

''' <summary>
''' « Marquer comme remise » de l'activité « Remise des retenues à la source »
''' du tableau de bord (ACT_DAS, script T377). Session authentifiée (UserId) et
''' compagnie de session obligatoires.
''' POST application/json { debut: "aaaa-mm-jj", montant?, reference? }
''' → s0996MarquerRemiseDAS → { ok } ou { ok:false, erreur }.
''' </summary>
Public Class RemiseDASHandler
    Implements IHttpHandler, IRequiresSessionState

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

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
            Repondre(context, js, 403, New With {.ok = False, .erreur = "403"})
            Return
        End If
        If context.Request.HttpMethod.ToUpperInvariant() <> "POST" OrElse context.Request.ContentLength > 5000 Then
            Repondre(context, js, 400, New With {.ok = False, .erreur = "400"})
            Return
        End If

        Dim debut As Date, montant As Decimal = 0D, reference As String = ""
        Try
            Dim brut As String
            Using lecteur As New StreamReader(context.Request.InputStream, Encoding.UTF8)
                brut = lecteur.ReadToEnd()
            End Using
            Dim d As Dictionary(Of String, Object) = TryCast(js.DeserializeObject(brut), Dictionary(Of String, Object))
            If d Is Nothing OrElse Not d.ContainsKey("debut") OrElse
               Not Date.TryParseExact(Convert.ToString(d("debut")), "yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, debut) Then
                Repondre(context, js, 400, New With {.ok = False, .erreur = "debut"})
                Return
            End If
            If d.ContainsKey("montant") AndAlso d("montant") IsNot Nothing Then
                Decimal.TryParse(Convert.ToString(d("montant"), System.Globalization.CultureInfo.InvariantCulture).Replace(",", "."),
                                 System.Globalization.NumberStyles.Number, System.Globalization.CultureInfo.InvariantCulture, montant)
            End If
            If d.ContainsKey("reference") AndAlso d("reference") IsNot Nothing Then reference = Convert.ToString(d("reference")).Trim()
        Catch
            Repondre(context, js, 400, New With {.ok = False, .erreur = "json"})
            Return
        End Try

        Try
            Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand("s0996MarquerRemiseDAS", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.Add(New SqlParameter("@CompanyGUID", company))
                    cmd.Parameters.Add(New SqlParameter("@DebutPeriode", debut))
                    cmd.Parameters.Add(New SqlParameter("@Montant", If(montant > 0D, CObj(montant), DBNull.Value)))
                    cmd.Parameters.Add(New SqlParameter("@Reference", If(reference = "", CObj(DBNull.Value), reference)))
                    cmd.Parameters.Add(New SqlParameter("@UserId", userId))
                    conn.Open()
                    cmd.ExecuteNonQuery()
                End Using
            End Using
            Repondre(context, js, 200, New With {.ok = True})
        Catch ex As SqlException
            Repondre(context, js, 200, New With {.ok = False, .erreur = ex.Message})
        End Try
    End Sub

    Private Shared Sub Repondre(context As HttpContext, js As JavaScriptSerializer, statut As Integer, corps As Object)
        context.Response.StatusCode = statut
        context.Response.Write(js.Serialize(corps))
    End Sub
End Class
