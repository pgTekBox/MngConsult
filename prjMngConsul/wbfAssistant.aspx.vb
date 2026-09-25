Imports System.Text
Imports System.Text.RegularExpressions

''' <summary>
''' La page complète de l'assistant IA (le ⤢ de la boîte flottante). La
''' conversation vit en session (même clé que le handler AssistantIA.ashx) ;
''' chaque échange est journalisé par clsAssistantIA. Le profil de la compagnie
''' et ses particularités s'entretiennent dans la colonne de droite.
''' </summary>
Public Class wbfAssistant
    Inherits clsData

    Private ReadOnly Property Historique As List(Of TourIA)
        Get
            Dim h = TryCast(Session(AssistantHandler.CleSession), List(Of TourIA))
            If h Is Nothing Then
                h = New List(Of TourIA)()
                Session(AssistantHandler.CleSession) = h
            End If
            Return h
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If
        btnNouvelle.Text = L("nouvelle")
        btnEnvoyer.Text = L("envoyer")
        btnParticularites.Text = L("enregistrerParticularites")
        btnActualiser.Text = L("actualiser")
        txtQuestion.Attributes("placeholder") = L("placeholder")
        txtParticularites.Attributes("placeholder") = L("particularitesPlaceholder")
        If Not IsPostBack Then txtParticularites.Text = clsAssistantProfil.Particularites(Company)
    End Sub

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        If Not isAuthenticated Then Return
        AfficherConversation()
        AfficherProfil()
    End Sub

    Private Sub AfficherConversation()
        Dim h = Historique
        pnlVide.Visible = h.Count = 0
        Dim sb As New StringBuilder()
        For Each t In h
            sb.Append("<div class='iap-tour ").Append(If(t.Role = "user", "user", "assistant")).Append("'><div><div class='iap-bulle'>")
            sb.Append(EnHtml(t.Texte)).Append("</div><div class='iap-quand'>").Append(t.Quand.ToString("HH:mm")).Append("</div></div></div>")
        Next
        litMessages.Text = sb.ToString()
        litCout.Text = Server.HtmlEncode(String.Format(L("cout"), clsAssistantIA.CoutDuMois(Company).ToString("N4")))
    End Sub

    Private Sub AfficherProfil()
        Dim quand = clsAssistantProfil.GenereLe(Company)
        litProfilInfo.Text = Server.HtmlEncode(If(quand.HasValue, String.Format(L("profilGenere"), quand.Value.ToString("yyyy-MM-dd HH:mm")), L("profilPasEncore")))
        Dim profil As String = clsAssistantProfil.ProfilGenere(Company)
        litProfil.Text = If(profil.Length = 0, Server.HtmlEncode(L("profilPasEncore")), Server.HtmlEncode(profil))
    End Sub

    ''' <summary>La réponse en HTML sûr : texte encodé, gras **…**, retours de ligne conservés par la feuille de style.</summary>
    Private Function EnHtml(texte As String) As String
        Dim s As String = Server.HtmlEncode(If(texte, ""))
        s = Regex.Replace(s, "\*\*(.+?)\*\*", "<b>$1</b>")
        Return s
    End Function

    Private Sub Message(texte As String, ok As Boolean)
        litMessage.Text = "<div class='iap-msg " & If(ok, "ok", "err") & "'>" & Server.HtmlEncode(texte) & "</div>"
    End Sub

    Private Async Sub btnEnvoyer_Click(sender As Object, e As EventArgs) Handles btnEnvoyer.Click
        Dim question As String = txtQuestion.Text.Trim()
        If question.Length = 0 Then
            Message(L("ecrivez"), False)
            Return
        End If
        Try
            Dim r = Await clsAssistantIA.DemanderAsync(Company, UserEmail, question, Historique, CurrentLang, "administration")
            Historique.Add(New TourIA With {.Role = "user", .Texte = question, .Quand = Date.Now})
            Historique.Add(New TourIA With {.Role = "assistant", .Texte = r.Texte, .Quand = Date.Now})
            txtQuestion.Text = ""
        Catch ex As SaisieAssistantException
            Message(ex.Message, False)
        Catch ex As Exception
            Message(L("pasRepondu") & ex.Message, False)
        End Try
    End Sub

    Private Sub btnNouvelle_Click(sender As Object, e As EventArgs) Handles btnNouvelle.Click
        Session.Remove(AssistantHandler.CleSession)
        txtQuestion.Text = ""
    End Sub

    Private Sub btnParticularites_Click(sender As Object, e As EventArgs) Handles btnParticularites.Click
        clsAssistantProfil.EnregistrerParticularites(Company, txtParticularites.Text.Trim(), UserEmail)
        Message(L("particularitesEnregistrees"), True)
    End Sub

    Private Sub btnActualiser_Click(sender As Object, e As EventArgs) Handles btnActualiser.Click
        clsAssistantProfil.Obtenir(Company, forcer:=True)
        Message(L("profilActualise"), True)
    End Sub

    ''' <summary>Libellés de la page (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "titre" : Return Choose3(lang, "Assistant", "Assistant", "Asistente")
            Case "sousTitre" : Return Choose3(lang, "Posez vos questions sur 60Sec-AI : l'assistant connaît l'aide en ligne et le profil de cette compagnie.", "Ask your questions about 60Sec-AI: the assistant knows the online help and this company's profile.", "Haga sus preguntas sobre 60Sec-AI: el asistente conoce la ayuda en línea y el perfil de esta compañía.")
            Case "nouvelle" : Return Choose3(lang, "Nouvelle conversation", "New conversation", "Nueva conversación")
            Case "envoyer" : Return Choose3(lang, "Envoyer", "Send", "Enviar")
            Case "placeholder" : Return Choose3(lang, "Votre question… (Ctrl+Entrée pour envoyer)", "Your question… (Ctrl+Enter to send)", "Su pregunta… (Ctrl+Intro para enviar)")
            Case "micro" : Return Choose3(lang, "Poser la question à voix haute", "Ask the question out loud", "Hacer la pregunta en voz alta")
            Case "ecoute" : Return Choose3(lang, "Je vous écoute… parlez, puis faites une pause.", "I'm listening… speak, then pause.", "Le escucho… hable y luego haga una pausa.")
            Case "aucune" : Return Choose3(lang, "Aucune question pour l'instant. Par exemple :", "No question yet. For example:", "Ninguna pregunta por ahora. Por ejemplo:")
            Case "ex1" : Return Choose3(lang, "Comment comptabiliser une facture client ?", "How do I post a customer invoice?", "¿Cómo contabilizo una factura de cliente?")
            Case "ex2" : Return Choose3(lang, "Pourquoi mon bilan n'est-il pas en équilibre ?", "Why is my balance sheet out of balance?", "¿Por qué mi balance no cuadra?")
            Case "ex3" : Return Choose3(lang, "Comment faire ma remise de TPS/TVQ ?", "How do I remit GST/QST?", "¿Cómo hago mi remesa de TPS/TVQ?")
            Case "ex4" : Return Choose3(lang, "Comment payer un fournisseur avec Stripe ?", "How do I pay a supplier with Stripe?", "¿Cómo pago a un proveedor con Stripe?")
            Case "ex5" : Return Choose3(lang, "Par où commencer pour importer QuickBooks ?", "Where do I start to import QuickBooks?", "¿Por dónde empiezo para importar QuickBooks?")
            Case "cout" : Return Choose3(lang, "Coût des questions ce mois-ci : {0} US$", "Cost of questions this month: US${0}", "Costo de las preguntas este mes: {0} US$")
            Case "profil" : Return Choose3(lang, "Profil de la compagnie", "Company profile", "Perfil de la compañía")
            Case "profilNote" : Return Choose3(lang, "Ce que l'assistant sait de cette compagnie : réglages, plan comptable, volumes, intégrations. Il est généré depuis vos données et refait automatiquement quand elles changent.", "What the assistant knows about this company: settings, chart of accounts, volumes, integrations. It is generated from your data and rebuilt automatically when it changes.", "Lo que el asistente sabe de esta compañía: ajustes, plan contable, volúmenes, integraciones. Se genera a partir de sus datos y se rehace automáticamente cuando cambian.")
            Case "profilGenere" : Return Choose3(lang, "Profil généré le {0}.", "Profile generated on {0}.", "Perfil generado el {0}.")
            Case "profilPasEncore" : Return Choose3(lang, "Le profil sera généré à la première question.", "The profile will be generated at the first question.", "El perfil se generará con la primera pregunta.")
            Case "particularites" : Return Choose3(lang, "Particularités (écrites par vous)", "Particularities (written by you)", "Particularidades (escritas por usted)")
            Case "particularitesPlaceholder" : Return Choose3(lang, "Ce que le logiciel ne sait pas : secteur d'activité, façon de facturer, habitudes comptables, ententes particulières…", "What the software doesn't know: line of business, invoicing habits, accounting practices, special agreements…", "Lo que el programa no sabe: sector de actividad, forma de facturar, hábitos contables, acuerdos particulares…")
            Case "enregistrerParticularites" : Return Choose3(lang, "Enregistrer les particularités", "Save particularities", "Guardar las particularidades")
            Case "actualiser" : Return Choose3(lang, "Actualiser le profil", "Refresh profile", "Actualizar el perfil")
            Case "voirProfil" : Return Choose3(lang, "Voir le profil envoyé à l'assistant", "See the profile sent to the assistant", "Ver el perfil enviado al asistente")
            Case "confidentialite" : Return Choose3(lang, "Confidentialité", "Privacy", "Confidencialidad")
            Case "confidentialiteTexte" : Return Choose3(lang,
                "Chaque question part vers OpenAI avec l'aide en ligne de 60Sec-AI et le profil ci-dessus. Aucun nom de client, de fournisseur, d'employé ou d'utilisateur, aucun numéro d'identification (NEQ, NAS, TPS/TVQ), aucune adresse ni aucun compte bancaire n'est envoyé. Ne les écrivez pas dans vos questions. Les échanges sont conservés par 60Sec-AI pour améliorer l'assistant. Ses réponses ne remplacent pas l'avis d'un comptable.",
                "Each question goes to OpenAI with the 60Sec-AI online help and the profile above. No customer, supplier, employee or user name, no identification number (NEQ, SIN, GST/QST), no address and no bank account is sent. Do not write them in your questions. Exchanges are kept by 60Sec-AI to improve the assistant. Its answers do not replace an accountant's advice.",
                "Cada pregunta se envía a OpenAI con la ayuda en línea de 60Sec-AI y el perfil anterior. No se envía ningún nombre de cliente, proveedor, empleado o usuario, ningún número de identificación (NEQ, NAS, TPS/TVQ), ninguna dirección ni cuenta bancaria. No los escriba en sus preguntas. 60Sec-AI conserva los intercambios para mejorar el asistente. Sus respuestas no sustituyen la opinión de un contador.")
            Case "ecrivez" : Return Choose3(lang, "Écrivez une question.", "Write a question.", "Escriba una pregunta.")
            Case "pasRepondu" : Return Choose3(lang, "L'assistant n'a pas pu répondre : ", "The assistant could not answer: ", "El asistente no pudo responder: ")
            Case "particularitesEnregistrees" : Return Choose3(lang, "Particularités enregistrées : l'assistant en tiendra compte dès la prochaine question.", "Particularities saved: the assistant will use them from the next question.", "Particularidades guardadas: el asistente las tendrá en cuenta desde la próxima pregunta.")
            Case "profilActualise" : Return Choose3(lang, "Profil actualisé.", "Profile refreshed.", "Perfil actualizado.")
            Case Else : Return key
        End Select
    End Function

    Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

End Class
