Imports System.Data
Imports System.Data.SqlClient
Imports BCrypt.Net

Public Class wbfLogin
    Inherits clsData

    ''' <summary>
    ''' Langue courante : ?lang=fr|en|es (défaut fr). Conserve la langue choisie
    ''' sur la landing page à travers l'écran de connexion (transmise via le lien
    ''' « Connexion » et préservée dans le query string au postback).
    ''' </summary>
    Protected ReadOnly Property CurrentLang As String
        Get
            Dim l As String = If(Request.QueryString("lang"), "").Trim().ToLowerInvariant()
            Select Case l
                Case "en", "es", "fr"
                    Return l
                Case Else
                    Return "fr"
            End Select
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ApplyLocalization()

        ' Si déjà connecté, rediriger vers la page d'accueil
        If Not IsPostBack AndAlso Not UserId = 0 Then
            Response.Redirect("~/Default.aspx")
        End If
    End Sub

    ''' <summary>
    ''' Applique la langue courante aux contrôles serveur (titre, bouton, champs).
    ''' Les textes statiques (titres, libellés, pied de page) sont localisés
    ''' directement dans le markup via &lt;%= L("clé") %&gt;.
    ''' </summary>
    Private Sub ApplyLocalization()
        Page.Title = L("pageTitle")
        btnLogin.Text = L("login")
        tbEmail.Attributes("placeholder") = L("emailPh")
        tbPassword.Attributes("placeholder") = "••••••••"
    End Sub

    ''' <summary>
    ''' Traductions de l'interface de connexion (fr/en/es).
    ''' </summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle"
                Return Choose3(lang, "Connexion — 60Sec-AI", "Sign in — 60Sec-AI", "Iniciar sesión — 60Sec-AI")
            Case "welcome"
                Return Choose3(lang, "Bienvenue", "Welcome", "Bienvenido")
            Case "subtitle"
                Return Choose3(lang, "Connectez-vous à 60Sec-AI", "Sign in to 60Sec-AI", "Conéctese a 60Sec-AI")
            Case "email"
                Return Choose3(lang, "Courriel", "Email", "Correo electrónico")
            Case "emailPh"
                Return Choose3(lang, "vous@exemple.com", "you@example.com", "usted@ejemplo.com")
            Case "password"
                Return Choose3(lang, "Mot de passe", "Password", "Contraseña")
            Case "remember"
                Return Choose3(lang, "Se souvenir de moi", "Remember me", "Recordarme")
            Case "forgot"
                Return Choose3(lang, "Mot de passe oublié ?", "Forgot password?", "¿Contraseña olvidada?")
            Case "login"
                Return Choose3(lang, "Se connecter", "Sign in", "Iniciar sesión")
            Case "footer"
                Return Choose3(lang, "© 2026 60Sec-AI — Tous droits réservés", "© 2026 60Sec-AI — All rights reserved", "© 2026 60Sec-AI — Todos los derechos reservados")
            Case "errEmpty"
                Return Choose3(lang, "Veuillez entrer votre courriel et votre mot de passe.", "Please enter your email and password.", "Por favor, introduzca su correo electrónico y contraseña.")
            Case "errInvalid"
                Return Choose3(lang, "Courriel ou mot de passe incorrect.", "Incorrect email or password.", "Correo electrónico o contraseña incorrectos.")
            Case Else
                Return ""
        End Select
    End Function

    Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Protected Sub btnLogin_Click(sender As Object, e As EventArgs) Handles btnLogin.Click

        Dim email As String = If(tbEmail.Text, "").Trim().ToLower()
        Dim password As String = If(tbPassword.Text, "")

        ' Validation basique
        If String.IsNullOrEmpty(email) OrElse String.IsNullOrEmpty(password) Then
            ShowError(L("errEmpty"))
            Return
        End If

        ' Récupérer l'utilisateur
        Dim userRow As DataRow = GetUserByEmail(email)
        If userRow Is Nothing Then
            ShowError(L("errInvalid"))
            Return
        End If



        ' Vérifier le mot de passe avec bcrypt
        Dim hash As String = userRow("PasswordHash").ToString()
        Dim isValid As Boolean = False
        Try
            isValid = BCrypt.Net.BCrypt.Verify(password, hash)
        Catch
            isValid = False
        End Try

        If Not isValid Then
            ShowError(L("errInvalid"))
            Return
        End If

        ' === Login OK ===

        ' Vérifier qu'il est actif
        If Not CBool(userRow("IsActive")) Then
            Response.Redirect("~/wbfRegister.aspx?ac=" & userRow("ActivationToken").ToString() & "&lang=" & CurrentLang)
            Return
        End If

        UserId = userRow("Id")

        ' « Se souvenir de moi » : cookie de connexion persistant (7 jours).
        If cbRemember.Checked Then
            clsRememberMe.Issue(Context, CInt(userRow("Id")))
        End If

        'Verifier s'il a un abonnement actif (pour le rediriger vers la page de paiement s'il n'en a pas)
        Dim pa As New Collection
        pa.Add(New SqlParameter("@CompanyGUID", CType(userRow("CompanyGUID"), Guid)))
        Dim dsa As DataSet = ExecuteSQLds("s0313GetSubscriptionForPaiement", pa)
        If dsa.Tables(0).Rows.Count = 1 Then
            Response.Redirect("~/wbfPayment.aspx?lang=" & CurrentLang)
            Return
        End If

        Dim pac As New Collection
        pac.Add(New SqlParameter("@UserId", CType(userRow("Id"), Integer)))
        Dim dsac As DataSet = ExecuteSQLds("s0315GetProfileCompleted", pac)
        If dsac.Tables(0).Rows(0)("ProfileCompleted") < 100 Then
            Response.Redirect("~/wbfNewUser.aspx")
            Return
        End If







        Company = CType(userRow("CompanyGUID"), Guid)
        'email = userRow("Email").ToString()


        ' Mettre à jour la dernière connexion
        UpdateLastLogin(userId)

        ' Redirection
        Dim returnUrl As String = Request.QueryString("ReturnUrl")
        If Not String.IsNullOrEmpty(returnUrl) AndAlso returnUrl.StartsWith("/") Then
            Response.Redirect(returnUrl)
        Else
            Response.Redirect("~/Default.aspx")
        End If
    End Sub

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

    Private Sub UpdateLastLogin(userId As Integer)
        Try

            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", userId))


            ExecuteSQL("s0201UpdateLastLogin", p)

        Catch
            ' Non-bloquant
        End Try
    End Sub

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

End Class
