Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.UI.WebControls
Imports Telerik.Web.UI

''' <summary>
''' Classe de base pour l'accès aux données de la console d'administration.
''' Toutes les pages qui appellent des procédures stockées héritent de clsData.
''' Reprend le pattern de prjMngConsul (ExecuteSQL / ExecuteSQLds / SetDDL).
''' Inclut les surcharges SetDDL (DropDownList ASP.NET + RadDropDownList Telerik)
''' pour que les pages migrées depuis l'app principale fonctionnent sans modification.
''' </summary>
Public Class clsData
    Inherits System.Web.UI.Page

    ' -------------------------------------------------------------------------
    ' Garde d'authentification global : toute page héritant de clsData qui n'est
    ' pas une page anonyme (login / reset / logout) redirige vers wbfLogin.aspx
    ' si l'utilisateur n'est pas authentifié.
    ' -------------------------------------------------------------------------
    ''' <summary>
    ''' Recharge l'administrateur quand la session est vide (session perdue, ou
    ''' navigateur rouvert), sans dépendre de Global.asax ni de la session :
    '''  1. cookie de connexion Forms valide → administrateur relu par son courriel ;
    '''  2. sinon, jeton « Se souvenir de moi » valide (clsAdminRememberMe) →
    '''     nouveau cookie de connexion de session + administrateur rechargé.
    ''' Un compte introuvable ou désactivé est déconnecté. Appelé avant le contrôle
    ''' d'accès (OnLoad), donc aussi sur wbfLogin (page par défaut de « / » et cible
    ''' des redirections), qui renvoie alors directement dans la console.
    ''' </summary>
    Protected Overrides Sub OnPreInit(e As EventArgs)
        If AdminId = 0 Then RechargerAdmin()
        MyBase.OnPreInit(e)
    End Sub

    Private Sub RechargerAdmin()
        Try
            Dim email As String = ""
            If Context.User IsNot Nothing AndAlso Context.User.Identity IsNot Nothing AndAlso Context.User.Identity.IsAuthenticated Then
                email = If(Context.User.Identity.Name, "").Trim().ToLowerInvariant()
            End If

            If email <> "" Then
                Dim p As New Collection
                p.Add(New SqlParameter("@Email", email))
                Dim ds As DataSet = ExecuteSQLds("s0640GetAdminByEmail", p)
                Dim actif As Boolean = False
                If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                    Dim r As DataRow = ds.Tables(0).Rows(0)
                    actif = Not IsDBNull(r("IsActive")) AndAlso CBool(r("IsActive"))
                    If actif Then
                        AdminId = CInt(r("Id"))
                        AdminEmail = r("Email").ToString()
                        Return
                    End If
                End If
                ' Compte introuvable ou désactivé : on coupe la connexion.
                System.Web.Security.FormsAuthentication.SignOut()
                Return
            End If

            ' Pas de cookie de connexion : « Se souvenir de moi » ?
            If clsAdminRememberMe.HasCookie(Context) Then
                Dim id As Integer = 0
                Dim courriel As String = clsAdminRememberMe.TryRestore(Context, id)
                If courriel <> "" AndAlso id > 0 Then
                    System.Web.Security.FormsAuthentication.SetAuthCookie(courriel, False)
                    AdminId = id
                    AdminEmail = courriel
                End If
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("RechargerAdmin : " & ex.Message)
        End Try
    End Sub

    Protected Overrides Sub OnLoad(e As EventArgs)
        If Not IsAnonymousPage() AndAlso Not IsAuthenticated Then
            Dim returnUrl As String = ""
            Try
                returnUrl = Request.RawUrl
            Catch
            End Try
            Response.Redirect("~/wbfLogin.aspx?ReturnUrl=" & Server.UrlEncode(returnUrl), True)
            Return
        End If
        MyBase.OnLoad(e)
    End Sub

    ''' <summary>Pages accessibles sans authentification.</summary>
    Private Function IsAnonymousPage() As Boolean
        Dim file As String = ""
        Try
            file = System.IO.Path.GetFileNameWithoutExtension(Request.CurrentExecutionFilePath).ToLowerInvariant()
        Catch
        End Try
        Return file = "wbflogin" OrElse file = "wbfresetpassword" OrElse file = "wbflogout"
    End Function

    ' -------------------------------------------------------------------------
    ' Compagnie courante (contexte). Choisie via le sélecteur de wbfUsers.aspx
    ' et conservée en session. Les procédures stockées utilisateurs filtrent
    ' sur ce CompanyGUID.
    ' -------------------------------------------------------------------------
    Public Property Company() As Guid
        Get
            Try
                If Session("Company") Is Nothing Then
                    Session("Company") = Guid.Empty
                End If
                Return CType(Session("Company"), Guid)
            Catch ex As Exception
                Return Guid.Empty
            End Try
        End Get
        Set(ByVal Value As Guid)
            Session("Company") = Value
        End Set
    End Property

    ' -------------------------------------------------------------------------
    ' Administrateur connecté (console). Renseigné par wbfLogin.aspx.
    ' -------------------------------------------------------------------------
    Public Property AdminId() As Integer
        Get
            Try
                If Session("AdminId") Is Nothing Then Return 0
                Return CInt(Session("AdminId"))
            Catch ex As Exception
                Return 0
            End Try
        End Get
        Set(ByVal Value As Integer)
            Session("AdminId") = Value
        End Set
    End Property

    Public Property AdminEmail() As String
        Get
            Try
                Return If(CStr(Session("AdminEmail")), "")
            Catch ex As Exception
                Return ""
            End Try
        End Get
        Set(ByVal Value As String)
            Session("AdminEmail") = Value
        End Set
    End Property

    ''' <summary>Vrai si un administrateur est connecté.</summary>
    Public ReadOnly Property IsAuthenticated() As Boolean
        Get
            Return AdminId > 0
        End Get
    End Property

    ' -------------------------------------------------------------------------
    ' Deux membres attendus par les pages « Tâches », reprises de l'ERP.
    ' -------------------------------------------------------------------------

    ''' <summary>
    ''' Identifiant transmis aux procédures des tâches (@UserId, @LanceePar).
    '''
    ''' Dans l'ERP c'était l'utilisateur connecté (T015User) ; ici c'est
    ''' l'administrateur de la console (T900AdminUser). Ces colonnes ne portent
    ''' aucune clé étrangère, elles servent à retenir QUI a lancé une tâche : la
    ''' valeur reste donc exploitable, mais elle se lit dans T900AdminUser, pas
    ''' dans T015User.
    ''' </summary>
    Public ReadOnly Property UserId() As Integer
        Get
            Return AdminId
        End Get
    End Property

    ''' <summary>
    ''' Langue de l'interface (fr/en/es), conservée en Session. Un ?lang=xx dans
    ''' l'URL est prioritaire. La console est en français, mais les pages des
    ''' tâches sont traduites : on garde le mécanisme plutôt que de figer « fr ».
    ''' </summary>
    Public Property CurrentLang() As String
        Get
            Dim q As String = If(Request.QueryString("lang"), "").Trim().ToLowerInvariant()
            If q = "fr" OrElse q = "en" OrElse q = "es" Then
                Session("Lang") = q
                Return q
            End If
            Dim s As String = TryCast(Session("Lang"), String)
            If s = "fr" OrElse s = "en" OrElse s = "es" Then Return s
            Return "fr"
        End Get
        Set(value As String)
            Dim v As String = If(value, "").Trim().ToLowerInvariant()
            If v = "fr" OrElse v = "en" OrElse v = "es" Then Session("Lang") = v
        End Set
    End Property

    ' -------------------------------------------------------------------------
    ' Courriel utilisé comme @ModifiedBy dans les procédures : celui de
    ' l'administrateur connecté, sinon "admin".
    ' -------------------------------------------------------------------------
    Public ReadOnly Property UserEmail() As String
        Get
            Dim e As String = AdminEmail
            Return If(String.IsNullOrEmpty(e), "admin", e)
        End Get
    End Property

    ' -------------------------------------------------------------------------
    ' Chaîne de connexion (BD MngConsul) lue depuis appSettings du Web.config.
    ' -------------------------------------------------------------------------
    Private m_ConnectionString As String = ""
    Public Property ConnectionString() As String
        Get
            Try
                If m_ConnectionString.Length = 0 Then
                    m_ConnectionString = System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
                End If
                Return m_ConnectionString
            Catch ex As Exception
                Return ""
            End Try
        End Get
        Set(ByVal Value As String)
            m_ConnectionString = Value
        End Set
    End Property

    ' -------------------------------------------------------------------------
    ' Chaîne de connexion vers la BD MailService (file d'attente T400Mails,
    ' relevée par le service Windows SrvAI pour l'envoi SMTP).
    ' -------------------------------------------------------------------------
    Private m_ConnectionStringMail As String = ""
    Public Property ConnectionStringMail() As String
        Get
            Try
                If m_ConnectionStringMail.Length = 0 Then
                    m_ConnectionStringMail = System.Configuration.ConfigurationManager.AppSettings("ConnectionStringMail")
                End If
                Return m_ConnectionStringMail
            Catch ex As Exception
                Return ""
            End Try
        End Get
        Set(ByVal Value As String)
            m_ConnectionStringMail = Value
        End Set
    End Property

    ''' <summary>
    ''' Exécute une procédure stockée sur la BD MailService (insertion de courriel).
    ''' </summary>
    Public Sub ExecuteSQLMail(ByVal SQLStatement As String, AllParameters As Collection)
        Using DRconn As New SqlClient.SqlConnection(ConnectionStringMail)
            Dim oCom As New SqlClient.SqlCommand(SQLStatement, DRconn)
            oCom.CommandType = CommandType.StoredProcedure
            For Each oParam As SqlClient.SqlParameter In AllParameters
                oCom.Parameters.Add(oParam)
            Next
            DRconn.Open()
            oCom.ExecuteNonQuery()
        End Using
    End Sub

    ''' <summary>Exécute une procédure stockée sur la BD MailService et retourne un DataSet (lecture courriels).</summary>
    Public Function ExecuteSQLdsMail(ByVal SQLStatement As String) As DataSet
        Using DRconn As New SqlClient.SqlConnection(ConnectionStringMail)
            Dim oCom As New SqlClient.SqlCommand(SQLStatement, DRconn)
            oCom.CommandType = CommandType.StoredProcedure
            Dim MyDA As New SqlClient.SqlDataAdapter(oCom)
            Dim oDs As New DataSet
            MyDA.Fill(oDs)
            Return oDs
        End Using
    End Function

    Public Function ExecuteSQLdsMail(ByVal SQLStatement As String, AllParameters As Collection) As DataSet
        Using DRconn As New SqlClient.SqlConnection(ConnectionStringMail)
            Dim oCom As New SqlClient.SqlCommand(SQLStatement, DRconn)
            oCom.CommandType = CommandType.StoredProcedure
            For Each oParam As SqlClient.SqlParameter In AllParameters
                oCom.Parameters.Add(oParam)
            Next
            Dim MyDA As New SqlClient.SqlDataAdapter(oCom)
            Dim oDs As New DataSet
            MyDA.Fill(oDs)
            Return oDs
        End Using
    End Function

    ' -------------------------------------------------------------------------
    ' Exécute une procédure stockée (sans retour).
    ' -------------------------------------------------------------------------
    Public Sub ExecuteSQL(ByVal SQLStatement As String)
        Using DRconn As New SqlClient.SqlConnection(ConnectionString)
            Dim oCom As New SqlClient.SqlCommand(SQLStatement, DRconn)
            oCom.CommandType = CommandType.StoredProcedure
            DRconn.Open()
            oCom.ExecuteNonQuery()
        End Using
    End Sub

    Public Sub ExecuteSQL(ByVal SQLStatement As String, AllParameters As Collection)
        Using DRconn As New SqlClient.SqlConnection(ConnectionString)
            Dim oCom As New SqlClient.SqlCommand(SQLStatement, DRconn)
            oCom.CommandType = CommandType.StoredProcedure
            For Each oParam As SqlClient.SqlParameter In AllParameters
                oCom.Parameters.Add(oParam)
            Next
            DRconn.Open()
            oCom.ExecuteNonQuery()
        End Using
    End Sub

    ' -------------------------------------------------------------------------
    ' Exécute une procédure stockée et retourne un DataSet.
    ' -------------------------------------------------------------------------
    Public Function ExecuteSQLds(ByVal SQLStatement As String) As DataSet
        Using DRconn As New SqlClient.SqlConnection(ConnectionString)
            Dim oCom As New SqlClient.SqlCommand(SQLStatement, DRconn)
            oCom.CommandType = CommandType.StoredProcedure
            Dim MyDA As New SqlClient.SqlDataAdapter(oCom)
            Dim oDs As New DataSet
            MyDA.Fill(oDs)
            Return oDs
        End Using
    End Function

    Public Function ExecuteSQLds(ByVal SQLStatement As String, AllParameters As Collection) As DataSet
        Using DRconn As New SqlClient.SqlConnection(ConnectionString)
            Dim oCom As New SqlClient.SqlCommand(SQLStatement, DRconn)
            oCom.CommandType = CommandType.StoredProcedure
            For Each oParam As SqlClient.SqlParameter In AllParameters
                oCom.Parameters.Add(oParam)
            Next
            Dim MyDA As New SqlClient.SqlDataAdapter(oCom)
            Dim oDs As New DataSet
            MyDA.Fill(oDs)
            Return oDs
        End Using
    End Function

    ' -------------------------------------------------------------------------
    ' Remplissage de listes déroulantes à partir d'une procédure stockée.
    ' Repris de prjMngConsul.clsData pour que les pages migrées depuis l'app
    ' principale (ex. wbfSettingsOpenAiPrompts) fonctionnent sans modification.
    ' Overloads : DropDownList (ASP.NET) et RadDropDownList (Telerik).
    ' -------------------------------------------------------------------------

    Sub SetDDL(ByVal oDDL As DropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String)

        Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
        oCon.Open()
        Dim oCom As New SqlClient.SqlCommand(SQLStatement, oCon)
        oCom.CommandType = CommandType.StoredProcedure
        Dim oDr As SqlClient.SqlDataReader
        oDr = oCom.ExecuteReader
        oDDL.Items.Clear()
        Do While oDr.Read()
            Dim MyItem As New ListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))
            oDDL.Items.Add(MyItem)
        Loop
        oDr.Close()
        oCom.Connection.Close()
        oCon.Close()

    End Sub

    Sub SetDDL(ByVal oDDL As DropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String, ByVal SetSelectedValue As Integer)

        Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
        oCon.Open()
        Dim oCom As New SqlClient.SqlCommand(SQLStatement, oCon)
        oCom.CommandType = CommandType.StoredProcedure
        Dim oDr As SqlClient.SqlDataReader
        oDr = oCom.ExecuteReader
        oDDL.Items.Clear()
        Do While oDr.Read()
            Dim MyItem As New ListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))
            oDDL.Items.Add(MyItem)
        Loop
        oDr.Close()
        oCom.Connection.Close()
        oCon.Close()

        For Each oItem As ListItem In oDDL.Items
            oItem.Selected = False
        Next
        For Each oItem As ListItem In oDDL.Items
            If SetSelectedValue = oItem.Value Then
                oItem.Selected = True
                Exit For
            End If
        Next

    End Sub

    Sub SetDDL(ByVal oDDL As RadDropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String)

        Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
        oCon.Open()
        Dim oCom As New SqlClient.SqlCommand(SQLStatement, oCon)
        oCom.CommandType = CommandType.StoredProcedure
        Dim oDr As SqlClient.SqlDataReader
        oDr = oCom.ExecuteReader
        oDDL.Items.Clear()
        Do While oDr.Read()
            Dim MyItem As New DropDownListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))
            oDDL.Items.Add(MyItem)
        Loop
        oDr.Close()
        oCom.Connection.Close()
        oCon.Close()

        For Each oItem As DropDownListItem In oDDL.Items
            oItem.Selected = False
        Next

    End Sub

    Sub SetDDL(ByVal oDDL As RadDropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String, AllParameters As Collection)

        Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
        oCon.Open()
        Dim oCom As New SqlClient.SqlCommand(SQLStatement, oCon)
        For Each oParam As SqlClient.SqlParameter In AllParameters
            oCom.Parameters.Add(oParam)
        Next
        oCom.CommandType = CommandType.StoredProcedure
        Dim oDr As SqlClient.SqlDataReader
        oDr = oCom.ExecuteReader
        oDDL.Items.Clear()
        Do While oDr.Read()
            Dim MyItem As New DropDownListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))
            oDDL.Items.Add(MyItem)
        Loop
        oDr.Close()
        oCom.Connection.Close()
        oCon.Close()

        For Each oItem As DropDownListItem In oDDL.Items
            oItem.Selected = False
        Next

    End Sub

    Sub SetDDL(ByVal oDDL As RadDropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String, ByVal SetSelectedValue As Integer)

        Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
        oCon.Open()
        Dim oCom As New SqlClient.SqlCommand(SQLStatement, oCon)
        oCom.CommandType = CommandType.StoredProcedure
        Dim oDr As SqlClient.SqlDataReader
        oDr = oCom.ExecuteReader
        oDDL.Items.Clear()
        Do While oDr.Read()
            Dim MyItem As New DropDownListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))
            oDDL.Items.Add(MyItem)
        Loop
        oDr.Close()
        oCom.Connection.Close()
        oCon.Close()

        For Each oItem As DropDownListItem In oDDL.Items
            oItem.Selected = False
        Next
        For Each oItem As DropDownListItem In oDDL.Items
            If SetSelectedValue = oItem.Value Then
                oItem.Selected = True
                Exit For
            End If
        Next

    End Sub

    ''' <summary>Convertit DBNull en chaîne vide (utilisé par SetDDL).</summary>
    Private Function CheckStringNull(ByVal oObj As Object) As Object
        If IsDBNull(oObj) Then
            Return ""
        Else
            Return oObj
        End If
    End Function

End Class
