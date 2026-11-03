Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Page publique (anonyme) de confirmation du courriel d'une demande « Réserver
''' ma place ». Le lien du courriel de validation mène ici avec ?t=&lt;jeton&gt; ;
''' s0962ValidateLandingReservation marque la demande validée. Trilingue (?lang).
''' </summary>
Public Class LandingValidation
    Inherits System.Web.UI.Page

    Protected litTitre As System.Web.UI.WebControls.Literal
    Protected litMessage As System.Web.UI.WebControls.Literal
    Protected litLang As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim lang As String = (If(Request.QueryString("lang"), "fr")).Trim().ToLowerInvariant()
        lang = If(lang.Length >= 2, lang.Substring(0, 2), "fr")
        If lang <> "en" AndAlso lang <> "es" Then lang = "fr"
        litLang.Text = lang

        Dim token As String = If(Request.QueryString("t"), "").Trim()
        Dim etat As String = "erreur"   ' erreur | ok | deja | introuvable

        Dim g As Guid
        If Guid.TryParse(token, g) Then
            Try
                Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                    Using cmd As New SqlCommand("s0962ValidateLandingReservation", conn) With {.CommandType = CommandType.StoredProcedure}
                        cmd.Parameters.Add(New SqlParameter("@Token", g))
                        conn.Open()
                        Using rd As SqlDataReader = cmd.ExecuteReader()
                            If rd.Read() Then
                                Dim trouve As Boolean = Convert.ToInt32(rd("Trouve")) = 1
                                Dim deja As Boolean = Convert.ToInt32(rd("DejaValide")) = 1
                                etat = If(Not trouve, "introuvable", If(deja, "deja", "ok"))
                            End If
                        End Using
                    End Using
                End Using
            Catch
                etat = "erreur"
            End Try
        End If

        litTitre.Text = Titre(lang, etat)
        litMessage.Text = Message(lang, etat)
    End Sub

    Private Shared Function T(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Shared Function Titre(lang As String, etat As String) As String
        Select Case etat
            Case "ok" : Return T(lang, "Adresse confirmée", "Email confirmed", "Correo confirmado")
            Case "deja" : Return T(lang, "Déjà confirmée", "Already confirmed", "Ya confirmado")
            Case "introuvable" : Return T(lang, "Lien introuvable", "Link not found", "Enlace no encontrado")
            Case Else : Return T(lang, "Lien invalide", "Invalid link", "Enlace no válido")
        End Select
    End Function

    Private Shared Function Message(lang As String, etat As String) As String
        Select Case etat
            Case "ok"
                Return T(lang,
                         "Merci ! Votre adresse courriel est confirmée. Nous vous écrirons en priorité dès l'ouverture, le 1er avril 2027.",
                         "Thank you! Your email address is confirmed. We will contact you first when we open, on April 1, 2027.",
                         "¡Gracias! Su dirección de correo está confirmada. Le escribiremos con prioridad en la apertura, el 1 de abril de 2027.")
            Case "deja"
                Return T(lang,
                         "Cette adresse était déjà confirmée. Il n'y a rien d'autre à faire.",
                         "This address was already confirmed. There is nothing more to do.",
                         "Esta dirección ya estaba confirmada. No hay nada más que hacer.")
            Case "introuvable"
                Return T(lang,
                         "Ce lien de validation ne correspond à aucune demande. Il a peut-être déjà servi ou expiré.",
                         "This validation link matches no request. It may have already been used or expired.",
                         "Este enlace de validación no corresponde a ninguna solicitud. Quizá ya se usó o caducó.")
            Case Else
                Return T(lang,
                         "Le lien de validation est incomplet ou invalide. Vérifiez l'adresse ou réessayez à partir du courriel reçu.",
                         "The validation link is incomplete or invalid. Check the address or try again from the email you received.",
                         "El enlace de validación está incompleto o no es válido. Verifique la dirección o inténtelo de nuevo desde el correo recibido.")
        End Select
    End Function

End Class
