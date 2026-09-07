Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Accès aux données pour l'exécution des tâches.
'''
''' clsData hérite de System.Web.UI.Page : inutilisable depuis un handler, qui
''' n'est pas une page. D'où cette classe, qui offre les mêmes appels — et la
''' même règle : uniquement des procédures stockées, jamais de SQL en dur.
'''
''' Deux bases, comme partout dans l'écosystème : MngConsul porte les tâches et
''' les données métier, MailService porte la file d'envoi (T400Mails) que SrvAI
''' vide.
''' </summary>
Public Class clsJobData

    Public Shared ReadOnly Property ConnectionString As String
        Get
            Return ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    Public Shared ReadOnly Property ConnectionStringMail As String
        Get
            Return ConfigurationManager.AppSettings("ConnectionStringMail")
        End Get
    End Property

#Region "Exécution"

    Public Shared Function ExecuteSQLds(procName As String,
                                        Optional parametres As Collection = Nothing,
                                        Optional timeoutSeconds As Integer = 120) As DataSet
        Return Exec(ConnectionString, procName, parametres, timeoutSeconds)
    End Function

    Public Shared Function ExecuteSQLdsMail(procName As String,
                                            Optional parametres As Collection = Nothing,
                                            Optional timeoutSeconds As Integer = 120) As DataSet
        Return Exec(ConnectionStringMail, procName, parametres, timeoutSeconds)
    End Function

    Public Shared Function ExecuteSQL(procName As String,
                                      Optional parametres As Collection = Nothing,
                                      Optional timeoutSeconds As Integer = 120) As Integer
        Using cnn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand(procName, cnn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.CommandTimeout = timeoutSeconds
                AjouterParametres(cmd, parametres)
                cnn.Open()
                Return cmd.ExecuteNonQuery()
            End Using
        End Using
    End Function

    ''' <summary>
    ''' Lance une procédure métier dont on ne connaît pas la signature.
    ''' DeriveParameters demande au serveur ce qu'elle attend : on ne passe que
    ''' les paramètres qu'elle accepte, et @CompanyGUID est comblé par la
    ''' compagnie de la tâche quand le JSON ne le fournit pas. Une définition de
    ''' tâche peut ainsi pointer vers n'importe quelle procédure existante sans
    ''' qu'on l'adapte.
    ''' </summary>
    Public Shared Function ExecuteProcedureLibre(procName As String,
                                                 companyGuid As Guid,
                                                 parametres As Dictionary(Of String, Object),
                                                 timeoutSeconds As Integer) As Integer

        Using cnn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand(procName, cnn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.CommandTimeout = If(timeoutSeconds > 0, timeoutSeconds, 300)

                cnn.Open()
                SqlCommandBuilder.DeriveParameters(cmd)

                For Each p As SqlParameter In cmd.Parameters
                    If p.Direction = ParameterDirection.ReturnValue Then Continue For

                    Dim nom As String = p.ParameterName.TrimStart("@"c)
                    Dim valeur As Object = Nothing

                    If parametres IsNot Nothing Then
                        For Each kv As KeyValuePair(Of String, Object) In parametres
                            If String.Equals(kv.Key.TrimStart("@"c), nom, StringComparison.OrdinalIgnoreCase) Then
                                valeur = kv.Value
                                Exit For
                            End If
                        Next
                    End If

                    If valeur Is Nothing AndAlso
                       String.Equals(nom, "CompanyGUID", StringComparison.OrdinalIgnoreCase) AndAlso
                       companyGuid <> Guid.Empty Then
                        valeur = companyGuid
                    End If

                    p.Value = If(valeur, DBNull.Value)
                Next

                Return cmd.ExecuteNonQuery()
            End Using
        End Using
    End Function

    Private Shared Function Exec(connectionString As String,
                                 procName As String,
                                 parametres As Collection,
                                 timeoutSeconds As Integer) As DataSet
        Using cnn As New SqlConnection(connectionString)
            Using cmd As New SqlCommand(procName, cnn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.CommandTimeout = timeoutSeconds
                AjouterParametres(cmd, parametres)

                Dim ds As New DataSet()
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(ds)
                End Using
                Return ds
            End Using
        End Using
    End Function

    Private Shared Sub AjouterParametres(cmd As SqlCommand, parametres As Collection)
        If parametres Is Nothing Then Return
        For Each p As SqlParameter In parametres
            cmd.Parameters.Add(p)
        Next
    End Sub

#End Region

#Region "Lecture"

    Public Shared Function P(name As String, value As Object) As SqlParameter
        Return New SqlParameter(name, If(value, DBNull.Value))
    End Function

    Public Shared Function Str(row As DataRow, col As String) As String
        If row Is Nothing OrElse Not row.Table.Columns.Contains(col) Then Return ""
        If IsDBNull(row(col)) Then Return ""
        Return Convert.ToString(row(col)).Trim()
    End Function

    Public Shared Function Num(row As DataRow, col As String) As Integer
        If row Is Nothing OrElse Not row.Table.Columns.Contains(col) Then Return 0
        If IsDBNull(row(col)) Then Return 0
        Return Convert.ToInt32(row(col))
    End Function

    Public Shared Function Dec(row As DataRow, col As String) As Decimal
        If row Is Nothing OrElse Not row.Table.Columns.Contains(col) Then Return 0D
        If IsDBNull(row(col)) Then Return 0D
        Return Convert.ToDecimal(row(col))
    End Function

    Public Shared Function FirstRow(ds As DataSet) As DataRow
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return Nothing
        Return ds.Tables(0).Rows(0)
    End Function

#End Region

End Class
