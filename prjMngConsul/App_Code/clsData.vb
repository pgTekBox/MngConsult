Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI
Imports Telerik.Web.UI.Editor.DialogControls



Public Class clsData
    Inherits System.Web.UI.Page

    ''' <summary>
    ''' Langue courante de l'interface (fr/en/es), conservée en Session.
    ''' Un paramètre ?lang=xx dans l'URL (sélecteur de langue du header) est
    ''' prioritaire et met à jour la Session ; sinon on relit la valeur mémorisée,
    ''' défaut « fr ». Ainsi la langue persiste d'une page à l'autre (menu de
    ''' gauche, etc.) sans devoir propager ?lang= sur chaque lien.
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

    Private Function GetUserByEmail(email As String) As DataRow
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Email", email))
            Dim ds As DataSet = ExecuteSQLds("s0200GetUserByEmail", p)
            If ds.Tables(0).Rows.Count > 0 Then Return ds.Tables(0).Rows(0)
        Catch ex As Exception
            ' Ne pas révéler les détails au user
            System.Diagnostics.Debug.WriteLine("Login error: " & ex.Message)
        End Try
        Return Nothing
    End Function
    Private Function GetUserById(UserId As Integer) As DataRow
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", UserId))
            Dim ds As DataSet = ExecuteSQLds("s0314GetUserByUserId", p)
            If ds.Tables(0).Rows.Count > 0 Then Return ds.Tables(0).Rows(0)
        Catch ex As Exception
            ' Ne pas révéler les détails au user
            System.Diagnostics.Debug.WriteLine("Login error: " & ex.Message)
        End Try
        Return Nothing
    End Function


    Public Property IsAccountant() As Boolean
        Get
            Try
                If Session("IsAccountant") Is Nothing Then
                    Dim userRow As DataRow = GetUserById(UserId)
                    Session("IsAccountant") = CType(userRow("IsAccountant"), Boolean)
                End If
                Return Session("IsAccountant")
            Catch ex As Exception
                Return False
            End Try
        End Get
        Set(ByVal Value As Boolean)
            Session("IsAccountant") = Value
        End Set
    End Property

    ''' <summary>
    ''' Vrai quand le comptable a choisi « Portail comptable » dans le sélecteur
    ''' de l'en-tête : le menu de gauche et les pages basculent sur l'espace du
    ''' cabinet. Mis à False dès qu'il entre dans une compagnie (dossier).
    ''' </summary>
    Public Property EnPortailComptable() As Boolean
        Get
            Try
                ' Jamais défini explicitement : un comptable démarre dans le portail
                ' par défaut (le sélecteur de l'en-tête se positionne sur « Portail
                ' comptable »). Dès qu'il entre dans un dossier, la valeur est posée
                ' (False) et prime ; un non-comptable reste toujours hors portail.
                If Session("PortailComptable") Is Nothing Then Return IsAccountant
                Return CBool(Session("PortailComptable"))
            Catch
                Return False
            End Try
        End Get
        Set(ByVal Value As Boolean)
            Session("PortailComptable") = Value
        End Set
    End Property


    Public Property isAdmin() As Boolean
        Get
            Try
                If Session("isAdmin") Is Nothing Then
                    Dim userRow As DataRow = GetUserById(UserId)
                    Session("isAdmin") = CType(userRow("isAdmin"), Boolean)
                End If
                Return Session("isAdmin")
            Catch ex As Exception
                Return False
            End Try
        End Get
        Set(ByVal Value As Boolean)
            Session("isAdmin") = Value
        End Set
    End Property

    Public Property isAuthenticated() As Boolean
        Get
            Try
                If UserId = 0 Then
                    Return False
                End If
                Return True

            Catch ex As Exception
                Return False
            End Try
        End Get
        Set(ByVal Value As Boolean)

        End Set
    End Property
    Public Property Abonnement() As String
        Get
            Try
                If String.IsNullOrEmpty(Session("Abonnement")) Then
                    Session("Abonnement") = ""
                End If

                Return Session("Abonnement")
            Catch ex As Exception
                Return ""
            End Try

        End Get
        Set(ByVal Value As String)
            Session("Abonnement") = Value
        End Set
    End Property


    Public Property Company() As Guid
        Get
            Try
                If Session("Company") Is Nothing Then
                    Session("Company") = Guid.Parse("00000000-0000-0000-0000-000000000000")
                End If

                Return Session("Company")
            Catch ex As Exception
                Return Guid.Empty
            End Try

        End Get
        Set(ByVal Value As Guid)
            Session("Company") = Value
        End Set
    End Property

    Public Property UserId() As Integer
        Get
            Try
                If Session("UserId") Is Nothing Then
                    Session("UserId") = 0
                End If

                Return Session("UserId")
            Catch ex As Exception
                Return 0
            End Try

        End Get
        Set(ByVal Value As Integer)

            Session("UserId") = Value



        End Set
    End Property

    Public Property CompanyName() As String
        Get
            Try
                ' Nom de la compagnie COURANTE (celle de session), pas la compagnie
                ' maison de l'utilisateur : le comptable change de dossier via le
                ' sélecteur, le nom doit suivre. Cache indexé sur le GUID courant.
                Dim cg As String = Company.ToString()
                If Session("CompanyName") Is Nothing OrElse CStr(If(Session("CompanyNameGuid"), "")) <> cg Then
                    Session("CompanyName") = GetCompanyNameByGuid(Company)
                    Session("CompanyNameGuid") = cg
                End If
                Return CStr(If(Session("CompanyName"), ""))
            Catch ex As Exception
                Return ""
            End Try
        End Get
        Set(ByVal Value As String)
            Session("CompanyName") = Value
            Session("CompanyNameGuid") = Company.ToString()
        End Set
    End Property

    ''' <summary>Nom d'une compagnie par son GUID (s0918GetCompanyName → fCompanyName).</summary>
    Private Function GetCompanyNameByGuid(cg As Guid) As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", cg))
            Dim ds As DataSet = ExecuteSQLds("s0918GetCompanyName", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return CStr(ds.Tables(0).Rows(0)("Name"))
            End If
        Catch
        End Try
        Return ""
    End Function

    Public Property UserFirstName() As String
        Get
            Try
                If String.IsNullOrEmpty(Session("UserFirstName")) Then

                    Dim userRow As DataRow = GetUserById(UserId)
                    Session("UserFirstName") = CType(userRow("FirstName"), String)
                End If
                Return Session("UserFirstName")
            Catch ex As Exception
                Return ""
            End Try
        End Get
        Set(ByVal Value As String)
            Session("UserFirstName") = Value
        End Set
    End Property

    Public Property UserLastName() As String
        Get
            Try
                If String.IsNullOrEmpty(Session("UserLastName")) Then

                    Dim userRow As DataRow = GetUserById(UserId)
                    Session("UserLastName") = CType(userRow("LastName"), String)
                End If
                Return Session("UserLastName")
            Catch ex As Exception
                Return ""
            End Try
        End Get
        Set(ByVal Value As String)
            Session("UserLastName") = Value
        End Set
    End Property
    Public Property UserEmail() As String
        Get
            Try
                If String.IsNullOrEmpty(Session("UserEmail")) Then

                    Dim userRow As DataRow = GetUserById(UserId)
                    Session("UserEmail") = CType(userRow("Email"), String)
                End If
                Return Session("UserEmail")
            Catch ex As Exception
                Return ""
            End Try
        End Get
        Set(ByVal Value As String)
            Session("UserEmail") = Value
        End Set
    End Property


    Private m_ConnectionString As String = ""
    Public Property ConnectionString() As String
        Get
            Try

                If m_ConnectionString.Length = 0 Then
                    Dim sConnect As String = System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
                    m_ConnectionString = sConnect
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
    ' Connection vers la BD MailService (insertion dans T400Mails pour envoi).
    ' Utilisée par les méthodes ExecuteSQLMail / ExecuteSQLdsMail.
    ' -------------------------------------------------------------------------
    Private m_ConnectionStringMail As String = ""
    Public Property ConnectionStringMail() As String
        Get
            Try
                If m_ConnectionStringMail.Length = 0 Then
                    Dim sConnect As String = System.Configuration.ConfigurationManager.AppSettings("ConnectionStringMail")
                    m_ConnectionStringMail = sConnect
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

    ' -------------------------------------------------------------------------
    ' Exécute une stored procedure dans la BD MailService.
    ' Équivalent de ExecuteSQL mais sur la 2e connection string.
    ' -------------------------------------------------------------------------
    Public Sub ExecuteSQLMail(ByVal SQLStatement As String, AllParameters As Collection)
        Dim DRconn As SqlClient.SqlConnection
        DRconn = New SqlClient.SqlConnection(ConnectionStringMail)

        Dim oCom As New SqlClient.SqlCommand
        oCom.CommandText = SQLStatement
        oCom.Connection = DRconn
        oCom.CommandType = CommandType.StoredProcedure

        For Each oParam As Data.SqlClient.SqlParameter In AllParameters
            oCom.Parameters.Add(oParam)
        Next

        oCom.Connection.Open()
        oCom.ExecuteNonQuery()
        oCom.Connection.Close()
    End Sub

    ' -------------------------------------------------------------------------
    ' Exécute une stored procedure dans MailService et retourne un DataSet.
    ' Utile quand la proc retourne l'Id du mail inséré (OUTPUT INSERTED.Id).
    ' -------------------------------------------------------------------------
    Public Function ExecuteSQLdsMail(ByVal SQLStatement As String, AllParameters As Collection) As DataSet
        Dim DRconn As SqlClient.SqlConnection
        DRconn = New SqlClient.SqlConnection(ConnectionStringMail)
        Dim MyDA As New SqlClient.SqlDataAdapter

        Dim oCom As New SqlClient.SqlCommand
        oCom.CommandText = SQLStatement
        oCom.Connection = DRconn
        oCom.CommandType = CommandType.StoredProcedure
        MyDA.SelectCommand = oCom

        For Each oParam As Data.SqlClient.SqlParameter In AllParameters
            oCom.Parameters.Add(oParam)
        Next

        Dim oDs As New DataSet
        MyDA.Fill(oDs)
        Return oDs
    End Function

    Public Sub ExecuteSQL(ByVal SQLStatement As String)
        GarderLectureSeule(SQLStatement, True)    ' T395
        Dim oCom As New SqlClient.SqlCommand
        oCom.CommandText = SQLStatement
        oCom.Connection = New SqlClient.SqlConnection(ConnectionString)
        oCom.CommandType = CommandType.StoredProcedure
        oCom.Connection.Open()
        oCom.ExecuteNonQuery()
        oCom.Connection.Close()
    End Sub
    Public Sub ExecuteSQL(ByVal SQLStatement As String, AllParameters As Collection)
        GarderLectureSeule(SQLStatement, True)    ' T395 : accès restreint = lecture seule
        Dim DRconn As SqlClient.SqlConnection
        DRconn = New SqlClient.SqlConnection(ConnectionString)


        Dim oCom As New SqlClient.SqlCommand
        oCom.CommandText = SQLStatement
        oCom.Connection = DRconn
        oCom.CommandType = CommandType.StoredProcedure


        For Each oParam As Data.SqlClient.SqlParameter In AllParameters
            oCom.Parameters.Add(oParam)
        Next

        oCom.Connection.Open()
        oCom.ExecuteNonQuery()
        oCom.Connection.Close()

    End Sub
    ''' <summary>
    ''' Affiche un message à l'utilisateur via la boîte définie dans Site.Master.
    '''
    ''' N'utilise PAS radalert : appelé depuis un script de démarrage, il s'exécute
    ''' avant que Telerik ait créé son RadWindowManager côté client et lève
    ''' « Cannot read properties of undefined (reading 'radalert') ». L'exception
    ''' interrompt le traitement de la réponse AJAX, après quoi la page ne réagit
    ''' plus aux clics suivants.
    ''' </summary>
    ''' <param name="msg">Texte affiché (inséré via textContent, jamais interprété).</param>
    ''' <param name="title">Titre de la boîte ; « Information » si vide.</param>
    Public Sub ShowMessageBox(msg As String, Optional title As String = "")
        Dim script As String = "showAppMessage('" & HttpUtility.JavaScriptStringEncode(If(msg, "")) &
                               "','" & HttpUtility.JavaScriptStringEncode(If(title, "")) & "');"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "appMsg", script, True)
    End Sub

    ' ══════════════════════════════════════════════════════════════════════
    '  Cloisonnement par compagnie (T306)
    '  Tout identifiant qui revient du navigateur — adresse, champ caché,
    '  argument AJAX — doit être confronté à la compagnie de la session AVANT
    '  de lire ou de modifier l'enregistrement : la plupart des procédures
    '  « par Id » ne reçoivent pas la compagnie et ne peuvent pas le faire.
    ' ══════════════════════════════════════════════════════════════════════

    ''' <summary>
    ''' Vrai si l'enregistrement appartient à la compagnie de la session.
    ''' Types : PARTY, ADRESSE, DOCUMENT, ECRITURE, TEMPLATE, PRODUIT, COMPTE, PARAM, IMPORT.
    ''' </summary>
    Public Function Appartient(type As String, id As Integer) As Boolean
        If id <= 0 Then Return False
        Try
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Type", type))
            p.Add(New SqlClient.SqlParameter("@Id", id))
            Dim ds As DataSet = ExecuteSQLds("s0891AppartientCompagnie", p)
            Return ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 AndAlso
                   Convert.ToBoolean(ds.Tables(0).Rows(0)("Ok"))
        Catch
            ' Dans le doute, on refuse.
            Return False
        End Try
    End Function

    ''' <summary>Même contrôle pour un reçu numérisé, identifié par son imageGUID (type RECU).</summary>
    Public Function AppartientRecu(imageGuid As Guid) As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Type", "RECU"))
            p.Add(New SqlClient.SqlParameter("@Guid", imageGuid))
            Dim ds As DataSet = ExecuteSQLds("s0891AppartientCompagnie", p)
            Return ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 AndAlso
                   Convert.ToBoolean(ds.Tables(0).Rows(0)("Ok"))
        Catch
            Return False
        End Try
    End Function

    ''' <summary>
    ''' Arrête la requête (403) si l'enregistrement n'est pas à la compagnie de
    ''' la session. À appeler dès qu'un identifiant est lu dans l'adresse.
    ''' </summary>
    Public Sub ExigerAppartenance(type As String, id As Integer)
        If Appartient(type, id) Then Return
        Response.Clear()
        Response.StatusCode = 403
        Response.Write("Accès refusé.")
        Response.End()
    End Sub

    Public Function ExecuteSQLds(ByVal SQLStatement As String) As DataSet
        GarderLectureSeule(SQLStatement, False)   ' T395
        Dim oDa As New SqlClient.SqlDataAdapter(SQLStatement, ConnectionString)
        Dim oDs As New DataSet
        oDa.Fill(oDs)
        Return oDs
    End Function

    Public Function ExecuteSQLds(ByVal SQLStatement As String, AllParameters As Collection) As DataSet
        GarderLectureSeule(SQLStatement, False)   ' T395 : accès restreint = lecture seule
        Dim DRconn As SqlClient.SqlConnection
        DRconn = New SqlClient.SqlConnection(ConnectionString)
        Dim MyDA As New SqlClient.SqlDataAdapter

        Dim oCom As New SqlClient.SqlCommand
        oCom.CommandText = SQLStatement
        oCom.Connection = DRconn
        oCom.CommandType = CommandType.StoredProcedure
        MyDA.SelectCommand = oCom

        For Each oParam As Data.SqlClient.SqlParameter In AllParameters
            oCom.Parameters.Add(oParam)
        Next

        Dim oDs As New DataSet
        MyDA.Fill(oDs)
        Return oDs

    End Function

    Sub SetDDL(ByVal oDDL As System.Web.UI.WebControls.DropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String)

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

    Sub SetDDL(ByVal oDDL As RadDropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String, AllParameters As Collection)




        Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
        oCon.Open()
        Dim oCom As New SqlClient.SqlCommand(SQLStatement, oCon)

        For Each oParam As Data.SqlClient.SqlParameter In AllParameters
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
            If SetSelectedValue = oDr(KeyField) Then MyItem.Selected = True
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


    Sub SetDDL(ByVal oDDL As System.Web.UI.WebControls.DropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String, ByVal SetSelectedValue As Integer)

        Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
        oCon.Open()
        Dim oCom As New SqlClient.SqlCommand(SQLStatement, oCon)
        oCom.CommandType = CommandType.StoredProcedure
        Dim oDr As SqlClient.SqlDataReader
        oDr = oCom.ExecuteReader
        oDDL.Items.Clear()
        Do While oDr.Read()
            Dim MyItem As New ListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))
            If SetSelectedValue = oDr(KeyField) Then MyItem.Selected = True
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
    Private Function CheckStringNull(ByVal oObj As Object) As Object
        If IsDBNull(oObj) Then
            Return ""
        Else
            Return oObj
        End If
    End Function
    Public Function ToDoubleAnyCulture(value As String) As Double

        If String.IsNullOrWhiteSpace(value) Then
            Return 0
        End If

        value = value.Trim()

        ' enlever espaces
        value = value.Replace(" ", "")

        ' trouver le dernier séparateur
        Dim lastDot = value.LastIndexOf("."c)
        Dim lastComma = value.LastIndexOf(","c)

        Dim decimalPos = Math.Max(lastDot, lastComma)

        If decimalPos >= 0 Then
            Dim intPart = value.Substring(0, decimalPos)
            Dim decPart = value.Substring(decimalPos + 1)

            ' enlever autres séparateurs
            intPart = intPart.Replace(".", "").Replace(",", "")

            value = intPart & "." & decPart
        End If

        Dim result As Double

        If Double.TryParse(value,
        Globalization.NumberStyles.Float,
        Globalization.CultureInfo.InvariantCulture,
        result) Then

            Return result
        End If

        Return 0

    End Function

    Public Function FormatQty(value As Object) As String

        If value Is Nothing OrElse IsDBNull(value) Then
            Return ""
        End If

        Dim s As String = value.ToString().Trim()

        ' normaliser
        s = s.Replace(",", ".")

        Dim n As Double

        If Not Double.TryParse(s,
        Globalization.NumberStyles.Any,
        Globalization.CultureInfo.InvariantCulture,
        n) Then

            Return ""
        End If

        ' max 2 décimales
        n = Math.Floor(n * 100) / 100

        Dim result As String = n.ToString("0.##", Globalization.CultureInfo.InvariantCulture)

        Return result

    End Function


    Public Function FormatUnitPrice(value As String) As String

        If String.IsNullOrWhiteSpace(value) Then
            Return ""
        End If

        ' normaliser
        value = value.Trim()
        value = value.Replace(",", ".")

        ' garder seulement chiffres et .
        Dim clean As String = ""
        For Each c As Char In value
            If Char.IsDigit(c) Or c = "."c Then
                clean &= c
            End If
        Next

        ' un seul point
        Dim firstDot = clean.IndexOf("."c)
        If firstDot >= 0 Then

            Dim left = clean.Substring(0, firstDot)
            Dim right = clean.Substring(firstDot + 1).Replace(".", "")

            ' max 2 décimales
            If right.Length > 2 Then
                right = right.Substring(0, 2)
            End If

            clean = left & "." & right

        End If

        Dim n As Double

        If Not Double.TryParse(clean, Globalization.NumberStyles.Any,
                           Globalization.CultureInfo.InvariantCulture, n) Then
            Return ""
        End If

        Dim dec = n.ToString("0.00", Globalization.CultureInfo.InvariantCulture)

        If dec.EndsWith(".00") Then
            Return CInt(n).ToString()
        End If

        Return dec

    End Function
    'Sub SetDDL(ByVal oDDL As System.Web.UI.WebControls.DropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String, DefaultValue As Integer)



    '    Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
    '    oCon.Open()
    '    Dim oCom As New SqlClient.SqlCommand("exec " & SQLStatement, oCon)
    '    Dim oDr As SqlClient.SqlDataReader
    '    oDr = oCom.ExecuteReader
    '    oDDL.Items.Clear()
    '    Do While oDr.Read()

    '        Dim MyItem As New ListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))

    '        If oDr(KeyField) = DefaultValue Then
    '            MyItem.Selected = True
    '            oDDL.SelectedValue = DefaultValue.ToString
    '        End If
    '        oDDL.Items.Add(MyItem)

    '    Loop
    '    oDr.Close()
    '    oCom.Connection.Close()
    '    oCon.Close()

    'End Sub



    'Sub SetDDL(ByVal oDDL As System.Web.UI.WebControls.DropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String)



    '    Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
    '    oCon.Open()
    '    Dim oCom As New SqlClient.SqlCommand("exec " & SQLStatement, oCon)
    '    Dim oDr As SqlClient.SqlDataReader
    '    oDr = oCom.ExecuteReader
    '    oDDL.Items.Clear()
    '    Do While oDr.Read()

    '        Dim MyItem As New ListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))

    '        oDDL.Items.Add(MyItem)

    '    Loop
    '    oDr.Close()
    '    oCom.Connection.Close()
    '    oCon.Close()

    'End Sub




    Sub SetListBox(ByVal oDDL As System.Web.UI.WebControls.ListBox, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String)

        Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
        oCon.Open()
        Dim oCom As New SqlClient.SqlCommand("exec " & SQLStatement, oCon)
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

    'Private Function CheckStringNull(ByVal oObj As Object) As Object
    '    If IsDBNull(oObj) Then
    '        Return ""
    '    Else
    '        Return oObj
    '    End If
    'End Function
    Public Sub FillListBox(ByVal SQLstatement As String, ByVal SelectSQL As String, ByRef lstBox As System.Web.UI.WebControls.ListBox)

        Dim oDa As New SqlClient.SqlDataAdapter(SQLstatement & "," & SelectSQL, ConnectionString)
        Dim oDs As New DataSet

        Dim iSelectedIndex As Integer = -1

        lstBox.Items.Clear()
        oDa.Fill(oDs)
        lstBox.DataSource = oDs.Tables(0)
        lstBox.DataTextField = "Name"
        lstBox.DataValueField = "Id"
        lstBox.DataBind()
    End Sub
    Public Sub FillListBox(ByVal SQLstatement As String, ByRef lstBox As System.Web.UI.WebControls.ListBox)

        Dim oDa As New SqlClient.SqlDataAdapter(SQLstatement, ConnectionString)
        Dim oDs As New DataSet

        Dim iSelectedIndex As Integer = -1

        lstBox.Items.Clear()
        oDa.Fill(oDs)
        lstBox.DataSource = oDs.Tables(0)
        lstBox.DataTextField = "Name"
        lstBox.DataValueField = "Id"
        lstBox.DataBind()
    End Sub

    Public Sub SetRadComboCheckBox(oCombo As RadComboBox, sList As String)

        Dim arrItem As Array = sList.Split(",")



        For z As Integer = 0 To arrItem.Length - 1
            Dim sListitem As String = arrItem(z)
            For Each oItem As Telerik.Web.UI.RadComboBoxItem In oCombo.Items
                If sListitem = oItem.Value Then
                    oItem.Checked = True
                End If
            Next
        Next


    End Sub

    Public Sub SetRadComboCheckBox(oCombo As RadDropDownTree, sList As String)

        oCombo.EmbeddedTree.UncheckAllNodes()

        Dim arrItem As Array = sList.Split(",")



        For z As Integer = 0 To arrItem.Length - 1
            Dim sListitem As String = arrItem(z)
            Dim oItem As Telerik.Web.UI.RadTreeNode = oCombo.EmbeddedTree.FindNodeByValue(sListitem)
            If Not oItem Is Nothing Then
                If sListitem = oItem.Value Then
                    oItem.Checked = True
                End If
            End If
        Next
    End Sub

    Public Function FormatDateFr(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return ""
        Dim d As DateTime = CDate(value)
        Return d.ToString("dd MMM yyyy", New System.Globalization.CultureInfo("fr-FR"))
    End Function

    ' =========================================================================
    ' Square - jeton d'acces de la compagnie (OAuth par abonne)
    ' =========================================================================

    ''' <summary>
    ''' Retourne un access token Square valide pour la compagnie courante.
    ''' Rafraichit automatiquement si l'expiration approche. A defaut de
    ''' connexion OAuth, retombe sur le jeton unique de Web.config (sandbox).
    ''' </summary>
    Public Function GetValidSquareAccessToken() As String
        Try
            Dim col As New Collection
            col.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0663GetCompanySquareAuth", col)

            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim row As DataRow = ds.Tables(0).Rows(0)
                Dim accEnc As String = If(IsDBNull(row("SquareAccessTokenEnc")), "", row("SquareAccessTokenEnc").ToString())

                If Not String.IsNullOrEmpty(accEnc) Then
                    Dim access As String = clsCrypto.Decrypt(accEnc)
                    Dim expires As DateTime = If(IsDBNull(row("SquareTokenExpiresAt")), DateTime.MinValue, CDate(row("SquareTokenExpiresAt")))

                    ' Rafraichir si le jeton expire dans moins de 7 jours
                    If expires <> DateTime.MinValue AndAlso expires <= DateTime.Now.AddDays(7) Then
                        Dim refEnc As String = If(IsDBNull(row("SquareRefreshTokenEnc")), "", row("SquareRefreshTokenEnc").ToString())
                        If Not String.IsNullOrEmpty(refEnc) Then
                            Try
                                Dim info As clsSquare.SquareTokenInfo = clsSquare.RefreshAccessToken(clsCrypto.Decrypt(refEnc))
                                SaveCompanySquareTokens(info, Nothing, Nothing)
                                access = info.AccessToken
                            Catch
                                ' Garder l'ancien jeton si le refresh echoue
                            End Try
                        End If
                    End If
                    Return access
                End If
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("GetValidSquareAccessToken: " & ex.Message)
        End Try

        ' Fallback : jeton unique de Web.config (utile en sandbox avant OAuth)
        Return System.Configuration.ConfigurationManager.AppSettings("Square.AccessToken")
    End Function

    ''' <summary>Location Square principale de la compagnie (pour le terminal).</summary>
    Public Function GetCompanySquareLocationId() As String
        Try
            Dim col As New Collection
            col.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0663GetCompanySquareAuth", col)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim row As DataRow = ds.Tables(0).Rows(0)
                If Not IsDBNull(row("SquareLocationId")) Then Return row("SquareLocationId").ToString()
            End If
        Catch
        End Try
        Return ""
    End Function

    ''' <summary>Octets du logo de la compagnie courante (T010Company.Logo) via s0690GetCompanyLogo,
    ''' ou Nothing si aucun logo. Utilisé pour le PDF de facture et l'en-tête de l'app.</summary>
    Public Function GetCompanyLogoBytes() As Byte()
        Try
            Dim col As New Collection
            col.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0690GetCompanyLogo", col)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                If Not IsDBNull(r("Logo")) Then
                    Dim bytes As Byte() = CType(r("Logo"), Byte())
                    If bytes IsNot Nothing AndAlso bytes.Length > 0 Then Return bytes
                End If
            End If
        Catch
        End Try
        Return Nothing
    End Function

    ''' <summary>Indique si la compagnie a connecte un compte Square (OAuth).</summary>
    Public Function IsSquareConnected() As Boolean
        Try
            Dim col As New Collection
            col.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0663GetCompanySquareAuth", col)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return Not IsDBNull(ds.Tables(0).Rows(0)("SquareAccessTokenEnc"))
            End If
        Catch
        End Try
        Return False
    End Function

    ''' <summary>Enregistre (chiffres) les jetons Square de la compagnie courante.</summary>
    Public Sub SaveCompanySquareTokens(info As clsSquare.SquareTokenInfo, merchantId As String, locationId As String)
        Dim col As New Collection
        col.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        col.Add(New SqlClient.SqlParameter("@MerchantId", If(String.IsNullOrEmpty(merchantId), CObj(DBNull.Value), merchantId)))
        col.Add(New SqlClient.SqlParameter("@AccessTokenEnc", If(info Is Nothing OrElse String.IsNullOrEmpty(info.AccessToken), CObj(DBNull.Value), clsCrypto.Encrypt(info.AccessToken))))
        col.Add(New SqlClient.SqlParameter("@RefreshTokenEnc", If(info Is Nothing OrElse String.IsNullOrEmpty(info.RefreshToken), CObj(DBNull.Value), clsCrypto.Encrypt(info.RefreshToken))))
        col.Add(New SqlClient.SqlParameter("@ExpiresAt", If(info Is Nothing OrElse info.ExpiresAt = DateTime.MinValue, CObj(DBNull.Value), CObj(info.ExpiresAt))))
        col.Add(New SqlClient.SqlParameter("@LocationId", If(String.IsNullOrEmpty(locationId), CObj(DBNull.Value), locationId)))
        ExecuteSQL("s0662SaveCompanySquareTokens", col)
    End Sub


    ' ══════════════════════════════════════════════════════════════════════
    '  Actions permises dans un dossier (T393)
    '  Un employé du cabinet entré dans l'ERP d'un client n'ouvre que les
    '  pages des actions que l'administrateur lui a cochées pour ce dossier
    '  (« Gérer les dossiers »). Sinon : retour à l'accueil, avec un message.
    ' ══════════════════════════════════════════════════════════════════════
    Protected Overrides Sub OnLoad(e As EventArgs)
        Dim refus As String = ""
        Try
            If Session IsNot Nothing AndAlso Session("UserId") IsNot Nothing AndAlso IsAccountant AndAlso Company <> Guid.Empty Then
                Dim action As String = clsActionsDossier.ActionDePage(Me.AppRelativeVirtualPath)
                If action <> "" AndAlso Not clsActionsDossier.PagePermise(UserEmail, Company, Me.AppRelativeVirtualPath) Then
                    refus = clsActionsDossier.Libelle(action, CurrentLang)
                End If
            End If
        Catch
            refus = ""
        End Try

        If refus <> "" Then
            Session("ActionRefusee") = refus
            Response.Redirect("~/Default.aspx", True)
            Return
        End If

        ' Le message du refus, affiché sur la page d'arrivée
        Try
            If Session IsNot Nothing AndAlso Session("ActionRefusee") IsNot Nothing Then
                Dim zone As String = Convert.ToString(Session("ActionRefusee"))
                Session.Remove("ActionRefusee")
                Dim l As String = CurrentLang
                Dim msg As String = If(l = "en", "Your firm has not given you access to """ & zone & """ in this file.",
                                    If(l = "es", "Su despacho no le dio acceso a «" & zone & "» en este expediente.",
                                       "Votre cabinet ne vous a pas donné accès à « " & zone & " » dans ce dossier."))
                ShowMessageBox(msg, If(l = "en", "Access", If(l = "es", "Acceso", "Accès")))
            End If
        Catch
        End Try

        MyBase.OnLoad(e)
    End Sub


    ' ══════════════════════════════════════════════════════════════════════
    '  Accès restreint = lecture seule (T395)
    '  Dans une zone dont le niveau est « restreint » pour l'employé du
    '  cabinet, la page se consulte mais aucune écriture n'atteint la base :
    '  ExecuteSQL (écritures) et ExecuteSQLds sur une procédure qui écrit
    '  lèvent LectureSeuleException ; OnError la transforme en message.
    ' ══════════════════════════════════════════════════════════════════════
    Private _lectureSeule As Boolean? = Nothing

    ''' <summary>Vrai si la page courante est en lecture seule pour l'utilisateur (niveau « restreint »).</summary>
    Public ReadOnly Property LectureSeule As Boolean
        Get
            If _lectureSeule.HasValue Then Return _lectureSeule.Value
            ' Garde anti-récursion : lire le courriel ou la compagnie peut interroger la
            ' base (ExecuteSQLds → GarderLectureSeule → LectureSeule) pendant le calcul.
            _lectureSeule = False
            Dim r As Boolean = False
            Try
                If Session IsNot Nothing AndAlso Session("UserId") IsNot Nothing AndAlso IsAccountant AndAlso Company <> Guid.Empty Then
                    Dim action As String = clsActionsDossier.ActionDePage(Me.AppRelativeVirtualPath)
                    If action <> "" Then r = (clsActionsDossier.NiveauDe(UserEmail, Company, action) = "restreint")
                End If
            Catch
                r = False
            End Try
            _lectureSeule = r
            Return r
        End Get
    End Property

    ' Procédures qui ne font que lire, même appelées par ExecuteSQL
    Private Shared ReadOnly VerbesLecture As String() = {"Get", "List", "Count", "Valid", "Check", "Find", "Search", "Read", "Lire", "Is", "Exists", "Load"}
    ' Verbes d'écriture (ExecuteSQLds sert surtout à lire, sauf ces procédures)
    Private Shared ReadOnly VerbesEcriture As String() = {"Insert", "Update", "Delete", "Save", "Set", "Create", "Assign", "Add", "Remove",
        "Annuler", "Lier", "Delier", "Comptabiliser", "Marquer", "Regler", "Generer", "Supprimer", "Creer", "Enregistrer", "Import",
        "Push", "Apply", "Applique", "Approve", "Reject", "Cancel", "Close", "Cloturer", "Rouvrir", "Inscrire", "Ignorer", "Simuler", "Reset", "Restore", "Accept"}

    ''' <summary>Le nom de la procédure sans le préfixe « sNNNN » / « sp_ » / « dbo. ».</summary>
    Private Shared Function VerbeDe(proc As String) As String
        Dim n As String = If(proc, "").Trim()
        If n.StartsWith("dbo.", StringComparison.OrdinalIgnoreCase) Then n = n.Substring(4)
        If n.StartsWith("sp_", StringComparison.OrdinalIgnoreCase) Then Return n.Substring(3)
        If n.Length > 5 AndAlso (n(0) = "s"c OrElse n(0) = "S"c) AndAlso Char.IsDigit(n(1)) Then
            Dim i As Integer = 1
            While i < n.Length AndAlso Char.IsDigit(n(i)) : i += 1 : End While
            Return n.Substring(i)
        End If
        Return n
    End Function

    Private Shared Function CommencePar(nom As String, verbes As String()) As Boolean
        For Each v As String In verbes
            If nom.StartsWith(v, StringComparison.OrdinalIgnoreCase) Then Return True
        Next
        Return False
    End Function

    ''' <summary>Refuse une écriture en lecture seule. nonQuery = appel par ExecuteSQL (écriture sauf verbe de lecture).</summary>
    Private Sub GarderLectureSeule(proc As String, nonQuery As Boolean)
        If Not LectureSeule Then Return
        Dim nom As String = VerbeDe(proc)
        Dim ecrit As Boolean = If(nonQuery, Not CommencePar(nom, VerbesLecture), CommencePar(nom, VerbesEcriture))
        If ecrit Then Throw New LectureSeuleException(MessageLectureSeule())
    End Sub

    Private Function MessageLectureSeule() As String
        Select Case CurrentLang
            Case "en" : Return "Read-only access: your firm lets you view this area of the file, but not change it. Nothing was saved."
            Case "es" : Return "Acceso de solo lectura: su despacho le permite consultar esta zona del expediente, pero no modificarla. No se guardó nada."
            Case Else : Return "Accès en lecture seule : votre cabinet vous permet de consulter cette zone du dossier, mais pas de la modifier. Rien n'a été enregistré."
        End Select
    End Function

    ''' <summary>Une écriture refusée et non interceptée par la page : message, puis retour à la même page.</summary>
    Protected Overrides Sub OnError(e As EventArgs)
        Dim ex As Exception = Server.GetLastError()
        While ex IsNot Nothing AndAlso Not TypeOf ex Is LectureSeuleException
            ex = ex.InnerException
        End While
        If ex IsNot Nothing Then
            Server.ClearError()
            Session("LectureSeuleMsg") = ex.Message
            ' Fin nette de la requête : la page interrompue ne doit pas se rendre
            Response.Clear()
            Response.Redirect(Request.RawUrl, True)
            Return
        End If
        MyBase.OnError(e)
    End Sub

    ''' <summary>Bandeau « Lecture seule » et boutons de modification grisés (js/appPopup.js : appLectureSeule).</summary>
    Protected Overrides Sub OnPreRender(e As EventArgs)
        MyBase.OnPreRender(e)
        Try
            If LectureSeule Then
                Dim l As String = CurrentLang
                Dim txt As String = If(l = "en", "Read-only — your firm gives you restricted access to this area of the file: you can view it but not change it.",
                                    If(l = "es", "Solo lectura — su despacho le da un acceso restringido a esta zona del expediente: puede consultarla pero no modificarla.",
                                       "Lecture seule — votre cabinet vous donne un accès restreint à cette zone du dossier : vous pouvez la consulter, mais pas la modifier."))
                ScriptManager.RegisterStartupScript(Me, Me.GetType(), "lectureSeule",
                    "if (window.appLectureSeule) appLectureSeule('" & HttpUtility.JavaScriptStringEncode(txt) & "');", True)
            End If
            If Session IsNot Nothing AndAlso Session("LectureSeuleMsg") IsNot Nothing Then
                Dim m As String = Convert.ToString(Session("LectureSeuleMsg"))
                Session.Remove("LectureSeuleMsg")
                ShowMessageBox(m, If(CurrentLang = "en", "Read-only", If(CurrentLang = "es", "Solo lectura", "Lecture seule")))
            End If
        Catch
        End Try
    End Sub

End Class
