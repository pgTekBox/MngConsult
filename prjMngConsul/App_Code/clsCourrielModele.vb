Imports System.Text
Imports System.Web

''' <summary>
''' Gabarit commun des courriels de compte de 60Sec-AI (mot de passe, invitation…).
''' HTML pensé pour les logiciels de courriel : tableaux, styles en ligne, largeur
''' 600 px, aucune image externe (le logo est dessiné en HTML), texte de
''' prévisualisation caché, bouton « à l'épreuve » d'Outlook (lien dans un tableau).
''' Tout le texte reçu est encodé ici (HtmlEncode) : l'appelant passe du texte brut.
''' </summary>
Public NotInheritable Class clsCourrielModele

    Private Sub New()
    End Sub

    Private Shared Function E(s As String) As String
        Return HttpUtility.HtmlEncode(If(s, ""))
    End Function

    ''' <summary>
    ''' Construit le courriel.
    ''' </summary>
    ''' <param name="lang">fr / en / es (pied de page)</param>
    ''' <param name="apercu">texte de prévisualisation (ligne grise dans la boîte de réception)</param>
    ''' <param name="titre">grand titre de la carte</param>
    ''' <param name="salut">« Bonjour Luc, »</param>
    ''' <param name="paragraphes">paragraphes de texte brut</param>
    ''' <param name="bouton">libellé du bouton</param>
    ''' <param name="lien">adresse du bouton</param>
    ''' <param name="encadre">texte de l'encadré « Bon à savoir » (sécurité, validité) ; vide = aucun</param>
    ''' <param name="mention">dernière ligne grise (ex. « Si vous n'avez rien demandé… ») ; vide = aucune</param>
    ''' <param name="blocHtml">bloc HTML DÉJÀ ENCODÉ par l'appelant (ex. le reçu de paiement), inséré
    ''' après les paragraphes et avant le bouton ; vide = aucun</param>
    Public Shared Function Construire(lang As String, apercu As String, titre As String, salut As String,
                                      paragraphes As IEnumerable(Of String), bouton As String, lien As String,
                                      encadre As String, mention As String,
                                      Optional blocHtml As String = "") As String
        Dim l As String = If(lang, "fr").ToLowerInvariant()
        Dim T = Function(fr As String, en As String, es As String) If(l = "en", en, If(l = "es", es, fr))
        Dim lienE As String = E(lien)
        Dim sb As New StringBuilder()

        sb.Append("<!DOCTYPE html><html lang=""").Append(E(l)).Append("""><head><meta charset=""utf-8"" />")
        sb.Append("<meta name=""viewport"" content=""width=device-width, initial-scale=1"" />")
        sb.Append("<meta name=""color-scheme"" content=""light"" /><title>").Append(E(titre)).Append("</title></head>")
        sb.Append("<body style=""margin:0;padding:0;background:#EEF2F8;-webkit-text-size-adjust:100%;"">")
        ' Texte de prévisualisation (caché)
        sb.Append("<div style=""display:none;max-height:0;overflow:hidden;opacity:0;color:#EEF2F8;font-size:1px;line-height:1px;"">")
        sb.Append(E(apercu)).Append("&#8203;&nbsp;&#8203;&nbsp;&#8203;&nbsp;</div>")

        sb.Append("<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""background:#EEF2F8;"">")
        sb.Append("<tr><td align=""center"" style=""padding:32px 12px;"">")
        sb.Append("<table role=""presentation"" width=""600"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""width:100%;max-width:600px;"">")

        ' En-tête : le logo 60 (rond mauve) + le nom
        sb.Append("<tr><td style=""padding:0 8px 18px;"">")
        sb.Append("<table role=""presentation"" cellpadding=""0"" cellspacing=""0"" border=""0""><tr>")
        sb.Append("<td style=""width:44px;height:44px;border-radius:22px;background:#6D3FD1;color:#FFFFFF;font:800 18px/44px Arial,Helvetica,sans-serif;text-align:center;"">60</td>")
        sb.Append("<td style=""padding-left:12px;font:800 20px Arial,Helvetica,sans-serif;color:#0E1F3D;"">60Sec-AI</td>")
        sb.Append("</tr></table></td></tr>")

        ' La carte
        sb.Append("<tr><td style=""background:#FFFFFF;border-radius:20px;box-shadow:0 8px 28px rgba(14,31,61,.08);"">")
        ' Bandeau de couleur
        sb.Append("<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0""><tr>")
        sb.Append("<td style=""height:6px;border-radius:20px 20px 0 0;background:#1B4F9C;background-image:linear-gradient(90deg,#1B4F9C,#6D3FD1);font-size:0;line-height:0;"">&nbsp;</td>")
        sb.Append("</tr></table>")

        sb.Append("<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0""><tr><td style=""padding:34px 40px 10px;font-family:Arial,Helvetica,sans-serif;color:#0E1F3D;"">")
        sb.Append("<h1 style=""margin:0 0 18px;font-size:24px;line-height:1.25;font-weight:800;color:#0E1F3D;"">").Append(E(titre)).Append("</h1>")
        If Not String.IsNullOrEmpty(salut) Then
            sb.Append("<p style=""margin:0 0 14px;font-size:16px;line-height:1.55;color:#0E1F3D;"">").Append(E(salut)).Append("</p>")
        End If
        If paragraphes IsNot Nothing Then
            For Each p As String In paragraphes
                If Not String.IsNullOrEmpty(p) Then
                    sb.Append("<p style=""margin:0 0 14px;font-size:15px;line-height:1.6;color:#33415C;"">").Append(E(p)).Append("</p>")
                End If
            Next
        End If
        If Not String.IsNullOrEmpty(blocHtml) Then sb.Append(blocHtml)
        sb.Append("</td></tr>")

        ' Le bouton (tableau : rendu fiable dans Outlook)
        If Not String.IsNullOrEmpty(lien) Then
            sb.Append("<tr><td align=""left"" style=""padding:10px 40px 26px;"">")
            sb.Append("<table role=""presentation"" cellpadding=""0"" cellspacing=""0"" border=""0""><tr>")
            sb.Append("<td align=""center"" style=""border-radius:999px;background:#1B4F9C;"">")
            sb.Append("<a href=""").Append(lienE).Append(""" target=""_blank"" style=""display:inline-block;padding:15px 34px;font:800 16px Arial,Helvetica,sans-serif;color:#FFFFFF;text-decoration:none;border-radius:999px;"">")
            sb.Append(E(bouton)).Append(" &rarr;</a></td></tr></table></td></tr>")
        End If

        ' L'encadré « Bon à savoir »
        If Not String.IsNullOrEmpty(encadre) Then
            sb.Append("<tr><td style=""padding:0 40px 24px;"">")
            sb.Append("<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0""><tr>")
            sb.Append("<td style=""background:#F2F5FB;border-left:4px solid #6D3FD1;border-radius:12px;padding:14px 16px;font:14px/1.55 Arial,Helvetica,sans-serif;color:#33415C;"">")
            sb.Append("<strong style=""color:#0E1F3D;"">&#128274; ").Append(E(T("Bon à savoir", "Good to know", "Bueno saber"))).Append("</strong><br />")
            sb.Append(E(encadre)).Append("</td></tr></table></td></tr>")
        End If

        ' Lien de secours
        If Not String.IsNullOrEmpty(lien) Then
            sb.Append("<tr><td style=""padding:0 40px 30px;font:12.5px/1.55 Arial,Helvetica,sans-serif;color:#6B7A90;"">")
            sb.Append(E(T("Le bouton ne fonctionne pas ? Copiez ce lien dans votre navigateur :",
                          "Button not working? Copy this link into your browser:",
                          "¿El botón no funciona? Copie este enlace en su navegador:")))
            sb.Append("<br /><a href=""").Append(lienE).Append(""" style=""color:#1B4F9C;word-break:break-all;"">").Append(lienE).Append("</a></td></tr>")
        End If
        sb.Append("</table></td></tr>")

        ' Pied de page
        sb.Append("<tr><td style=""padding:22px 24px 0;text-align:center;font:12px/1.6 Arial,Helvetica,sans-serif;color:#7A879C;"">")
        If Not String.IsNullOrEmpty(mention) Then sb.Append(E(mention)).Append("<br />")
        sb.Append(E(T("Courriel automatique de 60Sec-AI — merci de ne pas y répondre.",
                      "Automatic email from 60Sec-AI — please do not reply.",
                      "Correo automático de 60Sec-AI — por favor no responda.")))
        sb.Append("<br />&copy; ").Append(DateTime.Now.Year).Append(" 60Sec-AI · Montréal, Québec")
        sb.Append("</td></tr>")

        sb.Append("</table></td></tr></table></body></html>")
        Return sb.ToString()
    End Function
End Class
