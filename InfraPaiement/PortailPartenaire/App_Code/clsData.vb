Imports System
Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Classe de base de toutes les pages du PortailPartenaire (portail des
''' partenaires / canaux de revente - Modele B).
''' Fournit :
'''   - l'acces a la base 60secPaiement via procedures stockees (sNNNN) ;
'''   - l'etat d'authentification de l'utilisateur partenaire conserve en
'''     Session, y compris l'identifiant du partenaire (PartenaireId) qui
'''     scope TOUTES les operations (isolation du canal).
''' Toutes les pages heritent de clsData au lieu de System.Web.UI.Page.
''' </summary>
Public Class clsData
    Inherits System.Web.UI.Page

    ' =====================================================================
    ' Etat de session : utilisateur partenaire connecte
    ' =====================================================================

    ''' <summary>Id de l'utilisateur partenaire connecte (0 = non connecte).</summary>
    Public Property UserId() As Integer
        Get
            Try
                If Session("PtnUserId") Is Nothing Then Session("PtnUserId") = 0
                Return CInt(Session("PtnUserId"))
            Catch
                Return 0
            End Try
        End Get
        Set(value As Integer)
            Session("PtnUserId") = value
        End Set
    End Property

    ''' <summary>Id du partenaire (canal) auquel l'utilisateur est rattache.
    ''' Scope toutes les operations : un partenaire ne voit JAMAIS les abonnes
    ''' d'un autre partenaire.</summary>
    Public Property PartenaireId() As Integer
        Get
            Try
                If Session("PtnId") Is Nothing Then Session("PtnId") = 0
                Return CInt(Session("PtnId"))
            Catch
                Return 0
            End Try
        End Get
        Set(value As Integer)
            Session("PtnId") = value
        End Set
    End Property

    ''' <summary>Nom complet de l'utilisateur connecte (pour l'entete).</summary>
    Public Property UserName() As String
        Get
            Return If(TryCast(Session("PtnUserName"), String), "")
        End Get
        Set(value As String)
            Session("PtnUserName") = value
        End Set
    End Property

    ''' <summary>Courriel de l'utilisateur connecte.</summary>
    Public Property UserEmail() As String
        Get
            Return If(TryCast(Session("PtnUserEmail"), String), "")
        End Get
        Set(value As String)
            Session("PtnUserEmail") = value
        End Set
    End Property

    ''' <summary>Raison sociale du partenaire (affichee dans l'entete).</summary>
    Public Property PartenaireName() As String
        Get
            Return If(TryCast(Session("PtnName"), String), "")
        End Get
        Set(value As String)
            Session("PtnName") = value
        End Set
    End Property

    ''' <summary>True si l'utilisateur est administrateur de son partenaire
    ''' (peut gerer les cles d'API).</summary>
    Public Property IsPartnerAdmin() As Boolean
        Get
            Dim v As Object = Session("PtnIsAdmin")
            If v Is Nothing Then Return False
            Return CBool(v)
        End Get
        Set(value As Boolean)
            Session("PtnIsAdmin") = value
        End Set
    End Property

    ''' <summary>True si un utilisateur partenaire est authentifie.</summary>
    Public ReadOnly Property IsAuthenticated() As Boolean
        Get
            Return UserId <> 0 AndAlso PartenaireId <> 0
        End Get
    End Property

    ''' <summary>Termine la session de l'utilisateur.</summary>
    Public Sub SignOut()
        Session.Remove("PtnUserId")
        Session.Remove("PtnId")
        Session.Remove("PtnUserName")
        Session.Remove("PtnUserEmail")
        Session.Remove("PtnName")
        Session.Remove("PtnIsAdmin")
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

    ''' <summary>Encodage HTML tolerant au nul.</summary>
    Protected Function Enc(o As Object) As String
        Return Server.HtmlEncode(If(o, "").ToString())
    End Function

End Class
