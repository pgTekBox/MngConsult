Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Cible du lien de vérification du courriel d'entreprise envoyé par wbfSetting.
''' Le token (24 h) est validé par s0692VerifyCompanyMail, qui confirme l'adresse
''' dans T010Company. La page est publique : le lien est cliqué depuis la boîte
''' de réception, pas nécessairement dans une session ouverte.
''' </summary>
Public Class wbfVerifyCompanyMail
    Inherits clsData

    ''' <summary>Applique la langue aux contrôles serveur et au titre.</summary>
    Private Sub ApplyLocalization()
        Page.Title = L("pageTitle")
        For Each lnk As HyperLink In New HyperLink() {lnkSettings, lnkSettingsExpired, lnkSettingsAlready, lnkSettingsInvalid}
            lnk.Text = L("settingsBtn")
            lnk.NavigateUrl = "~/wbfSetting.aspx?lang=" & CurrentLang
        Next
    End Sub

    ''' <summary>Traductions de la page de vérification (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Vérification du courriel — 60Sec-AI", "Email verification — 60Sec-AI", "Verificación del correo — 60Sec-AI")
            Case "successTitle" : Return Choose3(lang, "Adresse vérifiée !", "Address verified!", "¡Dirección verificada!")
            Case "successBefore" : Return Choose3(lang, "L'adresse courriel de votre entreprise est confirmée : ", "Your company email address is confirmed: ", "La dirección de correo de su empresa está confirmada: ")
            Case "successAfter" : Return Choose3(lang, ".", ".", ".")
            Case "expiredTitle" : Return Choose3(lang, "Lien expiré", "Link expired", "Enlace caducado")
            Case "expiredMsg" : Return Choose3(lang, "Ce lien de vérification a expiré (durée maximale : 24 heures). Retournez dans les paramètres pour en demander un nouveau.", "This verification link has expired (maximum 24 hours). Go back to the settings to request a new one.", "Este enlace de verificación ha caducado (máximo 24 horas). Vuelva a los ajustes para solicitar uno nuevo.")
            Case "alreadyTitle" : Return Choose3(lang, "Adresse déjà vérifiée", "Address already verified", "Dirección ya verificada")
            Case "alreadyMsg" : Return Choose3(lang, "Cette adresse courriel a déjà été confirmée. Il n'y a rien de plus à faire.", "This email address has already been confirmed. There is nothing more to do.", "Esta dirección de correo ya fue confirmada. No hay nada más que hacer.")
            Case "invalidTitle" : Return Choose3(lang, "Lien invalide", "Invalid link", "Enlace no válido")
            Case "invalidMsg" : Return Choose3(lang, "Ce lien n'est pas valide ou a été remplacé par une demande plus récente. Retournez dans les paramètres pour relancer la vérification.", "This link is not valid or has been replaced by a more recent request. Go back to the settings to start the verification again.", "Este enlace no es válido o fue reemplazado por una solicitud más reciente. Vuelva a los ajustes para reiniciar la verificación.")
            Case "settingsBtn" : Return Choose3(lang, "Aller aux paramètres", "Go to settings", "Ir a los ajustes")
            Case Else : Return ""
        End Select
    End Function

    Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ApplyLocalization()

        If IsPostBack Then Return

        Dim tokenStr As String = Request.QueryString("token")
        Dim token As Guid

        If String.IsNullOrEmpty(tokenStr) OrElse Not Guid.TryParse(tokenStr, token) Then
            pnlInvalid.Visible = True
            Return
        End If

        VerifyMail(token)
    End Sub

    Private Sub VerifyMail(token As Guid)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Token", token))

            Dim ds As DataSet = ExecuteSQLds("s0692VerifyCompanyMail", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                pnlInvalid.Visible = True
                Return
            End If

            Dim r As DataRow = ds.Tables(0).Rows(0)
            Dim result As Integer = If(IsDBNull(r("Result")), 0, CInt(r("Result")))
            Dim email As String = If(IsDBNull(r("Email")), "", r("Email").ToString())

            Select Case result
                Case 1
                    litEmail.Text = Server.HtmlEncode(email)
                    pnlSuccess.Visible = True
                Case -1
                    pnlExpired.Visible = True
                Case -2
                    pnlAlready.Visible = True
                Case Else
                    pnlInvalid.Visible = True
            End Select

        Catch
            pnlInvalid.Visible = True
        End Try
    End Sub

End Class
