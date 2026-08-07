Imports System.Collections.Generic
Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.UI.WebControls

''' <summary>
''' Console d'administration — Courriel (service MailService / SrvAI).
''' Réception : lit T990SmtpInboundMessage (MIME brut parsé par clsMime),
'''             affiché dans une iframe sandbox.
''' Envoyés   : lit T400Mails (corps HTML).
''' Composer  : insère dans T400Mails via s0610InsertOutboundMail (ToSend=1),
'''             le service SrvAI fait l'envoi SMTP. Expéditeur = noreply@60sec.ca.
''' </summary>
Public Class wbfMail
    Inherits clsData

    Private Const NoReplyFrom As String = "noreply@60sec.ca"

    Private Property Mode() As String
        Get
            Return If(TryCast(ViewState("mode"), String), "inbox")
        End Get
        Set(value As String)
            ViewState("mode") = value
        End Set
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            BindMailboxes()
            ShowMode("inbox")
        End If
    End Sub

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

        lbInbox.CssClass = "mail-tab" & If(m = "inbox", " active", "")
        lbSent.CssClass = "mail-tab" & If(m = "sent", " active", "")
        lbCompose.CssClass = "mail-tab" & If(m = "compose", " active", "")

        pnlBrowse.Visible = (m <> "compose")
        pnlCompose.Visible = (m = "compose")
        pnlFilter.Visible = (m = "inbox")

        rptInbox.Visible = (m = "inbox")
        rptSent.Visible = (m = "sent")

        If m = "inbox" Then
            BindInbox()
        ElseIf m = "sent" Then
            BindSent()
        End If
    End Sub

    ' ---------------------------------------------------------------- Bindings
    Private Sub BindMailboxes()
        ddlMailbox.Items.Clear()
        ddlMailbox.Items.Add(New ListItem("Toutes les adresses", ""))
        Try
            Dim ds As DataSet = ExecuteSQLdsMail("s0615ListLocalRecipients")
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    Dim em As String = r("Email").ToString()
                    ddlMailbox.Items.Add(New ListItem(em, em))
                Next
            End If
        Catch
        End Try
    End Sub

    Protected Sub ddlMailbox_SelectedIndexChanged(sender As Object, e As EventArgs)
        BindInbox()
        ClearRead()
    End Sub

    Private Sub BindInbox()
        Dim p As New Collection
        Dim rcpt As String = ddlMailbox.SelectedValue
        p.Add(New SqlParameter("@Rcpt", If(String.IsNullOrEmpty(rcpt), CType(DBNull.Value, Object), rcpt)))
        p.Add(New SqlParameter("@Top", 300))
        Dim ds As DataSet = ExecuteSQLdsMail("s0611ListInboundMail", p)
        BindList(rptInbox, ds)
    End Sub

    Private Sub BindSent()
        Dim p As New Collection
        p.Add(New SqlParameter("@Top", 300))
        Dim ds As DataSet = ExecuteSQLdsMail("s0613ListSentMail", p)
        BindList(rptSent, ds)
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
        Dim id As Long = CLng(e.CommandArgument)
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        Dim ds As DataSet = ExecuteSQLdsMail("s0612GetInboundMail", p)
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

        ' Pièces jointes réelles (parsées du MIME brut, avec lien de téléchargement)
        Dim links As New List(Of String)()
        If raw IsNot Nothing Then
            Dim atts = clsMime.ExtractAttachments(raw)
            For i As Integer = 0 To atts.Count - 1
                links.Add("<a href=""MailAttachment.ashx?src=inbound&mid=" & id & "&ix=" & i & """ target=""_blank"">📎 " &
                          Server.HtmlEncode(atts(i).FileName) & "</a>")
            Next
        End If
        ShowAttachLinks(links)

        pnlRead.Visible = True
        pnlReadEmpty.Visible = False
    End Sub

    Protected Sub rptSent_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName <> "open" Then Return
        Dim id As Integer = CInt(e.CommandArgument)
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        Dim ds As DataSet = ExecuteSQLdsMail("s0614GetSentMail", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return
        Dim r As DataRow = ds.Tables(0).Rows(0)

        litSubject.Text = Server.HtmlEncode(SubjectOr(r("Subject")))
        litFrom.Text = Server.HtmlEncode(Val_(r("From")))
        litTo.Text = Server.HtmlEncode(Val_(r("To")))
        litDate.Text = Server.HtmlEncode(FormatDate(r("Created")))
        ShowSentAttachments(id)

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
    ''' Affiche le corps dans une iframe sandbox (aucun script du courriel n'est exécuté).
    ''' - &lt;base target="_blank"&gt; : les hyperliens du courriel s'ouvrent dans un nouvel onglet.
    ''' - sandbox="allow-popups allow-popups-to-escape-sandbox" : autorise UNIQUEMENT l'ouverture
    '''   du lien hors de l'iframe (sinon un sandbox nu la bloque) ; le nouvel onglet n'hérite pas
    '''   du bac à sable. Toujours pas de allow-scripts / allow-same-origin (courriel non exécuté).
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
            p.Add(New SqlParameter("@Sender", NoReplyFrom))
            p.Add(New SqlParameter("@From", NoReplyFrom))
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
            ShowSend("ok", "✔ Courriel mis en file d'envoi" & extra & " (destinataire : " & Server.HtmlEncode(toAddr) & "). Le service SrvAI l'expédiera sous peu.")
            txtTo.Text = "" : txtCc.Text = "" : txtSubject.Text = "" : reBody.Content = ""
        Catch ex As Exception
            ShowSend("err", "✖ Échec de l'envoi : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

    Private Sub ShowSend(kind As String, text As String)
        pnlSendMsg.Visible = True
        litSendMsg.Text = "<div class=""send-msg " & kind & """>" & text & "</div>"
    End Sub

    ''' <summary>Convertit le HTML du RadEditor en texte brut (validation + corps texte).</summary>
    Private Shared Function HtmlToText(htmlContent As String) As String
        If String.IsNullOrEmpty(htmlContent) Then Return ""
        Dim s As String = htmlContent
        ' sauts de ligne pour les balises de bloc
        s = System.Text.RegularExpressions.Regex.Replace(s, "(?i)<br\s*/?>", vbLf)
        s = System.Text.RegularExpressions.Regex.Replace(s, "(?i)</(p|div|li|tr|h[1-6])>", vbLf)
        ' retirer toutes les balises
        s = System.Text.RegularExpressions.Regex.Replace(s, "<[^>]+>", "")
        ' décoder les entités (&nbsp; &eacute; …)
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

    ' -------------------------------------------------------------- Helpers UI
    Private Sub ShowAttachLinks(links As List(Of String))
        If links Is Nothing OrElse links.Count = 0 Then
            pnlAttach.Visible = False
        Else
            pnlAttach.Visible = True
            litAttach.Text = String.Join(" &nbsp; ", links.ToArray())
        End If
    End Sub

    ''' <summary>Pièces jointes d'un ENVOYÉ (T402Attachments) avec liens de téléchargement.</summary>
    Private Sub ShowSentAttachments(mailId As Integer)
        Dim links As New List(Of String)()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@MailId", mailId))
            Dim ds As DataSet = ExecuteSQLdsMail("s0626ListSentAttachments", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each row As DataRow In ds.Tables(0).Rows
                    links.Add("<a href=""MailAttachment.ashx?src=sent&id=" & row("Id").ToString() & """ target=""_blank"">📎 " &
                              Server.HtmlEncode(Val_(row("FileName"))) & "</a>")
                Next
            End If
        Catch
        End Try
        ShowAttachLinks(links)
    End Sub

    Protected Function Val_(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return o.ToString()
    End Function

    Protected Function SubjectOr(o As Object) As String
        Dim s As String = Val_(o).Trim()
        Return If(s = "", "(sans sujet)", s)
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
            Return "<span class=""tag tag-ok"">envoyé</span>"
        ElseIf tosend IsNot Nothing AndAlso Not IsDBNull(tosend) AndAlso CInt(tosend) = 1 Then
            Return "<span class=""tag tag-q"">en file</span>"
        Else
            Return "<span class=""tag tag-err"">non envoyé</span>"
        End If
    End Function

End Class
