Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.UI.WebControls
Imports System.Linq
Imports System.Text

''' <summary>
''' Boîte courriel @60sec.ca de la compagnie courante (service MailService / SrvAI).
''' Limitée à l'adresse de l'abonné (T010Company.Sec60Email) :
'''   Réception : messages entrants adressés à SON adresse (T990SmtpInboundMessage).
'''   Envoyés   : messages qu'IL a envoyés (T400Mails.From = son adresse).
'''   Composer  : envoi via s0610InsertOutboundMail, expéditeur = son adresse
'''               (@60sec.ca → aligné SPF/DMARC).
''' Le corps entrant (MIME brut) est parsé par clsMime et rendu en iframe sandbox.
''' </summary>
Public Class wbfMailbox
    Inherits clsData

    Private _addr As String = ""

    Private Property Mode() As String
        Get
            Return If(TryCast(ViewState("mode"), String), "inbox")
        End Get
        Set(value As String)
            ViewState("mode") = value
        End Set
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        _addr = GetMailbox()
        litAddr.Text = Server.HtmlEncode(_addr)
        litComposeFrom.Text = Server.HtmlEncode(_addr)
        ApplyLocalization()
        If Not IsPostBack Then
            ShowMode("inbox")
        End If
    End Sub

    ''' <summary>La tête, les pastilles et les textes vides (fr/en/es).</summary>
    Private Sub ApplyLocalization()
        litRubrique.Text = T("Mon entreprise", "My business", "Mi empresa")
        litTitre.Text = T("Courriel", "Mail", "Correo")
        litSousTitre.Text = T("La boîte @60sec.ca de votre entreprise : ce que vous recevez, ce que vous envoyez.", "Your company's @60sec.ca mailbox: what you receive, what you send.", "El buzón @60sec.ca de su empresa: lo que recibe, lo que envía.")
        litDossier.Text = T("Dossier", "Folder", "Carpeta")
        lbInbox.Text = T("Réception", "Inbox", "Recepción")
        lbSent.Text = T("Envoyés", "Sent", "Enviados")
        lbCompose.Text = "+ " & T("Composer", "Compose", "Redactar")
        litListEmpty.Text = T("Aucun message.", "No message.", "Ningún mensaje.")
        litReadEmpty.Text = T("Sélectionnez un message pour le lire.", "Select a message to read it.", "Seleccione un mensaje para leerlo.")
        btnSend.Text = T("Envoyer", "Send", "Enviar")
    End Sub

    ''' <summary>Sélecteur de langue simple (fr/en/es) pour les libellés de la page.</summary>
    Protected Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    ''' <summary>Les quatre indicateurs : reçus, envoyés, en file, non envoyés (sur les 300 derniers).</summary>
    Private Sub ChargerIndicateurs(dsIn As DataSet, dsOut As DataSet)
        Dim recus As Integer = 0, envoyes As Integer = 0, enFile As Integer = 0, echecs As Integer = 0
        If dsIn IsNot Nothing AndAlso dsIn.Tables.Count > 0 Then recus = dsIn.Tables(0).Rows.Count
        If dsOut IsNot Nothing AndAlso dsOut.Tables.Count > 0 Then
            For Each r As DataRow In dsOut.Tables(0).Rows
                If Entier(r("SendWithSuccess")) = 1 Then
                    envoyes += 1
                ElseIf Entier(r("ToSend")) = 1 Then
                    enFile += 1
                Else
                    echecs += 1
                End If
            Next
        End If
        Dim sb As New StringBuilder()
        sb.Append(Kpi(T("Reçus", "Received", "Recibidos"), recus.ToString(), T("derniers messages", "latest messages", "últimos mensajes"), "#1B4F9C"))
        sb.Append(Kpi(T("Envoyés", "Sent", "Enviados"), envoyes.ToString(), T("partis de la boîte", "left the mailbox", "salieron del buzón"), "#43B47A"))
        sb.Append(Kpi(T("En file", "Queued", "En cola"), enFile.ToString(), T("en attente d'envoi", "waiting to be sent", "pendientes de envío"), "#E3B341"))
        sb.Append(Kpi(T("Non envoyés", "Not sent", "No enviados"), echecs.ToString(), T("à vérifier", "to check", "por revisar"), If(echecs > 0, "#A3261C", "#AEBBCD")))
        litKpis.Text = sb.ToString()
    End Sub

    Private Function Kpi(lab As String, val As String, sub_ As String, point As String) As String
        Return "<div class=""fc-kpi""><span class=""lab""><i style=""background:" & point & """></i>" & Server.HtmlEncode(lab) & "</span>" &
               "<span class=""val"">" & Server.HtmlEncode(val) & "</span><span class=""sub"">" & Server.HtmlEncode(sub_) & "</span></div>"
    End Function

    Private Shared Function Entier(o As Object) As Integer
        If o Is Nothing OrElse IsDBNull(o) Then Return 0
        Try
            Return Convert.ToInt32(o)
        Catch
            Return 0
        End Try
    End Function

    ''' <summary>Adresse @60sec.ca de la compagnie ; l'attribue au besoin.</summary>
    Private Function GetMailbox() As String
        Dim a As String = ""
        Try
            Dim ds As DataSet = ExecuteSQLds("s0713GetCompanyMailbox", ParamsCompany())
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 _
               AndAlso Not IsDBNull(ds.Tables(0).Rows(0)(0)) Then
                a = ds.Tables(0).Rows(0)(0).ToString()
            End If
            If a = "" Then
                Dim ds2 As DataSet = ExecuteSQLds("s0712AssignMailbox", ParamsCompany())
                If ds2 IsNot Nothing AndAlso ds2.Tables.Count > 0 AndAlso ds2.Tables(0).Rows.Count > 0 Then
                    a = ds2.Tables(0).Rows(0)("Email").ToString()
                End If
            End If
        Catch
        End Try
        Return a
    End Function

    Private Function ParamsCompany() As Collection
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Me.Company))
        Return p
    End Function

    ' ------------------------------------------------------------------ Onglets
    Protected Sub lbInbox_Click(sender As Object, e As EventArgs)
        ShowMode("inbox")
    End Sub
    Protected Sub lbSent_Click(sender As Object, e As EventArgs)
        ShowMode("sent")
    End Sub
    Protected Sub lbCompose_Click(sender As Object, e As EventArgs)
        ShowMode("compose")
    End Sub

    Private Sub ShowMode(m As String)
        Mode = m
        ClearRead()

        lbInbox.CssClass = "fc-pill" & If(m = "inbox", " on", "")
        lbSent.CssClass = "fc-pill" & If(m = "sent", " on", "")
        lbCompose.CssClass = "fc-btn primaire"

        pnlBrowse.Visible = (m <> "compose")
        pnlCompose.Visible = (m = "compose")
        rptInbox.Visible = (m = "inbox")
        rptSent.Visible = (m = "sent")

        ' Les deux dossiers sont lus pour les indicateurs ; seul celui du dossier choisi est affiché.
        Dim dsIn As DataSet = LireDossier("s0616ListInboxForAddress")
        Dim dsOut As DataSet = LireDossier("s0618ListSentForAddress")
        ChargerIndicateurs(dsIn, dsOut)
        If m = "inbox" Then
            BindList(rptInbox, dsIn)
        ElseIf m = "sent" Then
            BindList(rptSent, dsOut)
        End If
    End Sub

    Private Function LireDossier(proc As String) As DataSet
        Dim p As New Collection
        p.Add(New SqlParameter("@Addr", _addr))
        p.Add(New SqlParameter("@Top", 300))
        Return ExecuteSQLdsMail(proc, p)
    End Function

    ' ---------------------------------------------------------------- Bindings
    Private Sub BindInbox()
        Dim p As New Collection
        p.Add(New SqlParameter("@Addr", _addr))
        p.Add(New SqlParameter("@Top", 300))
        BindList(rptInbox, ExecuteSQLdsMail("s0616ListInboxForAddress", p))
    End Sub

    Private Sub BindSent()
        Dim p As New Collection
        p.Add(New SqlParameter("@Addr", _addr))
        p.Add(New SqlParameter("@Top", 300))
        BindList(rptSent, ExecuteSQLdsMail("s0618ListSentForAddress", p))
    End Sub

    Private Sub BindList(rpt As Repeater, ds As DataSet)
        Dim n As Integer = 0
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            rpt.DataSource = ds.Tables(0)
            rpt.DataBind()
            n = ds.Tables(0).Rows.Count
        Else
            rpt.DataSource = Nothing
            rpt.DataBind()
        End If
        pnlListEmpty.Visible = (n = 0)
    End Sub

    ' ------------------------------------------------------------- Ouverture
    Protected Sub rptInbox_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName <> "open" Then Return
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", CLng(e.CommandArgument)))
        p.Add(New SqlParameter("@Addr", _addr))
        Dim ds As DataSet = ExecuteSQLdsMail("s0617GetInboxForAddress", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return
        Dim r As DataRow = ds.Tables(0).Rows(0)

        litSubject.Text = Server.HtmlEncode(SubjectOr(r("SubjectHeader")))
        litFrom.Text = Server.HtmlEncode(Val_(r("MailFrom")))
        litTo.Text = Server.HtmlEncode(Val_(r("RcptTo")))
        litDate.Text = Server.HtmlEncode(FormatDate(r("ReceivedAtUtc")))

        Dim raw As Byte() = Nothing
        If Not IsDBNull(r("RawMessage")) Then raw = CType(r("RawMessage"), Byte())
        Dim mr As clsMime.MimeResult = clsMime.ExtractBody(raw)

        Dim inner As String
        If mr.IsHtml Then
            inner = mr.Body
        Else
            inner = "<pre style=""white-space:pre-wrap;word-wrap:break-word;font-family:system-ui,Segoe UI,Arial,sans-serif;font-size:14px;margin:12px;"">" _
                    & Server.HtmlEncode(mr.Body) & "</pre>"
        End If
        RenderBodyFrame(inner)

        ' Pièces jointes : liens de téléchargement via MailAttachment.ashx
        ' (ExtractAttachments = même fonction/ordre que le handler → indices cohérents).
        Dim atts = clsMime.ExtractAttachments(raw)
        If atts IsNot Nothing AndAlso atts.Count > 0 Then
            pnlAttach.Visible = True
            Dim sb As New System.Text.StringBuilder()
            For i As Integer = 0 To atts.Count - 1
                If i > 0 Then sb.Append(" &nbsp; ")
                sb.Append("<a href=""MailAttachment.ashx?mid=").Append(CLng(e.CommandArgument)) _
                  .Append("&ix=").Append(i).Append(""" target=""_blank"">📎 ") _
                  .Append(Server.HtmlEncode(atts(i).FileName)).Append("</a>")
            Next
            litAttach.Text = sb.ToString()
        Else
            pnlAttach.Visible = False
        End If

        pnlRead.Visible = True
        pnlReadEmpty.Visible = False
    End Sub

    Protected Sub rptSent_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName <> "open" Then Return
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", CInt(e.CommandArgument)))
        p.Add(New SqlParameter("@Addr", _addr))
        Dim ds As DataSet = ExecuteSQLdsMail("s0619GetSentForAddress", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return
        Dim r As DataRow = ds.Tables(0).Rows(0)

        litSubject.Text = Server.HtmlEncode(SubjectOr(r("Subject")))
        litFrom.Text = Server.HtmlEncode(Val_(r("From")))
        litTo.Text = Server.HtmlEncode(Val_(r("To")))
        litDate.Text = Server.HtmlEncode(FormatDate(r("Created")))
        pnlAttach.Visible = False

        Dim html As String = Val_(r("HTMLBody"))
        If String.IsNullOrEmpty(html) Then
            html = "<pre style=""white-space:pre-wrap;font-family:system-ui;font-size:14px;margin:12px;"">" _
                   & Server.HtmlEncode(Val_(r("TextBody"))) & "</pre>"
        End If
        RenderBodyFrame(html)

        pnlRead.Visible = True
        pnlReadEmpty.Visible = False
    End Sub

    ''' <summary>
    ''' Rend le corps dans une iframe sandbox (scripts du courriel non exécutés).
    ''' &lt;base target="_blank"&gt; : les hyperliens s'ouvrent dans un nouvel onglet ;
    ''' sandbox="allow-popups allow-popups-to-escape-sandbox" autorise cette ouverture
    ''' (un sandbox nu la bloque) sans permettre l'exécution des scripts du courriel.
    ''' </summary>
    Private Sub RenderBodyFrame(innerHtml As String)
        Dim doc As String = "<base target=""_blank"">" & innerHtml
        litBody.Text = "<iframe class=""mailframe"" sandbox=""allow-popups allow-popups-to-escape-sandbox"" srcdoc=""" & Server.HtmlEncode(doc) & """></iframe>"
    End Sub

    Private Sub ClearRead()
        pnlRead.Visible = False
        pnlReadEmpty.Visible = True
        litBody.Text = ""
        pnlAttach.Visible = False
    End Sub

    ' ------------------------------------------------------------------ Envoi
    Protected Sub btnSend_Click(sender As Object, e As EventArgs)
        If _addr = "" Then
            ShowSend("err", "✖ Aucune adresse courriel n'est configurée pour cette compagnie.")
            Return
        End If
        Dim toAddr As String = txtTo.Text.Trim()
        Dim subj As String = txtSubject.Text.Trim()
        Dim htmlBody As String = If(reBody.Content, "").Trim()
        Dim plainBody As String = HtmlToText(htmlBody)

        If toAddr = "" OrElse subj = "" OrElse plainBody.Trim() = "" Then
            ShowSend("err", "✖ Destinataire, sujet et message sont obligatoires.")
            Return
        End If

        ' Le RadEditor fournit déjà du HTML mis en forme ; on l'enveloppe pour la police de base.
        Dim html As String = "<div style=""font-family:system-ui,-apple-system,Segoe UI,Arial,sans-serif;font-size:14px;color:#0f172a;"">" _
                             & htmlBody & "</div>"

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@To", toAddr))
            p.Add(New SqlParameter("@Subject", subj))
            p.Add(New SqlParameter("@HTMLBody", html))
            p.Add(New SqlParameter("@TextBody", plainBody))
            p.Add(New SqlParameter("@Sender", _addr))
            p.Add(New SqlParameter("@From", _addr))
            Dim cc As String = txtCc.Text.Trim()
            If cc <> "" Then p.Add(New SqlParameter("@CC", cc))

            ' s0610 retourne l'Id inséré (OUTPUT INSERTED.Id)
            Dim ds As DataSet = ExecuteSQLdsMail("s0610InsertOutboundMail", p)
            Dim mailId As Integer = 0
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Integer.TryParse(ds.Tables(0).Rows(0)(0).ToString(), mailId)
            End If

            ' Pièces jointes -> T402Attachments (lues par SrvAI à l'envoi)
            Dim attCount As Integer = SaveAttachments(mailId)

            Dim extra As String = If(attCount > 0, " avec " & attCount & " pièce(s) jointe(s)", "")
            ShowSend("ok", "✔ Courriel mis en file d'envoi" & extra & " (destinataire : " & Server.HtmlEncode(toAddr) & ").")
            txtTo.Text = "" : txtCc.Text = "" : txtSubject.Text = "" : reBody.Content = ""
        Catch ex As Exception
            ShowSend("err", "✖ Échec de l'envoi : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

    ''' <summary>Convertit le HTML du RadEditor en texte brut (validation + corps texte).</summary>
    Private Shared Function HtmlToText(htmlContent As String) As String
        If String.IsNullOrEmpty(htmlContent) Then Return ""
        Dim s As String = htmlContent
        s = System.Text.RegularExpressions.Regex.Replace(s, "(?i)<br\s*/?>", vbLf)
        s = System.Text.RegularExpressions.Regex.Replace(s, "(?i)</(p|div|li|tr|h[1-6])>", vbLf)
        s = System.Text.RegularExpressions.Regex.Replace(s, "<[^>]+>", "")
        s = System.Net.WebUtility.HtmlDecode(s)
        Return s.Trim()
    End Function

    ''' <summary>
    ''' Enregistre les fichiers téléversés du composeur dans T402Attachments
    ''' (via s0623ImapInsertAttachment). Retourne le nombre de pièces jointes.
    ''' </summary>
    Private Function SaveAttachments(mailId As Integer) As Integer
        If mailId <= 0 OrElse fuAttach Is Nothing OrElse Not fuAttach.HasFiles Then Return 0
        Dim n As Integer = 0
        For Each pf As HttpPostedFile In fuAttach.PostedFiles
            If pf Is Nothing OrElse pf.ContentLength <= 0 Then Continue For
            Dim fn As String = System.IO.Path.GetFileName(pf.FileName)
            If String.IsNullOrWhiteSpace(fn) Then fn = "piece-jointe"
            Dim ct As String = If(String.IsNullOrEmpty(pf.ContentType), "application/octet-stream", pf.ContentType)
            Dim bytes As Byte()
            Using br As New System.IO.BinaryReader(pf.InputStream)
                bytes = br.ReadBytes(pf.ContentLength)
            End Using

            Dim pa As New Collection
            pa.Add(New SqlParameter("@MailId", mailId))
            pa.Add(New SqlParameter("@FileName", fn))
            pa.Add(New SqlParameter("@content", bytes))
            pa.Add(New SqlParameter("@ContentType", ct))
            pa.Add(New SqlParameter("@ContentId", ""))
            pa.Add(New SqlParameter("@ContentDisposition", "attachment"))
            ExecuteSQLMail("s0623ImapInsertAttachment", pa)
            n += 1
        Next
        Return n
    End Function

    Private Sub ShowSend(kind As String, text As String)
        pnlSendMsg.Visible = True
        litSendMsg.Text = "<div class=""send-msg " & kind & """>" & text & "</div>"
    End Sub

    ' -------------------------------------------------------------- Helpers UI
    Protected Function Val_(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return o.ToString()
    End Function

    Protected Function SubjectOr(o As Object) As String
        Dim s As String = Val_(o).Trim()
        Return If(s = "", T("(sans sujet)", "(no subject)", "(sin asunto)"), s)
    End Function

    Protected Function FormatDate(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Dim d As DateTime
        If DateTime.TryParse(o.ToString(), d) Then
            Return d.ToString("yyyy-MM-dd HH:mm")
        End If
        Return o.ToString()
    End Function

    Protected Function SentStatusTag(success As Object, tosend As Object) As String
        If success IsNot Nothing AndAlso Not IsDBNull(success) AndAlso CInt(success) = 1 Then
            Return "<span class=""fc-pay"" style=""background:#E3F3EA;color:#0F5A3A"">" & T("envoyé", "sent", "enviado") & "</span>"
        ElseIf tosend IsNot Nothing AndAlso Not IsDBNull(tosend) AndAlso CInt(tosend) = 1 Then
            Return "<span class=""fc-pay"" style=""background:#FBF1DC;color:#7A5200"">" & T("en file", "queued", "en cola") & "</span>"
        Else
            Return "<span class=""fc-pay"" style=""background:#FDECEA;color:#A3261C"">" & T("non envoyé", "not sent", "no enviado") & "</span>"
        End If
    End Function

End Class
