Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Security.Cryptography
Imports System.Text
Imports System.Web

''' <summary>
''' « Se souvenir de moi » (login persistant) pour le portail des abonnes.
''' Patron « split token » : le cookie AbnRemember = Selector:Validator ; la
''' base ne stocke que SHA-256(Validator). A la restauration, le hash est
''' compare en temps constant, puis le jeton est **roule** (ancien supprime,
''' nouveau emis avec une nouvelle echeance glissante) pour limiter la fenetre
''' de rejeu. Ecrit directement les valeurs de session lues par clsData.
''' </summary>
Public Class clsRememberMe

    Public Const CookieName As String = "AbnRemember"
    Private Const PersistDays As Integer = 30

    Private Shared ReadOnly Property ConnStr() As String
        Get
            Return ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    ' =====================================================================
    ' Emission (login avec « se souvenir de moi » coche)
    ' =====================================================================
    Public Shared Sub Issue(ctx As HttpContext, abonneUserId As Integer)
        Try
            If ctx Is Nothing Then Return
            Dim selector As String = RandHex(12)    ' 24 caracteres
            Dim validator As String = RandHex(32)   ' 64 caracteres
            Dim expires As DateTime = DateTime.UtcNow.AddDays(PersistDays)

            Using cn As New SqlConnection(ConnStr)
                Using cmd As New SqlCommand("s0074InsertRememberToken", cn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@AbonneUserId", abonneUserId)
                    cmd.Parameters.AddWithValue("@Selector", selector)
                    cmd.Parameters.AddWithValue("@ValidatorHash", Sha256Hex(validator))
                    cmd.Parameters.AddWithValue("@ExpiresUtc", expires)
                    cn.Open()
                    cmd.ExecuteNonQuery()
                End Using
            End Using

            WriteCookie(ctx, selector & ":" & validator, expires)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Remember Issue: " & ex.Message)
        End Try
    End Sub

    ' =====================================================================
    ' Restauration (point d'interception : Global.asax AcquireRequestState)
    ' =====================================================================
    Public Shared Sub TryRestore(ctx As HttpContext)
        Try
            If ctx Is Nothing OrElse ctx.Session Is Nothing Then Return
            ' Deja authentifie : rien a faire.
            Dim cur As Object = ctx.Session("AbnUserId")
            If cur IsNot Nothing AndAlso CInt(cur) <> 0 Then Return

            Dim c As HttpCookie = ctx.Request.Cookies(CookieName)
            If c Is Nothing OrElse String.IsNullOrEmpty(c.Value) Then Return

            Dim parts As String() = c.Value.Split(":"c)
            If parts.Length <> 2 OrElse parts(0).Length = 0 OrElse parts(1).Length = 0 Then
                ClearCookie(ctx) : Return
            End If
            Dim selector As String = parts(0)
            Dim validator As String = parts(1)

            Dim row As DataRow = GetToken(selector)
            If row Is Nothing Then
                ClearCookie(ctx) : Return
            End If

            ' Expiration.
            If CDate(row("ExpiresUtc")) < DateTime.UtcNow Then
                DeleteToken(selector) : ClearCookie(ctx) : Return
            End If
            ' Validateur (comparaison en temps constant).
            If Not FixedTimeEquals(Sha256Hex(validator), row("ValidatorHash").ToString()) Then
                ' Cookie invalide (potentiel vol) : on revoque le jeton.
                DeleteToken(selector) : ClearCookie(ctx) : Return
            End If
            ' Compte utilisateur actif ?
            If IsDBNull(row("IsActive")) OrElse Not CBool(row("IsActive")) Then
                DeleteToken(selector) : ClearCookie(ctx) : Return
            End If
            ' Abonne non suspendu / ferme ?
            Dim statut As String = If(IsDBNull(row("AbonneStatut")), "", row("AbonneStatut").ToString())
            If statut = "Suspendu" OrElse statut = "Ferme" OrElse statut = "Fermé" Then
                DeleteToken(selector) : ClearCookie(ctx) : Return
            End If

            ' --- Restauration de la session (memes cles que clsData) ---
            Dim uid As Integer = CInt(row("AbonneUserId"))
            ctx.Session("AbnUserId") = uid
            ctx.Session("AbnId") = CInt(row("AbonneId"))
            ctx.Session("AbnUserEmail") = row("Email").ToString()
            ctx.Session("AbnUserName") = ((If(IsDBNull(row("FirstName")), "", row("FirstName").ToString())) & " " &
                                          (If(IsDBNull(row("LastName")), "", row("LastName").ToString()))).Trim()
            ctx.Session("AbnName") = If(IsDBNull(row("NomAffichage")) OrElse row("NomAffichage").ToString().Length = 0,
                                        row("RaisonSociale").ToString(), row("NomAffichage").ToString())
            ctx.Session("AbnIsAdmin") = (Not IsDBNull(row("IsAdmin")) AndAlso CBool(row("IsAdmin")))

            ' --- Rotation : on supprime l'ancien jeton et on en emet un nouveau. ---
            DeleteToken(selector)
            Issue(ctx, uid)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Remember TryRestore: " & ex.Message)
        End Try
    End Sub

    ' =====================================================================
    ' Effacement (deconnexion)
    ' =====================================================================
    Public Shared Sub Clear(ctx As HttpContext)
        Try
            If ctx Is Nothing Then Return
            Dim c As HttpCookie = ctx.Request.Cookies(CookieName)
            If c IsNot Nothing AndAlso Not String.IsNullOrEmpty(c.Value) Then
                Dim parts As String() = c.Value.Split(":"c)
                If parts.Length >= 1 AndAlso parts(0).Length > 0 Then DeleteToken(parts(0))
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Remember Clear: " & ex.Message)
        End Try
        ClearCookie(ctx)
    End Sub

    ' =====================================================================
    ' Acces BD + helpers
    ' =====================================================================
    Private Shared Function GetToken(selector As String) As DataRow
        Using cn As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand("s0075GetRememberToken", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@Selector", selector)
                Dim da As New SqlDataAdapter(cmd)
                Dim dt As New DataTable()
                da.Fill(dt)
                If dt.Rows.Count = 0 Then Return Nothing
                Return dt.Rows(0)
            End Using
        End Using
    End Function

    Private Shared Sub DeleteToken(selector As String)
        Try
            Using cn As New SqlConnection(ConnStr)
                Using cmd As New SqlCommand("s0076DeleteRememberToken", cn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@Selector", selector)
                    cn.Open()
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Remember DeleteToken: " & ex.Message)
        End Try
    End Sub

    Private Shared Sub WriteCookie(ctx As HttpContext, value As String, expires As DateTime)
        Dim c As New HttpCookie(CookieName, value)
        c.HttpOnly = True
        c.Secure = ctx.Request.IsSecureConnection
        c.SameSite = SameSiteMode.Lax
        c.Path = "/"
        c.Expires = expires.ToLocalTime()   ' HttpCookie.Expires est en heure locale
        ctx.Response.Cookies.Set(c)
    End Sub

    Private Shared Sub ClearCookie(ctx As HttpContext)
        If ctx Is Nothing Then Return
        Dim c As New HttpCookie(CookieName, "")
        c.HttpOnly = True
        c.Secure = ctx.Request.IsSecureConnection
        c.SameSite = SameSiteMode.Lax
        c.Path = "/"
        c.Expires = DateTime.Now.AddDays(-1)   ' expire immediatement
        ctx.Response.Cookies.Set(c)
    End Sub

    Private Shared Function RandHex(nbBytes As Integer) As String
        Dim bytes(nbBytes - 1) As Byte
        Using rng As RandomNumberGenerator = RandomNumberGenerator.Create()
            rng.GetBytes(bytes)
        End Using
        Dim sb As New StringBuilder(nbBytes * 2)
        For Each b As Byte In bytes
            sb.Append(b.ToString("x2"))
        Next
        Return sb.ToString()
    End Function

    Private Shared Function Sha256Hex(value As String) As String
        Using sha As SHA256 = SHA256.Create()
            Dim bytes As Byte() = sha.ComputeHash(Encoding.UTF8.GetBytes(value))
            Dim sb As New StringBuilder(bytes.Length * 2)
            For Each b As Byte In bytes
                sb.Append(b.ToString("x2"))
            Next
            Return sb.ToString()
        End Using
    End Function

    ''' <summary>Comparaison a temps constant de deux chaines hex de meme longueur.</summary>
    Private Shared Function FixedTimeEquals(a As String, b As String) As Boolean
        If a Is Nothing OrElse b Is Nothing Then Return False
        Dim aa As String = a.Trim()
        Dim bb As String = b.Trim()
        If aa.Length <> bb.Length Then Return False
        Dim diff As Integer = 0
        For i As Integer = 0 To aa.Length - 1
            diff = diff Or (AscW(aa(i)) Xor AscW(bb(i)))
        Next
        Return (diff = 0)
    End Function

End Class
