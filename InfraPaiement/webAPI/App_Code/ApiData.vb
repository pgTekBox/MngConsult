Imports System.Data
Imports System.Data.SqlClient
Imports System.Security.Cryptography
Imports System.Text

''' <summary>
''' Accès base de données pour l'API 60secPaiement.
''' Réutilise les mêmes procédures stockées (sNNNN) et la même base
''' 60secPaiement que le portail. Aucune requête SQL en ligne.
''' </summary>
Public Class ApiData

    Private Shared m_ConnectionString As String = ""

    Public Shared ReadOnly Property ConnectionString() As String
        Get
            If m_ConnectionString.Length = 0 Then
                m_ConnectionString = System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
            End If
            Return m_ConnectionString
        End Get
    End Property

    ''' <summary>Exécute une procédure stockée (sans résultat).</summary>
    Public Shared Sub ExecuteSQL(proc As String, params As Collection)
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand(proc, conn)
                cmd.CommandType = CommandType.StoredProcedure
                For Each p As SqlParameter In params
                    cmd.Parameters.Add(p)
                Next
                conn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    ''' <summary>Exécute une procédure stockée et retourne un DataTable.</summary>
    Public Shared Function ExecuteSQLdt(proc As String, params As Collection) As DataTable
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand(proc, conn)
                cmd.CommandType = CommandType.StoredProcedure
                For Each p As SqlParameter In params
                    cmd.Parameters.Add(p)
                Next
                Dim da As New SqlDataAdapter(cmd)
                Dim dt As New DataTable()
                da.Fill(dt)
                Return dt
            End Using
        End Using
    End Function

    ''' <summary>Hash SHA-256 (hex minuscule) d'une chaîne — pour les clés d'API.</summary>
    Public Shared Function Sha256Hex(value As String) As String
        Using sha As SHA256 = SHA256.Create()
            Dim bytes As Byte() = sha.ComputeHash(Encoding.UTF8.GetBytes(If(value, "")))
            Dim sb As New StringBuilder(bytes.Length * 2)
            For Each b As Byte In bytes
                sb.Append(b.ToString("x2"))
            Next
            Return sb.ToString()
        End Using
    End Function

    ''' <summary>
    ''' Résout une clé d'API en clair vers l'abonné propriétaire (si active).
    ''' Retourne l'AbonneId, ou 0 si la clé est invalide/révoquée.
    ''' Met à jour LastUsed via la procédure.
    ''' </summary>
    Public Shared Function ResolveApiKey(rawKey As String, ByRef env As String, ByRef apiKeyId As Integer) As Integer
        env = ""
        apiKeyId = 0
        If String.IsNullOrEmpty(rawKey) Then Return 0
        Dim p As New Collection
        p.Add(New SqlParameter("@KeyHash", Sha256Hex(rawKey.Trim())))
        Dim dt As DataTable = ExecuteSQLdt("s0027ResolveApiKey", p)
        If dt.Rows.Count = 0 Then Return 0
        env = dt.Rows(0)("Environment").ToString()
        apiKeyId = CInt(dt.Rows(0)("ApiKeyId"))
        Return CInt(dt.Rows(0)("AbonneId"))
    End Function

    ''' <summary>
    ''' Résout une clé d'API en clair vers son porteur : soit un abonné
    ''' (clé "sk_…"), soit un partenaire (clé "pk_…", Modèle B). Retourne
    ''' Nothing si la clé est absente/invalide/révoquée.
    ''' </summary>
    Public Shared Function ResolvePrincipal(rawKey As String) As ApiPrincipal
        If String.IsNullOrEmpty(rawKey) Then Return Nothing
        Dim p As New Collection
        p.Add(New SqlParameter("@KeyHash", Sha256Hex(rawKey.Trim())))
        Dim dt As DataTable = ExecuteSQLdt("s0027ResolveApiKey", p)
        If dt.Rows.Count = 0 Then Return Nothing
        Dim r As DataRow = dt.Rows(0)
        Dim pr As New ApiPrincipal()
        pr.ApiKeyId = CInt(r("ApiKeyId"))
        pr.AbonneId = If(IsDBNull(r("AbonneId")), 0, CInt(r("AbonneId")))
        pr.PartenaireId = If(r.Table.Columns.Contains("PartenaireId") AndAlso Not IsDBNull(r("PartenaireId")), CInt(r("PartenaireId")), 0)
        pr.Environment = r("Environment").ToString()
        Return pr
    End Function

End Class

''' <summary>
''' Porteur d'une clé d'API : un abonné (AbonneId) OU un partenaire
''' (PartenaireId). IsPartner distingue les deux.
''' </summary>
Public Class ApiPrincipal
    Public AbonneId As Integer
    Public PartenaireId As Integer
    Public Environment As String = ""
    Public ApiKeyId As Integer
    Public ReadOnly Property IsPartner As Boolean
        Get
            Return PartenaireId > 0
        End Get
    End Property
End Class
