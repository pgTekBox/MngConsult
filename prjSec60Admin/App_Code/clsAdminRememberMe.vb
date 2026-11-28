Imports System
Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Security.Cryptography
Imports System.Text
Imports System.Web

''' <summary>
''' « Se souvenir de moi » de la console (30 jours), indépendant de la clé de
''' chiffrement du serveur (machineKey) : le cookie Forms persistant devenait
''' illisible quand IIS régénérait cette clé, et la connexion mémorisée se perdait.
''' Patron « split token » de l'ERP (clsRememberMe) : le cookie contient
''' sélecteur:validateur ; la base ne garde que SHA-256(validateur) ; comparaison
''' en temps constant puis rotation du jeton à chaque reprise (fenêtre glissante).
''' Cookie HttpOnly, Secure en https. Table T901AdminRememberToken, procs s1040-s1042.
''' </summary>
Public Class clsAdminRememberMe

    Public Const CookieName As String = "Sec60AdminRemember"
    Private Const JOURS As Integer = 30
    Private Const SELECTOR_BYTES As Integer = 12
    Private Const VALIDATOR_BYTES As Integer = 32

    Private Shared ReadOnly Property ConnString As String
        Get
            Return ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    ''' <summary>Émet un jeton (haché en base) et pose le cookie de 30 jours. Appelé au login.</summary>
    Public Shared Sub Issue(ctx As HttpContext, adminId As Integer)
        Try
            Dim selector As String = RandBase64Url(SELECTOR_BYTES)
            Dim validator As String = RandBase64Url(VALIDATOR_BYTES)
            Dim expires As DateTime = DateTime.Now.AddDays(JOURS)

            ExecNonQuery("s1040InsertAdminRememberToken",
                         New SqlParameter("@AdminId", adminId),
                         New SqlParameter("@Selector", selector),
                         New SqlParameter("@ValidatorHash", Sha256Base64(validator)),
                         New SqlParameter("@ExpiresOn", expires))

            Dim ck As New HttpCookie(CookieName, selector & ":" & validator) With {
                .HttpOnly = True,
                .Secure = ctx.Request.IsSecureConnection,
                .SameSite = SameSiteMode.Lax,
                .Expires = expires,
                .Path = "/"
            }
            ctx.Response.Cookies.Add(ck)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("AdminRememberMe.Issue : " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Valide le cookie et retourne le courriel de l'administrateur (actif), ou "" .
    ''' En cas de succès, fait tourner le jeton (nouveau cookie de 30 jours). Ne touche
    ''' pas à la session : appelé avant qu'elle soit disponible (PostAuthenticateRequest).
    ''' </summary>
    Public Shared Function TryRestore(ctx As HttpContext, ByRef adminId As Integer) As String
        adminId = 0
        Try
            Dim ck As HttpCookie = ctx.Request.Cookies(CookieName)
            If ck Is Nothing OrElse String.IsNullOrEmpty(ck.Value) Then Return ""

            Dim parts() As String = ck.Value.Split(":"c)
            If parts.Length <> 2 OrElse parts(0).Length = 0 OrElse parts(1).Length = 0 Then
                ClearCookie(ctx)
                Return ""
            End If
            Dim selector As String = parts(0)
            Dim validator As String = parts(1)

            Dim row As DataRow = ExecSingle("s1041GetAdminRememberToken", New SqlParameter("@Selector", selector))
            If row Is Nothing Then
                ' Jeton expiré, révoqué ou déjà remplacé par une requête parallèle (rotation) :
                ' on n'efface pas le cookie, une réponse voisine vient peut-être d'en poser un neuf.
                Return ""
            End If
            If Not FixedEquals(row("ValidatorHash").ToString(), Sha256Base64(validator)) Then
                ' Cookie forgé ou validateur invalide : révoquer ce sélecteur.
                DeleteToken(selector)
                ClearCookie(ctx)
                Return ""
            End If

            adminId = Convert.ToInt32(row("AdminId"))
            Dim email As String = row("Email").ToString()

            ' Rotation : révoquer l'ancien jeton, en émettre un nouveau (glissant 30 j).
            DeleteToken(selector)
            Issue(ctx, adminId)
            Return email
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("AdminRememberMe.TryRestore : " & ex.Message)
            adminId = 0
            Return ""
        End Try
    End Function

    ''' <summary>Vrai si la requête porte un cookie « Se souvenir de moi ».</summary>
    Public Shared Function HasCookie(ctx As HttpContext) As Boolean
        Dim ck As HttpCookie = ctx.Request.Cookies(CookieName)
        Return ck IsNot Nothing AndAlso Not String.IsNullOrEmpty(ck.Value)
    End Function

    ''' <summary>Supprime le cookie et le jeton en base. Appelé à la déconnexion.</summary>
    Public Shared Sub Clear(ctx As HttpContext)
        Try
            Dim ck As HttpCookie = ctx.Request.Cookies(CookieName)
            If ck IsNot Nothing AndAlso Not String.IsNullOrEmpty(ck.Value) Then
                Dim parts() As String = ck.Value.Split(":"c)
                If parts.Length >= 1 AndAlso parts(0).Length > 0 Then DeleteToken(parts(0))
            End If
        Catch
        End Try
        ClearCookie(ctx)
    End Sub

    Private Shared Sub ClearCookie(ctx As HttpContext)
        Dim ck As New HttpCookie(CookieName, "") With {.Expires = DateTime.Now.AddDays(-1), .Path = "/"}
        ctx.Response.Cookies.Add(ck)
    End Sub

    Private Shared Sub DeleteToken(selector As String)
        Try
            ExecNonQuery("s1042DeleteAdminRememberToken", New SqlParameter("@Selector", selector))
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("AdminRememberMe.DeleteToken : " & ex.Message)
        End Try
    End Sub

    ' ------------------------------------------------------------------ crypto
    Private Shared Function RandBase64Url(nBytes As Integer) As String
        Dim b(nBytes - 1) As Byte
        Using rng As RandomNumberGenerator = RandomNumberGenerator.Create()
            rng.GetBytes(b)
        End Using
        Return Convert.ToBase64String(b).TrimEnd("="c).Replace("+", "-").Replace("/", "_")
    End Function

    Private Shared Function Sha256Base64(s As String) As String
        Using sha As SHA256 = SHA256.Create()
            Return Convert.ToBase64String(sha.ComputeHash(Encoding.UTF8.GetBytes(s)))
        End Using
    End Function

    Private Shared Function FixedEquals(a As String, b As String) As Boolean
        If a Is Nothing OrElse b Is Nothing Then Return False
        Dim ba() As Byte = Encoding.UTF8.GetBytes(a)
        Dim bb() As Byte = Encoding.UTF8.GetBytes(b)
        If ba.Length <> bb.Length Then Return False
        Dim diff As Integer = 0
        For i As Integer = 0 To ba.Length - 1
            diff = diff Or (ba(i) Xor bb(i))
        Next
        Return diff = 0
    End Function

    ' --------------------------------------------------------------- accès BD
    Private Shared Sub ExecNonQuery(proc As String, ParamArray params() As SqlParameter)
        Using cn As New SqlConnection(ConnString)
            Using cmd As New SqlCommand(proc, cn) With {.CommandType = CommandType.StoredProcedure}
                cmd.Parameters.AddRange(params)
                cn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Private Shared Function ExecSingle(proc As String, ParamArray params() As SqlParameter) As DataRow
        Using cn As New SqlConnection(ConnString)
            Using cmd As New SqlCommand(proc, cn) With {.CommandType = CommandType.StoredProcedure}
                cmd.Parameters.AddRange(params)
                Using da As New SqlDataAdapter(cmd)
                    Dim ds As New DataSet()
                    da.Fill(ds)
                    If ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then Return ds.Tables(0).Rows(0)
                End Using
            End Using
        End Using
        Return Nothing
    End Function

End Class
