Imports System.Web
Imports System.Web.SessionState
Imports System.Data
Imports System.Data.SqlClient
Imports System.Collections.Generic
Imports System.Web.Script.Serialization

''' <summary>
''' Export des données d'un abonné (?abonneId=N) au format JSON (portabilité
''' RGPD art. 20). Réservé au staff connecté (session). Rassemble les jeux de
''' résultats de s0091ExportAbonneData et les sérialise en un document JSON
''' téléchargeable. Aucun secret (hash mot de passe, hash clé d'API, secret
''' webhook) n'est inclus.
''' </summary>
Public Class AbonneExport
    Implements IHttpHandler, IRequiresSessionState

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        Dim ctx As HttpContext = context

        ' Authentification (session staff).
        Dim adminId As Integer = 0
        If ctx.Session IsNot Nothing AndAlso ctx.Session("AdminId") IsNot Nothing Then adminId = CInt(ctx.Session("AdminId"))
        If adminId = 0 Then
            ctx.Response.StatusCode = 403
            ctx.Response.Write("Non autorisé.")
            Return
        End If

        Dim abonneId As Integer
        If Not Integer.TryParse(ctx.Request.QueryString("abonneId"), abonneId) OrElse abonneId <= 0 Then
            ctx.Response.StatusCode = 400
            ctx.Response.Write("abonneId requis.")
            Return
        End If

        Try
            Dim ds As DataSet = LoadExport(abonneId)

            ' Abonné introuvable -> 404.
            If ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ctx.Response.StatusCode = 404
                ctx.Response.Write("Abonné introuvable.")
                Return
            End If

            ' Audit de l'export (traçabilité RGPD).
            Dim abonneNom As String = If(IsDBNull(ds.Tables(0).Rows(0)("RaisonSociale")), "", ds.Tables(0).Rows(0)("RaisonSociale").ToString())
            Dim actorEmail As String = If(ctx.Session("AdminEmail") Is Nothing, "", ctx.Session("AdminEmail").ToString())
            clsAudit.Write(adminId, actorEmail, "Export", "Abonne", abonneId, abonneNom, Nothing, ctx.Request.UserHostAddress)

            Dim root As New Dictionary(Of String, Object)
            root("exportedUtc") = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss") & "Z"
            root("exportedByAdminId") = adminId
            root("abonneId") = abonneId
            root("format") = "60secPaiement/abonne-export/v1"
            root("abonne") = FirstRow(ds, 0)
            root("utilisateurs") = TableToList(ds, 1)
            root("clients") = TableToList(ds, 2)
            root("fournisseurs") = TableToList(ds, 3)
            root("paiements") = TableToList(ds, 4)
            root("journal") = TableToList(ds, 5)
            root("clesApi") = TableToList(ds, 6)
            root("webhook") = FirstRow(ds, 7)
            root("retoursEft") = TableToList(ds, 8)

            Dim js As New JavaScriptSerializer()
            js.MaxJsonLength = Integer.MaxValue
            Dim json As String = js.Serialize(root)

            Dim fileName As String = "abonne_" & abonneId & "_export_" & DateTime.UtcNow.ToString("yyyyMMdd_HHmmss") & ".json"
            ctx.Response.ContentType = "application/json; charset=utf-8"
            ctx.Response.AddHeader("Content-Disposition", "attachment; filename=""" & fileName & """")
            ctx.Response.Write(json)
        Catch ex As Exception
            ctx.Response.StatusCode = 500
            ctx.Response.Write("Erreur d'export.")
            System.Diagnostics.Debug.WriteLine("AbonneExport: " & ex.ToString())
        End Try
    End Sub

    Private Function LoadExport(abonneId As Integer) As DataSet
        Dim cs As String = System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
        Using conn As New SqlConnection(cs)
            Using cmd As New SqlCommand("s0091ExportAbonneData", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@AbonneId", abonneId)
                Dim da As New SqlDataAdapter(cmd)
                Dim ds As New DataSet()
                da.Fill(ds)
                Return ds
            End Using
        End Using
    End Function

    ''' <summary>Première ligne d'une table -> dictionnaire (ou Nothing si vide).</summary>
    Private Function FirstRow(ds As DataSet, tableIndex As Integer) As Object
        If ds.Tables.Count <= tableIndex OrElse ds.Tables(tableIndex).Rows.Count = 0 Then Return Nothing
        Return RowToDict(ds.Tables(tableIndex), ds.Tables(tableIndex).Rows(0))
    End Function

    ''' <summary>Table -> liste de dictionnaires (liste vide si absente).</summary>
    Private Function TableToList(ds As DataSet, tableIndex As Integer) As List(Of Object)
        Dim list As New List(Of Object)
        If ds.Tables.Count <= tableIndex Then Return list
        Dim t As DataTable = ds.Tables(tableIndex)
        For Each row As DataRow In t.Rows
            list.Add(RowToDict(t, row))
        Next
        Return list
    End Function

    ''' <summary>Ligne -> dictionnaire colonne→valeur. Dates en ISO 8601 ;
    ''' DBNull -> Nothing (null JSON).</summary>
    Private Function RowToDict(t As DataTable, row As DataRow) As Dictionary(Of String, Object)
        Dim d As New Dictionary(Of String, Object)
        For Each col As DataColumn In t.Columns
            Dim v As Object = row(col)
            If v Is Nothing OrElse IsDBNull(v) Then
                d(col.ColumnName) = Nothing
            ElseIf TypeOf v Is DateTime Then
                d(col.ColumnName) = CDate(v).ToString("yyyy-MM-ddTHH:mm:ss")
            ElseIf TypeOf v Is Guid Then
                d(col.ColumnName) = v.ToString()
            Else
                d(col.ColumnName) = v
            End If
        Next
        Return d
    End Function

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
