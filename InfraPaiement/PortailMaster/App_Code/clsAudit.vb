Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Journal d'audit des actions sensibles (T070AuditLog). Helper partagé,
''' appelable depuis les pages (héritant de clsData) comme depuis les
''' handlers (.ashx). L'échec d'écriture d'audit est journalisé mais ne fait
''' pas échouer l'action métier (best-effort).
''' </summary>
Public Class clsAudit

    ''' <summary>Enregistre une action sensible.</summary>
    ''' <param name="action">Export / Offboard / Reactivate / Anonymize / ...</param>
    Public Shared Sub Write(actorAdminId As Integer, actorEmail As String, action As String,
                            targetType As String, targetId As Integer, targetName As String,
                            Optional details As String = Nothing, Optional ipAddress As String = Nothing)
        Try
            Dim cs As String = System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
            Using conn As New SqlConnection(cs)
                Using cmd As New SqlCommand("s0092WriteAuditLog", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@ActorAdminId", If(actorAdminId = 0, CObj(DBNull.Value), actorAdminId))
                    cmd.Parameters.AddWithValue("@ActorEmail", NzOrNull(actorEmail))
                    cmd.Parameters.AddWithValue("@Action", action)
                    cmd.Parameters.AddWithValue("@TargetType", NzOrNull(targetType))
                    cmd.Parameters.AddWithValue("@TargetId", If(targetId = 0, CObj(DBNull.Value), targetId))
                    cmd.Parameters.AddWithValue("@TargetName", NzOrNull(targetName))
                    cmd.Parameters.AddWithValue("@Details", NzOrNull(details))
                    cmd.Parameters.AddWithValue("@IpAddress", NzOrNull(ipAddress))
                    conn.Open()
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            ' Best-effort : ne pas casser l'action métier si l'audit échoue.
            System.Diagnostics.Debug.WriteLine("Audit.Write(" & action & "): " & ex.Message)
        End Try
    End Sub

    Private Shared Function NzOrNull(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

End Class
