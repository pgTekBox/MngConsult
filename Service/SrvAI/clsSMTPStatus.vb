Public Class clsSMTPStatus



#Region "SMTP mail"



    Public HaveNewStatut As Boolean = True

    Private _MailSizeInput As String = "0"
    Public Property MailSizeInput As String
        Set(value As String)
            _MailSizeInput = value
            HaveNewStatut = True

        End Set
        Get
            Return _MailSizeInput
        End Get
    End Property

    Private _LastRecipient As String = "Jamais"
    Public Property LastRecipient As String
        Set(value As String)
            _LastRecipient = value
            HaveNewStatut = True
        End Set
        Get
            Return _LastRecipient
        End Get
    End Property



    Private _LastDomainName As String = "Jamais"
    Public Property LastDomainName As String
        Set(value As String)
            _LastDomainName = value
            HaveNewStatut = True
        End Set
        Get
            Return _LastDomainName
        End Get
    End Property




    Private _ThreadSMTPInputStarted As String = "Jamais"
    Public Property ThreadSMTPInputStarted As String
        Set(value As String)
            _ThreadSMTPInputStarted = value
            HaveNewStatut = True
        End Set
        Get
            Return _ThreadSMTPInputStarted
        End Get
    End Property




    Private _ThreadSMTPLastReceived As String = "Jamais"
    Public Property ThreadSMTPLastReceived As String
        Set(value As String)
            _ThreadSMTPLastReceived = value
            HaveNewStatut = True
        End Set
        Get
            Return _ThreadSMTPLastReceived
        End Get
    End Property




    Private _SMTPClientIP As String = "Jamais"
    Public Property SMTPClientIP As String
        Set(value As String)
            _SMTPClientIP = value
            HaveNewStatut = True
        End Set
        Get
            Return _SMTPClientIP
        End Get
    End Property



    Private _CounterEmailInput As String = "0"
    Public Property CounterEmailInput As String
        Set(value As String)
            _CounterEmailInput = value
            HaveNewStatut = True
        End Set
        Get
            Return _CounterEmailInput
        End Get
    End Property

    Private _StatusSMTPStepInput As String = "Jamais"
    Public Property StatusSMTPStepInput As String
        Set(value As String)
            _StatusSMTPStepInput = value
            HaveNewStatut = True
        End Set
        Get
            Return _StatusSMTPStepInput
        End Get
    End Property



    Private _SMTPStep As String = "0"
    Public Property SMTPStep As String
        Set(value As String)
            _SMTPStep = value
            HaveNewStatut = True
        End Set
        Get
            Return _SMTPStep
        End Get
    End Property
#End Region


#Region "Transmission de mail"

    Public HaveNewSendStatut As Boolean = True

    Private _SendStep As String = "0"
    Public Property SendStep As String
        Set(value As String)
            _SendStep = value
            HaveNewSendStatut = True
        End Set
        Get
            Return _SendStep
        End Get
    End Property

    Private _SendTo As String = "Jamais"
    Public Property SendTo As String
        Set(value As String)
            _SendTo = value
            HaveNewSendStatut = True
        End Set
        Get
            Return _SendTo
        End Get
    End Property

    Private _SendFrom As String = "Jamais"
    Public Property SendFrom As String
        Set(value As String)
            _SendFrom = value
            HaveNewSendStatut = True
        End Set
        Get
            Return _SendFrom
        End Get
    End Property

    Private _LastSend As String = "Jamais"
    Public Property LastSend As String
        Set(value As String)
            _LastSend = value
            HaveNewSendStatut = True
        End Set
        Get
            Return _LastSend
        End Get
    End Property

    Private _CounterEmailSend As String = "Jamais"
    Public Property CounterEmailSend As String
        Set(value As String)
            _CounterEmailSend = value
            HaveNewSendStatut = True
        End Set
        Get
            Return _CounterEmailSend
        End Get
    End Property

#End Region








    Public Function GetAllParam() As String
        HaveNewStatut = False
        Return CounterEmailInput & "|" & StatusSMTPStepInput & "|" & MailSizeInput & "|" & LastRecipient & "|" & LastDomainName & "|" & ThreadSMTPInputStarted & "|" & ThreadSMTPLastReceived & "|" & SMTPClientIP & "|" & SMTPStep & "|" & SendStep & "|" & SendTo & "|" & SendFrom & "|" & LastSend & "|" & CounterEmailSend
    End Function

    Public Sub Reset()
        CounterEmailInput = "0"
        StatusSMTPStepInput = ""
        MailSizeInput = ""
        LastRecipient = ""
        LastDomainName = ""
        ThreadSMTPInputStarted = ""
        ThreadSMTPLastReceived = ""
        SMTPClientIP = ""
        SMTPStep = "0"
        HaveNewStatut = True



    End Sub





    Public Sub ResetSend()
        CounterEmailSend = "0"
        LastSend = ""
        SendFrom = ""
        SendTo = ""
        SendStep = ""

        HaveNewSendStatut = True



    End Sub



    Public Sub RestoreParam(AllParam As String)

        Dim aParam As String() = AllParam.Split("|")

        CounterEmailInput = aParam(0)
        StatusSMTPStepInput = aParam(1)
        MailSizeInput = aParam(2)
        LastRecipient = aParam(3)
        LastDomainName = aParam(4)
        ThreadSMTPInputStarted = aParam(5)
        ThreadSMTPLastReceived = aParam(6)
        SMTPClientIP = aParam(7)
        SMTPStep = aParam(8)

        SendStep = aParam(9)
        SendTo = aParam(10)
        SendFrom = aParam(11)
        LastSend = aParam(12)
        CounterEmailSend = aParam(13)

    End Sub










End Class
