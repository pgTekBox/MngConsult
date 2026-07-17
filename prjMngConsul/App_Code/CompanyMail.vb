Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Expéditeur des courriels envoyés AU NOM d'une compagnie.
'''
''' Le From reste noreply@60sec.ca (colonne T400Mails.Sender) : SrvAI envoie en
''' direct-to-MX depuis notre IP, donc un From au domaine du client échouerait
''' son SPF/DMARC. C'est le Reply-To qui porte l'adresse de la compagnie, et
''' seulement si elle a été vérifiée (cf. wbfSetting / s0691-s0693).
''' </summary>
Public Class CompanyMail

    ''' <summary>
    ''' Adresse Reply-To de la compagnie, ou "" si non configurée / non vérifiée
    ''' (dans ce cas on n'ajoute simplement pas d'en-tête Reply-To).
    ''' Ne lève jamais : un courriel doit partir même si le Reply-To est indisponible.
    ''' </summary>
    Public Shared Function GetVerifiedReplyTo(connectionString As String, companyGuid As Guid) As String
        If companyGuid = Guid.Empty Then Return ""
        Try
            Using conn As New SqlConnection(connectionString)
                Using cmd As New SqlCommand("s0694GetCompanyReplyTo", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.Add(New SqlParameter("@CompanyGUID", SqlDbType.UniqueIdentifier) With {.Value = companyGuid})
                    conn.Open()
                    Dim o As Object = cmd.ExecuteScalar()
                    If o Is Nothing OrElse Convert.IsDBNull(o) Then Return ""
                    Return o.ToString()
                End Using
            End Using
        Catch
            Return ""
        End Try
    End Function

    ''' <summary>
    ''' Ajoute le paramètre @ReplyTo à la collection destinée à
    ''' s0610InsertOutboundMail : l'adresse vérifiée de la compagnie, ou DBNull.
    ''' </summary>
    Public Shared Sub AddReplyToParam(p As Collection, connectionString As String, companyGuid As Guid)
        Dim replyTo As String = GetVerifiedReplyTo(connectionString, companyGuid)
        p.Add(New SqlParameter("@ReplyTo", If(String.IsNullOrEmpty(replyTo), CType(DBNull.Value, Object), replyTo)))
    End Sub

End Class
