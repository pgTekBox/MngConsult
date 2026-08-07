Imports System
Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Classe de base de toutes les pages du PortailABN (portail des abonnes).
''' Fournit :
'''   - l'acces a la base 60secPaiement via procedures stockees (sNNNN) ;
'''   - l'etat d'authentification de l'utilisateur abonne conserve en Session,
'''     y compris l'identifiant du locataire (AbonneId) qui scope TOUTES les
'''     requetes (isolation multi-locataire).
''' Toutes les pages heritent de clsData au lieu de System.Web.UI.Page.
''' </summary>
Public Class clsData
    Inherits System.Web.UI.Page

    ' =====================================================================
    ' Etat de session : utilisateur abonne connecte
    ' =====================================================================

    ''' <summary>Id de l'utilisateur abonne connecte (0 = non connecte).</summary>
    Public Property UserId() As Integer
        Get
            Try
                If Session("AbnUserId") Is Nothing Then Session("AbnUserId") = 0
                Return CInt(Session("AbnUserId"))
            Catch
                Return 0
            End Try
        End Get
        Set(value As Integer)
            Session("AbnUserId") = value
        End Set
    End Property

    ''' <summary>Id du locataire (abonne) auquel l'utilisateur est rattache.
    ''' Scope toutes les operations : un utilisateur ne voit JAMAIS les
    ''' donnees d'un autre abonne.</summary>
    Public Property AbonneId() As Integer
        Get
            Try
                If Session("AbnId") Is Nothing Then Session("AbnId") = 0
                Return CInt(Session("AbnId"))
            Catch
                Return 0
            End Try
        End Get
        Set(value As Integer)
            Session("AbnId") = value
        End Set
    End Property

    ''' <summary>Nom complet de l'utilisateur connecte (pour l'entete).</summary>
    Public Property UserName() As String
        Get
            Return If(TryCast(Session("AbnUserName"), String), "")
        End Get
        Set(value As String)
            Session("AbnUserName") = value
        End Set
    End Property

    ''' <summary>Courriel de l'utilisateur connecte.</summary>
    Public Property UserEmail() As String
        Get
            Return If(TryCast(Session("AbnUserEmail"), String), "")
        End Get
        Set(value As String)
            Session("AbnUserEmail") = value
        End Set
    End Property

    ''' <summary>Raison sociale de l'abonne (affichee dans l'entete).</summary>
    Public Property AbonneName() As String
        Get
            Return If(TryCast(Session("AbnName"), String), "")
        End Get
        Set(value As String)
            Session("AbnName") = value
        End Set
    End Property

    ''' <summary>True si l'utilisateur est administrateur de son abonne
    ''' (peut gerer cles d'API / webhooks).</summary>
    Public Property IsAbonneAdmin() As Boolean
        Get
            Dim v As Object = Session("AbnIsAdmin")
            If v Is Nothing Then Return False
            Return CBool(v)
        End Get
        Set(value As Boolean)
            Session("AbnIsAdmin") = value
        End Set
    End Property

    ''' <summary>True si un utilisateur abonne est authentifie.</summary>
    Public ReadOnly Property IsAuthenticated() As Boolean
        Get
            Return UserId <> 0 AndAlso AbonneId <> 0
        End Get
    End Property

    ''' <summary>Termine la session de l'utilisateur.</summary>
    Public Sub SignOut()
        Session.Remove("AbnUserId")
        Session.Remove("AbnId")
        Session.Remove("AbnUserName")
        Session.Remove("AbnUserEmail")
        Session.Remove("AbnName")
        Session.Remove("AbnIsAdmin")
    End Sub

    ' =====================================================================
    ' Acces base de donnees (60secPaiement)
    ' =====================================================================

    Private m_ConnectionString As String = ""
    Public Property ConnectionString() As String
        Get
            If m_ConnectionString.Length = 0 Then
                m_ConnectionString = System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
            End If
            Return m_ConnectionString
        End Get
        Set(value As String)
            m_ConnectionString = value
        End Set
    End Property

    ''' <summary>Execute une procedure stockee sans resultat.</summary>
    Public Sub ExecuteSQL(ByVal StoredProc As String, AllParameters As Collection)
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand(StoredProc, conn)
                cmd.CommandType = CommandType.StoredProcedure
                For Each p As SqlParameter In AllParameters
                    cmd.Parameters.Add(p)
                Next
                conn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    ''' <summary>Execute une procedure stockee et retourne un DataSet.</summary>
    Public Function ExecuteSQLds(ByVal StoredProc As String, AllParameters As Collection) As DataSet
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand(StoredProc, conn)
                cmd.CommandType = CommandType.StoredProcedure
                For Each p As SqlParameter In AllParameters
                    cmd.Parameters.Add(p)
                Next
                Dim da As New SqlDataAdapter(cmd)
                Dim ds As New DataSet()
                da.Fill(ds)
                Return ds
            End Using
        End Using
    End Function

    ' =====================================================================
    ' Helpers de formatage partages (accessibles depuis les .aspx via <%# %>)
    ' =====================================================================

    Private Shared ReadOnly CultCA As Globalization.CultureInfo = New Globalization.CultureInfo("fr-CA")

    ''' <summary>Formate un montant en cents entiers vers « 1 234,56 $ ».</summary>
    Protected Function Money(cents As Object) As String
        Dim c As Long = If(cents Is Nothing OrElse IsDBNull(cents), 0L, Convert.ToInt64(cents))
        Return (c / 100D).ToString("N2", CultCA) & " $"
    End Function

    ''' <summary>Date + heure « yyyy-MM-dd HH:mm » (— si nul).</summary>
    Protected Function FormatDt(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return "—"
        Return CDate(d).ToString("yyyy-MM-dd HH:mm")
    End Function

    ''' <summary>Date seule « yyyy-MM-dd » (— si nul).</summary>
    Protected Function FormatDate(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return "—"
        Return CDate(d).ToString("yyyy-MM-dd")
    End Function

    ''' <summary>Encodage HTML sur (comme Server.HtmlEncode mais tolerant au nul).</summary>
    Protected Function Enc(o As Object) As String
        Return Server.HtmlEncode(If(o, "").ToString())
    End Function

End Class
