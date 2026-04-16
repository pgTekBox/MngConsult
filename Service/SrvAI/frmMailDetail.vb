
Imports System.Data.SqlClient

Imports System.Drawing






Public Class frmMailDetail
    Public MailId As Integer = 0 ' 438583 '437911
    Public ConnectionString As String

    Function CheckNull(str As Object) As String
        If IsDBNull(str) Then Return ""


        Return str.ToString

    End Function
    Function CheckDateNull(str As Object) As String

        If IsDBNull(str) Then Return ""


        Return Format(str, "d MMMM yyyy HH:mm:ss")

    End Function

    Sub BindTXT()
        Dim cnn As New SqlClient.SqlConnection
        cnn.ConnectionString = ConnectionString
        Dim comm As SqlCommand
        comm = cnn.CreateCommand()
        comm.CommandType = System.Data.CommandType.Text
        comm.CommandText = "select * from T400Mails  where id =" & MailId.ToString
        'SMTPMail = 1 or coalesce(tosend,0) = 1
        Dim MyDA As New SqlDataAdapter
        Dim MyDS As New DataSet
        comm.Connection = cnn
        MyDA.SelectCommand = comm
        MyDA.Fill(MyDS)
        If MyDS.Tables(0).Rows.Count = 1 Then


            txtId.Text = MyDS.Tables(0).Rows(0)("Id")
            txtMail.Text = CheckNull(MyDS.Tables(0).Rows(0)("Mail"))
            txtRCPT.Text = CheckNull(MyDS.Tables(0).Rows(0)("RCPT"))

            txtReceived.Text = CheckDateNull(MyDS.Tables(0).Rows(0)("Received"))
            txtSended.Text = CheckDateNull(MyDS.Tables(0).Rows(0)("Sended"))
            txtCreated.Text = CheckDateNull(MyDS.Tables(0).Rows(0)("Created"))
            txtSendAt.Text = CheckDateNull(MyDS.Tables(0).Rows(0)("SendAt"))
            txtCountResend.Text = CheckNull(MyDS.Tables(0).Rows(0)("CountResend"))

            txtFolderId.Text = CheckNull(MyDS.Tables(0).Rows(0)("FolderId"))
            txtFrom.Text = CheckNull(MyDS.Tables(0).Rows(0)("From"))
            txtBCC.Text = CheckNull(MyDS.Tables(0).Rows(0)("BCC"))
            txtCC.Text = CheckNull(MyDS.Tables(0).Rows(0)("CC"))
            txtReplyTo.Text = CheckNull(MyDS.Tables(0).Rows(0)("ReplyTo"))
            txtResentBCC.Text = CheckNull(MyDS.Tables(0).Rows(0)("ResentBCC"))
            txtResentCC.Text = CheckNull(MyDS.Tables(0).Rows(0)("ResentCC"))
            txtResentFrom.Text = CheckNull(MyDS.Tables(0).Rows(0)("ResentFrom"))
            txtResentReplyTo.Text = CheckNull(MyDS.Tables(0).Rows(0)("ResentReplyTo"))
            txtResentSender.Text = CheckNull(MyDS.Tables(0).Rows(0)("ResentSender"))
            txtResentTo.Text = CheckNull(MyDS.Tables(0).Rows(0)("ResentTo"))
            txtSender.Text = CheckNull(MyDS.Tables(0).Rows(0)("Sender"))
            txtTo.Text = CheckNull(MyDS.Tables(0).Rows(0)("To"))
            txtInReplyTo.Text = CheckNull(MyDS.Tables(0).Rows(0)("InReplyTo"))
            txtImportance.Text = CheckNull(MyDS.Tables(0).Rows(0)("Importance"))
            txtxPriority.Text = CheckNull(MyDS.Tables(0).Rows(0)("xPriority"))
            txtMessageId.Text = CheckNull(MyDS.Tables(0).Rows(0)("MessageId"))
            txtResentMessageId.Text = CheckNull(MyDS.Tables(0).Rows(0)("ResentMessageId"))
            txtSubject.Text = CheckNull(MyDS.Tables(0).Rows(0)("Subject"))
            txtTextBody.Text = CheckNull(MyDS.Tables(0).Rows(0)("TextBody"))
            txtHTMLBody.Text = CheckNull(MyDS.Tables(0).Rows(0)("HTMLBody"))

            txtClientIP.Text = CheckNull(MyDS.Tables(0).Rows(0)("ClientIP"))
            txtHasBeenRead.Text = CheckNull(MyDS.Tables(0).Rows(0)("HasBeenRead"))
            txtRCPT_ORG.Text = CheckNull(MyDS.Tables(0).Rows(0)("RCPT_ORG"))
            txtHasBeenNotifie.Text = CheckNull(MyDS.Tables(0).Rows(0)("HasBeenNotifie"))
            txtToSend.Text = CheckNull(MyDS.Tables(0).Rows(0)("ToSend"))
            txtSendWithSuccess.Text = CheckNull(MyDS.Tables(0).Rows(0)("SendWithSuccess"))
            txtHaveAttachment.Text = CheckNull(MyDS.Tables(0).Rows(0)("HaveAttachment"))
            txtUId.Text = CheckNull(MyDS.Tables(0).Rows(0)("UId"))
            txtSecuredEmail.Text = CheckNull(MyDS.Tables(0).Rows(0)("SecuredEmail"))
            txtConseillerId.Text = CheckNull(MyDS.Tables(0).Rows(0)("ConseillerId"))
            txtResponsablesId.Text = CheckNull(MyDS.Tables(0).Rows(0)("ResponsablesId"))
            txtUserId.Text = CheckNull(MyDS.Tables(0).Rows(0)("UserId"))
            txtMailGUID.Text = CheckNull(MyDS.Tables(0).Rows(0)("MailGUID"))
            txtCommandId.Text = CheckNull(MyDS.Tables(0).Rows(0)("CommandId"))
            txtClientId.Text = CheckNull(MyDS.Tables(0).Rows(0)("ClientId"))
            txtContratId.Text = CheckNull(MyDS.Tables(0).Rows(0)("ContratId"))
            txtDATAgi.Text = CheckNull(MyDS.Tables(0).Rows(0)("DATAgi"))
            txtpi_Conseiller.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_Conseiller"))
            txtpi_CommandeId.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_CommandeId"))
            txtpi_Status.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_Status"))
            txtpi_Ligne.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_Ligne"))
            txtpi_sUser.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_sUser"))
            txtpi_DateMessage.Text = CheckDateNull(MyDS.Tables(0).Rows(0)("pi_DateMessage"))
            txtpi_Commentaire.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_Commentaire"))
            txtpi_CommandeConseiller.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_CommandeConseiller"))
            txtpi_ResultatId.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_ResultatId"))
            txtpi_ResultatValue.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_ResultatValue"))
            txtrecipientIDList.Text = CheckNull(MyDS.Tables(0).Rows(0)("recipientIDList"))
            txtcontratlist.Text = CheckNull(MyDS.Tables(0).Rows(0)("contratlist"))
            txtpi_entrevupasse.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_entrevupasse"))
            txtpi_HaveDateEntrevue.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_HaveDateEntrevue"))
            txtpi_ClientIdList.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_ClientIdList"))
            txtpi_ResponsableIdList.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_ResponsableIdList"))
            txtT405EventId.Text = CheckNull(MyDS.Tables(0).Rows(0)("T405EventId"))
            txtSMTPMail.Text = CheckNull(MyDS.Tables(0).Rows(0)("SMTPMail"))
            txtpi_DateMarketing.Text = CheckDateNull(MyDS.Tables(0).Rows(0)("pi_DateMarketing"))
            txtpi_DateEnCours.Text = CheckDateNull(MyDS.Tables(0).Rows(0)("pi_DateEnCours"))
            txtpi_DateEnControl.Text = CheckDateNull(MyDS.Tables(0).Rows(0)("pi_DateEnControl"))
            txtpi_DateFermeGagne.Text = CheckDateNull(MyDS.Tables(0).Rows(0)("pi_DateFermeGagne"))
            txtpi_DateFermePerdu.Text = CheckDateNull(MyDS.Tables(0).Rows(0)("pi_DateFermePerdu"))
            txtpi_DateFermeAnnule.Text = CheckDateNull(MyDS.Tables(0).Rows(0)("pi_DateFermeAnnule"))
            txtpi_DateNouveau.Text = CheckDateNull(MyDS.Tables(0).Rows(0)("pi_DateNouveau"))
            txtpi_CommandesResultatID.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_CommandesResultatID"))
            txtpi_ClientId.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_ClientId"))
            txtpi_ResponsableId.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_ResponsableId"))
            txtpi_ContratId.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_ContratId"))
            txtpi_RecruteurId.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_RecruteurId"))
            txtpi_RecruteurResId.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_RecruteurResId"))
            txtpi_VendeurId.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_VendeurId"))
            txtDATAgi_BK.Text = CheckNull(MyDS.Tables(0).Rows(0)("DATAgi_BK"))

            txtNotePriority.Text = CheckNull(MyDS.Tables(0).Rows(0)("NotePriority"))
            txtpi_SouleverPar.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_SouleverPar"))
            txtxmlClientId.Text = CheckNull(MyDS.Tables(0).Rows(0)("xmlClientId"))
            txtxmlConseillerId.Text = CheckNull(MyDS.Tables(0).Rows(0)("xmlConseillerId"))
            txtxmlmessagetypeid.Text = CheckNull(MyDS.Tables(0).Rows(0)("xmlmessagetypeid"))
            txtxmlMessageType.Text = CheckNull(MyDS.Tables(0).Rows(0)("xmlMessageType"))
            txtxmlMessageTypeValue.Text = CheckNull(MyDS.Tables(0).Rows(0)("xmlMessageTypeValue"))
            txtxmlConseillerIdSTR.Text = CheckNull(MyDS.Tables(0).Rows(0)("xmlConseillerIdSTR"))
            txtxmlCommandId.Text = CheckNull(MyDS.Tables(0).Rows(0)("xmlCommandId"))
            txtSecureMessage.Text = CheckNull(MyDS.Tables(0).Rows(0)("SecureMessage"))
            txtSecureMessageFacturation.Text = CheckNull(MyDS.Tables(0).Rows(0)("SecureMessageFacturation"))
            txtNotShowTextInHisto.Text = CheckNull(MyDS.Tables(0).Rows(0)("NotShowTextInHisto"))
            txtpi_FromCommandId.Text = CheckNull(MyDS.Tables(0).Rows(0)("pi_FromCommandId"))

            If CheckNull(MyDS.Tables(0).Rows(0)("ToSend")) = "1" Then
                Me.Text = "Mail detail: " & MailId.ToString & "   Outbound mail"
                txtToSend.BackColor = Color.Aqua
                txtSMTPMail.BackColor = Color.Aqua
                lblMailDirection.Text = Me.Text
            Else

                If CheckNull(MyDS.Tables(0).Rows(0)("SMTPMail")) = "1" Then
                    Me.Text = "Mail detail: " & MailId.ToString & "   inbound mail"
                    txtToSend.BackColor = Color.LightGreen
                    txtSMTPMail.BackColor = Color.LightGreen
                    lblMailDirection.Text = Me.Text
                Else
                    Me.Text = "Mail detail: " & MailId.ToString & "   internal message"
                    txtToSend.BackColor = Color.LightPink
                    txtSMTPMail.BackColor = Color.LightPink
                    lblMailDirection.Text = Me.Text
                End If


            End If

            lblNAVId.Text = MailId
        Else
            MailId = lblNAVId.Text
        End If
        lblNAVId.Text = MailId
    End Sub



    Private Sub Form1_Shown(sender As Object, e As EventArgs) Handles Me.Shown

        BindTXT()


    End Sub

    Private Sub Form1_Load(sender As Object, e As EventArgs) Handles MyBase.Load

    End Sub

    Private Sub btnMail_Click(sender As Object, e As EventArgs) Handles btnMail.Click
        ShowDetail("Mail")
    End Sub
    Sub ShowDetail(FieldName As String)
        Dim Myform As frmFieldDetail = New frmFieldDetail

        Myform.MailId = MailId
        Myform.FieldName = FieldName

        Myform.ConnectionString = ConnectionString




        Myform.ShowDialog()

    End Sub

    Private Sub btnTextBody_Click(sender As Object, e As EventArgs) Handles btnTextBody.Click
        ShowDetail("TextBody")
    End Sub

    Private Sub btnHTMLBody_Click(sender As Object, e As EventArgs) Handles btnHTMLBody.Click
        ShowDetail("HTMLBody")
    End Sub

    Private Sub btnSubject_Click(sender As Object, e As EventArgs) Handles btnSubject.Click
        ShowDetail("Subject")
    End Sub

    Private Sub btnTo_Click(sender As Object, e As EventArgs) Handles btnTo.Click
        ShowDetail("To")
    End Sub

    Private Sub btnMessageId_Click(sender As Object, e As EventArgs) Handles btnMessageId.Click
        ShowDetail("MessageId")
    End Sub

    Private Sub btnBCC_Click(sender As Object, e As EventArgs) Handles btnBCC.Click
        ShowDetail("BCC")
    End Sub

    Private Sub btnrecipientIDList_Click(sender As Object, e As EventArgs) Handles btnrecipientIDList.Click
        ShowDetail("recipientIDList")
    End Sub

    Private Sub btnpi_Commentaire_Click(sender As Object, e As EventArgs) Handles btnpi_Commentaire.Click
        ShowDetail("pi_Commentaire")
    End Sub

    Private Sub btnDATAgi_Click(sender As Object, e As EventArgs) Handles btnDATAgi.Click
        ShowDetail("DATAgi")
    End Sub

    Private Sub btnpi_Ligne_Click(sender As Object, e As EventArgs) Handles btnpi_Ligne.Click
        ShowDetail("pi_Ligne")
    End Sub

    Private Sub btnLeft_Click(sender As Object, e As EventArgs) Handles btnLeft.Click
        MailId = MailId - 1
        BindTXT()

    End Sub

    Private Sub btnRight_Click(sender As Object, e As EventArgs) Handles btnRight.Click
        MailId = MailId + 1
        BindTXT()
    End Sub
End Class
