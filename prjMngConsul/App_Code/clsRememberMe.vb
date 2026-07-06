Imports System
Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Security.Cryptography
Imports System.Text
Imports System.Web

''' <summary>
''' Connexion persistante « Se souvenir de moi » (7 jours).
''' Patron « split token » : le cookie contient Selector:Validator ; la base ne
''' stocke que SHA-256(Validator). À chaque restauration, comparaison en temps
''' constant puis rotation du jeton (fenêtre glissante). Le cookie est HttpOnly
''' et Secure en HTTPS. Table T016UserRememberToken, procs s0682/s0683/s0684.
''' </summary>
Public Class clsRememberMe

    Public Const CookieName As String = "MngConsulRemember"
    Private Const DAYS As Integer = 7
    Private Const SELECTOR_BYTES As Integer = 12
    Private Const VALIDATOR_BYTES As Integer = 32

    Private Shared ReadOnly Property ConnString As String
        Get
            Return ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    ''' <summary>
    ''' Génère un jeton persistant, l'enregistre (haché) et pose le cookie 7 jours.
    ''' Appelé au login quand « Se souvenir de moi » est coché.
    ''' </summary>
    Public Shared Sub Issue(ctx As HttpContext, userId As Integer)
        Try
            Dim selector As String = RandBase64Url(SELECTOR_BYTES)
            Dim validator As String = RandBase64Url(VALIDATOR_BYTES)
            Dim expires As DateTime = DateTime.Now.AddDays(DAYS)

            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", userId))
            p.Add(New SqlParameter("@Selector", selector))
            p.Add(New SqlParameter("@ValidatorHash", Sha256Base64(validator)))
            p.Add(New SqlParameter("@ExpiresOn", expires))
            ExecNonQuery("s0682InsertRememberToken", p)

            Dim ck As New HttpCookie(CookieName, selector & ":" & validator)
            ck.HttpOnly = True
            ck.Secure = ctx.Request.IsSecureConnection
            ck.SameSite = SameSiteMode.Lax
            ck.Expires = expires
            ck.Path = "/"
            ctx.Response.Cookies.Add(ck)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("RememberMe.Issue: " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Tente de restaurer la session depuis le cookie. Pose Session("UserId") et
    ''' Session("Company") comme un login normal, puis fait tourner le jeton.
    ''' Retourne True si la session a été restaurée.
    ''' </summary>
    Public Shared Function TryRestore(ctx As HttpContext) As Boolean
        Try
            Dim ck As HttpCookie = ctx.Request.Cookies(CookieName)
            If ck Is Nothing OrElse String.IsNullOrEmpty(ck.Value) Then Return False

            Dim parts() As String = ck.Value.Split(":"c)
            If parts.Length <> 2 OrElse parts(0).Length = 0 OrElse parts(1).Length = 0 Then
                ClearCookie(ctx)
                Return False
            End If

            Dim selector As String = parts(0)
            Dim validator As String = parts(1)

            Dim p As New Collection
            p.Add(New SqlParameter("@Selector", selector))
            Dim row As DataRow = ExecSingle("s0683GetRememberToken", p)
            If row Is Nothing Then
                ClearCookie(ctx)
                Return False
            End If

            ' Comparaison en temps constant du hash du validator.
            If Not FixedEquals(row("ValidatorHash").ToString(), Sha256Base64(validator)) Then
                ' Cookie forgé / validator invalide : révoquer ce selector.
                DeleteToken(selector)
                ClearCookie(ctx)
                Return False
            End If

            Dim userId As Integer = Convert.ToInt32(row("UserId"))
            Dim company As Guid = CType(row("CompanyGUID"), Guid)

            ' Restaurer la session (mêmes clés que le login).
            ctx.Session("UserId") = userId
            ctx.Session("Company") = company

            ' Rotation : révoquer l'ancien jeton, en émettre un nouveau (glissant 7j).
            DeleteToken(selector)
            Issue(ctx, userId)
            Return True
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("RememberMe.TryRestore: " & ex.Message)
            Return False
        End Try
    End Function

    ''' <summary>
    ''' Supprime le cookie et le jeton en base. Appelé à la déconnexion.
    ''' </summary>
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
        Dim ck As New HttpCookie(CookieName, "")
        ck.Expires = DateTime.Now.AddDays(-1)
        ck.Path = "/"
        ctx.Response.Cookies.Add(ck)
    End Sub

    Private Shared Sub DeleteToken(selector As String)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Selector", selector))
            ExecNonQuery("s0684DeleteRememberToken", p)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("RememberMe.DeleteToken: " & ex.Message)
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
    Private Shared Sub ExecNonQuery(proc As String, params As Collection)
        Using cn As New SqlConnection(ConnString)
            Using cmd As New SqlCommand(proc, cn)
                cmd.CommandType = CommandType.StoredProcedure
                For Each pr As SqlParameter In params
                    cmd.Parameters.Add(pr)
                Next
                cn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Private Shared Function ExecSingle(proc As String, params As Collection) As DataRow
        Using cn As New SqlConnection(ConnString)
            Using cmd As New SqlCommand(proc, cn)
                cmd.CommandType = CommandType.StoredProcedure
                For Each pr As SqlParameter In params
                    cmd.Parameters.Add(pr)
                Next
                Dim da As New SqlDataAdapter(cmd)
                Dim ds As New DataSet()
                da.Fill(ds)
                If ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then Return ds.Tables(0).Rows(0)
            End Using
        End Using
        Return Nothing
    End Function

End Class
