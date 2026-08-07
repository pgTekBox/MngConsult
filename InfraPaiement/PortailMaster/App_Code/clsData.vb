Imports System
Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Classe de base de toutes les pages du PortailMaster.
''' Fournit :
'''   - l'acces a la base 60secPaiement via procedures stockees (sNNNN) ;
'''   - l'etat d'authentification (administrateur du portail) conserve en Session.
''' Toutes les pages heritent de clsData au lieu de System.Web.UI.Page.
''' </summary>
Public Class clsData
    Inherits System.Web.UI.Page

    ' =====================================================================
    ' Etat de session : administrateur du portail connecte
    ' =====================================================================

    ''' <summary>Id de l'administrateur connecte (0 = non connecte).</summary>
    Public Property AdminId() As Integer
        Get
            Try
                If Session("AdminId") Is Nothing Then Session("AdminId") = 0
                Return CInt(Session("AdminId"))
            Catch
                Return 0
            End Try
        End Get
        Set(value As Integer)
            Session("AdminId") = value
        End Set
    End Property

    ''' <summary>Nom complet de l'administrateur connecte (pour l'entete).</summary>
    Public Property AdminName() As String
        Get
            Return If(TryCast(Session("AdminName"), String), "")
        End Get
        Set(value As String)
            Session("AdminName") = value
        End Set
    End Property

    ''' <summary>Courriel de l'administrateur connecte.</summary>
    Public Property AdminEmail() As String
        Get
            Return If(TryCast(Session("AdminEmail"), String), "")
        End Get
        Set(value As String)
            Session("AdminEmail") = value
        End Set
    End Property

    ''' <summary>True si l'administrateur connecte est super-administrateur
    ''' (droit de gerer les utilisateurs du portail).</summary>
    Public Property AdminIsSuperAdmin() As Boolean
        Get
            Dim v As Object = Session("AdminIsSuperAdmin")
            If v Is Nothing Then Return False
            Return CBool(v)
        End Get
        Set(value As Boolean)
            Session("AdminIsSuperAdmin") = value
        End Set
    End Property

    ''' <summary>True si un administrateur est authentifie.</summary>
    Public ReadOnly Property IsAuthenticated() As Boolean
        Get
            Return AdminId <> 0
        End Get
    End Property

    ''' <summary>
    ''' Garde de page : redirige vers la connexion si non authentifie.
    ''' A appeler en tete de Page_Load des pages protegees.
    ''' </summary>
    Protected Sub RequireLogin()
        If Not IsAuthenticated Then
            Dim ret As String = Request.RawUrl
            Response.Redirect("~/wbfLogin.aspx?ReturnUrl=" & Server.UrlEncode(ret))
        End If
    End Sub

    ''' <summary>Termine la session de l'administrateur.</summary>
    Public Sub SignOut()
        Session.Remove("AdminId")
        Session.Remove("AdminName")
        Session.Remove("AdminEmail")
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

End Class
